/**
* @File Name          : UB_VehicleEquipmentHelper.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         15-04-2024            Zafaruddin         Initial Version

**/

public class UB_VehicleEquipmentHelper {
    
    public String loanId{get;set;}
    public Loan_Applicant__c applicant{get;set;}
    public VehicleEquipmentWrapper wrapper{get;set;}
    public Loan_Application__c loanApplication{get;set;}
    public List<Loan_Applicant__c> coApplicantGaurantorIndividualList{get;set;}
    public List<Loan_Applicant__c> coApplicantGaurantorNonIndividualList{get;set;}
    public List<Address__c> applicantpermamentAddressList{get;set;}
    public List<Address__c> applicantCurrentAddressList{get;set;}
    public List<Address__c> applicantOfficeAddressList{get;set;}
    public List<Reference_Member__c> applicantReferenceMemberList{get;set;}
    public List<Reference_Member__c> applicationReferenceMemberList{get;set;}
    public list<Vehicle__c> applicationVehicle{get;set;}
    public Map<Id,String> applicantPhotoMap {get;set;}
    public List<Bank_Details__c> bankDetailList{get;set;}
    public List<Old_Vehicle_Details__c>oldVehicleDetailList{get;set;}
    public List<Verification__c >verifications{get;set;}
    public List<Vehicle__c> newVehicleList { get; set; }
    public List<Vehicle__c> usedVehicleList { get; set; }
    //public List<String> feelabel {get;set;}
   public String feelabel {get;set;}
    
    public UB_VehicleEquipmentHelper(ApexPages.StandardController controller) {
    }
    public void getPDF()
    {
        try {
           Set<Id> parentDocumentSet = new Set<Id>();
            wrapper = new VehicleEquipmentWrapper();
            applicantPhotoMap = new Map<Id,String>();
            loanId = apexpages.currentPage().getParameters().get('Id');
            //loanId = 'a0ABl000000mSLNMA2';
            System.debug('VALUEEEEEEEEEEEEE  '+loanId);
            Set<Id> applicantIdsSet = new Set<Id>();
            coApplicantGaurantorIndividualList = new List<Loan_Applicant__c>();
            coApplicantGaurantorNonIndividualList = new List<Loan_Applicant__c>();
            applicantReferenceMemberList = new List<Reference_Member__c>();
            applicationReferenceMemberList = new List<Reference_Member__c>();
            applicationVehicle = new list<Vehicle__c>();
            applicantpermamentAddressList = new  List<Address__c>();
            applicantCurrentAddressList = new  List<Address__c>();
            applicantOfficeAddressList = new  List<Address__c>();
            bankDetailList = new  List<Bank_Details__c>();
            oldVehicleDetailList = new  List<Old_Vehicle_Details__c>();
            verifications = new  List<Verification__c >();
            //feelabel = new list<String>();
            system.debug('UB_ConstantsUtil.FEELABEL > '+ UB_ConstantsUtil.FEELABEL);
            feelabel = UB_ConstantsUtil.FEELABEL != null ? UB_ConstantsUtil.FEELABEL : '';
          
            if(String.isnotBlank(loanId)) {
                loanApplication = [SELECT Id,Name,Product__c,Lead__r.Branch__r.Name,Application_Type__c,PSL_Non_PSL__c,PSL_Category__c,Sub_Category__c,Subsub_category__c,Details__c  FROM Loan_Application__c WHERE Id=:loanId];
                system.debug('loanApplication>> '+loanApplication);
                applicationVehicle = [SELECT Id,Loan_Application__c, Product__r.Product_Category__c, Product__r.Product_Schemes__c FROM Vehicle__c  WHERE  Loan_Application__c = :loanId LIMIT 1];
                system.debug('applicationVehicle>> '+applicationVehicle);
                applicant = [SELECT Id,Applicant_Type__c,Telephone__c,Mobile__c,Official_Email_ID__c,Account_Name__c,Account_Number__c,Annual_Turnover__c,Gross_Annual_Turnover__c,No_of_Years_in_current_business__c,No_of_Years_in_previous_business__c,Type_Of_Profession__c,Is_Related_Party__c,Entity_Name__c,Date_Of_Incorporation__c,Registration_Number__c,Constitution__c,Maiden_Name__c,Beneficiery_of_GST_Benefit__c,GST_Registration_Number__c
                             ,Name_of_the_Bank__c,Name_of_the_Director_Senior_Officer__c,Relationship_with_Director_Senior_Offic__c,Name_of_the_Director__c,
                             Address_Type__c,Proof_of_Address__c,Pan_Number__c,Education__c,Residential_Status__c,Date_of_Birth__c,Gender__c,Marital_Status__c,
                             Category__c,Religion__c,Mother_Name__c,Father_Spouse_Name__c,Date_of_birth_of_Spouse__c ,Pan_Number_Spouse__c
                             ,Identification_Number__c,KYC_Document_Type__c,KYC_Document_Type_Name__c ,Occupation_Type__c,Email__c,Company_Name__c,
                             Employer_Detail__c,Employee_ID__c,Designation__c, Name_of_Previous_Organisation__c,Type_Of_Profession_Name__c,
                             Nature_of_Business__c, Net_Annual_Income__c,Income_from_other_sources__c,Income_from_Agriculture__c,
                             Gross_Annual_Income__c,Industry_Type__c,Department__c,No_of_years_at_current_job__c,
                             Total_Work_Experience__c,Last_Name__c,First_Name__c,Middle_Name__c,RecordTypeId 
                             FROM Loan_Applicant__c WHERE Applicant_Type__c = 'Applicant' AND Loan_Application__c =:loanId Limit 1];
                System.debug('applicant>> ' + applicant);
                List<Loan_Applicant__c> loanApplicantList = [SELECT Id,Applicant_Type__c,Account_Name__c,Annual_Turnover__c,Gross_Annual_Turnover__c,No_of_Years_in_current_business__c,No_of_Years_in_previous_business__c,Type_Of_Profession__c,Is_Related_Party__c,Entity_Name__c,Date_Of_Incorporation__c,Registration_Number__c,Constitution__c,Maiden_Name__c,Beneficiery_of_GST_Benefit__c,GST_Registration_Number__c
                                                             ,Name_of_the_Bank__c,Official_Email_ID__c,Name_of_the_Director_Senior_Officer__c,Relationship_with_Director_Senior_Offic__c,Name_of_the_Director__c,
                                                             Address_Type__c,Proof_of_Address__c,Pan_Number__c,Education__c,Residential_Status__c,Date_of_Birth__c,Gender__c,Marital_Status__c,
                                                             Category__c,Religion__c,Mother_Name__c,Father_Spouse_Name__c,Date_of_birth_of_Spouse__c ,Pan_Number_Spouse__c
                                                             ,Identification_Number__c,KYC_Document_Type__c,KYC_Document_Type_Name__c ,Occupation_Type__c,Email__c,Company_Name__c,
                                                             Employer_Detail__c,Employee_ID__c,Designation__c, Name_of_Previous_Organisation__c,Type_Of_Profession_Name__c,
                                                             Nature_of_Business__c, Net_Annual_Income__c,Income_from_other_sources__c,Income_from_Agriculture__c,
                                                             Gross_Annual_Income__c,Industry_Type__c,Department__c,No_of_years_at_current_job__c,
                                                             Total_Work_Experience__c,Last_Name__c,First_Name__c,Middle_Name__c,RecordTypeId,
                                                             (SELECT Id,Address_Type__c,Loan_Applicant__c,Name,Address_Line_2__c,Address_Line_3__c,Landmark__c ,Floor__c,District__c,Pincode__r.Name,Residence_is__c ,Residence_Type__c ,Sector_Localty__c,City__c,State__c  FROM Addresses__r),
                                                             (SELECT Id,Type__c,Date_of_birth__c,Type_of_Profession__c, Address__PostalCode__s,Address__city__s,Address__Street__s ,First_Name__c,Middle_Name__c,Last_Name__c,Nationality__c,Designation__c,KYC_Document_Type__c,Identification_Number__c FROM Reference_Members__r )                            
                                                             FROM Loan_Applicant__c WHERE Applicant_Type__c != 'Applicant' AND Is_Deleted__c = 'No' AND Loan_Application__c =:loanId];
                bankDetailList = [SELECT Id,Account_Number__c,Account_Type__c,Active_Since__c,Bank_Name__c,Branch_Name__c,IFSC_Code__c,Loan_Application__c,
                                  Loan_Application__r.Name,Name,RecordTypeId,RecordType.Name,Is_Primary_Repayment_Account__c FROM Bank_Details__c WHERE Loan_Application__c = :loanId AND RecordType.Name= 'Repayment' AND Is_Primary_Repayment_Account__c = true ];
                System.debug('bankDetailList>> ' + bankDetailList);
                
                oldVehicleDetailList = [SELECT Id,Asset_Make__c,EMI_Amount__c,Financier_Name__c,Free_Fin__c,Loan_Amount__c,Loan_Applicant__c,Loan_Applicant__r.Account_Name__c,Model__c,Name,New_Used__c
                                        ,RC_date_Transfer_Date__c,Relationship__c,
                                        Total_EMI_Paid__c,Vehicle_Regn_No__c FROM Old_Vehicle_Details__c WHERE Loan_Applicant__c = :applicant.Id ];
                System.debug('oldVehicleDetailList>> ' + oldVehicleDetailList);
                verifications = [SELECT Id,CIF__c FROM Verification__c WHERE RecordType.Name = 'Dedupe Check' AND Loan_Applicant__c =:applicant.Id];
                System.debug('verifications>> ' + verifications);
                System.debug('loanApplicantList>> ' + loanApplicantList);
                applicantReferenceMemberList = [SELECT Id,Type__c,Date_of_birth__c,Type_of_Profession__c,
                                                Address__PostalCode__s,Address__city__s,Address__Street__s ,
                                                First_Name__c,Middle_Name__c,Last_Name__c,Nationality__c,Designation__c,KYC_Document_Type__c,Identification_Number__c  FROM Reference_Member__c WHERE Loan_Applicant__c= :applicant.Id];
                System.debug('applicantReferenceMemberList  '+applicantReferenceMemberList);
                applicationReferenceMemberList = [SELECT Id,Type__c,Mobile__c,Pincode__r.name,Date_of_birth__c,Type_of_Profession__c,
                                                  Address__PostalCode__s,Address__city__s,Address__Street__s ,Pincode_Name__c,
                                                  First_Name__c,Middle_Name__c,Last_Name__c,Nationality__c,Designation__c,KYC_Document_Type__c,Identification_Number__c FROM Reference_Member__c WHERE Loan_Application__c= :loanId AND Type__c='Trade References'];
                System.debug('applicationReferenceMemberList  '+applicationReferenceMemberList);
                
                newVehicleList = new UB_VehiclesSelector().selectByLoanApplicationIdforVehicle(loanId,UB_ConstantsUtil.NEW_VEHICLE);
            System.debug('newVehicleList '+newVehicleList);
            usedVehicleList = new UB_VehiclesSelector().selectByLoanApplicationIdforVehicle(loanId,UB_ConstantsUtil.USED_VEHICLE);
            System.debug('usedVehicleList '+usedVehicleList);
                
                
                
                if(!applicantReferenceMemberList.isEmpty()) {
                    wrapper.isApplicantTrustee = true;
                }
                system.debug('00000000000');
                if(!applicationReferenceMemberList.isEmpty()) {
                    wrapper.isApplicationTradeReference = true;
                }
                if(!applicationVehicle.isEmpty()) {
                    wrapper.product = applicationVehicle[0].Product__r.Product_Category__c.contains('CV') ? 'Commercial Vehicle' : 'Commercial Equipment'  ;
                    wrapper.customerCategory = applicationVehicle[0].Product__r.Product_Schemes__c;
                }
                System.debug('1111111111');
                if(applicant != null) {
                    applicantIdsSet.add(applicant.Id);
                    applicantPhotoMap.put(applicant.Id,'0');
                }
                applicantpermamentAddressList = [SELECT Id,Name,Address_Line_2__c,Address_Line_3__c,Landmark__c ,Floor__c,District__c,Pincode__r.Name,Residence_is__c ,Residence_Type__c ,Sector_Localty__c,City__c,State__c  FROM Address__c WHERE Loan_Applicant__c =:applicant.Id AND Address_Type__c='Permanent Address'];
                applicantCurrentAddressList = [SELECT Id,Name,Address_Line_2__c,Address_Line_3__c,Landmark__c ,Floor__c,District__c,Pincode__r.Name,Residence_is__c ,Residence_Type__c ,Sector_Localty__c,City__c,State__c FROM Address__c WHERE Loan_Applicant__c =:applicant.Id AND Address_Type__c='Residence Address'];
                applicantOfficeAddressList = [SELECT Id,Name,Address_Line_2__c,Address_Line_3__c,Landmark__c ,Floor__c,District__c,Pincode__r.Name,Residence_is__c ,Residence_Type__c ,Sector_Localty__c,City__c,State__c FROM Address__c WHERE Loan_Applicant__c =:applicant.Id AND Address_Type__c='Office Address'];
                System.debug('222222222222222');
                for(Loan_Applicant__c loanApplicant : loanApplicantList) {
                    System.debug('loanApplicant  '+loanApplicant);
                    System.debug('loanApplicant.RecordTypeId  '+loanApplicant.RecordTypeId);
                    System.debug('UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE  '+ UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE);
                    if(loanApplicant.RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE ){
                        System.debug('2222222222+++++++++');
                        coApplicantGaurantorIndividualList.add(loanApplicant);
                        applicantIdsSet.add(loanApplicant.Id);
                        applicantPhotoMap.put(loanApplicant.Id,'0');
                    } else {
                        coApplicantGaurantorNonIndividualList.add(loanApplicant);
                        applicantIdsSet.add(loanApplicant.Id);
                        applicantPhotoMap.put(loanApplicant.Id,'0');
                    }
                    System.debug('333333333333  '+loanApplicant);
                }
                System.debug('applicantIdsSet   '+applicantIdsSet);
                if(!applicantIdsSet.isEmpty()) {
                    for(Document__c document : [SELECT Id,Loan_Applicant__c,Document_URL__c FROM Document__c  where Loan_Applicant__c IN :applicantIdsSet AND Document_Type__c='Photo']) {
                        parentDocumentSet.add(document.Id);
                        System.debug('document   '+document);

                    }
                    System.debug('parentDocumentSet  '+parentDocumentSet);
                    if(!parentDocumentSet.isEmpty()) {
                        for(Document__c childDocument : [SELECT Id, parent_document__r.Loan_Applicant__c, Document_URL__c FROM Document__c  where  parent_document__c IN:parentDocumentSet]) {
                            if(childDocument.parent_document__r.Loan_Applicant__c != NULL && childDocument.Document_URL__c != NULL) {
                                applicantPhotoMap.put(childDocument.parent_document__r.Loan_Applicant__c, childDocument.Document_URL__c);
                            }
                        }
                    }
                }
                System.debug('applicantPhotoMap   '+applicantPhotoMap);
                System.debug('coApplicantGaurantorIndividualList   '+coApplicantGaurantorIndividualList);
                System.debug('coApplicantGaurantorNonIndividualList   '+coApplicantGaurantorNonIndividualList);
                if(applicant.KYC_Document_Type__c == 'Others'){
                    wrapper.identificationNumber = applicant.KYC_Document_Type_Name__c + ' '+ applicant.Identification_Number__c;
                }
                if(applicant != null && applicant.RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE) {
                    wrapper.isApplicantIndividual = true;
                } else if( applicant != null && applicant.RecordTypeId == UB_ConstantsUtil.NON_INDIVIDUAL_APPICANT_RECORD_TYPE) {
                    wrapper.isApplicantIndividual = false;
                }
                if(!applicantpermamentAddressList.isEmpty()) {
                    wrapper.isApplicantPermamentAdd = true;
                }
                if(!applicantCurrentAddressList.isEmpty()) {
                    wrapper.isApplicantCurrentAdd = true;
                }
                if(!applicantOfficeAddressList.isEmpty()) {
                    System.debug('applicantOfficeAddressList  '+applicantOfficeAddressList);
                    wrapper.isApplicantOfficeAdd = true;
                }
                if(!coApplicantGaurantorIndividualList.isEmpty()) {
                    wrapper.iscoApplicantGaurantorIndividual = true;
                }
                if(!coApplicantGaurantorNonIndividualList.isEmpty()) {
                    wrapper.iscoApplicantGaurantorNonIndividual = true;
                }
                if(!oldVehicleDetailList.isEmpty()) {
                    wrapper.isOldVehicleDetailList = true;
                }
                if(!bankDetailList.isEmpty()) {
                    wrapper.isBankDetailList = true;
                }
                if(!verifications.isEmpty()) {
                    wrapper.isVerification = true;
                }
                System.debug('loanApplication  '+loanApplication);
                System.debug('applicant  '+applicant);
                System.debug('isApplicantIndividual  '+wrapper.isApplicantIndividual);
                List<Document__c> lafDOcument = [SELECT Id FROM Document__c WHERE Document_Type__c='LAF Form' AND Loan_Application__c =:loanId];
                System.debug('lafDOcument   '+lafDOcument);
                //UB_VehicleEquipmentHelper.linkLoanApplicationFormToDocument(loanId);  
            } 
        } catch(Exception e) {
            System.debug('ERRORRRRRRRRRR    '+e.getMessage());
            System.debug('Line   No'+e.getLineNumber());
        }
    }
    @Future(callout=true)
    public static void linkLoanApplicationFormToDocument(String LAFId) {
        try {
            List<Document__c> lafDOcument = [SELECT Id FROM Document__c WHERE Document_Type__c='LAF Form' AND Loan_Application__c =:LAFId];
            System.debug('lafDOcument   '+lafDOcument);
            if(lafDOcument.isEmpty()) {
                System.debug('LAFId ID v  '+LAFId);
                Blob b ;
                if(LAFId != null ) {
                    PageReference PDf =  Page.CV_VehicleEquipment;
                    PDf.getParameters().put('Id',LAFId);
                    PDf.setRedirect(false);
                    b = PDf.getContentAsPdf();
                    UB_CommonUtil.createDocument('CV Loan Application Form','CV Loan Application Form.PDF', b,LAFId, NULL,'LAF Form','LAF Form - Unsigned');
                }
            } 
        } catch (Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }
     @Future(callout=true)
    public static void linkLoanApplicationFormToDocumentBL(String LAFId) {
        try {
            List<Document__c> lafDOcument = [SELECT Id FROM Document__c WHERE Document_Type__c='BL Form' AND Loan_Application__c =:LAFId];
            System.debug('lafDOcument   '+lafDOcument);
            if(lafDOcument.isEmpty()) {
                System.debug('LAFId ID v  '+LAFId);
                Blob b ;
               /* if(LAFId != null ) {
                    PageReference PDf =  Page.BL_LoanApplicationForm;
                    PDf.getParameters().put('Id',LAFId);
                    PDf.setRedirect(false);
                    b = PDf.getContentAsPdf();
                    UB_CommonUtil.createDocument('BL Loan Application Form','BL Loan Application Form.PDF', b,LAFId, NULL,'BL Form','BL Form - Unsigned');
                }*/
            } 
        } catch (Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }
    @AuraEnabled
    public static String  generateLoanApplicationPDF(String loanId){
        try {
            List<Loan_Applicant__c> loanApplicantList = new List<Loan_Applicant__c>();
            if( String.isnotBlank(loanId)) {
                loanApplicantList = [SELECT Id,Account_Name__c,Loan_Application__r.LOB__c FROM Loan_Applicant__c WHERE Applicant_Type__c = 'Applicant' AND Loan_Application__c =:loanId ];
            }
            System.debug('!loanApplicantList.isEmpty()  '+loanApplicantList);
            if(!loanApplicantList.isEmpty() && loanApplicantList[0].Loan_Application__r.LOB__c == 'BL') {
                UB_VehicleEquipmentHelper.linkLoanApplicationFormToDocumentBL(loanId);
               return 'BL';
            }else if(!loanApplicantList.isEmpty()){
                 UB_VehicleEquipmentHelper.linkLoanApplicationFormToDocument(loanId);
                return 'UB';
            }
           // return !loanApplicantList.isEmpty() ? true : false ;
            
        } catch (Exception e) {
            system.debug('ERRRR  '+e.getMessage());
        }
        return 'none';
    }
    
    public static String createEmailBody(String loanApplicationId){
        Map<String,Loan_Applicant__c> applicantMap = new Map<String,Loan_Applicant__c>();
        List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanApplicationId}); 
        System.debug('**loanAppObj->   '+loanAppObj );
        System.debug('Loan Applicant >   '+loanAppObj[0].Loan_Applicants__r );
        if(!loanAppObj[0].Loan_Applicants__r.isEmpty()){
            for(Loan_Applicant__c app : loanAppObj[0].Loan_Applicants__r){
                applicantMap.put(app.Applicant_Type__c, app);
            }
        }
        List<Address__c>  addressObj = new UB_AddressesSelector().getApplicantAddress(new Set<Id>{applicantMap.get(UB_ConstantsUtil.APPLICANT).id});
        System.debug('addressObj->   '+addressObj );
        
        
        System.debug('applicantMap->   '+applicantMap );
        EmailTemplate tempID = [SELECT Id,Name,Body,HTMLValue FROM EmailTemplate WHERE DeveloperName  =: UB_ConstantsUtil.SANCTION_LETTER_EMAIL_TEMPLATE_NAME];
       
        String emailBody = tempID.Body;
       // String emailBody = tempID.HTMLValue;
        
        emailBody = emailBody.replace('applicant_Name',applicantMap.get(UB_ConstantsUtil.APPLICANT).Account_Name__c);
        emailBody = emailBody.replace('co_Applicant_Name1',applicantMap.get(UB_ConstantsUtil.CO_APPLICANT).Account_Name__c);
        emailBody = emailBody.replace('guarantoe_Name',applicantMap.get(UB_ConstantsUtil.GUATANTOR).Account_Name__c);
        if(addressObj.size() > 0){
            system.debug('in isde addres');
            emailBody = emailBody.replace('Address1', addressObj[0].Name +' '+ addressObj[0].Address_Line_2__c );
            emailBody = emailBody.replace('Address2', addressObj[0].Address_Line_3__c +' '+ addressObj[0].City__c+' '+ addressObj[0].District__c);
            emailBody = emailBody.replace('Address3',  addressObj[0].State__c +' '+  addressObj[0].Pincode__c +' '+ addressObj[0].Country__c);
        }
        system.debug('in isde addres>>' + addressObj[0].Name + addressObj[0].Address_Line_2__c);
        emailBody = emailBody.replace('application_Number ',loanAppObj[0].Name);
        emailBody = emailBody.replace('today_Date',String.valueOf(System.today()));
        emailBody = emailBody.replace('loan_Amount', String.valueOf(loanAppObj[0].Amount__c) != null ? String.valueOf(loanAppObj[0].Amount__c) : '0');
        emailBody = emailBody.replace('ROI ',String.valueOf(loanAppObj[0].ROI__c) != null ? String.valueOf(loanAppObj[0].ROI__c) : '0');
        // emailBody = emailBody.replace('tenor',line3);
        //  emailBody = emailBody.replace('total_Vehicles',line3);
        // emailBody = emailBody.replace('total_Vehicle_Cost',line3);
        System.debug('emailBody after change>   '+ emailBody );
        
        
        return emailBody;
        
    }
    public class VehicleEquipmentWrapper {
        public Boolean isApplicantIndividual{get;set;}
        public Boolean isApplicantTrustee{get;set;}
        public String identificationNumber{get;set;}
        public Boolean isApplicantPermamentAdd{get;set;}
        public Boolean isApplicantCurrentAdd{get;set;}
        public Boolean isApplicantOfficeAdd{get;set;}
        public Boolean iscoApplicantGaurantorIndividual{get;set;}
        public Boolean iscoApplicantGaurantorNonIndividual{get;set;}
        public Boolean isApplicationTradeReference{get;set;}
        public String product{get;set;}
        public String customerCategory{get;set;}
        public Boolean isOldVehicleDetailList{get;set;}
        public Boolean isBankDetailList{get;set;}
        public Boolean isVerification{get;set;}
        
        
    }
    
}