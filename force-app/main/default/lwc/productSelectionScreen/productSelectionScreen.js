import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import PRODUCT_MASTER_OBJECT from "@salesforce/schema/Product_Master__c";
import CATEGORY_FIELD from "@salesforce/schema/Product_Master__c.Product_Category__c";
import checkValidations from '@salesforce/apex/UB_ProductSelectionController.checkValidations';
import fetchDropdownValues from '@salesforce/apex/UB_ProductSelectionController.fetchDropdownValues';
import fetchProductSubCategory from '@salesforce/apex/UB_ProductSelectionController.fetchSubCategoryValues';
import fetchProductRateCodes from '@salesforce/apex/UB_ProductSelectionController.fetchProductRateCodes';
import fetchInterestRange from '@salesforce/apex/UB_ProductSelectionController.fetchInterestRange';
import createProduct from '@salesforce/apex/UB_ProductSelectionController.createProduct';
import SAMPLEMC from "@salesforce/messageChannel/LMSChannel__c";
import { publish, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductSelectionScreen extends LightningElement {
    @api recordId;
    @api loanApplicationId;
    @track isLoading = false;
    @track isShowModal = false;
    @track error;
    @track showNumberOfVehicle = false;
    @track stopMultipleClicks = false;
    @track showBLTemplate = false;
    @track categoryValues;
    @track isInterestTypeFloating = false;
    @track interestRange;

    defaultRecordTypeId;
    sub_categoryValues;
    schemeValues;
    @track dynamicSubCategory = 'Sub-Category';
    @track dynamicSchemes = 'Product Schemes';
    loanPurposeOptions;
    interestTypeOptions;
    rateCodeOptions;
    balanceTransferOptions;
    rateCodesWithIndexRate;

    @track productDetails = this.productDetails = {category : '', subCategory : '', disableCatCombobox : false,
                                                   disableSubCombobox : false, scheme : '', disableScheme : false, 
                                                   numberOfVehicle :1
                                                };

    connectedCallback(){
        this.stopMultipleClicks = false;
        this.isLoading = true;
        this.checkProductValidations();
    }

    @wire(getObjectInfo, { objectApiName: PRODUCT_MASTER_OBJECT })
    results({ error, data }) {
        if (data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.defaultRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$defaultRecordTypeId", fieldApiName: CATEGORY_FIELD })
    picklistResults({ error, data }) {
        if (data) {
            this.categoryValues = data.values;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.categoryValues = undefined;
        }
    }

    checkProductValidations(){
        checkValidations({loanApplicationId : this.loanApplicationId, recordId: this.recordId})
        .then((result) => {
            this.isLoading = false;
            if(result != undefined && result != null){
                console.log('@#result'+result);
                if(result.includes('recordFound#')){
                    var resultParse = JSON.parse(result.replace('recordFound#',''));
                    if(resultParse.lob != 'BL'){
                        this.sub_categoryValues = [{"label": resultParse.subCategory, "value": resultParse.subCategory}];
                        if(resultParse.scheme == 'Retail' || resultParse.scheme == 'Strategic'){
                            this.schemeValues = [{"label": "Retail", "value": "Retail"},
                                                 {"label": "Strategic", "value": "Strategic"}];
                            this.productDetails.category            = resultParse.category; 
                            this.productDetails.subCategory         = resultParse.subCategory; 
                            this.productDetails.disableCatCombobox  = true;
                            this.productDetails.disableSubCombobox  = true;
                            this.productDetails.scheme              = resultParse.scheme;
                            this.productDetails.disableScheme       = false;
                            this.productDetails.numberOfVehicle     = resultParse.numberOfVehicle;
                            this.showNumberOfVehicle = true;
                        }else{
                            this.schemeValues = [{"label": resultParse.scheme, "value": resultParse.scheme}];
                            this.productDetails.category            = resultParse.category; 
                            this.productDetails.subCategory         = resultParse.subCategory; 
                            this.productDetails.disableCatCombobox  =  true;
                            this.productDetails.disableSubCombobox  = true;
                            this.productDetails.scheme              = resultParse.scheme;
                            this.productDetails.disableScheme       = true;
                            this.productDetails.numberOfVehicle     = resultParse.numberOfVehicle;
                            this.showNumberOfVehicle = false;
                        }
                    }else{
                        this.productDetails = {category : '', subCategory : '', disableCatCombobox : false,
                                                disableSubCombobox : false, vertical : 'MSME',
                                                scheme : '', disableScheme : false, numberOfVehicle :0,
                                                rateCode : '', interestType : '', loanPurpose : '',
                                                balanceTransferApplicable : 'No'
                                              };
                        this.categoryValues = [{"label": 'Business Loan', "value": 'Business Loan'}];
                        this.sub_categoryValues = [
                            {"label": 'Business Loan', "value": 'Business Loan'},
                            {"label": 'Business Loan Plus', "value": 'Business Loan Plus'}
                        ];
                        this.fetchSubCategoryValues(resultParse.category, resultParse.subCategory);
                        this.balanceTransferOptions = [
                            {"label": 'Yes', "value": 'Yes'},
                            {"label": 'No', "value": 'No'}
                        ];
                        this.fetchLoanPurposeOptions();
                        this.interestTypeOptions = [
                            {"label": 'Fixed', "value": 'Fixed'},
                            {"label": 'Floating', "value": 'Floating'}
                        ];
                        this.dynamicSubCategory = 'Product Name';
                        this.dynamicSchemes = 'Program';
                        this.schemeValues = [{"label": resultParse.scheme, "value": resultParse.scheme}];
                        this.productDetails.category                  = resultParse.category; 
                        this.productDetails.subCategory               = resultParse.subCategory; 
                        this.productDetails.disableCatCombobox        = true;
                        this.productDetails.disableSubCombobox        = resultParse.category.includes('Business') ? false : true;
                        this.productDetails.scheme                    = resultParse.scheme;
                        this.productDetails.disableScheme             = resultParse.category.includes('Business') ? false : true;
                        if(resultParse.disableInterest){
                            this.fetchRateCodeValues();
                        }else{
                            this.fetchRateOfInterestRange();
                        }
                        this.productDetails.vertical                  = resultParse.vertical;
                        this.productDetails.balanceTransferApplicable = resultParse.balanceTransferApplicable;
                        this.productDetails.loanPurpose               = resultParse.loanPurpose;
                        this.productDetails.interestType              = resultParse.interestType;
                        this.productDetails.rateCode                  = resultParse.rateCode;
                        this.productDetails.rateOfInterest            = resultParse.rateOfInterest;
                        this.productDetails.spread                    = resultParse.spread;
                        this.productDetails.moratoriumPeriod          = resultParse.moratoriumPeriod;
                        this.productDetails.indexRate                 = resultParse.indexRate;
                        this.productDetails.loanAmount                = resultParse.loanAmount;
                        this.productDetails.loanTenure                = resultParse.loanTenure;
                        this.productDetails.disableInterest           = resultParse.disableInterest;
                        this.showNumberOfVehicle                      = false;
                        this.isInterestTypeFloating                   = resultParse.interestType == 'Floating' ? true : false;
                        this.showBLTemplate                           = resultParse.category.includes('Business') ? true : false; 
                    }
                    this.isShowModal = true;
                }else if(!result.includes('Success')){
                    this.showToastMsg('Application Error', result, 'Error');
                    this.handleCloseMethod();
                }else{
                    var resultParse = JSON.parse(result.replace('Success#',''));
                    this.showBLTemplate = resultParse.lob.includes('BL') ? true : false;
                    if(!this.showBLTemplate){
                        const newArr = [...this.categoryValues];
                        newArr.splice(-1);
                        this.categoryValues = [...newArr];
                    }else{
                        this.productDetails = {category : resultParse.category, subCategory : resultParse.subCategory, 
                                               disableCatCombobox : false, vertical : 'MSME',
                                               disableSubCombobox : false, balanceTransferApplicable : 'No',
                                               scheme : '', disableScheme : false, numberOfVehicle :0,
                                               rateCode : '', interestType : '', loanPurpose : '',
                                               loanAmount : resultParse.loanAmount, loanTenure : resultParse.loanTenure
                        };
                        const newArr = [...this.categoryValues];
                        newArr.reverse();
                        newArr.splice(1);
                        this.categoryValues = [...newArr];
                        this.dynamicSubCategory = 'Product Name';
                        this.dynamicSchemes = 'Program';
                        this.sub_categoryValues = [
                            {"label": 'Business Loan', "value": 'Business Loan'},
                            {"label": 'Business Loan Plus', "value": 'Business Loan Plus'}
                        ];
                        this.fetchSubCategoryValues(resultParse.category, resultParse.subCategory);
                        this.balanceTransferOptions = [
                            {"label": 'Yes', "value": 'Yes'},
                            {"label": 'No', "value": 'No'}
                        ];
                        this.fetchLoanPurposeOptions();
                        this.interestTypeOptions = [
                            {"label": 'Fixed', "value": 'Fixed'},
                            {"label": 'Floating', "value": 'Floating'}
                        ];
                    }
                    this.isShowModal = true;
                }
            }else{
                this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
            }
        })
        .catch((error) => {
            this.isLoading = false;
            console.error(error);
        });
    }

    fetchLoanPurposeOptions(){
        fetchDropdownValues({objectApiName : 'Product__c', fieldApiName : 'BL_Purpose_of_Loan__c'  })
        .then((result) => {
            if(result != undefined && result != null){
                this.loanPurposeOptions = [
                    ...result
                ];
                //console.log(JSON.stringify(this.loanPurposeOptions));
            }else{
                this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    handleChangeEvent(event){
        this.stopMultipleClicks = false;
        if(event.target.name == 'category'){
            this.productDetails.category = event.target.value;
            this.productDetails.subCategory = '';
            this.productDetails.scheme = '';
            this.showNumberOfVehicle = false;
            this.productDetails.numberOfVehicle = 1;
            this.sub_categoryValues = [];
            this.schemeValues = [];

            this.fetchSubCategoryValues(this.productDetails.category, this.productDetails.subCategory);
        }else if(event.target.name == 'sub_category'){
            this.productDetails.subCategory = event.target.value;
            this.productDetails.scheme = '';
            this.showNumberOfVehicle = false;
            this.productDetails.numberOfVehicle = 1;
            this.schemeValues = [];
            
            this.fetchSubCategoryValues(this.productDetails.category, this.productDetails.subCategory);
        }else if(event.target.name == 'schemes'){
            this.productDetails.scheme = event.target.value;
            this.showNumberOfVehicle = event.target.value == 'Retail' || event.target.value == 'Strategic' ? true : false;
            this.productDetails.numberOfVehicle = 1;

        }else if(event.target.name == 'numberOfVehicles'){
            this.productDetails.numberOfVehicle = event.target.value;
            if(this.productDetails.scheme != '' && this.productDetails.scheme == 'Retail'){
                if(event.target.value > 0 && event.target.value > 4){
                    this.showToastMsg('Validation', 'Number of vehicles added are not as per the defined policy norms.', 'Error');
                }
            }else if(this.productDetails.scheme != '' && this.productDetails.scheme == 'Strategic'){
                if(event.target.value > 0 && event.target.value < 5){
                    this.showToastMsg('Validation', 'Number of vehicles added are not as per the defined policy norms.', 'Error');
                }
            }
        }else if(event.target.name == 'balanceTransferApplicable'){
            this.productDetails.balanceTransferApplicable = event.target.value;
        }else if(event.target.name == 'loanPurpose'){
            this.productDetails.loanPurpose = event.target.value;
        }else if(event.target.name == 'interestType'){
            this.productDetails.interestType = event.target.value;
            this.isInterestTypeFloating = event.target.value == 'Floating' ? true : false;
            this.productDetails.rateOfInterest = 0;
            if(this.isInterestTypeFloating){
                this.fetchRateCodeValues();
                this.productDetails.disableInterest = true;
            }else{
                this.fetchRateOfInterestRange();
                this.productDetails.disableInterest = false;
            }
        }else if(event.target.name == 'rateCode'){
            this.productDetails.rateCode = event.target.value;
            this.productDetails.indexRate = this.rateCodesWithIndexRate[event.target.value];
            if(this.isInterestTypeFloating){
                let spread    = this.productDetails.spread != '' && this.productDetails.spread > 0 ? this.productDetails.spread : 0;
                let indexRate = this.productDetails.indexRate != '' && this.productDetails.indexRate > 0 ? this.productDetails.indexRate : 0;
                this.productDetails.rateOfInterest = (parseFloat(spread)+parseFloat(indexRate));  
            }
        }else if(event.target.name == 'indexRate'){
            this.productDetails.indexRate = event.target.value;
        }else if(event.target.name == 'rateOfInterest'){
            if(!this.isInterestTypeFloating){
                if(parseFloat(event.target.value) <= 0){
                    this.showToastMsg('Validation Error', 'Kindly provide a valid positive value!', 'Error');
                }
                this.productDetails.rateOfInterest = parseFloat(event.target.value);
            }
        }else if(event.target.name == 'moratoriumPeriod'){
            if(parseInt(event.target.value) <= 0){
                this.showToastMsg('Validation Error', 'Kindly provide a valid positive value!', 'Error');
            }
            this.productDetails.moratoriumPeriod = parseInt(event.target.value);
        }else if(event.target.name == 'loanAmount'){
            if(parseFloat(event.target.value) <= 0){
                this.showToastMsg('Validation Error', 'Kindly provide a valid positive value!', 'Error');
            }
            this.productDetails.loanAmount = parseFloat(event.target.value);
        }else if(event.target.name == 'loanTenure'){
            if(parseInt(event.target.value) <= 0){
                this.showToastMsg('Validation Error', 'Kindly provide a valid positive value!', 'Error');
            }
            this.productDetails.loanTenure = parseInt(event.target.value);
        }else if(event.target.name == 'spread'){
            if(parseFloat(event.target.value) <= 0){
                this.showToastMsg('Validation Error', 'Kindly provide a valid positive value!', 'Error');
            }
            this.productDetails.spread = parseFloat(event.target.value);
            if(this.isInterestTypeFloating && parseFloat(event.target.value) > 0){
                let spread    = this.productDetails.spread != '' && this.productDetails.spread > 0 ? this.productDetails.spread : 0;
                let indexRate = this.productDetails.indexRate != '' && this.productDetails.indexRate > 0 ? this.productDetails.indexRate : 0;
                this.productDetails.rateOfInterest = (parseFloat(spread)+parseFloat(indexRate)); 
            }
        }
        console.log('productDetails '+JSON.stringify(this.productDetails));
    }

    fetchSubCategoryValues(pCategory, pSubCategory){
        fetchProductSubCategory({productCategory : pCategory, productSubCategory : pSubCategory })
        .then((result) => {
            if(result != undefined && result != null){
                if(pSubCategory != ''){
                    this.schemeValues = [
                        ...result
                    ];
                    console.log(JSON.stringify(this.schemeValues));
                }else{
                    this.sub_categoryValues = [
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

    fetchRateCodeValues(){
        fetchProductRateCodes({productDetails : JSON.stringify(this.productDetails) })
        .then((result) => {
            if(result != undefined && result != null){
                console.log('@#'+result);
                let options = [];
                for(let key in result){
                    let temp = {"label" : key, "value" : key};
                    options.push(temp);
                }
                this.rateCodeOptions = options;
                this.rateCodesWithIndexRate = result;
            }else{
                this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
            }
        })
        .catch((error) => {
           console.error(error);
        });
    }

    fetchRateOfInterestRange(){
        fetchInterestRange({productDetails : JSON.stringify(this.productDetails) })
        .then((result) => {
            if(result != undefined && result != null){
                this.interestRange = result;
                this.productDetails.rateOfInterest = parseFloat(result.split('#')[1]);
                console.log('@@@'+this.interestRange);
            }else{
                this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
            }
        })
        .catch((error) => {
           console.error(error);
        });
    }

    validateFields() {
        return [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, field) => validSoFar && field.reportValidity(), true);
    }

    handleSaveMethod(event){
        this.isLoading = true;
        if(this.productDetails.category == '' || this.productDetails.subCategory == '' || this.productDetails.scheme  == ''){
            this.showToastMsg('Application Warning', 'Kindly fill all mandatory fields to proceed further!', 'Warning');
        }else if(this.showBLTemplate && (this.productDetails.interestType == '' || (this. isInterestTypeFloating && this.productDetails.rateCode == '') || this.productDetails.loanPurpose == '' || !this.validateFields())){
            this.showToastMsg('Application Warning', 'Kindly fill all mandatory fields to proceed further!', 'Warning');
        }else if(!this.showBLTemplate && this.productDetails.numberOfVehicle <= 0){
            this.showToastMsg('Application Validation', 'Please provide valid input in Number of Vehicles!', 'Warning');
        }else if(!this.showBLTemplate && ((this.productDetails.scheme == 'Strategic') && (this.productDetails.numberOfVehicle == undefined || this.productDetails.numberOfVehicle == null || this.productDetails.numberOfVehicle == '' || this.productDetails.numberOfVehicle <= 0))){
            this.showToastMsg('Application Warning', 'Number of Vehicles is mandatory if Product Schemes is strategic.', 'Warning');
        }else if(!this.showBLTemplate && (this.productDetails.scheme == 'Retail' && (this.productDetails.numberOfVehicle <= 0 || this.productDetails.numberOfVehicle > 4))){
            this.showToastMsg('Validation', 'Number of vehicles added are not as per the defined policy norms.', 'Error');
        }else if(!this.showBLTemplate && (this.productDetails.scheme == 'Strategic' && (this.productDetails.numberOfVehicle <= 0 || this.productDetails.numberOfVehicle < 5))){
            this.showToastMsg('Validation', 'Number of vehicles added are not as per the defined policy norms.', 'Error');
        }else if(this.showBLTemplate && !this.isInterestTypeFloating && (this.productDetails.rateOfInterest < this.interestRange.split('#')[0] || this.productDetails.rateOfInterest > this.interestRange.split('#')[1])){
            this.showToastMsg('Validation Error', 'Kindly provide rate of interest within specified range!', 'Error');
        }else if(this.showBLTemplate && this.productDetails.loanAmount <= 0 || this.productDetails.moratoriumPeriod <= 0 || this.productDetails.rateOfInterest <= 0){
            this.showToastMsg('Validation Error', 'Kindly provide a valid positive value in Applied Loan Amount, Rate of Interest, and Moratorium Period fields!', 'Error');
        }else{
            
            if(!this.stopMultipleClicks){
                this.stopMultipleClicks = true;
                createProduct({recordId : this.recordId, loanApplicationId : this.loanApplicationId, productDetails : JSON.stringify(this.productDetails)})
                .then((result) => {
                    this.isLoading = false;
                    this.isShowModal = false;
                    this.handleCloseMethod();
                    if(result != undefined && result != null && result.includes('Success')){
                        this.showToastMsg('Success', 'Product record created successfully!', 'Success');
                        this.publishMessage();
                    }else if(result != undefined && result != null){
                        this.showToastMsg('Application Error', result, 'Error');
                    }else{
                        this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
                    }
                })
                .catch((error) => {
                console.error(error);
                });
            }
        }
    }

    @wire(MessageContext)
    messageContext;

    publishMessage() {
        let message = { message: this.loanApplicationId };
        publish(this.messageContext, SAMPLEMC, message);
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

    handleCloseMethod(){
        this.isShowModal = false;
        // Creates the event with the data.
        const selectedEvent = new CustomEvent("closecmp", {
            detail: this.isShowModal
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}