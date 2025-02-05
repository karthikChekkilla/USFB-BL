/*
Name        : UB_DisplayUBDocumentsController
Author      : Lakshya Verma
Description : 
Test Class  :
*/

public class UB_DisplayUBDocumentsController {
    @AuraEnabled
    public static ResponseWrapper getLeadDocuments(String leadId){
        ResponseWrapper response = new ResponseWrapper();
        response.isSuccess = true;
        try{
            List<Document__c> documentList = [SELECT Id, Name, Document_Type__c, Stage__c, Status__c, Is_Required__c, 
                                              Document_Sub_Type__c, Lead__c, Lead__r.Name, 
                                              Loan_Applicant__c, Loan_Applicant__r.name, Loan_Application__c, Loan_Application__r.name 
                                              FROM Document__c WHERE Lead__c =: leadId order by Is_Required__c desc];
            if(documentList != null && documentList.size() > 0){
                response.responseBody = JSON.serialize(documentList);
                response.totalRecords = documentList.size();
            }else{
                response.isSuccess = false;
                response.responseBody = 'Document records are not exist!!';
                response.totalRecords = documentList.size();
            }                      
        }catch(Exception e){
            response.isSuccess = false;
            response.responseBody = e.getMessage();
            return response;
        }
        return response;
    }
    
    @AuraEnabled
    public static ResponseWrapper getDisbursementDocs(String disburseId,string metadata){
        system.debug('disburseId==>'+disburseId);
        system.debug('metadata==>'+metadata);
        //parameter metadata added by chandan on 25th July,2024 for sanction condition on disbursement
        ResponseWrapper response = new ResponseWrapper();
        response.isSuccess = true;
        List<Document__c> documentList = new List<Document__c>();
        try{
            if(metadata == 'Sanction_Condition'){
                // Query to get the Disbursement record along with the related Loan Application Id
                Disbursement__c disrec = [SELECT Id, Loan_Application__r.Id FROM Disbursement__c WHERE Id = :disburseId LIMIT 1];
                
                // Store the Loan Application Id in the string variable loanId
                String loanId = disrec.Loan_Application__r.Id;
                documentList = [select id,name,Description__c,Acknowledge_Status__c, Status__c,Sanction_Condion_SL__c,Sanction_Condition_Sl_no__c from document__c where Loan_Application__c =:loanId and Document_Type__c = 'Sanction Condition'];
            }else{
                documentList = [SELECT Id, Name, Document_Type__c,Sanction_Condion_SL__c,Description__c, Stage__c, Status__c, Is_Required__c, 
                                Document_Sub_Type__c, Disbursement__c, Disbursement__r.Name, Acknowledge_Status__c,
                                Loan_Applicant__c, Loan_Applicant__r.name, Loan_Application__c, Loan_Application__r.name 
                                FROM Document__c WHERE Disbursement__c =: disburseId 
                                ORDER by Is_Required__c desc];
            }
            
            
            if(documentList != null && documentList.size() > 0){
                response.responseBody = JSON.serialize(documentList);
                response.totalRecords = documentList.size();
            }else{
                response.isSuccess = false;
                response.responseBody = 'Document records are not exist!!';
                response.totalRecords = documentList.size();
            }  
            system.debug('documentList==>'+documentList);
        }catch(Exception e){
            response.isSuccess = false;
            response.responseBody = e.getMessage();
            return response;
        }
        return response;
    }
    
    @AuraEnabled
    public static ResponseWrapper getApplicationDocuments(String applicationId, String loanApplicantId){
        system.debug('applicationId==>'+applicationId);
        ResponseWrapper response = new ResponseWrapper();
        try{
            List<Loan_Applicant__c> loanApplicantList = new List<Loan_Applicant__c>();
            if(loanApplicantId != null && String.isNotBlank(loanApplicantId)){
                loanApplicantList = [SELECT Id, Account__c FROM Loan_Applicant__c WHERE Id =: loanApplicantId AND Is_Deleted__c = 'No'/* WITH SECURITY_ENFORCED*/ LIMIT 1];
            }
            String qry = 'SELECT Id, Name, Document_Type__c,Description__c,Sanction_Condition_Sl_no__c,Sanction_Condion_SL__c, Document_Sub_Type__c,Is_Required__c ,Acknowledge_Status__c,  Lead__c, Lead__r.Name, Stage__c, Status__c,   ';
            qry += ' Loan_Applicant__c, Loan_Applicant__r.name, Loan_Application__c, Loan_Application__r.name, Loan_Application__r.Record_Type_Name__c FROM Document__c ';
            qry += ' WHERE Loan_Application__c=: applicationId ';
            //if(loanApplicantList != null && loanApplicantList.size() > 0){
            //qry += ' AND Loan_Applicant__r.Account__c = \'' +loanApplicantList[0].Account__c + '\'';
            //}else{
            //qry += ' AND Loan_Applicant__c =: loanApplicantId';
            //}
            qry += ' AND Loan_Applicant__c =: loanApplicantId order by Is_Required__c desc ';
            
            List<Document__c> documentList = Database.query(qry);
            if(documentList != null && documentList.size() > 0){
                response.responseBody = JSON.serialize(documentList);
                response.isSuccess = true;
                response.totalRecords = documentList.size();
            }else{
                response.isSuccess = false;
                response.responseBody = 'Document records are not existes';
                response.totalRecords = documentList.size();
            }
            
        }catch(Exception ex){
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
            return response;
        }
        RETURN response;
    }
    
    @AuraEnabled
    public static ResponseWrapper deleteDoc(String recordId) {
        ResponseWrapper response = new ResponseWrapper();
        try{
            if(recordId != null && String.isnotBlank(recordId) ){
                Document__c docObj = [Select Id from Document__c where Id =: recordId];
                delete docObj;
                response.isSuccess = true;
            }else{
                response.isSuccess = false;
            }
            //return response;
        }
        catch(Exception error){
            //system.debug('error' + error);
            //system.debug('error' + error.getMessage());
            response.isSuccess = false;
            response.responseBody =  JSON.serialize(error.getMessage());
            return response;
        }
        return response;
    }
    
    @AuraEnabled
    public static ResponseWrapper updateDocumentStatus(String recordId, String status) {
        ResponseWrapper response = new ResponseWrapper();
        try{
            if(recordId != null && String.isnotBlank(recordId) && status != null && String.isnotBlank(status) ){
                
                Document__c docObj = [Select Id, Status__c from Document__c where Id =: recordId];
                docObj.Status__c = status;
                UPDATE docObj;
                system.debug('recordId-> ' + recordId);
                system.debug('status-> ' + status);
                system.debug('docObj-> ' + docObj);
                response.isSuccess = true;
            }else{
                response.isSuccess = false;
            }
            //return response;
        }
        catch(Exception error){
            //system.debug('error' + error);
            //system.debug('error' + error.getMessage());
            response.isSuccess = false;
            response.responseBody =  JSON.serialize(error.getMessage());
            return response;
        }
        return response;
    }
    
    @AuraEnabled
    public static ResponseWrapper uploadDocument(String documentSubType , String fileName, String base64, String recordId, String contentVersionId) {
        ResponseWrapper response = new ResponseWrapper();
        System.debug('UPLOAD CLASSSSS');
        System.debug('documentSubType  '+documentSubType);
        System.debug('base64base64base64base64  '+base64);
        try{
            Id profileId=userinfo.getProfileId();
            List<Valuation__c> RCUActivityLst = new List<Valuation__c>();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
            List<Document__c> documentList = [SELECT Id,Document_Sub_Type__c,Document_Type__c, Status__c,Loan_Applicant__c,Loan_Application__c FROM Document__c WHERE Id =: recordId];
            if(documentList[0]?.Loan_Applicant__c != null && documentList[0]?.Loan_Application__c != null && documentList[0]?.Document_Type__c == 'Photo'){
                RCUActivityLst = [select id,name,Loan_Applicant__c,Loan_Application__c,RecordType_Name__c,Applicant_URL__c from Valuation__c WHERE Loan_Application__c =:documentList[0].Loan_Application__c AND Loan_Applicant__c =:documentList[0].Loan_Applicant__c AND RecordType_Name__c='RCU'/*:UB_ConstantsUtil.RCU_VALUATION_RECORD_TYPE*/ ORDER BY CreatedDate Desc];
            }
            
            System.debug('RCUActivityLst===>'+RCUActivityLst);
            System.debug('documentList   '+documentList);
            System.debug('base64      '+documentList);
            if(documentList != null && documentList.size() > 0 && contentVersionId != null ){
                Document__c documentChild = new Document__c();
                documentChild.Parent_Document__c = documentList[0].Id;
                documentChild.File_Name__c = fileName;
                INSERT documentChild;
                System.debug('documentChild   '+documentChild);
                
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
                
                
                List<Document__c> documentInsertedList = [SELECT Id FROM Document__c WHERE Id =: documentChild.Id];
                
                //ContentVersion cv = new ContentVersion();
                //cv.Title = fileName;
                //cv.PathOnClient = fileName;
                //cv.VersionData =  Blob.valueOf( base64);
                //if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
                // cv.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
                // }
                //cv.VersionData = EncodingUtil.base64Decode(base64);
                //cv.IsMajorVersion = true;
                // Insert cv;
                
                
                
                //Create ContentDocumentLink 
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = documentInsertedList[0].Id;
                cdl.ContentDocumentId = conDocId;
                cdl.shareType = 'I';
                Insert cdl;
                
                ContentDistribution newDist = new ContentDistribution();
                newDist.ContentVersionId = contentVersionId;
                newDist.Name = fileName;
                newDist.PreferencesNotifyOnVisit = false;
                newDist.PreferencesAllowViewInBrowser = true;
                newDist.PreferencesAllowOriginalDownload=true;
                insert newDist;
                
                List<ContentDistribution> distribution = [Select Id, ContentDownloadUrl, 
                                                          DistributionPublicUrl, PdfDownloadUrl FROM
                                                          ContentDistribution where id =: newDist.Id];
                if(distribution != null && distribution.size() > 0){
                    if(distribution[0].DistributionPublicUrl != null && String.isNotBlank(distribution[0].DistributionPublicUrl) && distribution[0].ContentDownloadUrl != null && String.isNotBlank(distribution[0].ContentDownloadUrl)){
                        if(documentInsertedList != null && documentInsertedList.size() > 0){
                            documentInsertedList[0].Document_URL__c = distribution[0].ContentDownloadUrl;
                            documentInsertedList[0].Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
                            documentInsertedList[0].Status__c = 'Uploaded';
                            UPDATE documentInsertedList;
                        }
                    }
                }
                
                //documentInsertedList[0].Document_URL__c = distribution[0].ContentDownloadUrl;
                //documentInsertedList[0].Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
                documentList[0].Status__c = 'Uploaded';
                documentList[0].Document_Sub_Type__c = String.isNotBlank(documentSubType) ? documentSubType : '';
                UPDATE documentList;
                
                if(RCUActivityLst.size()>0 && documentList[0]?.Document_Type__c != null && documentList[0]?.Document_Type__c == 'Photo'){
                    RCUActivityLst[0].Applicant_URL__c = distribution[0].DistributionPublicUrl;
                    update RCUActivityLst;
                }
                /*
// code to call ImageMasking Api.
if(documentSubType == UB_ConstantsUtil.AADHAR_DOCUMENT_SUB_TYPE) {
System.debug('CALING IMAGE MASK API');
UB_AadharIMageMasking.getkAadharMaskImage( cv.Id);
} */
                response.isSuccess = true;
            }
            /*ContentVersion cv = new ContentVersion();
cv.Title = fileName;
cv.PathOnClient = fileName;
cv.VersionData = EncodingUtil.base64Decode(base64);
//cv.IsMajorVersion = true;
Insert cv;

//Get Content Documents
Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

//Create ContentDocumentLink 
ContentDocumentLink cdl = New ContentDocumentLink();
cdl.LinkedEntityId = recordId;
cdl.ContentDocumentId = conDocId;
cdl.shareType = 'V';
Insert cdl;*/
            
            /*ContentDistribution newDist = new ContentDistribution();
newDist.ContentVersionId = contentVersionId;
newDist.Name = fileName;
newDist.PreferencesNotifyOnVisit = false;
newDist.PreferencesAllowViewInBrowser = true;
newDist.PreferencesAllowOriginalDownload=true;
insert newDist;*/
            
            /*List<ContentDistribution> distribution = [Select Id, ContentDownloadUrl, 
DistributionPublicUrl, PdfDownloadUrl FROM
ContentDistribution where id =: newDist.Id];*/
            /*if(distribution != null && distribution.size() > 0){
if(distribution[0].DistributionPublicUrl != null && String.isNotBlank(distribution[0].DistributionPublicUrl) && distribution[0].ContentDownloadUrl != null && String.isNotBlank(distribution[0].ContentDownloadUrl)){
List<Document__c> existingDocumentList = [SELECT Id, Document_URL__c, Status__c FROM Document__c WHERE Id =: recordId];
system.debug('existingDocumentList-> ' + existingDocumentList);
system.debug('recordId-> ' + recordId);
if(existingDocumentList != null && existingDocumentList.size() > 0){
existingDocumentList[0].Document_URL__c = distribution[0].ContentDownloadUrl;
existingDocumentList[0].Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
existingDocumentList[0].Status__c = 'Uploaded';
UPDATE existingDocumentList;
}else{
Document__c documentObj = new Document__c();

}
}
}*/
            
            //return response;
        }
        catch(Exception error){
            system.debug('error' + error.getLineNumber());
            system.debug('error' + error.getMessage());
            response.isSuccess = false;
            response.responseBody =  JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            return response;
        }
        System.debug('RESPONSEEEEEE  '+response);
        
        return response;
    }
    
    /* @AuraEnabled
public static Map<ID, String> getRelatedFilesByRecordId(String recordId) {
// Get record file IDs        
List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];
List<ID> fileIDs = new List<ID>();
for (ContentDocumentLink docLink : files) {
fileIDs.add(docLink.ContentDocumentId);
}

List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title 
FROM ContentVersion WHERE ContentDocumentId IN : fileIDs];
Map<ID, String> mapIdTitle = new Map<ID, String>();
for (ContentVersion docLink : docs) {
mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
}
system.debug('mapIdTitle-> ' + mapIdTitle);
return mapIdTitle;
}*/
    
    @AuraEnabled
    public static List<Document__c> getRelatedFilesByRecordId(String recordId , String applicationId){
        Map<ID, String> mapIdTitle = new Map<ID, String>();
        Set<Id> childIds = new Set<Id>();
        List<ID> fileIDs = new List<ID>();
        List<Document__c> documentList = new List<Document__c>();
        if(String.isNotBlank(recordId) && recordId != null){
            for (Document__c docLink : [SELECT Id,Name,File_Name__c,Status__c, Document_URL__c,Uploaded_By__c,Uploaded_Date__c,  Document_Preview_Url__c, Document_Type__c,Parent_Document__r.Document_Type__c FROM Document__c WHERE Parent_Document__c =: recordId ]) {
                mapIdTitle.put(docLink.Id, docLink.Document_Preview_Url__c);
                documentList.add(docLink);
            }
            /*List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : childIds];

for (ContentDocumentLink docLink : files) {
fileIDs.add(docLink.ContentDocumentId);
}

List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title 
FROM ContentVersion WHERE ContentDocumentId IN : fileIDs];
for (ContentVersion docLink : docs) {
mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
}*/
        }
        //return mapIdTitle;
        //ResponseWrapper response = new ResponseWrapper();
        /*Map<ID, String> mapIdTitle = new Map<ID, String>();
try{
List<Document__c> documentList = [SELECT Id, Document_URL__c, Document_Preview_Url__c FROM Document__c WHERE Id =: recordId AND Document_URL__c != null AND Document_Preview_Url__c != null];
if(documentList != null && documentList.size() > 0){
response.isSuccess = true;
response.responseBody = JSON.serialize(documentList[0].Document_Preview_Url__c);
//mapIdTitle.put(documentList[0].Id, documentList[0].Document_URL__c);
}else{
response.isSuccess = false;
response.responseBody = 'Document records are not exist!!';
}                      
}catch(Exception e){
response.isSuccess = false;
response.responseBody = e.getMessage();
return response;
}*/
        return documentList;
        //return mapIdTitle;
    }
    
    /**
* @description getLoanApplicantRecords
* @param applicationId
* @return response
*/
    @AuraEnabled(Cacheable=true)
    public static ResponseWrapper getLoanApplicantRecords(String applicationId){
        ResponseWrapper response = new ResponseWrapper();
        try{
            List<Loan_Applicant__c> loanApplicantList = [SELECT Id, Name, Applicant_Type__c, Account_Name__c,
                                                         Account__c, Loan_Application__c,Loan_Application__r.IsReadOnly__c 
                                                         FROM Loan_Applicant__c 
                                                         WHERE Loan_Application__c=: applicationId AND Is_Deleted__c = 'No' /*WITH SECURITY_ENFORCED*/
                                                         Order By Applicant_Type__c];
            if(loanApplicantList != null && loanApplicantList.size() > 0){
                Map<String, String> loanApplicantIdAndRelationMap = new Map<String, String>();
                for(Loan_Applicant__c record : loanApplicantList){
                    response.irReadOnly =record.Loan_Application__r.IsReadOnly__c;
                    String name = '';
                    String key = record.Account_Name__c + '-' + record.Loan_Application__c;
                    if(loanApplicantIdAndRelationMap.containsKey(key)){
                        name = loanApplicantIdAndRelationMap.get(key);
                        name += ', ' + record.Applicant_Type__c;
                        loanApplicantIdAndRelationMap.put(key, name);
                    }else{
                        name = record.Account_Name__c + '(' + record.Applicant_Type__c;
                        loanApplicantIdAndRelationMap.put(key, name);
                    }
                }
                
                // Generate JSON Without Wrapper.
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartArray();
                for(Loan_Applicant__c record : loanApplicantList){
                    String key = record.Account_Name__c + '-' + record.Loan_Application__c;
                    if(loanApplicantIdAndRelationMap.containsKey(key) && loanApplicantIdAndRelationMap.get(key) != ''){
                        String name = loanApplicantIdAndRelationMap.get(key);
                        gen.writeStartObject();
                        gen.writeStringField('Id', record.Id);
                        gen.writeStringField('Name', name + ')' );
                        gen.writeEndObject();
                        loanApplicantIdAndRelationMap.put(key, '');
                    }
                }
                gen.writeEndArray();
                response.responseBody = gen.getAsString();
                response.isSuccess = true;
            }else{
                response.isSuccess = false;
                response.responseBody = 'Loan Applicants records are not existes';
            }
        }catch(Exception ex){
            response.isSuccess = false;
            response.responseBody = ex.getMessage();
            return response;
        }
        system.debug('ResponseWrapper-> ' + response);
        RETURN response;
    }
    
    @AuraEnabled
    public static Boolean getRecordIsReadOnlyFromSObject(String recordId, String SObjectName){
        if(SObjectName == 'Loan_Application__c'){
            RETURN [SELECT Id, IsReadOnly__c FROM Loan_Application__c WHERE Id =: recordId LIMIT 1].IsReadOnly__c;
        }else if(SObjectName == 'Lead__c'){
            RETURN [SELECT Id, IsReadOnly__c FROM Lead__c WHERE Id =: recordId  LIMIT 1].IsReadOnly__c;
        }else if(SObjectName == 'Disbursement__c'){
            RETURN [SELECT Id,Is_Read_Only__c FROM Disbursement__c WHERE Id =: recordId  LIMIT 1].Is_Read_Only__c;
        }
        RETURN null;
    }
    
    @AuraEnabled
    public static ResponseWrapper getTaskrecord(String recordId){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            if(String.isNotBlank(recordId)){
                List<Task> taskList = [Select Id,Status, WhatId, Document__c From Task WHERE Id =: recordId];
                List<Valuation__c> valuationList = [Select Id,  Document__c,Loan_Application__c From Valuation__c WHERE Id =: recordId];
                List<Personal_Discussion__c> pdList = new UB_PersonalDiscussionsSelector().selectById(new Set<Id>{recordId});
                if(taskList != null && taskList.size() > 0){
                    List<Loan_Application__c> applicationRecord  = [SELECT Id FROM Loan_Application__c WHERE Id =: taskList[0].WhatId];
                    List<Task> existingTaskWithDocument = [SELECT Id, Document__c FROM Task WHERE Id =: recordId AND Document__c != null];
                    if(existingTaskWithDocument != null && existingTaskWithDocument.size() > 0){
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(existingTaskWithDocument[0]);
                        RETURN resWrap;
                    }else{
                        Document__c documentRecord = new Document__c();
                        documentRecord.Document_Type__c = 'Others';
                        documentRecord.Loan_Application__c = applicationRecord.size() > 0 && applicationRecord != null ?  applicationRecord[0].Id : null;
                        INSERT documentRecord;
                        
                        List<Document__c>  documentList = [Select Id From Document__c WHERE Id =: documentRecord.Id]; 
                        taskList[0].Document__c = documentList[0].Id;
                        UPDATE taskList;
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(taskList[0]);
                        system.debug('taskList[0]-> ' + resWrap);
                        RETURN resWrap;
                    }
                }else if(valuationList != null && valuationList.size() > 0){
                    List<Loan_Application__c> applicationRecord  = [SELECT Id FROM Loan_Application__c WHERE Id =: valuationList[0].Loan_Application__c];
                    List<Valuation__c> existingValuationWithDocument = [Select Id,  Document__c,Loan_Application__c From Valuation__c WHERE Id =: recordId AND Document__c != null ];
                    if(existingValuationWithDocument != null && existingValuationWithDocument.size() > 0){
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(existingValuationWithDocument[0]);
                        RETURN resWrap;
                    }else{
                        Document__c documentRecord = new Document__c();
                        documentRecord.Document_Type__c = 'Others';
                        documentRecord.Valuation__c = recordId;
                        documentRecord.Loan_Application__c = applicationRecord.size() > 0 && applicationRecord != null ?  applicationRecord[0].Id : null;
                        INSERT documentRecord;
                        
                        List<Document__c>  documentList = [Select Id From Document__c WHERE Id =: documentRecord.Id]; 
                        valuationList[0].Document__c = documentList[0].Id;
                        UPDATE valuationList;
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(valuationList[0]);
                        system.debug('valuationList[0]-> ' + resWrap);
                        RETURN resWrap;
                    } 
                }else if(!pdList.isEmpty() && pdList.size() > 0){
                    if(pdList[0].Document__c != null){
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(pdList[0]);
                        RETURN resWrap;
                    }else{
                        Document__c documentRecord = new Document__c();
                        documentRecord.Document_Type__c = UB_ConstantsUtil.PD_DOC_TYPE;
                        documentRecord.Loan_Application__c = pdList[0].Loan_Application__c != null ? pdList[0].Loan_Application__c : null;
                        INSERT documentRecord;
                        
                        pdList[0].Document__c = documentRecord.Id;
                        UPDATE pdList;
                        resWrap.isSuccess = true;
                        resWrap.responseBody = JSON.serialize(pdList[0]);
                        RETURN resWrap;
                    } 
                }
            }
        }catch(Exception error){
            system.debug('error' + error.getLineNumber());
            system.debug('error' + error.getMessage());
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
            return resWrap;
        }
        RETURN null;
    }
    
    /*@AuraEnabled
public static Task getTaskrecord(String recordId){
List<Task> taskList = [Select Id,Status, WhatId, Document__c From Task WHERE Id =:recordId  AND Document__c != null AND WhatId != null ];
if(taskList != null && taskList.size() > 0){
system.debug('getTaskrecord if taskList-> ' + taskList);
List<Document__c> checkExistDocument = [SELECT Id, Document_Type__c FROM Document__c WHERE Loan_Application__c =: taskList[0].WhatId AND Document_Type__c = 'Others'];
if(checkExistDocument.size() > 0){
system.debug('getTaskrecord if checkExistDocument-> ' + checkExistDocument);
RETURN  taskList[0];
}  
}else{
try{
system.debug('getTaskrecord else');
List<Task> taskListWithouDoc = [Select Id,Status, WhatId, Document__c From Task WHERE Id =:recordId AND WhatId != null];
system.debug('taskListWithouDoc-> ' + taskListWithouDoc);
if(taskListWithouDoc != null && taskListWithouDoc.size() > 0 ){
system.debug('getTaskrecord else taskListWithouDoc ' + taskListWithouDoc[0].WhatId );
List<Loan_Application__c> applicationRecord  = [SELECT Id FROM Loan_Application__c WHERE Id =: taskListWithouDoc[0].WhatId];
system.debug('getTaskrecord else applicationRecord' + applicationRecord );
Document__c documentRecord = new Document__c();
documentRecord.Document_Type__c = 'Others';
documentRecord.Loan_Application__c = applicationRecord.size() > 0 && applicationRecord != null ?  applicationRecord[0].Id : null;
INSERT documentRecord;

List<Document__c>  documentList = [Select Id From Document__c WHERE Id =: documentRecord.Id]; 
taskListWithouDoc[0].Document__c = documentList[0].Id;
UPDATE taskListWithouDoc;
RETURN taskListWithouDoc[0];
}
}catch(Exception error){
system.debug('Error getTaskrecord-> ' + error.getMessage() + error.getLineNumber() + error.getStackTraceString());
}
}  
RETURN null;
}*/
    
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getDocumentUrl(String recordId){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            List<Task> taskList = [Select Id,Document__c, Document__r.Loan_Application__c,Document__r.Parent_Document__c From Task WHERE Id =:recordId AND Document__c != null];
            List<Valuation__c> valuationList = [Select Id,  Document__c,Loan_Application__c, Document__r.Parent_Document__c From Valuation__c WHERE Id =: recordId AND Document__c != null AND Document__r.Status__c='Uploaded'];
            List<Personal_Discussion__c> pdList = new UB_PersonalDiscussionsSelector().selectById(new Set<Id>{recordId});
            if(taskList != null && taskList.size() > 0){
                resWrap.isSuccess = true;
                resWrap.responseBody = taskList[0].Document__c;
            }else if(valuationList != null && valuationList.size() > 0){
                resWrap.isSuccess = true;
                resWrap.responseBody = valuationList[0].Document__c;
            }else if(!pdList.isEmpty() && pdList.size() > 0){
                resWrap.isSuccess = true;
                resWrap.responseBody = pdList[0].Document__c;
            }
            return resWrap;
        }catch(Exception ex){
            resWrap.isSuccess = false;
            resWrap.responseBody = ex.getMessage();
            return resWrap;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Document__c getDocumentType(String recordId){
        try{
            RETURN[SELECT Id,Document_Type__c, Document_Sub_Type__c FROM Document__c WHERE Id =: recordId];
        }catch(Exception ex){
            return null;
        }
    }
    
    @AuraEnabled
    public static ResponseWrapper updateVerifiedDocument(List<String> docIds, String sObjectName, String ackStatus) {
        ResponseWrapper resWrap = new ResponseWrapper();
        String disbursementId;
        
        try {
            // Validate input parameters
            if (docIds == null || docIds.isEmpty() || String.isBlank(sObjectName) || String.isBlank(ackStatus)) {
                return createErrorResponse(resWrap, 'Invalid input parameters.');
            }
            
            System.debug('docIds -> ' + docIds);
            
            // Fetch current user's profile and role
            User userRecord = [
                SELECT Profile.Name, UserRole.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            String profileName = userRecord.Profile != null ? userRecord.Profile.Name : null;
            String roleName = userRecord.UserRole != null ? userRecord.UserRole.Name : null;
            
            System.debug('Current user profile: ' + profileName);
            System.debug('Current user role: ' + roleName);
            
            // Query documents and extract disbursementId
            List<Document__c> documents = [
                SELECT Id, Status__c, Acknowledge_Status__c, Disbursement__c,Document_Type__c
                FROM Document__c 
                WHERE Id IN :docIds
            ];
            
            if (documents.isEmpty()) {
                return createErrorResponse(resWrap, 'No documents found for the provided IDs.');
            }
            
            // Extract the first non-null Disbursement__c value
            for (Document__c doc : documents) {
                if (doc.Disbursement__c != null) {
                    disbursementId = doc.Disbursement__c;
                    break;
                }
            }
            
           /* if (disbursementId == null) {
                return createErrorResponse(resWrap, 'No valid disbursement ID found in the documents.');
            }*/
            
            // Fetch pending RCU activities related to the disbursementId
            List<Valuation__c> pendingActivities = [
                SELECT Id 
                FROM Valuation__c 
                WHERE Disbursement__c = :disbursementId 
                AND RecordType_Name__c = 'RCU' 
                AND Result__c = null
            ];
            
            // Validate based on user role and document status
            if (!validateUserPermissions(roleName, profileName, documents, pendingActivities, resWrap)) {
                return resWrap;
            }
            
            // Update document statuses
            updateDocumentStatuses(documents, roleName, ackStatus);
            update documents;
            
            resWrap.isSuccess = true;
            resWrap.responseBody = 'Verified Successfully!!';
            
        } catch (Exception e) {
            System.debug('Error in document verification: ' + e.getMessage());
            return createErrorResponse(resWrap, 'An error occurred while verifying documents: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
        
        return resWrap;
    }
    
    // Helper method to create an error response
    private static ResponseWrapper createErrorResponse(ResponseWrapper resWrap, String message) {
        resWrap.isSuccess = false;
        resWrap.responseBody = message;
        return resWrap;
    }
    
  private static Boolean validateUserPermissions(String roleName, String profileName, List<Document__c> documents, List<Valuation__c> pendingActivities, ResponseWrapper resWrap) {
    for (Document__c docObj : documents) {
        if (roleName == 'RCU Manager' && (docObj.Acknowledge_Status__c == 'OTC' || docObj.Acknowledge_Status__c == 'PDD')) {
            createErrorResponse(resWrap, 'RCU Manager cannot update the acknowledgment status when it is OTC or PDD.');
            return false;  // Return false to indicate that validation failed
        }
        
         if (roleName == 'RCU Manager' && (docObj.Status__c == 'CM Acknowledged')) {
            createErrorResponse(resWrap, 'RCU Manager cannot update the status of CM Acknowledged documents.');
            return false;  // Return false to indicate that validation failed
        }

        if (roleName == 'Credit Manager' && docObj.Status__c == 'RCU Acknowledged') {
            createErrorResponse(resWrap, 'CM cannot change the status of RCU acknowledged documents.');
            return false;  // Return false to indicate that validation failed
        }

        if ((roleName == 'Credit Manager' || profileName == 'System Administrator') && !pendingActivities.isEmpty()) {
            createErrorResponse(resWrap, 'RCU is initiated, CM cannot change the document status.');
            return false;  // Return false to indicate that validation failed
        }
        if((docObj.Acknowledge_Status__c == 'Waived Off' || docObj.Acknowledge_Status__c == 'Completed' ) && docObj.Document_Type__c == 'Sanction Condition'){
            createErrorResponse(resWrap, 'You cannot change the status once it is waived off or completed');
            return false;  // Return false to indicate that validation failed
        }
    }
    return true;  // Return true to indicate that validation passed
}

    // Helper method to update document statuses based on the role
    private static void updateDocumentStatuses(List<Document__c> documents, String roleName, String ackStatus) {
        for (Document__c docObj : documents) {
            if (roleName == 'RCU Manager') {
                docObj.Status__c = 'RCU Acknowledged'; 
            } else if (roleName == 'Credit Manager') {
                docObj.Status__c = 'CM Acknowledged';
            } else {
                docObj.Status__c = 'CPA Acknowledged';
            }
            docObj.Acknowledge_Status__c = ackStatus;
        }
    }
    
    
    
    @AuraEnabled
    public static ResponseWrapper createTaskForAcknowledement(List<String> docIds,String verificationStatus,String comments){
        ResponseWrapper resWrap = new ResponseWrapper();
        try{
            List<Document__c> documentVerifiedStatus = new List<Document__c>();
            List<Task> taskForAcknowledement = new List<Task>();
            String documentNames = '';
            
            if(docIds != null && docIds.size() > 0){
                for(Document__c docObj : [SELECT Id,Status__c,Acknowledge_Status__c, Document_Type__c, 
                                          Document_Sub_Type__c, Loan_Application__c, Loan_Application__r.Ro_RM__c, Loan_Application__r.LOB__c,Disbursement__c,Disbursement__r.RM_RO__c,
                                          Loan_Application__r.DSA__c
                                          FROM Document__c WHERE Id IN : docIds]){
                                              documentNames += '(' + docObj.Document_Type__c +')';
                                              docObj.Status__c = 'CPA Acknowledged';
                                              docObj.Acknowledge_Status__c = String.isNotBlank(verificationStatus) ? verificationStatus : '' ;
                                              Task taskObj = new Task();
                                              taskObj.Subject = docObj.Document_Type__c + '-' + (String.isNotBlank(docObj.Document_Sub_Type__c) ? docObj.Document_Sub_Type__c: '');
                                              taskObj.Description = String.isNotBlank(comments) ? comments : '' ;
                                              taskObj.Type_of_Query__c = 'Document';
                                              taskObj.Type_of_User__c = 'Employee';
                                              if(docObj.Loan_Application__r.LOB__c != null && docObj.Loan_Application__r.LOB__c == 'BL'){
                                                  taskObj.OwnerId = docObj.Loan_Application__c != null && docObj.Loan_Application__r.DSA__c != null ? docObj.Loan_Application__r.DSA__c : UserInfo.getUserId();
                                              }else{
                                                  taskObj.OwnerId = docObj.Disbursement__c != null && docObj.Disbursement__r.RM_RO__c != null ? docObj.Disbursement__r.RM_RO__c : UserInfo.getUserId();
                                              }
                                              taskObj.WhatId = docObj.Id;
                                              taskObj.Loan_Application__c = docObj.Loan_Application__c != null ? docObj.Loan_Application__c : null;
                                               taskObj.Disbursement__c = docObj.Disbursement__c != null ? docObj.Disbursement__c : null;
                                              taskObj.Status = 'InProgress';
                                              taskForAcknowledement.add(taskObj);
                                              documentVerifiedStatus.add(docObj);
                                          }
                if(documentVerifiedStatus != null && documentVerifiedStatus.size() > 0 ){
                    UPDATE documentVerifiedStatus;
                    if(taskForAcknowledement != null && taskForAcknowledement.size() > 0){
                        resWrap.isSuccess = true;
                        resWrap.responseBody = 'Queries are created successfully for these ' + documentNames  ;
                        resWrap.totalRecords = taskForAcknowledement.size();
                        INSERT taskForAcknowledement;
                    }
                }
            }
            
            return resWrap;
        }catch(Exception error){
            resWrap.isSuccess = false;
            resWrap.responseBody =  JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );    
            return resWrap;
        }
    }
    
    @AuraEnabled
    public static String getApplicationRecordType(String applicationId){
        try{
            RETURN [SELECT Id, Record_Type_Name__c FROM Loan_Application__c WHERE Id =: applicationId LIMIT 1].Record_Type_Name__c;
        }catch(Exception error){
            String exError = JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );    
            return exError;
        }
    }
    
    @AuraEnabled
    public static Map<String,String> getSelectedDocumentSubType(String documentRecordId){ 
        Map<String,String> mapOfAllObject = new  Map<String,String>();
        String name = '';
        String label = '';
        if(String.isNotBlank(documentRecordId)){
            List<Document__c> documentList = [SELECT Id,Document_Checklist__r.Document_Subtype__c FROM Document__c where Document_Checklist__c != null AND Id =: documentRecordId AND Document_Checklist__r.Document_Subtype__c != null];
            if(documentList != null && documentList.size() > 0){
                if(documentList[0].Document_Checklist__r.Document_Subtype__c.contains(';')){
                    for(String str : documentList[0].Document_Checklist__r.Document_Subtype__c.split(';')){
                        system.debug('str-> ' + str);
                        mapOfAllObject.put(str,str);
                    }
                    system.debug('mapOfAllObject-> ' + mapOfAllObject);
                    RETURN mapOfAllObject;
                }else{
                    name = documentList[0].Document_Checklist__r.Document_Subtype__c;
                    label = documentList[0].Document_Checklist__r.Document_Subtype__c;
                    mapOfAllObject.put(name,label);
                    RETURN mapOfAllObject;
                }
            }
        }
        RETURN null;
    }
    
    @AuraEnabled
    public static string getDisbursementId(string applicationId) {
        system.debug('applicationId===>'+applicationId);
        // Query the Disbursement__c record
        Disbursement__c disbursement = [SELECT Id, Name FROM Disbursement__c WHERE Loan_Application__c = :applicationId ORDER BY CreatedDate LIMIT 1];
        system.debug('disbursement.Id==>'+disbursement.Id);
        // Return the Id of the Disbursement__c record
        return disbursement.Id;
    }
    
    
    /**
* @description getCurrentLoggedInUserProfile
* @return String- Profile Name
* @Author : Mohit Saxena 01 August, 2024
*/
    @AuraEnabled
    public static String getCurrentLoggedInUserProfile(){
        Id profileId=userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        return profileName;
    } 
    
    public class ResponseWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String responseBody;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Boolean irReadOnly;
    }
}