/**
* @File Name          : UB_ProductSelectionController.cls
* @Description        : This controller used to fetch product master info and used in ProductSelectionScreen LWC.
* @Author             : Mohit
* @Test CLass         : UB_ProductSelectionControllerTest
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         24-04-2024               Mohit                 Initial Version
*/
public class UB_ProductSelectionController {
    @AuraEnabled
    public static List<PicklistSet> fetchSubCategoryValues(String productCategory, String productSubCategory){
        List<PicklistSet> picklistValues = new List<PicklistSet>();
        Set<String> picklistValueSet = new Set<String>();
        List<Product_Master__c> productMasterList = new List<Product_Master__c>();
        String query = 'SELECT Id, Product_Sub_Category__c, Product_Schemes__c FROM Product_Master__c ';
        if(String.isNotBlank(productCategory) && String.isNotBlank(productSubCategory)){
            query += ' WHERE Active__c = true AND Product_Category__c = \''+productCategory+'\'';
            query += ' AND Product_Sub_Category__c = \''+productSubCategory+'\'';
        }else if(String.isNotBlank(productCategory) && String.isBlank(productSubCategory)){
            query += ' WHERE Active__c = true AND Product_Category__c = \''+productCategory+'\'';
        }
        productMasterList = Database.query(query);
        
        if(!productMasterList.isEmpty() && productMasterList.size() > 0){
            for(Product_Master__c obj : productMasterList){
                if(String.isBlank(productSubCategory)){
                    picklistValueSet.add(obj.Product_Sub_Category__c);
                }else{
                    picklistValueSet.add(obj.Product_Schemes__c);
                }
            }
            
            for(String str : picklistValueSet){
                picklistValues.add(new PicklistSet(str, str));
            }
            return picklistValues;
        }
        return null;
    }
    
    @AuraEnabled
    public static String checkValidations(String loanApplicationId, String recordId){
        List<Loan_Application__c> loanApplicationList = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanApplicationId});
        List<Product__c> productList = new List<Product__c>();
        String query = ' SELECT Id,Product_Category__c,Product_Sub_Category__c,Product_Schemes__c,Number_Of_Vehicles__c, ';
        query       += ' BL_Applied_Loan_Amount__c, BL_Balance_Transfer_Applicable__c, BL_Index_Rate__c,BL_Interest_Type__c, ';
        query       += ' BL_Loan_Tenure_months__c, BL_Moratorium_Period_Month__c, BL_Purpose_of_Loan__c, BL_Rate_Code__c, ';
        query       += ' BL_Rate_of_Interest__c, BL_Spread__c, Product__r.LOB__c, Product_Vertical__c ';
        query       += ' FROM Product__c ';
        query       += ' WHERE Loan_Application__c = \''+loanApplicationId+'\'';
        if(String.isNotBlank(recordId)){
            query += ' AND Id = \''+recordId+'\'';
        }
        //query       += ' ORDER BY CreatedDate ASC ';
        productList = Database.query(query);
        
        //Added By Mohit on 30-07-24 for BL - <Product can't update after login stage for BL process>
        if(String.isNotBlank(loanApplicationList[0].LOB__c) && loanApplicationList[0].LOB__c == UB_ConstantsUtil.LOB_BL){
            if(loanApplicationList[0].RecordTypeId != UB_ConstantsUtil.LOGIN_LOAN_APPLICATION_RECORD_TYPE){
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ProductScreenValidation');
                return messageConfigMap.get('ProductEditRestriction') != null ? messageConfigMap.get('ProductEditRestriction').Message__c : null;
            }
        }
        
        if(!productList.isEmpty() && productList.size() > 0){
            if(String.isNotBlank(loanApplicationList[0].LOB__c)){
                if(loanApplicationList[0].LOB__c == BL_ConstantsUtil.LOB_BL){
                    if(productList.size() > 0 && String.isBlank(recordId)){
                        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ProductScreenValidation');
                        return messageConfigMap.get('TwoProductValidation') != null ? messageConfigMap.get('TwoProductValidation').Message__c : null;
                    }else if(productList.size() == 1 && String.isNotBlank(recordId)){
                        ProductDetails obj = new ProductDetails();
                        obj.category    			  = productList[0].Product_Category__c;
                        obj.subCategory 			  = productList[0].Product_Sub_Category__c;
                        obj.scheme                    = productList[0].Product_Schemes__c;
                        obj.vertical                  = productList[0].Product_Vertical__c;
                        obj.balanceTransferApplicable = productList[0].BL_Balance_Transfer_Applicable__c;
                        obj.loanAmount                = productList[0].BL_Applied_Loan_Amount__c;
                        obj.indexRate      			  = productList[0].BL_Index_Rate__c;
                        obj.interestType      		  = productList[0].BL_Interest_Type__c;
                        obj.loanTenure      		  = productList[0].BL_Loan_Tenure_months__c;
                        obj.moratoriumPeriod      	  = Integer.valueOf(productList[0].BL_Moratorium_Period_Month__c);
                        obj.loanPurpose      		  = productList[0].BL_Purpose_of_Loan__c;
                        obj.rateCode      			  = productList[0].BL_Rate_Code__c;
                        obj.disableInterest           = productList[0].BL_Interest_Type__c == BL_ConstantsUtil.FLOATING_INTEREST_TYPE ? true : false;
                        obj.rateOfInterest      	  = productList[0].BL_Rate_of_Interest__c;
                        obj.spread      			  = productList[0].BL_Spread__c;
                        obj.lob                       = productList[0].Product__r.LOB__c;
                        return 'recordFound#'+JSON.serialize(obj);
                    }
                }else{
                    if(productList.size() >= 2 && String.isBlank(recordId)){
                        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ProductScreenValidation');
                        return messageConfigMap.get('TwoProductValidation') != null ? messageConfigMap.get('TwoProductValidation').Message__c : null;
                    }else if(productList.size() == 1 || (productList.size() >= 2 && String.isNotBlank(recordId))){
                        ProductDetails obj = new ProductDetails();
                        for(Product__c productObj : productList){
                            if(String.isBlank(recordId)){
                                if(productObj.Product_Category__c.contains('New')){
                                    obj.category = productObj.Product_Category__c.replace('New','Used');
                                }else if(productObj.Product_Category__c.contains('Used')){
                                    obj.category = productObj.Product_Category__c.replace('Used','New');
                                }
                            }else{
                                obj.category = productObj.Product_Category__c;
                            }
                            obj.subCategory     = productObj.Product_Sub_Category__c;
                            obj.scheme          = productObj.Product_Schemes__c;
                            obj.numberOfVehicle = productObj.Number_Of_Vehicles__c != null && productObj.Number_Of_Vehicles__c > 0 ? Integer.valueOf(productObj.Number_Of_Vehicles__c) : 1;
                            obj.lob             = productList[0].Product__r.LOB__c;
                        } return 'recordFound#'+JSON.serialize(obj);
                    }    
                }
            }else{
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ProductScreenValidation');
                return messageConfigMap.get('NoApplicationLOBFound') != null ? messageConfigMap.get('NoApplicationLOBFound').Message__c : null;
            }
        } 
        ProductDetails obj = new ProductDetails();
        obj.category    = BL_ConstantsUtil.BL_PRODUCT_CATEGORY;
        if(String.isNotBlank(loanApplicationList[0].Lead__r.Product_Name__c)){
            obj.subCategory = loanApplicationList[0].Lead__r.Product_Name__c.contains('129') ? BL_ConstantsUtil.BL_PRODUCT_CATEGORY : BL_ConstantsUtil.BUSINESS_LOAN_PLUS_CATEGORY; 
        }else{
            obj.subCategory = BL_ConstantsUtil.BL_PRODUCT_CATEGORY;
        }
        obj.loanTenure  = loanApplicationList[0].Lead__r.Loan_Period__c != null ? loanApplicationList[0].Lead__r.Loan_Period__c : 0;
        obj.loanAmount  = loanApplicationList[0].Lead__r.Amount__c != null ? loanApplicationList[0].Lead__r.Amount__c : 0;
        obj.lob         = loanApplicationList[0].LOB__c;
        return 'Success#'+JSON.serialize(obj);
    }
    
    @AuraEnabled
    public static String createProduct(String recordId, String loanApplicationId, String productDetails){
        if(productDetails != null && String.isNotBlank(productDetails)){
            ProductDetails customObj = (ProductDetails) JSON.deserialize(productDetails, ProductDetails.class);
            List<Product_Master__c> productList = new UB_ProductMastersSelector().filterByCriteria(customObj.category, customObj.subCategory, customObj.scheme);
            if(!productList.isEmpty() && productList.size() > 0){
                Product__c createProduct = new Product__c();
                createProduct.Name                  = productList[0].Name;
                createProduct.Loan_Application__c   = loanApplicationId;
                createProduct.Product__c            = productList[0].Id;
                if(productList[0].LOB__c != UB_ConstantsUtil.LOB_BL){
                    createProduct.Number_Of_Vehicles__c = customObj.numberOfVehicle != null && customObj.numberOfVehicle > 0 ? customObj.numberOfVehicle : 1;
                }
                if(productList[0].LOB__c == UB_ConstantsUtil.LOB_BL){
                    createProduct.Product_Vertical__c               = customObj.vertical;
                    createProduct.BL_Balance_Transfer_Applicable__c = String.isNotBlank(customObj.balanceTransferApplicable) ? customObj.balanceTransferApplicable : '';              
                    createProduct.BL_Applied_Loan_Amount__c         = customObj.loanAmount != null && customObj.loanAmount > 0 ? customObj.loanAmount : 0;
                    createProduct.BL_Index_Rate__c                  = customObj.indexRate != null && customObj.indexRate > 0 ? customObj.indexRate : 0;          
                    createProduct.BL_Interest_Type__c 			    = String.isNotBlank(customObj.interestType) ? customObj.interestType : '';          
                    createProduct.BL_Loan_Tenure_months__c 			= customObj.loanTenure != null && customObj.loanTenure > 0 ? customObj.loanTenure : 0;
                    createProduct.BL_Moratorium_Period_Month__c 	= customObj.moratoriumPeriod != null && customObj.moratoriumPeriod > 0 ? customObj.moratoriumPeriod : 0;
                    createProduct.BL_Purpose_of_Loan__c				= String.isNotBlank(customObj.loanPurpose) ? customObj.loanPurpose : '';          
                    createProduct.BL_Rate_Code__c					= String.isNotBlank(customObj.rateCode) ? customObj.rateCode : '';          
                    createProduct.BL_Rate_of_Interest__c 			= customObj.rateOfInterest != null && customObj.rateOfInterest > 0 ? customObj.rateOfInterest : 0;
                    createProduct.BL_Spread__c 						= customObj.spread != null && customObj.spread > 0 ? customObj.spread : 0;
                }
                
                // Set up the unit of work
                fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{Product__c.sObjectType});
                uow.registerNew(new List<Product__c>{createProduct});
                
                if(String.isNotBlank(recordId)){
                    uow.registerDeleted(new List<Product__c>{new Product__c(Id = recordId)});
                }
                // Commit all of the work at a safe moment
                uow.commitWork();
                
                List<Product__c> existingProductList = new UB_ProductsSelector().selectByLoanApplicationIds(new Set<Id>{loanApplicationId});
                Loan_Application__c updateObj = new Loan_Application__c(Id = loanApplicationId);
                updateObj.LOB__c = String.isNotBlank(productList[0].LOB__c) ? productList[0].LOB__c : '';
                if(productList[0].LOB__c != UB_ConstantsUtil.LOB_BL){
                    updateObj.CB_Customer_Category__c = String.isNotBlank(customObj.scheme) ? customObj.scheme : '';
                    if(!existingProductList.isEmpty() && existingProductList.size() > 1){
                        updateObj.Application_Type__c = UB_ConstantsUtil.NEW_USED_CATEGORY;
                    }else{
                        updateObj.Application_Type__c = productList[0].Product_Category__c.contains(UB_ConstantsUtil.NEW_CATEGORY) ? UB_ConstantsUtil.NEW_CATEGORY : UB_ConstantsUtil.USED_CATEGORY;
                    }
                    if(String.isNotBlank(productList[0].LOB__c)){
                        if(productList[0].LOB__c == UB_ConstantsUtil.LOB_CV){
                            updateObj.Product__c = UB_ConstantsUtil.COMMERCIAL_VEHICLE_LOAN;
                        }else if(productList[0].LOB__c == UB_ConstantsUtil.LOB_CE){
                            updateObj.Product__c = UB_ConstantsUtil.CONSTRUCTION_EQUIPMENT_LOAN;
                        }
                    }
                }
                // Set up the unit of work
                fflib_ISObjectUnitOfWork uowApp = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{Loan_Application__c.sObjectType});
                uowApp.registerDirty(updateObj);
                // Commit all of the work at a safe moment
                uowApp.commitWork();
                return 'Success';
            }else{
                Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ProductScreenValidation');
                return messageConfigMap.get('NoProductMasterRecordFound') != null ? messageConfigMap.get('NoProductMasterRecordFound').Message__c : null;
            }
        } return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Decimal> fetchProductRateCodes(String productDetails){
        ProductDetails customObj = (ProductDetails) JSON.deserialize(productDetails, ProductDetails.class);
        List<Product_Master__c> productList = new UB_ProductMastersSelector().filterByCriteria(customObj.category, customObj.subCategory, customObj.scheme);
        if(!productList.isEmpty() && productList.size() > 0){
            String query = ' SELECT Id,BL_Rate_Code__c,BL_Product_Master__c,BL_Is_Active__c,BL_Effective_Date__c,BL_Index_Rate__c ';
            query       += ' FROM BL_Rate_Code_Master__c ';
            query       += ' WHERE BL_Product_Master__c = \''+productList[0].Id+'\' AND ';
            query       += ' BL_Effective_Date__c != null AND BL_Is_Active__c = true ';
            query       += ' ORDER BY BL_Effective_Date__c DESC ';
            List<BL_Rate_Code_Master__c> rateCodeList = Database.query(query);
            if(!rateCodeList.isEmpty() && rateCodeList.size() > 0){
                Set<String> rateCodeSet = new Set<String>();
                Map<String,Decimal> mapCodeWithIndexRate = new Map<String,Decimal>();
                for(BL_Rate_Code_Master__c obj : rateCodeList){
                    rateCodeSet.add(obj.BL_Rate_Code__c);
                    if(!mapCodeWithIndexRate.containsKey(obj.BL_Rate_Code__c)){
                        mapCodeWithIndexRate.put(obj.BL_Rate_Code__c, obj.BL_Index_Rate__c);
                    }
                }
                return mapCodeWithIndexRate;
            }
        }
        return null;
    }
    
     @AuraEnabled(cacheable=true)
    public static String fetchInterestRange(String productDetails){
        ProductDetails customObj = (ProductDetails) JSON.deserialize(productDetails, ProductDetails.class);
        List<Product_Master__c> productList = new UB_ProductMastersSelector().filterByCriteria(customObj.category, customObj.subCategory, customObj.scheme);
        if(!productList.isEmpty() && productList.size() > 0){
            return productList[0].BL_Minimum_ROI__c+'#'+productList[0].BL_Maximum_ROI__c;
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PicklistSet> fetchDropdownValues(String objectApiName, String fieldApiName){
        List<PicklistSet> options = new List<PicklistSet>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().get(fieldApiName).getDescribe();

        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(new PicklistSet(entry.getValue(), entry.getLabel()));
        }
        return options;
    }
    
    public class PicklistSet {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        
        public PicklistSet(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
    
    public class ProductDetails {
        @AuraEnabled public String  category { get; set; }
        @AuraEnabled public String  subCategory { get; set; }
        @AuraEnabled public String  scheme { get; set; }
        @AuraEnabled public String  vertical { get; set; }
        @AuraEnabled public String  balanceTransferApplicable { get; set; }
        @AuraEnabled public String  loanPurpose { get; set; } 
		@AuraEnabled public String  interestType { get; set; } 
        @AuraEnabled public String  rateCode { get; set; }
        @AuraEnabled public String  lob { get; set; } 
        @AuraEnabled public Integer numberOfVehicle { get; set; }
        @AuraEnabled public Integer moratoriumPeriod { get; set; }
        @AuraEnabled public Decimal indexRate { get; set; }
        @AuraEnabled public Decimal loanAmount { get; set; }
        @AuraEnabled public Decimal loanTenure { get; set; }
        @AuraEnabled public Decimal spread { get; set; } 
        @AuraEnabled public Decimal rateOfInterest { get; set; }
        @AuraEnabled public Boolean disableInterest { get; set; } 
    }
}