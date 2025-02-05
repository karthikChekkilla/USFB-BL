import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import financialsCalculationProductValidation from '@salesforce/apex/UB_CommonUtil.financialsCalculationProductValidation'; //Added by Mohit Saxena on 3rd April 2024
import SAMPLEMC from "@salesforce/messageChannel/LMSChannel__c";
import { publish, MessageContext } from 'lightning/messageService';
import LOAN_APPLICATION_ID from "@salesforce/schema/Disbursement__c.Loan_Application__c";
import callENachAPI from '@salesforce/apex/UB_HTTPCalloutService.callENachAPI'; //Added by Mohd Musab on 01-07-2024
//import callQuoteAPI from '@salesforce/apex/UB_Quote_API.getQuoteAPI'; //Added by Umair on 23-07-2024
//import latestQuoteVerificationRecord from '@salesforce/apex/UB_Quote_API.latestQuoteVerificationRecord'; //Added by Umair on 24-07-2024
//import callPartnerAPI from '@salesforce/apex/UB_PartnerApi.callPartnerApi'; //Added by Umair on 25-07-2024
import { getRecord  } from "lightning/uiRecordApi";
import getRecordIsReadOnlyFromSObject from '@salesforce/apex/UB_DisplayUBDocumentsController.getRecordIsReadOnlyFromSObject';
//import callVehicleAssetCollateralAPI from '@salesforce/apex/UB_Vehicle_Asset_Collateral_API.initiateVehicleAssetCollateralAPI'; //Added by Umair on 01-07-2024

export default class Ub_CreateFinancialRecord extends NavigationMixin(LightningElement) {
    @api recordTypeName;
    @api object_Name;
    @api recordId;
    @api metadata;
    @api buttonLabel;
    @api buttonName;
    @track isShowAddress = false;
    executeFlow = false;
    @api parentObjectName;
    @track showDocumentModal = false;
    @track showScreenFlow = false;
    @track showSanctionConditionsFlow = false;
    @track flowApiName = '';
    @track inputVariables = [];
    @track loanApplicationId;
    @track isDisabled = false;
    @track isReadonly = false;
    @track eNachResult = true;

    @wire(getRecord, { recordId: "$recordId", fields: [LOAN_APPLICATION_ID] })
    disbursementRecs({ error, data }) {
        if (error) {
            console.log('error-> ', error);
        }else if (data) {
            console.log('data-> ', data);
            if(data.fields.Loan_Application__c.value != null){
                this.loanApplicationId = data.fields.Loan_Application__c.value;
                console.log('loanApplicationId-> ', this.loanApplicationId);
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: '$object_Name' })
    financialObjectInfo({ data, error }) {
        if (data) {
            const recordTypes = data.recordTypeInfos
            for (const rtId in recordTypes) {
                if (recordTypes[rtId].name == this.recordTypeName) {
                    this.recordTypeId = rtId;
                    break;
                }
            }
        }
        if (error) {
            console.log('error is>', error);
        }
    }

    connectedCallback() {
        console.log('parentObjectName->', this.parentObjectName);
        console.log('recordId connect->', this.recordId);
        console.log('metadata connected->', this.metadata);
        this.getRecordIsReadOnlyFromSObject();
    }

    handleClick(event) {
        this.executeFlow = false;
        console.log('recordId' + this.recordId);
        console.log('recordTypeName  ', this.recordTypeName);
        console.log('metadata>> ' + this.metadata);
        if (this.metadata == 'Financials' || this.metadata == 'FFR') {
            try {
                console.log('this.recordTypeId  ', this.recordTypeId);

                // call function to check any product associated with Loan Application.
                financialsCalculationProductValidation({ loanId: this.recordId, recordTypeName: this.recordTypeName, })
                    .then((result) => {
                        console.log('DATA   ', result.includes(this.recordTypeName));
                        console.log('resultresult  ', result);
                        if (result != null && result.includes(this.recordTypeName)) {
                            var objdata = {
                                Loan_Application__c: this.recordId,
                            };
                            console.log('this.objdata  ', objdata);
                            if (this.recordTypeName == 'FFR') {
                                objdata.Financial_Duplicate_Id__c = this.recordId + 'FFR';

                            }
                            console.log('objdata   ' + objdata);
                            // Navigate to the create record page with the fetched record type ID
                            this[NavigationMixin.Navigate]({
                                type: 'standard__objectPage',
                                attributes: {
                                    objectApiName: this.object_Name,
                                    actionName: 'new'
                                },
                                state: {
                                    defaultFieldValues: encodeDefaultFieldValues(objdata),
                                    recordTypeId: this.recordTypeId,

                                }
                            });

                        } else if (result.includes('duplicate')) {
                            this.showSpinner = false;
                            this.showToastMsg('error', 'The record is already created.', 'error');

                        }
                        else {
                            this.showSpinner = false;
                            this.showToastMsg('error', 'You can not do the assessment.', 'error');

                        }
                    }).catch((err) => {
                        this.showSpinner = false;
                        console.log('Error in returnRelatedRecords = ', err);
                    });




            } catch (e) {
                console.log('Error  ', e);
            }
        } else if (this.metadata == 'Product_Records') {
            console.log('apicalling ' + this.recordId);
            this.executeFlow = true;
        } else if (this.metadata == 'Members') {
            //method addedd by lakshya for member screen on applicant object
            var objdata = {
                Loan_Applicant__c: this.recordId,
                Loan_Application__c:  this.loanApplicationId
            };
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.object_Name,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(objdata),
                    recordTypeId: this.recordTypeId,

                }
            });
        } else if (this.metadata == 'TradeReferences' || this.metadata == 'References') {
            //method addedd by lakshya for TradeReferences screen on application object
            var objdata = {
                Loan_Application__c: this.recordId,
            };
            console.log('References objdata>> ',objdata)
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.object_Name,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(objdata),
                    recordTypeId: this.recordTypeId,

                }
            });
        } else if (this.metadata == 'Address' || this.metadataName == 'AddressBL') {
            //method addedd by lakshya for Address screen on applicant object
            //this.parentObjectName = 'Loan_Applicant__c';
            this.isShowAddress = true;
        } else if (this.metadata == 'Document_Information') {

            this.showDocumentModal = true;
            if (this.parentObjectName == 'Lead__c') {
                this.inputVariables = [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    },
                    {
                        name: 'objectApiName',
                        type: 'String',
                        value: this.parentObjectName
                    }
                ];
            }
        } else if (this.metadata == 'Personal_Discussion') {// Added by Mohit on 14-05-2024
            this.showScreenFlow = true;
            this.flowApiName = 'UB_Personal_Discussion_Form';
            this.inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: ''
                },
                {
                    name: 'loanApplicationId',
                    type: 'String',
                    value: this.recordId
                }
            ]
        } else if (this.metadata == 'BL_CIBIL_Obligation') {// Added by Mohit on 14-05-2024
            this.showScreenFlow = true;
            this.flowApiName = 'BL_Create_CIBIL_Obligation_Records';
            this.inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                }
            ]
        } else if (this.metadata == 'Balance_Transfers') {// Added by Manjeet on 16-05-2024
            this.showScreenFlow = true;
            this.flowApiName = 'BL_Balance_Transfer_Creation';
            this.inputVariables = [
                {
                    name: 'loanApplicationID',
                    type: 'String',
                    value: this.recordId
                }
            ]
        }else if (this.metadata == 'Sanction_Conditions') {// Added by Mohit on 04-06-2024
            this.showScreenFlow = true;
            this.flowApiName = 'UB_Create_Sanction_Condition_Record';
            this.inputVariables = [
                {
                    name: 'loanApplicationId',
                    type: 'String',
                    value: this.recordId
                }
            ]
        }
        else if (this.metadata == 'Special_Conditions') {// Added by mansur on 15-07-2024
            this.showScreenFlow = true;
            this.flowApiName = 'UB_Create_Special_Condition_Record';
            this.inputVariables = [
                {
                    name: 'loanApplicationID',
                    type: 'String',
                    value: this.recordId
                }
            ]
             console.log('special condition input>>> > ' + this.inputVariables);
        }
        else if (this.metadata == 'collateral') {//added by mansur alam to create new Collateral record 16-05-2024
            console.log('in collateral> ', this.recordId);
            var objdata = {
                Loan_Application__c: this.recordId,
            };
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.object_Name,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(objdata),
                    //recordTypeId: this.recordTypeId,
                }
            });
        } else if (this.metadata == 'Bank_Details') {
            console.log('Bank_Details>>>>> ', this.recordId);
            console.log('this.recordTypeId>>>>> ', this.recordTypeId);
            console.log('this.recordTypeName>>>>> ', this.recordTypeName);
            if (this.recordTypeName == 'Repayment') {
                var objdata = {
                    Loan_Application__c: this.recordId
                };
            }else if (this.recordTypeName == 'Disbursement') {
                var objdata = {
                    Loan_Application__c: this.recordId
                };
            }else{
                 var objdata = {
                    Loan_Application__c: this.loanApplicationId,
                    Disbursement__c: this.recordId
                };
            }

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.object_Name,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(objdata),
                    recordTypeId: this.recordTypeId,
                }
            });
        }else if(this.metadata == 'E-Nach'){
            setTimeout(() => {
                if(this.eNachResult){
                    this.callENachAPI();
                }
            }, 500);
            console.log('isDisabled@@ ',this.isDisabled);
        }else if(this.metadata == 'Vehicle Asset Collateral API'){
            this.callVehicleAssetCollateralAPI();
        }
    }

    //method addedd by lakshya
    handleAddressClose(event) {
        this.isShowAddress = event.detail;
        //window.location.reload();
    }

    //method addedd by lakshya
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showDocumentModal = false;
            this.showToastMsg('Success', 'Document Created Successfully', 'Success');
            if (this.parentObjectName == 'Lead__c') {
                window.location.reload();
            }
        }
    }

    //added by Mohit on 14-05-2024-- Starts
    handleScreenFlowChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showScreenFlow = false;
            this.publishMessage();
        }
    }

    @wire(MessageContext)
    messageContext;

    publishMessage() {
        let message = { message: this.recordId };
        publish(this.messageContext, SAMPLEMC, message);
    }
    //added by Mohit on 14-05-2024-- Ends

    //method addedd by lakshya
    showToastMsg(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester"
            })
        )
    }
//Added by Mohd Musab on 02-07-2024
    callENachAPI(){
        callENachAPI({ disbursementId: this.recordId})
        .then((result) => {
            console.log('RESULTTTTTT  ', result);
            this.showToastMsg('Success', 'E-Nach Triggered Successfully', 'Success');
          
    }).catch((err) => {
        this.showSpinner = false;
        this.showToastMsg('Application Error', 'Kindly contact your admin!'+' Error-'+err, 'Error');
        console.log('Error in API Verification API @@ ', err);
    });
    }

     //Addedd by Umair on 30th July 24
     callVehicleAssetCollateralAPI(){
        callVehicleAssetCollateralAPI({ disbursementId: this.recordId})
        .then((result) => {
            console.log('RESULTTTTTT  Vehicle>> ', result);
            this.showToastMsg('Success', 'Vehicle Asset and Collateral Triggered Successfully', 'Success');
          
    }).catch((err) => {
        this.showSpinner = false;
        this.showToastMsg('Application Error', 'Kindly contact your admin!'+' Error-'+err, 'Error');
        console.log('Error in  Vehicle API Verification API @@ ', err);
    });
    }


    //Method added by Lakshya
    handleClose() {
        this.showDocumentModal = false;
        this.executeFlow = false;
        this.showScreenFlow = false;
    }

    getRecordIsReadOnlyFromSObject() {
        getRecordIsReadOnlyFromSObject({ recordId: this.recordId, SObjectName: this.parentObjectName })
            .then(result => {
                console.log('getRecordIsReadOnlyFromSObject result -> ', result);
                this.isReadonly = result;
            }).catch(error => {
                console.log('getRecordIsReadOnlyFromSObject error -> ', error);
            })
    }

}