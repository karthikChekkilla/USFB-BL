import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import getSectionAndFields from '@salesforce/apex/UB_GenericRecordEditFormController.getSectionAndFields';
import getPinCodeDetails from '@salesforce/apex/UB_AddressComponentController.getPinCodeDetails';
export default class GenericRecordEditForm extends LightningElement {
    @api editRecordId;
    @api recordId;
    @track fields;
    @track isRedFlag = false;
    @track isRedFlagModal = false;
    @api customerRecordId;
    @api objectName;
    @api defaultValues = [];    // From collateral LWC
    @api recordInfo = [];
    @api extraFields;           // Fields That We Wants To Show Before Metadata Fields (From collateral LWC)
    @api sectionName = 'Document_Information';           // Above Fields Show in Which Section (From collateral LWC)
    @api recordTypeName;
    @track sectionWithfields = [];
    @track applicationProductId = '';
    @track userProfileName = '';
    @track oppStageName;
    @track isShowModal;
    isDisabled = false;
    selectedRecordTypeId = '';
    recordTypeOptions = [];
    isShow = true;
    showSpinner = false;
    activeSections = [];//['Collateral_Information'];
    addressObj = {
        City: '',
        State: '',
        Country: '',
        District: ''
    };

    handleClose() {
        //this.isShow = false;
        //this.isRedFlagModal = false;
        //eval("$A.get('e.force:refreshView').fire();");
        const selectedEvent = new CustomEvent('close', {
            detail : false, 
            bubbles: true, 
            composed: true 
        });
        this.dispatchEvent(selectedEvent);
        
        /*this.dispatchEvent(
            new CustomEvent('close', { detail: { isShowModal: false }, bubbles: true, composed: true })
        );*/
    }
    async connectedCallback() {
        console.log('objectName', this.objectName);
        console.log('editRecordId', this.customerRecordId);
        console.log('recordId->', this.recordId);
        this.getRedFlagCustomer();
        console.log('result recordInfo connectedCallback-> ', JSON.stringify(this.defaultValues));
        this.showSpinner = true;
        
        /*if(this.objectName == 'Collateral__c' && this.editRecordId){
            this.get
        }else{*/
        this.getSectionAndFields();
        //}

    }

    getSectionAndFields() {
        getSectionAndFields({ objectName: this.objectName })
            .then(result => {
                console.log('result getSectionAndFields=> ', result);
                let resultList = [];
                for (var section of result) {
                    let obj = {
                        DeveloperName: section.formSection.DeveloperName,
                        Id: section.formSection.Id,
                        MasterLabel: section.formSection.MasterLabel,
                        Sort_Order_Number__c: section.formSection.Sort_Order_Number__c,
                        Section_Fields__r: section.sectionField,
                        Show_Form_Condition__c: section.formSection.Show_Form_Condition__c
                    };
                    resultList.push(obj);
                }
                console.log('resultList-> ', resultList);
                /*if (this.defaultValues && this.defaultValues['StageName']) {
                    console.log('Stage >>   ', this.defaultValues['StageName']);
                    this.oppStageName = this.defaultValues['StageName'];
                }*/ 
                for (var section of resultList) {
                    section['isShow'] = true;
                    this.activeSections.push(section.DeveloperName); // Open All Sections By Default
                    // Added More Fields Before Metadata Fields.
                    console.log('Stage >>   ', section.DeveloperName);
                    console.log('section.Section_Fields__r ', section.Section_Fields__r);
                    if (section.DeveloperName == this.sectionName) {
                        //console.log('this.extraFiels ', JSON.parse(JSON.stringify(this.extraFields)));
                        //let fields = JSON.parse(JSON.stringify(this.extraFields));//[{Field_API_Name__c : 'Application__c', is_Ready_Only__c: true, is_Required__c: true},{Field_API_Name__c : 'Asset__c', is_Ready_Only__c: true, is_Required__c: true},{Field_API_Name__c : 'Application_Product__c', is_Required__c: true, dataType: 'Picklist'}];
                        //section.Section_Fields__r = [...fields, ...section.Section_Fields__r];
                        
                    } 
                    if (section && section.Section_Fields__r) {
                        for (var field of section.Section_Fields__r) {
                            console.log('field-> ' , field);
                            if (this.defaultValues[field.Field_API_Name__c] != '') {
                                field['value'] = this.defaultValues[field.Field_API_Name__c];
                                if(field.Field_API_Name__c == 'Lead__c'){
                                    //field['is_Ready_Only__c'] = false; 
                                    //field['is_Required__c'] = false;
                                    //field['value'] = this.recordId;
                                     field['value'] = this.defaultValues['Lead__c'];
                                }if(field.Field_API_Name__c == 'Loan_Applicant__c'){
                                   field['value'] = this.defaultValues['Loan_Applicant__c'];
                                }if(field.Field_API_Name__c == 'Account__c'){
                                   field['value'] = this.defaultValues['Account__c'];
                                }if(field.Field_API_Name__c == 'Loan_Application__c'){
                                   field['value'] = this.defaultValues['Loan_Application__c'];
                                }
                            }
                            //field['isShow'] = true;
                            //field['isDisabled'] = false;
                            //console.log('Data type of Field'+field.Data_Type__c);
                            //field['isDate'] = field.Data_Type__c=='Date'?true:false;
                            //console.log('Field 116'+field+'-type-'+field['isDate']);
                            //console.log('field.Field_API_Name__c', field.Field_API_Name__c);
                            //if (this.defaultValues[field.Field_API_Name__c] != '') {
                              //  console.log('field.Field_API_Name__c-> ' , field.Field_API_Name__c);
                                //console.log('defaultValues : ', this.defaultValues);
                                //this.recordInfo[field.Field_API_Name__c] = this.defaultValues[field.Field_API_Name__c];
                                //field['value'] = this.defaultValues[field.Field_API_Name__c];

                                /*if (field.Field_API_Name__c == 'MF_ROC_Check__c' || field.Field_API_Name__c == 'MF_CERSAI_Check__c') {
                                    this.recordInfo[field.Field_API_Name__c] = this.defaultValues['roc_Value'];
                                    field['value'] = this.defaultValues['roc_Value'];
                                }
                                if (field.Field_API_Name__c == 'MF_CERSAI_Check__c') {
                                    this.recordInfo[field.Field_API_Name__c] = this.defaultValues['cersai_Value'];
                                    field['value'] = this.defaultValues['cersai_Value'];
                                }

                                if (field.Field_API_Name__c == 'Application__c') {
                                    if (this.defaultValues[field.Field_API_Name__c] && this.objectName == 'Collateral__c') {
                                        console.log('INN : ', this.defaultValues[field.Field_API_Name__c]);
                                        this.getAppValues(this.defaultValues[field.Field_API_Name__c]);
                                    }
                                }*/

                           /* } else {
                                this.recordInfo[field.Field_API_Name__c] = '';
                                field['value'] = '';
                            }*/
                        }
                    }
                }

                console.log('RecordTypeId', this.selectedRecordTypeId);
                if (this.selectedRecordTypeId) {
                    this.recordInfo['RecordTypeId'] = this.selectedRecordTypeId;
                }
                console.log('recordInfo ', this.recordInfo);
                this.sectionWithfields = resultList;
                console.log('sectionWithfields :', this.sectionWithfields);
                if (this.objectName == 'Collateral__c' && this.editRecordId) {
                    let recInfoFields = '';
                    for (let key in this.recordInfo) {
                        recInfoFields += ', ' + key;
                    }
                    console.log('recInfoFields=> ', recInfoFields);
                    this.getInsertedRecords(recInfoFields);
                } else {
                    this.updateFieldsVisibility();
                }
            })
            .catch(error => {
                console.log('Error1= ', error);
                if (error && error.body && error.body.message) {
                    console.log('Error1= ', error.body.message);
                }
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    // When Record Open in Edit Mode It Will Call.
    getInsertedRecords(recInfoFields) {
        
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            console.log('DATA >> ', data);
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
        }
    }



    handleOnChange(event) {
        this.isDisabled = false;
        let name= typeof event.target.fieldName == "undefined"?event.target.name:event.target.fieldName;
        this.recordInfo[name] = event.target.value;
        console.log('name ', name + ' val' + event.target.value);
        if (this.objectName === 'Asset__c') {
            console.log('objectName ', this.objectName);
            if (event.target.fieldName === 'Pin_Code__c') {
                if(event.target.value != ''){
                    console.log('inside pincode if');
                    getPinCodeDetails({ pinCodeId: event.target.value })
                    .then(result => {
                        console.log('result getRecord=> 1 ', JSON.stringify(result));
                        if (result && result.Id) {
                            if (result.city__c) {
                                this.addressObj.City = (result.city__r.Name) ? result.city__r.Name : '';
                                if (result.city__r.District__c) {
                                    this.addressObj.District = result.city__r.District__r.Name ? result.city__r.District__r.Name : '';
                                    if (result.city__r.District__r.State__c) {
                                        this.addressObj.State = (result.city__r.District__r.State__r.Name) ? result.city__r.District__r.State__r.Name : '';
                                        if (result.city__r.District__r.State__r.Country__c) {
                                            this.addressObj.Country = (result.city__r.District__r.State__r.Country__r.Name) ? result.city__r.District__r.State__r.Country__r.Name : '';
                                        }
                                    }
                                }
                            }
                            console.log('addressObj' + JSON.stringify(this.addressObj) + 'City' + this.addressObj.City);
                            this.doAssignValues(event);
                        }
                    })
                    .catch(error => {
                        console.log('Error= ', error);
                        console.log('Error= ', error.body.message);
                    }).finally(() => {
                        //this.showSpinner = false;
                    });
                }else{
                    console.log('inside pincode else');
                    this.addressObj.City = '';
                    this.addressObj.District = '';
                    this.addressObj.State = '';
                    this.addressObj.Country = '';
                    this.doAssignValues(event);
                }
            }
            else {
                this.doAssignValues(event);
            }
        } else {
            this.doAssignValues(event);
        }
    }

    // CH01:Tarun| 12 Dec 2023 -> moved the assignmednt values logic in this method as i need to call this method after retrived the pincode data to pre populate the Asset__c address fields.
    doAssignValues(event) {
        console.log('event val--->>',event.target.fieldName+'--'+event.target.name+'--'+event.target.value);
        for (var section of this.sectionWithfields) {
            if (section && section.Section_Fields__r) {
                for (var field of section.Section_Fields__r) {
                    //console.log(field.Field_API_Name__c);
                    //console.log(event.target.fieldName);
                    if (field.Field_API_Name__c == event.target.fieldName || field.Field_API_Name__c == event.target.name) {
                        console.log('inside --299'+event.target.value);
                        field.value = event.target.value;
                    }
                    //CH01: 12 -Dec-2023 |Tarun to pre populate the District,City,State,Pincode for Asset__c
                    if (this.objectName === 'Asset__c') {
                        if (field.Field_API_Name__c === 'District__c') {
                            field.value = this.addressObj.District ? this.addressObj.District : '';
                        }
                        else if (field.Field_API_Name__c === 'State__c')
                            field.value = this.addressObj.State ? this.addressObj.State : '';
                        else if (field.Field_API_Name__c === 'City__c') {
                            field.value = this.addressObj.City ? this.addressObj.City : '';
                        }
                        else if (field.Field_API_Name__c === 'Country__c')
                            field.value = this.addressObj.Country ? this.addressObj.Country : '';
                    }
                }
            }
        }
        console.log('this.sectionWithfields ', this.sectionWithfields);
        this.updateFieldsVisibility();
    }

    updateFieldsVisibility() {
        console.log('Enter');
        try{
        for (var section of this.sectionWithfields) {
            if (section && section.Show_Form_Condition__c != undefined && section.Show_Form_Condition__c != null) {
                console.log('section display condition', section.MasterLabel, section.Show_Form_Condition__c);
                let result = section.Show_Form_Condition__c;
                for (let key in this.recordInfo) {
                    //console.log('key ', key);
                    if (section.Show_Form_Condition__c.includes('User.Profile.Name')) {
                        section.Show_Form_Condition__c = section.Show_Form_Condition__c.replaceAll('User.Profile.Name', "'" + this.userProfileName + "'");
                    }
                    if (this.oppStageName && section.Show_Form_Condition__c.includes('StageName')) {
                        section.Show_Form_Condition__c = section.Show_Form_Condition__c.replaceAll('StageName', "'" + this.oppStageName + "'");
                    }
                    //console.log('recordType label :',this.recordTypeOptions.find(opt => opt.value === this.selectedRecordTypeId).label);
                    if (this.recordTypeName && section.Show_Form_Condition__c.includes('RecordTypeId')) {
                        section.Show_Form_Condition__c = section.Show_Form_Condition__c.replaceAll('RecordTypeId', "'" + this.recordTypeName + "'");
                    } else if (this.selectedRecordTypeId && section.Show_Form_Condition__c.includes('RecordTypeId')) {
                        section.Show_Form_Condition__c = section.Show_Form_Condition__c.replaceAll('RecordTypeId', "'" + this.recordTypeOptions.find(opt => opt.value === this.selectedRecordTypeId).label + "'");
                    }
                    section.Show_Form_Condition__c = section.Show_Form_Condition__c.replaceAll(key, "'" + this.recordInfo[key.trim()] + "'");
                }
                console.log('OUT=> ', section.Show_Form_Condition__c);
                section.isShow = eval(section.Show_Form_Condition__c);
                section.Show_Form_Condition__c = result;
                console.log('section.isShow', section.isShow);
            }
            console.log('form dekho ', section.isShow, section.MasterLabel);
        }
        for (var section of this.sectionWithfields) {
            console.log('Enter1');
            if (section && section.Section_Fields__r) {
                console.log('Enter2');
                for (var field of section.Section_Fields__r) {
                    console.log('Enter3', field.DeveloperName, field.Show_Filter_Condition__c);
                    if (field.Show_Filter_Condition__c) {
                        let result = field.Show_Filter_Condition__c;
                        for (let key in this.recordInfo) {
                            //console.log('key ', key);
                            if (field.Show_Filter_Condition__c.includes('User.Profile.Name')) {
                                field.Show_Filter_Condition__c = field.Show_Filter_Condition__c.replaceAll('User.Profile.Name', "'" + this.userProfileName + "'");
                            }
                            if (this.oppStageName && field.Show_Filter_Condition__c.includes('StageName')) {
                                field.Show_Filter_Condition__c = field.Show_Filter_Condition__c.replaceAll('StageName', "'" + this.oppStageName + "'");
                            }
                            if (this.recordTypeName && field.Show_Filter_Condition__c.includes('RecordTypeId')) {
                                field.Show_Filter_Condition__c = field.Show_Filter_Condition__c.replaceAll('RecordTypeId', "'" + this.recordTypeName + "'");
                            } else if (this.selectedRecordTypeId && field.Show_Filter_Condition__c.includes('RecordTypeId')) {
                                field.Show_Filter_Condition__c = field.Show_Filter_Condition__c.replaceAll('RecordTypeId', "'" + this.recordTypeOptions.find(opt => opt.value === this.selectedRecordTypeId).label + "'");
                            }
                            field.Show_Filter_Condition__c = field.Show_Filter_Condition__c.replaceAll(key, "'" + this.recordInfo[key.trim()] + "'");
                        }
                        console.log('OUT1= ', field.Show_Filter_Condition__c);
                        field.isShow = eval(field.Show_Filter_Condition__c);
                        field.Show_Filter_Condition__c = result;
                        console.log('section.isShow', field.isShow);
                    } else {
                        field.isShow = true;
                    }
                }
            }
        }
        }catch(error){
            console.log('error 386'+error);
        }
    }
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
        this.recordInfo['RecordTypeId'] = this.selectedRecordTypeId;
        console.log('current recordtypeId :', this.recordInfo['RecordTypeId']);
        this.updateFieldsVisibility();
    }
    handleSaveClick() {
        this.isDisabled = true;
    }
    handleRecordSaveSuccess(event) {
        this.isDisabled = false;
        console.log('----handleRecordSaveSuccess-', event.detail.id);
        try {
            this.showSpinner = false;
            var evt = new ShowToastEvent({
                title: 'Success',
                message: this.objectLabel + ' added Successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            //const name = event.detail.Id;
            //console.log('name', name);
            //this.handleClose();

            const selectedEvent = new CustomEvent('save', {
                detail : false
            });
            this.dispatchEvent(selectedEvent);

            /*const selectEvent = new CustomEvent('recordsavesuccess', {
                detail: event.detail.id
            });
            this.dispatchEvent(selectEvent);*/
            
            /*this.dispatchEvent(
                new CustomEvent('save', { detail: { recId: event.detail.id, objectName: this.objectName, isShowModal: false }, bubbles: true, composed: true })
            );*/
        }
        catch (error) {
            console.log('OUTPUT: ', error);
        }
    }
    handleError(event) {
        console.log('ERRORR Method');
        this.isDisabled = false;
        console.log('----ErrorError-' + JSON.stringify(event.detail), this.isDisabled);
        if (Object.values(event.detail.output.fieldErrors).length > 0) {
            console.log('in if');
            const fieldErrors = [];
            Object.values(event.detail.output.fieldErrors).forEach(
                (errorArray) => {
                    fieldErrors.push(
                        ...errorArray.map((e) => e.message)
                    );
                }
            );
            let text = fieldErrors.toString();
            if (text.includes(",")) {
                text = text.replaceAll(',', '');
            }
            this.showNotification('Error', text, 'error');
        } else if (event.detail.output.errors) {
            console.log('in else');
            this.showNotification('Error', JSON.stringify(event.detail.output.errors[0].message), 'error');
        }
    }
    get objectLabel() {
        return this.objectName == 'Account' ? 'Customer' : this.objectName == 'Asset__c' ? 'Asset' : this.objectName == 'Collateral__c' ? 'Collateral' : this.objectName == 'Document__c' ? 'Document' : this.objectName == 'Check_Detail__c' ? 'Check Detail' : 'Loan Applicant';
    }
    get isShowRecordType() {
        return (this.recordTypeOptions.length > 0 && this.objectName != 'Document__c');
    }
    get newOrEdit() {
        return (this.editRecordId) ? 'Edit' : 'New';
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleChange(event) {
        console.log('handleChange');
        console.log('handleChange', event.target.value);
        this.applicationProductId = event.target.value;
    }

    handleSubmit(event) {
        this.isDisabled = true;
        console.log('Called handleSubmit ' , event.detail.fields);
        const fields = event.detail.fields;
        event.preventDefault();       // stop the form from submitting
        this.fields = event.detail.fields;
        console.log('Called fields', JSON.stringify(this.fields));
        // Added Field Value in Collateral__c Object.
        if (this.objectName == 'Collateral__c') {
            
        }
        else if (this.isRedFlag == true) {
            this.isRedFlagModal = true;
        }
        else {
            this.template.querySelector('lightning-record-edit-form').submit(this.fields);
        }
    }

    saveredFlag() {
        this.template.querySelector('lightning-record-edit-form').submit(this.fields);
        this.isShow = false;
        this.isRedFlagModal = false;
    }

    getAppValues(appRecId) {
        
    }

    getRedFlagCustomer() {
        
    }
}