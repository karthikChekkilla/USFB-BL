/**
* @File Name          : UB_VehicleMasterSelector.cls
* @Description        : This class used to fetch/query Vehicle Master records based on conditions.
* @Author             : Mohit Saxena
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         10-5-2024              Mohit Saxena             Initial Version
*/
public with sharing class UB_VehicleMasterSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           Vehicle_Master__c.Id,
           Vehicle_Master__c.Name,
           Vehicle_Master__c.Model__c,
           Vehicle_Master__c.Make__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Vehicle_Master__c.sObjectType;
    }
    
    public List<Vehicle_Master__c> selectByModel(Set<String> vehicleModels){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Model__c IN : vehicleModels');
        return (List<Vehicle_Master__c>) Database.query(query.toSOQL());
    }
}