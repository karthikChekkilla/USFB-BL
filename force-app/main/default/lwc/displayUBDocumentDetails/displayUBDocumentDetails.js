import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import ROLE_NAME from '@salesforce/schema/User.UserRole.Name';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getLeadDocuments from '@salesforce/apex/UB_DisplayUBDocumentsController.getLeadDocuments';
import getApplicationDocuments from '@salesforce/apex/UB_DisplayUBDocumentsController.getApplicationDocuments';
import deleteDoc from '@salesforce/apex/UB_DisplayUBDocumentsController.deleteDoc';
import updateDocumentStatus from '@salesforce/apex/UB_DisplayUBDocumentsController.updateDocumentStatus';
import { refreshApex } from '@salesforce/apex';
import portalUrl from '@salesforce/label/c.CV_Portal_URL';
import PageSizeDocument from '@salesforce/label/c.PageSizeDocument';
import getRecordIsReadOnlyFromSObject from '@salesforce/apex/UB_DisplayUBDocumentsController.getRecordIsReadOnlyFromSObject';
import getApplicationRecordType from '@salesforce/apex/UB_DisplayUBDocumentsController.getApplicationRecordType';
import getCurrentLoggedInUserProfile from '@salesforce/apex/UB_DisplayUBDocumentsController.getCurrentLoggedInUserProfile';
import getDisbursementDocs from '@salesforce/apex/UB_DisplayUBDocumentsController.getDisbursementDocs';
//import updateDocumentDetails from '@salesforce/apex/UB_DisplayUBDocumentsController.updateDocumentDetails';
const VIEW_FILE_TYPE = ['.jpg', '.jpeg', '.png', '.bmp', '.pdf', '.txt'];
import getRCUVendors from '@salesforce/apex/BL_RCUController.getRCUVendors';
import initiateRCUtoVendor from '@salesforce/apex/BL_RCUController.initiateRCUtoVendor';
import getRCUActivityStatus from '@salesforce/apex/BL_RCUController.getRCUActivityStatus';
import uploadDocument from '@salesforce/apex/UB_DisplayUBDocumentsController.uploadDocument';
const columns = [
    {
        label: 'Document Name', fieldName: 'DocumentName', type: 'url', sortable: "true",
        typeAttributes: {
            label: {
                fieldName: 'Document_Type__c'
            },
            target: '_blank'
        }
    },
    { label: 'Document Sub Type', fieldName: 'Document_Sub_Type__c', sortable: "true" },
    { label: 'Acknowledge Status', fieldName: 'Acknowledge_Status__c', sortable: "true" },
    { label: 'Status', fieldName: 'Status__c', sortable: "true" },

];

const SANCTION_COLUMNS = [
    { label: 'Sanction Condition', fieldName: 'Sanction_Condion_SL__c', type: 'text' },
      { label: 'Description', fieldName: 'Description__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Acknowledge Status', fieldName: 'Acknowledge_Status__c', type: 'text' }
  
];

const rowAction = [];
export default class DisplayUBDocumentDetails extends NavigationMixin(LightningElement) {
    @api leadId;
    @track rowAction = rowAction;
    @api documentType;
    @api objectName;
    @api metadata;
    @api PDD;
    @track documentList = [];
    @track columns = columns;
    @track showModal = false;
    @track showPreviewModal = false;
    @track documentId;
    @track fileName = '';
    @track title = 'Document Verification';
    @track message = 'Do you want to confirm the Uploaded document Verify?';
    @track dmsDocumentIdSelected = '';
    @track isDialogVisible = false;
    @track showSpinner = false;
    @track userProfileName;
    @track userRoleName;
    @track isReadOnlyRecord;
    @track filePreviewUrl = "https://img.freepik.com/free-photo/closeup-shot-yellow-gaillardia-flower_181624-43107.jpg?w=826&t=st=1674197598~exp=1674198198~hmac=6e83e953a422e1620ddbd9e933717a23617235fed98a03f68fcc70f3ba3045c4";
    @api applicationId;
    @api applicantId;
    @track isRenderedCallBackExecuted = false;
    @track sortBy;
    @track sortDirection;
    @track showBulkVerifyButton = false;
    @track recordTypeName;

    @track disbursementId;
    @track showRCUInitiate = false;
    @track isConfirmModelRCU = false;
    @track rcuVendorsOptions = []; 
    @track selectedVendor = '';
    @track comment = '';
    @track isRCUInitiateDisbale = true;

     @track lob;
    @track disbursementStage = '';
    @track isPDD;
    @track awbNumber = '';
    @track courierNumber = '';
    @track dispatchDate = '';
    @track showSubmitButton = false;
    @track todayDate;

     @track fileData = {};

    // JS Properties 
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    records = []; //All records available in the data table
    //columns = []; //columns information available in the data table
    totalRecords = 0; //Total no.of records
    //pageSize = 0; //No.of records to be displayed per page
    pageSize = PageSizeDocument; //No.of records to be displayed per page
    totalPages = 0; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    @track acceptedFormats = [
        '.jpg', '.jpeg', '.png',
        '.bmp', '.csv', '.doc',
        '.docx', '.pdf', '.ppt', '.pptx',
        '.xls', '.xlsx', '.txt'
    ];
    
    label = {
        portalUrl
    };

    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    handleSortAccountData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortAccountData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortAccountData(fieldname, direction) {

        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));

        let keyValue = (a) => {
            return a[fieldname];
        };


        let isReverse = direction === 'asc' ? 1 : -1;


        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });

        this.recordsToDisplay = parseData;


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
            this.recordsToDisplay.push(this.documentList[i]);
        }
    }



    //modified by chandan on 25th July
    connectedCallback() {
        // assignment of today date in proper format
        let today = new Date();
        let day = ('0' + today.getDate()).slice(-2);
        let month = ('0' + (today.getMonth() + 1)).slice(-2);
        let year = today.getFullYear();
        this.todayDate = `${year}-${month}-${day}`;

        const { leadId, objectName, metadata } = this;
        this.getRecordIsReadOnlyFromSObject();
        console.log('leadId ->', leadId);
        console.log('objectName ->', objectName);
        this.fetchUserProfileName();

        //  if((metadata === 'pdd') && isRelationshipManager){
        //      this.showSubmitButton = true;
        //      console.log('showButton : ',this.showSubmitButton);
        // }

        if (leadId) {
            if (objectName === 'Lead__c') {
                this.getLeadDocuments();
                return;
            }
            else if (objectName === 'Disbursement__c') {
                this.getDisbursementDocs();
                return;
            }
        }
        else if (metadata === 'Sanction_Condition') {
            this.getDisbursementDocs();
        }
        else {
            this.getApplicationDocuments();
            this.getApplicationRecordType();
            this.getRCUActivityStatus();
        }
        // this.getApplicationLOB();


    }
    //added by Mohit on 1st August,2024 to fetch current logged in user profile name
    fetchUserProfileName() {
        getCurrentLoggedInUserProfile({})
            .then((result) => {
                if (result != undefined && result != null) {
                    this.userProfileName = result;
                } else {
                    this.showToastMsg('Application Error', 'Kindly contact your admin!', 'Error');
                }
            })
            .catch((error) => {
                console.error(error);
            });
    }

    //added by chandan on 24th July,2024 to set the column based on role
    setColumnsAndActions() {
        const { metadata, userRoleName, userProfileName } = this;

        console.log('Metadata:', metadata);
        console.log('User Role inside document details:', userRoleName);
        console.log('User Profile:', userProfileName);

        const isSanctionCondition = metadata === 'Sanction_Condition';
        const isCreditManager = userRoleName === 'Credit Manager';
        const isSystemAdmin = userProfileName === 'System Administrator';
        const isRCUManager = userRoleName === 'RCU Manager';
        const isNCM = userRoleName === 'National Credit Manager';
        const isRCM = userRoleName === 'Regional Credit Manager';
        const isZCM = userRoleName === 'Zonal Credit Manager';
        const isCH = userRoleName === 'Credit Head';
        const isRelationshipManager = userRoleName === 'Relationship Manager';

        const isCPCMaker = userRoleName === 'CPC Agents (Maker)';
        const isCPCChecker = userRoleName === 'CPC Agents (Checker)'; 

        if (isSanctionCondition && (isCreditManager || isSystemAdmin || isRCUManager || isCPCMaker || isNCM || isRCM || isZCM || isCH || isRelationshipManager || isCPCChecker)) {
            console.log('Setting columns for Sanction Condition');
            this.columns = SANCTION_COLUMNS;
        }
    }


    renderedCallback() {
        if (!this.isRenderedCallBackExecuted) {
            console.log('this.isRenderedCallBackExecuted ', this.isRenderedCallBackExecuted);
            this.isRenderedCallBackExecuted = true;
            console.log('this.applicationId ', this.applicationId);
            console.log('this.applicantId ', this.applicantId);
            if (this.objectName == 'Loan_Application__c') {
                this.getApplicationDocuments();
            } else if (this.objectName == 'Lead__c') {
                this.getLeadDocuments();
            } else if (this.objectName == 'Disbursement__c') {
                this.getDisbursementDocs();
            }
        }
        //  const { metadata, userRoleName, userProfileName } = this;
        //   const isRelationshipManager = userRoleName === 'Relationship Manager';
          // this.setupColumns();
    }

    //added by chandan on 24th July
    @wire(getRecord, { recordId: Id, fields: [ProfileName, ROLE_NAME] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
            console.log('OUTPUT : errorrr', this.error);
            return;
        }

        if (!data) {
            return;
        }
        console.log('OUTPUT :inside document details ', data);
        const profileValue = data.fields.Profile?.value;
        const userRoleValue = data.fields.UserRole?.value;

        if (profileValue) {
            this.userProfileName = profileValue.fields.Name.value;
        }

        if (userRoleValue) {
            this.userRoleName = userRoleValue.fields.Name.value;
        }

        console.log('User Profile:', this.userProfileName);
        console.log('User Role:', this.userRoleName);
        console.log('OUTPUT :meta ', this.metadata);

        

        //Ended by Lakshya Verma on 14th Aug for RCU BL Managers

        // commented by chandan on 23rd september for PDD Flow
        // if (this.metadata === 'pdd') {
        //     this.showBulkVerifyButton = false;
        // }

        console.log('Final User Profile:', this.userProfileName);
        console.log('Portal URL Label:', this.label.portalUrl);
    }




    getRecordIsReadOnlyFromSObject() {
        var recordId;
        if (this.leadId != undefined) {
            recordId = this.leadId;
        } else {
            recordId = this.applicationId;
        }
        getRecordIsReadOnlyFromSObject({ recordId: recordId, SObjectName: this.objectName })
            .then(result => {
                console.log('getRecordIsReadOnlyFromSObject result -> ', result);
                this.isReadOnlyRecord = result;

                //Added by Lakshya Verma on 03-10-2024
                const showButtonProfiles = ['Credit', 'System Administrator', 'RCU'];
                const showButtonRoles = ['CPC Agents (Maker)'];
                const showButtonProfilesBL = ['System Administrator', 'RCU'];
                const showBasedOnMetaData = ['pdd'];
                const showBasedOnRoleForPDD = ['CPC Agents (Checker)', 'Business Head'];

                if ((showButtonProfiles.includes(this.userProfileName) || showButtonRoles.includes(this.userRoleName)) && (!showBasedOnMetaData.includes(this.metadata))) {
                    console.log('this.isReadOnlyRecord 1-> ', this.isReadOnlyRecord);
                    if (this.isReadOnlyRecord == false) {//Added this check as part of USFBL-473 by Lakshya Verma on 03-10-2024
                        this.showBulkVerifyButton = true;
                    }
                }

                if (showBasedOnMetaData.includes(this.metadata) && showBasedOnRoleForPDD.includes(this.userRoleName)) {
                    console.log('this.isReadOnlyRecord 2-> ', this.isReadOnlyRecord);
                    if (this.isReadOnlyRecord == false) {//Added this check as part of USFBL-473 by Lakshya Verma on 03-10-2024
                        this.showBulkVerifyButton = true;
                    }
                }


                // added by chandan on 26th september for PDD flow for rendering submit button
                const isRelationshipManager = this.userRoleName === 'Relationship Manager';
                console.log('OUTPUT : ', isRelationshipManager);
                if (this.metadata === 'pdd' && isRelationshipManager) {
                    this.showSubmitButton = true;
                    console.log('showButton : ', this.showSubmitButton);
                }

                //Added by Lakshya Verma on 14th Aug for RCU BL Managers

                if (showButtonProfilesBL.includes(this.userProfileName)) {

                    this.showRCUInitiate = true;

                }
            }).catch(error => {
                console.log('getRecordIsReadOnlyFromSObject error -> ', error);
            })
    }

    getApplicationRecordType() {
        getApplicationRecordType({ applicationId: this.applicationId })
            .then(result => {
                console.log('getApplicationRecordType result -> ', result);
                this.recordTypeName = result;
            }).catch(error => {
                console.log('getApplicationRecordType error -> ', error);
            })
    }


    // modified by chandan on 25th July,2024 to segregate the result for sanction condition and columns dynamically
    @api
    getApplicationDocuments() {
        this.showSpinner = true;

        const applicationId = this.applicationId || this.leadId;
        const loanApplicantId = this.applicantId;

        getApplicationDocuments({ applicationId, loanApplicantId })
            .then(result => {
                console.log('result getApplicationDocuments ->', result.responseBody);

                if (!result.isSuccess) {
                    this.handleDocumentFetchError(result);
                    return;
                }

                const allDocuments = JSON.parse(result.responseBody);
                console.log('Total documents:', allDocuments.length);

                this.documentList = this.filterDocuments(allDocuments);
                this.totalRecords = this.documentList.length;
                console.log('Page size:', this.pageSize);

                this.paginationHelper();
            })
            .catch(error => {
                this.handleDocumentFetchError(error);
            })
            .finally(() => {
                this.setupColumns();
                this.showSpinner = false;
            });
    }

    // added by chandan on 24th July to filter the document
    filterDocuments(allDocuments) {
        if (this.metadata === 'Sanction_Condition') {
            console.log('Filtering sanctioned documents');
            return allDocuments.filter(doc => doc.Document_Type__c === 'Sanction Condition');
        }

        return allDocuments.filter(doc => doc.Document_Type__c !== 'Sanction Condition');
    }

    handleDocumentFetchError(error) {
        this.documentList = [];
        this.totalRecords = 0;
        console.log('Error fetching documents:', error);
    }

    //added by chandan on 24th July,2024 to set columns and  actions
    setupColumns() {
        if (this.metadata === 'Sanction_Condition') {
            this.setColumnsAndActions();
        } else {
            this.columns = [...columns];
            this.makeNameClickable();
        }
        this.columns = this.columns.concat([
                { label: 'Action', fixedWidth: 100, type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }
            ]);
    }



    @api getLeadDocuments() {
        this.showSpinner = true;
        getLeadDocuments(
            {
                leadId: this.leadId
            })
            .then(result => {
                console.log('result getLeadDocuments-> ', result);
                console.log('result.length getLeadDocuments-> ', result.length);
                if (result.isSuccess) {
                    this.documentList = JSON.parse(result.responseBody);
                    this.totalRecords = result.totalRecords;
                    //this.pageSize = this.pageSizeOptions[0];
                    console.log('this.pageSize ', this.pageSize);
                    this.paginationHelper();
                    //this.documentList = JSON.parse(JSON.stringify(result.responseBody));
                    // console.log('this.documentList ', this.documentList);
                } else {
                    this.documentList = [];
                    console.log('getLeadDocuments result-> ', result);
                }
            })
            .catch(error => {
                this.documentList = [];
                console.log(' error-> ', error);
            })
            .finally(() => {
                //this.columns = [...columns].filter(col => col.fieldName != 'Document_Sub_Type__c' && col.label != 'Verify');
                this.columns = [...columns];
                //this.addActions();
                this.makeNameClickable();
                this.columns = this.columns.concat([{ label: '', type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }]);
                this.showSpinner = false;
            });
    }


   // modified by Chandan on 25th July,2024 to Fetches and processes disbursement documents based on the provided lead ID(disbursement Id) and metadata.
    @api getDisbursementDocs() {
        this.showSpinner = true;
        getDisbursementDocs({
            disburseId: this.leadId,
            metadata: this.metadata
        })
            .then(result => {
                console.log('result : ', result);
                const { isSuccess, responseBody, totalRecords } = result;
                const allDocuments = JSON.parse(responseBody);
                console.log('this.metadata43========>', this.metadata);
                if (isSuccess) {
                    if (this.metadata === 'pdd') {
                        this.documentList = allDocuments.filter(doc => ((doc.Acknowledge_Status__c === 'PDD') || doc.Document_Category__c === 'Post Disbursal' || (doc.Acknowledge_Status__c === 'OTC')));
                        this.totalRecords = this.documentList.length;
                        console.log('Total records:', this.totalRecords);

                        allDocuments.forEach(doc => {
                            if (doc.Disbursement__c) {
                                this.disbursementStage = doc.Disbursement__r.Stage__c;
                                console.log('Stage__c:', this.disbursementStage);
                            }
                        });

                    } else {
                        this.documentList = allDocuments;
                        this.totalRecords = this.documentList.length;
                        console.log('Total records:', this.totalRecords);
                    }


                    this.paginationHelper();
                } else {
                    this.documentList = [];
                    console.log('Error in getDisbursementDocs result:', result);
                }
            })
            .catch(error => {
                this.documentList = [];
                console.log('Error fetching disbursement documents:', JSON.stringify(error));
            })
            .finally(() => {
                if (this.metadata === 'Sanction_Condition') {
                    this.setColumnsAndActions();
                    this.columns = this.columns.concat([{
                        label: 'Action',
                        fixedWidth: 100,
                        type: 'action',
                        typeAttributes: { rowActions: this.getRowActions.bind(this) }
                    }]);
                }
                else {
                    this.columns = [...columns];
                    //this.columns = [...columns].filter(col => col.fieldName !== 'Acknowledge_Status__c' && col.label !== 'Acknowledge Status');
                    this.makeNameClickable();
                    //   if (this.metadata !== 'pdd') {
                    this.columns = this.columns.concat([{
                        label: '',
                        type: 'action',
                        typeAttributes: { rowActions: this.getRowActions.bind(this) }
                    }]);
                    //  }
                    // }else if( this.disbursementStage === 'Disbursement Checker'){
                    //     this.columns = this.columns.concat([{
                    //         label: '',
                    //         type: 'action',
                    //         typeAttributes: { rowActions: this.getRowActions.bind(this) }
                    //     }]); 
                    // }

                }
                this.showSpinner = false;
            });
    }




    getSelectedAction(event) {
        console.log('event-> ', event);
        let selectedRows = JSON.parse(JSON.stringify(event.detail.selectedRows));
        console.log('selectedRows-> ', selectedRows);
    }



     //modified by chandan on 24th July,2024 to set actions based on different roles
    getRowActions(row, doneCallback) {
        const actions = [];

        // Common action for all roles
        actions.push({ label: "View", name: 'View', iconName: "utility:preview" });

        // Check user role and metadata to determine additional actions
        const isSanctionCondition = this.metadata === 'Sanction_Condition';
        const ispddCondition = this.metadata === 'pdd';
        const isSystemAdmin = this.userProfileName === 'System Administrator';
        const isCreditManager = this.userRoleName === 'Credit Manager';
        const isCPCMaker = this.userRoleName === 'CPC Agents (Maker)';
        const isCPCChecker = this.userRoleName === 'CPC Agents (Checker)';
        const isRCUManager = this.userRoleName === 'RCU Manager';
        const isRelationshipManager = this.userRoleName === 'Relationship Manager';
        const isPDD = this.PDD === 'pdd';
        const isLoginRecord = this.recordTypeName === 'Login';
        console.log('recordtype==> login', isLoginRecord);
        console.log('isRelationshipManager', isRelationshipManager);
        console.log('this.isReadOnlyRecord===>', this.isReadOnlyRecord);
        console.log('stage : ', this.disbursementStage);
        console.log('isPDD : ', ispddCondition);
        if (this.isReadOnlyRecord) {
            console.log('OUTPUT : INSIDE READ ONLY');

            if (ispddCondition && (isCPCChecker || isRelationshipManager || isSystemAdmin)) {
                // Additional actions for 'Sanction Condition' metadata and specific roles
                actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
                // actions.push({ label: "OTC", name: 'OTC' });
                // actions.push({ label: "PDD", name: 'PDD' });
            }
            //  actions.push({ label: "View", name: 'View', iconName: "utility:preview" });
            // Only 'View' action for read-only records
            // No additional actions are added
        } else if (ispddCondition && this.disbursementStage == 'PDD Collection') {
            actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
        }
        else if (isSanctionCondition && (isCreditManager || isSystemAdmin)) {
            // Additional actions for 'Sanction Condition' metadata and specific roles
            actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
            // actions.push({ label: "OTC", name: 'OTC' });
            // actions.push({ label: "PDD", name: 'PDD' });
        } else if (ispddCondition && (isCPCChecker || isSystemAdmin)) {
            // Additional actions for 'Sanction Condition' metadata and specific roles
            actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
            // actions.push({ label: "OTC", name: 'OTC' });
            // actions.push({ label: "PDD", name: 'PDD' });
        }
        else if (isRelationshipManager) {
            actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
            if (isLoginRecord) {
                actions.push({ label: "Submitted to CPA", name: 'Submitted to CPA', iconName: "action:check" });
            }
        } else {
            // Default actions for other roles
            // actions.push({ label: "View", name: 'View', iconName: "utility:preview" });
            actions.push({ label: "Upload", name: 'Upload', iconName: "action:upload" });
            if (isLoginRecord) {
                actions.push({ label: "Submitted to CPA", name: 'Submitted to CPA', iconName: "action:check" });
            }
        }
        console.log('credit userRoleName  ', this.userRoleName)
       

        // Call doneCallback with the actions after a delay
        setTimeout(() => {
            doneCallback(actions);
        }, 500);
    }


    makeNameClickable() {
        if (this.documentList) {
            if (this.userProfileName == 'USFB - Partner Community User') {
                this.documentList.forEach(item => item['DocumentName'] = this.label.portalUrl + item['Id']);
            } else {
                this.documentList.forEach(item => item['DocumentName'] = '/lightning/r/Document__c/' + item['Id'] + '/view');
            }
            //this.documentList.forEach(item => item['Lead__c'] = item['Lead__r.Name']);
        }
        this.documentList = this.documentList.map(row => {
            return { ...row, Lead__c: (row.Lead__c) ? row.Lead__r.Name : '' }
        })
        this.documentList = this.documentList.map(row => {
            return { ...row, Loan_Application__c: (row.Loan_Application__c) ? row.Loan_Application__r.Name : '' }
        })
        this.documentList = this.documentList.map(row => {
            return { ...row, Loan_Applicant__c: (row.Loan_Applicant__c) ? row.Loan_Applicant__r.Name : '' }
        })
    }

    handleRowAction(event) {
        console.log('handleRowAction event.detail.action.name-> ', event.detail.action.name);
        console.log('handleRowAction event.detail.row-> ', event.detail.row.Id);
        console.log('handleRowAction event.detail.row-> ', event.detail.row.Document_Type__c);
        console.log('handleRowAction event.detail.row-> ', this.userProfileName);
        let actionName = event.detail.action.name;
        this.documentId = event.detail.row.Id;
        if (actionName == 'Upload' && this.metadata !== 'pdd') {
            this.showModal = true;
        } if (actionName == 'View') {
            //added by Mohit on 01-08-2024 for BL - DSA don't have permission to view CIBIL report
            if (this.userProfileName == 'USFB BL - Partner Community User' && event.detail.row.Document_Type__c == 'Cibil Report') {
                this.showNotification('Warning', 'You do not have permission to view this document.', 'warning');
            } else {
                this.showPreviewModal = true;
                this.dmsDocumentIdSelected = event.detail.row.Id;
            }
            console.log('this.dmsDocumentIdSelected-> ', this.dmsDocumentIdSelected);
            //this.navigateToViewObjectPage();
        } if (actionName == 'Delete') {
            this.deleteDoc(this.documentId);
        } if (actionName == 'Submitted to CPA' || actionName == 'OTC' || actionName == 'PDD' || actionName == 'Waived Off' || actionName == 'Completed') {
            this.updateDocumentStatus(this.documentId, actionName);
        } if (actionName == 'Upload' && this.metadata === 'pdd') {
            this.isPDD = true;
        }
    }

     // When We Upload File Using File Uploader, This Function Will Call.
    handleFileUpload(event) {
        console.log('FILE STANDARD LWC UPLOAD')
        const file = event.detail.files[0];
        console.log('file->', file);
        console.log('file->', file.name);
        console.log('file->', file.contentBodyId);
        console.log('file->', file.contentVersionId);
        this.fileData = {
            'filename': file.name,
            'base64': file.contentBodyId,
            'contentVersionId': file.contentVersionId
        }
        //this.showNotification('Success', file.name + 'uploaded  successfully', 'success');
    }
    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field === 'awbNumber') {
            this.awbNumber = event.target.value;
        } else if (field === 'courierNumber') {
            this.courierNumber = event.target.value;
        } else if (field === 'dispatchDate') {
            const selectedDate = new Date(event.target.value);
            const today = new Date();

            // Reset time to 00:00:00 for both dates to only compare the date part
            selectedDate.setHours(0, 0, 0, 0);
            today.setHours(0, 0, 0, 0);

            console.log('today : ', today);
            console.log('selectedDate : ', selectedDate);

            if (selectedDate > today) {
                // If the dispatch date is in the future, show an error or reset the value
                this.showNotification('Error', 'Dispatch Date cannot be a future Date !!', 'error');
                event.target.value = ''; // Reset the field if the date is invalid
            } else {
                this.dispatchDate = event.target.value;
            }
        }
    }

    closeModal(event) {
        console.log('event.detail-> ', event.detail);
        this.showModal = event.detail;
        if (this.leadId) {
            if (this.objectName == 'Lead__c') {
                this.getLeadDocuments();
            } else if (this.objectName == 'Disbursement__c') {
                this.getDisbursementDocs();
            }
        } else {
            this.getApplicationDocuments();
        }
    }

    closeModal1() {
        this.isPDD = false;

    }

    // Navigate to View Account Page
    navigateToViewObjectPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.dmsDocumentIdSelected,
                objectApiName: 'Document__c',
                actionName: 'view'
            },
        });
    }

    deleteDoc(docId) {
        this.showSpinner = true;
        deleteDoc({ recordId: docId })
            .then(result => {
                if (result.isSuccess) {
                    this.showNotification('Success', 'Record is deleted successfully', 'success');
                    //this.template.querySelector('c-confirmation-dialog');
                } else {
                    this.showNotification('Error', 'Something Went Wrong!!', 'error');
                }
            })
            .catch(error => {
                //console.log('Error updateVerify= ', error);
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', 'Something Went Wrong!!', 'error');
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    updateDocumentStatus(docId, status) {
        this.showSpinner = true;
        updateDocumentStatus({ recordId: docId, status: status })
            .then(result => {
                console.log('result.updateDocumentStatus-> ', result);
                if (result.isSuccess) {
                    this.showNotification('Success', 'Record is updated successfully', 'success');
                    //this.template.querySelector('c-confirmation-dialog');
                } else {
                    this.showNotification('Error', 'Something Went Wrong!!', 'error');
                }
            })
            .catch(error => {
                //console.log('Error updateVerify= ', error);
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', 'Something Went Wrong!!', 'error');
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    // Common Method For Toast Message
    showNotification(title, msg, variant) {
        //eval("$A.get('e.force:refreshView').fire();");
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);

        //refreshApex(this.documentList);
        if (this.leadId) {
            this.getLeadDocuments();
        } else {
            this.getApplicationDocuments();
        }
    }

    handleClose() {
        const selectedEvent = new CustomEvent('closedetail', {
            detail: false
        });
        this.dispatchEvent(selectedEvent);
    }

    handleTableSelection(event) {
        console.log('event.detail.target-> ', event.detail.target);
    }

    closePreviewModal(event) {
        console.log('event-> ', event.detail);
        this.showPreviewModal = event.detail;
    }

    //Method added by Lakshya Verma
    handleAcknowledge() {
        if ((this.metadata === 'Sanction_Condition') && (this.objectName == 'Disbursement__c')) {
            this.getDisbursementDocs();
        }
        if ((this.metadata === 'Sanction_Condition') && (this.objectName == 'Loan_Application__c')) {
            this.getApplicationDocuments();
        }
        let selectedIds = [];
        let selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length > 0) {
            selectedRecords.forEach(currentItem => {
                console.log('currentItem.Status__c-> ', currentItem.Status__c);
                if (this.objectName == 'Disbursement__c') {
                    if (currentItem.Status__c == 'Uploaded' || currentItem.Status__c == 'Not Uploaded' || currentItem.Status__c == 'Submitted to CPA' || currentItem.Status__c == 'CPA Acknowledged' || currentItem.Status__c == 'CM Acknowledged' || currentItem.Status__c == 'RCU Acknowledged' || currentItem.Status__c == 'Query Raised') {
                        selectedIds.push(currentItem.Id);
                    }
                } else {
                    if (currentItem.Status__c == 'Uploaded' || currentItem.Status__c == 'Not Uploaded' || currentItem.Status__c == 'Submitted to CPA' || currentItem.Status__c == 'CPA Acknowledged' || currentItem.Status__c == 'CM Acknowledged' || currentItem.Status__c == 'RCU Acknowledged') {
                        selectedIds.push(currentItem.Id);
                    }
                }

            });
            //console.log('selectedIds' + JSON.stringify(selectedIds));
            if (selectedIds.length > 0 && selectedIds.length == selectedRecords.length) {
                this.documentId = selectedIds;
                this.isDialogVisible = true;
                console.log('bulk documentId', JSON.stringify(this.documentId));
            } else {
                if (this.objectName == 'Disbursement__c') {
                    this.showNotification('Warning', 'Please select uploaded document for verification.', 'warning');
                } else {
                    this.showNotification('Warning', 'Please select uploaded or Sent to CPA document for verification.', 'warning');
                }
            }
        } else {
            this.showNotification('Warning', 'Please select atleast one Document.', 'warning');
        }
    }


    //Added by Lakshya Verma for RCU vendors list on 14th aug
    handleRCUInitiateToVendors(){
        //this.isConfirmModelRCU = true;
        let selectedIds = [];
        this.getRCUVendors();
        let selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length > 0) {
            selectedRecords.forEach(currentItem => {
                console.log('currentItem-> ', currentItem);
                selectedIds.push(currentItem.Id);
            });
        }else {
            this.showNotification('Warning', 'Please select atleast one Document.', 'warning');
        }

        if (selectedIds.length > 0 && selectedIds.length == selectedRecords.length) {
            this.documentId = selectedIds;
            this.isConfirmModelRCU = true;
            console.log('bulk documentId', JSON.stringify(this.documentId));
        } else {
            
        }
        
    }

    //Added by Lakshya Verma for RCU vendors list on 14th aug
    handleSave(){
        console.log('this.documentId', JSON.stringify(this.documentId));
        console.log('this.selectedVendor', JSON.stringify(this.selectedVendor));
        console.log('this.applicationId', JSON.stringify(this.applicationId)); 
        console.log(' this.comment',  this.comment);
        this.initiateRCUtoVendor();
    }

     handleSubmit() {
        // Show spinner when submitting
        this.showSpinner = true;

        // Log the document upload action
        console.log('Uploading Document and Updating Details');

        // Prepare promises for both operations
        const uploadPromise = uploadDocument({
            documentSubType: this.documentSubType,
            fileName: this.fileData.filename,
            base64: this.fileData.base64,
            recordId: this.documentId,
            contentVersionId: this.fileData.contentVersionId
        });

        const updateDetailsPromise = updateDocumentDetails({
            documentId: this.documentId,
            awbNumber: this.awbNumber,
            courierNumber: this.courierNumber,
            dispatchDate: this.dispatchDate
        });

        // Use Promise.all to handle both promises in parallel
        Promise.all([uploadPromise, updateDetailsPromise])
            .then(([uploadResult, updateResult]) => {
                // Handle document upload result
                if (uploadResult.isSuccess) {
                    this.showNotification('Success', 'Document Uploaded and Details Updated Successfully', 'success');
                    // this.closeModal();
                    this.isPDD = false;

                } else {
                    // Show error if upload fails
                    this.showNotification('Error', uploadResult.responseBody, 'error');
                }
            })
            .catch(error => {
                // Handle any errors from either promise
                console.error('Error:', error);
                this.showNotification('Error', error.body?.message || 'An error occurred', 'error');
            })
            .finally(() => {
                // Hide spinner after operation completes
                this.showSpinner = false;
                window.location.reload();
                // refreshApex(this.documentList);
            });
    }




    // For Getting Input From Confirmation Modal
    handleConfirmationClick(event) {
        console.log('handleConfirmationClick ', event.detail.status);
        if (event.detail.status == 'close' || event.detail.status == 'cancel') {
            this.isDialogVisible = false;
        } if (event.detail.status == 'confirm') {
            this.isDialogVisible = false;
            if (this.objectName == 'Disbursement__c') {
                this.getDisbursementDocs();
            } else {
                this.getApplicationDocuments();
            }
        }
    }

    handleCloseRCUModel(){
        this.isConfirmModelRCU = false;
    }

    getRCUVendors() {
        this.showSpinner = true;
        getRCUVendors({ loanApplicationId: this.applicationId })
            .then(result => {
                console.log('result.getRCUVendors-> ', result);
                console.log('getUsersManagersList result === > ',JSON.stringify(result));
                if(result != null && result != undefined){
                    this.rcuVendorsOptions = [];
                    //this.tempResultRejection = result;
                    for (let key in result ) {
                        //this.usersList.push({ label: key, value: key });
                        this.rcuVendorsOptions.push({ label: result[key].Name, value: result[key].Id });
                    }
                    console.log('if this.rcuVendorsOptions-> ', JSON.stringify(this.rcuVendorsOptions));
                }else{
                    this.rcuVendorsOptions = null;
                    console.log('else this.rcuVendorsOptions-> ', this.rcuVendorsOptions);
                }
                this.showSpinner =false;
            })
            .catch(error => {
                //console.log('Error updateVerify= ', error);
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', 'Something Went Wrong!!', 'error');
            }).finally(() => {
                this.showSpinner = false;
            });

    }



    initiateRCUtoVendor() {
        this.showSpinner = true;
        initiateRCUtoVendor({ docIds: this.documentId, selectedVendorId : this.selectedVendor, applicationId : this.applicationId, susTrigger : this.comment   })
            .then(result => {
                console.log('result.initiateRCUtoVendor-> ', result);
                console.log('getUsersManagersList result === > ',JSON.stringify(result));
                if(result.isSuccess){
                    this.showNotification('Success', result.responseBody, 'success');
                    this.showSpinner =false;
                    this.isConfirmModelRCU = false;
                    setInterval(() => {
                        window.location.reload();
                    }, 1000);
                }else{
                    this.showNotification('Error', result.responseBody, 'error');
                    this.showSpinner =false;
                    this.isConfirmModelRCU = false;
                }
            })

            .catch(error => {
                console.log('Error initiateRCUtoVendor= ', error);
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', error, 'error');
                this.showSpinner = false;
                this.isConfirmModelRCU = false;
            }).finally(() => {
                this.showSpinner = false;
            });

    }



    getRCUActivityStatus() {
        this.showSpinner = true;
        getRCUActivityStatus({ loanApplicationId : this.applicationId })
            .then(result => {
                console.log('getRCUActivityStatus-> ', result);
                //console.log('getRCUActivityStatus-> ', result[0].Status__c);
                if(result){
                    if(result[0].Status__c != 'null' || result[0].Status__c != ''){
                        if(result[0].Status__c == 'Sampled'){
                            this.isRCUInitiateDisbale = false;
                            console.log('getRCUActivityStatus result === > ',JSON.stringify(result));
                        }else{
                            this.isRCUInitiateDisbale = true;
                        }
                    }
                }else{
                    //this.showNotification('Error', 'Something went wrong', 'error');
                     this.isRCUInitiateDisbale = true;
                }
            })
            .catch(error => {
                console.log('Error getRCUActivityStatus= ', JSON.stringify(error));
                //console.log('Error= ', error.body.message);
                this.showNotification('Error', error, 'error');
                this.showSpinner = false;
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    handleChange(event){
        this.selectedVendor = event.detail.value;
        console.log('this.selectedVendor ' , this.selectedVendor);
    }

    handleChangeTrigger(event){
        this.comment = event.detail.value;
        console.log(' this.comment',  this.comment);
    }


}