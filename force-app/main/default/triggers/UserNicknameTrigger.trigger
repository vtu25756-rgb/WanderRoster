trigger UserNicknameTrigger on User (before insert) {
    for (User u : Trigger.new) {
        // If the user registered without a nickname or Salesforce gave a generated User17... alias
        if (String.isBlank(u.CommunityNickname) || u.CommunityNickname.startsWith('User17')) {
            String fullName = ((u.FirstName != null ? u.FirstName : '') + ' ' + (u.LastName != null ? u.LastName : '')).trim();
            if (String.isNotBlank(fullName)) {
                // Keep within 40 characters limit of CommunityNickname
                u.CommunityNickname = fullName.left(40);
            }
        }
    }
}