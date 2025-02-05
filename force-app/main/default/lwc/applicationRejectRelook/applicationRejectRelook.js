import { LightningElement, wire, api } from 'lwc';
import relookApplication from "@salesforce/apex/UB_RelookController.relookApplication";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class ApplicationRejectRelook extends LightningElement {
    @api recordId;
   
 
    handleSubmit() {
        event.preventDefault();
        console.log('-------------');
        const fields = event.detail.fields;

        relookApplication({ applicationId: this.recordId, comment: fields.Comment__c})
        .then((result) => {
            this.showToastMessage('Success', 'Loan application is active now.', 'success');
                setTimeout(() => {
                //location.reload('/lightning/r/Lead__c/'+this.recordId);
                window.location.href = "/"+this.recordId;
                }, "2000");
                    
        })
        .catch((error) => {
            console.log('ERROR:'+error);
            console.log('JSON.stringify(error):'+JSON.stringify(error));
            this.showToastMessage('Error',error.body.message, 'error');
        });

     
       
        
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
        this.showToastMessage('Success', 'Relook rejected application successfully done.', 'success');
    }


    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}