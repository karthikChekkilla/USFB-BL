/**
* @File Name          : UB_VehiclesSelector.cls
* @Description        : This class used to fetch/query Vehicl records based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         24-4-2024              Deepak Joshi                 Initial Version
*/
public  with sharing class  UB_VehiclesSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Vehicle__c.Id,
                Vehicle__c.Name,
                Vehicle__c.Vehicle_Cost__c,
                Vehicle__c.Number_Of_Vehicles__c,
                Vehicle__c.Tenure__c,
                Vehicle__c.ROI__c,
                Vehicle__c.Asset_Insurance_Premium__c,
                Vehicle__c.Margin_Money__c,
                Vehicle__c.Loan_Application__c,
                Vehicle__c.Registration_Number__c,
                Vehicle__c.Vehicle_Type__c,
                Vehicle__c.Body_Type__c,
                Vehicle__c.Number_of_Asset_Unit__c,
                Vehicle__c.Model__c,
                Vehicle__c.RTO_Value__c,
                Vehicle__c.EMI__c,
                Vehicle__c.ROI__c,
                Vehicle__c.Make__c,
                Vehicle__c.Owner_Name__c,
                Vehicle__c.Chassis_Number__c,
                Vehicle__c.Engine_Number__c,
                Vehicle__c.Manufactured_Month_Year__c,
                Vehicle__c.Owner_Serial_Number__c,
                Vehicle__c.Fitness_Validity__c,
                Vehicle__c.Subvention__c,
                Vehicle__c.Plough_Black_Amount__c,
                Vehicle__c.Plough_Back__c,
                Vehicle__c.Eligible_LTV__c,
                Vehicle__c.Actual_LTV__c,
                Vehicle__c.IDV__c,
                Vehicle__c.Funding_Limit__c,
                Vehicle__c.Credit_Facility_Amount__c,
                Vehicle__c.Variant__c,
                Vehicle__c.Insurance_Expiry_Date__c,
                Vehicle__c.Advance_EMI__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Vehicle__c.sObjectType;
    }
    
    public List<Vehicle__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN : recordIds');
        return (List<Vehicle__c>) Database.query(query.toSOQL());
    }
    //added by Mansur Alam
    public List<Vehicle__c> selectByLoanApplicationId(Set<Id> applicationId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c IN : applicationId' );
        query.selectField('Dealer__r.IFSC_Code__c');
        return (List<Vehicle__c>) Database.query(query.toSOQL());
    }
    
    public List<Vehicle__c> selectByIdsWithProductInfo(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Product__c');
        query.selectField('Product__r.Product_Category__c');
        query.setCondition('Id IN : recordIds' );
        return (List<Vehicle__c>) Database.query(query.toSOQL());
    }

    //added by Mohd Musab 13-07-2024
    public List<Vehicle__c> selectByLoanApplicationIdforVehicle(String applicationId, String recordTypeName){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c =: applicationId AND recordType.Name =: recordTypeName' );
        query.selectField('Dealer__r.IFSC_Code__c');
        query.selectField('Vehicle_Master__r.Registrable__c');
        query.selectField('Vehicle_Master__r.Vehicle_Type__c');
        query.selectField('Vehicle_Master__r.Vehicle_Classification__c');
        query.selectField('Vehicle_Master__r.Vehicle_Category__c');
        query.selectField('Dealer__r.Name');
        query.selectField('Dealer__r.Dealer_Code__c');
        return (List<Vehicle__c>) Database.query(query.toSOQL());
    }
}