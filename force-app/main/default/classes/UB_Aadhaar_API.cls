/**
* @File Name          : UB_Aadhar_API.cls
* @Description        : API to check Aadhar status for the customer.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
* 1.1         30-05-2024               Mohit                 Aadhaar Number Masking
* 1.2         31-05-2024               Mohit                 Aadhaar Number Unmasking
*/
public without sharing class UB_Aadhaar_API {
    UB_HTTPCalloutService service;
    
    //Commented after we changed the approach for Aadhaar masking. User needs to provide Aadhaar Number while initiating verification
    /*public class FlowInputs{
        @InvocableVariable
        public String aadhaarNumber;
        @InvocableVariable
        public String applicantId;
    }
    
    @InvocableMethod(Label='Aadhaar Number Masking')
    public static void fetchAadhaarUID(List<FlowInputs> flowRequest){
        if(!flowRequest.isEmpty() && flowRequest.size() > 0){
            if(String.isNotBlank(flowRequest[0].aadhaarNumber) && String.isNotBlank(flowRequest[0].applicantId)){
                if(!System.isFuture() && !System.isBatch()){
                    for(FlowInputs str : flowRequest){
                        aadhaarNumberMasking(str.applicantId, str.aadhaarNumber);
                    }
                }
            }
        }
    }*/
    
    @AuraEnabled
    public static String aadhaarNumberMasking(String customerId, String aadhaarNumber){
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        List<Loan_Applicant__c> applicantList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        String customToken = '';
        //Savepoint sp = Database.setSavepoint();
        try{
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            if(String.isNotBlank(accessToken)){
                UB_Aadhaar_API aadharAPI = new UB_Aadhaar_API();
                aadharAPI.service = new UB_HTTPCalloutService('Aadhaar_Number_Masking');
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('headers');
                gen.writeStartObject();
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('actor_type'))){
                    gen.writeStringField('actor_type',aadharAPI.service.getExtraParameter('actor_type'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('channel_code'))){
                    gen.writeStringField('channel_code',aadharAPI.service.getExtraParameter('channel_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('channel_version'))){
                    gen.writeStringField('channel_version',aadharAPI.service.getExtraParameter('channel_version'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('client_code'))){
                    gen.writeStringField('client_code',aadharAPI.service.getExtraParameter('client_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('client_ip'))){
                    gen.writeStringField('client_ip',aadharAPI.service.getExtraParameter('client_ip'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('function_code'))){
                    gen.writeStringField('function_code',aadharAPI.service.getExtraParameter('function_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('function_sub_code'))){
                    gen.writeStringField('function_sub_code',aadharAPI.service.getExtraParameter('function_sub_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('location'))){
                    gen.writeStringField('location',aadharAPI.service.getExtraParameter('location'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('operation_mode'))){
                    gen.writeStringField('operation_mode',aadharAPI.service.getExtraParameter('operation_mode'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('run_mode'))){
                    gen.writeStringField('run_mode',aadharAPI.service.getExtraParameter('run_mode'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('session_info'))){
                    gen.writeStringField('session_info',aadharAPI.service.getExtraParameter('session_info'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('stan'))){
                    gen.writeStringField('stan',aadharAPI.service.getExtraParameter('stan'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('sub_client_code'))){
                    gen.writeStringField('sub_client_code',aadharAPI.service.getExtraParameter('sub_client_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('transmission_datetime'))){
                    gen.writeStringField('transmission_datetime',aadharAPI.service.getExtraParameter('transmission_datetime'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('user_handle_type'))){
                    gen.writeStringField('user_handle_type',aadharAPI.service.getExtraParameter('user_handle_type'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('user_handle_value'))){
                    gen.writeStringField('user_handle_value',aadharAPI.service.getExtraParameter('user_handle_value'));
                }
                gen.writeEndObject();
                gen.writeFieldName('request');
                gen.writeStartObject();
                gen.writeStringField('aadhaar_number',aadhaarNumber);
                gen.writeStringField('document','');
                gen.writeStringField('document_format','');
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('purpose'))){
                    gen.writeStringField('purpose',aadharAPI.service.getExtraParameter('purpose'));
                }
                gen.writeStringField('uid_token','');
                gen.writeEndObject();
                gen.writeEndObject();
                
                aadharAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                aadharAPI.service.setRequestBody(gen.getAsString());

                HttpResponse response = aadharAPI.service.sendRequest(); 
                if(response.getStatusCode() == 200){
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('response_data')){
                        Map<String,Object> mapResponseData = (Map<String,Object>) mapResponseResult.get('response_data');
                        if(mapResponseData.keySet().size() > 0 && mapResponseData.containsKey('custom_token')){
                            customToken = (String) String.valueOf(mapResponseData.get('custom_token'));
                        }
                    }
                }
                
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    aadharAPI.service.getEndpointURL(), 
                    String.valueOf(aadharAPI.service.getHeaderParameters()), 
                    aadharAPI.service.getRequestMethod(), 
                    gen.getAsString().replace(aadhaarNumber,customToken), 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_Aadhaar_API.class.getName(), 
                    customerId, 
                    Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'AADHAAR Masking UID',
                    applicantList[0].Loan_Application__r.LOB__c
                );
                createLogList.add(apiLogger);
            }
            if(!createLogList.isEmpty() && createLogList.size() > 0){
                UB_API_LoggerUtility.insertRecords(createLogList);
            }
            return String.isNotBlank(customToken) ? customToken : 'System Error: Generate access token API failed.';
        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, applicantList[0].Loan_Application__r.LOB__c);
            return e.getMessage();
        }
    }
    
    public static String aadhaarNumberUnmasking(String aadhaarNumber){
        //Savepoint sp = Database.setSavepoint();
        try{
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            if(String.isNotBlank(accessToken)){
                UB_Aadhaar_API aadharAPI = new UB_Aadhaar_API();
                aadharAPI.service = new UB_HTTPCalloutService('Aadhaar_Number_Unmasking');
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeFieldName('headers');
                gen.writeStartObject();
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('actor_type'))){
                    gen.writeStringField('actor_type',aadharAPI.service.getExtraParameter('actor_type'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('channel_code'))){
                    gen.writeStringField('channel_code',aadharAPI.service.getExtraParameter('channel_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('channel_version'))){
                    gen.writeStringField('channel_version',aadharAPI.service.getExtraParameter('channel_version'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('client_code'))){
                    gen.writeStringField('client_code',aadharAPI.service.getExtraParameter('client_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('client_ip'))){
                    gen.writeStringField('client_ip',aadharAPI.service.getExtraParameter('client_ip'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('function_code'))){
                    gen.writeStringField('function_code',aadharAPI.service.getExtraParameter('function_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('function_sub_code'))){
                    gen.writeStringField('function_sub_code',aadharAPI.service.getExtraParameter('function_sub_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('location'))){
                    gen.writeStringField('location',aadharAPI.service.getExtraParameter('location'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('operation_mode'))){
                    gen.writeStringField('operation_mode',aadharAPI.service.getExtraParameter('operation_mode'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('run_mode'))){
                    gen.writeStringField('run_mode',aadharAPI.service.getExtraParameter('run_mode'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('stan'))){
                    gen.writeStringField('stan',aadharAPI.service.getExtraParameter('stan'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('sub_client_code'))){
                    gen.writeStringField('sub_client_code',aadharAPI.service.getExtraParameter('sub_client_code'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('transmission_datetime'))){
                    gen.writeStringField('transmission_datetime',aadharAPI.service.getExtraParameter('transmission_datetime'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('user_handle_type'))){
                    gen.writeStringField('user_handle_type',aadharAPI.service.getExtraParameter('user_handle_type'));
                }
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('user_handle_value'))){
                    gen.writeStringField('user_handle_value',aadharAPI.service.getExtraParameter('user_handle_value'));
                }
                gen.writeEndObject();
                gen.writeFieldName('request');
                gen.writeStartObject();
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('token_type'))){
                    gen.writeStringField('token_type',aadharAPI.service.getExtraParameter('token_type'));
                }
                gen.writeStringField('token_value',aadhaarNumber);
                if(String.isNotBlank(aadharAPI.service.getExtraParameter('purpose'))){
                    gen.writeStringField('purpose',aadharAPI.service.getExtraParameter('purpose'));
                }
                gen.writeEndObject();
                gen.writeEndObject();
                
                aadharAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                aadharAPI.service.setRequestBody(gen.getAsString());
                HttpResponse response = aadharAPI.service.sendRequest(); 
                System.debug('response@@@'+response.getBody());
                if(response.getStatusCode() == 200){
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('response_data')){
                        Map<String,Object> mapResponseData = (Map<String,Object>) mapResponseResult.get('response_data');
                        if(mapResponseData.keySet().size() > 0 && mapResponseData.containsKey('aadhaar_number')){
                            return (String) String.valueof(mapResponseData.get('aadhaar_number')); 
                        }
                    }
                }
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        return null;
    }
    
    @AuraEnabled
    public static String sendAadhaarOTP (Id customerId, String maskedAadhaarNumber){
        List<Loan_Applicant__c> applicantList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        List<Verification__c> createVerifyList = new List<Verification__c>();
        String customerAadhaar = '';
        //Savepoint sp = Database.setSavepoint();
        try{            
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            if(String.isNotBlank(accessToken)){
                UB_Aadhaar_API aadharAPI = new UB_Aadhaar_API();
                aadharAPI.service = new UB_HTTPCalloutService('Aadhaar_OTP_API');
                if(String.isNotBlank(maskedAadhaarNumber)){
                    customerAadhaar = aadhaarNumberUnmasking(maskedAadhaarNumber);
                }
                
                if(customerAadhaar != null && String.isNotBlank(customerAadhaar)){
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                    gen.writeStringField('aadhaarNo',customerAadhaar);
                    gen.writeStringField('consent','Y');
                    gen.writeFieldName('clientData');
                    gen.writeStartObject();
                    gen.writeStringField('caseId',customerId);
                    gen.writeEndObject();
                    gen.writeEndObject();
                    
                    aadharAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                    aadharAPI.service.setRequestBody(gen.getAsString());
                    
                    HttpResponse response = aadharAPI.service.sendRequest(); 
                    Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.OTP_SENT);
                    if(response.getStatusCode() == 200){
                        Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                        if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('requestId')){
                            verify.Aadhaar_Number__c = maskedAadhaarNumber;
                            verify.Aadhaar_OTP_Request_ID__c = (String) String.valueOf(mapResponseResult.get('requestId'));
                        }
                    }else{
                        verify.Status__c = UB_ConstantsUtil.OTP_ATTEMP_FAILED;
                        verify.Failed_Reason__c = response.getBody();
                    }
                    system.debug('verify'+verify);
                    createVerifyList.add(verify);
                    
                    API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                        aadharAPI.service.getEndpointURL(), 
                        String.valueOf(aadharAPI.service.getHeaderParameters()), 
                        aadharAPI.service.getRequestMethod(), 
                        gen.getAsString().replace(customerAadhaar,maskedAadhaarNumber), 
                        response.getBody(), 
                        response.getStatusCode(), 
                        UB_Aadhaar_API.class.getName(), 
                        customerId, 
                        Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                        UB_ConstantsUtil.REST_API_TYPE,
                        'AADHAAR OTP',
                        applicantList[0].Loan_Application__r.LOB__c
                    );
                    createLogList.add(apiLogger);
                    if(!createLogList.isEmpty() && createLogList.size() > 0){
                        UB_API_LoggerUtility.insertRecords(createLogList);
                    }
                }else{
                    Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('AadhaarAPIStatus');
                    return messageConfigMap.get('Aadhaar_Unmasked_API_Fail').Message__c;
                }
            }else{
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('AadhaarAPIStatus');
				return messageConfigMap.get('Access_Token_API_Fail').Message__c;
            }            
        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, applicantList[0].Loan_Application__r.LOB__c);
            Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.FAILED_STATUS);
            verify.Failed_Reason__c = e.getMessage();
            createVerifyList.add(verify);
            return e.getMessage();
        }
        if(!createVerifyList.isEmpty() && createVerifyList.size() > 0){
            insert createVerifyList;
            update new Loan_Applicant__c(Id = customerId, Aadhaar_Verification__c = createVerifyList[0].Id);
            if(!applicantList.isEmpty() && applicantList.size() > 0 && String.isNotBlank(applicantList[0].Mobile__c)){
                if(createVerifyList[0].Status__c != UB_ConstantsUtil.FAILED_STATUS){
                	sendOTPPublicLinkViaWhatsapp(JSON.serialize(createVerifyList[0]), applicantList[0].Mobile__c);
                    return UB_ConstantsUtil.SUCCESS_STATUS;
                }
            }
        }
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('AadhaarAPIStatus');
        return messageConfigMap.get('Aadhaar_OTP_API_Failed').Message__c;
    }
    
    //@Description: This Method is used to check the Otp Status If Otp has been arrived for the Applicant or Co-Applicant under Loan Application
    @AuraEnabled
    public static String fetchOtpStatus(String verificationId){
        String otpStatus;
        List<Verification__c> verificationList = new UB_VerificationsSelector().selectById(new Set<Id>{verificationId});
        try {
            Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
            String[] authenticationForList = new List<String>();
            if(String.isnotBlank(verificationId) && String.isnotEmpty(verificationId)){
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('AadhaarAPIStatus');
                if(!verificationList.isEmpty() && verificationList.size() > 0){
                    for(Verification__c obj : verificationList){
                        if(String.isNotBlank(obj.Status__c)){
                            if(obj.Status__c == UB_ConstantsUtil.FAILED_STATUS){
                                otpStatus = messageConfigMap.get('Aadhaar_API_Fail').Message__c;
                            }if(obj.Status__c == UB_ConstantsUtil.OTP_ATTEMP_FAILED){
                                otpStatus = messageConfigMap.get('Aadhaar_API_Attempt_Fail').Message__c;
                            }if(obj.Status__c == UB_ConstantsUtil.COMPLETEDSTATUS || obj.Status__c == UB_ConstantsUtil.IN_PROGRESS_STATUS){
                                otpStatus = messageConfigMap.get('Aadhaar_API_Link_Expired').Message__c;
                            }else{
                                otpStatus = UB_ConstantsUtil.SUCCESS_STATUS;
                            }
                        }else{
                            otpStatus = messageConfigMap.get('Aadhaar_API_Link_Expired').Message__c;
                        }
                    }
                }else{
                    otpStatus = errorMessageConfigMap.get('SystemError').Message__c;
                }
            }else{
                otpStatus = errorMessageConfigMap.get('SystemError').Message__c;
            }
        }catch(Exception e){
            System.debug('Fetch Otp Status Error :'+e.getMessage());
            System.debug('Fetch Otp StatusIn Line Number :'+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, verificationList[0].Loan_Applicant__r.Loan_Application__r.LOB__c);
        }
        System.debug('otpStatus'+otpStatus);
        return otpStatus;
    }
    
    //@Description: This Method is used to send the Aadhaar Otp Public Link via Whatsapp
    @future(callout = true)
    public static Void sendOTPPublicLinkViaWhatsapp(String verificationJson, String applicantMobile){
        List<Verification__c> updateRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        
        //Savepoint sp = Database.setSavepoint();
        try{            
            Verification__c verification = (Verification__c)JSON.deserialize(verificationJson, Verification__c.class);
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            
            if(String.isNotBlank(accessToken)){
                UB_Aadhaar_API aadharAPI = new UB_Aadhaar_API();
                aadharAPI.service = new UB_HTTPCalloutService('WhatsApp_Aadhaar_OTP_API');
                
                UB_ConsentRequestAPI.JSONRequest customWrapper = new UB_ConsentRequestAPI.JSONRequest();
                customWrapper.TEMPLATEINFO = aadharAPI.service.getExtraParameter('TEMPLATEINFO')+'~'+Label.CV_Portal_URL+'UB_AadhaarVerification?id='+verification.Id;
                customWrapper.ID           = verification.Loan_Applicant__c;
                customWrapper.MSGTYPE      = aadharAPI.service.getExtraParameter('MSGTYPE');
                customWrapper.A_FROM       = aadharAPI.service.getExtraParameter('FROM');
                customWrapper.A_TO         = '91'+applicantMobile;
                String requestBody = UB_ConsentRequestAPI.generateJSON(JSON.serialize(customWrapper));
                
                aadharAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                aadharAPI.service.setRequestBody(requestBody);
                
                HttpResponse response = aadharAPI.service.sendRequest(); 
                if(response.getStatusCode() == 200){
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('MESSAGEACK')){
                        Map<String,Object> mapResponseBody = (Map<String,Object>) mapResponseResult.get('MESSAGEACK');
                        if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('GUID')){
                            Verification__c verify = new Verification__c(Id = verification.Id);
                            verify.GUID__c = (String) String.valueOf(mapResponseResult.get('GUID'));
                            if(mapResponseResult.containsKey('SUBMITDATE')){
                                verify.GUID_Submit_Date__c = (String) String.valueOf(mapResponseResult.get('SUBMITDATE'));
                            }
                            updateRecords.add(verify);
                        }
                    }else{
                        updateRecords.add(new Verification__c(Id = verification.Id, Status__c = UB_ConstantsUtil.FAILED_STATUS, Failed_Reason__c = response.getBody()));
                    }
                }else{
                    updateRecords.add(new Verification__c(Id = verification.Id, Status__c = UB_ConstantsUtil.FAILED_STATUS, Failed_Reason__c = response.getBody()));
                }
                
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    aadharAPI.service.getEndpointURL(), 
                    String.valueOf(aadharAPI.service.getHeaderParameters()), 
                    aadharAPI.service.getRequestMethod(), 
                    requestBody, 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_Aadhaar_API.class.getName(), 
                    verification.Loan_Applicant__c, 
                    Id.valueOf(verification.Loan_Applicant__c).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'AADHAR OTP VIA WHATSAPP',
                    UB_ConstantsUtil.LOB_CV
                );
                createLogList.add(apiLogger);
                
                if(!createLogList.isEmpty() && createLogList.size() > 0){
                    UB_API_LoggerUtility.insertRecords(createLogList);
                }
            }else{
                updateRecords.add(new Verification__c(Id = verification.Id, Status__c = UB_ConstantsUtil.FAILED_STATUS));
            }
            if(!updateRecords.isEmpty() && updateRecords.size() > 0){
                UB_VerificationUtility.updateRecords(updateRecords);
            }
        }catch(Exception e){
            System.debug('Aadhaar Otp Public Link Error :'+e.getMessage());
            System.debug('Aadhaar Otp Public Line Number :'+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
    }
    
    @AuraEnabled
    public static String validateVerification(String verificationId, String otp){
        List<Verification__c> updateList = new List<Verification__c>();
        String[] authenticationForList = new List<String>();
        List<Verification__c> verificationList = new UB_VerificationsSelector().selectByIdWithParentInfo(new Set<Id>{verificationId});
        try{
            String statusCode;
            ResponseWrapper wrapperObj = new ResponseWrapper();
            List<Verification__c> updateVerfList = new List<Verification__c>();
            List<API_Logger__c> createLogList = new List<API_Logger__c>();
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
            if(String.isNotBlank(verificationId) && String.isNotBlank(accessToken)){
                if(!verificationList.isEmpty() && verificationList.size() > 0){
                    if(String.isNotBlank(verificationList[0].Status__c) && verificationList[0].Status__c == UB_ConstantsUtil.OTP_SENT){
                        String aadhaarNumber = aadhaarNumberUnmasking(verificationList[0].Aadhaar_Number__c);
                        if(aadhaarNumber != null && String.isNotBlank(aadhaarNumber)){
                            UB_Aadhaar_API aadharAPI = new UB_Aadhaar_API();
                            aadharAPI.service = new UB_HTTPCalloutService('Aadhaar_API');
                            
                            JSONGenerator gen = JSON.createGenerator(true);
                            gen.writeStartObject();
                            gen.writeStringField('otp',String.isNotBlank(otp) ? otp : '');
                            gen.writeStringField('aadhaarNo',aadhaarNumber);
                            gen.writeStringField('shareCode',aadharAPI.service.getExtraParameter('shareCode'));
                            if(String.isNotBlank(verificationList[0].Aadhaar_OTP_Request_ID__c)){
                                gen.writeStringField('requestId',verificationList[0].Aadhaar_OTP_Request_ID__c);
                            }else{
                                gen.writeStringField('requestId','');
                            }
                            gen.writeStringField('consent','Y');
                            gen.writeFieldName('clientData');
                            gen.writeStartObject();
                            if(verificationList[0].Loan_Applicant__c != null){
                                gen.writeStringField('caseId',verificationList[0].Loan_Applicant__c);
                            }else{
                                gen.writeStringField('caseId','');
                            }
                            gen.writeEndObject();
                            gen.writeEndObject();
                            
                            aadharAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                            aadharAPI.service.setRequestBody(gen.getAsString());
                            
                            HttpResponse response = aadharAPI.service.sendRequest(); 
                            System.debug('response@@@'+response.getBody());
                            Map<String,Object> mapResponseResult = new Map<String,Object>();
                            if(response.getStatusCode() == 200){
                                mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                                if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('result')){
                                    Map<String,Object> mapResultBody = (Map<String,Object>) (mapResponseResult.get('result'));
                                    if(mapResultBody.keySet().size() > 0 && mapResultBody.containsKey('dataFromAadhaar')){
                                        Map<String,Object> mapDataFromAadhar = (Map<String,Object>) (mapResultBody.get('dataFromAadhaar'));
                                        Verification__c verify = new Verification__c(Id = verificationId);
                                        if(mapDataFromAadhar.keySet().size() > 0){
                                            if(mapDataFromAadhar.containsKey('name')){
                                                verify.Aadhaar_Name__c = (String) String.valueOf(mapDataFromAadhar.get('name'));
                                            }
                                            if(mapDataFromAadhar.containsKey('dob')){
                                                verify.Aadhaar_DOB__c = (String) String.valueOf(mapDataFromAadhar.get('dob'));
                                            }
                                            if(mapDataFromAadhar.containsKey('address')){
                                                Map<String,Object> mapAadharAddress = (Map<String,Object>) (mapDataFromAadhar.get('address'));
                                                if(mapAadharAddress.keySet().size() > 0 && mapAadharAddress.containsKey('combinedAddress')){
                                                    verify.Aadhaar_Address__c = (String) String.valueOf(mapAadharAddress.get('combinedAddress'));
                                                }
                                            }
                                            verify.Status__c = UB_ConstantsUtil.COMPLETEDSTATUS;
                                        }else{
                                            verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
                                        }
                                        updateList.add(verify);
                                        wrapperObj.statusCode = response.getStatusCode();
                                        wrapperObj.ResponseMap = mapResponseResult;
                                    }else{
                                        wrapperObj.statusCode = response.getStatusCode();
                                        wrapperObj.ResponseMap = mapResponseResult;
                                    }
                                    
                                    if(!updateList.isEmpty() && updateList.size() > 0){
                                        update updateList;
                                    }
                                }else{
                                    wrapperObj.statusCode = response.getStatusCode();
                                    wrapperObj.ResponseMap = mapResponseResult;
                                }
                            }else{
                                wrapperObj.statusCode = response.getStatusCode();
                                wrapperObj.ResponseMap = mapResponseResult;
                            }
                            
                            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                                aadharAPI.service.getEndpointURL(), 
                                String.valueOf(aadharAPI.service.getHeaderParameters()), 
                                aadharAPI.service.getRequestMethod(), 
                                gen.getAsString().replace(aadhaarNumber,verificationList[0].Aadhaar_Number__c), 
                                response.getBody(), 
                                response.getStatusCode(), 
                                UB_Aadhaar_API.class.getName(), 
                                verificationId, 
                                Id.valueOf(verificationId).getSObjectType().getDescribe().getName(), 
                                UB_ConstantsUtil.REST_API_TYPE,
                                'AADHAAR API',
                                verificationList[0].Loan_Applicant__r.Loan_Application__r.LOB__c
                            );
                            createLogList.add(apiLogger);
                            
                            if(!createLogList.isEmpty() && createLogList.size() > 0){
                                UB_API_LoggerUtility.insertRecords(createLogList);
                            }
                        }else{
                            Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('AadhaarAPIStatus');
                            wrapperObj.statusCode = 400;
                            wrapperObj.ResponseMap = new Map<String,Object>{'error'=>messageConfigMap.get('Aadhaar_Unmasked_API_Fail').Message__c};
                        }
                    }else{
                        wrapperObj.statusCode = 400;
                        wrapperObj.ResponseMap = new Map<String,Object>{'error'=>'Unable to find verification record access.'};
                    }
                }else{
                    wrapperObj.statusCode = 400;
                    wrapperObj.ResponseMap = new Map<String,Object>{'error'=>'Unable to find verification record access.'};
                }
            }else{
                wrapperObj.statusCode = 400;
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('Access_Token');
                wrapperObj.ResponseMap = new Map<String,Object>{'error'=>messageConfigMap.get('Access_Token_Failed').Message__c};
            }
            return JSON.serialize(wrapperObj);
        }catch(Exception e){
            UB_CommonUtil.createExceptionLogRecord(e, verificationList[0].Loan_Applicant__r.Loan_Application__r.LOB__c);
        }
        return null;
    }
    
    public class AdhaarXmlOtpRequest {
        public String aadhaarNo {get; set;}
        public String consent {get; set;}
    }
    
    public class AdhaarXmlFileRequest {
        public String otp {get; set;}
        public String requestId {get; set;}
        public String aadhaarNo {get; set;}
        public String consent {get; set;}
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public Map<String,Object> ResponseMap;
        public ResponseWrapper(){
            statusCode = null;
            ResponseMap = new Map<String,Object>();
        }
    }
}