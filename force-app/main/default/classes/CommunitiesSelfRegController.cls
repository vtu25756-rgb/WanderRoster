public without sharing class CommunitiesSelfRegController {

    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String password { get; set; }
    public String confirmPassword { get; set; }
    public String communityNickname { get; set; }

    public CommunitiesSelfRegController() {}

    public PageReference registerUser() {
        if (!isValidPassword()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Passwords do not match.'));
            return null;
        }

        // 1. Locate the container Account for portal employees
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'WanderRoster Employees' LIMIT 1];
        if (accounts.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Default registration account not found.'));
            return null;
        }
        Id accountId = accounts[0].Id;

        // 2. Construct the User sObject (Without setting u.ProfileId directly)
        User u = new User();
        u.Username = email;
        u.Email = email;
        u.FirstName = firstName;
        u.LastName = lastName;
        u.CommunityNickname = String.isNotBlank(communityNickname) ? communityNickname : (firstName + '.' + lastName);

        // 3. Delegate external user and contact creation to Salesforce Site engine
        try {
            String userId = Site.createExternalUser(u, accountId, password);
            if (userId != null) {
                ApexPages.PageReference lgn = Site.login(email, password, '/s/');
                return lgn != null ? lgn : ApexPages.currentPage();
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }

        return null;
    }

    private Boolean isValidPassword() {
        return password == confirmPassword;
    }
}