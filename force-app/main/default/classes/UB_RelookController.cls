/**
* @File Name          : UB_RelookController.cls
* @Description        : This class use to relook rejected records.
* @Author             : Kamal Hussain
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         02-04-2024            Kamal Hussain           Initial Version           
**/
public class UB_RelookController {

    // rellok lead functionality
    @AuraEnabled
    public static void relookLead(string leadId, string comment) {
            system.debug(leadId);
            system.debug(comment);
            lead__c leadRec = [SELECT Id, Rejected_By__c,Comment__c, Lead_Status__c, ownerId FROM lead__c WHERE Id =:leadId];
            leadRec.Lead_Status__c = 'Active';
            leadRec.ownerId = leadRec.Rejected_By__c;
            leadRec.Rejected_By__c = null;
            leadRec.Comment__c = comment;
            update leadRec;
    }

    // rellok loan application functionality
    @AuraEnabled
    public static void relookApplication(string applicationId, string comment) {
            try{
                system.debug('==================');
                Loan_Application__c appliRec = [SELECT Id, Rejected_By__c,Comment__c, ownerId, Loan_Application_Status__c FROM Loan_Application__c WHERE Id =:applicationId];
                appliRec.Loan_Application_Status__c = 'Active';
                appliRec.Comment__c = comment;
                appliRec.ownerId = appliRec.Rejected_By__c;
                appliRec.Rejected_By__c = null;
                update appliRec;
            }catch(Exception e){
                String customMessge = e.getMessage();
                Integer startIndex = customMessge.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
                if (startIndex != -1) {
                        startIndex += 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length() + 2;
                        customMessge =  'ERROR: '+customMessge.substring(startIndex);
                }else{
                        Integer startIndex1 = customMessge.indexOf('INVALID_CROSS_REFERENCE_KEY');
                        if(startIndex1 != -1){
                                startIndex1 += 'INVALID_CROSS_REFERENCE_KEY'.length() + 2;
                                customMessge =  'ERROR: '+customMessge.substring(startIndex1);
                        }
                }
                //return customMessge;
                throw new AuraHandledException(customMessge);
            }
            
    }
}