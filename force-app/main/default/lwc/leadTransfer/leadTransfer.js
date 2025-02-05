import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from "lightning/navigation";
import transferLead from "@salesforce/apex/UB_LeadTransferController.transferLead";

export default class LeadTransfer extends NavigationMixin (LightningElement) {
    @api recordId;
    
    updateRecord() {
        transferLead({ leadId: this.recordId })
        .then((result) => {
           console.log('result=='+result);
           if(result != null && result.startsWith('ERROR:')){
            console.log('result=in error=='+result);
                 this.showToastMessage('ERROR',result,'error');
                 this.closeQuickAction();
            }
            else if(result == null){
                this.showToastMessage('ERROR','Relationship Manager Not Found..','error');
                this.closeQuickAction();
            }
            else{
                try{
                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Lead__c',
                            actionName: 'list'
                        },
                    });
                    this.showToastMessage('Success', 'Record Transfered successfully', 'success');
                    this.closeQuickAction();
                } catch(errMsg) {
                    console.log(errMsg);
                    console.log('error -- >',JSON.stringify(errMsg));
                    this.showToastMessage('Error',JSON.stringify(errMsg), 'error');
                    this.closeQuickAction();
                }

            }
        })
        .catch((error) => {
            console.log('error=='+error);
            console.log('error=='+JSON.stringify(error));
            this.showToastMessage('Error',JSON.stringify(error), 'error');
            this.closeQuickAction();
        });

        //this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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

}