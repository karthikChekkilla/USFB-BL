/**
* @File Name          : UB_DisbursementMemoController.cls
* @Description        : This class used to fetch data for Disbursement Memo.
* @Author             : Mohd Musab
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         24-07-2024               Mohd Musab                Initial Version
*/

public class UB_DisbursementMemoController {

    @AuraEnabled    
    public static DisbursementWrapper getDisbursementMemo(String recordId){
    DisbursementWrapper wrapInstance = new DisbursementWrapper();
    try{    
    Date currentDate = Date.today();
    DateTime currentDateTime = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
    List<Disbursement__c> listOfDisbursement = new UB_DisbursementsSelector().getDisbursementRecordsByIds(new Set<Id>{recordId});
    List<Loan_Application__c> loanApplicationObj = new UB_LoanApplicationsSelector().selectByIds(new Set<Id>{listOfDisbursement[0].Loan_Application__c});
    
    //Loan_Application__c loanApplicationObj = new UB_LoanApplicationsSelector().getLoanApplicationRecord(listOfDisbursement[0].Loan_Application__c);
    List<Loan_Applicant__c> primaryApplicantList = new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{listOfDisbursement[0].Loan_Application__c},UB_ConstantsUtil.APPLICANT);
    wrapInstance.currentDate = currentDateTime.format('dd-MMMM-yyyy');
    wrapInstance.applicationNumber = loanApplicationObj[0].Name;
    wrapInstance.applicantName = primaryApplicantList[0].Name;
    wrapInstance.branchCode = primaryApplicantList[0].Loan_Application__r.Branch__r.Branch_Code__c;
    wrapInstance.cifExistingClient = String.isNotBlank(primaryApplicantList[0].CIF__c)?primaryApplicantList[0].CIF__c : 'NA';
    wrapInstance.rormCode = loanApplicationObj[0].Ro_RM__r.Name+ ' '+loanApplicationObj[0].Ro_RM__r.EmployeeNumber;
    wrapInstance.sourcingChannel = loanApplicationObj[0].Lead__r.Lead_Source__c;
    wrapInstance.dsaNameCode = loanApplicationObj[0].DSA_Name__c;
    wrapInstance.newUsedAppType = loanApplicationObj[0].Application_Type__c;
    wrapInstance.product = loanApplicationObj[0].Product__c;
    wrapInstance.customerCategory = loanApplicationObj[0].CB_Customer_Category__c;
    wrapInstance.manufacturer = listOfDisbursement[0].Vehicle__r.Make__c;
    wrapInstance.assetNameModel = listOfDisbursement[0].Vehicle__r.Model__c;
    wrapInstance.creditShieldPremium = listOfDisbursement[0].Vehicle__r.Credit_Shield_Premium__c;
    wrapInstance.vehicleCost = String.valueOf(listOfDisbursement[0].Vehicle__r.Vehicle_Cost__c);
    wrapInstance.registrable =  String.valueOf(listOfDisbursement[0].Vehicle__r.Is_Asset_Registrable__c);
    wrapInstance.marginMoney =  String.valueOf(listOfDisbursement[0].Vehicle__r.Margin_Money__c);
    wrapInstance.repaymentMode = String.valueOf(listOfDisbursement[0].Repayment_Mode__c);
    wrapInstance.loanAmount =  String.valueOf(listOfDisbursement[0].Loan_Amount__c);
    wrapInstance.irr =  String.valueOf(listOfDisbursement[0].ROI__c);
    wrapInstance.tenorInMonths =  String.valueOf(listOfDisbursement[0].Tenure__c);
    wrapInstance.numberOfInstallments =  String.valueOf(listOfDisbursement[0].Tenure__c);
    wrapInstance.moratorium =  String.valueOf(loanApplicationObj[0].Moratorium_Period_Month__c);
    wrapInstance.emiAmount =  String.valueOf(listOfDisbursement[0].EMI_Amount__c);
    wrapInstance.emiDueDate =  String.valueOf(listOfDisbursement[0].Last_Emi_Date__c);
    wrapInstance.emiAmount =  String.valueOf(listOfDisbursement[0].EMI_Amount__c);
    wrapInstance.emiDueDate =  String.valueOf(listOfDisbursement[0].Last_Emi_Date__c);
        if(listOfDisbursement[0].Vehicle__r.Vehicle_Master__r.Vehicle_Type__c.contains('Fully Built')){
        wrapInstance.isFullyBuilt = true;
        }
        else{
            wrapInstance.isFullyBuilt = false;
        }
    List<Bank_Details__c> bankDetailsList = [SELECT Id,Name,Account_Holder_Name__c,Account_Number__c,Payment_Mode__c,IFSC_Code__r.Name,RecordType.Name from Bank_Details__c WHERE Disbursement__c =: listOfDisbursement[0].Id AND RecordType.Name = 'Disbursement' order by createdDate desc LIMIT 1];
    System.debug('bankDetailsList '+bankDetailsList);
    if(bankDetailsList.size() > 0){
        wrapInstance.fillBeneficiarySection = true;
        wrapInstance.ifsc = bankDetailsList[0].IFSC_Code__r.Name!=null ? bankDetailsList[0].IFSC_Code__r.Name : '';
        wrapInstance.disbursementInFavour = bankDetailsList[0].Account_Holder_Name__c != null ? bankDetailsList[0].Account_Holder_Name__c : '';
        wrapInstance.disbursementAccount = bankDetailsList[0].Account_Number__c!=null ? Decimal.valueOf(bankDetailsList[0].Account_Number__c) : 0;
        wrapInstance.disbursementMode = bankDetailsList[0].Payment_Mode__c != null ? bankDetailsList[0].Payment_Mode__c : '';
    }
    else{
        wrapInstance.fillBeneficiarySection = false;
    }
    List<Fees__c> feesListOfDisbursement = [SELECT Id,Name,Total_Amount__c from Fees__c WHERE Disbursement__c =: listOfDisbursement[0].Id];
    System.debug('feesListOfDisbursement '+feesListOfDisbursement);
    for(Fees__c feesInstance : feesListOfDisbursement){
        if(feesInstance.Name == 'CERSAI'){
            wrapInstance.cersaiCharges = feesInstance.Total_Amount__c;
        }
        if(feesInstance.Name == 'Documentation Charges'){
            wrapInstance.documentCharges = feesInstance.Total_Amount__c;
        }
        if(feesInstance.Name == 'Processing Fees'){
            wrapInstance.processingFeesAmount = feesInstance.Total_Amount__c.setScale(2, RoundingMode.HALF_UP);
        }
    }
    wrapInstance.totalCharges =  (wrapInstance.cersaiCharges + wrapInstance.documentCharges + wrapInstance.processingFeesAmount).setScale(2, RoundingMode.HALF_UP);
    wrapInstance.netDisbursementAmount = (listOfDisbursement[0].Loan_Amount__c - wrapInstance.totalCharges).setScale(2, RoundingMode.HALF_UP);
    List<Bank_Details__c> repaymentBankDetailList = [SELECT Id,Bank_Name__c,Payment_Mode__c,Account_Number__c from Bank_Details__c WHERE Is_Primary_Repayment_Account__c = true AND Loan_Application__c =: listOfDisbursement[0].Loan_Application__c AND RecordType.Name = 'Repayment' order by createdDate desc LIMIT 1];
    if(repaymentBankDetailList.size()>0){
    wrapInstance.repaymentBankName = repaymentBankDetailList[0].Bank_Name__c != null ? repaymentBankDetailList[0].Bank_Name__c : '';
    wrapInstance.repaymentAccountNumber = repaymentBankDetailList[0].Account_Number__c != null ? String.valueOf(repaymentBankDetailList[0].Account_Number__c) : '';
    System.debug('wrapInstance@@ '+wrapInstance);
    }
    if(wrapInstance.repaymentBankName.contains('Utkarsh')){
        //wrapInstance.repaymentMode = listOfDisbursement[0].Repayment_Mode__c;
        wrapInstance.repaymentMode = 'Standing Instructions';
    }
    return wrapInstance; 
    }
    catch (Exception e) {
        System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        return wrapInstance;
    }
    }
    
    // This method is used to create or update the Disbursement Bank Details
    @AuraEnabled
    public static String upsertBankDetails(String wrapperResponse,String disbursementId){
    String message = '';
    System.debug('wrapperResponse '+wrapperResponse);
    try{
    List<Bank_Details__c> bankDetailsList = [SELECT Id,Name,Account_Holder_Name__c,Account_Number__c,Payment_Mode__c,IFSC_Code__r.Name,RecordType.Name from Bank_Details__c WHERE Disbursement__c =: disbursementId AND RecordType.Name = 'Disbursement' order by createdDate desc LIMIT 1];
    BankDetailsWrapper wrapper=(BankDetailsWrapper)JSON.deserialize(wrapperResponse,BankDetailsWrapper.class);
    System.debug('wrapper '+wrapper);
    if(wrapper!=null)
      {
        Bank_Details__c bankDetailInstance = new Bank_Details__c();
        if(bankDetailsList.size()>0){
            bankDetailInstance.Id = bankDetailsList[0].Id;
        }
        bankDetailInstance.Account_Holder_Name__c = wrapper.disbursementInFavour;
        bankDetailInstance.Account_Number__c = String.valueOf(wrapper.disbursementAccount);
        bankDetailInstance.Payment_Mode__c = wrapper.disbursementMode;
        if(wrapper.ifsc != null){
        bankDetailInstance.IFSC_Code__c = wrapper.ifsc;
        }
        bankDetailInstance.Disbursement__c = disbursementId;
        bankDetailInstance.recordTypeId = UB_ConstantsUtil.DISBURSEMENT_RECORD_TYPE;
        upsert bankDetailInstance;
    
        Disbursement__c disObj = new Disbursement__c();
        disObj.id = disbursementId;
        disObj.Repayment_Mode__c = wrapper.repaymentMode;
        disObj.IsMemoCompleted__c = true;
        update disObj;
        message = 'success';
        System.debug('message@@ '+message);
      }
    }
    catch (Exception e) {
        System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        message = 'failure';
    }
    return message;
    }
    
    
    public class BankDetailsWrapper
    {
        @AuraEnabled
        public String ifsc{get;set;}
        @AuraEnabled
        public String disbursementInFavour{get;set;}
        @AuraEnabled
        public String disbursementAccount {get;set;}
        @AuraEnabled
        public String disbursementMode {get;set;}
        @AuraEnabled
        public String repaymentMode {get;set;}
    }
    
    public class DisbursementWrapper{
    
    @AuraEnabled 
    public String currentDate;
    @AuraEnabled    
    public String applicationNumber;
    @AuraEnabled    
    public String applicantName;
    @AuraEnabled    
    public String cifExistingClient;
    @AuraEnabled    
    public String branchCode;
    @AuraEnabled    
    public String rormCode;
    @AuraEnabled    
    public String sourcingChannel;
    @AuraEnabled    
    public String dsaNameCode;
    @AuraEnabled    
    public String newUsedAppType;
    @AuraEnabled    
    public String product;
    @AuraEnabled    
    public String customerCategory;
    @AuraEnabled    
    public String manufacturer;
    @AuraEnabled    
    public String assetNameModel;
    @AuraEnabled    
    public String vehicleCost;
    @AuraEnabled    
    public String registrable;
    @AuraEnabled    
    public String marginMoney;
    @AuraEnabled    
    public String loanAmount;
    @AuraEnabled    
    public String tenorInMonths;
    @AuraEnabled 
    public String moratorium;
    @AuraEnabled    
    public String numberOfInstallments;
    @AuraEnabled    
    public String irr;
    @AuraEnabled    
    public String emiAmount;
    @AuraEnabled    
    public String emiDueDate;
    @AuraEnabled    
    public Decimal processingFeesAmount;
    @AuraEnabled    
    public Decimal documentCharges;
    @AuraEnabled    
    public Decimal cersaiCharges;
    @AuraEnabled    
    public Decimal totalCharges;
    @AuraEnabled    
    public Decimal creditShieldPremium;
    @AuraEnabled    
    public String repaymentBankName;
    @AuraEnabled    
    public String repaymentAccountNumber;
    @AuraEnabled    
    public String repaymentMode;
    @AuraEnabled    
    public Decimal netDisbursementAmount;
    @AuraEnabled    
    public boolean isFullyBuilt;
    @AuraEnabled    
    public boolean fillBeneficiarySection;
    @AuraEnabled    
    public String ifsc;
    @AuraEnabled    
    public String disbursementInFavour;
    @AuraEnabled    
    public String disbursementMode;
    @AuraEnabled    
    public Decimal disbursementAccount;
    
    
    public DisbursementWrapper() {
        this.currentDate = '';
        this.applicationNumber = '';
        this.applicantName = '';
        this.cifExistingClient = '';
        this.branchCode = '';
        this.rormCode = '';
        this.sourcingChannel = '';
        this.dsaNameCode = '';
        this.newUsedAppType = '';
        this.product = '';
        this.customerCategory = '';
        this.manufacturer = '';
        this.assetNameModel = '';
        this.vehicleCost = '';
        this.registrable = '';
        this.marginMoney = '';
        this.loanAmount = '';
        this.tenorInMonths = '';
        this.moratorium = '';
        this.numberOfInstallments = '';
        this.irr = '';
        this.emiAmount = '';
        this.emiDueDate = '';
        this.processingFeesAmount = 0;
        this.documentCharges = 0;
        this.cersaiCharges = 0;
        this.totalCharges = 0;
        this.disbursementAccount = 0;
        this.creditShieldPremium = 0;
        this.repaymentMode = '';
        this.repaymentBankName = '';
        this.netDisbursementAmount = 0;
        this.ifsc = '';
        this.disbursementInFavour = '';
        this.disbursementMode = '';
        isFullyBuilt = false;
        repaymentAccountNumber = '';
    }
    }
    
    }