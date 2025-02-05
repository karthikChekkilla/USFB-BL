/**
* @File Name          : UB_RejectController.cls
* @Description        : This class use to rejectLead stages.
* @Author             : Kamal Hussain
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024            Kamal Hussain           Initial Version           
**/
public class UB_RejectController {
     @AuraEnabled
    public static string rejectLead(string leadId, string reason, string subReason) {
            system.debug(leadId);
            system.debug(reason);
            system.debug(subReason);

            try{
            user userRec = [SELECT id, contact.account.Relationship_Manager__c FROM user WHERE id =:userInfo.getUserId()];
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
            
            update leadRec;

            }catch(exception e ) {
               system.debug('====='+e.getMessage());
               return e.getMessage();
            }

            return 'success';
            
           
    }
}