/**
* @File Name          : UB_SyncLeadService.cls
* @Description        : API to create Lead to the external system.
* @Author             : Mohit
* @Test CLass         : UB_SyncLeadServiceTest
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         21-03-2024               Mohit                 Initial Version
*/
public class UB_SyncLeadService {
    UB_HTTPCalloutService service;
    
    @future(callout=true)
    public static void doExternalCallout(Set<Id> leadIdSet) {
        //Savepoint sp = Database.setSavepoint();
        UB_SyncLeadService syncLeadAPI = new UB_SyncLeadService();
        syncLeadAPI.service = new UB_HTTPCalloutService('External_Lead_Creation_API');
        List<Lead__c> leadRecords = new UB_LeadsSelector().selectById(leadIdSet);

        try{
            if(syncLeadAPI.service.calloutMetadata != null){
                List<Lead__c> updateLeadList = new List<Lead__c>(); 
                List<API_Logger__c> createLogList = new List<API_Logger__c>(); 
                List<UB_CreateLeadService.LeadDetails> wrapperList = new List<UB_CreateLeadService.LeadDetails>();
                
                for(Lead__c ldObj : leadRecords){
                    UB_CreateLeadService.LeadDetails ldWrapper = new UB_CreateLeadService.LeadDetails();
                    ldWrapper.Customer_Type    = String.isNotBlank(ldObj.Customer_Type__c) ? ldObj.Customer_Type__c : '';
                    ldWrapper.Customer_Name    = String.isNotBlank(ldObj.First_Name__c) ? ldObj.First_Name__c : '';
                    ldWrapper.Customer_Name   += String.isNotBlank(ldObj.Middle_Name__c) ? ldObj.Middle_Name__c : '';
                    ldWrapper.Customer_Name   += String.isNotBlank(ldObj.Last_Name__c) ? ldObj.Last_Name__c : '';
                    ldWrapper.Mobile_Number    = String.isNotBlank(ldObj.Mobile_Number__c) ? ldObj.Mobile_Number__c : '';
                    ldWrapper.Lead_Source      = String.isNotBlank(ldObj.Lead_Source__c) ? ldObj.Lead_Source__c : '';
                    ldWrapper.Campaign_Type    = String.isNotBlank(ldObj.Campaign_Type__c) ? ldObj.Campaign_Type__c : '';
                    ldWrapper.Lead_Nature      = String.isNotBlank(ldObj.Lead_Nature__c) ? ldObj.Lead_Nature__c : '';
                    ldWrapper.Lead_Status      = String.isNotBlank(ldObj.Lead_Status__c) ? ldObj.Lead_Status__c : '';
                    ldWrapper.Department       = String.isNotBlank(ldObj.Department__c) ? ldObj.Department__c : '';
                    ldWrapper.Product_Vertical = String.isNotBlank(ldObj.Product_Vertical__c) ? ldObj.Product_Vertical__c : '';
                    ldWrapper.Product_Category = String.isNotBlank(ldObj.Product_Category__c) ? ldObj.Product_Category__c : '';
                    ldWrapper.Product_Name     = String.isNotBlank(ldObj.Product_Name__c) ? ldObj.Product_Name__c : '';
                    //ldWrapper.Product_Code     = String.isNotBlank(ldObj.Product_Code__c) ? ldObj.Product_Code__c : '';
                    ldWrapper.Branch           = String.isNotBlank(ldObj.Branch__c) ? ldObj.Branch__r.Name : '';
                    ldWrapper.Gender           = String.isNotBlank(ldObj.Gender__c) ? ldObj.Gender__c : '';
                    ldWrapper.Amount           = ldObj.Amount__c != null && ldObj.Amount__c > 0 ? String.valueOf(ldObj.Amount__c) : '';
                    ldWrapper.Loan_Period      = ldObj.Loan_Period__c != null && ldObj.Loan_Period__c > 0 ? String.valueOf(ldObj.Loan_Period__c) : '';
                    ldWrapper.PAN              = String.isNotBlank(ldObj.PAN__c) ? ldObj.PAN__c : '';
                    if(ldObj.Addresses__r.size() > 0){
                        //ldWrapper.City             = String.isNotBlank(ldObj.Addresses__r) ?  : '';	
                        //ldWrapper.State            = String.isNotBlank() ?  : '';
                        //ldWrapper.Pin_Code         = String.isNotBlank() ?  : '';
                    }
                    ldWrapper.Platform         = String.isNotBlank(ldObj.Platform__c) ? ldObj.Platform__c : '';
                    wrapperList.add(ldWrapper);
                }
                
                if(!wrapperList.isEmpty() && wrapperList.size() > 0){
                    syncLeadAPI.service.setRequestBody(JSON.serialize(wrapperList));
                    HttpResponse response = syncLeadAPI.service.sendRequest(); 
                    Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if(response.getStatusCode() == 200){
                        if(mapResponseResult.keySet().size() > 0 && mapResponseResult.containsKey('data')){
                            Map<String,Object> mapResponseBody = (Map<String,Object>) (mapResponseResult.get('data'));
                            if(mapResponseBody != null && mapResponseBody.keySet().size() > 0 && mapResponseBody.containsKey('leadId')){
                                for(String leadId : leadIdSet){
                                    updateLeadList.add(new Lead__c(Id = leadId,LeMS_Lead_ID__c = (String) String.valueOf(mapResponseBody.get('leadId'))));
                                }
                                
                                if(!updateLeadList.isEmpty() && updateLeadList.size() > 0){
                                    UB_LeadUtility.updateRecords(updateLeadList);
                                }
                            }
                        }
                    }
                    API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                        syncLeadAPI.service.getEndpointURL(), 
                        String.valueOf(syncLeadAPI.service.getHeaderParameters()), 
                        syncLeadAPI.service.getRequestMethod(), 
                        JSON.serialize(wrapperList), 
                        response.getBody(), 
                        response.getStatusCode(), 
                        UB_SyncLeadService.class.getName(), 
                        String.valueOf(new List<Id>(leadIdSet)[0]), 
                        Id.valueOf(new List<Id>(leadIdSet)[0]).getSObjectType().getDescribe().getName(), 
                        UB_ConstantsUtil.REST_API_TYPE,
                        'SyncLeadExternalAPI',
                        leadRecords[0].LOB__c
                    );
                    if(mapResponseResult.containsKey('status')){
                        apiLogger.Status__c = (String) String.valueOf(mapResponseResult.get('status'));
                    }
                    createLogList.add(apiLogger);
                    if(!createLogList.isEmpty() && createLogList.size() > 0){
                        UB_API_LoggerUtility.insertRecords(createLogList);
                    }
                }
            }
        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, leadRecords[0].LOB__c);
        }
    }
    
    @InvocableMethod
    public static void syncLeadToExternalSystem(List<Id> leadIdSet){
        System.debug('Invocable- '+leadIdSet);
        UB_SyncLeadService.doExternalCallout(new Set<Id>(leadIdSet));
    }
}