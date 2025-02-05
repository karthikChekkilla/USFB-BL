public class UB_Valuationdetails {
     @AuraEnabled
    public static String getValuationDetail(String parentId, String valuationType){
         List<Valuation__c > valustionList = new List<Valuation__c>();
        try{
        
        if(parentId != null && valuationType == 'Residence FI' || valuationType == 'Office FI'  || valuationType == 'Permanent FI'){
             valustionList = [SELECT Id FROM Valuation__c where Loan_Applicant__c = :parentId Order By CreatedDate Desc LIMIT 1 ];
           system.debug('valustionList1> ' + valustionList );
            
        } else if(parentId != null && valuationType == 'Property Valuation' || valuationType == 'Legal'){
             valustionList = [SELECT Id FROM Valuation__c where Collateral__c = :parentId Order By CreatedDate Desc LIMIT 1 ];
            system.debug('valustionList2> ' + valustionList );
           
        }else if(parentId != null && valuationType == 'Vehicle Valuation'){
            valustionList = [SELECT Id FROM Valuation__c where Vehicle__c = :parentId Order By CreatedDate Desc LIMIT 1 ];
           system.debug('valustionList3> ' + valustionList );
           
        }
        if(!valustionList.isEmpty()){
            return  valustionList[0].Id;
        }
      return null; 
    }
    
    Catch(Exception error){
        String errors =  JSON.serialize(error.getMessage() + error.getLineNumber() + error.getStackTraceString() );
        return errors;
    }
      
    }
}