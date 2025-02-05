/**
* @File Name          : UB_VehicleUtility.cls
* @Description        : Vehicle Utility Class to perform DML actions
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Mohit                 Initial Version
*/
public with sharing class UB_VehicleUtility {
	public static List<Vehicle__c> updateRecords(List<Vehicle__c> recordList) {
        try{
            update recordList;
            return recordList;
        }catch(DmlException e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new List<Vehicle__c>();
        }
    }
}