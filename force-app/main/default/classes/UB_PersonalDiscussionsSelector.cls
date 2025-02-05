/**
* @File Name          : UB_PersonalDiscussionsSelector.cls
* @Description        : This class used to fetch/query Personal Discussion records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         22-06-2024               Mohit                 Initial Version
*/
public class UB_PersonalDiscussionsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Personal_Discussion__c.Id,
            Personal_Discussion__c.Name,
			Personal_Discussion__c.Document__c,
            Personal_Discussion__c.Loan_Application__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Personal_Discussion__c.sObjectType;
    } 
	
    public List<Personal_Discussion__c> selectById (Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Personal_Discussion__c>) Database.query(query.toSOQL());
    }
}