import { LightningElement, wire, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import checkValidations from "@salesforce/apex/UB_LoanApplicationMoveToNextController.checkValidations";
import moveToNext from "@salesforce/apex/UB_LoanApplicationMoveToNextController.moveToNext";
import captureDecisionComment from "@salesforce/apex/UB_LoanApplicationMoveToNextController.captureDecisionComment";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import APPLICATION_STAGE from "@salesforce/schema/Loan_Application__c.Loan_Application_Stage__c";
    
    export default class LoanApplicationMoveToNext  extends NavigationMixin(LightningElement) {
        @api recordId;
        @track isConfirmModel = false;
        @track isValidation = false; 
        @track validationMsg;  
        @track isRecordId;
        @track isSpinner;  
        @track isMoveToNextModal = false;
        @track commentInputVisible = false;
        @track reason;
             
        renderedCallback() {
            if(!this.isRecordId && this.recordId){
                console.log('recordId=11==========:'+this.recordId);     
                this.isSpinner =true;
                this.isRecordId = true;
                this.callkValidations();

            }
        }
        connectedCallback(){
            console.log('recordId=00==========:'+this.recordId);    
            this.isMoveToNextModal = true;        
           
        }
        callkValidations(){ 
            checkValidations({ recordId: this.recordId,  buttonLabel : '' })
                .then((result) => {
                    console.log('result === > ',result);
                    if(result){
                        this.isValidation = true;
                        this.isConfirmModel = false;
                        this.validationMsg = '<ul>'+result+'</ul>';
                    }
                    else{
                        this.isValidation = false;
                        this.isConfirmModel = true;
                    }
                    this.isSpinner =false;                   
                })
                .catch((error) => {
                    console.log('Error:'+error);
                    console.log('Error:'+ JSON.stringify(error));
                    this.showToastMessage('Error', error, 'error');
                    this.isSpinner =false; 
                    
                });
         
        } 

         @wire(getRecord, { recordId: "$recordId", fields: [APPLICATION_STAGE] })
        disbursementRecs({ error, data }) {
            if (error) {
                console.log('error-> ', error);
            }else if (data) {
                if(data.fields.Loan_Application_Stage__c.value == 'Recommended for Approval'){
                    this.commentInputVisible = true;
                    console.log('commentInputVisible ',this.commentInputVisible);
                }
            }
        }    

        handleRemark(event) {
            console.log('recommendReason  ',event.target.value);
            this.reason = event.target.value;
            }
            checkValidation(){
            let inputElement = this.template.querySelectorAll('.requiredField');
            let isValid = true;
            inputElement.forEach(element => {
                let isValidOrNot = element.reportValidity();
                /*if(element.name == 'DocumentInput' && isValidOrNot && this.isFileSizeMoreThanMaxLimit){
                    element.setCustomValidity(this.fileSizeExceedErrorMsg);
                    isValidOrNot = element.reportValidity();
                }else if(element.name == 'DocumentInput' && !this.isFileSizeMoreThanMaxLimit){
                    element.setCustomValidity('');
                    isValidOrNot = element.reportValidity();
                }*/
                console.log('isValidOrNot ', isValidOrNot);
                if(!isValidOrNot && isValid){
                    isValid = isValidOrNot;
                }
            });
            return isValid;
        }       
        // Update lead
          updateLead() {
            if(this.checkValidation()){
                if(this.commentInputVisible){
                    this.captureDecisionComment();
                }
            this.isSpinner =true; 
              moveToNext({ recordId: this.recordId })
                .then((result) => {
                    console.log('result === > ',result);
                    if(result.startsWith('DDEMoved')){
                        let message  =result.split('::');
                        this.navigateToRecord();
                        this.showToastMessage('Success', 'Loan application moved to next stage '+message[1]+' successfully', 'success');
                        this.closeQuickAction();
                       

                    }

                    else if(result.startsWith('ERROR:')){
                        this.showToastMessage('ERROR',result,'error');
                      }
                    else if(result){
                        this.showToastMessage('Success', 'Loan application moved to next stage '+result+' successfully', 'success');
                        this.closeQuickAction();
                       
                       setTimeout(() => {
                        location.reload();
                       
                      }, "1000");
                     
                    }
                    else{
                        this.showToastMessage('Error', 'loan application moved to next stage not found', 'error');
                        this.closeQuickAction();
                    }
                    this.isSpinner =false; 
                })
                .catch((error) => {
                    console.log('error === > ',error);
                    console.log('error === --> ',JSON.stringify(error));
                    this.showToastMessage('Error', error.body.message, 'error');
                    this.isSpinner =false; 
                });
            }
        }

        // Method is used to update Decision Comment Field on Loan Application
        captureDecisionComment(){
            console.log('recordId@@ ',this.recordId);
            captureDecisionComment({recordId : this.recordId,comments:this.reason})
                    .then(result => {
                          console.log('result ',result);
                    })
                    .catch(error => {
                        console.log('Error@ ', error);
                        this.showNotification('Error', error, 'error');
                    })
        }
    
        // Close quick action popup
       closeQuickAction(event) {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.isSpinner =false; 
           this.isMoveToNextModal = false;
           if(event){
           event.preventDefault();
           }
           const selectedEvent = new CustomEvent("close", { detail: false });
           // Dispatches the event.
           this.dispatchEvent(selectedEvent);
        }
        // show toast message   
        showToastMessage(title, message, variant) {
            this.isSpinner =false; 
            this.dispatchEvent(
                new ShowToastEvent({
                    title: title,
                    message: message,
                    variant: variant,
                }),
            );
        }
        navigateToRecord() {      
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Loan_Application__c',
                    actionName: 'list'
                },
            });
         }
    }