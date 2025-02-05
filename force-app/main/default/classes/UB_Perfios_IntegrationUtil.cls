/**
* @File Name          : Perfios_IntegrationUtil
* @Description        : Utility class for Perfios Integration
* @Author             : Chandan Kumar
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class UB_Perfios_IntegrationUtil {
    
    public static UB_HTTPCalloutService service;
    static String privateKey =
        'MIIJKAIBAAKCAgEAjOWSI60gsLzppylwYkzrwsJA6P7zAyitZAxkbAgHUvvpZFe2\r\n'
        + 'l4F4pCGkbIsYgFKktDswSwCMOE+CylrEaK2+INclkFF1ubi3Hr2ldKjz6qiyfipZ\r\n'
        + 'MI6ITYRiNop7t9odrVl/BWS0DYpb+0OupG/n+lJEatBJXiT+W7q3Q9SnsSDRa2wO\r\n'
        + 'y8y1A0cN7ggKVPmfWkvY6tTAic8rjJJKHBfuSBqZKAwOVxT/aUmpGJFfBT8aAu/B\r\n'
        + 'iHuic+148zo4kbl65cm8YC+fM3Qw/4JOZFJrQkD7vDgc1UT1J+iFFoiHYu5Mnumt\r\n'
        + 'ft/M2J6mcptt/EJ3i/ZC7H5Oiu9C2/JnCKDNcPbl1Atgj+hDIi+cHR3IoB+xeqP9\r\n'
        + 'Dvo4owv0zHgMb85PkUwWYAy+CGN0tqp7w6eUV8vLXPut8BWIsPuM8VygzHEWQCI6\r\n'
        + 'NmYGCZQwELhvgWUkZqLuypN27Rhm1ZeVESa8Wa5ycbonZ+wYDpFwPXtsFWZ2FOYe\r\n'
        + 'iqZl8sVBYqaK0gdHP2d/N11kuLX8FB5I0g/efhiLCbe+FCIaQ+hIG10AAub5zwec\r\n'
        + 'Giddi8Bdxl2j+E/a5sxaDONcd+Zacy2MFHANQqsjBgzfV5xLgDLLViNr1S4Mxbq0\r\n'
        + 'fiiHlVF8kNhB+SN1ZUAEJ31z+MuoPNO8l4Y0SSwOwkq2h9jnr+JWYpBi1esCAwEA\r\n'
        + 'AQKCAgAmy2tCsX/HyixXn5xXJLDhrlTrEo/c9c1QN+1KpadGnSA1RcV7z+Vk4/J/\r\n'
        + 'BImZg6fgDFAOxrbVJmdvyjA8VmJ8bmDkbNmKaqbZKwSsq3yFxy9md8iZCxXSqjnU\r\n'
        + 'pKrOA5uaSIMl/AVrmQYcmBU1J67rCM3Xz0P0TSFQJoghgCMwLUYcWuN0EAhjP6RB\r\n'
        + 'PyuBHD5ZQXsXpb7h8w4dpYYMWDZ+2fwDv9YO+jQdTG/n2Ncd/bLuzg8uwkQHwYJF\r\n'
        + 'DmnXDggdzz80CMjABSUcpUdqbhskYfouaBDgVB1ggLBsdOk6Pz0PoG3p+jtQBdb0\r\n'
        + 'xYEyLSb3fbYNofWEYb66CvN9t7D5Gf8daMxLW6GDvf894T0w54Hl60jfq1qJt4ai\r\n'
        + 'ij5zQlSjYNwd8L10Ni59y15z7lojNN+FiEgZ8sL5hYfNK9SPOUhJlgKIZFo72RWQ\r\n'
        + 'n0pHN21lA6r2MEvgBNufDS6aE9x+A9yZ2qWnq+GaIVv+w+VWzG9uosF4INxaqiD9\r\n'
        + 'Xssonc1Xjb4EBBWQlMmWMkJI1bGz2VgE+OMX2514ISfAP6/j6oEvaIn1se1dtGRg\r\n'
        + 'oUR4Ba1KJG73jfcRa8HZpLMCqc00rclv32pRw17lvNFzMDCuR4JPW9Q+/ZbB6kFv\r\n'
        + 'ADra48KxNExXSPB89tiydEzPZ46DBAqKjxHYjFDhs+uKRjQ0EQKCAQEAxvSyZ5F6\r\n'
        + 'gH4OsjNPq8JDmdMFhv4X3xJZrO5ykd8AyNzIrJ+WqkAjekQwTpFr+irDMZCBrXO6\r\n'
        + 'xN/5pH2fcLMrTPnI+nL3Y8eGKAkwjN51IobK9YkaDb+xlBRODO6T0uHgJCirEQAu\r\n'
        + 'mYuaHqK/4HBGEm8IooCAzriR1FZJX7BxF6PYdvgTziNTfZKeuIZnLoT2bymHZhpR\r\n'
        + 'dtPMG9h8ZndTswqRx5lHIJ0EHziVQ9nZ9sTuRpTxtmvqPdMn+oCUVGOzNdb39Wfp\r\n'
        + 'RnplcClF/bzYcRCU8Nra+J2X0tSMINc10K8uMdCfwmr4EBI5WlpfoLAmv9hLf+I+\r\n'
        + 'l0s+7K2Y8f0c6QKCAQEAtUtaeSdPD7bl9RMsSo5pDdoRVdEdQ+QXF6kSg1pI+btI\r\n'
        + 'OcfPX6J35A7jbReQy8kJBNGgs+/62nhkXmdsioo8fP+Gvg6SSWHDvZ7bcrNNPV9A\r\n'
        + 'RWw+8INDDchv1px0sgf81WX4GRudWH0wlF3lVyth5RHULmR4YYmMtu2EgNrtFmzr\r\n'
        + 'f9k9t/Lyh5X6EwBTwZP1HJ8spXuEJvNk2bPL+KyVHzwP0FPiVeKKadu7gwLjzBRI\r\n'
        + '/mX77/EkytQGM4+AxwpLBXm2fZR/Q7Dihyx4DlzEsqYX0VxMzm0censADcYcHAiU\r\n'
        + 'yZnAblvlvqtYn4OPuLcvObp2mWWXosUkjXRD9GtHswKCAQEAk/nb13w0iO05MQFI\r\n'
        + '+I78iKSTL9w9FQUo/Z48SJJ8mujbuMjZ3rblrEKbS1SN4vt7QpogWUoCV/veSaHF\r\n'
        + 'vKUGR7Jg8SYhKm10MsLjAWNT6+Ilgon+fstc4K5ZfvTTrb2iYEJ/OZ3RCxLyBmc2\r\n'
        + 'H1BiTcOXwIWjSB2vGSc0W593/gU3MwVAdcmAh51NwCD3DXqHcBaLRj286YyN+wgB\r\n'
        + 'PpTyA/CQjMxMQs2GC1KiclzN6OR/9K9DOFL7XhB3Y7HOoRWmbRz+P+CReIIAgHOy\r\n'
        + 'Qw76TN3waVPeGZvdGEpODv8CX7xrt1FcAdZdulZTogglp/ZcW8QcI3m64/xrSM21\r\n'
        + 'PAbuQQKCAQAZEiWd0YDOdIWSgadDXDRM9RYmnveEFvvWiswDnC2xU2Pmkaos2IPp\r\n'
        + '5uEuie69L7zujKrDl3FCWxnOMFFDS2CYDKIukEdMnJd8FobUctVAonZ540FE83IH\r\n'
        + 'auuEazh8Ejy1qhdIKZh1z0IzklSP3HD6Q5/rFnvLSUFLXsdPJndY/ZEHqhwt3wwJ\r\n'
        + 'EgV2MTpj77kazyxWaiFZXZlZvdJ8PimVGzI4phELvXtUrk1dDb5Az6FUhPf1M4zZ\r\n'
        + '+74rzTGK1PKQ/EbvUOTUkJaTCORFYDDXX761diUs+svQaEgWn4ntmoYw5vFEkbLQ\r\n'
        + 'zlNAI+pxKev++LlD91ej681lPmnTWC6fAoIBAF1jccui63BcgxhkHqwhkel+sDPi\r\n'
        + 'FVYzGeMnYeLG1oN75rZQ8AZkuIrFh7N7npADKqlQEe2oca0fDuiT1N75ZwcSXvH6\r\n'
        + 'SJQRa7pg2z1GG5w19ElB4yW7RthufYoDeAUma05gmDvlZgG8l4/3mmfZ9ZMBpHep\r\n'
        + 'LAtnJFWxjaXb3GZiPa3w2b0CiUbmmwpRAgSmjRXyHeFeosM5gWhiZE27HyItDPyL\r\n'
        + 'oEy9Il4ZoY9dCtCBbQ2SR12rIRdlRmTZL5uNnjcoX6toZjUnFaVIFy1g/YbanNJY\r\n'
        + 'U2vD3g9grcuk6ag7rd99Kpne6Vr62cnbmj4IYpeNiSDSYKNpGpnyS7SLvE8=';
    
    public static String host = 'demo.perfios.com'; //System.Label.Perfios_Host;
    public static String perfiosDate = Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    public static String algorithm = 'PERFIOS1-RSA-SHA256';
    
    public static string generateTransactionTkn(String processType){
        String prefix, tokenToReturn;
        if(('CREDIT_CARD').EqualsIgnoreCase(processType)){
            prefix = 'TXNCC';    
        }else if(('SALARY_SLIP').EqualsIgnoreCase(processType)){
            prefix = 'TXNSS';     
        }else if(('STATEMENT').EqualsIgnoreCase(processType)){
            prefix = 'TXNBS';     
        }else if(('CREDIT_BUREAU').EqualsIgnoreCase(processType)){
            prefix = 'TXNCB';     
        }else if(('CAM').EqualsIgnoreCase(processType)){
            prefix = 'TXNCAM';     
        }
        Integer randomTkn = Integer.valueof((Math.random() * 999999));
        tokenToReturn = prefix+randomTkn;
        system.debug('Transaction Token: \n'+tokenToReturn);
        return tokenToReturn;
    }
    public static string getProcessFileSuffix(String processType){
        String suffix;
        if(('CREDIT_CARD').EqualsIgnoreCase(processType)){
            suffix = '/credit-card-statements';    
        }else if(('SALARY_SLIP').EqualsIgnoreCase(processType)){
            suffix = '/salary-slips';     
        }else if(('STATEMENT').EqualsIgnoreCase(processType)){
            suffix = '/bank-statements';     
        }else if(('CREDIT_BUREAU').EqualsIgnoreCase(processType)){
            suffix = '/credit-bureau-statements';     
        } 
        return suffix;
    } 
    public static AuthPayload createCanonicalRequest(string method, string path, string payload, string fileType){ 
        AuthPayload cPayload = new AuthPayload();
        system.debug('payload: \n '+payload);
        String payloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));
        
        //Changes to generate the signature dynamically.
        String canonicalRequest = '';        
        String canonicalUri = path; 
        
        string canonicalHeaders= 'host:' + host + '\n' 
            + 'x-perfios-content-sha256:' + payloadHash + '\n' 
            + 'x-perfios-date:' + perfiosDate;
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        
        if(method == 'GET'){
            String canonicalQueryString = fileType.contains(',') ? ('types='+fileType).replace(',','2c') : ('types='+fileType);            
                canonicalRequest = method + '\n' 
                + canonicalUri + '\n'  
                + canonicalQueryString + '\n' 
                + canonicalHeaders + '\n' 
                + signedHeaders + '\n' 
                + payloadHash;
        }else{           
            String canonicalQueryString = '';
            canonicalRequest = method + '\n' 
                + canonicalUri + '\n'  
                + canonicalQueryString + '\n' 
                + canonicalHeaders + '\n' 
                + signedHeaders + '\n' 
                + payloadHash;
        }     
        
        System.debug('canonicalRequest: \n'+canonicalRequest);        
        String stringToSign = algorithm + '\n' +  perfiosDate + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(canonicalRequest)));
        System.debug('stringToSign: \n'+stringToSign);
        
        String Checksum = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(StringToSign))) ; 
        System.debug('Checksum: \n'+Checksum);        
        
        system.debug('privateKey perfios>> '+privateKey);        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        String signature = EncodingUtil.convertToHex(Crypto.sign('RSA-SHA256', Blob.valueOf(Checksum), privateKeyBlob)).toLowerCase();
        
        System.debug('Updated signature: \n'+signature);
        cPayload.signature = signature;
        cPayload.perfdate = perfiosDate;
        cPayload.payloadHash = payloadHash;
        return cPayload;        
    } 
    public static HTTPResponse initiateTransaction(String payload){
        HTTPResponse res = new HTTPResponse();
        try{
            service = new UB_HTTPCalloutService('Perfios_Initiate_Transaction_API');
            String method = service.getRequestMethod();
            String endpoint = service.getEndpointURL();
            
            HTTP http = new HTTP();
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            service.setHeaderParameter('Authorization','Bearer '+accessToken);
            if(service.getHeaderParameters().get('PartnerID') != null){
                service.setHeaderParameter('PartnerID', service.getHeaderParameters().get('PartnerID'));
            }
            if(service.getHeaderParameters().get('Connection') != null){
                service.setHeaderParameter('Connection',service.getHeaderParameters().get('Connection'));   
            }
            service.setRequestBody(payload);
            res = service.sendRequest();
            system.debug('response====>'+res);
            System.debug('UTIL: Response: \n'+res.getStatusCode()+'---'+res.getBody());
        }Catch(Exception e){
            System.debug('Error hai :'+e.getMessage());
            System.debug('In Line Number :'+e.getLineNumber());            
        }
        return res;
    }   
    
    public static HTTPResponse uploadFiles(String transactionId, String fileName, ContentVersion doc, String customerDocId) {
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        HTTPResponse res = new HTTPResponse();
        
        try {
            // Initialize the HTTP callout service with the specified service name
            service = new UB_HTTPCalloutService('Perfios_Upload_Files');
            String method = service.getRequestMethod();  
            
            // Construct the endpoint URL and path for the API request
            String endpoint = service.getEndpointURL()+transactionId+'/files';
            
            // Get the file content from the ContentVersion object
            Blob body = doc.VersionData;
            // Get the content type for the multipart/form-data request
            String contentType = UB_FormData.GetContentType();
            system.debug('contentType==>'+contentType);
            String form64 = '';
            
            // Add document metadata or properties to the form data
            form64 += UB_FormData.append('key', 'Value');
            form64 += UB_FormData.append('key', 'value');
            
            // Add the document body with file parameter to the form data
            Blob formBlob = UB_FormData.makeBlobWithFile('file', body, doc.title + '.' + doc.filetype, form64);
            
            // Get the content length of the form data
            String contentLength = String.valueOf(formBlob.size());
            
            // Create the canonical request for authentication
            //  AuthPayload cPayload = createCanonicalRequest(method, path, '', '');
            
            // Initialize the HTTP request
            HTTP http = new HTTP();
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint(endpoint);
            req.setMethod(method);        
            req.setTimeout(120000);
            
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            req.setHeader('Authorization','Bearer '+accessToken);
            if(service.getHeaderParameters().get('PartnerID') != null){
                req.setHeader('PartnerID',service.getHeaderParameters().get('PartnerID'));
            }
            if(service.getHeaderParameters().get('Connection') != null){
                req.setHeader('Connection',service.getHeaderParameters().get('Connection'));
            }
            if(service.getHeaderParameters().get('Accept') != null){
                req.setHeader('Accept',service.getHeaderParameters().get('Accept'));
            }
            
            // Set the request headers
            //  req.setHeader('Connection', 'keep-alive');
            req.setHeader('Content-Length', contentLength);
            req.setHeader('Content-Type', contentType);
            //  req.setHeader('cache-control', 'no-cache');
            //  req.setHeader('Accept', 'application/json');
            
            // Set the request body as the form data blob
            req.setBodyAsBlob(formBlob);       
            System.debug('UTIL: Request:' + req);
            
            // Send the HTTP request and get the response
            res = http.send(req);
            
            //Added By Mohit on 11-08-2024 for BL - <Passing Loan Application LOB>
            List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerDocId});
            
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                endpoint, 
                String.valueOf(service?.getHeaderParameters()), 
                method, 
                string.valueof(formBlob), 
                res?.getBody(), 
                res?.getStatusCode(), 
                UB_Perfios_Upload_Files_Integration.class.getName(), 
                customerDocId, 
                Id.valueOf(customerDocId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'UB_Perfios_Upload_Files_Integration',
                String.isNotBlank(loanAppList[0].Loan_Application__r.LOB__c) ? loanAppList[0].Loan_Application__r.LOB__c : UB_ConstantsUtil.LOB_CV
            );
            createLogList.add(apiLogger);
            if (!createLogList.isEmpty()) {
                UB_API_LoggerUtility.insertRecords(createLogList);
            }
            
            
            
            System.debug('UTIL: Response: \n' + res.getStatus() + '---' + res.getBody());
        } catch (Exception e) {
            // Catch any exceptions and log the error message and line number
            System.debug('Error :' + e.getMessage());
            System.debug('In Line Number :' + e.getLineNumber());
        }
        
        // Return the HTTP response
        return res;
    }
    
    
    public static HTTPResponse processFiles(String transactionId, String payload, String processType,string customerDocId){
        HTTPResponse res = new HTTPResponse();
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        string body;
        service = new UB_HTTPCalloutService('Perfios_Process_Files_API');           
        String method = service.getRequestMethod();             
        String endpoint = service.getEndpointURL() +transactionId+'/bank-statements';
        
        try{
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            service.setHeaderParameter('Authorization','Bearer '+accessToken);
            if(service.getHeaderParameters().get('PartnerID') != null){
                service.setHeaderParameter('PartnerID', service.getHeaderParameters().get('PartnerID'));
            }
            if(service.getHeaderParameters().get('Connection') != null){
                service.setHeaderParameter('Connection',service.getHeaderParameters().get('Connection'));   
            }
            if(service.getHeaderParameters().get('Accept') != null){
                service.setHeaderParameter('Accept',service.getHeaderParameters().get('Accept'));   
            }
            if(service.getHeaderParameters().get('Content-Type') != null){
                service.setHeaderParameter('Content-Type',service.getHeaderParameters().get('Content-Type'));   
            }
            // service.setHeaderParameter('PartnerID', 'TCS');
            // service.setHeaderParameter('Connection','keep-alive');
            //  service.setHeaderParameter('Content-Type', 'application/xml');
            // service.setHeaderParameter('Accept','application/xml');
            service.setEndpointURL(endpoint);
            body = '<payload><fileId>'+payload+'</fileId></payload>';//'&lt;payload&gt;&lt;fileId&gt;'+payload+'&lt;/fileId&gt;&lt;/payload&gt;';//'<?xml version="1.0"?><payload><fileId>'+payload+'</fileId></payload>';//<payload><fileId>'+payload+'</fileId></payload>';
            system.debug('payload'+body);
            service.setRequestBody(body);
            system.debug('Request: \n'+service.getRequest());
            res = service.sendRequest();
            System.debug('Response: \n'+res.getStatusCode()+'---'+res.getBody());
        }Catch(Exception e){
            System.debug('Error :'+e.getMessage());
            System.debug('In Line Number :'+e.getLineNumber());
        }
        
        //Added By Mohit on 11-08-2024 for BL - <Passing Loan Application LOB>
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerDocId});
        
        API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
            endpoint, 
            String.valueOf(service?.getHeaderParameters()), 
            method, 
            body, 
            res?.getBody(), 
            res?.getStatusCode(), 
            UB_BANK_STATEMENT_Perfios_Integration.class.getName(), 
            customerDocId, 
            Id.valueOf(customerDocId).getSObjectType().getDescribe().getName(), 
            UB_ConstantsUtil.REST_API_TYPE,
            'UB_Perfios_Process_Files_Integration',
            String.isNotBlank(loanAppList[0].Loan_Application__r.LOB__c) ? loanAppList[0].Loan_Application__r.LOB__c : UB_ConstantsUtil.LOB_CV
        );
        
        createLogList.add(apiLogger);
        if (!createLogList.isEmpty()) {
            UB_API_LoggerUtility.insertRecords(createLogList);
        }
        return res;
    } 
    public static HTTPResponse generateReport(String transactionId,string customerDocumentID){
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        HTTPResponse res = new HTTPResponse();
        service = new UB_HTTPCalloutService('Perfios_Generate_Report_API');           
        String method = service.getRequestMethod();
        String endpoint = service.getEndpointURL()+transactionId+'/reports';
        try{
            String payload = '';  
            
            service.setEndpointURL(endpoint);
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            service.setHeaderParameter('Authorization','Bearer '+accessToken);
            if(service.getHeaderParameters().get('PartnerID') != null){
                service.setHeaderParameter('PartnerID', service.getHeaderParameters().get('PartnerID'));
            }
            if(service.getHeaderParameters().get('Connection') != null){
                service.setHeaderParameter('Connection',service.getHeaderParameters().get('Connection'));   
            }
            // service.setHeaderParameter('PartnerID', 'TCS');
            //service.setHeaderParameter('Connection','keep-alive');
            system.debug('UTIL: Request: \n'+service.getRequest());
            res = service.sendRequest();
            System.debug('UTIL: Response: \n'+res.getStatusCode()+'---'+res.getBody());
        }Catch(Exception e){
            System.debug('Error :'+e.getMessage());
            System.debug('In Line Number :'+e.getLineNumber());
        }
        
        //Added By Mohit on 11-08-2024 for BL - <Passing Loan Application LOB>
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerDocumentID});
        
        //create log on success response
        API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
            endpoint, 
            String.valueOf(service?.getHeaderParameters()), 
            method, 
            '', 
            res?.getBody(), 
            res?.getStatusCode(), 
            UB_Perfios_Generate_Report_Integration.class.getName(), 
            customerDocumentID, 
            Id.valueOf(customerDocumentID).getSObjectType().getDescribe().getName(), 
            UB_ConstantsUtil.REST_API_TYPE,
            'UB_Perfios_Generate_Report_Integration',
            String.isNotBlank(loanAppList[0].Loan_Application__r.LOB__c) ? loanAppList[0].Loan_Application__r.LOB__c : UB_ConstantsUtil.LOB_CV
        );
        createLogList.add(apiLogger);
        if (!createLogList.isEmpty()) {
            UB_API_LoggerUtility.insertRecords(createLogList);
        }
        return res;
    }
    
    public static HTTPResponse retrieveReport(String transactionId, String fileType,string customerDocId){
        //transactionId = 'RN3A1720448347043';
        service = new UB_HTTPCalloutService('Perfios_Retrieve_Report_API');
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        String method = service.getRequestMethod();	
        String endpoint = service.getEndpointURL()+transactionId+'/reports?types='+fileType;
        
        //  Perfios_IntegrationUtil.AuthPayload cPayload = Perfios_IntegrationUtil.createCanonicalRequest(method, path, payload, fileType);
        HTTP http = new HTTP();
        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint(endpoint);
        req1.setMethod(method);
        // req1.setHeader('content-type', 'application/json');
        String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
        req1.setHeader('Authorization','Bearer '+accessToken);
        
        if(service.getHeaderParameters().get('PartnerID') != null){
            req1.setHeader('PartnerID', service.getHeaderParameters().get('PartnerID'));
        }
        if(service.getHeaderParameters().get('content-type') != null){
            req1.setHeader('content-type', service.getHeaderParameters().get('content-type'));
        }
        
        if(service.getHeaderParameters().get('Connection') != null){
            req1.setHeader('Connection',service.getHeaderParameters().get('Connection'));   
        }
        if(service.getHeaderParameters().get('Accept') != null){
            req1.setHeader('Accept',service.getHeaderParameters().get('Accept'));   
        }
        if(service.getHeaderParameters().get('Accept-Encoding') != null){
            req1.setHeader('Accept-Encoding',service.getHeaderParameters().get('Accept-Encoding'));   
        }
        //  req1.setHeader('PartnerID', 'TCS');
        /// req1.setHeader('Connection','keep-alive');
        //req1.setHeader('cache-control', 'no-cache');
        //  req1.setHeader('Accept', 'application/json');
        
        
        /** Additional Headers **/
        // req1.setHeader('Connection', 'keep-alive');
        //  req1.setHeader('Accept-Encoding', 'gzip, deflate, br');    
        
        system.debug('UTIL: Request: \n'+req1);        
        system.debug('Method '+req1.getMethod());
        HTTPResponse res = http.send(req1);
        System.debug('UTIL: Response: \n'+res.getStatus()+'---'+res.getBody());
        
        //Added By Mohit on 11-08-2024 for BL - <Passing Loan Application LOB>
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerDocId});
        
        //create log on success response
        API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
            endpoint, 
            String.valueOf(service?.getHeaderParameters()), 
            method, 
            '', 
            res?.getBody(), 
            res?.getStatusCode(), 
            UB_Perfios_Retrieve_Report_Integration.class.getName(), 
            customerDocId, 
            Id.valueOf(customerDocId).getSObjectType().getDescribe().getName(), 
            UB_ConstantsUtil.REST_API_TYPE,
            'UB_Perfios_Retrieve_Report_Integration',
            String.isNotBlank(loanAppList[0].Loan_Application__r.LOB__c) ? loanAppList[0].Loan_Application__r.LOB__c : UB_ConstantsUtil.LOB_CV
        );
        createLogList.add(apiLogger);
        if (!createLogList.isEmpty()) {
            UB_API_LoggerUtility.insertRecords(createLogList);
        }
        return res;
    }
    public static HTTPResponse getPerfiosSatus(String transactionId,string customerDocId){
       // transactionId = 'RN3A1720448347043';
        List<API_Logger__c> createLogList = new List<API_Logger__c>();
        HTTPResponse res = new HTTPResponse();
        try{
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
            service = new UB_HTTPCalloutService('Perfios_Status');
            String method = service.getRequestMethod();	
            String endpoint = service.getEndpointURL()+'47L81720608945098'+'/status';
            HttpRequest req = new HttpRequest();
            req.setMethod(method);
            req.setEndpoint(endpoint);
            req.setTimeout(12000);
            req.setHeader('Authorization','Bearer '+accessToken);
            
            if(service.getHeaderParameters().get('PartnerID') != null){
                req.setHeader('PartnerID', service.getHeaderParameters().get('PartnerID'));
            }
            if(service.getHeaderParameters().get('Connection') != null){
                req.setHeader('Connection',service.getHeaderParameters().get('Connection'));   
            }
            // req.setHeader('PartnerID', 'TCS');
            //req.setHeader('Connection','keep-alive');
            Http http = new Http();
            try {
                res = http.send(req);
                system.debug('response===>'+res.getBody());
                
                //Added By Mohit on 11-08-2024 for BL - <Passing Loan Application LOB>
                List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{customerDocId});
       
                //create log on success response
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    endpoint, 
                    String.valueOf(service?.getHeaderParameters()), 
                    method, 
                    '', 
                    res?.getBody(), 
                    res?.getStatusCode(), 
                    UB_Perfios_Status.class.getName(), 
                    customerDocId, 
                    Id.valueOf(customerDocId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'UB_Perfios_Status',
                    String.isNotBlank(loanAppList[0].Loan_Application__r.LOB__c) ? loanAppList[0].Loan_Application__r.LOB__c : UB_ConstantsUtil.LOB_CV
                );
                createLogList.add(apiLogger);
                if (!createLogList.isEmpty()) {
                    UB_API_LoggerUtility.insertRecords(createLogList);
                }
            } catch (Exception e) {
                // Handle any exceptions
                System.debug('Callout error: ' + e.getMessage());
                return null;
            }
            return res;
        }catch (Exception e) {
            // Handle any exceptions
            System.debug('Callout error: ' + e.getMessage());
            return null;
        }
    }
    
    public static void saveFile(HTTPResponse res, String verificationId, String fileName, String fileType,String customerDocId,String applicationId){
        String base64 = EncodingUtil.base64Encode(res.getBodyAsBlob());
        
        User guestUser;
        User adminUser;
        if(string.isNotEmpty(verificationId)){
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName+'.'+fileType;
            cv.FirstPublishLocationId = verificationId;
            cv.PathOnClient = fileName+'.'+fileType;
            cv.VersionData = EncodingUtil.base64Decode(base64);
            cv.IsMajorVersion = true;
            
            try {
                insert cv;
                // Retrieve the inserted ContentVersion record to check the owner
                // ContentVersion insertedCv = [SELECT Id, OwnerId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                Document__c document = UB_CommonUtil.createDocumentRecord(applicationId, customerDocId, verificationId);
                document.Document_Type__c = 'Banking Report';
                insert document;
                
                UB_DisplayUBDocumentsController.uploadDocument('', cv.Title, String.valueOf(cv.VersionData), document.Id, cv.Id);
            } catch (DmlException e) {
                System.debug('Error inserting or updating ContentVersion: ' + e.getMessage());
            }                       
        }
    }
    public class AuthPayload{
        public string signature;
        public string perfdate;
        public string payloadHash;
    }
    public class processPayload{
        public payloadParent payload;        
    }
    public class payloadParent{
        public string fileId;
        public string password;
        public string txnId;
        public string loanAmount;
        public string loanDuration;
        public string loanType;
        public string processingType;
        public string yearMonthFrom;
        public string yearMonthTo;
        public string transactionCompleteCallbackUrl;
        public string acceptancePolicy;
        public boolean uploadingScannedStatements;
        public string employmentType;
        public string facility;
        public string sourceSystem;
        public string productType;
        public string employerName;
        public string currency1;
        public string[] dataSources;
        public string[] incomeTaxDocuments;
        public string form26ASDOB;
        public Integer idleUserCallbackTimeoutSeconds;
        public string institutionId;
        public string maxVintageDays;
        public string requireIdleUserCallback;
        public string returnUrl;
        public payloadCompanyNames[] companyNames;
        public payloadSisterCompanyNames[] sisterCompanyNames;
        
        /** Process files - constructor **/
        public payloadParent(string file_id, string pwd){
            this.fileId 	= file_id;
            this.password 	= pwd;
        }
        /** Initiate Transaction - Constructor **/
        public payloadParent(string txn_id, string lAmt, string lDuration, string lType, string prType, string ymFrom, string ymTo, string calbckUrl, string accPolicy, String institutionId){
            this.txnId = txn_id;
            this.loanAmount = lAmt;
            this.loanDuration = lDuration;
            this.loanType = lType;
            this.processingType = prType;
            this.yearMonthFrom = ymFrom;
            this.yearMonthTo = ymTo;
            this.institutionId = institutionId;
            this.transactionCompleteCallbackUrl = calbckUrl;
            this.acceptancePolicy = accPolicy;
        }       
    }
    public class payloadCompanyNames{
        public payloadNamePattern namePattern;
    }
    public class payloadSisterCompanyNames{
        public payloadNamePattern namePattern;
    }
    public class payloadNamePattern{
        public string pattern;
    }
}