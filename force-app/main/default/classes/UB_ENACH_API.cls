/**
* @File Name          : UB_ENACH_API.cls
* @Description        : This API is used .......
* @Author             : Mohd Musab
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-07-2024               Mohd Musab                 Initial Version
*/
public class UB_ENACH_API {
	UB_HTTPCalloutService service;

    @future(callout = true)
    public static void getENach(Id disbursementId, String accessToken){
        System.debug('disbursementId '+disbursementId);
        System.debug('accessToken '+accessToken);
        //String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
        List<Disbursement__c> listOfDisbursement = [SELECT Id,Loan_Application__c,Loan_Amount__c,Tenure__c,ROI__c,First_EMI_Date__c,Last_Emi_Date__c,EMI_Amount__c from Disbursement__c WHERE Id =: disbursementId];
        List<Loan_Applicant__c> loanAppList = [SELECT Id,Name,Official_Email_ID__c,Mobile__c,Telephone__c,Loan_Application__c,Loan_Application__r.LOB__c,Pan_Number__c from Loan_Applicant__c WHERE Loan_Application__c =: listOfDisbursement[0].Loan_Application__c AND Is_Deleted__c = 'No' AND Applicant_Type__c =: UB_ConstantsUtil.APPLICANT LIMIT 1];
        List<Verification__c> insertVerifyRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
        try{
        //List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        List<Bank_Details__c> bankDetailList = [SELECT Id,Account_Number__c, Account_Type__c,IFSC_Code__r.Name from Bank_Details__c WHERE Is_Primary_Repayment_Account__c = true AND Loan_Application__c =: listOfDisbursement[0].Loan_Application__c LIMIT 1];
        System.debug('listOfDisbursement@@ '+listOfDisbursement);
        System.debug('loanAppList@@ '+loanAppList);
        System.debug('errorMessageConfigMap@@ '+errorMessageConfigMap);
        System.debug('bankDetailList@@ '+bankDetailList);

        UB_ENACH_API e_NachInstance = new UB_ENACH_API();
        e_NachInstance.service = new UB_HTTPCalloutService('E_NACH_API');

        JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('referenceNumber', 'NACHUTK12345679');
            gen.writeStringField('utilityCode', 'NACH00000000000019');
            gen.writeStringField('categoryCode', 'L002');
            gen.writeStringField('schmNm', 'Loan amount security');
            gen.writeStringField('consRefNo', 'NACHCRT000000091');
            gen.writeStringField('seqTp', 'RCUR');
            gen.writeStringField('frqcy', 'MNTH');
            gen.writeStringField('frstColltnDt', listOfDisbursement[0].First_EMI_Date__c != null ? String.Valueof(listOfDisbursement[0].First_EMI_Date__c): null);
            gen.writeStringField('fnlColltnDt', listOfDisbursement[0].Last_Emi_Date__c != null ? String.Valueof(listOfDisbursement[0].Last_Emi_Date__c) : null);
            gen.writeStringField('amountTp', 'MAXA');
            gen.writeStringField('colltnAmt', listOfDisbursement[0].EMI_Amount__c != null ? String.Valueof(listOfDisbursement[0].EMI_Amount__c):null);
            gen.writeStringField('dbtrNm', !String.isBlank(loanAppList[0].Name) ? loanAppList[0].Name : '');
            gen.writeStringField('phone', !String.isBlank(loanAppList[0].Telephone__c) ? loanAppList[0].Telephone__c : '');
            gen.writeStringField('mobile', !String.isBlank(loanAppList[0].Mobile__c) ? loanAppList[0].Mobile__c : '');
            gen.writeStringField('email', !String.isBlank(loanAppList[0].Official_Email_ID__c) ? loanAppList[0].Official_Email_ID__c : '');
            gen.writeStringField('pan', !String.isBlank(loanAppList[0].Pan_Number__c) ? loanAppList[0].Pan_Number__c : '');
            gen.writeStringField('bnkId', (bankDetailList.size()>0 && bankDetailList[0].IFSC_Code__r.Name != null) ? bankDetailList[0].IFSC_Code__r.Name.substring(0, 4):'');
            gen.writeStringField('dbtrAccTp', (bankDetailList.size()>0 && bankDetailList[0].Account_Type__c != null) ? String.valueOf(bankDetailList[0].Account_Type__c) : '' );
            gen.writeStringField('dbtrAccNo', (bankDetailList.size()>0 && bankDetailList[0].Account_Number__c != null) ? String.valueOf(bankDetailList[0].Account_Number__c) : '');
            gen.writeEndObject();
              e_NachInstance.service.setHeaderParameter('Authorization','Bearer '+accessToken);

        System.debug('URL params@@  '+e_NachInstance.service.getURLParameters());
        e_NachInstance.service.setRequestBody(gen.getAsString());        
        HttpResponse response = e_NachInstance.service.sendRequest(); 
        System.debug('response@@@ '+response);
        System.debug('response## '+response.getBody());
        String mockResponse = '{"timestamp":"2024-03-18T11:37:04.664674665Z","status":"200","code":"201","message":"2878091999088880f","moreInfo":"mandate request created.","reference":"81af5adc-1c26-457b-b694-0bd317b14923"}';
        Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        //Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(mockResponse);
            Verification__c verify = UB_CommonUtil.createVerfication(loanAppList[0].Id, UB_ConstantsUtil.ENACH_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.COMPLETEDSTATUS);
            verify.Disbursement__c = disbursementId;
            System.debug('verify@@ '+verify);
            //Verification__c verify = new Verification__c();
            if(response.getStatusCode() == 200){
                System.debug('Success##');
                if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('reference')){
                    verify.E_Nach_Reference__c = (String) String.valueOf(mapResponseResult.get('reference'));
                }else{
                    verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                    verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
                }
            }else{
                verify.Failed_Reason__c = errorMessageConfigMap.get('NoResultFound').Message__c;
                verify.Status__c = UB_ConstantsUtil.FAILED_STATUS;
            }
            insertVerifyRecords.add(verify);
            if(insertVerifyRecords.size()>0){
               insert insertVerifyRecords;
               update new Disbursement__c(Id = disbursementId, E_Nach_Verification__c = insertVerifyRecords[0].Id);
            }
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                e_NachInstance.service.getEndpointURL(), 
                String.valueOf(e_NachInstance.service.getHeaderParameters()), 
                e_NachInstance.service.getRequestMethod(), 
                gen.getAsString(), 
                response.getBody(), 
                response.getStatusCode(), 
                UB_ENACH_API.class.getName(), 
                loanAppList[0].Id, 
                Id.valueOf(loanAppList[0].Id).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'E-NACH API',
                UB_ConstantsUtil.LOB_CV
            );
            if(mapResponseResult.containsKey('status')){
                apiLogger.Status__c = (String) String.valueOf(mapResponseResult.get('status'));
            }
            createLogList.add(apiLogger);
            
            if(!createLogList.isEmpty() && createLogList.size() > 0){
                UB_API_LoggerUtility.insertRecords(createLogList);
            }
        }
        catch(Exception e) { 
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);   
            System.debug('Exception@@'+e.getMessage());   
            System.debug('Exception@@'+e.getLineNumber());      
        }
    }
}