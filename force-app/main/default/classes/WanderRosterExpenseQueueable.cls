
public class WanderRosterExpenseQueueable implements Queueable {

    private Set<Id> expenseIds;

    public WanderRosterExpenseQueueable(Set<Id> expenseIds) {
        this.expenseIds = expenseIds;
    }

    public void execute(QueueableContext context) {

        List<Expense__c> expensesToUpdate = new List<Expense__c>();

        for (Expense__c expense : [
            SELECT Id, Expense_Status__c
            FROM Expense__c
            WHERE Id IN :expenseIds
            AND Expense_Status__c = 'Submitted'
        ]) {
            expense.Expense_Status__c = 'Pending Finance Review';
            expensesToUpdate.add(expense);
        }

        if (!expensesToUpdate.isEmpty()) {
            update expensesToUpdate;
        }
    }
}
