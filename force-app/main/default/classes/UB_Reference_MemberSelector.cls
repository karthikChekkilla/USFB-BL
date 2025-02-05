/**
* @File Name          : UB_Reference_MemberSelector.cls
* @Description        : This class used to fetch/query Reference records based on conditions.
* @Author             : Mansur
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         30-07-2024               Mansur                 Initial Version
*/
public class UB_Reference_MemberSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
          
          Reference_Member__c.Reference_Address__c,
          Reference_Member__c.Identification_Number__c,
          Reference_Member__c.Id,
          Reference_Member__c.First_Name__c,
          Reference_Member__c.Designation__c,
          Reference_Member__c.Date_of_birth__c,
          Reference_Member__c.KYC_Document_Type__c,
          Reference_Member__c.KYC_Document_Type_Name__c,
          Reference_Member__c.Last_Name__c,
          Reference_Member__c.Loan_Application__c,
          Reference_Member__c.Loan_Applicant_Name__c,
          Reference_Member__c.Loan_Applicant__c,
          Reference_Member__c.Loan_Application_Name__c,
          Reference_Member__c.Member_Name__c,
          Reference_Member__c.Middle_Name__c,
          Reference_Member__c.Mobile__c,
          Reference_Member__c.Name,
          Reference_Member__c.Nationality__c,
          Reference_Member__c.Occupation_Type__c,
          Reference_Member__c.Pincode__c,
          Reference_Member__c.Pincode_Name__c,
          Reference_Member__c.Reference_Member__c.Type__c,
          Reference_Member__c.Type_of_Profession__c,
          Reference_Member__c.Type_of_Profession_Name__c

        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Reference_Member__c.sObjectType;
    }
   
    public List<Reference_Member__c> selectById(Set<Id> recordIds){
        return (List<Reference_Member__c>) selectSObjectsById(recordIds);
    }
    public List<Reference_Member__c > selectByLoanApplicantId(Set<Id> loanApplcantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c  IN : loanApplcantId' );
           query.selectField('RecordType.Name');
            query.selectField('Loan_Applicant__r.Name');
        return (List<Reference_Member__c >) Database.query(query.toSOQL());
    }
    public List<Reference_Member__c > selectByLoanApplicationId(Set<Id> loanApplcationId,String recordTypeId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c  IN : loanApplcationId AND RecordTypeId = :recordTypeId' );
           query.selectField('RecordType.Name');
        return (List<Reference_Member__c >) Database.query(query.toSOQL());
    }
   	
}