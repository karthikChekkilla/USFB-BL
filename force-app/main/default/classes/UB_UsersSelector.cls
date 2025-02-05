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
public class UB_UsersSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            User.Id,
                User.ManagerId, 
                User.Manager.UserRole.Name,
                User.ProfileId,
                User.Profile.Name
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return User.sObjectType;
    }
    
    public List<User> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('isActive = true AND Id IN : recordIds');
        return (List<User>) Database.query(query.toSOQL());
    }
    
    public List<User> fetchUserWithManager(){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('isActive = true AND ManagerId != null');
        return (List<User>) Database.query(query.toSOQL());
    }
    
    public List<User> selectByIdWIthManagerId(Set<Id> userIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('isActive = true AND ManagerId != null AND (Id IN : userIds OR Id IN : userIds)');
        return (List<User>) Database.query(query.toSOQL());
    }
    
    public List<User> selectAdminUser(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        String adminProfile = 'System Administrator';
        query.selectField('Profile.Name');
        query.setCondition('isActive = true AND Id IN : recordIds AND Profile.Name =: adminProfile ');
        return (List<User>) Database.query(query.toSOQL());
    }
}