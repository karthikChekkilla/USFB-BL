/**
 * @File Name          : UB_BANK_STATEMENT_Perfios_Integration
 * @Description        : Class to get the Details to initiate Transaction
 * @Author             : Chandan Kumar
 * 
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0                           Initial Version
 */
public class UB_Perfios_API {
    @AuraEnabled
    public static void initiateTransaction(String customerId,string password){
        system.debug('ApplicantId===>'+customerId);
        UB_BANK_STATEMENT_Perfios_Integration queueableInstance = new UB_BANK_STATEMENT_Perfios_Integration(customerId,password);
        System.enqueueJob(queueableInstance);
    }
}