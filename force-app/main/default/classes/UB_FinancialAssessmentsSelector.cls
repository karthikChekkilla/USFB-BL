/**
* @File Name          : UB_FinancialAssessmentsSelector.cls
* @Description        : This class used to fetch/query Financial Assessment based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-04-2024               Deepak Joshi                 Initial Version
*/
public class UB_FinancialAssessmentsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Financial_Assessment__c.Id,
            Financial_Assessment__c.Product__c, 
            Financial_Assessment__c.Loan_Application__c,
            Financial_Assessment__c.RecordTypeId
            
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Financial_Assessment__c.sObjectType;
    }

    public List<Financial_Assessment__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Financial_Assessment__c>) Database.query(query.toSOQL());
    } 
    public List<Financial_Assessment__c> selectByLoanApplicationId(Set<Id> loanApplicationId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c IN : loanApplicationId');
        return (List<Financial_Assessment__c>) Database.query(query.toSOQL());
    }    
}