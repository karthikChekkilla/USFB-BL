/**
* @File Name          : UB_DisbursementCltr.cls
* @Description        : This class use to move disbursment stages.
* @Author             : Lakshya
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         28-06-2024            Lakshya Verma          Initial Version
* 
**/
public class UB_DisbursementCltr {
    @AuraEnabled(cacheable = true)
    public static Disbursement__c getSelectedDisbursementRec(String loanAppId, String disburseId){
        try{
            if(String.isNotBlank(loanAppId) && String.isNotBlank(disburseId)){
                List<Disbursement__c> disbursementRec = [SELECT Id, Name, Vehicle__c, Loan_Amount__c, Loan_Application__c, 
                                                         Insurance_Amount__c, Processing_Fee__c, LAN__c, Stage__c, 
                                                         Status__c, ROI__c, Tenure__c 
                                                         FROM Disbursement__c 
                                                         WHERE Id =:disburseId AND Loan_Application__c =: loanAppId
                                                         LIMIT 1
                                                        ];
                RETURN disbursementRec[0];
            }
        }catch(Exception ex){
            system.debug('ex-> ' + ex.getMessage());
        }
        RETURN null;
        
    }
    
    @AuraEnabled
    public static ResponseWrapper  getPendingDibursements(String loanAppId){
        system.debug('loanAppId>>> '+ loanAppId);
        ResponseWrapper resWrap = new ResponseWrapper();
        Set<Id> disburseIds = new Set<Id>();
        set<String> loanOfferReviewSet = new set<String>();
        Set<String> disburseNames = new Set<String>();
        try{
            system.debug('inside try>>> '+ loanAppId);
            if(String.isNotBlank(loanAppId)){
                List<Disbursement__c> disburseList = new List<Disbursement__c>();
                //List<Disbursement__c> disburseApporvedList = new List<Disbursement__c>();
                for(Disbursement__c disburse : [SELECT Id, Name,  Status__c, Loan_Offer_Review_Status__c 
                                                FROM Disbursement__c 
                                                WHERE Loan_Application__c =: loanAppId AND 
                                                Loan_Offer_Review_Status__c !=null
                                               ]){
                                                   if(disburse.Status__c != UB_ConstantsUtil.DISBURSEMENT_DISBURSED /*&& disburse.Loan_Offer_Review_Status__c != UB_ConstantsUtil.DISBURSEMENT_REJECTED*/){
                                                       disburseList.add(disburse);
                                                       disburseNames.add(disburse.Name);
                                                       loanOfferReviewSet.add(disburse.Loan_Offer_Review_Status__c);
                                                   }
                                                   
                                               }
                                               system.debug('disburseList>>> '+ disburseList);
                                               system.debug('disburseNames>>> '+ disburseNames);
                if(!disburseList.isEmpty()){
                    resWrap.isSuccess = true;
                    resWrap.responseBody =  JSON.serialize(disburseNames);
                    resWrap.loanOfferStatus =  JSON.serialize(loanOfferReviewSet);
                }else{
                    resWrap.isSuccess = false;
                    resWrap.responseBody =  UB_ConstantsUtil.NO_DISBURSEMENTS;
                }
            }
            RETURN resWrap;
        }catch(Exception ex){
            system.debug('ex-> ' + ex.getMessage());
            resWrap.responseBody =  JSON.serialize(ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString() );
            resWrap.isSuccess = false;
            RETURN resWrap;
        }
    }
    
    @AuraEnabled
    public static ResponseWrapper sendSelectedDisRecToManager(String recordId, Disbursement__c disburseData, String loanAppId){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            if(disburseData != null && String.isNotBlank(recordId) && String.isNotBlank(loanAppId)){
                system.debug('disburseData-> ' + disburseData);
                Set<Id> setDisWithoutAppr = new Set<Id>();
                Set<Id> setDisWithAppr = new Set<Id>();
                boolean firstDisbursement = false;
                List<Disbursement__c> disbursementList = new List<Disbursement__c> ();
                List<Disbursement__c> disburseList = [SELECT Id, Name, Vehicle__c,Vehicle__r.Vehicle_Type__c, Loan_Amount__c, Loan_Application__c, 
                                                      Insurance_Amount__c, Processing_Fee__c, LAN__c, Stage__c, 
                                                      Status__c, ROI__c, Tenure__c,
                                                      Loan_Amount_Approval__c, Insurance_Amount_Approval__c, 
                                                      Processing_Fee_Approval__c, ROI_Approval__c, Tenure_Approval__c, CM__c
                                                      FROM Disbursement__c 
                                                      WHERE Id =: recordId LIMIT 1];
                for(Disbursement__c dis : [SELECT Id, Name, Vehicle__c, Loan_Amount__c, Loan_Application__c, Vehicle__r.Vehicle_Type__c, Loan_Offer_Review_Status__c
                                           FROM Disbursement__c 
                                           WHERE  Loan_Application__c =:  loanAppId]){
                                        System.debug('dis.Loan_Offer_Review_Status__c>> ' +dis.Loan_Offer_Review_Status__c);
                                               if(dis.Vehicle__r.Vehicle_Type__c == 'Chassis'  || dis.Vehicle__r.Vehicle_Type__c == 'Fully Built'){
                                                   firstDisbursement = true;
                                               }
                                               if(dis.Loan_Offer_Review_Status__c == null){
                                                   setDisWithoutAppr.add(dis.Id);
                                               }else{
                                                   setDisWithAppr.add(dis.Id);
                                               }
                                           }
                                           system.debug('setDisWithAppr > ' + setDisWithAppr  + 'setDisWithoutAppr>> ' + setDisWithoutAppr);
                if(setDisWithAppr.isEmpty()){
                    //if(!setDisWithoutAppr.isEmpty() && setDisWithoutAppr.contains(recordId)){
                    for(Disbursement__c disburse : disburseList){
                        if(firstDisbursement == true && (disburse.Vehicle__r.Vehicle_Type__c == 'Chassis'  || disburse.Vehicle__r.Vehicle_Type__c == 'Fully Built')){
                            if(disburse.Loan_Amount__c != disburseData.Loan_Amount__c){
                                disburse.Loan_Amount_Approval__c = disburseData.Loan_Amount__c;
                            }if(disburse.Insurance_Amount__c != disburseData.Insurance_Amount__c){
                                disburse.Insurance_Amount_Approval__c = disburseData.Insurance_Amount__c;
                            }if(disburse.Processing_Fee__c != disburseData.Processing_Fee__c){
                                disburse.Processing_Fee_Approval__c = disburseData.Processing_Fee__c;
                            }if(disburse.ROI__c != disburseData.ROI__c){
                                disburse.ROI_Approval__c = disburseData.ROI__c;
                            }if(disburse.Tenure__c != disburseData.Tenure__c){
                                disburse.Tenure_Approval__c = disburseData.Tenure__c;
                            }
                            disbursementList.add(disburse);
                        }else{
                             if(disburse.Loan_Amount__c != disburseData.Loan_Amount__c){
                                disburse.Loan_Amount_Approval__c = disburseData.Loan_Amount__c;
                            }if(disburse.Insurance_Amount__c != disburseData.Insurance_Amount__c){
                                disburse.Insurance_Amount_Approval__c = disburseData.Insurance_Amount__c;
                            }if(disburse.Processing_Fee__c != disburseData.Processing_Fee__c){
                                disburse.Processing_Fee_Approval__c = disburseData.Processing_Fee__c;
                            }if(disburse.ROI__c != disburseData.ROI__c){
                                disburse.ROI_Approval__c = disburseData.ROI__c;
                            }if(disburse.Tenure__c != disburseData.Tenure__c){
                                disburse.Tenure_Approval__c = disburseData.Tenure__c;
                            }
                            disbursementList.add(disburse);
                        }
                    }
                    if(!disbursementList.isEmpty()){
                        resWrap.isSuccess = true;
                        resWrap.responseBody =  'Success';
                        UPDATE disbursementList;
                        Id userId  = UserInfo.getUserId();
                        UB_LoanApplicationMoveToNextController.approavalProcessMethod(disbursementList[0].Id,disbursementList[0].CM__c, userId,'Approval_Disbursement' );
                    }else{
                        resWrap.isSuccess = false;
                        resWrap.responseBody =  UB_ConstantsUtil.DISBURSEMENT_VALIDATION;
                    }                    
                }else{
                    for(Disbursement__c disburse : disburseList){
                        if(disburse.Loan_Amount__c != disburseData.Loan_Amount__c){
                            disburse.Loan_Amount_Approval__c = disburseData.Loan_Amount__c;
                        }if(disburse.Insurance_Amount__c != disburseData.Insurance_Amount__c){
                            disburse.Insurance_Amount_Approval__c = disburseData.Insurance_Amount__c;
                        }if(disburse.Processing_Fee__c != disburseData.Processing_Fee__c){
                            disburse.Processing_Fee_Approval__c = disburseData.Processing_Fee__c;
                        }if(disburse.ROI__c != disburseData.ROI__c){
                            disburse.ROI_Approval__c = disburseData.ROI__c;
                        }if(disburse.Tenure__c != disburseData.Tenure__c){
                            disburse.Tenure_Approval__c = disburseData.Tenure__c;
                        }
                        disbursementList.add(disburse);
                    }
                    if(!disbursementList.isEmpty()){
                        resWrap.isSuccess = true;
                        resWrap.responseBody =  'Success';
                        UPDATE disbursementList;
                        Id userId  = UserInfo.getUserId();
                        UB_LoanApplicationMoveToNextController.approavalProcessMethod(disbursementList[0].Id,disbursementList[0].CM__c, userId,'Approval_Disbursement' );
                    }else{
                        resWrap.isSuccess = false;
                        resWrap.responseBody =  'ERROR';
                    }
                    
                }
            }
            RETURN resWrap;
        }catch(Exception ex){
            system.debug('ex-> ' + ex.getMessage());
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString() );    
            return resWrap;
        }
    }
    
    
    @AuraEnabled
    public static ResponseWrapper disburmentDocumentGenerate(String LAFId, String sanctionLetter, String repaymentLetter, String disbursementId) {
        ResponseWrapper resWrap = new ResponseWrapper();
        try {
            System.debug('LAFId ID v  '+LAFId);
            Blob b ;
            List<Disbursement__c> disbursementList = [SELECT Id, Name, Vehicle__c,Vehicle__r.Name, Loan_Application__c
                                                      FROM Disbursement__c WHERE id =: disbursementId 
                                                      AND Loan_Application__c != null AND Vehicle__c != null];
            if(!disbursementList.isEmpty()){
               /* if(String.isNotBlank(LAFId) &&  String.isNotBlank(disbursementId)) {
                    if(sanctionLetter == 'Sanction Letter PDF'){
                        PageReference PDf = Page.CV_SanctionLetter;
                        PDf.getParameters().put('Id',disbursementId);
                        PDf.setRedirect(false);
                        b = PDf.getContent();
                        system.debug('b-> ' + b);
                        UB_DisbursementCltr.createDocument(disbursementList[0].Vehicle__r.Name,'Sanction Letter.PDF', b,LAFId, disbursementId,'Sanction Letter','Sanction Letter');
                        resWrap.isSuccess = true;
                    }if(repaymentLetter == 'Repayment Schedule PDF' ){
                        PageReference PDf = Page.UB_RepaymentSchedulePDF;
                        PDf.getParameters().put('Id',disbursementId);
                        PDf.setRedirect(false);
                        b = PDf.getContent();
                        system.debug('b-> ' + b);
                        UB_DisbursementCltr.createDocument(disbursementList[0].Vehicle__r.Name,'Repayment Schedule.PDF', b,LAFId, disbursementId,'Repayment Schedule','Repayment Schedule');
                        resWrap.isSuccess = true;
                    }
                }*/                
            }else{
                 resWrap.isSuccess = false;
            }
            return resWrap;
        } catch (Exception e) {
            System.debug('@the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
            System.debug('@#Line '+e.getLineNumber());
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(e.getMessage() + e.getLineNumber() + e.getStackTraceString() );    
            return resWrap;
        }
    }
    
    public static void createDocument(String title, String pathOnClient, Blob data,String LoanId, String disbursementId, String docType, String docSubType) {
       //List<Document__c> documents = [SELECT Id,Document_Type__c FROM Document__c WHERE Document_Type__c =:docType /*AND Document_Sub_Type__c=:docSubType*/ AND Loan_Application__c=:LoanId AND Disbursement__c =: disbursementId];
        List<Document__c> documents = new List<Document__c>();
        System.debug('docSubType   '+docSubType);
        for(Document__c doc : [SELECT Id,Document_Type__c, Document_Sub_Type__c FROM Document__c WHERE Document_Type__c =:docType /*AND Document_Sub_Type__c=:docSubType*/ AND Loan_Application__c=:LoanId AND Disbursement__c =: disbursementId]){
            if(doc.Document_Sub_Type__c.contains(docSubType)){
                documents.add(doc);
            }
        }
        System.debug('documents   '+documents);
        System.debug('Titleeee  '+title);
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        String documentId = '';
        if(!documents.isEmpty()) {
            documentId = documents[0].Id;
        } else {
            Document__c document = new Document__c();
            document.Document_Type__c = docType;
            document.Document_Sub_Type__c = docSubType;
            document.Loan_Application__c = LoanId;
            document.Disbursement__c = disbursementId;
            document.Status__c = 'Uploaded';
            insert document;
            System.debug('document   '+document);
            documentId = document.Id;
            
        }  
        System.debug('DATAAAAAAA  '+data);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = pathOnClient;
        cv.VersionData = data;
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
            cv.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
        }
        Insert cv;
        
        System.debug('cvcvcvcvcvcv   '+cv);
        
        UB_DisplayUBDocumentsController.uploadDocument(docSubType,title, String.valueOf(data),documentId,cv.Id);
        System.debug('cvcvcvcvcvcv1111   '+cv);
        
    }
    
     @AuraEnabled 
    public static string checkValidations(string recordId) {
        try{
            if(String.isNotBlank(recordId) ){
                List<Disbursement__c> disbursementList =  [SELECT Id, Name, Vehicle__c, Loan_Application__c, 
                                                           Loan_Amount__c, Processing_Fee__c, Insurance_Amount__c, LAN__c, 
                                                           Stage__c, Status__c, ROI__c, Tenure__c, CM__c, Loan_Offer_Review_Status__c 
                                                           FROM Disbursement__c WHERE Id =: recordId AND Loan_Application__c != null
                                                          ];
                if(!disbursementList.isEmpty()){
                    String validationMsg = checkValidation(disbursementList[0]);
                    RETURN validationMsg;
                }
            }
            return null; 
        }catch (Exception e) {
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            String customMessge = e.getMessage() + ' '+ e.getLineNumber();
            RETURN customMessge;
        }
    }
    
    private static string checkValidation(Disbursement__c disburseRec) {
        String validationMsg = '';
        if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_NEGOTIATION){
            if(disburseRec.Loan_Offer_Review_Status__c == null){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_INITIATE+'</li>';  
            }
            if(disburseRec.CM__c == null){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_CM_ERROR+'</li>';  
            }
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_PRE_DISBURSAL){
            /*List<document__c> documentList = [SELECT Id, Name, File_Name__c, Document_Type__c, Document_Sub_Type__c, Status__c, Disbursement__c,
                                              Loan_Application__c
                                              FROM document__c 
                                              WHERE Disbursement__c =: disburseRec.Id ];*/
            List<document__c> documentList = new List<document__c>();
            List<document__c> documentListForSanctionletter = new List<document__c>();
          for(document__c doc : [SELECT Id, Name, File_Name__c, Document_Type__c, Document_Sub_Type__c, Status__c, Disbursement__c,
                                   Loan_Application__c
                                   FROM document__c 
                                   WHERE Disbursement__c =: disburseRec.Id ]){
                                       if(doc.Document_Type__c == 'Sanction Letter' || doc.Document_Type__c == 'Repayment Schedule'){
                                           documentListForSanctionletter.add(doc);
                                       }else{
                                           documentList.add(doc);
                                       } 
                                       
                                   }
           Set<String> documentName = new Set<String>();
            Boolean statusNotUpload = false;
            
            if(documentListForSanctionletter.isEmpty() ){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_LETTERS_ERROR+'</li>';
            }else if(!documentList.isEmpty()){
                for(document__c docs : documentList){
                    if(docs.Disbursement__c != null && docs.Loan_Application__c != null){
                    if(docs.Status__c != 'Uploaded'){
                        statusNotUpload=true;
                        documentName.add(docs.Document_Type__c);
                    }
                }
                }
               if(statusNotUpload){
                   validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_ERROR+'</li>';
               }
            }
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_DOCS_REVIEW){
            Boolean documentNotVerified = false;
            Boolean queryNotCompleted = false;
            Set<String> docName = new Set<String>();
            Set<String> activtyName = new Set<String>();
           for(document__c doc : [SELECT Id, Name, File_Name__c, Document_Type__c, Document_Sub_Type__c, Status__c, Disbursement__c,
                                   Loan_Application__c
                                   FROM document__c 
                                   WHERE Disbursement__c =: disburseRec.Id ]){
                                       if(doc.Status__c != UB_ConstantsUtil.ACTIVITY_CM && doc.Status__c != UB_ConstantsUtil.ACTIVITY_RCU){
                                        docName.add(doc.Document_Type__c);
                                           documentNotVerified = true;
                                       } 
                                   }
            
            for(Task openQuery : [Select Id,Status, WhatId, Document__c,Disbursement__c From Task WHERE Disbursement__c=:disburseRec.Id AND Status!= 'Completed']){
                queryNotCompleted = true;
            }
            
            List<Valuation__c> activityList = new List<Valuation__c>();
            for(Valuation__c val : [select id, name, Loan_Application__c, RecordType_Name__c, 
                                    owner.name, Disbursement__c, Status__c,Result__c, 
                                    Vendor_Status__c  from Valuation__c  WHERE 
                                    Disbursement__c =: disburseRec.Id AND
                                    (Status__c =: UB_ConstantsUtil.ACTIVITY_SAMPLED or Status__c =: UB_ConstantsUtil.ACTIVITY_SCREENED or Status__c = null) 
                                    AND Result__c = null AND
                                    Vendor_Status__c =: UB_ConstantsUtil.ACTIVITY_PENDING ]){
                                        activtyName.add(val.Name);
                                        activityList.add(val);
                                    }
            if(!activityList.isEmpty()){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_ACTIVITY+activtyName+'</li>';
            }
            if(documentNotVerified){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_DOC_NOTVERIFIED +'</li>'; 
            }
            if(queryNotCompleted){
                 validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_OPEN_QUERY +'</li>'; 
            }
            
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_NACH_PENDING){
            List<Bank_Details__c> bankDetailsList = [SELECT Id,Name,Account_Holder_Name__c,Account_Number__c,Payment_Mode__c,IFSC_Code__r.Name,RecordType.Name from Bank_Details__c WHERE Disbursement__c =: disburseRec.Id AND RecordType.Name = 'Disbursement' order by createdDate desc LIMIT 1];
            if(bankDetailsList.isEmpty()){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_MEMO+'</li>';
            }
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_MAKER){
            Boolean documentNotVerified = false;
            Boolean queryNotCompleted = false;
            Set<String> docName = new Set<String>();
            for(document__c doc : [SELECT Id, Name, File_Name__c, Document_Type__c, Document_Sub_Type__c, Status__c, Disbursement__c,
                                   Loan_Application__c
                                   FROM document__c 
                                   WHERE Disbursement__c =: disburseRec.Id ]){
                                       if(doc.Status__c != UB_ConstantsUtil.ACK_STATUS_WAIVED_OFF && doc.Status__c != UB_ConstantsUtil.ACK_STATUS_Completed || doc.Status__c != UB_ConstantsUtil.ACK_STATUS_PDD){
                                           docName.add(doc.Document_Type__c);
                                           documentNotVerified = true;
                                       } 
                                   }
            
            for(Task openQuery : [Select Id,Status, WhatId, Document__c,Disbursement__c From Task WHERE Disbursement__c=:disburseRec.Id AND Status!= 'Completed']){
                queryNotCompleted = true;
            }
            
            if(documentNotVerified){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_MAKER_DOC_NOTVERIFIED +'</li>'; 
            }
            if(queryNotCompleted){
                validationMsg += '<li>'+UB_ConstantsUtil.DISBURSMENT_OPEN_QUERY +'</li>'; 
            }
            
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_CHECKER){
            
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_PDD){
            
        }else if(disburseRec.Stage__c == UB_ConstantsUtil.DISBURSMENT_CLOSED){
            
        }
        RETURN validationMsg;
    }
    
    @AuraEnabled
    public static string moveToNext(string recordId) {
        system.debug('move to next');
        Savepoint sp = Database.setSavepoint();
        try{
            if(String.isNotBlank(recordId) ){
                List<Disbursement__c> disbursementList =  [SELECT Id, Name, Vehicle__c, Loan_Application__c, Loan_Application__r.Ro_RM__c, 
                                                           Loan_Amount__c, Processing_Fee__c, Insurance_Amount__c, LAN__c, Loan_Application__r.LOB__c,
                                                           Stage__c, Status__c, ROI__c, Tenure__c, CM__c, Loan_Offer_Review_Status__c, OwnerId,Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c 
                                                           FROM Disbursement__c WHERE Id =: recordId AND Loan_Application__c != null
                                                          ];
                if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_NEGOTIATION){
                    disbursementList[0].Stage__c = UB_ConstantsUtil.DISBURSMENT_PRE_DISBURSAL;
                    update disbursementList[0];
                     // Added for Recreating the Fees on stage change || Musab || 18-07-2024
                     List<Fees__c> createFeeDetails =  new List<Fees__c>();
                     List<Fees__c> listOfFees = [SELECT Id,Amount__c,GST_Amount__c,Total_Amount__c,Name from Fees__c WHERE Disbursement__c  =: disbursementList[0].Id];
                     if(listOfFees.size() > 0){
                        delete listOfFees;
                     }
                     List<Fee_Master__mdt > feeMasterList = [SELECT Id,Fee_Name__c,Amount_Value__c,Vehicle_Classification__c,Calculation_Type__c,GST_Percentage__c,LOB__c,Percentage_Of__c From Fee_Master__mdt WHERE isActive__c = true];
                     if(!feeMasterList.isEmpty() && feeMasterList.size() > 0){
                                  for(Fee_Master__mdt fee : feeMasterList){
                                    System.debug('Obj Classification '+ fee.Vehicle_Classification__c + ' ---- '+ 'Metadata Classification '+ disbursementList[0].Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c);
                                      if(fee.LOB__c == disbursementList[0].Loan_Application__r.LOB__c){
                                        if(fee.Vehicle_Classification__c != null && fee.Vehicle_Classification__c == disbursementList[0].Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c){
                                            System.debug('Metadata Classification '+ fee.Vehicle_Classification__c + ' ---- '+ ' OBJ Classification '+ disbursementList[0].Vehicle__r.Vehicle_Master__r.Vehicle_Classification__c);
                                            Fees__c feeObj = new Fees__c();
                                            feeObj.Name = fee.Fee_Name__c;
                                            feeObj.Disbursement__c  = disbursementList[0].Id;
                                            // Amount calculation
                                            if(fee.Calculation_Type__c == UB_ConstantsUtil.AMOUNT){
                                                feeObj.Amount__c = fee.Amount_Value__c;
                                            }else{
                                                feeObj.Amount__c = disbursementList[0].Loan_Amount__c*(fee.Amount_Value__c /100); //ex 0.03 % of Loan_Amount__c
                                            }
                                            //GST Amount calculation
                                            feeObj.GST_Amount__c = feeObj.Amount__c * (fee.GST_Percentage__c/100);
                                            //Total Amount calculation
                                            feeObj.Total_Amount__c = ( feeObj.Amount__c + feeObj.GST_Amount__c );
                                            feeObj.Loan_Application__c = disbursementList[0].Loan_Application__c;
                                            createFeeDetails.add(feeObj);  
                                            system.debug('feeeee>>>> ' + feeObj);
                                        }
                                        else if(fee.Vehicle_Classification__c == null){
                                            Fees__c feeObj = new Fees__c();
                                            feeObj.Name = fee.Fee_Name__c;
                                            feeObj.Disbursement__c  = disbursementList[0].Id;
                                            // Amount calculation
                                            if(fee.Calculation_Type__c == UB_ConstantsUtil.AMOUNT){
                                                feeObj.Amount__c = fee.Amount_Value__c;
                                            }else{
                                                feeObj.Amount__c = disbursementList[0].Loan_Amount__c*(fee.Amount_Value__c /100); //ex 0.03 % of Loan_Amount__c
                                            }
                                            //GST Amount calculation
                                            feeObj.GST_Amount__c = feeObj.Amount__c * (fee.GST_Percentage__c/100);
                                            //Total Amount calculation
                                            feeObj.Total_Amount__c = ( feeObj.Amount__c + feeObj.GST_Amount__c );
                                            feeObj.Loan_Application__c = disbursementList[0].Loan_Application__c;
                                            createFeeDetails.add(feeObj);  
                                            system.debug('feeeee>>>> ' + feeObj);
                                        }
                                          
                                         }
                                      }
                        if(!createFeeDetails.isEmpty() && createFeeDetails.size() > 0){
                            system.debug('createFeeDetails!!'+createFeeDetails.size());
                            insert createFeeDetails;
                        }
                     }
                    RETURN UB_ConstantsUtil.DISBURSMENT_PRE_DISBURSAL;
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_PRE_DISBURSAL){          
                    List<Document__c> docList = new List<Document__c>();
                    for(Document__c doc : [SELECT Id, Name, OwnerId FROM Document__c 
                                           WHERE 
                                           Loan_Application__c != null and Disbursement__c =: recordId]){
                                               doc.OwnerId = disbursementList[0].CM__c != null ? disbursementList[0].CM__c : null;
                                               docList.add(doc);
                                           }
                    if(!docList.isEmpty()){
                        UPDATE docList;
                    }
                    disbursementList[0].Stage__c = UB_ConstantsUtil.DISBURSMENT_DOCS_REVIEW;
                    disbursementList[0].OwnerId = disbursementList[0].CM__c != null ? disbursementList[0].CM__c : null;
                    update disbursementList[0];
                    RETURN UB_ConstantsUtil.DISBURSMENT_DOCS_REVIEW;
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_DOCS_REVIEW){
                    List<Document__c> docList = new List<Document__c>();
                    for(Document__c doc : [SELECT Id, Name, OwnerId FROM Document__c 
                                           WHERE 
                                           Loan_Application__c != null and Disbursement__c =: recordId]){
                                               doc.OwnerId = disbursementList[0].Loan_Application__r.Ro_RM__c != null ? disbursementList[0].Loan_Application__r.Ro_RM__c : null;
                                               docList.add(doc);
                                           }
                    if(!docList.isEmpty()){
                        UPDATE docList;
                    }
                    disbursementList[0].Stage__c = UB_ConstantsUtil.DISBURSMENT_NACH_PENDING;
                    disbursementList[0].OwnerId = disbursementList[0].Loan_Application__r.Ro_RM__c != null ? disbursementList[0].Loan_Application__r.Ro_RM__c : null;
                    update disbursementList[0];
                    RETURN UB_ConstantsUtil.DISBURSMENT_NACH_PENDING;
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_NACH_PENDING){
                    //Added by mansur--04-07-2024----(start)
                    disbursementList[0].Stage__c = UB_ConstantsUtil.DISBURSMENT_MAKER;
                    Group cpcMakerQueue = [SELECT Id,DeveloperName,Type FROM Group WHERE Type = :UB_ConstantsUtil.QUEUE AND DeveloperName = :UB_ConstantsUtil.CPC_AGENT_MAKER_QUEUE LIMIT 1];
                    system.debug('cpcMakerQueue>> ' + cpcMakerQueue);
                    if(cpcMakerQueue != null){
                        disbursementList[0].OwnerId = cpcMakerQueue.Id;
                        system.debug('disbursementList[0].OwnerId>> ' + disbursementList[0].OwnerId);
                    }
                    system.debug('disbursementList[0]>> ' + disbursementList[0]);
                    update disbursementList[0];
                     RETURN UB_ConstantsUtil.DISBURSMENT_MAKER;
                  
                    
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_MAKER){
                    
                    disbursementList[0].Stage__c = UB_ConstantsUtil.DISBURSMENT_CHECKER;
                    Group cpcCheckerQueue = [SELECT Id,DeveloperName,Type FROM Group WHERE Type = :UB_ConstantsUtil.QUEUE AND DeveloperName = :UB_ConstantsUtil.CPC_AGENT_CHECKER_QUEUE LIMIT 1];
                    system.debug('cpcCheckerQueue>> ' + cpcCheckerQueue);
                    if(cpcCheckerQueue != null){
                        disbursementList[0].OwnerId = cpcCheckerQueue.Id;
                        system.debug('disbursementList[0].OwnerId>> ' + disbursementList[0].OwnerId);
                    }
                    system.debug('disbursementList[0]>> ' + disbursementList[0]);
                    update disbursementList[0];
                     RETURN UB_ConstantsUtil.DISBURSMENT_CHECKER;
                    //end----
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_CHECKER){
                    
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_PDD){
                    
                }else if(disbursementList[0].Stage__c == UB_ConstantsUtil.DISBURSMENT_CLOSED){
                    
                }
            }
            RETURN null;
        }catch (Exception e) {
            System.debug('** error Line   == '+ e.getLineNumber());
            System.debug('** error e   == '+ e);
            String customMessge = e.getMessage() + ' '+ e.getLineNumber();
            RETURN customMessge;
        }
    }

    @AuraEnabled
    public static Boolean latestPartnerVerificationRecord(String disbursementId){
        Boolean quoteStatusCompleted = false;
        try{
         system.debug('disbursmentId>>> '+disbursementId);
         if(disbursementId != Null){

         
        List<Verification__c> verificationList = new UB_VerificationsSelector().selectByDisbIdAndRecordType(new Set<Id>{disbursementId}, UB_ConstantsUtil.PARTNER_VERIFICATION_RECORD_TYPE_NAME);
            if(!verificationList.isEmpty()){
                if(verificationList[0].status__c == 'Completed'){
                    system.debug('completed ');
                    quoteStatusCompleted = true;
                }else{
                    quoteStatusCompleted = false;
                }
            }
            system.debug('quoteStatusCompleted>> '+quoteStatusCompleted);

            system.debug('verificationList>> '+verificationList);
        }
            return quoteStatusCompleted;
    }catch(Exception e) {
        
        System.debug('Exception@@'+e.getMessage());
        System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
        return quoteStatusCompleted;

    }
}
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
         @AuraEnabled public String loanOfferStatus;
        @AuraEnabled public String responseBody;
    }
}