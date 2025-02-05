/**
* @File Name          : UB_ProductsSelector.cls
* @Description        : This class used to fetch/query Product records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024               Mohit                 Initial Version
*/
public class UB_ProductsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           //Product__c.Product_Name__c,
           //Product__c.Product_Code__c,
            Product__c.Name,
            Product__c.Product__c,
            Product__c.Loan_Application__c,
            Product__c.Product_Category__c,
            Product__c.Product_Schemes__c,
            Product__c.Product_Sub_Category__c, 
            Product__c.BL_RCU_Required__c,
            Product__c.BL_Balance_Transfer_Applicable__c,
            Product__c.Sanction_Loan_Amount__c,
            Product__c.BL_Rate_of_Interest__c,
            Product__c.BL_Loan_Tenure_months__c,
            Product__c.BL_Applied_Loan_Amount__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Product__c.sObjectType;
    }
    
    public List<Product__c> selectById(Set<Id> recordIds){
        //return (List<Product__c>) selectSObjectsById(recordIds);
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector vehiclesSelector = new UB_VehiclesSelector();
        vehiclesSelector.addQueryFactorySubselect(query, 'Vehicles__r');
        fflib_SObjectSelector productMastersSelector = new UB_ProductMastersSelector();
        productMastersSelector.configureQueryFactoryFields(query, 'Product__r');
        fflib_SObjectSelector financialAssessmentsSelector = new UB_FinancialAssessmentsSelector();
        financialAssessmentsSelector.addQueryFactorySubselect(query, 'Financial_Assessment__r');

        query.setCondition('Id IN : recordIds');
        return (List<Product__c>) Database.query(query.toSOQL());
    }
    
    public List<Product__c> fetchProductMasterWithId(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector productMastersSelector = new UB_ProductMastersSelector();
        productMastersSelector.configureQueryFactoryFields(query, 'Product__r');
        query.setCondition('Id IN : recordIds');
        return (List<Product__c>) Database.query(query.toSOQL());
    }
    
    public List<Product__c> selectByLoanApplicationIds(Set<Id> loanApplicationIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c IN : loanApplicationIds');
        return (List<Product__c>) Database.query(query.toSOQL());
    }
}