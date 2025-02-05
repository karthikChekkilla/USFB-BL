/**
* @File Name          : UB_VehicleSelectionController.cls
* @Description        : This controller will help to create dynamic picklist values for different vehicle fields.
* @Author             : Mohit
* @Test CLass         : UB_VehicleSelectionController
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         24-04-2024               Mohit                 Initial Version
*/
public class UB_VehicleSelectionController {
    @AuraEnabled
    public static List<PicklistSet> fetchPicklistValues(String vehicleDetails, Id productId){
        VehicleDetails customWrapper = (VehicleDetails) JSON.deserialize(vehicleDetails, VehicleDetails.class);
        system.debug('customWrapper@@'+customWrapper);
        system.debug('productId@@'+productId);
        List<PicklistSet> picklistValues = new List<PicklistSet>();
        Set<String> picklistValueSet = new Set<String>();
        List<Product__c> productList = new UB_ProductsSelector().fetchProductMasterWithId(new Set<Id>{productId});
        system.debug('productList@@'+productList);
        List<Vehicle_Master__c> vehicleList = new List<Vehicle_Master__c>();
        String query = ' SELECT Id, Name, Make__c, Model__c, Vehicle_Type__c, Fuel_Type__c, Body_Type__c ';
        query       += ' FROM Vehicle_Master__c WHERE Active__c = true ';
        if(!productList.isEmpty() && productList.size() > 0){
            if(productList[0].Product__c != null){
                query += ' AND Sub_Product__c = \''+productList[0].Product__r.LOB__c+'\' ';
            }
        }
        if(String.isNotBlank(customWrapper.make) && String.isNotBlank(customWrapper.model)){
			query += ' AND Make__c = \''+customWrapper.make+'\' ';
            query += ' AND Model__c = \''+customWrapper.model+'\' ';
        }else if(String.isNotBlank(customWrapper.make)){
            query += ' AND Make__c = \''+customWrapper.make+'\' ';
        }
        system.debug('query'+query);
        vehicleList = Database.query(query);
        system.debug('vehicleList'+vehicleList);
        system.debug('customWrapper'+customWrapper);
        if(!vehicleList.isEmpty() && vehicleList.size() > 0 && customWrapper != null){
            system.debug('make'+customWrapper.make);
            for(Vehicle_Master__c obj : vehicleList){
                if(String.isBlank(customWrapper.make)){
                    picklistValueSet.add(obj.Make__c);
                }else if(String.isBlank(customWrapper.model)){
                    picklistValueSet.add(obj.Model__c);
                }else if(String.isBlank(customWrapper.type)){
                    if(obj.Vehicle_Type__c != null && String.isNotBlank(obj.Vehicle_Type__c) && obj.Vehicle_Type__c.contains(';')){
                        for(String str : obj.Vehicle_Type__c.split(';')){
                            picklistValueSet.add(str);
                        }
                    }else{
                        picklistValueSet.add(obj.Vehicle_Type__c);
                    }
                }else if(String.isBlank(customWrapper.fuelType)){
                    if(obj.Fuel_Type__c != null && String.isNotBlank(obj.Fuel_Type__c) && obj.Fuel_Type__c.contains(';')){
                        for(String str : obj.Fuel_Type__c.split(';')){
                            picklistValueSet.add(str);
                        }
                    }else{
                        picklistValueSet.add(obj.Fuel_Type__c);
                    }
                }else if(String.isBlank(customWrapper.bodyType)){
                    if(obj.Body_Type__c != null && String.isNotBlank(obj.Body_Type__c) && obj.Body_Type__c.contains(';')){
                        for(String str : obj.Body_Type__c.split(';')){
                            picklistValueSet.add(str);
                        }
                    }else{
                        picklistValueSet.add(obj.Body_Type__c);
                    }
                }
            }
            system.debug('picklistValueSet'+picklistValueSet);
            for(String str : picklistValueSet){
                picklistValues.add(new PicklistSet(str, str));
            }
            return picklistValues;
        }
        return picklistValues;
    }
    
    @AuraEnabled
    public static String fetchVehicleMasterId(String vehicleModel){
        List<Vehicle_Master__c> vehicleMasterList = new List<Vehicle_Master__c>();
        system.debug('vehicleModel > ' + vehicleModel);
        if(String.isNotBlank(vehicleModel)){
            vehicleMasterList = new UB_VehicleMasterSelector().selectByModel(new Set<String>{vehicleModel});
            system.debug('vehicleMasterList > ' + vehicleMasterList);
            if(!vehicleMasterList.isEmpty() && vehicleMasterList.size() > 0){
                return vehicleMasterList[0].Id;
            }
            return null;
        }
        return null;
    }
    
    @AuraEnabled
    public static VehicleDetails fetchVehicleProductInfo(String vehicleId){
        List<Vehicle__c> vehicleList = new UB_VehiclesSelector().selectByIdsWithProductInfo(new Set<Id>{vehicleId});
        if(!vehicleList.isEmpty() && vehicleList.size() > 0){
            VehicleDetails obj = new VehicleDetails();
            if(String.isBlank(obj.make)){
                obj.makeValues = fetchPicklistValues(JSON.serialize(obj), vehicleList[0].Product__c);
                obj.make = String.isNotBlank(vehicleList[0].Make__c) ? vehicleList[0].Make__c : '';
            }
            if(String.isBlank(obj.model)){
                obj.modelValues = fetchPicklistValues(JSON.serialize(obj), vehicleList[0].Product__c);
                obj.model = String.isNotBlank(vehicleList[0].Model__c) ? vehicleList[0].Model__c : '';
            }
            if(String.isBlank(obj.type)){
                obj.vehicleTypeValues = fetchPicklistValues(JSON.serialize(obj), vehicleList[0].Product__c);
                obj.type = String.isNotBlank(vehicleList[0].Vehicle_Type__c) ? vehicleList[0].Vehicle_Type__c : '';
            }
            if(String.isBlank(obj.fuelType)){
                obj.fuelTypeValues = fetchPicklistValues(JSON.serialize(obj), vehicleList[0].Product__c);
                obj.fuelType = String.isNotBlank(vehicleList[0].Fuel_Type__c) ? vehicleList[0].Fuel_Type__c : '';
            }
            if(String.isBlank(obj.bodyType)){
                obj.bodyTypeValues = fetchPicklistValues(JSON.serialize(obj), vehicleList[0].Product__c);
                obj.bodyType = String.isNotBlank(vehicleList[0].Body_Type__c) ? vehicleList[0].Body_Type__c : '';
            }
            obj.productId       = vehicleList[0].Product__c != null ? vehicleList[0].Product__c : null;
            obj.productCategory = String.isNotBlank(vehicleList[0].Product__r.Product_Category__c) ? vehicleList[0].Product__r.Product_Category__c : '';
            system.debug('VehicleObj'+obj);
            return obj;
        }
        return null;
    }
    
	public class PicklistSet {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistSet(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public class VehicleDetails {
        @AuraEnabled public String make { get; set; }
        @AuraEnabled public String model { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String cost { get; set; }
        @AuraEnabled public String tenure { get; set; }
        @AuraEnabled public String roi { get; set; }
        @AuraEnabled public String numberOfVehicles { get; set; }
        @AuraEnabled public String fuelType { get; set; }
        @AuraEnabled public String bodyType { get; set; }
        @AuraEnabled public String productId { get; set; }
        @AuraEnabled public String productCategory { get; set; }
        @AuraEnabled public List<PicklistSet> makeValues { get; set; }
        @AuraEnabled public List<PicklistSet> modelValues { get; set; }
        @AuraEnabled public List<PicklistSet> vehicleTypeValues { get; set; }
        @AuraEnabled public List<PicklistSet> fuelTypeValues { get; set; }
        @AuraEnabled public List<PicklistSet> bodyTypeValues { get; set; }
    }
}