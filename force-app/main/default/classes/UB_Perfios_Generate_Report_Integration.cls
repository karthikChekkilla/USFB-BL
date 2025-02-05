/**
* @File Name          : UB_Perfios_Generate_Report_Integration
* @Description        : Class to Trigger Perfios APIs for Generating Reports
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class UB_Perfios_Generate_Report_Integration implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    private final UB_HTTPCalloutService service;
    public String transactionID;
    public String customerDocumentID,verificationId;
    List<API_Logger__c> createLogList = new List<API_Logger__c>();
    
    // Constants
    private static final Integer STATUS_CODE_ACCEPTED = 202;
    
    /**
* Parameterized Constructor
* 
* @param customerDocumentID - The ID of the customer document.
* @param transactionID - The transaction ID.
*/
    public UB_Perfios_Generate_Report_Integration(String customerDocumentID, String transactionID,string verificationId) {
        // this.service = new UB_HTTPCalloutService();
        this.transactionID = transactionID;
        this.customerDocumentID = customerDocumentID;
        this.verificationId = verificationId;
         this.service = new UB_HTTPCalloutService('Perfios_Generate_Report_API');
    }
    
    // Default constructor
    public UB_Perfios_Generate_Report_Integration() {
      
    }
    
    /**
* Method to execute the Queueable job
*/
    public void execute(QueueableContext context) {
        if (isValidTransactionId(this.transactionID)) {
            generateReport(this.transactionID);
        }
    }
    
    /**
* Method to check if the transaction ID is valid
*/
    private Boolean isValidTransactionId(String transactionId) {
        return String.isNotEmpty(transactionId) && String.isNotBlank(transactionId);
    }
    
    /**
* Method to generate the report
* 
* @param transactionId - The transaction ID.
*/
    public void generateReport(String transactionId) {  
        try {
            Verification__c verification = [SELECT Id,Perfios_API_Status__c,Is_Report_available__c,Loan_Applicant__c,Processing_Files_Done__c FROM Verification__c WHERE Perfios_Transaction_Id__c =:transactionId AND Loan_Applicant__c =:customerDocumentID LIMIT 1];          
            HTTPResponse res = UB_Perfios_IntegrationUtil.generateReport(transactionId,customerDocumentID);            
            if (res.getStatusCode() == STATUS_CODE_ACCEPTED) {
                System.enqueueJob(new UB_Perfios_Status(transactionID,customerDocumentID));
               // HTTPResponse res1 = UB_Perfios_IntegrationUtil.getPerfiosSatus(transactionID,customerDocumentID);
                
                // Deserialize the JSON string into a map
              //  Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(res1.getBody());
               // System.debug('deserializedResult==>' + deserializedResult);
                
                // Access the nested map to get the required values
              /*    if (deserializedResult.containsKey('transactions')) {
                    Map<String, Object> transactions = (Map<String, Object>) deserializedResult.get('transactions');
                    
                  if (transactions.containsKey('transaction')) {
                        Map<String, Object> transactionRec = (Map<String, Object>) transactions.get('transaction');
                        Boolean reportAvailable = (Boolean) transactionRec.get('reportAvailable');
                        String status = (String) transactionRec.get('status');
                        
                        System.debug('reportAvailable==>' + reportAvailable);
                        System.debug('status==>' + status);
                        verification.Perfios_API_Status__c = status;
                        verification.Is_Report_available__c = reportAvailable;
                        update verification;
                        if(status == 'COMPLETED' && reportAvailable){
                            system.debug('inside fetching the document');
                            System.enqueueJob(new UB_Perfios_Retrieve_Report_Integration(customerDocumentID, transactionID));
                        }
                    }
                }*/
                // System.enqueueJob(new UB_Perfios_Retrieve_Report_Integration(customerDocumentID, transactionID));
            } else {
                updateVerificationRecordWithFailureStatus(res);
            }
        } catch (Exception e) {           
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber()); 
            UB_LogException error = new UB_LogException();
            error.log(e, '');
            
        }
    }
    
    /**
* Method to update the verification record with failure status
*/
    private void updateVerificationRecordWithFailureStatus(HTTPResponse res ) {
}
}