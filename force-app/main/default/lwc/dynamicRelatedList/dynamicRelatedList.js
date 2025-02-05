import { LightningElement, api, track, wire } from 'lwc';
import returnRelatedRecords from '@salesforce/apex/UB_DynamicRelatedListCtrl.returnRelatedRecords';
//import getFilterRecords from '@salesforce/apex/UB_DynamicRelatedListCtrl.getFilterRecords';
//import getOppRecord from '@salesforce/apex/UB_DynamicRelatedListCtrl.getOppRecord';
//import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//import { CurrentPageReference } from 'lightning/navigation';
import { deleteRecord, updateRecord, getFieldValue, getRecord } from 'lightning/uiRecordApi';
import SAMPLEMC from "@salesforce/messageChannel/LMSChannel__c";
import { subscribe, MessageContext } from 'lightning/messageService';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import verifyAPI_Details from '@salesforce/apex/UB_HTTPCalloutService.validateAccessToken'; //Added by Mohit Saxena on 1st April 2024
import callENachAPI from '@salesforce/apex/UB_HTTPCalloutService.callENachAPI'; //Added by Mohd Musab on 01-07-2024
import fetchVerificationId from '@salesforce/apex/UB_CommonUtil.fetchVerificationId'; //Added by Mohit Saxena on 3rd April 2024
//import checkPanAndAadharVerify from '@salesforce/apex/UB_DynamicRelatedListCtrl.checkPanAndAadharVerify';
import getVehicleAssessmentDetails from '@salesforce/apex/UB_CommonUtil.getVehicleAssessmentDetails'; //Added by Zafaruddin on 3rd April 2024
import financialsCalculationProductValidation from '@salesforce/apex/UB_CommonUtil.financialsCalculationProductValidation'; //Added by Mohit Saxena on 3rd April 2024
import updateDocumentStatus from '@salesforce/apex/UB_DisplayUBDocumentsController.updateDocumentStatus';
const rowAction = [];
import getLoanApplicantRecords from '@salesforce/apex/UB_DisplayUBDocumentsController.getLoanApplicantRecords';
import getValuationDetail from '@salesforce/apex/UB_Valuationdetails.getValuationDetail';
import fetchAadhaarMaskedUID from '@salesforce/apex/UB_Aadhaar_API.aadhaarNumberMasking';
import initiateTransaction from '@salesforce/apex/UB_Perfios_API.initiateTransaction';
import sendAadhaarOTP from '@salesforce/apex/UB_Aadhaar_API.sendAadhaarOTP';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';//Added by Mohit on 28th May 2024
import VEHICLE_OBJECT from "@salesforce/schema/Vehicle__c";//Added by Mohit on 28th May 2024
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import UserRoleName from '@salesforce/schema/User.UserRole.Name';
import READ_ONLY from "@salesforce/schema/Loan_Application__c.IsReadOnly__c";
import getPendingDibursements from '@salesforce/apex/UB_DisbursementCltr.getPendingDibursements';
import APPLICANT_ID_FIELD from "@salesforce/schema/Loan_Applicant__c.Id";
import APPLICANT_IS_DELETED from "@salesforce/schema/Loan_Applicant__c.Is_Deleted__c";
import RCU_WAIVED from "@salesforce/schema/Loan_Application__c.BL_RCU_Waived__c";
import LOAN_APPLICATION_ID from "@salesforce/schema/Loan_Application__c.Id";
import FI_WAIVED from "@salesforce/schema/Loan_Applicant__c.Waive_FI__c";
import isAcitivityRecordExist from '@salesforce/apex/BL_DynamicRelatedListCtrl.getAcitivityRecord';
import isAddressRecord from '@salesforce/apex/BL_DynamicRelatedListCtrl.getAddressRecord';
import LOB_FIELD from "@salesforce/schema/Loan_Application__c.LOB__c";
import permanentAddressSameCheck from '@salesforce/apex/BL_DynamicRelatedListCtrl.permanentAddressSameCheck';
import IS_REVOKED from "@salesforce/schema/Valuation__c.Is_Revoked__c";
import VALUATION_ID from "@salesforce/schema/Valuation__c.Id";
import rcuWaiveActivityByManager from '@salesforce/apex/BL_RCUController.rcuWaiveActivityByManager';
const fields = [READ_ONLY];
export default class DynamicRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api callingApi;
    @track addressId;
    @api objectApiName;
    @api metadataName;
    @api userQuery;
    @api title;
    @api queryParameters;
    @track relatedRecords;
    @track modelTitle;
    @track showSpinner;
    @track rowAction = rowAction;
    @track isShowAddress = false;
    @track showDocumentModal = false;
    @track showNewButton;
    @track childRecordId;
    @track actionName = '';
    @track showModal = false;
    @track loanApplicantList = [];
    @track isRecordFound = true;
    @track currentTabApplicantId = '';
    @track isreadonly = false;
    @track defaultValues = [];
    @track inputVariables = [];
    @track productCategory = '';

    @track vendorInputVariables = [];
    @track isVendorCall = false;
    @track flowApiName = '';
    @track showAadhaarScreen = false;
    @track showPerfiosFileUpload = false;
    @track uploadedFiles;
    @track aadhaarNumber = '';
    @track password = '';
    @track vehicleId;
    showVehicleScreen = false;
    showProductScreen = false;
    showScreenFlow = false;
    vehicleRecordType = [];
    vehicleRecordTypeId;
    @track selectedRows;
    submitDecision = false;
    userRoleName;
    userProfileName;
    showSubmitButton = false;
    @track isReadOnly = false ;

    @track loanOfferReview = false;
    @track generateLetter = false;
    activityAlreadyExist = false;
    @track applicationLob = '';
    addressType = '';

    @track showPreviewModal = false;

    @wire(getRecord, { recordId: "$recordId", fields: [LOB_FIELD] })
    getApplications({ error, data }) {
        if (error) {
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            if(data.fields.LOB__c.value != null){
                this.applicationLob = data.fields.LOB__c.value;
                console.log('loanApplicationId-> ', this.applicationLob);
            }
        }
    }


    @wire(getRecord, { recordId: "$recordId", fields })
    loanApplication;

    get readOnly() {
        console.log('readOnly-> ', getFieldValue(this.loanApplication.data, READ_ONLY));
        return getFieldValue(this.loanApplication.data, READ_ONLY);
    }

    get cssClass(){
        console.log('width :',window.innerWidth);
        return window.innerWidth < 493 ? '' : 'slds-float_right';
    }

    // For Hide & Show Opportunity Component
    get showForOpportunityObject(){
        return (this.objectApiName == 'Loan_Application__c') ? true : false;
    }
     
     // To accept the format of document for Perfios 
     // added by Chandan on 02-07-2024
     get acceptedFormats() {
        return ['.pdf'];
    }
    
     // To handle the document for Perfios 
     // added by Chandan on 02-07-2024
    handleUploadFinished(event) {
        // Get the list of uploaded files
          this.uploadedFiles = event.detail.files;
          console.log('OUTPUT : ',this.uploadedFiles);
      //  alert('No. of files uploaded : ' + uploadedFiles.length);
    }
    connectedCallback() {
        this.showSpinner = true;
        console.log('callingApi   ',this.callingApi);
        console.log('metadataNamev   ',this.metadataName);
        console.log('query   ',this.userQuery);
        console.log('this.objectApiName   ',this.objectApiName);
        console.log('this.recordId   ',this.recordId);
        if(this.objectApiName == 'Lead__c'){
            this.showNewButton = true;
        }
        //console.log('parentObjectName=> ', this.recordId);
        //console.log('this.recordId=> ', this.recordId);
        this.getRelatedRecords();
        this.handleSubscribe();
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName, UserRoleName] })
    userDetails({ error, data }) {
        console.log('inside wire>> ');
        if (error) {
            this.error = error;
            console.log('inside error>> ',error);

        }else if (data) {
            console.log('inside data>> ',data);

            if (data.fields.Profile.value != null) {
                this.userProfileName  = data.fields.Profile.value.fields.Name.value;
                if(data.fields.UserRole.value != null){
                    this.userRoleName = data.fields.UserRole.value.fields.Name.value;
                }
                if( this.userProfileName == 'System Administrator' || this.userRoleName == 'National Credit Manager' || this.userRoleName == 'Regional Credit Manager' || 
                    this.userRoleName == 'Credit Head' || this.userRoleName == 'Zonal Credit Manager' || this.userRoleName == 'BL Branch Credit Manager'
                ){
                    this.showSubmitButton = true;
                }
                console.log('this.userProfileName ', this.userProfileName);
                console.log('this.userRoleName ', this.userRoleName);
            }
        }
    }

    //Added by Mohit on 28th May 2024- Starts
    /*@Descriptor : Need to pass Vehicle Record Type Id based on Product category Selection */ 
    @wire(getObjectInfo, { objectApiName: VEHICLE_OBJECT })
    function({error,data}){
        if(data){
            this.vehicleRecordType = data.recordTypeInfos;
        }else if(error){
            console.log(JSON.stringify(error))
           // perform your logic related to error 
        }
    };
    //Added by Mohit on 28th May 2024- Ends

    handleActiveTab(event){
        this.currentTabApplicantId = event.target.dataset.id;
        console.log('this.currentTabApplicantId-> ', this.currentTabApplicantId);
    }

    handleClose(event){
        this.showDocumentModal = false;
        //console.log('event', event.detail);
        this.loanOfferReview = false;
        this.generateLetter = false;
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCloseDisbursement(event){
        this.loanOfferReview = event.detail;
        this.generateLetter = event.detail;
    }

    handleStatusChange(event){
        if (event.detail.status === 'FINISHED') {
            this.showDocumentModal = false;
            this.showToastMsg('Success', 'Document Created Successfully', 'Success');
            if(this.objectApiName == 'Loan_Application__c'){
                //this.template.querySelector("c-display-u-b-document-details").getApplicationDocuments();
                window.location.reload();
            }if(this.objectApiName == 'Lead__c'){
                //this.template.querySelector("c-display-u-b-document-details").getLeadDocuments();
            }
        }
    }

    // Open New Record Creation Page.
    handleClick(event) {
        if(this.metadataName == 'Document_Information'){
            this.showDocumentModal = true;
            if(this.objectApiName == 'Loan_Application__c'){
                this.defaultValues['Loan_Application__c'] = this.recordId;
                this.inputVariables = [
                        {
                            name: 'recordId',
                            type: 'String',
                            value: this.recordId
                        },
                        {
                            name: 'applicantId',
                            type: 'String',
                            value: this.currentTabApplicantId
                        },
                        {
                            name: 'objectApiName',
                            type: 'String',
                            value: this.objectApiName
                        }
                ];
            }if(this.objectApiName == 'Lead__c'){
                this.defaultValues['Lead__c'] = this.recordId;
                this.inputVariables = [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    },
                    {
                        name: 'applicantId',
                        type: 'String',
                        value: this.currentTabApplicantId
                    },
                    {
                        name: 'objectApiName',
                        type: 'String',
                        value: this.objectApiName
                    }
            ];
         }
        }if(this.metadataName == 'Address' || this.metadataName == 'AddressBL'){
            this.isShowAddress = true;
        }
    }

    // Wire Method For Get Loan Applicant Records For Creating Tabs
    @wire(getLoanApplicantRecords, {
        applicationId : '$recordId'
    })
    wireGetLoanApplicantRecords({error, data}){
        this.wiredApplicantResult = data;
        if(data){
            this.isRecordFound = true;
            if(data.isSuccess){
                let tempList = JSON.parse(data.responseBody);
                console.log('wireGetLoanApplicantRecords=> ', tempList);
                //console.log('wireGetLoanApplicantRecords=> ', data.responseBody);
                this.loanApplicantList.push({Name: 'Application', Id: ''});
                tempList.forEach(element => {
                    this.loanApplicantList.push(element);
                });
                console.log('this.loanApplicantList=> ', this.loanApplicantList);
                //this.loanApplicantList = JSON.parse(data.responseBody);
            }else{
                this.isRecordFound = false;
                //this.loanApplicantList.push({Name: 'Application', Id: '', DocumentType: ''});
                console.log('else wireGetLoanApplicantRecords Data-> ',data);
            }
        }else if(error){
            console.error(' Error wireGetLoanApplicantRecords ', error.responseBody);
        }

    }

    @wire(MessageContext)
    messageContext;

    handleSubscribe() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.messageContext, SAMPLEMC, (message) => {
            console.log(message.message);
            this.showSpinner = true;
            this.getRelatedRecords();
        });
    }

    @api getRelatedRecords(){
        this.relatedRecords = undefined;

        returnRelatedRecords({ applicationId: this.recordId, metadataName: this.metadataName, query: this.userQuery /*'Lead__c IN : IDS_SET'*/, queryParameters: this.queryParameters })
        .then((result) => {
            this.showSpinner = false;
            this.relatedRecords = JSON.parse(JSON.stringify(result));
            console.log('Result 2 in returnRelatedRecords = ', JSON.stringify(this.relatedRecords));
            console.log('Result 2 in returnRelatedRecords = ', this.relatedRecords);
            this.objectAPIName = result.objectAPIName;
            this.modelTitle = result.label;
        }).catch((err) => {
            this.showSpinner = false;
            console.log('Error in returnRelatedRecords = ', err);
        });
    }
    

    handleTableSelection(evt) {
        this.showVehicleScreen = false;
        this.showProductScreen = false;
        this.showSpinner = true;
        var data = evt.detail;
        console.log('data-> ', JSON.stringify(data));
        //this.isShowAddress = false;     
        this.childRecordId = data.recordData.id;   
        console.log('this.childRecordId ', this.childRecordId);
        console.log('this.callingApi  ',this.callingApi);
        console.log('this.metadataName  ',this.metadataName);
        console.log('ActionName  ',data.ActionName);
        this.actionName = data.ActionName;

        //added by lakshya verma USFBL-454 on 30-sept
        if(this.metadataName == 'Documents_Child' ){
            if(this.actionName == 'View'){
                console.log('Documents_Child this.childRecordId ', this.childRecordId);
                this.showSpinner = false;
                this.showPreviewModal = true;
            }
        }

        if(this.metadataName == 'InactiveApplicants'){
            if(this.actionName == 'Active'){
                this.updateApplicantStatus(data.recordData.id,'No');
                window.setTimeout(() => {
                    this.getRelatedRecords();
                }, 3000);
            }
        }

        if(this.metadataName == 'Disbursement'){
            this.showSpinner = false;
            if(this.actionName == 'Loan Offer Review Requested'){
                if(data.recordData.Status__c == 'Disbursed'){
                    this.showToastMsg('Warning', 'You cannot proceed the disburment once disbursed.', 'Warning');
                }else{
                    this.getPendingDibursements();
                }
            }else if(this.actionName == 'Generate Sanction Letter'){
                if(data.recordData.Status__c == 'Disbursed'){
                    this.showToastMsg('Warning', 'You cannot proceed the disburment once disbursed.', 'Warning');
                }else{
                     this.generateLetter = true;
                }
            }else if(this.actionName == 'Pre-Disbursal Documents'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.childRecordId,
                        objectApiName: 'Disbursement__c',
                        actionName: 'view'
                    },
                });
            }
            console.log('this.actionName-> ', this.actionName);
        }

        if(data.ActionName == 'Edit'){
            this.showSpinner = false;
           if(this.metadataName == 'Applicants' || this.metadataName == 'CoApplicant' || this.metadataName == 'Guarantor'){
                const selectedEvent = new CustomEvent('action',  {
                    //detail : true
                    detail: {
                            customerId: data.recordData.id,
                            model: true
                        }
                });
                this.dispatchEvent(selectedEvent);
                return ;
            }
            if (this.metadataName == 'Address' || this.metadataName == 'AddressBL') {
                this.showSpinner = false;
                this.addressId = data.recordData.id;
                //console.log('this.addressId', this.addressId);
                //console.log('recordId', this.recordId);
                //console.log('recordName', this.objectApiName);
                this.isShowAddress = true;

                const selectedEvent = new CustomEvent('action',  {
                    //detail : true
                    detail: {
                            customerId: data.recordData.id,
                            model: true
                        }
                });
                this.dispatchEvent(selectedEvent);
                return ;
            }
            
            if(this.metadataName == 'Product_Records' || this.metadataName == 'BL_Product_Records'){
                this.showProductScreen = true;
            }
            if(this.metadataName == 'Personal_Discussion'){
                this.flowApiName = 'UB_Personal_Discussion_Form';
                this.inputVariables = [];
                this.inputVariables = [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.childRecordId
                    },
                    {
                        name: 'loanApplicationId',
                        type: 'String',
                        value: this.recordId
                    }
                ]
                this.showScreenFlow = true;
            }
            if (this.metadataName == 'Balance_Transfers') {
                this.flowApiName = 'BL_Balance_Transfer_Creation';
                this.inputVariables = [];
                this.inputVariables = [
                    {
                        name: 'loanApplicationID',
                        type: 'String',
                        value: this.recordId
                    },
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.childRecordId
                    }
                ]
                this.showScreenFlow = true;
            }
            if(this.metadataName == 'Sanction_Conditions'){
                this.flowApiName = 'UB_Create_Sanction_Condition_Record';
                this.inputVariables = [];
                this.inputVariables = [
                    {
                        name: 'sanctionConditionRecordId',
                        type: 'String',
                        value: this.childRecordId
                    },
                    {
                        name: 'loanApplicationId',
                        type: 'String',
                        value: this.recordId
                    }
                ]
                this.showScreenFlow = true;
            }
            //Edit Functionality for Special COndition deviation----Mansur 15-07-2024
              if(this.metadataName == 'Special_Conditions'){
                this.flowApiName = 'UB_Create_Special_Condition_Record';
                this.inputVariables = [];
                this.inputVariables = [
                    {
                        name: 'specialConditionRecordId',
                        type: 'String',
                        value: this.childRecordId
                    }
                    
                ]
                this.showScreenFlow = true;
                console.log('special condition input > ' + JSON.stringify(this.inputVariables));
            }
            if(this.metadataName == 'Vehicle_Records'){
                this.vehicleId = data.recordData.id;
                this.showVehicleScreen = true;
            }
        }

        if (this.actionName == 'Download') {
            this.showSpinner = false;
            this.childRecordId = data.recordData.id;
            this.navigateToViewObjectPage();
        }

        if(this.actionName == 'Submitted to CPA'){
            this.showSpinner = false;
            let actionName = 'Sent to CPA for Manual Verification';
            this.childRecordId = data.recordData.id;
            this.updateDocumentStatus(this.childRecordId, actionName);
        }

        if (this.actionName == 'Upload') {
            this.showModal = true;
            this.showSpinner = false;
            this.childRecordId = data.recordData.id;
        }
        /*if (this.callingApi != undefined && data.recordData.id != undefined && data.ActionName != undefined && (this.callingApi == 'Office FI' || this.callingApi == 'Residence FI' || this.callingApi == 'Vehicle Valuation' || this.callingApi == 'Legal' || this.callingApi == 'Property Valuation')) {

            if (data.ActionName == 'View Detail') {
                getValuationDetail({ parentId: data.recordData.id, valuationType: this.callingApi })
                    .then((result) => {
                        if (result) {
                                this.showSpinner = false;
                            console.log('result>11 ', result);
                            var createdRecordId = result;
                            this.navigateToRecordPage(createdRecordId, 'Valuation__c');

                        }

                    }).catch((err) => {
                        this.showSpinner = false;
                        console.log('Error in returnRelatedRecords = ', err);
                    });


            } else {
                this.vendorInputVariables = [
                    {
                        name: 'vendorParentId',
                        type: 'String',
                        value: data.recordData.id
                    },
                    {
                        name: 'vendorType',
                        type: 'String',
                        value: this.callingApi
                    }
                ];
                 this.showSpinner = false;
                this.isVendorCall = true;
               
                console.log('Vander call--> ', JSON.stringify(this.vendorInputVariables));
            }

        }*/

        if (data.recordData.id != undefined && this.callingApi != undefined && data.ActionName == 'Initiate Verification') {
            if (this.callingApi != undefined && data.recordData.id != undefined && data.ActionName != undefined && 
                (
                    this.callingApi == 'Office FI' || this.callingApi == 'Residence FI'|| 
                     this.callingApi == 'Vehicle Valuation' || this.callingApi == 'Legal' || 
                    this.callingApi == 'Property Valuation' || 
                    this.callingApi == 'Permanent FI' 
                  )
            ){
                console.log('his.applicationLob>>> ',this.applicationLob)
              
                this.vendorInputVariables = [
                    {
                        name: 'vendorParentId',
                        type: 'String',
                        value: data.recordData.id
                    },
                    {
                        name: 'vendorType',
                        type: 'String',
                        value: this.callingApi
                    }
                ];
                this.showSpinner = false;
                if(this.applicationLob == 'BL'){
                    if(this.callingApi == 'Permanent FI'){
                        console.log('in permanent>>')
                        this.permanentAddressSameCheck(data.recordData.id, this.callingApi);
                    }else{
                        this.isAddressRecord(data.recordData.id, this.callingApi);
                    }
                }else{
                    this.isVendorCall = true;
                }
                            
                console.log('Vander call--> ', JSON.stringify(this.vendorInputVariables));
            }else if(this.callingApi == 'AADHAAR'){
                this.showSpinner = false;
                this.showAadhaarScreen = true;
            }else if(this.metadataName == 'Perfios_APIs'){
                if(this.callingApi == 'PERFIOS'){   // added by chandan on 02-07-2024
                    this.showSpinner = false;
                    this.showPerfiosFileUpload = true;
                }
            }else if(this.callingApi == 'E-NACH'){
                    console.log('E-NACH ##');
                    callENachAPI({ disbursementId: data.recordData.id})
                    .then((result) => {
                        console.log('RESULTTTTTT  ', result);
                        console.log('INCLUDE VALUE    ', result.includes('Success'));
                    if (result != undefined && result != null && !result.includes('Success')){
                        this.showToastMsg('Warning', result, 'Warning');
                        this.showSpinner = false;
                    }
                    else if (result != undefined && result != null && result.includes('Success')){
                        window.setTimeout(() => {
                            this.getRelatedRecords();
                            this.showSpinner = false;
                            this.showToastMsg('Success', this.callingApi + ' Triggered Successfully', 'Success');
                            //this.showToastMsg('Success', this.callingApi + ' Verification OTP sent.', 'Success');
                        }, 7000);
                        console.log('Verification API');
                    }else{
                        this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
                        this.showSpinner = false;
                    }
                }).catch((err) => {
                    this.showSpinner = false;
                    this.showToastMsg('Application Error', 'Kindly contact your admin!'+' Error-'+err, 'Error');
                    console.log('Error in API Verification API @@ ', err);
                });
            }else{
                 verifyAPI_Details({ customerId: data.recordData.id, apiName: this.callingApi })
                    .then((result) => {
                        console.log('RESULTTTTTT  ', result);
                        console.log('INCLUDE VALUE    ', result.includes('Success'));
                    if (result != undefined && result != null && !result.includes('Success')){
                        this.showToastMsg('Warning', result, 'Warning');
                        this.showSpinner = false;
                    }else if(result != undefined && result != null && result.includes('Address Details')) {
                        this.showToastMsg('Warning', result, 'Warning');
                        this.showSpinner = false;
                    }
                    else if(result != undefined && result != null && result.includes('Sherlock')) {
                        this.showToastMsg('Warning', result, 'Warning');
                        this.showSpinner = false;
                    }else if (result != undefined && result != null && result.includes('Success')){
                        window.setTimeout(() => {
                            this.getRelatedRecords();
                            this.showSpinner = false;
                            this.showToastMsg('Success', this.callingApi + ' Triggered Successfully', 'Success');
                            //this.showToastMsg('Success', this.callingApi + ' Verification OTP sent.', 'Success');
                        }, 7000);
                        console.log('Verification API');
                    }else{
                        this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
                        this.showSpinner = false;
                    }
                }).catch((err) => {
                    this.showSpinner = false;
                    this.showToastMsg('Application Error', 'Kindly contact your admin!'+' Error-'+err, 'Error');
                    console.log('Error in API Verification API @@ ', err);
                });
            }
           
        }
        /* Author : Zafaruddin
        Date : 19/04/2024
        Description :  It will redirect in view mode of record based on Id */ 
        if(data.recordData.id != undefined && this.callingApi == undefined && data.ActionName == 'View Detail'){
            this.navigateToRecordPage(data.recordData.id,this.objectApiName);
            this.showSpinner = false;
            return ;
        }
        // end here
        
        /* Author : Zafaruddin
        Date : 19/04/2024
        Description :  It will redirect  on Create view of Object. */ 
        if(data.recordData.id != undefined && this.callingApi != undefined && this.callingApi.includes('Financial_Assessment__c') && data.ActionName == 'Create Assessment'){
           console.log('HIRE VS BUY data.recordData.id  ',data.recordData.id);

                           // call function to check any product associated with Loan Application.
                           financialsCalculationProductValidation({ loanId: data.recordData.id, recordTypeName : this.callingApi.split(':')[1], })
                           .then((result) => {
                            console.log('resultresult  ',result);
                            console.log('AAAAAAA   ',this.callingApi.split(':')[1]);
                               console.log('DATA   ',result.includes(this.callingApi.split(':')[1]));
                              
                               if(result != null && ( result.includes(this.callingApi.split(':')[1].slice(0, -1)) 
                                        || (   this.callingApi.split(':')[1] == 'Hire_and_Buy_' && result.includes('Hire')))) {
                                console.log('result  ',result);
                                getVehicleAssessmentDetails({ vehicleId: data.recordData.id, details: this.callingApi })
                                .then((result) => {
                                    console.log('RESULTTTTTT  ',result);
                                    var wrapper  = JSON.parse(result); 
                                    if(wrapper.recordTypeId != null && wrapper.recordTypeId != undefined) {
                                        this.showSpinner = false;
                                         // Navigate to the create record page with the fetched record type ID
                                        this[NavigationMixin.Navigate]({
                                            type: 'standard__objectPage',
                                            attributes: {
                                                objectApiName: wrapper.ObjectName,
                                                actionName: 'new'
                                            },
                                            state: {
                                                defaultFieldValues: encodeDefaultFieldValues({
                                                    Loan_Application__c:  wrapper.loanApplicationId,
                                                     Vehicle__c        : data.recordData.id,
                                                  }),
                                                recordTypeId:wrapper.recordTypeId,
                        
                                            }
                                        });
                                    } else {
                                        this.showSpinner = false;
                                        this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
                                    }
                    
                                }).catch((err) => {
                                    this.showSpinner = false;
                                    this.showToastMsg('Application Error', 'Kindly contact your admin!'+' Error-'+err, 'Error');
                                    console.log('Error in API Verification API @@ ', err);
                                });
           
                               } else {
                                   this.showSpinner = false;
                                   this.showToastMsg('error', 'You can not do the assessment.'  , 'error');
           
                               }
                           }).catch((err) => {
                               this.showSpinner = false;
                               console.log('Error in returnRelatedRecords = ', err);
                           });




        }

        // end here
        if(data.recordData.id != undefined && this.callingApi != undefined && data.ActionName == 'View Detail'){
            if (this.callingApi != undefined && data.recordData.id != undefined && (this.callingApi == 'Office FI' || this.callingApi == 'Residence FI' || this.callingApi == 'Vehicle Valuation' || this.callingApi == 'Legal' || this.callingApi == 'Property Valuation' || this.callingApi == 'Permanent FI')){
                getValuationDetail({ parentId: data.recordData.id, valuationType: this.callingApi })
                    .then((result) => {
                        console.log('getValuationDetail result-> ' , result);
                        if (result) {
                            this.showSpinner = false;
                            console.log('result>11 ', result);
                            var createdRecordId = result;
                            this.navigateToRecordPage(createdRecordId, 'Valuation__c');

                        }else{
                             this.showSpinner = false;
                        this.showToastMsg('Warning', 'There is no ' + this.callingApi +  ' Activity Created ', 'Warning');
                    }

                    }).catch((err) => {
                        this.showSpinner = false;
                        console.log('Error in returnRelatedRecords = ', err);
                    });
            }else{
                console.log('OUTPUT : ',data.recordData.id);
                console.log('OUTPUT : ',this.callingApi);
                fetchVerificationId({ customerId: data.recordData.id, apiName: this.callingApi })
                .then((result) => {
                    console.log('RESULTTTTTT  ',result);
                    this.showSpinner = false;
                    if(result != undefined && result != null){
                        this.navigateToRecordPage(result,'Verification__c');
                    }else{
                        this.showToastMsg('Warning', 'Kindly initiate the ' + this.callingApi +  ' verification for the applicant to proceed further!', 'Warning');
                    }
                }).catch((err) => {
                    this.showSpinner = false;
                    this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Warning');
                    console.log('No verification record found!', err);
                });
            }
        }

        if(data.recordData.id != undefined && this.callingApi != undefined && data.ActionName == 'Waive FI'){
            if (this.callingApi != undefined && data.recordData.id != undefined && (this.callingApi == 'Office FI' || this.callingApi == 'Residence FI' || this.callingApi == 'Permanent FI')){
                console.log('Waive fi called ')
                //applicants id: data.recordData.id
                this.isAcitivityRecordExist(data.recordData.id, this.callingApi);
            }
        }

        /*Added by Mohit Saxena on 1st April 2024- Ends*/

        /*Added by Mohit Saxena on 1st April 2024- Starts*/
        if(data.recordData.id != undefined && data.ActionName == 'Add Vehicle Details'){
            this.showSpinner = false;
            this.showVehicleScreen = true;
            if(data.recordData.Product_Category__c != undefined && data.recordData.Product_Category__c != null && data.recordData.Product_Category__c != ''){
                this.productCategory = data.recordData.Product_Category__c; 
                /*@Descriptor : Need to pass Vehicle Record Type Id based on Product category Selection */ 
                for (let i in this.vehicleRecordType){
                    if(this.productCategory.includes('Used') && this.vehicleRecordType[i].name.includes('Used')){
                        this.vehicleRecordTypeId = this.vehicleRecordType[i].recordTypeId;
                    }else if(this.productCategory.includes('New') && this.vehicleRecordType[i].name.includes('New')){
                        this.vehicleRecordTypeId = this.vehicleRecordType[i].recordTypeId;
                    }
                }
            }
        }

        if(data.recordData.id != undefined && data.ActionName == 'Delete'){
                this.deleteSelectedRecord(data.recordData.id);
                window.setTimeout(() => {
                    this.getRelatedRecords();
                }, 4000);
        }

        /*Added by Lakshya for soft delete functionlity on 19 july 2024 */
        if(data.recordData.id != undefined && data.ActionName == 'Inactive'){
            if(this.metadataName == 'CoApplicant' || this.metadataName == 'Guarantor'){
                console.log('data.ActionName-> ' , data.ActionName);
                this.updateApplicantStatus(data.recordData.id,'Yes');
                window.setTimeout(() => {
                    this.getRelatedRecords();
                }, 3000);
            }
        }

        

        /*Added by Mohit Saxena on 1st April 2024- Ends*/

        /*Added by Mohit Saxena on 10th May 2024- Starts*/
        if(data.recordData.id != undefined && data.ActionName == 'Initiate Customer TVR'){
            this.flowApiName = 'UB_Customer_Tele_Verification_Report';
            this.showSpinner = false;
            this.inputVariables = [];
            this.inputVariables = [
                {
                    name: 'loanApplicantId',
                    type: 'String',
                    value: this.childRecordId
                }
            ]
            this.showScreenFlow = true;
        }

        if(data.recordData.id != undefined && data.ActionName == 'Initiate Dealer TVR'){
            this.flowApiName = 'UB_Dealer_Tele_Verification_Record';
            this.showSpinner = false;
            this.inputVariables = [];
            this.inputVariables = [
                {
                    name: 'vehicleId',
                    type: 'String',
                    value: this.childRecordId
                }
            ]
            this.showScreenFlow = true;
        }
        /*Added by Mohit Saxena on 1st April 2024- Ends*/

        //Added by Lakshya Verma on 26-08-2024 for BL RCU vendor changes
        if(this.metadataName == 'BLRCUVendor'){
            if(this.actionName == 'Revoke'){
                //this.showSpinner = false;
                this.rcuVendorRevoke();
            }
        }
    }

    deleteSelectedRecord(recordId) {
        try {
            deleteRecord(recordId);
            this.showToastMsg('Success', 'Record deleted successfully!', 'Success');
        } catch (error) {
            this.showToastMsg('Error deleting record', reduceErrors(error).join(', '), 'error');
        }
    }

    // Navigate to View Account Page
    navigateToViewObjectPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.childRecordId,
                objectApiName: 'Document__c',
                actionName: 'view'
            },
        });
    }

    // addedd by lakshya verma on 30-apr-2024 for update the status to Sent to CPA of document
    updateDocumentStatus(docId,status) {
        this.showSpinner = true;
        updateDocumentStatus({recordId: docId, status : status})
            .then(result => {
                console.log('result.updateDocumentStatus-> ' , result);
                if (result.isSuccess) {
                    this.showNotification('Success', 'Record is updated successfully', 'success');
                   //this.template.querySelector('c-confirmation-dialog');
                } else {
                    this.showNotification('Error', 'Something Went Wrong!!', 'error');
                }
            })
            .catch(error => {
                //console.log('Error updateVerify= ', error);
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', 'Something Went Wrong!!', 'error');
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        //eval("$A.get('e.force:refreshView').fire();");
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);
        this.getRelatedRecords();
    }

    closeModal(event) {
        console.log('event.detail-> ' , event.detail);
        this.showModal = event.detail;
        this.getRelatedRecords();
    }

    handleFlowStatusChange(event){
        if(event.detail.status === 'FINISHED'){
            this.showScreenFlow = false;
            this.getRelatedRecords();
        }
    }

    handleRowSelection(evt) {
        var data = evt.detail;

        this.selectedRows = null;

        console.log('here ', JSON.stringify(evt.detail));
        this.selectedRows = evt.detail;

        console.log('data handleRowSelection-> ', data.ActionName);
        console.log('selectedRows: ' + JSON.stringify(this.selectedRows));

        for (var action of this.relatedRecords.headerActions) {
            console.log('action-> ', action);
            if (action.enableFilterConditions != '' && action.enableFilterConditions != undefined) {
                if (this.selectedRows.length == 1) {
                    console.log('enableFilterConditions ', action.enableFilterConditions);
                    console.log('record id ', this.selectedRows[0].id);
                    //this.callGetFilterRecords(this.objectAPIName, this.selectedRows[0].id, action.enableFilterConditions, action);
                } else {
                    action.isEnable = true;
                }
            } else {
                action.isEnable = true;
            }
        }
    }

    handleheaderAction(event) {
            if(event.target.name == 'Initiate_RCU'){
                console.log('action name: ' + event.target.name);
                this.showScreenFlow = true;
                this.flowApiName = 'BL_RCU_Initiate';
                this.inputVariables = [
                        {
                            name: 'recordId',
                            type: 'String',
                            value: this.recordId
                        }
                ];
            }else if(event.target.name == 'Waive_RCU'){
                console.log('action name: ' + event.target.name);
                this.showSpinner = true;
                this.rcuWaiveActivityByManager();
            }else if(event.target.name == 'Submit_Decision'){
                let selectedIds = [];
                console.log('action name: ' + event.target.name);
                console.log('this.selectedRows-> ' + JSON.stringify(this.selectedRows));
                if (this.selectedRows == undefined || this.selectedRows.length == undefined || this.selectedRows.length == 0) {
                    this.showToastMsg('Error', 'Please select at-least a record.', 'error');
                }else{
                    var dataset = event.target.dataset;
                    this.showSpinner = true;
                    console.log('here ' + this.selectedRows.length);
                    console.log('dataset.type ' + dataset.type);
                    if (this.selectedRows.length > 0) {
                        this.selectedRows.forEach(currentItem => {
                            if(this.userRoleName == 'Regional Credit Manager' || this.userProfileName == 'System Administrator'){
                                if(currentItem.Approving_Authority__c.includes(this.userRoleName)){
                                    console.log('currentItem1-> ', currentItem.Approving_Authority__c);
                                    selectedIds.push(currentItem.id);
                                }
                            }
                            /*if(currentItem.Approving_Authority__c.includes(this.userRoleName) || this.userProfileName == 'System Administrator' || 
                                (this.userRoleName == 'Credit Head' || this.userRoleName == 'National Credit Manager' || this.userRoleName == 'Zonal Credit Manager') 
                            ){
                                console.log('currentItem-> ', currentItem.id);
                                selectedIds.push(currentItem.id);
                            }*/
                            else if(this.userRoleName == 'Zonal Credit Manager' || this.userProfileName == 'System Administrator'){
                                console.log('currentItem2-> ', currentItem.Approving_Authority__c);
                                console.log('this.userRoleName2-> ', this.userRoleName);
                                if(currentItem.Approving_Authority__c.includes('Regional Credit Manager') || currentItem.Approving_Authority__c.includes('Zonal Credit Manager')){
                                    selectedIds.push(currentItem.id);
                                }
                            }else if(this.userRoleName == 'National Credit Manager' || this.userProfileName == 'System Administrator'){
                                if(currentItem.Approving_Authority__c.includes('National Credit Manager') || currentItem.Approving_Authority__c.includes('Regional Credit Manager') || currentItem.Approving_Authority__c.includes('Zonal Credit Manager')){
                                    console.log('currentItem3-> ', currentItem.Approving_Authority__c);
                                    selectedIds.push(currentItem.id);
                                }
                            }else if(this.userRoleName == 'Credit Head' || this.userProfileName == 'System Administrator'){
                                console.log('currentItem4-> ', currentItem.Approving_Authority__c);
                                selectedIds.push(currentItem.id);
                            }
                        });
                        console.log('selectedIds-> ', JSON.stringify(selectedIds));
                    }

                if (selectedIds.length > 0 && selectedIds.length == this.selectedRows.length) {
                     if(selectedIds){
                        this.inputVariables = [
                                {
                                    name: 'deviationConIds',
                                    type: 'String',
                                    value: selectedIds
                                },
                                {
                                    name: 'recordId',
                                    type: 'String',
                                    value: this.recordId
                                }
                        ];
                        this.showSpinner = false;
                        this.submitDecision = true;
                    }
                }else{
                    this.showSpinner = false;
                    this.showToastMsg('Warning', 'Please submit decision for deviations which are owned by you or your subordinates!!', 'warning');
                }
            }

            /*if (dataset.type == 'Apex Method') {
                this.showSpinner = false;
                
            }*/
        }
    }

    handleAddressClose(event) {
        console.log('in dynamicList Handle Close', event.detail);
        this.isShowAddress = event.detail;
        this.getRelatedRecords();
        this.selectedRows = undefined;
    }

    /*Added by Mohit Saxena on 3rd April 2024- Starts*/
    navigateToRecordPage(recordId, objectApiName){
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
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

    closeScreen(event){
        this.showVehicleScreen = false;
        this.showProductScreen = false;
        this.showScreenFlow = false;
        this.showAadhaarScreen = false;
        this.showPerfiosFileUpload = false;
        this.showSpinner = false;
    }
    /*Added by Mohit Saxena on 3rd April 2024- Ends*/
    handleCloseVendor(event){
        this.isVendorCall = false;
    }
    handleStatusChangeVendor(event){
        console.log('event>>>> : ' + JSON.stringify(event));
        if (event.detail.status === 'FINISHED') {
            this.isVendorCall = false;
            this.showToastMsg('Success', 'Activity Created Successfully', 'Success');
            
        }

    }

    handleStatusSubmitDecision(event){
        if (event.detail.status === 'FINISHED') {
            this.submitDecision = false;
            this.showToastMsg('Success', 'Deviation Decision Updated Successfully', 'Success');
            
        }
    }

    handleSubmitDecision(){
        this.submitDecision = false;
    }

    handleChangeEvent(event){
        if(event.target.name == 'aadhaarNumber'){
            this.aadhaarNumber = event.target.value;
        }
        if(event.target.name == 'password'){
            this.password = event.target.value;
        }
    }
    
    handleSaveMethod(event){
        this.showSpinner = true;
        if(this.aadhaarNumber != '' || this.aadhaarNumber != undefined && this.aadhaarNumber != null){
            fetchAadhaarMaskedUID({customerId : this.childRecordId, aadhaarNumber : this.aadhaarNumber})
            .then((result) => {
                this.showSpinner = false;
                if(result.includes('failed')){
                    this.showToastMsg('System Error', result, 'Error'); 
                }else{
                    this.showSpinner = true;
                    this.sendAadhaarOTPWithLink(this.childRecordId, result);
                }
                console.log('Aadhaar Masked UID: '+result);
            })
            .catch((error) => {
                console.error(error);
                this.showSpinner = false;
                this.showToastMsg('System Error', error, 'Error');
                this.showAadhaarScreen = false;
            });
        }else{
            this.showToastMsg('Warning', 'Kindly provide Aadhaar Number to proceed with verification.', 'Error');
            this.showSpinner = false; 
        }
    }

    // added by Chandan on 2nd July,2024
    // To Handle the uploaded the files
    handleUploadMethod(event){
        this.showSpinner = true;
        console.log('Uploaded Files : ',JSON.stringify(this.uploadedFiles));
        console.log('customerId : ',this.childRecordId);
        if(this.uploadedFiles != undefined){
            initiateTransaction({customerId : this.childRecordId,password: this.password})
            .then((result) => {
            // this.showSpinner = false;
                this.showPerfiosFileUpload = false;
                // this.showToastMsg('Success', this.callingApi + ' APIs are Triggered', 'Success');

                window.setTimeout(() => {
                                this.getRelatedRecords();
                                this.showSpinner = false;
                                this.showToastMsg('Success', this.callingApi + ' Triggered Successfully', 'Success');
                                this.navigateToRecordPage(data.recordData.id,this.objectApiName);
                                //this.showToastMsg('Success', this.callingApi + ' Verification OTP sent.', 'Success');
                            }, 20000);
            }).catch((error) => {
                    console.error(error);
                    this.showSpinner = false;
                    this.showToastMsg('System Error', error, 'Error');
                    this.showPerfiosFileUpload = false;
                });
        }else{
            this.showToastMsg('Warning', 'Kindly upload file to proceed further!', 'Error');
            this.showSpinner = false;
        }
    }

    sendAadhaarOTPWithLink(customerId, maskedAadhaarNumber){
        sendAadhaarOTP({customerId : customerId, maskedAadhaarNumber : maskedAadhaarNumber })
        .then((result) => {
            this.showSpinner = false;
            if(result.includes('Success')){
                this.showToastMsg('Success', this.callingApi + ' Verification OTP sent.', 'Success');
            }else{
                this.showToastMsg('System Error', result, 'Error'); 
            }
            this.getRelatedRecords();
        })
        .catch((error) => {
            console.error(error);
            this.showToastMsg('System Error', error, 'Error'); 
            this.showSpinner = false;
        });
        this.showAadhaarScreen = false;
    }

    getPendingDibursements() {
        this.showSpinner = true;
        getPendingDibursements({loanAppId : this.recordId
        })
            .then(result => {
                console.log('result.getPendingDibursements-> ' , result);
                if(result.isSuccess){
                    this.showSpinner = false;
                    this.showToastMsg('Error', 'Please complete existing disbursment to proceed further ' + result.responseBody, 'error');
                    
                }else{
                    this.showSpinner = false;
                    this.loanOfferReview = true;
                    //this.showToastMsg('Error', result.responseBody, 'error');
                }
            })
            .catch(error => {
                console.log('Error updateVerify= ', error);
                this.showToastMsg('Error', error, 'error');
            })
    }

    rcuWaiveActivityByManager() {
        this.showSpinner = true;
        rcuWaiveActivityByManager({loanApplicationId : this.recordId
        })
            .then(result => {
                console.log('result.getPendingDibursements-> ' , result);
                if(result.isSuccess){
                    this.showSpinner = false;
                    this.showToastMsg('Error', result.responseBody, 'error');
                }else if(result.rcuWaive){
                    this.updateApplicationRCUWaived();
                }else{
                    this.showToastMsg('Error', result.responseBody, 'error');
                }
            })
            .catch(error => {
                console.log('Error updateVerify= ', error);
                this.showToastMsg('Error', error, 'error');
            })
    }

    async updateApplicantStatus(applicantId,applicantStatus) {
        const fields = {};
        fields[APPLICANT_ID_FIELD.fieldApiName] = applicantId;
        fields[APPLICANT_IS_DELETED.fieldApiName] = applicantStatus;
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            if(applicantStatus == 'Yes'){
                this.showToastMsg('Success', 'Applicant inactive successfully', 'success');
            }else if(applicantStatus == 'No'){
                this.showToastMsg('Success', 'Applicant active successfully', 'success');
            }
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMsg('Error', error.body.output.errors[0].message, 'error');
           
        });
        
    }

    async updateApplicationRCUWaived() {
        const fields = {};
        fields[LOAN_APPLICATION_ID.fieldApiName] = this.recordId;
        fields[RCU_WAIVED.fieldApiName] = true;
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMsg('Success', 'RCU Waived successfully.', 'success');
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMsg('Error', error.body.output.errors[0].message, 'error');
           
        });
        
    }

    //addedd by Lakshya on 26-08-2024 for rcu vendor revoke functionlaity
    async rcuVendorRevoke() {
        const fields = {};
        fields[VALUATION_ID.fieldApiName] = this.childRecordId;
        fields[IS_REVOKED.fieldApiName] = true;
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMsg('Success', 'Revoke successfully from vendor.', 'success');
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMsg('Error', error.body.output.errors[0].message, 'error');
           this.showSpinner = false;
        });
        
    }

    //Addedd by Umair
    async updateApplicantFIWaived(applicantId) {
        const fields = {};
        fields[APPLICANT_ID_FIELD.fieldApiName] = applicantId;
        fields[FI_WAIVED.fieldApiName] = true;
        const recordInput = {
            fields: fields
        };

        await updateRecord(recordInput).then((record) => {
            this.showToastMsg('Success', 'FI Waived successfully.', 'success');
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('ERROR:'+JSON.stringify(error));
            this.showToastMsg('Error', error.body.output.errors[0].message, 'error');
           
        });
        
    }
  //Addedd by Umair
    isAcitivityRecordExist(applicantId, callingApi){
        this.showSpinner = true;
        isAcitivityRecordExist({applicantId : applicantId, callingApi :callingApi
        })
            .then(result => {
                console.log('result.isAcitivityRecordExist-> ' , result);
                if(result){
                    this.showToastMsg('Error', 'You can not waived as verification already Initiated.', 'error');
                    this.showSpinner = false;
                }else{
                    this.updateApplicantFIWaived(applicantId);
                     this.showSpinner = false;
                }
            })
            .catch(error => {
                console.log('Error isAcitivityRecordExist= ', error);
                this.showToastMsg('Error', error, 'error');
                this.showSpinner = false;
            })
    }

    //Addedd by Umair
    isAddressRecord(applicantId, callingApi){
        this.showSpinner = true;
        isAddressRecord({applicantId : applicantId, callingApi :callingApi
        })
            .then(result => {
                console.log('result.isAddressRecord-> ' , result);
                if(!result){
                    if(callingApi == 'Permanent FI'){
                        this.addressType = 'Permanent Address';
                    }else if(callingApi == 'Residence FI'){
                        this.addressType = 'Residence Address';
                    }else if(callingApi == 'Office FI'){
                        this.addressType = 'Office Address';
                    }
                    console.log(' this.addressType>> ', this.addressType)
                    this.showToastMsg('Error',  this.addressType+'  does not exist for this applicant.', 'error');
                    this.showSpinner = false;
                }else{
                    this.isVendorCall = true;
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                console.log('Error isAddressRecord= ', error);
                this.showToastMsg('Error', JSON.stringify(error), 'error');
                this.showSpinner = false;
            })
    }
      //Addedd by Umair
      permanentAddressSameCheck(applicantId, callingApi){
        this.showSpinner = true;
        permanentAddressSameCheck({applicantId : applicantId
        })
            .then(result => {
                console.log('result.permanentAddressSameCheck-> ' , result);
                if(result){
                    if(callingApi == 'Permanent FI'){
                        this.showToastMsg('Error',  'Permanent Address Same as Residence Address', 'error');
                    }
                    console.log(' this.permanentAddressSameCheck>> ', this.addressType)
                    this.showSpinner = false;
                }else{
                    this.isAddressRecord(applicantId, callingApi);
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                console.log('Error permanentAddressSameCheck= ', error);
                this.showToastMsg('Error', JSON.stringify(error), 'error');
                this.showSpinner = false;
            })
    }

    //added by lakshya verma USFBL-454 on 30-sept started
    closePreviewModal(event) {
        console.log('event-> ', event.detail);
        this.showPreviewModal = event.detail;
    }
}