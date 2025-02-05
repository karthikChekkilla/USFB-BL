/**
* @File Name          : BL_RejectionLetterCltr.cls
* @Description        : This class use to map sanction lettee .
* @Author             : Lakshya Verma
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-08-2024            Lakshya Verma         Initial Version           
**/
public class BL_RejectionLetterCltr {
    public String plainHTML { get; set; }
    public String loanId{get;set;}   
    public List<Loan_Application__c> loanAppObj { get; set; }
    public String todayDate { get; set; }
    //public BL_RejectionLetterCltr(ApexPages.StandardController controller) {
        //loanId = apexpages.currentPage().getParameters().get('Id');
    //}
    //
    
    public List<Loan_Application__c> getLoanDetails() {
        if (this.loanId != null && String.isNotEmpty(this.loanId)){
            loanAppObj = [SELECT Id, Name,Lead__r.CreatedDate,Reject_Sub_Reason__c,Reject_Reason__c, BL_Product_Category__c,
                                      (SELECT Id, Name,Applicant_Name__c,Applicant_Type__c FROM Loan_Applicants__r WHERE Applicant_Type__c = 'Applicant' ), 
                                      (SELECT Id, Product_Category__c FROM Products__r LIMIT 1) 
                                      FROM Loan_Application__c 
                                      WHERE Id =: this.loanId];
            System.debug('**loanAppObj->   '+loanAppObj );
            if(!loanAppObj.isEmpty()){
                todayDate = String.valueOf(Date.today().day()).leftPad(2, '0') + '/' +
                    String.valueOf(Date.today().month()).leftPad(2, '0') + '/' +
                    String.valueOf(Date.today().year());
                System.debug('>>>>>> ' + !loanAppObj[0].Loan_Applicants__r.isEmpty());
                
                EmailTemplate tempID = [SELECT Id,Name,Body,HTMLValue FROM EmailTemplate WHERE DeveloperName  =: BL_ConstantsUtil.REJECTION_LETTER];
                String emailBody = tempID.Body;
                //mapping vehicle details
                
                emailBody = emailBody.replace('{rec.Name}', loanAppObj[0].name);
                emailBody = emailBody.replace('{rec1.Name}', loanAppObj[0].name  );
                emailBody = emailBody.replace('{dated}', todayDate);
                emailBody = emailBody.replace('{Date}', todayDate);
                emailBody = emailBody.replace('{product.Product_Category__c}', loanAppObj[0].BL_Product_Category__c);
                System.debug('emailBody after change>   '+ emailBody );
                return loanAppObj;
            } 
        }
        RETURN null;
    }
    
    public void getPDF(){
        try {
            loanId = apexpages.currentPage().getParameters().get('Id');
            System.debug('VALUEEEEEEEEEEEEE  '+loanId);
            plainHTML = createEmailBody(loanId);
        }catch(Exception e) {
            System.debug('ERRORRRRRRRRRR    '+e.getMessage());
            System.debug('Line   No'+e.getLineNumber());
        }
    }
    
    public static String createEmailBody(String loanApplicationId){
        String productCat = '';
        String ApplicantId= '';
        datetime d = system.today();
        String todayDate = String.valueOf(Date.today().day()).leftPad(2, '0') + '/' +
            String.valueOf(Date.today().month()).leftPad(2, '0') + '/' +
            String.valueOf(Date.today().year());
        system.debug('todayDate >  ' + todayDate);
        List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanApplicationId});
        
        System.debug('**loanAppObj->   '+loanAppObj );
        if(!loanAppObj.isEmpty()){
            System.debug('>>>>>> ' + !loanAppObj[0].Loan_Applicants__r.isEmpty());
           
            EmailTemplate tempID = [SELECT Id,Name,Body,HTMLValue FROM EmailTemplate WHERE DeveloperName  =: BL_ConstantsUtil.REJECTION_LETTER];
            String emailBody = tempID.Body;
            //mapping vehicle details
            
            emailBody = emailBody.replace('{rec.Name}', loanAppObj[0].name);
            emailBody = emailBody.replace('{rec1.Name}', loanAppObj[0].name  );
            emailBody = emailBody.replace('{dated}', todayDate);
            emailBody = emailBody.replace('{Date}', todayDate);
            emailBody = emailBody.replace('{product.Product_Category__c}', loanAppObj[0].BL_Product_Category__c);
            System.debug('emailBody after change>   '+ emailBody );
            return emailBody;
        } 
        return null;
    }
}