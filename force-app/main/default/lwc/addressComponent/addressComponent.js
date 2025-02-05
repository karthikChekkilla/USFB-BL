import { LightningElement, wire, track, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ADDRESS_TYPE from '@salesforce/schema/Address__c.Address_Type__c';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import SAMPLEMC from "@salesforce/messageChannel/LMSChannel__c";
import { publish, MessageContext } from 'lightning/messageService';
import { RefreshEvent } from 'lightning/refresh';
import isCommunicationAddressExist from '@salesforce/apex/UB_AddressComponentController.isCommunicationAddressExist';
import isPermanentAddressIsSameAsResidence from '@salesforce/apex/UB_AddressComponentController.isPermanentAddressIsSameAsResidence';
import isAddressSameBL from '@salesforce/apex/UB_AddressComponentController.isAddressSameBL';
import getPinCodeDetails from '@salesforce/apex/UB_AddressComponentController.getPinCodeDetails';
import getParentRecordType from '@salesforce/apex/UB_AddressComponentController.getParentRecordType';
const FIELDS = ['Address__c.Sector_Localty__c', 'Address__c.Landmark__c', 'Address__c.Floor__c', 'Address__c.Name', 'Address__c.Customer__c', 'Address__c.Lead__c',
     'Address__c.Name', 'Address__c.Address_Line_2__c', 'Address__c.Address_Line_3__c', 'Address__c.Address_Type__c', 'Address__c.City__c', 'Address__c.Customer_Type__c', 
     'Address__c.Distance_of_Business_Premise_from_Branch__c', 'Address__c.Is_Communication__c', 'Address__c.Number_of_Years_in_Same_City__c', 'Address__c.Premise_Ownership__c',
      'Address__c.Principal_place_of_Business__c', 'Address__c.Pincode__r.Name', 'Address__c.BL_Residence_Type__c', 'Address__c.BL_PermanentAddressSameAsResidence__c'
      , 'Address__c.BL_Other_Residence_Type__c'
      ];

export default class AddressComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @api parentObjectId;
    @api parentObjectName;
    @track parentRecordTypeId;
    @track parentRecordTypeName;
    @track error;
    @track addressObj = {};
    @track addressTypeOptions;
    @track showSpinner = false;
    @track isShowModal = false;
    @track isLoading = false;
    @track isDisableSave = false;
    @track isCommunicationAddressExistOrNot = false;
    @track isPermanentAddressIsSameAsResidenceOrNot = false;
    @track blRecordType = false;
    @track addressTypeResidence = false;
    @track residenceTypeEnablity = false;
    @track otherStatus = false;
    @track notOfficeAdd = true;
    @track addressSame;
    @track BLResidenceType;
    @track addressType = '';
    @track otherResidenceType = false;

    connectedCallback() {
        this.fetchParentRecordType();
        this.isCommunicationAddressExistOrNot = false;
        this.isPermanentAddressIsSameAsResidenceOrNot = false;
        console.log('inaddressConnectedcallback');
        this.isShowModal = true;
        console.log('parentObjectId=> ', this.parentObjectId);
        console.log('parentObjectName=> ', this.parentObjectName);
        console.log('this.recordId=> ', this.recordId);

        /*if(this.parentObjectName == 'Account'){
            this.addressObj.Customer = this.parentObjectId;
            console.log('this.parentObjectId= ', this.parentObjectId);
        }*/if (this.parentObjectName == 'Lead__c') {
            this.addressObj.Lead = this.parentObjectId;
        } if (this.parentObjectName == 'Loan_Applicant__c') {
            this.addressObj.loanApplicant = this.parentObjectId;
        }/*if(this.parentObjectName == 'Customer__c'){
            this.addressObj.Customer = this.parentObjectId;
        }*/
        this.isPermanentAddressIsSameAsResidence();
        this.isAddressSameBL();
        this.isCommunicationAddressExist();
    }

    fetchParentRecordType() {
        getParentRecordType({ parentObjectId: this.parentObjectId, sObjectName :  this.parentObjectName})
            .then(result => {
                console.log('result>>',result);
                this.blRecordType = result;
            })
            .catch(error => {
                this.error = error;
                console.log('Error: ', error);
            });
    }

    isCommunicationAddressExist() {
        let recId = (this.addressObj.loanApplicant) ? this.addressObj.loanApplicant : this.addressObj.Lead;
        isCommunicationAddressExist({ objectName: this.parentObjectName, recordId: recId, addressId: this.recordId })
            .then(result => {
                console.log('result getRecord=> ', result);
                if (result && result != 0) {
                    this.isCommunicationAddressExistOrNot = true;
                }
            })
            .catch(error => {
                console.log('Error= ', error);
                console.log('Error= ', error.body.message);
            }).finally(() => {
                //this.showSpinner = false;
            });
    }

    isPermanentAddressIsSameAsResidence() {
        let recId = (this.addressObj.loanApplicant) ? this.addressObj.loanApplicant : this.addressObj.Lead;
        isPermanentAddressIsSameAsResidence({ objectName: this.parentObjectName, recordId: recId, addressId: this.recordId })
            .then(result => {
                console.log('result isPermanentAddressIsSameAsResidence=> ', result);
                if (result && result != 0) {
                    this.isPermanentAddressIsSameAsResidenceOrNot = true;
                    if(this.isPermanentAddressIsSameAsResidenceOrNot){
                        this.showToast('Warning', 'Permanent Address Same as Residence already exist', 'Warning');
                        this.isDisableSave = true;
                    }
                }
            })
            .catch(error => {
                console.log('Error= ', error);
                console.log('Error= ', error.body.message);
            }).finally(() => {
                //this.showSpinner = false;
            });
    }


    @wire(MessageContext)
    messageContext;

    publishMessage() {
        console.log('publishMessage', this.recordId);
        let message = { message: this.recordId };
        console.log('publishMessage1', message);
        publish(this.messageContext, SAMPLEMC, message);
    }

    @wire(getPicklistValues, { fieldApiName: ADDRESS_TYPE })
    wireGetPicklistValues({ error, data }) {
        if (error) {
            console.log('wireGetPicklistValues Error = ', error);
        } else if (data) {
            //this.addressTypeOptions = data.values;
            console.log('this.addressTypeOptions= ', data);
        }
    }



    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAddressRecord({ error, data }) {
        if (error) {
            console.error('wiredAddressRecord=> ', error);
        } if (data) {
            let address = data;
            console.log('Address= ', address);
            //console.log('Address= ', address.fields.City__c.value);

            this.addressObj.AddressLine1 = address.fields.Name && address.fields.Name.value ? address.fields.Name.value : '';
            this.addressObj.AddressLine2 = address.fields.Address_Line_2__c && address.fields.Address_Line_2__c.value ? address.fields.Address_Line_2__c.value : '';
            this.addressObj.AddressLine3 = address.fields.Address_Line_3__c && address.fields.Address_Line_3__c.value ? address.fields.Address_Line_3__c.value : '';
            this.addressObj.AddressNumber = address.fields.Name && address.fields.Name.value ? address.fields.Name.value : '';
            this.addressObj.AddressType = address.fields.Address_Type__c && address.fields.Address_Type__c.value ? address.fields.Address_Type__c.value : '';
            this.addressObj.City = address.fields.City__c && address.fields.City__c.value ? address.fields.City__c.value : '';
            this.addressObj.District = address.fields.District__c && address.fields.District__c.value ? address.fields.District__c.value : '';
            this.addressObj.State = address.fields.State__c && address.fields.State__c.value ? address.fields.State__c.value : '';
            this.addressObj.Floor = address.fields.Floor__c && address.fields.Floor__c.value ? address.fields.Floor__c.value : '';
            this.addressObj.Landmark = address.fields.Landmark__c && address.fields.Landmark__c.value ? address.fields.Landmark__c.value : '';
            this.addressObj.Sector = address.fields.Sector_Localty__c && address.fields.Sector_Localty__c.value ? address.fields.Sector_Localty__c.value : '';
            //this.addressObj.Country = address.fields.Country__c && address.fields.Country__c.value ? address.fields.Country__c.value : '';	
            this.addressObj.Country = 'India';
            this.addressObj.CustomerType = address.fields.Customer_Type__c && address.fields.Customer_Type__c.value ? address.fields.Customer_Type__c.value : '';
            this.addressObj.DistanceBranch = address.fields.Distance_of_Business_Premise_from_Branch__c && address.fields.Distance_of_Business_Premise_from_Branch__c.value ? address.fields.Distance_of_Business_Premise_from_Branch__c.value : '';
            this.addressObj.IsCommunication = address.fields.Is_Communication__c && address.fields.Is_Communication__c.value ? address.fields.Is_Communication__c.value : '';
            this.addressObj.NumberSameCity = address.fields.Number_of_Years_in_Same_City__c && address.fields.Number_of_Years_in_Same_City__c.value ? address.fields.Number_of_Years_in_Same_City__c.value : '';
            //this.addressObj.PinCode = address.fields.Pin_Code__c && address.fields.Pin_Code__c.value ? address.fields.Pin_Code__c.value : '';	
            this.addressObj.PremiseOwnership = address.fields.Premise_Ownership__c && address.fields.Premise_Ownership__c.value ? address.fields.Premise_Ownership__c.value : '';
            this.addressObj.PrincipalBusiness = address.fields.Principal_place_of_Business__c && address.fields.Principal_place_of_Business__c.value ? address.fields.Principal_place_of_Business__c.value : false;
            this.addressObj.PinCode = address.fields.Pincode__r.value.id &&address.fields.Pincode__r.value ?  address.fields.Pincode__r.value.id : '';
            this.addressObj.BLResidenceType  = address.fields.BL_Residence_Type__c && address.fields.BL_Residence_Type__c.value ? address.fields.BL_Residence_Type__c.value : ''; 
            this.addressObj.PermanentAddressSameAsResidence = address.fields.BL_PermanentAddressSameAsResidence__c && address.fields.BL_PermanentAddressSameAsResidence__c.value ? address.fields.BL_PermanentAddressSameAsResidence__c.value : '';
            //this.addressObj.BlResidenceType = address.fields.BL_PermanentAddressSameAsResidence__c && address.fields.BL_PermanentAddressSameAsResidence__c.value ? address.fields.BL_PermanentAddressSameAsResidence__c.value : '';
            //this.addressObj.PinCode = address.fields.Address_Type__c && address.fields.Address_Type__c.value ? address.fields.Address_Type__c.value : '';
            console.log('this.addressObj=> ', this.addressObj);
            this.addressObj.OtherResidenceType = address.fields.BL_Other_Residence_Type__c && address.fields.BL_Other_Residence_Type__c.value ? address.fields.BL_Other_Residence_Type__c.value : '';
            console.log('address.fields.PinCode__r.displayValue>>> ',address.fields.Pincode__r.value.id)
            console.log('this.addressObj.OtherResidenceType ',this.addressObj.OtherResidenceType);
            if (this.addressObj.BLResidenceType == 'Others') {
                if (this.addressObj.OtherResidenceType != '' || this.addressObj.OtherResidenceType != undefined) {
                    this.otherResidenceType = true;
                }
            }
            if(this.addressObj.PinCode && this.addressObj.PinCode != ''){
                this.getPinCodeDetails(this.addressObj.PinCode);
            }
            
            if(this.addressObj.AddressType == 'Office Address'){
                    this.residenceTypeEnablity = true;
                    this.BLResidenceType = '';
                    this.addressObj.PermanentAddressSameAsResidence = '';
            }
        }
    }

    handleCloseMethod() {
        console.log('handleCloseMethod1-> ');
        try {
            const selectedEvent1 = new CustomEvent('close', {
                detail: false
            });
            this.dispatchEvent(selectedEvent1);
            console.log('selectedEvent1-> ', selectedEvent1);
        } catch (err) {
            console.log('err-> ', err);
        }
        //this.isShowModal = false;
        //this.isLoading = false;
    }

    handleSuccess(event) {
        console.log('onsuccess event recordEditForm', event.detail.id);
        let msg = 'Address updated successfully.';
        this.showToast('Success', msg, 'success');
        this.isLoading = false;
        this.recordId = event.detail.id;
        setInterval(() => {
            window.location.reload();
        }, 1000);
        //this.handleCloseMethod();
    }

    handleSubmit(event) {
        this.isLoading = false;
        console.log('Called handleSubmit');
        event.preventDefault();
        const fields = event.detail.fields;
        console.log('Called fields', JSON.stringify(fields));
        console.log('this.addressType', this.addressType);
        if (this.isCommunicationAddressExistOrNot && fields["Is_Communication__c"] == 'Yes') {
            this.isLoading = false;
            this.showToast('Error', 'One Communication Address is Already Exist, Please Select \'Communication\' Field as \'No\'.', 'error');
        }else if (fields["Address_Type__c"] != 'Office Address' && this.blRecordType && this.isPermanentAddressIsSameAsResidenceOrNot && (fields["BL_PermanentAddressSameAsResidence__c"] == 'Yes' || fields["BL_PermanentAddressSameAsResidence__c"] == 'No')) {
            this.isLoading = false;
            this.showToast('Error', 'Permanent Address Same as Residence already exist', 'error');
        }else if (fields["Address_Type__c"] == 'Office Address' && this.blRecordType && this.isPermanentAddressIsSameAsResidenceOrNot && (fields["BL_PermanentAddressSameAsResidence__c"] == 'Yes')) {
            this.isLoading = false;
            this.showToast('Error', 'Permanent Address Same as Residence already exist', 'error');
        }else if(this.addressType == 'Office Address'  && ( (fields["BL_Residence_Type__c"] != '' && fields["BL_Residence_Type__c"] != null) || (fields["BL_PermanentAddressSameAsResidence__c"] != '' && fields["BL_PermanentAddressSameAsResidence__c"] != null) ) ){
            this.isLoading = false;
            this.showToast('Error', 'In the case of office address, Residence fields should not be present', 'error');
        }
        else {
            //this.isDisableSave = true;
            //this.isLoading = true;
            if(fields["BL_Residence_Type__c"] != 'Others'){
                fields["BL_Other_Residence_Type__c"] = '';
            }
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }

    }

    handleError(event) {


        console.log('err-->' + JSON.stringify(event.detail));
        console.log('err-->', event);
        if(event.detail.detail){
            this.showToast('Error', event.detail.detail, 'error');
        }
        
    }

    handleChange(event) {
        console.log('event.target.value-> ', event.target.name);
         console.log('event.target.value-> ', event);
        if (event.target.name == 'pincode') {
            console.log('event.target.value-> ', event.target.value);
            this.getPinCodeDetails(event.target.value);
        }
         if (event.target.name == 'underResidenceStatus') {
             if(event.detail.value == 'Others'){
           this.otherStatus = true;
             }else{
                 this.otherStatus = false;
             }

        }

    }

    getPinCodeDetails(pinCodeId) {
        getPinCodeDetails({ pinCodeId: pinCodeId })
            .then(result => {
                console.log('result getRecord=> 1 ', result);
                if (result && result.Id) {
                    if (result.City1__c) {
                        this.addressObj.City = (result.City1__c) ? result.City1__c : '';
                        if (result.District__c) {
                            this.addressObj.District = result.District__r.Name ? result.District__r.Name : '';
                            if (result.District__r.State_Name__c) {
                                this.addressObj.State = (result.District__r.State_Name__c) ? result.District__r.State_Name__c : '';
                                if (result.District__r.State__r.Country__c) {
                                    //this.addressObj.Country = (result.City__r.District__r.State__r.Country__r.Name) ? result.City__r.District__r.State__r.Country__r.Name : '';
                                }
                            }
                        }
                    }
                } else {
                    this.addressObj.City = '';
                    this.addressObj.State = '';
                    this.addressObj.Country = '';
                    this.addressObj.District = '';
                }
            })
            .catch(error => {
                console.log('Error= ', error);
                console.log('Error= ', error.body.message);
            }).finally(() => {
                //this.showSpinner = false;
            });
    }

    showToast(title, msg, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleAddressTypeChange(event) {
        console.log('event.target.value-in address> ', event.target.value);
        console.log('this.blRecordType>>> ',this.blRecordType);
        this.addressType = event.target.value;
        if(event.target.value == 'Office Address'){
            this.notOfficeAdd = false;
            if(this.isPermanentAddressIsSameAsResidenceOrNot){
                this.isDisableSave = false;
            }
            if(this.blRecordType){
                this.residenceTypeEnablity = true;
                this.addressObj.PermanentAddressSameAsResidence = '';
                this.addressObj.BLResidenceType = null;
                console.log(' this.addressObj.BLResidenceType>>> ', this.addressObj.BLResidenceType);
            }
        }else{
            this.residenceTypeEnablity = false;
        }
        var addressValue = event.target.value;
            if (addressValue == 'Residence Address') {
                this.addressTypeResidence = true;
            } else {
                this.addressTypeResidence = false;
            }
    }

    isAddressSameBL() {
        let recId = (this.addressObj.loanApplicant) ? this.addressObj.loanApplicant : this.addressObj.Lead;
        isAddressSameBL({ applicantORLeadId: recId })
            .then(result => {
                console.log('result isAddressSameBL=> ', result);
                if(result){
                    this.addressSame = result;               
                }
            })
            .catch(error => {
                console.log('Error= ', error);
                console.log('Error= ', error.body.message);
            }).finally(() => {
                //this.showSpinner = false;
            });
    }

    handleAddressCheckbox(event) {
        console.log('event.target.value-in handleAddressCheckbox> ', event.target.value);
        console.log(' this.addressSame >> ', this.addressSame )
        if(this.blRecordType){
            if(event.target.value == 'Yes' && this.addressSame == 'No'){
                this.isDisableSave = true;
                this.showToast('Error', 'Permananet address is already not same as residence. Please select No.', 'Error');
            }else{
                this.isDisableSave = false;
            }
        }
      
    }

    //added by lakshya on 30-09-2024 USFBL-399
    handleResidenceType(event){
        console.log('handleResidenceType-> ' , event.target.value);
        if(event.target.value == 'Others'){
            this.otherResidenceType = true;
        }else if(event.target.value != 'Others'){
            this.addressObj.OtherResidenceType = null;
            this.otherResidenceType = false;
        }
    }
}