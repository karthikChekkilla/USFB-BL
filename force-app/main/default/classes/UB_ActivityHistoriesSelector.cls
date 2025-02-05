/**
* @File Name          : UB_ActivityHistoriesSelector.cls
* @Description        : This class used to fetch/query ActivityHistories records based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         2-05-2024               Deepak Joshi                 Initial Version
*/
public with sharing class  UB_ActivityHistoriesSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Activity_History__c.Id,
            Activity_History__c.TAT__c,
            Activity_History__c.CreatedDate,
            Activity_History__c.Name,
            Activity_History__c.From_User__c,
            Activity_History__c.To_User__c,
            Activity_History__c.Loan_Application__c,
            Activity_History__c.From_To_Queue__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Activity_History__c.sObjectType;
    }
    public override String getOrderBy(){
        return 'Name DESC';
     }
    public List<Activity_History__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Activity_History__c>) Database.query(query.toSOQL());
    }
    public List<Activity_History__c> selectByLoanApplicationId(Set<Id> recordIds){  
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c IN : recordIds');
        System.debug(query.toSOQL());
        return (List<Activity_History__c>) Database.query(query.toSOQL());
    }

    //Added by Musab || 13-07-2024
    public List<Activity_History__c> selectLatestByLoanApplicationId(Set<Id> recordIds){  
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c IN : recordIds');
        query.selectField('From_User__r.Name');
        query.selectField('To_User__r.Name');
        query.selectField('From_User__r.EmployeeNumber');
        query.setOrdering('createddate',fflib_QueryFactory.SortOrder.DESCENDING);
        query.setLimit(1);
        System.debug(query.toSOQL());
        return (List<Activity_History__c>) Database.query(query.toSOQL());
    }
}