/**
* @File Name          : Ub_Sanction_Letter_Template_Controller.cls
* @Description        : This class use to map sanction lettee .
* @Author             : Mansur
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         17-06-2024            Mansur         Initial Version           
**/
public class Ub_Sanction_Letter_Template_Controller{
    
    public String plainHTML { get; set; }
    public String loanId{get;set;}   
    public Ub_Sanction_Letter_Template_Controller(ApexPages.StandardController controller) {
        //loanId = apexpages.currentPage().getParameters().get('Id');
    }
    public void getPDF(){
        try {
            loanId = apexpages.currentPage().getParameters().get('Id');
            System.debug('VALUEEEEEEEEEEEEE  '+loanId);
            plainHTML = createEmailBody(loanId);
        }catch(Exception e) {
            System.debug('ERRORRRRRRRRRR    '+e.getMessage());
            System.debug('Line   No'+e.getLineNumber());
        }
    }
    public static String createEmailBody(String loanApplicationId){
        List<String> coApp = new list<String>();
        String productCat = '';
        Decimal TOTAL_VEHICLE = 0;
        Decimal TOTAL_VEHICLE_COST = 0;
        Decimal TOATL_MARGIN_MONEY = 0;
        String add1 = '';
        String add2 = '';
        String add3 = '';
        String COAPP1 = '';
        String COAPP2 = '';
        String GUARTNTOR = '';
        Map<String,Loan_Applicant__c> applicantMap = new Map<String,Loan_Applicant__c>();
        List<Loan_Application__c>  loanAppObj = new UB_LoanApplicationsSelector().selectById(new Set<Id>{loanApplicationId});
        
        System.debug('**loanAppObj->   '+loanAppObj );
        System.debug('Loan Applicant >   '+loanAppObj[0].Loan_Applicants__r);
        if(!loanAppObj.isEmpty()){
            
            System.debug('>>>>>> ' + !loanAppObj[0].Loan_Applicants__r.isEmpty());
            if(!loanAppObj[0].Loan_Applicants__r.isEmpty()){
                for(Loan_Applicant__c app : loanAppObj[0].Loan_Applicants__r){
                    if(app.Applicant_Type__c == UB_ConstantsUtil.CO_APPLICANT){
                        coApp.add(app.Account_Name__c);
                    }else{
                        applicantMap.put(app.Applicant_Type__c, app);
                    }
                }
            }
            if(!loanAppObj[0].Products__r.isEmpty()){
                String[] sp = loanAppObj[0].Products__r[0].Product_Category__c.split('-');
                productCat= sp[0];
                System.debug('productCat->   '+ productCat );
            }
            List<Address__c>  addressObj = new UB_AddressesSelector().getApplicantAddress(new Set<Id>{applicantMap.get(UB_ConstantsUtil.APPLICANT).id});
            System.debug('addressObj->   '+addressObj );
            if(!addressObj.isEmpty() && addressObj.size()> 0 ){
                add1 = addressObj[0].Name +' '+ (addressObj[0].Address_Line_2__c!=null ? addressObj[0].Address_Line_2__c : '');
                add2= (addressObj[0].Address_Line_3__c != null ? addressObj[0].Address_Line_3__c : '' ) +' '+ addressObj[0].City__c+' '+ addressObj[0].District__c;
                add3 = addressObj[0].State__c +' '+  addressObj[0].Pincode__r.Name +' '+ addressObj[0].Country__c;
            }
            List<Vehicle__c >  vehicleObj = new UB_VehiclesSelector().selectByLoanApplicationId(new Set<Id>{loanApplicationId});
            System.debug('applicantMap->   '+applicantMap );
            EmailTemplate tempID = [SELECT Id,Name,Body,HTMLValue FROM EmailTemplate WHERE DeveloperName  =: UB_ConstantsUtil.SANCTION_LETTER_EMAIL_TEMPLATE_NAME];
            String emailBody = tempID.Body;
            if(vehicleObj.size() > 0){
                System.debug('vehicleObj>>>> ' + vehicleObj);
                for(Vehicle__c  vehicle :vehicleObj ){
                    TOATL_MARGIN_MONEY = TOATL_MARGIN_MONEY + (vehicle.Margin_Money__c != null ? vehicle.Margin_Money__c : 0);
                    TOTAL_VEHICLE = TOTAL_VEHICLE + (vehicle.Number_Of_Vehicles__c != null ? vehicle.Number_Of_Vehicles__c : 0);
                    TOTAL_VEHICLE_COST = TOTAL_VEHICLE_COST + ((vehicle.Number_Of_Vehicles__c != null ? vehicle.Number_Of_Vehicles__c : 0) * (vehicle.Vehicle_Cost__c != null ? vehicle.Vehicle_Cost__c : 0));
                }
            }
            if(coApp.size()==1){
                COAPP1 = coApp[0];
            }
            else if(coApp.size() > 1){
                 COAPP1 = coApp[0];
                COAPP2 = coApp[1];
            }
            if(applicantMap.containsKey(UB_ConstantsUtil.GUATANTOR)){
                GUARTNTOR = applicantMap.get(UB_ConstantsUtil.GUATANTOR).Account_Name__c;
            }
             emailBody = emailBody.replace('co_Applicant_Name1',COAPP1);
              emailBody = emailBody.replace('co_Applicant_Name2',COAPP2);
            emailBody = emailBody.replace('applicant_Name',applicantMap.get(UB_ConstantsUtil.APPLICANT).Account_Name__c);
            emailBody = emailBody.replace('guarantor_Name', GUARTNTOR);
            emailBody = emailBody.replace('Address1', add1  );
            emailBody = emailBody.replace('Address2', add2);
            emailBody = emailBody.replace('Address3', add3);
            emailBody = emailBody.replace('productCategory',productCat);
            emailBody = emailBody.replace('application_Number',loanAppObj[0].Name);
            emailBody = emailBody.replace('today_Date',String.valueOf(System.today()));
            emailBody = emailBody.replace('marginMoney',String.valueOf(TOATL_MARGIN_MONEY));
            emailBody = emailBody.replace('creditInsuranceAmount','0');
            emailBody = emailBody.replace('loan_Amount', String.valueOf(loanAppObj[0].Amount__c) != null ? String.valueOf(loanAppObj[0].Amount__c) : '0');
            emailBody = emailBody.replace('ROI',String.valueOf(loanAppObj[0].ROI__c) != null ? String.valueOf(loanAppObj[0].ROI__c) : '0');
            emailBody = emailBody.replace('maximumTenor',String.valueOf(loanAppObj[0].Loan_Period__c) != null ? String.valueOf(loanAppObj[0].Loan_Period__c):'0');
            System.debug(' TOTAL_VEHICLE >   '+ TOTAL_VEHICLE + 'TOTAL_VEHICLE_COST>> '+ TOTAL_VEHICLE_COST );
            emailBody = emailBody.replace('total_Vehicles',String.valueOf(TOTAL_VEHICLE));
            emailBody = emailBody.replace('total_Vehicle_Cost',String.valueOf(TOTAL_VEHICLE_COST));
            System.debug('emailBody after change>   '+ emailBody );
            return emailBody;
        } 
        return null;
    }
}