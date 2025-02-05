/**
* @File Name          : UB_LoanApplicationMoveToNextController.cls
* @Description        : This class use to move loan application stages.
* @Author             : Deepak Joshi
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-03-2024            Deepak Joshi           Initial Version
* 1.1         22-05-2024            Mohit                  Stage to PD in Progress
* 1.2         07-06-2024            Mohit                  Approve Stage Validations
* 1.3         10-06-2024            Lakshya Verma          Validation from Credit Assessment to Recommend for Approval
* 1.4         09-08-2024            Mohit                  BL related changes are shifted to BL_LoanApplicationMoveToNextController class.
**/
public class UB_LoanApplicationMoveToNextController {
    
    /**
* @description check validations before moving stage
* @return string
*/
    @AuraEnabled 
    public static string checkValidations(string recordId, String buttonLabel) {
        try{
            Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('LoanApplicationMoveToNextController');
            List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{recordId}); 
            System.debug('**loanAppObj--checkValidations->   '+loanAppObj ); 
            System.debug('**loanAppObj--messageConfigMap->   '+messageConfigMap ); 
            System.debug('**loanAppObj--buttonLabel->   '+buttonLabel ); 
            string validationMsg = checkValidation(loanAppObj[0],messageConfigMap, buttonLabel);
            system.debug('validationMsg>> ' + validationMsg);
            
            if(String.isNotBlank(validationMsg) && validationMsg.trim().length() > 0) {
                return validationMsg;
            }  
            //return null;        
        } catch (Exception e) {
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            String customMessge = e.getMessage();
            Integer startIndex = customMessge.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
            if (startIndex != -1) {
                startIndex += 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length() + 2;
                customMessge =  'ERROR: '+customMessge.substring(startIndex);
            }else{
                customMessge = 'ERROR: ' + e.getMessage();
            }
            //return customMessge;
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    /**
* @description move to  next stage
* @return string
*/
    @AuraEnabled
    public static string moveToNext(string recordId) {
        system.debug('move to next');
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('LoanApplicationMoveToNextController');
            List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{recordId});
            System.debug('**loanAppObj--->   '+loanAppObj);            
            if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.KYC_VALIDATION){
                loanAppObj[0].Loan_Application_Stage__c =UB_ConstantsUtil.CIBIL;
                update loanAppObj[0];
                // Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION , loanAppObj[0].Id, UB_ConstantsUtil.KYC_VALIDATION ,UB_ConstantsUtil.CIBIL);
                // insert activityHistory;
                return UB_ConstantsUtil.CIBIL;
            }
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.CIBIL){
                
                
                loanAppObj[0].Loan_Application_Stage__c =UB_ConstantsUtil.DOCUMENT_VERIFICATION;
                loanAppObj[0].Document_Verification_Start_Date__c = System.now();
                system.debug('Document_Verification_Start_Date__c> ' +  loanAppObj[0].Document_Verification_Start_Date__c);
                update loanAppObj[0];
                
                String createDocumentd  =   createDocument(loanAppObj[0]);
                if(createDocumentd =='SUCCESS'){
                    // Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION,loanAppObj[0].Id, UB_ConstantsUtil.CIBIL ,UB_ConstantsUtil.DOCUMENT_VERIFICATION);
                    // insert activityHistory;
                    return UB_ConstantsUtil.DOCUMENT_VERIFICATION;
                }
                else{
                    Database.rollback(sp);
                    return createDocumentd;
                }
                
            }
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.DOCUMENT_VERIFICATION){
                loanAppObj[0].Loan_Application_Stage__c =UB_ConstantsUtil.DDE;
                //Added By Mohit on 03-07-2024 for BL - <Assign to CPA directly in case of BL>
                if(loanAppObj[0].LOB__c == UB_ConstantsUtil.LOB_BL){
                    if(loanAppObj[0].User_Role__c == 'BL Relationship Manager'){
                        loanAppObj[0].Ro_RM__c = loanAppObj[0].OwnerId;
                    }
                    loanAppObj[0].OwnerId = BL_LoanApplicationMoveToNextController.transferToCPAQueue(loanAppObj);
                }else {
                    loanAppObj[0].Ro_RM__c = loanAppObj[0].OwnerId; 
                    List<Group>  queuleist = new UB_QueuesSelector().selectQueueDeveloperName('CPA_Team');
                    loanAppObj[0].OwnerId =queuleist[0].Id;
                }
                loanAppObj[0].RecordTypeId = Schema.SObjectType.Loan_Application__c.getRecordTypeInfosByDeveloperName().get(UB_ConstantsUtil.DDE).getRecordTypeId();
                update loanAppObj[0];
                // Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION,loanAppObj[0].Id, UB_ConstantsUtil.DOCUMENT_VERIFICATION ,UB_ConstantsUtil.DDE);
                // insert activityHistory;
                return 'DDEMoved ::'+UB_ConstantsUtil.DDE;
            }
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.DDE){
                
                loanAppObj[0].Loan_Application_Stage__c =UB_ConstantsUtil.LAF_GENERATION_CONSENT;
                update loanAppObj[0];
                // Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION,loanAppObj[0].Id, UB_ConstantsUtil.DDE ,UB_ConstantsUtil.LAF_GENERATION_CONSENT);
                // insert activityHistory;
                return UB_ConstantsUtil.LAF_GENERATION_CONSENT;
            }
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.LAF_GENERATION_CONSENT){
                loanAppObj[0].Loan_Application_Stage__c =UB_ConstantsUtil.ASSIGNED_TO_CREDIT;
                loanAppObj[0].RecordTypeId = UB_ConstantsUtil.UNDERWRITING_INITIATED_APPLICATION_RECORD_TYPE;
                //Added By Mohit on 31-07-2024 for CV/CE - <Assign to CM Queue directly in case of CV/CE>
                if(loanAppObj[0].LOB__c != UB_ConstantsUtil.LOB_BL){
                    List<Group>  queuleist = new UB_QueuesSelector().selectQueueDeveloperName('Credit_Manager_Queue');
                    loanAppObj[0].OwnerId =queuleist[0].Id;
                }else{ 
                    //Added By Mohit on 31-07-2024 for BL - <Assign to CM Queue directly in case of BL>
                    loanAppObj[0].OwnerId = BL_LoanApplicationMoveToNextController.transferToBCMQueue(loanAppObj);
                }
                update loanAppObj[0];
                // Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION,loanAppObj[0].Id, UB_ConstantsUtil.LAF_GENERATION_CONSENT ,UB_ConstantsUtil.ASSIGNED_TO_CREDIT);
                // insert activityHistory;
                return UB_ConstantsUtil.ASSIGNED_TO_CREDIT;
            }
            /**** Version 1.1- Added by Mohit on 22-05-2024 (Starts)****/
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.ASSIGNED_TO_CREDIT){
                loanAppObj[0].Loan_Application_Stage__c = UB_ConstantsUtil.PD_IN_PROGRESS;
                UB_LoanApplicationUtility.updateRecords(new List<Loan_Application__c>{loanAppObj[0]});
                return UB_ConstantsUtil.PD_IN_PROGRESS;
            }
            /**** Version 1.1- Added by Mohit on 22-05-2024 (Ends)****/
            
            /**** Version 1.1- Added by Lakshya on 07-06-2024 (Starts)****/
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.PD_IN_PROGRESS){
                loanAppObj[0].Loan_Application_Stage__c = UB_ConstantsUtil.CREDIT_ASSESSMENT;
                UB_LoanApplicationUtility.updateRecords(new List<Loan_Application__c>{loanAppObj[0]});
                return UB_ConstantsUtil.CREDIT_ASSESSMENT;
            }
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.CREDIT_ASSESSMENT){
                Id managerId  = [select id, name, profile.name, userrole.name, Manager.name, ManagerId from user where Id =: loanAppObj[0].ownerId].ManagerId;
                List<Deviation_Sanction_Condition__c> deviationConditionList = new  List<Deviation_Sanction_Condition__c>();
                for(Deviation_Sanction_Condition__c deviationCondition : [select id ,Deviation__c, Loan_Application__c,Deviations__c, Decision__c 
                                                                          FROM Deviation_Sanction_Condition__c 
                                                                          WHERE Loan_Application__c =: loanAppObj[0].Id
                                                                         ]){
                                                                             deviationCondition.Decision__c = UB_ConstantsUtil.SENT_FOR_REVIEW;
                                                                             deviationConditionList.add(deviationCondition);
                                                                         }
                if(deviationConditionList != null && deviationConditionList.size() > 0){
                    UPDATE deviationConditionList;
                }
                loanAppObj[0].Loan_Application_Stage__c = UB_ConstantsUtil.RECOMMENDED_FOR_APPROVAL;
                loanAppObj[0].OwnerId = managerId;
                UB_LoanApplicationUtility.updateRecords(new List<Loan_Application__c>{loanAppObj[0]});
                /**** Version 1.2- Added by Mohit on 07-06-2024 (Starts)****/
                if(loanAppObj[0].Amount__c != null && loanAppObj[0].Amount__c > 0){
                    Approval_Matrix__mdt customMetaData = Approval_Matrix__mdt.getInstance('Committee');
                    if(customMetaData.Range_Min__c != null && customMetaData.Range_Min__c > 0){
                        if(loanAppObj[0].Amount__c >= customMetaData.Range_Min__c){
                            Document__c doc = new Document__c();
                            doc.File_Name__c = UB_ConstantsUtil.COMMITTEE_APPROVAL_NOTES_DOC_TYPE;
                            doc.Loan_Application__c = loanAppObj[0].Id;
                            doc.Document_Type__c = UB_ConstantsUtil.COMMITTEE_APPROVAL_NOTES_DOC_TYPE;
                            doc.Is_Required__c = true;
                            insert doc;                
                        }
                    }
                }  
                /**** Version 1.2- Added by Mohit on 07-06-2024 (Ends)****/
                
                return UB_ConstantsUtil.RECOMMENDED_FOR_APPROVAL;
            }
            /**** Version 1.1- Added by Lakshya on 07-06-2024 (Ends)****/
            
            /**** Version 1.2- Added by Mohit on 07-06-2024 (Starts)****/
            else if(loanAppObj[0].Loan_Application_Stage__c == UB_ConstantsUtil.RECOMMENDED_FOR_APPROVAL){
                //Create Sanction Condition if there is any open RCU activity
                List<Valuation__c> valuationList = new UB_ActivitySelector().selectByAppId_RecType_Status(new Set<Id>{loanAppObj[0].Id}, new Set<String>{UB_ConstantsUtil.RCU_VALUATION_RECORD_TYPE},  new Set<String>{UB_ConstantsUtil.APPROVED_STATUS});
                if(valuationList.isEmpty()){
                    Document__c doc = UB_CommonUtil.createSanctionCondition(loanAppObj[0].Id, UB_ConstantsUtil.SANCTION_CONDITION_TYPE, UB_ConstantsUtil.PENDING_STATUS);
                    doc.Description__c = 'Subject to Positive RCU Report to be obtained before disbursement';
                    doc.Sanction_Condition_Sl_no__c = 1;
                    insert doc;
                }
                
                loanAppObj[0].Loan_Application_Status__c = UB_ConstantsUtil.APPROVED_STATUS;
                loanAppObj[0].RecordTypeId               = UB_ConstantsUtil.DISBURSEMENT_INITIATED_RECORD_TYPE;
                loanAppObj[0].Loan_Application_Stage__c  = UB_ConstantsUtil.DISBURSAL_IN_PROGRESS;
                if(loanAppObj[0].Ro_RM__c != null){
                    loanAppObj[0].OwnerId = loanAppObj[0].Ro_RM__c;
                }
                loanAppObj[0].Final_Authority__c = UserInfo.getUserId();
                loanAppObj[0].isSendBackforMoveToNext__c = false;
                update loanAppObj[0];
                List<Fee_Master__mdt > feeMasterList = [SELECT Id,Fee_Name__c,Amount_Value__c,Calculation_Type__c,GST_Percentage__c,LOB__c,Percentage_Of__c,Vehicle_Classification__c From Fee_Master__mdt WHERE isActive__c = true];
                List<Vehicle__c> vehicleList = new UB_VehiclesSelector().selectByLoanApplicationId(new Set<Id>{loanAppObj[0].Id});
                List<Disbursement__c> disbursementList = new List<Disbursement__c>();
                if(!vehicleList.isEmpty() && vehicleList.size() > 0){
                    for(Vehicle__c obj : vehicleList){
                        if(obj.Number_Of_Vehicles__c != null && obj.Number_Of_Vehicles__c > 0){
                            for(Integer i = 0; i < obj.Number_Of_Vehicles__c; i++){
                                Disbursement__c createObj = UB_CommonUtil.createDisbursement(obj.Id, obj.Loan_Application__c, UB_ConstantsUtil.PREDISBURSAL_DOCUMENT_COLLECTION_STAGE, UB_ConstantsUtil.ACTIVE_STATUS);
                                createObj.Tenure__c           = obj.Tenure__c;
                                createObj.ROI__c              = obj.ROI__c;
                                createObj.Insurance_Amount__c = obj.Asset_Insurance_Premium__c; 
                                createObj.CM__c               = loanAppObj[0].CM__c;
                                createObj.Stage__c            = UB_ConstantsUtil.NEGOTIATION_STAGE;
                                createObj.RM_RO__c            = loanAppObj[0].Ro_RM__c;
                                createObj.Vehicle__c          = obj.Id;
                                if(loanAppObj[0].Ro_RM__c != null ){
                                    createObj.OwnerId = loanAppObj[0].Ro_RM__c;
                                }
                                createObj.Loan_Amount__c  = obj.Credit_Facility_Amount__c;
                                if(String.isNotBlank(loanAppObj[0].LOB__c)){
                                    createObj.RecordTypeId = loanAppObj[0].LOB__c.contains(UB_ConstantsUtil.LOB_BL) ? UB_ConstantsUtil.BL_DISBURSEMENT_RECORD_TYPE : UB_ConstantsUtil.CV_CE_DISBURSEMENT_RECORD_TYPE;
                                }
                                disbursementList.add(createObj);
                            }
                        }
                    }
                    if(!disbursementList.isEmpty() && disbursementList.size() > 0){
                        insert disbursementList; 
                        List<Disbursement__c> fetchCreatedDisbursment = new List<Disbursement__c>();
                        for(Disbursement__c disbursment : [SELECT Id,Loan_Amount__c,Tenure__c,ROI__c , Insurance_Amount__c,CM__c,Stage__c,Vehicle__c,Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c,Vehicle__r.recordType.Name,Vehicle__r.Dealer__r.IFSC_Code__c FROM Disbursement__c WHERE Id IN:disbursementList]) {
                            fetchCreatedDisbursment.add(disbursment);
                        }
                        System.debug('fetchCreatedDisbursment  '+fetchCreatedDisbursment);
                        String condition = 'Applicable_For__c = \''+UB_ConstantsUtil.DISBURSEMENT+'\' AND ';
                        condition += ' Stage__c = \''+UB_ConstantsUtil.DISBURSAL_IN_PROGRESS+'\' AND ';
                        condition += ' Is_Active__c = true ';
                        List<Document_Checklist__c> docCheckList = new UB_DocumentChecklistsSelector().selectByCondition(condition);
                        system.debug('docCheckList!!'+docCheckList.size());
                        if(!docCheckList.isEmpty() && docCheckList.size() > 0){
                            List<Document__c> createDocs = new List<Document__c>();
                            List<Bank_Details__c> createBankDetails = new List<Bank_Details__c>();
                            List<Fees__c> createFeeDetails = new List<Fees__c>();
                            system.debug('disbursementList!!'+disbursementList.size());
                            for(Disbursement__c disc : fetchCreatedDisbursment){
                                for(Document_Checklist__c obj : docCheckList){
                                    if(String.isNotBlank(loanAppObj[0].LOB__c) && obj.LOB__c.contains(loanAppObj[0].LOB__c)){
                                        Document__c doc = new Document__c();
                                        doc.Document_Checklist__c = obj.Id;
                                        doc.Document_Type__c      = String.isNotBlank(obj.Disbursement_Type__c) ? obj.Disbursement_Type__c : '';
                                        doc.Document_Sub_Type__c  = String.isNotBlank(obj.Disbursement_Sub_Type__c) ? obj.Disbursement_Sub_Type__c : '';
                                        //doc.Loan_Application__c   = loanAppObj[0].Id; //these docs need to show against Disbursement record, These are mixing with application record that's why commenting this line---------Mansur
                                        doc.Is_Required__c        = obj.Is_Required__c;
                                        doc.Disbursement__c       = disc.Id;
                                        if(loanAppObj[0].Ro_RM__c != null ){
                                            doc.OwnerId = loanAppObj[0].Ro_RM__c;
                                        }
                                        createDocs.add(doc);
                                    }
                                }
                                /**** Version 1.1- Added by Mansur Alam on 03-07-2024 (start)****/
                                
                                if(!feeMasterList.isEmpty() && feeMasterList.size() > 0){
                                    for(Fee_Master__mdt fee : feeMasterList){
                                        if(fee.LOB__c == loanAppObj[0].LOB__c){
                                            if(fee.Vehicle_Classification__c != null && fee.Vehicle_Classification__c == disc.Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c){
                                                Fees__c feeObj = new Fees__c();
                                                feeObj.Name = fee.Fee_Name__c;
                                                feeObj.Disbursement__c  = disc.Id;
                                                // Amount calculation
                                                if(fee.Calculation_Type__c == UB_ConstantsUtil.AMOUNT){
                                                    feeObj.Amount__c = fee.Amount_Value__c;
                                                }else{
                                                    feeObj.Amount__c = disc.Loan_Amount__c*(fee.Amount_Value__c /100); //ex 0.03 % of Loan_Amount__c
                                                }
                                                //GST Amount calculation
                                                feeObj.GST_Amount__c = feeObj.Amount__c * (fee.GST_Percentage__c/100);
                                                //Total Amount calculation
                                                feeObj.Total_Amount__c = ( feeObj.Amount__c + feeObj.GST_Amount__c );
                                                feeObj.Loan_Application__c = loanAppObj[0].Id;
                                                createFeeDetails.add(feeObj);  
                                                system.debug('feeeee>>>> ' + feeObj);
                                            }
                                            else if(fee.Vehicle_Classification__c == null){
                                                Fees__c feeObj = new Fees__c();
                                                feeObj.Name = fee.Fee_Name__c;
                                                feeObj.Disbursement__c  = disc.Id;
                                                // Amount calculation
                                                if(fee.Calculation_Type__c == UB_ConstantsUtil.AMOUNT){
                                                    feeObj.Amount__c = fee.Amount_Value__c;
                                                }else{
                                                    feeObj.Amount__c = disc.Loan_Amount__c*(fee.Amount_Value__c /100); //ex 0.03 % of Loan_Amount__c
                                                }
                                                //GST Amount calculation
                                                feeObj.GST_Amount__c = feeObj.Amount__c * (fee.GST_Percentage__c/100);
                                                //Total Amount calculation
                                                feeObj.Total_Amount__c = ( feeObj.Amount__c + feeObj.GST_Amount__c );
                                                feeObj.Loan_Application__c = loanAppObj[0].Id;
                                                createFeeDetails.add(feeObj);  
                                                system.debug('feeeee>>>> ' + feeObj);   
                                            }
                                            
                                        }
                                    }
                                }
                                /**** Version 1.1- Added by Mansur Alam on 03-07-2024 (end)****/
                                /**** Added by Musab || 25-07-2024
Purpose- condition to create Bank Detail record only for new vehicles ****/
                                if(disc.Vehicle__r.recordType.Name == UB_ConstantsUtil.NEW_VEHICLE){
                                    //if(disc.Vehicle__r.Product__r.Product_Category__c == 'CV-New'){
                                    Bank_Details__c bankDetail = new Bank_Details__c();
                                    bankDetail.Loan_Application__c = loanAppObj[0].Id;
                                    bankDetail.Active_Since__c     = System.today();
                                    bankDetail.IFSC_Code__c        = disc.Vehicle__r.Dealer__r.IFSC_Code__c;
                                    bankDetail.Disbursement__c     = disc.Id;
                                    bankDetail.RecordTypeId        = UB_ConstantsUtil.DISBURSEMENT_RECORD_TYPE;
                                    createBankDetails.add(bankDetail);
                                }
                            }
                            
                            if(!createDocs.isEmpty() && createDocs.size() > 0){
                                system.debug('createDocs!!'+createDocs.size());
                                insert createDocs;
                            }
                            if(!createBankDetails.isEmpty() && createBankDetails.size() > 0){
                                system.debug('createBankDetails!!'+createBankDetails.size());
                                insert createBankDetails;
                            }
                            if(!createFeeDetails.isEmpty() && createFeeDetails.size() > 0){
                                system.debug('createFeeDetails!!'+createFeeDetails.size());
                                insert createFeeDetails;
                            }
                        }
                    }
                }
                
                UB_LoanApplicationMoveToNextController.loanApplicationProvisionalDocument(loanAppObj[0].Id);
                
                /*
Author : Zafaruddin
Date : 10/07/2024
Description :  Link CAM pdf to document checklist.
*/
                if(loanAppObj[0].Cam_Generate__c) {
                    CAM_PDFController.linkCamToDocument(loanAppObj[0].Id);
                }                // end here
                return UB_ConstantsUtil.PREDISBURSAL_DOCUMENT_COLLECTION_STAGE;
            }
            /**** Version 1.2- Added by Mohit on 07-06-2024 (Ends)****/
            else{
                return '';
            }
            
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            String customMessge = e.getMessage();
            Integer startIndex = customMessge.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
            if (startIndex != -1) {
                startIndex += 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length() + 2;
                customMessge =  'ERROR: '+customMessge.substring(startIndex);
            }else{
                customMessge = 'ERROR: ' + e.getMessage();
            }
            return customMessge;
            // throw new AuraHandledException(e.getMessage());
        }
        
    }
    /**
* @description check user is DSA user
* @return Boolean
*/
    private static Boolean checkCurrentUserProfile(){
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME){
            return true;
        }
        return false;
        
    }
    /**
* @description LoanApplicationProvisionalDocument
* @return void
* @Author : Lakshya Verma 14-June-2024
*/
    public static void loanApplicationProvisionalDocument(String LAFId) {
        try {
            if(String.isNotBlank(LAFId)) {
                System.debug('LAFId ID v  '+LAFId);
                Blob b ;
                if(String.isNotBlank(LAFId)) {
                    PageReference PDf = Page.CV_Provisional_Sanction_Letter;
                    PDf.getParameters().put('Id',LAFId);
                    PDf.setRedirect(false);
                    b = PDf.getContentAsPdf();
                    system.debug('b-> ' + b);
                    UB_CommonUtil.createDocument('Provisional Sanction Letter','Provisional Sanction Letter.PDF', b,LAFId, NULL,'Provisional Sanction Letter','Provisional Sanction Letter');
                }
            }
        } catch (Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }
    
    public static String checkAddressForApplicants(List<Loan_Applicant__c>  loanApplicantList) {
        String validationMsg = '';
        String addressMessage = '';
        
        String residenceAddressCompare = '';
        Integer individualAddressCount = 0;
        Integer nonIndividualAddressCount = 0;
        Set<String> applicantNames = new Set<String>();
        Set<String> applicantNamesNI = new Set<String>();
        Map<String, Integer > applicantsAddressMap = new  Map<String, Integer >();
        for(Loan_Applicant__c  applicant : loanApplicantList) {
            applicantsAddressMap.put(applicant.Id, NULL);
        }
        SYstem.debug('applicantsAddressMap  '+applicantsAddressMap);
        for(Loan_Applicant__c  applicant : [SELECT Id, RecordType.Name,Account_Name__c FROM Loan_Applicant__c WHERE Id IN:applicantsAddressMap.keySet() AND Is_Deleted__c = 'NO' ]) {
            applicantsAddressMap.put(applicant.RecordType.Name, 0);
            if(applicant.RecordType.Name == 'Individual') {
                individualAddressCount += 1;
            }else {
                nonIndividualAddressCount += 1;
            }
            // Code to fetch Name of Applicant who have missing Addess.
            Integer count = 0;
            for(Address__c address : [SELECT Id,
                                      Loan_Applicant__c, Loan_Applicant__r.RecordType.Name, Address_Type__c FROM Address__c WHERE Loan_Applicant__c IN : applicantsAddressMap.keySet() AND Loan_Applicant__c != NULL]) {
                                          if(address.Loan_Applicant__c == applicant.Id && address.Loan_Applicant__r.RecordType.Name == 'Individual' &&  (address.Address_Type__c == 'Permanent Address' || address.Address_Type__c == 'Residence Address')) {
                                              count += 1;
                                          }
                                          else if (address.Loan_Applicant__c == applicant.Id && address.Loan_Applicant__r.RecordType.Name == 'Non Individual' &&  address.Address_Type__c == 'Office Address') {
                                              count += 1;
                                          }
                                      }
            System.debug('applicant.RecordType.Name  '+applicant.RecordType.Name);
            System.debug('count  countcountcount  '+count);
            if(applicant.RecordType.Name == 'Individual' && count != 2) {
                applicantNames.add(applicant.Account_Name__c);
            }
            else if(applicant.RecordType.Name == 'Non Individual' && count != 1) {
                applicantNamesNI.add(applicant.Account_Name__c);
                
            }
        }
        SYstem.debug('applicantsAddressMap111111111  '+applicantsAddressMap);
        if(!applicantsAddressMap.keySet().IsEmpty()) {
            
            for(Address__c address : [SELECT Id,Aadhar_Address__c,Compare_Address_with_Aadhar__c,
                                      Loan_Applicant__c, Loan_Applicant__r.RecordType.Name, Address_Type__c,Loan_Applicant__r.Account_Name__c 
                                      FROM Address__c WHERE Loan_Applicant__c IN : applicantsAddressMap.keySet() AND Loan_Applicant__c != NULL]) {
                                          //applicantsAddressMap.clear();
                                          
                                          if(address.Address_Type__c == 'Residence Address' && address.Aadhar_Address__c != NULL && !address.Compare_Address_with_Aadhar__c) {
                                              residenceAddressCompare += address.Loan_Applicant__r.Account_Name__c + ', ';
                                          }
                                          SYstem.debug('Applicant   '+address.Loan_Applicant__c);
                                          System.debug('Loan_Applicant__r.RecordType.Name  '+address.Loan_Applicant__r.RecordType.Name);
                                          if(address.Loan_Applicant__r.RecordType.Name == 'Individual' && (address.Address_Type__c == 'Permanent Address' || address.Address_Type__c == 'Residence Address')) {
                                              System.debug('SSSS  '+applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name));
                                              if(applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) != 0) {
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name, applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) +1);
                                              } else { 
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name,1);
                                              }                
                                              
                                          } else if(address.Loan_Applicant__r.RecordType.Name == 'Non Individual' && address.Address_Type__c == 'Office Address') {
                                              if(applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) != 0) {
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name, applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) +1);
                                              } else { 
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name,1);
                                              }
                                          }
                                      }
            System.debug('applicantsAddressMap FINAL  '+applicantsAddressMap);
            System.debug('individualAddressCount   '+individualAddressCount);
            System.debug('nonIndividualAddressCount   '+nonIndividualAddressCount);
            String appName = String.valueOf(applicantNames).replace('{','').replace('}','');
            System.debug('appNameappNameappName  '+appName);
            String appNameNI = String.valueOf(applicantNamesNI).replace('{','').replace('}','');
            System.debug('appNameNIappNameNI  '+appNameNI);
            if(applicantsAddressMap.get('Individual') != NULL && applicantsAddressMap.get('Individual') != 2*individualAddressCount) {
                validationMsg  += '<li>'+'Permanent and Residence  Address is Mandatory for Individual Applicant <b>'+appName+'</b>'+'</li>';
                System.debug('222222');
            }
            if(applicantsAddressMap.get('Non Individual') != NULL && applicantsAddressMap.get('Non Individual') != nonIndividualAddressCount) {
                //addressMessage += 'Office Address is Mandatory for Non Individual  Applicant' ;
                validationMsg  += '<li>'+'Office Address is Mandatory for Non Individual  Applicant <b>'+appNameNI+'</b>'+'</li>';
                System.debug('3333');
            }
            SYstem.debug('residenceAddressCompare  '+residenceAddressCompare);
            if(residenceAddressCompare.length() > 0) {
                validationMsg  += '<li>'+ ' Compare Residence address with Aadhar address for Applicant ' + residenceAddressCompare.replace(',',' ')+' <b> '+appName+' </b> '+'</li>';
            }
        }
        return validationMsg;
    }
    
    /**
* @description check validation move to next stage
* @return static
*/
    private static string checkValidation(Loan_Application__c loanApplication,Map<String,Messages_Config__mdt> messageConfigMap, String buttonLabel) {
        String validationMsg = '';
        System.debug('checkValidation!!');
        try{
            Boolean isActivity = getActivityHistory(loanApplication);
            if(isActivity == false){
                //validationMsg  +=  '<li> <b>'+messageConfigMap.get('NoActivityLast_30day').Message__c+ '</b></li>';
                //return validationMsg;
            }
            List<Loan_Applicant__c>  loanApplicantList = new UB_LoanApplicantsSelector().selectByIdWithLoanApplication(new Set<Id>{loanApplication.Id});
            string currentUser = userinfo.getuserId(); 
            List<user> CMLst = [select id,name,UserRole.Name from user where id =: currentUser AND UserRole.Name = 'Credit Manager'];
            String KYC_ValidationCheck = check_KYC_Validation(loanApplicantList , messageConfigMap);
            if(KYC_ValidationCheck != ''){
                validationMsg += KYC_ValidationCheck;
            }
            /**** Added by Chandan on 22-07-2024****/
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.CREDIT_ASSESSMENT || loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.RECOMMENDED_FOR_APPROVAL){
                String RCUNotVerifiedDocs = checkRCUDocuments(loanApplication,loanApplicantList);
                if(RCUNotVerifiedDocs != null && CMLst.size()>0){
                    validationMsg  += RCUNotVerifiedDocs;
                }
            }
            if(loanApplication.Branch__c == null)  {
                validationMsg  += '<li>'+messageConfigMap.get('Add_Branch').Message__c+'</li>';
            }
            
            
            
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.KYC_VALIDATION 
               || loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DDE){
                   system.debug('Loan_Application_Stage__c ' + loanApplication.Loan_Application_Stage__c);
                   String secondaryApplicantCheck  =  '';
                   //String addressValidation = checkAddressForApplicants(loanApplicantList);
                   String addressValidation = '';
                   String ROI_Validation = '';
                   system.debug('loanApplication.LOB__c-> ' + loanApplication.LOB__c);
                   if(loanApplication.LOB__c == UB_ConstantsUtil.LOB_CV || loanApplication.LOB__c == UB_ConstantsUtil.LOB_CE){
                       addressValidation = checkAddressForApplicants(loanApplicantList);
                       ROI_Validation = check_ROI_Validation(loanApplication , messageConfigMap);
                       if(ROI_Validation != ''){
                           validationMsg += ROI_Validation;
                       }
                       secondaryApplicantCheck  =  secondaryApplicantCheck(loanApplicantList , messageConfigMap,loanApplication.Loan_Application_Stage__c);
                   }else if(loanApplication.LOB__c == UB_ConstantsUtil.LOB_BL){
                       addressValidation = BL_LoanApplicationMoveToNextController.checkAddressForApplicantsForBL(loanApplicantList);
                       //Added By Mohit on 30-07-24 for BL - <Bug: USFBL-174 (Show mandatory fields validation for applicants)>
                       if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.KYC_VALIDATION){
                           validationMsg += BL_LoanApplicationMoveToNextController.mandatoryfieldsValidation(loanApplicantList, messageConfigMap);
                       }
                       secondaryApplicantCheck  =  BL_LoanApplicationMoveToNextController.secondaryApplicantCheck(loanApplicantList , messageConfigMap,loanApplication.Loan_Application_Stage__c);
                   }
                   System.debug('addressValidation   '+addressValidation);
                   if(addressValidation.length() > 0) {
                       validationMsg += addressValidation;
                   }
                   if(secondaryApplicantCheck != ''){
                       validationMsg += secondaryApplicantCheck;
                   }
               }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.CIBIL 
               || loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DDE){
                   
                   String KYC_Validation = check_KYC_ValidationCible(loanApplicantList , messageConfigMap);
                   if(KYC_Validation != ''){
                       validationMsg += KYC_Validation;
                   }
                   System.debug('** Products  :   '+loanApplication.Products__r);
                   if(loanApplication.Products__r.size() == 0){
                       validationMsg += '<li>'+messageConfigMap.get('ProductRequired').Message__c+'</li>';
                   } 
                   
                   //Added By Mohit on 29-08-24 for BL - <Bug: USFBL-351 (Balance Transfer Validation)>
                   if(loanApplication.LOB__c == UB_ConstantsUtil.LOB_BL){
                       if(loanApplication.Products__r.size() == 1){
                           validationMsg += BL_LoanApplicationMoveToNextController.checkBalanceTransferValidation(loanApplication, messageConfigMap);
                       }
                   }
               }
            Boolean isDockmentCheck = false;
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DOCUMENT_VERIFICATION || loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DDE){
                String documentValidationMessage = checkDocumentValidations(loanApplication.Id , messageConfigMap);
                if(documentValidationMessage != ''){
                    validationMsg += documentValidationMessage;
                    isDockmentCheck = true;
                }
                
                system.debug('loanApplication.Reference_Members__r.size()-> ' + loanApplication.Reference_Members__r.size());
                system.debug('loanApplication.lob__c-> ' + loanApplication.lob__c);
                
                //Addedd by Lakshya on 26th Aug for members validations on move to next
                if(loanApplication.lob__c == 'BL'){ 
                    if(loanApplication.Reference_Members__r.size() == 0 || loanApplication.Reference_Members__r.size() == 1){
                        validationMsg += '<li>'+BL_ConstantsUtil.REFERENCE_ERROR+'</li>';
                    }
                }
                
            }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DOCUMENT_VERIFICATION && isDockmentCheck == false){
                Boolean isCommuntuUser = checkCurrentUserProfile();
                if(isCommuntuUser == true){
                    return '<li> <b>'+messageConfigMap.get('DSA_User_Access').Message__c+ '</b></li>';
                }
                
            }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.DDE){
                
                if(loanApplication.Products__r.size() > 0 && loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
                    system.debug('loanApplication.Products__r> '+ loanApplication.Products__r);
                    String vehicleCheck   = vehicleCheck(loanApplication.Products__r ,messageConfigMap,loanApplication);
                    if(vehicleCheck != ''){
                        validationMsg += vehicleCheck;
                    }
                    //Added by mansur--01-09-2024
                    String viabilityAndHireValidation = viabilityAndHireValidation(loanApplication.Products__r,loanApplication.Id ,messageConfigMap);
                    if(viabilityAndHireValidation != ''){
                        validationMsg += viabilityAndHireValidation;
                    }
                }
                //end here
                String checkRaiseQuery   = checkRaiseQuery(loanApplication ,messageConfigMap);
                if(checkRaiseQuery != ''){
                    validationMsg += checkRaiseQuery;
                }
                
                //CPA Acknowledge validation for all the document at the DDE Stage
                String  cpaAcknowlwdge= cpa_Acknowlwdge(loanApplication , messageConfigMap);
                if(cpaAcknowlwdge != ''){
                    system.debug('cpaAcknowlwdge>>>>> '+ cpaAcknowlwdge);
                    validationMsg += cpaAcknowlwdge;
                }
                
                if(loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
                    //Reference/member record validation
                    String  reference_member= referenceMembers(loanApplication , messageConfigMap);
                    if(reference_member != ''){
                        system.debug('reference_member>>>>> '+ reference_member);
                        validationMsg += reference_member;
                    }
                    //Repayment Bank Details record validation
                    String repaymentBank= repaymentBankDetailValidation(loanApplication , messageConfigMap);
                    if(repaymentBank != ''){
                        system.debug('repaymentBank>>>>> '+ repaymentBank);
                        validationMsg += repaymentBank;
                    }
                }
            }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.LAF_GENERATION_CONSENT){
                String checkRaiseQuery   = checkRaiseQuery(loanApplication ,messageConfigMap);
                if(checkRaiseQuery != ''){
                    validationMsg += checkRaiseQuery;
                }
                String  signedDocument= lef_SignedDocumentCheck(loanApplication , messageConfigMap);
                if(signeddocument != ''){
                    validationMsg += signedDocument;
                }
                
                String reTriggerLAF = LAFRetriggerCheck(loanApplication , messageConfigMap);
                system.debug('reTriggerLAF==>'+reTriggerLAF);
                if(reTriggerLAF != ''){
                    validationMsg += reTriggerLAF;
                }
                
                //Addedd by Lakshya on 26th Aug for Bank validations on move to next
                if(loanApplication.LOB__c == 'BL'){
                    if(loanApplication.Bank_Details__r.size() == 0){
                        //validationMsg += '<li>'+BL_ConstantsUtil.REFERENCE_ERROR+'</li>';
                        validationMsg += '<li>'+BL_ConstantsUtil.BANK_ERROR+'</li>';
                    }else if(loanApplication.Bank_Details__r.size() > 0){
                        Set<String> bankTypeSet = new Set<String>{BL_ConstantsUtil.DISBURSEMENT,BL_ConstantsUtil.REPAYMENT};
                            system.debug('loanApplication.Bank_Details__r-> ' + loanApplication.Bank_Details__r);
                        if(!loanApplication.Bank_Details__r.isEmpty()){
                            for(Bank_Details__c obj : loanApplication.Bank_Details__r){
                                if(obj.Record_Type_Name__c != null){
                                    bankTypeSet.remove(obj.Record_Type_Name__c);
                                }
                            }
                        }
                        if(!bankTypeSet.isEmpty()){
                            system.debug('leadObj.bankTypeSet->  ' + bankTypeSet);
                            String bankName = String.valueOf(bankTypeSet).replace('{','').replace('}','');
                            validationMsg += '<li>'+bankName+ ' Bank is Required'+'</li>';
                        }
                    }if(loanApplication.Loan_Applicants__r.size() > 0){ ////Added by Lakshya for BL for Banking analysis validation(perfios)
                        Boolean bankingAnalysisNotAvailable = false;
                        Set<String> applicantsBankingAnalysisNotAvailable = new Set<String>();
                        Set<String> applicantsBankingAnalysisAvailable = new Set<String>();
                        for(Loan_Applicant__c objLoanApplicant : loanApplication.Loan_Applicants__r){
                            if(objLoanApplicant.BL_Income_Considered__c == 'Yes'){
                                if(objLoanApplicant.Perfios_Verification__c == null){
                                    applicantsBankingAnalysisNotAvailable.add(objLoanApplicant.Account_Name__c);
                                }if(objLoanApplicant.Perfios_Verification__c != null){
                                    /*if(objLoanApplicant.Perfios_Verification__r.Status__c != null && objLoanApplicant.Perfios_Verification__r.Status__c != 'Completed'){
applicantsBankingAnalysisAvailable.add(objLoanApplicant.Account_Name__c);
applicantsBankingAnalysisNotAvailable.remove(objLoanApplicant.Account_Name__c);
}*/
                                }
                            }
                        }
                        if(!applicantsBankingAnalysisNotAvailable.isEmpty()){
                            system.debug('leadObj.applicantsBankingAnalysisNotAvailable->  ' + applicantsBankingAnalysisNotAvailable);
                            String appName = String.valueOf(applicantsBankingAnalysisNotAvailable).replace('{','').replace('}','');
                            validationMsg += '<li>'+ BL_ConstantsUtil.BANKING_ANALYSIS_ERROR + appName+'</b> </li>';
                        }
                    }
                }
                //Ended by Lakshya for BL
                
            }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.ASSIGNED_TO_CREDIT){
                if(loanApplication.lob__c == 'BL'){
                    Boolean rcuActvityRequired = false;
                    Boolean rcuWaived = false;
                    if(!loanApplication.Products__r.isEmpty()){
                        for(Product__c product : loanApplication.Products__r){
                            if(product.BL_RCU_Required__c){
                                rcuActvityRequired = true;
                            }
                        }
                    }
                    if(loanApplication.BL_RCU_Waived__c == true){
                        rcuWaived = true;
                    }
                    
                    if(rcuActvityRequired == true && rcuWaived == false){
                        List<Valuation__c> rcuActvity = [select id, name, 
                                                         loan_application__c, RecordType_Name__c, 
                                                         Owner.name, Result__c, Comment__c, Status__c, 
                                                         Is_Revoked__c, BL_Vendor_Activity__c from Valuation__c 
                                                         WHERE loan_application__c =: loanApplication.ID AND (RecordType_Name__c =: BL_ConstantsUtil.RCU)];
                        if(rcuActvity.isEmpty()){
                            validationMsg += '<li>'+BL_ConstantsUtil.RCU_ACTIVITY_MSG+'</li>';
                        }
                    }
                }
            }
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.PD_IN_PROGRESS){
                List<String> container = new List<String>(UB_ConstantsUtil.MY_STRING_LIST);
                String  validationMessage= validationMethod(loanApplication , messageConfigMap, container);
                if(validationMessage != ''){
                    system.debug('validationMessage>>>>> '+ validationMessage);
                    validationMsg += validationMessage;
                }
            }
            /**** Version 1.1- Added by Lakshya on 07-06-2024 (Starts)****/
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.CREDIT_ASSESSMENT){
                Set<Id> applicantIdsSet = new Set<Id>();
                Boolean isCibilVerificationDone = false;
                Boolean checkScoreCardStatus = false;
                Boolean checkScoreCard = false;
                Boolean tvrInitiated = false;
                Boolean retriggerScoreCard = false;
                Set<String> applicantNameSet = new Set<String>();
                for(Loan_Applicant__c applicant : [select id, name, Cibil_Verification__c,ScoreCard_Verification__c, TVR_Initiated__c,Applicant_Type__c, 
                                                   ScoreCard_Verification__r.name,ScoreCard_Verification__r.Status__c, Record_Type_Name__c,
                                                   CFR_Verification__c, Account_Name__c, Loan_Application__r.Is_Retrigger_S1__c
                                                   FROM Loan_Applicant__c  WHERE 
                                                   Loan_Application__c =: loanApplication.Id AND Is_Deleted__c = 'No' ]){
                                                       applicantIdsSet.add(applicant.Id);
                                                       if(applicant.Cibil_Verification__c == NULL) {
                                                           isCibilVerificationDone = true;
                                                       }
                                                       if(applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.Record_Type_Name__c == UB_ConstantsUtil.INDIVIDUAL){
                                                           if(applicant.ScoreCard_Verification__c != null && applicant.ScoreCard_Verification__r.Status__c != UB_ConstantsUtil.COMPLETEDSTATUS ){
                                                               checkScoreCardStatus = true;
                                                           }else if(applicant.ScoreCard_Verification__c == null){
                                                               checkScoreCard = true;
                                                           }else if(applicant.Loan_Application__r.Is_Retrigger_S1__c){
                                                               retriggerScoreCard = true;
                                                           }
                                                       }
                                                       if(applicant.TVR_Initiated__c == false &&  applicant.Applicant_Type__c != UB_ConstantsUtil.GUATANTOR){
                                                           tvrInitiated = true;
                                                       }
                                                       if(applicant.CFR_Verification__c == null){
                                                           applicantNameSet.add(applicant.Account_Name__c);
                                                       }
                                                   }
                List<Vehicle__c> vehicleList = [select id, name, TVR_Initiated__c from Vehicle__c where recordType.Name =: UB_ConstantsUtil.NEW_VEHICLE AND Loan_Application__c =: loanApplication.Id and TVR_Initiated__c = false ];
                if(vehicleList != null && vehicleList.size() > 0){
                    validationMsg += '<li>'+UB_ConstantsUtil.DEALER_TVR_ERROR+'</li>';
                }if(checkScoreCard){
                    validationMsg += '<li>'+UB_ConstantsUtil.SCORECARD_ERROR+'</li>';
                }if(checkScoreCardStatus){
                    validationMsg += '<li>'+UB_ConstantsUtil.SCORECARD_ERROR_1+'</li>';
                }if(retriggerScoreCard){
                    validationMsg += '<li>'+UB_ConstantsUtil.SCORECARD_ERROR_INITIATED+'</li>';
                }if(tvrInitiated){
                    if(loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
                        validationMsg += '<li>'+UB_ConstantsUtil.CUSTOMER_TVR_ERROR+'</li>';
                    }
                }if(!applicantNameSet.isEmpty() && applicantNameSet.size() > 0){
                    validationMsg += '<li>'+messageConfigMap.get('CFR_Mandatory').Message__c+' '+'<b>'+String.valueOf(applicantNameSet).remove('{').remove('}')+'</b>'+'</li>';
                }
                /* Author : Zafaruddin
Date : 25/06/2024
Description : Add Validation to check all Applicant should pass cibil (Commercial/Consumer) Api.
*/
                System.debug(' isCibilVerificationDone   '+isCibilVerificationDone);
                System.debug('applicantIdsSet   '+applicantIdsSet);
                List<Verification__c> cibilVerificationList = [SELECT Id,Name,Status__c FROM Verification__c WHERE RecordTypeId=:UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE AND Status__c != :UB_ConstantsUtil.COMPLETEDSTATUS AND Status__c != :UB_ConstantsUtil.FAILED_STATUS  AND Loan_Applicant__c IN:applicantIdsSet];
                System.debug('cibilVerificationList   '+cibilVerificationList);
                if(!cibilVerificationList.isEmpty() || isCibilVerificationDone) {
                    validationMsg += '<li>'+UB_ConstantsUtil.CIBIL_Non_INDIVIDUAL_ERROR+'</li>';
                } 
                
                //end here
            }
            /**** Version 1.1- Added by Lakshya on 07-06-2024 (Ends)****/
            system.debug('stage-> ' + loanApplication.Loan_Application_Stage__c);
            if(loanApplication.Loan_Application_Stage__c == UB_ConstantsUtil.RECOMMENDED_FOR_APPROVAL){
                User usrObj = [SELECT Id, Userrole.Name, Userrole.DeveloperName FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
                system.debug('userRole-> ' + usrObj.Userrole.Name);
                String message = '';
                List<Deviation_Sanction_Condition__c> deviationConditionList = [select id, Loan_Application__c, Decision__c, Authority_Role__c, Approving_Authority__c 
                                                                                FROM Deviation_Sanction_Condition__c WHERE Loan_Application__c =: loanApplication.Id 
                                                                                AND Decision__c NOT IN ('Approved') AND Type__c IN  ('Deviation')  // (Decision__c != 'Approved')
                                                                               ];
                if(deviationConditionList != null && deviationConditionList.size() > 0){
                    //message = 'Please make decisions on the deviations to proceed further!!';
                    Boolean isAnyOpenDeviation = false;
                    Boolean isAnyCurrentUserOpenDeviation = false;
                    Boolean isAnyRejectedDeviation = false;
                    for(Deviation_Sanction_Condition__c obj : deviationConditionList){
                        if(String.isNotBlank(obj.Decision__c)){
                            if(obj.Decision__c != UB_ConstantsUtil.REJECTED_DEVIATION){
                                isAnyOpenDeviation = true;
                                if(String.isNotBlank(obj.Authority_Role__c)){
                                    if(obj.Authority_Role__c == usrObj.Userrole.Name){
                                        isAnyCurrentUserOpenDeviation = true;
                                    }
                                }
                            }else{
                                isAnyRejectedDeviation = true;
                            }
                        }
                    }
                    if(String.isNotBlank(buttonLabel) && buttonLabel == 'Recommend'){
                        if(isAnyCurrentUserOpenDeviation){
                            system.debug('validationMessage>>>>> '+ UB_ConstantsUtil.DEVIATION_ERROR);
                            validationMsg += '<li>'+UB_ConstantsUtil.DEVIATION_ERROR+'</li>';
                        }
                    }else{
                        if(isAnyOpenDeviation){
                            validationMsg += '<li>'+messageConfigMap.get('Open_Deviation').Message__c+'</li>';
                        }
                        if(isAnyRejectedDeviation){
                            validationMsg += '<li>'+messageConfigMap.get('Rejected_Deviation').Message__c+'</li>';
                        }
                    }
                }
                if(String.isNotBlank(buttonLabel) && buttonLabel != 'Recommend'){
                    /**** Version 1.2- Added by Mohit on 07-06-2024 (Starts)****/
                    if(String.isNotBlank(usrObj.Userrole.DeveloperName)){
                        validationMsg += UB_LoanApplicationApprovalValidations.approvingAuthorityThreshold(usrObj, loanApplication, messageConfigMap);
                    } 
                    validationMsg += UB_LoanApplicationApprovalValidations.integrationsActivityValidity(loanApplication.Id, messageConfigMap);
                    /**** Version 1.2- Added by Mohit on 07-06-2024 (Ends)****/
                }
            }
            //Added By Umair for BL Underwriting FI Process on 23-08-24
            if(loanApplication.LOB__c == UB_ConstantsUtil.LOB_BL && loanApplication.Record_Type_Name__c == 'Underwriting Initiated'){
                if(loanApplication.Id != Null && !loanApplicantList.isEmpty()){
                    if(loanApplication.Record_Type_Name__c == 'Underwriting Initiated'){
                        validationMsg += BL_LoanApplicationMoveToNextController.FIProcessCheck(loanApplication.Id, loanApplicantList);
                    }
                    validationMsg += BL_LoanApplicationMoveToNextController.isCommunicationCheck(loanApplication.Id, loanApplicantList);
                }
                system.debug('FI Process validationMsg '+validationMsg);
            }
        }catch (Exception e) {
            System.debug('**Check validation error Line   == '+ e.getLineNumber());
            System.debug('**Check validation error Line error e   == '+ e);
        }
        return validationMsg;
    }
    
    /**** Added by Chandan on 22-07-2024****/
    public static String checkRCUDocuments(Loan_Application__c loanApplication, List<Loan_Applicant__c> loanApplicantList) {
        Map<String, Messages_Config__mdt> messageConfigRCUDocMap = UB_CommonUtil.getMessageRecord('RCU');
        
        Id userId = UserInfo.getUserId();
        String validationMessage;
        User userRecord = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        
        String profileName = userRecord.Profile.Name;
        Set<Id> loanApplicantIdSet = new Set<Id>();
        Boolean isRCUActivityClosed = isRCUClosed(loanApplication);
        system.debug('isRCUActivityClosed==>'+isRCUActivityClosed);
        // Check if the user has the required profile
        if ((profileName == 'Credit' || profileName == 'System Administrator') && isRCUActivityClosed) { //
            // Get the Id of all the Loan Applicants
            for (Loan_Applicant__c applicant : loanApplicantList) {
                loanApplicantIdSet.add(applicant.Id);
            }
            
            // Get all the documents which are not RCU Verified
            List<Document__c> documentList = [
                SELECT Id, Name, Status__c 
                FROM Document__c 
                WHERE (Loan_Application__c = :loanApplication.Id OR Loan_Applicant__c IN :loanApplicantIdSet) 
                AND Status__c != 'RCU Acknowledged' AND Document_Type__c != 'Sanction Condition'
            ];
            system.debug('documentList===>'+documentList);
            
            // Add validation message if there are documents not verified
            if (!documentList.isEmpty()) {
                validationMessage = '<li>' + messageConfigRCUDocMap.get('RCU_Documents').Message__c + '</li>';
            }
        }
        
        return validationMessage;
    }
    //method to check whether RCU Activity is closed or not
    public static Boolean isRCUClosed(Loan_Application__c loanApplication) {
        Boolean isClosed = false;
        
        // Fetch the latest RCU Record related to the loan application, if any
        List<Valuation__c> RCURecords = [
            SELECT Id, Name, Loan_Application__c, Status__c, Result__c, Vendor_Status__c 
            FROM Valuation__c 
            WHERE Loan_Application__c = :loanApplication.Id AND RecordType_Name__c = 'RCU'
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        system.debug('RCURecords==>'+RCURecords);
        // Check if the query returned any records
        if (!RCURecords.isEmpty()) {
            Valuation__c RCURecord = RCURecords[0];
            system.debug('RCURecord==>'+RCURecord);
            system.debug('RCURecord.Status__c==>'+RCURecord.Status__c);
            
            // Evaluate conditions based on the fetched RCU record
            if (RCURecord.Status__c == 'Screened' && RCURecord.Result__c != null) {
                isClosed = true;
            } else if (RCURecord.Status__c == 'Sampled' && RCURecord.Result__c != null && RCURecord.Vendor_Status__c == 'Completed') {
                isClosed = true;
            }
        }
        
        return isClosed;
    }
    
    
    
    
    /**
* @description Approval process
* @return static
*/
    @AuraEnabled
    public static void approavalProcessMethod(String loanApplicationId , Id nextApproaverId , Id submitterId, String approvalProcessName){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(loanApplicationId);
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(submitterId); 
        Id[] nextApprId = new Id[] {nextApproaverId};
            req1.setNextApproverIds(nextApprId);
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId(approvalProcessName);
        //req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        system.debug('req1-> ' + req1);
        system.debug('result-> ' + result);
    }
    
    /**
* @description check check required document validations
* @return static
*/
    private static String checkDocumentValidations(String loanApplicationId ,Map<String,Messages_Config__mdt> messageConfigMap){
        List<Document__c>  documentList = new UB_DocumentsSelector().selectByLoanApplicationIdAndIsRequired(new Set<Id>{loanApplicationId}); 
        
        String validationMsg ='';
        if(documentList != null && documentList.size() > 0){
            validationMsg = '<li>'+messageConfigMap.get('RequiredDocuments').Message__c+'</li>';
        }
        return validationMsg;
        
    }
    /**
* @description check check KYC relatedvValidation
* @return static
*/
    private static String check_KYC_Validation(List<Loan_Applicant__c>  loanAppList ,Map<String,Messages_Config__mdt> messageConfigMap){
        
        String validationMsg ='';
        String  panVerification;
        String  dedupeVerification ;
        String  aadhaarVerification;
        Boolean pendingConsent = false;
        String LOB = '';
        for(Loan_Applicant__c applicant : loanAppList){
            LOB = applicant.Loan_Application__r.LOB__c;
            String applicantName = applicant.Account_Name__c;
            //if(applicant.Constitution__c== UB_ConstantsUtil.INDIVIDUAL || applicant.Constitution__c == UB_ConstantsUtil.SOLE_PROPRIETORSHIP){
            if(!applicant.Consent_Received__c){
                pendingConsent = true;
            }
            if(applicant.PAN_Verification__c == null){
                panVerification =  panVerification != null ?  panVerification += ', '+applicantName : applicantName;
                
            }
            if(applicant.Dedupe_Verification__c == null){
                dedupeVerification =  dedupeVerification != null ?  dedupeVerification += ', '+applicantName : applicantName;                  
            }
            if(applicant.Aadhaar_Verification__c == null && applicant.Aadhaar_Verification__r.Aadhaar_Number__c != null){
                aadhaarVerification =  aadhaarVerification != null ?  aadhaarVerification += ', '+applicantName : applicantName;                     
            }
            
            // }
            
        } 
        if(pendingConsent){
            validationMsg += '<li>'+messageConfigMap.get('Consent_Mandatory').Message__c+'</li>';
        }
        if(panVerification != null){
            validationMsg += '<li>'+messageConfigMap.get('PAN_Required').Message__c+ ' <b> '+panVerification+'</b></li>';
        }
        if(dedupeVerification != null){
            validationMsg += '<li>'+messageConfigMap.get('DedupeRequired').Message__c+ '<b> '+dedupeVerification+'</b></li>';
        }
        if(aadhaarVerification != null){
            validationMsg += '<li>'+messageConfigMap.get('Aadhaar_Required').Message__c+ '<b> '+aadhaarVerification+'</b></li>';
            
        }
        
        //Added By Mohit on 19-09-2024 for BL - <Validation when identity/address proof is Aadhaar for the applicants>
        if(String.isNotBlank(LOB) && LOB == UB_ConstantsUtil.LOB_BL){
            if(!loanAppList.isEmpty() && loanAppList.size() > 0){
                validationMsg += BL_LoanApplicationMoveToNextController.aadhaarProofValidation(loanAppList, messageConfigMap);
            }
        }
        return validationMsg;
        
    }
    /**
* @description check check KYC relatedvValidation
* @return static
*/
    private static String check_KYC_ValidationCible (List<Loan_Applicant__c>  loanAppList ,Map<String,Messages_Config__mdt> messageConfigMap){
        System.debug('loanAppList>>>>>>  '+loanAppList);
        String validationMsg ='';
        String  cibilVerification;
        for(Loan_Applicant__c applicant : loanAppList){
            String applicantName = applicant.Account_Name__c;
            System.debug('** applicantName>>>> '+applicantName);
            if(applicant.Constitution__c== UB_ConstantsUtil.INDIVIDUAL || applicant.Constitution__c == UB_ConstantsUtil.SOLE_PROPRIETORSHIP){
                System.debug('** (applicant.Cibil_Verification__c >>>'+ applicant.Cibil_Verification__c);
                if(applicant.Cibil_Verification__c == null ){
                    cibilVerification =  cibilVerification != null ?  cibilVerification += ', '+applicantName : applicantName; 
                    
                }               
                if(applicant.Cibil_Verification__c !=null && applicant.Cibil_Verification__r.Status__c != UB_ConstantsUtil.COMPLETEDSTATUS) {
                    cibilVerification =  cibilVerification != null ?  cibilVerification += ', '+applicantName : applicantName;
                    
                }
            }
            
        } 
        
        if(cibilVerification != null){
            validationMsg += '<li>'+messageConfigMap.get('Cibli_Required').Message__c+'<b> '+cibilVerification+ '</b></li>';
        }
        
        System.debug('** nvalidationMsg>>>> '+validationMsg);
        return validationMsg;
        
    }
    /**
* @description check check secondary applicant created or not
* @return static
*/
    private static String secondaryApplicantCheck(List<Loan_Applicant__c>  loanAppList ,Map<String,Messages_Config__mdt> messageConfigMap,String loanApplicationStage){
        String validationMsg ='';
        Boolean isSecondaryApplicant =  false;
        Boolean isPrimaryApplicant = false;
        Boolean isGuarantorApp = false;
        Boolean isNonIndividualApp = false;
        system.debug('loanAppList>>>>111 ' + loanAppList);
        try{
            for(Loan_Applicant__c applicant : loanAppList){
                system.debug('applicant-> ' + BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE );
                
                system.debug('if isPrimaryApplicant>>' + applicant.Loan_Application__r.LOB__c +' ' +applicant.Applicant_Type__c +' ' +applicant.RecordTypeId );
                if(applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE){
                    isPrimaryApplicant = true;
                    isNonIndividualApp = true;
                    system.debug('hello 1 ' + isPrimaryApplicant +' ' +isNonIndividualApp );
                }else if(applicant.Loan_Application__r.LOB__c == 'BL' && applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.RecordTypeId == BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE){
                    isNonIndividualApp = true;
                    isPrimaryApplicant = true;            
                    system.debug('hello 2' + applicant.Loan_Application__r.LOB__c +' ' +applicant.Applicant_Type__c +' ' +applicant.RecordTypeId );
                }else if(applicant.Loan_Application__r.LOB__c == 'BL' && applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.RecordTypeId != BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE){
                    isPrimaryApplicant = true; 
                    isNonIndividualApp = false;
                    isGuarantorApp = true;
                }else if(applicant.Applicant_Type__c == UB_ConstantsUtil.GUATANTOR){
                    isGuarantorApp = true; 
                    system.debug('hello 3');
                } else if( applicant.Applicant_Type__c == UB_ConstantsUtil.CO_APPLICANT){
                    System.debug('** applicant.Applicant_Type__c  '+applicant.Applicant_Type__c);
                    system.debug('hello 4');
                    isSecondaryApplicant = true;
                }
                /* if(loanApplicationStage == UB_ConstantsUtil.DDE && applicant.Applicant_Type__c !=UB_ConstantsUtil.APPLICANT){
isSecondaryApplicant = false;
}*/
            }
            if(loanApplicationStage == UB_ConstantsUtil.KYC_VALIDATION || loanApplicationStage == UB_ConstantsUtil.DDE /*&& isPrimaryApplicant == true && isNonIndividualApp == true && isGuarantorApp == false*/){
                if(isPrimaryApplicant == true && isNonIndividualApp == true && isGuarantorApp == false){
                    validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant').Message__c+'</li>';
                }else if(isNonIndividualApp == false && isSecondaryApplicant == false){
                    if((loanApplicationStage == UB_ConstantsUtil.DDE || loanApplicationStage == UB_ConstantsUtil.KYC_VALIDATION) && isGuarantorApp == true){
                        validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant_DDE').Message__c+'</li>';
                    }else{
                        validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant').Message__c+'</li>';
                    }
                }
            }
            /*if(loanApplicationStage == UB_ConstantsUtil.DDE && isNonIndividualApp == false && isSecondaryApplicant == false){
                if(loanApplicationStage == UB_ConstantsUtil.DDE && isGuarantorApp == true){
                    validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant_DDE').Message__c+'</li>';
                }else{
                    validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant').Message__c+'</li>';
                }
            } */
        }catch(Exception ex){
            System.debug('ex-> '+ ex.getLineNumber());
            System.debug('ex-> '+ ex);
        }
        
        system.debug('validationMsg-> ' + validationMsg);
        return validationMsg;
        
    }
    /**
* @description check vehicle  added or not
* @return static
*/
    private static String vehicleCheck( List<Product__c> productList , Map<String,Messages_Config__mdt> messageConfigMap,Loan_Application__c loanApplication){
        String validationMsg ='';
        String  vehicles;
        Set<Id> productId = new Set<Id>();
        Set<String> vehilceModelName = new Set<String>();
        set<String> creditAssessmentValueSet = new  set<String>();
        if(!productList.isEmpty()){
            for(Product__c p:productList ){
                productId.add(p.id);
            }
            
            
            //Set<Id> productIds = (new Map<Id,SObject>(productList)).keySet();
            
            List<Product__c>  productDetailList = new UB_ProductsSelector().selectById(productId);
            system.debug('productDetailList > ' + productDetailList);
            
            //List<String> creditAssessmentValue;
            
            for(Product__c pro :  productDetailList){
                
                system.debug('pro.Vehicles__r.size() > ' + pro.Vehicles__r.size());
                system.debug('pro.Vehicles__r > ' + pro.Vehicles__r);
                if(pro.Vehicles__r.size() == 0){
                    vehicles =  vehicles != null ?  vehicles += ', '+pro.Name : pro.Name;  
                }
                
                system.debug('vehicles > ' + vehicles);
                system.debug('pro.Product__r> ' + pro.Product__r);
                if(pro.Product__r.Credit_Assessment_Method__c != null){
                    List<String> assements = pro.Product__r.Credit_Assessment_Method__c.split(';');
                    for (String assessment : assements) {
                        if(assessment ==UB_ConstantsUtil.FFR ||  assessment ==UB_ConstantsUtil.FINANCIALS)
                            creditAssessmentValueSet.add(assessment);
                    }
                    
                }
                system.debug('creditAssessmentValueSet > ' + creditAssessmentValueSet);
            }
            
        }
        Set<String> assessmentTypes = new Set<String>();
        Set<String> fassessmentRecordTypeName = new Set<String>();
        List<Financial_Assessment__c>  fAssessmentList = [SELECT Id,RecordType.Name FROM  Financial_Assessment__c WHERE Loan_Application__c =:loanApplication.Id];
        system.debug('fAssessmentList> ' + fAssessmentList);
        for(Financial_Assessment__c fAssessment : fAssessmentList){
            system.debug('fAssessment record type name> ' + fAssessment.RecordType.Name);
            if(fAssessment.RecordType.Name == UB_ConstantsUtil.FFR || fAssessment.RecordType.Name == UB_ConstantsUtil.FINANCIALS){
                fassessmentRecordTypeName.add(fAssessment.RecordType.Name);
            }
        }
        system.debug('fassessmentRecordTypeName> ' + fassessmentRecordTypeName);
        
        Set<String> differenceSet = new Set<String>();
        differenceSet.addAll(creditAssessmentValueSet);
        differenceSet.removeAll(fassessmentRecordTypeName);
        system.debug('<<<<>>>>> ' + differenceSet);
        if(!differenceSet.isEmpty()){
            validationMsg = '<li>' +'Please create Assessment for ' +'<b> '+ String.join(differenceSet, ', ')+' </b></li>';
        }
        system.debug('validationMsg>> ' + validationMsg);
        //Added By Mohit on 01-08-2024 for BL - <Vehicle validation is not required for BL>
        if(loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL && vehicles !=null){
            validationMsg += '<li>'+messageConfigMap.get('Vehicle_Required').Message__c+'<b> '+vehicles+ '</b></li>';
        }
        return validationMsg;
        
    } 
    /**
* @description check digned document uploded or not
* @return static
*/
    private static String  lef_SignedDocumentCheck(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg ='';
        Boolean isDocumentSigned = false;
        for(Document__c doc :loanApplication.Documents__r){
            if(doc.Document_Type__c == UB_ConstantsUtil.LAF_FORM && doc.Document_Sub_Type__c == UB_ConstantsUtil.LAF_FORM_SIGNED && doc.Status__c == UB_ConstantsUtil.UPLOADED ){
                isDocumentSigned = true;
            }
        }
        if(isDocumentSigned == false){
            validationMsg = '<li>'+messageConfigMap.get('RequiredSignedDocument').Message__c+'</li>';
        }
        return validationMsg;
        
    }
    /**
* @description create new document on document stage momemet
* @return static
*/
    public static String createDocument(Loan_Application__c loanApplication) {
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String,List<Loan_Applicant__c>> applicantWithIds = new Map<String,List<Loan_Applicant__c>>();
            List<Loan_Applicant__c>  loanApplicantList = new UB_LoanApplicantsSelector().selectByIdWithLoanApplication(new Set<Id>{loanApplication.Id});
            for(Loan_Applicant__c applicant :loanApplicantList ){
                if(applicant.Applicant_Type__c != null){
                    
                    if(!applicantWithIds.containsKey(applicant.Applicant_Type__c)){
                        applicantWithIds.put(applicant.Applicant_Type__c, new List<Loan_Applicant__c>{applicant});
                        
                    }else{
                        applicantWithIds.get(applicant.Applicant_Type__c).add(applicant);
                    }
                    
                }
            }
            String productSchemes;
            if(loanApplication.Products__r !=null && loanApplication.Products__r.size() >0  && loanApplication.Products__r[0].Product_Schemes__c !=null ){
                productSchemes = loanApplication.Products__r[0].Product_Schemes__c;
            }
            System.debug('** --->productSchemes--> '+productSchemes);
            
            List<Document_Checklist__c>  documentChecklists = new UB_DocumentChecklistsSelector().selectByStage(loanApplication.Loan_Application_Stage__c); 
            List<Document__c> documentList = new List<Document__c>();
            for(Document_Checklist__c doc : documentChecklists ){
                if(doc.Is_Active__c == true && applicantWithIds.containsKey(doc.Applicable_For__c) &&  doc.LOB__c.contains(loanApplication.LOB__c)  && doc.Applicable_For__c != 'Guarantor' && doc.Applicable_For__c != 'Co-Applicant'){
                    for(Loan_Applicant__c appId : applicantWithIds.get(doc.Applicable_For__c)){
                        if(doc.Constituation_of_Applicant__c !=null && doc.Constituation_of_Applicant__c.contains(appId.Constitution__c) && productSchemes !=null /*&& doc.Product_Parameters__c!=null && doc.Product_Parameters__c.contains(productSchemes)*/ ){
                            Document__c documentObj = new Document__c();
                            documentObj.Document_Checklist__c = doc.Id;
                            documentObj.Loan_Applicant__c = appId.Id;
                            documentObj.Loan_Application__c = loanApplication.Id;
                            documentObj.Stage__c = doc.Stage__c;
                            documentObj.Is_Required__c = doc.Is_Required__c;
                            documentObj.Document_Type__c = doc.Document_Type__c;
                            //documentObj.Document_Sub_Type__c = doc.Document_Subtype__c;
                            documentList.add(documentObj);
                        }
                    }
                }
                
            }
            if(!documentList.isEmpty()){
                System.debug('** documentList '+ documentList);
                insert documentList;
                
            }
            return 'SUCCESS';
            
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            return 'ERROR: '+e.getMessage();
        }
        
    }
    /**
* @description check raise query completed or not
* @return static
*/
    public static String checkRaiseQuery(Loan_Application__c loanApplicationList , Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg ='';
        List<Task>  taskList = new UB_TasksSelector().selectByWhatId(new Set<Id>{loanApplicationList.Id}); 
        for(Task taskObj : taskList){
            if(taskObj.Status != 'Completed'){
                validationMsg = '<li>'+messageConfigMap.get('Complete_Raise_Query').Message__c+'</li>';
            }
        }
        return validationMsg;
    }
    /**
* @description not activity last 30 days
* @return static
*/
    public static Boolean getActivityHistory(Loan_Application__c loanApplication){
        Boolean isActivity  = true;
        List<Activity_History__c>  activityHistoryList = new UB_ActivityHistoriesSelector().selectByLoanApplicationId(new Set<Id>{loanApplication.Id});         
        if(activityHistoryList !=null &&activityHistoryList.size() > 0){
            Date activityHistotyDate = activityHistoryList[0].CreatedDate.date();
            Date currentDate = date.today().addDays(-30);
            System.debug('====loanApplication d  '+activityHistotyDate);
            System.debug('====currentDate  '+currentDate);
            if(activityHistotyDate < currentDate){
                isActivity = false;
            }
        }
        return isActivity;
        
    }
    /**
* @description check digned document uploded or not
* @return static
*/
    private static String  validationMethod(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap, List<String> validationFor){
        system.debug('validationFor >' + validationFor[0] + ' >> ' + validationFor[1]);
        system.debug('loanApplication.Products__r>>' + loanApplication.Products__r[0].Product_Category__c);
        system.debug('loanApplication.Valuation__r>>>' + loanApplication.Valuation__r);
        String validationMsg ='';
        Set<String>TempValue = new Set<String>();
        Set<String> differenceSet = new Set<String>();
        List<Collateral__c> collList = new List<Collateral__c>();
        if(loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
            differenceSet.addAll(UB_ConstantsUtil.ACTIVITY_RECORDTYPE_NAME_LIST);
            collList = [SELECT Id,Loan_Application__c from Collateral__c where Loan_Application__c = :loanApplication.Id] ;
            system.debug('collList>>>' + collList);
            if(collList != null && collList.size() > 0){
                differenceSet.addAll(UB_ConstantsUtil.ACTIVITY_RECORDTYPE_NAME_LIST2);
            }
            system.debug('differenceSet>>>>>>>>>11' + differenceSet);
        }else{
            differenceSet.addAll(BL_ConstantsUtil.ACTIVITY_RECORDTYPE_NAME_LIST);
        }
        system.debug('differenceSet>>>>>>>>>' + differenceSet);
        if(validationFor.contains('CREATE_ACTIVITY')){
            for(Valuation__c activity :loanApplication.Valuation__r){
                TempValue.add(activity.RecordType_Name__c);
            }
            system.debug('TempValue>>>>>>>>>' + TempValue);
            if(loanApplication.Products__r.size() > 0 && !loanApplication.Products__r.isEmpty()){
                for(Product__c product : loanApplication.Products__r){
                    if(product.Product_Category__c.contains(UB_ConstantsUtil.USED)){
                        differenceSet.add(UB_ConstantsUtil.VEHICLE_VALUATION);
                    }
                }
            }
            system.debug('differenceSet>>>>>>>>>' + differenceSet);
            differenceSet.removeAll(TempValue);
            system.debug('UdifferenceSet ' + differenceSet);
            if(!differenceSet.isEmpty()){
                //validationMsg = '<li>' +'Please create Activity for ' + String.join(differenceSet, ', ')+'</li>';
            }
            system.debug('validationMsg>> ' + validationMsg);
        }
        if(validationFor.contains('PD_DOCUMENT')){
            Boolean isPdDocument = false;
            for(Document__c doc :loanApplication.Documents__r){
                system.debug('doc>> ' + doc);
                system.debug('doc.Document_Type__c==>'+doc.Document_Type__c);
                system.debug('doc.Status__c=>'+doc.Status__c);
                if(doc.Document_Type__c == UB_ConstantsUtil.PD && ((doc.Status__c == UB_ConstantsUtil.UPLOADED|| doc.Status__c =='RCU Acknowledged'))){
                    isPdDocument = true;
                }
            }
            system.debug('isPdDocument==>'+isPdDocument);
            if(isPdDocument == false && loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
                validationMsg = '<li>'+messageConfigMap.get('RequiredPD_Document').Message__c+'</li>' + validationMsg ;
            }
        }  
        
        system.debug('validationMsg > ' + validationMsg);
        return validationMsg;
        
    }
    //CPA ACKNOWLEDGE Validation--------
    private static String  cpa_Acknowlwdge(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        system.debug('inside cpa_Acknowlwdge');
        String validationMsg ='';
        Map<String,String> mapApplicantIdWithActive = new Map<String,String>();
        // Initialize count variables
        Integer VERIFIED_ERROR_COUNT = 0;
        Integer CPA_Acknowledge_count = 0;
        
        for(Loan_Applicant__c loanApplicant : loanApplication.Loan_Applicants__r){
            mapApplicantIdWithActive.put(loanApplicant.Id,loanApplicant.Is_Deleted__c);
        }
        for(Document__c cpaDoc :loanApplication.Documents__r){
            system.debug('cpaDoc>> ' + cpaDoc);
            if(mapApplicantIdWithActive.containsKey(cpaDoc.Loan_Applicant__c)){
                if(mapApplicantIdWithActive.get(cpaDoc.Loan_Applicant__c) == 'No'){
                    if(loanApplication.LOB__c != UB_ConstantsUtil.LOB_BL){
                        if( cpaDoc.Status__c != UB_ConstantsUtil.CPA_ACKNOWLEDGE || cpaDoc.Acknowledge_Status__c != UB_ConstantsUtil.ACKNOWLEDGE_STATUS){
                            if(cpaDoc.Acknowledge_Status__c != UB_ConstantsUtil.ACKNOWLEDGE_STATUS && VERIFIED_ERROR_COUNT == 0){
                                validationMsg = '<li>'+UB_ConstantsUtil.VERIFIED_ERROR+'</li>';
                                VERIFIED_ERROR_COUNT+=1;
                            }if(cpaDoc.Status__c != UB_ConstantsUtil.CPA_ACKNOWLEDGE && CPA_Acknowledge_count == 0){
                                validationMsg += '<li>'+messageConfigMap.get('CPA_Acknowledge').Message__c+'</li>';
                                CPA_Acknowledge_count+=1;
                            }
                        }
                    }else if(loanApplication.LOB__c == UB_ConstantsUtil.LOB_BL){
                        if( cpaDoc.Status__c != UB_ConstantsUtil.CPA_ACKNOWLEDGE || cpaDoc.Acknowledge_Status__c != UB_ConstantsUtil.ACKNOWLEDGE_STATUS){
                            validationMsg = '<li>'+BL_ConstantsUtil.VERIFIED_ERROR+'</li>';
                        }
                    }
                    
                }
            }
        }
        return validationMsg;
    }
    //ROI Validation---------------mansur alam
    public static String check_ROI_Validation(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        system.debug('ROI>>>> ' + loanApplication.ROI__c);
        String validationMsg ='';
        if(loanApplication.ROI__c == null){
            validationMsg += '<li>'+messageConfigMap.get('ROI_Validation_Msg').Message__c+'</li>';
        }
        return validationMsg;
    }
    //Reference Trade/Member validation---------------mansur alam
    public static String referenceMembers(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        system.debug('loanApplication.Loan_Applicants__r>>>>11 ' + loanApplication.Loan_Applicants__r);
        //system.debug('loanApplication.Loan_Applicants__r>>>> 22' + loanApplication.Reference_Members__r);
        UB_Reference_MemberSelector refeSelector = new UB_Reference_MemberSelector();
        String validationMsg ='';
        map<Id,String> nonIndApplicant = new map<Id,String> ();
        Set<String> allNonIndApplicantName = new Set<String>();
        Set<String> applicantNameList = new Set<String>();
        Set<Id> nonIndApplicantId = new Set<Id>();
        Set<String> differenceSet = new Set<String>();
        
        //for trade reference
        List<Reference_Member__c> tradeMemberList = refeSelector.selectByLoanApplicationId(new Set<Id>{loanApplication.Id},UB_ConstantsUtil.TRADE_REFERENCE_RECORD_TYPE);
        if(tradeMemberList.isEmpty()){
            validationMsg += '<li>'+messageConfigMap.get('Trade_Member_validation_Msg').Message__c+'</li>';
        }
        //for reference member
        for(Loan_Applicant__c applicants : loanApplication.Loan_Applicants__r){
            system.debug('applicants1111>>> '+ applicants);
            if(applicants.Record_Type_Name__c  == UB_ConstantsUtil.NON_INDIVIDUAL){
                allNonIndApplicantName.add(applicants.Name);
                nonIndApplicantId.add(applicants.Id);
            }
        }
        system.debug('nonIndApplicantId>>> '+ nonIndApplicantId);
        system.debug('allNonIndApplicantName>>> '+ allNonIndApplicantName);
        if(!nonIndApplicantId.isEmpty() && nonIndApplicantId.size() > 0){
            
            for(Reference_Member__c referenceMemberRecord : refeSelector.selectByLoanApplicantId(nonIndApplicantId)){
                system.debug('referenceMemberRecord>>> '+ referenceMemberRecord);
                if(referenceMemberRecord.RecordType.Name =='Members'){
                    applicantNameList.add(referenceMemberRecord.Loan_Applicant__r.Name);
                    system.debug('referenceMemberRecord.Loan_Applicant__r.Name>>> '+ referenceMemberRecord.Loan_Applicant__r.Name);
                }
            }
            system.debug('applicantNameList>>> '+ applicantNameList);
            system.debug('allNonIndApplicantName>>> '+ allNonIndApplicantName);
            
            differenceSet.addAll(allNonIndApplicantName);
            differenceSet.removeAll(applicantNameList);
            system.debug('<<<<>>>>> ' + differenceSet);
            if(!differenceSet.isEmpty()){
                validationMsg +=  '<li>' +'Please create Member Reference Record for ' +'<b> '+ String.join(differenceSet, ', ')+' </b></li>';
            }
            
        }
        
        return validationMsg;
    }
    
    //Repayment bank detial validation---------------mansur alam
    public static String repaymentBankDetailValidation(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        system.debug('loanApplication.Id ' + loanApplication.Id);
        String validationMsg ='';
        UB_BankSelector bankSelector = new UB_BankSelector();
        List <Bank_Details__c> bank  = bankSelector.selectByLoanApplicationId(new Set<Id>{loanApplication.Id});
        system.debug('bank ' + bank);
        if(bank.isEmpty() && bank.size() == 0 ){
            validationMsg += '<li>'+messageConfigMap.get('Repayment_Bank_validation_Msg').Message__c+'</li>';
        }
        return validationMsg;
    }
    public static String LAFRetriggerCheck(Loan_Application__c loanApplication, Map<String, Messages_Config__mdt> messageConfigMap) {
        System.debug('loanApplication.Id inside LAF ' + loanApplication.Id);
        String validationMsg = '';
        system.debug('loanApplication.isSendBackToDDE__c==>'+loanApplication.isSendBackToDDE__c);
        if (loanApplication.isSendBackToDDE__c) {
            Messages_Config__mdt config = messageConfigMap.get('ReTrigger_LAF');
            system.debug('config===>'+config);
            if (config != null && config.Message__c != null) {
                validationMsg += '<li>' + config.Message__c + '</li>';
            } else {
                System.debug('ReTrigger_LAF configuration not found or message is null');
            }
        }
        
        return validationMsg;
    }
    //Added by mansur--01-09-2024
    private static String viabilityAndHireValidation(List<Product__c> productList,String lafId , Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg = '';
        Set<String> vehicleIds = new Set<String>();
        Set<Id> productId = new Set<Id>();
        Map<String,SET<String>> vehicleNameCreditAssMethodMap = new Map<String,Set<String>>();
        system.debug('productList><<' + productList);
        if(productList.size() > 0 && productList != null){
            for(Product__c p:productList ){
                productId.add(p.id);
            }
        }
        List<Product__c>  productDetailList = new UB_ProductsSelector().selectById(productId);
        for(Product__c pro : productDetailList){
            system.debug('pro111' + pro);
            for(Vehicle__c vcl : pro.Vehicles__r){
                system.debug('vcl111' + vcl);
                vehicleIds.add(vcl.Id);
            }
        }
        
        system.debug('vehicleIds><<' + vehicleIds);
        if(vehicleIds != null && vehicleIds.size() > 0){
            for(Vehicle__c vehiclRecord : [SELECT Id,Name,Product__r.Name,Product__r.Product__r.Credit_Assessment_Method__c from Vehicle__c WHERE Id IN : vehicleIds]){
                system.debug('vehiclRecord>>>>> ' +vehiclRecord);
                If(vehicleNameCreditAssMethodMap.containsKey(vehiclRecord.Name + vehiclRecord.Product__r.Name) == false){
                    vehicleNameCreditAssMethodMap.put(vehiclRecord.Name + vehiclRecord.Product__r.Name, new Set<String>());
                }
                
                system.debug('vehicleNameCreditAssMethodMap1>> ' +vehicleNameCreditAssMethodMap);
                if(vehicleNameCreditAssMethodMap.containsKey(vehiclRecord.Name + vehiclRecord.Product__r.Name) == true){
                    List<String> creditAssements = vehiclRecord.Product__r.Product__r.Credit_Assessment_Method__c.split(';');
                    for (String assessment : creditAssements) {
                        if(assessment.contains(UB_ConstantsUtil.VIABILITY) ||  assessment.contains(UB_ConstantsUtil.HIRE_VS_BUY)){
                            Set<String> dummySet = vehicleNameCreditAssMethodMap.get(vehiclRecord.Name + vehiclRecord.Product__r.Name);
                            system.debug('dummySet1> ' +dummySet);
                            dummySet.add(assessment);
                            system.debug('dummySet2> '+ dummySet);
                            vehicleNameCreditAssMethodMap.put(vehiclRecord.Name + vehiclRecord.Product__r.Name,dummySet);
                        }
                    }                                      
                }
            }
        }
        system.debug('vehicleNameCreditAssMethodMap1>> ' +vehicleNameCreditAssMethodMap);
        system.debug('vehicleList>>>>1 ' + vehicleIds);
        List<Financial_Assessment__c>  fAssessmentList = [SELECT Id,RecordType.Name,Vehicle__r.Name,Vehicle__r.Product__r.Name FROM  Financial_Assessment__c WHERE vehicle__c IN :vehicleIds];
        system.debug('fAssessmentList> ' + fAssessmentList);
        for(Financial_Assessment__c fAssessment : fAssessmentList){
            system.debug('fAssessment record type name> ' + fAssessment.RecordType.Name);
            if(fAssessment.RecordType.Name.contains(UB_ConstantsUtil.HIRE)){
                String Hire_vs_Buy = 'Hire vs Buy';
                vehicleNameCreditAssMethodMap.get(fAssessment.Vehicle__r.Name + fAssessment.Vehicle__r.Product__r.Name).remove(Hire_vs_Buy);
            }
            if(fAssessment.RecordType.Name.contains(UB_ConstantsUtil.VIABILITY)){
                String modifiedString = fAssessment.RecordType.Name.replaceAll('\\s*-\\s*', '-');  //'Viability - CV' will convert as '	Viability-CV'
                System.debug('>>'  + modifiedString);
                vehicleNameCreditAssMethodMap.get(fAssessment.Vehicle__r.Name + fAssessment.Vehicle__r.Product__r.Name).remove(modifiedString);
            }
        }
        system.debug('vehicleNameCreditAssMethodMap UPADTEDDD>>>>> ' + vehicleNameCreditAssMethodMap);
        Set<String> vehicleNames = new Set<String>();
        for(Vehicle__c vcl : [SELECT Id,Name,product__r.Name from Vehicle__c WHERE Id IN: vehicleIds]){
            if(vehicleNameCreditAssMethodMap.get(vcl.Name + vcl.product__r.Name) != null && !vehicleNames.contains(vcl.Name+vcl.product__r.Name) && vehicleNameCreditAssMethodMap.get(vcl.Name + vcl.product__r.Name).size() > 0){
                validationMsg+= '<li>' +'Please create ' +'<b> '+ vehicleNameCreditAssMethodMap.get(vcl.Name + vcl.product__r.Name)+' </b>' +' Assessement for <b> '+ vcl.Name + vcl.product__r.Name +'</b></li>';
                vehicleNames.add(vcl.Name + vcl.product__r.Name);
            }
        }
        system.debug('validationMsg1234>> ' + validationMsg);
        return validationMsg;
    }
    //end here
    
    @AuraEnabled
    public static Boolean captureDecisionComment(String recordId, String comments) {
        Boolean isSuccess = false;
        try {
            List<Loan_Application__c> listApplication = [SELECT Id, OwnerId,Decisioning_Comments__c FROM Loan_Application__c WHERE Id =: recordId];
            listApplication[0].Id = recordId;
            listApplication[0].Decisioning_Comments__c = UB_CommonUtil.getDecisionComment(comments,'Approved',listApplication[0].Decisioning_Comments__c);
            update listApplication;
            isSuccess = true;
        } catch (Exception e) {
            isSuccess = false;
            System.debug('The exception is >>' + e.getLineNumber() + ' Exception message is >>' + e.getMessage());
        }
        return isSuccess;
    }
}