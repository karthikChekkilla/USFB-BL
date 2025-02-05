/**
* @File Name          : UB_ProductMastersSelector.cls
* @Description        : This class used to fetch/query Product Master records based on conditions.
* @Author             : Deepak Joshi 
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         25-04-2024               Deepak Joshi                 Initial Version
*/
public with sharing class UB_ProductMastersSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           Product_Master__c.Name,
           Product_Master__c.Id,
           Product_Master__c.Credit_Assessment_Method__c,
           Product_Master__c.Product_Category__c,
           Product_Master__c.Product_Sub_Category__c,
           Product_Master__c.Product_Schemes__c,
           Product_Master__c.LOB__c,
                 Product_Master__c.CoApplicant_Applicant_Office_FI_Mandator__c,
                Product_Master__c.CoApplicant_applicant_Residence_FI_Manda__c,
                Product_Master__c.Guarantor_applicant_Office_FI_Mandatory__c,
                Product_Master__c.Guarantor_applicant_Residence_FI_Mandato__c,
                Product_Master__c.Primary_applicant_Office_FI_Mandatory__c,
                Product_Master__c.Primary_applicant_Residence_FI_Mandatory__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Product_Master__c.sObjectType;
    }
    
    public List<Product_Master__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Product_Master__c>) Database.query(query.toSOQL());
    }
    
    public List<Product_Master__c> filterByCriteria(String category, String subCategory, String schemes){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Product_Category__c =: category AND Product_Sub_Category__c =: subCategory AND Product_Schemes__c =: schemes');
        query.selectField('BL_Maximum_ROI__c');
        query.selectField('BL_Minimum_ROI__c');
        return (List<Product_Master__c>) Database.query(query.toSOQL());
    }
}