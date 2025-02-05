/**
* @File Name          : UB_SmsApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-07-2024            Zafaruddin         Initial Version

**/

public with sharing class UB_SmsApi {

    UB_HTTPCalloutService service;

        /**
    * @description  Funtion will invoke from flow whenever Lead/Loan status got rejeted. 
    * @author Zafaruddin | 15-07-2024  
    * @param recordId 
    **/
    @InvocableMethod(label='SMS API Invoke' description='Method used for calling SMS Api')
    public static void initiateSmsApi(List<Id> recordId) {
        System.debug('recordIdrecordIdrecordIdrecordId  '+recordId);
        if(recordId != NULL && recordId.size()>0){     
             UB_SmsApi.sendSmsToCustomer(recordId[0]);
        }
    }  

        
    /**
    * @description  Funtion will Call SMS APi 
    * @author Zafaruddin | 15-07-2024  
    * @param recordId 
    **/
    public static void sendSmsToCustomer (Id recordId){
        String lob='';
        String Mobile;
        List<Loan_Applicant__c> loanAppList  = new List<Loan_Applicant__c>();
        try {
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            System.debug('sObjName  '+sObjName);
            if(sObjName == 'Lead__c') {
                List<Lead__c> leadList =   new UB_LeadsSelector().selectById(new Set<Id>{recordId});
                System.debug('leadList   '+leadList);
                Mobile = leadList[0].Mobile_Number__c;
                lob = leadList[0].LOB__c;
            } else {
                loanAppList = [SELECT Id,Mobile__c,Loan_Application__r.LOB__c FROM Loan_Applicant__c WHERE Loan_Application__c=:recordId AND Applicant_Type__c=:UB_ConstantsUtil.APPLICANT] ;
                Mobile = loanAppList[0].Mobile__c;
                System.debug('loanAppList   '+loanAppList);
                lob = loanAppList[0].Loan_Application__r.LOB__c;
            }
            System.debug('MobileMobile  '+Mobile);
            Reject_Reason_Master__mdt rejectMdt = [SELECT Id,TemplateId__c FROM Reject_Reason_Master__mdt WHERE LOB__c=:lob LIMIT 1];
            System.debug('rejectMdt  '+rejectMdt);
            UB_SmsApi smsApi = new UB_SmsApi();
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
            smsApi.service = new UB_HTTPCalloutService('SMS_Api');
            smsApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
            // passing hard coded value as for now we don't have template code.
            String requestJson = '{"RequestMessage":{"Header":{"PartnerID":"' + smsApi.service.getExtraParameter('PartnerID') + '","TraceId ":"' + smsApi.service.getExtraParameter('TraceId') +  '","JwtAuthToken":"'  + smsApi.service.getExtraParameter('JwtAuthToken') + '","SendDateTime":"'  + smsApi.service.getExtraParameter('SendDateTime') +  '","RemoteIPAddress":"' + smsApi.service.getExtraParameter('RemoteIPAddress') + '"},"Payload":{"SMSData":{"RECIPIENT_MOBILE_NUMBER":"' + Mobile +   '","RECIPIENT_EMAIL_ID":"","OTP_CODE":"","OTP_REFRENCE_NUMBER":"","TEMPLATE_CODE":"' + smsApi.service.getExtraParameter('TEMPLATE_CODE') +  '","HMAC":"","REMARKS":"102","BENEFICIARY_NAME":"","BENEFICIARY_ACCOUNT_NUMBER":"","COOLING_PERIOD_TIME":"","BENE_FULL_NAME":"","LIMIT":"","PAYEE_ACCT_NO":"","TRANSFER_AMOUNT":"","LINK":"","SAVINGS_ACCT_NO":"","MESSAGE_ID":"","DEBIT_CARD_NO":"","PERSONAL_LOAN_APL_NO":"","LOAN_AMOUNT":""}}}}';
            System.debug('requestJson   '+requestJson);

            smsApi.service.setRequestBody(requestJson);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = smsApi.service.sendRequest();
            System.debug('responeObj   '+responeObj);
            system.debug( 'RESPONSE BODY - ' + responeObj.getBody());
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                smsApi.service.getEndpointURL(), 
                String.valueOf(smsApi.service.getHeaderParameters()), 
                smsApi.service.getRequestMethod(), 
                requestJson, 
                responeObj.getBody(), 
                responeObj.getStatusCode(), 
                UB_SmsApi.class.getName(), 
                recordId, 
                Id.valueOf(recordId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'SMS API',
                lob
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            } 
        } catch(Exception e) {
            System.debug('Exception--->'+e.getMessage());
            System.debug('ERROR LINE NUMBER--->'+e.getLineNumber());
            // call method to create ExceptionLogRecord
            UB_CommonUtil.createExceptionLogRecord(e, lob);
        }

    }
}