public class UB_LoanApplicantsController {
	@AuraEnabled
    public static List<Account> getCustomerDetail(String name, String mobileNo, String kycDocType, String kycDocValue){
        List<Account> accountList = new List<Account>();
        String orOperator = '';
        try{
            if(String.isNotBlank(name) || String.isNotBlank(mobileNo) || (String.isNotBlank(kycDocType) && String.isNotBlank(kycDocValue))){
                String query = 'SELECT Id, Name, Pan_Number__c, Mobile__c FROM Account WHERE ';
                if(String.isNotBlank(name)){
                    name ='\'%' + name  + '%\'';
                    //query += ' Name =: name';
                    //query += ' Name LIKE ' + name + ' OR FirstName LIKE ' + name + ' OR LastName LIKE ' + name + ' OR MiddleName LIKE '+ name;
                    query += ' Name LIKE ' + name ;
                    orOperator = ' OR ';
                }if(String.isNotBlank(kycDocType) && kycDocType == 'PAN Number' && String.isNotBlank(kycDocValue)){
                    query += orOperator + ' Pan_Number__c =: kycDocValue';
                    orOperator = ' OR ';
                }if(String.isNotBlank(mobileNo)){
                    query += orOperator + ' Mobile__c =: mobileNo';
                    //orOperator = ' OR '; 
                }
                accountList = Database.query(query);
                System.debug('**Query=> '+ accountList);
            }
        }catch(Exception ex){
            System.debug('Exception getCustomerDetail => '+ ex.getMessage());
        }
        RETURN accountList;
    }
}