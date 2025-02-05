/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-05-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class UB_DynamicRelatedListCtrl {
    @AuraEnabled
    public static GenericDataTableController.DataTableResponse returnRelatedRecords(String applicationId, String metadataName, String query, String queryParameters){
        System.debug('applicationId=  '+applicationId);
        System.debug('queryParameters  '+queryParameters);
        GenericDataTableController genericDTObj = new GenericDataTableController();
        genericDTObj.METADATA_NAME = metadataName; 
        genericDTObj.IDS_SET = new Set<String>(); 
        //Added by Mohit on 21-06-2024 - Hide Actions if the IsReadOnly check box is true on Loan Application
        List<Loan_Application__c> loanApplicationList = new UB_LoanApplicationsSelector().selectByIds(new Set<Id>{applicationId});
        if(!loanApplicationList.isEmpty() && loanApplicationList.size() > 0){
            genericDTObj.IS_READ_ONLY = loanApplicationList[0].IsReadOnly__c ? true : false;
        }else{
            genericDTObj.IS_READ_ONLY = false;
        }
        
        if(String.isNotBlank(queryParameters)){ 
            genericDTObj.IDS_SET.addAll(queryParameters.split(';'));
        }
        genericDTObj.IDS_SET.add(applicationId);
        // genericDTObj.WHERE_CLAUSE = ' Application__c IN : IDS_SET';
        System.debug('IDS_SET is = '+genericDTObj.IDS_SET);
        System.debug('Query is = '+query);
        genericDTObj.WHERE_CLAUSE = query;
        System.debug('genericDTObj  '+genericDTObj);
        System.debug('genericDTObj.getTable()-> ' + genericDTObj.getTable());
        return genericDTObj.getTable();     
    }

    @AuraEnabled
    public static List<sObject> getFilterRecords(String sObjectName, Id recordId, String filterConditions) {
        return Database.query('Select Id From '+sObjectName+' Where Id =:recordId AND '+filterConditions);
    }

    /*@AuraEnabled
    Public static Opportunity getOppRecord(String recordId) {
        System.debug('Current User Id - '+UserInfo.getUserId());
    
        List<Opportunity> oppRecord = [Select IsReadOnly__c, StageName, RecordType.Name, Previous_Sales_Owner__c From opportunity where id = : recordId LIMIT 1];
        System.debug(recordId);
        return [SELECT Id, StageName,  RecordType.Name, Previous_Sales_Owner__c,IsReadOnly__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
    }*/


    /**
    * @description  method wil return map having pan verification for all applicants.
    * @author  Zafaruddin | 04-05-2024 
    * @param loanId 
    * @return Map<Object, Boolean> 
    **/
    @AuraEnabled
    Public static Map<Object,Boolean> checkPanAndAadharVerify(String loanId) {
        Map<Object,Boolean> loanApplicantMap = new Map<Object,Boolean>();
        if(String.isNotBlank(loanId)) {
            for(Loan_Applicant__c applicantRecord : [SELECT Id, PAN_Verification__c, Aadhaar_Verification__c FROM  Loan_Applicant__c WHERE Loan_Application__c = :loanId]) {
                if(applicantRecord.PAN_Verification__c == NULL /*|| applicantRecord.Aadhaar_Verification__c == NULL */) {
                    loanApplicantMap.put(applicantRecord.Id,false);
                } else {
                    loanApplicantMap.put(applicantRecord.Id,True);
                }
            }
        }
        return loanApplicantMap;

    }

}