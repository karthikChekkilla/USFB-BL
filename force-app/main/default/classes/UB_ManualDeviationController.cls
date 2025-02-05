public class UB_ManualDeviationController {
    public class FlowInputs{
        @InvocableVariable
        public String recordId;         
    }
    
    public class FlowReturns{
        @InvocableVariable
        public List<String> devRecordIds;         
    }
    
    @AuraEnabled
    public static ResponseWrapper recommendDeviations(String authorityName, String loanApplicationId){
        ResponseWrapper response = new ResponseWrapper();
        
        try{
            if(String.isNotBlank(authorityName) && String.isNotBlank(loanApplicationId)){
                List<Loan_Application__c> listApplication = [SELECT Id, OwnerId FROM Loan_Application__c WHERE Id =: loanApplicationId];
                if(listApplication != null && listApplication.size() > 0){
                    String userId = [SELECT Id, Userrole.name FROM User WHERE userrole.name =: authorityName LIMIT 1].Id;
                    listApplication[0].OwnerId = String.isNotBlank(userId) ? userId : null;
                    UPDATE listApplication;
                    response.isSuccess = true;
                    response.responseBody = 'Recommended Successfully!!';
                }else{
                    response.isSuccess = false;
                    response.responseBody = 'Something Went Wrong!!';
                }
            }
        }catch(Exception ex){
            system.debug('error' + ex.getLineNumber());
            system.debug('error' + ex.getMessage());
            response.isSuccess = false;
            response.responseBody =  JSON.serialize(ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString() );
            return response;
        }
        RETURN response;
    }
        
    @AuraEnabled
    public static string getPendingDeviations(String loanApplicationId){
        String userRole = [SELECT Id, Userrole.name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].Userrole.name;
        system.debug('userRole-> ' + userRole);
        String message = '';
        List<Deviation_Sanction_Condition__c> deviationConditionList = [select id, Loan_Application__c, Decision__c, Authority_Role__c, Approving_Authority__c 
                                                                        FROM Deviation_Sanction_Condition__c WHERE Loan_Application__c =: loanApplicationId 
                                                                        AND Authority_Role__c =: userRole
                                                                        AND Decision__c NOT IN ('Approved','Rejected') // (Decision__c != 'Approved' AND Decision__c != 'Rejected')
                                                                       ];
        if(deviationConditionList != null && deviationConditionList.size() > 0){
            message = 'Please submit decision for deviations which are owned by you or your subordinates.';
        }else{
            message = 'Success';
        }
        RETURN message;
    }
    @InvocableMethod(label='Get Manual Deviations')
    public static List<FlowReturns> getManualDeviations(List<FlowInputs> request){
        if(request.size() != null && request.size() > 0){
            String productScheme = '';
            String productCategory = '';
            String productSubCategory = '';
            //List<Deviations__c> deviationList = new List<Deviations__c>();
            List<String> deviationIds = new List<String>();
            List<FlowReturns> objFlowReturnsList = new List<FlowReturns>();
            FlowReturns objFlowReturns = new FlowReturns();
            if(String.isNotBlank(request[0].recordId)){
                List<Product__c> productList = [select id, Product_Schemes__c, Product_Category__c, 
                                                Product_Sub_Category__c, Product__r.LOB__c  
                                                FROM Product__c WHERE 
                                                Loan_Application__c =: request[0].recordId];
               /* for(Product__c productObj : [select id, Product_Schemes__c, Product_Category__c, 
                                             Product_Sub_Category__c, Product__r.LOB__c  
                                             FROM Product__c WHERE 
                                             Loan_Application__c =: request[0].recordId]){
                                                 productScheme += productObj.Product_Schemes__c +';';
                                                 productCategory += productObj.Product_Category__c +';';
                                                 productSubCategory += productObj.Product_Sub_Category__c +';';
                                             }*/
                
                //system.debug('productScheme-> ' + productScheme);
                //system.debug('productCategory-> ' + productCategory);
                //system.debug('productSubCategory-> ' + productSubCategory);
                if(productList != null && productList.size() > 0){
                    if(productList.size() == 1){
                        for(Deviation_Master__c devObj : [select id , Product_Schemes__c, Product_Category__c, Product_Sub_Category__c, LOB__c from Deviation_Master__c  
                                                          WHERE  Product_Schemes__c includes (:productList[0].Product_Schemes__c) 
                                                          AND Product_Category__c includes ( :productList[0].Product_Category__c) 
                                                          AND Product_Sub_Category__c includes (:productList[0].Product_Sub_Category__c) AND Active__c = true]){
                                                              deviationIds.add(devObj.Id);
                                                          }
                    }if(productList.size() == 2){
                        for(Deviation_Master__c devObj : [select id , Product_Schemes__c, Product_Category__c, Product_Sub_Category__c, LOB__c from Deviation_Master__c  
                                                          WHERE  (Product_Schemes__c includes (:productList[0].Product_Schemes__c) OR Product_Schemes__c includes (:productList[1].Product_Schemes__c))
                                                          AND (Product_Category__c includes ( :productList[0].Product_Category__c) OR Product_Category__c includes ( :productList[1].Product_Category__c))
                                                          AND (Product_Sub_Category__c includes (:productList[0].Product_Sub_Category__c) OR Product_Sub_Category__c includes (:productList[1].Product_Sub_Category__c)) AND Active__c = true]){
                                                              deviationIds.add(devObj.Id);
                                                          }
                    }
                }
                
                objFlowReturns.devRecordIds = deviationIds;
                objFlowReturnsList.add(objFlowReturns);
                system.debug('objFlowReturnsList-> ' + objFlowReturnsList.size());
                RETURn objFlowReturnsList;
            }
        }
        RETURN null;
    }
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
    }
}