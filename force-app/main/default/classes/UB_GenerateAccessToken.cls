/**
* @File Name          : UB_GenerateAccessToken.cls
* @Description        : Method will generate Access token for Callout API.
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         28-03-2024            Zafaruddin         Initial Version
*/
public class UB_GenerateAccessToken {
    
    UB_HTTPCalloutService service;
    

    public static String getToken(String metaData){ 
        UB_GenerateAccessToken tokenApi = new UB_GenerateAccessToken();
        tokenApi.service = new UB_HTTPCalloutService(metaData);
        try {
            if(tokenApi.service!= NULL &&  tokenApi.service.calloutMetadata!= NULL && tokenApi.service.calloutMetadata.Active__c) {
                HTTPResponse res = tokenApi.service.sendRequest();
                System.debug('TOKEN END POINT  '+tokenApi.service.getEndpointURL());
                object obj = JSON.deserializeUntyped(res.getBody());
                map<string,object> resMap= (Map<String, object>)obj;
                String access_token = (String)resMap.get('access_token');
                system.debug('TOKENNNNNNNNNNN  '+access_token);
                return access_token;
            }
        }catch(Exception e) { 
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        return null;
    }

    /*
    @AuraEnabled
    public static ConfigurationDetail getSecurityToken(String metaData){ 
        UB_GenerateAccessToken tokenApi = new UB_GenerateAccessToken();
        tokenApi.service = new UB_HTTPCalloutService(metaData);
        try {
            if(tokenApi.service!= NULL &&  tokenApi.service.calloutMetadata!= NULL && tokenApi.service.calloutMetadata.Active__c) {
                HTTPResponse res = tokenApi.service.sendRequest();
                System.debug('TOKEN END POINT  '+tokenApi.service.getEndpointURL());
                object obj = JSON.deserializeUntyped(res.getBody());
                map<string,object> resMap= (Map<String, object>)obj;
                ConfigurationDetail configObj = new ConfigurationDetail();
                configObj.endPointUrl = 'https://apiuat.utkarsh.bank/aadhar/v1.0.0/kyc';
                configObj.accessToken = (String)resMap.get('access_token');
                system.debug('TOKENNNNNNNNNNN  '+(String)resMap.get('access_token'));
                return configObj;
            }
        }catch(Exception e) { 
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        return null;
    } 



    public class configurationDetail{
        @AuraEnabled
        public String accessToken = '';
        @AuraEnabled
        public String endPointUrl = '';
    } */

}