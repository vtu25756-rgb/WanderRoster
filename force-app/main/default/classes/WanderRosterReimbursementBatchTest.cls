
@IsTest
private class WanderRosterReimbursementBatchTest {

    @IsTest
    static void testBatchProcessesApprovedExpenses() {

        Travel_Request__c travel = new Travel_Request__c(
            Destination__c = 'Bengaluru',
            Purpose__c = 'Client meeting',
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Estimated_Cost__c = 10000,
            Department_Budget__c = 15000
        );
        insert travel;

        List<Expense__c> expenses = new List<Expense__c>{
            new Expense__c(
                Travel_Request__c = travel.Id,
                Amount__c = 500,
                Expense_Category__c = 'Hotel',
                Expense_Date__c = Date.today().addDays(2),
                Merchant_Name__c = 'Batch Test Hotel',
                Description__c = 'Approved hotel expense',
                Expense_Status__c = 'Approved',
                Reimbursement_Status__c = 'Pending'
            ),
            new Expense__c(
                Travel_Request__c = travel.Id,
                Amount__c = 200,
                Expense_Category__c = 'Food',
                Expense_Date__c = Date.today().addDays(2),
                Merchant_Name__c = 'Batch Test Restaurant',
                Description__c = 'Draft expense',
                Expense_Status__c = 'Draft',
                Reimbursement_Status__c = 'Pending'
            )
        };
        insert expenses;

        Test.startTest();
        Database.executeBatch(
            new WanderRosterReimbursementBatch(),
            100
        );
        Test.stopTest();

        Map<Id, Expense__c> results = new Map<Id, Expense__c>([
            SELECT Id, Expense_Status__c, Reimbursement_Status__c
            FROM Expense__c
            WHERE Id IN :new Set<Id>{expenses[0].Id, expenses[1].Id}
        ]);

        System.assertEquals(
            'Processing',
            results.get(expenses[0].Id).Reimbursement_Status__c,
            'Approved expense should enter reimbursement processing.'
        );

        System.assertEquals(
            'Draft',
            results.get(expenses[1].Id).Expense_Status__c,
            'Draft expense should remain a draft.'
        );

        System.assertEquals(
            'Pending',
            results.get(expenses[1].Id).Reimbursement_Status__c,
            'Draft expense should not enter reimbursement processing.'
        );
    }
}
