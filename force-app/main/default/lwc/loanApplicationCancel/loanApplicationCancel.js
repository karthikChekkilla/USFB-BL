import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class LoanApplicationCancel extends LightningElement {
    @api recordId;

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        console.log( "Fields: ", fields.Cancel_Reason__c);
        if(fields.Cancel_Reason__c == 'Other reason' && !fields.Comment__c) {
            this.showToastMessage('Error', 'Comment is required for Other reason.', 'error');  
            return;
        }
        fields.Loan_Application_Status__c ='Cancelled';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
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

    handleSuccess() {
        this.showToastMessage('Success', 'Loan Application Canceled successfully.', 'success');
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}