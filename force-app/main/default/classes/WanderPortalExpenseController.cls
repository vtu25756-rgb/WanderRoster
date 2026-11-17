public without sharing class WanderPortalExpenseController {

    public class UserRoleInfo {
        @AuraEnabled public Boolean isManager;
        @AuraEnabled public Boolean isEmployee;
        @AuraEnabled public String userRole;
    }

    public class TravelOption {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public Decimal estimatedCost;
    }

    public class ReimbursementItem {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String travelRequestName;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date expenseDate;
        @AuraEnabled public String status;
        @AuraEnabled public String description;
    }

    // 1. Determine user role (Manager vs Employee)
    @AuraEnabled(cacheable=true)
    public static UserRoleInfo getUserPortalRole() {
        UserRoleInfo info = new UserRoleInfo();
        Id currentUserId = UserInfo.getUserId();

        User u = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :currentUserId LIMIT 1];
        String prof = (u.Profile != null && u.Profile.Name != null) ? u.Profile.Name.toLowerCase() : '';
        
        // Checks profile name or role for manager keywords
        Boolean isMgr = prof.contains('manager') || prof.contains('admin');
        info.isManager = isMgr;
        info.isEmployee = !isMgr;
        info.userRole = isMgr ? 'Manager' : 'Employee';
        return info;
    }

    // 2. Fetch approved travel requests for the submission dropdown
    @AuraEnabled(cacheable=true)
    public static List<TravelOption> getApprovedTravelRequests() {
        Id currentUserId = UserInfo.getUserId();
        List<TravelOption> options = new List<TravelOption>();

        List<Travel_Request__c> requests = [
            SELECT Id, Name, Destination__c, Estimated_Cost__c 
            FROM Travel_Request__c 
            WHERE CreatedById = :currentUserId 
              AND Status__c IN ('Approved', 'Completed')
            ORDER BY CreatedDate DESC 
            LIMIT 50
        ];

        for (Travel_Request__c tr : requests) {
            TravelOption opt = new TravelOption();
            opt.id = tr.Id;
            opt.label = tr.Name + ' - ' + (tr.Destination__c != null ? tr.Destination__c : 'Trip');
            opt.estimatedCost = tr.Estimated_Cost__c != null ? tr.Estimated_Cost__c : 0;
            options.add(opt);
        }
        return options;
    }

    // 3. Fetch expenses filtered strictly by a specific Travel Request ID
    @AuraEnabled(cacheable=true)
    public static List<ReimbursementItem> getExpensesForRequest(Id travelRequestId) {
        List<ReimbursementItem> claims = new List<ReimbursementItem>();
        if (travelRequestId == null) {
            return claims;
        }

        List<Expense__c> records = [
            SELECT Id, Name, Travel_Request__r.Name, Expense_Category__c, Amount__c, Expense_Date__c, Expense_Status__c, Description__c 
            FROM Expense__c 
            WHERE Travel_Request__c = :travelRequestId 
            ORDER BY Expense_Date__c DESC, CreatedDate DESC 
            LIMIT 100
        ];

        for (Expense__c exp : records) {
            ReimbursementItem item = new ReimbursementItem();
            item.id = exp.Id;
            item.name = exp.Name;
            item.travelRequestName = exp.Travel_Request__r != null ? exp.Travel_Request__r.Name : '-';
            item.category = exp.Expense_Category__c;
            item.amount = exp.Amount__c;
            item.expenseDate = exp.Expense_Date__c;
            item.status = exp.Expense_Status__c != null ? exp.Expense_Status__c : 'Pending Approval';
            item.description = exp.Description__c;
            claims.add(item);
        }
        return claims;
    }

    // 4. Create new reimbursement claim
    @AuraEnabled
    public static Expense__c createExpenseClaim(
        Id travelRequestId, 
        String category, 
        Decimal amount, 
        Date expenseDate, 
        String description
    ) {
        if (travelRequestId == null) {
            throw new AuraHandledException('Please select a valid travel request.');
        }
        if (amount == null || amount <= 0) {
            throw new AuraHandledException('Expense amount must be greater than 0.');
        }

        try {
            Expense__c exp = new Expense__c(
                Travel_Request__c = travelRequestId,
                Expense_Category__c = category,
                Amount__c = amount,
                Expense_Date__c = expenseDate,
                Description__c = description,
                Expense_Status__c = 'Pending Approval'
            );
            insert exp;
            return exp;
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to log reimbursement: ' + ex.getMessage());
        }
    }
}