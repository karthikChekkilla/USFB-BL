/**
* @File Name          : UB_Perfios_Retrieve_Report_Integration
* @Description        : Class to Trigger Perfios APIs for Retrieving Reports
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class UB_Perfios_Retrieve_Report_Integration implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    private final UB_HTTPCalloutService service; 
    public Id customerDocId;
    public String transactionID;
    List<API_Logger__c> createLogList = new List<API_Logger__c>();
    
    // Constants
    private static final Integer STATUS_CODE_SUCCESS = 200;
    private static final String FILE_TYPE = 'xlsx';
    
    /**
* Parameterized Constructor
* 
* @param customerDocId - The ID of the customer document.
* @param transactionID - The transaction ID.
*/
    public UB_Perfios_Retrieve_Report_Integration(Id customerDocId, String transactionID) {
        this.service = new UB_HTTPCalloutService('Perfios_Initiate_Transaction_API');
        this.customerDocId = customerDocId;
        this.transactionID = transactionID;
    }
    
    /**
* Non-Parameterized Constructor needed for the implementation of UbRetryApiLwcController.IReTryAPI (Interface).
*/
    public UB_Perfios_Retrieve_Report_Integration() {
        // this.service = new UB_HTTPCalloutService();
    }
    
    /**
* Method to execute the Queueable job
*/
    public void execute(QueueableContext context) {
        if (isValidCustomerDocId(this.customerDocId)) {           
            retrieveReportFile(this.transactionID);
        }
    }
    
    /**
* Method to check if the customer document ID is valid
*/
    private Boolean isValidCustomerDocId(Id customerDocId) {
        return customerDocId != null && String.isNotEmpty(customerDocId);
    }
    
    /**
* Method to retrieve the report file
* 
* @param transactionId - The transaction ID.
*/
    public void retrieveReportFile(String transactionId) {   
        try {
            List<Loan_Applicant__c> applicants = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerDocId});
            HTTPResponse res = UB_Perfios_IntegrationUtil.retrieveReport(transactionId, FILE_TYPE,string.valueof(customerDocId));
            system.debug('res====>'+res);
            
            
            if (res.getStatusCode() == STATUS_CODE_SUCCESS) {
                String verificationId = UB_CommonUtil.fetchVerificationId(customerDocId,UB_ConstantsUtil.PERFIOS_API);               
                UB_Perfios_IntegrationUtil.saveFile(res, verificationId, 'Report', FILE_TYPE,customerDocId,applicants[0].Loan_Application__c);
            } else {
                handleUnsuccessfulResponse(res);
            }
        } catch (Exception e) {
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber());
            UB_LogException error = new UB_LogException();
            error.log(e, '');
        }
    }
    
    /**
* Method to handle unsuccessful responses
* 
* @param res - The HTTP response.
*/
    private void handleUnsuccessfulResponse(HTTPResponse res) {
        System.debug('Unexpected status code: ' + res.getStatusCode());
    }
}