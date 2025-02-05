import { LightningElement, api, wire, track } from 'lwc';
import fetchFraudInfo from '@salesforce/apex/UB_CFR_API.fetchFraudDetails';

const columns = [
    { label: 'Fraud Case', fieldName: 'fraudCaseNumber', hideDefaultActions: true},
    { label: 'Perpetrator Name', fieldName: 'nameOfPerpetrator', hideDefaultActions: true},
    { label: 'Bank Name', fieldName: 'nameOfBank', wrapText:true, hideDefaultActions: true},
    { label: 'Reporting Date', fieldName: 'dateOfReporting', hideDefaultActions: true},
    { label: 'Account Address', fieldName: 'perpetratorOrAccountAddress', wrapText:true, hideDefaultActions: true},
    { label: 'Fraud Nature', fieldName: 'natureOfFraud', wrapText:true, hideDefaultActions: true},
    { label: 'Fraud Type', fieldName: 'typeOfFraud', wrapText:true, hideDefaultActions: true},
    { label: 'Amount Involved (In Lakhs)', fieldName: 'amountInvolvedRsInLakhs', hideDefaultActions: true},
    { label: 'Operation Area', fieldName: 'areaOfOperation', hideDefaultActions: true},
    { label: 'Perpetrator/Partner/Director Name', fieldName: 'perpetratorOrPartnerOrDirectorName', hideDefaultActions: true},
    { label: 'Perpetrator/Partner/Director Address', fieldName: 'perpetratorOrPartnerOrDirectorAddress', wrapText:true, hideDefaultActions: true},
    { label: 'Brief History', fieldName: 'briefHistoryAndOtherDevelopements', wrapText:true, hideDefaultActions: true},
    { label: 'Modus Operandi', fieldName: 'modusOperandi', wrapText:true, hideDefaultActions: true},
];

export default class UB_FraudInformation extends LightningElement {
    @api recordId
    @track fraudList;
    @track columns = columns;
    @track showFraudInfo = false;

    @wire(fetchFraudInfo, {verificationId : '$recordId'})
    fraudInfo(result) {
        if (result.data) {
            this.showFraudInfo = true;
            this.fraudList = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.showFraudInfo = false;
            this.error = result.error;
            this.fraudList = undefined;
        }
    }
}