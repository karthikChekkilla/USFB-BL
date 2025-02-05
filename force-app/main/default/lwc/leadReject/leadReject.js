import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import rejectLead from "@salesforce/apex/UB_RejectController.rejectLead";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from "@salesforce/user/Id";
import { NavigationMixin } from "lightning/navigation";

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Lead__c.Name";
import OWNER_FIELD from "@salesforce/schema/Lead__c.OwnerId";
const fields = [NAME_FIELD, OWNER_FIELD];

//import { updateRecord } from "lightning/uiRecordApi";
export default class LeadReject extends NavigationMixin (LightningElement) {
    @api recordId;
    crntUserId = Id;
     
    @wire(getRecord, { recordId: "$recordId", fields}) 
    lead;

    get isRecordOwner() {
        let ownerId = getFieldValue(this.lead.data, OWNER_FIELD);
        if(this.crntUserId == ownerId) {
            return true;
        } else {
            return false;
        }
    }

    // renderedCallback() {
 

    //     setTimeout(() => {
    //             console.log('------'+this.lead.data.apiName);
    //             console.log('------'+JSON.stringify(this.lead.data));
    //         }, "2000");
       
    // }

    /*async updateLead() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Rejected';
        const recordInput = {
            fields: fields
        };

    
        await updateRecord(recordInput).then((record) => {
            this.showToastMessage('Success', 'Lead rejected successfully.', 'success');
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMessage('Error', error.body.output.errors[0].message, 'error');
           
        });
       

        this.closeQuickAction();
        
    }*/

    handleSubmit() {
        event.preventDefault();
        console.log('==='+this.crntUserId);
        const fields = event.detail.fields;
        console.log( "Fields: ", fields );
        console.log( "Fields: ", fields.Reject_Reason__c);
        console.log( "Fields: ", fields.Reject_Sub_Reason__c);
        if(fields.Reject_Reason__c == 'Any Other Reasons' && !fields.Comment__c) {
            this.showToastMessage('Error', 'Comment is required for Other reason.', 'error');
            //let commentBox = this.template.querySelector(".commentCls");
            //commentBox.setCustomValidity("Comment value is required"); 
            //commentBox.reportValidity();
            return;
        }

        // fields.Lead_Status__c = 'Rejected';
        // fields.Rejected_By__c = this.crntUserId;
        
        //====
        rejectLead({ leadId: this.recordId, reason: fields.Reject_Reason__c, subReason:fields.Reject_Sub_Reason__c})
            .then((result) => {
                console.log('result=='+result);

                if(result == 'success') {

                        this.showToastMessage('Success', 'Lead rejected successfully.', 'success');
                    //  setTimeout(() => {
                    //     location.reload();
                    //  }, "2000");

                    try{
                        this[NavigationMixin.Navigate]({
                            type: 'standard__objectPage',
                            attributes: {
                                objectApiName: 'Lead__c',
                                actionName: 'list'
                            },
                        });
                    } catch(errMsg) {
                        console.log(errMsg);
                    }
                } else {
                    console.log('error==1'+JSON.stringify(result));
                    this.showToastMessage('Error',JSON.stringify(result), 'error');

                }
                
                     
            })
            .catch((error) => {
                console.log('error=='+JSON.stringify(error));
                this.showToastMessage('Error',JSON.stringify(error), 'error');
            });

        this.closeQuickAction();
        
        //this.template.querySelector('lightning-record-edit-form').submit(fields);
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
        this.showToastMessage('Success', 'Lead rejected successfully.', 'success');
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}