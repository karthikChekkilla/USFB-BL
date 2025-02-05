import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoanApplicantRecords from '@salesforce/apex/UB_DisplayUBDocumentsController.getLoanApplicantRecords';
import getRecordIsReadOnlyFromSObject from '@salesforce/apex/UB_DisplayUBDocumentsController.getRecordIsReadOnlyFromSObject';
import { getRecord } from 'lightning/uiRecordApi';
import READ_ONLY from "@salesforce/schema/Loan_Application__c.IsReadOnly__c";
export default class DisplayUBDocuments extends LightningElement {
    @api objectApiName;
    @api metadata = 'Document_Information';
    @api PDD;
    @track isReadonly = false;
    @track showDocumentModal = false;
    @track sectionName;
    @api recordId;
    @track loanApplicantList = [];
    @track wiredApplicantResult;
    @track isRecordFound = true;
    @track currentTabApplicantId = '';
    @track defaultValues = [];
    @track inputVariables = [];
    @track buttonLabel = 'New';
    @api hideNewButton;
    hideNew = false;

   /* @wire(getRecord, { recordId: "$recordId", fields: [READ_ONLY] })
    getApplications({ error, data }) {
        if (error) {
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            if(data.fields.IsReadOnly__c.value != null){
                this.isreadonly = data.fields.IsReadOnly__c.value;
                console.log('data.fields.IsReadOnly__c.value-> ', data.fields.IsReadOnly__c.value);
            }
        }
    }*/


    //added by chandan on 25th July,2024 to dynamically change label of button and hide and show the new button
    connectedCallback() {
        console.log('DisplayUBDocuments recordId:', this.recordId);
        console.log('DisplayUBDocuments objectApiName:', this.objectApiName);

        // Set button label based on metadata
        this.buttonLabel = (this.metadata === 'Sanction_Condition') ? 'New Sanction Condition' : this.buttonLabel;

        // Determine if the new button should be hidden
        this.hideNew = this.hideNewButton === 'Yes';
        this.getRecordIsReadOnlyFromSObject();
    }


    /*@wire(getRecord, { recordId:'$recordId', fields: this.fields})
    loadFields({error, data}){
        if(error){
            console.log('error getRecord', error);
        }else if(data){
            console.log('data', JSON.parse(JSON.stringify(data)));
            const paramField1 = getFieldValue(data, isReadOnlyLead);
            const paramField2 = getFieldValue(data, isReadOnlyApp);
            console.log('paramField1', paramField1);
            console.log('paramField2', paramField2);
        }
    }*/



    refreshData() {
        return refreshApex(this.wiredApplicantResult);
    }

    //modified by chandan on 24th July,2024
    get showForOpportunityObject() {
        return this.objectApiName === 'Loan_Application__c' || this.metadata === 'Sanction_Condition';
    }

    get cssClass() {
        console.log('width :', window.innerWidth);
        return window.innerWidth < 493 ? '' : 'slds-float_right';
    }

    showToastMsg(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        )
    }

    // Wire Method For Get Loan Applicant Records For Creating Tabs
    // modified by chandan on 24th July,2024
    @wire(getLoanApplicantRecords, { applicationId: '$recordId' })
    wireGetLoanApplicantRecords({ error, data }) {
        if (data) {
            console.log('OUTPUT: loan applicant data:', data);

            this.wiredApplicantResult = data;

            if (data.isSuccess) {
                // Success scenario
                this.isRecordFound = true;
                //this.isreadonly = data.irReadOnly;

                // Parse and set loan applicant list
                const tempList = JSON.parse(data.responseBody);
                console.log('Parsed loan applicants:', tempList);

                this.loanApplicantList = [{ Name: 'Application', Id: '' }, ...tempList];
                console.log('Updated loanApplicantList:', this.loanApplicantList);
            } else {
                // Handle cases where record is not found
                this.isRecordFound = this.metadata === 'Sanction_Condition';
                console.log('No record found. Data:', data);
            }
        } else if (error) {
            console.error('Error retrieving loan applicant records:', error);
        }
    }


    // modified by chandan on 24th July,2024 
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // Hide the document modal
            this.showDocumentModal = false;

            // Show a success toast message based on metadata
            const successMessage = this.metadata === 'Sanction_Condition'
                ? 'Sanction Conditions added Successfully'
                : 'Document Created Successfully';
            this.showToastMsg('Success', successMessage, 'Success');

            // Handle different object types and refresh data accordingly
            // added by chandan on 24th July,2024
            const documentDetailsComponent = this.template.querySelector("c-display-u-b-document-details");
            if (documentDetailsComponent) {
                switch (this.objectApiName) {
                    case 'Loan_Application__c':
                        documentDetailsComponent.getApplicationDocuments();
                        break;
                    case 'Lead__c':
                        documentDetailsComponent.getLeadDocuments();
                        break;
                    case 'Disbursement__c':
                        documentDetailsComponent.getDisbursementDocs();
                        break;
                    default:
                        console.warn(`Unhandled objectApiName: ${this.objectApiName}`);
                        break;
                }
            } else {
                console.error('Document details component not found');
            }
        }
    }

    // modified by chandan on 24th July,2024 to set the imput parameter for flows based on different objects
    // Open New Record Creation Page.
    handleClick(event) {
        this.showDocumentModal = true;

        // Common input variables
        this.inputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            },
            {
                name: 'applicantId',
                type: 'String',
                value: this.currentTabApplicantId
            },
            {
                name: 'objectApiName',
                type: 'String',
                value: this.objectApiName
            }
        ];

        // Handle different object types
        switch (this.objectApiName) {
            case 'Loan_Application__c':
                this.defaultValues['Loan_Application__c'] = this.recordId;
                this.inputVariables.push({
                    name: 'metaData',
                    type: 'String',
                    value: this.metadata
                });
                break;

            case 'Lead__c':
                this.defaultValues['Lead__c'] = this.recordId;
                break;

            case 'Disbursement__c':
                console.log('OUTPUT: objectApiName:', this.objectApiName);
                console.log('OUTPUT: recordId:', this.recordId);
                console.log('OUTPUT: metadata:', this.metadata);
                this.inputVariables.push({
                    name: 'metaData',
                    type: 'String',
                    value: this.metadata
                });
                break;

            default:
                console.warn('Unhandled objectApiName:', this.objectApiName);
                break;
        }

        // Common default values
        this.defaultValues['Loan_Applicant__c'] = this.currentTabApplicantId;

        // Log the default values
        console.log('this.defaultValues:', this.defaultValues);
    }


    handleActiveTab(event) {
        this.currentTabApplicantId = event.target.dataset.id;
        console.log('this.currentTabApplicantId-> ', this.currentTabApplicantId);
    }

    handleClose1(event) {
        //console.log('Close ', event.detail.isShowModal);
        //this.showDocumentModal = event.detail.isShowModal;
        console.log('handleClose1-> ', event.detail);
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
        //refreshApex(this.taskResourceResults);
        //eval("$A.get('e.force:refreshView').fire();");
    }

    handleClose(event) {
        //console.log('Close ', event.detail.isShowModal);
        //this.showDocumentModal = event.detail.isShowModal;
        //eval("$A.get('e.force:refreshView').fire();");
        this.showDocumentModal = false;
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave(event) {
        //console.log('Save ', event.detail.isShowModal);
        //eval("$A.get('e.force:refreshView').fire();");
        //this.template.querySelector('c-display-mf-document-details').getApplicationDocuments();
        if (this.objectApiName == 'Loan_Application__c') {
            this.template.querySelector("c-display-u-b-document-details").getApplicationDocuments();
        } if (this.objectApiName == 'Lead__c') {
            this.template.querySelector("c-display-u-b-document-details").getLeadDocuments();
        }
        this.showDocumentModal = event.detail;

    }

    get showDocumentDetails() {
        // Check if metadata is not null and record is found
        console.log('OUTPUT : recordfound', this.isRecordFound);
        console.log('OUTPUT : metadata', this.metadata);
        return this.isRecordFound && this.metadata == 'Sanction_Condition';
    }

    getRecordIsReadOnlyFromSObject() {
        getRecordIsReadOnlyFromSObject({ recordId: this.recordId, SObjectName: this.objectApiName })
            .then(result => {
                console.log('getRecordIsReadOnlyFromSObject result -> ', result);
                this.isReadonly = result;
            }).catch(error => {
                console.log('getRecordIsReadOnlyFromSObject error -> ', error);
            })
    }
    
}