/**
* @File Name          : UB_Cibil_API.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         05-04-2024            Zafaruddin         Initial Version

**/

public  with sharing class UB_Cibil_API {
    
    UB_HTTPCalloutService service;

    
    public static String addPrifixInAmount(String enquiryAmount){
        while(enquiryAmount.length() < 9) {
            enquiryAmount = '0' + enquiryAmount;
        }

        System.debug('enquiryAmount  '+enquiryAmount);
        return enquiryAmount;
    }

    
    /**
    * @description  Funtion will Call Cibil APi and return Cibil Score on verification record.
    * @author Zafaruddin | 04-15-2024 
    * @param customerId 
    * @param accessToken 
    **/
    @future(callout = true)
    public static void getCibilScore (Id customerId, String accessToken){
        UB_Cibil_API cibilApi = new UB_Cibil_API();
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        System.debug('APPLICATION ID   '+loanAppList[0].Loan_Application__c);
        //List<Address__c> applicantPermanentAddressList = [SELECT Id,Name,Address_Line_2__c,Address_Line_3__c,CIbil_State_Code__c,Pincode__r.Name FROM Address__c WHERE Loan_Applicant__c = : customerId AND Address_Type__c='Residence Address'];

        Map<String,Address__c> applicantAddressMap = new Map<String,Address__c>();
        for(Address__c address : [SELECT Id,Name,Address_Line_2__c,Address_Line_3__c,CIbil_State_Code__c,Pincode__r.Name,Address_Type__c FROM Address__c WHERE Loan_Applicant__c = : customerId]) {
            if(address.Address_Type__c == 'Permanent Address') {
                applicantAddressMap.put('Permanent Address', address);

            } else if(address.Address_Type__c == 'Residence Address') {
                applicantAddressMap.put('Residence Address', address);
            } else if(address.Address_Type__c == 'Office Address') {
                applicantAddressMap.put('Office Address', address);
            }
        }


        Verification__c verifyRecord = new Verification__c();
        cibilApi.service = new UB_HTTPCalloutService('Cibil_API');
        cibilApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
        System.debug('TOKENNNNN  '+accessToken);
        //system.debug('mock response  '+cibilApi.service.calloutMetadata.Mock_Response__c);
        Savepoint sp;
        Integer CibilScore;
        Try{
            String RequestJson;
            RequestJson=  '{"serviceCode": "' + cibilApi.service.getExtraParameter('serviceCode') + '",';
            RequestJson+= '"monitoringDate": "'+DateTime.newInstance(Date.today().year(), Date.today().month(),Date.today().day()).format('ddMMyyyy')+ '",'; //current date
            RequestJson+= '"consumerInputSubject": {';
            RequestJson+= '"tuefHeader": {';
            RequestJson+= '"headerType": "TUEF",';
            RequestJson+= '"version": "12",';
            RequestJson+= '"memberRefNo": "'+cibilApi.service.getExtraParameter('memberRefNo') +'",';
            RequestJson+= '"gstStateCode": "'+cibilApi.service.getExtraParameter('gstStateCode') +'",';
            RequestJson+= '"enquiryMemberUserId": "'+cibilApi.service.getExtraParameter('enquiryMemberUserId') +'",';   // Meta Data
            RequestJson+= '"enquiryPassword": "'+cibilApi.service.getExtraParameter('enquiryPassword') +'",';           // Meta Data
            RequestJson+= '"enquiryPurpose": "05",';
            RequestJson+= '"enquiryAmount": "' +  ( loanAppList[0].Loan_Application__r.Amount__c != NULL ? UB_Cibil_API.addPrifixInAmount(String.valueOf( Integer.valueOf(loanAppList[0].Loan_Application__r.Amount__c)))  : '' ) + '",';
            RequestJson+= '"scoreType": "16",';
            RequestJson+= '"outputFormat": "03",';
            RequestJson+= '"responseSize": "1",';
            RequestJson+= '"ioMedia": "CC",';
            RequestJson+= '"authenticationMethod": "L"},';
            RequestJson+='"names": [{"index": "N01",';
            RequestJson+='"firstName": "'+ (loanAppList[0].First_Name__c != NULL ? loanAppList[0].First_Name__c : '') +'",';
            //if(String.isNotEmpty(loanAppList[0].Middle_Name__c) && String.isNotBlank(loanAppList[0].Middle_Name__c))
               // RequestJson+='"middleName":"'+loanAppList[0].Middle_Name__c +'",';
            RequestJson+='"lastName":"'+ (loanAppList[0].Last_Name__c != NULL ? loanAppList[0].Last_Name__c : '') +'",';
            if(loanAppList[0].Date_of_Birth__c!= NULL){
                RequestJson+='"birthDate":"'+DateTime.newInstance(loanAppList[0].Date_of_Birth__c.year(), loanAppList[0].Date_of_Birth__c.month(),loanAppList[0].Date_of_Birth__c.day()).format('ddMMyyyy') +'",';
            }
            else{
                RequestJson+='"birthDate":"",';
            }
            
            RequestJson+='"gender":"'+(UB_ConstantsUtil.CibilGenderCodeMap.containsKey(loanAppList[0].Gender__c) ? UB_ConstantsUtil.CibilGenderCodeMap.get(loanAppList[0].Gender__c) : '')+'"}],';
            RequestJson+='"ids": [';
            // For Handling the Id type Index number
            Integer index = 1;
            if(String.isNotBlank(loanAppList[0].Pan_Number__c) && String.isNotEmpty(loanAppList[0].Pan_Number__c)){
                RequestJson+='{"index": "I0'+index+'",';
                RequestJson+='"idNumber":"'+loanAppList[0].Pan_Number__c +'",';
                RequestJson+='"idType": "'+UB_ConstantsUtil.CibilIdsTypeMap.get('PAN')+'"},';
                index++;
            }
            if(String.isNotBlank(loanAppList[0].Passport__c) && String.isNotEmpty(loanAppList[0].Passport__c)){
                RequestJson+='{"index": "I0'+index+'",';
                RequestJson+='"idNumber":"'+loanAppList[0].Passport__c +'",';
                RequestJson+='"idType": "'+UB_ConstantsUtil.CibilIdsTypeMap.get('Passport Number')+'"},';
                index++;
            }
            if(String.isNotBlank(loanAppList[0].Voter_Card__c) && String.isNotEmpty(loanAppList[0].Voter_Card__c)){
                RequestJson+='{"index": "I0'+index+'",';
                RequestJson+='"idNumber":"'+loanAppList[0].Voter_Card__c +'",';
                RequestJson+='"idType": "'+UB_ConstantsUtil.CibilIdsTypeMap.get('Voter ID Number')+'"},';
                index++;
            }
            if(String.isNotBlank(loanAppList[0].Driving_Licence__c) && String.isNotEmpty(loanAppList[0].Driving_Licence__c)){
                RequestJson+='{"index": "I0'+index+'",';
                RequestJson+='"idNumber":"'+loanAppList[0].Driving_Licence__c +'",';
                RequestJson+='"idType": "'+UB_ConstantsUtil.CibilIdsTypeMap.get('Driver’s License Number')+'"},';
                index++;
            }
            /*
            if(String.isNotBlank(loanAppList[0].Aadhaar_Number__c) && String.isNotEmpty(loanAppList[0].Aadhaar_Number__c)){
                RequestJson+='{"index": "I0'+index+'",';
                RequestJson+='"idNumber":"'+loanAppList[0].Aadhaar_Number__c +'",';
                RequestJson+='"idType": "'+UB_ConstantsUtil.CibilIdsTypeMap.get('Aadhaar Number')+'"},';
                index++;
            }  */
            RequestJson = RequestJson.removeEnd(',');
            RequestJson += '],';
            RequestJson+='"telephones": [{';
            RequestJson+='"index": "T01",';
            RequestJson+='"telephoneNumber": "'+ (loanAppList[0].Mobile__c != NULL ? loanAppList[0].Mobile__c : '') +'",';
            RequestJson+='"telephoneType": "01",';
            RequestJson+='"enquiryEnriched": "Y"}],';
            RequestJson+='"addresses": [';
            
            if( applicantAddressMap.get('Permanent Address') != null  ) {
                RequestJson+='{"index": "A01",';
                String Address='';
                if(applicantAddressMap.get('Permanent Address').Name != NULL) {
                    
                    Address += applicantAddressMap.get('Permanent Address').Name;
                }
                if(applicantAddressMap.get('Permanent Address').Address_Line_2__c != NULL) {
                    Address += applicantAddressMap.get('Permanent Address').Address_Line_2__c;
                }
                if(applicantAddressMap.get('Permanent Address').Address_Line_3__c != NULL) {
                    Address += applicantAddressMap.get('Permanent Address').Address_Line_3__c;
                }
                System.debug('AddressAddressAddress  '+Address);
                System.debug('AddressAddressAddress LENGHTTTTT '+Address.LENGTH());
                RequestJson+='"line1": "'+( Address.LENGTH() > 40 ? Address.substring(0,40) : Address ) +'", ';
                RequestJson+='"line2": "'+( Address.LENGTH() >= 40 ? Address.substring(40,(Address.LENGTH() < 80 ? Address.LENGTH() : 80)) : '' ) +'", ';
                RequestJson+='"line3": "'+( Address.LENGTH() >= 80 ? Address.substring(80,(Address.LENGTH() < 120 ? Address.LENGTH() : 120)) : '' ) +'", ';
                RequestJson+='"line4": "'+( Address.LENGTH() >= 120 ? Address.substring(120,(Address.LENGTH() < 160 ? Address.LENGTH() : 160)) : '' ) +'", ';
                RequestJson+='"line5": "'+( Address.LENGTH() >= 160 ? Address.substring(160,(Address.LENGTH() < 200 ? Address.LENGTH() : 199)) : '' ) +'", ';
                // Cibil State Code and Pincode addition in Json request.
                RequestJson+='"stateCode": "' + applicantAddressMap.get('Permanent Address').CIbil_State_Code__c + '",';
                RequestJson+='"pinCode":"'+applicantAddressMap.get('Permanent Address').Pincode__r.Name +'",';
                RequestJson+='"addressCategory": "'+'01'+'"},';
            }
            
            if( applicantAddressMap.get('Residence Address') != null  ) {
                RequestJson+='{"index": "A02",';
                String Address='';
                if(applicantAddressMap.get('Residence Address').Name != NULL) {
                    
                    Address += applicantAddressMap.get('Residence Address').Name;
                }
                if(applicantAddressMap.get('Residence Address').Address_Line_2__c != NULL) {
                    Address += applicantAddressMap.get('Residence Address').Address_Line_2__c;
                }
                if(applicantAddressMap.get('Residence Address').Address_Line_3__c != NULL) {
                    Address += applicantAddressMap.get('Residence Address').Address_Line_3__c;
                }
                System.debug('AddressAddressAddress  '+Address);
                System.debug('AddressAddressAddress LENGHTTTTT '+Address.LENGTH());
                RequestJson+='"line1": "'+( Address.LENGTH() > 40 ? Address.substring(0,40) : Address ) +'", ';
                RequestJson+='"line2": "'+( Address.LENGTH() >= 40 ? Address.substring(40,(Address.LENGTH() < 80 ? Address.LENGTH() : 80)) : '' ) +'", ';
                RequestJson+='"line3": "'+( Address.LENGTH() >= 80 ? Address.substring(80,(Address.LENGTH() < 120 ? Address.LENGTH() : 120)) : '' ) +'", ';
                RequestJson+='"line4": "'+( Address.LENGTH() >= 120 ? Address.substring(120,(Address.LENGTH() < 160 ? Address.LENGTH() : 160)) : '' ) +'", ';
                RequestJson+='"line5": "'+( Address.LENGTH() >= 160 ? Address.substring(160,(Address.LENGTH() < 200 ? Address.LENGTH() : 199)) : '' ) +'", ';
                // Cibil State Code and Pincode addition in Json request.
                RequestJson+='"stateCode": "' + applicantAddressMap.get('Residence Address').CIbil_State_Code__c + '",';
                RequestJson+='"pinCode":"'+applicantAddressMap.get('Residence Address').Pincode__r.Name +'",';
                RequestJson+='"addressCategory": "'+'02'+'"},';
            }

          /*  if( applicantAddressMap.get('Office Address') != null  ) {
                RequestJson+='{"index": "A03",';
                String Address='';
                if(applicantAddressMap.get('Office Address').Name != NULL) {
                    
                    Address += applicantAddressMap.get('Office Address').Name;
                }
                if(applicantAddressMap.get('Office Address').Address_Line_2__c != NULL) {
                    Address += applicantAddressMap.get('Office Address').Address_Line_2__c;
                }
                if(applicantAddressMap.get('Office Address').Address_Line_3__c != NULL) {
                    Address += applicantAddressMap.get('Office Address').Address_Line_3__c;
                }
                System.debug('AddressAddressAddress  '+Address);
                System.debug('AddressAddressAddress LENGHTTTTT '+Address.LENGTH());
                RequestJson+='"line1": "'+( Address.LENGTH() > 40 ? Address.substring(0,40) : Address ) +'", ';
                RequestJson+='"line2": "'+( Address.LENGTH() >= 40 ? Address.substring(40,(Address.LENGTH() < 80 ? Address.LENGTH() : 80)) : '' ) +'", ';
                RequestJson+='"line3": "'+( Address.LENGTH() >= 80 ? Address.substring(80,(Address.LENGTH() < 120 ? Address.LENGTH() : 120)) : '' ) +'", ';
                RequestJson+='"line4": "'+( Address.LENGTH() >= 120 ? Address.substring(120,(Address.LENGTH() < 160 ? Address.LENGTH() : 160)) : '' ) +'", ';
                RequestJson+='"line5": "'+( Address.LENGTH() >= 160 ? Address.substring(160,(Address.LENGTH() < 200 ? Address.LENGTH() : 199)) : '' ) +'", ';
                // Cibil State Code and Pincode addition in Json request.
                RequestJson+='"stateCode": "' + applicantAddressMap.get('Office Address').CIbil_State_Code__c + '",';
                RequestJson+='"pinCode":"'+applicantAddressMap.get('Office Address').Pincode__r.Name +'",';
                RequestJson+='"addressCategory": "'+'03'+'"},';
            } */
            RequestJson = RequestJson.removeEnd(',');
            RequestJson += '],';

            System.debug('ZAFAR RequestJson   '+RequestJson);





            //RequestJson+='"residenceCode": "01"}],';
            RequestJson+='"enquiryAccounts": [{';
            RequestJson+='"index": "I01",';
            RequestJson+='"accountNumber":"'+ ( /*loanAppList[0].Account_Number__c !=  NULL ? String.valueOf(loanAppList[0].Account_Number__c ):*/ '')  +'"}]}}';
            system.debug('RequestJson>> '+RequestJson);

            cibilApi.service.setRequestBody(RequestJson);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = cibilApi.service.sendRequest();
            System.debug('responeObj   '+responeObj);
            sp = Database.setSavepoint();
            String cibilReport ;
            String JSONResponse = responeObj.getBody();//res.getBody();
            System.debug('JSONResponse LENGTH  '+JSONResponse.length());
            system.debug('JSONResponse>> '+JSONResponse);
            system.debug('responeObj.getStatusCode()  '+responeObj.getStatusCode());          
            Map<String,Object> ResponseMap = (Map<String,Object>)JSON.deserializeUntyped(JSONResponse);
            Map<String,Object> jsonMap = new  Map<String,Object>();
            system.debug('ResponseMap  '+ResponseMap);
            system.debug('CIBIL REPORTTTT  '+(Map<String,Object>)ResponseMap.get('additionalData'));
            if(ResponseMap.containsKey('additionalData')) {
                jsonMap = (Map<String,Object>)ResponseMap.get('additionalData');
                if(jsonMap.containsKey('base64')) {
                    cibilReport =  String.valueOf(jsonMap.get('base64'));
                    System.debug('BASE 6444444  '+cibilReport);
                }
            }
            if(ResponseMap != NULL){
                if(ResponseMap.containsKey('data')) {
                    jsonMap =   (Map<String,Object>)ResponseMap.get('data') ;
                    System.debug('successMap000000000000000  '+jsonMap);
                    if(jsonMap.containsKey('controlData')) {
                        jsonMap =   (Map<String,Object>)jsonMap.get('controlData') ;
                        System.debug('successMap 2222 '+ jsonMap);
                        if(jsonMap.get('success') == true) {
                            jsonMap =   (Map<String,Object>)ResponseMap.get('data') ;
                            List<Object> recordList = (List<Object>)jsonMap.get('consumerCreditData');
                            for (Object eachRecord : recordList) {
                                jsonMap =   (Map<String,Object>)eachRecord ;
                                System.debug('SCOREEEEE  '+jsonMap.get('scores'));
                                if(jsonMap.containsKey('scores')) {
                                    recordList = (List<Object>)jsonMap.get('scores'); 
                                    for (Object Record : recordList) {
                                        jsonMap =   (Map<String,Object>)Record ;
                                        CibilScore = Integer.valueOf( jsonMap.get('score'));

                                        System.debug('SCORE LAST  '+jsonMap.get('score'));
                                    }
                                }
                            }
                        } else{
                            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                            verifyRecord.Failed_Reason__c = String.valueOf(jsonMap.get('errorResponseArray'))  ;
                            insert verifyRecord;
                            update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
                        }
                    }
                }
                if(CibilScore != NULL){
                    System.debug('CIBIL SCOREEEEE  '+CibilScore);
                    verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.COMPLETEDSTATUS);
                    verifyRecord.Cibil_Score__c =  String.valueOf( CibilScore);
                    insert verifyRecord;
                    System.debug('verifyRecord  '+verifyRecord);
                    UB_Cibil_API.saveAndLinkCibilResponse(verifyRecord.Id, JSONResponse);
                    update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
                    //Added by Mohit on 24th Sept- Reject the loan application when score is not acceptable
                    if(CibilScore != null && CibilScore >= 0){
                        CIbil_Score__mdt mdt = CIbil_Score__mdt.getInstance('Reject_LAF');
                        if(mdt.Lower_Limit__c >= 0 && mdt.Upper_Limit__c > 0){
                            if(CibilScore >= mdt.Lower_Limit__c && CibilScore <= mdt.Upper_Limit__c){
                                Loan_Application__c loanApplication = new Loan_Application__c(Id = loanAppList[0].Loan_Application__c);
                                loanApplication.Loan_Application_Status__c = UB_ConstantsUtil.REJECT_LOAN_STATUS;
                                loanApplication.Reject_Reason__c           = UB_ConstantsUtil.SYSTEM_REJECT;
                                loanApplication.Reject_Sub_Reason__c       = UB_ConstantsUtil.CIBIL_SCORE_NOT_ACCETABLE;
                                update loanApplication;
                            }
                        }
                    }
                    SYstem.debug('CIBIL REPORT   '+cibilReport);
                    SYstem.debug('CIBIL REPORT   '+cibilReport.length());
                    if(cibilReport.length() > 0 ) {
                        System.debug('YESSSSSSSS');
                        //String base64Content = EncodingUtil.Base64Encode( Blob.valueOf( cibilReport ) );
                        Blob blobContent = EncodingUtil.base64Decode(  cibilReport );
                        //Blob blobContent =  Blob.valueOf( cibilReport );
                        // method to store Cibil report in Document checklist.
                        UB_CommonUtil.createDocument('Cibil Report','CIBIL Report.html',blobContent,loanAppList[0].Loan_Application__c, customerId,'Cibil Report',NULL);
                    }
                        //saveAndLinkCibilResponse(applicantObj, JSONResponse);
                } 
            }
            System.debug('AAAAAAAAAAA1111  '+String.valueOf(ResponseMap).length());
            String jsonRequestBody = JSONResponse ;
            // code to check Reponse length > 131072 then replace base64 part.
            if(JSONResponse.length() > 131072) {
                String base64Json = jsonRequestBody.substringBetween('base64', ',');
                jsonRequestBody = jsonRequestBody.replace(base64Json, '": null');
                System.debug('jsonRequestBody  jsonRequestBody   '+jsonRequestBody);
            }
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                cibilApi.service.getEndpointURL(), 
                String.valueOf(cibilApi.service.getHeaderParameters()), 
                cibilApi.service.getRequestMethod(), 
                RequestJson, 
                jsonRequestBody, 
                responeObj.getStatusCode(), 
                UB_Cibil_API.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'CIBIL API',
                loanAppList[0].Loan_Application__r.LOB__c
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            }

        }catch(System.CalloutException e) {
            if(sp != NULL) {
                Database.rollback(sp);
            }
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);

            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);            
        }catch(Exception e) {
            if(sp != NULL) {
             Database.rollback(sp);
            }
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = +e.getMessage();
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Cibil_Verification__c = verifyRecord.Id);
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);
        }
        
    }

    public static void saveAndLinkCibilResponse( String verificationId, String cibilResponse){
        String base64Content = EncodingUtil.Base64Encode( Blob.valueOf( cibilResponse ) );
        Blob blobContent = EncodingUtil.base64Decode( base64Content );
        String profileName=[Select Id,Name from Profile where Id=: userinfo.getProfileId()].Name;
        ContentVersion cibilCvObj = new ContentVersion (Title = 'Cibil Response', PathOnClient = 'Cibil Response.json',VersionData = blobContent, FirstPublishLocationId = verificationId);
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME || profileName == BL_ConstantsUtil.PORTAL_PROFILE_NAME_BL) {
            cibilCvObj.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
        }
        insert cibilCvObj;
        System.debug('cibilCvObj RESPONSE  '+cibilCvObj);
   }
    
    
 

}