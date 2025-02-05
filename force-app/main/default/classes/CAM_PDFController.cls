/**
* @File Name          : CAM_PDFController.cls
* @Description        : This class used to fetch data for CAM report.
* @Author             : Mohd Musab
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         09-07-2024               Mohd Musab                Initial Version
*/
public class CAM_PDFController {
    public Loan_Application__c applicationId { get; set; }
    public Loan_Application__c loanApplicationObj { get; set; }
    public List<Vehicle__c> newVehicleList { get; set; }
    public List<Vehicle__c> usedVehicleList { get; set; }
    public List<Loan_Applicant__c> primaryApplicantList {get; set;}
    public List<Loan_Applicant__c> coApplicantList {get; set;}
    public List<Loan_Applicant__c> guarantorApplicantList {get; set;}
    public List<Deviation_Sanction_Condition__c> deviationSanctionList {get; set;}
    public List<Deviation_Sanction_Condition__c> deviationDecisionSheet {get; set;}
    public List<Activity_History__c> activityHistoryList {get; set;}
    public Financial_Assessment__c financialAssessment{get;set;}
    public List<Valuation__c> applicantActivityFI{get;set;}
    public List<Valuation__c> applicantActivityOffice{get;set;}
    public List<Valuation__c> applicantActivityRCU{get;set;}
    public String loginDate {get; set;}
    public String internalDedupeStatus {get; set;}
    public String IsDirectorSrOfficer {get; set;}
    public String decisioningOfficeName {get;set;}
    public String recommendedOfficerName {get;set;}
    public String recommendedOfficerSignature {get;set;}
    public String decisioningOfficerSignature {get;set;}
    public String formattedDate {get; set;}
    public String lastModifiedDate {get; set;}
    public String decisioningStatus {get; set;}
    public CAM_PDFController() {
        try
        {
            Date currentDate = Date.today();
            DateTime currentDateTime = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
            formattedDate = currentDateTime.format('dd-MMMM-yyyy');
            Id applicationId = ApexPages.currentPage().getParameters().get('id');
            if (applicationId != null) {
            loanApplicationObj = new UB_LoanApplicationsSelector().getLoanApplicationRecord(applicationId);
            System.debug('loanApplicationObj '+ loanApplicationObj);
            loginDate = loanApplicationObj.createdDate.format('yyyy-MM-dd');
            lastModifiedDate = loanApplicationObj.LastModifiedDate.format('dd-MMMM-yyyy');
            if(loanApplicationObj.Duplicate_LAF_Id__c != null){
                internalDedupeStatus = 'Match Found';
            }
            else{
                internalDedupeStatus = 'No Match Found';
            }
            System.debug('internalDedupeStatus  '+internalDedupeStatus);
            newVehicleList = new UB_VehiclesSelector().selectByLoanApplicationIdforVehicle(applicationId,'New Vehicle');
            System.debug('newVehicleList '+newVehicleList);
            usedVehicleList = new UB_VehiclesSelector().selectByLoanApplicationIdforVehicle(applicationId,'Used Vehicle');
            System.debug('usedVehicleList '+usedVehicleList);

            primaryApplicantList = new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{applicationId},UB_ConstantsUtil.APPLICANT);
            System.debug('primaryApplicantList '+primaryApplicantList);

            IsDirectorSrOfficer = primaryApplicantList[0].Working_in_a_bank_as_director_Sr_Office__c;
            System.debug('2222222222222  ');

            coApplicantList = new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{applicationId},UB_ConstantsUtil.CO_APPLICANT);
            System.debug('coApplicantList '+coApplicantList);

            guarantorApplicantList = new UB_LoanApplicantsSelector().getApplicants(new Set<Id>{applicationId},UB_ConstantsUtil.GUATANTOR);
            System.debug('guarantorApplicantList '+guarantorApplicantList);

            deviationSanctionList = [SELECT Id,Deviation_Description__c,Approving_Authority__c,Deviation_Type__c,Mitigants__c,Decision__c, Approved_Rejected_By__c,
                                     Type__c,Loan_Application__c from Deviation_Sanction_Condition__c
                                     WHERE Loan_Application__c =: applicationId AND Type__c = 'Deviation'];

            System.debug('deviationSanctionList '+deviationSanctionList);


            deviationDecisionSheet = [SELECT Id,Reason_Special_Condition__c,Reason_Comments__c,CreatedBy.Name,CreatedDate,
            Type__c,Loan_Application__c,Approving_Authority__c from Deviation_Sanction_Condition__c
            WHERE Loan_Application__c =: applicationId AND Type__c = 'Special Condition'];                             
            System.debug('deviationDecisionSheet '+deviationDecisionSheet);
            financialAssessment = [SELECT Id,DSCR_should_be_1__c, TOL_TNW__c, Current_Ratio__c,Loan_Application__c
                                       from Financial_Assessment__c WHERE Loan_Application__c =: applicationId  Order by Year__c desc LIMIT 1];    
                                       
            System.debug('financialAssessment '+financialAssessment);
            applicantActivityFI = new UB_ActivitySelector().selectByApplicantId(primaryApplicantList[0].Id, 'Residence FI');
            applicantActivityOffice = new UB_ActivitySelector().selectByApplicantId(primaryApplicantList[0].Id, 'Office FI');
            applicantActivityRCU = new UB_ActivitySelector().selectByApplicantId(primaryApplicantList[0].Id, 'RCU');        
            activityHistoryList = new UB_ActivityHistoriesSelector().selectLatestByLoanApplicationId(new Set<Id>{applicationId});
            System.debug('applicantActivityFI '+applicantActivityFI);
            System.debug('applicantActivityOffice '+applicantActivityOffice);
            System.debug('applicantActivityRCU '+applicantActivityRCU);
            System.debug('activityHistoryList '+activityHistoryList);
            if(loanApplicationObj.Loan_Application_Status__c == UB_ConstantsUtil.APPROVED_STATUS){
                decisioningStatus = UB_ConstantsUtil.APPROVED_STATUS;
                recommendedOfficerName = activityHistoryList.size()>0 ? activityHistoryList[0].From_User__r.Name : '';
                decisioningOfficeName = UserInfo.getName();
                recommendedOfficerSignature = activityHistoryList.size()>0 ? activityHistoryList[0].From_User__r.Name + ' ' + activityHistoryList[0].From_User__r.EmployeeNumber +' '+ loanApplicationObj.LastModifiedDate.format('yyyy-MM-dd') : '';
                decisioningOfficerSignature = UserInfo.getName() + ' ' + loanApplicationObj.LastModifiedDate.format('dd-MMMM-yyyy');
            }
            else{
                decisioningStatus = 'Recommended for Approval';
                recommendedOfficerName = UserInfo.getName();
                decisioningOfficeName = 'NA';
                recommendedOfficerSignature = UserInfo.getName()  + ' ' + loanApplicationObj.LastModifiedDate.format('dd-MMMM-yyyy');
                decisioningOfficerSignature = 'NA';
                
            } 
        }                                        
        }
        catch (Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }

	@AuraEnabled
    @Future(callout=true)
    public static void linkCamToDocument(String loanId) {
        try {
            List<Document__c> camDOcument = [SELECT Id FROM Document__c WHERE Document_Type__c='CAM Report' AND Loan_Application__c =:loanId];
            System.debug('lafDOcument   '+camDOcument);
            System.debug('loanId ID  '+loanId);
            Blob b ;
            if(loanId != null ) {
                PageReference PDf =  Page.CV_CAM_PDF;
                System.debug('PDfPDfPDf  '+PDf);
                PDf.getParameters().put('Id',loanId);
                System.debug('1AAAAAAAAAAAAAA');
                PDf.setRedirect(false);
                b = PDf.getContentAsPdf();
                System.debug('1BBBBBBBBBBBBBBBBB'+b );

                UB_CommonUtil.createDocument('CV CAM','CV CAM.pdf', b,loanId, NULL,'CAM Report','CAM Report with time stamp and Version number');
                Loan_Application__c loanApplication = new Loan_Application__c();
                loanApplication.Id = loanId;
                loanApplication.Cam_Generate__c = false;
                update loanApplication;
            } 
        } catch (Exception e) {
            System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }

}