/**
* @File Name          : Ub_SanctionLetterCltr.cls
* @Description        : This class use to map sanction letter .
* @Author             : Lakshya Verma
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         20-06-2024            Lakshya Verma         Initial Version           
**/
public class Ub_SanctionLetterCltr {
    public String plainHTML { get; set; }
    public String disburseRecId{get;set;} 
    public Ub_SanctionLetterCltr(ApexPages.StandardController controller) {
        
    }
    public void getPDF(){
        try {
            disburseRecId = apexpages.currentPage().getParameters().get('Id');
            if(String.isNotBlank(disburseRecId)){
                plainHTML = createEmailBody(disburseRecId);
            }
            System.debug('VALUEEEEEEEEEEEEE  '+disburseRecId);
        }catch(Exception e) {
            System.debug('ERRORRRRRRRRRR    '+e.getMessage());
            System.debug('Line   No'+e.getLineNumber());
        }
    }
    
    public static String createEmailBody(String disburseRecId){
        String currentUserFullName = UserInfo.getName();
        String UserId = UserInfo.getUserId();
        User userObj = [SELECT Id,Name,EmployeeNumber from User WHERE Id =: UserId];
        List<Loan_Applicant__c> applicants = new list<Loan_Applicant__c>();
        List<Vehicle__c> vehicleRecord = new List<Vehicle__c>();
         List<String> coApp = new list<String>();
         String COAPP1 = '';
        String APPLICANTID;
        String COAPP2 = '';
        String GUARTNTOR = '';
         String APPLICANT = '';
        String APPLICANT_ADDRESS  = '';
        String productCat = '';
        String MODEL = '';
        String MAKE = '';
        Decimal CREDIT_INSURANCE;
        Decimal LOAN_FUNDING;
        String TYPE = '';
        Decimal ASSET_COST;
        Decimal BODY_COST;
		String BODY_FUNDING = '';
        String LTV ='';
		String DEALER_NAME='';
        String DEALER_ADD = '';
        String ROI = '';
        String TENURE = '';
        String MORATORIUM = '';
        Integer MORATORIUM_VALUE = 0;
        String MORATORIUM_DAYS = '';
        String EMI_START_DATE = '';
        String EMI_DUE_DATE = '';
        String EMI_AMOUNT = '';
        String VEHICLE_CATEGORY = '';
        String VEHICLE_CLASSIFICATION = '';
        Decimal TOTAL_LOAN ;
        String CERSAI_CHARGES = '';
        String DOC_CHARGES = '';
        String PROCESSING_CHARGES = '';
        String SANCTION_DESCRIPTIONS = '';
        String SIGNATURE_LIST = '';
        String SELLER_NAME = '';
        String TOTAL_LOAN_IN_WORDS = '';
        String BODY_MAKER_NAME = '';
        String BODY_MAKER_ADDRESS = '';
        String NUMBER_OF_INSTALLMENTS = '';
        String REPAYMENT_MODE = '';
        String REPAYMENT_BANK_NAME = '';
        String BOUNCE_CHARGES = '';
        String NO_DUES_CHARGES = '';
        String DUPLICATE_REPAYMENT = '';
        String LOAN_CANCELLATION_CHARGES = '';
        String PREPAYMENT_CHARGES = '';
        String REVALIDATION_CHARGES = '';
        String STATEMENT_CHARGES = '';
        String SWAP_CHARGES = '';
        String BUREAU_CHARGES = '';

        List<String> listOfApplicants = new List<String>();
        List<Disbursement__c> disbursementRecsList = [SELECT Id, Name,ROI__c, Insurance_Amount__c, LAN__c, Loan_Amount__c, 
                                                      Loan_Application__c, Processing_Fee__c, Stage__c, Status__c, 
                                                      Tenure__c, Vehicle__c, Loan_Application__r.Branch__r.name,Repayment_Mode__c,
                                                      Loan_Application__r.Branch__r.Branch_Code__c, Loan_Application__r.Name,
                                                      Loan_Application__r.Moratorium_Period_Month__c,First_EMI_Date__c,Last_Emi_Date__c,EMI_Amount__c
                                                      FROM Disbursement__c WHERE Id =: disburseRecId
                                                     ];
        if(!disbursementRecsList.isEmpty()){
            String loanApplicationId = disbursementRecsList[0].Loan_Application__c != null ? disbursementRecsList[0].Loan_Application__c : '';
            TENURE = disbursementRecsList[0].Tenure__c != null ? String.valueOf(disbursementRecsList[0].Tenure__c) : '';
            ROI =String.valueOf(disbursementRecsList[0].ROI__c != null ? disbursementRecsList[0].ROI__c : 0 );
            MORATORIUM = disbursementRecsList[0].Loan_Application__r.Moratorium_Period_Month__c != null ? String.valueOf(disbursementRecsList[0].Loan_Application__r.Moratorium_Period_Month__c) : '';
            if(MORATORIUM == '1 Month'){
                MORATORIUM_VALUE = 1;
                MORATORIUM_DAYS = '30';        
            }
            else{
                MORATORIUM_VALUE = 2;
                MORATORIUM_DAYS = '60';
            }
            EMI_START_DATE = disbursementRecsList[0].First_EMI_Date__c != null ?DateTime.newInstance(disbursementRecsList[0].First_EMI_Date__c, Time.newInstance(0, 0, 0, 0)).format('dd-MM-yyyy') : '';
            EMI_DUE_DATE = disbursementRecsList[0].Last_Emi_Date__c != null ? DateTime.newInstance(disbursementRecsList[0].Last_Emi_Date__c, Time.newInstance(0, 0, 0, 0)).format('dd-MM-yyyy') : '';
            EMI_AMOUNT = disbursementRecsList[0].EMI_Amount__c != null ? String.valueOf(disbursementRecsList[0].EMI_Amount__c) : '';
            REPAYMENT_MODE = disbursementRecsList[0].Repayment_Mode__c != null ?  disbursementRecsList[0].Repayment_Mode__c : '';
            if(String.isNotBlank(loanApplicationId) ){
                 applicants = [select id,Name,Account_Name__c, Applicant_Type__c from Loan_Applicant__c  
                               WHERE Loan_Application__c =:  loanApplicationId AND Loan_Application__c != null AND Is_Deleted__c = 'No' ];
            } 
            system.debug('applicants>> ' + applicants);
            if(disbursementRecsList[0].Vehicle__c != null){
             vehicleRecord = [SELECT Id,Make__c,Model__c,Vehicle_Master__r.Vehicle_Classification__c,Vehicle_Master__r.Vehicle_Category__c,Number_of_Body_Unit_If_Applicable__c,Credit_Shield_Premium__c,Funding_Limit__c,
                                              Vehicle_Cost__c,Body_Funding_Amount_If_Applicable__c,LTV__c,Dealer__r.Name,Dealer__r.Dealer_Address__c,ROI__c,Product__r.Product_Category__c,Owner_Name__c,
                                              RecordTypeId,RecordType.Name,Body_Maker_Address_If_Applicable__c,Body_Maker_Name__c
                                              FROM Vehicle__c WHERE id= :disbursementRecsList[0].Vehicle__c];
            }
            integer guarntorCount = 1;
            List<String> guarantorList = new List<String>();
            //Applicant, Co-Applicant and Guarantor mapping
            if(!applicants.isEmpty() && applicants.size()>0){
                integer counter = 1;
                for(Loan_Applicant__c app : applicants){
                    listOfApplicants.add(app.Applicant_Type__c);
                    listOfApplicants.sort();
                    if(app.Applicant_Type__c == UB_ConstantsUtil.CO_APPLICANT){
                        //coApp.add(app.Account_Name__c);
                        coApp.add('<b>'+counter+'.</b> '+ 'Co Applicant Name : '+ ' '+ app.Name + '<br/>');
                        counter+=1;
                    }else if(app.Applicant_Type__c == UB_ConstantsUtil.APPLICANT){
                        APPLICANTID = app.id;
                        APPLICANT = app.Account_Name__c;
                    }else{
                        guarantorList.add('<b>'+guarntorCount+'.</b> '+ 'Guarantor Name : '+ ' '+ app.Name + '<br/>');
                        guarntorCount+=1;
                        //GUARTNTOR = app.Account_Name__c;
                    }
                }
                COAPP1 = String.join(coApp, '');
                GUARTNTOR = String.join(guarantorList, '');
            }
            System.debug('listOfApplicants '+listOfApplicants);
            integer coApplicantCount = 1;
            integer guarantorCount = 1;
            List<String> tempList = new List<String>();
            for(String name : listOfApplicants){
                if(name=='Applicant'){
                    tempList.add(name);
                }
                if(name=='Co-Applicant'){
                    tempList.add(name+' '+coApplicantCount);
                    coApplicantCount+=1;
                }
                if(name=='Guarantor'){
                    tempList.add(name+' '+guarantorCount);
                    guarantorCount+=1;
                }
            }
            System.debug('tempList '+tempList);
            listOfApplicants = tempList;
            Integer i =1;
            for (String appName : tempList) {
                if(appName=='Applicant'){
                SIGNATURE_LIST += '<div style="width: 48%; float: left; margin-bottom: 20px;">';
                SIGNATURE_LIST += '<div>Signature of '+appName+': </div>';
                SIGNATURE_LIST += '<div>Place:</div>';
                SIGNATURE_LIST += '<div>Date:</div>';
                SIGNATURE_LIST += '</div>';
                }
                if(appName.contains('Co-Applicant')){
                SIGNATURE_LIST += '<div style="width: 48%; float: left; margin-bottom: 20px;">';
                SIGNATURE_LIST += '<div>Signature of '+appName+': </div>';
                SIGNATURE_LIST += '<div>Place:</div>';
                SIGNATURE_LIST += '<div>Date:</div>';
                SIGNATURE_LIST += '</div>';
                }
                if(appName.contains('Guarantor')){
                    SIGNATURE_LIST += '<div style="width: 48%; float: left; margin-bottom: 20px;">';
                    SIGNATURE_LIST += '<div>Signature of '+appName+': </div>';
                    SIGNATURE_LIST += '<div>Place:</div>';
                    SIGNATURE_LIST += '<div>Date:</div>';
                    SIGNATURE_LIST += '</div>';
                }
            }
            System.debug('SIGNATURE_LIST '+SIGNATURE_LIST);
            

            //  if(coApp.size()==1){
            //     COAPP1 = coApp[0];
            // }
            // else if(coApp.size() > 1){
            //      COAPP1 = coApp[0];
            //     COAPP2 = coApp[1];
            // }

            // Address mapping
            List<Address__c>  addressObj = new UB_AddressesSelector().getApplicantAddress(new Set<Id>{APPLICANTID});
            System.debug('addressObj->   '+addressObj );
            if(!addressObj.isEmpty() && addressObj.size()> 0 ){
                APPLICANT_ADDRESS = addressObj[0].Name +' '+ (addressObj[0].Address_Line_2__c!=null ? addressObj[0].Address_Line_2__c : '') + ' ' + (addressObj[0].Address_Line_3__c != null ? addressObj[0].Address_Line_3__c : '' ) +' '+ addressObj[0].City__c+' '+ addressObj[0].District__c+ ' '+addressObj[0].State__c +' '+  addressObj[0].Pincode__r.Name +' '+ addressObj[0].Country__c;
            }
            List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanApplicationId});
            
           
             
            //Vehicle Mapping
            if(!vehicleRecord.isEmpty() && vehicleRecord.size()>0){
                	//ROI =String.valueOf(vehicleRecord[0].ROI__c != null ? vehicleRecord[0].ROI__c : 0 );
                    DEALER_ADD=vehicleRecord[0].Dealer__r.Dealer_Address__c != null ? vehicleRecord[0].Dealer__r.Dealer_Address__c : '' ;
                    DEALER_NAME=vehicleRecord[0].Dealer__r.Name != null ? vehicleRecord[0].Dealer__r.Name : '';
                    LTV=String.valueOf(vehicleRecord[0].LTV__c != null ?  vehicleRecord[0].LTV__c : 0);
                    BODY_FUNDING=String.valueOf(vehicleRecord[0].Body_Funding_Amount_If_Applicable__c != null ? vehicleRecord[0].Body_Funding_Amount_If_Applicable__c : 0);
                    ASSET_COST=vehicleRecord[0].Vehicle_Cost__c != null ?  vehicleRecord[0].Vehicle_Cost__c : 0;
                    BODY_COST=vehicleRecord[0].Funding_Limit__c != null ?  vehicleRecord[0].Funding_Limit__c : 0;
                    TYPE=vehicleRecord[0].Vehicle_Master__r.Vehicle_Classification__c != null ? vehicleRecord[0].Vehicle_Master__r.Vehicle_Classification__c : '';
                    MODEL=vehicleRecord[0].Model__c != null ? vehicleRecord[0].Model__c : '';
                    MAKE=vehicleRecord[0].Make__c != null ? vehicleRecord[0].Make__c : '';
                    CREDIT_INSURANCE=vehicleRecord[0].Credit_Shield_Premium__c != null ? vehicleRecord[0].Credit_Shield_Premium__c : 0;
                    LOAN_FUNDING = vehicleRecord[0].Funding_Limit__c != null ? vehicleRecord[0].Funding_Limit__c : 0;
                    VEHICLE_CATEGORY = vehicleRecord[0].Vehicle_Master__r.Vehicle_Category__c != null ? vehicleRecord[0].Vehicle_Master__r.Vehicle_Category__c : ''; 
                    TOTAL_LOAN = ASSET_COST + LOAN_FUNDING + CREDIT_INSURANCE;
                    TOTAL_LOAN_IN_WORDS = '- <b>' +UB_CommonUtil.convertToWords(Integer.ValueOf(TOTAL_LOAN))+ '</b>';
                    if(vehicleRecord[0].RecordType.Name == UB_ConstantsUtil.USED_VEHICLE){
                        SELLER_NAME = vehicleRecord[0].Owner_Name__c != null ? vehicleRecord[0].Owner_Name__c : '';
                    }
                    else{
                        SELLER_NAME = 'NA';
                    }
                    BODY_MAKER_NAME = vehicleRecord[0].Body_Maker_Name__c!=null?vehicleRecord[0].Body_Maker_Name__c:'';
                    BODY_MAKER_ADDRESS = vehicleRecord[0].Body_Maker_Address_If_Applicable__c!=null?vehicleRecord[0].Body_Maker_Address_If_Applicable__c:'';
                    
                    NUMBER_OF_INSTALLMENTS = String.valueOf(Integer.valueOf(TENURE) - Integer.valueOf(MORATORIUM_VALUE));
                    System.debug('NUMBER_OF_INSTALLMENTS-> '+ NUMBER_OF_INSTALLMENTS );
                if(vehicleRecord[0].Product__r.Product_Category__c != null){
                String[] sp = (vehicleRecord[0].Product__r.Product_Category__c.split('-'));
                productCat= sp[1];
                System.debug('productCat->   '+ productCat );
                }
                    }
            
            //Getting processing fees, document charges, cersai charges
            List<Fees__c> feesListOfDisbursement = [SELECT Id,Name,Total_Amount__c from Fees__c WHERE Disbursement__c =: disburseRecId];
            System.debug('feesListOfDisbursement '+feesListOfDisbursement);
            for(Fees__c feesInstance : feesListOfDisbursement){
                if(feesInstance.Name == 'CERSAI'){
                    CERSAI_CHARGES = String.valueOf(feesInstance.Total_Amount__c);
                }
                if(feesInstance.Name == 'Documentation Charges'){
                    DOC_CHARGES = String.valueOf(feesInstance.Total_Amount__c);
                }
                if(feesInstance.Name == 'Processing Fees'){
                    PROCESSING_CHARGES = String.valueOf(feesInstance.Total_Amount__c);
                }
             }
             //Other Charges
             List<Fees_and_Charges__mdt> sanctionLetterCharges = [SELECT Id,Label,DeveloperName,Type__c, Value__c from Fees_and_Charges__mdt WHERE Type__c = 'Sanction Letter'];
             for(Fees_and_Charges__mdt obj : sanctionLetterCharges){
                 if(obj.DeveloperName == 'Bounce_Charges'){
                    BOUNCE_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Duplicate_No_Objection_Certificate_No'){
                    NO_DUES_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Duplicate_Repayment_Amortization_Charges'){
                    DUPLICATE_REPAYMENT = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Loan_Cancellation_charges'){
                    LOAN_CANCELLATION_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Prepayment_Statement_Charges'){
                    PREPAYMENT_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Revalidation_of_No_Objection_Certificate'){
                    REVALIDATION_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Statement_of_Account_Charges'){
                    STATEMENT_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Swap_Charges'){
                    SWAP_CHARGES = obj.Value__c;
                 }
                 if(obj.DeveloperName == 'Bureau_Report_Other_Verification_Charges'){
                    BUREAU_CHARGES = obj.Value__c;
                 }
             }
             //Sanction 
            List<Document__c> sanctionConditionList = [Select Id,Name,Description__c,Document_Type__c from Document__c WHERE Document_Type__c = 'Sanction Condition' AND Loan_Application__c =: disbursementRecsList[0].Loan_Application__c];
            if(sanctionConditionList.size()>0){
                List<String> sanctionDescriptionList = new List<String>();
                Integer count = 1;
                for(Document__c obj : sanctionConditionList){
                    if(obj.Description__c != null){
                        sanctionDescriptionList.add('<b>'+count+'.</b> '+ obj.Description__c + '<br/>');
                        count +=1;
                    }
                }
                SANCTION_DESCRIPTIONS = String.join(sanctionDescriptionList, '');
            }
            List<Bank_Details__c> repaymentBankDetailList = [SELECT Id,Bank_Name__c,Payment_Mode__c,Account_Number__c from Bank_Details__c WHERE Is_Primary_Repayment_Account__c = true AND Loan_Application__c =: disbursementRecsList[0].Loan_Application__c AND RecordType.Name = 'Repayment' order by createdDate desc LIMIT 1];
            if(repaymentBankDetailList.size()>0){
                REPAYMENT_BANK_NAME = repaymentBankDetailList[0].Bank_Name__c !=null ? repaymentBankDetailList[0].Bank_Name__c : '';
            }            
            EmailTemplate tempID = [SELECT Id,Name,Body,HTMLValue FROM EmailTemplate WHERE DeveloperName  =: UB_ConstantsUtil.SANCTION_LETTER];
            String emailBody = tempID.Body;
            emailBody = emailBody.replace('{branch_name}',disbursementRecsList[0].Loan_Application__c != null && disbursementRecsList[0].Loan_Application__r.Branch__c != null ? disbursementRecsList[0].Loan_Application__r.Branch__r.Name : '' );
            emailBody = emailBody.replace('{branch_code}',disbursementRecsList[0].Loan_Application__c != null && disbursementRecsList[0].Loan_Application__r.Branch__c != null ? disbursementRecsList[0].Loan_Application__r.Branch__r.Branch_Code__c  : '' );
            emailBody = emailBody.replace('{date}',system.today().format() );
            emailBody = emailBody.replace('{dated}',system.today().format() );
            emailBody = emailBody.replace('{application_number}',disbursementRecsList[0].Loan_Application__c != null ? disbursementRecsList[0].Loan_Application__r.Name : '' );
            emailBody = emailBody.replace('{applicant_name}', APPLICANT );
            emailBody = emailBody.replace('{co_applicant_names}',COAPP1 );
            emailBody = emailBody.replace('{co_applicant_name_2nd}',COAPP2 );
            emailBody = emailBody.replace('{guarantor_name}',GUARTNTOR );
            emailBody = emailBody.replace('{applicant_address}', APPLICANT_ADDRESS);
            emailBody = emailBody.replace(' {application_number1}',disbursementRecsList[0].Loan_Application__c != null ? disbursementRecsList[0].Loan_Application__r.Name : '' );
            emailBody = emailBody.replace(' {dated1}',system.today().format() );
            emailBody = emailBody.replace('{CV_CE}',loanAppObj[0].LOB__c != null ? loanAppObj[0].LOB__c : '');
            emailBody = emailBody.replace('{New_Used}',productCat );
            emailBody = emailBody.replace('{make}',MAKE );
            emailBody = emailBody.replace('{model}',MODEL );
            emailBody = emailBody.replace('{Manufacturer}',MAKE );
            emailBody = emailBody.replace('{assetCategory}',VEHICLE_CATEGORY);
            emailBody = emailBody.replace('{assetClassification}',TYPE);
            emailBody = emailBody.replace('{type}',TYPE );
            emailBody = emailBody.replace('{no_of_units_chachis}','' );
            emailBody = emailBody.replace('{no_of_units_body}','' );
            emailBody = emailBody.replace('{insured_person}',APPLICANT);
            emailBody = emailBody.replace('{asset_cost}', String.valueOf(ASSET_COST) );
            emailBody = emailBody.replace('{body_cost}',String.valueOf(BODY_COST));
            emailBody = emailBody.replace('{body_funding}',BODY_FUNDING );
            emailBody = emailBody.replace('{credit_insurance}',String.valueOf(CREDIT_INSURANCE));
            emailBody = emailBody.replace('{loan_funding_amount}',String.valueOf(LOAN_FUNDING));
            emailBody = emailBody.replace('{total_loan}',String.valueOf(TOTAL_LOAN));
             emailBody = emailBody.replace('{total_loan_words}',TOTAL_LOAN_IN_WORDS);
             emailBody = emailBody.replace('{seller_name}',SELLER_NAME);
             emailBody = emailBody.replace('{ltv}',LTV ); 
            emailBody = emailBody.replace('{as_received_from_bank}','' );
             emailBody = emailBody.replace('{dealer_name}',DEALER_NAME );
             emailBody = emailBody.replace(':{dealer_address}',DEALER_ADD );
             emailBody = emailBody.replace(' {body_maker_name}',' '+BODY_MAKER_NAME);
             emailBody = emailBody.replace('{body_maker_address}',' '+BODY_MAKER_ADDRESS);
             emailBody = emailBody.replace('{repayment_tenure} ',TENURE +' ');
             emailBody = emailBody.replace('{moratorium} ',MORATORIUM_DAYS +' ');
             emailBody = emailBody.replace('{number_of_installment}',' '+NUMBER_OF_INSTALLMENTS);
             emailBody = emailBody.replace('{rate_of_intrest}',ROI );
             emailBody = emailBody.replace('{emi_due_date}',EMI_DUE_DATE );
             emailBody = emailBody.replace('{emi_start_date}',EMI_START_DATE);
             emailBody = emailBody.replace('{repayment_mode}',' - '+REPAYMENT_MODE );
             emailBody = emailBody.replace('{bankName}',' - '+REPAYMENT_BANK_NAME );
             emailBody = emailBody.replace('{collateral_detail}','' );
             emailBody = emailBody.replace('{stamp_duty}','' );
             emailBody = emailBody.replace('{credit_insurance}',String.valueOf(CREDIT_INSURANCE));
             emailBody = emailBody.replace('{emi_amount}',EMI_AMOUNT);
             emailBody = emailBody.replace('{processingFee}',PROCESSING_CHARGES);
             emailBody = emailBody.replace('{docCharges}',DOC_CHARGES);
             emailBody = emailBody.replace('{bureauCharges}',BUREAU_CHARGES);
             emailBody = emailBody.replace('{cersaiCharges}',CERSAI_CHARGES);
             emailBody = emailBody.replace('{creditManager}', currentUserFullName);
             emailBody = emailBody.replace('{empCode}', userObj.EmployeeNumber!=null ?userObj.EmployeeNumber : '');
             emailBody = emailBody.replace('{sanctionDescrpition}', SANCTION_DESCRIPTIONS);
             emailBody = emailBody.replace('{signature}', SIGNATURE_LIST);
             emailBody = emailBody.replace('{prepaymentCharges}',PREPAYMENT_CHARGES );
             emailBody = emailBody.replace('{statementCharges}',STATEMENT_CHARGES );
             emailBody = emailBody.replace('{bounceCharges}', BOUNCE_CHARGES);
             emailBody = emailBody.replace('{duplicateRepayment}',DUPLICATE_REPAYMENT );
             emailBody = emailBody.replace('{noDuesCertificateCharges}',NO_DUES_CHARGES );
             emailBody = emailBody.replace('{revalidationCharges}', REVALIDATION_CHARGES );
             emailBody = emailBody.replace('{swapCharges}',SWAP_CHARGES);
             emailBody = emailBody.replace('{loanCancellationCharges}',LOAN_CANCELLATION_CHARGES );
            system.debug('emailBody-> ' + emailBody);
            // String emailBody = tempID.HTMLValue;
             return emailBody;
        }
        RETURN null;
    }
}