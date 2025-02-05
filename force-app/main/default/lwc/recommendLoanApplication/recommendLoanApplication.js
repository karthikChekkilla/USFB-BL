import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import recommendDeviations from "@salesforce/apex/UB_ManualDeviationController.recommendDeviations";
import checkValidations from "@salesforce/apex/UB_LoanApplicationMoveToNextController.checkValidations";
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import UserRoleName from '@salesforce/schema/User.UserRole.Name';
import { getRecord } from 'lightning/uiRecordApi';
export default class RecommendLoanApplication extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showSpinner = false;
    @track isValidation = false; 
    @track validationMsg;
    @track value = '';
    @track isRecordId;
    @track authorityValue = '';
    @track isConfirmModel = false;
    @track userProfileName = '';
    @track options;
    @track userRoleName = '';

    @wire(CurrentPageReference)
    getLAFId(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('recordId-> ', this.recordId);
            this.checkValidations();
        }
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName, UserRoleName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        }else if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                this.userRoleName = data.fields.UserRole.value.fields.Name.value;
                if(this.userRoleName == 'Regional Credit Manager' || this.userProfileName == 'System Administrator'){
                    this.options = [
                        { label: 'National Credit Manager', value: 'National Credit Manager' },
                        { label: 'Zonal Credit Manager', value: 'Zonal Credit Manager' },
                        { label: 'Credit Head', value: 'Credit Head' },
                    ];
                }else if(this.userRoleName == 'Zonal Credit Manager' || this.userProfileName == 'System Administrator'){
                    this.options = [
                        { label: 'National Credit Manager', value: 'National Credit Manager' },
                        { label: 'Credit Head', value: 'Credit Head' },
                    ];
                }else if(this.userRoleName == 'National Credit Manager' || this.userProfileName == 'System Administrator'){
                    this.options = [
                        { label: 'Credit Head', value: 'Credit Head' },
                    ];
                }
                console.log('this.userProfileName ', this.userProfileName);
                console.log('this.options recommendLoanApplication.js ', this.options); 
            }
        }
    }

    checkValidations(){ 
            checkValidations({ recordId: this.recordId, buttonLabel : 'Recommend' })
                .then((result) => {
                    console.log('result === > ',result);
                    if(result){
                        this.isValidation = true;
                        this.isConfirmModel = false;
                        this.validationMsg = '<ul>'+result+'</ul>';
                    }
                    else{
                        this.isValidation = false;
                        this.isConfirmModel = true;
                    }
                    this.showSpinner =false;                   
                })
                .catch((error) => {
                    console.log('Error:'+error);
                    console.log('Error:'+ JSON.stringify(error));
                    this.showToastMessage('Error', error, 'error');
                    this.showSpinner =false; 
                    
                });
         
        } 
    
    /*get options() {
        return [
            { label: 'National Credit Manager', value: 'National Credit Manager' },
            { label: 'Zonal Credit Manager', value: 'Zonal Credit Manager' },
            { label: 'Credit Head', value: 'Credit Head' },
        ];
    }*/


    connectedCallback() {
        console.log('recordId-> ', this.recordId);
        //this.getPendingDeviations();
    }


    showToastMessage(title, message, variant) {
        this.showSpinner =false; 
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
    
    handleSave(){
        this.authorityValue = this.template.querySelector('.authority').value;
        console.log('authorityValue-> ', this.authorityValue);
        this.recommendDeviations();
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    // Close quick action popup
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showSpinner =false; 
        this.isValidation = false;
        
    }

    recommendDeviations(){
        recommendDeviations({authorityName : this.authorityValue, loanApplicationId : this.recordId})
        .then(result =>{
            console.log('recommendDeviations result-> ' , result);
            if(result.isSuccess){
                this.closeQuickAction();
                this.isConfirmModel = false;
                this.showToastMessage('Success', result.responseBody, 'Success');
                setInterval(() => {
                    window.location.reload();
                }, 500);
            }else{
                this.isConfirmModel = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToastMessage('Error', result.responseBody, 'Error');
            }
        }).catch(error =>{
            this.showToastMessage('Error', error, 'error');
            this.showSpinner =false; 
            this.isConfirmModel = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            console.log('recommendDeviations error-> ' , error);
        })
    }


}