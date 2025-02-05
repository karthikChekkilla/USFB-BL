/**
* @File Name          : UB_Vahan_API.cls
* @Description        : API to check Vehicle status for customer.
* @Author             : Mohit
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-05-2024               Mohit                 Initial Version
*/
public class UB_Vahan_API {
    
    UB_HTTPCalloutService service;
    
    @AuraEnabled
    public static Vehicle__c fetchVahanDetails (Id loanApplicationId, String registrationNumber){
        //Savepoint sp = Database.setSavepoint();
        try{
            List<Verification__c> insertRecords = new List<Verification__c>();
            List<API_Logger__c> createLogList = new List<API_Logger__c>();
            
            UB_Vahan_API vahanStatusCheck = new UB_Vahan_API();
            vahanStatusCheck.service = new UB_HTTPCalloutService('Vahan_API');
            
            String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API');
            
            if(String.isNotBlank(accessToken)){
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('registrationNumber',String.isNotBlank(registrationNumber) ? registrationNumber : '');
                gen.writeStringField('consent','Y');
                gen.writeNumberField('version',3.1);
                gen.writeFieldName('clientData');
                gen.writeStartObject();
                gen.writeStringField('caseId',loanApplicationId);
                gen.writeEndObject();
                gen.writeEndObject();
                
                vahanStatusCheck.service.setHeaderParameter('Authorization','Bearer '+accessToken);
                vahanStatusCheck.service.setRequestBody(gen.getAsString());        
                HttpResponse response = vahanStatusCheck.service.sendRequest(); 
                Map<String,Object> mapResponseResult = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                Vehicle__c vehicle = new Vehicle__c();
                if(response.getStatusCode() == 200){
                    if(mapResponseResult.containsKey('result')){
                        Map<String,Object> mapResultBody = (Map<String,Object>) (mapResponseResult.get('result'));
                        if(mapResultBody.keySet().size() > 0){
                            if(mapResultBody.containsKey('makerDescription')){
                                vehicle.Make__c = typeCastObjectToString(mapResultBody.get('makerDescription'));
                            }
                            if(mapResultBody.containsKey('makerModel')){
                                vehicle.Model__c = typeCastObjectToString(mapResultBody.get('makerModel'));
                            }
                            if(mapResultBody.containsKey('fuelDescription')){
                                vehicle.Fuel_Type__c = typeCastObjectToString(mapResultBody.get('fuelDescription'));
                            }
                            if(mapResultBody.containsKey('chassisNumber')){
                                vehicle.Chassis_Number__c = typeCastObjectToString(mapResultBody.get('chassisNumber'));
                            }
                            if(mapResultBody.containsKey('normsDescription')){
                                vehicle.Vehicle_Pollution_Norm_Description__c = typeCastObjectToString(mapResultBody.get('normsDescription'));
                            }
                            if(mapResultBody.containsKey('engineNumber')){
                                vehicle.Engine_Number__c = typeCastObjectToString(mapResultBody.get('engineNumber'));
                            }
                            if(mapResultBody.containsKey('bodyTypeDescription')){
                                vehicle.Body_Type__c = typeCastObjectToString(mapResultBody.get('bodyTypeDescription'));
                            }
                            if(mapResultBody.containsKey('blackListInfo')){
                                vehicle.Blacklist_Info__c = typeCastObjectToString(mapResultBody.get('blackListInfo'));
                            }
                            if(mapResultBody.containsKey('blackListStatus')){
                                vehicle.Blacklist_Status__c = typeCastObjectToString(mapResultBody.get('blackListStatus'));
                            }
                            if(mapResultBody.containsKey('ownerName')){
                                vehicle.Owner_Name__c = typeCastObjectToString(mapResultBody.get('ownerName'));
                            }
                            if(mapResultBody.containsKey('fatherName')){
                                vehicle.Father_Name__c = typeCastObjectToString(mapResultBody.get('fatherName'));
                            }
                            if(mapResultBody.containsKey('manufacturedMonthYear')){
                                vehicle.Manufactured_Month_Year__c = typeCastObjectToString(mapResultBody.get('manufacturedMonthYear'));
                            }
                            if(mapResultBody.containsKey('registrationDate')){
                                vehicle.Date_of_Registration__c = typeCastObjectToDate(mapResultBody.get('registrationDate'));
                            }
                            if(mapResultBody.containsKey('chassisNumber')){
                                vehicle.Chassis_Number__c = typeCastObjectToString(mapResultBody.get('chassisNumber'));
                            }
                            if(mapResultBody.containsKey('engineNumber')){
                                vehicle.Engine_Number__c = typeCastObjectToString(mapResultBody.get('engineNumber'));
                            }
                            if(mapResultBody.containsKey('registeredAt')){
                                vehicle.RTO_Name__c = typeCastObjectToString(mapResultBody.get('registeredAt'));
                            }
                            if(mapResultBody.containsKey('stateCd')){
                                vehicle.State_Code__c = typeCastObjectToString(mapResultBody.get('stateCd'));
                            }
                            if(mapResultBody.containsKey('ownerSerialNumber')){
                                vehicle.Owner_Serial_Number__c = typeCastObjectToString(mapResultBody.get('ownerSerialNumber'));
                            }
                            if(mapResultBody.containsKey('financier')){
                                vehicle.Financer__c = typeCastObjectToString(mapResultBody.get('financier'));
                            }
                            if(mapResultBody.containsKey('nocDetails')){
                                vehicle.NOC_Details__c = typeCastObjectToString(mapResultBody.get('nocDetails'));
                            }
                            if(mapResultBody.containsKey('normsDescription')){
                                vehicle.Vehicle_Pollution_Norm_Description__c = typeCastObjectToString(mapResultBody.get('normsDescription'));
                            }
                            if(mapResultBody.containsKey('nationalPermitExpiryDate')){
                                vehicle.National_Permit_Expiry_Date__c = typeCastObjectToDate(mapResultBody.get('nationalPermitExpiryDate'));
                            }
                            if(mapResultBody.containsKey('nationalPermitIssuedBy')){
                                vehicle.National_Permit_Issued_By__c = typeCastObjectToString(mapResultBody.get('nationalPermitIssuedBy'));
                            }
                            if(mapResultBody.containsKey('nationalPermitNumber')){
                                vehicle.National_Permit_Number__c = typeCastObjectToString(mapResultBody.get('nationalPermitNumber'));
                            }
                            if(mapResultBody.containsKey('statePermitType')){
                                vehicle.State_Permit_Type__c = typeCastObjectToString(mapResultBody.get('statePermitType'));
                            }
                            if(mapResultBody.containsKey('statePermitNumber')){
                                vehicle.State_Permit_Number__c = typeCastObjectToString(mapResultBody.get('statePermitNumber'));
                            }
                            if(mapResultBody.containsKey('statePermitIssuedDate')){
                                vehicle.State_Permit_Issue_Date__c = typeCastObjectToDate(mapResultBody.get('statePermitIssuedDate'));
                            }
                            if(mapResultBody.containsKey('statePermitExpiryDate')){
                                vehicle.State_Permit_Expiry_Date__c = typeCastObjectToDate(mapResultBody.get('statePermitExpiryDate'));
                            }
                            if(mapResultBody.containsKey('taxPaidUpto')){
                                vehicle.Tax_Paid_Upto__c = typeCastObjectToString(mapResultBody.get('taxPaidUpto'));
                            }
                            if(mapResultBody.containsKey('pucNumber')){
                                vehicle.PUC_Serial_Number__c = typeCastObjectToString(mapResultBody.get('pucNumber'));
                            }
                            if(mapResultBody.containsKey('pucExpiryDate')){
                                vehicle.PUC_Expiry_Date__c = typeCastObjectToDate(mapResultBody.get('pucExpiryDate'));
                            }
                            if(mapResultBody.containsKey('fitnessUpto')){
                                vehicle.Fitness_Validity__c = typeCastObjectToDate(mapResultBody.get('fitnessUpto'));
                            }
                            if(mapResultBody.containsKey('insuranceCompany')){
                                vehicle.Insurance_Company__c = typeCastObjectToString(mapResultBody.get('insuranceCompany'));
                            }
                            if(mapResultBody.containsKey('insuranceUpto')){
                                vehicle.Insurance_Expiry_Date__c = typeCastObjectToDate(mapResultBody.get('insuranceUpto'));
                            }
                            if(mapResultBody.containsKey('insurancePolicyNumber')){
                                vehicle.Policy_Number__c = typeCastObjectToString(mapResultBody.get('insurancePolicyNumber'));
                            }
                            if(mapResultBody.containsKey('rcMobileNo')){
                                vehicle.RC_Mobile_Number__c = typeCastObjectToString(mapResultBody.get('rcMobileNo'));
                            }
                            if(mapResultBody.containsKey('rcStatus')){
                                vehicle.RC_Status__c = typeCastObjectToString(mapResultBody.get('rcStatus'));
                            }
                        }
                    }
                }
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    vahanStatusCheck.service.getEndpointURL(), 
                    String.valueOf(vahanStatusCheck.service.getHeaderParameters()), 
                    vahanStatusCheck.service.getRequestMethod(), 
                    gen.getAsString(), 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_Vahan_API.class.getName(), 
                    loanApplicationId, 
                    Id.valueOf(loanApplicationId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'Vahan API',
                    UB_ConstantsUtil.LOB_CV
                );
                if(mapResponseResult.containsKey('status')){
                    apiLogger.Status__c = (String) String.valueOf(mapResponseResult.get('status'));
                }
                createLogList.add(apiLogger);
                
                if(!createLogList.isEmpty() && createLogList.size() > 0){
                    UB_API_LoggerUtility.insertRecords(createLogList);
                } 
                System.debug(vehicle);
                return vehicle;
            } return null;
       }catch(Exception e) {
            //Database.rollback(sp);
            //Database.releaseSavepoint(sp);
            System.debug('Exception@@'+e.getMessage());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            return null;
        }
    }
    
    public static String typeCastObjectToString(Object obj){
        return obj != null ? (String) String.valueOf(obj) : '';
    }
    
    public static Date typeCastObjectToDate(Object obj){
        if(obj != null){
            String dateStr = (String) String.valueOf(obj);
            List<String> listOfDateStr = dateStr.split('-');
            return Date.newInstance(Integer.valueOf(listOfDateStr[2]),Integer.valueOf(listOfDateStr[1]),Integer.valueOf(listOfDateStr[0]));
        } return null;
    }
}