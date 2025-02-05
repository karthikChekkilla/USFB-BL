public class BL_SendRejectionEmailToCustomer {
    
    @InvocableMethod(label='Send Rejection email')
    public static void BL_SendRejectionEmail(list<String> loanId){
        system.debug('inside invocable method');
        EmailTemplate template = [SELECT Id, DeveloperName, Subject, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE DeveloperName =: BL_ConstantsUtil.REJECTION_LETTER
                                  LIMIT 1];
        system.debug('template>> ' + template);
        system.debug('LAF_ID>> ' + loanId);
        if(!loanId.isEmpty() && template.Id != null){
            Loan_Application__c lafrecord = [Select Id,(SELECT Id,Email__c, Name,Applicant_Name__c,Applicant_Type__c 
                                                        FROM Loan_Applicants__r WHERE Applicant_Type__c = 'Applicant' ) 
                                             FROM Loan_Application__c WHERE Id =:loanId[0]];
            system.debug('lafrecord>> ' + lafrecord);
            if(lafrecord != null){
                if(lafrecord.Loan_Applicants__r[0].Email__c != null){
                    
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
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
                    message.setTemplateID(template.Id); 
                    system.debug('lafrecord.Id-> ' + lafrecord.Id);
                    message.setWhatId(lafrecord.Id);
                    message.toAddresses = new String[] {lafrecord.Loan_Applicants__r[0].Email__c};
                        System.debug('message.toAddresses.>>' + message.toAddresses);
                    system.debug('message>> ' + message);
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
    }
}