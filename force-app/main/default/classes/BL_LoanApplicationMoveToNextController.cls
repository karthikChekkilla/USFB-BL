/**
* @File Name          : BL_LoanApplicationMoveToNextController.cls
* @Description        : This class use to move loan application stages for BL specific changes.
* @Author             : Mohit Saxena
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         09-08-2024            Mohit                  Initial version
**/
public class BL_LoanApplicationMoveToNextController {
    //Added By Mohit on 03-07-2024 for BL - <Assign to CPA directly in case of BL>
    public static String transferToCPAQueue(List<Loan_Application__c> applicationList){
        List<Group> queuleist = new UB_QueuesSelector().selectQueueDeveloperName('BL_CPA_Queue');
        return queuleist[0].Id;
    }
    
    //Added By Mohit on 31-07-2024 for BL - <Assign to CM Queue directly in case of BL>
    public static String transferToBCMQueue(List<Loan_Application__c> applicationList){
        List<Group> queuleist = new UB_QueuesSelector().selectQueueDeveloperName('BL_Credit_Manager_Queue');
        return queuleist[0].Id;
    }
    
    //Added By Mohit on 30-07-24 for BL - <Bug: USFBL-174 (Show mandatory fields validation for applicants)>
    public static String mandatoryfieldsValidation(List<Loan_Applicant__c> loanApplicantList, Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg = '';
        Set<String> applicantNames = new Set<String>();
        
        if(!loanApplicantList.isEmpty() && loanApplicantList.size() > 0){
            for(Loan_Applicant__c obj : loanApplicantList){
                if(String.isBlank(obj.Email__c)){
                    applicantNames.add(obj.Name);
                }
            }
            for(String str : applicantNames){
                validationMsg  += '<li>'+messageConfigMap.get('Applicant_Mandatory_Fields').Message__c+' '+'<b>'+str+'</b>'+'</li>';
            }
        }
        return validationMsg;
    }
    
    //Added By Mohit on 29-08-24 for BL - <Bug: USFBL-351 (Balance Transfer Validation)>
    public static String checkBalanceTransferValidation(Loan_Application__c loanApplication, Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg = '';
        if(String.isNotBlank(loanApplication.Products__r[0].BL_Balance_Transfer_Applicable__c)){
            if(loanApplication.Products__r[0].BL_Balance_Transfer_Applicable__c == UB_ConstantsUtil.YES){
                List<Balance_Transfer__c> balanceTransferList = new BL_BalanceTransfersSelector().selectByLoanApplicationId(new Set<Id>{loanApplication.Id});
                if(balanceTransferList.isEmpty() || balanceTransferList.size() == 0){
                    validationMsg += '<li>'+messageConfigMap.get('BalanceTransferRequired').Message__c+'</li>';
                }
            }
        }
        return validationMsg;
    }
    
    //Added By Mohit on 19-09-2024 for BL - <Validation when identity/address proof is Aadhaar for the applicants>
    public static String aadhaarProofValidation(List<Loan_Applicant__c> loanApplicantList, Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg = '';
        Set<String> applicantNames = new Set<String>();
        for(Loan_Applicant__c obj : loanApplicantList){
            if(String.isNotBlank(obj.Proof_of_Address__c)){
                if(obj.Proof_of_Address__c == BL_ConstantsUtil.AADHAAR_IDENTITY_PROOF && obj.Aadhaar_Verification__c == null){
					applicantNames.add(obj.Account_Name__c);
                }
            }
            if(String.isNotBlank(obj.BL_Proof_of_Identity__c)){
                if(obj.BL_Proof_of_Identity__c == BL_ConstantsUtil.AADHAAR_IDENTITY_PROOF && obj.Aadhaar_Verification__c == null){
                    applicantNames.add(obj.Account_Name__c);                
                }
            }
        }
        if(applicantNames.size() > 0){
            for(String str : applicantNames){
                validationMsg += '<li>'+messageConfigMap.get('AadhaarProofValidation').Message__c+' '+'<b>'+str+'</b>'+'</li>';
            }
        }
        return validationMsg;
    }
    
    public static String checkAddressForApplicantsForBL(List<Loan_Applicant__c>  loanApplicantList) {
        Map<String, Integer > applicantsAddressMap = new  Map<String, Integer >();
        Integer individualAddressCount = 0;
        Integer nonIndividualAddressCount = 0;
        Integer permanentAddressSameAsResi = 0;
        String validationMsg = '';
        String residenceAddressCompare = '';
        Set<String> applicantNames = new Set<String>();
        Set<String> applicantNamesNI = new Set<String>();
        
        for(Loan_Applicant__c  applicant : loanApplicantList) {
            applicantsAddressMap.put(applicant.Id, NULL);
        }
        for(Loan_Applicant__c  applicant : [SELECT Id, RecordType.Name, BL_Income_Considered__c, Account_Name__c FROM Loan_Applicant__c WHERE Id IN:applicantsAddressMap.keySet() AND Is_Deleted__c = 'No' ]) {
            
            applicantsAddressMap.put(applicant.RecordType.Name, 0);
            if(applicant.RecordType.Name == 'BL Individual' && applicant.BL_Income_Considered__c == 'Yes') {
                applicantsAddressMap.put('BL Non Individual', 0);
                applicantNames.add(applicant.Account_Name__c);
                individualAddressCount += 1;
            }
            if(applicant.RecordType.Name == 'BL Individual' && applicant.BL_Income_Considered__c != 'Yes') {
                applicantNames.add(applicant.Account_Name__c);
                individualAddressCount += 1;
            }else {
                nonIndividualAddressCount += 1;
                applicantNamesNI.add(applicant.Account_Name__c);
            }
        }
        
        if(!applicantsAddressMap.keySet().IsEmpty()) {
            for(Address__c address : [SELECT Id,Aadhar_Address__c,Compare_Address_with_Aadhar__c,BL_PermanentAddressSameAsResidence__c, 
                                      Loan_Applicant__c, Loan_Applicant__r.RecordType.Name,Loan_Applicant__r.BL_Income_Considered__c,
                                      Address_Type__c,Loan_Applicant__r.Account_Name__c
                                      FROM Address__c WHERE 
                                      Loan_Applicant__c IN : applicantsAddressMap.keySet() 
                                      AND Loan_Applicant__c != NULL]) {
                                          if(address.Address_Type__c == 'Residence Address' && address.Aadhar_Address__c != NULL && !address.Compare_Address_with_Aadhar__c) {
                                              residenceAddressCompare += address.Loan_Applicant__r.Account_Name__c + ', ';
                                              applicantNames.add(address.Loan_Applicant__r.Account_Name__c);
                                          }
                                          
                                          if(address.Loan_Applicant__r.RecordType.Name == 'BL Individual' && (address.Address_Type__c == 'Permanent Address' || address.Address_Type__c == 'Residence Address')) {
                                              if(applicantNames.contains(address.Loan_Applicant__r.Account_Name__c)){
                                                  applicantNames.remove(address.Loan_Applicant__r.Account_Name__c);
                                              }
                                              //applicantNames.add(address.Loan_Applicant__r.Account_Name__c);
                                              if(address.BL_PermanentAddressSameAsResidence__c == 'Yes'){
                                                  permanentAddressSameAsResi += 1;
                                              }
                                              if(applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) != 0) {
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name, applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) +1);
                                              } else { 
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name,1);
                                              }                
                                              
                                          } else if(address.Loan_Applicant__r.RecordType.Name == 'BL Non Individual' && address.Address_Type__c == 'Office Address') {
                                              if(applicantNames.contains(address.Loan_Applicant__r.Account_Name__c)){
                                                  applicantNames.remove(address.Loan_Applicant__r.Account_Name__c);
                                              }
                                              if(applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) != 0) {
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name, applicantsAddressMap.get(address.Loan_Applicant__r.RecordType.Name) +1);
                                              } else { 
                                                  applicantsAddressMap.put(address.Loan_Applicant__r.RecordType.Name,1);
                                              }
                                          }else if(address.Loan_Applicant__r.RecordType.Name == 'BL Individual' && address.Address_Type__c == 'Office Address' && address.Loan_Applicant__r.BL_Income_Considered__c == 'Yes') {
                                              if(applicantNames.contains(address.Loan_Applicant__r.Account_Name__c)){
                                                  applicantNames.remove(address.Loan_Applicant__r.Account_Name__c);
                                              }if(applicantNamesNI.contains(address.Loan_Applicant__r.Account_Name__c)){
                                                  applicantNamesNI.remove(address.Loan_Applicant__r.Account_Name__c);
                                              }
                                              if(applicantsAddressMap.get('BL Non Individual') != 0) {
                                                  applicantsAddressMap.put('BL Non Individual', applicantsAddressMap.get('BL Non Individual') +1);
                                              } else { 
                                                  applicantsAddressMap.put('BL Non Individual',1);
                                              }
                                              //applicantNamesNI.remove(address.Loan_Applicant__r.Account_Name__c);
                                              //applicantNames.remove(address.Loan_Applicant__r.Account_Name__c);
                                          }
                                          
                                      }
            String appName = String.valueOf(applicantNames).replace('{','').replace('}','');
            String appNameNI = String.valueOf(applicantNamesNI).replace('{','').replace('}','');
            system.debug('appName>>> '+appName);
            system.debug('applicantNames>>> '+applicantNames);
            
            system.debug('applicantsAddressMap-> ' + applicantsAddressMap);
            system.debug('permanentAddressSameAsResi-> ' + permanentAddressSameAsResi); 
            system.debug('individualAddressCount-> ' + individualAddressCount); 
            system.debug('nonIndividualAddressCount-> ' + nonIndividualAddressCount); 
            if(permanentAddressSameAsResi == 0){
                if(String.isNotBlank(appName)){
                    if(applicantsAddressMap.get('BL Individual') != NULL &&  
                       (/* applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi ) ||  */
                           applicantsAddressMap.get('BL Individual') != (2 - individualAddressCount) ) ) {
                               validationMsg  += '<li>'+'Permanent Or Residence  Address is Mandatory for <b>'+appName+'</b>'+'</li>';
                           }
                }
            }else if(permanentAddressSameAsResi == 1){
                if(String.isNotBlank(appName)){
                    if(applicantsAddressMap.get('BL Individual') != NULL &&  
                       (/* applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi ) ||  */
                           applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi - individualAddressCount) ) ) {
                               validationMsg  += '<li>'+'Permanent Or Residence  Address is Mandatory for <b>'+appName+'</b>'+'</li>';
                           }
                }
            }else if(permanentAddressSameAsResi == 2){
                if(String.isNotBlank(appName)){
                    if(applicantsAddressMap.get('BL Individual') != NULL &&  
                       (/* applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi ) ||  */
                           applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi - individualAddressCount) ) ) {
                               validationMsg  += '<li>'+'Permanent Or Residence  Address is Mandatory for <b>'+appName+'</b>'+'</li>';
                           }
                }
            }else if(permanentAddressSameAsResi == 3){
                if(String.isNotBlank(appName)){
                    if(applicantsAddressMap.get('BL Individual') != NULL &&  
                       (/* applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi ) ||  */
                           applicantsAddressMap.get('BL Individual') != (2*permanentAddressSameAsResi - individualAddressCount) ) ) {
                               validationMsg  += '<li>'+'Permanent Or Residence  Address is Mandatory for <b>'+appName+'</b>'+'</li>';
                           }
                }
            }
            
            if(applicantsAddressMap.get('BL Non Individual') != NULL && applicantsAddressMap.get('BL Non Individual') != nonIndividualAddressCount) {
                validationMsg  += '<li>'+'Office Address is Mandatory for <b>'+appNameNI+'</b>'+'</li>';
            }if(residenceAddressCompare.length() > 0) {
                //validationMsg  += '<li>'+ ' Compare Residence address with Aadhar address for Applicant ' + residenceAddressCompare.replace(',',' ')+' <b> '+appName+' </b> '+'</li>';
            }
        }
        return validationMsg;
    }
    
    //Added By Umair for BL Underwriting FI Process on 22-08-24
    public static String FIProcessCheck(String loanAppId, List<Loan_Applicant__c> loanAppList){
        String validationMsg = '';        
        try{
            if(loanAppId != Null){
                UB_ProductsSelector productSelectObj = new UB_ProductsSelector();
                UB_ProductMastersSelector productMasterSelectObj  = new UB_ProductMastersSelector();
                UB_LoanApplicantsSelector applicantSelectObj = new UB_LoanApplicantsSelector();
                UB_ActivitySelector activitySelectObj = new UB_ActivitySelector();
                String applicantId;
                String coAapplicantId;
                String guaranterId;
                
                Boolean appOfficeFICheck = false;
                Boolean appResidenceFICheck = false;
                Boolean appPermanentFICheck = false;
                
                Boolean coAppOfficeFICheck = false;
                Boolean coAppResidenceFICheck = false;
                Boolean coAppPermanentFICheck = false;
                
                Boolean guarantorOfficeFICheck = false;
                Boolean guarantorResidenceFICheck = false;
                Boolean guarantorPermanentFICheck = false;
                
                //List<Loan_Applicant__c> loanAppList = applicantSelectObj.selectByIdWithLoanApplication(new Set<ID>{loanAppId});
                List<Product__c> productList = productSelectObj.selectByLoanApplicationIds(new Set<ID>{loanAppId});
                if(!productList.isEmpty()){
                    List<Product_Master__c>  productoMasterObj = productMasterSelectObj.selectById(new Set<Id> {productList[0].Product__c});    
                    
                    if(!loanAppList.isEmpty() && !productoMasterObj.isEmpty()){
                        for(Loan_Applicant__c applicantObj : loanAppList){
                            //Primary Applicant Check FI
                            if(applicantObj.Applicant_Type__c == 'Applicant' && applicantObj.Waive_FI__c == false){
                                if(productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c != Null){
                                    if(applicantObj.Constitution__c == 'Sole Proprietorship' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('Propertioship')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Individual' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('Individual')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Partnership' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('Partnership')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Private Ltd' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('Pvt Ltd')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Public Ltd' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('Public Ltd')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'LLP' && productoMasterObj[0].Primary_applicant_Office_FI_Mandatory__c.contains('LLP')){
                                        applicantId = applicantObj.Id;
                                        appOfficeFICheck = true;
                                    }
                                }
                                
                                if(productoMasterObj[0].Primary_applicant_Residence_FI_Mandatory__c != Null){
                                    if(applicantObj.Constitution__c == 'Sole Proprietorship' && productoMasterObj[0].Primary_applicant_Residence_FI_Mandatory__c.contains('Propertioship')){
                                        applicantId = applicantObj.Id;
                                        appResidenceFICheck = true;
                                    }
                                    else  if(applicantObj.Constitution__c == 'Individual' && productoMasterObj[0].Primary_applicant_Residence_FI_Mandatory__c!= Null && productoMasterObj[0].Primary_applicant_Residence_FI_Mandatory__c.contains('Individual')){
                                        applicantId = applicantObj.Id;
                                        appResidenceFICheck = true;
                                    }
                                }
                            }      
                            
                            //Co-Applicant Check FI
                            else if(applicantObj.Applicant_Type__c == 'Co-Applicant' && applicantObj.Waive_FI__c == false){
                                if(productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c != Null){
                                    if(applicantObj.Constitution__c == 'Sole Proprietorship' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('Propertioship') && applicantObj.BL_Income_Considered__c == 'Yes'){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Individual' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('Individual') && applicantObj.BL_Income_Considered__c == 'Yes'){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Partnership' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('Partnership')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Private Ltd' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('Pvt Ltd')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Public Ltd' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('Public Ltd')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'LLP' && productoMasterObj[0].CoApplicant_Applicant_Office_FI_Mandator__c.contains('LLP')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppOfficeFICheck = true;
                                    } 
                                }
                                if(productoMasterObj[0].CoApplicant_applicant_Residence_FI_Manda__c != Null){
                                    if(applicantObj.Constitution__c == 'Sole Proprietorship' && productoMasterObj[0].CoApplicant_applicant_Residence_FI_Manda__c.contains('Propertioship')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppResidenceFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Individual' && productoMasterObj[0].CoApplicant_applicant_Residence_FI_Manda__c.contains('Individual')){
                                        coAapplicantId = applicantObj.Id;
                                        coAppResidenceFICheck = true;
                                    } 
                                }
                                
                            }
                            
                            //Guarantor Check FI
                            else if(applicantObj.Applicant_Type__c == 'Guarantor' && applicantObj.Waive_FI__c == false){
                                if(productoMasterObj[0].Guarantor_applicant_Residence_FI_Mandato__c != Null){
                                    if(applicantObj.Constitution__c == 'Sole Proprietorship' && productoMasterObj[0].Guarantor_applicant_Residence_FI_Mandato__c.contains('Propertioship')){
                                        guaranterId = applicantObj.Id;
                                        guarantorResidenceFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Individual' && productoMasterObj[0].Guarantor_applicant_Residence_FI_Mandato__c.contains('Individual')){
                                        guaranterId = applicantObj.Id;
                                        guarantorResidenceFICheck = true;
                                    }  
                                }
                                if(productoMasterObj[0].Guarantor_applicant_Office_FI_Mandatory__c != Null){
                                    if(applicantObj.Constitution__c == 'Partnership' && productoMasterObj[0].Guarantor_applicant_Office_FI_Mandatory__c.contains('Partnership')){
                                        guaranterId = applicantObj.Id;
                                        guarantorOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Private Ltd' && productoMasterObj[0].Guarantor_applicant_Office_FI_Mandatory__c.contains('Pvt Ltd')){
                                        guaranterId = applicantObj.Id;
                                        guarantorOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'Public Ltd' && productoMasterObj[0].Guarantor_applicant_Office_FI_Mandatory__c.contains('Public Ltd')){
                                        guaranterId = applicantObj.Id;
                                        guarantorOfficeFICheck = true;
                                    }
                                    else if(applicantObj.Constitution__c == 'LLP' && productoMasterObj[0].Guarantor_applicant_Office_FI_Mandatory__c.contains('LLP')){
                                        guaranterId = applicantObj.Id;
                                        guarantorOfficeFICheck = true;
                                    } 
                                }
                                
                            }
                        }
                        
                        //Activity Check for Primary Applicant FI
                        if(applicantId != Null){
                            if(appPermanentFICheck == true){
                                List<Valuation__c> activityPermanentList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.PERMANENT_FI);
                                system.debug('activityPermanentList>>> '+activityPermanentList);
                                if(activityPermanentList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.PERMANENT_FI_APP_VALLIDATION+'</li>';
                                } 
                            }
                            
                            if(appResidenceFICheck == true){
                                List<Valuation__c> activityResidenceList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.RESIDENCE_FI);
                                system.debug('activityResidenceList>>> '+activityResidenceList);
                                if(activityResidenceList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.RESIDENCE_FI_APP_VALLIDATION+'</li>';
                                } 
                            }
                            
                            if(appOfficeFICheck == true){
                                List<Valuation__c> activityOfficeList = activitySelectObj.selectByApplicantId(applicantId, BL_ConstantsUtil.OFFICE_FI);
                                system.debug('activityOfficeList>>> '+activityOfficeList);
                                if(activityOfficeList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.OFFICE_FI_APP_VALLIDATION+'</li>';
                                }
                            }
                            
                        }  
                        //Activity Check for Co Applicant FI
                        if(coAapplicantId != Null){
                            if(coAppPermanentFICheck == true){
                                List<Valuation__c> activityList = activitySelectObj.selectByApplicantId(coAapplicantId, BL_ConstantsUtil.PERMANENT_FI);
                                system.debug('activityList>>> '+activityList);
                                if(activityList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.PERMANENT_FI_CO_APP_VALLIDATION+'</li>';
                                } 
                            }
                            
                            if(coAppResidenceFICheck == true){
                                List<Valuation__c> activityResidenceList = activitySelectObj.selectByApplicantId(coAapplicantId,BL_ConstantsUtil.RESIDENCE_FI);
                                system.debug('activityResidenceList>>> '+activityResidenceList);
                                if(activityResidenceList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.RESIDENCE_FI_CO_APP_VALLIDATION+'</li>';
                                }
                            }
                            
                            if(coAppOfficeFICheck == true){
                                List<Valuation__c> activityOfficeList = activitySelectObj.selectByApplicantId(coAapplicantId, BL_ConstantsUtil.OFFICE_FI);
                                system.debug('activityOfficeList>>> '+activityOfficeList);
                                if(activityOfficeList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.OFFICE_FI_CO_APP_VALLIDATION+'</li>';
                                }
                            }
                            
                        } 
                        //Activity Check for Guarantor FI
                        if(guaranterId != Null){
                            if(guarantorPermanentFICheck == true){
                                List<Valuation__c> activityList = activitySelectObj.selectByApplicantId(guaranterId, BL_ConstantsUtil.PERMANENT_FI);
                                system.debug('activityList>>> '+activityList);
                                if(activityList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.PERMANENT_FI_GUARANT_VALLIDATION+'</li>';
                                }
                            }
                            
                            if(guarantorResidenceFICheck == true){
                                List<Valuation__c> activityResidenceList = activitySelectObj.selectByApplicantId(guaranterId, BL_ConstantsUtil.RESIDENCE_FI);
                                system.debug('activityResidenceList>>> '+activityResidenceList);
                                if(activityResidenceList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.RESIDENCE_FI_GUARANT_VALLIDATION+'</li>';
                                } 
                            }
                            
                            if(guarantorOfficeFICheck == true){
                                List<Valuation__c> activityOfficeList = activitySelectObj.selectByApplicantId(guaranterId, BL_ConstantsUtil.OFFICE_FI);
                                system.debug('activityOfficeList>>> '+activityOfficeList);
                                if(activityOfficeList.isEmpty()){
                                    validationMsg += '<li>'+BL_ConstantsUtil.OFFICE_FI_GUARANT_VALLIDATION+'</li>';
                                }
                            }
                            
                        } 
                    }
                }
            }
        }catch(Exception ex){
            system.debug('Exception Line number: '+ex.getLineNumber());
            system.debug('Exception Message: '+ex.getMessage());
        }
        return validationMsg;
    }
    
    
    //Added By Umair for BL on 30-08-24
    public static String isCommunicationCheck(String loanAppId, List<Loan_Applicant__c> loanAppList){
        
        UB_LoanApplicantsSelector applicantSelectObj = new UB_LoanApplicantsSelector();
        UB_AddressesSelector addressSelectObj = new UB_AddressesSelector();
        String validationMsg = '';
        Map<Id,List<Address__c>> appAddMap = new  Map<Id,List<Address__c>>();
        List<Address__c> addressList = new List<Address__c>();
        Set<Id> applicantIdSet = new Set<Id>();
        
        try{
            
            for(Loan_Applicant__c appObj :  loanAppList){
                applicantIdSet.add(appObj.Id);
            }
            if(applicantIdSet != Null){
                addressList = addressSelectObj.getApplicantAddress(applicantIdSet);
            }
            
            for(Loan_Applicant__c appObj :  loanAppList){
                appAddMap.put(appObj.Id, null);
            }
            
            for(Address__c addObj : addressList){
                if(appAddMap.containsKey(addObj.Loan_Applicant__c)){
                    appAddMap.put(addObj.Loan_Applicant__c,new List<Address__c>{addObj});
                }
            }
            for(Loan_Applicant__c appObj :  loanAppList){
                if(appAddMap.get(appObj.Id) == null){
                    validationMsg += '<li>'+appObj.Name+BL_ConstantsUtil.IS_COMM_YES+'</li>';
                }
            }
            
            
            system.debug('appAddMap>> '+appAddMap);   
            system.debug('validationMsg addd>> '+validationMsg);
            
        }catch(Exception ex){
            system.debug('Exception Line number: '+ex.getLineNumber());
            system.debug('Exception Message: '+ex.getMessage());
        }
        return validationMsg;
        
    }
    
    //Added by Lakshya verma for applicants check on 09-sept-2024
    public static String secondaryApplicantCheck(List<Loan_Applicant__c>  loanAppList ,Map<String,Messages_Config__mdt> messageConfigMap,String loanApplicationStage){
        String validationMsg ='';
        Boolean isSecondaryApplicant =  false;
        Boolean isPrimaryApplicant = false;
        Boolean isGuarantorApp = false;
        Boolean isGuarantorAppExist = false;
        Boolean isNonIndividualApp = false;
        Boolean isCoApplicantExist = false;
        system.debug('loanAppList>>>>111 ' + loanAppList);
        try{
            for(Loan_Applicant__c applicant : loanAppList){
                system.debug('applicant-> ' + BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE );
                
                system.debug('if isPrimaryApplicant>>' + applicant.Loan_Application__r.LOB__c +' ' +applicant.Applicant_Type__c +' ' +applicant.RecordTypeId );
                if(applicant.Loan_Application__r.LOB__c == 'BL' && applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.RecordTypeId == BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE){
                    isNonIndividualApp = true;
                    isGuarantorApp = true;
                    isPrimaryApplicant = true;            
                    system.debug('hello 2' + applicant.Loan_Application__r.LOB__c +' ' +applicant.Applicant_Type__c +' ' +applicant.RecordTypeId );
                }if(applicant.Loan_Application__r.LOB__c == 'BL' && applicant.Applicant_Type__c == UB_ConstantsUtil.APPLICANT && applicant.RecordTypeId != BL_ConstantsUtil.BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE){
                    isPrimaryApplicant = true; 
                    isNonIndividualApp = false;
                    isGuarantorApp = false;
                    system.debug('hello 3');
                }if(applicant.Applicant_Type__c == UB_ConstantsUtil.GUATANTOR && applicant.Loan_Application__r.LOB__c == 'BL'){
                    isGuarantorAppExist = true;
                    isGuarantorApp = false;
                    system.debug('hello 5');
                }if( applicant.Applicant_Type__c == UB_ConstantsUtil.CO_APPLICANT && applicant.Loan_Application__r.LOB__c == 'BL'){
                    System.debug('** applicant.Applicant_Type__c  '+applicant.Applicant_Type__c);
                    system.debug('hello 6');
                    isCoApplicantExist = true;
                }
                /* if(loanApplicationStage == UB_ConstantsUtil.DDE && applicant.Applicant_Type__c !=UB_ConstantsUtil.APPLICANT){
isSecondaryApplicant = false;
}*/
            }
            System.debug('** applicant  '+isPrimaryApplicant +  isNonIndividualApp + isGuarantorApp + isSecondaryApplicant);
            if(loanApplicationStage == UB_ConstantsUtil.KYC_VALIDATION || loanApplicationStage == UB_ConstantsUtil.DDE /*&& isPrimaryApplicant == true && isNonIndividualApp == true && isGuarantorApp == false*/){
                if(isPrimaryApplicant == true && isNonIndividualApp == true){
                    if( isGuarantorAppExist == false){
                        validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant_DDE').Message__c+'</li>';
                        system.debug('if condition 1');
                    } 
                }else if(isNonIndividualApp == false && isSecondaryApplicant == false){
                   if(isCoApplicantExist == false){
                        system.debug('else if else condition');
                        validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant').Message__c+'</li>';
                    }
                }
            }
            /*if(loanApplicationStage == UB_ConstantsUtil.DDE && isNonIndividualApp == false && isSecondaryApplicant == false){
if(loanApplicationStage == UB_ConstantsUtil.DDE && isGuarantorApp == true){
validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant_DDE').Message__c+'</li>';
}else{
validationMsg += '<li>'+messageConfigMap.get('Secondary_Applicant').Message__c+'</li>';
}
} */
        }catch(Exception ex){
            System.debug('ex-> '+ ex.getLineNumber());
            System.debug('ex-> '+ ex);
        }
        
        system.debug('validationMsg-> ' + validationMsg);
        return validationMsg;
        
    }
}