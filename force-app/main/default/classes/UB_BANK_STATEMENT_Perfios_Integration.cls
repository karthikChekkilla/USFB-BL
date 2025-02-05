/**
* @File Name          : UB_BANK_STATEMENT_Perfios_Integration
* @Description        : Class to Trigger Perfios APIs for retrieving TransactionId.
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/

public without sharing class UB_BANK_STATEMENT_Perfios_Integration implements Queueable, Database.AllowsCallouts {
    
    // Class level variables
    public Id customerId;
    private String password;
    private UB_HTTPCalloutService service;
    private UB_HTTPCalloutService callbackService;
    
    private static final String PROCESS_TYPE = 'STATEMENT';
    private static final String LOAN_TYPE = 'Personal Loan';
    
    /**
* Description: Parameterized Constructor for Passing the Parameters to Queueable Class.
* @param customerId - The ID of the customer for whom the transaction is being created.
*/
    public UB_BANK_STATEMENT_Perfios_Integration(Id customerId, String password) {
        this.customerId = customerId;
        this.password = password;
        this.service = new UB_HTTPCalloutService('Perfios_Initiate_Transaction_API');
       // this.callbackService = new UB_HTTPCalloutService('Perfios_Transaction_Callback');
    } 
    
    /**
* Description: Executes the Queueable job to create a transaction.
* @param context - The context of the queueable job.
*/
    public void execute(QueueableContext context) {
        try {
            createTransaction();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('In Line Number: ' + e.getLineNumber());
            UB_LogException error = new UB_LogException();
            error.log(e, '');
        }
    }
    
    /**
* Description: Method to create a transaction with Perfios.
*/
    public void createTransaction() {
        Verification__c verify = null;
        List<Verification__c> createVerifyList = new List<Verification__c>();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        
        HTTPResponse res = new HTTPResponse();
        List<Loan_Applicant__c> applicants = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        try {
            
            String bankName = applicants[0].Name_of_the_Bank__c;
            /*  Bank_Details__c bankDetail = selectBankDetailsByBankName(bankName);

if (bankDetail == null || String.isBlank(bankDetail.Institution_Id__c)) {
verify = createVerificationRecord('Institution Id is not available in Application Bank Details');
createVerifyList.add(verify);
insert createVerifyList;
applicants[0].Perfios_Verification__c = createVerifyList[0].Id;
update applicants;
return;
}*/
            
            String rangeFrom = '2019-01'; //system.now().addMonths(-6).format('yyyy-MM')
            String rangeTo = '2019-03'; //system.now().format('yyyy-MM');
            String loanType = applicants[0].Loan_Application__r.LOB__c != UB_ConstantsUtil.LOB_BL ? String.valueOf(applicants[0].Loan_Application__r.Product__c) : BL_ConstantsUtil.BL_PRODUCT_CATEGORY;
            UB_Perfios_IntegrationUtil.payloadParent plDetails = new UB_Perfios_IntegrationUtil.payloadParent(
                applicants[0].Id,
                String.valueOf(Integer.valueOf(applicants[0].Loan_Application__r.Amount__c)),
                String.valueOf(applicants[0].Loan_Application__r.Loan_Period__c),
                loanType,
                PROCESS_TYPE,
                rangeFrom,
                rangeTo,
                '',
                'atLeastOneTransactionPerMonthInRange',
                '20'//bankDetail.Institution_Id__c
            );
            
            UB_Perfios_IntegrationUtil.processPayload processPayload = new UB_Perfios_IntegrationUtil.processPayload();
            processPayload.payload = plDetails;
            String payload = JSON.serialize(processPayload, true);
            
            res = UB_Perfios_IntegrationUtil.initiateTransaction(payload);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            if (res.getStatusCode() == 200 && responseMap.containsKey('transaction')) {
                Map<String, Object> perfiosTransactionIdMap = (Map<String, Object>) responseMap.get('transaction');
                String perfiosTransactionId = (String) perfiosTransactionIdMap.get('perfiosTransactionId');
                
                verify = createVerificationRecord(null);
                verify.Perfios_Transaction_Id__c =perfiosTransactionId;//'RN3A1720448347043';
                verify.Loan_Applicant__c = customerId;
                verify.Password__c = password;
                createVerifyList.add(verify);
                
                insert createVerifyList;
                applicants[0].Perfios_Verification__c = createVerifyList[0].Id;
                update applicants;
                
                Document__c document = createDocumentRecord(applicants[0].Loan_Application__c, customerId, createVerifyList[0].Id);
                document.Document_Type__c = 'Banking Document';
                insert document;
                
                List<ContentVersion> cvObjList = selectContentVersionsByLinkedEntityId(customerId);
                UB_DisplayUBDocumentsController.uploadDocument('', cvObjList[0].Title, String.valueOf(cvObjList[0].VersionData), document.Id, cvObjList[0].Id);
                
                System.enqueueJob(new UB_Perfios_Upload_Files_Integration(customerId,perfiosTransactionId, cvObjList,  createVerifyList[0].Id));
            } else {
                verify = createVerificationRecord('Received status code ' + res.getStatusCode());
                createVerifyList.add(verify);
            }
            
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                service.getEndpointURL(), 
                String.valueOf(service.getHeaderParameters()), 
                service.getRequestMethod(), 
                String.valueOf(plDetails), 
                res.getBody(), 
                res.getStatusCode(), 
                UB_BANK_STATEMENT_Perfios_Integration.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'Perfios Initiate Transaction',
                'CV'
            );
            createLogList.add(apiLogger);
            if (!createLogList.isEmpty()) {
                UB_API_LoggerUtility.insertRecords(createLogList);
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('In Line Number: ' + e.getLineNumber());
            UB_LogException error = new UB_LogException();
            error.log(e, '');
            
            verify = createVerificationRecord(e.getMessage() + ' at line ' + e.getLineNumber());
            createVerifyList.add(verify);
        }
        
        if (!createVerifyList.isEmpty() && createVerifyList[0].Id == null) {
            insert createVerifyList;
            applicants[0].Perfios_Verification__c = createVerifyList[0].Id;
            update applicants;
        }
    }
    
    private Verification__c createVerificationRecord(String failedReason) {
        Verification__c verify = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.PERFIOS_API_RECORD_TYPE, 'In Progress');
        verify.Failed_Reason__c = failedReason;
        verify.Loan_Applicant__c = customerId;
        return verify;
    }
    
    private Document__c createDocumentRecord(Id loanApplicationId, Id customerId, Id verificationId) {
        Document__c document = new Document__c();
        document.Loan_Application__c = loanApplicationId;
        document.Loan_Applicant__c = customerId;
        document.Verification__c = verificationId;
        document.Document_Type__c = 'Banking Document';
        document.Status__c = 'Uploaded';
        return document;
    }
    
    private Bank_Details__c selectBankDetailsByBankName(String bankName) {
        List<Bank_Details__c> bankDetails = [SELECT Id, Institution_Id__c 
                                             FROM Bank_Details__c 
                                             WHERE Bank_Name__c = :bankName];
        if (!bankDetails.isEmpty()) {
            return bankDetails[0];
        }
        return null;
    }
    
    private List<ContentVersion> selectContentVersionsByLinkedEntityId(Id linkedEntityId) {
        List<String> contentDocumentIdList = new List<String>();
        for (ContentDocumentLink docLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :customerId]) {
            contentDocumentIdList.add(docLink.ContentDocumentId);
            System.debug('document id: ' + docLink.ContentDocumentId);
        }
        
        // Fetch the content versions of the documents
        List<ContentVersion> cvObjList = [SELECT Title, Id, VersionData, FileType FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIdList ORDER BY CreatedDate DESC LIMIT 1];
        
        return cvObjList;
       
    }
}