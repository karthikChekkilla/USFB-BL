/**
* @File Name          : BL_RejectionBatchSchedule
* @Description        : Batch Schedule for the rejection hard or soft
* @Author             : Lakshya Verma
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
global with sharing class BL_RejectionBatchSchedule implements Schedulable{
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        BL_RejectionBatch batchReject = new BL_RejectionBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Id batchId = Database.executeBatch(batchReject, 200);
    }
}