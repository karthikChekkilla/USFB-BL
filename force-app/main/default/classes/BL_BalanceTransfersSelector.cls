/**
* @File Name          : BL_BalanceTransfersSelector.cls
* @Description        : This class used to fetch/query Balance Transfer records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         29-8-2024                 Mohit                Initial Version
*/
public with sharing class BL_BalanceTransfersSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Balance_Transfer__c.Id,
            Balance_Transfer__c.Name,
            Balance_Transfer__c.BL_Loan_Application__c    
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Balance_Transfer__c.sObjectType;
    }
    
    public List<Balance_Transfer__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Balance_Transfer__c>) Database.query(query.toSOQL());
    }
    
    public List<Balance_Transfer__c> selectByLoanApplicationId(Set<Id> loanApplicationIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('BL_Loan_Application__c IN : loanApplicationIds');
        return (List<Balance_Transfer__c>) Database.query(query.toSOQL());
    }
}