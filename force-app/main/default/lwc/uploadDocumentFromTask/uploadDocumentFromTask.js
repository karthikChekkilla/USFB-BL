import { LightningElement, api, wire, track  } from 'lwc';
import getTaskrecord from '@salesforce/apex/UB_DisplayUBDocumentsController.getTaskrecord';
import getDocumentUrl from '@salesforce/apex/UB_DisplayUBDocumentsController.getDocumentUrl';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
export default class UploadDocumentFromTask extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track showUploadModal = false;
    disabledUploadButton = false;
    @track documentId = '';
    @track dmsDocumentId = '';
    @track showPreviewModal = false;
    @track disabledViewButton = true;
    @track userProfileName;
    @track uploadDocumentButton = false;
    
    connectedCallback() {
        console.log('recordId-> ' , this.recordId);
        console.log('objectApiName-> ' , this.objectApiName);
    }
    openUploadModal(){
        //this.showUploadModal = true;
        this.getTaskrecord();
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
         console.log('OUTPUT : inside error');
            this.error = error;
          
        }else if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                if((this.userProfileName == 'USFB CV - Partner Community User' || this.userProfileName == 'USFB BL - Partner Community User' || this.userProfileName == 'System Administrator') || this.objectApiName == 'Task' || this.objectApiName == 'Personal_Discussion__c'){
                    this.uploadDocumentButton = true;
                    console.log('Inside IF statement ');
                }
                console.log('this.userProfileName ', this.userProfileName);
                console.log('uploadDocumentButton ', this.uploadDocumentButton);
            }
        }
    }


    getTaskrecord(){
        getTaskrecord({recordId : this.recordId })
        .then(result=>{
            console.log('result getDocumentRecord=> ',result);
            if(result.isSuccess){
                this.showUploadModal = true;
                console.log('result getDocumentRecord if=> ',JSON.parse(result.responseBody));
                let responseBody = JSON.parse(result.responseBody);
                console.log('responseBody-> ',responseBody.Document__c);
                this.documentId = responseBody.Document__c;
            }else{
                console.log('result getDocumentRecord=> ',JSON.parse(result.responseBody));
            }
            //this.documentId = result.Document__c;
            
            //console.log('this.documentId-> ', this.documentId);
        })
        .catch(error =>{
            this.showUploadModal = false;
            console.log('getTaskrecord Error= ', error);
            //console.log('getTaskrecord Error= ', error.body.message);
        }).finally(() => {
            //this.showSpinner = false;
        });
    }

    @wire(getDocumentUrl,{recordId:'$recordId'})
    getDocumentUrl({ error, data }) {
        if (data) {
            console.log('getDocumentUrl data-> ' , data);
            if(data.isSuccess){
                this.dmsDocumentId = data.responseBody;
                this.disabledViewButton = false;
                //this.showPreviewModal = true;
            }else{
                console.log('get data through wire method', data);
                this.showPreviewModal = false;
                this.disabledViewButton = true;
            }
        } else if (error) {
           console.log('check errror' , JSON.stringify(error));
           this.showPreviewModal = false;
        }
    }
    

    openPreviewModal(){
        this.showPreviewModal = true;
        //this.getDocumentUrl();
    }

    /*getDocumentUrl(){
        getDocumentUrl({recordId : this.recordId })
        .then(result=>{
            if(result.isSuccess){
                this.dmsDocumentId = result.responseBody;
                console.log('this.documentId getDocumentUrl-> ', this.dmsDocumentId);
                this.showPreviewModal = true;
            }else{
                this.showPreviewModal = false;
                console.log('result getDocumentUrl-> ', result);
            }
        })
        .catch(error =>{
            this.showPreviewModal = false;
            console.log('Error= ', error);
            console.log('Error= ', error.body.message);
        }).finally(() => {
            //this.showSpinner = false;
        });
    }*/

    

    closeUploadModal(event){
        this.showUploadModal = false;
        window.location.reload();
        //refreshApex(this.wireDocumentResult);
    }

    closePreviewModal(event) {
        console.log('event-> ', event.detail);
        this.showPreviewModal = event.detail;
    }
}