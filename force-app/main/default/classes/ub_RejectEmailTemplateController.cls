global class ub_RejectEmailTemplateController {
    public List<Loan_Application__c> loanAppliocationDetail { get; set; }
    public List<Address__c> addressDetail { get; set; }
    public List<Product__c> productDetail { get; set; }
    public Loan_Applicant__c applicantDetail { get; set; }
    public Id loanApplicationId { get; set; }
    public List<Loan_Application__c> getLoanDetails() {
        System.debug('loanApplicationId>> ' + this.loanApplicationId);
        if (this.loanApplicationId != null && String.isNotEmpty(this.loanApplicationId)){
            loanAppliocationDetail = [SELECT Id, Name,Lead__r.CreatedDate,Reject_Sub_Reason__c,Reject_Reason__c, 
                                      (SELECT Id, Name,Applicant_Name__c,Applicant_Type__c FROM Loan_Applicants__r WHERE Applicant_Type__c = 'Applicant' ), 
                                      (SELECT Id, Product_Category__c FROM Products__r LIMIT 1) 
                                      FROM Loan_Application__c 
                                      WHERE Id =:this.loanApplicationId];
            if(!loanAppliocationDetail[0].Loan_Applicants__r.isEmpty()){
                 applicantDetail = loanAppliocationDetail[0].Loan_Applicants__r[0];
            }else{
                applicantDetail = new Loan_Applicant__c();
            }
             if(!loanAppliocationDetail[0].Products__r.isEmpty()){
                 productDetail = loanAppliocationDetail[0].Products__r;
            }
               addressDetail =[SELECT id,Pincode__r.Name,Name,Address_Line_2__c,Address_Line_3__c,Is_Communication__c,City__c,State__c,Country__c from Address__c where Loan_Applicant__c = :loanAppliocationDetail[0].Loan_Applicants__r[0].Id AND Is_Communication__c = 'Yes' LIMIT 1];
            System.debug('AddressDetail>> ' + AddressDetail);
            return loanAppliocationDetail;
        }
        return null;
    }
    public List<Loan_Application__c> getLoanAppDetails() {
        return  loanAppliocationDetail;
    }
    public List<Address__c> getAddressDetail() {
        return  addressDetail ;
    }
    public Loan_Applicant__c getApplicantDetail() {
        return  applicantDetail ;
    }
     public List<Product__c>  getProductDetail() {
        return  productDetail ;
    }
}