/**
* @File Name          : UB_LoanApplicationsSelector.cls
* @Description        : This class used to fetch/query Loan Applications based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-03-2024               Deepak Joshi                 Initial Version
*/
public class UB_LoanApplicationsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Loan_Application__c.Id,
                Loan_Application__c.Loan_Application_Stage__c,
                Loan_Application__c.Branch__c,
                Loan_Application__c.Amount__c,
                Loan_Application__c.Name,
                Loan_Application__c.Loan_Period__c,
                Loan_Application__c.DSA__c,
                Loan_Application__c.OwnerId,
                Loan_Application__c.LOB__c,
                Loan_Application__c.CreatedDate,
                Loan_Application__c.Ro_RM__c,
                Loan_Application__c.ROI__c,
                Loan_Application__c.Amount__c,
                Loan_Application__c.IsReadOnly__c,
                Loan_Application__c.Product__c,
                Loan_Application__c.Lead__c,
                Loan_Application__c.CM__c,
                Loan_Application__c.CPA__c,
                Loan_Application__c.Duplicate_LAF_Id__c,  
                Loan_Application__c.Loan_Application_Status__c,  
                Loan_Application__c.Lead__r.Cam_Generate__c,
                Loan_Application__c.DSA_Name__c,  
                Loan_Application__c.Application_Type__c,  
                Loan_Application__c.RM_Name__c,
                Loan_Application__c.CB_Customer_Category__c,
                Loan_Application__c.Product__c,
                Loan_Application__c.Risk__c,
                Loan_Application__c.Strength__c,
                Loan_Application__c.LastModifiedDate,
                Loan_Application__c.Moratorium_Period_Month__c,
                Loan_Application__c.BL_Product_Category__c,
                Loan_Application__c.RecordTypeId,
                Loan_Application__c.isSendBackToDDE__c,
                Loan_Application__c.Ro_RM__c,
                Loan_Application__c.BL_Product_Name__c,
                Loan_Application__c.BL_Program__c,
                Loan_Application__c.Branch__r.name,
                Loan_Application__c.BL_RCU_Waived__c,
                Loan_Application__c.Record_Type_Name__c,
                Loan_Application__c.User_Role__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Loan_Application__c.sObjectType;
    }
    
    public List<Loan_Application__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        
        fflib_SObjectSelector productsSelector = new UB_ProductsSelector();
        productsSelector.addQueryFactorySubselect(query, 'Products__r');
        fflib_SObjectSelector applicantSelector = new UB_LoanApplicantsSelector();
        applicantSelector.addQueryFactorySubselect(query, 'Loan_Applicants__r');
        fflib_SObjectSelector documentsSelector = new UB_DocumentsSelector();
        documentsSelector.addQueryFactorySubselect(query, 'Documents__r');
        fflib_SObjectSelector activitySelector = new UB_ActivitySelector();
        activitySelector.addQueryFactorySubselect(query, 'Valuation__r');
        fflib_SObjectSelector branchSelector = new UB_BranchSelector();
        branchSelector.configureQueryFactoryFields(query, 'Branch__r');
        fflib_SObjectSelector referenceSelector = new UB_Reference_MemberSelector();
        referenceSelector.addQueryFactorySubselect(query, 'Reference_Members__r');
        fflib_SObjectSelector bankSelector = new UB_BankSelector();
        bankSelector.addQueryFactorySubselect(query, 'Bank_Details__r');
        query.selectField('Lead__r.Product_Name__c');
        query.selectField('Lead__r.Loan_Period__c');
        query.selectField('Lead__r.Amount__c');
        query.setCondition('Id IN : recordIds');
        return (List<Loan_Application__c>) Database.query(query.toSOQL());
    }
    
    public List<Loan_Application__c> selectByIds(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Lead__r.Product_Category__c');
        query.selectField('Lead__r.Lead_Generator_Code__c');
        query.selectField('Lead__r.Sourcing__c');
        query.selectField('Lead__r.Product_Sub_Type__c');
        query.selectField('Lead__r.Lead_Source__c');
        query.selectField('Branch__r.Branch_Code__c');
        query.selectField('Ro_RM__r.EmployeeNumber');
        query.selectField('Ro_RM__r.Name');
        query.setCondition('Id IN : recordIds');
        return (List<Loan_Application__c>) Database.query(query.toSOQL());
    }
    
    public Loan_Application__c getLoanApplicationRecord(Id recordId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Lead__r.Product_Category__c');
        query.selectField('Lead__r.Lead_Generator_Code__c');
        query.selectField('Lead__r.Sourcing__c');
        query.selectField('Lead__r.Product_Sub_Type__c');
        query.selectField('Lead__r.Lead_Source__c');
        query.selectField('Branch__r.Branch_Code__c');
        query.selectField('Branch__r.Name');
        query.selectField('Ro_RM__r.EmployeeNumber');
        query.selectField('Ro_RM__r.Name');
        query.setCondition('Id =: recordId');
        return (Loan_Application__c) Database.query(query.toSOQL());
    }
}