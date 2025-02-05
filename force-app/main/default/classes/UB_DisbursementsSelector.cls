/**
* @File Name          : UB_DisbursementsSelector.cls
* @Description        : This class used to fetch/query Disbursement based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         22-07-2024              Umair Ahmad            Initial Version
*/
public class UB_DisbursementsSelector extends fflib_SObjectSelector{
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Disbursement__c.Loan_Application__c,
                Disbursement__c.Tenure__c,
                Disbursement__c.Loan_Amount__c,
                Disbursement__c.Loan_Application__c,
                Disbursement__c.EMI_Amount__c,
                Disbursement__c.First_EMI_Date__c,
                Disbursement__c.Last_Emi_Date__c,
                Disbursement__c.Processing_Fee__c,
                Disbursement__c.Repayment_Mode__c,
                Disbursement__c.ROI__c
                };
                    }
    
    
    public Schema.SObjectType getSObjectType(){
        return Disbursement__c.sObjectType;
    }
    
    public List<Disbursement__c> getDisbursementRecordsByIds(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        
        query.setCondition('Id IN: recordIds');
        query.selectField('Vehicle__r.Name');
        query.selectField('Vehicle__r.Make__c');
        query.selectField('Vehicle__r.Model__c');
        query.selectField('Vehicle__r.Is_Asset_Registrable__c');
        query.selectField('Vehicle__r.Vehicle_Cost__c');
        query.selectField('Vehicle__r.Margin_Money__c');
        query.selectField('Vehicle__r.Credit_Shield_Premium__c');
        query.selectField('Vehicle__r.Vehicle_Master__r.Vehicle_Type__c');
        system.debug('Disbursement__c query==> '+query.toSOQL());
        return (List<Disbursement__c>) Database.query(query.toSOQL());
    }
}