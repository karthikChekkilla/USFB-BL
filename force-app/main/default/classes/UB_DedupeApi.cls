/**
* @File Name          : UB_DedupeApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-04-2024            Zafaruddin         Initial Version

**/

public class UB_DedupeApi {
    
    UB_HTTPCalloutService service;

    
    /**
    * @description method will check dedupe based on Pan,Aadhar and DOB and return response data on verification Object.
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 04-15-2024 
    * @param customerId 
    * @param accessToken 
    **/
    @future(callout = true)
    public static void checkDedupe (Id customerId, String accessToken){
        Savepoint sp;
        String maskAadhar;
        String unMaskAadhar;
        String Endpoint ;
        Verification__c verifyRecord = new Verification__c();
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        try{
            Date dob;
            System.debug('loanAppList  '+loanAppList);
            if((loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE || loanAppList[0].RecordTypeId == BL_ConstantsUtil.BL_INDIVIDUAL_APPICANT_RECORD_TYPE) && loanAppList[0].Date_of_Birth__c != null){
                dob = loanAppList[0].Date_of_Birth__c;
            } else if((loanAppList[0].RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE || loanAppList[0].RecordTypeId == BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE) && loanAppList[0].Date_Of_Incorporation__c != null) {
                dob = loanAppList[0].Date_Of_Incorporation__c;
            }
            System.debug('dobdobdob  '+dob);
            System.debug('loanAppList  '+loanAppList);
            UB_DedupeApi dedupeApi = new UB_DedupeApi();
            dedupeApi.service = new UB_HTTPCalloutService('Dedupe_Api');
            dedupeApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
            System.debug('Header VALUESS '+dedupeApi.service.getHeaderParameters());
            dedupeApi.service.setURLParameter('transactionDateTime', Datetime.now().formatGMT('YYYYMMddHHmmss'));
            dedupeApi.service.setURLParameter('PAN', String.isNotBlank(loanAppList[0].Pan_Number__c) ? loanAppList[0].Pan_Number__c : '');
            dedupeApi.service.setURLParameter('DOB', dob != NULL ? UB_CommonUtil.dateFormatter(dob) : '');
            System.debug('loanAppList[0].Aadhaar_Verification__c  '+loanAppList[0].Aadhaar_Verification__c);
            if(loanAppList[0].Aadhaar_Verification__c != NULL  ) {
                List<Verification__c> verificationList = new UB_VerificationsSelector().selectById(new Set<Id>{loanAppList[0].Aadhaar_Verification__c});
                if( String.isNotBlank( verificationList[0].Aadhaar_Number__c)) {
                    maskAadhar = verificationList[0].Aadhaar_Number__c;
                    System.debug('MASK Aaadhar NUmber   '+maskAadhar);
                    unMaskAadhar = UB_Aadhaar_API.aadhaarNumberUnmasking(verificationList[0].Aadhaar_Number__c);
                    System.debug('Real Aadhar Number  '+unMaskAadhar);
                    dedupeApi.service.setURLParameter('AADHAAR', String.isNotBlank(unMaskAadhar) ? unMaskAadhar : '');
                }
            }
            System.debug('URL VALUEEEEE  '+dedupeApi.service.getURLParameters());
            HttpResponse response = dedupeApi.service.sendRequest() ;
            sp = Database.setSavepoint();
            System.debug('RESPONSEEEEEEEE  '+response);
            system.debug('Response Body - ' + response.getBody());
            if(response.getStatusCode() == 200) {
                verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.DEDUPE_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.COMPLETEDSTATUS);
                map<string,object> mapJSONResponse = (Map<String, object>) JSON.deserializeUntyped(response.getBody());
                system.debug('#@ '+mapJSONResponse.get('ResponseMessage'));
                system.debug('@#mapJSONResponse '+mapJSONResponse);
                mapJSONResponse = (Map<String, object>) mapJSONResponse.get('ResponseMessage');
                system.debug('mapJSONResponse ResponseMessage>>>>>'+ mapJSONResponse);
                mapJSONResponse = (Map<String, object>) mapJSONResponse.get('Payload');
                system.debug(' mapJSONResponse Payload>>>>>' + mapJSONResponse);
               // System.debug('mapJSONResponse.Status '+mapJSONResponse.get('Status'));
                //System.debug('mapJSONResponse.Status '+mapJSONResponse.get('RESPONSE_ID'));
                if(mapJSONResponse.get('Status') != NULL) {
                	verifyRecord.Dedupe_Status__c =  (String.ValueOf(mapJSONResponse.get('Status'))).toUppercase();
                    verifyRecord.Dedupe_Response_Id__c =  (String.ValueOf(mapJSONResponse.get('RESPONSE_ID')));

                } else if(mapJSONResponse.get('Status') == NULL) {
                    verifyRecord.Status__c = UB_ConstantsUtil.FAILED_STATUS;
                }
                mapJSONResponse = (Map<String, object>) mapJSONResponse.get('DECUST');
                System.debug('mapJSONResponse DECUST  '+mapJSONResponse);
                if(mapJSONResponse != NULL && mapJSONResponse.containsKey('Record') && mapJSONResponse.get('Record') != NULL) {
                       mapJSONResponse = (Map<String, object>) mapJSONResponse.get('Record');
                       verifyRecord.CIF__c = String.valueOf(mapJSONResponse.get('cif'));
                       verifyRecord.Dedupe_Address__c = String.valueOf(mapJSONResponse.get('address1'));
                       //verifyRecord.Dedupe_Response_Id__c = String.valueOf(mapJSONResponse.get('RESPONSE_ID'));
                       verifyRecord.UCID__c =  String.valueOf(mapJSONResponse.get('ucid'));
                } 
                
                if(verifyRecord != NULL) {
                    insert verifyRecord;
                    System.debug('verifyRecord  '+verifyRecord);
                    update new Loan_Applicant__c(Id = customerId, Dedupe_Verification__c = verifyRecord.Id, CIF__c=verifyRecord.CIF__c,UCID__c=verifyRecord.UCID__c);
                }
            } else {
                verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.DEDUPE_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
                insert verifyRecord;
                update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);

            }
            Endpoint = dedupeApi.service.getEndpointURL();
            if(unMaskAadhar != NULL && Endpoint.contains(unMaskAadhar)) {
                Endpoint  = Endpoint.replace(unMaskAadhar,maskAadhar);
                SYstem.debug('Endpoint  '+Endpoint);
            }
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                Endpoint, 
                String.valueOf(dedupeApi.service.getHeaderParameters()), 
                dedupeApi.service.getRequestMethod(), 
                '', 
                response.getBody(), 
                response.getStatusCode(), 
                UB_DedupeApi.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'DEDUPE API',
                loanAppList[0].Loan_Application__r.LOB__c
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            }
        }catch(System.CalloutException e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.DEDUPE_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Dedupe_Verification__c = verifyRecord.Id);
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);            
        }
        catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@11111'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE11111  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);
        }
    }
    


}