/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-29-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class UB_GenericRecordEditFormController {

    @AuraEnabled
    public static List<Form_Section> getSectionAndFields(String objectName){
        Map<String, Map<Decimal, Section_Field__mdt>> fieldMap = new Map<String, Map<Decimal, Section_Field__mdt>>();
        Map<String, List<Section_Field__mdt>> sectionFieldMap = new Map<String, List<Section_Field__mdt>>();
        List<Section_Field__mdt> sectionFieldList = [Select Id,Label, Form_Section__c, Form_Section__r.DeveloperName, Sort_Order_Number__c, DeveloperName, Field_API_Name__c, Show_Filter_Condition__c, is_Required__c, is_Ready_Only__c,Data_Type__c From Section_Field__mdt WHERE Form_Section__r.Object_Name__c  =:objectName Order By Sort_Order_Number__c];
        List<Form_Section__mdt> formSectionList = [Select Id, Sort_Order_Number__c, MasterLabel, DeveloperName, Show_Form_Condition__c From Form_Section__mdt Where Object_Name__c =:objectName Order by Sort_Order_Number__c];
        for(Section_Field__mdt secField : sectionFieldList){
            if(sectionFieldMap != null && sectionFieldMap.containsKey(secField.Form_Section__r.DeveloperName)){
                sectionFieldMap.get(secField.Form_Section__r.DeveloperName).add(secField);
            }else{
                sectionFieldMap.put(secField.Form_Section__r.DeveloperName, new List<Section_Field__mdt>{secField});
            }
        }
		system.debug('sectionFieldMap :'+sectionFieldMap);
        List<Form_Section> formSectionFinalList = new List<Form_Section>();
        for(Form_Section__mdt formSec : formSectionList){
            Form_Section wrap = new Form_Section();
            wrap.formSection = formSec;
            wrap.sectionField = sectionFieldMap.get(formSec.DeveloperName);
            formSectionFinalList.add(wrap);
        }
        system.debug('formSectionFinalList :'+formSectionFinalList);
        return formSectionFinalList;
    }
	
    @AuraEnabled
    public static Account getCustomerRecordData(String recordId){
       /* commented for deployment if(recordId != null && recordId !=''){
            Account acc = [Select id, Name, RecordTypeId, RecordType.Name from Account where Id =: recordId ];
            return acc;
        } */
        return null;
    }
    
    public class Form_Section{
        @AuraEnabled public Form_Section__mdt formSection;
        @AuraEnabled public List<Section_Field__mdt> sectionField;
    }

}