/**
* @File Name          : UB_ConstantsUtil.cls
* @Description        : This class will have all the constants defined to be used in various other classes
* @Author             : Karthik Chekkilla
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         14-03-2024            Karthik Chekkilla            Initial Version
* 2.0         20-03-2024            Zafaruddin    
* 3.0 		  25-07-2024            	
**/
public class UB_ConstantsUtil { 
    
    public static final String DROPDOWN = 'Dropdown';
    public static final String DISBURSMENT_LOANAPPLICATION_STATUS ='Disbursal In Progress';
    public static final String CIBIL_CLASS = 'UB_Cibil_API';
    public static final String LAF_TITLE = 'CV Loan Application Form';
    public static final String SCORECARD_API_MESSAGE = 'Please Re Initiate Score Card api, contact your sustem Admin.';
    public static final String PD_DOC_TYPE = 'PD';
    public static final String NEW_USED_CATEGORY = 'New/Used';
    public static final String NEW_CATEGORY = 'New';
    public static final String USED_CATEGORY = 'Used';
    public static final String BL_PRODUCT_CATEGORY = 'Business Loan';
    public static final String DISBURSEMENT = 'Disbursement';
    public static final String DISBURSEMENT_INITIATED = 'Disbursement Initiated';
    public static final String FINANCIAL_AUDITED = 'Audited';
    public static final String AADHAR_DOCUMENT_SUB_TYPE = 'Aadhar Card';
    public static final List<String> API_REPORTS = new List<String>{'Cibil Report','Sherlock Report'};
    public static final String SYSTEM_REJECT = 'System Reject';
    public static final String LEAD_SUB_REJECT = 'Customer denied the consent';
    public static final Map<String,String> iciciPartnerMartialStatusMap = new Map<String,String>{'Unmarried'=>'697','Married'=>'696','Other'=>'694'};
    public static final Map<String,String> iciciPartnerEducationMap = new Map<String,String>{'Post-Graduate'=>'676','Graduate'=>'680','Under-Graduate'=>'679','Professional'=>'677','Other'=>'677'};//Added others by Umair
    public static final String COMMERCIAL_VEHICLE_LOAN = 'Commercial Vehicle Loan';
    public static final String CONSTRUCTION_EQUIPMENT_LOAN = 'Construction Equipment Loan';
    public static final String REJECT_LOAN_STATUS = 'Rejected';
    public static final String CV_PRODUCT_VERTICAL = 'Wheels';
    public static final String DEPARTMENT = 'Assets'; 
    public static final String LEAD_STAGE = 'New';
    public static final String LOB_CV = 'CV';
    public static final String LOB_CE = 'CE';
    public static final String LOB_BL = 'BL';
    public static final String USED = 'Used';
    public static final String VEHICLE_VALUATION= 'Vehicle Valuation';
    public static final String PSL_CATEGORY = 'PSL';   
    public static final String UDYAM_API = 'Udyam';
	public static final String CIBIL_SCORE_NOT_ACCETABLE = 'CIBIL score below acceptable range';
    public static final String PORTAL_PROFILE_NAME = 'USFB CV - Partner Community User';
    public static final String PRODUCT_CATEGORY_CV = 'CV/CE';
    public static final String ADDRESS_TYPE = 'Residence Address';
    public static final String LEMS_RECORD_TYPE = Schema.SObjectType.Lead__c.getRecordTypeInfosByName().get('LeMS Lead').getRecordTypeId();
    public static final String PARTNER_PORTAL_RECORD_TYPE = Schema.SObjectType.Lead__c.getRecordTypeInfosByName().get('Partner Portal Lead').getRecordTypeId();
   
    public static final String UDYAM_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Udyam Check').getRecordTypeId();
    public static final String ENACH_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('E-Nach').getRecordTypeId();
    public static final String PAN_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('PAN Verification').getRecordTypeId();
    public static final String CFR_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('CFR Verification').getRecordTypeId();
    public static final String AADHAR_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Aadhaar Verification').getRecordTypeId();
    public static final String DEDUPE_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Dedupe Check').getRecordTypeId();
    public static final String CBS_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('CBS Verification').getRecordTypeId();
    public static final String CIBIL_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('CIBIL Check').getRecordTypeId();
    public static final String INDIVIDUAL_APPICANT_RECORD_TYPE = Schema.SObjectType.Loan_Applicant__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
    public static final String NON_INDIVIDUAL_APPICANT_RECORD_TYPE = Schema.SObjectType.Loan_Applicant__c.getRecordTypeInfosByName().get('Non Individual').getRecordTypeId();
    public static final String SHERLOCK_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Sherlock  Verification').getRecordTypeId();
    public static final String FINANCIAL_RECORD_TYPE = Schema.SObjectType.Financial_Assessment__c.getRecordTypeInfosByName().get('Financials').getRecordTypeId();
    public static final String CONSENT_CHECK_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Consent Check').getRecordTypeId();
    public static final String SCORE_CARD_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('ScoreCard').getRecordTypeId();
    //public static final String BRE_API_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('BRE API').getRecordTypeId();
    public static final String VEHICLE_VALUATION_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('Vehicle Valuation').getRecordTypeId();
    public static final String LEGAL_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('Legal').getRecordTypeId();
    public static final String PROPERTY_VALUATION_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('Property Valuation').getRecordTypeId();
    public static final String OFFICE_FI_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('Office FI').getRecordTypeId();
    public static final String RESIDENCE_FI_VALUATION_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('Residence FI').getRecordTypeId();
    public static final String LEEGALITY_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Leegality').getRecordTypeId();
    public static final String RCU_VALUATION_RECORD_TYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('RCU').getRecordTypeId();
    public static final String PERFIOS_API_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Perfios API').getRecordTypeId();
     public static final String HUNTER_API_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('HUNTER API').getRecordTypeId();
    public static final String UDYAM_PSL_VERIFY_LINE_ITEM_RECORD_TYPE = Schema.SObjectType.Verification_Line_Item__c.getRecordTypeInfosByName().get('Udyam PSL').getRecordTypeId();
    public static final String TRADE_REFERENCE_RECORD_TYPE = Schema.SObjectType.Reference_Member__c.getRecordTypeInfosByName().get('Trade References').getRecordTypeId();
    public static final String MEMBER_REFERENCE_RECORD_TYPE = Schema.SObjectType.Reference_Member__c.getRecordTypeInfosByName().get('Members').getRecordTypeId();


    public static final String CUSTOM_METADATA_NOT_FOUND = 'Unable to query custom metadata. Make sure you\'ve passed the correct developer name.';
    public static final String MOCK_NOT_FOUND = 'Response Mock not found for the current request URL';
    public static final String CONTINUATION_LIMIT_EXCEEDED = 'You can add upto ' + UB_HTTPCalloutAsyncService.CONTINUATION_LIMIT + ' callouts in a single continuation request.';
    public static final String ACCOUNT = 'Account';
    public static final String LOAN_APPLICANT = 'Loan_Applicant__c';
    public static final String LOAN_APPLICATION = 'Loan_Application__c';
    public static final String PRODUCT = 'Product__c';
    public static final String CONVERTED = 'Converted'; 
    public static final String CONSENT_PENDING = 'Consent Pending';
    public static final String PAN_REQUIRED = 'PAN is required.';
    public static final String ADDRESS_REQUIRED = 'Address is required.';
    public static final String REQUIRED_FIELDS = 'Please complete all the required fields in Details section.';
    public static final String LINE_BREAK = '\n';
    public static final String KYC_VALIDATION = 'KYC Validation & Dedupe Pending'; 
    public static final String CUSTOMER = 'Customer';
    public static final String CIBIL = 'CIBIL Initiation';
    public static final String DOCUMENT_VERIFICATION = 'Document Verification';
    public static final String DDE = 'DDE';
    public static final String National_Credit_Manager_Role = 'National_Credit_Manager';
    public static final String Credit_Manager_Role = 'Credit_Manager';
    public static final String AADHAAR_ADDRESS_PROOF = 'UID (Aadhaar)';
    
    public static final String YES = 'Yes';
     public static final String FFR = 'FFR';
     public static final String FINANCIALS = 'Financials';
     public static final String VIABILITY = 'Viability';
    
   
    
    public static final String COMPLETEDSTATUS = 'Completed';
    public static final String REST_API_TYPE = 'REST';
    public static final String WBESERVICE_API_TYPE = 'WEBSERVICE';

    public static final String APPLICANT = 'Applicant';
    public static final String GAURANTOR = 'Guarantor';
    public static final String CO_APPLICANT = 'Co-Applicant';
    public static final String CONSENT_API = 'CONSENT';    
    public static final String PAN_API = 'PAN';
    public static final String E_NACH_API = 'E-NACH';
    public static final String SCORECARD_API = 'SCORECARD';
     public static final String BRE_API = 'BRE';
    public static final String HUNTER_API = 'HUNTER';
    public static final String CFR_API = 'CFR';
    public static final String DEDUPE_API = 'DEDUPE';
    public static final String CIBIL_API = 'CIBIL';
    public static final String AADHAAR_OTP_API = 'AADHAAR';
    public static final String PERFIOS_API = 'PERFIOS';
    public static final String SHERLOCK_API = 'SHERLOCK'; 
    public static final String NOT_UPLOADED = 'Not Uploaded';
    public static final String OTP_ATTEMP_FAILED = 'OTP Attempt Failed';
    public static final String OTP_SENT = 'OTP Sent';
    public static final String FAILED_STATUS = 'Failed';
    public static final String IN_PROGRESS_STATUS = 'In Progress';
    public static final String SUCCESS_STATUS = 'Success';
     public static final String DATE_OF_BIRTH_INCORPORATION = 'Date_of_Birth_Incorporation__c';
     public static final String DATE_OF_INCORPORATION = 'Date_Of_Incorporation__c';
    
    public static final Map<String,String> CibilGenderCodeMap = new Map<String,String>{'Male' => '1','Female' => '2','Transgender' => '3'};
    public static final Map<String,String> SherlockGenderCodeMap = new Map<String,String>{'Male' => 'G01','Female' => 'G02','Transgender' => 'G03'};
    public static final Map<String,String> CibilIdsTypeMap = new Map<String,String>{'PAN'=>'01','Passport Number'=>'02','Voter ID Number'=>'03','Driver’s License Number'=>'04','Aadhaar Number' =>'07'}; 
    public static final Map<String,String> CibilTelephonesTypeMap = new Map<String,String>{'Mobile Phone'=>'1','Home Phone'=>'2','Office Phone'=>'3'};
    public static final String LEAD_STAGE_NEW = 'New';
    public static final String INDIVIDUAL = 'Individual';
    public static final String SOLE_PROPRIETORSHIP = 'Sole Proprietorship';
     public static final String DATE_OF_BIRTH = 'Date_of_Birth__c';
    public static final String LOGIN_LOAN_APPLICATION_RECORD_TYPE = Schema.SObjectType.Loan_Application__c.getRecordTypeInfosByDeveloperName().get('Login').getRecordTypeId();
    public static final String CUSTOMER_ACCOUNT_RECORD_TYPE =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
    public static final String LAF_GENERATION_CONSENT = 'LAF Generation & Consent';
    public static final String ASSIGNED_TO_CREDIT = 'Assigned to Credit';
    public static final String UNDERWRITING_INITIATED_APPLICATION_RECORD_TYPE =Schema.SObjectType.Loan_Application__c.getRecordTypeInfosByDeveloperName().get('Underwriting_Initiated').getRecordTypeId();
    public static final String DISBURSEMENT_INITIATED_RECORD_TYPE = Schema.SObjectType.Loan_Application__c.getRecordTypeInfosByDeveloperName().get('Disbursement_Initiated').getRecordTypeId();
    public static final String BL_DISBURSEMENT_RECORD_TYPE = Schema.SObjectType.Disbursement__c.getRecordTypeInfosByDeveloperName().get('BL').getRecordTypeId();
    public static final String CV_CE_DISBURSEMENT_RECORD_TYPE = Schema.SObjectType.Disbursement__c.getRecordTypeInfosByDeveloperName().get('CV_CE').getRecordTypeId();
    public static final String DISBURSEMENT_RECORD_TYPE = Schema.SObjectType.Bank_Details__c.getRecordTypeInfosByDeveloperName().get('Disbursement').getRecordTypeId();

    public static final String PREDISBURSAL_DOCUMENT_COLLECTION_STAGE = 'Pre-Disbursal Document Collection';
    public static final String PD_IN_PROGRESS = 'PD in Progress'; 
    public static final String PD = 'PD';
    public static final String CPA_ACKNOWLEDGE = 'CPA Acknowledged';
    public static final String ACKNOWLEDGE_STATUS = 'Verified';
    public static final List<String> MY_STRING_LIST = new List<String>{'PD_DOCUMENT', 'CREATE_ACTIVITY'};
     public static final Set<String> ACTIVITY_RECORDTYPE_NAME_LIST = new Set<String>{'Office FI', 'Residence FI'};
          public static final Set<String> ACTIVITY_RECORDTYPE_NAME_LIST2 = new Set<String>{'Property Valuation','Legal'};
    public static final List<String> OBJECT_IDENTIFIER_LIST = new List<String>{'Loan_Application__c', 'Address__c','Loan_Applicant__c','Branch__c','Vehicle__c','Lead__c'};
    public static final String CREDIT_ASSESSMENT = 'Credit Assessment'; 
    public static final String RECOMMENDED_FOR_APPROVAL = 'Recommended for Approval';
    public static final String COMMITTEE_APPROVAL_NOTES_DOC_TYPE = 'Committee Approval Notes';
    public static final String GUATANTOR = 'Guarantor'; 
    public static final String LAF_FORM= 'LAF Form'; 
    public static final String LAF_FORM_SIGNED= 'LAF Form - signed';
    public static final String UPLOADED= 'Uploaded'; 
    public static final String LEAD= 'Lead__c'; 
    public static final String HIRE_VS_BUY= 'Hire vs Buy';
    public static final String HIRE= 'Hire';    
    public static final String ACTIVE_STATUS = 'Active';
    public static final String SANCTION_CONDITION_TYPE = 'Sanction Condition';
    public static final String DISBURSAL_IN_PROGRESS = 'Disbursal In Progress';
    public static final String NEGOTIATION_STAGE = 'Negotiation';
    
    public static final String FRAUD_FOUND = 'Fraud Found'; 
    public static final String FRAUD_NOT_FOUND = 'Fraud Not Found';
    public static final String APPROVED_STATUS = 'Approved';
    public static final String REJECTED_DEVIATION = 'Rejected';
    public static final String PENDING_STATUS = 'Pending';
    public static final String NO_REPLY_EMAIL_DISPLAY_NAME = 'noreply@domain.com';
    public static final String SANCTION_LETTER_EMAIL_TEMPLATE_NAME = 'Provisional_Sanction_Letter';
        
    public static final String SENT_FOR_REVIEW = 'Sent for Review';
    public static final String DEVIATION_ERROR = 'Please submit decision for deviations which are owned by you or your subordinates.';
	public static final String SCORECARD_ERROR = 'Kindly run the Scorecard for given Loan Application.';
    public static final String SCORECARD_ERROR_INITIATED = 'Kindly run the Scorecard for given Loan Application.';
    public static final String SCORECARD_ERROR_1 = 'Kindly run the Scorecard for given Loan Application.';
    public static final String CUSTOMER_TVR_ERROR = 'Please initiate the customer TVR for all the applicants.';
    public static final String DEALER_TVR_ERROR = 'Please initiate the dealer TVR for all the vehicles.';
    public static final String SANCTION_LETTER = 'Sanction_Letter';
    public static final String CIBIL_Non_INDIVIDUAL_ERROR = 'Please initiate the Cibil Api for all Applicants.';
    public static final String DISBURSEMENT_REJECTED = 'Rejected';
    public static final String DISBURSEMENT_DISBURSED = 'Disbursed';
    public static final String NO_DISBURSEMENTS = 'No Disbursements sent for approaval.';
    public static final String DISBURSEMENT_VALIDATION = 'Please select the vehicle type Chassis or Fully Built for the first disbursement.';
    public static final String SHERLOCK_HTML_EXTRA_CODE = '&lt;!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
    public static final String DISBURSMENT_NEGOTIATION = 'Negotiation';
    public static final String DISBURSMENT_PRE_DISBURSAL = 'Pre-Disbursal Document Collection';
    public static final String DISBURSMENT_DOCS_REVIEW = 'Documents Review';
    public static final String DISBURSMENT_NACH_PENDING = 'E-Nach Pending';
    public static final String DISBURSMENT_MAKER = 'Disbursement Maker';
    public static final String DISBURSMENT_CHECKER = 'Disbursement Checker';
    public static final String DISBURSMENT_PDD = 'PDD';
    public static final String DISBURSMENT_CLOSED = 'Closed';
    public static final String DISBURSMENT_DOC_NOTVERIFIED = 'Please acknowledge all documents to move forward';
     public static final String DISBURSMENT_SANCTION_CONDITION_NOTVERIFIED = 'Please acknowledge all sanction condition to move forward';
    public static final String DISBURSMENT_MAKER_DOC_NOTVERIFIED = 'Acknowledge status all documents should be either Waived Off, Completed or PDD to move forward';
    public static final String DISBURSMENT_OPEN_QUERY = 'Please complete all the Task to move forward';
    public static final String DISBURSMENT_CBS_ERROR = 'Please Fill CIF and UCID on Non Individual Applicant.';
    public static final String DISBURSMENT_CBS_API_ERROR = 'Please Initiate CBS Api.';
    public static final String DISBURSMENT_ACTIVITY = 'Please Complete the RCU activity ';
    public static final String DISBURSMENT_MEMO = 'Please Complete the Disbursement Memo process';
    public static final String DISBURSMENT_INITIATE = 'Before move to next please verify this disburment ';
    public static final String DISBURSMENT_CM_ERROR = 'Credit Manager field is blank';
    public static final String DISBURSMENT_LETTERS_ERROR = 'Please generate letters for this disbursement before move to next';
    public static final String DISBURSMENT_ERROR = 'Kindly Upload all the required documents in Pre-Disbursal chekclist and Sanction Condition (if any)';
    public static final String DISBURSMENT_SANCTIONLETTER_REQUIRED = 'Please generate the Sanction Letter before move to next';
    public static final String DISBURSMENT_REPAYMENT_SCHEDULE_REQUIRED = 'Please generate the Repayment Schedule  before move to next';
    public static final String INSURANCE_API_REQUIRED = 'Kindly run the Insurance API to move to next stage';
    public static final String ACTIVITY_CM = 'CM Acknowledged';
    public static final String ACTIVITY_RCU = 'RCU Acknowledged';
     public static final String ACK_STATUS_WAIVED_OFF = 'Waived Off';
     public static final String ACK_STATUS_Completed = 'Completed';
    public static final String ACK_STATUS_PDD = 'PDD';
    public static final String ACK_OPEN_QUERY = 'Please update the acknowledge status as Verify, OTC or PDD to move forward.';
    
    public static final String ACTIVITY_SAMPLED = 'Sampled';
    public static final String ACTIVITY_SCREENED = 'Screened';
    public static final String ACTIVITY_PENDING = 'Pending';
    public static final String AMOUNT = 'Amount';
    public static final String CPC_AGENT_MAKER_QUEUE = 'CPC_Agents_Queue';
     public static final String CPC_AGENT_CHECKER_QUEUE = 'CPC_Agents_Checker_Queue';
    public static final String QUEUE = 'Queue';
     public static final String FEELABEL = Label.Fee_mapping;
    public static final String VERIFIED_ERROR = 'Verified is required for all the documents';
    public static final String QUOTE_VERIFICATION_RECORD_TYPE_NAME = 'Quote Check';
    public static final String QUOTE_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Quote Check').getRecordTypeId();
	 public static final String PURCHASE_OF_CV = 'Purchase of Commercial Vehicle';
     public static final String PURCHASE_OF_CE = 'Purchase of Construction Equipment';
     public static final String COMMERICIAL = 'Commercial';
     public static final String CONSTRUCTION = 'Construction';
    public static final String NEW_VEHICLE = 'New Vehicle';
    public static final String USED_VEHICLE = 'Used Vehicle';
    public static final String PARTNER_VERIFICATION_RECORD_TYPE_NAME = 'Partner Api Verification';
    public static final String PARTNER_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Partner Api Verification').getRecordTypeId();

    // Added By Manjeet on 25-07-2024
    public static final String TYPE = 'type';
    public static final String PARENT_ID = 'parentId';
    public static final String TOKEN_GENERATE_API  = 'Token_Generate_API';
    public static final String AADHAR_NUMBER  = 'aadharNumber';
    public static final String FILE_BASE_64  = 'filebase64';
    public static final String FILE_NAME  = 'fileName';
    public static final String NON_INDIVIDUAL  = 'Non Individual';
    
    public static final String CONSENT  = 'Consent';
    public static final String PAN  = 'PAN';
    public static final String AADHAR_VERIFICATION  = 'Aadhar_Verification';
    public static final String AADHAR_IMAGE_MASKING  = 'Aadhar_Image_Masking';
    public static final String DEDUPE_CHECK  = 'Dedupe_Check';
    public static final String CIBIL_TYPE  = 'CIBIL';
    
    public static final String REGISTRATION_NUMBER  = 'registrationNumber';
    public static final String CASE_ID  = 'caseId'; 
    //public static final String VEHICLE_ASS_COLL_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('Vehicle Asset Collateral API Verification').getRecordTypeId();
}