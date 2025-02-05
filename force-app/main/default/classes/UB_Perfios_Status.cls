/**
* @File Name          : UB_Perfios_Generate_Report_Integration
* @Description        : Class to get Perfios APIs status
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class UB_Perfios_Status implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    private final UB_HTTPCalloutService service;
    public String transactionID, customerDocumentID;
    
    // Constants
    private static final Integer STATUS_CODE_ACCEPTED = 200;
    
    /**
* Parameterized Constructor
* 
* @param customerDocumentID - The ID of the customer document.
* @param transactionID - The transaction ID.
*/
    public UB_Perfios_Status(String transactionID, String customerDocumentID) {
        // this.service = new UB_HTTPCalloutService();
        this.transactionID = transactionID;
        this.customerDocumentID = customerDocumentID;
    }
    
    // Default constructor
    public UB_Perfios_Status() {
        // this.service = new UB_HTTPCalloutService();
    }
    
    /**
* Method to execute the Queueable job
*/
    public void execute(QueueableContext context) {
        if (isValidTransactionId(this.transactionID)) {
            getCurrentPerfiosStatus(this.transactionID);
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
    public void getCurrentPerfiosStatus(String transactionId) {
        //transactionId = 'RN3A1720448347043';
        List<Verification__c> verificationLst = new List<Verification__c>();
        List<Verification__c> verifications = [SELECT Id,Perfios_API_Status__c,Loan_Applicant__c,Is_Report_available__c FROM Verification__c WHERE Perfios_Transaction_Id__c =:transactionId AND Loan_Applicant__c=:customerDocumentID  ORDER BY CreatedDate Desc LIMIT 1];
        try {
            HTTPResponse res = UB_Perfios_IntegrationUtil.getPerfiosSatus(transactionId,customerDocumentID);
            System.debug('res.getStatusCode()==>' + res.getStatusCode());
            if (res.getStatusCode() == STATUS_CODE_ACCEPTED) {
                System.debug('response body===>' + res.getBody());
                
                // Deserialize the JSON string into a map
                Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('deserializedResult==>' + deserializedResult);
                
                // Access the nested map to get the required values
                if (deserializedResult.containsKey('transactions')) {
                    Map<String, Object> transactions = (Map<String, Object>) deserializedResult.get('transactions');
                    if (transactions.containsKey('transaction')) {
                        Map<String, Object> transactionRec = (Map<String, Object>) transactions.get('transaction');
                        Boolean reportAvailable = (Boolean) transactionRec.get('reportAvailable');
                        String status = (String) transactionRec.get('status');
                        
                        System.debug('reportAvailable==>' + reportAvailable);
                        System.debug('status==>' + status);
                        if(verifications.size()>0){
                            verifications[0].Perfios_API_Status__c = status;
                            verifications[0].Is_Report_available__c = reportAvailable;
                            verifications[0].Status__c = 'Completed';
                            //verificationLst.add(verification);
                        }                       
                        
                        if(verifications.size()>0){
                            update verifications;
                        }
                        if(status == 'COMPLETED' && reportAvailable){
                            system.debug('inside fetching the document');
                            System.enqueueJob(new UB_Perfios_Retrieve_Report_Integration(customerDocumentID, transactionID));
                            // System.enqueueJob(new UB_Perfios_Retrieve_Report_Integration(customerDocumentID, transactionID));
                        }
                    }
                }
                
                // Continue your logic here, for example:
                // System.enqueueJob(new UB_Perfios_Retrieve_Report_Integration(customerDocumentID, transactionID));
            } else {
                updateVerificationRecordWithFailureStatus();
            }
        } catch (Exception e) {
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber());
        }
    }
    
    /**
* Method to update the verification record with failure status
*/
    private void updateVerificationRecordWithFailureStatus() {
        // Implement the logic to update the verification record with failure status
        System.debug('Update the verification record with failure status');
    }
}