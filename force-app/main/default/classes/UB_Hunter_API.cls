/**
 * @File Name          : UB_Hunter_API.cls
 * @Description        : Handles API callouts to the Hunter API.
 * @Author             : Mohit
 * @Test CLass         : 
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         08-04-2024               Mohit                 Initial Version
 * 1.1         24-07-2024               Chandan               Modified Version
 */
public without sharing class UB_Hunter_API {
    UB_HTTPCalloutService service;
    String identifier, applicantId;
    
    public MatchResponse invokeAPI(String customerId) {
        List<Verification__c> createVerifyList = new List<Verification__c>();
        Verification__c verify = null;
        applicantId = customerId;
        List<Meta_Hunter_Rule_List__mdt> hunterRules = [SELECT Id,MasterLabel, Rule_Name__c, Rule_ID__c, Description__c
                                            From Meta_Hunter_Rule_List__mdt];
        
        try {
            // Select the loan applicant and its related loan application
            List<Loan_Applicant__c> loanAppList = new UB_LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
            List<Address__c> addressLst = new UB_AddressesSelector().getApplicantAddress(new Set<Id>{customerId});
            System.debug('addressLst   '+addressLst);
            String loanId = loanAppList[0]?.Loan_Application__r.Id;
            
            List<Loan_Application__c> loanApplicationLst = [SELECT Id, Branch__c, Branch__r.Name FROM Loan_Application__c WHERE Id = :loanId];
            List<API_Logger__c> createLogList = new List<API_Logger__c>();
            
            if (!loanAppList.isEmpty()) {
                identifier = loanAppList[0].Account__r.Name + loanAppList[0].Pan_Number__c.right(4) + String.ValueOf(System.Today());
                UB_Hunter_API hunterAPI = new UB_Hunter_API();
                hunterAPI.service = new UB_HTTPCalloutService('Hunter_API');
                
                String requestBody = buildRequestBody(hunterAPI, loanAppList, addressLst, loanApplicationLst);
                
                hunterAPI.service.setRequestBody(requestBody);
                String accessToken = UB_GenerateAccessToken.getToken('Token_Generate_API'); 
                hunterAPI.service.setHeaderParameter('Authorization', 'Bearer ' + accessToken);
                hunterAPI.service.setHeaderParameter('PartnerId', hunterAPI.service.getHeaderParameters().get('PartnerID'));
                hunterAPI.service.setHeaderParameter('Accept', '*/*');
                hunterAPI.service.setHeaderParameter('Content-Type', hunterAPI.service.getHeaderParameters().get('Content-Type'));
                
                HTTPResponse response = hunterAPI.service.sendRequest();
                //String xmlString = response.getBody().replaceAll('&lt;', '<').replaceAll('&gt;', '>');
                string xmlString = hunterAPI.service.calloutMetadata.Mock_Response__c.replaceAll('&lt;', '<');
                Integer statusCode = response.getStatusCode();
                MatchResponse matchResponse = parseMatchResponse(xmlString);
                String hunterRulesResponse = '';
                verify = createVerificationRecord(null);
                
                System.debug('RULE SIZEEE  '+matchResponse.MatchResult.ResultBlock.MatchSummary.Rules.size());
                for(UB_Hunter_API.Rule rule : matchResponse.MatchResult.ResultBlock.MatchSummary.Rules) {
                    Integer count =1;
                    if(rule.RuleID != NULL) {
                        System.debug('rulerulerulerule  '+rule);
                        hunterRulesResponse += 'Rule ID: '+rule.RuleID;
                        for(Meta_Hunter_Rule_List__mdt ruleMdt : hunterRules){
                            if(ruleMdt.Rule_ID__c  == rule.RuleID && count == 1){
                                hunterRulesResponse += '\n'+'Description: '+ ruleMdt.Description__c ;
                                count++;
                            }
                        }
                    }
                    if(rule.Score != NULL) {
                        System.debug('ScoreScoreScoreScoreScore  '+rule);
                        hunterRulesResponse += '\nScore: '+rule.Score;
                    }

                    hunterRulesResponse += '\n\n';
                    
                }

                System.debug('hunterRulesResponse>>>>  '+hunterRulesResponse);
                //response.MatchResult.ResultBlock.MatchSummary.Rules
                verify.Status__c = (statusCode == 200) ? 'Completed' : 'Failed';
                verify.Hunter_Total_Match_Score__c = String.valueOf(matchResponse.MatchResult.ResultBlock.MatchSummary.TotalMatchScore);
                verify.Hunter_Summary_Match__c = (matchResponse.MatchResult.ResultBlock.MatchSummary.matches > 0) ? 'Match Found' : 'Not Found';
                verify.Hunter_Status__c = (matchResponse.MatchResult.ResultBlock.ErrorWarnings.Errors.errorCount > 0) ? 'Error' : 'Completed';
                verify.Hunter_Response__c = hunterRulesResponse;
                createVerifyList.add(verify);
                insert createVerifyList;
                
                loanAppList[0].Hunter_Verification__c = createVerifyList[0].Id;
                update loanAppList;
                
                API_Logger__c apiLogger = UB_HTTPCalloutService.createAPILogRecord(
                    hunterAPI.service.getEndpointURL(), 
                    String.valueOf(hunterAPI.service.getHeaderParameters()), 
                    hunterAPI.service.getRequestMethod(), 
                    requestBody, 
                    response.getBody(), 
                    response.getStatusCode(), 
                    UB_Hunter_API.class.getName(), 
                    customerId, 
                    Id.valueOf(customerId).getSObjectType().getDescribe().getName(), 
                    UB_ConstantsUtil.REST_API_TYPE,
                    'Hunter API',
                    UB_ConstantsUtil.LOB_CV
                );
                
                createLogList.add(apiLogger);
                insert createLogList;
                
                return matchResponse;
            }
        } catch (Exception e) {
            UB_CommonUtil.createExceptionLogRecord(e, UB_ConstantsUtil.LOB_CV);
        }
        return null;
    }
    
    private String buildRequestBody(UB_Hunter_API hunterAPI, List<Loan_Applicant__c> loanAppList, List<Address__c> addressLst, List<Loan_Application__c> loanApplicationLst) {
        String requestBody = '{ "controlXml": " <ControlBlock xmlns=\\"urn:mclsoftware.co.uk:hunterII\\" xmlns:xsi=\\"http://www.w3.org/2001/XMLSchema-instance\\">';
        requestBody += '<Customer> <CustomerID>' + hunterAPI.service.getExtraParameter('CustomerID') + '</CustomerID>';
        requestBody += '<CustomerName>' + hunterAPI.service.getExtraParameter('CustomerName') + '</CustomerName>';
        requestBody += '</Customer> <Loading> <SubmissionLoad>' + hunterAPI.service.getExtraParameter('SubmissionLoad') + '</SubmissionLoad><SuppressVersion flag=\\"0\\" /> </Loading> <Matching> <MatchSchemeSet>';
        requestBody += '<SchemeSetID>' + hunterAPI.service.getExtraParameter('SchemeSetID') + '</SchemeSetID><SchemeSetID>' + hunterAPI.service.getExtraParameter('SchemeSetID2') + '</SchemeSetID>';
        requestBody += '</MatchSchemeSet> <PersistMatches>' + hunterAPI.service.getExtraParameter('PersistMatches') + '</PersistMatches>';
        requestBody += '<WorklistInsert>' + hunterAPI.service.getExtraParameter('WorklistInsert') + '</WorklistInsert>';
        requestBody += '</Matching> <Results> <RsltCode>' + hunterAPI.service.getExtraParameter('RsltCode') + '</RsltCode></Results>';
        requestBody += '</ControlBlock>", "batchXml": " <BATCH xmlns=\\"urn:mclsoftware.co.uk:hunterII\\"> <HEADER> <ORIGINATOR>' + hunterAPI.service.getExtraParameter('ORIGINATOR') + '</ORIGINATOR>';
        requestBody += '<COUNT>' + hunterAPI.service.getExtraParameter('COUNT') + '</COUNT> </HEADER> <SUBMISSIONS> <SUBMISSION>';
        requestBody += '<IDENTIFIER>' + hunterAPI.identifier + '</IDENTIFIER> <PRODUCT>' + hunterAPI.service.getExtraParameter('PRODUCT') + '</PRODUCT>';
        requestBody += '<CLASSIFICATION>' + hunterAPI.service.getExtraParameter('CLASSIFICATION') + '</CLASSIFICATION>';
        requestBody += '<DATE>' + DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('yyyy-MM-dd') + '</DATE>';
        requestBody += '<APP_DTE>' + DateTime.newInstance(loanAppList[0].CreatedDate.year(), loanAppList[0].CreatedDate.month(), loanAppList[0].CreatedDate.day()).format('yyyy-MM-dd') + '</APP_DTE>';
        requestBody += '<BRNCH_RGN></BRNCH_RGN> <MA> <PAN>' + loanAppList[0].Pan_Number__c + '</PAN>';
        requestBody += '<FST_NME>' + loanAppList[0].First_Name__c + '</FST_NME>'; 
        requestBody += '<LST_NME>' + loanAppList[0].Last_Name__c + '</LST_NME>';
        if (loanAppList[0].Date_of_Birth__c != null) {
            requestBody += '<DOB>' + DateTime.newInstance(loanAppList[0].Date_of_Birth__c.year(), loanAppList[0].Date_of_Birth__c.month(), loanAppList[0].Date_of_Birth__c.day()).format('yyyy-MM-dd') + '</DOB> ';
        }
        requestBody += '<MA_CA>';
        if (addressLst[0].Name != null) {
            requestBody += '<ADD>' + addressLst[0].Name + '</ADD>';
        }
        if (addressLst[0].City__c != null && addressLst[0].State__c != null) {
            requestBody += '<CTY>' + addressLst[0].City__c + '</CTY> <STE>' + addressLst[0].State__c + '</STE>';
        }
        if (addressLst[0].Pincode__c != null) {
            requestBody += '<PIN>' + addressLst[0].Pincode__c + '</PIN> </MA_CA> <MA_PMA>';
        }
        requestBody += '</MA_PMA> <MA_HT> <TEL_NO>' + loanAppList[0].Mobile__c + '</TEL_NO> </MA_HT> <MA_MT> <TEL_NO>' + loanAppList[0].Mobile__c + '</TEL_NO> </MA_MT> <MA_EMA> <EMA_ADD>' + loanAppList[0].Email__c + '</EMA_ADD> </MA_EMA><MA_BNK>';   
        requestBody += '<BNK_NM>BOB</BNK_NM> <ACC_NO>' + loanAppList[0].Account_Number__c + '</ACC_NO>'; //
        if (loanApplicationLst[0].Branch__r.Name != null) {
            requestBody += '<BRNCH>' + loanApplicationLst[0].Branch__r.Name + '</BRNCH> <MICR></MICR>';
        }
        requestBody += '</MA_BNK> <MA_ID> <DOC_TYP>' + hunterAPI.service.getExtraParameter('DOC_TYP') + '</DOC_TYP> <DOC_NO>' + 'KNL5XaC6nOaX3rjN' + '</DOC_NO> </MA_ID> <MA_EMP>';
        requestBody += '<ORG_NME>' + 'UTKARSH SMALL FINANCE BANK LTD' + '</ORG_NME> <EMP_IND></EMP_IND> <EMP_NO></EMP_NO> <MA_EMP_AD>';
        //<ADD>babatpur varanasi</ADD> <CTY>varanasi</CTY> <STE>Uttar Pradesh</STE> <CTRY>India</CTRY> <PIN>221105</PIN>  
        requestBody += '</MA_EMP_AD></MA_EMP> </MA> </SUBMISSION></SUBMISSIONS> </BATCH>",';
        requestBody += '"username": "' + hunterAPI.service.getExtraParameter('webusername') + '", "password": "' + hunterAPI.service.getExtraParameter('webpassword') + '" }';
        System.debug('requestBody>>>' + requestBody);
        
        return requestBody;
    }
    
      public static MatchResponse parseMatchResponse(String xmlString) {
        system.debug('xmlstring==?'+xmlString);
        if (String.isEmpty(xmlString)) {
            return null;
        }
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);
        MatchResponse response = new MatchResponse();
        
        Dom.XmlNode rootNode = doc.getRootElement();
        Dom.XmlNode bodyNode = rootNode.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
        System.debug('bodyNode===>' + bodyNode);
        if (bodyNode != null) {
            Dom.XmlNode matchResponseNode = bodyNode.getChildElement('MatchResponse', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
            System.debug('matchResponseNode===>' + matchResponseNode);
            if (matchResponseNode != null) {
                Dom.XmlNode matchResultNode = matchResponseNode.getChildElement('MatchResult', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                System.debug('matchResultNode===>' + matchResultNode);
                if (matchResultNode != null) {
                    response.MatchResult = new MatchResult();
                    response.MatchResult.ResultBlock = new ResultBlock();
                    
                    Dom.XmlNode resultBlockNode = matchResultNode.getChildElement('ResultBlock', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                    System.debug('resultBlockNode===>' + resultBlockNode);
                    if (resultBlockNode != null) {
                        Dom.XmlNode matchSummaryNode = resultBlockNode.getChildElement('MatchSummary', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                        if (matchSummaryNode != null) {
                            response.MatchResult.ResultBlock.MatchSummary = new MatchSummary();
                            response.MatchResult.ResultBlock.MatchSummary.matches = Integer.valueOf(matchSummaryNode.getAttribute('matches', null));
                            response.MatchResult.ResultBlock.MatchSummary.TotalMatchScore = (matchSummaryNode.getChildElement('TotalMatchScore', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText());
                            
                            // Parse Rules
                            Dom.XmlNode rulesNode = matchSummaryNode.getChildElement('Rules', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                            if (rulesNode != null) {
                                response.MatchResult.ResultBlock.MatchSummary.Rules = new List<Rule>();
                                for (Dom.XmlNode ruleNode : rulesNode.getChildElements()) {
                                    Rule rule = new Rule();
                                    rule.ruleCount = Integer.valueOf(ruleNode.getAttribute('ruleCount', null));
                                    rule.RuleID = ruleNode.getChildElement('RuleID', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText();
                                    rule.Score = Integer.valueOf(ruleNode.getChildElement('Score', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText());
                                    response.MatchResult.ResultBlock.MatchSummary.Rules.add(rule);
                                }
                            }
                            
                            // Parse MatchSchemes
                            Dom.XmlNode matchSchemesNode = matchSummaryNode.getChildElement('MatchSchemes', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                            if (matchSchemesNode != null) {
                                response.MatchResult.ResultBlock.MatchSummary.MatchSchemes = new List<MatchScheme>();
                                for (Dom.XmlNode schemeNode : matchSchemesNode.getChildElements()) {
                                    MatchScheme matchScheme = new MatchScheme();
                                    //  matchScheme.schemeCount = Integer.valueOf(schemeNode.getAttribute('schemeCount', null));
                                    Scheme scheme = new Scheme();
                                    // scheme.SchemeID = Integer.valueOf(schemeNode.getChildElement('SchemeID', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText());
                                    scheme.Score = Integer.valueOf(schemeNode.getChildElement('Score', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText());
                                    matchScheme.Scheme = scheme;
                                    response.MatchResult.ResultBlock.MatchSummary.MatchSchemes.add(matchScheme);
                                }
                            }
                        }
                        
                        // Parse ErrorWarnings
                        Dom.XmlNode errorWarningsNode = resultBlockNode.getChildElement('ErrorWarnings', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                        if (errorWarningsNode != null) {
                            response.MatchResult.ResultBlock.ErrorWarnings = new ErrorWarnings();
                            response.MatchResult.ResultBlock.ErrorWarnings.Errors = new Errors();
                            Dom.XmlNode errorsNode = errorWarningsNode.getChildElement('Errors', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                            if (errorsNode != null) {
                                response.MatchResult.ResultBlock.ErrorWarnings.Errors.errorCount = Integer.valueOf(errorsNode.getAttribute('errorCount', null));
                            }
                            response.MatchResult.ResultBlock.ErrorWarnings.Warnings = new Warnings();
                            Dom.XmlNode warningsNode = errorWarningsNode.getChildElement('Warnings', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                            if (warningsNode != null) {
                                response.MatchResult.ResultBlock.ErrorWarnings.Warnings.warningCount = Integer.valueOf(warningsNode.getAttribute('warningCount', null));
                                response.MatchResult.ResultBlock.ErrorWarnings.Warnings.Warning = new List<Warning>();
                                
                                for (Dom.XmlNode warningNode : warningsNode.getChildElements()) {
                                    Warning warning = new Warning();
                                    warning.Numbers = Integer.valueOf(warningNode.getChildElement('Number', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText());
                                    warning.Message = warningNode.getChildElement('Message', 'http://www.mclsoftware.co.uk/HunterII/WebServices').getText();
                                    warning.Values = new List<Integer>();
                                    Dom.XmlNode valuesNode = warningNode.getChildElement('Values', 'http://www.mclsoftware.co.uk/HunterII/WebServices');
                                    if (valuesNode != null) {
                                        for (Dom.XmlNode valueNode : valuesNode.getChildElements()) {
                                            warning.Values.add(Integer.valueOf(valueNode.getText()));
                                        }
                                    }
                                    response.MatchResult.ResultBlock.ErrorWarnings.Warnings.Warning.add(warning);
                                }
                            }
                        }
                    }
                }
            }
        }
        return response;
    }
    private Verification__c createVerificationRecord(String failedReason) {
        Verification__c verify = UB_CommonUtil.createVerfication(applicantId, UB_ConstantsUtil.HUNTER_API_RECORD_TYPE, '');
        verify.Failed_Reason__c = failedReason;
        verify.Loan_Applicant__c = applicantId;
        return verify;
    }
    
      // Separate classes for deserialization of the MatchResponse
    public class MatchResponse {
        public MatchResult MatchResult;
    }
    
    public class MatchResult {
        public ResultBlock ResultBlock;
    }
    
    public class ResultBlock {
        public MatchSummary MatchSummary;
        public ErrorWarnings ErrorWarnings;
    }
    
    public class MatchSummary {
        public Integer matches;
        public String TotalMatchScore;
        public List<Rule> Rules;
        public List<MatchScheme> MatchSchemes;
    }
    
    public class Rule {
        public Integer ruleCount;
        public String RuleID;
        public Integer Score;
    }
    
    public class MatchScheme {
        public Integer schemeCount;
        public Scheme Scheme;
    }
    
    public class Scheme {
        public Integer SchemeID;
        public Integer Score;
    }
    
    public class ErrorWarnings {
        public Errors Errors;
        public Warnings Warnings;
    }
    
    public class Errors {
        public Integer errorCount;
    }
    
    public class Warnings {
        public Integer warningCount;
        public List<Warning> Warning;
    }
    
    public class Warning {
        public Integer Numbers;
        public String Message;
        public List<Integer> Values;
    }
}