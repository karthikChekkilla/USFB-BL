/**
* @File Name          : UB_GenerateConsentRequestAPI.cls
* @Description        : This class will generate consent API Request dynamically
* @Author             : Mohit
* @Test CLass         : UB_GenerateConsentRequestAPITest
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         20-05-2024               Mohit                 Initial Version
*/
public with sharing class UB_ConsentRequestAPI {
    public static String generateJSON(String request){
        if(String.isNotBlank(request)){
            JSONRequest customWrapper = (JSONRequest) JSON.deserialize(request, JSONRequest.class);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('@VER',customWrapper.VER != null ? customWrapper.VER : '1.2');
            gen.writeFieldName('USER');
            gen.writeStartObject();
            gen.writeStringField('@CH_TYPE',customWrapper.CH_TYPE != null ? customWrapper.CH_TYPE : '4');
            gen.writeStringField('@UNIXTIMESTAMP',customWrapper.UNIXTIMESTAMP != null ? customWrapper.UNIXTIMESTAMP : String.valueOf(System.today()));
            gen.writeEndObject();
            gen.writeFieldName('SMS');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('@UDH',customWrapper.UDH != null ? customWrapper.UDH : '0');
            gen.writeStringField('@CODING',customWrapper.CODING != null ? customWrapper.CODING : '1');
            if(customWrapper.TEXT != null){
                gen.writeStringField('@TEXT',customWrapper.TEXT);
            }
            if(customWrapper.TEMPLATEINFO != null){
                gen.writeStringField('@TEMPLATEINFO',customWrapper.TEMPLATEINFO);
            }
            gen.writeStringField('@PROPERTY',customWrapper.PROPERTY != null ? customWrapper.PROPERTY : '0');
            if(customWrapper.MSGTYPE != null){
                gen.writeStringField('@MSGTYPE',customWrapper.MSGTYPE);
            }
            if(customWrapper.MEDIADATA != null){
                gen.writeStringField('@MEDIADATA',customWrapper.MEDIADATA);
            }
            if(customWrapper.TYPE != null){
                gen.writeStringField('@TYPE',customWrapper.TYPE);
            }
            gen.writeStringField('@ID',customWrapper.ID != null ? customWrapper.ID : '123');
            gen.writeFieldName('ADDRESS');
            gen.writeStartArray();
            gen.writeStartObject();
            if(customWrapper.A_FROM != null){
                gen.writeStringField('@FROM',customWrapper.A_FROM);
            }
            if(customWrapper.A_TO != null){
                gen.writeStringField('@TO',customWrapper.A_TO);
            }
            gen.writeStringField('@SEQ',customWrapper.SEQ != null ? customWrapper.SEQ : '1');
            gen.writeStringField('@TAG',customWrapper.TAG != null ? customWrapper.TAG : 'some clientside random data');
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeEndObject();

            return gen.getAsString();
        }
        return null;
    }

    public class JSONRequest{
        @AuraEnabled public String VER { get; set; }
        @AuraEnabled public String CH_TYPE { get; set; }
        @AuraEnabled public String UNIXTIMESTAMP { get; set; }
        @AuraEnabled public String UDH { get; set; }
        @AuraEnabled public String CODING { get; set; }
        @AuraEnabled public String TEXT { get; set; }
        @AuraEnabled public String TEMPLATEINFO { get; set; }
        @AuraEnabled public String PROPERTY { get; set; }
        @AuraEnabled public String MSGTYPE { get; set; }
        @AuraEnabled public String MEDIADATA { get; set; }
        @AuraEnabled public String TYPE { get; set; }
        @AuraEnabled public String ID { get; set; }
        @AuraEnabled public String ADDRESS { get; set; }
        @AuraEnabled public String A_FROM { get; set; }
        @AuraEnabled public String A_TO { get; set; }
        @AuraEnabled public String SEQ { get; set; }
        @AuraEnabled public String TAG { get; set; }
    }
}