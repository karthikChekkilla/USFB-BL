/**
* @File Name          : UB_LeegalityApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         12-06-2024            Zafaruddin         Initial Version

**/


public with sharing class UB_LeegalityApi {

    UB_HTTPCalloutService service;

        /**
    * @author Zafaruddin | 06-05-2024  
    * @param loanApplicationId 
    **/

    @AuraEnabled
    public static Boolean legalityApiCall (Id loanApplicationId){        
        try {
            Verification__c verifyRecord = new Verification__c();
            List<Invitees> inviteesList = new List<Invitees>();
            UB_LeegalityApi leegalityApi = new UB_LeegalityApi();
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
            for(Loan_Applicant__c applicant : new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{loanApplicationId},UB_ConstantsUtil.APPLICANT) ) {
                if(applicant.Email__c != NULL ) {
                    Invitees invitee = new Invitees();
                    invitee.name =   applicant.Applicant_Name__c;
                    invitee.email =  applicant.Email__c ;
                    invitee.phone =  applicant.Mobile__c;
                    inviteesList.add(invitee);
                }
            }
            for(Loan_Applicant__c applicant :  new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{loanApplicationId},UB_ConstantsUtil.CO_APPLICANT)) {
                if(applicant.Email__c != NULL ) {
                    Invitees invitee = new Invitees();
                    invitee.name =   applicant.Applicant_Name__c;
                    invitee.email =  applicant.Email__c ;
                    invitee.phone =  applicant.Mobile__c;
                    inviteesList.add(invitee);
                }
            }
            for(Loan_Applicant__c applicant : new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{loanApplicationId},UB_ConstantsUtil.GUATANTOR) ) {
                if(applicant.Email__c != NULL ) {
                    Invitees invitee = new Invitees();
                    invitee.name =   applicant.Applicant_Name__c;
                    invitee.email =  applicant.Email__c ;
                    invitee.phone =  applicant.Mobile__c;
                    inviteesList.add(invitee);
                }
            }
            System.debug('inviteesList  '+ JSON.serialize(inviteesList)  );
            List<Bank_Signatory__mdt> inviteeDetailList = [SELECT Id, Email__c, Group_Id__c, Group_Name__c, Name_of_Signatory__c, Order_Of_Signatory__c, Phone__c FROM Bank_Signatory__mdt];
            System.debug('inviteeDetailList META DATA>>'+ inviteeDetailList);
            if( !inviteeDetailList.isEmpty() ){
                for(Bank_Signatory__mdt bnkSigntry : inviteeDetailList){
                    Invitees signatory = new Invitees();
                    signatory.email=bnkSigntry.Email__c;
                    signatory.name = bnkSigntry.Name_of_Signatory__c;
                    signatory.groupId = bnkSigntry.Group_Id__c;
                    signatory.groupName = bnkSigntry.Group_Name__c;
                    inviteesList.add(signatory);
                }
            }
            System.debug('inviteesList UPDATEDDDDDDDDD '+ JSON.serialize(inviteesList)  );
            leegalityApi.service = new UB_HTTPCalloutService('Leegality_Api');
            leegalityApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
            // code to get LAF pdf base 64 againts application.
            PageReference PDf =  Page.CV_VehicleEquipment;
            PDf.getParameters().put('Id',loanApplicationId);
            PDf.setRedirect(false);
            Blob b = PDf.getContentAsPdf();
            List<String> base64 = new List<String>();
            base64.add(EncodingUtil.base64Encode(b));
            String RequestJson = '{"profileId":"4mcWfoO","file":{"name":"","fields":[{}],"additionalFiles": ' + JSON.serialize(base64,true) + ' },"invitees":' + JSON.serialize(inviteesList,true) + ',"irn":""}';
           
            System.debug('requestBodyXXXXXXXXXX  '+RequestJson);
            leegalityApi.service.setRequestBody(RequestJson);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = leegalityApi.service.sendRequest();
            System.debug('responeObj   '+responeObj);
            System.debug('STATUS CODE   '+responeObj.getStatusCode());
            String JSONResponse = responeObj.getBody();//res.getBody();
            List<Loan_Applicant__c> loanAppList = [SELECT Id FROM Loan_Applicant__c WHERE Loan_Application__c=:loanApplicationId AND Applicant_Type__c=:UB_ConstantsUtil.APPLICANT];
            if(responeObj.getStatusCode() == 200) {
                Map<String,Object> ResponseMap = (Map<String,Object>)JSON.deserializeUntyped(JSONResponse);
                System.debug('ResponseMap  '+ResponseMap);
                if(ResponseMap.get('data') != NULL) {
                    ResponseMap =   (Map<String,Object>)ResponseMap.get('data') ;
                    System.debug('ResponseMap   1111 '+ResponseMap);
                    verifyRecord = UB_CommonUtil.createVerfication(loanAppList[0].Id, UB_ConstantsUtil.LEEGALITY_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.COMPLETEDSTATUS);
                    verifyRecord.DocumentId__c = String.valueOf(ResponseMap.get('documentId'));
                }

            } else {
                verifyRecord = UB_CommonUtil.createVerfication(loanAppList[0].Id, UB_ConstantsUtil.LEEGALITY_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                verifyRecord.Failed_Reason__c = JSONResponse  ;
            }
            insert verifyRecord;
            System.debug('verifyRecord  '+verifyRecord);
            update new Loan_Applicant__c(Id = loanAppList[0].Id, Leegality_Verification__c = verifyRecord.Id);
            system.debug('JSONResponse>> '+JSONResponse);
            system.debug('JSONResponse>> LENGTH '+RequestJson.length());
            //When Request Length > 131072
            if(RequestJson.length() > 131072) {
                RequestJson =  RequestJson.substring(0,131072);
                System.debug('jsonRequestBody  jsonRequestBody   '+RequestJson);
            } 

            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                leegalityApi.service.getEndpointURL(), 
                String.valueOf(leegalityApi.service.getHeaderParameters()), 
                leegalityApi.service.getRequestMethod(), 
                RequestJson, 
                JSONResponse, 
                responeObj.getStatusCode(), 
                UB_LeegalityApi.class.getName(), 
                loanAppList[0].Id, 
                Id.valueOf(loanAppList[0].Id).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'LEEGALITY API',
                UB_ConstantsUtil.LOB_CV
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            } 

            return true;
            
        }catch(Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        } 

        return false;
    }

    public class Invitees {
        public String name;
        public String email;
        public String phone;
        public String groupId;
        public String groupName;
    }


}