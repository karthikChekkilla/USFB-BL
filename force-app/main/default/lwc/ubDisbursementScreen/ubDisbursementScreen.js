import { LightningElement, wire, track, api } from 'lwc';
import LightningAlert from 'lightning/alert';
import LightningConfirm from "lightning/confirm";
import getSelectedDisbursementRec from '@salesforce/apex/UB_DisbursementCltr.getSelectedDisbursementRec';
import sendSelectedDisRecToManager from '@salesforce/apex/UB_DisbursementCltr.sendSelectedDisRecToManager';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from "@salesforce/schema/Disbursement__c.Id";
import STATUS_FIELD from "@salesforce/schema/Disbursement__c.Loan_Offer_Review_Status__c";
import STATUS from "@salesforce/schema/Disbursement__c.Status__c";
import LOAN_APPLICATION_ID from "@salesforce/schema/Disbursement__c.Loan_Application__c";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import getPendingDibursements from '@salesforce/apex/UB_DisbursementCltr.getPendingDibursements';
import LOAN_AMT from "@salesforce/schema/Disbursement__c.Loan_Amount__c";
import TENURE from "@salesforce/schema/Disbursement__c.Tenure__c";
import ROI from "@salesforce/schema/Disbursement__c.ROI__c";
import PROCESS_FEE from "@salesforce/schema/Disbursement__c.Processing_Fee__c";
import INS_AMT from "@salesforce/schema/Disbursement__c.Insurance_Amount__c";
import IS_READONNLY from "@salesforce/schema/Disbursement__c.Is_Read_Only__c";
//import latestQuoteVerificationRecord from '@salesforce/apex/UB_Quote_API.latestQuoteVerificationRecord'; //Added by Umair on 24-07-2024

export default class UbDisbursementScreen extends LightningElement {
    @api loanApplicationId;  
    @api recordId;
    @track isChangeInput = false;
    @track disburseData = [];
    @track disburseData1 = {};
    @track disburseStatus = false;
    @track readonlyField = false
    isQuoteInitiated = false;

    fields = [LOAN_AMT, TENURE, ROI,PROCESS_FEE,INS_AMT];
    @track disbursementMsg = '';

    connectedCallback() {
        console.log('this.recordId ',this.recordId);
        if(this.recordId){
            //this.latestQuoteVerificationRecord();
        }
    }

    renderedCallback() {
        console.log('this.loanApplicationId renderedCallback',this.loanApplicationId);
        console.log('this.recordId renderedCallback',this.recordId);
    }

    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
            console.log('recordId->>>>>> ', this.recordId);
            
        }
    }
    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD, STATUS,LOAN_APPLICATION_ID,IS_READONNLY] })
    disbursementRecs({ error, data }) {
        if (error) {
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            this.readonlyField = data.fields.Is_Read_Only__c.value;
            console.log('this.readonlyField  ',this.readonlyField);
            if(data.fields.Loan_Application__c.value != null){
                this.loanApplicationId = data.fields.Loan_Application__c.value;
                console.log('loanApplicationId-> ', this.loanApplicationId);
            }if(data.fields.Status__c.value != null){
                //this.disburseStatus = data.fields.Status__c.value;
                if(data.fields.Status__c.value == 'Disbursed'){
                    this.showNotification('Warning', 'You cannot proceed the disburment once disbursed.', 'Warning');
                    this.disburseStatus = true;
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    
                    //this.getPendingDibursements();
                }
            }
        }
    }

    // Wire Method For Get Loan Applicant Records For Creating Tabs
    @wire(getSelectedDisbursementRec, {
        loanAppId : '$loanApplicationId',
        disburseId : '$recordId'
    })
    getSelectedDisbursementRec({error, data}){
        this.wiredApplicantResult = data;
        if(data){
            console.log('getSelectedDisbursementRec data-> ', data);
            this.disburseData = data;
            console.log('this.disburseData-> ', this.disburseData);
        }else if(error){
            console.error(' Error getSelectedDisbursementRec ', error.responseBody);
        }

    }

    

    handleSave(){
        if(this.isQuoteInitiated == false){
            this.showNotification('Error', 'Please kindly initiate Quote API First.', 'error');
        }else{
            this.getPendingDibursements();
        }
        
        
        console.log('handleSave ');
        console.log('this.isChangeInput inside handle save ' , this.isChangeInput);
        /*let loanAmount = this.template.querySelector(".loan-amount").value;
        let tenure = this.template.querySelector(".tenure").value;
        let roi = this.template.querySelector(".roi").value;
        let processingFee = this.template.querySelector(".processing-fee").value;
        let insAmount = this.template.querySelector(".insurance-amount").value;
        if(this.isChangeInput){
            //this.showError('Are you sure to change?','error','Error'); 
            this.disburseData1.Loan_Amount__c = loanAmount;
            this.disburseData1.Tenure__c = tenure;
            this.disburseData1.ROI__c = roi;
            this.disburseData1.Processing_Fee__c = processingFee;
            this.disburseData1.Insurance_Amount__c = insAmount;

            console.log('this.disburseData1-> ', JSON.stringify(this.disburseData1));
            this.handleConfirmClick();
            
            this.isChangeInput = false;
            
        }else{
           this.updateDisbursement();
        }*/
    }

    handleCancel(){
        console.log('handleCancel ');
        const selectedEvent = new CustomEvent('modalclick',  {
            detail : false
        });
        this.dispatchEvent(selectedEvent);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(){
        this.isChangeInput = true;
    }

    showError(message, theme,label){
        LightningAlert.open({
            message: message, 
            theme: theme,
            label: label,
        });
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    async handleConfirmClick() {
        console.log('inside handleConfirmClick');
        const result = await LightningConfirm.open({
        message: "Are you sure to change?",
        variant: "headerless",
        label: "Warning",
        }).then((result) => {
            console.log('handleConfirmClick Result: ', result);
            if(result){
                this.sendSelectedDisRecToManager();
            }
        })
    }

    handleSuccess(event){
       console.log('handleSuccess->');
    }

    handleSubmit(event){
        event.preventDefault();  
        const fields = event.detail.fields;
        console.log('fields->' , fields);
    }

    handleError(event){
         console.log('handleError err-->'+JSON.stringify(event.detail));
    }

    sendSelectedDisRecToManager() {
        console.log('inside sendSelectedDisRecToManager')
        sendSelectedDisRecToManager({recordId : this.recordId ,disburseData: this.disburseData1,
            loanAppId : this.loanApplicationId
        })
            .then(result => {
                console.log('result.sendSelectedDisRecToManager-> ' , JSON.stringify(result));
                if(result.isSuccess){
                    this.showNotification('Success', 'Disbursment has been sent for approval', 'success');
                    this.handleCancel();
                    //window.location.reload();
                }else{
                    this.showNotification('Error', result.responseBody, 'error');
                    this.handleCancel();
                }
            })
            .catch(error => {
                console.log('Error updateVerify= ', error);
                this.showNotification('Error', error, 'error');
            })
    }
    
    async updateDisbursement() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'No Approval Required';
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showNotification('Success', 'No Approval Required', 'success');
            this.handleCancel();
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showNotification('Error', error.body.output.errors[0].message, 'error');
           
        });
        
    }

    getPendingDibursements() {
        //this.showSpinner = true;
        console.log('this.loanApplicationId>> ' , this.loanApplicationId);
        getPendingDibursements({loanAppId : this.loanApplicationId
        })
            .then(result => {
                console.log('result.getPendingDibursements-> ' , result);
                if(result.isSuccess){
                      console.log('this.loanApplicationId>> ' , JSON.stringify(result));
                    //this.showSpinner = false;
                    this.disburseStatus = true;
                    if(result.loanOfferStatus.includes('Sent for Apporval')){
                         this.showNotification('Error', 'This Record has sent for Approval to Credit Manager ' + result.responseBody, 'error');
                    }else{
                         this.showNotification('Error', 'Please complete existing disbursment to proceed further ' + result.responseBody, 'error');
                    }
                    this.disbursementMsg = 'Please complete existing disbursment to proceed further '+result.responseBody;
                   
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    this.disburseStatus = false;

                    let loanAmount = this.template.querySelector(".loan-amount").value;
                    let tenure = this.template.querySelector(".tenure").value;
                    let roi = this.template.querySelector(".roi").value;
                    let processingFee = this.template.querySelector(".processing-fee").value;
                    let insAmount = this.template.querySelector(".insurance-amount").value;
                    if(this.isChangeInput){
                        //this.showError('Are you sure to change?','error','Error'); 
                        this.disburseData1.Loan_Amount__c = loanAmount;
                        this.disburseData1.Tenure__c = tenure;
                        this.disburseData1.ROI__c = roi;
                        this.disburseData1.Processing_Fee__c = processingFee;
                        this.disburseData1.Insurance_Amount__c = insAmount;

                        console.log('this.disburseData1-> ', JSON.stringify(this.disburseData1));
                        this.handleConfirmClick();
                        
                        this.isChangeInput = false;
                        
                    }else{
                        this.updateDisbursement();
                    }
                    
                    //this.showSpinner = false;
                    //this.loanOfferReview = true;
                    //this.showToastMsg('Error', result.responseBody, 'error');
                }
            })
            .catch(error => {
                console.log('Error updateVerify= ', error);
                this.showNotification('Error', error, 'error');
            })
    }

    //Added By Umair on 30th July 24
    /*latestQuoteVerificationRecord() {
        console.log('record id in latestQuoteVerificationRecord>>> ', this.recordId)
        latestQuoteVerificationRecord({ disbursementId: this.recordId })
            .then((result) => {
                console.log('RESULTTTTTT  latestQuoteVerificationRecord ', result);
                if (result) {
                    this.isQuoteInitiated = true;
                } else if (!result) {
                    this.isQuoteInitiated = false;
                    console.log('isQuoteInitiated false ')
                }
            }).catch((err) => {
                this.showSpinner = false;
                this.showNotification('Application Error', 'Kindly contact your admin!' + ' Error-' + err, 'Error');
                console.log('Error in latestQuoteVerificationRecord  ', err);
            });
    }*/
}