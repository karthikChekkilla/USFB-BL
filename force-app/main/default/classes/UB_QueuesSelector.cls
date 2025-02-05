/**
* @File Name          : UB_QueuesSelector.cls
* @Description        : This class used to fetch/query Queues.
* @Author             : Deepak Joshi
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         04-04-2024               Deepak Joshi                 Initial Version
*/
public class UB_QueuesSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Group.Id,
            Group.DeveloperName,
            Group.Name
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Group.sObjectType;
    }

    public List<Group> selectQueueDeveloperName(String queueDeveloperName){
        fflib_QueryFactory query = newQueryFactory();
        String type ='Queue';
        query.setCondition('Type =:type  AND DeveloperName  =:queueDeveloperName');
        return (List<Group>) Database.query(query.toSOQL());
    } 

    
}