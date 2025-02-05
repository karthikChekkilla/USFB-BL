/**
* @File Name          : UB_BankSelector.cls
* @Description        : This class used to fetch/query Reference records based on conditions.
* @Author             : Mansur
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         30-07-2024               Mansur                 Initial Version
*/
public class UB_BankSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Bank_Details__c.Id,
                Bank_Details__c.Account_Holder_Name__c,
                Bank_Details__c.Account_Number__c,
                Bank_Details__c.Account_Type__c,
                Bank_Details__c.Active_Since__c,
                Bank_Details__c.Bank_Name__c,
                Bank_Details__c.Branch_Name__c,
                Bank_Details__c.Is_Primary_Repayment_Account__c,
                Bank_Details__c.Institution_Id__c,
                Bank_Details__c.IFSC_Code__c,
                Bank_Details__c.Disbursement__c,
                Bank_Details__c.Loan_Application__c,
                Bank_Details__c.Name,
                Bank_Details__c.Payment_Mode__c,
                Bank_Details__c.RecordType.Name ,
                Bank_Details__c.Record_Type_Name__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Bank_Details__c.sObjectType;
    }
    
    public List<Bank_Details__c> selectById(Set<Id> recordIds){
        return (List<Bank_Details__c>) selectSObjectsById(recordIds);
    }
    public List<Bank_Details__c > selectByLoanApplicationId(Set<Id> loanApplication){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Application__c  IN : loanApplication AND Is_Primary_Repayment_Account__c = true' );
        query.selectField('RecordType.Name'); 
        query.selectField('RecordType.DeveloperName');
        return (List<Bank_Details__c >) Database.query(query.toSOQL());
    }
    
}