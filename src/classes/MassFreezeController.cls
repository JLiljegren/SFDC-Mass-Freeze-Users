public with sharing class MassFreezeController {
    FINAL private String PAGE_ACTION_MELT = 'melt';
    FINAL private String PAGE_ACTION_FREEZE = 'freeze';

    private Set<Id> userIdsToNotFreeze = new Set<Id>();
    private Set<Id> profileIdsToNotFreeze = new Set<Id>();

    private List<Id> activeUserIds;
    private List<Id> inactiveUserIds;
    private List<UserLogin> usersToFreeze;
    private List<UserLogin> usersToMelt;

    private Integer usersToFreezeCount;
    private Integer usersToMeltCount;

    private Integer neverEverFreezeUsersCount;
    private Boolean showNoFreezeUsers;
    private Boolean showFreezePanel = false;
    private Boolean showMeltPanel = false;
    private Boolean showNotAllowedMessage = true;
    private Boolean canFreeze = false;
    private Boolean canMelt = false;

    private String pageAction = PAGE_ACTION_FREEZE;

    private List<User> neverEverFreezeUsers;

    public MassFreezeController () {
        setPageAction(PAGE_ACTION_FREEZE);

        userIdsToNotFreeze.add(UserInfo.getUserId()); // Make sure we never freeze current user
        profileIdsToNotFreeze.add(Constants.PROFILE_SYSADMIN_ID); // Make sure we never freeze users in System Administrator profile

        neverEverFreezeUsers = new List<User>();

        for (MassFreezeSecurity__c setting : [SELECT Id
                                                     ,SetupOwnerId
                                                     ,NeverEverFreeze__c
                                              FROM MassFreezeSecurity__c]) {
            if(((String)setting.SetupOwnerId).left(3) == '005') {
                userIdsToNotFreeze.add(setting.SetupOwnerId);
            }
            if(((String)setting.SetupOwnerId).left(3) == '00e') {
                profileIdsToNotFreeze.add(setting.SetupOwnerId);
            }
        }

        for (User u : [SELECT Id, Name, Profile.Name
                       FROM User
                       WHERE IsActive=True
                             AND (Id in :userIdsToNotFreeze
                                  OR ProfileId in :profileIdsToNotFreeze)
                       ORDER BY Profile.Name]) {
            neverEverFreezeUsers.add(u);
        }

        getCurrentSetup();
    }

    public List<UserLogin> getUsersToFreeze() {
        usersToFreeze = new List<UserLogin>([SELECT Id
                                                   ,UserId
                                                   ,IsFrozen
                                            FROM UserLogin
                                            WHERE IsFrozen=false
                                                  and UserId in :([SELECT Id
                                                                   FROM User
                                                                   WHERE IsActive=True
                                                                         AND Id not in :neverEverFreezeUsers])]);

//        usersToFreezeCount = usersToFreeze.size();

        return usersToFreeze;
    }

    public Integer getUsersToFreezeCount() {
        if(usersToFreeze != null) {
            usersToFreezeCount = usersToFreeze.size();
        }
        else {
            usersToFreezeCount = 0;
        }

        return usersToFreezeCount;
    }

    public List<UserLogin> getUsersToMelt() {
        usersToMelt = new List<UserLogin>([SELECT Id
                                                 ,UserId
                                                 ,IsFrozen
                                           FROM UserLogin
                                           WHERE IsFrozen=True
                                                  and UserId in :([SELECT Id
                                                                   FROM User
                                                                   WHERE IsActive=True])]);

//        usersToMeltCount = usersToMelt.size();

        return usersToMelt;

    }

    public Integer getUsersToMeltCount() {
        if(usersToMelt != null) {
            usersToMeltCount = usersToMelt.size();
        }
        else {
            usersToMeltCount = 0;
        }

        return usersToMeltCount;
    }

    public List<User> getNeverEverFreezeUsers() {
        if(neverEverFreezeUsers != null) {
            return neverEverFreezeUsers;
        }
        //Just return an empty list - to avoid null pointer exceptions...
        return new List<User>();
    }

    public Integer getNeverEverFreezeUsersCount() {
        if(neverEverFreezeUsers != null) {
            neverEverFreezeUsersCount = neverEverFreezeUsers.size();
        }
        else {
            neverEverFreezeUsersCount = 0;
        }
        return neverEverFreezeUsersCount;
    }

    public Boolean getShowFreezePanel() {
        if(pageAction == PAGE_ACTION_FREEZE && getCanFreeze()) {
            showFreezePanel = true;
        }
        else {
            showFreezePanel = false;
        }

        return showFreezePanel;
    }

    public Boolean getShowMeltPanel() {
        if(pageAction == PAGE_ACTION_MELT && getCanMelt()) {
            showMeltPanel = true;
        }
        else {
            showMeltPanel = false;
        }

        return showMeltPanel;
    }

    public Boolean getShowNotAllowedMessage() {
        if(pageAction == PAGE_ACTION_FREEZE && getCanFreeze()) {
            showNotAllowedMessage = false;
        }
        if(pageAction == PAGE_ACTION_MELT && getCanMelt()) {
            showNotAllowedMessage = false;
        }
        return showNotAllowedMessage;
    }

    public Boolean getCanMelt() {
        canMelt = MassFreezeSecurity__c.getInstance().HasPermissionToMeltUsers__c;
        return canMelt;
    }

    public Boolean getCanFreeze() {
        canFreeze = MassFreezeSecurity__c.getInstance().HasPermissionToFreezeUsers__c;
        return canFreeze;
    }

    public Boolean getShowNoFreezeUsers() {
        if(neverEverFreezeUsers != null && neverEverFreezeUsers.size() > 0) {
            showNoFreezeUsers = true;
        }
        else {
            showNoFreezeUsers = false;
        }

        return showNoFreezeUsers;
    }

    public String getPageAction() {
        return pageAction;
    }

    public void setPageAction(String inputAction) {
        system.assert(inputAction == PAGE_ACTION_FREEZE || inputAction == PAGE_ACTION_MELT);

        pageAction = inputAction;
    }

    public PageReference swapAction() {
        if (pageAction == PAGE_ACTION_FREEZE) {
            pageAction = PAGE_ACTION_MELT;
        }
        else if (pageAction == PAGE_ACTION_MELT) {
            pageAction = PAGE_ACTION_FREEZE;
        }

        return null;
    }

    public PageReference freezeAll() {
        for(UserLogin ul : usersToFreeze) {
            ul.IsFrozen = true;
        }
        update usersToFreeze;

        getCurrentSetup();
        pageAction = PAGE_ACTION_MELT;

        return null;
    }

    public PageReference meltAll() {
        for(UserLogin ul : usersToMelt) {
            ul.IsFrozen = false;
        }
        update usersToMelt;

        getCurrentSetup();
        pageAction = PAGE_ACTION_FREEZE;

        return null;
    }

    private void getCurrentSetup() {
        getUsersToFreeze();
        getUsersToMelt();
    }

}