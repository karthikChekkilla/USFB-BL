/**
* @File Name          : UB_TasksSelector.cls
* @Description        : This class used to fetch/query Tasks records based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         30-04-2024               Deepak Joshi                 Initial Version
*/
public with sharing class  UB_TasksSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Task.Id,
            Task.Status
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Task.sObjectType;
    }
    
    public List<Task> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Task>) Database.query(query.toSOQL());
    }
    public List<Task> selectByWhatId(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('WhatId IN : recordIds OR Loan_Application__c  IN : recordIds');
        return (List<Task>) Database.query(query.toSOQL());
    }
}