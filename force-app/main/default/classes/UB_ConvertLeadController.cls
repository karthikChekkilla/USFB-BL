/**
* @File Name          : UB_ConvertLeadController.cls
* @Description        : This class will have convert lead
* @Author             : Deepak Joshi
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         22-03-2024            Deepak Joshi          Initial Version           
**/
public with sharing class UB_ConvertLeadController {
 /*
    This method is use to to convert lead and create new records 
    */
    @AuraEnabled
    public static string convertLead(String leadId){
        Savepoint sp = Database.setSavepoint();
        try {
            List<Lead_Fields_Mapping__mdt>  leadFieldsMappingList = Lead_Fields_Mapping__mdt.getAll().values();
            List<Lead__c> leadRecords = new UB_LeadsSelector().selectById(new Set<Id>{leadId});
            Lead__c leadObj  = leadRecords[0];
            if(leadObj.Lead_Stage__c == 'New'){
                leadObj.Lead_Stage__c = UB_ConstantsUtil.CONSENT_PENDING;
                update leadObj;
                createDocument(leadObj.Lead_Stage__c ,leadObj.Id);
                return 'SUCCESS';

            }



            Account accObje = new Account();
            Loan_Applicant__c loanApplicantObj = new Loan_Applicant__c();
            Loan_Application__c  loanApplicationObj = new Loan_Application__c();
            //Product__c  productObj = new Product__c();
            String loanApplicationId;

            for(Lead_Fields_Mapping__mdt leadFields : leadFieldsMappingList){
                
                if(leadFields.Target_Object__c == UB_ConstantsUtil.ACCOUNT && leadObj.get(leadFields.Lead_Fields_Name__c) !=null){
                   accObje.put(leadFields.Target_Object_Field_Name__c ,leadObj.get(leadFields.Lead_Fields_Name__c));
                
                }
                if(leadFields.Target_Object__c== UB_ConstantsUtil.LOAN_APPLICANT && leadObj.get(leadFields.Lead_Fields_Name__c) !=null){
                   loanApplicantObj.put(leadFields.Target_Object_Field_Name__c ,leadObj.get(leadFields.Lead_Fields_Name__c));
            
                }
                if(leadFields.Target_Object__c== UB_ConstantsUtil.LOAN_APPLICATION  && leadObj.get(leadFields.Lead_Fields_Name__c) !=null){
                   loanApplicationObj.put(leadFields.Target_Object_Field_Name__c ,leadObj.get(leadFields.Lead_Fields_Name__c));
            
                }
                //if(leadFields.Target_Object__c== UB_ConstantsUtil.PRODUCT && leadObj.get(leadFields.Lead_Fields_Name__c) !=null){
                //    productObj.put(leadFields.Target_Object_Field_Name__c ,leadObj.get(leadFields.Lead_Fields_Name__c));
            
                //}

            }
            //if(Schema.sObjectType.Account.isCreateable()){
                System.debug('** accObje   == '+accObje);
                accObje.RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(UB_ConstantsUtil.CUSTOMER).getRecordTypeId();
                Account checkedDupAccount= UB_CommonUtil.ckeckAccountduplicateWithPanNo(leadObj.PAN__c);
                if(checkedDupAccount != null){
                    accObje.Id = checkedDupAccount.Id;
                    
                }
                upsert accObje;
            //}
            //if(Schema.sObjectType.Product__c.isCreateable()){
             //   System.debug('** productObj   == '+productObj);
            //    insert productObj;
           // }
            if(Schema.sObjectType.Loan_Application__c.isCreateable()){
                System.debug('** loanApplicationObj   == '+loanApplicationObj);
                loanApplicationObj.Loan_Application_Stage__c =UB_ConstantsUtil.KYC_VALIDATION;
                insert loanApplicationObj;
                loanApplicationId =  loanApplicationObj.Id;
               
            }
            if(Schema.sObjectType.Loan_Applicant__c.isCreateable()){
                loanApplicantObj.Account__c =accObje.Id; 
                loanApplicantObj.Loan_Application__c =loanApplicationId;
                loanApplicantObj.Applicant_Type__c = UB_ConstantsUtil.APPLICANT;
                insert loanApplicantObj;
                updateDocument(leadId,loanApplicationId,loanApplicantObj.Id);
                updateAddress(leadId,loanApplicantObj.Id);
            }
            if(Schema.sObjectType.Lead__c.isUpdateable()){
                leadObj.Lead_Stage__c =UB_ConstantsUtil.CONVERTED;
                update leadObj;
            }
            
            Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LOAN_APPLICATION,loanApplicationId,UB_ConstantsUtil.KYC_VALIDATION ,'');
            insert activityHistory;
            return loanApplicationId;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
           return 'ERROR: '+e.getMessage();
           // throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string checkValidations(string recordId) {
        try{
            Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ConvertLeadController');
            List<Lead__c> leadList = new UB_LeadsSelector().selectById(new Set<Id>{recordId});
            System.debug('**loanAppObj--checkValidations->   '+leadList);
            string validationMsg = checkValidation(leadList[0], messageConfigMap); 
            if(validationMsg.trim().length() > 0) {
                return validationMsg;
            }  
            return null;        
        } catch (Exception e) {
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
        
            throw new AuraHandledException(e.getMessage());
        }
    }
     // methode to check validations
     private static string checkValidation(Lead__c leadObj,Map<String,Messages_Config__mdt> messageConfigMap) {
        string validationMsg = '';
    

        if(leadObj.Lead_Stage__c == UB_ConstantsUtil.CONSENT_PENDING){
               System.debug('**leadObj== '+ leadObj.Consent_Received__c);
            if(leadObj.Consent_Received__c == false)  {
            validationMsg = '<li>'+messageConfigMap.get('Consent_Received').Message__c+'</li>';
            }
            if(leadObj.PAN__c == null)  {
                validationMsg  += '<li>'+messageConfigMap.get('PAN').Message__c+'</li>';
            }
        }
        if(leadObj.Lead_Stage__c == 'New'){
            if(leadObj.PAN__c == null)  {
                validationMsg = '<li>'+UB_ConstantsUtil.PAN_REQUIRED+'</li>';
            }
            
            if(leadObj.Addresses__r.size() == 0) {
                validationMsg += '<li>'+UB_ConstantsUtil.ADDRESS_REQUIRED+'</li>';
            } 
           
        }
        
        return validationMsg;
    }
    // update loan Application Id on leade Documents
    private static void updateDocument( String leadId, String loanApplicationId,String loanApplicantId){
        if(Schema.sObjectType.Document__c.isUpdateable() && loanApplicantId !=null){
            List<Document__c>  documentList = new UB_DocumentsSelector().selectByLeasId(new Set<Id>{leadId}); 
            System.debug('documentList  '+documentList);
            for(Document__c doc :documentList){
                doc.Loan_Application__c = loanApplicationId;
                doc.Loan_Applicant__c = loanApplicantId;
            }
            update documentList;
        }

    }
    // update loan Application Id on leade address 
    private static void updateAddress( String leadId, String loanApplicantId){
        if(Schema.sObjectType.Address__c.isUpdateable() && loanApplicantId !=null){ 
            List<Address__c>  addressList = new UB_AddressesSelector().selectByLeasId(new Set<Id>{leadId}); 
            System.debug('--addressList  '+addressList);
            for(Address__c addr :addressList){
                addr.Loan_Applicant__c = loanApplicantId;
            }
            update addressList;
        }

    }
    public static void createDocument(String stageName,String leadId) {
        Savepoint sp = Database.setSavepoint();
        try{
            System.debug('** stageName '+ stageName);
            List<Document_Checklist__c>  documentChecklists = new UB_DocumentChecklistsSelector().selectByStage(stageName); 
            System.debug('** documentChecklists '+ documentChecklists);
            List<Document__c> documentList = new List<Document__c>();
            for(Document_Checklist__c doc : documentChecklists ){
               Document__c documentObj = new Document__c();
                documentObj.Document_Checklist__c = doc.Id;
                documentObj.Lead__c = leadId;
                documentObj.Stage__c = doc.Stage__c;
                documentObj.Is_Required__c = doc.Is_Required__c;
                documentObj.Document_Type__c = doc.Document_Type__c;
                documentObj.Document_Sub_Type__c = doc.Document_Subtype__c;
                documentList.add(documentObj);
            }
            if(!documentList.isEmpty()){
                System.debug('** documentList '+ documentList);
                insert documentList;

            }
        
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            System.debug('Exception@@'+e.getMessage());
        }

    }
    
    
}