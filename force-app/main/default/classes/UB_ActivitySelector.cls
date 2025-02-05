/**
* @File Name          : UB_ActivitySelector.cls
* @Description        : This class used to fetch/query Valuation/Activity based on conditions.
* @Author             : Mansur Alam
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-05-2024             Mansur alam                 Initial Version
*/
public class UB_ActivitySelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Valuation__c.Id,
            Valuation__c.Collateral__c,
            Valuation__c.Current_Owner__c,
            Valuation__c.Document__c,
            
            Valuation__c.Loan_Application__c,
            Valuation__c.Loan_Applicant__c,
            Valuation__c.RecordType_Name__c,
            Valuation__c.Status__c,
            Valuation__c.Vehicle__c,
            Valuation__c.Vendor_Status__c,
            Valuation__c.Name,
            Valuation__c.Result__c,
            Valuation__c.Comment__c,
            Valuation__c.Loan_Applicant__c

           
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Valuation__c.sObjectType;
    }

    public List<Valuation__c > selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Valuation__c >) Database.query(query.toSOQL());
    }
    
    public List<Valuation__c > selectByLoanApplicationId(Set<Id> loanApplicationId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__r.Loan_Application__c IN : loanApplicationId OR Vehicle__r.Loan_Application__c IN : loanApplicationId OR Collateral__r.Loan_Application__c IN : loanApplicationId');
        query.selectField('RecordType.Name');
        query.selectField('RecordType.DeveloperName');
        query.selectField('LastModifiedDate');
        query.selectField('Loan_Applicant__c');
        query.selectField('Loan_Applicant__r.Name');
        query.selectField('Vehicle__c');
        query.selectField('Vehicle__r.Name');
        query.selectField('Collateral__c');
        query.selectField('Collateral__r.Name');
        query.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        return (List<Valuation__c >) Database.query(query.toSOQL());
    }
   	
    public List<Valuation__c > selectByAppId_RecType_Status(Set<Id> loanApplicationIds, Set<String> recordTypeIds, Set<String> status){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : loanApplicationIds AND RecordTypeId IN : recordTypeIds AND Status__c IN : status');
        return (List<Valuation__c >) Database.query(query.toSOQL());
    }

    //Added by Musab || 13-07-2024
    public List<Valuation__c> selectByApplicantId(String loanApplicantId, String recordTypeName){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c =: loanApplicantId AND recordType.Name =: recordTypeName' );
        query.setOrdering('createddate',fflib_QueryFactory.SortOrder.DESCENDING);
        query.setLimit(1);
        return (List<Valuation__c >) Database.query(query.toSOQL());
    }
}