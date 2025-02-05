/**
* @File Name          : UB_LeadTransferController.cls
* @Description        : This class use to transfter lead to manager RM
* @Author             : Kamal Hussain
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024            Kamal Hussain           Initial Version           
**/
public class UB_LeadTransferController {
	// Transfter lead to contact manager
    @AuraEnabled
    public static string transferLead(string leadId) {
        system.debug('==='+leadId);
        Savepoint sp = Database.setSavepoint();
        try{
    		user userRec = [SELECT id, contact.account.Relationship_Manager__c FROM user WHERE id =:userInfo.getUserId()];
            if(userRec.contact.account.Relationship_Manager__c !=null) {
                lead__c leadRec = new lead__c();
                leadRec.Id = leadId;
                system.debug('==='+userRec.contact.account.Relationship_Manager__c);
                leadRec.OwnerId = userRec.contact.account.Relationship_Manager__c;
                update leadRec;
                return leadRec.Id;
            }
            return null;
        }catch(exception e) {
            Database.rollback(sp);
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            system.debug('===error:'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            return 'ERROR: '+e.getMessage();
            
        }
       
    }
}