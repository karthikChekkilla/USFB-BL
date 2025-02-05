/**
* @File Name          : UB_SherlockAPI.cls
* @Description        : 
* @Author             :Zafaruddin
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         16-05-2024            Zafaruddin         Initial Version

**/

public class UB_SherlockAPI {

    UB_HTTPCalloutService service;
    public static string caseId;
    
    /**
    * @description : It is First Sherlock Api, which will return caseId, will later used it in second Api. 
    * @author  Zafaruddin | 04-15-2024 
    **/
    @future(callout = true)
    public static void getCaseId (Id customerId, String accessToken){
        Savepoint sp;
        try{
            List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
            Verification__c verifyRecord = new Verification__c();
            System.debug('loanAppList  '+loanAppList);
            system.debug('LOAN NAme  '+loanAppList[0].Loan_Application__r.Name);
            System.debug('LOan Applicant Id   '+loanAppList[0].Id);
            System.debug('PAN   '+loanAppList[0].Pan_Number__c.right(4));
            Map<String,Address__c> applicantAddressMap = new Map<String,Address__c>();
            for(Address__c address : [SELECT Id,Address_Type__c,City__c,Name,Address_Line_2__c,Address_Line_3__c,CIbil_State_Code__c,Pincode__r.Name,Sherlock_State_Code__c,State__c FROM Address__c WHERE Loan_Applicant__c = : customerId]) {
                if(address.Address_Type__c == 'Permanent Address') {
                    applicantAddressMap.put('Permanent Address', address);

                } else if(address.Address_Type__c == 'Residence Address') {
                    applicantAddressMap.put('Residence Address', address);
                }
                else if(address.Address_Type__c == 'Office Address') {
                    applicantAddressMap.put('Office Address', address);
                }
            }
            System.debug('applicantAddressMap   '+applicantAddressMap);
            UB_SherlockAPI sherlockAsyncApi = new UB_SherlockAPI();
            sherlockAsyncApi.service = new UB_HTTPCalloutService('Sherlock_Async_API');
            sherlockAsyncApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);
            String AsyncRequestXmlBody = '';

            //********************* Forming Request XML for Async API ***************************//

            AsyncRequestXmlBody = '{ "reqXml":"<REQUEST-FILE> <HEADER-SEGMENT>';
            AsyncRequestXmlBody += '<REQUEST-TYPE>SHERLOCK</REQUEST-TYPE>'; // required
            AsyncRequestXmlBody += '<DATE-OF-REQUEST>' + DateTime.newInstance(Date.today().year(), Date.today().month(),Date.today().day()).format('dd-MM-yyyy') + '</DATE-OF-REQUEST>'; // required
            AsyncRequestXmlBody += '<REQUEST-ACTION-TYPE>SUBMIT</REQUEST-ACTION-TYPE>'; // required
            AsyncRequestXmlBody += '<RESPONSE-FORMAT>XML</RESPONSE-FORMAT>'; // required
            AsyncRequestXmlBody += '<RES-FOR-FUTURE1></RES-FOR-FUTURE1>';
            AsyncRequestXmlBody += '<RES-FOR-FUTURE2></RES-FOR-FUTURE2>';
            AsyncRequestXmlBody += '</HEADER-SEGMENT>';
            AsyncRequestXmlBody += '<INQUIRY><PRIORITY></PRIORITY><APPLICATION-SEGMENT>';    
            AsyncRequestXmlBody += '<APPLN-ID>'+ loanAppList[0].Loan_Application__r.Name + '</APPLN-ID>'; // required
            AsyncRequestXmlBody += '<APPLN-DT>'+ DateTime.newInstance(loanAppList[0].CreatedDate.year(), loanAppList[0].CreatedDate.month(),loanAppList[0].CreatedDate.day()).format('dd-MM-yyyy') + '</APPLN-DT>'; // required
            AsyncRequestXmlBody += '<BRANCH-ID></BRANCH-ID>';
            AsyncRequestXmlBody += '<BRANCH-REGION></BRANCH-REGION>';
            AsyncRequestXmlBody += '<ACCT-OPEN-DATE></ACCT-OPEN-DATE>';
            AsyncRequestXmlBody += '<APPLN-VALUE>'+ Integer.valueOf(loanAppList[0].Loan_Application__r.Amount__c) + '</APPLN-VALUE>'; // required
            AsyncRequestXmlBody += '<LTV></LTV>';
            AsyncRequestXmlBody += '<TERM>' + Integer.valueOf(loanAppList[0].Loan_Application__r.Loan_Period__c) + '</TERM>'; // required
            AsyncRequestXmlBody += '<APPLN-OFFICER></APPLN-OFFICER>';
            AsyncRequestXmlBody += '<APPLN-TYPE>IA09</APPLN-TYPE>'; // required
            AsyncRequestXmlBody += '<OTHER-DESC></OTHER-DESC>';
            AsyncRequestXmlBody += '<APPLICANT-SEGMENT><APPLICANT>';
            AsyncRequestXmlBody += '<APPLICANT-TYPE>O01</APPLICANT-TYPE>'; // required
            AsyncRequestXmlBody += '<APPLICANT-ID>'+ loanAppList[0].Loan_Application__r.Name + '' + loanAppList[0].Pan_Number__c.right(4) + '</APPLICANT-ID>'; // required
            AsyncRequestXmlBody += '<FRAUD-VICTIM-FLAG></FRAUD-VICTIM-FLAG>';
            AsyncRequestXmlBody += '<FRAUD-VICTIM-CLASS></FRAUD-VICTIM-CLASS>';
            AsyncRequestXmlBody += '<GENDER>' + (UB_ConstantsUtil.SherlockGenderCodeMap.containsKey(loanAppList[0].Gender__c) ? UB_ConstantsUtil.SherlockGenderCodeMap.get(loanAppList[0].Gender__c) : '') + '</GENDER>'; // required
            AsyncRequestXmlBody += '<AKA></AKA>';
            AsyncRequestXmlBody += '<QUALIFICATION></QUALIFICATION>';
            AsyncRequestXmlBody += '<APPLICANT-NAME>';
            AsyncRequestXmlBody += '<NAME1>' + loanAppList[0].Account_Name__c + '</NAME1>'; // required
            AsyncRequestXmlBody += '<NAME2></NAME2>';
            AsyncRequestXmlBody += '<NAME3></NAME3>';
            AsyncRequestXmlBody += '<NAME4></NAME4>';
            AsyncRequestXmlBody += '</APPLICANT-NAME>';
            AsyncRequestXmlBody += '<DOB>';
            if(loanAppList[0].Date_of_Birth__c != NULL) {
            	AsyncRequestXmlBody += '<DOB-DATE>' + DateTime.newInstance(loanAppList[0].Date_of_Birth__c.year(), loanAppList[0].Date_of_Birth__c.month(),loanAppList[0].Date_of_Birth__c.day()).format('dd-MM-yyyy') + '</DOB-DATE>';
            } else {
                AsyncRequestXmlBody += '<DOB-DATE>' + DateTime.newInstance(loanAppList[0].Date_Of_Incorporation__c.year(), loanAppList[0].Date_Of_Incorporation__c.month(),loanAppList[0].Date_Of_Incorporation__c.day()).format('dd-MM-yyyy') + '</DOB-DATE>';
            }            AsyncRequestXmlBody += '<AGE></AGE>';
            AsyncRequestXmlBody += '<AGE-AS-ON></AGE-AS-ON>';
            AsyncRequestXmlBody += '</DOB>';
            AsyncRequestXmlBody += '<IDS><ID>';           
            
            if(String.isNotBlank(loanAppList[0].Passport__c))
            { 
                AsyncRequestXmlBody += '<APPLICANT-ID-TYPE>ID01</APPLICANT-ID-TYPE>'; // required
                AsyncRequestXmlBody += '<APPLICANT-ID-VALUE>' + loanAppList[0].Passport__c + '</APPLICANT-ID-VALUE>'; // required
            }
            if(String.isNotBlank(loanAppList[0].Voter_Card__c))
            { 
                AsyncRequestXmlBody += '<APPLICANT-ID-TYPE>ID02</APPLICANT-ID-TYPE>'; // required
                AsyncRequestXmlBody += '<APPLICANT-ID-VALUE>' + loanAppList[0].Voter_Card__c + '</APPLICANT-ID-VALUE>'; // required
            }
            /*
            if(String.isNotBlank(loanAppList[0].Aadhaar_Number__c))
            {   
                AsyncRequestXmlBody += '<APPLICANT-ID-TYPE>ID03</APPLICANT-ID-TYPE>';  // required
                AsyncRequestXmlBody += '<APPLICANT-ID-VALUE>' + loanAppList[0].Aadhaar_Number__c + '</APPLICANT-ID-VALUE>'; // required
            }  */         
            if(String.isNotBlank(loanAppList[0].Driving_Licence__c))
            { 
                AsyncRequestXmlBody += '<APPLICANT-ID-TYPE>ID06</APPLICANT-ID-TYPE>'; // required
                AsyncRequestXmlBody += '<APPLICANT-ID-VALUE>' + loanAppList[0].Driving_Licence__c + '</APPLICANT-ID-VALUE>'; // required
            }
            if(String.isNotBlank(loanAppList[0].Pan_Number__c))
            { 
                AsyncRequestXmlBody += '<APPLICANT-ID-TYPE>ID07</APPLICANT-ID-TYPE>'; // required
                AsyncRequestXmlBody += '<APPLICANT-ID-VALUE>' + loanAppList[0].Pan_Number__c + '</APPLICANT-ID-VALUE>'; // required
            }
            AsyncRequestXmlBody += '</ID></IDS>';
            AsyncRequestXmlBody += '<RELATIONS><RELATION>';
            AsyncRequestXmlBody += '<RELATION-TYPE></RELATION-TYPE>';
            AsyncRequestXmlBody += '<RELATIVE-NAME></RELATIVE-NAME>';
            AsyncRequestXmlBody += '</RELATION></RELATIONS>';
            AsyncRequestXmlBody += '<ACC-VERIFICATION><VERIFICATION>';
            AsyncRequestXmlBody += '<ACCT-DOC-TYPE>' + 'DOC1' + '</ACCT-DOC-TYPE>'; // Document Type Code 
            AsyncRequestXmlBody += '<ACCT-DOC-NUMBER>' + loanAppList[0].Pan_Number__c + '</ACCT-DOC-NUMBER>';
            /*
            if(String.isNotBlank(String.valueOf(loanAppList[0].Account_Number__c)))
            { 
                AsyncRequestXmlBody += '<ACCT-NUMBER>' + loanAppList[0].Account_Number__c + '</ACCT-NUMBER>';
            } */
            if(String.isNotBlank(loanAppList[0].Name_of_the_Bank__c) )
            { 
                AsyncRequestXmlBody += '<BANK_NAME>' + loanAppList[0].Name_of_the_Bank__c + '</BANK_NAME>';
            }
            AsyncRequestXmlBody += '</VERIFICATION></ACC-VERIFICATION>';
            AsyncRequestXmlBody += '<EMPLOYMENTS><EMPLOYMENT>';
            AsyncRequestXmlBody += '<OCCUPATION>' + 'J01' + '</OCCUPATION>'; // passing J01 code for salaried
            if(String.isNotBlank(loanAppList[0].Designation__c) )
            { 
                AsyncRequestXmlBody += '<JOB-TITLE>' + loanAppList[0].Designation__c + '</JOB-TITLE>';
            }
            if(String.isNotBlank(loanAppList[0].Employee_Name__c) ) {
                AsyncRequestXmlBody += '<EMPLOYER-NAME>' + loanAppList[0].Employee_Name__c + '</EMPLOYER-NAME>';
            }
            if(loanAppList[0].Monthly_Income__c != NULL)
            { 
                AsyncRequestXmlBody += '<INCOME>' + loanAppList[0].Monthly_Income__c + '</INCOME>';
            }
            AsyncRequestXmlBody += '<INCOME-INDICATOR>' + 'SF01' + '</INCOME-INDICATOR>'; // @ SF01 code for Monthly    
            AsyncRequestXmlBody += '</EMPLOYMENT></EMPLOYMENTS>';
            AsyncRequestXmlBody += '<ADDRESSES><ADDRESS>';
            if(loanAppList[0].RecordTypeId == UB_ConstantsUtil.INDIVIDUAL_APPICANT_RECORD_TYPE) {
                if( applicantAddressMap.get('Residence Address') != null  ){
                    AsyncRequestXmlBody += '<ADDRESS-TYPE>D01</ADDRESS-TYPE>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE1>' + applicantAddressMap.get('Residence Address').Name + '</ADDRESS-LINE1>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE2> ' + applicantAddressMap.get('Residence Address').Address_Line_2__c + '</ADDRESS-LINE2>'; 
                    AsyncRequestXmlBody += '<ADDRESS-LINE3> ' + applicantAddressMap.get('Residence Address').Address_Line_3__c + '</ADDRESS-LINE3>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE4></ADDRESS-LINE4>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE5></ADDRESS-LINE5>';
                    AsyncRequestXmlBody += '<CITY>' + applicantAddressMap.get('Residence Address').City__c + '</CITY>'; // required
                    AsyncRequestXmlBody += '<STATE>' + applicantAddressMap.get('Residence Address').Sherlock_State_Code__c + '</STATE>'; // required
                    AsyncRequestXmlBody += '<PIN>' + applicantAddressMap.get('Residence Address').Pincode__r.Name + '</PIN>'; // required
                }
                if(applicantAddressMap.get('Permanent Address') != null ) {
                    AsyncRequestXmlBody += '<ADDRESS-TYPE>D04</ADDRESS-TYPE>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE1>' + applicantAddressMap.get('Permanent Address').Name + '</ADDRESS-LINE1>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE2> ' + applicantAddressMap.get('Permanent Address').Address_Line_2__c + '</ADDRESS-LINE2>'; 
                    AsyncRequestXmlBody += '<ADDRESS-LINE3> ' + applicantAddressMap.get('Permanent Address').Address_Line_3__c + '</ADDRESS-LINE3>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE4></ADDRESS-LINE4>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE5></ADDRESS-LINE5>';
                    AsyncRequestXmlBody += '<CITY>' + applicantAddressMap.get('Permanent Address').City__c + '</CITY>'; // required
                    AsyncRequestXmlBody += '<STATE>' + applicantAddressMap.get('Permanent Address').Sherlock_State_Code__c + '</STATE>'; // required
                    AsyncRequestXmlBody += '<PIN>' + applicantAddressMap.get('Permanent Address').Pincode__r.Name + '</PIN>'; // required
                    AsyncRequestXmlBody += '<COUNTRY>IND</COUNTRY>';
                }
            } else {
                if(applicantAddressMap.get('Office Address') != null ) {
                    AsyncRequestXmlBody += '<ADDRESS-TYPE>D02</ADDRESS-TYPE>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE1>' + applicantAddressMap.get('Office Address').Name + '</ADDRESS-LINE1>'; // required
                    AsyncRequestXmlBody += '<ADDRESS-LINE2> ' + applicantAddressMap.get('Office Address').Address_Line_2__c + '</ADDRESS-LINE2>'; 
                    AsyncRequestXmlBody += '<ADDRESS-LINE3> ' + applicantAddressMap.get('Office Address').Address_Line_3__c + '</ADDRESS-LINE3>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE4></ADDRESS-LINE4>';
                    AsyncRequestXmlBody += '<ADDRESS-LINE5></ADDRESS-LINE5>';
                    AsyncRequestXmlBody += '<CITY>' + applicantAddressMap.get('Office Address').City__c + '</CITY>'; // required
                    AsyncRequestXmlBody += '<STATE>' + applicantAddressMap.get('Office Address').Sherlock_State_Code__c + '</STATE>'; // required
                    AsyncRequestXmlBody += '<PIN>' + applicantAddressMap.get('Office Address').Pincode__r.Name + '</PIN>'; // required
                    AsyncRequestXmlBody += '<COUNTRY>IND</COUNTRY>';
                }
            }
            AsyncRequestXmlBody += '<FROM-DATE></FROM-DATE>';
            AsyncRequestXmlBody += '<TO-DATE></TO-DATE>';
            AsyncRequestXmlBody += '</ADDRESS></ADDRESSES>';
            AsyncRequestXmlBody += '<PHONES><PHONE>';
            AsyncRequestXmlBody += '<TELE-NO-TYPE>P03</TELE-NO-TYPE>'; // required
            AsyncRequestXmlBody += '<TELE-NO>' + loanAppList[0].Mobile__c + '</TELE-NO>'; // required
            AsyncRequestXmlBody += '</PHONE></PHONES>';
            AsyncRequestXmlBody += '<E-MAILS><E-MAIL>';
            AsyncRequestXmlBody += '<EMAIL-TYPE>EMT02</EMAIL-TYPE>'; // required
            AsyncRequestXmlBody += '<EMAIL-ID>' + loanAppList[0].Email__c + '</EMAIL-ID>'; // required
            AsyncRequestXmlBody += '</E-MAIL></E-MAILS></APPLICANT></APPLICANT-SEGMENT>';  
            // Additional code from PL Project
            AsyncRequestXmlBody += '<COLLATERAL-SEGMENT><COLLATERAL><TYPE-OF-COLLATERAL></TYPE-OF-COLLATERAL><COLLAT-OTHER-DESC></COLLAT-OTHER-DESC><PROP-OWN-NAME></PROP-OWN-NAME><TYPE-OF-CHARGE></TYPE-OF-CHARGE><COLLATERAL-VALUE></COLLATERAL-VALUE><VALUATION-DATE></VALUATION-DATE><APPRAISER-NAME></APPRAISER-NAME><PROP-ADDRESS-TYPE></PROP-ADDRESS-TYPE><PROP-ADDRESS-LINE1></PROP-ADDRESS-LINE1><PROP-ADDRESS-LINE2></PROP-ADDRESS-LINE2><CITY></CITY><STATE></STATE><PIN-CODE></PIN-CODE><BUILD-TYPE></BUILD-TYPE><YEAR-OF-MAKE></YEAR-OF-MAKE><DEALER></DEALER><REG-NO></REG-NO><ENG-NO></ENG-NO><CHASSIS-NO></CHASSIS-NO></COLLATERAL></COLLATERAL-SEGMENT><OTHER-ENTITIES><OTHER-ENTITY><REF-TITLE></REF-TITLE><REF-NAME1></REF-NAME1><REF-NAME2></REF-NAME2><REF-NAME3></REF-NAME3><REF-AKA></REF-AKA><REF-PHONE1></REF-PHONE1><REF-PHONE2></REF-PHONE2><REF-EMAIL1></REF-EMAIL1><REF-EMAIL2></REF-EMAIL2><REF-ADDRESS-LINE1></REF-ADDRESS-LINE1><REF-ADDRESS-LINE2></REF-ADDRESS-LINE2><REF-ADDRESS-LINE3></REF-ADDRESS-LINE3><REF-CITY></REF-CITY><REF-STATE></REF-STATE><REF-PINCODE></REF-PINCODE><REF-COUNTRY></REF-COUNTRY></OTHER-ENTITY><OTHER-ENTITY><REF-TITLE></REF-TITLE><REF-NAME1></REF-NAME1><REF-NAME2></REF-NAME2><REF-NAME3></REF-NAME3><REF-AKA></REF-AKA><REF-PHONE1></REF-PHONE1><REF-PHONE2></REF-PHONE2><REF-EMAIL1></REF-EMAIL1><REF-EMAIL2></REF-EMAIL2><REF-ADDRESS-LINE1></REF-ADDRESS-LINE1><REF-ADDRESS-LINE2></REF-ADDRESS-LINE2><REF-ADDRESS-LINE3></REF-ADDRESS-LINE3><REF-CITY></REF-CITY><REF-STATE></REF-STATE><REF-PINCODE></REF-PINCODE><REF-COUNTRY></REF-COUNTRY></OTHER-ENTITY></OTHER-ENTITIES><BROKER><BRKR-ORG-NAME></BRKR-ORG-NAME><BRKR-NAME></BRKR-NAME><BRKR-ADD><BRKR-ADDRESS></BRKR-ADDRESS><BRKR-CITY></BRKR-CITY><BRKR-STATE></BRKR-STATE><BRKR-PINCODE></BRKR-PINCODE><BRKR-COUNTRY></BRKR-COUNTRY></BRKR-ADD><BRKR-PHONE></BRKR-PHONE></BROKER>';              
            AsyncRequestXmlBody += '</APPLICATION-SEGMENT> ';
            AsyncRequestXmlBody += '</INQUIRY> ';
            AsyncRequestXmlBody += '</REQUEST-FILE>" } ';
           
            //AsyncRequestXmlBody = '{ "reqXml":"<REQUEST-FILE><HEADER-SEGMENT><REQUEST-TYPE>SHERLOCK</REQUEST-TYPE><DATE-OF-REQUEST>12-01-2023</DATE-OF-REQUEST><REQUEST-ACTION-TYPE>SUBMIT</REQUEST-ACTION-TYPE><RESPONSE-FORMAT>XML</RESPONSE-FORMAT><RES-FOR-FUTURE1></RES-FOR-FUTURE1><RES-FOR-FUTURE2></RES-FOR-FUTURE2></HEADER-SEGMENT><INQUIRY><PRIORITY></PRIORITY><APPLICATION-SEGMENT><APPLN-ID>001Test</APPLN-ID><APPLN-DT>12-01-2023</APPLN-DT><BRANCH-ID></BRANCH-ID><BRANCH-REGION></BRANCH-REGION><ACCT-OPEN-DATE></ACCT-OPEN-DATE><APPLN-VALUE>500000</APPLN-VALUE><LTV></LTV><TERM>25</TERM><APPLN-OFFICER></APPLN-OFFICER><APPLN-TYPE>IA04</APPLN-TYPE><OTHER-DESC></OTHER-DESC><APPLICANT-SEGMENT><APPLICANT><APPLICANT-TYPE>O01</APPLICANT-TYPE><APPLICANT-ID>ABC</APPLICANT-ID><FRAUD-VICTIM-FLAG></FRAUD-VICTIM-FLAG><FRAUD-VICTIM-CLASS></FRAUD-VICTIM-CLASS><GENDER>G01</GENDER><AKA></AKA><QUALIFICATION></QUALIFICATION><APPLICANT-NAME><NAME1>OM PRAKASH</NAME1><NAME2></NAME2><NAME3></NAME3><NAME4></NAME4><NAME5></NAME5></APPLICANT-NAME><DOB><DOB-DATE>07-09-1970</DOB-DATE><AGE></AGE><AGE-AS-ON></AGE-AS-ON></DOB><IDS><ID><APPLICANT-ID-TYPE>ID03</APPLICANT-ID-TYPE><APPLICANT-ID-VALUE></APPLICANT-ID-VALUE><APPLICANT-ID-TYPE>ID02</APPLICANT-ID-TYPE><APPLICANT-ID-VALUE>deleted</APPLICANT-ID-VALUE></ID></IDS><RELATIONS><RELATION><RELATION-TYPE></RELATION-TYPE><RELATIVE-NAME></RELATIVE-NAME></RELATION></RELATIONS><ACC-VERIFICATION><VERIFICATION><ACCT-DOC-TYPE></ACCT-DOC-TYPE><ACCT-DOC-NUMBER></ACCT-DOC-NUMBER><DOC-ISSUE-DATE></DOC-ISSUE-DATE><ACCT-DOC-PURPOSE></ACCT-DOC-PURPOSE><PLACE-OF-ISSUE></PLACE-OF-ISSUE><ACCT-NUMBER></ACCT-NUMBER><BANK_NAME></BANK_NAME><BANK-IFSC></BANK-IFSC><BANK-MICR></BANK-MICR></VERIFICATION></ACC-VERIFICATION><EMPLOYMENTS><EMPLOYMENT><OCCUPATION></OCCUPATION><JOB-TITLE></JOB-TITLE><EMPLOYER-NAME></EMPLOYER-NAME><EMPLOYER-STATUS></EMPLOYER-STATUS><INDUSTRY></INDUSTRY><EMPLOYEE-NUMBER></EMPLOYEE-NUMBER><EMP-START-DATE></EMP-START-DATE><EMP-END-DATE></EMP-END-DATE><INCOME></INCOME><INCOME-INDICATOR></INCOME-INDICATOR></EMPLOYMENT></EMPLOYMENTS><ADDRESSES><ADDRESS><ADDRESS-TYPE>D01</ADDRESS-TYPE><ADDRESS-LINE1>S-124 R.K. Colony</ADDRESS-LINE1><ADDRESS-LINE2></ADDRESS-LINE2><ADDRESS-LINE3></ADDRESS-LINE3><ADDRESS-LINE4></ADDRESS-LINE4><ADDRESS-LINE5></ADDRESS-LINE5><CITY>MULSHI</CITY><STATE>MH</STATE><PIN>411019</PIN><COUNTRY>IND</COUNTRY><FROM-DATE></FROM-DATE><TO-DATE></TO-DATE></ADDRESS></ADDRESSES><PHONES><PHONE><TELE-NO-TYPE>P03</TELE-NO-TYPE><TELE-NO>1234567890</TELE-NO></PHONE></PHONES><E-MAILS><E-MAIL><EMAIL-TYPE>EMT01</EMAIL-TYPE><EMAIL-ID>utk56694@utkarsh.bank</EMAIL-ID></E-MAIL></E-MAILS></APPLICANT></APPLICANT-SEGMENT><COLLATERAL-SEGMENT><COLLATERAL><TYPE-OF-COLLATERAL></TYPE-OF-COLLATERAL><COLLAT-OTHER-DESC></COLLAT-OTHER-DESC><PROP-OWN-NAME></PROP-OWN-NAME><TYPE-OF-CHARGE></TYPE-OF-CHARGE><COLLATERAL-VALUE></COLLATERAL-VALUE><VALUATION-DATE></VALUATION-DATE><APPRAISER-NAME></APPRAISER-NAME><PROP-ADDRESS-TYPE></PROP-ADDRESS-TYPE><PROP-ADDRESS-LINE1></PROP-ADDRESS-LINE1><PROP-ADDRESS-LINE2></PROP-ADDRESS-LINE2><CITY></CITY><STATE></STATE><PIN-CODE></PIN-CODE><BUILD-TYPE></BUILD-TYPE><YEAR-OF-MAKE></YEAR-OF-MAKE><DEALER></DEALER><REG-NO></REG-NO><ENG-NO></ENG-NO><CHASSIS-NO></CHASSIS-NO></COLLATERAL></COLLATERAL-SEGMENT><OTHER-ENTITIES><OTHER-ENTITY><REF-TITLE></REF-TITLE><REF-NAME1></REF-NAME1><REF-NAME2></REF-NAME2><REF-NAME3></REF-NAME3><REF-AKA></REF-AKA><REF-PHONE1></REF-PHONE1><REF-PHONE2></REF-PHONE2><REF-EMAIL1></REF-EMAIL1><REF-EMAIL2></REF-EMAIL2><REF-ADDRESS-LINE1></REF-ADDRESS-LINE1><REF-ADDRESS-LINE2></REF-ADDRESS-LINE2><REF-ADDRESS-LINE3></REF-ADDRESS-LINE3><REF-CITY></REF-CITY><REF-STATE></REF-STATE><REF-PINCODE></REF-PINCODE><REF-COUNTRY></REF-COUNTRY></OTHER-ENTITY><OTHER-ENTITY><REF-TITLE></REF-TITLE><REF-NAME1></REF-NAME1><REF-NAME2></REF-NAME2><REF-NAME3></REF-NAME3><REF-AKA></REF-AKA><REF-PHONE1></REF-PHONE1><REF-PHONE2></REF-PHONE2><REF-EMAIL1></REF-EMAIL1><REF-EMAIL2></REF-EMAIL2><REF-ADDRESS-LINE1></REF-ADDRESS-LINE1><REF-ADDRESS-LINE2></REF-ADDRESS-LINE2><REF-ADDRESS-LINE3></REF-ADDRESS-LINE3><REF-CITY></REF-CITY><REF-STATE></REF-STATE><REF-PINCODE></REF-PINCODE><REF-COUNTRY></REF-COUNTRY></OTHER-ENTITY></OTHER-ENTITIES><BROKER><BRKR-ORG-NAME></BRKR-ORG-NAME><BRKR-NAME></BRKR-NAME><BRKR-ADD><BRKR-ADDRESS></BRKR-ADDRESS><BRKR-CITY></BRKR-CITY><BRKR-STATE></BRKR-STATE><BRKR-PINCODE></BRKR-PINCODE><BRKR-COUNTRY></BRKR-COUNTRY></BRKR-ADD><BRKR-PHONE></BRKR-PHONE></BROKER></APPLICATION-SEGMENT></INQUIRY></REQUEST-FILE>"}';
            sherlockAsyncApi.service.setRequestBody(AsyncRequestXmlBody);
            System.debug('REQUESTTT   BODYYYYYYYYYYYY  '+AsyncRequestXmlBody);
            HTTPResponse response =  sherlockAsyncApi.service.sendRequest();
            sp = Database.setSavepoint();
            System.debug('RESPONSEEEEEEE  '+response);
           //String sampleAsyncXmlResponseBody = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <ACKNOWLEDGEMENT-FILE> <INQUIRY-STATUS> <INQUIRY> <APPLN-ID>001Test</APPLN-ID> <DATE-OF-REQUEST>16-02-2023</DATE-OF-REQUEST> <CASE-ID>14251607379</CASE-ID> <RESPONSE-DT>16-02-2023</RESPONSE-DT> <RESPONSE-TYPE>ACKNOWLEDGEMENT</RESPONSE-TYPE> </INQUIRY> </INQUIRY-STATUS> </ACKNOWLEDGEMENT-FILE>';
            String asyncXmlResponseBody = response.getBody(); // sampleAsyncXmlResponseBody;
            System.debug('RESPONSEEEEEEE BODYYYYYy++  '+asyncXmlResponseBody);
            System.debug('response.getStatusCode()  '+response.getStatusCode());
            if(response.getStatusCode() == 200){
               parseXML(asyncXmlResponseBody,'Async',customerId);
            }
            else{
                System.debug('CODE NOT 200');
                parseXML(asyncXmlResponseBody,'Async',customerId); 
            } 

            System.debug('AAAAAAAAAAA1111');
            API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                sherlockAsyncApi.service.getEndpointURL(), 
                String.valueOf(sherlockAsyncApi.service.getHeaderParameters()), 
                sherlockAsyncApi.service.getRequestMethod(), 
                AsyncRequestXmlBody, 
                response.getBody(), 
                response.getStatusCode(), 
                UB_SherlockAPI.class.getName(), 
                customerId, 
                Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                UB_ConstantsUtil.REST_API_TYPE,
                'Sherlock  Async API',
                UB_ConstantsUtil.LOB_CV
                );
            if(apiLogger != NULL) {
               insert apiLogger;
                System.debug('apiLogger  '+apiLogger);
            }
        }catch(Exception e) {
            if(sp != NULL) {
                Database.rollback(sp);
            }
            System.debug('Exception@@0000'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE 00000 '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        
    }

    @future(callout = true)
    //@Description : This method is used to invoke the Second SherLock API i.e., Issue API to fetch the SherLock Details    
    public static void invokeIssueApi(String caseId, String customerId, string accessToken) {
        System.debug('caseIdcaseId   '+caseId);
        System.debug('customerId   '+customerId);
        Savepoint sp;
        Map<String,Messages_Config__mdt> messageConfigMap = UB_CommonUtil.getMessageRecord('ReadTimeOutIssue');
        try {
            UB_SherlockAPI sherlockIssueApi = new UB_SherlockAPI();
            sherlockIssueApi.service = new UB_HTTPCalloutService('Sherlock_Issue_API');
            sherlockIssueApi.service.setHeaderParameter('Authorization', 'Bearer '+accessToken);

            if(String.isNotBlank(caseId) && String.isNotEmpty(caseId))
            {
                String issueXmlRequestBody = '';
                issueXmlRequestBody += '{ "reqXml":"';
                issueXmlRequestBody += '<ISSUE-FILE>';
                issueXmlRequestBody += '<HEADER-SEGMENT>';
                issueXmlRequestBody += '<REQUEST-TYPE>' + 'SHERLOCK' + '</REQUEST-TYPE>';
                issueXmlRequestBody += '<CUSTOMER-ID>' + sherlockIssueApi.service.getExtraParameter('CUSTOMER-ID') + '</CUSTOMER-ID>';
                issueXmlRequestBody += '<DATE-OF-REQUEST>' + DateTime.newInstance(Date.today().year(), Date.today().month(),Date.today().day()).format('dd-MM-yyyy') + '</DATE-OF-REQUEST>';
                issueXmlRequestBody += '<REQUEST-ACTION-TYPE>' + 'ISSUE' + '</REQUEST-ACTION-TYPE>';
                issueXmlRequestBody += '<RESPONSE-FORMAT>' + 'XML' + '</RESPONSE-FORMAT>';
                issueXmlRequestBody += '</HEADER-SEGMENT>';
                issueXmlRequestBody += '<INQUIRY>';
                issueXmlRequestBody += '<CASE-ID>' + caseId + '</CASE-ID>';
                issueXmlRequestBody += '<CIR/>';
                issueXmlRequestBody += '</INQUIRY>';
                issueXmlRequestBody += '</ISSUE-FILE>';
                issueXmlRequestBody += '" }';

                //issueXmlRequestBody = '{"reqXml":"<ISSUE-FILE><HEADER-SEGMENT><REQUEST-TYPE>SHERLOCK|SHERLOCK-HTML</REQUEST-TYPE><CUSTOMER-ID>SFB0000004</CUSTOMER-ID><DATE-OF-REQUEST>13-01-2023</DATE-OF-REQUEST><REQUEST-ACTION-TYPE>ISSUE</REQUEST-ACTION-TYPE><RESPONSE-FORMAT>XML</RESPONSE-FORMAT></HEADER-SEGMENT><INQUIRY><CASE-ID>14251604775</CASE-ID><CIR/></INQUIRY></ISSUE-FILE>"}';
                sherlockIssueApi.service.setRequestBody(issueXmlRequestBody);
                System.debug('issueXmlRequestBody   '+issueXmlRequestBody);      
                HTTPResponse response = sherlockIssueApi.service.sendRequest();
                sp = Database.setSavepoint();
                System.debug('response   '+response);
                String issueXmlResponseBody =  response.getBody(); // sampleIssueXmlResponseBody;
                //System.debug('issueXmlResponseBody  '+issueXmlResponseBody);
                parseXML(issueXmlResponseBody,'Issue',customerId);   
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    sherlockIssueApi.service.getEndpointURL(), 
                    String.valueOf(sherlockIssueApi.service.getHeaderParameters()), 
                    sherlockIssueApi.service.getRequestMethod(), 
                    issueXmlRequestBody, 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_SherlockAPI.class.getName(), 
                    customerId, 
                    Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'Sherlock Issue API',
                    UB_ConstantsUtil.LOB_CV
                    );
                if(apiLogger != NULL) {
                   insert apiLogger;
                    System.debug('apiLogger  '+apiLogger.Id);
                }            
            }
                      

        }catch(System.CalloutException e) {
            Database.rollback(sp);
            System.debug('Exception@@'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE  '+e.getLineNumber());
            Verification__c verifyRecord = new Verification__c();
            verifyRecord = UB_CommonUtil.createVerfication(customerId, UB_ConstantsUtil.SHERLOCK_VERIFICATION_RECORD_TYPE,UB_ConstantsUtil.FAILED_STATUS);
            verifyRecord.Failed_Reason__c = messageConfigMap.get('Read_Time_Out_Api_Issue').Message__c;
            insert verifyRecord;
            update new Loan_Applicant__c(Id = customerId, Sherlock_Verification__c = verifyRecord.Id);
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);            
        }catch(Exception e) {
            Database.rollback(sp);
            System.debug('Exception@@0000'+e.getMessage());
            System.debug('Exception@@ LINEEEEEE 00000 '+e.getLineNumber());
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }

    }

    //@Description: XML Response Parsing Method
    public static  void parseXML(String xmlresponse,String apiName,String loanApplicantId) {        
        if(String.isNotBlank(xmlresponse) && String.isNotEmpty(xmlresponse))
        {
            if(apiName == 'Async' && !xmlresponse.contains('ERROR') && xmlresponse.contains('CASE-ID')) // Success Response in Async API
            {
                System.debug('000000000000000');
                storeSherLockResponseData(xmlresponse,loanApplicantId,'Async');
            } 
            else if(apiName == 'Async' && xmlresponse.contains('ERROR') && xmlresponse.contains('DESCRIPTION')) // status code is 200 - But Error Response in Async API
            {          
                System.debug('1111111111111111');     
                storeSherLockResponseData(xmlresponse,loanApplicantId,'Async');
            } 
            else if(apiName == 'Async' && xmlresponse.contains('<error>') && xmlresponse.contains('message')) // status code is not 200 - Error Response in Async API
            {        
                System.debug('2222222222222222');       
                storeSherLockResponseData(xmlresponse,loanApplicantId,'Async');
            }                
            else if(apiName == 'Issue' && !xmlresponse.contains('ERROR') && xmlresponse.contains('IN_PROCESS')) // status code is 200 - But IN PROCESS Response in Issue API
            {
                System.debug('33333333333333333333');
                storeSherLockResponseData('IN PROCESS',loanApplicantId,'Issue');                           
            }
            else if(apiName == 'Issue' && !xmlresponse.contains('ERROR')) // status code is 200 - Success Response in Issue API
            {
                System.debug('44444444444444444');
                if(xmlresponse.contains('SHERLOCK-DETAILS'))
                    storeSherLockResponseData(xmlresponse.substringBetween('<SHERLOCK-REPORT>','</SHERLOCK-REPORT>'),loanApplicantId,'Issue');                          
            }             
            else if(apiName == 'Issue' && xmlresponse.contains('ERROR') && xmlresponse.contains('DESCRIPTION')) // status code is 200 - BUT ERROR  Response in Issue API
            {
                System.debug('555555555555555555555');
                storeSherLockResponseData(xmlresponse,loanApplicantId,'Issue');
            }
            else if(apiName == 'Issue' && xmlresponse.contains('<error>') && xmlresponse.contains('message')) // status code is not 200 -  ERROR  Response in Issue API
            {               
                System.debug('666666666666666666666');
                storeSherLockResponseData(xmlresponse,loanApplicantId,'Issue');
            }
            
        }
        else{  return; }
    }
    
    
    //@Description : This method is used to parse the Necessary information from the Response and storing it in Risk Containment Unit Object
    public static String storeSherLockResponseData(string xmlresponse,String loanApplicantId,String calledFrom) {
        Verification__c verificationRecord = new Verification__c();
        List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectById(new Set<Id>{loanApplicantId});
        verificationRecord = UB_CommonUtil.createVerfication(loanApplicantId, UB_ConstantsUtil.SHERLOCK_VERIFICATION_RECORD_TYPE,NULL);
        List<Verification__c> sherlockVerificationRecord = [SELECT Id FROM Verification__c WHERE Loan_Applicant__c=:loanApplicantId AND RecordTypeId=:UB_ConstantsUtil.SHERLOCK_VERIFICATION_RECORD_TYPE];
        if(!sherlockVerificationRecord.isEmpty()) {
            verificationRecord = sherlockVerificationRecord[0];
        } else {
            insert verificationRecord ;
        }

       
        update new Loan_Applicant__c(Id = loanApplicantId, Sherlock_Verification__c = verificationRecord.Id);
        System.debug('verifyRecord  '+verificationRecord);

        RCUResponseWrapper riskContainmentWrapperObj = new RCUResponseWrapper();
        if(calledFrom == 'Async' && !xmlresponse.containsIgnoreCase('<error>'))
        {               
            riskContainmentWrapperObj.SherLock_Case_Id = xmlresponse.substringBetween('<CASE-ID>','</CASE-ID>'); 
            verificationRecord.Status__c = 'In Progress' ;      
        }
        else if(calledFrom == 'Issue' && xmlresponse != 'IN PROCESS' && !xmlresponse.containsIgnoreCase('<error>'))
        {
            if(xmlresponse.contains('SHERLOCK-DECISION')){  
                riskContainmentWrapperObj.SherLock_Status =  xmlresponse.substringBetween('<SHERLOCK-DECISION>','</SHERLOCK-DECISION>');            
            }	
            
            riskContainmentWrapperObj.Sherlock_Details_Applicant ='';        
            if(xmlresponse.contains('STATUS') || xmlresponse.contains('SCORE')){
                riskContainmentWrapperObj.Sherlock_Details_Applicant ='APPLICANT DETAILS :-\n\n';
            }
            
            if(xmlresponse.contains('STATUS')) {
                riskContainmentWrapperObj.Sherlock_Details_Applicant += 'STATUS - '+xmlresponse.substringBetween('<STATUS>','</STATUS>')+'\n';
            }
            
            if(xmlresponse.contains('SCORE'))  {
                riskContainmentWrapperObj.Sherlock_Details_Applicant += 'SCORE - '+xmlresponse.substringBetween('<SCORE>', '</SCORE>')+'\n\n';
            }
            
            riskContainmentWrapperObj.Sherlock_Details_Rules = '';
            Dom.Document documentObj = new Dom.Document(); 
            Dom.XMLNode rootElement;
            
            if(xmlresponse.contains('RULE-TYPE-FULLBASE'))
            {
                documentObj = new Dom.Document(); 
                String rulesdata = xmlresponse.substringBetween('<RULES>', '</RULES>');
                rulesdata = rulesdata.replaceAll('<RULE-TYPE-FRiDAI/>','');  
                rulesdata = rulesdata.replaceAll('<RULE-FULLBASE>', '');
                rulesdata = rulesdata.replaceAll('</RULE-FULLBASE>', '');
                documentObj.load(rulesdata);
                rootElement = documentObj.getRootElement();  
                for ( Dom.XMLNode childElement : rootElement.getChildElements() ) { 
                    if(childElement.getName() != 'RULE-ID') {
                        riskContainmentWrapperObj.Sherlock_Details_Rules += childElement.getName() + ' - ' + childElement.getText() + '\n';
                    }             
                    
                    if(childElement.getName() == 'SEVERITY'){
                        riskContainmentWrapperObj.Sherlock_Details_Rules += '\n';
                    }                
                }
            }
            
            if(xmlresponse.contains('DECISION-ATTRIBUTES'))
            {
                riskContainmentWrapperObj.Sherlock_Details_Applicant +='BUREAU SUMMARY CREDIT INFO DECISION ATTRIBUTES :-\n\n';
                
                if(xmlresponse.contains('INQUIRIES-IN-LAST-SIX-MONTHS')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'INQUIRIES-IN-LAST-SIX-MONTHS' + ' - ' + xmlresponse.substringBetween('<INQUIRIES-IN-LAST-SIX-MONTHS>', '</INQUIRIES-IN-LAST-SIX-MONTHS>') + '\n';
                }
                if(xmlresponse.contains('LENGTH-OF-CREDIT-HISTORY-YEAR')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'LENGTH-OF-CREDIT-HISTORY-YEAR' + ' - ' + xmlresponse.substringBetween('<LENGTH-OF-CREDIT-HISTORY-YEAR>', '</LENGTH-OF-CREDIT-HISTORY-YEAR>') + '\n'; 
                }
                if(xmlresponse.contains('LENGTH-OF-CREDIT-HISTORY-MONTH')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'LENGTH-OF-CREDIT-HISTORY-MONTH' + ' - ' + xmlresponse.substringBetween('<LENGTH-OF-CREDIT-HISTORY-MONTH>', '</LENGTH-OF-CREDIT-HISTORY-MONTH>') + '\n';  
                }
                if(xmlresponse.contains('AVERAGE-ACCOUNT-AGE-YEAR')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'AVERAGE-ACCOUNT-AGE-YEAR' + ' - ' + xmlresponse.substringBetween('<AVERAGE-ACCOUNT-AGE-YEAR>', '</AVERAGE-ACCOUNT-AGE-YEAR>') + '\n';   
                }
                if(xmlresponse.contains('AVERAGE-ACCOUNT-AGE-MONTH')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'AVERAGE-ACCOUNT-AGE-MONTH' + ' - ' + xmlresponse.substringBetween('<AVERAGE-ACCOUNT-AGE-MONTH>', '</AVERAGE-ACCOUNT-AGE-MONTH>') + '\n';  
                }
                if(xmlresponse.contains('NEW-ACCOUNTS-IN-LAST-SIX-MONTHS')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'NEW-ACCOUNTS-IN-LAST-SIX-MONTHS' + ' - ' + xmlresponse.substringBetween('<NEW-ACCOUNTS-IN-LAST-SIX-MONTHS>', '</NEW-ACCOUNTS-IN-LAST-SIX-MONTHS>') + '\n';  
                }
                if(xmlresponse.contains('NEW-DELINQ-ACCOUNT-IN-LAST-SIX-MONTHS')){
                    riskContainmentWrapperObj.Sherlock_Details_Applicant += 'NEW-DELINQ-ACCOUNT-IN-LAST-SIX-MONTHS' + ' - ' + xmlresponse.substringBetween('<NEW-DELINQ-ACCOUNT-IN-LAST-SIX-MONTHS>', '</NEW-DELINQ-ACCOUNT-IN-LAST-SIX-MONTHS>');   
                }
            } 
            riskContainmentWrapperObj.Sherlock_Verification_Summary ='';  
            if(xmlresponse.contains('VERIFICATION-SUMMARY') && xmlresponse.contains('ID-VERIFICATION-SUMMARY'))
            {
                String[] expectedElements = new List<String>{'DESCRIPTION','REQ-SERVICE-TYPE','REMARK','DESCRIPITION'};
                    if(xmlresponse.contains('ID-VERIFICATION-SUMMARY') && !xmlresponse.contains('<ID-VERIFICATION-SUMMARY/>'))
                    riskContainmentWrapperObj.Sherlock_Verification_Summary = 'ID VERIFICATION SUMMARY :-\n\n';
                documentObj = new Dom.Document(); 
                rootElement = null;
                String idVerificationdata = xmlresponse.substringBetween('<VERIFICATION-SUMMARY>', '</VERIFICATION-SUMMARY>');
                idVerificationdata = idVerificationdata.replaceAll('<SCORES>','');
                idVerificationdata = idVerificationdata.replaceAll('</SCORES>','');
                if(idVerificationdata.contains('LITIGATION-VERIFICATION-SUMMARY'))       
                {
                    if(!idVerificationdata.contains('<LITIGATION-VERIFICATION-SUMMARY/>'))
                    {
                        idVerificationdata = idVerificationdata.replaceAll(idVerificationdata.substringBetween('<LITIGATION-VERIFICATION-SUMMARY>', '</LITIGATION-VERIFICATION-SUMMARY>'), '');
                        idVerificationdata = idVerificationdata.replaceAll('<LITIGATION-VERIFICATION-SUMMARY>','');
                        idVerificationdata = idVerificationdata.replaceAll('</LITIGATION-VERIFICATION-SUMMARY>','');
                    }
                    else {
                        idVerificationdata = idVerificationdata.replaceAll('<LITIGATION-VERIFICATION-SUMMARY/>','');
                    }
                } 
                if(idVerificationdata.contains('AML-VERIFICATION-SUMMARY'))
                {              
                    if(!idVerificationdata.contains('<AML-VERIFICATION-SUMMARY/>'))    
                    {
                        idVerificationdata = idVerificationdata.replaceAll(idVerificationdata.substringBetween('<AML-VERIFICATION-SUMMARY>', '</AML-VERIFICATION-SUMMARY>'), '');    
                        idVerificationdata = idVerificationdata.replaceAll('<AML-VERIFICATION-SUMMARY>', '');
                        idVerificationdata = idVerificationdata.replaceAll('</AML-VERIFICATION-SUMMARY>', '');
                    }
                    else {
                        idVerificationdata = idVerificationdata.replaceAll('<AML-VERIFICATION-SUMMARY/>','');
                    }                
                }
                
                documentObj.load(idVerificationdata);
                rootElement = documentObj.getRootElement();
                for ( Dom.XMLNode childElement : rootElement.getChildElements()) {   
                    
                    if(expectedElements.contains(childElement.getName()) && String.isNotBlank(childElement.getText()) && String.isNotEmpty(childElement.getText())){
                        riskContainmentWrapperObj.Sherlock_Verification_Summary += childElement.getName() + ' - ' + childElement.getText() + '\n';                 
                    }
                    
                    for (Dom.XMLNode detailElement : childElement.getChildElements()){
                        
                        if(expectedElements.contains(detailElement.getName()) && String.isNotBlank(detailElement.getText()) && String.isNotEmpty(detailElement.getText())) {
                            riskContainmentWrapperObj.Sherlock_Verification_Summary += detailElement.getName() + ' - ' + detailElement.getText() + '\n';  
                        }                  
                        
                        for (Dom.XMLNode detailElement1 : detailElement.getChildElements()){    
                            
                            if(expectedElements.contains(detailElement1.getName()) && String.isNotBlank(detailElement1.getText()) && String.isNotEmpty(detailElement1.getText())) {
                                riskContainmentWrapperObj.Sherlock_Verification_Summary += detailElement1.getName() + ' - ' + detailElement1.getText() + '\n'; 
                            }  
                            
                            if(detailElement1.getName() == 'DESCRIPTION'){
                                riskContainmentWrapperObj.Sherlock_Verification_Summary += '\n'; 
                            }                                       
                        }
                    } 
                }  
            }
            
            if(xmlresponse.contains('VERIFICATION-SUMMARY') && xmlresponse.contains('AML-VERIFICATION-SUMMARY'))
            {
                String[] expectedElements = new List<String>{'DESCRIPTION','REQ-SERVICE-TYPE','REMARK','DESCRIPITION'};
                    if(xmlresponse.contains('AML-VERIFICATION-SUMMARY') && !xmlresponse.contains('<AML-VERIFICATION-SUMMARY/>'))
                    riskContainmentWrapperObj.Sherlock_Verification_Summary += '\n AML VERIFICATION SUMMARY :-\n\n';
                documentObj = new Dom.Document(); 
                rootElement = null;
                
                String amlVerificationData = (xmlresponse.substringBetween('<VERIFICATION-SUMMARY>', '</VERIFICATION-SUMMARY>')).remove(xmlresponse.substringBetween('<ID-VERIFICATION-SUMMARY>', '</ID-VERIFICATION-SUMMARY>'));
                amlVerificationData = amlVerificationData.replaceAll('<SCORES>','');
                amlVerificationData = amlVerificationData.replaceAll('</SCORES>','');
                
                if(amlVerificationData.contains('LITIGATION-VERIFICATION-SUMMARY'))
                {
                    if(!amlVerificationData.contains('<LITIGATION-VERIFICATION-SUMMARY/>'))
                    {
                        amlVerificationData = amlVerificationData.replaceAll(amlVerificationData.substringBetween('<LITIGATION-VERIFICATION-SUMMARY>', '</LITIGATION-VERIFICATION-SUMMARY>'), '');
                        amlVerificationData = amlVerificationData.replaceAll('<LITIGATION-VERIFICATION-SUMMARY>','');
                        amlVerificationData = amlVerificationData.replaceAll('</LITIGATION-VERIFICATION-SUMMARY>','');
                    }
                    else {
                        amlVerificationData = amlVerificationData.replaceAll('<LITIGATION-VERIFICATION-SUMMARY/>','');
                    }
                }       
                if(amlVerificationData.contains('ID-VERIFICATION-SUMMARY'))
                {
                    if(!amlVerificationData.contains('<ID-VERIFICATION-SUMMARY/>'))
                    {
                        amlVerificationData = amlVerificationData.replaceAll(amlVerificationData.substringBetween('<ID-VERIFICATION-SUMMARY>', '</ID-VERIFICATION-SUMMARY>'), '');
                        amlVerificationData = amlVerificationData.replaceAll('<ID-VERIFICATION-SUMMARY>', '');
                        amlVerificationData = amlVerificationData.replaceAll('</ID-VERIFICATION-SUMMARY>', '');
                    }
                    else {
                        amlVerificationData = amlVerificationData.replaceAll('<ID-VERIFICATION-SUMMARY/>', '');
                    }
                }
                
                documentObj.load(amlVerificationData);
                rootElement = documentObj.getRootElement();
                for ( Dom.XMLNode childElement : rootElement.getChildElements() ) { 
                    
                    if(expectedElements.contains(childElement.getName()) && String.isNotBlank(childElement.getText()) && String.isNotEmpty(childElement.getText())){
                        riskContainmentWrapperObj.Sherlock_Verification_Summary += childElement.getName() + ' - ' + childElement.getText() + '\n';                    
                    }
                    
                    for (Dom.XMLNode detailElement : childElement.getChildElements()){
                        
                        if(expectedElements.contains(detailElement.getName()) && String.isNotBlank(detailElement.getText()) && String.isNotEmpty(detailElement.getText()))  {
                            riskContainmentWrapperObj.Sherlock_Verification_Summary += detailElement.getName() + ' - ' + detailElement.getText() + '\n'; 
                        }                  
                        
                        
                        for (Dom.XMLNode detailElement1 : detailElement.getChildElements()){ 
                            
                            if(expectedElements.contains(detailElement1.getName()) && String.isNotBlank(detailElement1.getText()) && String.isNotEmpty(detailElement1.getText())) {
                                riskContainmentWrapperObj.Sherlock_Verification_Summary += detailElement1.getName() + ' - ' + detailElement1.getText() + '\n';     
                            }  
                            
                            if(detailElement1.getName() == 'DESCRIPTION'){
                                riskContainmentWrapperObj.Sherlock_Verification_Summary += '\n'; 
                            }                        
                        }
                    } 
                } 
            }      
        } 
        
        
        // Storing the Required Information from Issue API's Response on the Verification  Object...
        if(xmlresponse.containsIgnoreCase('<error>')){
            //verificationRecord.Sherlock_Case_Id__c = null;
            verificationRecord.Sherlock_Applicant_Details__c = null;
            verificationRecord.Sherlock_Rules_Details__c = null;
            verificationRecord.SherLock_Status__c = 'API FAILED';
            verificationRecord.Status__c = 'Failed';
            //verificationRecord.SherLock_Verification_Summary__c = null;
            
        }
        else if(calledFrom == 'Async')
        {
            verificationRecord.Sherlock_Case_Id__c = riskContainmentWrapperObj.SherLock_Case_Id;
            verificationRecord.Status__c = 'In Progress' ;   
            verificationRecord.SherLock_Status__c = NULL ;   
        }
        else if(calledFrom == 'Issue')
        {
            if(xmlresponse != 'IN PROCESS' )
            {
                verificationRecord.Sherlock_Applicant_Details__c = riskContainmentWrapperObj.Sherlock_Details_Applicant;
                verificationRecord.Sherlock_Rules_Details__c = riskContainmentWrapperObj.Sherlock_Details_Rules;
                verificationRecord.SherLock_Status__c = riskContainmentWrapperObj.SherLock_Status;
                verificationRecord.SherLock_Verification_Summary__c = riskContainmentWrapperObj.Sherlock_Verification_Summary;
                verificationRecord.Status__c = UB_ConstantsUtil.COMPLETEDSTATUS;
               
               /* System.debug('xmlImage     '+xmlresponse.substringBetween('<PRINTABLE-RPRT>','</PRINTABLE-RPRT>'));

                String base64Content = EncodingUtil.Base64Encode( Blob.valueOf( xmlresponse.substringBetween('<PRINTABLE-RPRT>','</PRINTABLE-RPRT>') ) );
                System.debug('SHERLOCK DOCUMENTTTT');

                Blob blobContent = Blob.valueOf( xmlresponse.substringBetween('<PRINTABLE-RPRT>','</PRINTABLE-RPRT>') );
                UB_CommonUtil.createDocument('Sherlock.html','Sherlock.html', blobContent,loanAppList[0].Loan_Application__c, loanAppList[0].Id,'Sherlock Report',NULL);
                */
                System.debug('SHERLOCK DOCUMENTTTT1111');
            }
            else {
                verificationRecord.SherLock_Status__c = 'IN PROCESS';
                verificationRecord.Sherlock_Applicant_Details__c = null;
                verificationRecord.Sherlock_Rules_Details__c = null;
                verificationRecord.SherLock_Verification_Summary__c = null;
                verificationRecord.Status__c = 'In Progress';
            }
        }
        
        try {
            update verificationRecord;
            return 'Success';
        } catch (Exception e) {

            system.debug('Exception Occured11111111111'+e.getMessage());
            return e.getMessage();
        }       
    }
    
    public class RCUResponseWrapper
    {
        public String SherLock_Status;
        public String SherLock_Case_Id;
        public String Sherlock_Details_Applicant;
        public String Sherlock_Details_Rules;
        public String Sherlock_Verification_Summary;        
    }

}