/**
 * @description       : 
 * @author            : Umair Ahmad
 * @group             : 
 * @last modified on  : 26-08-2024
 * @last modified by  : Umair Ahmad
**/

public with sharing class BL_DynamicRelatedListCtrl {


    /**
  * @description  method wil return flag if address exist for particular applicant or not.
  * @author  Umair | 26-08-2024 
  * @param loanId 
  * @return Boolean 
  **/
  @AuraEnabled
Public static Boolean getAddressRecord(String applicantId, String callingApi){
  Boolean addressExist = false;
  UB_AddressesSelector addressSelectObj = new UB_AddressesSelector();
  String addressType;
  system.debug('applicantId>> '+applicantId);
  system.debug('callingApi>> '+callingApi);

  try{
      if(applicantId != Null && callingApi != Null){

          if(callingApi == 'Permanent FI'){
              addressType = 'Permanent Address';
          }else if(callingApi == 'Residence FI'){
              addressType = 'Residence Address';
          }else if(callingApi == 'Office FI'){
              addressType = 'Office Address';
          }
          system.debug('addressType>> '+addressType);

          if(addressType != Null){
              List<Address__c> addressList =  addressSelectObj.getApplicantAddressByType(new Set<ID>{applicantId}, addressType);
              system.debug('addressList>> '+addressList);

              if(addressType == 'Residence Address' && addressList.isEmpty()){
                  List<Address__c> permanentAddressList =  addressSelectObj.getApplicantAddressByType(new Set<ID>{applicantId}, 'Permanent Address');
                  if(!permanentAddressList.isEmpty()){
                      if(permanentAddressList[0].BL_PermanentAddressSameAsResidence__c == 'Yes'){
                          addressExist = true;
                      }
                  }
              }

            if(!addressList.isEmpty()){
              addressExist = true;
            }
          }

      }
      system.debug('addressExist>> '+addressExist);
  }catch(Exception ex){
      system.debug('Exception Line number: '+ex.getLineNumber());
      system.debug('Exception Message: '+ex.getMessage());
  }
  return addressExist;

}

   /**
  * @description  method wil return flag if address exist for particular applicant or not.
  * @author  Umair | 26-08-2024 
  * @param loanId 
  * @return Boolean 
  **/
  @AuraEnabled
Public static Boolean permanentAddressSameCheck(String applicantId){
  Boolean addressSame = false;
  UB_AddressesSelector addressSelectObj = new UB_AddressesSelector();
  try{

       if(applicantId != Null){
          List<Address__c> addressList =  addressSelectObj.getAllAddressOfApplicant(new Set<ID>{applicantId});
          System.debug('addressList>>> '+addressList);

          if(!addressList.isEmpty()){
              for(Address__c addObj : addressList){
                  if(addObj.BL_PermanentAddressSameAsResidence__c == 'Yes'){
                      addressSame = true;
                  }
              }
             
          }
      }
      System.debug('addressSame>>> '+addressSame);
  }catch(Exception ex){
              system.debug('Exception Line number: '+ex.getLineNumber());
              system.debug('Exception Message: '+ex.getMessage());
          }
          return addressSame;

}

  /**
  * @description  method wil return flag if activity exist for particular applicant or not.
  * @author  Umair | 23-08-2024 
  * @param loanId 
  * @return Boolean 
  **/
  @AuraEnabled
Public static Boolean getAcitivityRecord(String applicantId, String callingApi){
  Boolean actiivityExist = false;
  UB_UsersSelector userSelectObj = new UB_UsersSelector();
  try{
      List<User> userList = userSelectObj.selectAdminUser(new Set<Id>{UserInfo.getUserId()});
      if(!userList.isEmpty() && userList[0].Profile.Name != 'System Administrator'){
      if(applicantId != Null){
        UB_ActivitySelector activitySelectObj = new UB_ActivitySelector();

          if(callingApi == 'Permanent FI'){
          List<Valuation__c> activityPermanentList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.PERMANENT_FI);
          system.debug('activityPermanentList>>> '+activityPermanentList);
          if(!activityPermanentList.isEmpty()){
              actiivityExist = true;
          }
          }
          else  if(callingApi == 'Residence FI'){
          List<Valuation__c> activityPermanentList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.RESIDENCE_FI);
          if(!activityPermanentList.isEmpty()){
              actiivityExist = true;
          }
          system.debug('activityPermanentList>>> '+activityPermanentList);
          }
          else  if(callingApi == 'Office FI'){
          List<Valuation__c> activityPermanentList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.OFFICE_FI);
          if(!activityPermanentList.isEmpty()){
              actiivityExist = true;
          }
          system.debug('activityPermanentList>>> '+activityPermanentList);
          }
      }
  }
  }catch(Exception ex){
          system.debug('Exception Line number: '+ex.getLineNumber());
          system.debug('Exception Message: '+ex.getMessage());
      }
      return actiivityExist;
  }

}