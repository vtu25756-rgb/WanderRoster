trigger WanderRosterTravelRequestTrigger on Travel_Request__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        WanderRosterTravelRequestEmailService.sendApprovalRequestEmails(Trigger.new, Trigger.oldMap);
    }
}