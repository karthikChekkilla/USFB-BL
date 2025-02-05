import { api,wire,track,LightningElement } from 'lwc';
import {CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import generateCam from '@salesforce/apex/CAM_PDFController.linkCamToDocument';


export default class UB_camGeneratePdf extends NavigationMixin(LightningElement) {


    @api recordId;
    @track showSpinner ;

    handleSubmit() {
        this.showSpinner = true;
        console.log('this.recordId   '+this.recordId);
        generateCam({
            loanId: this.recordId,
        })
        .then(result =>{
            console.log('result   ',result);
            this.showSpinner = false;
            console.log('redirect  ',this.recordId);

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/CV_CAM_PDF?Id=' + this.recordId
                }
            });
            this.showToastMsg('Success', 'CAM Report generate successfully', 'Success');

        }).catch(error =>{
         console.log("errrrrrrrrrrrrrr",error);
        }); 

    }


    showToastMsg(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title   : title,
                message : message,
                variant : variant,
                mode : "pester"
            })
        )
    }

    handleSuccess() {
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}