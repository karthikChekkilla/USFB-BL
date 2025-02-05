/**
* @File Name          : UB_CFR_API.cls
* @Description        : API to check CFR Information via PAN status of customer.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         31-05-2024               Mohit                 Initial Version
* 1.1         12-06-2024               Mohit                 Show Fraud Information on Verification record
*/
public with sharing class UB_CFR_API {
    UB_HTTPCalloutService service;
    
    public static void fetchServices (Id customerId){
        Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
        List<Verification__c> insertRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        //Savepoint sp = Database.setSavepoint();
        try{
            List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            
            if(String.isNotBlank(accessToken)){
                UB_CFR_API cfrAPI = new UB_CFR_API();
                cfrAPI.service = new UB_HTTPCalloutService('CFR_API');
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartArray();
                gen.writeStartObject();
                if(String.isNotBlank(cfrAPI.service.getExtraParameter('searchType'))){
                    gen.writeStringField('searchType',cfrAPI.service.getExtraParameter('searchType'));
                }
                gen.writeStringField('value',String.isNotBlank(loanAppList[0].Pan_Number__c) ? loanAppList[0].Pan_Number__c : '');
                if(String.isNotBlank(cfrAPI.service.getExtraParameter('operatorType'))){
                    gen.writeStringField('operatorType',cfrAPI.service.getExtraParameter('operatorType'));
                }
                gen.writeEndObject();
                gen.writeEndArray();
                
                cfrAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                cfrAPI.service.setRequestBody(gen.getAsString()); 
                HttpResponse response = new HttpResponse();
                if(cfrAPI.service.calloutMetadata.Active__c){
                    response = cfrAPI.service.sendRequest();
                }else{
                    response.setStatusCode(200);
                    response.setBody(cfrAPI.service.calloutMetadata.Mock_Response__c);
                }
                Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CFR_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.COMPLETEDSTATUS);
                if(response.getStatusCode() == 200){
                    if(mapResponseResult.keySet().size() > 0 && !mapResponseResult.values().isEmpty()){
                        if(mapResponseResult.containsKey('data')){
                            List<Object> dataResultList = (List<Object>) mapResponseResult.get('data');
                            if(dataResultList.size() > 0 && !dataResultList.isEmpty()){
                                verify.CFR_Status__c = UB_ConstantsUtil.FRAUD_FOUND;
                                verify.CFR_Fraud_Information__c = response.getBody();
                            }else{
                                verify.CFR_Status__c = UB_ConstantsUtil.FRAUD_NOT_FOUND;
                            }
                        }else{
                            verify.CFR_Status__c = UB_ConstantsUtil.FRAUD_NOT_FOUND;
                        }
                    }
                }else{
                    verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                    verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
                }
                
                insertRecords.add(verify);
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    cfrAPI.service.getEndpointURL(), 
                    String.valueOf(cfrAPI.service.getHeaderParameters()), 
                    cfrAPI.service.getRequestMethod(), 
                    gen.getAsString(), 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_CFR_API.class.getName(), 
                    customerId, 
                    Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'CFR API',
                    UB_ConstantsUtil.LOB_CV
                );
                createLogList.add(apiLogger);
                
                if(!createLogList.isEmpty() && createLogList.size() > 0){
                    UB_API_LoggerUtility.insertRecords(createLogList);
                }
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            //Database.releaseSavepoint(sp);
            Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CFR_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.FAILED_STATUS);
			verify.Failed_Reason__c = e.getMessage();
            insertRecords.add(verify); 
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        if(!insertRecords.isEmpty() && insertRecords.size() > 0){
            insertRecords = UB_VerificationUtility.insertRecords(insertRecords);
            UB_LoanApplicantUtility.updateRecords(new List<Loan_Applicant__c>{new Loan_Applicant__c(Id = customerId, CFR_Verification__c = insertRecords[0].Id)});
        }
    }
    
    /**
	* @Description  : Fetch Fraud Information and display on verification record
	* @Version      : 1.1
    * @Dependencies : ub_FraudInformation LWC 
	*/
    @AuraEnabled(cacheable=true)
    public static List<Object> fetchFraudDetails(String verificationId){
        if(String.isNotBlank(verificationId)){
            List<Verification__c> verfyList = new UB_VerificationsSelector().selectByIdWithFraudInfo(new Set<Id>{verificationId});
            if(!verfyList.isEmpty() && verfyList.size() > 0){
                if(String.isNotBlank(verfyList[0].CFR_Fraud_Information__c)){
                    Map<String,Object> mapFraudInfoJSON = (Map<String,Object>) JSON.deserializeUntyped(verfyList[0].CFR_Fraud_Information__c);
                    if(mapFraudInfoJSON.keySet().size() > 0 && !mapFraudInfoJSON.values().isEmpty()){
                        if(mapFraudInfoJSON.containsKey('data')){
                            List<Object> fraudInfoList = (List<Object>) mapFraudInfoJSON.get('data');
                            if(!fraudInfoList.isEmpty() && fraudInfoList.size() > 0){
                                return fraudInfoList;
                            }
                        }
                    }
                }
            }
        }
        return null;
    }
}