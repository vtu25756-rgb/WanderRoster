
public class WanderRosterReimbursementBatch
    implements Database.Batchable<SObject> {

    public Database.QueryLocator start(
        Database.BatchableContext context
    ) {
        return Database.getQueryLocator([
            SELECT Id, Reimbursement_Status__c
            FROM Expense__c
            WHERE Expense_Status__c = 'Approved'
            AND Reimbursement_Status__c = 'Pending'
        ]);
    }

    public void execute(
        Database.BatchableContext context,
        List<SObject> scope
    ) {
        List<Expense__c> expensesToUpdate = new List<Expense__c>();

        for (SObject record : scope) {
            Expense__c expense = (Expense__c) record;
            expense.Reimbursement_Status__c = 'Processing';
            expensesToUpdate.add(expense);
        }

        if (!expensesToUpdate.isEmpty()) {
            update expensesToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('WanderRoster reimbursement batch completed.');
    }
}
