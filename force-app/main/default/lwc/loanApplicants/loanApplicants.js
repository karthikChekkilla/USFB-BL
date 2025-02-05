import { LightningElement, track, wire, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomerDetail from '@salesforce/apex/UB_LoanApplicantsController.getCustomerDetail';
import LOB_FIELD from "@salesforce/schema/Loan_Application__c.LOB__c";
import LOAN_STATUS from "@salesforce/schema/Loan_Application__c.Loan_Application_Status__c";
import getRecordIsReadOnlyFromSObject from '@salesforce/apex/UB_DisplayUBDocumentsController.getRecordIsReadOnlyFromSObject';
const columns = [	
    { label: 'Customer Name', fieldName: 'CustomerUrl', type: 'url', 
        typeAttributes: {
            label: { 
                fieldName: 'Name'
            },
            target : '_blank'
        }
    },
    { label: 'PAN Number', fieldName: 'Pan_Number__c' },
    { label: 'Mobile No', fieldName: 'Mobile__c' }

];


export default class LoanApplicants extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track inputVariables = [];
    @track showSpinner = false;
    @track name = '';
    @track customerId = '';
    @track mobileNo = '';
    @track kycDocType = '';
    @track kycDocLabel = '';
    @track kycDocValue = '';
    @track createTable = false;
    @track buttonSwitch = false;
    @track applicationLob = '';
    pageNumber = 1; //Page number
    columns = columns;
    totalPages; //Total no.of pages
    pageSize = 10;
    @track isFlowInvoked = false;
    @track isFlowInvokedBL = false;
    @track showRecordTypePage = false;
    @track activetabContent='applicant';
    @track recordsToDisplay = [];
    //Pagination
    totalRecords = 0; //Total no.of records
    @track modalHeader = 'Loan Applicant Information';
    @track isReadOnlyRecord;
    @track isNewButtonVisible = false;
    @track recordTypeName = false;
    @track loanStatus = '';
    @track isCVModal = false;
    @track isBLModal = false;

    @wire(getRecord, { recordId: "$recordId", fields: [LOB_FIELD, LOAN_STATUS] })
    getApplications({ error, data }) {
        if (error) {
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            if(data.fields.Loan_Application_Status__c.value){
                this.loanStatus = data.fields.Loan_Application_Status__c.value;
            }
            if(data.fields.LOB__c.value != null){
                this.applicationLob = data.fields.LOB__c.value;
                if(this.applicationLob == 'BL'){
                    this.isBLModal = true;
                }else if(this.applicationLob != 'BL'){
                    this.isCVModal = true;
                }
                console.log('loanApplicationId-> ', this.applicationLob);
            }if(data.recordTypeInfo.name != null){
                this.recordTypeName = data.recordTypeInfo.name;
                console.log('recordTypeName-> ', this.recordTypeName);
            }
        }
    }

    connectedCallback() {
        console.log('recordId-> ', this.recordId);
        console.log('objectApiName-> ', this.objectApiName);
        this.getRecordIsReadOnlyFromSObject();
    }

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    handleStatusChange(event){
        console.log('event-> ', event.detail.status);
        if (event.detail.status === 'FINISHED') {
            //this.renderFlow = false;
            this.showToastMsg('Success', 'Loan Applicant Created Successfully', 'Success');
            //this.template.querySelector("c-dynamic-related-list").getRelatedRecords();
            if(this.applicationLob == 'CV' || this.applicationLob == 'CE'){
               this.isFlowInvoked = false;
           }else if(this.applicationLob == 'BL'){
               this.isFlowInvokedBL = false;
           } 
            window.location.reload();
        }else{
            console.log('Flow execution encountered an unexpected status.');
        }
    }

    showToastMsg(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title   : title,
                message : message,
                variant : variant,
                mode : "sticky"
            })
        )
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    handleClick(event) {
        if(event.target.name === 'Customer Button'){
            console.log('handleclick-> ', event.target.name);
            //this.showRecordTypePage = true;
           if(this.applicationLob == 'CV' || this.applicationLob == 'CE'){
               this.isFlowInvoked = true;
               this.inputVariables = [
                        {
                            name: 'applicationRecordId',
                            type: 'String',
                            value: this.recordId
                        }
                ];
           }if(this.applicationLob == 'BL'){
                console.log('@@@@@@'+this.recordId);
               this.isFlowInvokedBL = true;
               this.inputVariables = [
                        {
                            name: 'applicationRecordId',
                            type: 'String',
                            value: this.recordId
                        },
                        {
                            name: 'recordTypeName',
                            type: 'String',
                            value: this.recordTypeName
                        }
                ];
           }
           
            //this.openLoanApplicantCreationForm();
        }
    }

    get kycDocTypeOptions() {
        return [
            { value: "", label: "None" },
            { value: "PAN Number", label: "PAN Number" }
        ];
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    getCustomerDetail(){
        this.recordsToDisplay = [];
        this.createTable = false;
        this.customerDetails = [];
        getCustomerDetail({name: this.name, mobileNo: this.mobileNo, kycDocType: this.kycDocType, kycDocValue: this.kycDocValue})
        .then(result =>{
            this.customerDetails = result;
            this.customerDetails.forEach(item => item['CustomerUrl'] = '/lightning/r/Account/' +item['Id'] +'/view');
            console.log('called---------', this.customerDetails.length);
            //-------------------Pagination---------------//    
            if(this.customerDetails != undefined && this.customerDetails != null){
                if(this.customerDetails.length>0){
                    this.totalRecords = result.length; // update total records count  
                    this.paginationHelper(); // call helper menthod to update pagination logic 
                    this.buttonSwitch = true;
                }
                else{
                    this.buttonSwitch = false;
                }
            }
            else{
                this.buttonSwitch = false;
            }    
            console.log('recordsToDisplay-> ', this.recordsToDisplay);
        }).catch(error =>{
            console.log('error---------', error);
        })    
    }

    handleInput(event){
        console.log('Entered value in', event.target.name);
        this.valideValue = false;
        if(event.target.name === 'CustomerName'){
            this.name = event.target.value.trim();
        }else if(event.target.name === 'MobileNo'){
            this.mobileNo = event.target.value.trim();
        }else if(event.target.name === 'KycDocType'){
            this.kycDocType = event.target.value;
            if(this.kycDocType){
                this.kycDocLabel = event.target.value;
            }else{
                this.kycDocValue = '';
            }
        }else if(event.target.name === 'KycDocValue'){
            this.kycDocValue = event.target.value.trim();
        }
    }

    handleAction(event){
        console.log('event-> ', event.detail.customerId);
        console.log('event-> ', this.recordId);
        console.log('event-> ', this.recordTypeName);
        console.log('event-> ', event.detail.model);
        console.log('this.applicationLob-> ', this.applicationLob);
        if(this.applicationLob == 'CV' || this.applicationLob == 'CE'){
            this.isFlowInvoked = event.detail.model;
            this.inputVariables = [
                {
                    name: 'applicationRecordId',
                    type: 'String',
                    value: this.recordId
                },
                {
                    name: 'applicantId',
                    type: 'String',
                    value: event.detail.customerId
                }
            ];
        }else if(this.applicationLob == 'BL'){
            this.isFlowInvokedBL = event.detail.model;
            this.inputVariables = [
                {
                    name: 'applicationRecordId',
                    type: 'String',
                    value: this.recordId
                },
                {
                    name: 'applicantId',
                    type: 'String',
                    value: event.detail.customerId
                },
                {
                    name: 'recordTypeName',
                    type: 'String',
                    value: this.recordTypeName
                }
            ];
        }
    }

    handleClearClick(){
        this.createTable = false;
        this.name = '';
        this.mobileNo = '';
        this.kycDocType = '';
        this.kycDocValue = '';
        this.customerId = '';
        this.applicationCustomerType = '';
        this.accountDefaultValues = '';
        this.selectedRelationshipType = '';
        this.newAppButton = true;
        this.newCustButton = false;
        this.buttonSwitch = false;
    }

    handleSECClick(){
        this.getCustomerDetail();
        this.createTable = true;
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.customerDetails[i]);
        }
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    handleClose(event){
        this.showRecordTypePage = event.detail;
        if(this.applicationLob == 'CV' || this.applicationLob == 'CE'){
            this.isFlowInvoked = false;
        }else if(this.applicationLob == 'BL'){
            this.isFlowInvokedBL = false;
        }
    }

    getRecordIsReadOnlyFromSObject(){
        getRecordIsReadOnlyFromSObject({recordId : this.recordId , SObjectName : this.objectApiName })
        .then(result=>{
            console.log('getRecordIsReadOnlyFromSObject result -> ', result);
            this.isReadOnlyRecord = result;
            if(!this.isReadOnlyRecord){
                if(this.loanStatus != 'Rejected'){
                    this.isNewButtonVisible =  true;
                }
            }else{
                this.isNewButtonVisible =  false;
            }
        }).catch(error =>{
            console.log('getRecordIsReadOnlyFromSObject error -> ', error);
        })
    }


    //method for selecting only one of the rows of the datatable
    selectedRows = event => {
        console.log('detail event---------' , JSON.stringify(event.detail));
        //this.newAppButton = false;
        //this.newCustButton = true;
        var selectedRows = event.detail.selectedRows;
        console.log('selectedRows-> ', selectedRows);
        this.customerId = '';

        if(selectedRows == null || selectedRows==''){
            console.log('on row deselect');
            //this.newAppButton = true;
            //this.newCustButton = false;
        }else {
            this.customerId = selectedRows[0].Id;
            //console.log('this.customerId=>', this.customerId);
        }


        if(selectedRows.length == this.recordsToDisplay.length && this.recordsToDisplay.length > 1){
            var el = this.template.querySelector('lightning-datatable');
            selectedRows = el.selectedRows = [];
        }

        if(selectedRows.length>1)
        {
            console.log('on row select selectedRows ');
            var el = this.template.querySelector('lightning-datatable');
            selectedRows = el.selectedRows = el.selectedRows.slice(1);
            this.customerId = selectedRows[0];
            console.log('this.customerId', this.customerId);
            event.preventDefault();
            return;
        }
        
    }

}