/**
* @File Name          : UB_sendBackController
* @Description        : Class to Trigger Send Back Functionality
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/

public class UB_sendBackController {
    
    /**
* Handles the send-back operation for Loan Application and Disbursement records, 
* processing based on record ID, object type, current stage, record type, and 
* user-selected stage, with reassignment and reason logging.
*/
    
    @AuraEnabled
    public static void handleSendBack(
        Id recordId, 
        String objectApiName, 
        String loanStage, 
        String recordType, 
        String ownerRole, 
        String selectedStage, 
        String sendBackReason, 
        Id ownerToBeId) {
            
            // Debug logs for input parameters
            System.debug('Record ID: ' + recordId);
            System.debug('Object API Name: ' + objectApiName);
            System.debug('Loan Stage: ' + loanStage);
            System.debug('Record Type: ' + recordType);
            System.debug('Owner Role: ' + ownerRole);
            System.debug('Selected Stage: ' + selectedStage);
            System.debug('Send Back Reason: ' + sendBackReason);
            System.debug('Owner To Be ID: ' + ownerToBeId);
            
            // Process based on the object type
            if (objectApiName == 'Loan_Application__c') {
                handleLoanApplicationSendBack(recordId, loanStage, 'Underwriting Initiated', 'Credit Manager', selectedStage, sendBackReason, ownerToBeId);
            }
            if (objectApiName == 'Disbursement__c') {
                system.debug('inside disbursement');
                handleLoanApplicationSendBack(recordId, loanStage, 'Disbursement Initiated', 'Credit Manager', selectedStage, sendBackReason, ownerToBeId);
            }
        }
    
    /**
* Handles send-back logic for Loan Application records, updating based on record ID, stage, type, owner role, 
* selected stage, reassignment target, and reason for send back.
*/
    
    private static void handleLoanApplicationSendBack(Id recordId, String loanStage, String recordType, String ownerRole, String selectedStage, String sendBackReason, Id ownerToBeId) {
        // Get the user's time zone
        TimeZone userTimeZone = UserInfo.getTimeZone();
        
        // Format the current datetime according to the user's local time zone
        String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss', userTimeZone.getID());
        
        
        // Fetch the current user details
        User currentUser = [SELECT Username,Name, EmployeeNumber FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Format the new comment with username, employee number, and timestamp
        String formattedComment = '---\nUser: ' + currentUser.username + 
            '\nEmployee Number: ' + currentUser.EmployeeNumber + 
            '\nTime: ' + timestamp +  '\n';
        
        
        // Fetching the Loan Application record
        Loan_Application__c loanApp = [
            SELECT Id, Loan_Application_Stage__c, OwnerId, CPA__c, CM__c, Send_Back__c,Decisioning_Comments__c,Loan_Application_Status__c
            FROM Loan_Application__c 
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        
        // Handling send back based on the current loan stage and record type
        if (loanStage == 'Credit Assessment' && recordType == 'Underwriting Initiated') {
            loanApp.Loan_Application_Stage__c = 'DDE';
            loanApp.OwnerId = determineOwnerId(ownerToBeId, 'BL_CPA_Queue');
            loanApp.isSendBackToDDE__c = true;
            updateRecordType(recordId,'DDE','Loan_Application__c');
            signedDocumentReTriggerValidation(loanApp.Id);
        } else if (loanStage == 'Recommended for Approval' && recordType == 'Underwriting Initiated') {
            loanApp.Loan_Application_Stage__c = selectedStage;
            if (selectedStage == 'DDE') {
                loanApp.OwnerId = determineOwnerId(ownerToBeId, 'BL_CPA_Queue');
                loanApp.isSendBackToDDE__c = true;
                updateRecordType(recordId,'DDE','Loan_Application__c');
                signedDocumentReTriggerValidation(loanApp.Id);
            } else if (selectedStage == 'Credit Assessment') {
                loanApp.OwnerId = determineOwnerId(loanApp.CM__c, 'Credit_Manager_Queue');
            }
        }else if (loanStage == 'Disbursal In Progress' && recordType == 'Disbursement Initiated' && selectedStage == 'Credit Assessment') {
            system.debug('inside disbursement disbursement initi');
            loanApp.Loan_Application_Stage__c = 'Credit Assessment';
            loanApp.OwnerId = determineOwnerId(ownerToBeId, 'BL_CPA_Queue');
            loanApp.isSendBackToDDE__c = true;
            updateRecordType(recordId,'Underwriting Initiated','Loan_Application__c');
        }else if (loanStage == 'Disbursal In Progress' && recordType == 'Disbursement Initiated' && selectedStage == 'Recommended for Approval') {
            loanApp.Loan_Application_Stage__c = 'Recommended for Approval';
            loanApp.OwnerId = determineOwnerId(ownerToBeId, 'BL_CPA_Queue');
            loanApp.isSendBackToDDE__c = true;
            updateRecordType(recordId,'Underwriting Initiated','Loan_Application__c');
        }else if (loanStage == 'Disbursal In Progress' && recordType == 'Disbursement Initiated' && selectedStage == 'DDE') {
            loanApp.Loan_Application_Stage__c = 'DDE';
            loanApp.OwnerId = determineOwnerId(ownerToBeId, 'BL_CPA_Queue');
            loanApp.isSendBackToDDE__c = true;
            updateRecordType(recordId,'DDE','Loan_Application__c');
            signedDocumentReTriggerValidation(loanApp.Id);
        }
        loanApp.Loan_Application_Status__c = 'Active';
        loanApp.isSendBackforMoveToNext__c = true;
        // Append the new comment to the existing comments
        if (loanApp.Decisioning_Comments__c != null) {
            loanApp.Decisioning_Comments__c += '\n' + formattedComment;
        } else {
            loanApp.Decisioning_Comments__c = formattedComment;
        }
        
        // Update the Send Back reason and save the record
        loanApp.Send_Back__c = sendBackReason;
        update loanApp;
        
        createActivityHistoryRecord(loanApp.Id, loanStage, selectedStage, ownerToBeId);
    }
    
    /**
* Determines the owner ID to assign, using a fallback queue if the user is inactive, 
* returning the active user ID or fallback queue ID.
*/
    
    private static Id determineOwnerId(Id userId, String fallbackQueue) {
        if (isUserActive(userId)) {
            return userId;
        } else {
            Group fallbackQueueGroup = [
                SELECT Id 
                FROM Group 
                WHERE Name = :fallbackQueue
                LIMIT 1
            ];
            return fallbackQueueGroup.Id;
        }
    }
    
    /**
* Verifies if the user with the given ID is active, returning true if active, otherwise false.
*/
    
    private static Boolean isUserActive(Id userId) {
        User user = [
            SELECT IsActive 
            FROM User 
            WHERE Id = :userId
            LIMIT 1
        ];
        return user != null && user.IsActive;
    }
    
    /** Retrieves the record type name for the given record type ID. */
    
    @AuraEnabled(cacheable=true)
    public static String getRecordTypeName(String recordTypeId) {
        RecordType recordType = [
            SELECT Name 
            FROM RecordType 
            WHERE Id = :recordTypeId 
            LIMIT 1
        ];
        return recordType.Name;
    }
    
    /** Retrieves the Loan Application record linked to the given Disbursement ID, or null if not found. */
    
    @AuraEnabled(cacheable=true)
    public static Loan_Application__c getLoanApplicationByDisbursement(Id disbursementId) {
        system.debug('disbursementId===>' + disbursementId);
        
        // Query Disbursement__c record
        List<Disbursement__c> disbursementList = [
            SELECT Loan_Application__c 
            FROM Disbursement__c 
            WHERE Id = :disbursementId
            LIMIT 1
        ];
        
        // Check if the disbursement record is found
        if (!disbursementList.isEmpty()) {
            Disbursement__c disbursement = disbursementList[0];
            
            if (disbursement.Loan_Application__c != null) {
                // Query the related Loan_Application__c record
                List<Loan_Application__c> loanAppList = [
                    SELECT Id, Loan_Application_Stage__c, OwnerId, CPA__c, CM__c,Final_Authority__c 
                    FROM Loan_Application__c 
                    WHERE Id = :disbursement.Loan_Application__c
                    LIMIT 1
                ];
                system.debug('loanAppList[0]===>'+loanAppList[0]);
                // Return the Loan_Application__c record if found
                if (!loanAppList.isEmpty()) {
                    return loanAppList[0];
                }
            }
        }
        
        // Return null if no matching records found
        return null;
    }
    
    public static user getCurrentUserDetail(){
        return [SELECT id,name,profile.name,UserRole.Name from user WHERE id =:userinfo.getuserid()];
    }
    public static void createActivityHistoryRecord(Id loanApplicationId, String fromStage, String toStage, Id toUserId) {
        // Create a new Activity_History__c record
        Activity_History__c activityHistory = new Activity_History__c();
        
        // Set the related Loan Application ID (assuming there is a lookup or master-detail relationship)
        activityHistory.Loan_Application__c = loanApplicationId;
        
        // Set the stage movement fields
        activityHistory.From_Stage__c = fromStage;
        activityHistory.To_Stage__c = toStage;
        
        // Set the user the record is assigned to
        activityHistory.To_User__c = toUserId;
        
        //set the isSendBack to true
        activityHistory.isSendBack__c = true;
        // Insert the Activity_History__c record
        insert activityHistory;
    }
    public static void updateRecordType(Id recordId, String recordTypeName, String sObjectType) {
        //Query the RecordType based on Name and sObject Type
        RecordType recordType = [
            SELECT Id FROM RecordType 
            WHERE Name = :recordTypeName 
            AND SObjectType = :sObjectType 
            LIMIT 1
        ];
        
        // Check if the record type exists
        if (recordType != null) {
            // Query the record to be updated
            SObject record = Database.query('SELECT Id, RecordTypeId FROM ' + sObjectType + ' WHERE Id = :recordId');
            
            system.debug('record==>'+record);
            //Update the RecordTypeId field with the new record type
            record.put('RecordTypeId', recordType.Id);
            
            // Update the record in the database
            update record;
        } else {
            // Handle case where record type is not found
            // throw new CustomException('Record Type not found: ' + recordTypeName);
        }
    }
    
    //LAF Signing validation
    public static void signedDocumentReTriggerValidation(String loanId) {
        // Query only required fields and limit results if needed (based on governor limits)
        List<Document__c> docLstToUpdate = new List<Document__c>();
        for (Document__c doc : [
            SELECT Id, Name, Document_Sub_Type__c 
            FROM Document__c 
            WHERE Loan_Application__c = :loanId 
            AND Document_Type__c = 'LAF Form'
        ]) {
            if ('LAF Form - signed'.equals(doc.Document_Sub_Type__c)) {
                doc.Status__c = 'Not Uploaded';
                docLstToUpdate.add(doc);
            }
        }
        
        // Update only if there are records to update
        if (!docLstToUpdate.isEmpty()) {
            try {
                update docLstToUpdate;
            } catch (DmlException e) {
                // Handle the DML exception (logging, rethrowing, etc.)
                System.debug('DML Exception occurred: ' + e.getMessage());
                throw e; // Rethrow or handle according to your requirements
            }
        }
    }
    
    
}