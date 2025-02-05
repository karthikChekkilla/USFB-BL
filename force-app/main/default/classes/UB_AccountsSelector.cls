/**
* @File Name          : UB_AccountsSelector.cls
* @Description        : This class used to fetch/query Loan Applications based on conditions.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-03-2024               Deepak Joshi                 Initial Version
*/
public class UB_AccountsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Account.Id,
            Account.Name,
            Account.Pan_Number__c  
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Account.sObjectType;
    }
    
    public List<Account> selectById(Set<Id> recordIds){
        return (List<Account>) selectSObjectsById(recordIds);
    }
   
    public List<Account> selectByPanNo(String panNo){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Pan_Number__c =: panNo');
        return (List<Account>) Database.query(query.toSOQL());
    }
}