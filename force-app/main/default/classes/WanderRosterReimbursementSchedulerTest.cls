
@IsTest
private class WanderRosterReimbursementSchedulerTest {

    @IsTest
    static void testSchedulerLaunchesReimbursementBatch() {

        Travel_Request__c travel = new Travel_Request__c(
            Destination__c = 'Bengaluru',
            Purpose__c = 'Client meeting',
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Estimated_Cost__c = 10000,
            Department_Budget__c = 15000
        );
        insert travel;

        Expense__c expense = new Expense__c(
            Travel_Request__c = travel.Id,
            Amount__c = 500,
            Expense_Category__c = 'Hotel',
            Expense_Date__c = Date.today().addDays(2),
            Merchant_Name__c = 'Scheduler Test Hotel',
            Description__c = 'Approved hotel expense',
            Expense_Status__c = 'Approved',
            Reimbursement_Status__c = 'Pending'
        );
        insert expense;

        Test.startTest();

        new WanderRosterReimbursementScheduler().execute(null);

        Test.stopTest();

        Expense__c result = [
            SELECT Reimbursement_Status__c
            FROM Expense__c
            WHERE Id = :expense.Id
        ];

        System.assertEquals(
            'Processing',
            result.Reimbursement_Status__c,
            'The scheduler should launch the batch and process the approved expense.'
        );
    }
}
