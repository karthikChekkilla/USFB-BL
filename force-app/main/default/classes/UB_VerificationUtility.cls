/**
* @File Name          : UB_VerificationUtility.cls
* @Description        : Verification Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_VerificationUtility {
	public static List<Verification__c> insertRecords(List<Verification__c> recordList) {
        try{
            insert recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Verification__c>();
        }
    }
    
    public static List<Verification__c> updateRecords(List<Verification__c> recordList) {
        try{
            update recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Verification__c>();
        }
    }
}