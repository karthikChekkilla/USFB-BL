/**
* @File Name          : BL_RejectionBatch
* @Description        : Batch for the rejection hard
* @Author             : Lakshya Verma
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
global class BL_RejectionBatch implements Database.Batchable<sObject>,Database.Stateful {
	
    global Database.QueryLocator  start(Database.BatchableContext bc) {
        String qry = 'SELECT Id, BL_Reject_Type__c, BL_Soft_Reject_Date__c, BL_Validity_End_Date__c, ';
        qry += ' Reject_Reason__c, Reject_Sub_Reason__c, Loan_Application_Status__c , Comment__c ';
        qry +=   ' FROM Loan_Application__c WHERE BL_Validity_End_Date__c = today AND BL_Reject_Type__c = \'' + 'Soft' + '\'';
        qry +=   '  AND Loan_Application_Status__c  = \'' + 'Rejected' + '\'';
        return Database.getQueryLocator(qry);
    }

    global void execute(Database.BatchableContext bc, List<Loan_Application__c> rejectionScope) {
        system.debug('rejectionScope-> ' + rejectionScope);
        List<Loan_Application__c> hardRejectionList = new List<Loan_Application__c>();
        for(Loan_Application__c loanApp : rejectionScope){
            loanApp.BL_Reject_Type__c = BL_ConstantsUtil.REJECTION_TYPE;
            hardRejectionList.add(loanApp);
        }
        if(!hardRejectionList.isEmpty()){
            system.debug('hardRejectionList-> ' + hardRejectionList);
            UPDATE hardRejectionList;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // execute any post-processing operations - send emails, notify clients,
        // give a call to another batch class
        // Can give to another batch class
        // Can give callout request
        system.debug('batch job id = '+bc.getJobId());
    }
	
}