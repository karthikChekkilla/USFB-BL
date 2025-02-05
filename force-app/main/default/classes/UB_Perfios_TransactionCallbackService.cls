/**
* @File Name          : UB_Perfios_Retrieve_Report_Integration
* @Description        : Class to Trigger Perfios APIs for Retrieving Reports
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
@RestResource(urlMapping='/TransactionCallback/*')
global class UB_Perfios_TransactionCallbackService {
    @HttpPost
    global static void updateStatus() {
        String status;
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<Verification__c> verificationLst = new List<Verification__c>();
        try{
            
            //Convert the request body to a String
            String requestBody = req.requestBody.toString();
            system.debug('req***'+req);   
            
            PerfiosRequest perfReq = (PerfiosRequest) JSON.deserialize(requestBody,PerfiosRequest.class);
            system.debug('perfReq**'+perfReq);
            if( String.isBlank( perfReq.clientTransactionId)) {
                RestContext.response.statusCode = 400;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "errorMessages": "No client TransactionId provided." }');
                UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),'No client TransactionId provided',400,'UB_Perfios_TransactionCallbackService','PerfiosCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                return ;
            }
            
            if(perfReq.clientTransactionId != Null){
                List<Verification__c> verifications = [SELECT id, Perfios_Transaction_Id__c,Loan_Applicant__c FROM Verification__c WHERE Perfios_Transaction_Id__c =: perfReq.perfiosTransactionId Limit 1];//new UB_VerificationsSelector().selectById(new Set<Id>{perfReq.perfiosTransactionId}); //[SELECT id, Perfios_Transaction_Id__c,Loan_Applicant__c FROM Verification__c WHERE Perfios_Transaction_Id__c =: perfReq.perfiosTransactionId Limit 1];
                verifications[0].Perfios_API_Status__c = perfReq.status;
                verificationLst.addAll(verifications);
                
                if(verifications[0].Loan_Applicant__c != null){
                    UB_Perfios_Retrieve_Report_Integration queueableInstance = new UB_Perfios_Retrieve_Report_Integration(verifications[0].Loan_Applicant__c,perfReq.perfiosTransactionId);
                    System.enqueueJob(queueableInstance);
                    RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "errorMessages": "" }');
                    UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),'Success',200,'UB_Perfios_TransactionCallbackService','PerfiosCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
                    return ;
                }             
            }
            system.debug('Status** '+status);
        }Catch(Exception ex){
            status = 'Error Occured: '+ex.getMessage()+'at line no: '+ex.getLineNumber();
            res.statusCode = 500;
            UB_LogException error = new UB_LogException();
            error.log(ex,'');
            RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "errorMessages": "'+status+'" }');
            UB_CommonUtil.createCallBackApiLog(req.requestBody.tostring(),status,400,'UB_Perfios_TransactionCallbackService','PerfiosCallBackService',UB_ConstantsUtil.WBESERVICE_API_TYPE);
            return ;
        }
        if(verificationLst.size()>0){
            update verificationLst;
        }
       // return status;            
    }
    global class PerfiosRequest{
        global string perfiosTransactionId;
        global string clientTransactionId;
        global string status;
        global string errorCode;
        global string errorMessage;
    }
}