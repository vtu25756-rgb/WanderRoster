public without sharing class TravelInsightsController {

    public class ItinerarySummaryWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String travelName;
        @AuraEnabled public String destination;
        @AuraEnabled public String status;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Integer totalDays;
        @AuraEnabled public Decimal estimatedCost;
        @AuraEnabled public Decimal dailyBurnRate;
        @AuraEnabled public String submitterName;
    }

    @AuraEnabled(cacheable=true)
    public static ItinerarySummaryWrapper getTravelInsights(Id recordId) {
        Travel_Request__c tr = [
            SELECT Id, Name, Destination__c, Status__c, Start_Date__c, End_Date__c, 
                   Estimated_Cost__c, Purpose__c, CreatedBy.Name, CreatedBy.FirstName, 
                   CreatedBy.LastName, CreatedBy.Contact.Name, CreatedBy.CommunityNickname 
            FROM Travel_Request__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];

        ItinerarySummaryWrapper wrap = new ItinerarySummaryWrapper();
        wrap.recordId = tr.Id;
        wrap.travelName = tr.Name;
        wrap.destination = tr.Destination__c;
        wrap.status = tr.Status__c;
        wrap.startDate = tr.Start_Date__c;
        wrap.endDate = tr.End_Date__c;
        wrap.estimatedCost = tr.Estimated_Cost__c != null ? tr.Estimated_Cost__c : 0;

        // Resolve clean employee name
        String empName = 'Employee';
        if (tr.CreatedBy != null) {
            if (tr.CreatedBy.Contact != null && String.isNotBlank(tr.CreatedBy.Contact.Name)) {
                empName = tr.CreatedBy.Contact.Name;
            } else if (String.isNotBlank(tr.CreatedBy.CommunityNickname) && !tr.CreatedBy.CommunityNickname.toLowerCase().startsWith('user17')) {
                empName = tr.CreatedBy.CommunityNickname;
            } else if (String.isNotBlank(tr.CreatedBy.FirstName) || String.isNotBlank(tr.CreatedBy.LastName)) {
                empName = ((tr.CreatedBy.FirstName != null ? tr.CreatedBy.FirstName : '') + ' ' + 
                          (tr.CreatedBy.LastName != null ? tr.CreatedBy.LastName : '')).trim();
            } else {
                empName = tr.CreatedBy.Name;
            }
        }
        wrap.submitterName = empName;

        Integer days = 1;
        if (tr.Start_Date__c != null && tr.End_Date__c != null) {
            days = tr.Start_Date__c.daysBetween(tr.End_Date__c) + 1;
            if (days < 1) days = 1;
        }
        wrap.totalDays = days;
        wrap.dailyBurnRate = (wrap.estimatedCost / days).setScale(2);

        return wrap;
    }
}