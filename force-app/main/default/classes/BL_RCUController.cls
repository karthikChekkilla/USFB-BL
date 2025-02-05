/**
* @File Name          : BL_RCUController.cls
* @Description        : This class use to rcu changes related managers & vendors for BL specific changes.
* @Author             : Lakshya Verma
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0        14th-Aug-2024            Lakshya                  Initial version
**/
public class BL_RCUController {
    @AuraEnabled
    public static List<User> getRCUVendors(String loanApplicationId){
        try{
            if(String.isNotBlank(loanApplicationId) ){
               List<Loan_Application__c> loanApplicationList = [SELECT Id, Name, Branch__c FROM Loan_Application__c WHERE Id =: loanApplicationId 
                                                                AND Branch__c != null];
                if(!loanApplicationList.isEmpty()){
                    Set<Id> accountIds = new Set<Id>();
                    for(vendor_branch_mapping__c vendor : [SELECT Id, Name, Branch__c,Account__c, Account__r.Type_of_Valuer__c
                                                           FROM vendor_branch_mapping__c 
                                                           WHERE Branch__c != null  AND Branch__c =: loanApplicationList[0].Branch__c
                                                           AND Account__c != null AND Account__r.Type_of_Valuer__c != null 
                                                           AND Account__r.Type_of_Valuer__c = 'RCU Vendor' ]){
                                                               accountIds.add(vendor.Account__c);
                                                           }
                    if(!accountIds.isEmpty()){
                        Set<Id> contactIds = new Set<Id>();
                        for(Contact conObj : [SELECT Id, Name, AccountId from Contact WHERE AccountId != null 
                                                      AND AccountId =: accountIds]){
                            contactIds.add(conObj.Id);
                        }
                        
                        if(!contactIds.isEmpty()){
                            LisT<User> rcuVendorsList = [SELECT Id, contactId, Name FROM User WHERE contactId != null AND contactId =: contactIds ];
                            system.debug('rcuVendorsList-> ' + rcuVendorsList);
                            if(!rcuVendorsList.isEmpty()){
                                RETURN rcuVendorsList;
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug( e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static ResponseWrapper initiateRCUtoVendor(List<String> docIds, String selectedVendorId, String applicationId, String susTrigger){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            if(!docIds.isEmpty() && String.isNotBlank(selectedVendorId) && String.isNotBlank(applicationId) && String.isNotBlank(susTrigger)){
                List<Valuation__c> rcuManagerActivity = [SELECT Id, name, loan_application__c,BL_Vendor_Activity__c , 
                                                         RecordType_Name__c, Owner.name from Valuation__c  WHERE
                                                         loan_application__c  =: applicationId AND 
                                                         RecordType_Name__c =: BL_ConstantsUtil.RCU AND
                                                          ( Status__c = '' OR Status__c = 'Sampled')];
                if(!rcuManagerActivity.isEmpty()){
                    Valuation__c rcuVendorActivity = new Valuation__c();
                    rcuVendorActivity.recordtypeId = BL_ConstantsUtil.RCU_VENDOR_RECORDTYPE;
                    rcuVendorActivity.loan_application__c = applicationId;
                    rcuVendorActivity.OwnerId = selectedVendorId;
                    rcuVendorActivity.Suspicious_Triggers__c = susTrigger;
                    rcuVendorActivity.BL_Vendor_Activity__c = rcuManagerActivity[0].Id;
                    INSERT rcuVendorActivity;
                    
                    //rcuManagerActivity[0].BL_Vendor_Activity__c = rcuVendorActivity.Id;
                    //UPDATE rcuManagerActivity;
                    
                    List<Document__c> documentList = [SELECT Id, Name,Valuation__c  FROM Document__c WHERE Id IN : docIds];
                    for(Document__c doc : documentList){
                        doc.Valuation__c = rcuVendorActivity.Id;
                    }
                    UPDATE documentList;
                    
                    SYSTEM.debug('rcuVendorActivity-> ' + rcuVendorActivity);
                    SYSTEM.debug('documentList-> ' + documentList);
                    resWrap.isSuccess = true;
                    resWrap.responseBody = 'Successfully Initiated to RCU Vendor';
                }else{
                    resWrap.isSuccess = false;
                    resWrap.responseBody = 'Something went wrong';
                }
            }
            return resWrap;
        }catch(Exception error){
            String exError = JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            resWrap.isSuccess = false;
            resWrap.responseBody = exError;
            return resWrap;
        }
    }
    
     @AuraEnabled
    public static ResponseWrapper rcuWaiveActivityByManager(String loanApplicationId){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            List<Valuation__c> rcuActvity = [SELECT Id from Valuation__c 
                                             WHERE loan_application__c =: loanApplicationId AND (RecordType_Name__c =: BL_ConstantsUtil.RCU)
                                             /*AND (Status__c != 'Screened' OR Status__c ='' )*/ ];
            if(!rcuActvity.isEmpty()){
                resWrap.isSuccess = true;
                resWrap.responseBody = 'RCU Activity is already initiated.';
            }else{
                resWrap.rcuWaive = true;
            }
            RETURN resWrap;
        }catch(Exception error){
            String exError = JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            resWrap.isSuccess = false;
            resWrap.responseBody = exError;
            return resWrap;
        }
    }
    
    @AuraEnabled
    public static List<Valuation__c> getRCUActivityStatus(String loanApplicationId){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            List<Valuation__c> rcuActvity = [SELECT Id, Status__c from Valuation__c 
                                             WHERE loan_application__c =: loanApplicationId AND (RecordType_Name__c =: BL_ConstantsUtil.RCU) 
                                             AND (RecordType_Name__c = 'RCU') 
                                             AND (Status__c != 'Screened' OR Status__c = '' ) ];
            if(!rcuActvity.isEmpty()){
                resWrap.isSuccess = true;
                resWrap.responseBody = JSON.serialize(rcuActvity[0].Status__c);
                 RETURN rcuActvity;
            }else{
                resWrap.isSuccess = false;
                RETURN null;
            }
        }catch(Exception error){
            String exError = JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            resWrap.isSuccess = false;
            resWrap.responseBody = exError;
            return null;
        }
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
        @AuraEnabled public Boolean rcuWaive;
    }
}