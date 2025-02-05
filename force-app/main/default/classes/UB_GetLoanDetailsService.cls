/**
* @File Name          : UB_GetLoanDetailsService.cls
* @Description        : Api to get loan Application / Lead  Details.
* @Author             : Zafaruddin
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024           Zafaruddin         Initial Version
*/

@RestResource(urlMapping='/LoanStatus/*')
global with sharing class UB_GetLoanDetailsService {
    
    
    /**
    * @description function will get Lead/Loan Status .
    * @author Zafaruddin | 04-15-2024 
    **/
    @HttpGet
    global static void getLoanStatus() {
        Savepoint sp = Database.setSavepoint();
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('LoanGetDetailsService');
        try {
            RestRequest req = RestContext.request;
            System.debug('AAAAAAAA2222  '+req.params.get('leadId'));
            if(req.params.get('leadId') == null) {
                RestContext.response.statusCode = 400;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('LeMS_LeadId_is_not_Passed_in_WebService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('LeMS_LeadId_is_not_Passed_in_WebService').Message__c + '") }');
                return ;
            }
            List<Lead__c> leadList = [SELECT Id,Lead_Status__c, (SELECT Id,Loan_Application_Status__c FROM Loan_Applications__r) FROM Lead__c WHERE LeMS_Lead_ID__c =:req.params.get('leadId')];
            System.debug('leadList   '+leadList);
            if(leadList.isEmpty()) {
                RestContext.response.statusCode = 404;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('Lead_Record_Not_Found').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('Lead_Record_Not_Found').Message__c + '") }');
                return ;
            }
            String status;
            if(!leadList[0].Loan_Applications__r.isEmpty() && leadList[0].Loan_Applications__r[0].Id !=  NULL) {
                status = String.valueOf(leadList[0].Loan_Applications__r[0].Loan_Application_Status__c);
            } else {
                status = String.valueOf(leadList[0].Lead_Status__c);
            }
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "loanStatus":"' + status + '" ,  "responseType": "' + messageConfigMap.get('Loan_Status_Return').Message_Type__c + '" , "Messages": "' + messageConfigMap.get('Loan_Status_Return').Message__c + '") }');
        	} catch(Exception e) {
            Database.rollback(sp);
            System.debug('Exception--->'+e.getMessage());
            System.debug('ERROR LINE NUMBER--->'+e.getLineNumber());
            // call method to create ExceptionLogRecord
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            RestContext.response.statusCode = 406;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "responseType": "' + messageConfigMap.get('DevelopmentError_LoanGetDetailsService').Message_Type__c + '" , "errorMessages": "' + messageConfigMap.get('DevelopmentError_LoanGetDetailsService').Message__c + '  : ' + e.getMessage() +   '") }');
        }
    }
     
   public class LoanDetails {
       public String LoanStatus;

   }
    
   global class ModelClass {
        public String status;
        public String responseMessage;
        public String loanStatus;
        public String responseType;

        public ModelClass() {
            status = '';
            responseMessage = '';
            loanStatus = NULL;
            responseType = '';
        }
    }
    
    
    public static ModelClass checkValidation(String Status , String Message, String responseType) {
        ModelClass modCls = new ModelClass();
        modCls.Status = Status;
        modcls.responseMessage = Message;
        modcls.responseType = responseType;
        return modCls;    
    }
        


}