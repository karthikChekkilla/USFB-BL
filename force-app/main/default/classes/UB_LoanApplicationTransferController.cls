/**
* @File Name          : UB_LoanApplicationTransferController.cls
* @Description        : This class use to transfter Loan Application to manager RM
* @Author             : Deepak Joshi
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         04-04-2024            Deepak Joshi          Initial Version           
**/
public class UB_LoanApplicationTransferController {
	// Transfter lead to contact manager
    @AuraEnabled
    public static string transferToRM(string recordId) {
        system.debug('==='+recordId);
        Savepoint sp = Database.setSavepoint();
        try{
    		User userRec = [SELECT Id, ManagerId FROM User WHERE Id =:userInfo.getUserId()];
            if(userRec.ManagerId !=null &&  Schema.sObjectType.Loan_Application__c.isUpdateable()) {
                Loan_Application__c recordObj = new Loan_Application__c();
                recordObj.Id = recordId;
                system.debug('==='+userRec.ManagerId);
                recordObj.OwnerId = userRec.ManagerId;
                update recordObj;
                return recordObj.Id;
                
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