/**
* @File Name          : UB_LoanApplicationUtility.cls
* @Description        : Loan Application Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_LoanApplicationUtility {
	public static List<Loan_Application__c> insertRecords(List<Loan_Application__c> recordList) {
        try{
            insert recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Loan_Application__c>();
        }
    }
    
    public static List<Loan_Application__c> updateRecords(List<Loan_Application__c> recordList) {
        try{
            update recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Loan_Application__c>();
        }
    }
}