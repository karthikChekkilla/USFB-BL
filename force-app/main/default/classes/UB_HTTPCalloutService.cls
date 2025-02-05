/**
* @File Name          : UB_HTTPCalloutService.cls
* @Description        : Callout Framework Class.
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         28-03-2024            Zafaruddin         Initial Version
*/

public without sharing class UB_HTTPCalloutService {

    public UB_Callout_Framework__mdt calloutMetadata;

    String endpointURL, requestMethod, requestBody, requestCertificate, namedCredential,mockRespnse,host;
    Blob requestBodyAsBlob;
    Dom.Document requestBodyAsDocument;
    Integer requestTimeout;
    Boolean isCompressedRequest;
    Map<String, String> urlParametersMap;
    Map<String, String> headerParametersMap;
	Map<String, String> extraParametersMap;
    static final String TYPE_URL_PARAMETERS = 'URL_PARAMETERS';
    static final String TYPE_HEADER_PARAMETERS = 'HEADER_PARAMETERS';
	static final String TYPE_EXTRA_PARAMETERS = 'EXTRA_PARAMETERS';
	//
    HTTPRequest request;


	public String getmockRespnse() {
		return mockRespnse;
	}

	public void setmockRespnse(String mockRespnse) {
		this.mockRespnse = mockRespnse;
	}

    // added by chandan on 04/07/2024
 /*   public HTTPResponse generateReport(String transactionId) {
        return UB_Perfios_IntegrationUtil.generateReport(transactionId);
    }
    
     public HTTPResponse retrieveReport(String transactionId, String fileType) {
        return UB_Perfios_IntegrationUtil.retrieveReport(transactionId, fileType);
    }*/

	public String getEndpointURL() {
		return endpointURL;
	}

	public void setEndpointURL(String endpointURL) {
		this.endpointURL = endpointURL;
	}

	public String getRequestMethod() {
		return requestMethod;
	}

	public void setRequestMethod(String requestMethod) {
		this.requestMethod = requestMethod;
	}

	public String getRequestBody() {
		return requestBody;
	}

	public void setRequestBody(String requestBody) {
		this.requestBody = requestBody;
        system.debug('this.requestBody==>'+this.requestBody);
	}

	public Blob getRequestBodyAsBlob() {
		return requestBodyAsBlob;
	}

	public void setRequestBodyAsBlob(Blob requestBodyAsBlob) {
		this.requestBodyAsBlob = requestBodyAsBlob;
	}

	public Dom.Document getRequestBodyAsDocument() {
		return requestBodyAsDocument;
	}

	public void setRequestBodyAsDocument(Dom.Document requestBodyAsDocument) {
		this.requestBodyAsDocument = requestBodyAsDocument;
	}

	public String getRequestCertificate() {
		return requestCertificate;
	}
    
    public string getHostName(){
        return Host;
    }

	public void setRequestCertificate(String requestCertificate) {
		this.requestCertificate = requestCertificate;
	}

	public Integer getRequestTimeout() {
		return requestTimeout;
	}

	public void setRequestTimeout(Integer requestTimeout) {
		this.requestTimeout = requestTimeout;
	}
	
	// Added By Ajay : 02-03-2023
	public String getExtraParameter(String key) {
        return extraParametersMap.get(key);
    }

    public Map<String, String> getExtraParameters() {
        return extraParametersMap;
    }

    public void setExtraParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            extraParametersMap.put(key, value);
        }
    }

    public void removeExtraParameter(String key) {
        extraParametersMap.remove(key);
    }
	//////////////////////////////////////////////
	
    public String getHeaderParameter(String key) {
        return headerParametersMap.get(key);
    }

    public Map<String, String> getHeaderParameters() {
        return headerParametersMap;
    }

    public void setHeaderParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headerParametersMap.put(key, value);
        }
    }

    public void removeHeaderParameter(String key) {
        headerParametersMap.remove(key);
    }

    public String getURLParameter(String key) {
        return urlParametersMap.get(key);
    }

    public Map<String, String> getURLParameters() {
        return urlParametersMap;
    }

    public void setURLParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(key, value);
        } else if(String.isNotEmpty(key)) {
            urlParametersMap.put(key, value);
        }
    }

    public void removeURLParameter(String key) {
        urlParametersMap.remove(key);
    }

    public String customMetadataName { get; set; }
    
    public UB_HTTPCalloutService(String customMetadataName) {
        try {
            calloutMetadata = [Select Id,Active__c,HeaderParams__c,URL_Parameters__c,Named_Credential__c,Certificate_Name__c,Timeout_Time__c,Body__c,HTTP_Method__c,Mock_Response__c,Endpoint__c,Extra_Param_s__c,Host__c FROM UB_Callout_Framework__mdt WHERE DeveloperName =: customMetadataName];
                //UB_Callout_Framework__mdt.getInstance(customMetadataName);
        } catch (Exception ex) {
            throw ex;
        }
        initialize();
    }

    private void initialize() {
        urlParametersMap = new Map<String, String>();
        headerParametersMap = new Map<String, String>();
		extraParametersMap = new Map<String, String>();
		//
        if(calloutMetadata != null) {
            endpointURL = calloutMetadata.Endpoint__c;
            mockRespnse = calloutMetadata.Mock_Response__c;
            requestMethod = calloutMetadata.HTTP_Method__c;
            requestBody = calloutMetadata.Body__c;
            requestTimeout = Integer.valueOf(calloutMetadata.Timeout_Time__c);
            requestCertificate = calloutMetadata.Certificate_Name__c;
            namedCredential = calloutMetadata.Named_Credential__c;
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, calloutMetadata.URL_Parameters__c);
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, calloutMetadata.HeaderParams__c);
            setUrlOrHeaderParameters(TYPE_EXTRA_PARAMETERS, calloutMetadata.Extra_Param_s__c);
            host = calloutMetadata.Host__c;
        }
    }

    /*
    * This method is used to set URL or Header parameters from Custom Metadata
    */
    private void setUrlOrHeaderParameters(String parameterType, String parameterInfo) {
        if(String.isNotEmpty(parameterInfo)) {
            Map<String, String> parametersMap = new Map<String, String>();
            List<String> parameters = parameterInfo.split('\n');
            for(String urlParam : parameters) {
                List<String> keyValuePair = urlParam.trim().split(':');
                if(!keyValuePair.isEmpty()) {
                    if(keyValuePair.size() == 2) {
                        if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                            parametersMap.put(keyValuePair[0], keyValuePair[1]);
                        }
                    } else if(
                        (keyValuePair.size() == 1) &&
                        (parameterType != TYPE_HEADER_PARAMETERS)
                    ) {
                        if(String.isNotEmpty(keyValuePair[0])) {
                            parametersMap.put(keyValuePair[0], '');
                        }
                    }
                }
            }
            if(parameterType == TYPE_URL_PARAMETERS) {
                urlParametersMap.putAll(parametersMap);
            } else if(parameterType == TYPE_HEADER_PARAMETERS) {
                headerParametersMap.putAll(parametersMap);
            }
			else if(parameterType == TYPE_EXTRA_PARAMETERS) {
                extraParametersMap.putAll(parametersMap);
            }
			////
        }
    }

    /*
    * This method is used to append the URL parameters at the end of URL
    */
    private void appendURLParameters() {
        Set<String> urlParamKeys = urlParametersMap.keySet();
        if(!urlParamKeys.isEmpty()) {
            endpointURL += '?';
            for(String urlParamKey : urlParamKeys) {
                endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
    }

    /*
    * This method is used to set Header parameters using headerParametersMap
    */
    private void addHeaderParameters() {
        for(String key : headerParametersMap.keySet()) {
            request.setHeader(key, headerParametersMap
                              .get(key));
        }
    }

    /*
    * This method is used to form HTTP Request
    */
    public void formHTTPRequest() {
        request = new HTTPRequest();
        addHeaderParameters();
        if(String.isNotEmpty(endpointURL)) {
            endpointURL = endpointURL.substringBefore('?');
            appendURLParameters();
            request.setEndpoint(endpointURL);
        }
        if(String.isNotEmpty(requestMethod)) {
            request.setMethod(requestMethod);
        }
        if(String.isNotEmpty(requestBody)) {
            request.setBody(requestBody);
        } else if((requestBodyAsBlob != null) &&  String.isNotEmpty(requestBodyAsBlob.toString())) {
            request.setBodyAsBlob(requestBodyAsBlob);
        } else if((requestBodyAsDocument != null) && String.isNotEmpty(requestBodyAsDocument.toXmlString())) {
            request.setBodyDocument(requestBodyAsDocument);
        }
        if(requestTimeout!=null) {
            request.setTimeout(requestTimeout);
        }
        if(String.isNotEmpty(requestCertificate)) {
            request.setClientCertificateName(requestCertificate);
        }
        if(isCompressedRequest!=null) {
            request.setCompressed(isCompressedRequest);
        }
    }

    /*
    * This method forms and returns the HTTP Request without sending (for debugging purposes)
    */
    public HTTPRequest getRequest() {
        formHTTPRequest();
        return request;
    }

    /*
    * This method is used to send HTTP Request and return the response
    */
    public HTTPResponse sendRequest() {
        formHTTPRequest();
        Http http = new Http();
        HTTPResponse obj;
        if(true){
            obj =  http.send(request);
            system.debug('obj===>'+obj);
        }else{
            obj = new HTTPResponse();
            obj.setBody(calloutMetadata.Mock_Response__c);
            obj.setStatus('OK');
            obj.setStatusCode(200);
        }
        return obj;
    }

    /*
    * This method is used to send HTTP Request received in parameter and return the response
    */
    public HTTPResponse sendRequest(HTTPRequest request) {
        Http http = new Http();
        HTTPResponse obj;
        
            obj =  http.send(request);
     
        return obj;
    }
    
    /**
     * @Description : Get API details From 'API Detail' Metadata
     * @Author      :Mohit
     * @Date        :21/03/2024
    */
    public static UB_Callout_Framework__mdt getAPIMetadataDetails(String apiServiceClassName){
        Boolean isApiCalledFromSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String serviceName = /*SUD_ConstantService.getServiceClass(apiServiceClassName)*/  '' ;
        serviceName = isApiCalledFromSandbox ? serviceName+'_sandbox': '';
        System.debug('serviceName ### '+serviceName);
        UB_Callout_Framework__mdt  objData = UB_Callout_Framework__mdt.getInstance(apiServiceClassName);
        RETURN objData;
    }
    
    /**
     * @Description : method will generate api log dictionary
     * @Author      : Zafaruddin
     * @Date        :01/04/2023
    */
    @AuraEnabled
    public static Api_Logger__c createAPILogRecord(String endpoint, String headers, String method,
                                                   String  requestBody, String responseBody, Integer responseCode, String className, String recordId, String sObjectName, String apiType, String source,String lob){
                                                       Api_Logger__c apiLogRecord = new Api_Logger__c();
                                                       apiLogRecord.End_Point__c = endpoint;
                                                       apiLogRecord.Headers__c = headers;
                                                       apiLogRecord.Method__c = method;
                                                       apiLogRecord.Request__c = requestBody;
                                                       if(responseBody.length() > 131072){
                                                           apiLogRecord.Response__c = responseBody.subString(0,131071);
                                                       }
                                                       else{
                                                           apiLogRecord.Response__c = responseBody;
                                                       }
                                                       
                                                       apiLogRecord.Status_Code__c = String.valueOf(responseCode);
                                                       apiLogRecord.Class_Name__c = className;
                                                       apiLogRecord.Record_Id__c = recordId;
                                                       apiLogRecord.Sobject__c = sObjectName;
                                                       apiLogRecord.Api_Type__c = apiType;
                                                       apiLogRecord.Source__c = source;
                                                       apiLogRecord.LOB__c = lob;
                                                       return apiLogRecord;
        
    }

    public static void checkReTriggerScoreCardValidation(String customerId) {
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        List<Verification__c> scoreCardVerificationList = new  List<Verification__c>();
        List<Verification__c> CibilVerificationList = new  List<Verification__c>();
        if(loanAppList[0].ScoreCard_Verification__c != NULL) {
            scoreCardVerificationList = new UB_VerificationsSelector().selectById(new Set<Id>{loanAppList[0].ScoreCard_Verification__c});
        }
        if(loanAppList[0].Cibil_Verification__c != NULL) {
            CibilVerificationList = new UB_VerificationsSelector().selectById(new Set<Id>{loanAppList[0].Cibil_Verification__c});
        }
        System.debug('scoreCardVerificationList  '+scoreCardVerificationList);
        System.debug('CibilVerificationList  '+CibilVerificationList);
        if(!scoreCardVerificationList.isEmpty() && scoreCardVerificationList[0].Status__c == UB_ConstantsUtil.COMPLETEDSTATUS 
        && !CibilVerificationList.isEmpty() && CibilVerificationList[0].Status__c == UB_ConstantsUtil.COMPLETEDSTATUS) {
            System.debug('RE trigger Condition for Score Card');
            Loan_Application__c loanApplication = new Loan_Application__c();
            loanApplication.Id = loanAppList[0].Loan_Application__c;
            loanApplication.Is_Retrigger_S1__c = true;
            update loanApplication;
        }
    }
    
    @AuraEnabled
    public static String validateAccessToken (Id customerId, String apiName){
        System.debug('TOKEN ');
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('VerificationAPI');
        List<Verification__c> verificationList = new  List<Verification__c>();
        List<Address__c> applicantAddressList = [SELECT Id FROM Address__c WHERE  Loan_Applicant__c=:customerId AND Address_Type__c='Residence Address'];
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
       // System.debug('LOAN APPLICANT RECORD TYPE '+loanAppList[0].RecordTypeId);
       // System.debug('INDIVIDUAL_APPICANT_RECORD_TYPE '+UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE);
       // System.debug('NON_INDIVIDUAL_APPICANT_RECORD_TYPE '+UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE);
        //System.debug('applicantAddressList   '+applicantAddressList);
        if(apiName == UB_ConstantsUtil.CIBIL_API && loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE && applicantAddressList.isEmpty()) {
            return messageConfigMap.get('AddressIsMandatory') != NULL ? messageConfigMap.get('AddressIsMandatory').Message__c : NULL ;
        }
        System.debug('loanAppList[0].Sherlock_Verification__c  '+loanAppList[0].Sherlock_Verification__c);
        if(loanAppList[0].Sherlock_Verification__c != NULL) {
            verificationList = new UB_VerificationsSelector().selectById(new Set<Id>{loanAppList[0].Sherlock_Verification__c});
        }
        if(apiName == UB_ConstantsUtil.SHERLOCK_API && loanAppList[0].Email__c == NULL) {
            return messageConfigMap.get('EmailIsMandatory') != NULL ? messageConfigMap.get('EmailIsMandatory').Message__c : NULL ;
        }
        System.debug('verificationList  '+verificationList);
        if(!loanAppList[0].Consent_Received__c && apiName != 'CONSENT'){
            return messageConfigMap.get('ConsentIsMandatory') != NULL ? messageConfigMap.get('ConsentIsMandatory').Message__c : NULL ;
    	}else if(apiName == UB_ConstantsUtil.PAN_API || apiName == UB_ConstantsUtil.CFR_API){
            // Added By Mohit on 30-07-24 for BL - <Bug: USFBL-174 (PAN Net Annual Income Validation is visible for CV/CE)>
            if(loanAppList[0].Loan_Application__r.LOB__c != UB_ConstantsUtil.LOB_BL && apiName == UB_ConstantsUtil.PAN_API && loanAppList[0].Net_Annual_Income__c == NULL ) {
                return messageConfigMap.get('Net_Anunual_Income_required') != NULL ? messageConfigMap.get('Net_Anunual_Income_required').Message__c : NULL ;
            }
            if(loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE && (String.isBlank(loanAppList[0].Pan_Number__c) || loanAppList[0].Date_of_Birth__c == NULL)){
                return messageConfigMap.get('Individual_PAN_API_Required_Info') != NULL ? messageConfigMap.get('Individual_PAN_API_Required_Info').Message__c : NULL ;
            }else if(loanAppList[0].RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE && (String.isBlank(loanAppList[0].Pan_Number__c) || loanAppList[0].Date_Of_Incorporation__c == NULL)){
                return messageConfigMap.get('Non_Individual_PAN_API_Required_Info') != NULL ? messageConfigMap.get('Non_Individual_PAN_API_Required_Info').Message__c : NULL ;
            }
        }else if(apiName == UB_ConstantsUtil.AADHAAR_OTP_API && String.isBlank(loanAppList[0].Aadhaar_Verification__r.Aadhaar_Number__c)){
            return messageConfigMap.get('Aadhaar_API_Required_Info') != NULL ? messageConfigMap.get('Aadhaar_API_Required_Info').Message__c : NULL ;

        }else if(apiName == UB_ConstantsUtil.DEDUPE_API){
            if(String.isBlank(loanAppList[0].PAN_Verification__c)){
                return  messageConfigMap.get('Dedupe_Pan_Api_Required_Info') != NULL ? messageConfigMap.get('Dedupe_Pan_Api_Required_Info').Message__c : NULL ;

            }
            if(loanAppList[0].Proof_of_Address__c == UB_ConstantsUtil.AADHAAR_ADDRESS_PROOF && loanAppList[0].Aadhaar_Verification__c == NULL){
                return  messageConfigMap.get('Dedupe_Aadhaar_Api_Required_Info') != NULL ? messageConfigMap.get('Dedupe_Aadhaar_Api_Required_Info').Message__c : NULL ;

            }
        }else if(apiName == UB_ConstantsUtil.UDYAM_API){
            if(String.isBlank(loanAppList[0].BL_URC__c)){
                return  messageConfigMap.get('Udyam_Registration_Certificate_Required') != NULL ? messageConfigMap.get('Udyam_Registration_Certificate_Required').Message__c : NULL ;
            }
        }else if(apiName == UB_ConstantsUtil.SCORECARD_API) {
            if(loanAppList[0].Monthly_Income__c == NULL){
                return  messageConfigMap.get('ScoreCard_API_Required_Info') != NULL ? messageConfigMap.get('ScoreCard_API_Required_Info').Message__c : NULL ;
            }


            List<Verification__c> cibilVerificationList = [SELECT Id,Name,Cibil_Score__c FROM Verification__c WHERE Loan_Applicant__c = : customerId AND RecordTypeId=:UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE Order By createdDate DESC LIMIT 1 ];
            System.debug('cibilVerificationList  '+cibilVerificationList);
            List<ContentDocumentLink> listContDoc = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :cibilVerificationList[0].Id ];
            System.debug( 'listContDocumentttttttt' +listContDoc);
            List<ContentVersion> listContentVersion = [ SELECT VersionData FROM ContentVersion
                                                      WHERE IsLatest = true AND ContentDocumentId =: listContDoc[0].ContentDocumentId];
            System.debug( 'ContentVersionhhhhhhhh' +listContentVersion);
    
            String cibilResponse = listContentVersion[0].VersionData.toString();




            //List<Api_Logger__c> cibilApiLogger = [ SELECT Id, Name,Response__c  FROM Api_Logger__c WHERE Record_Id__c=:customerId AND Class_Name__c=:UB_ConstantsUtil.CIBIL_CLASS Order By Name DESC ];
            //System.debug('cibilApiLogger  '+cibilApiLogger);
            if(cibilVerificationList.isEmpty()) {
                return  messageConfigMap.get('Cibil_Api_Initiate_Before_ScoreCard_Api') != NULL ? messageConfigMap.get('Cibil_Api_Initiate_Before_ScoreCard_Api').Message__c : NULL ;

            }
            Map<String,Object>  mapCibilResp = (Map<String, Object>)JSON.deserializeUntyped(cibilResponse);
            system.debug('mapCibilResp'+mapCibilResp);
            Map<String, Object> dataMap = (Map<String, Object>)mapCibilResp.get('data');
            System.debug('dataMap   '+dataMap);
            if(dataMap.get('consumerCreditData') == NULL) {
                 return  messageConfigMap.get('Cibil_Api_response_issue') != NULL ? messageConfigMap.get('Cibil_Api_response_issue').Message__c : NULL ;
            }
            mapCibilResp = (Map<String,Object>) ((List<Object>)dataMap.get('consumerCreditData'))[0];
            System.debug('mapCibilResp  '+mapCibilResp);
            System.debug('ACCOUNT  DATA  '+mapCibilResp.get('accounts'));
            if(mapCibilResp.get('accounts') ==  NULL) {
                System.debug('YESSSSSSSSSSS  SCORECARD API');
                return  messageConfigMap.get('Cibil_Api_response_issue') != NULL ? messageConfigMap.get('Cibil_Api_response_issue').Message__c : NULL ;
            }

        }
        System.debug('apiNameapiNameapiName  '+apiName);
       // System.debug('UB_ConstantsUtil.CIBIL  '+UB_ConstantsUtil.CIBIL_API);
        String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
        if(String.isNotBlank(accessToken) && String.isNotBlank(apiName)){
            if(apiName == UB_ConstantsUtil.PAN_API) {
            	UB_PAN_PROFILE_API.validateAccountNumber(customerId,accessToken);
            } else if(apiName == UB_ConstantsUtil.DEDUPE_API){
                System.debug('DEDUPEEEEEEEEE');
                if(loanAppList[0].Applicant_Type__c == 'Applicant') {
                   UB_CommonUtil.dedupeTriggerRuled(loanAppList[0].Pan_Number__c,loanAppList[0].Loan_Application__c);
                }
                UB_DedupeApi.checkDedupe(customerId,accessToken);
            } else if(apiName == UB_ConstantsUtil.CIBIL_API && (loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE || loanAppList[0].RecordTypeId == BL_ConstantsUtil.BL_INDIVIDUAL_APPICANT_RECORD_TYPE)){
                UB_HTTPCalloutService.checkReTriggerScoreCardValidation(customerId);
                System.debug('Consumer CIBILLLLLLLLLLLl API CALL');
                UB_Cibil_API.getCibilScore(customerId,accessToken);
            } else if(apiName == UB_ConstantsUtil.CIBIL_API && (loanAppList[0].RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE || loanAppList[0].RecordTypeId == BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE)){
                System.debug('COMMERCIAL CIBILLLLLLLLLLLl API CALL');
                UB_CommercialCibilApi.getCibilScore(customerId,accessToken);
            }else if(apiName == UB_ConstantsUtil.UDYAM_API){
                UB_Udyam_API.fetchPdfData(customerId, accessToken);
            }else if(apiName == UB_ConstantsUtil.SHERLOCK_API){
                System.debug('SHERLOCKKKKKKKKK');
                 system.debug('app'+loanAppList);
                  system.debug('app'+loanAppList[0].Sherlock_Verification__c);
                 System.debug('verification'+verificationList);
                if(loanAppList[0].Sherlock_Verification__c == NULL || (verificationList != NULL && verificationList[0].Sherlock_Case_Id__c == NULL) ) {
                    UB_SherlockAPI.getCaseId(customerId,accessToken);
                } else {
                    if(verificationList[0].SherLock_Status__c == 'IN PROCESS' ) {
                        UB_SherlockAPI.getCaseId(customerId,accessToken);
                        return messageConfigMap.get('sherlock_Api_Issue').Message__c;
                    }
                    UB_SherlockAPI.invokeIssueApi(verificationList[0].Sherlock_Case_Id__c,customerId,accessToken);
                    System.debug('ZAFAR FOR SHRLOCK CASE API.');
                }
               
            }else if(apiName == UB_ConstantsUtil.HUNTER_API){
                UB_Hunter_API HunterAPI = new UB_Hunter_API();
                HunterAPI.invokeAPI(customerId);
            }
            else if(apiName == UB_ConstantsUtil.CONSENT_API){
                //Added By Mohit on 04-10-2024 for BL (Bug-144) - <Throw Validation if consent is already in-progress or completed>
                if(loanAppList[0].Loan_Application__r.LOB__c == UB_ConstantsUtil.LOB_BL){
                    if(loanAppList[0].Consent_Verification__c != null && !loanAppList[0].Consent_Received__c){
                        if(loanAppList[0].Consent_Verification__r.Status__c != UB_ConstantsUtil.FAILED_STATUS){
                            return messageConfigMap.get('ConsentCompleted').Message__c;
                        }
                    }else if(loanAppList[0].Consent_Received__c){
                        return messageConfigMap.get('ConsentCompleted').Message__c;
                    }
                }
                UB_ConsentValueFirstApi.getCustomerConsent(customerId,accessToken);
            } else if(apiName == UB_ConstantsUtil.CFR_API){
                UB_CFR_API.fetchServices(customerId);
            } else if(apiName == UB_ConstantsUtil.SCORECARD_API){
                UB_ScoreCardApi.getScoreCard(customerId,accessToken);
            } else if(apiName == BL_ConstantsUtil.MCA_API){ // added by mansur --02/08/2024
                List<Loan_Applicant__c> loanApplicantData=  [SELECT Id,Loan_Application__c FROM  Loan_Applicant__c WHERE Id =:customerId ];
                system.debug('loanApplicantData>> ' + loanApplicantData);
                UB_MCA_DOCUMENT_API.callMcaApi(loanApplicantData[0].Id);
            }
            return 'Success';
        } return null; 
    }

    @AuraEnabled
    public static String callENachAPI (Id disbursementId){
      System.debug('disbursementId@@ '+disbursementId);
      String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
      System.debug('accessToken@@ '+accessToken);
      //UB_ENACH_API.getENach(disbursementId,accessToken);
      return 'Success';
    }
}