import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCancelReasonsList from '@salesforce/apex/UB_LoanApplicationRejectController.getCancelReasonsList';
import CANCELLATION_APPLICATION_REASON from "@salesforce/schema/Loan_Application__c.BL_Cancellation_Reasons__c";
import CANCELLATION_APPLICATION_SOURCE from "@salesforce/schema/Loan_Application__c.BL_Cancellation_Source__c";
import LOAN_STATUS from "@salesforce/schema/Loan_Application__c.Loan_Application_Status__c";
import CANCELLATION_LEAD_REASON from "@salesforce/schema/Lead__c.BL_Cancellation_Reasons__c";
import CANCELLATION_LEAD_SOURCE from "@salesforce/schema/Lead__c.BL_Cancellation_Source__c";
import LEAD_STATUS from "@salesforce/schema/Lead__c.Lead_Status__c";
import APPLICATION_ID from "@salesforce/schema/Loan_Application__c.Id";
import LEAD_ID from "@salesforce/schema/Lead__c.Id";
import { deleteRecord, updateRecord, getFieldValue, getRecord } from 'lightning/uiRecordApi';
export default class CancelRecord extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track cancellationSource;
    @track cancelReason;
    @track cancelReasonOptions = [];
    @track bankInducedReasons = [];
    @track customerInducedReasons = [];
    @track cancellationSourceOptions = [];
    @track showSpinner = false;

    connectedCallback() {
        this.loadCancelReasons();
    }

    async loadCancelReasons() {
        try {
            console.log('Flag1');
            console.log('recordId ',this.recordId);
            console.log('objectApiName ',this.objectApiName);
            console.log('Flag1');
            const data = await getCancelReasonsList();
            const bankInducedMap = new Map();
            const customerInducedMap = new Map();
            const sourceSet = new Set();

            data.forEach(reason => {
                sourceSet.add(reason.Cancellation_Source__c);
                if (reason.Cancellation_Source__c === 'Bank Induced') {
                    bankInducedMap.set(reason.Cancel_Reason__c, reason.Cancel_Reason__c);
                } else if (reason.Cancellation_Source__c === 'Customer Induced') {
                    customerInducedMap.set(reason.Cancel_Reason__c, reason.Cancel_Reason__c);
                }
            });

            this.cancellationSourceOptions = Array.from(sourceSet).map(source => ({ label: source, value: source }));
            this.bankInducedReasons = Array.from(bankInducedMap.entries()).map(([value, label]) => ({ label, value }));
            this.customerInducedReasons = Array.from(customerInducedMap.entries()).map(([value, label]) => ({ label, value }));
        } catch (error) {
            this.showToastMessage('Error', 'Failed to load cancellation reasons.', 'error');
            console.error('Error fetching cancel reasons: ', error);
        }
    }

    handleCancellationSourceChange(event) {
        this.cancellationSource = event.detail.value;
        if (this.cancellationSource === 'Bank Induced') {
            this.cancelReasonOptions = this.bankInducedReasons;
        } else if (this.cancellationSource === 'Customer Induced') {
            this.cancelReasonOptions = this.customerInducedReasons;
        }
        this.cancelReason = null; 
    }

    handleCancelReasonChange(event) {
        this.cancelReason = event.detail.value;
    }

    handleSubmit(event) {
        console.log('Flag2');
        event.preventDefault();
        const fields = event.detail.fields;
        this.showSpinner = true;
        if (this.objectApiName === 'Lead__c') {
            console.log('FlagLead');
            if (this.cancelReason == '' || this.cancellationSource == '' || this.cancelReason == undefined || this.cancellationSource == undefined) {
                this.showToastMessage('Error', 'Please fill required fields', 'error');
                this.showSpinner = false;
            } else {
                this.updateLeadStatus();
            }
        } else if (this.objectApiName === 'Loan_Application__c') {
            console.log('this.cancelReason ', this.cancelReason);
            console.log('this.cancellationSource ', this.cancellationSource);
            if (this.cancelReason == '' || this.cancellationSource == '' || this.cancelReason == undefined || this.cancellationSource == undefined) {
                this.showToastMessage('Error', 'Please fill required fields', 'error');
                this.showSpinner = false;
            } else {
                this.updateApplicationStatus();
            }
        }

        
    }

    handleSuccess() {
        console.log('FlagSuccess');
        this.showToastMessage('Success', 'Record cancelled successfully.', 'success');
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.showSpinner = false;
        const event = new CustomEvent('closeaction');
        this.dispatchEvent(event);
    }

    showToastMessage(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    async updateApplicationStatus() {
        const fields = {};
        fields[CANCELLATION_APPLICATION_REASON.fieldApiName] =  this.cancelReason;
        fields[CANCELLATION_APPLICATION_SOURCE.fieldApiName] = this.cancellationSource;
        fields[APPLICATION_ID.fieldApiName] = this.recordId;
        fields[LOAN_STATUS.fieldApiName] = 'Cancelled';
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMessage('Success', 'Loan Application cancelled successfully.', 'success');
            this.closeQuickAction();
        })
            .catch(error => {
                console.log('ERROR:' + JSON.stringify(error));
                this.showToastMessage('Error', error.body.output.errors[0].message, 'error');

            });

    }

    async updateLeadStatus() {
        const fields = {};
        fields[CANCELLATION_LEAD_REASON.fieldApiName] =  this.cancelReason;
        fields[CANCELLATION_LEAD_SOURCE.fieldApiName] = this.cancellationSource;
        fields[LEAD_ID.fieldApiName] = this.recordId;
        fields[LEAD_STATUS.fieldApiName] = 'Cancelled';
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMessage('Success', 'Lead cancelled successfully.', 'success');
            this.closeQuickAction();
        })
            .catch(error => {
                console.log('ERROR:' + JSON.stringify(error));
                this.showToastMessage('Error', error.body.output.errors[0].message, 'error');

            });

    }
}