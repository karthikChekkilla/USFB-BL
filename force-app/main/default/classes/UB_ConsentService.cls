/**
* @File Name          : UB_ConsentService.cls
* @Description        : Api to update customer consent on verification log.
* @Author             : Zafaruddin
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         22-05-2024           Zafaruddin         Initial Version
*/

@RestResource(urlMapping='/consent/*')
global with sharing class UB_ConsentService {

    /**
    * @description  : Methid will post leMS lead into Salesforce.
    * @author Zafaruddin | 04-15-2024 
    **/
    @HttpPOST
    global static void getCustomerConsent() {
        Savepoint sp = Database.setSavepoint();
        try {
            RestRequest req = RestContext.request;
            Map<String,Object> RequestMap = (Map<String,Object>)JSON.deserializeUntyped(req.requestBody.tostring());
            System.debug('GUIDDDD  '+RequestMap.get('guid'));
            System.debug('GUIDDDD  '+String.valueOf(RequestMap.get('guid')).length());

            if(String.valueOf(RequestMap.get('guid')).length() == 0 ) {
                RestContext.response.statusCode = 404;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"fail" , "Messages": " GUI is Blank." }');
                return ;
            }
            String guid =  RequestMap.get('guid') != NULL? String.valueOf(RequestMap.get('guid')) : null;
            List<Verification__c> VerificationList = [SELECT Id, Status__c,Consent__c,OwnerId,Lead__c,Loan_Applicant__c,Loan_Applicant__r.Account_Name__c,Loan_Applicant__r.Loan_Application__r.Name,Loan_Applicant__r.Loan_Application__r.Id,Loan_Applicant__r.Loan_Application__r.OwnerId FROM Verification__c  WHERE GUID__c=:guid Order By Name DESC];
            String profileName=[Select Id,profile.name from user where Id=:VerificationList[0].OwnerId].profile.name; 
            if(!VerificationList.isEmpty()){
                if(VerificationList[0].Lead__c != NULL && RequestMap.get('consent') == 'No') {
                    Lead__c lead = new Lead__c();
                    lead.Id = VerificationList[0].Lead__c;
                    lead.Lead_Status__c = UB_ConstantsUtil.REJECT_LOAN_STATUS;
                    lead.Reject_Reason__c = UB_ConstantsUtil.SYSTEM_REJECT ;
                    lead.Reject_Sub_Reason__c = UB_ConstantsUtil.LEAD_SUB_REJECT;
                    lead.Rejected_By__c = VerificationList[0].OwnerId;
                    lead.Consent_Received__c = true;
                    // code for portal user
                    System.debug('PROFILE NAME   '+profileName);
                    if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
                        lead.OwnerId = [SELECT Id, ManagerId FROm USER WHERE Id=:VerificationList[0].OwnerId].ManagerId; 
                        System.debug('DSA MANAGER '+lead.OwnerId );
                    }
                    update lead ;
                } else if(VerificationList[0].Lead__c != NULL && RequestMap.get('consent') == 'Yes') {
                    Lead__c lead = new Lead__c();
                    lead.Id = VerificationList[0].Lead__c;
                    lead.Consent_Received__c = true;
                    update lead ;
                } else if(VerificationList[0].Loan_Applicant__c != NULL && RequestMap.get('consent') == 'Yes') {
                    Loan_Applicant__c applicant = new Loan_Applicant__c();
                    applicant.Id = VerificationList[0].Loan_Applicant__c;
                    applicant.Consent_Received__c = true;
                    update applicant ;
                } else if (VerificationList[0].Loan_Applicant__c != NULL && RequestMap.get('consent') == 'No'){
                    system.debug('Notification Condition');
                    UB_CommonUtil.sendNotification('Consent is Failed  for ' + VerificationList[0].Loan_Applicant__r.Account_Name__c + ' on Application ' + VerificationList[0].Loan_Applicant__r.Loan_Application__r.Name  ,'Consent Failed','Lead_Owner_Change',VerificationList[0].Loan_Applicant__r.Loan_Application__r.Id,VerificationList[0].Loan_Applicant__r.Loan_Application__r.OwnerId);
                }
                //update consent on verification record. 
                VerificationList[0].Consent__c = String.valueOf(RequestMap.get('consent'));
                VerificationList[0].Status__c = UB_ConstantsUtil.COMPLETEDSTATUS;
                update VerificationList;

                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf('{ "status":"success" , "Messages": " Consent Update Successfully. " }');
               
                
            }
            System.debug('Request Body  '+req.requestBody.tostring());
            System.debug('RequestMap   '+RequestMap);

        }catch(Exception e) {
            //Database.rollback(sp);
            System.debug('Exception--->'+e.getMessage());
            System.debug('ERROR LINE NUMBER--->'+e.getLineNumber());
            // call method to create ExceptionLogRecord
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"fail",   "errorMessages": "' + e.getMessage() +  '" }');
        } 
}



   
}