/**
* @File Name          : UB_Perfios_Process_Files_Integration
* @Description        : Class to Trigger Perfios APIs for Processing Files
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class UB_Perfios_Process_Files_Integration implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    public Id customerDocId;
    public String password,payload ;
    public String fileID;
    public Boolean isRetry;
    public List<ContentVersion> conVerList;
    public String transactionID,verificationId;
    private UB_HTTPCalloutService service;
    List<API_Logger__c> createLogList = new List<API_Logger__c>();
    
    // Constants
    private static final String PROCESS_TYPE_STATEMENT = 'STATEMENT';
    private static final Integer STATUS_CODE_OK = 200;
    private static final Integer STATUS_CODE_ACCEPTED = 202;
    
    /**
* Parameterized Constructor
* 
* @param customerDocId - The ID of the customer document.
* @param fileID - The file ID.
* @param password - The password.
* @param isRetry - Flag to indicate if it's a retry.
* @param conVerList - List of ContentVersion objects.
* @param transactionID - The transaction ID.
*/
    public UB_Perfios_Process_Files_Integration(Id customerDocId, String fileID, String password, String verificationId, List<ContentVersion> conVerList, String transactionID) {
        this.customerDocId = customerDocId;
        this.fileID = fileID;
        this.password = password;
        this.isRetry = isRetry;
        this.conVerList = conVerList;
        this.transactionID = transactionID;
        this.verificationId = verificationId;
         this.service = new UB_HTTPCalloutService('Perfios_Process_Files_API');
    }
    
    // Default constructor
    public UB_Perfios_Process_Files_Integration() {
       
    }
    
    /**
* Method to execute the Queueable job
*/
    public void execute(QueueableContext context) {
        if (isValidInput()) {
            Boolean isSuccess = processFiles(this.transactionID, this.fileID, PROCESS_TYPE_STATEMENT);
            
            this.conVerList.remove(0);
            System.debug('conv size==>' + this.conVerList.size());
            
            if (isSuccess) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new UB_Perfios_Generate_Report_Integration(this.customerDocId, this.transactionID,verificationId));
                } 
            }
        }
    }
    
    /**
* Method to check if the input is valid
*/
    private Boolean isValidInput() {
        return String.isNotEmpty(this.customerDocId) && String.isNotBlank(this.customerDocId);
    }
    
    /**
* Method to process files
* 
* @param transactionId - The transaction ID.
* @param fileId - The file ID.
* @param processType - The type of process.
* @return isSuccess - Boolean indicating if the process was successful.
*/
    public Boolean processFiles(String transactionId, String fileId, String processType) {
        Boolean isSuccess = false;
        List<Verification__c> verificationLst = new List<Verification__c>();
        Verification__c verification = [SELECT Id,Perfios_API_Status__c,Is_Report_available__c,Loan_Applicant__c,Processing_Files_Done__c FROM Verification__c WHERE Perfios_Transaction_Id__c =:transactionId AND Loan_Applicant__c =:customerDocId LIMIT 1];
        try {
            payload = createPayload(fileId, this.password);
            HTTPResponse res = UB_Perfios_IntegrationUtil.processFiles(transactionId, fileId, processType,customerDocId);
            
            System.debug('Response: ---' + res.getBody());
            System.debug('Response status code: ' + res.getStatusCode());
            
            if (res.getStatusCode() == STATUS_CODE_OK || res.getStatusCode() == STATUS_CODE_ACCEPTED) {
                isSuccess = true;
                verification.Processing_Files_Done__c = true;
                update verification;
                
            } else {
                handleErrorResponse(res);
            }
        } catch (Exception e) {
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber());
            UB_LogException error = new UB_LogException();
            error.log(e, '');
        }
        
        return isSuccess;
    }
    
    /**
* Method to create the payload for processing files
* 
* @param fileId - The file ID.
* @param password - The password.
* @return payload - The serialized payload.
*/
    private String createPayload(String fileId, String password) {
        UB_Perfios_IntegrationUtil.processPayload processPayload = new UB_Perfios_IntegrationUtil.processPayload();
        UB_Perfios_IntegrationUtil.payloadParent plDetails = new UB_Perfios_IntegrationUtil.payloadParent(fileId, password);
        processPayload.payload = plDetails;
        return JSON.serialize(processPayload, true);
    }
    
    /**
* Method to handle error responses
* 
* @param res - The HTTP response.
*/
    private void handleErrorResponse(HTTPResponse res) {
        System.debug('status code not 200 or 202');
        string code,message;
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        
        if (responseMap.containsKey('error')) {
            Map<String, Object> responseDataMap = (Map<String, Object>)responseMap.get('error');
            List<Object> details = new List<Object>();
            
            if (responseDataMap.containsKey('details')) {
                details = (List<Object>)responseDataMap.get('details');
            }
            
            if (!details.isEmpty()) {
                Map<String, Object> detail = (Map<String, Object>)details[0];
                System.debug(String.valueOf(detail.get('code')));
                System.debug(String.valueOf(detail.get('message')));
                code = String.valueOf(detail.get('code'));
                message = String.valueOf(detail.get('message'));
            } else {
                System.debug(String.valueOf(responseDataMap.get('code')));
                System.debug(String.valueOf(responseDataMap.get('message')));
                code = String.valueOf(responseDataMap.get('code'));
                message = String.valueOf(responseDataMap.get('message'));
            }
        }
    }
}