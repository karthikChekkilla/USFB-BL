public class ResponseTaskController {

    @InvocableMethod(label = 'Response from task')
    public static List<ReturnVariable> taskResponse(List<FlowInputs> request) {
        if(request.size() > 0){
            List<ReturnVariable> responseVariableList = new List<ReturnVariable>();
            if(request[0].recordId != null && String.isNotBlank(request[0].recordId) && request[0].responseMsg != null && String.isNotBlank(request[0].responseMsg)){
                List<Task> taskList = [SELECT Id, Description FROM Task WHERE Id =: request[0].recordId];
                if(taskList.size() > 0){
                    ReturnVariable responseVar = new ReturnVariable();
                    String existingComment = taskList[0].Description;
                    String userInfo =  UserInfo.getFirstName()  + UserInfo.getLastName() + ' '+ '[' + System.now().format() +']' + ' : ' + request[0].responseMsg;
                    if(existingComment != null && String.isNotBlank(existingComment)){
                        //String userInfo =  UserInfo.getName + ' '+ (System.now()) ':' + request[0].responseMsg;
                        String newText = existingComment + '\r\n' + userInfo ;
                        responseVar.responseMsg = newText;
                    }else{
                        responseVar.responseMsg = userInfo; 
                    }
                    responseVariableList.add(responseVar);
                }
            }
            //system.debug('request-> ' + request);
            //system.debug('recordId-> ' + request[0].recordId);
            //system.debug('responseMsg-> ' + request[0].responseMsg);
            RETURN responseVariableList;
        }

       RETURN null;

    } 

    public class FlowInputs {
        @InvocableVariable public String recordId;
        @InvocableVariable public String responseMsg = '';
    }

    public class ReturnVariable {
        @InvocableVariable
        public String responseMsg = '';
   }
}