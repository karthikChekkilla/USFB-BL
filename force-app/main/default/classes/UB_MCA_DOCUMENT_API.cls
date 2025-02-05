/**
* @File Name          : UB_MCA_DOCUMENT_API.cls
* @Description        : API to send email to the current logged in User for MCA Documents.
* @Author             : Mansur Alam
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0        291-07-2024               Mansur                  Initial Version
*/
public class UB_MCA_DOCUMENT_API {
    UB_HTTPCalloutService service;
    @future(callout = true)
    public static void callMcaApi (Id lafId){
        List<Loan_Applicant__c> updateApplicantList = new List<Loan_Applicant__c>();
        List<Verification__c> insertVerifyRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
        //getting logged in user detail
        Id userId =UserInfo.getUserId(); 
        User loggedInUser = [SELECT Id,Email  FROM User WHERE Id =: userId];
        system.debug(loggedInUser);
        try{
            List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().getNonIndApplicants(new Set<Id>{lafId},BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE);
            System.debug('loanAppList>> ' + loanAppList);
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            
            if(String.isNotBlank(accessToken) && String.isNotBlank(loanAppList[0].id) ){
                UB_MCA_DOCUMENT_API mca_docs = new UB_MCA_DOCUMENT_API();
                mca_docs.service = new UB_HTTPCalloutService('MCA_DOCUMENT_API');
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('entityId',loanAppList[0].id);
                
                if(String.isNotBlank(mca_docs.service.getExtraParameter('consent'))){
                    gen.writeStringField('consent',mca_docs.service.getExtraParameter('consent'));
                }
                if(String.isNotBlank(mca_docs.service.getExtraParameter('webhook'))){
                    gen.writeStringField('webhook',mca_docs.service.getExtraParameter('webhook'));
                }
                if(loggedInUser != null){
                    if(String.isNotBlank(loggedInUser.Email)){
                        gen.writeStringField('notifyToEmail',loggedInUser.Email);
                    }
                }
                System.debug('CATEGORYREQUIRED>> ' + BL_ConstantsUtil.CATEGORYREQUIRED);
                // Write the empty array for documentsRequired
                gen.writeFieldName('documentsRequired');
                gen.writeStartArray();
                gen.writeEndArray();
                
                // Write the array for categoryRequired
                gen.writeFieldName('categoryRequired');
                gen.writeStartArray();
                if(BL_ConstantsUtil.CATEGORYREQUIRED.size() > 0){
                    for(String str : BL_ConstantsUtil.CATEGORYREQUIRED){
                        gen.writeString(str);
                    }
                }
                gen.writeEndArray();
                gen.writeEndObject();
                mca_docs.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                
                System.debug('URL params@@  '+mca_docs.service.getURLParameters());
                mca_docs.service.setRequestBody(gen.getAsString());  
                System.debug('Request@@@ '+gen.getAsString());
                HttpResponse response = mca_docs.service.sendRequest(); 
                System.debug('response@@@ '+response);
                System.debug('response## '+response.getBody());
                Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('mapResponseResult## '+ mapResponseResult);
                
                //create verification record
                System.debug('>>>>>>>>> '+lafId + ' ' +BL_ConstantsUtil.MCA_DOCUMENTS_VERIFICATION_RECORD_TYPE + ' ' +BL_ConstantsUtil.COMPLETEDSTATUS );
                Verification__c verify = UB_CommonUtil.createVerfication(lafId, BL_ConstantsUtil.MCA_DOCUMENTS_VERIFICATION_RECORD_TYPE, BL_ConstantsUtil.COMPLETEDSTATUS);
                verify.Loan_Applicant__c  = loanAppList[0].Id;
                System.debug('verify@@ '+verify);
                if(response.getStatusCode() == 200){
                    if(mapResponseResult.keySet().size() > 0 ){
                        verify.Status__c = BL_ConstantsUtil.COMPLETEDSTATUS;
                    }else{
                        verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                        verify.Status__c = BL_ConstantsUtil.FAILED_STATUS;
                    }
                }else{
                    verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                    verify.Status__c = BL_ConstantsUtil.FAILED_STATUS;
                }
                insertVerifyRecords.add(verify);
                
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    mca_docs.service.getEndpointURL(), 
                    String.valueOf(mca_docs.service.getHeaderParameters()), 
                    mca_docs.service.getRequestMethod(), 
                    gen.getAsString(), 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_MCA_DOCUMENT_API.class.getName(), 
                    lafId, 
                    Id.valueOf(lafId).getSObjectType().getDescribe().getName(), 
                    BL_ConstantsUtil.REST_API_TYPE,
                    'MCA DOCUMENT API',
                    BL_ConstantsUtil.LOB_BL
                );
                if(mapResponseResult.containsKey('status')){
                    apiLogger.Status__c = (String) String.valueOf(mapResponseResult.get('status'));
                }
                createLogList.add(apiLogger);
                
                if(!createLogList.isEmpty() && createLogList.size() > 0){
                    system.debug('createLogList for logger> ' + createLogList);
                    UB_API_LoggerUtility.insertRecords(createLogList);
                }
                
            }
        }catch(Exception e) {
            Verification__c verify = UB_CommonUtil.createVerfication(lafId, BL_ConstantsUtil.MCA_DOCUMENTS_VERIFICATION_RECORD_TYPE, BL_ConstantsUtil.COMPLETEDSTATUS);
            verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
            verify.Status__c = BL_ConstantsUtil.FAILED_STATUS;
            insertVerifyRecords.add(verify);
            System.debug('Exception@@'+e.getMessage());   
            System.debug('Exception@@'+e.getLineNumber()); 
            UB_CommonUtil.createExceptionLogRecord(e, BL_ConstantsUtil.LOB_BL);
        }
        
        if(insertVerifyRecords.size()>0){
            insertVerifyRecords = UB_VerificationUtility.insertRecords(insertVerifyRecords);
            updateApplicantList.add(new Loan_Applicant__c(Id = lafId, MCA_Document_Verification__c = insertVerifyRecords[0].Id));
            update updateApplicantList;
        }
    }
}