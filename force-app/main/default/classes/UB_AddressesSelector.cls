/**
* @File Name          : UB_AddressesSelector.cls
* @Description        : This class used to fetch/query Address records based on conditions.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         26-03-2024               Mohit                 Initial Version
*/
public class UB_AddressesSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Address__c.Id,
                Address__c.City__c,
                Address__c.State__c,
                Address__c.Pincode__c,
                Address__c.CreatedDate,
                Address__c.Loan_Applicant__c,
                Address__c.Is_Communication__c,
                Address__c.Name,
                Address__c.Address_Line_2__c,
                Address__c.Address_Line_3__c,
                Address__c.Country__c,
                Address__c.District__c,
                Address__c.BL_PermanentAddressSameAsResidence__c,
                Address__c.Address_Type__c,
                Address__c.ICICI_State_Code__c

                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Address__c.sObjectType;
    }
    
    public List<Address__c> selectById(Set<Id> recordIds){
        return (List<Address__c>) selectSObjectsById(recordIds);
    }
    //Added By Deepak Joshi 10/04/2024
    public List<Address__c> selectByLeasId(Set<Id> leadIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Lead__c IN : leadIds');
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    //added by Mansur Alam
    public List<Address__c> getApplicantAddress(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Pincode__c');
        query.selectField('Pincode__r.Name');
        String var = UB_ConstantsUtil.YES;
        query.setCondition('Loan_Applicant__c IN : applicantId AND Is_Communication__c = :var' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    
    /**
* @description 
* @author Zafaruddin | 07-19-2024 
* @param applicantId 
* @return List<Address__c> 
**/
    public List<Address__c> getApplicantResidenceAddress(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Pincode__c');
        query.selectField('Pincode__r.Name');
        String addressType = 'Residence Address';
        query.setCondition('Loan_Applicant__c IN : applicantId AND Address_Type__c= :addressType' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    /**
* @description 
* @author Zafaruddin | 07-19-2024 
* @param applicantId 
* @return List<Address__c> 
**/
    public List<Address__c> getApplicantPermanentAddress(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Pincode__c');
        query.selectField('Pincode__r.Name');
        String addressType = 'Permanent Address';
        
        query.setCondition('Loan_Applicant__c IN : applicantId AND Address_Type__c= :addressType' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    /**
* @description 
* @author Zafaruddin | 07-19-2024 
* @param applicantId 
* @return List<Address__c> 
**/
    public List<Address__c> getApplicantOfficeAddress(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Pincode__c');
        query.selectField('Pincode__r.Name');
        String addressType = 'Office Address';
        
        query.setCondition('Loan_Applicant__c IN : applicantId AND Address_Type__c= :addressType' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    /**
* @description 
* @author Umair | 08-21-2024 
* @param applicantId 
* @return List<Address__c> 
**/
    public List<Address__c> getAddressByParent(Set<Id> applicantORLeadId){
        fflib_QueryFactory query = newQueryFactory();
        String addressType = 'Office Address';
        query.selectField('BL_PermanentAddressSameAsResidence__c');
        query.setCondition('(Loan_Applicant__c IN : applicantORLeadId OR Lead__c IN: applicantORLeadId) AND Address_Type__c != :addressType');
        system.debug('query>>> '+query);
        system.debug('result>>> '+(List<Address__c>) Database.query(query.toSOQL()));
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    
    /**
* @description 
* @author Umair | 26-08-2024 
* @param applicantId 
* @return List<Address__c> 
**/
    public List<Address__c> getApplicantAddressByType(Set<Id> applicantId, String addressType){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Pincode__c');
        query.selectField('Pincode__r.Name');
        query.setCondition('Loan_Applicant__c IN : applicantId AND Address_Type__c= :addressType' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    /*public override String getOrderBy(){
return 'CreatedDate DESC';
}*/
    
    public List<Address__c> getAllAddressOfApplicant(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c IN : applicantId' );
        return (List<Address__c>) Database.query(query.toSOQL());
    }
}