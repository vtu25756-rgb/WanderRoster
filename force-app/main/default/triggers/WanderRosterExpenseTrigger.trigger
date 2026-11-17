
trigger WanderRosterExpenseTrigger on Expense__c (after insert, after update) {

    Set<Id> submittedExpenseIds = new Set<Id>();

    for (Expense__c expense : Trigger.new) {

        Boolean isSubmitted =
            expense.Expense_Status__c == 'Submitted';

        Boolean wasSubmitted = false;

        if (Trigger.isUpdate) {
            wasSubmitted =
                Trigger.oldMap.get(expense.Id).Expense_Status__c
                == 'Submitted';
        }

        if (isSubmitted && !wasSubmitted) {
            submittedExpenseIds.add(expense.Id);
        }
    }

    if (!submittedExpenseIds.isEmpty()) {
        System.enqueueJob(
            new WanderRosterExpenseQueueable(submittedExpenseIds)
        );
    }
}
