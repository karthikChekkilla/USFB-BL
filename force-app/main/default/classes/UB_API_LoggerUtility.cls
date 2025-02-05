/**
* @File Name          : UB_API_LoggerUtility.cls
* @Description        : API Logger Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_API_LoggerUtility {
    public static List<API_Logger__c> insertRecords(List<API_Logger__c> recordList) {
        try{
            insert recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<API_Logger__c>();
        }
    }
}