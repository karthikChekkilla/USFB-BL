import { LightningElement, wire, api } from 'lwc';
import getData from '@salesforce/apex/UB_CommonUtil.getData';


export default class UB_Error_Message extends LightningElement {

    @api recordId;
    isMessageShow = false;
    loanStatus;
    rejectReason;


 connectedCallback(){

    console.log('RECORD IDDDDDDD  ', this.recordId);
    console.log('loanStatus   ',this.loanStatus);
    getData

    getData({ loanId: this.recordId })
    .then((result) => {
 
        console.log('RESULTTTTT  ',result);
        if(result.Loan_Application_Status__c == 'Rejected' && (result.Reject_Sub_Reason__c == 'Duplicate Record'|| result.Reject_Sub_Reason__c == 'Duplicate record rejected within 60 days')) {
            this.isMessageShow = true;
        }
        console.log('this.isMessageShow  ',this.isMessageShow);
    }).catch((err) => {
        this.showSpinner = false;
        console.log('Error in returnRelatedRecords = ', err);
    });
 }
}