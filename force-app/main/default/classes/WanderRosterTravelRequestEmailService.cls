public with sharing class WanderRosterTravelRequestEmailService {

    public static void sendApprovalRequestEmails(List<Travel_Request__c> newRecords, Map<Id, Travel_Request__c> oldMap) {
        List<Id> qualifyingRequestIds = new List<Id>();

        for (Travel_Request__c tr : newRecords) {
            Boolean isStatusChangedToSubmitted = tr.Status__c == 'Submitted' &&
                (oldMap == null || oldMap.get(tr.Id).Status__c != 'Submitted');

            if (isStatusChangedToSubmitted) {
                qualifyingRequestIds.add(tr.Id);
            }
        }

        if (qualifyingRequestIds.isEmpty()) {
            return;
        }

        // Query related details, owner, and owner's manager
        List<Travel_Request__c> requestsToSend = [
            SELECT Id, Name, Purpose__c, Destination__c, Estimated_Cost__c, 
                   Department_Budget__c, Risk_Level__c, Status__c,
                   Owner.Name, Owner.Email, OwnerId,
                   CreatedBy.Name
            FROM Travel_Request__c
            WHERE Id IN :qualifyingRequestIds
        ];

        // Retrieve manager IDs from User standard hierarchy
        Set<Id> ownerIds = new Set<Id>();
        for (Travel_Request__c tr : requestsToSend) {
            ownerIds.add(tr.OwnerId);
        }

        Map<Id, User> userManagerMap = new Map<Id, User>([
            SELECT Id, Email, ManagerId, Manager.Email, Manager.Name 
            FROM User 
            WHERE Id IN :ownerIds
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Travel_Request__c tr : requestsToSend) {
            User submitter = userManagerMap.get(tr.OwnerId);
            String recipientEmail;

            if (submitter != null && submitter.Manager != null && String.isNotBlank(submitter.Manager.Email)) {
                recipientEmail = submitter.Manager.Email;
            } else if (submitter != null && String.isNotBlank(submitter.Email)) {
                // Fallback to the submitter/running user if no manager is configured
                recipientEmail = submitter.Email;
            }

            if (String.isBlank(recipientEmail)) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ recipientEmail });
            mail.setSubject('Approval Needed: Travel Request ' + tr.Name);

            String orgUrl = URL.getOrgDomainUrl().toExternalForm();
            String recordUrl = orgUrl + '/' + tr.Id;

            String htmlBody = '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; color: #333;">'
                + '<div style="max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">'
                + '<div style="background-color: #0176D3; color: #fff; padding: 18px; text-align: center;">'
                + '<h2 style="margin: 0;">WanderRoster Approval Request</h2></div>'
                + '<div style="padding: 20px; background-color: #ffffff;">'
                + '<p>Hello,</p>'
                + '<p>A new Travel Request has been submitted and is awaiting your review and approval.</p>'
                + '<table style="width: 100%; border-collapse: collapse; margin: 16px 0;">'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold; width: 35%;">Travel Request:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + tr.Name + '</td></tr>'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold;">Destination:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + (tr.Destination__c != null ? tr.Destination__c : 'N/A') + '</td></tr>'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold;">Purpose:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + (tr.Purpose__c != null ? tr.Purpose__c : 'N/A') + '</td></tr>'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold;">Estimated Cost:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + (tr.Estimated_Cost__c != null ? String.valueOf(tr.Estimated_Cost__c) : '0') + '</td></tr>'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold;">Risk Level:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + (tr.Risk_Level__c != null ? tr.Risk_Level__c : 'Low') + '</td></tr>'
                + '<tr><td style="padding: 8px; border-bottom: 1px solid #eee; font-weight: bold;">Status:</td><td style="padding: 8px; border-bottom: 1px solid #eee;">' + tr.Status__c + '</td></tr>'
                + '</table>'
                + '<p style="text-align: center; margin-top: 20px;">'
                + '<a href="' + recordUrl + '" style="background-color: #0176D3; color: #ffffff; padding: 10px 20px; text-decoration: none; border-radius: 4px; font-weight: bold;">View Travel Request</a>'
                + '</p></div>'
                + '<div style="font-size: 11px; color: #888; text-align: center; padding: 12px; background-color: #f4f6f9;">'
                + 'Sent automatically by WanderRoster Travel & Expense Management.</div></div></body></html>';

            mail.setHtmlBody(htmlBody);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}