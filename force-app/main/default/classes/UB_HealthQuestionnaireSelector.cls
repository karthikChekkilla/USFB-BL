/**
* @File Name          : UB_HealthQuestionnaireSelector.cls
* @Description        : This class used to fetch/query health questions based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-07-2024              Umair Ahmad            Initial Version
*/
public class UB_HealthQuestionnaireSelector extends fflib_SObjectSelector{
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Health_Questionnaire__c.Id
                };
                    }
    
    
    public Schema.SObjectType getSObjectType(){
        return Health_Questionnaire__c.sObjectType;
    }
    
    public List<Health_Questionnaire__c> getHealthQuestionsByDisbIds(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        
        query.setCondition('Disbursement__c IN: recordIds');
        
        system.debug('Health_Questionnaire__c query==> '+query.toSOQL());
        return (List<Health_Questionnaire__c>) Database.query(query.toSOQL());
    }
}