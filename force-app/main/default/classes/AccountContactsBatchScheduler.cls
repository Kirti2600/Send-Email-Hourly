global class AccountContactsBatchScheduler implements Schedulable
{
    global void execute(SchedulableContext sc) 
    {
        // Run the batch job
        Database.executeBatch(new AccountContactBatch());
    }

    // Method to schedule the batch job
    public static void scheduleBatchJob(String jobName, String cronExp) 
    {
        // Abort existing jobs with the same name to avoid duplicates
        List<CronTrigger> existingJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }

        // Schedule the new job
        System.schedule(jobName, cronExp, new AccountContactBatchScheduler());
    }
}