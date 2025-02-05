/**
* @File Name          : UB_Perfios_Generate_Report_Integration
* @Description        : Class to schedule the status and retrieve the report
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public class UB_Perfios_Scheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        
        List<Verification__c> verificationLstForReport = [SELECT Id,Loan_Applicant__c,Perfios_Transaction_Id__c FROM Verification__c where Perfios_Transaction_Id__c != null AND Is_Report_available__c = false AND Processing_Files_Done__c = true];
        if(verificationLstForReport.size()>0){
              for(Verification__c verify : verificationLstForReport){
            UB_Perfios_Status queueableInstance = new UB_Perfios_Status(verify.Perfios_Transaction_Id__c,verify.Loan_Applicant__c);
            System.enqueueJob(queueableInstance);
        }
        }
    }
}