/**
* @File Name          : UB_DocumentChecklistsSelector.cls
* @Description        : This class used to fetch/query document checklist based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024               Deepak Joshi                 Initial Version
*/
public class UB_DocumentChecklistsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Document_Checklist__c.Id,
                Document_Checklist__c.Stage__c,
                Document_Checklist__c.LOB__c,
                Document_Checklist__c.Is_Active__c,
                Document_Checklist__c.Document_Type__c,
                Document_Checklist__c.Is_Required__c,
                Document_Checklist__c.Document_Subtype__c,
                Document_Checklist__c.Constituation_of_Applicant__c,
                Document_Checklist__c.Applicant_Type__c,
                Document_Checklist__c.Applicable_For__C,
                Document_Checklist__c.Product_Parameters__c,
                Document_Checklist__c.Disbursement_Type__c,
                Document_Checklist__c.Disbursement_Sub_Type__c 
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Document_Checklist__c.sObjectType;
    }
   
    public List<Document_Checklist__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }
    public List<Document_Checklist__c> selectByStage(String stage){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('stage__c =: stage');
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }
    
    public List<Document_Checklist__c> selectByCondition(String condition){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition(condition);
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }
}