import { LightningElement , track, wire, api} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord, getRecord, updateRecord  } from 'lightning/uiRecordApi';
import getAadharMaskImage from '@salesforce/apex/UB_AadharIMageMasking.getAadharMaskImage';
import uploadDocument from '@salesforce/apex/UB_DisplayUBDocumentsController.uploadDocument';
import getDocumentType from '@salesforce/apex/UB_DisplayUBDocumentsController.getDocumentType';
import getSelectedDocumentSubType from '@salesforce/apex/UB_DisplayUBDocumentsController.getSelectedDocumentSubType';
const FIELDS = [
    'Document__c.Document_Type__c',
    'Document__c.Document_Sub_Type__c'
];
export default class UploadDocument extends LightningElement {
    @api documentId;
    @track fileData = {};
    @track docTypeOptions;
    @track showSpinner = false;
    @track documentType = '';
    @track documentSubType = '';
    @track dmsDocId = '';
    @track acceptedFormats;
    @track selecteddocumentSubtype = [];
    @track isAadhar = false;
    // If We Add More Extension Here Then We Have To Added Then Same in Apex As Well.
    /*get acceptedFormats() {
        return ['.jpg', '.jpeg', '.png', 
                '.bmp', '.csv', '.doc', 
                '.docx', '.pdf', '.ppt', '.pptx', 
                '.xls', '.xlsx', '.txt'
               ];*/
        /*return ['.jpg', '.jpeg', '.png', 
                '.svg', '.bmp', '.csv', '.doc', 
                '.docx', '.pdf', '.ppt', '.pptx', 
                '.xls', '.xlsx', '.txt'
               ];*/
   // }

   connectedCallback() {
       this.getSelectedDocumentSubType();
   }

    @wire(getRecord, { recordId: '$documentId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading contact',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            console.log('data.fields.Document_Sub_Type__c.value==> ',data.fields.Document_Sub_Type__c.value);
            this.documentType = data.fields.Document_Type__c.value;
            this.documentSubType = data.fields.Document_Sub_Type__c.value;

        }
    }

    @wire(getDocumentType, { recordId: '$documentId' })
    getDocumentType({ error, data }) {
        if (error) {
            console.log('error.getDocumentType==> ',data.fields.Document_Sub_Type__c.value);
        } else if (data) {
            console.log('data.getDocumentType==> ',data);
            if(data.Document_Type__c == 'Photo' && data.Document_Sub_Type__c == 'Photo'){
                this.acceptedFormats = ['.jpg', '.jpeg', '.png'
               ];
            }else{
                this.acceptedFormats = [ 
                '.jpg', '.jpeg', '.png',
                '.bmp', '.csv', '.doc', 
                '.docx', '.pdf', '.ppt', '.pptx', 
                '.xls', '.xlsx', '.txt'
               ];
            }
        }
    }

    // When We Upload File Using File Uploader, This Function Will Call.
    handleFileUpload(event) {
        console.log('FILE STANDARD LWC UPLOAD')
        const file = event.detail.files[0];
        console.log('file->' , file);
        console.log('file->' , file.name);
        console.log('file->' , file.contentBodyId);
        console.log('file->' , file.contentVersionId);
        this.fileData = {
                'filename': file.name,
                'base64': file.contentBodyId,
                'contentVersionId' : file.contentVersionId
        }
        //this.showNotification('Success', file.name + 'uploaded  successfully', 'success');
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

 
    callAadharImageMasking(){
        console.log('AAAAAAAAAAA ')
        getAadharMaskImage({base64: this.fileData.base64, fileName : this.fileData.filename ,  documentId: this.documentId})
            .then(result=>{
                console.log('TOKENNNNNNNNNNN=> ',result);
                this.showSpinner = false;
                if(!result ) {
                    this.showNotification('Success', 'Document Uploaded Successfully', 'success');
                } else {
                    this.showNotification('Error', 'Please Upload correct Aadhar Card.', 'error');

                }
                this.closeModal();
            })
            .catch(error =>{
                console.log('getAccessTokenForAadharMasking Error= ', error);
                console.log('Error= ', error.message);
               // this.showNotification('Error', error.body.message, 'error');
                this.showSpinner = false;
            });
    }


    handleUpload(event){
        event.preventDefault();
        console.log('this.fileData.base64', this.fileData.base64);
        console.log('this.fileData.base64', this.fileData.filename);
        if(this.checkValidation()){
            this.showSpinner = true;
            /*
            Author : Zafaruddin
            Date : 30/05/2024
            Description : code to execute AadharImageMaskApi when document upload is Aadhar
            */
            if(this.documentSubType == 'Aadhar Card') {
                console.log('CALL  API');
                this.callAadharImageMasking();
            } 
            // end here
            else {
                console.log('OTHER DOC');
                uploadDocument({documentSubType : this.documentSubType, fileName : this.fileData.filename, base64 : this.fileData.base64 ,  recordId: this.documentId, contentVersionId : this.fileData.contentVersionId})
                    .then(result => {
                        console.log('handleUpload result ', result);
                        if (result.isSuccess) {
                            this.showNotification('Success', 'Document Uploaded Successfully', 'success');
                            this.closeModal();
                            //this.showNotification('Success', 'Record was deleted successfully', 'success');
                        //this.template.querySelector('c-confirmation-dialog');
                        } else {
                            this.showNotification('Error', result.responseBody, 'error');
                        }
                    })
                    .catch(error => {
                        //console.log('Error updateVerify= ', error);
                        //console.log('Error= ', error.body.message);
                        this.showNotification('Error', error.body.message, 'error');
                    }).finally(() => {
                        this.showSpinner = false;
                    });
                }
        }
    }

    // When We Upload File Using File Uploader, This Function Will Call.
    handleFileUpload1(event) {
        const file = event.target.files[0];
        console.log('file1-> ', file);
        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64
            }
            console.log(this.fileData)
        }
        reader.readAsDataURL(file);
        //this.checkValidation();
        console.log('this.fileData', this.fileData);
    }
    
    // For Closing Action Screen Modal
    closeModal(){
        this.fileData = {};
        const selectedEvent = new CustomEvent("closemodal", {
            detail: false
        });
        this.dispatchEvent(selectedEvent);
        //this.detailValue.isShowModal = false;
        
    }

    getSelectedDocumentSubType(){
        getSelectedDocumentSubType({documentRecordId : this.documentId})
            .then(result => {
                console.log('result selecteddocumentSubtype-> ', result);
                if(result != null && result != undefined){
                    this.selecteddocumentSubtype = [];
                    for (let key in result ) {
                        this.selecteddocumentSubtype.push({ label: key, value: key });
                    }
                    console.log('if this.selecteddocumentSubtype-> ', JSON.stringify(this.selecteddocumentSubtype));
                }else{
                    this.selecteddocumentSubtype = null;
                    console.log('else this.selecteddocumentSubtype-> ', this.selecteddocumentSubtype);
                }
            })
            .catch(error => {
                console.log('error getSelectedDocumentSubType-> ', error);
            }).finally(() => {
                
            });
    }

    handleSubtypeChange(event){
        this.documentSubType = event.detail.value;
        if(this.documentSubType == 'Aadhar Card') {
            this.isAadhar = true;
        }
        console.log('isAadhar   ',this.isAadhar);
        console.log('this.documentSubType -> ', this.documentSubType);
    }

    checkValidation(){
        let inputElement = this.template.querySelectorAll('.requiredField');
        let isValid = true;
        inputElement.forEach(element => {
            let isValidOrNot = element.reportValidity();
            /*if(element.name == 'DocumentInput' && isValidOrNot && this.isFileSizeMoreThanMaxLimit){
                element.setCustomValidity(this.fileSizeExceedErrorMsg);
                isValidOrNot = element.reportValidity();
            }else if(element.name == 'DocumentInput' && !this.isFileSizeMoreThanMaxLimit){
                element.setCustomValidity('');
                isValidOrNot = element.reportValidity();
            }*/
            console.log('isValidOrNot ', isValidOrNot);
            if(!isValidOrNot && isValid){
                isValid = isValidOrNot;
            }
        });
        return isValid;
    }

    onchangeFileUpload(event) {
        console.log('FILE INPUTTTTTT');
        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64
            }
            console.log('FIlEEEEE ',JSON.stringify(this.fileData));
        }
        reader.readAsDataURL(file);
        //this.checkValidation();
        console.log('this.fileData', this.fileData);
    }
    
}