trigger TravelRequestApprovalSync on Travel_Request__c (after update) {
    Set<Id> approvedRequestIds = new Set<Id>();
    Set<Id> rejectedRequestIds = new Set<Id>();

    for (Travel_Request__c tr : Trigger.new) {
        Travel_Request__c oldTr = Trigger.oldMap.get(tr.Id);

        // Check if Status changed
        if (tr.Status__c != oldTr.Status__c) {
            if (tr.Status__c == 'Approved') {
                approvedRequestIds.add(tr.Id);
            } else if (tr.Status__c == 'Rejected') {
                rejectedRequestIds.add(tr.Id);
            }
        }
    }

    List<Expense__c> expensesToUpdate = new List<Expense__c>();

    if (!approvedRequestIds.isEmpty()) {
        for (Expense__c exp : [
            SELECT Id, Reimbursement_Status__c 
            FROM Expense__c 
            WHERE Travel_Request__c IN :approvedRequestIds
        ]) {
            exp.Reimbursement_Status__c = 'Approved';
            expensesToUpdate.add(exp);
        }
    }

    if (!rejectedRequestIds.isEmpty()) {
        for (Expense__c exp : [
            SELECT Id, Reimbursement_Status__c 
            FROM Expense__c 
            WHERE Travel_Request__c IN :rejectedRequestIds
        ]) {
            exp.Reimbursement_Status__c = 'Rejected';
            expensesToUpdate.add(exp);
        }
    }

    if (!expensesToUpdate.isEmpty()) {
        update expensesToUpdate;
    }
}