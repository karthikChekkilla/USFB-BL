/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class UB_RepaymentSchedule {

    Public List<RepaymentScheduleWrapper> wrapperList{get; set; }

    public static Date getFirstEmiDate(Date disbursmentDate) {
        System.debug('disbursmentDate  '+disbursmentDate);
        System.debug('disbursmentDate.day()  '+disbursmentDate.day());
        Date firstDayOfNextMonth = System.today().toStartOfMonth().addMonths(1);
        System.debug('firstDayOfNextMonth  '+firstDayOfNextMonth);
        Date FirstEmiDate ;

        if(disbursmentDate.day() >= 1 &&  disbursmentDate.day() <= 10) {
            FirstEmiDate = firstDayOfNextMonth.addDays(6);

        } else if(disbursmentDate.day() >= 1 &&  disbursmentDate.day() <= 22) {
            FirstEmiDate = firstDayOfNextMonth.addDays(14);

        } else {
            firstDayOfNextMonth = firstDayOfNextMonth.addMonths(1);
            FirstEmiDate = firstDayOfNextMonth.addDays(6);

        }
        SYstem.debug('FirstEmiDate  '+FirstEmiDate);
        return FirstEmiDate;
    }

    public UB_RepaymentSchedule(ApexPages.StandardController controller){
        system.debug('ZAFARRRRRRRRRRRRR');
        String  disbursementId = apexpages.currentPage().getParameters().get('id'); 
        System.debug('disbursementId   '+disbursementId);
        List<Disbursement__c> disbursement = [SELECT Id,Tenure__c,ROI__c,Loan_Amount__c From Disbursement__c WHERE Id=:disbursementId];
        System.debug('disbursementdisbursement ' +disbursement);
        if(!disbursement.isEmpty()) {
            String repaymentJson = UB_RepaymentSchedule.repaymentScheduleData( Integer.valueOf(disbursement[0].Tenure__c),disbursement[0].ROI__c,disbursement[0].Loan_Amount__c) ;
            System.debug('repaymentJson  for PDF  '+repaymentJson);
            wrapperList = ( List<RepaymentScheduleWrapper>)JSON.deserialize(repaymentJson, List<RepaymentScheduleWrapper>.class);
            System.debug('wrapperList  for PDF  '+wrapperList);

        }

    }

    
    @AuraEnabled(cacheable=true)
    public static List<Vehicle__c> getVehicleDetails(String loanApplicationId){
        List<Vehicle__c>  vehiclesList= new List<Vehicle__c>();
        if(String.isNotBlank(loanApplicationId)) {
            vehiclesList = [SELECT Id,Name,ROI__c,Tenure__c,Vehicle_Cost__c,Credit_Facility_Amount__c FROM Vehicle__c WHERE Loan_Application__c=:loanApplicationId AND ROI__c != NULL AND Tenure__c != NULL AND Credit_Facility_Amount__c != NULL AND EMI__c != NULL];
        }
        return vehiclesList;
    }

    @AuraEnabled
    public static decimal getPMT(Decimal rate, Decimal nper, Decimal pv){
        rate = (rate/100)/12;
        Double doubleValue = 1 + rate;
        Double exponent = nper;
        Decimal pvif = Math.pow( doubleValue,exponent );
        Decimal pmt =  ((pv*(rate))*pvif)/(pvif - 1);
        System.debug('getPMT ^^^^^^ '+ pmt);
        return  Math.ceil( pmt);
    }

    // Method to calculate Emi Payment Table
    @AuraEnabled
    public static String repaymentScheduleData( Integer tenure, Decimal roi, Decimal vehicleCost){
        
        List<RepaymentScheduleWrapper> wrapperList = new List<RepaymentScheduleWrapper>();
        try {
            Decimal emi =  UB_RepaymentSchedule.getPMT(roi, tenure, vehicleCost);
            System.debug('EMIIIIIIIIIIII    '+emi);
            Date emiDate;
            Decimal oB = 0;
            Integer actualDays = 0;
            Decimal totalInterest = 0;
            //Integer tenure = Integer.valueOf(repayment.get('tenure'));
            System.debug('tenure  '+tenure);
            System.debug('roi  '+roi);
            System.debug('vehicleCost  '+vehicleCost);
            //Decimal APR = 0.0;


            Date firstEmiDate = UB_RepaymentSchedule.getFirstEmiDate(System.today());
            System.debug('  FIRST EMI DATE  '+ firstEmiDate);
            Date lastLoanDate = firstEmiDate.addMonths( tenure)  ;
            System.debug('  lastLoanDate  '+ lastLoanDate);

            Integer totalLoanDays = firstEmiDate.daysBetween(lastLoanDate);
            System.debug('totalLoanDays  '+totalLoanDays);
            Decimal avgOpeningBalance = 0;
            for (Integer i = 1;  i <= tenure; i++) {                
                if(i == 1) {
                    emiDate = firstEmiDate;
                    oB = vehicleCost;
                    actualDays =  System.today().daysBetween(firstEmiDate) ;
                }
                RepaymentScheduleWrapper wrapperRecord = new RepaymentScheduleWrapper();
                wrapperRecord.emiNo = i;
                wrapperRecord.emiDate =  emiDate;
                wrapperRecord.openingBalance =  oB;
                avgOpeningBalance += oB;
                if(i == tenure && oB > Math.round(emi)) {
                    wrapperRecord.emi = oB;
                }
                else {
                    wrapperRecord.emi =  Math.round(emi) ;
                }
                wrapperRecord.daysInYear = (  ( math.mod(system.today().year(),4) == 0 &&  math.mod(system.today().year(),100) != 0 ) ||  math.mod(system.today().year(),400) == 0 ) ==true ? 366 : 365 ;
                wrapperRecord.actualDays = actualDays;
                wrapperRecord.roi = roi/100 ;
                wrapperRecord.interest = Math.ceil(( oB *  wrapperRecord.actualDays * wrapperRecord.roi ) / wrapperRecord.daysInYear)    ;
                totalInterest += wrapperRecord.interest ;
                wrapperRecord.principle =   wrapperRecord.emi - wrapperRecord.interest ;
                wrapperRecord.closingBalance = ( i == tenure ) ? 0 :  wrapperRecord.openingBalance - wrapperRecord.principle ;
                emiDate = wrapperRecord.emiDate.addMonths(1);
                oB = wrapperRecord.closingBalance ;
                actualdays =  wrapperRecord.emiDate.daysBetween(emiDate);
                wrapperList.add(wrapperRecord);
                System.debug('wrapperRecord   '+wrapperRecord);
            } 
            System.debug('wrapperList   '+wrapperList);
            /*
            APR =  ( ( loanRecord.Final_PF__c +  totalInterest + loanRecord.Broken_Period_Interest__c  ) /Math.round( avgOpeningBalance/Integer.valueOf(loanRecord.Applied_Tenure_in_Months__c) ) ) / totalLoanDays  * 365 * 100 ;
            System.debug('APR  '+APR);
            System.debug('APR+++++++++  '+loanRecord.APR__c);
            if(APR > 0 && loanRecord.APR__c != APR) {
                System.debug('YESSS UPDATEEEEEE');
                loanRecord.APR__c = APR;
                loanRecord.Total_Interest_on_Loan__c = totalInterest + loanRecord.Broken_Period_Interest__c ;
                update loanRecord;
            }  */  
        } catch (Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        return json.serialize(wrapperList);
    }
    
    //Added by Musab || 16-07-2024 || Method is used to updated EMI date fields
    @AuraEnabled
    public static void updateDisbursementAndEMIDate(String recordId){
        try{
        Disbursement__c disburseObj = [SELECT Id,Loan_Amount__c,Tenure__c,ROI__c from Disbursement__c WHERE Id =: recordId];
        Disbursement__c disburseInstance = new Disbursement__c();
        disburseInstance.Id = recordId;
        disburseInstance.First_EMI_Date__c = UB_RepaymentSchedule.getFirstEmiDate(System.today());
        disburseInstance.Last_Emi_Date__c = disburseInstance.First_EMI_Date__c.addMonths(Integer.valueOf(disburseObj.Tenure__c)-1);
        disburseInstance.EMI_Amount__c = UB_RepaymentSchedule.getPMT(disburseObj.ROI__c,disburseObj.Tenure__c,disburseObj.Loan_Amount__c);
        disburseInstance.Disbursment_Date__c = System.today();
        update disburseInstance;
        }
        catch(exception e){
        System.debug('the exception is >>'+e.getLineNumber()+'Exception message is >>'+e.getMessage());
        }
    }

    public  class RepaymentScheduleWrapper {

        public Integer emiNo{get; set;}
        public Date emiDate{get; set;}
        public Decimal openingBalance{get; set;}
        public Decimal emi{get; set;}
        public Decimal interest{get; set;}
        public Decimal principle{get; set;}
        public Decimal closingBalance{get; set;}
        public Decimal roi{get; set;}
        public Integer daysInYear{get; set;}
        public Integer actualDays{get; set;}


    }

}