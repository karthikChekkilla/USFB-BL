/**
* @File Name          : UB_AadharIMageMasking.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         27-05-2024            Zafaruddin         Initial Version

**/
public class UB_AadharIMageMasking {

    UB_HTTPCalloutService service;

    /**
    * @description  function will create Aadhar document and associated maskImage wth it.
    * @author Zafaruddin | 30-05-2024 
    **/

    public static void createAadharMaskDocument(String base64, String documentSubType, String fileName,String documentId){
        System.debug('base64base64base64  '+base64);
        System.debug('documentSubType   '+documentSubType);
        System.debug('fileName   '+fileName);
        System.debug('documentId   '+documentId);
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData =    EncodingUtil.base64Decode(  base64 );
        if(profileName == UB_ConstantsUtil.PORTAL_PROFILE_NAME) {
            cv.NetworkId =  [SELECT NetworkId, MemberId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()].NetworkId;
        }
        Insert cv;

        System.debug('CVVVVVVVVVVVVv  '+cv);

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        System.debug('conDocId   '+conDocId);

        Document__c documentChild = new Document__c();
        documentChild.Parent_Document__c = documentId;
        documentChild.File_Name__c = fileName;
        INSERT documentChild;
        System.debug('documentChild   '+documentChild);

        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = documentChild.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;

        System.debug('ContentDocumentLink  '+cdl);
        
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = cv.Id;
        newDist.Name = fileName;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        insert newDist;

        System.debug('ContentDistribution  '+cdl);

        List<ContentDistribution> distribution = [Select Id, ContentDownloadUrl, 
        DistributionPublicUrl, PdfDownloadUrl FROM
        ContentDistribution where id =: newDist.Id];
        if(!distribution.isEmpty()) {
            documentChild.Document_URL__c = distribution[0].ContentDownloadUrl;
            documentChild.Document_Preview_Url__c = distribution[0].DistributionPublicUrl;
            documentChild.Status__c = 'Uploaded';
            UPDATE documentChild;
        }

        System.debug('updated child document  '+documentChild);
        Document__c parentDoc = new Document__c();
        parentDoc.Id = documentId;
        parentDoc.Status__c = 'Uploaded';
        parentDoc.Document_Sub_Type__c = String.isNotBlank(documentSubType) ? documentSubType : '';
        UPDATE parentDoc;
        System.debug('updated parentDoc document  '+parentDoc);
    } 

    /**
    * @description  Funtion will Call Aadhar Image  Mask APi.
    * @author Zafaruddin | 04-15-2024 
    * @param customerId 
    * @param accessToken 
    **/
   // @future(callout = true)
    @AuraEnabled
    public static Boolean getAadharMaskImage (String base64, String fileName,String documentId){
        System.debug('base64base64base64  '+base64);
        List<Document__c> docList = new UB_DocumentsSelector().selectById(new Set<Id>{documentId});
        System.debug('docList   '+docList);
        docList[0].Document_Sub_Type__c = 'Aadhar Card';
        

        UB_AadharIMageMasking imageMasking = new UB_AadharIMageMasking();
        String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        imageMasking.service = new UB_HTTPCalloutService('Aadhar_Image_Masking');
        imageMasking.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
        Savepoint sp;
        try{
            String RequestJson;
            RequestJson=  '{"maskAadhaarText": "' + imageMasking.service.getExtraParameter('maskAadhaarText') + '",';
            RequestJson+= '"responseType": "' + imageMasking.service.getExtraParameter('responseType') + '",';
            RequestJson+=  '"responseFormat": "' + imageMasking.service.getExtraParameter('responseFormat') + '",';
            RequestJson+=  '"maskAadhaarImage": "' + imageMasking.service.getExtraParameter('maskAadhaarImage') + '",';
            RequestJson+=  '"file": "' + '' + '",';
            RequestJson+=  '"pdfPassword": "' + '' + '",';
            RequestJson+=  '"url": "' + '' + '",';
            RequestJson+=  '"fileBase64": "' + base64 + '"';
            RequestJson+= '}';
            System.debug('RequestJson  '+RequestJson);
            imageMasking.service.setRequestBody(RequestJson);
            HTTPResponse responeObj = new HTTPResponse();
            responeObj = imageMasking.service.sendRequest();
            String JsonResponse = responeObj.getBody();
            System.debug('responeObj   '+responeObj);
            System.debug('RESPONSE BODY     '+responeObj.getBody());
            Map<String,Object> ResponseMap = (Map<String,Object>)JSON.deserializeUntyped(JsonResponse);
            System.debug('ResponseMap  '+ResponseMap);
            System.debug(' statusCode '+ResponseMap.get('statusCode'));
            if(ResponseMap.get('statusCode') == 102) {
                return true;
            }
            if(ResponseMap.get('result') != NULL) {
                ResponseMap = (Map<String,Object>)ResponseMap.get('result');
                System.debug('BASE 6444  '+ResponseMap.get('fileBase64'));
                base64 =  String.valueOf(ResponseMap.get('fileBase64'))   ;
                Blob blobContent = EncodingUtil.base64Decode(  base64 );
                update docList;
                UB_CommonUtil.createDocument(docList[0].Document_Type__c,fileName,blobContent,docList[0].Loan_Application__c, docList[0].Loan_Applicant__c,docList[0].Document_Type__c,'Aadhar Card');
               
               // createAadharMaskDocument( base64 , documentSubType, fileName, documentId);
            }
            
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                imageMasking.service.getEndpointURL(), 
                String.valueOf(imageMasking.service.getHeaderParameters()), 
                imageMasking.service.getRequestMethod(), 
                RequestJson, 
                responeObj.getBody(), 
                responeObj.getStatusCode(), 
                UB_AadharIMageMasking.class.getName(), 
                null, 
                null, 
                UB_ConstantsUtil.REST_API_TYPE,
                'Aadhar Image Masking API',
                UB_ConstantsUtil.LOB_CV
                );
            if(apiLogger != NULL) {
                insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            }


        
        }catch(System.CalloutException e) {
            if(sp != NULL) {
                Database.rollback(sp);
            }
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);            
        }catch(Exception e) {
            if(sp != NULL) {
                Database.rollback(sp);
            }            
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }

        return false;
    }

}