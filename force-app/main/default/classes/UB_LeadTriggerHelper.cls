public without sharing class UB_LeadTriggerHelper {
    public UB_LeadTriggerHelper(){
        System.debug('TriggerHelper Constructor');
    }

    public void sendLeadToExternalSystem(List<Lead__c> newRecords){
        Set<Id> leadIdSet = new Set<Id>();
        for(Lead__c ldObj : newRecords){
            if(ldObj.RecordTypeId == UB_ConstantsUtil.PARTNER_PORTAL_RECORD_TYPE){
                leadIdSet.add(ldObj.Id);
            }
		}
        
        if(!leadIdSet.isEmpty() && leadIdSet.size() > 0){
            //System.enqueueJob(new UB_SyncLeadService(leadIdSet));
        }
    }
}