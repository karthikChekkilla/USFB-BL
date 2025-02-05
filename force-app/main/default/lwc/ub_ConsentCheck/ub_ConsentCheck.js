import { LightningElement,api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import checkCustomerConsent from '@salesforce/apex/UB_ConsentValueFirstApi.checkCustomerConsent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Ub_ConsentCheck extends LightningElement {

    @api recordId;
    showSpinner = false;

    @wire(CurrentPageReference)
    getLeadId(currentPageReference) {
        console.log('currentPageReference   ',currentPageReference);
        
        if (currentPageReference) {
            if(currentPageReference.type == 'standard__recordPage') {
                this.recordId = currentPageReference.attributes.recordId;
            } else {
                this.recordId = currentPageReference.state.recordId;

            }
            console.log('record id  ',this.recordId);
            
            this.callConsentApi();
        }
    }

    callConsentApi(){
        this.showSpinner = true;
        checkCustomerConsent({'leadId' :this.recordId})
        .then((data => {
            if (data != null && data.includes('success')) {
                this.showToastMsg('success', 'Consent Triggered Successfully.' , 'success');
                this.showSpinner = false;
                this.closeQuickAction();
            } else {
                this.showToastMsg('error', data , 'error');
                this.showSpinner = false;
                this.closeQuickAction();
            }
        })).catch((err) => {
            console.log('Error in returnRelatedRecords = ', err.message);
        });
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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

}