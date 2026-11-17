public without sharing class WanderRosterPortalApprovalController {

    public class UserContextWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String roleCategory; 
        @AuraEnabled public Boolean isApprover;
    }

    public class TravelRequestWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String destination;
        @AuraEnabled public String purpose;
        @AuraEnabled public Decimal estimatedCost;
        @AuraEnabled public String status;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Id createdById;
        @AuraEnabled public String submitterName;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled(cacheable=true)
    public static UserContextWrapper getUserContext() {
        Id currentUserId = UserInfo.getUserId();
        UserContextWrapper context = new UserContextWrapper();

        User currentUser = [
            SELECT Id, Name, FirstName, LastName, Email, Profile.Name, UserRole.Name, Contact.Name, CommunityNickname 
            FROM User 
            WHERE Id = :currentUserId 
            LIMIT 1
        ];

        context.userId = currentUser.Id;
        
        // Resolve display name for the current logged-in user
        if (currentUser.Contact != null && String.isNotBlank(currentUser.Contact.Name)) {
            context.userName = currentUser.Contact.Name;
        } else if (String.isNotBlank(currentUser.CommunityNickname) && !currentUser.CommunityNickname.toLowerCase().startsWith('user17')) {
            context.userName = currentUser.CommunityNickname;
        } else if (String.isNotBlank(currentUser.FirstName) || String.isNotBlank(currentUser.LastName)) {
            context.userName = ((currentUser.FirstName != null ? currentUser.FirstName : '') + ' ' + 
                                (currentUser.LastName != null ? currentUser.LastName : '')).trim();
        } else {
            context.userName = currentUser.Name;
        }

        context.userEmail = currentUser.Email;

        Set<String> assignedPermSets = new Set<String>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :currentUserId
        ]) {
            assignedPermSets.add(psa.PermissionSet.Name.toLowerCase());
        }

        String profileName = currentUser.Profile.Name.toLowerCase();
        String roleName = currentUser.UserRole != null ? currentUser.UserRole.Name.toLowerCase() : '';

        if (assignedPermSets.contains('wanderroster_finance') || roleName.contains('finance')) {
            context.roleCategory = 'Finance';
            context.isApprover = true;
        } else if (
            assignedPermSets.contains('wanderroster_manager') || 
            assignedPermSets.contains('wanderroster_admin') || 
            roleName.contains('manager') ||
            profileName.contains('system administrator')
        ) {
            context.roleCategory = 'Manager';
            context.isApprover = true;
        } else {
            context.roleCategory = 'Employee';
            context.isApprover = false;
        }

        return context;
    }

    @AuraEnabled(cacheable=true)
    public static List<TravelRequestWrapper> getTravelRequests() {
        Id currentUserId = UserInfo.getUserId();

        User currentUser = [
            SELECT Id, Profile.Name, UserRole.Name 
            FROM User 
            WHERE Id = :currentUserId 
            LIMIT 1
        ];

        Set<String> assignedPermSets = new Set<String>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :currentUserId
        ]) {
            assignedPermSets.add(psa.PermissionSet.Name.toLowerCase());
        }

        String profileName = currentUser.Profile.Name.toLowerCase();
        String roleName = currentUser.UserRole != null ? currentUser.UserRole.Name.toLowerCase() : '';

        Boolean isManagerOrFinance = assignedPermSets.contains('wanderroster_manager') 
            || assignedPermSets.contains('wanderroster_finance') 
            || assignedPermSets.contains('wanderroster_admin')
            || profileName.contains('system administrator')
            || roleName.contains('manager')
            || roleName.contains('finance');

        List<Travel_Request__c> rawList;
        if (isManagerOrFinance) {
            // WHERE CreatedBy.IsActive = TRUE automatically filters out deactivated employees
            rawList = [
                SELECT Id, Name, Destination__c, Purpose__c, Estimated_Cost__c, Status__c, 
                       Start_Date__c, End_Date__c, CreatedById, 
                       CreatedBy.Name, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.CommunityNickname,
                       CreatedBy.Contact.Name, CreatedBy.Contact.FirstName, CreatedBy.Contact.LastName,
                       CreatedDate
                FROM Travel_Request__c
                WHERE CreatedBy.IsActive = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
        } else {
            rawList = [
                SELECT Id, Name, Destination__c, Purpose__c, Estimated_Cost__c, Status__c, 
                       Start_Date__c, End_Date__c, CreatedById, 
                       CreatedBy.Name, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.CommunityNickname,
                       CreatedBy.Contact.Name, CreatedBy.Contact.FirstName, CreatedBy.Contact.LastName,
                       CreatedDate
                FROM Travel_Request__c
                WHERE CreatedById = :currentUserId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        }

        List<TravelRequestWrapper> wrappedList = new List<TravelRequestWrapper>();
        for (Travel_Request__c tr : rawList) {
            TravelRequestWrapper wrap = new TravelRequestWrapper();
            wrap.id = tr.Id;
            wrap.name = tr.Name;
            wrap.destination = tr.Destination__c;
            wrap.purpose = tr.Purpose__c;
            wrap.estimatedCost = tr.Estimated_Cost__c;
            wrap.status = tr.Status__c;
            wrap.startDate = tr.Start_Date__c;
            wrap.endDate = tr.End_Date__c;
            wrap.createdById = tr.CreatedById;
            wrap.createdDate = tr.CreatedDate;

            // Priority order: Contact Name -> Non-masked Nickname -> First + Last -> Name -> Fallback
            String resolvedName = '';
            if (tr.CreatedBy != null) {
                if (tr.CreatedBy.Contact != null && String.isNotBlank(tr.CreatedBy.Contact.Name)) {
                    resolvedName = tr.CreatedBy.Contact.Name;
                } else if (String.isNotBlank(tr.CreatedBy.CommunityNickname) && !tr.CreatedBy.CommunityNickname.toLowerCase().startsWith('user17')) {
                    resolvedName = tr.CreatedBy.CommunityNickname;
                } else if (String.isNotBlank(tr.CreatedBy.FirstName) || String.isNotBlank(tr.CreatedBy.LastName)) {
                    resolvedName = ((tr.CreatedBy.FirstName != null ? tr.CreatedBy.FirstName : '') + ' ' + 
                                   (tr.CreatedBy.LastName != null ? tr.CreatedBy.LastName : '')).trim();
                } else if (String.isNotBlank(tr.CreatedBy.Name) && !tr.CreatedBy.Name.toLowerCase().startsWith('user17')) {
                    resolvedName = tr.CreatedBy.Name;
                }
            }

            wrap.submitterName = String.isNotBlank(resolvedName) ? resolvedName : 'Employee';
            wrappedList.add(wrap);
        }

        return wrappedList;
    }

    @AuraEnabled
    public static Travel_Request__c submitTravelRequest(
        String destination, 
        String purpose, 
        Decimal estimatedCost, 
        Date startDate, 
        Date endDate
    ) {
        try {
            Travel_Request__c req = new Travel_Request__c(
                Destination__c = destination,
                Purpose__c = purpose,
                Estimated_Cost__c = estimatedCost,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = 'Pending Approval'
            );
            insert req;
            return req;
        } catch (Exception ex) {
            throw new AuraHandledException('Error submitting travel request: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void updateRequestStatus(Id requestId, String newStatus) {
        try {
            // 1. Update the parent Travel Request status
            Travel_Request__c req = [
                SELECT Id, Status__c 
                FROM Travel_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            req.Status__c = newStatus;
            update req;

            // 2. Cascade status to all related child Expense__c records
            Map<String, Schema.SObjectField> expenseFields = Schema.SObjectType.Expense__c.fields.getMap();
            String statusFieldName = '';
            if (expenseFields.containsKey('expense_status__c')) {
                statusFieldName = 'Expense_Status__c';
            } else if (expenseFields.containsKey('status__c')) {
                statusFieldName = 'Status__c';
            }

            if (String.isNotBlank(statusFieldName)) {
                String expenseQuery = 'SELECT Id, ' + statusFieldName + ' FROM Expense__c WHERE Travel_Request__c = :requestId';
                List<SObject> relatedExpenses = Database.query(expenseQuery);

                if (!relatedExpenses.isEmpty()) {
                    for (SObject exp : relatedExpenses) {
                        if (newStatus == 'Approved') {
                            exp.put(statusFieldName, 'Approved');
                        } else if (newStatus == 'Rejected') {
                            exp.put(statusFieldName, 'Rejected');
                        } else if (newStatus == 'Pending Approval') {
                            exp.put(statusFieldName, 'Draft');
                        }
                    }
                    update relatedExpenses;
                }
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error updating status: ' + ex.getMessage());
        }
    }
}