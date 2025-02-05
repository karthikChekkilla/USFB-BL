/**
* @File Name          : UB_DocumentsSelector.cls
* @Description        : This class used to fetch/query document based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         03-04-2024               Deepak Joshi                 Initial Version
*/
public class UB_DocumentsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Document__c.Id,
            Document__c.Loan_Application__c,
            Document__c.Lead__c,
            Document__c.Is_Required__c,
            Document__c.Document_URL__c,
            Document__c.Loan_Applicant__c,
            Document__c.Document_Type__c,
            Document__c.Document_Sub_Type__c,
            Document__c.Status__c,
            Document__c.Acknowledge_Status__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Document__c.sObjectType;
    }

    public List<Document__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Document__c>) Database.query(query.toSOQL());
    }
    public List<Document__c> selectByLeasId(Set<Id> leadIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Lead__c IN : leadIds');
        fflib_SObjectSelector documentChecklistsSelector = new UB_DocumentChecklistsSelector();
        documentChecklistsSelector.configureQueryFactoryFields(query, 'Document_Checklist__r');
        return (List<Document__c>) Database.query(query.toSOQL());
    }
    public List<Document__c> selectByLoanApplicationIdAndIsRequired(Set<Id> loanApplicationId ){
        fflib_QueryFactory query = newQueryFactory();
        String NotUploaded =UB_ConstantsUtil.NOT_UPLOADED;
        String NO = 'No';
        query.setCondition('Loan_Application__c IN : loanApplicationId AND Is_Required__c = true AND Status__c =:NotUploaded AND Loan_Applicant__r.Is_Deleted__c =: NO ' );
        return (List<Document__c>) Database.query(query.toSOQL());
    }
    
    public List<Document__c> selectByConditions(String condition){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition(condition);
        return (List<Document__c>) Database.query(query.toSOQL());
    }
}