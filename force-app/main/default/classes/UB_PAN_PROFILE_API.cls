/**
* @File Name          : UB_PAN_PROFILE_API.cls
* @Description        : This API is used to check PAN Profile for customer.
* @Author             : Mohd Musab
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-06-2024               Mohd Musab                 Initial Version
*/

public class UB_PAN_PROFILE_API {
    UB_HTTPCalloutService service;
    
    @future(callout = true)
    public static void validateAccountNumber (Id customerId, String accessToken){
        Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
        List<Verification__c> insertRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        //Savepoint sp = Database.setSavepoint();
        try{
            UB_PAN_PROFILE_API panStatusCheck = new UB_PAN_PROFILE_API();
            panStatusCheck.service = new UB_HTTPCalloutService('PAN_PROFILE_API');
            
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('pan',String.isNotBlank(loanAppList[0].Pan_Number__c) ? loanAppList[0].Pan_Number__c : '');
            gen.writeStringField('name',loanAppList[0].Account_Name__c);
            if(loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE && loanAppList[0].Date_of_Birth__c != null){
                gen.writeStringField('dob',
                                     DateTime.newInstance(
                                         loanAppList[0].Date_of_Birth__c.year(), 
                                         loanAppList[0].Date_of_Birth__c.month(), 
                                         loanAppList[0].Date_of_Birth__c.day()
                                     ).format('yyyy-MM-dd')
                                    );
            }else if(loanAppList[0].RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE && loanAppList[0].Date_Of_Incorporation__c != null){
            	gen.writeStringField('dob',
                                     DateTime.newInstance(
                                         loanAppList[0].Date_Of_Incorporation__c.year(), 
                                         loanAppList[0].Date_Of_Incorporation__c.month(), 
                                         loanAppList[0].Date_Of_Incorporation__c.day()
                                     ).format('yyyy-MM-dd')
                                    );
            }
            gen.writeStringField('consent','Y');
            gen.writeFieldName('clientData');
            gen.writeStartObject();
            gen.writeStringField('caseId',loanAppList[0].Id);
            gen.writeEndObject();
            gen.writeEndObject();
            
            panStatusCheck.service.setHeaderParameter('Authorization','Bearer '+accessToken);
        	panStatusCheck.service.setRequestBody(gen.getAsString());        
            HttpResponse response = panStatusCheck.service.sendRequest(); 
            System.debug('response## '+response.getBody());
            Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.PAN_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.COMPLETEDSTATUS);
            if(response.getStatusCode() == 200){
                if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('result')){
                    Map<String,Object> mapResponseBody = (Map<String,Object>) (mapResponseResult.get('result'));
                    if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('name')){
                        verify.PAN_Name__c = (String) String.valueOf(mapResponseBody.get('name'));
                    }
                    if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('dob')){
                        verify.PAN_DOB__c = (String) String.valueOf(mapResponseBody.get('dob'));
                    }
                    if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('aadhaarLinked')){
                        verify.Is_Aadhar_Linked__c = (boolean)mapResponseBody.get('aadhaarLinked');
                    }
                    if(mapResponseBody.containsKey('profileMatch')){
                        List<Object> profileMatchList = (List<Object>) mapResponseBody.get('profileMatch');
                        if(profileMatchList.size() > 0){
                            for(Object profileMatchObj : profileMatchList){
                                Map<String, Object> profileMatchMap = (Map<String, Object>) profileMatchObj;
                                String parameter = (String) profileMatchMap.get('parameter');
                                Boolean matchResult = (Boolean) profileMatchMap.get('matchResult');
                                
                                if(parameter == 'name'){
                                    verify.Is_Name_Matched__c = matchResult;
                                } else if(parameter == 'dob'){
                                    verify.Is_DOB_Matched__c = matchResult;
                                }
                            }
                        }

                    }
                    /*if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('dobMatch')){
                        String isDOBMatched = (String) String.valueOf(mapResponseBody.get('dobMatch'));
                        verify.Is_DOB_Matched__c = isDOBMatched != null && String.isNotBlank(isDOBMatched) && isDOBMatched == 'true' ? true : false; 
                    }*/
                    /*if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('duplicate')){
                        String isDupMatched = (String) String.valueOf(mapResponseBody.get('duplicate'));
                        verify.Is_Duplicate__c = isDupMatched != null && String.isNotBlank(isDupMatched) && isDupMatched == 'true' ? true : false;
                    }*/
                    /*
                    if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('nameMatch')){
                        String isNameMatched = (String) String.valueOf(mapResponseBody.get('nameMatch'));
                        verify.Is_Name_Matched__c = isNameMatched != null && String.isNotBlank(isNameMatched) && isNameMatched == 'true' ? true : false; 
                    }*/
                }else{
                    verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                    verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
                }
            }else{
                verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
            }
            insertRecords.add(verify);
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                panStatusCheck.service.getEndpointURL(), 
                String.valueOf(panStatusCheck.service.getHeaderParameters()), 
                panStatusCheck.service.getRequestMethod(), 
                gen.getAsString(), 
                response.getBody(), 
                response.getStatusCode(), 
                UB_PAN_API.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'PAN Profile API',
                loanAppList[0].Loan_Application__r.LOB__c
            );
            if(mapResponseResult.containsKey('status')){
                apiLogger.Status__c = (String) String.valueOf(mapResponseResult.get('status'));
            }
            createLogList.add(apiLogger);
            
            if(!createLogList.isEmpty() && createLogList.size() > 0){
                UB_API_LoggerUtility.insertRecords(createLogList);
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            //Database.releaseSavepoint(sp);
            Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.PAN_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.FAILED_STATUS);
			verify.Failed_Reason__c = e.getMessage();
            insertRecords.add(verify); 
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);
        }
        
        if(!insertRecords.isEmpty() && insertRecords.size() > 0){
            insertRecords = UB_VerificationUtility.insertRecords(insertRecords);
            UB_LoanApplicantUtility.updateRecords(new List<Loan_Applicant__c>{new Loan_Applicant__c(Id = customerId, PAN_Verification__c = insertRecords[0].Id)});
        }
    }
}