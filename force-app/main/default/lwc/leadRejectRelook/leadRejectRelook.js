import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import relookLead from "@salesforce/apex/UB_RelookController.relookLead";
export default class LeadRejectRelook extends LightningElement {
    @api recordId;
    @track flag = false;
 
    handleSubmit() {
        event.preventDefault();
        console.log('-------------');
        try{
            
            const fields = event.detail.fields;
            // console.log('===='+fields.Rejected_By__c);
            // fields.Lead_Status__c = 'Active';
            // fields.ownerId = fields.Rejected_By__c;
            
            // this.template.querySelector('lightning-record-edit-form').submit(fields);
            // this.closeQuickAction();

            

             relookLead({ leadId: this.recordId, comment: fields.Comment__c})
            .then((result) => {
                this.showToastMessage('Success', 'Lead is active now.', 'success');
                 
                 setTimeout(() => {
                    //location.reload('/lightning/r/Lead__c/'+this.recordId);
                    window.location.href = "/"+this.recordId;
                 }, "2000");
                     
            })
            .catch((error) => {
                console.log('error=='+error);
                this.showToastMessage('Error',JSON.stringify(error), 'error');
            });

        // this.closeQuickAction();

        } catch(errMsg) {
            console.log('===='+errMsg);
        }
       
        
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
        this.showToastMessage('Success', 'Relook rejected lead successfully done.', 'success');
    }


    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}