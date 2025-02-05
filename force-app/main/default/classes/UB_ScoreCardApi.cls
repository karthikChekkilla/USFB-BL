/**
* @File Name          : UB_ScoreCardApi.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         06-06-2024            Zafaruddin         Initial Version

**/

public class UB_ScoreCardApi {

    UB_HTTPCalloutService service;

    public static String createRequestBody(Id customerId) {
        String reqJSON ;
        UB_ScoreCardApi scoreCardApi = new UB_ScoreCardApi();
        scoreCardApi.service = new UB_HTTPCalloutService('Score_Card_Api');
        Map<String,Object>  mapCibilResp;
        List<Object> listCibilAccntDetails;
        List<CibilAccountWrapper> listCibilAccntWrapper = new List<CibilAccountWrapper>();
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        System.debug('APPLICATION ID   '+loanAppList[0].Loan_Application__c);
        List<Address__c> applicantResidenceAddressList = [SELECT Id,Pincode__r.Name FROM Address__c WHERE Loan_Applicant__c = : customerId];
        List<Verification__c> cibilVerificationList = [SELECT Id,Name,Cibil_Score__c FROM Verification__c WHERE Loan_Applicant__c = : customerId AND RecordTypeId=:UB_ConstantsUtil.CIBIL_VERIFICATION_RECORD_TYPE Order By createdDate DESC LIMIT 1 ];
        System.debug('cibilVerificationList  '+cibilVerificationList);
        String apptDate = '';
        if( loanAppList[0].Loan_Application__r.CreatedDate <> Null ){
            apptDate = loanAppList[0].Loan_Application__r.CreatedDate.year() + '-';
            apptDate += loanAppList[0].Loan_Application__r.CreatedDate.month() >= 10 ? loanAppList[0].Loan_Application__r.CreatedDate.month() + '-' : '0'+loanAppList[0].Loan_Application__r.CreatedDate.month()+'-';
            apptDate += loanAppList[0].Loan_Application__r.CreatedDate.day() >= 10 ? loanAppList[0].Loan_Application__r.CreatedDate.day()+'': '0'+loanAppList[0].Loan_Application__r.CreatedDate.day();
        }
        String dob = '';
        if( loanAppList[0].Date_of_Birth__c <> Null ){
            dob = loanAppList[0].Date_of_Birth__c.year() + '-';
            dob += loanAppList[0].Date_of_Birth__c.month() >= 10 ? loanAppList[0].Date_of_Birth__c.month() + '-' : '0'+loanAppList[0].Date_of_Birth__c.month()+'-';
            dob += loanAppList[0].Date_of_Birth__c.day() >= 10 ? loanAppList[0].Date_of_Birth__c.day()+'': '0'+loanAppList[0].Date_of_Birth__c.day();
        }
       // List<Api_Logger__c> cibilApiLogger = [ SELECT Id, Name,Response__c  FROM Api_Logger__c WHERE Record_Id__c=:customerId AND Class_Name__c=:UB_ConstantsUtil.CIBIL_CLASS Order By Name DESC ];
        //String cibilResponse = cibilApiLogger[0].Response__c;

        // code to get Cibil Response from Stored Files.
        List<ContentDocumentLink> listContDoc = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :cibilVerificationList[0].Id ];
         System.debug( 'listContDocumentttttttt' +listContDoc);
        List<ContentVersion> listContentVersion = [ SELECT VersionData FROM ContentVersion
                                                   WHERE IsLatest = true AND ContentDocumentId =: listContDoc[0].ContentDocumentId];
         System.debug( 'ContentVersionhhhhhhhh' +listContentVersion);
 
        String cibilResponse = listContentVersion[0].VersionData.toString();


        reqJSON = '{"StrategyOneRequest": {"Header": {';
        reqJSON += '"InquiryCode": "' + scoreCardApi.service.getExtraParameter('InquiryCode') + '",';
        reqJSON += '"ProcessCode": "' + scoreCardApi.service.getExtraParameter('ProcessCode') + '"},';
        reqJSON += '"Body": {"APPLICATION": {"Variables": {';
        reqJSON += '"APPLICATION_ID": "' + loanAppList[0].Loan_Application__r.Name.split('-')[1] + '",';
        reqJSON += '"APPLICATION_DATE": "' + apptDate + '"},';
        reqJSON += '"Categories": [{"CUSTOMER": {"Variables": {';
        reqJSON += '"DOB": "' + dob + '",';
        reqJSON += '"EMPLOYMENT_CATEGORY": "' + 'E' + '",'; // hard coded passed as now we dont have any value to map.
        reqJSON += '"NET_MONTHLY_INCOME": "' + loanAppList[0].Monthly_Income__c + '",';
        reqJSON += '"RESIDENTIAL_PINCODE": ' + (applicantResidenceAddressList != NULL ? applicantResidenceAddressList[0].Pincode__r.Name : ' ') + ',';
        reqJSON += '"BUREAU_SCORE": ' +  (cibilVerificationList != NULL  ? String.valueOf(cibilVerificationList[0].Cibil_Score__c) : '') + '},';
        mapCibilResp = (Map<String, Object>)JSON.deserializeUntyped(cibilResponse);
        //system.debug('mapCibilResp'+mapCibilResp);
        Map<String, Object> dataMap = (Map<String, Object>)mapCibilResp.get('data');
        mapCibilResp = (Map<String,Object>) ((List<Object>)dataMap.get('consumerCreditData'))[0];
        listCibilAccntDetails = (List<Object>)mapCibilResp.get('accounts');
        listCibilAccntDetails = listCibilAccntDetails == Null ? new List<CibilAccountWrapper>() : listCibilAccntDetails;
       // System.debug( 'listCibilAccntDetails'+ listCibilAccntDetails);
        String strCibilAccntDetails = JSON.serialize(listCibilAccntDetails, true).replaceAll('index', 'candidateId');
        listCibilAccntWrapper = (List<CibilAccountWrapper>) System.JSON.deserialize( strCibilAccntDetails, List<CibilAccountWrapper>.class );
       // System.debug('listCibilAccntWrapper11111111'+ listCibilAccntWrapper  );
        List<String> listBureauEnquiryDetails = new List<String>();
        for( CibilAccountWrapper objCibilAccnt : listCibilAccntWrapper ){
            if( objCibilAccnt.dateOpened <> Null ){ //
                objCibilAccnt.dateOpened = objCibilAccnt.dateOpened.substring(4, 8)+'-'+objCibilAccnt.dateOpened.substring(2, 4)+'-'+objCibilAccnt.dateOpened.substring(0, 2);
            }

            if( objCibilAccnt.lastPaymentDate <> Null ){
                objCibilAccnt.lastPaymentDate = objCibilAccnt.lastPaymentDate.substring(4, 8)+'-'+objCibilAccnt.lastPaymentDate.substring(2, 4)+'-'+objCibilAccnt.lastPaymentDate.substring(0, 2);
            }

            if( objCibilAccnt.dateClosed <> Null ){
                objCibilAccnt.dateClosed = objCibilAccnt.dateClosed.substring(4, 8)+'-'+objCibilAccnt.dateClosed.substring(2, 4)+'-'+objCibilAccnt.dateClosed.substring(0, 2);
            }

            if( objCibilAccnt.dateReported <> Null ){
                objCibilAccnt.dateReported = objCibilAccnt.dateReported.substring(4, 8)+'-'+objCibilAccnt.dateReported.substring(2, 4)+'-'+objCibilAccnt.dateReported.substring(0, 2);
            }

            if( objCibilAccnt.paymentStartDate <> Null ){
                objCibilAccnt.paymentStartDate = objCibilAccnt.paymentStartDate.substring(4, 8)+'-'+objCibilAccnt.paymentStartDate.substring(2, 4)+'-'+objCibilAccnt.paymentStartDate.substring(0, 2);
            }

            if( objCibilAccnt.paymentEndDate <> Null ){
                objCibilAccnt.paymentEndDate = objCibilAccnt.paymentEndDate.substring(4, 8)+'-'+objCibilAccnt.paymentEndDate.substring(2, 4)+'-'+objCibilAccnt.paymentEndDate.substring(0, 2);
            }

            if( objCibilAccnt.errorDate <> Null ){
                objCibilAccnt.errorDate = objCibilAccnt.errorDate.substring(4, 8)+'-'+objCibilAccnt.errorDate.substring(2, 4)+'-'+objCibilAccnt.errorDate.substring(0, 2);
            }

            if( objCibilAccnt.cibilRemarksDate <> Null ){
                objCibilAccnt.cibilRemarksDate = objCibilAccnt.cibilRemarksDate.substring(4, 8)+'-'+objCibilAccnt.cibilRemarksDate.substring(2, 4)+'-'+objCibilAccnt.cibilRemarksDate.substring(0, 2);
            }

            if( objCibilAccnt.errorRemarksDate <> Null ){
                objCibilAccnt.errorRemarksDate = objCibilAccnt.errorRemarksDate.substring(4, 8)+'-'+objCibilAccnt.errorRemarksDate.substring(2, 4)+'-'+objCibilAccnt.errorRemarksDate.substring(0, 2);
            }
            listBureauEnquiryDetails.add( '{"BUREAU": {"Variables":' + JSON.serialize( objCibilAccnt , true) + '}}');
        }//end of CibilAccountWrapper Loop
        //System.debug(  'listBureauEnquiryDetails - ' + listBureauEnquiryDetails );
        reqJSON += '"Categories":';
        if( listBureauEnquiryDetails.isEmpty()){
            reqJSON += '[]';
        }else{
            reqJSON += '['+ String.join(listBureauEnquiryDetails, ',') +']';
        }
        reqJSON +=  '}}]}}}}';
        return reqJSON ;
    }

    /**
    * @author Zafaruddin | 06-05-2024  
    * @param customerId 
    * @param accessToken 
    **/
    @future(callout = true)
    public static void getScoreCard (Id customerId, String accessToken){
        
        Verification__c verifyRecord = new Verification__c();
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        try {
            //System.debug('customerId   '+customerId);
           // System.debug('TOKENNNNN  '+accessToken);
            UB_ScoreCardApi scoreCardApi = new UB_ScoreCardApi();
            scoreCardApi.service = new UB_HTTPCalloutService('Score_Card_Api');
            scoreCardApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
            // function call to prepare request body.
            String requestBody = UB_ScoreCardApi.createRequestBody(customerId);
            System.debug(' Final S1 Request JSON - ' + requestBody);
            scoreCardApi.service.setRequestBody(requestBody);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = scoreCardApi.service.sendRequest();
            System.debug('responeObj   '+responeObj);
            system.debug( 'RESPONSE BODY - ' + responeObj.getBody());
            if(responeObj.getStatusCode() != 200) {
                verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                verifyRecord.Failed_Reason__c = UB_ConstantsUtil.SCORECARD_API_MESSAGE  ;
            }
            String jsonResponse = responeObj.getBody();
            Map<String,Object> ResponseMap = (Map<String,Object>)JSON.deserializeUntyped(jsonResponse);
            system.debug('mock response  '+ResponseMap);
            if(ResponseMap.get('StrategyOneResponse') != NULL) {
                System.debug('ResponseMap.StrategyOneResponse  '+ResponseMap.get('StrategyOneResponse'));
                ResponseMap = (Map<String,Object>)ResponseMap.get('StrategyOneResponse');
                if(ResponseMap.get('Body') != NULL) {
                    System.debug('ResponseMap.Body  '+ResponseMap.get('Body'));
                    ResponseMap = (Map<String,Object>)ResponseMap.get('Body');
                    if(ResponseMap.get('APPLICATION') != NULL) {
                        System.debug('ResponseMap.Body  '+ResponseMap.get('APPLICATION'));
                        ResponseMap = (Map<String,Object>)ResponseMap.get('APPLICATION');
                        if(ResponseMap.get('Variables') != NULL) {
                            System.debug('ResponseMap.Body  '+ResponseMap.get('Variables'));
                            ResponseMap = (Map<String,Object>)ResponseMap.get('Variables');
                            System.debug('ResponseMap.FINAL  '+ResponseMap);
                            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.COMPLETEDSTATUS);
                            verifyRecord.APPLICATION_ID__c = String.valueOf(ResponseMap.get('APPLICATION_ID'));
                            verifyRecord.FINAL_SCORE__c = Integer.valueOf(ResponseMap.get('FINAL_SCORE'));
                            verifyRecord.V1__c =   Integer.valueOf(ResponseMap.get('V1'));
                            verifyRecord.V2__c = Integer.valueOf(ResponseMap.get('V2'));
                            verifyRecord.V3__c = Integer.valueOf(ResponseMap.get('V3'));
                            verifyRecord.V4__c = Integer.valueOf(ResponseMap.get('V4'));
                            verifyRecord.V5__c = Integer.valueOf(ResponseMap.get('V5'));
                            verifyRecord.V6__c = Integer.valueOf(ResponseMap.get('V6'));
                            verifyRecord.V7__c = Integer.valueOf(ResponseMap.get('V7'));
                            verifyRecord.V8__c = Integer.valueOf(ResponseMap.get('V8'));
                            verifyRecord.V9__c = Integer.valueOf(ResponseMap.get('V9'));
                        } else {
                            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                        }
                    
                    } else {
                        verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                    }
                } else {
                    verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
                }
            } else {
                verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SCORE_CARD_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            }
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, ScoreCard_Verification__c = verifyRecord.Id);
            System.debug('verifyRecord  '+verifyRecord);
            System.debug('verifyRecord STATUSSSS  '+verifyRecord.Status__c);
            System.debug('UB_ConstantsUtil.COMPLETEDSTATUS  '+UB_ConstantsUtil.COMPLETEDSTATUS);
            // code to update Is Retrigger S1 checkbox false when Score Card Api is Completed
            if(verifyRecord != NULL && verifyRecord.Status__c == UB_ConstantsUtil.COMPLETEDSTATUS) {
                System.debug('YESSSSSSSSS');
                Loan_Application__c loanApplication = new Loan_Application__c();
                loanApplication.Id = loanAppList[0].Loan_Application__c;
                loanApplication.Is_Retrigger_S1__c = false;
                update loanApplication;
            }
            
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                scoreCardApi.service.getEndpointURL(), 
                String.valueOf(scoreCardApi.service.getHeaderParameters()), 
                scoreCardApi.service.getRequestMethod(), 
                requestBody, 
                jsonResponse, 
                responeObj.getStatusCode(), 
                UB_ScoreCardApi.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'Score Card API',
                UB_ConstantsUtil.LOB_CV
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            } 
        } catch(Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        
       
    }


    //Cibil JSON  Account Wrapper
    public class CibilAccountWrapper{
        public String candidateId;  //T001  instead of index used candidateId as index was reserved keyword in S1
        public String memberShortName;  //NOT DISCLOSED
        public String accountNumber;    //XXXX4321
        public String accountType;  //05
        public String ownershipIndicator;   //1
        public String dateOpened;   //31122018
        public String lastPaymentDate;  //04032019
        public String dateClosed;   //01011900
        public String dateReported; //31032019
        public String highCreditAmount; //34000
        public String currentBalance;   //33372
        public String amountOverdue;    //0
        public String paymentHistory;   //000XXX000000
        public String paymentStartDate; //01032019
        public String paymentEndDate;   //01122022
        public String suitFiled;    //00
        public String creditFacilityStatus; //00
        public String collateralValue;  //000123456
        public String collateralType;   //01
        public String creditLimit;  //000023434
        public String cashLimit;    //000000200
        public String interestRate; //24.13
        public String paymentTenure;    //48
        public String emiAmount;    //1392
        public String woAmountTotal;    //2343
        public String woAmountPrincipal;    //78787
        public String settlementAmount; //67676
        public String paymentFrequency; //03
        public String actualPaymentAmount;  //1392
        public String errorDate;    //12122022
        public String errorCode;    //009
        public String cibilRemarksDate; //12122022
        public String cibilRemarksCode; //TL1008
        public String errorRemarksDate; //12122022
        public String errorRemarksCode1;    //000001
    }


}