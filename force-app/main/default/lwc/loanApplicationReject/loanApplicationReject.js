import { LightningElement, api, track, wire } from 'lwc';

import { CloseActionScreenEvent } from 'lightning/actions';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getUserManager from "@salesforce/apex/UB_LoanApplicationRejectController.getUserManager";

import getRejectReasonsList from "@salesforce/apex/UB_LoanApplicationRejectController.getRejectReasonsList";

import Id from "@salesforce/user/Id";

import captureRejectResponse from "@salesforce/apex/UB_LoanApplicationRejectController.captureRejectResponse";

import { getRecord } from 'lightning/uiRecordApi';

import { CurrentPageReference } from 'lightning/navigation';

import LOB_FIELD from "@salesforce/schema/Loan_Application__c.LOB__c";

export default class LoanApplicationReject extends LightningElement {

    @api recordId;

    @track ownerId;

    @track applicationLob = '';

    currentUserId = Id;

    @track rejectReasons = [];

    @track rejectSubReasons = [];

    @track rejectSectionBL = false;

    @track rejectSectionCV = false;

    @track showSpinner = false;

    @track rejectReasonValues = '';

    @track rejectSubReasonValues = '';

    @track commentsValue = '';

    @track tempResultRejection = [];

    @track varRejection = [];

    @api objectApiName;

    @track recordTypeName = '';

    @track blRejectType = '';

    rejectTypeOptions = [{ label: 'Soft', value: 'Soft' },

    { label: 'Hard', value: 'Hard' },];



    connectedCallback() {

        /* getUserManager()
 
         .then((result) => {
 
             this.ownerId = result;
 
         })
 
         .catch((error) => {
 
             console.log(' error  ', error);
 
         });*/



    }



    @wire(CurrentPageReference)

    getLAFId(currentPageReference) {

        console.log('currentPageReference-> ', currentPageReference);

        if (currentPageReference) {

            if (currentPageReference.state.recordId) {

                this.recordId = currentPageReference.state.recordId;

            } else if (currentPageReference.attributes.recordId) {

                this.recordId = currentPageReference.attributes.recordId;

            }

            console.log('recordId-> ', this.recordId);

        }

    }



    @wire(getRecord, { recordId: "$recordId", fields: [LOB_FIELD] })

    getApplications({ error, data }) {

        if (error) {

            console.log('error-> ', error);

        } else if (data) {

            console.log('data-> ', data);

            console.log('recordTypeInfo-> ', data.recordTypeInfo.name);

            if (data.recordTypeInfo.name != null) {

                this.recordTypeName = data.recordTypeInfo.name;

            }

            if (data.fields.LOB__c.value != null) {

                this.applicationLob = data.fields.LOB__c.value != null ? data.fields.LOB__c.value : '';

                console.log('applicationLob-> ', this.applicationLob);

                if (this.applicationLob == 'BL') {

                    this.rejectSectionBL = true;

                    this.getRejectReasonsList();

                } else if (this.applicationLob == 'CV' || this.applicationLob == 'CE') {

                    this.rejectSectionCV = true;

                }

            }

        }

    }



    handleSubmit(event) {

        event.preventDefault();

        const fields = event.detail.fields;

        console.log("Fields: ", fields.Reject_Reason__c);

        if (fields.Reject_Reason__c == 'Any Other Reasons' && !fields.Comment__c) {

            this.showToastMessage('Error', 'Comment is required for Other reason.', 'error');

            return;

        }

        fields.Loan_Application_Status__c = 'Rejected';

        /* if(his.ownerId != this.currentUserId){
 
             fields.OwnerId= this.ownerId;
 
         }
 
         fields.Rejected_By__c= this.currentUserId;*/

        this.template.querySelector('lightning-record-edit-form').submit(fields);

    }



    showToastMessage(title, message, variant) {

        this.dispatchEvent(

            new ShowToastEvent({

                title: title,

                message: message,

                variant: variant,

            }),

        );

    }



    handleSuccess() {

        this.showToastMessage('Success', 'Loan Application rejected successfully.', 'success');

        this.closeQuickAction();

    }



    closeQuickAction(event) {

        this.rejectSectionCV = false;

        this.rejectSectionBL = false;

        this.showSpinner = false;

        this.dispatchEvent(new CloseActionScreenEvent());
        //event.preventDefault();
        const selectedEvent = new CustomEvent("close", { detail: false });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

    }



    //method added on 29-07-2024 by lakshya for getting the values of reject reasons for BL project

    getRejectReasonsList() {

        getRejectReasonsList()

            .then(result => {

                console.log('result getRejectReasonsList-> ', result);

                if (result != null && result != undefined) {

                    this.rejectReasons = [];

                    this.tempResultRejection = result;

                    for (let key in result) {

                        //this.rejectReasons.push({ label: key, value: key });

                        console.log('result key-> ', result[key].Rejection_Reason__c);

                        if (result[key].Rejection_Reason__c != null) {

                            this.rejectReasons.push({ label: result[key].Rejection_Reason__c, value: result[key].Rejection_Reason__c });

                        }

                    }

                    //console.log('if this.rejectReasons-> ', JSON.stringify(this.rejectReasons));

                } else {

                    this.rejectReasons = null;

                    console.log('else this.rejectReasons-> ', this.rejectReasons);

                }

            })

            .catch(error => {

                console.log('error rejectReasons-> ', error);

            }).finally(() => {



            });

    }











    handleReasons(event) {

        this.rejectReasonValues = event.detail.value;

        console.log('this.rejectReasonValues ', this.rejectReasonValues);

        this.varRejection = this.tempResultRejection.filter(res =>

            res.Rejection_Reason__c == this.rejectReasonValues

        )



        for (let key in this.varRejection) {

            this.rejectSubReasons = [];

            console.log('varRejection', this.varRejection[key].Rejection_Sub_Reason__c);

            if (this.varRejection[key].Rejection_Sub_Reason__c != null) {

                this.rejectSubReasons.push({ label: this.varRejection[key].Rejection_Sub_Reason__c, value: this.varRejection[key].Rejection_Sub_Reason__c });

            }

        }



    }



    handleSubReasons(event) {

        this.rejectSubReasonValues = event.detail.value;

        console.log('this.handleSubReasons ', this.rejectReasonValues);



    }

    handleRejectType(event) {

        this.blRejectType = event.detail.value;

        console.log('this.blRejectType ', this.blRejectType);

    }



    onchangeComments(event) {

        this.commentsValue = event.detail.value;

        console.log('this.commentsValue ', this.commentsValue);

    }





    handelSave() {

        this.showSpinner = true;

        //if(this.checkValidation()){

        //this.showSpinner = true; 

        //let reasons = this.template.querySelector('.reasons').value;

        //let subReasons = this.template.querySelector('.sub-reasons').value;

        //let comments = this.template.querySelector('.comments').value;

        console.log('this.rejectReasonValues ', this.rejectReasonValues);

        console.log('this.rejectSubReasonValues ', this.rejectSubReasonValues);

        console.log('this.commentsValue ', this.commentsValue);

        //}else{

        // this.showSpinner = false; 

        //}    

        this.captureRejectResponse();



    }



    checkValidation() {

        let inputElement = this.template.querySelectorAll('.requiredField');

        let isValid = true;

        inputElement.forEach(element => {

            let isValidOrNot = element.reportValidity();

            console.log('isValidOrNot ', isValidOrNot);

            if (!isValidOrNot && isValid) {

                isValid = isValidOrNot;

            }

        });

        return isValid;

    }



    //method added on 29-07-2024 by lakshya for getting the values of reject reasons for BL project

    captureRejectResponse() {

        captureRejectResponse({
            lafId: this.recordId, reasons: this.rejectReasonValues,

            subReasons: this.rejectSubReasonValues, comments: this.commentsValue, recordTypeName: this.recordTypeName, rejectType: 'Soft'
        })

            .then(result => {

                console.log('result captureRejectResponse-> ', result);

                if (result != null && result != undefined) {

                    if (result.isSuccess) {

                        this.showToastMessage('Success', 'Successfully Rejected', 'success');

                        this.closeQuickAction();

                        setInterval(() => {

                            window.location.reload();

                        }, 2000);



                    } else {

                        this.showToastMessage('Error', 'Something went wrong!!', 'error');

                        this.showSpinner = false;

                    }

                } else {

                    this.rejectReasons = null;

                    console.log('else captureRejectResponse-> ');

                    this.showToastMessage('Error', 'Something went wrong!!', 'error');

                    this.showSpinner = false;

                }

            })

            .catch(error => {

                console.log('error captureRejectResponse-> ', error);

                this.showToastMessage('Error', error, 'error');

                this.showSpinner = false;

            }).finally(() => {



            });

    }

}