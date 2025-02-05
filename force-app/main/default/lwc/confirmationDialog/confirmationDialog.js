import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import UserNameFIELD from '@salesforce/schema/User.Name';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import ROLE_NAME from '@salesforce/schema/User.UserRole.Name'; //added by chandan
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import updateVerifiedDocument from '@salesforce/apex/UB_DisplayUBDocumentsController.updateVerifiedDocument';
import createTaskForAcknowledement from '@salesforce/apex/UB_DisplayUBDocumentsController.createTaskForAcknowledement';
export default class ConfirmationDialog extends NavigationMixin(LightningElement) {
    @api visible; //used to hide/show dialog
    @api title; //modal title
    @api cancelLabel; //cancel button label
    @api objectName;
    @track userProfileName;
    @track headerClass = 'slds-modal__header slds-theme_alert-texture';
    @api originalMessage;
    @api name; //reference name of the component
    @api theme;
    @api confirmLabel; //confirm button label
    @track value = '';
    @track comments = '';
    @track verificationStatus = '';
    @api documentId;
    @track commentsRequired = false;
    @track verifyOptions = [];
    @api metadata;
    @track isQueryRaisedOnDisbursement = false;

    @wire(getObjectInfo, { objectApiName: DOCUMENT_OBJECT })
    objectInfo;



    connectedCallback() {
        console.log('documentId-> ', JSON.stringify(this.documentId));
        console.log('confirmationDialog.objectName-> ', this.objectName);
        this.applyHeaderClass();
        this.setVerifyOptions();
    }

    //added by chandan on 25th JUly,2024 to set different options based on users role and profile
    @wire(getRecord, { recordId: Id, fields: [UserNameFIELD, ProfileName, ROLE_NAME] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
            console.error('Error fetching user details:', error);
            return;
        }

        if (data) {
            console.log('OUTPUT : ', data);
            const { Profile, UserRole } = data.fields;
            if (Profile?.value && UserRole?.value) {
                this.userProfileName = Profile.value.fields.Name.value;
                this.userRoleName = UserRole.value.fields.Name.value;
                console.log('User Role Name:', this.userRoleName);
                this.setVerifyOptions();
            } else {
                console.log('Profile or UserRole data is missing');
            }
        }
    }


    // Added by Chandan on 22nd July,2024 to show only verify options for RCU Profile
    setVerifyOptions() {
        // Initialize verifyOptions to a default value
        let options = [
            { label: 'Verified', value: 'Verified' },
            { label: 'Query Raised', value: 'Query Raised' },
            { label: 'Not Received', value: 'Not Received' }
        ];

        // Determine verify options based on conditions
        switch (true) {
            case this.metadata === 'Sanction_Condition' &&
                this.userRoleName === 'Credit Manager' &&
                ['Loan_Application__c', 'Disbursement__c'].includes(this.objectName):
                options = [
                    { label: 'Verified', value: 'Verified' },
                    { label: 'Query Raised', value: 'Query Raised' },
                    { label: 'OTC', value: 'OTC' },
                    { label: 'PDD', value: 'PDD' }
                ];
                break;

            case this.userProfileName === 'RCU' &&
                ['Loan_Application__c', 'Disbursement__c'].includes(this.objectName):
                options = [
                    { label: 'Verified', value: 'Verified' }
                ];
                break;

            case this.objectName === 'Disbursement__c' &&
                this.userRoleName === 'CPC Agents (Maker)':
                options = [
                    { label: 'Query Raised', value: 'Query Raised' },
                    { label: 'Waived Off', value: 'Waived Off' },
                    { label: 'Completed', value: 'Completed' }
                ];
                break;

            case this.objectName === 'Disbursement__c' &&
                this.userRoleName === 'CPC Agents (Checker)':
                options = [
                    { label: 'Query Raised', value: 'Query Raised' },
                    { label: 'Waived Off', value: 'Waived Off' },
                    { label: 'Completed', value: 'Completed' }
                ];
                break;

            case this.userRoleName === 'Credit Manager' &&
                ['Disbursement__c'].includes(this.objectName):
                options = [
                    { label: 'Verified', value: 'Verified' },
                    { label: 'Query Raised', value: 'Query Raised' },
                    { label: 'OTC', value: 'OTC' },
                    { label: 'PDD', value: 'PDD' }
                ];
                break;

            case this.objectName === 'Disbursement__c':
                options = [
                    { label: 'Received', value: 'Received' },
                    { label: 'Not Received', value: 'Not Received' }
                ];
                break;
        }

        // Assign the determined options to verifyOptions
        this.verifyOptions = options;
    }

    /*get verifyOptions() {
        return [
            { label: 'Verified', value: 'Verified' },
            { label: 'Query Raised', value: 'Query Raised' },
            { label: 'Not Received', value: 'Not Received' },
        ];
    }*/

    // Apply Classes Based on Theme
    applyHeaderClass() {
        if (this.theme && this.theme.toLowerCase() == 'success') {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture slds-theme_success';
        } else if (this.theme && this.theme.toLowerCase() == 'error') {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture slds-theme_error';
        } else if (this.theme && this.theme.toLowerCase() == 'info') {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture slds-theme_info';
        } else if (this.theme && this.theme.toLowerCase() == 'warning') {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture slds-theme_warning';
        } else if (this.theme && this.theme.toLowerCase() == 'offline') {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture slds-theme_offline';
        } else {
            this.headerClass = 'slds-modal__header slds-theme_alert-texture';
        }
    }



    //modified by chandan on 24th July 2024 to Handles click events for various actions (e.g., cancel, confirm, close).
    handleClick(event) {
        const eventName = event.target.name;
        const textarea = this.template.querySelector('lightning-textarea');
        this.comments = textarea ? textarea.value : '';

        console.log('handleClick ->', eventName);
        console.log('Document IDs length ->', this.documentId.length);

        // Helper function to dispatch event
        const dispatchClickEvent = (status) => {
            this.dispatchEvent(new CustomEvent('clickdialog', { detail: { status } }));
        };

        // Handle different button actions based on the event name
        switch (eventName) {
            case 'cancel':
            case 'close':
                dispatchClickEvent(eventName);
                break;

            case 'confirm':
                console.log('Verification Status ->', this.verificationStatus);

                // Define valid verification statuses
                const validStatuses = ['Verified', 'Not Verified', 'RCU Acknowledged', 'Received', 'OTC', 'PDD', 'Completed', 'Waived Off'];

                // Check for valid verification status and proceed accordingly
                if (this.verificationStatus && validStatuses.includes(this.verificationStatus)) {
                    this.updateDocumentRecord(eventName);
                } else if (this.verificationStatus && ['Not Received', 'Query Raised'].includes(this.verificationStatus) &&
                    this.comments) {
                    console.log('Verification Status ->', this.verificationStatus);
                    console.log('Comments ->', this.comments);

                    if (this.objectName === 'Disbursement__c') {
                        this.updateDocumentRecord(eventName);
                        this.isQueryRaisedOnDisbursement = true;
                       // this.createTaskForAcknowledement(eventName);
                    } else {
                        this.createTaskForAcknowledement(eventName);
                    }
                }
                break;

            default:
                console.warn('Unknown event name:', eventName);
                break;
        }
    }


    updateDocumentRecord(event) {
        try {
            console.log('updateDocumentRecord this.documentId-> ', JSON.stringify(this.documentId));
            updateVerifiedDocument({ docIds: this.documentId, sObjectName: this.objectName, ackStatus: this.verificationStatus })
                .then(result => {
                    console.log('updateVerifiedDocument result -> ', result);
                    if (result.isSuccess) {
                        if(this.isQueryRaisedOnDisbursement){
                            this.createTaskForAcknowledement(eventName);
                        }
                        this.showNotification('Success', result.responseBody, 'success');
                        let finalEvent = {
                            status: event
                        };
                        //dispatch a 'click' event so the parent component can handle it
                        this.dispatchEvent(new CustomEvent('clickdialog', { detail: finalEvent }));
                    }else{
                         this.showNotification('Error', result.responseBody, 'error');
                    }
                }).catch(error => {
                    console.log('updateVerifiedDocument error -> ', error);
                    this.showNotification('Error', error, 'error');
                })
        } catch (error) {
            console.log('error-> ', error);
            this.showNotification('Error', error, 'error');
        }
    }

    createTaskForAcknowledement(eventName) {
        try {
            createTaskForAcknowledement({ docIds: this.documentId, verificationStatus: this.verificationStatus, comments: this.comments })
                .then(result => {
                    console.log('createTaskForAcknowledement result -> ', result);
                    if (result.isSuccess) {
                        this.showNotification('Success', result.responseBody, 'success');
                        let finalEvent = {
                            status: eventName
                        };
                        //dispatch a 'click' event so the parent component can handle it
                        this.dispatchEvent(new CustomEvent('clickdialog', { detail: finalEvent }));
                    } else {
                        this.showNotification('Error', result.responseBody, 'error');
                    }
                }).catch(error => {
                    console.log('createTaskForAcknowledement error -> ', error);
                    this.showNotification('Error', error, 'error');
                })
        } catch (error) {
            console.log('error-> ', error);
            this.showNotification('Error', error, 'error');
        }
    }

    //modified by chandan on 24th July,2024 to handles changes to the verification status selection.
    handleChange(event) {
        const value = event.target.value;
        const commentsRequiredStatuses = ['Query Raised', 'Not Received', 'OTC', 'PDD', 'Waived Off', 'Completed'];
        const noCommentsRequiredStatuses = ['Verified', 'Not Verified', 'Received'];

        // Set verification status and comments requirement based on the selected value
        if (commentsRequiredStatuses.includes(value)) {
            this.verificationStatus = value;
            this.commentsRequired = true;
        } else if (noCommentsRequiredStatuses.includes(value)) {
            this.verificationStatus = value;
            this.commentsRequired = false;
        }
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}