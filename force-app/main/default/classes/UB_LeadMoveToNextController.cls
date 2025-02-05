/**
* @File Name          : UB_LeadMoveToNextController.cls
* @Description        : This class use to move Lead stages.
* @Author             : Kamal Hussain
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024            Kamal Hussain           Initial Version           
**/
public class UB_LeadMoveToNextController {
    /*
    This method is use to to convert lead and create new records 
    */
    @AuraEnabled
    public static string convertLead(String leadId){
        Savepoint sp = Database.setSavepoint();
        try {
            List<Lead_Fields_Mapping__mdt>  leadFieldsMappingList = Lead_Fields_Mapping__mdt.getAll().values();
            List<Lead__c> leadRecords = new UB_LeadsSelector().selectById(new Set<Id>{leadId});
            List<Verification__c> leadVerificationList = [SELECT Id,Loan_Applicant__c,Lead__c FROM Verification__c WHERE Lead__c=:leadId Order BY Name DESC];
            System.debug('leadVerificationList    '+leadVerificationList);
            Lead__c leadObj  = leadRecords[0];
            if(leadObj.Lead_Stage__c == UB_ConstantsUtil.LEAD_STAGE_NEW){
                leadObj.Lead_Stage__c = UB_ConstantsUtil.CONSENT_PENDING;
                update leadObj;
                Activity_History__c activityHistory   = UB_CommonUtil.createActivityHistory(UB_ConstantsUtil.LEAD,leadObj.Id,UB_ConstantsUtil.LEAD_STAGE_NEW ,UB_ConstantsUtil.CONSENT_PENDING);
                insert activityHistory;
                String createDocumentd  =  createDocument(leadObj);
               if(createDocumentd =='SUCCESS'){
                return 'SUCCESS';
               }
               else{
                    Database.rollback(sp);
                    return createDocumentd;
               }
                

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
                     if(leadFields.Lead_Fields_Name__c == UB_ConstantsUtil.DATE_OF_BIRTH_INCORPORATION){
                        if(leadObj.Constitution__c == UB_ConstantsUtil.SOLE_PROPRIETORSHIP || leadObj.Constitution__c == UB_ConstantsUtil.INDIVIDUAL ){
                            system.debug('leadObj.Constitution__c BOB > '+ leadObj.Constitution__c);
                             loanApplicantObj.put(UB_ConstantsUtil.DATE_OF_BIRTH ,leadObj.get(leadFields.Lead_Fields_Name__c));
                        }else{
                              system.debug('leadObj.Constitution__c DOI > '+ leadObj.Constitution__c);
                            loanApplicantObj.put(UB_ConstantsUtil.DATE_OF_INCORPORATION ,leadObj.get(leadFields.Lead_Fields_Name__c));
                        }
                    }else{
                   loanApplicantObj.put(leadFields.Target_Object_Field_Name__c ,leadObj.get(leadFields.Lead_Fields_Name__c));
                    }
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
                accObje.RecordTypeId =UB_ConstantsUtil.CUSTOMER_ACCOUNT_RECORD_TYPE;
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
                loanApplicationObj.RecordTypeId = UB_ConstantsUtil.LOGIN_LOAN_APPLICATION_RECORD_TYPE;
                loanApplicationObj.Is_Retrigger_S1__c = true; // Added By Zafaruddin
                insert loanApplicationObj;
                loanApplicationId =  loanApplicationObj.Id;
               
            }
            system.debug('$## '+loanApplicationObj.lob__c);
            if(Schema.sObjectType.Loan_Applicant__c.isCreateable()){
                loanApplicantObj.Account__c =accObje.Id; 
                loanApplicantObj.Loan_Application__c =loanApplicationId;
                loanApplicantObj.Applicant_Type__c = UB_ConstantsUtil.APPLICANT;
                if((loanApplicationObj.lob__c == 'CV' || loanApplicationObj.lob__c == 'CE')){
                    loanApplicantObj.Is_Deleted__c = 'No';
                    if((loanApplicantObj.Constitution__c == UB_ConstantsUtil.INDIVIDUAL || loanApplicantObj.Constitution__c == UB_ConstantsUtil.SOLE_PROPRIETORSHIP) ){
                        loanApplicantObj.RecordTypeId = UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE;
                    }else if((loanApplicantObj.Constitution__c != UB_ConstantsUtil.INDIVIDUAL && loanApplicantObj.Constitution__c != UB_ConstantsUtil.SOLE_PROPRIETORSHIP) ){
                        loanApplicantObj.RecordTypeId = UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE;
                    }
                }
                //BL changes by lakshya verma on 23-july-2024
                else if(loanApplicationObj.lob__c == 'BL' ){
                    loanApplicantObj.BL_Income_Considered__c = 'Yes';
                    loanApplicantObj.Is_Deleted__c = 'No';
                    if((loanApplicantObj.Constitution__c == BL_ConstantsUtil.INDIVIDUAL_CONSTITUTION || loanApplicantObj.Constitution__c == BL_ConstantsUtil.SOLE_PROPRIETORSHIP_CONSTITUTION)){
                        loanApplicantObj.RecordTypeId = BL_ConstantsUtil.BL_INDIVIDUAL_APPICANT_RECORD_TYPE;
                    }else if((loanApplicantObj.Constitution__c != BL_ConstantsUtil.INDIVIDUAL_CONSTITUTION && loanApplicantObj.Constitution__c != BL_ConstantsUtil.SOLE_PROPRIETORSHIP_CONSTITUTION)){
                        loanApplicantObj.RecordTypeId = BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE;
                    }
                }/*
                else {
                    loanApplicantObj.RecordTypeId = UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE;
                }*/
                
                insert loanApplicantObj;
                // code added by zafaruddin
                if(!leadVerificationList.isEmpty()) {
                    for(Verification__c verification : leadVerificationList) {
                        verification.Loan_Applicant__c = loanApplicantObj.Id;
                    }
                    update leadVerificationList;
                    
                    loanApplicantObj.Consent_Received__c = true;
                    loanApplicantObj.Consent_Verification__c = leadVerificationList[0].Id;
                }
                List<Loan_Applicant__c> primaryLoanApplicant = [SELECT Id, Account_Name__c FROM Loan_Applicant__c 
                                                                WHERE Id =: loanApplicantObj.Id LIMIT 1];
                update loanApplicantObj;
                List<loan_application__c> loanInsertedId = [SELECT Id, Customer_Name__c FROM loan_application__c WHERE Id =: loanApplicationObj.Id LIMIT 1];
                loanInsertedId[0].Customer_Name__c = primaryLoanApplicant.size() > 0 & primaryLoanApplicant[0].Account_Name__c != null ? primaryLoanApplicant[0].Account_Name__c : '';
                
                system.debug('loanInsertedId-> ' + loanInsertedId);
                system.debug('primaryLoanApplicant-> ' + primaryLoanApplicant);
                UPDATE loanInsertedId;
                // end here
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
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CE);
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
            return '';        
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
        if(leadObj.Lead_Stage__c == UB_ConstantsUtil.LEAD_STAGE_NEW){
            if(leadObj.PAN__c == null)  {
                validationMsg = '<li>'+UB_ConstantsUtil.PAN_REQUIRED+'</li>';
            }
            
            if(leadObj.Addresses__r.size() == 0) {
                validationMsg += '<li>'+UB_ConstantsUtil.ADDRESS_REQUIRED+'</li>';
            }
            if(leadObj.Addresses__r.size() > 0){
                if(leadObj.LOB__c == UB_ConstantsUtil.LOB_BL){
                    
                    if(leadObj.Constitution__c == UB_ConstantsUtil.INDIVIDUAL || leadObj.Constitution__c == UB_ConstantsUtil.SOLE_PROPRIETORSHIP){
                        //validationMsg += '<li>'+BL_ConstantsUtil.RESIDENCE_ADDRESS+'</li>';
                        //validationMsg += '<li>'+BL_ConstantsUtil.OFFICE_ADDRESS+'</li>';
                        system.debug('leadObj.Addresses__r-> ' + leadObj.Addresses__r);
                        Set<String> addressType = new Set<String>{BL_ConstantsUtil.PERMANENT_ADDRESS, BL_ConstantsUtil.RESIDENCE_ADDRESS, BL_ConstantsUtil.OFFICE_ADDRESS};
                            if(!leadObj.Addresses__r.isEmpty()){
                                for(Address__c obj : leadObj.Addresses__r){
                                    if(String.isNotBlank(obj.Address_Type__c) && addressType.contains(obj.Address_Type__c)){
                                        if(obj.BL_PermanentAddressSameAsResidence__c != null && obj.BL_PermanentAddressSameAsResidence__c == 'Yes'){
                                            addressType.remove(BL_ConstantsUtil.PERMANENT_ADDRESS);
                                            addressType.remove(BL_ConstantsUtil.RESIDENCE_ADDRESS);
                                        }else{
                                            addressType.remove(obj.Address_Type__c);
                                        }
                                    }
                                }
                            }
                        if(!addressType.isEmpty()){
                            system.debug('leadObj.addressType-> ' + addressType);
                            String appName = String.valueOf(addressType).replace('{','').replace('}','');
                            validationMsg += '<li>'+appName+ ' is Required'+'</li>';
                        }
                               
                    }else if(leadObj.Constitution__c != UB_ConstantsUtil.INDIVIDUAL && leadObj.Constitution__c != UB_ConstantsUtil.SOLE_PROPRIETORSHIP){
                        Set<String> addressType = new Set<String>{BL_ConstantsUtil.OFFICE_ADDRESS};
                            for(Address__c obj : leadObj.Addresses__r){
                                if(String.isNotBlank(obj.Address_Type__c) && addressType.contains(obj.Address_Type__c)){
                                    addressType.remove(obj.Address_Type__c);
                                }
                            }
                        if(!addressType.isEmpty()){
                            String appName = String.valueOf(addressType).replace('{','').replace('}','');
                            validationMsg += '<li>'+appName+ ' is Required'+'</li>';
                        }
                    }
                }
            }
           
            
            //Added By Mohit Saxena on 19th July 2024 for BL - USFBL-155 
            //Description- First Name, Middle Name, and Last Name is mandatory for individual and Entity Name is mandatory for Non-individual
            if(leadObj.LOB__c == UB_ConstantsUtil.LOB_BL){
                if(String.isNotBlank(leadObj.Constitution__c)){
                    if((leadObj.Constitution__c == BL_ConstantsUtil.SOLE_PROPRIETORSHIP_CONSTITUTION || 
                       leadObj.Constitution__c == BL_ConstantsUtil.INDIVIDUAL_CONSTITUTION) && 
                       (String.isBlank(leadObj.First_Name__c) || /*String.isBlank(leadObj.Middle_Name__c) ||*/
                        String.isBlank(leadObj.Last_Name__c))){
                       		validationMsg += '<li>'+messageConfigMap.get('Individual_Name_Mandatory').Message__c+'</li>';
                    }else if(leadObj.Constitution__c != BL_ConstantsUtil.SOLE_PROPRIETORSHIP_CONSTITUTION && 
                       leadObj.Constitution__c != BL_ConstantsUtil.INDIVIDUAL_CONSTITUTION && 
                       String.isBlank(leadObj.Entity_Name__c)){
                       		validationMsg += '<li>'+messageConfigMap.get('Non_Individual_Entity_Mandatory').Message__c+'</li>';
                    }
                }
                if(String.isBlank(leadObj.Constitution__c) || String.isBlank(leadObj.BL_Repayment_Mode__c)){
                    validationMsg += '<li>'+messageConfigMap.get('Fill_Lead_Mandatory_Fields').Message__c+'</li>';
                }
            } 
            else if(leadObj.LOB__c != UB_ConstantsUtil.LOB_BL){
                if(leadObj.Constitution__c == null) {
                    validationMsg += '<li>'+UB_ConstantsUtil.REQUIRED_FIELDS+'</li>';
                } 
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
                if(doc.Document_Checklist__r.Applicable_For__c == UB_ConstantsUtil.APPLICANT){
                    System.debug('** Applicant Doc --- > '+doc.Document_Checklist__r.Applicable_For__c);
                    doc.Loan_Applicant__c = loanApplicantId;
                }
                doc.Loan_Application__c = loanApplicationId;
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
    public static String createDocument(Lead__c leadObj) {
        Savepoint sp = Database.setSavepoint();
        try{
            List<Document_Checklist__c>  documentChecklists = new UB_DocumentChecklistsSelector().selectByStage(leadObj.Lead_Stage__c); 
            System.debug('** documentChecklists-> '+ documentChecklists);
            System.debug('** leadObj-> '+ leadObj);
            List<Document__c> documentList = new List<Document__c>();
            for(Document_Checklist__c doc : documentChecklists ){
                if(doc.Is_Active__c == true && doc.LOB__c.contains(leadObj.LOB__c)  && doc.Constituation_of_Applicant__c !=null && leadObj.Constitution__c != NULL && doc.Constituation_of_Applicant__c.contains(leadObj.Constitution__c)){
                    System.debug('** doc-> '+ doc);
                    Document__c documentObj = new Document__c();
                    documentObj.Document_Checklist__c = doc.Id;
                    documentObj.Lead__c = leadObj.Id;
                    documentObj.Stage__c = doc.Stage__c;
                    documentObj.Is_Required__c = doc.Is_Required__c;
                    documentObj.Document_Type__c = doc.Document_Type__c;
                    //documentObj.Document_Sub_Type__c = doc.Document_Subtype__c;
                    documentList.add(documentObj);
                }

            }
            if(!documentList.isEmpty()){
                
                insert documentList;
                System.debug('** documentList '+ documentList);
            }
            return 'SUCCESS';
        
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CE);
            return 'ERROR: '+e.getMessage();
        }

    }
    
    
}