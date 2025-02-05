import { LightningElement, wire, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import checkValidations2 from "@salesforce/apex/UB_LeadMoveToNextController.checkValidations";
import convertLeadFromApex from '@salesforce/apex/UB_LeadMoveToNextController.convertLead';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STAGE_FIELD from "@salesforce/schema/Lead__c.Lead_Stage__c";
const fields = [STAGE_FIELD];

export default class LeadMoveToNext  extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isConfirmModel = false;
    @track isValidation = false; 
    @track validationMsg;
    @track userProfileName;
    @track isSpinner = true;
    @track isRecordId1 = false; 
    @track isRecordId2 = false; 

     renderedCallback() {
        console.log('isRecordId1:::',this.isRecordId1);
        console.log('recordId:::',this.recordId);
        if(!this.isRecordId2 && this.recordId ){
            this.isRecordId2 = true;
            console.log('validationsCalled:::',this.recordId);
            this.callkValidations2();
        }
    }
    connectedCallback() {
        
    }
    callkValidations2(){
        this.isSpinner = true;
        console.log('===callkValidations2==='); 
         console.log('=this.recordId===', this.recordId);
        checkValidations2({ recordId: this.recordId })
            .then((result) => {
                console.log('result === > ',result);
                this.isSpinner = false;
                if(result){
                    this.isValidation = true;
                    this.isConfirmModel = false;
                    this.validationMsg = '<ul>'+result+'</ul>';;
                    
                }
                else{
                    this.isValidation = false;
                this.isConfirmModel = true;
                }
                
                
            })
            .catch((error) => {
                console.log('Error:'+error);
                this.showToastMessage('Error', error, 'error');
                
            });
         
        }    

    // Update lead
    updateLead(){
            this.isSpinner = true;
            console.log("callConvertLeadFromApex====",this.recordId);
             convertLeadFromApex({ leadId: this.recordId })
            .then(result => {
                this.closeQuickAction();
                this.isSpinner = false;
                console.log("result---->====",result);
                if(result.startsWith('ERROR:')){
                    this.showToastMessage('ERROR',result,'error');
                }
                else{
                    console.log("result===&&  ",result);
                    
                     
                    if(result != null){
                        
                         
                         if(!result.startsWith('SUCCESS')){
                            this.showToastMessage('SUCCESS!!','Lead converted successfully..','success');
                            this.navigateToRecord(result+'');
                         }
                         else{
                            this.showToastMessage('SUCCESS!!','Lead moved to next stage successfully..','success');
                        setTimeout(() => {
                            location.reload();
                        }, "1000");
                    }
                        
                          
                    }
                } 
            })
            .catch(error => {
                console.log("error===&&  ",JSON.stringify(error));
                console.log("error===&&  ",error);
                this.isSpinner = false;
                this.showToastMessage('ERROR',error,'error');
                
            })
            
    }


    
     navigateToRecord(recId) {
        console.log('---navigateToRecord---', recId);
  
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recId,
                    actionName: 'view'
                }
            });
    
       

        
     }
    // Close quick action popup
   closeQuickAction() {
   
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    // show toast message   
    showToastMessage(title, message, variant) {
        this.isSpinner = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
}