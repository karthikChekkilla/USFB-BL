import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
//import LEAD_OBJECT from "@salesforce/schema/Lead__c";
//import STATUS_FIELD from "@salesforce/schema/Lead__c.Lead_Status__c";
//import ID_FIELD from "@salesforce/schema/Lead__c.Id";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { updateRecord } from "lightning/uiRecordApi";

export default class LeadCancel extends LightningElement {
    @api recordId;

    /*async updateLead() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Cancelled';
        const recordInput = {
            fields: fields
        };

    
        await updateRecord(recordInput).then((record) => {
            this.showToastMessage('Success', 'Lead Canceled successfully', 'success');
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMessage('Error', error.body.output.errors[0].message, 'error');
           
        });
       

        this.closeQuickAction();
        
    }*/

    handleSubmit(event) {
        console.log('=======');
        event.preventDefault();
        const fields = event.detail.fields;
        console.log('fields.Cancel_Reason__c : ',fields.Cancel_Reason__c);
        console.log('fields.Cancel_Reason__c : ',fields.Comment__c);
        if(fields.Cancel_Reason__c == 'Other reason' && !fields.Comment__c) {
    
            this.showToastMessage('Error', 'Comment is required for Other reason.', 'error');
            //let commentBox = this.template.querySelector(".commentCls");
            //commentBox.setCustomValidity("Comment value is required");
            //commentBox.reportValidity();
  
            return;
        }
        fields.Lead_Status__c = 'Cancelled'; 
        fields.IsReadOnly__c = true; 
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
        this.showToastMessage('Success', 'Lead cancelled successfully.', 'success');
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

     
}