/**
* @File Name          : UB_LoanApplicationRejectController.cls
* @Description        : This class use to loanApplicationReject LWC
* @Author             : Kamal Hussain
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-04-2024            Deepak Joshi      Initial Version           
**/
public with sharing class UB_LoanApplicationRejectController {
    @AuraEnabled
    public static string getUserManager(){
        try {
            
            User userRec = [SELECT Id, ManagerId FROM User WHERE Id =:userInfo.getUserId()];
            if(userRec.ManagerId !=null ) {
                
                return userRec.ManagerId;
            }
            return userInfo.getUserId();
            
        } catch (Exception e) {
            
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static boolean rejectLead(string leadId, string reason, string subReason) {
        system.debug(leadId);
        system.debug(reason);
        system.debug(subReason);
        
        
        user userRec = [SELECT id, contact.account.Relationship_Manager__c FROM user WHERE id =:userInfo.getUserId()];
        system.debug('userRec=='+userRec);
        string managerId = null;
        if(userRec.contact.account.Relationship_Manager__c !=null) {
            managerId = userRec.contact.account.Relationship_Manager__c;
        }    
        system.debug('managerId=='+managerId);
        lead__c leadRec = new lead__c();
        leadRec.id = leadId;
        leadRec.Lead_Status__c = 'Rejected';
        leadRec.Rejected_By__c = userInfo.getUserId();
        leadRec.Reject_Reason__c = reason;
        leadRec.Reject_Sub_Reason__c = subReason;
        if(managerId !=null)
            leadRec.OwnerId = managerId;
        
        
        system.debug('update leadRec > ' + leadRec);
        try{
            
            update leadRec;
            return true;
            
        }catch(Exception ex){
            System.debug('Exception type caught: ' + ex.getTypeName());    
            System.debug('Message: ' + ex.getMessage());    
            System.debug('Cause: ' + ex.getCause());    
            System.debug('Line number: ' + ex.getLineNumber());    
            System.debug('Stack trace: ' + ex.getStackTraceString());  
        }
        return false;      
        
    }
    
    @AuraEnabled //method added on 29-07-2024 by lakshya for getting the values of reject reasons for BL project
    public static List<Reject_Reason_Master__mdt> getRejectReasonsList(){
        List<Reject_Reason_Master__mdt> listRejectReasons = [SELECT Id,  Rejection_Reason__c, Rejection_Sub_Reason__c
                                                             FROM Reject_Reason_Master__mdt WHERE LOB__c = 'BL' AND
                                                             Rejection_Reason__c != null];
        RETURN listRejectReasons;
    }
    
    @AuraEnabled //method added on 29-07-2024 by lakshya for getting the values of Cancel reasons for BL project
    public static List<Reject_Reason_Master__mdt> getCancelReasonsList(){
        List<Reject_Reason_Master__mdt> listRejectReasons = [SELECT Id, Label, LOB__c, Invoke_From__c,
                                                             Cancel_Reason__c, Cancellation_Source__c FROM Reject_Reason_Master__mdt WHERE
                                                             Cancel_Reason__c != null and Invoke_From__c = 'Cancel'];
        RETURN listRejectReasons;
    }
    
    
    @AuraEnabled
    public static ResponseWrapper captureRejectResponse(String lafId, String reasons, String subReasons, String comments, String recordTypeName, String rejectType){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            if(String.isNotBlank(lafId)){
                List<Loan_Application__c> loanApplication = new List<Loan_Application__c>();
                if(String.isNotBlank(reasons) && String.isNotBlank(subReasons) /*&& String.isNotBlank(comments) && String.isNotBlank(recordTypeName)*/ ){
                    
                    List<Reject_Reason_Master__mdt> listMetaData = [SELECT Id, Label, LOB__c, Rejection_Reason__c, 
                                                                    Rejection_Sub_Reason__c, Rejection_Type__c,
                                                                    Reject_Validity__c FROM 
                                                                    Reject_Reason_Master__mdt WHERE LOB__c = 'BL' 
                                                                    AND Rejection_Reason__c =: reasons AND 
                                                                    Rejection_Sub_Reason__c =: subReasons
                                                                   ];
                    Integer validity = Integer.valueOf(listMetaData[0].Reject_Validity__c);
                    if(listMetaData.size() > 0){
                        if(listMetaData.size() > 0){
                            String ownerId = '';
                            for(Loan_Application__c loanObj : [SELECT Id, BL_Reject_Type__c, BL_Soft_Reject_Date__c, BL_Validity_End_Date__c, 
                                                               Reject_Reason__c, Reject_Sub_Reason__c, Loan_Application_Status__c , Comment__c,
                                                               RecordType.Name, OwnerId, Ro_RM__c
                                                               FROM Loan_Application__c WHERE Id =: lafId]){
                                                                   loanObj.BL_Reject_Type__c = rejectType;
                                                                   loanObj.BL_Soft_Reject_Date__c = system.today();
                                                                   loanObj.Comment__c = String.isNotBlank(comments) ? comments : null;
                                                                   loanObj.BL_Validity_End_Date__c = Date.valueOf(system.today() + validity);
                                                                   loanObj.Reject_Reason__c = reasons;
                                                                   loanObj.Reject_Sub_Reason__c = subReasons;
                                                                   loanObj.Loan_Application_Status__c = 'Rejected';
                                                                   //if(loanObj.RecordType.Name == 'Login'){
                                                                   //ownerId = loanObj.OwnerId;
                                                                   //}else if(loanObj.RecordType.Name != 'Login' && loanObj.Ro_RM__c != null){
                                                                   //  ownerId = loanObj.Ro_RM__c;
                                                                   //}
                                                                   loanApplication.add(loanObj);
                                                               }
                            if(loanApplication.size() > 0){
                                // if(String.isNotBlank(ownerId) && String.isNotBlank(recordTypeName) && recordTypeName == 'Login'){
                                // User userRec = [SELECT Id , Name, ManagerId FROM User WHERE Id =: ownerId];
                                //loanApplication[0].ownerId = userRec != null && userRec.ManagerId != null ? userRec.ManagerId : userRec.Id;
                                // }else if(String.isNotBlank(ownerId) && String.isNotBlank(recordTypeName) && recordTypeName != 'Login'){
                                //loanApplication[0].ownerId = ownerId;
                                // }
                                
                                UPDATE loanApplication;
                                resWrap.isSuccess = true;
                                resWrap.responseBody = 'Rejected Successfully';
                                system.debug('loanApplication-> ' + loanApplication);
                            }else{
                                resWrap.isSuccess = false;
                                resWrap.responseBody = '';
                            }
                        }
                    }
                }
            }
        }catch(Exception ex){
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString() );
        }
        
        RETURN resWrap;
    }
    
    @AuraEnabled
    public static ResponseWrapper captureCancelResponse(String lafId, String reasons, String comments){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            if(String.isNotBlank(lafId)){
                List<Loan_Application__c> loanApplication = new List<Loan_Application__c>();
                if(String.isNotBlank(reasons) && String.isNotBlank(comments)){
                    for(Loan_Application__c loanObj : [SELECT Id,  Loan_Application_Status__c , Comment__c,Cancel_Reason__c,
                                                       RecordType.Name, OwnerId, Ro_RM__c
                                                       FROM Loan_Application__c WHERE Id =: lafId]){
                                                           loanObj.Cancel_Reason__c = reasons;
                                                           loanObj.Loan_Application_Status__c = 'Cancelled';
                                                           loanObj.Comment__c = comments;
                                                           loanApplication.add(loanObj);
                                                       }
                    if(loanApplication.size() > 0){
                        UPDATE loanApplication;
                        resWrap.isSuccess = true;
                        resWrap.responseBody = 'Rejected Successfully';
                        system.debug('loanApplication-> ' + loanApplication);
                    }else{
                        resWrap.isSuccess = false;
                        resWrap.responseBody = '';
                    }
                }
            }
        }catch(Exception ex){
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString() );
        }
        
        RETURN resWrap;
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
    }
}