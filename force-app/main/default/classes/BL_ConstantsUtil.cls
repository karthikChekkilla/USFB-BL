/**
* @File Name          : BL_ConstantsUtil.cls
* @Description        : This class will have all the constants defined to be used in various other classes
* @Author             : Mohit
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         04-07-2024            Mohit Saxena             Initial Version
**/
public class BL_ConstantsUtil {
    public static final String LOB_BL = 'BL';
    public static final String FLOATING_INTEREST_TYPE = 'Floating';
    public static final String PORTAL_PROFILE_NAME_BL = 'USFB BL - Partner Community User';
    public static final String BL_LEMS_LEAD_RECORDTYPE = Schema.SObjectType.Lead__c.getRecordTypeInfosByName().get('BL LeMS Lead').getRecordTypeId();
    public static final String BL_Partner_Portal_Lead_RecordType = Schema.SObjectType.Lead__c.getRecordTypeInfosByName().get('BL Partner Portal Lead').getRecordTypeId();
    public static final String BL_DISBURSEMENT_RECORD_TYPE = Schema.SObjectType.Disbursement__c.getRecordTypeInfosByDeveloperName().get('BL').getRecordTypeId();
    public static final String BL_PRODUCT_CATEGORY = 'Business Loan';
    public static final String BUSINESS_LOAN_PLUS_CATEGORY = 'Business Loan Plus';
    public static final String SOLE_PROPRIETORSHIP_CONSTITUTION = 'Sole Proprietorship';
    public static final String INDIVIDUAL_CONSTITUTION = 'Individual';
    public static final String APPLICANT = 'Applicant';
    public static final String BL_CO_APPLICANT = 'Co-Applicant';
    public static final String BL_GAURANTOR = 'Guarantor';
    public static final String BL_INDIVIDUAL = 'BL Individual';
    public static final String BL_NON_INDIVIDUAL = 'BL Non Individual';
    public static final String BL_INDIVIDUAL_APPICANT_RECORD_TYPE = Schema.SObjectType.Loan_Applicant__c.getRecordTypeInfosByName().get('BL Individual').getRecordTypeId();
    public static final String BL_NON_INDIVIDUAL_APPICANT_RECORD_TYPE = Schema.SObjectType.Loan_Applicant__c.getRecordTypeInfosByName().get('BL Non Individual').getRecordTypeId();
    public static final String MCA_DOCUMENTS_VERIFICATION_RECORD_TYPE = Schema.SObjectType.Verification__c.getRecordTypeInfosByName().get('MCA-Documents').getRecordTypeId();
    public static final String CIBIL_OBLIGATION_VERIFY_LINE_ITEM_RECORD_TYPE = Schema.SObjectType.Verification_Line_Item__c.getRecordTypeInfosByName().get('CIBIL Obligation').getRecordTypeId();
    public static final String REPAYMENT_BANKING_DETAILS_RECORD_TYPE = Schema.SObjectType.Bank_Details__c.getRecordTypeInfosByName().get('Repayment').getRecordTypeId();
    
    public static final String COMPLETEDSTATUS = 'Completed';
    public static final String FAILED_STATUS = 'Failed';
    public static final String REST_API_TYPE = 'REST';
    public static final List<String> CATEGORYREQUIRED = new List<String>{'ARBE', 'CRGD', 'INC', 'CDRD', 'CETF', 'OTRE','LLPF','OTRA'};
        public static final String REJECTION_TYPE = 'Hard'; 
    public static final String LOGIN = 'Login';
    public static final String REJECTION_LETTER = 'Rejection_Letter_BL';
    public static final String MCA_API = 'MCA_API';
    public static final String OFFICE_ADDRESS = 'Office Address';
    public static final String RESIDENCE_ADDRESS = 'Residence Address';
    public static final String PERMANENT_ADDRESS = 'Permanent Address';
    public static final Set<String> ACTIVITY_RECORDTYPE_NAME_LIST = new Set<String>{'Office FI', 'Residence FI'};
        public static final String VERIFIED_ERROR = 'Acknowledge/Verify all required documents in Document Checklist';
    
    public static final String PERMANENT_FI_APP_VALLIDATION  = 'Please kindly Initiate Permanent FI for Primary Applicant.'; 
    public static final String RESIDENCE_FI_APP_VALLIDATION  = 'Please kindly Initiate Residence FI for Primary Applicant.'; 
    public static final String OFFICE_FI_APP_VALLIDATION  = 'Please kindly Initiate Office FI for Primary Applicant.'; 
    
    public static final String PERMANENT_FI_CO_APP_VALLIDATION  = 'Please kindly Initiate Permanent FI for Co Applicant.'; 
    public static final String RESIDENCE_FI_CO_APP_VALLIDATION  = 'Please kindly Initiate Residence FI for Co Applicant.'; 
    public static final String OFFICE_FI_CO_APP_VALLIDATION  = 'Please kindly Initiate Office FI for Co Applicant.'; 
    
    public static final String PERMANENT_FI_GUARANT_VALLIDATION  = 'Please kindly Initiate Permanent FI for Guarantor.'; 
    public static final String RESIDENCE_FI_GUARANT_VALLIDATION  = 'Please kindly Initiate Residence FI for Guarantor.'; 
    public static final String OFFICE_FI_GUARANT_VALLIDATION  = 'Please kindly Initiate Office FI for Guarantor.'; 
    
    public static final String RESIDENCE_FI  = 'Residence FI'; 
    public static final String OFFICE_FI  = 'Office FI'; 
    public static final String AADHAAR_IDENTITY_PROOF = 'UID (Aadhaar)';
    public static final String PERMANENT_FI  = 'Permanent FI'; 
    public static final String RCU  = 'RCU'; 
    public static final String AUTHORISED_SIGNATORY_TYPE = 'Authorised Signatory'; 
    public static final String RCU_VENDOR_RECORDTYPE = Schema.SObjectType.Valuation__c.getRecordTypeInfosByName().get('RCU Vendor').getRecordTypeId();
    public static final String REFERENCE_ERROR  = 'Please add at least 2 references for this application'; 
    public static final String BANK_ERROR  = 'Please add Repayment & Disbursement Bank Details'; 
    public static final String DISBURSEMENT  = 'Disbursement'; 
    public static final String REPAYMENT  = 'Repayment'; 
    public static final String RCU_ACTIVITY_MSG  = 'Please initiate RCU Activity.'; 
    public static final String BANKING_ANALYSIS_ERROR  = 'Please initiate the banking analysis for <b>'; 
    public static final String IS_COMM_YES  = ': Is Communication must be Yes for any one address.'; 
}