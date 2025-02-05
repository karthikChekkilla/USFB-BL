public class BL_SendApplicationCancellationEmail {
    
    @InvocableMethod(label='Send Cancellation Email')
    public static void sendCancellationEmail(List<LoanApplicationRequest> requestList) {
        System.debug('invoked : '+requestList);
        Loan_Application__c loanApp = [SELECT Id, (SELECT Email__c FROM Loan_Applicants__r) 
                                       FROM Loan_Application__c WHERE Id = :requestList[0].loanApplicationId LIMIT 1];
        
        List<Loan_Applicant__c> applicants = loanApp.Loan_Applicants__r;
        
        if (applicants.isEmpty()) {
            System.debug('Exit');
            return;
        }
        System.debug('called');
        sendEmail(applicants[0].Email__c, requestList[0].emailTemplateName, loanApp.Id);
    }
    
    private static void sendEmail(String recipientEmail, String templateName, Id loanAppId) {
        System.debug('sendEmail');
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
        
        if (template != null) {
            if(recipientEmail != null){
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.Id, null, loanAppId);
                message.setTargetObjectId(UserInfo.getUserId());
                OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :UB_ConstantsUtil.NO_REPLY_EMAIL_DISPLAY_NAME LIMIT 1];
                if (owea != null) {
                    message.setOrgWideEmailAddressId(owea.Id);
                } else {
                    System.debug('No noreply email address not found.');
                }
                System.debug('No noreply email address found.>>' + owea);
                message.setSaveAsActivity(false); 
                message.setTreatTargetObjectAsRecipient(false);
                message.toAddresses = new String[] {recipientEmail};
                    System.debug('message.toAddresses.>>' + message.toAddresses);
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                    try{
                        system.debug('success fully send email');
                        Messaging.sendEmail(messages); // email send
                    }catch(Exception e){
                        system.debug('error > ' + e);
                    }
            }
        }
    }
    
    public class LoanApplicationRequest {
        @InvocableVariable(required=true)
        public Id loanApplicationId;
        
        @InvocableVariable(required=true)
        public String emailTemplateName;
    }
}