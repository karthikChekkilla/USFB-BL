/**
* @File Name          : UB_ProductUtility.cls
* @Description        : Product Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_ProductUtility {
	public static List<Product__c> insertRecords(List<Product__c> recordList) {
        try{
            insert recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Product__c>();
        }
    }
    
    public static void deleteRecords(List<Product__c> recordList) {
        try{
            delete recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}