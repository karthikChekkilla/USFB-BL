/**
* @File Name          : UB_AccountsSelector.cls
* @Description        : This class used to fetch/query Loan Applications based on conditions.
* @Author             : Mohit Saxena
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-03-2024              Mohit Saxena            Initial Version
*/
public with sharing class UB_LoanApplicantsSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Loan_Applicant__c.Id,
                Loan_Applicant__c.Account_Name__c,	
                Loan_Applicant__c.Pan_Number__c,
                Loan_Applicant__c.Date_of_Birth__c,
                Loan_Applicant__c.First_Name__c,
                Loan_Applicant__c.Middle_Name__c,
                Loan_Applicant__c.Last_Name__c,
                Loan_Applicant__c.Date_of_Birth__c,
                Loan_Applicant__c.Gender__c,
                Loan_Applicant__c.Driving_Licence__c,
                Loan_Applicant__c.Voter_Card__c,
                Loan_Applicant__c.Passport__c,
                Loan_Applicant__c.Mobile__c,
                Loan_Applicant__c.Account_Number__c,
                Loan_Applicant__c.Aadhaar_Verification__c,
                Loan_Applicant__c.Official_Email_ID__c,
                Loan_Applicant__c.CreatedDate,
                Loan_Applicant__c.Name_of_the_Bank__c,
                Loan_Applicant__c.Designation__c,
                Loan_Applicant__c.Employee_Name__c,
                Loan_Applicant__c.Monthly_Income__c,
                Loan_Applicant__c.Cibil_Verification__c,
                Loan_Applicant__c.Dedupe_Verification__c,
                Loan_Applicant__c.Constitution__c,
                Loan_Applicant__c.Applicant_Type__c,
                Loan_Applicant__c.Name,
                Loan_Applicant__c.RecordTypeId,
                Loan_Applicant__c.Loan_Application__c,
                Loan_Applicant__c.Consent_Received__c,
                Loan_Applicant__c.Date_Of_Incorporation__c,
                Loan_Applicant__c.Applicant_Name__c,
                Loan_Applicant__c.Sherlock_Verification__c,
                Loan_Applicant__c.PAN_Verification__c,
                Loan_Applicant__c.Record_Type_Name__c,
                Loan_Applicant__c.ScoreCard_Verification__c,
                Loan_Applicant__c.Proof_of_Address__c,
                Loan_Applicant__c.Email__c,
                Loan_Applicant__c.Nature_of_Business__c,
                Loan_Applicant__c.CIN__c,
                Loan_Applicant__c.Net_Annual_Income__c,
                Loan_Applicant__c.Telephone__c,
                Loan_Applicant__c.Industry_Type__c,
                Loan_Applicant__c.Category__c,
                Loan_Applicant__c.Maiden_Name__c,
                Loan_Applicant__c.Mother_Name__c,
                Loan_Applicant__c.Marital_Status__c,
                Loan_Applicant__c.Religion__c,
                Loan_Applicant__c.Father_Spouse_Name__c,
                Loan_Applicant__c.Working_in_a_bank_as_director_Sr_Office__c,
                Loan_Applicant__c.RBI_Defaulter_List_Status__c,
                Loan_Applicant__c.Residential_Status__c,
                Loan_Applicant__c.Education__c,
                Loan_Applicant__c.BL_Customer_Type__c,
                Loan_Applicant__c.Occupation_Type__c,
                Loan_Applicant__c.Total_Work_Experience__c,
                Loan_Applicant__c.No_of_years_at_current_job__c,
                Loan_Applicant__c.Entity_Name__c,
                Loan_Applicant__c.Age__c,
                Loan_Applicant__c.Current_Residential_Address__c,
                Loan_Applicant__c.Is_Deleted__c,
                Loan_Applicant__c.Hunter_Verification__c,
                Loan_Applicant__c.BL_Balance_Tenure_in_months__c,
                Loan_Applicant__c.Udyam_Verification__c,
                Loan_Applicant__c.BL_URC__c,
                Loan_Applicant__c.USLBL_Staff__c,
                Loan_Applicant__c.CIF__c,
                Loan_Applicant__c.Consent_Verification__c,
                Loan_Applicant__c.Waive_FI__c,
                Loan_Applicant__c.Perfios_Verification__c,
                Loan_Applicant__c.BL_Income_Considered__c,
                Loan_Applicant__c.BL_Proof_of_Identity__c,
                Loan_Applicant__c.Identification_Number__c,
                Loan_Applicant__c.Proof_Of_Address_Name__c,
                Loan_Applicant__c.BL_Customer_Type__c,
                Loan_Applicant__c.BL_Purpose_of_Loan__c,
                Loan_Applicant__c.BL_Relationship_with_Applicant__c
                //  Loan_Applicant__c.Aadhaar_Verification__r
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Loan_Applicant__c.sObjectType;
    }
    
    public List<Loan_Applicant__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector verificationSelector = new UB_VerificationsSelector();
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Id IN : recordIds AND Is_Deleted__c =: deletedApplicant ');
        query.selectField('Loan_Application__r.LOB__c');
        query.selectField('Aadhaar_Verification__r.Aadhaar_Number__c');
        query.selectField('Perfios_Verification__r.Status__c');
        query.selectField('Account__r.Name');
        query.selectField('BL_Applicant_GST_registratio__c');
        query.selectField('Consent_Verification__r.Status__c');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    /**
* @description : To get Primary Applicant  
* @author Zafaruddin | 07-19-2024 
* @param recordIds 
* @return List<Loan_Applicant__c> 
**/
    public List<Loan_Applicant__c> getPrimaryApplicant(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        String applicant = 'Applicant';
        query.setCondition('Loan_Application__c IN : recordIds AND Is_Deleted__c =: deletedApplicant AND Applicant_Type__c =: applicant ');
        //query.selectField('Loan_Application__r.LOB__c');
        new UB_LoanApplicationsSelector().configureQueryFactoryFields(query,'Loan_Application__r');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    public List<Loan_Applicant__c> selectByIdWithParentRecords(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector accountsSelector = new UB_AccountsSelector();
        accountsSelector.configureQueryFactoryFields(query, 'Account__r');
        //fflib_SObjectSelector verificationSelector = new UB_VerificationsSelector();
        //  verificationSelector.configureQueryFactoryFields(query, 'Aadhar_Verification__r');
        fflib_SObjectSelector loanApplicationSelector = new UB_LoanApplicationsSelector();
        loanApplicationSelector.configureQueryFactoryFields(query, 'Loan_Application__r');
        //  loanApplicationSelector.configureQueryFactoryFields(query, 'Loan_Application__r.Branch__r');
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Id IN : recordIds AND Is_Deleted__c =: deletedApplicant');
        query.selectField('Loan_Application__r.LOB__c');
        system.debug('query==>'+query.toSOQL());
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    public List<Loan_Applicant__c> selectByIdWithRelatedRecords(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector loanApplicationSelector = new UB_LoanApplicationsSelector();
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Id IN : recordIds AND Is_Deleted__c =: deletedApplicant ');
        new UB_AddressesSelector().addQueryFactorySubselect(query,'Addresses__r');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    //Added by Deepak Joshi 16 april 2024
    public List<Loan_Applicant__c> selectByIdWithLoanApplication(Set<Id> loanApplicationId){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector loanApplicationSelector = new UB_LoanApplicationsSelector();
        fflib_SObjectSelector verificationSelector = new UB_VerificationsSelector();
        new UB_VerificationsSelector().configureQueryFactoryFields(query,'Cibil_Verification__r');
        new UB_VerificationsSelector().configureQueryFactoryFields(query,'Aadhaar_Verification__r');
        new UB_VerificationsSelector().configureQueryFactoryFields(query,'Perfios_Verification__r');
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.selectField('Loan_Application__r.LOB__c');
        query.setCondition('Loan_Application__c IN : loanApplicationId AND Is_Deleted__c =: deletedApplicant ');
        
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    //Added by Zafaruddin
    public List<Loan_Applicant__c> getApplicants(Set<Id> applicantionId, String type){
        fflib_QueryFactory query = newQueryFactory();
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Loan_Application__c IN : applicantionId AND Applicant_Type__c = :type AND Is_Deleted__c =: deletedApplicant' );
        query.selectField('Dedupe_Verification__r.Dedupe_Status__c');
        query.selectField('CFR_Verification__r.CFR_Status__c');
        query.selectField('Cibil_Verification__r.Cibil_Score__c');
        query.selectField('Loan_Application__r.Branch__r.Branch_Code__c');
        return (List<Loan_Applicant__c>) Database.query(query.toSOQL());
    }
    //Added by Mansur
    public List<Loan_Applicant__c> getNonIndApplicants(Set<Id> applicantId, String recordTypeId){
        fflib_QueryFactory query = newQueryFactory();
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Id IN : applicantId AND Is_Deleted__c =: deletedApplicant AND RecordTypeId =: recordTypeId');
        return (List<Loan_Applicant__c>) Database.query(query.toSOQL());
    }
    
    
}