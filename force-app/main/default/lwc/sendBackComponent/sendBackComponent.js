import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordTypeName from '@salesforce/apex/UB_sendBackController.getRecordTypeName';
import handleSendBack from '@salesforce/apex/UB_sendBackController.handleSendBack';
import getLoanApplicationByDisbursement from '@salesforce/apex/UB_sendBackController.getLoanApplicationByDisbursement';

import LOAN_STAGE_FIELD from '@salesforce/schema/Loan_Application__c.Loan_Application_Stage__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/Loan_Application__c.RecordTypeId';
import DISBURSEMENT_RECORD_TYPE_FIELD from '@salesforce/schema/Disbursement__c.RecordTypeId';
import OWNER_ID_FIELD from '@salesforce/schema/Loan_Application__c.OwnerId';
import CPA_FIELD from '@salesforce/schema/Loan_Application__c.CPA__c';
import CM_FIELD from '@salesforce/schema/Loan_Application__c.CM__c';
import FINAL_AUTHORITY_FIELD from '@salesforce/schema/Loan_Application__c.Final_Authority__c';
import STAGE_FIELD from '@salesforce/schema/Disbursement__c.Stage__c';

import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

const LOAN_FIELDS = [LOAN_STAGE_FIELD, RECORD_TYPE_FIELD, OWNER_ID_FIELD, CPA_FIELD, CM_FIELD, FINAL_AUTHORITY_FIELD];
const DISBURSEMENT_FIELDS = [STAGE_FIELD, DISBURSEMENT_RECORD_TYPE_FIELD];

export default class SendBackComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    stageOptions = [];
    selectedStage;
    sendBackReason = '';
    loanRecord = {};
    recordTypeName = '';
    loanStage = '';
    disbursementStage = '';
    loanApplication;

    @wire(getRecord, { recordId: '$recordId', fields: LOAN_FIELDS })
    wiredLoanRecord({ error, data }) {
        if (data) {
            this.loanRecord = data;
            this.setStageOptions();
        } else if (error) {
            // this.handleError('Error fetching loan record', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: DISBURSEMENT_FIELDS })
    wiredDisbursementRecord({ error, data }) {
        if (data) {
            this.loanRecord = data;
            this.setStageOptions();
        } else if (error) {
            // this.handleError('Error fetching disbursement record', error);
        }
    }

    @wire(getLoanApplicationByDisbursement, { disbursementId: '$recordId' })
    wiredLoanApplication({ error, data }) {
        if (data) {
            console.log('data : ',data);
            this.loanApplication = data;
            this.setStageOptions();
        } else if (error) {
           //  this.handleError('Error fetching loan application', error);
        }
    }

    get isLoanApplication() {
        return this.objectApiName === 'Loan_Application__c';
    }

    get isDisbursement() {
        return this.objectApiName === 'Disbursement__c';
    }

    connectedCallback() {
        this.objectApiName === 'Loan_Application__c';
        console.log('Connected callback - Object API Name:', this.objectApiName);
    }

    setStageOptions() {
        if (this.isLoanApplication) {
            this.setLoanStageOptions();
        } else if (this.isDisbursement) {
            this.setDisbursementStageOptions();
        }
    }

    setLoanStageOptions() {
        this.loanStage = this.loanRecord.fields?.Loan_Application_Stage__c?.value;
        const recordTypeId = this.loanRecord.fields?.RecordTypeId?.value;

        if (recordTypeId) {
            this.fetchRecordTypeName(recordTypeId).then(() => {
                if (this.loanStage === 'Recommended for Approval' && this.recordTypeName === 'Underwriting Initiated') {
                    this.stageOptions = [
                        { label: 'DDE', value: 'DDE' },
                        { label: 'Credit Assessment', value: 'Credit Assessment' }
                    ];
                } else if (this.loanStage === 'Credit Assessment' && this.recordTypeName === 'Underwriting Initiated') {
                    this.stageOptions = [{ label: 'DDE', value: 'DDE' }];
                }
            });
        }
    }

    setDisbursementStageOptions() {
        this.disbursementStage = this.loanRecord.fields?.Stage__c?.value;
        if (this.disbursementStage === 'Negotiation') {
            this.stageOptions = [
                { label: 'DDE', value: 'DDE' },
                { label: 'Credit Assessment', value: 'Credit Assessment' },
                { label: 'Recommended for Approval', value: 'Recommended for Approval' }
            ];
        }
        this.loanStage = this.loanApplication?.Loan_Application_Stage__c;
        console.log('OUTPUT :from disbursement ', this.loanStage);
    }

    async fetchRecordTypeName(recordTypeId) {
        try {
            const result = await getRecordTypeName({ recordTypeId });
            this.recordTypeName = result;
            console.log('Record Type Name:', this.recordTypeName);
        } catch (error) {
            //  this.handleError('Error fetching record type name', error);
        }
    }

    handleStageChange(event) {
        this.selectedStage = event.detail.value;
    }

    handleSendBackReasonChange(event) {
        this.sendBackReason = event.target.value;
    }

    handleSendBack() {
        const loanStage = this.loanStage;
        const recordType = this.recordTypeName;
        const ownerToBeId = this.determineOwnerToBeId(loanStage);
        console.log('ownertobe==>', ownerToBeId);
        console.log('boject : ',this.objectApiName);
        if(ownerToBeId === undefined){
             this.showNotification('Error', 'We did not find the owner against the specified selected stage to assign. Please update the Owner first', 'Error');
             return;
        }
        const recordIdToUse = this.isLoanApplication ? this.recordId : this.loanApplication?.Id;

        handleSendBack({
            recordId: recordIdToUse,
            objectApiName: this.objectApiName,
            loanStage: loanStage,
            recordType: recordType,
            ownerRole: null, // Owner Role would be determined server-side if needed
            selectedStage: this.selectedStage,
            sendBackReason: this.sendBackReason,
            ownerToBeId: ownerToBeId
        })
            .then(() => {
                this.showNotification('Success', 'Record sent back successfully', 'success');
                this.closeQuickAction();
                getRecordNotifyChange([{recordId: recordIdToUse}]);
               
               // this.navigateToRecordPage(recordIdToUse, this.objectApiName);
            })
            .catch(error => {
                this.handleError('Error sending back record', error);
            });
    }

    determineOwnerToBeId(loanStage) {
        console.log('OUTPUT : ',loanStage);
        const cpaId = this.loanRecord.fields?.CPA__c?.value || this.loanApplication?.CPA__c;
        const cmId = this.loanRecord.fields?.CM__c?.value || this.loanApplication?.CM__c;
        const fa = this.loanRecord.fields?.Final_Authority__c?.value || this.loanApplication?.Final_Authority__c;
        console.log('cpaId==>', cpaId);
        console.log('fa==>',fa);
        console.log('loan rec : ',this.loanRecord);
         console.log('loan app : ',this.loanApplication);
        let OwnerToBeId;

        if (loanStage === 'Credit Assessment') {
            OwnerToBeId = cpaId;
        } else if (loanStage === 'Recommended for Approval' && this.selectedStage === 'DDE') {
            OwnerToBeId = cpaId;
        } else if (loanStage === 'Recommended for Approval' && this.selectedStage === 'Credit Assessment') {
            OwnerToBeId = cmId;
        } else if (this.disbursementStage === 'Negotiation') {
            if (this.selectedStage === 'DDE') {
                OwnerToBeId = cpaId;
            } else if (this.selectedStage === 'Credit Assessment') {
                OwnerToBeId = cmId;
            } else if (this.selectedStage === 'Recommended for Approval') {
                OwnerToBeId = this.loanRecord.fields?.Final_Authority__c?.value || this.loanApplication?.Final_Authority__c;
            }
        }

        return OwnerToBeId;
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(message, error) {
        console.error(message, error);
        this.showNotification('Error', error.body ? error.body.message : message, 'error');
    }

    navigateToRecordPage(recordId, objectApiName) {
        console.log('called');
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
               // objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }
}