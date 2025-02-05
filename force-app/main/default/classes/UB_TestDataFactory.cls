/**
* @File Name          : UB_TestDataFactory.cls
* @Description        : Factory class to create test data
* @Author             : Karthik Chekkilla
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         14-03-2024            Karthik Chekkilla         Initial Version
*/
@isTest
public class UB_TestDataFactory {
    /**
     * @Description :
     * @Author      :
     * @Date        :
    */
    public static Lead createLead(){
        Lead objLead = new Lead();
        objLead.FirstName='test_data';
        objLead.LastName='test_purpose';
        return objLead;
    }
    
    public static Product__c createProduct(){
        Product__c prodRec = new Product__c();
        prodRec.Active_Status__c = 'Y';
        prodRec.Product_Code__c = '123456789';
        prodRec.Name = 'test Product';
        RETURN prodRec;
    }
}