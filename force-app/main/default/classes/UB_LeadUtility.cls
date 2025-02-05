/**
* @File Name          : UB_LeadUtility.cls
* @Description        : Lead Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_LeadUtility {
	public static List<Lead__c> updateRecords(List<Lead__c> recordList) {
        try{
            update recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Lead__c>();
        }
    }
}