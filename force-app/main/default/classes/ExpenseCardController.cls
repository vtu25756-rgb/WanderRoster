public without sharing class ExpenseCardController {
    @AuraEnabled(cacheable=true)
    public static ExpenseWrapper getExpenseDetails(Id recordId) {
        Expense__c exp = [
            SELECT Id, Name, Amount__c, Expense_Date__c, Status__c,
                   Travel_Request__c, Travel_Request__r.Name
            FROM Expense__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        ExpenseWrapper wrap = new ExpenseWrapper();
        wrap.expNumber = exp.Name;
        wrap.travelRequestNumber = exp.Travel_Request__r != null ? exp.Travel_Request__r.Name : 'Not Assigned';
        wrap.amount = exp.Amount__c != null ? exp.Amount__c : 0;
        wrap.expenseDate = exp.Expense_Date__c;
        wrap.status = String.isNotBlank(exp.Status__c) ? exp.Status__c : 'Draft';
        return wrap;
    }

    public class ExpenseWrapper {
        @AuraEnabled public String expNumber;
        @AuraEnabled public String travelRequestNumber;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date expenseDate;
        @AuraEnabled public String status;
    }
}