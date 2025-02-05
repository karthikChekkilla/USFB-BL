/*
*@description       : 
*@author            : ChangeMeIn@UserSettingsUnder.SFDoc
*@group             : 
*@last modified on  : 07-01-2024
*@last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
*/
public class BL_LAF_Pdf_Helper {
    public String loanId{get;set;}
    public Loan_Applicant__c primeApplicant{get;set;}
    public FormWrapper wrapper{get;set;}
    public Loan_Application__c loanApplication{get;set;}
    public Address__c primeAppCorresAddress{get;set;}
    public Address__c primeAppOfficeAddress{get;set;}
    public Reference_Member__c contactPersonDetails{get;set;}
    public List<Loan_Applicant__c> coApplicantIndividualList{get;set;}
    public List<Loan_Applicant__c> coApplicantNonIndividualList{get;set;}
    public List<Loan_Applicant__c> gaurantorIndividualList{get;set;}
    public List<Loan_Applicant__c> gaurantorNonIndividualList{get;set;}
    public List<Loan_Applicant__c> loanApplicantsList{get;set;}
    public List<Address__c> primeApplicantAddressList{get;set;}    
    public List<Reference_Member__c> applicantReferenceMemberList{get;set;}
    public List<Reference_Member__c> tradeReferencerList{get;set;}
    public List<Bank_Details__c> bankDetail{get;set;}
    public List<Verification__c >verifications{get;set;}
    public List<Verification_Line_Item__c> verificationLineItemList{get;set;}
    public Map<Id,String> applicantPhotoMap {get;set;}
    public BL_LAF_Pdf_Helper(ApexPages.StandardController controller) {
    }
    public void getPDF()
    {
        try {
            wrapper = new FormWrapper();
            loanId = apexpages.currentPage().getParameters().get('Id');
            Set<Id> applicantIdsSet = new Set<Id>();
            coApplicantIndividualList = new List<Loan_Applicant__c>();
            coApplicantNonIndividualList = new List<Loan_Applicant__c>();
            gaurantorIndividualList=new List<Loan_Applicant__c>();
            gaurantorNonIndividualList=new List<Loan_Applicant__c>();
            loanApplicantsList = new List<Loan_Applicant__c>();
            primeApplicantAddressList = new  List<Address__c>();
            bankDetail = new  List<Bank_Details__c>();
            applicantReferenceMemberList = new List<Reference_Member__c>();
            contactPersonDetails = new Reference_Member__c();
            tradeReferencerList = new List<Reference_Member__c>();
            verifications = new  List<Verification__c >();
            verificationLineItemList = new List<Verification_Line_Item__c>(); 
            if(String.isnotBlank(loanId)) {
                loanApplication = [SELECT Id,Name,Amount__c ,BL_Repayment_Mode__c ,Loan_Period__c,CreatedDate,
                                   Branch__r.Name, Branch__r.Branch_Code__c,Product__c,Lead__r.Branch__r.Name,
                                   Application_Type__c,PSL_Non_PSL__c,PSL_Category__c,Sub_Category__c,
                                   Details__c,Moratorium_Period_Month__c,Subsub_category__c,
                                   (SELECT ID, Product__c,BL_Applied_Loan_Amount__c,Product__r.Product_Code__c,
                                    BL_Interest_Type__c,BL_Loan_Tenure_months__c,BL_Purpose_of_Loan__c
                                    FROM Products__r),
                                   (SELECT Id,Type__c,Date_of_birth__c,Type_of_Profession__c, Reference_Address__c,
                                    First_Name__c,Middle_Name__c,Last_Name__c,Nationality__c,Designation__c,
                                    KYC_Document_Type__c,Identification_Number__c,Member_Name__c,Mobile__c,
                                    KYC_Document_Type_Name__c,Pincode__r.name,Pincode_Name__c,RecordTypeId,
                                    BL_Relationship_with_Applicant__c
                                    FROM Reference_Members__r )
                                   FROM Loan_Application__c WHERE Id=:loanId AND LOB__c =: BL_ConstantsUtil.LOB_BL];
                
                //Added by Mohit on August 27th, 2024 (Starts)
                if(loanApplication.Reference_Members__r.size() > 0){
                    for(Reference_Member__c obj : loanApplication.Reference_Members__r){
                        if(obj.RecordTypeId == UB_ConstantsUtil.TRADE_REFERENCE_RECORD_TYPE){
                            tradeReferencerList.add(obj);
                        }else{
                            applicantReferenceMemberList.add(obj);
                            if(obj.Type__c == BL_ConstantsUtil.AUTHORISED_SIGNATORY_TYPE){
                                contactPersonDetails = obj;
                            }
                        }
                    }
                }
                //Added by Mohit on August 27th, 2024 (Ends)
                
                List<Loan_Applicant__c> loanApplicantList = [SELECT Id,Applicant_Type__c,Nationality__c ,BL_Whether_MSME_unit_is_ZED_rated__c,BL_Gradation_obtained_by_MSME__c,BL_Purpose_of_Loan__c ,
                                                             Record_Type_Name__c,Account_Name__c,Annual_Turnover__c,Gross_Annual_Turnover__c,No_of_Years_in_current_business__c,No_of_Years_in_previous_business__c,
                                                             Udyam_Verification__c,BL_Udyam_Registration_Application_Date__c,BL_Udyam_available__c,BL_Type_of_Enterprise__c,Type_Of_Profession__c,Is_Related_Party__c,Entity_Name__c,Date_Of_Incorporation__c,Registration_Number__c,Constitution__c,Maiden_Name__c,Beneficiery_of_GST_Benefit__c,GST_Registration_Number__c
                                                             ,BL_Relationship_with_Applicant__c,Place_Of_Birth__c,Telephone__c,Mobile__c,Name_of_the_Bank__c,Official_Email_ID__c,Name_of_the_Director_Senior_Officer__c,Relationship_with_Director_Senior_Offic__c,Name_of_the_Director__c,
                                                             Address_Type__c,Proof_of_Address__c,Pan_Number__c,Education__c,Residential_Status__c,Date_of_Birth__c,Gender__c,Marital_Status__c,
                                                             Category__c,Religion__c,Mother_Name__c,Father_Spouse_Name__c,Date_of_birth_of_Spouse__c ,Pan_Number_Spouse__c,BL_Business_Type__c,BL_IEC_Importer_Exporter_Code__c,
                                                             Identification_Number__c,KYC_Document_Type__c,KYC_Document_Type_Name__c ,Occupation_Type__c,Email__c,Company_Name__c,BL_Weaker_Section__c,
                                                             Employer_Detail__c,Employee_ID__c,Designation__c, Name_of_Previous_Organisation__c,Type_Of_Profession_Name__c,Politically_Exposed_Person__c,BL_Business_Activity__c,
                                                             Nature_of_Business__c, Net_Annual_Income__c,Income_from_other_sources__c,Income_from_Agriculture__c,BL_URC__c,
                                                             Gross_Annual_Income__c,Industry_Type__c,Department__c,No_of_years_at_current_job__c,BL_Proof_of_Identity__c,
                                                             Total_Work_Experience__c,Last_Name__c,First_Name__c,Middle_Name__c,RecordTypeId,CIF__c,BL_SSI_TIN_Registration_Number__c,
                                                             BL_Women_Owned_Buisness__c,BL_Shareholding_of_Women__c,BL_Women_as__c,BL_Women_Involved_Actively_In_Business__c,
                                                             BL_PSL_Category__c,BL_PSL_Sub_Category__c,BL_Sub_Sub_Category__c,BL_Sub_Industry__c,
                                                             (SELECT Id,Address_Type__c,Loan_Applicant__c,Name,Address_Line_2__c,Address_Line_3__c,Landmark__c ,
                                                              Floor__c,District__c,Pincode__r.Name,Residence_is__c ,Residence_Type__c ,Sector_Localty__c,City__c,
                                                              State__c,Other__c,BL_Under_Residence_Status__c,Country__c,Is_Communication__c,BL_Accomodation_Type__c	
                                                              FROM Addresses__r ORDER BY Address_Type__c DESC),
                                                             (SELECT Id,Type__c,Date_of_birth__c,Type_of_Profession__c, Reference_Address__c,
                                                              First_Name__c,Middle_Name__c,Last_Name__c,Nationality__c,Designation__c,
                                                              KYC_Document_Type__c,Identification_Number__c,Member_Name__c,Mobile__c 
                                                              FROM Reference_Members__r ),
                                                             (SELECT ID,BL_Balance_Tenure_Months__c,BL_Consider_for_Obligation__c,
                                                              BL_Current_Outstanding__c,BL_Loan_Amount__c,BL_Monthly_Installment__c,
                                                              BL_Name_of_Lending_Institution__c,BL_Purpose_of_Loan__c,BL_ROI__c,
                                                              BL_Tenure_Months__c
                                                              From Verification_Line_Items__r 
                                                              WHERE RecordTypeId =: BL_ConstantsUtil.CIBIL_OBLIGATION_VERIFY_LINE_ITEM_RECORD_TYPE)
                                                             FROM Loan_Applicant__c WHERE  Is_Deleted__c = 'No' AND Loan_Application__c =:loanId];
                loanApplicantsList = loanApplicantList;                 
                for(Loan_Applicant__c applicant : loanApplicantList){
                    if(applicant.Applicant_Type__c == BL_ConstantsUtil.APPLICANT){
                        primeApplicant = applicant;
                        //Added by Mohit on August 27th, 2024 (Starts)
                        if(applicant.Addresses__r.size() > 0){
                            for(Address__c address : applicant.Addresses__r){
                                primeApplicantAddressList.add(address);
                                if(address.Is_Communication__c == UB_ConstantsUtil.YES){
                                    primeAppCorresAddress = address;
                                }
                                if(address.Address_Type__c == BL_ConstantsUtil.OFFICE_ADDRESS){
                                    primeAppOfficeAddress = address;
                                }
                            }
                        }
                        
                        if(applicant.Verification_Line_Items__r.size() > 0){
                            verificationLineItemList = applicant.Verification_Line_Items__r;
                        }
                        //Added by Mohit on August 27th, 2024 (Ends)
                    } 
                    if(applicant.Applicant_Type__c == BL_ConstantsUtil.BL_CO_APPLICANT && applicant.Record_Type_Name__c==BL_ConstantsUtil.BL_INDIVIDUAL){
                        coApplicantIndividualList.add(applicant);
                    }
                    if(applicant.Applicant_Type__c == BL_ConstantsUtil.BL_CO_APPLICANT && applicant.Record_Type_Name__c==BL_ConstantsUtil.BL_NON_INDIVIDUAL){
                        coApplicantNonIndividualList.add(applicant);
                    }
                    if(applicant.Applicant_Type__c == BL_ConstantsUtil.BL_GAURANTOR && applicant.Record_Type_Name__c==BL_ConstantsUtil.BL_INDIVIDUAL){
                        gaurantorIndividualList.add(applicant);
                    }
                    if(applicant.Applicant_Type__c == BL_ConstantsUtil.BL_GAURANTOR && applicant.Record_Type_Name__c==BL_ConstantsUtil.BL_NON_INDIVIDUAL){
                        gaurantorNonIndividualList.add(applicant);
                    }
                }
                
                bankDetail = [SELECT Id,Account_Number__c,Account_Holder_Name__c,Account_Type__c,Active_Since__c,Bank_Name__c,Branch_Name__c,IFSC_Code__c,Loan_Application__c,
                              Loan_Application__r.Name,Name,RecordTypeId,RecordType.Name,Is_Primary_Repayment_Account__c FROM Bank_Details__c WHERE Loan_Application__c =: loanId AND RecordTypeId =: BL_ConstantsUtil.REPAYMENT_BANKING_DETAILS_RECORD_TYPE AND Is_Primary_Repayment_Account__c = true ];
                //wrapper variables
                if(primeApplicant != null && primeApplicant.Record_Type_Name__c == BL_ConstantsUtil.BL_INDIVIDUAL) {
                    wrapper.isApplicantIndividual = true;
                }
                if(primeApplicant != null && primeApplicant.Record_Type_Name__c == BL_ConstantsUtil.BL_NON_INDIVIDUAL) {
                    wrapper.isApplicantNonIndividual = true;
                }
                if(coApplicantIndividualList != null) {
                    wrapper.iscoApplicantIndividual = true;
                }
                if(gaurantorIndividualList != null) {
                    wrapper.isGaurantorIndividual = true;
                }
                if(bankDetail != null) {
                    wrapper.isBankDetailList = true;
                }
            }
        }catch(Exception e){
            System.debug('Exception--->'+e.getMessage());
            System.debug('ERROR LINE NUMBER--->'+e.getLineNumber());
            // call method to create ExceptionLogRecord
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_BL);
        }
    }
    
    public class FormWrapper {
        public Boolean isApplicantIndividual{get;set;}
        public Boolean isApplicantNonIndividual{get;set;}
        public Boolean isApplicantTrustee{get;set;}
        public String identificationNumber{get;set;}
        public Boolean isApplicantPermamentAdd{get;set;}
        public Boolean isApplicantCurrentAdd{get;set;}
        public Boolean isApplicantOfficeAdd{get;set;}
        public Boolean iscoApplicantIndividual{get;set;}
        public Boolean iscoApplicantGaurantorNonIndividual{get;set;}
        public Boolean isGaurantorIndividual{get;set;}
        public Boolean isGaurantorNonIndividual{get;set;}
        public Boolean isApplicationTradeReference{get;set;}
        public String product{get;set;}
        public String customerCategory{get;set;}
        public Boolean isTradeReference{get;set;}
        public Boolean isBankDetailList{get;set;}
        public Boolean isVerification{get;set;}
    }
}