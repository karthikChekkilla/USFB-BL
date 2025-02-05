/**
* @File Name          : UB_UpdateEnachService.cls
* @Description        : Api to update Verification in the system.
* @Author             : Mohd Musab
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 2.0         03-07-2024             Mohd Musab         
*/

@RestResource(urlMapping='/ENachService/*')
global class UB_UpdateEnachService {

@HttpPost
global static void updateENach() {
    List<Verification__c> recordToUpdate = new List<Verification__c>();
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    String responseMessage;
    Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ENachWebService');
    try {
    String requestBody = req.requestBody.toString();
    Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

    // Extracting the params from the request body
    String umrn = (String) params.get('umrn');
    String referenceNumber = (String) params.get('referenceNumber');
    String status = (String) params.get('status');
    if(umrn == NULL || umrn == '') {
        RestContext.response.statusCode = 404;
        RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "Message": "' +messageConfigMap.get('UMRN_ENachWebService').Message__c + '"}');
        return ;
    }
    if(status == NULL || status == '') {
        RestContext.response.statusCode = 404;
        RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "Message": "' +messageConfigMap.get('Status_ENachWebService').Message__c + '"}');
        return ;
    }
    if(referenceNumber == NULL || referenceNumber == '') {
        RestContext.response.statusCode = 404;
        RestContext.response.responseBody = Blob.valueOf('{ "status":"fail", "Message": "' +messageConfigMap.get('ReferenceNumber_ENachWebService').Message__c + '"}');
        return ;
    }
    // Default response message
    responseMessage = 'Record not found or update failed';

    List<Verification__c> verificationRecordList = [SELECT Id, UMRN__c, E_Nach_Status__c FROM Verification__c WHERE E_Nach_Reference__c = :referenceNumber AND E_Nach_Reference__c != '' Order by createdDate desc LIMIT 1];

        // Updating the UMRN and Status field of E-Nach Verification Record
        if (verificationRecordList.size()>0) {
        Verification__c verificationRecord = new Verification__c();
        verificationRecord.Id = verificationRecordList[0].Id;
        verificationRecord.UMRN__c = umrn;
        verificationRecord.E_Nach_Status__c = status;
        recordToUpdate.add(verificationRecord);
        UB_VerificationUtility.updateRecords(recordToUpdate);
        responseMessage = 'E-Nach updated successfully';
        RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "Message": "E-Nach updated successfully"}');
        } else {
            res.statusCode = 404;
            RestContext.response.responseBody = Blob.valueOf('{ "status":"success", "Message": "Record not found or update failed"}');
            //return responseMessage;
        }
}
catch (DmlException e) {
    res.statusCode = 500;
    RestContext.response.responseBody = Blob.valueOf('{ "status":"failure", "Message": "' +e.getMessage() + '"}');
    //return 'Error updating E-Nach record: ' + e.getMessage();
}
    // Set response status code and message
    res.statusCode = 200;
    //return responseMessage;
}
}