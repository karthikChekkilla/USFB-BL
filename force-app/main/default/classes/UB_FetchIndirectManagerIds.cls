/**
* @File Name          : UB_FetchIndirectManagerIds.cls
* @Description        : Method to return DSA/RM Direct or Indirect Manager IDs which will store on Lead & Loan Application for sharing purposes.
* @Author             : Mohit
* @Test CLass         : 
* @Dependencies       : UB_Lead After Create Flow, UB_Lead After Update Flow, UB_Loan Application After Update Flow
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         08-05-2024               Mohit                 Initial Version
*/
public with sharing class UB_FetchIndirectManagerIds {
	public class FlowInputs{
        @InvocableVariable
        public String ownerID;         
    }
    
    @InvocableMethod
    public static List<List<String>> returnManagerIDs(List<FlowInputs> request){
        Boolean executionCompleted;
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> managerIdSet = new Set<Id>(); 
		List<List<String>> managerList = new List<List<String>>();
        if(!request.isEmpty() && request.size() > 0){
            for(FlowInputs input : request){
                ownerIdSet.add(input.ownerID);
            }
            List<User> userList = new UB_UsersSelector().selectById(ownerIdSet);
            if(!userList.isEmpty() && userList.size() > 0){
                for(User usr : userList){
                    managerIdSet.add(usr.Id);
                    if(usr.ManagerId != null){
                        managerIdSet.add(usr.ManagerId);
                    }
                }
                
                if(!managerIdSet.isEmpty() && managerIdSet.size() > 0){
                    do{
                        executionCompleted = true;
                        for(User usr : new UB_UsersSelector().selectByIdWIthManagerId(managerIdSet)){
                            if(!managerIdSet.contains(usr.Id) || (!managerIdSet.contains(usr.ManagerId) && usr.ManagerId != null)){
                                if(usr.ManagerId != null){
                                    managerIdSet.add(usr.ManagerId);
                                }
                                managerIdSet.add(usr.Id);
                                executionCompleted = false; 
                            }
                        }
                    } while(executionCompleted == false);
                } 
                for(FlowInputs input : request){
                    List<String> managerIdList = (List<String>)JSON.deserialize(JSON.serialize(managerIdSet), List<String>.class);
                    managerList.add(managerIdList);
                }
                System.debug('managerIdList@@ '+managerList);
                System.debug('managerIdList@@ '+managerList.size());
            }
        }
        return managerList;
    }
}