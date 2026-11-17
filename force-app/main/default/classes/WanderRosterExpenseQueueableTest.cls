
@IsTest
private class WanderRosterExpenseQueueableTest {

    @IsTest
    static void testSubmittedExpenseMovesToFinanceReview() {

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
            Merchant_Name__c = 'Test Hotel',
            Description__c = 'Hotel expense',
            Expense_Status__c = 'Submitted'
        );

        Test.startTest();
        insert expense;
        Test.stopTest();

        Expense__c savedExpense = [
            SELECT Id, Expense_Status__c
            FROM Expense__c
            WHERE Id = :expense.Id
        ];

        System.assertEquals(
            'Pending Finance Review',
            savedExpense.Expense_Status__c,
            'A submitted expense should move to Pending Finance Review.'
        );
    }
}
