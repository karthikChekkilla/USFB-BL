/**
* @File Name          : UB_CreateLeadService.cls
* @Description        : Api to insert Lead into system.
* @Author             : Zafaruddin
* @Test CLass         : UB_CreateLeadServiceTest
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================

* 2.0         26-03-2024           Zafaruddin         
*/

@RestResource(urlMapping='/LeadCreation/*')
global with sharing class UB_CreateLeadService {
    
    
    /**
    * @description  : Methid will post leMS lead into Salesforce.
    * @author Zafaruddin | 04-15-2024 
    **/
    @HttpPOST
    global static void doLeadPost() {
        Savepoint sp = Database.setSavepoint();
        String lob = '';
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('LeadWebService');
        RestRequest req = RestContext.request;
        try {
            SYstem.debug('req   '+req);
            LeadDetails leadDet = (LeadDetails)Json.deserialize(req.requestBody.tostring(),LeadDetails.class);
            if(leadDet.PAN == NULL) {
                RestContext.response.statusCode = 404;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('Pan_LeadWebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('Pan_LeadWebService').Message__c + '" }');
                UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('Pan_LeadWebService').Message__c,404,'UB_CreateLeadService','LeadCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                return ;
            } if (leadDet.employeeId == NULL) {
                RestContext.response.statusCode = 404;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('EmployeeCode_LeadWebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('EmployeeCode_LeadWebService').Message__c + '" }');
                UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('EmployeeCode_LeadWebService').Message__c,404,'UB_CreateLeadService','LeadCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                return ;
            } if (leadDet.LeadId == NULL) {
                RestContext.response.statusCode = 404;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('LeMS_LeadId_is_not_Available').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('LeMS_LeadId_is_not_Available').Message__c + '" }');
                UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('LeMS_LeadId_is_not_Available').Message__c,404,'UB_CreateLeadService','LeadCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                return ;
            }  else {
                Lead__c leadRecord = new Lead__c();
                if(leadDet.Product_Category == BL_ConstantsUtil.BL_PRODUCT_CATEGORY) {
                    leadRecord.RecordTypeId = BL_ConstantsUtil.BL_LEMS_LEAD_RECORDTYPE ;
                    lob = UB_ConstantsUtil.LOB_BL;
                    leadRecord.Account_Type__c = leadDet.AccountType ;
                    if(leadDet.AccountType == UB_ConstantsUtil.INDIVIDUAL){
                        leadRecord.Last_Name__c = leadDet.Customer_Name;
                    }else{
                        leadRecord.Entity_Name__c = leadDet.Customer_Name;
                    }
                } else {
                    leadRecord.RecordTypeId = UB_ConstantsUtil.LEMS_RECORD_TYPE ;
                    lob = UB_ConstantsUtil.LOB_CV;
                    leadRecord.Account_Type__c = leadDet.AccountType ;
                    leadRecord.Last_Name__c = leadDet.Customer_Name ;
                }
                
                leadRecord.LOB__c =  lob ;
                leadRecord.Product_Category__c = leadDet.Product_Category ;
                leadRecord.Customer_Type__c = leadDet.Customer_Type ;
                leadRecord.Lead_Stage__c = UB_ConstantsUtil.LEAD_STAGE;
                leadRecord.Lead_Status__c = 'Active';
                leadRecord.Mobile_Number__c = leadDet.Mobile_Number ;
                leadRecord.Lead_Source__c = leadDet.Lead_Source ;
                leadRecord.Campaign_Type__c = leadDet.Campaign_Type ;
                leadRecord.Lead_Nature__c = leadDet.Lead_Nature ;
                leadRecord.Product_Vertical__c   = leadDet.Product_Vertical ;
                leadRecord.Department__c = UB_ConstantsUtil.DEPARTMENT ;
                if(leadDet.employeeId != NULL) {
                   List<User> users = [SELECT Id FROM User WHERE EmployeeNumber  = :leadDet.employeeId  ];
                    if(!users.isEmpty()) {
                        leadRecord.OwnerId = users[0].Id ;
                        leadRecord.RO_RM_Name__c  = users[0].Id ;
                    }else{
                        RestContext.response.statusCode = 404;
                        RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('EmployeeCodeMatch_LeadWebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('EmployeeCodeMatch_LeadWebService').Message__c + '" }');
                        UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('EmployeeCodeMatch_LeadWebService').Message__c,404,'UB_CreateLeadService','LeadCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                        return ;
                    }
                }
                LIST<Branch__c> branchList = new LIST<Branch__c>();
                if(leadDet.Branch != NULL) {
                    branchList = [SELECT Id,Branch_Code__c FROM Branch__c WHERE Branch_Code__c =:leadDet.Branch];
                }
                if(!branchList.isEmpty()) {
                    leadRecord.Branch__c = branchList[0].Id ;
                }
                leadRecord.Gender__c = leadDet.Gender ;
               /* if(leadDet.AccountType == 'Individual') {
                    leadRecord.DOB__c =  Date.valueOf( leadDet.dob) ;
                } else {
                    leadRecord.Date_Of_Incorporation__c =  Date.valueOf( leadDet.dob) ;
                }*/
                System.debug('leadDet.dob  '+leadDet.dob);
                if(leadDet.dob != NULL &&  String.isNotBlank(leadDet.dob) && String.isNotEmpty(leadDet.dob) ) {
                    leadRecord.Date_of_Birth_Incorporation__c=  Date.valueOf( leadDet.dob) ;
                }
                leadRecord.Amount__c =  Integer.valueOf(leadDet.Amount) ;
                //leadRecord.Loan_Period__c = Integer.valueOf(leadDet.Loan_Period)   ;
                leadRecord.PAN__c = leadDet.PAN ;
                leadRecord.LeMS_Lead_ID__c = leadDet.LeadId ;
                List<Pincode__c> pincodeList = new List<Pincode__c>();
                if(Integer.valueOf(leadDet.Amount) != 0 ){
                    insert leadRecord;
                    RestContext.response.statusCode = 201;
                    RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "leadId": "' +leadRecord.Id + '" ,  "responseType": "' + messageConfigMap.get('leadCreate_LeadWebService').Message_Type__c + '" , "Messages": "' + messageConfigMap.get('leadCreate_LeadWebService').Message__c + '" }');
                    UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('leadCreate_LeadWebService').Message__c,201,'UB_CreateLeadService','LeadCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                }else{
                    RestContext.response.statusCode = 400;
                    RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('DevelopmentError_LeadWebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('DevelopmentError_LeadWebService').Message__c + ' :  ' + 'Please enter Loan amount.' +  '" }');
                    UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('DevelopmentError_LeadWebService').Message__c + ' :  ' + 'Please enter Loan amount.',400,'LeadCallBackService','LeadCallBAckService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                }
            }
        }catch(Exception e) {
            Database.rollback(sp);
            System.debug('Exception--->'+e.getMessage());
            System.debug('ERROR LINE NUMBER--->'+e.getLineNumber());
            // call method to create ExceptionLogRecord
            UB_CommonUtil.createExceptionLogRecord(e, lob);
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('DevelopmentError_LeadWebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('DevelopmentError_LeadWebService').Message__c + ' :  ' + e.getMessage() +  '" }');
            UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),messageConfigMap.get('DevelopmentError_LeadWebService').Message__c + ' :  ' + e.getMessage(),400,'LeadCallBackService','LeadCallBAckService',UB_ConstantsUtil.WBESERVICE_API_TYPE);

        }
    }
     
   public class LeadDetails {
       public String Customer_Type;
       public String Customer_Name;
       public String Mobile_Number;
       public String Lead_Source;
       public String Campaign_Type;
       public String Lead_Nature;
       public String Lead_Status;
       public String Department;
       public String Product_Code;
       public String Branch;
       public String Gender;
       public String Amount;
       public String Loan_Period;
       public String PAN;
       public String City;
       public String State;
       public String Pin_Code;
       public String Platform;
       public String employeeId;
       public String currentResidentialAddress;
       public String AddressLine1;
       public String AddressLine2;
       public String AddressLine3;
       public String District; 
       public String Product_Vertical;  
       public String Product_Category;   
       public String Product_Name; 
       Public String LeadId ;
       public String dob;
       public String AccountType;
   }
        
   global class ModelClass {
        public String status;
        public Integer statusCode;
        public String responseMessage;
        public String leadId;
        public String responseType;

        public ModelClass() {
            status = '';
            responseMessage = '';
            leadId = '';
            responseType = '';
            statusCode = 400;
        }
    }
    
    
    public static ModelClass checkValidation(String Status , String Message, String responseType, Integer statusCode) {
        ModelClass modCls = new ModelClass();
        modCls.Status = Status;
        modcls.responseMessage = Message;
        modcls.responseType = responseType;
        modcls.statusCode = statusCode;


        return modCls;    
    }
}