@isTest
private class WanderRosterTREmailServiceTest {

    @isTest
    static void testEmailNotificationOnSubmitted() {
        Travel_Request__c tr = new Travel_Request__c(
            Purpose__c = 'Client Onsite Integration',
            Destination__c = 'Chennai',
            Estimated_Cost__c = 1500,
            Status__c = 'Draft'
        );
        insert tr;

        Test.startTest();
        tr.Status__c = 'Submitted';
        update tr;
        
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations, 'An approval email should have been dispatched.');
    }
}