import { api,wire,track,LightningElement } from 'lwc';
import {CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import generateLoanApplicationPDF from '@salesforce/apex/UB_VehicleEquipmentHelper.generateLoanApplicationPDF';
import legalityApiCall from '@salesforce/apex/UB_LeegalityApi.legalityApiCall';

export default class GenerateLoanApplicationForm extends NavigationMixin(LightningElement) {

    @api recordId;
    @track showSpinner ;


    handleSubmit() {
        this.showSpinner = true;
        console.log('this.recordId   '+this.recordId);
        generateLoanApplicationPDF({
            loanId: this.recordId,
        })
        .then(result =>{
            console.log('result   ',result);
            this.showSpinner = false;
            if(result == 'none') {
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: ' No Applicant found againts Application. ',
                        variant: 'error',
                        duration:' 20000',
                    })
                );
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Loan_Application__c',
                        actionName: 'view'
                   }
                },true);
            }
            else if(result == 'UB') {
               this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/CV_VehicleEquipment?Id=' + this.recordId
                }
            })
            }
             else if(result == 'BL') {
               this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/BL_LoanApplicationForm?Id=' + this.recordId
                }
            })
            }
        }).catch(error =>{
         console.log("errrrrrrrrrrrrrr",error);
        }); 

    }

    callLegalityApi() {
        this.showSpinner = true;
        console.log('LEGALILITY API CALL');

        legalityApiCall({
            loanApplicationId: this.recordId,
        })
        .then(result =>{
            console.log('result   ',result);
            this.showSpinner = false;
        }).catch(error =>{
         console.log("errrrrrrrrrrrrrr",error.message);
        }); 

    }

   /* @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference  ',currentPageReference);
            this.recordId = currentPageReference.state.recordId;
            console.log('Application Id  ',this.recordId);
        // calling  method to find Applicant has Applicant role or not
        generateLoanApplicationPDF({
            loanId: this.recordId,
        })
        .then(result =>{
            console.log('result   ',result);
            if(result == false) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: ' No Applicant found againts Application. ',
                        variant: 'error',
                        duration:' 20000',
                    })
                );
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Loan_Application__c',
                        actionName: 'view'
                   }
                },true);
            }
            else if(result == true) {
               this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/CV_VehicleEquipment?Id=' + this.recordId
                }
            })
            }
        }).catch(error =>{
          this.error = error;
         console.log("errrrrrrrrrrrrrr",this.error);
        }); 
        }
    } */


    handleSuccess() {
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }


}