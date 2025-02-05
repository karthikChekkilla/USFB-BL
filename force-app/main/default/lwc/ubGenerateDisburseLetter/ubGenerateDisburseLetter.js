import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import disburmentDocumentGenerate from '@salesforce/apex/UB_DisbursementCltr.disburmentDocumentGenerate';
import updateDisbursementAndEMIDate from '@salesforce/apex/UB_RepaymentSchedule.updateDisbursementAndEMIDate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from "lightning/uiRecordApi";
import STATUS_FIELD from "@salesforce/schema/Disbursement__c.Loan_Offer_Review_Status__c";
import STATUS from "@salesforce/schema/Disbursement__c.Status__c";
import LOAN_APPLICATION_ID from "@salesforce/schema/Disbursement__c.Loan_Application__c";
import FIRST_EMI_DATE from "@salesforce/schema/Disbursement__c.First_EMI_Date__c";
import IS_REPAYMENT_SCHEDULE from "@salesforce/schema/Disbursement__c.isRepaymentSchedule__c";
import IS_SANCTIONLETTER_GENERATED from "@salesforce/schema/Disbursement__c.Is_Sanction_Letter_Generated__c";
import IS_MEMO_GENERATED from "@salesforce/schema/Disbursement__c.IsMemoCompleted__c";
import getPendingDibursements from '@salesforce/apex/UB_DisbursementCltr.getPendingDibursements';
import latestPartnerVerificationRecord from '@salesforce/apex/UB_DisbursementCltr.latestPartnerVerificationRecord'; //Added by Umair on 29-07-2024

export default class UbGenerateDisburseLetter extends NavigationMixin(LightningElement) {
    @api loanApplicationId;
    @api recordId;
    @track showSpinner = false;
    @track disburseStatus = false;
    @track firstEMI_date;
    isQuoteAPICalled = false;
    @track isRepaymentScheduleDone = false;
    @track isSantionLettterGenerated = false;
    @track isMemoCompleted = false;
    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('recordId-> ', this.recordId);
            
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD, STATUS,LOAN_APPLICATION_ID, FIRST_EMI_DATE,IS_REPAYMENT_SCHEDULE, IS_SANCTIONLETTER_GENERATED, IS_MEMO_GENERATED] })
    disbursementRecs({ error, data }) {
        this.latestPartnerVerificationRecord();
        if (error) {
            console.log('OUTPUT : error');
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            if(data.fields.Loan_Application__c.value != null){
                this.loanApplicationId = data.fields.Loan_Application__c.value;
                this.firstEMI_date = data.fields.First_EMI_Date__c.value;
                console.log('firstEMI_date@@ ',this.firstEMI_date);
                console.log('loanApplicationId-> ', this.loanApplicationId);
    
            }if(data.fields.Status__c.value != null){
                //this.disburseStatus = data.fields.Status__c.value;
                if(data.fields.Status__c.value == 'Disbursed'){
                    //this.showNotification('Warning', 'You cannot proceed the disburment once disbursed.', 'Warning');
                    this.disburseStatus = true;
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                   // this.getPendingDibursements();
                   this.disburseStatus = false;
                }
            }if(! data.fields.isRepaymentSchedule__c.value){
                this.isRepaymentScheduleDone = true;
                   // this.showNotification('Warning', 'Kindly Generate the Repayment Schedule', 'Warning');
            }
            if(data.fields.Is_Sanction_Letter_Generated__c.value){
                this.isSantionLettterGenerated = true;
            }
            if(data.fields.IsMemoCompleted__c.value){
                this.isMemoCompleted = true;
            }
        }
    }

    @api invoke() {
        //console.log('this.loanApplicationId ',this.loanApplicationId);
        //console.log('this.recordId ',this.recordId);
        //setTimeout(() => {
            //console.log('this.isQuoteAPICalled>> '+this.isQuoteAPICalled)
           /* if(this.isQuoteAPICalled == false){
                this.showNotification('Error', 'Kindly Initiate Book Insurance API First.', 'Error');
            }
            if(this.isRepaymentScheduleDone){
                this.showNotification('Error', 'Kindly Generate the Repayment Schedule', 'Error');
            }
            else */ 
            /*if(!this.firstEMI_date){
                console.log('repayment@@ ');
                this.handleRepaymentSchedulePDF();
            }else{
                console.log('sanction@@ ');
                this.handleSanctionPDF();
            }*/
        //}, 2000);
        console.log('isSantionLettterGenerated@@ ',this.isSantionLettterGenerated);
        if(this.firstEMI_date && !this.isSantionLettterGenerated && this.isMemoCompleted){
            console.log('sanction@@ ');
            this.handleSanctionPDF();
        }else if(!this.isMemoCompleted && !this.isSantionLettterGenerated){
            this.showNotification('Error', 'Please complete the Disbursment Memo process before sanction letter generation', 'error');  
        }else if(this.isSantionLettterGenerated){
            console.log('isSantionLettterGenerated ',this.isSantionLettterGenerated);
            this.showNotification('Error', 'Sanction PDF is already generated', 'error');  
        }
        else if(!this.firstEMI_date){
            this.showNotification('Error', 'Complete Repayment Schedule process before Sanction Letter', 'error');  
        }
       
    }

    handleSanctionPDF(event){
        this.disburmentDocumentGenerate(this.loanApplicationId,'Sanction Letter PDF','',this.recordId);
        let url = '/apex/CV_SanctionLetter?Id='+this.recordId;
        window.open(url,'_blank');
    }

    // handleRepaymentSchedulePDF(){
    //     this.updateDisbursementAndEMIDate();
    //     this.disburmentDocumentGenerate(this.loanApplicationId,'','Repayment Schedule PDF',this.recordId);
    //     let url = '/apex/UB_RepaymentSchedulePDF?Id='+this.recordId;
    //     window.open(url,'_blank');   
    // }

    handleSave(){
       // this.disburmentDocumentGenerate();
    }

    handleCancel(){
        console.log('handleCancel ');
        const selectedEvent = new CustomEvent('modalclick',  {
            detail : false
        });
        this.dispatchEvent(selectedEvent);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    disburmentDocumentGenerate(lafId, sanctionLetter, repaymentLetter, disburseId) {
        // this.showSpinner = true;
        console.log('lafId ', lafId);
        console.log('sanctionLetter ', sanctionLetter);
        console.log('repaymentLetter ', repaymentLetter);
        console.log('disburseId ', disburseId);
        disburmentDocumentGenerate({LAFId : lafId ,sanctionLetter : sanctionLetter, 
        repaymentLetter : repaymentLetter, disbursementId : disburseId

        })
            .then(result => {
                console.log('result.disburmentDocumentGenerate-> ' , result);
                if(result.isSuccess){
                    this.showNotification('Success', 'Letters has been generated successfully', 'success');
                    // this.showSpinner = false;
                     this.handleCancel();
                     //if(repaymentLetter != ''){
                        setInterval(() => {
                            window.location.reload();
                        }, 500);
                     //}
                }else{
                    this.showNotification('Error', result.responseBody, 'error');
                }
            })
            .catch(error => {
                console.log('Error updateVerify= ', error);
                this.showNotification('Error', error, 'error');
            })
    }

    // updateDisbursementAndEMIDate(){
    //     updateDisbursementAndEMIDate({recordId : this.recordId
    //         })
    //             .then(result => {
    //                 //this.showNotification('Success', 'EMI Date updated Successfully', 'success');
    //             })
    //             .catch(error => {
    //                 console.log('Error@ ', error);
    //                 this.showNotification('Error', error, 'error');
    //             })
    // }
    
    //Method Added by Umair on 29th July 24
    latestPartnerVerificationRecord() {
        latestPartnerVerificationRecord({ disbursementId: this.recordId })
            .then((result) => {
                console.log('RESULTTTTTT  latestPartnerVerificationRecord ', result);
                if (result) {
                    this.isQuoteAPICalled = true;
                    //this.showNotification('Error', 'Kindly Call Quote API First.', 'Error');
                } else if (!result) {
                    this.isQuoteAPICalled = false;
                    console.log('isDisabledHQ true ')
                }
            }).catch((err) => {
                this.showSpinner = false;
                //this.showNotification('Application Error', 'Kindly contact your admin!' + ' Error-' + err, 'Error');
                console.log('Error in latestPartnerVerificationRecord  ', err);
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

    getPendingDibursements() {
        //this.showSpinner = true;
        getPendingDibursements({loanAppId : this.loanApplicationId
        })
            .then(result => {
                console.log('result.getPendingDibursements-> ' , result);
                if(result.isSuccess){
                    //this.showSpinner = false;
                    this.disburseStatus = true;
                    this.showNotification('Error', 'Please complete existing disbursment to proceed further ' + result.responseBody, 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    this.disburseStatus = false;
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
}