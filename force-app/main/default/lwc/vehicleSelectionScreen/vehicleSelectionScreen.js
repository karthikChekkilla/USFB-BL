import { LightningElement, api, track, wire } from 'lwc';
import getPicklistValues from '@salesforce/apex/UB_VehicleSelectionController.fetchPicklistValues';
import fetchVahanDetails from '@salesforce/apex/UB_Vahan_API.fetchVahanDetails';
import fetchVehileMasterId from '@salesforce/apex/UB_VehicleSelectionController.fetchVehicleMasterId';
import fetchVehileProductCategory from '@salesforce/apex/UB_VehicleSelectionController.fetchVehicleProductInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VehicleSelectionScreen extends LightningElement {
    @api loanApplicationId;
    @api productId;
    @api productCategory;
    @api vehicleId;
    @api vehicleRecordTypeId;
    @track isLoading = false;
    @track isShowModal = false;
    @track isUsedProduct = false;
    @track isCVProduct = false;
    @track vahanDetails = {};
    @track isReadOnly = true; 
    makeValues;
    modelValues;
    vehicleTypeValues;
    fuelTypeValues;
    bodyTypeValues;
    vehicleDetails = {};
    activeSection = 'A';

    connectedCallback(){
        this.isShowModal = true;
        console.log('vehicleId'+this.vehicleId);
        if(this.vehicleId != undefined){
            fetchVehileProductCategory({vehicleId : this.vehicleId })
            .then((result) => {
                if(result != null && result != undefined){
                    this.isCVProduct = JSON.stringify(result.productCategory).includes('CV') ? true : false;
                    this.isUsedProduct = JSON.stringify(result.productCategory).includes('Used') ? true : false;
                    this.activeSection = this.isUsedProduct ? 'B' : 'A';
                    this.productCategory = JSON.stringify(result.productCategory);
                    //this.vahanDetails = result;
                    console.log('vahanDetails'+JSON.stringify(this.vahanDetails));
                    if(JSON.stringify(result).includes('makeValues')){
                        this.makeValues = [
                            ...result.makeValues
                        ];
                    }
                    if(JSON.stringify(result).includes('modelValues')){
                        this.modelValues = [
                            ...result.modelValues
                        ];
                    }
                    if(!this.isUsedProduct){
                        if(JSON.stringify(result).includes('vehicleTypeValues')){
                            this.vehicleTypeValues = [
                                ...result.vehicleTypeValues
                            ];
                        }
                        if(JSON.stringify(result).includes('fuelTypeValues')){
                            this.fuelTypeValues = [
                                ...result.fuelTypeValues
                            ];
                        }
                        if(JSON.stringify(result).includes('bodyTypeValues')){
                            this.bodyTypeValues = [
                                ...result.bodyTypeValues
                            ];
                        }
                    }
                    this.vahanDetails.productId = result.productId;
                    this.vehicleDetails.make = result.make;
                    this.vehicleDetails.model = result.model;
                    if(!this.isUsedProduct){
                        this.vehicleDetails.type = result.type;
                        this.vehicleDetails.fuelType = result.fuelType;
                        this.vehicleDetails.bodyType = result.bodyType;
                    }
                }
            })
            .catch((error) => {
                console.error(error);
            });
        }else{
            if(this.productCategory != undefined && this.productCategory != ''){
                this.isCVProduct = this.productCategory.includes('CV') ? true : false;
                this.isUsedProduct = this.productCategory.includes('Used') ? true : false;
                this.activeSection = this.isUsedProduct ? 'B' : 'A';
                this.fetchPicklistValues();
            }    
        }        
    }

    fetchPicklistValues(){
        console.log('VehicleID '+this.vehicleId);
        console.log('productID '+JSON.stringify(this.vehicleDetails));
        console.log('productID '+JSON.stringify(this.vehicleDetails).includes('productId'));
        console.log('productID '+this.vehicleDetails.productId);
        getPicklistValues({vehicleDetails : JSON.stringify(this.vehicleDetails), productId : this.vehicleDetails != {} && JSON.stringify(this.vehicleDetails).includes('productId') ? this.vehicleDetails.productId : this.productId })
        .then((result) => {
            if(result != undefined && result != null){
                if(JSON.stringify(this.vehicleDetails).includes('make') && this.vehicleDetails.model == ''){
                    this.modelValues = [
                        ...result
                    ];
                }else if(JSON.stringify(this.vehicleDetails).includes('model') && this.vehicleDetails.type == ''){
                    this.vehicleTypeValues = [
                        ...result
                    ];
                }else if(JSON.stringify(this.vehicleDetails).includes('type') && this.vehicleDetails.fuelType == ''){
                    this.fuelTypeValues = [
                        ...result
                    ];
                }else if(JSON.stringify(this.vehicleDetails).includes('fuelType') && this.vehicleDetails.bodyType == ''){
                    this.bodyTypeValues = [
                        ...result
                    ];
                }else{
                    this.makeValues = [
                        ...result
                    ];
                }
            }else{
                this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    handleChangeEvent(event){
        if(event.target.name == 'make'){
            this.vehicleDetails.make = event.target.value;
            this.modelValues = {};
            this.vehicleTypeValues = {};
            this.fuelTypeValues = {};
            this.bodyTypeValues = {};
            this.vehicleDetails.model    = '';
            this.vehicleDetails.type     = '';
            this.vehicleDetails.fuelType = '';
            this.vehicleDetails.bodyType = '';
            this.fetchPicklistValues();
        }else if(event.target.name == 'model'){
            this.vehicleDetails.model = event.target.value;
            this.vehicleTypeValues = {};
            this.fuelTypeValues = {};
            this.bodyTypeValues = {};
            this.vehicleDetails.type     = '';
            this.vehicleDetails.fuelType = '';
            this.vehicleDetails.bodyType = '';
            this.fetchPicklistValues();
        }else if(event.target.name == 'vehicleType'){
            this.vehicleDetails.type = event.target.value;
            this.fuelTypeValues = {};
            this.bodyTypeValues = {};
            this.vehicleDetails.fuelType = '';
            this.vehicleDetails.bodyType = '';
            this.fetchPicklistValues();
        }else if(event.target.name == 'fuelType'){
            this.vehicleDetails.fuelType = event.target.value;
            this.bodyTypeValues = {};
            this.vehicleDetails.bodyType = '';
            this.fetchPicklistValues();
        }else if(event.target.name == 'bodyType'){
            this.vehicleDetails.bodyType = event.target.value;
        }else if(event.target.name == 'tenure'){
            this.vehicleDetails.tenure = event.target.value;
        }else if(event.target.name == 'cost'){
            this.vehicleDetails.cost = event.target.value;
        }else if(event.target.name == 'roi'){
            this.vehicleDetails.roi = event.target.value;
        }else if(event.target.name == 'numberOfVehicles'){
            this.vehicleDetails.numberOfVehicles = event.target.value;
        }else if(event.target.name == 'registrationNumber'){
            this.vehicleDetails.registrationNumber = event.target.value;
        }else if(event.target.name == 'updateVahanDetails'){
            this.isReadOnly = event.target.value ? false: true; 
        }
        console.log('vehicleDetails@'+JSON.stringify(this.vehicleDetails));
    }

    handleSearch(event){
        this.isLoading = true;
        this.activeSection = 'B';
        this.fetchVehicleInfo();
    }

    fetchVehicleInfo(){
        this.isLoading = true;
        console.log('$$$'+this.vehicleDetails.registrationNumber);
        fetchVahanDetails({ loanApplicationId : this.loanApplicationId, registrationNumber : this.vehicleDetails.registrationNumber })
        .then((result) => {
            this.isLoading = false;
            if(result != undefined && result != null){
                this.vahanDetails = result;
                console.log('@@@'+this.vahanDetails);
                console.log('@@@'+result);
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    handleSubmit(event){
        event.preventDefault();

        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

        if(All_Compobox_Valid){
            if(!this.isUsedProduct || (this.isUsedProduct && this.vehicleDetails.model != undefined)){//Object.keys(this.vahanDetails) === 0
                //fetch Vehicle Master record Id
                fetchVehileMasterId({ vehicleModel : this.vehicleDetails.model })
                .then((result) => {
                    if(result != undefined && result != null){
                        event.detail.fields.Loan_Application__c = this.loanApplicationId;
                        event.detail.fields.Product__c          = this.productId;
                        if(this.vehicleDetails.make != undefined && this.vehicleDetails.model != undefined){
                            event.detail.fields.Name            = this.vehicleDetails.make +' '+ this.vehicleDetails.model;
                        }else{
                            event.detail.fields.Name            = this.vahanDetails.Registration_Number__c;
                        }
                        event.detail.fields.Make__c             = this.vehicleDetails.make;
                        event.detail.fields.Model__c            = this.vehicleDetails.model;
                        event.detail.fields.Vehicle_Type__c     = this.vehicleDetails.type;
                        event.detail.fields.Fuel_Type__c        = this.vehicleDetails.fuelType;
                        event.detail.fields.Body_Type__c        = this.vehicleDetails.bodyType;
                        event.detail.fields.Vehicle_Master__c   = result;
        
                        //Vahan Information
                        this.template.querySelector('lightning-record-edit-form').submit(event.detail.fields);
                        this.showToastMsg('Success', 'Vehicle Information is added successfully!', 'Success');
                        setTimeout(() => {
                            this.handleCloseMethod();
                            location.reload();
                        }, 1000);
                    }else{
                        this.showToastMsg('Warning', 'Oops! The requested vehicle model could not be found. Please contact your administrator for further assistance.', 'Warning');
                    }
                })
                .catch((error) => {
                    console.error(error);
                });
            }else{
                this.showToastMsg('Warning', 'Please fetch vahan details to proceed further!', 'Warning');
            }
        }else{
            this.showToastMsg('Warning', 'Please provide all required information to create vehicle record!', 'Warning');
        }
    }
    
    checkNumberValidty(inputVar){
        return inputVar <= 0 ? true : false;
    }

    handleCloseMethod(){
        this.isShowModal = false;
        // Creates the event with the data.
        const selectedEvent = new CustomEvent("closecmp", {
            detail: this.isShowModal
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
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
}