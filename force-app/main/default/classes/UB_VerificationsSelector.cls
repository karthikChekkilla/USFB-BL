/**
* @File Name          : UB_LeadsSelector.cls
* @Description        : This class used to fetch/query Verification records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         04-04-2024               Mohit                 Initial Version
*/
public class UB_VerificationsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Verification__c.Id,
            Verification__c.RecordTypeId,
            Verification__c.Aadhaar_OTP_Request_ID__c,
            Verification__c.Status__c,
            Verification__c.Loan_Applicant__c,
            Verification__c.Sherlock_Case_Id__c,
            Verification__c.SherLock_Status__c,
            Verification__c.Aadhaar_Number__c,
            Verification__c.Perfios_API_Status__c,
            Verification__c.Is_Report_available__c,
            Verification__c.Perfios_Transaction_Id__c,
            Verification__c.Annual_Premium_With_Tax__c,
            Verification__c.BRE_Decision__c,
            Verification__c.Base_Premium__c,
            Verification__c.ICICI_Partner_URL__c,
            Verification__c.Insurance_Amount__c,
            Verification__c.Is_Medical__c,
            Verification__c.Modal_Premium__c,
            Verification__c.Premium_Paying_Term__c,
            Verification__c.Response_Remarks__c,
            Verification__c.Total_First_Premium_Show__c,
            Verification__c.Total_First_Premium__c,
            Verification__c.Transaction_Id__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Verification__c.sObjectType;
    }
   
    public List<Verification__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        query.selectField('Loan_Applicant__r.Loan_Application__r.LOB__c');
        return (List<Verification__c>) Database.query(query.toSOQL());
    }
    
    public List<Verification__c> selectByIdWithParentInfo(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector loanApplicantsSelector = new UB_LoanApplicantsSelector();
        loanApplicantsSelector.configureQueryFactoryFields(query, 'Loan_Applicant__r');
        query.setCondition('Id IN : recordIds');
        query.selectField('Loan_Applicant__r.Loan_Application__r.LOB__c');
        return (List<Verification__c>) Database.query(query.toSOQL());
    }

    public List<Verification__c> selectByIdLoanApplicationId(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__r.Loan_Application__c IN : recordIds');
        query.selectField('RecordType.Name');
        query.selectField('RecordType.DeveloperName');
        query.selectField('Loan_Applicant__c');
        query.selectField('Loan_Applicant__r.Name');
        query.selectField('Loan_Applicant__r.Proof_of_Address__c');
        query.selectField('LastModifiedDate');
        query.selectField('CreatedDate');
        query.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        return (List<Verification__c>) Database.query(query.toSOQL());
    }
    
    public List<Verification__c> selectByIdWithFraudInfo(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('CFR_Fraud_Information__c');
        query.setCondition('Id IN : recordIds');
        return (List<Verification__c>) Database.query(query.toSOQL());
    }
    
    public List<Verification__c> selectByDisbIdAndRecordType(Set<Id> recordIds, String recordType){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Disbursement__c IN : recordIds and RecordType.Name =: recordType')
            .setOrdering('createddate',fflib_QueryFactory.SortOrder.DESCENDING)
            .setLimit(1);
        return (List<Verification__c>) Database.query(query.toSOQL());
    }
}