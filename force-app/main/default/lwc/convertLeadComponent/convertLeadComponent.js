import { LightningElement,api,track,wire } from 'lwc';
import convertLeadFromApex from '@salesforce/apex/UB_ConvertLeadController.convertLead';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import checkValidations from "@salesforce/apex/UB_ConvertLeadController.checkValidations";
export default class ConvertLeadComponent extends NavigationMixin(LightningElement) {   convertLeadComponent
    @track isSpinner = true;
    @api recordId;
    @track isValidation =false;
    @track validationMsg;
    @track isConfirmModel = false;
    @track isRecordId;  
             
        renderedCallback() {
            console.log('rendered------------');
            console.log(this.recordId + ' is provided');
            if(!this.isRecordId && this.recordId){
                this.isRecordId = true;
                this.callkValidations();
            }
        }
        callkValidations(){
            console.log('callkValidations----->>> :'+this.recordId);  
            checkValidations({ recordId: this.recordId })
                .then((result) => {
                    console.log('result === > ',result);
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
    

    /*@wire (checkValidations,{recordId: '$recordId'})
        wiredCheckValidations({data, error}){
            console.log('Data===========:'+data);
            if(data) {
                console.log('Data=1==========:'+data);
                this.isValidation = true;
                this.isConfirmModel = false;
                this.validationMsg = '<ul>'+data+'</ul>';;
            }else if(error) { 
                console.log('Data=2==========:'+data);
                console.log('Error:'+error);
                this.showToastMessage('Error', error, 'error');
            } else {
                this.isValidation = false;
                this.isConfirmModel = true;
                console.log('Data=3==========:'+data);
            }
        }*/

    yes() {
        console.log("Hi---------------- ",this.recordId);
        this.callConvertLeadFromApex();
        
    }
    
    no() {
        console.log("Hi no---------------- ",this.recordId);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    

    callConvertLeadFromApex(){
        console.log("Hi-in after invoke--------------- ",this.recordId);
        convertLeadFromApex({ leadId: this.recordId })
		.then(result => {
        if(result.startsWith('ERROR:')){
          this.ShowToastMessage('ERROR',result,'error');
        }
        else{
			      console.log("result===&&  ",result);
            this.isSpinner = false;
            this.ShowToastMessage('SUCCESS!!','Lead converted successfully..','success');
            if(result != null){
              this.navigateToRecord(result);
            }
          } 
		})
		.catch(error => {
            console.log("error===&&  ",error);
            this.isSpinner = false;
            this.ShowToastMessage('ERROR',error,'error');
			
		})
        
    }
    ShowToastMessage(title,message,variant) {
        const evt = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
        });
        this.dispatchEvent(evt);
      }
      navigateToRecord(recId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view'
            }
        });
  } 
}