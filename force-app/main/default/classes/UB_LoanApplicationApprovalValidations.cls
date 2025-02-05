/**
* @File Name          : UB_LoanApplicationApprovalValidations.cls
* @Description        : Check and validate validation errors while approving Loan Application
* @Author             : Mohit
* @Test Class         : 
* @Dependencies       : UB_LoanApplicationMoveToNextController
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         09-06-2024               Mohit                 Initial Version
*/
public without sharing class UB_LoanApplicationApprovalValidations {
    public static String approvingAuthorityThreshold(User usrObj, Loan_Application__c loanAppObj, Map<String,Messages_Config__mdt> messageConfigMap){
        String validationMsg = '';
        Approval_Matrix__mdt customMetadata = Approval_Matrix__mdt.getInstance(usrObj.Userrole.DeveloperName);
        if(customMetadata != null){
            if(loanAppObj.Amount__c != null && loanAppObj.Amount__c > 0){
                if(customMetadata.Active__c){
                    if(customMetadata.Range_Min__c != null && customMetadata.Range_Min__c >= 0 && 
                       customMetadata.Range_Max__c != null && customMetadata.Range_Max__c > 0){
                           if(loanAppObj.Amount__c < customMetadata.Range_Min__c || loanAppObj.Amount__c > customMetadata.Range_Max__c){
                               validationMsg += '<li>'+messageConfigMap.get('No_Approval_Authorization').Message__c+'</li>';
                           } 
                           Approval_Matrix__mdt thresholdLimit = Approval_Matrix__mdt.getInstance('Committee');
                           if(thresholdLimit.Range_Min__c != null && thresholdLimit.Range_Min__c > 0){
                               if(loanAppObj.Amount__c >= thresholdLimit.Range_Min__c){
                                   String condition = 'Loan_Application__c = \''+loanAppObj.Id+'\' AND ';
                                   condition += ' Document_Type__c = \''+UB_ConstantsUtil.COMMITTEE_APPROVAL_NOTES_DOC_TYPE+'\' AND ';
                                   condition += ' Status__c != \''+UB_ConstantsUtil.UPLOADED+'\' ';
                                   List<Document__c> docList = new UB_DocumentsSelector().selectByConditions(condition);
                                   if(!docList.isEmpty() && docList.size() > 0){
                                       validationMsg += '<li>'+messageConfigMap.get('Upload_Committee_Approval_Notes_Doc').Message__c+'</li>';
                                   }
                               }
                           }else{
                               validationMsg += '<li>'+messageConfigMap.get('No_Approval_Authorization').Message__c+'</li>';
                           }
                       }else{
                           validationMsg += '<li>'+messageConfigMap.get('No_Range_Found').Message__c+'</li>';
                       }
                }else{
                    validationMsg += '<li>'+messageConfigMap.get('No_Approval_Authorization').Message__c+'</li>';
                }
            }else{
                validationMsg += '<li>'+messageConfigMap.get('No_Loan_Amount_Found').Message__c+'</li>';
            }
        }else{
            validationMsg += '<li>'+messageConfigMap.get('No_Approval_Authorization').Message__c+'</li>';
        }
        return validationMsg;
    } 
    
    public static String integrationsActivityValidity(String loanApplicationId, Map<String,Messages_Config__mdt> messageConfigMap){
        Map<String, Activities_Config__mdt> customMetadata = Activities_Config__mdt.getAll();        
        //List<Valuation__c> valuationList = new UB_ActivitySelector().selectByLoanApplicationId(new Set<Id>{loanApplicationId});
        //List<Verification__c> verifyList = new UB_VerificationsSelector().selectByIdLoanApplicationId(new Set<Id>{loanApplicationId});
        List<Valuation__c> valuationList = [SELECT Id, Vendor_Status__c, RecordType.DeveloperName, Loan_Applicant__c,
                                            LastModifiedDate, CreatedDate, Loan_Applicant__r.Account_Name__c, Vehicle__c,
                                            Vehicle__r.Name, Collateral__c, Collateral__r.Name, RecordType.Name
                                            FROM Valuation__c 
                                            WHERE Loan_Applicant__r.Loan_Application__c =: loanApplicationId OR
                                            Vehicle__r.Loan_Application__c =: loanApplicationId OR 
                                            Collateral__r.Loan_Application__c =: loanApplicationId
                                            ORDER BY CreatedDate DESC];
        List<Verification__c> verifyList = [SELECT Id, Status__c, RecordType.DeveloperName, Loan_Applicant__c,
                                            Loan_Applicant__r.Account_Name__c, Loan_Applicant__r.Proof_of_Address__c,
                                            LastModifiedDate, CreatedDate, RecordType.Name
                                            FROM Verification__c 
                                            WHERE Loan_Applicant__r.Loan_Application__c =: loanApplicationId
                                            ORDER BY CreatedDate DESC];
        Set<String> recTypeWithIdSet = new Set<String>();
        Map<String,Set<String>> mapStrWithSetValues = new Map<String,Set<String>>();
        String validationMsg = '';
        
        if(!valuationList.isEmpty() && valuationList.size() > 0 && customMetadata.keySet().size() > 0){
            for(Valuation__c obj : valuationList){
                if(customMetadata.containsKey(obj.RecordType.DeveloperName) && customMetadata.get(obj.RecordType.DeveloperName).Active__c){
                    if(obj.Vehicle__c != null && obj.RecordTypeId == UB_ConstantsUtil.VEHICLE_VALUATION_RECORD_TYPE){
                        String str = obj.RecordType.DeveloperName+'#'+obj.Vehicle__c;
                        if(!recTypeWithIdSet.contains(str)){
                            recTypeWithIdSet.add(str);
                            if(obj.Vendor_Status__c == UB_ConstantsUtil.COMPLETEDSTATUS){
                                Decimal expiryDays = customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c != null ? customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c : 0;
                                Date expiryDate = expiryDays > 0 ? System.today().addDays(-Integer.valueOf(expiryDays)) : System.today();
                                if(obj.CreatedDate < expiryDate){
                                    String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.COMPLETEDSTATUS;
                                    Set<String> vehicleNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                    vehicleNameSet.add(obj.Vehicle__r.Name);
                                    mapStrWithSetValues.put(mapKey, vehicleNameSet);
                                }
                            }else{
                                String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.PENDING_STATUS;
                                Set<String> vehicleNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                vehicleNameSet.add(obj.Vehicle__r.Name);
                                mapStrWithSetValues.put(mapKey, vehicleNameSet);
                            }
                        }
                    }else if(obj.Collateral__c != null && (obj.RecordTypeId == UB_ConstantsUtil.PROPERTY_VALUATION_RECORD_TYPE || obj.RecordTypeId == UB_ConstantsUtil.LEGAL_RECORD_TYPE)){
                        String str = obj.RecordType.DeveloperName+'#'+obj.Collateral__c;
                        if(!recTypeWithIdSet.contains(str)){
                            recTypeWithIdSet.add(str);
                            if(obj.Vendor_Status__c == UB_ConstantsUtil.COMPLETEDSTATUS){
                                Decimal expiryDays = customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c != null ? customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c : 0;
                                Date expiryDate = expiryDays > 0 ? System.today().addDays(-Integer.valueOf(expiryDays)) : System.today();
                                if(obj.CreatedDate < expiryDate){
                                    String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.COMPLETEDSTATUS;
                                    Set<String> collateralNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                    collateralNameSet.add(obj.Collateral__r.Name);
                                    mapStrWithSetValues.put(mapKey, collateralNameSet);
                                }
                            }else{
                                String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.PENDING_STATUS;
                                Set<String> collateralNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                collateralNameSet.add(obj.Collateral__r.Name);
                                mapStrWithSetValues.put(mapKey, collateralNameSet);
                            }
                        }
                    }else if(obj.Loan_Applicant__c != null && (obj.RecordTypeId == UB_ConstantsUtil.OFFICE_FI_RECORD_TYPE || obj.RecordTypeId == UB_ConstantsUtil.RESIDENCE_FI_VALUATION_RECORD_TYPE)){
                        String str = obj.RecordType.DeveloperName+'#'+obj.Loan_Applicant__c;
                        if(!recTypeWithIdSet.contains(str)){
                            recTypeWithIdSet.add(str);
                            if(obj.Vendor_Status__c == UB_ConstantsUtil.COMPLETEDSTATUS){
                                Decimal expiryDays = customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c != null ? customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c : 0;
                                Date expiryDate = expiryDays > 0 ? System.today().addDays(-Integer.valueOf(expiryDays)) : System.today();
                                if(obj.CreatedDate < expiryDate){
                                    String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.COMPLETEDSTATUS;
                                    Set<String> applicantNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                    applicantNameSet.add(obj.Loan_Applicant__r.Account_Name__c);
                                    mapStrWithSetValues.put(mapKey, applicantNameSet);
                                }
                            }else{
                                String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.PENDING_STATUS;
                                Set<String> applicantNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                applicantNameSet.add(obj.Loan_Applicant__r.Account_Name__c);
                                mapStrWithSetValues.put(mapKey, applicantNameSet);
                            }
                        }
                    }
                }
            }
        }
        
        if(!verifyList.isEmpty() && verifyList.size() > 0 && customMetadata.keySet().size() > 0){
            for(Verification__c obj : verifyList){
                if((String.isNotBlank(obj.Loan_Applicant__r.Proof_of_Address__c) &&
                    obj.Loan_Applicant__r.Proof_of_Address__c == UB_ConstantsUtil.AADHAAR_ADDRESS_PROOF &&
                    obj.RecordTypeId == UB_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE) || 
                   obj.RecordTypeId != UB_ConstantsUtil.AADHAR_VERIFICATION_RECORD_TYPE){
                       if(customMetadata.containsKey(obj.RecordType.DeveloperName) && customMetadata.get(obj.RecordType.DeveloperName).Active__c){
                           String str = obj.RecordType.DeveloperName+'#'+obj.Loan_Applicant__c;
                           if(!recTypeWithIdSet.contains(str)){
                               recTypeWithIdSet.add(str);
                               if(obj.Status__c == UB_ConstantsUtil.COMPLETEDSTATUS){
                                   Decimal expiryDays = customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c != null ? customMetadata.get(obj.RecordType.DeveloperName).Expiry_Days__c : 0;
                                   Date expiryDate = expiryDays > 0 ? System.today().addDays(-Integer.valueOf(expiryDays)) : System.today();
                                   if(obj.createdDate < expiryDate){
                                       String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.COMPLETEDSTATUS;
                                       Set<String> applicantNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                       applicantNameSet.add(obj.Loan_Applicant__r.Account_Name__c);
                                       mapStrWithSetValues.put(mapKey, applicantNameSet);
                                   }
                               }else{
                                   String mapKey = obj.RecordType.Name+'#'+UB_ConstantsUtil.PENDING_STATUS;
                                   Set<String> applicantNameSet = mapStrWithSetValues.containsKey(mapKey) ? mapStrWithSetValues.get(mapKey) : new Set<String>();
                                   applicantNameSet.add(obj.Loan_Applicant__r.Account_Name__c);
                                   mapStrWithSetValues.put(mapKey, applicantNameSet);
                               }
                           }
                       }
                   }
            }
        }
        if(mapStrWithSetValues.keySet().Size() > 0){
            for(String str : mapStrWithSetValues.keySet()){
                String values = String.valueOf(mapStrWithSetValues.get(str)).remove('{').remove('}');
                if(str.contains(UB_ConstantsUtil.COMPLETEDSTATUS)){
                    validationMsg += '<li>'+'The '+'<b>'+str.split('#')[0]+'</b>'+' '+messageConfigMap.get('Activity_Expired').Message__c+' for '+'<b>'+values+'</b>'+'.'+'</li>';
                }else{
                    validationMsg += '<li>'+'The '+'<b>'+str.split('#')[0]+'</b>'+' '+messageConfigMap.get('Activity_Pending').Message__c+' for '+'<b>'+values+'</b>'+'.'+'</li>';
                } 
            }
        }
        return validationMsg;
    }
}