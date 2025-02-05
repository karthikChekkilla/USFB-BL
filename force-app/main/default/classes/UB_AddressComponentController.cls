/**
*   Name        :   UB_AddressComponentController
*   @author     :   Lakshya Verma
*   @description:   It is used to Address Component.
*   @date       :   20 March 2024
*   Test Class  :   
*   Jira        :  
*/
public class UB_AddressComponentController {

    public static Id BL_LeMSLeadRecordType = BL_ConstantsUtil.BL_LEMS_LEAD_RECORDTYPE;
    public static Id BL_PartnerPortalLeadRecordType = BL_ConstantsUtil.BL_Partner_Portal_Lead_RecordType;

    @AuraEnabled
    public static Pincode__c getPinCodeDetails(String pinCodeId){
        try{
             if (Schema.sObjectType.Pincode__c.isAccessible() && Schema.sObjectType.Pincode__c.isQueryable()) {
            List<Pincode__c> pinCodeList = [ SELECT Id, Name, City__c, City__r.Name, City__r.District__c, 
                                            City__r.District__r.Name, City__r.District__r.State__c, City__r.District__r.State__r.Name
                                            , City__r.District__r.State__r.Country__c  
                                            FROM Pincode__c WHERE Id =: pinCodeId LIMIT 1  ];
            if(pinCodeList != null && pinCodeList.size() > 0){
                return pinCodeList[0];
            }
             }
        }catch(Exception e){
            //System.debug(LoggingLevel.ERROR, 'getPinCodeDetails=> ' + e.getMessage());
            throw newMessageException(e.getMessage());
        }
        return new Pincode__c();
    }

    /**
    * @author Lakshya
    * @date 10-Apr-2024
    * @description This method is created to get Count Of Communition Address.
    * @param objectName
    * @param recordId
    * @param addressId
    * @return String
    */
    @AuraEnabled
    public static Integer isCommunicationAddressExist(String objectName, String recordId, String addressId){
        String query = 'SELECT Count() FROM Address__c WHERE Is_Communication__c = \'Yes\' AND Id !=: addressId ';
        Integer count = 0;
        if(objectName == 'Lead__c'){
            count = Database.countQuery(query + ' AND Lead__c =: recordId');
        }else if(objectName == 'Loan_Applicant__c'){
            count = Database.countQuery(query + ' AND Loan_Applicant__c =: recordId');
        }
        return count;
    }

    @AuraEnabled
    public static Integer isPermanentAddressIsSameAsResidence(String objectName, String recordId, String addressId){
        String query = 'SELECT Count() FROM Address__c WHERE BL_PermanentAddressSameAsResidence__c = \'Yes\' AND Id !=: addressId ';
        Integer count = 0;
        if(objectName == 'Lead__c'){
            count = Database.countQuery(query + ' AND Lead__c =: recordId');
        }else if(objectName == 'Loan_Applicant__c'){
            count = Database.countQuery(query + ' AND Loan_Applicant__c =: recordId');
        }
        return count;
    }

    //Addedd  by umair 22-08-24
    @AuraEnabled
    public static String isAddressSameBL(String applicantORLeadId){
        UB_AddressesSelector addSelector = new UB_AddressesSelector();
        String sameAddressCheck;
        system.debug('applicantORLeadId>> '+applicantORLeadId);

        if(applicantORLeadId != Null){
            List<Address__c> addList = addSelector.getAddressByParent(new Set<Id>{applicantORLeadId});
            system.debug('addList>> '+addList);

            if(!addList.isEmpty()){
                sameAddressCheck = addList[0].BL_PermanentAddressSameAsResidence__c;                
            }else{
                sameAddressCheck = '';
            }
        }else{
            sameAddressCheck = '';
        }
        system.debug('sameAddressCheck>> '+sameAddressCheck);
        return sameAddressCheck;
    }

    @testVisible private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    /**
    * @author Manjeet
    * @date 03-July-2024
    * @description This method is created to get the lead RecordTypeId.
    * @param parentObjectId
    * @return Wrapper
    */
    @AuraEnabled
    public static boolean getParentRecordType(Id parentObjectId, String sObjectName) {
        try {
            // Query the parent object to get the RecordTypeId and RecordType.Name
            if(sObjectName  == 'Lead__c'){
                Lead__c parentRecord = [SELECT RecordTypeId, RecordType.Name FROM Lead__c WHERE Id = :parentObjectId LIMIT 1];
                if (parentRecord != null && (parentRecord.RecordTypeId == BL_LeMSLeadRecordType || parentRecord.RecordTypeId == BL_PartnerPortalLeadRecordType)) {
                    return true;
                }
            }else if(sObjectName  == 'Loan_Applicant__c'){
                Loan_Applicant__c parentRecord = [SELECT RecordTypeId, RecordType.Name FROM Loan_Applicant__c WHERE Id = :parentObjectId LIMIT 1];
                if (parentRecord != null && (parentRecord.RecordType.Name == 'BL Non Individual' || parentRecord.RecordType.Name == 'BL Individual')) {
                    return true;
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}