/**
* @File Name          : UB_CommonUtil.cls
* @Description        : Common class to define reusable methods
* @Author             : Karthik Chekkilla
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         14-03-2024            Karthik Chekkilla         Initial Version
*/
public class UB_CommonUtil {
    
    
    /**
* @Description : Method to fetch MetaDataRecord based on source value.
* @Author      :Zafaruddin
* @Date        :20/03/2024
*/
     public static Map<String,Messages_Config__mdt> getMessageRecord(String source) {
        Map<String,Messages_Config__mdt> messageConfigMap = new Map<String,Messages_Config__mdt>();
        for(Messages_Config__mdt metaDataRecord :[SELECT  Id,Message__c,Message_Type__c,DeveloperName  FROM Messages_Config__mdt WHERE Source__c = :source]) {
            messageConfigMap.put(metaDataRecord.DeveloperName , metaDataRecord );
        }
        return messageConfigMap;
    }
    
    /**
* @Description : Method to insert Exception record in system
* @Author      :Zafaruddin
* @Date        :21/03/2024
*/
    public static void createExceptionLogRecord(Exception e, String lob) {
        UB_LogException logObj = new UB_LogException();
        logObj.log(e,lob);
    }
    /**
* @Description : Method to Check account duplicate pan no
* @Author      :Deepak Joshi
* @Date        :28/03/2024
*/
    public static Account ckeckAccountduplicateWithPanNo(String panNo){
        List<Account> accountList = new UB_AccountsSelector().selectByPanNo(panNo);
        if(!accountList.isEmpty()){
            return  accountList[0];
        }
        return null;
    }
    /**
* @Description : Method to create Activity History
* @Author      :Deepak Joshi
* @Date        :1/04/2024
*/
    public static Activity_History__c createActivityHistory (String ObjectName , Id recordId ,String OldStage ,String newStage){
        Activity_History__c appHistory = new Activity_History__c();
        if(ObjectName ==UB_ConstantsUtil.LOAN_APPLICATION){
            appHistory.Loan_Application__c = recordId;
        }
        if(ObjectName ==UB_ConstantsUtil.LEAD){
            appHistory.Lead__c = recordId;
        }
        appHistory.From_Stage__c = OldStage;
        appHistory.To_Stage__c = newStage;
        appHistory.From_User__c = UserInfo.getUserId();
        //appHistory.TAT__c =System.now();
        return appHistory;
        
    }
    
    /**
* @Description : Method to create Verification record
* @Author      : Mohit Saxena
* @Date        : 1/04/2024
*/
    public static Verification__c createVerfication (String loanApplicantId, String recordTypeId, String appStatus){
        Verification__c obj = new Verification__c(
            Loan_Applicant__c = loanApplicantId,
            RecordTypeId      = recordTypeId,
            Status__c         = appStatus
        );
        return obj;
    }
    
    /**
* @Description : Method to convert date into string format
* @Author      : Zafaruddin
* @Date        : 2/04/2024
*/
    public static String dateFormatter( Date dateOfBirth){
        String dob = '';
        if( dateOfBirth <> Null){
            dob += dateOfBirth.day() >= 10 ? dateOfBirth.day()+'': '0'+dateOfBirth.day();
            dob += '-';
            dob += dateOfBirth.month() >= 10 ? dateOfBirth.month() +'': '0'+dateOfBirth.month();
            dob += '-';
            dob += dateOfBirth.year();
        }
        return dob;
    }
    
    @AuraEnabled
    public static String fetchVerificationId (Id customerId, String apiName){
        if(String.isNotBlank(customerId) && String.isNotBlank(apiName)){
            Loan_Applicant__c obj = [SELECT Id,ScoreCard_Verification__c,Consent_Verification__c,Sherlock_Verification__c,
                                     Dedupe_Verification__c,PAN_Verification__c,Aadhaar_Verification__c,Cibil_Verification__c,Perfios_Verification__c,
                                     CFR_Verification__c,Hunter_Verification__c, Udyam_Verification__c, MCA_Document_Verification__c
                                     FROM Loan_Applicant__c WHERE Id =: customerId AND Is_Deleted__c = 'No'];
            system.debug('objTest1112223:::>'+obj);
            if(apiName == UB_ConstantsUtil.PAN_API){
                return obj.PAN_Verification__c;
            }else if(apiName == UB_ConstantsUtil.AADHAAR_OTP_API){
                return obj.Aadhaar_Verification__c;
            }else if(apiName == UB_ConstantsUtil.DEDUPE_API){
                return obj.Dedupe_Verification__c;
            }else if(apiName == UB_ConstantsUtil.CIBIL_API){
                return obj.Cibil_Verification__c;
            }else if(apiName == UB_ConstantsUtil.SHERLOCK_API){
                return obj.Sherlock_Verification__c;
            }else if(apiName == UB_ConstantsUtil.CONSENT_API){
                return obj.Consent_Verification__c;
            }else if(apiName == UB_ConstantsUtil.SCORECARD_API){
                return obj.ScoreCard_Verification__c;
            }else if(apiName == UB_ConstantsUtil.CFR_API){
                return obj.CFR_Verification__c;
            }else if(apiName == UB_ConstantsUtil.PERFIOS_API){
                return obj.Perfios_Verification__c;
            }else if(apiName == UB_ConstantsUtil.HUNTER_API){
                return obj.Hunter_Verification__c;
            }else if(apiName == UB_ConstantsUtil.UDYAM_API){
                return obj.Udyam_Verification__c;
            }else if(apiName == BL_ConstantsUtil.MCA_API){
                return obj.MCA_Document_Verification__c;
            }else{
                return null;
            }
        }
        return null;
    }

    /**
    * @description  : Method will create document record and link with it either loan applicant or loan applicant.
    * @author Zafaruddin | 05-08-2024 
    **/
    public static void createDocument(String title, String pathOnClient, Blob data,String LoanId, String applicantId, String docType, String docSubType) {
        List<Document__c> documents = new List<Document__c>();
        Id recordId = (Id)LoanId;
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        System.debug('sObjName   '+sObjName);
        System.debug('docSubType   '+docSubType);
        if(title == UB_ConstantsUtil.LAF_TITLE) {
            for(Document__c doc : [SELECT Id ,Document_Type__c, Document_Sub_Type__c FROM Document__c WHERE Document_Type__c =:docType /*AND Document_Sub_Type__c=:docSubType*/ AND Loan_Application__c=:LoanId]){
                if(doc.Document_Sub_Type__c.contains(docSubType)){
                    documents.add(doc);
                }
            }
        }
        else if(docSubType == NULL) {
            documents = [SELECT Id , Document_Type__c FROM Document__c WHERE Document_Type__c =:docType  AND  Loan_Application__c=:LoanId  AND Loan_Applicant__c=:applicantId];
        } 
        else {
            if(sObjName == UB_ConstantsUtil.LOAN_APPLICATION) {
                for(Document__c doc : [SELECT Id ,Document_Type__c, Document_Sub_Type__c FROM Document__c WHERE Document_Type__c =:docType AND /*Document_Sub_Type__c=:docSubType AND*/ Loan_Application__c=:LoanId AND Loan_Applicant__c=:applicantId]){
                    if(doc.Document_Sub_Type__c.contains(docSubType)){
                        documents.add(doc);
                    }
                }
            }
            else {
                //Disbursement Document checklist condition
                for(Document__c doc : [SELECT Id ,Document_Type__c, Document_Sub_Type__c FROM Document__c WHERE Document_Type__c =:docType AND Disbursement__c=:LoanId ]){
                    System.debug('DISBURSMENT DOCUMENT ' +doc);
                        documents.add(doc);
                    
                }
            }        
        }
        System.debug('documents   '+documents);
        System.debug('Titleeee  '+title);
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;

        String documentId = '';
        if(!documents.isEmpty()) {
            documentId = documents[0].Id;
            
        } else {
            Document__c document = new Document__c();
            document.Document_Type__c = docType;
            document.Document_Sub_Type__c = docSubType;
            if(sObjName == UB_ConstantsUtil.LOAN_APPLICATION) {
                document.Loan_Application__c = LoanId;
            } 
            else {
                document.Disbursement__c = LoanId;
               // List<Disbursement__c> disbursementList = new UB_DisbursementsSelector().getDisbursementRecordsByIds(new Set<Id>{document.Disbursement__c});
                //document.Loan_Application__c = disbursementList[0].Loan_Application__c;
            }
            document.Loan_Applicant__c = applicantId;
            document.Status__c = 'Uploaded';
            insert document;
            System.debug('document   '+document);
            documentId = document.Id;

        }
        System.debug('DATAAAAAAA  '+data);
       // System.debug('DATAAAAAAA 11111 '+data.toString());

        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = pathOnClient;
        cv.VersionData = data;
        // code for portal user.
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME  || profileName == BL_ConstantsUtil.PORTAL_PROFILE_NAME_BL) {
            cv.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
        }
        //cv.PublishStatus = 'p';
        //cv.IsMajorVersion = true;
        Insert cv;

        System.debug('cvcvcvcvcvcv   '+cv);
       // ContentVersion cv = new ContentVersion(Title = title, PathOnClient = pathOnClient, VersionData = data, FirstPublishLocationId = documentChild.Id);
       // insert cv;
        UB_DisplayUBDocumentsController.uploadDocument(docSubType,title, String.valueOf(data),documentId,cv.Id);
        System.debug('cvcvcvcvcvcv1111   '+cv);

    }
    
    
    public static sObject createCustomObjectShare(Id recordId, Id userOrGroupId, String recordAccessLevel, Boolean isShareRecord){
        String sObjLabel = recordId.getSObjectType().getDescribe().getName();
        // Create new sharing object for the custom object Job.
        sObjLabel = sObjLabel.contains('__c') ? sObjLabel.remove('__c') : sObjLabel;
        sObject sObj = Schema.getGlobalDescribe().get(sObjLabel + '__Share').newSObject();
        // Set the ID of record being shared.
        sObj.put('ParentId',recordId);
        // Set the ID of user or group being granted access.
        sObj.put('UserOrGroupId',userOrGroupId);
        // Set the access level.
        sObj.put('AccessLevel',recordAccessLevel);
        // Set rowCause to 'manual' for manual sharing.
        // This line can be omitted as 'manual' is the default value for sharing objects.
        //sObj.put('RowCause',Schema.Loan_Application__Share.RowCause.Manual);
        
        if(isShareRecord){
            // Insert the sharing record and capture the save result. 
            Database.SaveResult sr = Database.insert(sObj,false);
            // The false parameter allows for partial processing if multiple records passed 
            // into the operation.
            /*if(sr.isSuccess()){
                return true;
            }else {
                // Get first save result error.
                Database.Error err = sr.getErrors()[0];
                // Check if the error is related to trival access level.
                // Access level must be more permissive than the object's default.
                // These sharing records are not required and thus an insert exception is acceptable. 
                if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION && err.getMessage().contains('AccessLevel')){
                    return true;
                }else{
                    return false;
                }
            }*/
        }
        return sObj;
    }

    /**
    * @description  function to send Notification to user.
    * @author Zafaruddin | 04-24-2024 
    **/
    public static void sendNotification(String title, String body, String notificationName, String targetRecordId, String targetUserId ) {
        Try {
            List<CustomNotificationType > TemplateInfoDetail = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =:notificationName];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(TemplateInfoDetail[0].Id);
            notification.setTargetId(targetRecordId);

            System.debug('notification   '+notification);
            System.debug('targetUserId   '+targetUserId);
            notification.send(new Set<String>{targetUserId});

        }
        catch(Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        } 
    }




    /**
    * @description  method will check salesforce internal dedupe based on passing parameter.
    * @author Zafaruddin | 04-23-2024 
    * @param ApplicantPan 
    * @param loanId 
    **/
    public static void dedupeTriggerRuled(String ApplicantPan, String loanId) {
        List<String> rejectLoanStatus = new List<String>{'Rejected','Cancelled','Revoke','Closed','Disbursed'};
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('SalesforceDedupe');
        if(String.isNotBlank(loanId)) {
            List<Loan_Applicant__c> dedupeApplicant = [SELECT Id,Loan_Application__c,Loan_Application__r.Loan_Application_Status__c,
                                                        Loan_Application__r.Name,Loan_Application__r.Ro_RM__c, Loan_Application__r.DSA__c, Loan_Application__r.DSA__r.ManagerId 
                                                        FROM Loan_Applicant__c WHERE Loan_Application__c !=:loanId AND Applicant_Type__c='Applicant'  
                                                        AND Pan_Number__c=:ApplicantPan AND ( Loan_Application__r.Loan_Application_Status__c NOT IN : rejectLoanStatus 
                                                        OR  (Loan_Application__r.Loan_Application_Status__c='Rejected' 
                                                        AND CreatedDate = LAST_N_DAYS:60))];
            System.debug('dedupeApplicant    '+dedupeApplicant);
            if(!dedupeApplicant.isEmpty()) {
                Loan_Application__c  newApplication = new Loan_Application__c();
                newApplication.Id = loanId;
                newApplication.Reject_Reason__c = UB_ConstantsUtil.SYSTEM_REJECT;
                if(dedupeApplicant[0].Loan_Application__r.Loan_Application_Status__c ==  UB_ConstantsUtil.REJECT_LOAN_STATUS) {
                    newApplication.Reject_Sub_Reason__c     = messageConfigMap.get('Duplicate_record_rejected_within_60_days').Message__c;
                } else {
                    newApplication.Reject_Sub_Reason__c = messageConfigMap.get('Dedupe_Duplicate_Record').Message__c;
                }
                newApplication.Duplicate_LAF_Id__c = dedupeApplicant[0].Loan_Application__c;
                newApplication.Loan_Application_Status__c = UB_ConstantsUtil.REJECT_LOAN_STATUS;
                update newApplication ;
                // function to send notification to user.
                if(dedupeApplicant[0].Loan_Application__c != null && dedupeApplicant[0].Loan_Application__r.Ro_RM__c != null) {
                    UB_CommonUtil.sendNotification('Duplicate Application ' +dedupeApplicant[0].Loan_Application__r.Name  +'Found.','Dedupe Application Found','Lead_Owner_Change',dedupeApplicant[0].Loan_Application__c,dedupeApplicant[0].Loan_Application__r.Ro_RM__c);
                } else if(dedupeApplicant[0].Loan_Application__c != null && dedupeApplicant[0].Loan_Application__r.DSA__c != null) {
                    UB_CommonUtil.sendNotification('Duplicate Application ' +dedupeApplicant[0].Loan_Application__r.Name  +'Found.','Dedupe Application Found','Lead_Owner_Change',dedupeApplicant[0].Loan_Application__c,dedupeApplicant[0].Loan_Application__r.DSA__r.ManagerId);
                }
                
            }
        }
    }

    @AuraEnabled
    public static String financialsCalculationProductValidation (Id loanId, string recordTypeName){
        System.debug('loanIdloanIdloanId  '+loanId);
        String duplicateId = '';
        String sObjName = Id.valueOf(loanId).getSObjectType().getDescribe().getName();
        System.debug('sObjName  '+sObjName);
        if( sObjName == 'Vehicle__c') {
            loanId = [SELECT Id,Loan_Application__c FROM Vehicle__c WHERE Id=:loanId].Loan_Application__c ;
        }
        if(recordTypeName == 'FFR'){
            duplicateId = loanId + 'FFR';
            System.debug('duplicateId  '+duplicateId);
            List<Financial_Assessment__c> financialFFRList = [SELECT Id FROM Financial_Assessment__c WHERE Loan_Application__c=:loanId AND recordType.Name='FFR' AND Financial_Duplicate_Id__c=:duplicateId];
            System.debug('financialFFRList   '+financialFFRList);
            if(!financialFFRList.isEmpty()){
                return 'duplicate';
            }
        }

        System.debug('loanIdloanIdloanId  '+loanId);
        If(String.isNotBlank(loanId)) {
            String creditAssessmentMethod = '';
            for(Product__c product : [SELECT Id,Product__r.Credit_Assessment_Method__c FROM Product__c WHERE Loan_Application__c=:loanId]) {
                if(product != NULL && product.Product__r.Credit_Assessment_Method__c != NULL) {
                    creditAssessmentMethod += product.Product__r.Credit_Assessment_Method__c;
                }
            } System.debug('creditAssessmentMethod  '+creditAssessmentMethod);
             return  creditAssessmentMethod;
        }
    
        return null;
    }
    
    /**
    * @description : function will return record type and object name to show it in create mode.
    * @author Zafaruddin | 04-22-2024 
    * @param vehicleId 
    * @param details 
    * @return String 
    **/
    @AuraEnabled
    public static String getVehicleAssessmentDetails (Id vehicleId, String details){
        if(String.isNotBlank(vehicleId) && String.isNotBlank(vehicleId)){

           
            Vehicle__c vehicleObj = [SELECT Id,Loan_Application__c,Product__r.Product_Category__c FROM Vehicle__c WHERE Id=:vehicleId];
            System.debug('vehicleObj   '+vehicleObj);
            System.debug('VEHICLE   '+vehicleObj.Product__r.Product_Category__c);
            System.debug('Splitttt  '+ details.split(':')[1] );
            String recordTypeName = (vehicleObj.Product__r.Product_Category__c).indexOf('CV') != -1 ? details.split(':')[1] + 'CV' : details.split(':')[1] + 'CE';
         system.debug('TestClassRecordType::>>>>>>>>'+recordTypeName);
            RecordType recordTypeObj = [SELECT Id,DeveloperName from RecordType where DeveloperName =:recordTypeName];
            System.debug('recordTypeName  '+recordTypeName);
            System.debug('recordTypeName object '+recordTypeObj);
            String Json = '';
            if(recordTypeObj != null) {
                Json=  '{"recordTypeId": "' +recordTypeObj.id + '",';
            } else {
                Json=  '{"recordTypeId": "' +null + '",';
            }
            Json+= '"loanApplicationId": "'+vehicleObj.Loan_Application__c+ '",';
            Json+= '"ObjectName": "'+details.split(':')[0]+ '"}';
            System.debug('JSON   '+Json);
            return Json;

           
        }
        return '';
    }

	public static String getDecisionComment(String newComment, String callFrom, String existingComment) {
        String comment = '';
        comment += UserInfo.getName() + ' : ' + String.valueOf(System.now()) + '\n' ;
        comment +=  callFrom + ' : ' + newComment + '\n\n';
        if(existingComment != NULL) {
            existingComment += '\n' + comment;
        }
        else{
            existingComment = comment;
        }
        return existingComment;
    }
    
    @AuraEnabled
    public static Loan_Application__c getData (Id loanId){
        Loan_Application__c loanApplication = new Loan_Application__c();
        if(String.isNotBlank(loanId)) {
            loanApplication = [SELECT Id,Loan_Application_Status__c,Reject_Sub_Reason__c FROM Loan_Application__c WHERE Id=:loanId];
            return  loanApplication;
        }
        return null;
    }
        

    public class FlowInputs{
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String userOrGroupId;
        @InvocableVariable
        public String recordAccessLevel;        

    }
    
    @InvocableMethod(Label='Apex Record Sharing')
    public static void shareRecord(List<FlowInputs> request){
        if(request.size() > 0){
            system.debug('request'+request[0].recordId);
            system.debug('request'+request[0].userOrGroupId); 
            system.debug('request'+request[0].recordAccessLevel);
            if(String.isNotBlank(request[0].recordId) && String.isNotBlank(request[0].userOrGroupId) && String.isNotBlank(request[0].recordAccessLevel)){
                createCustomObjectShare(request[0].recordId, request[0].userOrGroupId, request[0].recordAccessLevel, true);
            }
        }
    }
  	
    /**
    * @description : function will return record type and object name to show it in create mode.
    * @author Mohit | 04-22-2024 
    * @param vehicleId 
    * @param details 
    * @return String 
    **/
    public static Document_Checklist__c createDocumentChecklist(String applicableFor, String docType, String stage, Boolean isActive, Boolean isRequired, String lob){
        Document_Checklist__c obj = new Document_Checklist__c();
        obj.Applicable_For__c = applicableFor;
        obj.Document_Type__c  = docType;
        obj.Stage__c          = stage;
        obj.Is_Active__c      = isActive;
        obj.Is_Required__c    = isRequired;
        obj.LOB__c            = lob;
        return obj;
    }
    
    /**
    * @description : function to create a new disbursement record
    * @author Mohit | 20-06-2024  
    * @return Disbursement record 
    **/
    public static Disbursement__c createDisbursement(String vehicleId, String loanApplicationId, String stage, String status){
        Disbursement__c obj = new Disbursement__c();
        obj.Vehicle__c          = vehicleId;
        obj.Loan_Application__c = loanApplicationId;
        obj.Stage__c            = stage;
        obj.Status__c           = status;
        return obj;
    }
    
    /**
    * @description : function to create a new Sanction Condition record
    * @author Mohit | 20-06-2024   
    * @return Sanction Condition record 
    **/
   /* public static Deviation_Sanction_Condition__c createSanctionCondition(String loanApplicationId, String type, String decision){
        Deviation_Sanction_Condition__c obj = new Deviation_Sanction_Condition__c();
        obj.Loan_Application__c = loanApplicationId;
        obj.Type__c = type;
        obj.Decision__c = decision;
        return obj;
    }*/
    
     //added by chandan on 26th July,2024 to create a Document record for a sanction condition
    public static Document__c createSanctionCondition(String loanApplicationId, String type, String decision) {
        // Create a new Document__c record
        Document__c sanctionCondition = new Document__c();
        
        // Set the fields for the Document record
        sanctionCondition.Loan_Application__c = loanApplicationId;
        sanctionCondition.Document_Type__c = type;
        sanctionCondition.Status__c = decision;
        
        // Return the created Document record
        return sanctionCondition;
    }
    
      /**
    * @description : function to create a Document Record
    * @author Chandan | 08-07-2024   
    * @return the document record 
    **/
    public static Document__c createDocumentRecord(Id loanApplicationId, Id customerId, Id verificationId) {
        Document__c document = new Document__c();
        document.Loan_Application__c = loanApplicationId;
        document.Loan_Applicant__c = customerId;
        document.Verification__c = verificationId;
        document.Status__c = 'Uploaded';
        return document;
    }


/**  @description : This method is used convert numbers into words.
 *   @Author : Musab
 *   date : 27-08-2024
 * **/
public static String convertToWords(Integer num) {
    List<String> thousands = new List<String>{'', 'Thousand', 'Lakh', 'Crore'};
    if (num == 0) {
        return 'Zero';
    }
    String words = '';
    Integer i = 0;
    while (num > 0) {
        Integer chunk = num - (num / 1000) * 1000;  // Get the last three digits
        if (i == 1) {
            // For thousands place, process two digits only
            chunk = num - (num / 100) * 100;
        }
        if (chunk != 0) {
            words = helper(chunk).trim() + ' ' + thousands[i] + ' ' + words;
        }
        num = (i == 1) ? num / 100 : num / 1000;  // Move to the next block of digits
        i++;
    }
    System.debug('words '+words.trim());
    return words.trim();
}
   
 public static void createCallBackApiLog( String body, String message, Integer statusCode, String className, String ApiName, STring apiType) {
    Api_Logger__c apiLogRecord = new Api_Logger__c();
    apiLogRecord.Request__c = body;
    apiLogRecord.Response__c = message;
    apiLogRecord.Status_Code__c = String.valueOf(statusCode);
    apiLogRecord.Class_Name__c = className;
    apiLogRecord.Source__c = ApiName;
    apiLogRecord.Api_Type__c = apiType;
    insert apiLogRecord;

}

public static String helper(Integer num) {
    List<String> belowTwenty = new List<String>{'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'};
    List<String> tens = new List<String>{'', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
    if (num < 20) {
        return belowTwenty[num];
    } else if (num < 100) {
        Integer tensPart = num / 10;  // Get the tens place
        Integer unitsPart = num - tensPart * 10;  // Get the units place
        return tens[tensPart] + (unitsPart != 0 ? ' ' + belowTwenty[unitsPart] : '');
    } else {
        Integer hundredsPart = num / 100;  // Get the hundreds place
        Integer remainder = num - hundredsPart * 100;  // Get the remainder for the next part
        return belowTwenty[hundredsPart] + ' Hundred' + (remainder != 0 ? ' ' + helper(remainder) : '');
    }
}
    
}