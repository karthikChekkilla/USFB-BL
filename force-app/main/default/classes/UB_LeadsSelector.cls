/**
* @File Name          : UB_LeadsSelector.cls
* @Description        : This class used to fetch/query Lead records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024               Mohit                 Initial Version
*/
public class UB_LeadsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Lead__c.Id,
            Lead__c.Name,
            Lead__c.Customer_Type__c,
            Lead__c.Last_Name__c,
            Lead__c.First_Name__c,
            Lead__c.Middle_Name__c,
            Lead__c.Mobile_Number__c,
            Lead__c.Lead_Source__c,
            Lead__c.Campaign_Type__c,
            Lead__c.Lead_Nature__c,
            Lead__c.Lead_Status__c,
            Lead__c.Department__c,
            Lead__c.Product_Vertical__c,
            Lead__c.Product_Category__c,
            Lead__c.Product_Name__c,
            //Lead__c.Product_Code__c, 
            Lead__c.Product_Name__c,
            Lead__c.PAN__c,
            Lead__c.Platform__c,
            Lead__c.Amount__c,
            Lead__c.Loan_Period__c,
            Lead__c.Gender__c,
            Lead__c.Constitution__c,
           // Lead__c.Date_Of_Incorporation__c,
            Lead__c.OwnerId,
            Lead__c.Consent_Received__c,
            Lead__c.Lead_Stage__c,
            Lead__c.Date_of_Birth_Incorporation__c,
            Lead__c.Name__c,
            Lead__c.Salutation__c,
            Lead__c.DSA__c,
            Lead__c.LOB__c,
            Lead__c.Email__c,
            Lead__c.Entity_Name__c,
            Lead__c.BL_Repayment_Mode__c,
            Lead__c.Manager_IDs__c    
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Lead__c.sObjectType;
    }
   
    public List<Lead__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector productsSelector = new UB_ProductsSelector();
        //productsSelector.configureQueryFactoryFields(query, 'Product__r');
        fflib_SObjectSelector branchSelector = new UB_BranchSelector();
        branchSelector.configureQueryFactoryFields(query, 'Branch__r');
        query.setCondition('Id IN : recordIds');
        new UB_AddressesSelector().addQueryFactorySubselect(query,'Addresses__r');
        System.debug(query.toSOQL());
        return (List<Lead__c>) Database.query(query.toSOQL());
    }
}