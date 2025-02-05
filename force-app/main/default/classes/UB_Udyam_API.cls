/**
* @File Name          : UB_Udyam_API.cls
* @Description        : This API is used to fetch Udyam for the non-individual customer.
* @Author             : Mohit Saxena
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-07-2024               Mohit Saxena          Initial Version
*/
public class UB_Udyam_API {
    UB_HTTPCalloutService service;
    
    public static void fetchPdfData (Id customerId, String accessToken){
        Map<String,Messages_Config__mdt> errorMessageConfigMap = UB_CommonUtil.getMessageRecord('GenericErrorMessage');
        List<Verification__c> insertRecords = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerId});
        List<Verification_Line_Item__c> insertLineItemRecords = new List<Verification_Line_Item__c>();

        //Savepoint sp = Database.setSavepoint();
        try{
            if(String.isNotBlank(accessToken)){
                UB_Udyam_API udyamAPI = new UB_Udyam_API();
                udyamAPI.service = new UB_HTTPCalloutService('Udyam_API');
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('consent','Y');
                gen.writeStringField('udyamRegistrationNo',loanAppList[0].BL_URC__c);
                gen.writeStringField('isPDFRequired','Y');
                gen.writeStringField('getEnterpriseDetails','Y');
                gen.writeFieldName('clientData');
                gen.writeStartObject();
                //gen.writeStringField('caseId',loanAppList[0].Id);
                gen.writeStringField('caseId','123456');
                gen.writeEndObject();
                gen.writeEndObject();
                
                udyamAPI.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                udyamAPI.service.setRequestBody(gen.getAsString());        
                HttpResponse response = new HttpResponse(); 
                if(udyamAPI.service.calloutMetadata.Active__c){
                    response = udyamAPI.service.sendRequest();
                }else{
                    response.setStatusCode(200);
                    response.setBody(udyamAPI.service.calloutMetadata.Mock_Response__c);
                } 
                Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.UDYAM_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.COMPLETEDSTATUS);
                if(response.getStatusCode() == 200){
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('result')){
                        Map<String,Object> mapResponseBody = (Map<String,Object>) (mapResponseResult.get('result'));
                        if(mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('pdfData')){
                            Blob blobContent = EncodingUtil.base64Decode((String) String.valueOf(mapResponseBody.get('pdfData')));
                            UB_CommonUtil.createDocument('Udyam Certificate', 'Udyam Certificate.pdf', blobContent, loanAppList[0].Loan_Application__c, loanAppList[0].Id, 'Udyam Certificate', null);
                        }
                        if(mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('industry')){
                            List<Object> industryList = (List<Object>) (mapResponseBody.get('industry'));
                            if(!industryList.isEmpty() && industryList.size() > 0){
                                for(Object obj : industryList){
                                    Verification_Line_Item__c lineItem = new Verification_Line_Item__c();
                                    lineItem.RecordTypeId      = UB_ConstantsUtil.UDYAM_PSL_VERIFY_LINE_ITEM_RECORD_TYPE;
                                    lineItem.PSL_Category__c   = UB_ConstantsUtil.PSL_CATEGORY;
                                    lineItem.Loan_Applicant__c = customerId;
                                    Map<String,Object> mapIndustryData = (Map<String,Object>) obj;
                                    if(mapIndustryData.containsKey('industry')){
                                        lineItem.PSL_Sub_Category__c = (String) String.valueOf(mapIndustryData.get('industry'));
                                    }
                                    if(mapIndustryData.containsKey('subSector')){
                                        lineItem.PSL_Sub_Sub_Category__c = (String) String.valueOf(mapIndustryData.get('subSector'));
                                    }
                                    insertLineItemRecords.add(lineItem);
                                }
                            }
                        }
                    }
                }
                insertRecords.add(verify); 
                
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    udyamAPI.service.getEndpointURL(), 
                    String.valueOf(udyamAPI.service.getHeaderParameters()), 
                    udyamAPI.service.getRequestMethod(), 
                    gen.getAsString(), 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_Udyam_API.class.getName(), 
                    customerId, 
                    Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'Udyam API',
                    loanAppList[0].Loan_Application__r.LOB__c
                );
                createLogList.add(apiLogger);
                if(!createLogList.isEmpty() && createLogList.size() > 0){
                    // Set up the unit of work
                    fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{API_Logger__c.sObjectType});
                    uow.registerNew(createLogList);
                    // Commit all of the work at a safe moment
                    uow.commitWork();
                }
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            //Database.releaseSavepoint(sp);
            Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.UDYAM_VERIFICATION_RECORD_TYPE, UB_ConstantsUtil.FAILED_STATUS);
            verify.Failed_Reason__c = e.getMessage();
            insertRecords.add(verify); 
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, loanAppList[0].Loan_Application__r.LOB__c);
        }
        
        if(!insertRecords.isEmpty() && insertRecords.size() > 0){
            insertRecords = UB_VerificationUtility.insertRecords(insertRecords);
            UB_LoanApplicantUtility.updateRecords(new List<Loan_Applicant__c>{new Loan_Applicant__c(Id = customerId, Udyam_Verification__c = insertRecords[0].Id)});
            if(!insertLineItemRecords.isEmpty() && insertLineItemRecords.size() > 0){
                for(Verification_Line_Item__c obj : insertLineItemRecords){
                    obj.Verification__c = insertRecords[0].Id;
                }
                insert insertLineItemRecords;
            }
        }
    }
}