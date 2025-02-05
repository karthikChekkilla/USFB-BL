/**
* @File Name          : UB_BranchSelector.cls
* @Description        : This class used to fetch/query Branch records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-03-2024               Mohit                 Initial Version
*/
public class UB_BranchSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           Branch__c.Name
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Branch__c.sObjectType;
    }
   
    public List<Branch__c> selectById(Set<Id> recordIds){
        return (List<Branch__c>) selectSObjectsById(recordIds);
    }
}