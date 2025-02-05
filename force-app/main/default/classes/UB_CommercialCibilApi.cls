/**
* @File Name          : UB_CommercialCibilApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         22-06-2024            Zafaruddin         Initial Version

**/
public with sharing class UB_CommercialCibilApi {
    
    UB_HTTPCalloutService service;

        /**
    * @description  Funtion will Call Cibil APi and return Cibil Score on verification record.
    * @author Zafaruddin | 04-15-2024 
    * @param customerId 
    * @param accessToken 
    **/
    @future(callout = true)
    public static void getCibilScore (Id customerId, String accessToken){
        UB_CommercialCibilApi commercialCibilApi = new UB_CommercialCibilApi();
        Verification__c verifyRecord = new Verification__c();

        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        System.debug('APPLICATION ID   '+loanAppList[0].Loan_Application__c);
        Map<String,Address__c> applicantAddressMap = new Map<String,Address__c>();
        for(Address__c address : [SELECT Id,City__c,Name,Address_Line_2__c,Address_Line_3__c,CIbil_State_Code__c,Pincode__r.Name,Address_Type__c , State__c FROM Address__c WHERE Loan_Applicant__c = : customerId]) {
            if(address.Address_Type__c == 'Office Address') {
                applicantAddressMap.put('Office Address', address);
            }
        }
        System.debug('applicantAddressMap   '+applicantAddressMap);
        String address='';
        if(applicantAddressMap.get('Office Address') != NULL) {
            if(applicantAddressMap.get('Office Address').Name != NULL) {
                
                Address += applicantAddressMap.get('Office Address').Name;
            }
            if(applicantAddressMap.get('Office Address').Address_Line_2__c != NULL) {
                Address += applicantAddressMap.get('Office Address').Address_Line_2__c;
            }
            if(applicantAddressMap.get('Office Address').Address_Line_3__c != NULL) {
                Address += applicantAddressMap.get('Office Address').Address_Line_3__c;
            }
        }
        commercialCibilApi.service = new UB_HTTPCalloutService('Commercial_Cibil_API');
        commercialCibilApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
        System.debug('TOKENNNNN  '+accessToken);
        Try{
            String RequestJson;
            System.debug('11111111');
            JSONGenerator jsonGenerator = JSON.createGenerator(true);
            System.debug('2222222222222222222');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeFieldName('request');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeFieldName('header');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('version',commercialCibilApi.service.getExtraParameter('version'));
            jsonGenerator.writeStringField('product_type',commercialCibilApi.service.getExtraParameter('product_type'));
            jsonGenerator.writeStringField('user_id',commercialCibilApi.service.getExtraParameter('user_id'));
            jsonGenerator.writeStringField('user_password',commercialCibilApi.service.getExtraParameter('user_password'));
            jsonGenerator.writeStringField('member_code',commercialCibilApi.service.getExtraParameter('member_code'));
            jsonGenerator.writeStringField('member_KOB',commercialCibilApi.service.getExtraParameter('member_KOB'));
            jsonGenerator.writeStringField('member_reference_number',commercialCibilApi.service.getExtraParameter('member_reference_number'));
            jsonGenerator.writeStringField('report_type',commercialCibilApi.service.getExtraParameter('report_type'));
            jsonGenerator.writeStringField('output_format',commercialCibilApi.service.getExtraParameter('output_format'));
            jsonGenerator.writeEndObject();
            System.debug('jsonGenerator111111111111  '+jsonGenerator);
            jsonGenerator.writeFieldName('search_data');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeFieldName('general_fields');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('enquiry_amount', loanAppList[0].Loan_Application__r.Amount__c != NULL ? String.valueOf(loanAppList[0].Loan_Application__r.Amount__c): '');
            jsonGenerator.writeStringField('enquiry_purpose',loanAppList[0].Loan_Application__r.Product__c != NULL ? loanAppList[0].Loan_Application__r.Product__c :'');
            jsonGenerator.writeStringField('enquiry_type',commercialCibilApi.service.getExtraParameter('enquiry_type'));
            jsonGenerator.writeStringField('type_of_entity',loanAppList[0].Constitution__c != NULL ? loanAppList[0].Constitution__c : '');
            jsonGenerator.writeStringField('class_of_activity',loanAppList[0].Nature_of_Business__c != NULL ? loanAppList[0].Nature_of_Business__c : '');
            jsonGenerator.writeStringField('date_of_registration',loanAppList[0].Date_Of_Incorporation__c != NULL ? String.valueOf(DateTime.newInstance(loanAppList[0].Date_Of_Incorporation__c.year(), loanAppList[0].Date_Of_Incorporation__c.month(),loanAppList[0].Date_Of_Incorporation__c.day()).format('dd-MMM-yyyy')) : '' );
            jsonGenerator.writeStringField('cmr_flag',commercialCibilApi.service.getExtraParameter('cmr_flag'));
            jsonGenerator.writeEndObject();
            jsonGenerator.writeFieldName('company_name');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('name',loanAppList[0].Account_Name__c != NULL ? loanAppList[0].Account_Name__c : '');
            jsonGenerator.writeEndObject();
            jsonGenerator.writeFieldName('id');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('pan',loanAppList[0].Pan_Number__c != NULL ? loanAppList[0].Pan_Number__c : '');
            jsonGenerator.writeStringField('cin',loanAppList[0].CIN__c != NULL ? loanAppList[0].CIN__c : '');
            jsonGenerator.writeStringField('crn','');
            jsonGenerator.writeStringField('tin','');
            jsonGenerator.writeEndObject();
            jsonGenerator.writeFieldName('contact');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeFieldName('address');
            jsonGenerator.writeStartArray();
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('addressType',commercialCibilApi.service.getExtraParameter('addressType') );
            jsonGenerator.writeStringField('addressLine1',Address);
            jsonGenerator.writeStringField('city',applicantAddressMap.get('Office Address').City__c != NULL ? applicantAddressMap.get('Office Address').City__c : '');
            jsonGenerator.writeStringField('state',applicantAddressMap.get('Office Address').State__c != NULL ? applicantAddressMap.get('Office Address').State__c : '');
            jsonGenerator.writeStringField('pinCode',applicantAddressMap.get('Office Address').Pincode__r.Name != NULL ? applicantAddressMap.get('Office Address').Pincode__r.Name : '');
            jsonGenerator.writeEndObject();
            jsonGenerator.writeEndArray();
            jsonGenerator.writeEndObject();
            jsonGenerator.writeFieldName('telephone');
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField('telephoneType','01');
            jsonGenerator.writeStringField('telephone_num',loanAppList[0].Mobile__c != NULL ? loanAppList[0].Mobile__c : '');
            jsonGenerator.writeStringField('contact_area','');
            jsonGenerator.writeStringField('contact_prefix','');
            jsonGenerator.writeEndObject();

            jsonGenerator.writeEndObject();
            jsonGenerator.writeFieldName('directors');
            jsonGenerator.writeNull();

            jsonGenerator.writeEndObject();
            jsonGenerator.writeEndObject();
            String jsonRequestBody = jsonGenerator.getAsString();
            System.debug('jsonRequestBody  '+jsonRequestBody);

            commercialCibilApi.service.setRequestBody(jsonRequestBody);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = commercialCibilApi.service.sendRequest();
            System.debug('responeObj   '+responeObj);
            String JSONResponse = responeObj.getBody();//res.getBody();
            System.debug('JSONResponse  '+JSONResponse);
            String cibilReport = '';
            String cibilScore = '';
            String responceBody = JSONResponse;
            if(responeObj.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(JSONResponse);
                while (parser.nextToken() !=  null) {
                    if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                        String text = parser.getText();
                        if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                            if (text == 'base64') {
                                cibilReport = parser.getText();
                            } else if (text == 'rankValue') {
                                cibilScore = parser.getText();
                            } 
                        }
                    }
                }
                System.debug('cibilScore  '+cibilScore);
                System.debug('cibilScore length  '+cibilScore.length());
                System.debug('cibilReport  '+cibilReport);
                if(cibilScore.length() > 0) {
                    System.debug('ZZZZZ');
                    System.debug('CIBIL SCOREEEEE  '+CibilScore);
                    verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.COMPLETEDSTATUS);
                    verifyRecord.Cibil_Score__c = CibilScore;
                    insert verifyRecord;
                    System.debug('verifyRecord  '+verifyRecord);
                   // UB_CommercialCibilApi.saveAndLinkCibilResponse(verifyRecord.Id, JSONResponse);
                    update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
                    if(cibilReport.length() > 0 ) {
                        System.debug('YESSSSSSSS');
                        //String base64Content = EncodingUtil.Base64Encode( Blob.valueOf( cibilReport ) );
                        Blob blobContent = EncodingUtil.base64Decode(  cibilReport );
                        //Blob blobContent =  Blob.valueOf( cibilReport );

                        // method to store Cibil report in Document checklist.
                        UB_CommonUtil.createDocument('Commercial Cibil Report','Commercial CIBIL Report.html',blobContent,loanAppList[0].Loan_Application__c, customerId,'Cibil Report',NULL);
                    }
                }

            } else {
                verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                verifyRecord.Failed_Reason__c = 'Please Contact your Admin for Commercial Cibil Report.'  ;
                insert verifyRecord;
                update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
            }

            // code to check Reponse length > 131072 then replace base64 part.
            if(JSONResponse.length() > 131072) {
                String base64Json = jsonRequestBody.substringBetween('base64', ',');
                responceBody = jsonRequestBody.replace(base64Json, '": null');
                System.debug('jsonRequestBody  jsonRequestBody   '+jsonRequestBody);
            }

            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                commercialCibilApi.service.getEndpointURL(), 
                String.valueOf(commercialCibilApi.service.getHeaderParameters()), 
                commercialCibilApi.service.getRequestMethod(), 
                jsonRequestBody, 
                responceBody, 
                responeObj.getStatusCode(), 
                UB_CommercialCibilApi.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'Commercial CIBIL API',
                UB_ConstantsUtil.LOB_CV
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            }

            //RequestJson=  '{"serviceCode": "' + cibilApi.service.getExtraParameter('serviceCode') + '",';
        }catch(System.CalloutException e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);

            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);            
        }catch(Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = +e.getMessage();
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);

            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }

    }

    public static void saveAndLinkCibilResponse( String verificationId, String cibilResponse){
        String base64Content = EncodingUtil.Base64Encode( Blob.valueOf( cibilResponse ) );
        Blob blobContent = EncodingUtil.base64Decode( base64Content );
        String profileName=[Select Id,Name from Profile where Id=: userinfo.getProfileId()].Name;
        ContentVersion cibilCvObj = new ContentVersion (Title = 'Commercial Cibil Response', PathOnClient = 'Commercial Response.json',VersionData = blobContent, FirstPublishLocationId = verificationId);
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
            cibilCvObj.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
        }
        insert cibilCvObj;
        System.debug('cibilCvObj RESPONSE  '+cibilCvObj);
   }
}