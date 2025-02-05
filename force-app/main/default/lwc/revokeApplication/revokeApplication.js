import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import ID_FIELD from "@salesforce/schema/Loan_Application__c.Id";
import STATUS_FIELD from "@salesforce/schema/Loan_Application__c.Loan_Application_Status__c";
import COMMENTS from "@salesforce/schema/Loan_Application__c.Comment__c";
import { updateRecord } from "lightning/uiRecordApi";
export default class RevokeApplication extends LightningElement {
    @api recordId;
    @track isConfirmModel = false;
    @track comments;

    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        console.log('recordId->' , this.recordId);
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess() {
        //this.showToastMessage('Success', 'Loan Application Canceled successfully.', 'success');
        //this.closeQuickAction();
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

    handleSave(){
        this.isConfirmModel = true;
        this.comments = this.template.querySelector(".commentCls").value;
    }

    handleYes(event){
        console.log('handle yes', this.comments);
        this.updateDisbursement();
    }

    handleSubmit(event) {
        
    }

    async updateDisbursement() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[COMMENTS.fieldApiName] = this.comments;
        fields[STATUS_FIELD.fieldApiName] = 'Revoke';
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMessage('Success', 'Loan Application has been revoked', 'success');
            this.closeQuickAction();
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMessage('Error', error.body.output.errors[0].message, 'error');
            this.closeQuickAction();
        });
    }
    
}