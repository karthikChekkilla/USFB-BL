/**
* @File Name          : UB_ConsentValueFirstApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         20-05-2024            Zafaruddin         Initial Version

**/

public with sharing class UB_ConsentValueFirstApi {

    UB_HTTPCalloutService service;

    @AuraEnabled
    public static string checkCustomerConsent(String leadId){
        try {
            if(String.isNotBlank(leadId)) {
                String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
                UB_ConsentValueFirstApi.getCustomerConsent(leadId,accessToken);
                return 'success';
            }
        } catch (Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            return e.getMessage();
        }
        return 'Please connect with System Admin, Internal Error.';
    }


    @future(callout = true)
    public static void getCustomerConsent (Id customerId, String accessToken){
        String sObjName = customerId.getSObjectType().getDescribe().getName();
        List<Loan_Applicant__c> loanAppList = new List<Loan_Applicant__c> ();
        List<Loan_Application__c> applicationList = new List<Loan_Application__c> ();
        List<Lead__c> leadList = new List<Lead__c> ();
        String RequestJson;
        UB_ConsentValueFirstApi consentApi = new UB_ConsentValueFirstApi();
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        Verification__c verifyRecord = new Verification__c();
        consentApi.service = new UB_HTTPCalloutService('Consent_Api_Value_First');
        consentApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
        Savepoint sp;
        String LOB = UB_ConstantsUtil.LOB_CV; 
        try {
            if(sObjName == 'Loan_Applicant__c') {
                loanAppList= new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
                applicationList = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanAppList[0].Loan_Application__c});
                LOB = applicationList[0].LOB__c;
                if(LOB != UB_ConstantsUtil.LOB_BL){
                    RequestJson = '{"@VER":"1.2","USER":{"@CH_TYPE":"4","@UNIXTIMESTAMP":""},"SMS":[{"@UDH":"0","@CODING":"1","@TEXT":"","@TEMPLATEINFO":"' + consentApi.service.getExtraParameter('TEMPLATEINFO') + '~' + applicationList[0].Product__c   + '~' + applicationList[0].Amount__c  + '~' + applicationList[0].Loan_Period__c + '","@BTN_PAYLOAD0":"SFDC_CV","@BTN_PAYLOAD1":"SFDC_CV","@PROPERTY":"0","@MSGTYPE":"3","@MEDIADATA":"'+ System.Label.consentValueFirstUrl  +'","@TYPE":"' + 'document' + '~' + 'USFB T&C' + '","@ID":"'+ applicationList[0].Id +'","ADDRESS":[{"@FROM":"' + consentApi.service.getExtraParameter('FROM') +'","@TO":"' + loanAppList[0].Mobile__c+ '","@SEQ":"1","@TAG":"some clientside random data"}]}]}';
                }else{
                    if(applicationList[0].Lead__c != null){
                        RequestJson = '{"@VER":"1.2","USER":{"@CH_TYPE":"4","@UNIXTIMESTAMP":""},"SMS":[{"@UDH":"0","@CODING":"1","@TEXT":"","@TEMPLATEINFO":"' + consentApi.service.getExtraParameter('TEMPLATEINFO') + '~' + applicationList[0].BL_Product_Name__c   + '~' + applicationList[0].Lead__r.Amount__c  + '~' + applicationList[0].Lead__r.Loan_Period__c + '","@BTN_PAYLOAD0":"SFDC_CV","@BTN_PAYLOAD1":"SFDC_CV","@PROPERTY":"0","@MSGTYPE":"3","@MEDIADATA":"'+ System.Label.consentValueFirstUrl  +'","@TYPE":"' + 'document' + '~' + 'USFB T&C' + '","@ID":"'+ applicationList[0].Id +'","ADDRESS":[{"@FROM":"' + consentApi.service.getExtraParameter('FROM') +'","@TO":"' + loanAppList[0].Mobile__c+ '","@SEQ":"1","@TAG":"some clientside random data"}]}]}';
                    }
                }
            } else {
                leadList = new UB_LeadsSelector().selectById(new Set<Id>{customerId});
                System.debug('LEADDDDDD  '+leadList);
            	LOB = leadList[0].LOB__c;
                if(LOB != UB_ConstantsUtil.LOB_BL){
                    RequestJson = '{"@VER":"1.2","USER":{"@CH_TYPE":"4","@UNIXTIMESTAMP":""},"SMS":[{"@UDH":"0","@CODING":"1","@TEXT":"","@TEMPLATEINFO":"' + consentApi.service.getExtraParameter('TEMPLATEINFO') + '~' + leadList[0].Product_Category__c + ' Loan'  + '~' + leadList[0].Amount__c  + '~' + leadList[0].Loan_Period__c  + '","@BTN_PAYLOAD0":"SFDC_CV","@BTN_PAYLOAD1":"SFDC_CV","@PROPERTY":"0","@MSGTYPE":"3","@MEDIADATA":"'+ System.Label.consentValueFirstUrl  +'","@TYPE":"' + 'document' + '~' +'USFB T&C'+ '","@ID":"'+ leadList[0].Id +'","ADDRESS":[{"@FROM":"' + consentApi.service.getExtraParameter('FROM') +'","@TO":"' + leadList[0].Mobile_Number__c+ '","@SEQ":"1","@TAG":"some clientside random data"}]}]}';
                }else{
                    RequestJson = '{"@VER":"1.2","USER":{"@CH_TYPE":"4","@UNIXTIMESTAMP":""},"SMS":[{"@UDH":"0","@CODING":"1","@TEXT":"","@TEMPLATEINFO":"' + consentApi.service.getExtraParameter('TEMPLATEINFO') + '~' + leadList[0].Product_Category__c + '~' + leadList[0].Amount__c  + '~' + leadList[0].Loan_Period__c  + '","@BTN_PAYLOAD0":"SFDC_CV","@BTN_PAYLOAD1":"SFDC_CV","@PROPERTY":"0","@MSGTYPE":"3","@MEDIADATA":"'+ System.Label.consentValueFirstUrl  +'","@TYPE":"' + 'document' + '~' +'USFB T&C'+ '","@ID":"'+ leadList[0].Id +'","ADDRESS":[{"@FROM":"' + consentApi.service.getExtraParameter('FROM') +'","@TO":"' + leadList[0].Mobile_Number__c+ '","@SEQ":"1","@TAG":"some clientside random data"}]}]}';
                }
            }

            consentApi.service.setRequestBody(RequestJson);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = consentApi.service.sendRequest();
            String JSONResponse = responeObj.getBody();//res.getBody();
            
            Map<String,Object> ResponseMap = (Map<String,Object>)JSON.deserializeUntyped(JSONResponse);
            if(ResponseMap.get('MESSAGEACK') != NULL) {
                ResponseMap = (Map<String,Object>)ResponseMap.get('MESSAGEACK');
                if(ResponseMap.get('GUID') != NULL) {
                    API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                        consentApi.service.getEndpointURL(), 
                        String.valueOf(consentApi.service.getHeaderParameters()), 
                        consentApi.service.getRequestMethod(), 
                        RequestJson, 
                        responeObj.getBody(), 
                        responeObj.getStatusCode(), 
                        UB_ConsentValueFirstApi.class.getName(), 
                        customerId, 
                        Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                        UB_ConstantsUtil.REST_API_TYPE,
                        'Consent API',
                        LOB
                        );
                    if(apiLogger != NULL) {
                        insert apiLogger;
                        System.debug('apiLogger  '+apiLogger);
                    }
                    
                    ResponseMap = (Map<String,Object>)ResponseMap.get('GUID');
                    if(sObjName == 'Loan_Applicant__c') {
                        verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CONSENT_CHECK_RECORD_TYPE,UB_ConstantsUtil.IN_PROGRESS_STATUS);
                    } else {
                        verifyRecord = UB_CommonUtil.createVerfication(null, UB_ConstantsUtil.CONSENT_CHECK_RECORD_TYPE,UB_ConstantsUtil.IN_PROGRESS_STATUS);
                        verifyRecord.Lead__c = customerId;
                        update new Lead__c(Id = customerId, Consent_Received__c	= false,
                            GUID__c = String.valueOf(ResponseMap.get('GUID')),
                            SUBMIT_DATE__c = String.valueOf(ResponseMap.get('SUBMITDATE'))
                        ); 
                    }
                    verifyRecord.SUBMIT_DATE__c = String.valueOf(ResponseMap.get('SUBMITDATE'));
                    verifyRecord.GUID__c = String.valueOf(ResponseMap.get('GUID'));
                    insert verifyRecord;
                    if(sObjName == 'Loan_Applicant__c') {
                        update new Loan_Applicant__c(Id = customerId, Consent_Verification__c = verifyRecord.Id); 
                    }
                }          
            } else {
                if(sObjName == 'Loan_Applicant__c') {
                    verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.DEDUPE_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                    verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
                    insert verifyRecord;
                    update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
                }
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, LOB);
        }
    }
}