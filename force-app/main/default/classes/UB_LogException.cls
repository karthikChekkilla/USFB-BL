/**
* @File Name          : UB_LogException.cls
* @Description        : Class to insert ExceptionLog into system.
* @Author             : Zafaruddin
* @Test CLass         : UB_LogExceptionTest
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         20-03-2024           Zafaruddin         Initial Version
*/
public class UB_LogException extends Exception {
    
    public String ModuleName {get; set;}
    public String StackTrace {get; set;}
    public String ClassName {get; set;}
    public String MethodName {get; set;}
     
    /**
     * @Description : Method to insert Exception record in system
     * @Author      :Zafaruddin
     * @Date        :21/03/2024
    */
    public void log(Exception ex,String lob)
    {
            System.debug('EORRRRR LOGGGGGGG');
        	if(ex != null) {
                System.debug('EORRRRR LOGGGGGGG 111 ' +ex);
                stackTrace = ex.getStackTraceString().substringBefore('\n');
                System.debug('stackTrace  '+stackTrace);
                className = stackTrace.substringAfter('.').substringBefore('.');
                System.debug('className   '+className);
                methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');  
                System.debug('methodName   '+methodName);
                System.debug('Exception EEEE  '+ex);
            
                Exception_Logger__c logger = new Exception_Logger__c();
                logger.Module_Name__c = ModuleName;
                logger.Stack_Trace__c = ex.getStackTraceString();
                logger.Class_Name__c = className;
                logger.Method_Name__c = methodName;
                logger.Line_Number__c = ex.getLineNumber();
                logger.Exception_Type__c = ex.getTypeName();
                logger.Exception_Cause__c = String.valueOf(ex.getCause());
                logger.LOB__c = lob;
                logger.Exception_Message__c = ex.getMessage();
                System.debug('BEFORE INSERT  logger   '+logger);
                insert logger; 
            
            System.debug('AFTER INSERT    logger   '+logger);
        }
        	        
    }
    
}