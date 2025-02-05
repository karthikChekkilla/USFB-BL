/**
* @File Name          : UB_FanancialCalcutionHelper.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         12-05-2024            Zafaruddin         Initial Version

**/

public with sharing class UB_FanancialCalcutionHelper {

    /**
    * @description  function to get financial record from metadata if records not created else will take from database.
    * @author Zafaruddin | 05-17-2024 
    * @param loanId 
    * @return String 
    **/
    @AuraEnabled
    public static String getFinancialData(String loanId) {
        List<FinancialWraper> wrapperList = new List<FinancialWraper>();
        try {
            System.debug('LOAN IDDDDDDDDDDD  '+loanId);
            Integer count = 1;
            Map<Integer,Financial_Assessment__c> finalAssessmentMap = new Map<Integer,Financial_Assessment__c>();
            for(Financial_Assessment__c financialRecord : [SELECT Id,Financial_Type__c, Year__c,Proposed_Loan__c,Capital__c,Reserves_surplus__c,Add_Profit_for_the_year__c,Total_Networth__c,Secured_loans_excluding_Bank_ODCC__c,Bank_ODCC__c,Unsecured_loans_from_Outsiders__c,Unsecured_loans_from_FriendsDirectors__c,Deferred_tax_balance__c,Current_Liability_Provisions__c,Sundry_Creditors_in_above__c,Total_Liabilities__c,
                                                                    Total_long_term_liabilities__c,Fixed_Assets__c,Investment__c,Current_Assets_Loans_Adv__c,Debtors_as_in_Above__c,Total_Assets__c,Gross_Receipts_TurnoverSales__c,Other_Income_not_relevant_to_key_buss__c,Total_Income_financials__c,Freight_Paid__c,Depreciation__c,Net_Profit__c,Tax_Expense__c,Financial_Expenses_Interest_and_chaerges__c,Cash_Profits_Depriciation_Net_Profit__c,PBDIT_Profit_before_depricaition__c,Sundry_Debtors_less_than_6_months__c,Sundry_Debtors_6_months__c,Total_Sundry_Debtors__c,
                                                                    ICOR_Interest_coverage_ratio__c,DSCR_Debt_Service_Coverage_Ratio__c,Current_Ratio__c,Leverage__c,Long_term_leverage_Debt_Equity_Ratio__c,TOL_TNW__c,Debtor_Turnover_Days__c,Creditor_Turnover_Days__c,NW__c,Turnover__c,Cash_Profit__c,Cash_Profit_percent__c,Net_Profit_percent__c,DSCR_including_proposed_should_be_1__c,TOL_TNW_should_be_6__c,Debtors_Turnover_should_be_90_days__c,Current_Ratio_should_be_11__c,DSCR_including_proposed_should_be_12__c,TOL_TNW_should_be_4__c,Current_Ratio_should_be_12__c,Net_Worth__c,Long_Term_Debt__c,PBDIT__c,Year_on_Year_Turnover_not_less_than_15__c,Year_on_Year_Profit_should_be_Positive__c,Year_on_Year_Net_Profit__c,Year_on_Year_NW__c,Long_Term_Debt_Net_Worth__c,DSCR_should_be_1__c,Debtors_Turnover_Days_should_be_75__c  FROM Financial_Assessment__c WHERE Loan_Application__c=:loanId AND RecordTypeId=:UB_ConstantsUtil.FINANCIAL_RECORD_TYPE Order BY Year__c ASC]) {
                finalAssessmentMap.put(count,financialRecord);
                count += 1;
            } 
            System.debug('finalAssessment  SIZE   '+finalAssessmentMap.values().size());
            for(Financials_Calculation__mdt financialmdt : [SELECT Id,LabelName__c,Formula__c, Row__c,Field_Api_Name__c,IsReadOnly__c,Label,MasterLabel From Financials_Calculation__mdt Order BY Row__c]) {
                FinancialWraper wrapper = new FinancialWraper();
                Date startFinancialDate = system.today().addYears(-3);
                wrapper.row = financialmdt.Row__c;
                wrapper.label = financialmdt.LabelName__c;
                wrapper.labelApiName = financialmdt.Field_Api_Name__c;
                wrapper.isReadonly = financialmdt.IsReadOnly__c;
                wrapper.isFirstRow = false;
                wrapper.isYearRow = false;
                wrapper.isotherRow = false;
                Integer index = 1;
                List<FinancialLableWraper> labelWrapperList = new List<FinancialLableWraper>();
                while(startFinancialDate <= System.today()) {
                    FinancialLableWraper obj = new FinancialLableWraper();
                    if(financialmdt.LabelName__c == 'Year') {
                        wrapper.isYearRow = true;
                        obj.answerIndex  = index;
                        //DateTime DT = DateTime.newInstance(startFinancialDate.year(), startFinancialDate.month(), startFinancialDate.day()) ;
                        obj.answer = String.valueOf(startFinancialDate.year());
                        if(finalAssessmentMap != NULL && !finalAssessmentMap.values().isEmpty()) {
                            obj.financialRecordId = String.valueOf(finalAssessmentMap.get(index).Id);
                        } else {
                            obj.financialRecordId = '';
                        }
                        
                        obj.formula = financialmdt.Formula__c;
                    } else{
                        obj.answerIndex  = index;
                        if(financialmdt.Row__c == 0) {
                            wrapper.isFirstRow = true;
                        } else{
                            wrapper.isotherRow = true;
                        }
                        
                        if(finalAssessmentMap != NULL && !finalAssessmentMap.values().isEmpty()) {
                            obj.financialRecordId = String.valueOf(finalAssessmentMap.get(index).Id);
                            if(String.valueOf(finalAssessmentMap.get(index).get(financialmdt.Field_Api_Name__c)) == '0' || String.valueOf(finalAssessmentMap.get(index).get(financialmdt.Field_Api_Name__c)) == '0.00') {
                                obj.answer = '';
                            } else {
                                obj.answer = String.valueOf(finalAssessmentMap.get(index).get(financialmdt.Field_Api_Name__c));
                            }   
                        } else {
                            if(finalAssessmentMap.values().size() == 0 && financialmdt.Row__c == 0) {
                                obj.answer = 'Audited';
                            } else {
                                obj.answer = '';
                            }
                            obj.financialRecordId = '';
                        }
                        obj.formula = financialmdt.Formula__c;
                    }
                    index += 1;
                    labelWrapperList.add(obj);
                    startFinancialDate  = startFinancialDate.addYears(1);
                }
                wrapper.labelwrapperList = labelWrapperList;
                wrapperList.add(wrapper);
                System.debug('wrapperList  '+wrapperList);
            }
            
        } catch(Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
           
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            return String.valueOf(e.getMessage());
        }
        return  JSON.serialize(wrapperList) ;
    }

    
    /**
    * @description   method to create financial assessment record and if alresy created then update them.
    * @author Zafaruddin | 05-17-2024 
    * @param loanId 
    * @param financialData 
    * @return String 
    **/
    @AuraEnabled
    public static String createFinancials(String loanId,String financialData){
        SYstem.debug('loanId  '+loanId);
        try {
            List<FinancialWraper> financialWrappers = new List<FinancialWraper>();
            MAP<Integer,Financial_Assessment__c> dataMap = new MAP<Integer,Financial_Assessment__c>();
            financialWrappers = (List<FinancialWraper>)JSON.deserialize(financialData, List<FinancialWraper>.class);
            if(!financialWrappers.isEmpty()){
                for(FinancialWraper parentData: financialWrappers){
                    for(FinancialLableWraper childData : parentData.labelwrapperList){
                        if(!dataMap.containsKey(childData.answerIndex)){
                            dataMap.put(childData.answerIndex,new Financial_Assessment__c () );
                            dataMap.get(childData.answerIndex).put('Loan_Application__c',loanId) ;
                            dataMap.get(childData.answerIndex).put('RecordTypeId',UB_ConstantsUtil.FINANCIAL_RECORD_TYPE );
                            if(childData.financialRecordId != NULL && !String.isBlank(childData.financialRecordId)) {
                                dataMap.get(childData.answerIndex).put('Id',childData.financialRecordId );
                            }
                    }
                    if(parentData.row == 1 || parentData.row == 0){
                        if(dataMap.containsKey(childData.answerIndex)){
                        dataMap.get(childData.answerIndex).put(parentData.labelApiName,(childData.answer) );
                        system.debug('in first row>>' + childData.answer );
                    }
                    }else{
                        if(dataMap.containsKey(childData.answerIndex)){
                            dataMap.get(childData.answerIndex).put(parentData.labelApiName,  ( String.isBlank(childData.answer) || childData.answer == 'NaN') ? 0 : Decimal.valueof(childData.answer)  );
                            system.debug('in otgher row>>');
                    }
                    }
                    }
                }
                if(!dataMap.isEmpty()){
                    try{
                        system.debug('Success');
                        upsert dataMap.values();
                    }catch(Exception e){
                        system.debug('error> '+ e);
                    }
                }
                return 'success';
                
            }
        } catch(Exception e) {
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
            return String.valueOf(e.getMessage());
        }
        return 'failure';
    }


    public class FinancialWraper{
        public Decimal row;
        public Boolean isFirstRow;
        public Boolean isYearRow;
        public Boolean isotherRow;
        public String label;
        public String labelApiName;
        public List<FinancialLableWraper> labelwrapperList;
        public Boolean isReadonly;

    }

    public class FinancialLableWraper{
        public Integer answerIndex;
        public String answer;
        public string formula; 
        public String DecodedFormula;
        public String financialRecordId;
        

    }

    
}