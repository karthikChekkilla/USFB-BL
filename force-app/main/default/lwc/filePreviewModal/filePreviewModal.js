import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import getRelatedFilesByRecord from '@salesforce/apex/UB_DisplayUBDocumentsController.getRelatedFilesByRecordId';
const VIEW_FILE_TYPE = ['.jpg', '.jpeg', '.png', '.bmp', '.pdf', '.txt'];
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import getRecordIsReadOnlyFromSObject from '@salesforce/apex/UB_DisplayUBDocumentsController.getRecordIsReadOnlyFromSObject';
const columns = [
    { label: 'Name', fieldName: 'File_Name__c', sortable: "true" },
    //{ label: 'Type', fieldName: 'Document_Type__c', sortable: "true" },
    { label: 'Uploaded By', fieldName: 'Uploaded_By__c', sortable: "true" },
    { label: 'Uploaded Date', fieldName: 'Uploaded_Date__c', sortable: "true" },
    { label: 'Status', fieldName: 'Status__c', sortable: "true" }
];
export default class FilePreviewModal extends NavigationMixin(LightningElement) {
    @api siteUrl;
    @api dmsDocumentId;
    @api isDownloadOnly = false;   
    @track filePreviewUrl;
    @track showSpinner = false;
    @track showPreviewModal = false;
    @api objectName;
    @track isReadOnlyRecord;
    @api applicationId;
    @api leadId;
    filesList =[];
    filesListSize;
    userProfileName;
    deleteVisible = false;
    @track columns = columns;

    connectedCallback() {
        console.log('dmsDocumentId-> ' , this.dmsDocumentId);
        console.log('objectName-> ' , this.objectName);
        console.log('applicationId-> ' , this.applicationId);
        console.log('leadId-> ' , this.leadId);
        this.getRelatedFilesByRecord();
        this.getRecordIsReadOnlyFromSObject();
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        }else if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                console.log('this.userProfileName ', this.userProfileName);
            }
        }
    }
    
    getRowActions(row, doneCallback) {
        const actions = [];
        actions.push({ label: "View", name: 'View', iconName: "utility:preview" });
        if(this.filesListSize > 1){
            if((this.userProfileName != 'Credit') && this.isReadOnlyRecord != true){
                actions.push({ label: "Delete", name: 'Delete', iconName: "utility:recycle_bin_empty" });
            }
        }
        setTimeout(() => {
            doneCallback(actions);
        }, 500);

    }

    getRelatedFilesByRecord(){
        getRelatedFilesByRecord({ recordId : this.dmsDocumentId})
        .then((result) => {
            console.log('result-> ' , result);
            if(result != null && result != undefined && result != ''){ 
                this.showPreviewModal = true;
                this.filesList = result;
                this.filesListSize = result.length;
                if(this.filesListSize > 1 ){
                    if((this.userProfileName != 'Credit') && this.isReadOnlyRecord != true){
                        this.deleteVisible = true;
                    }
                }
                console.log('this.filesListSize-> ', this.filesListSize);
            }else{
                this.showPreviewModal = false;
                this.showNotification('Error', 'No Documents Found', 'error');
            }
            /*if (result.isSuccess) {
                if(this.userProfileName == 'USFB - Partner Community User'){
                    console.log('getCustomerDocuments result-> ', JSON.parse(result.responseBody));
                    //window.location.href = JSON.parse(result.responseBody);
                    let url = JSON.parse(result.responseBody);
                    console.log('url-> ', url);
                    const config = {
                        type: 'standard__webPage',
                        attributes: {
                            url: url
                        }
                    };
                    this[NavigationMixin.Navigate](config);
                }else{
                    this.filePreviewUrl = JSON.parse(result.responseBody);
                }
                //this.previewHandler()
            } else {
                this.filePreviewUrl = '';
                this.showNotification('Warning', 'No Documents Found', 'Info');
                console.log('getCustomerDocuments result-> ', result);
            }*/
        })
        .catch((error) => {
            console.log('getRelatedFilesByRecord error-> ', error);
            //this.showNotification('Error', 'Something Went Wrong', 'Error');
        })
        .finally(() => {
                //this.columns = [...columns].filter(col => col.fieldName != 'Document_Sub_Type__c' && col.label != 'Verify');
                this.columns = [...columns];
                //this.addActions();
                this.columns = this.columns.concat([{ label: '', initialWidth: 100, type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }]);
                this.showSpinner = false;
            });

    }

    closeModal() {
        this.showPreviewModal = false;
        const selectedEvent = new CustomEvent('closemodal', {
            detail : this.showPreviewModal
        });
        this.dispatchEvent(selectedEvent);
    }

    handleRowAction(event) {
        console.log('handleRowAction event.detail.action.name-> ', event.detail.action.name );
        console.log('handleRowAction event.detail.row-> ', event.detail.row.Id );
        if(event.detail.action.name == 'View' ){
            console.log('handleRowAction event.detail.row-> ', JSON.stringify(event.detail.row.Document_Preview_Url__c) );
            this.previewHandler(event.detail.row.Document_Preview_Url__c);
        }if(event.detail.action.name == 'Delete'){
            this.deleteHandler(event.detail.row.Id);
        }
    }

    getSelectedAction(event){
        console.log('event-> ', event);
        let selectedRows = JSON.parse(JSON.stringify(event.detail.selectedRows));
        console.log('selectedRows-> ', selectedRows);
    }

    previewHandler(event){
        //console.log('previewHandler-> ', event.target.dataset.id)
        /*this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })*/
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": event
            }
        });
    }

    deleteHandler(event){
        //console.log('deleteHandler-> ', event.target.dataset.id);
        try {
            deleteRecord(event);
            this.showNotification('Success', 'Record deleted successfully!', 'Success');
            this.closePreviewModal();
        } catch (error) {
            this.showNotification('Error deleting record', reduceErrors(error).join(', '), 'error');
        }
    }

    closePreviewModal(){
        this.filesList = [];
        this.filesListSize = '';
        const selectedEvent = new CustomEvent("closemodal", {
            detail: false
        });
        this.dispatchEvent(selectedEvent);
    }
    
    renderedCallback(){
        console.log('RENDER CALLBACK');
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

    getRecordIsReadOnlyFromSObject(){
        var recordId;
        if(this.leadId != undefined){
            recordId = this.leadId;
        }else{
            recordId = this.applicationId;
        }
        getRecordIsReadOnlyFromSObject({recordId : recordId , SObjectName : this.objectName })
        .then(result=>{
            console.log('getRecordIsReadOnlyFromSObject result -> ', result);
            this.isReadOnlyRecord = result;
        }).catch(error =>{
            console.log('getRecordIsReadOnlyFromSObject error -> ', error);
        })
    }
}