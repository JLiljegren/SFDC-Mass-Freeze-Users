@isTest
private class MassFreezeController_Test {
    private static MassFreezeController ctrl;

    private static User testUserRegularProfile;
    private static User testUserSysAdmin;

    static testMethod void test_SettingUpTestData() {
        setupTestData();
    }

    static testMethod void test_SettingUpController() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();

            system.assertNotEquals(null, ctrl);
        }
    }

    static testMethod void test_UsersToFreezeCount() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(ctrl.getUsersToFreeze().size(), ctrl.getUsersToFreezeCount());
        }
    }

    static testMethod void test_UsersToMeltCount() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(ctrl.getUsersToMelt().size(), ctrl.getUsersToMeltCount());
        }
    }

    static testMethod void test_UsersToNeverEverFreezeCount() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(ctrl.getNeverEverFreezeUsers().size(), ctrl.getNeverEverFreezeUsersCount());
        }
    }

    static testMethod void test_ShowNoFreezeUsers() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();

            if(ctrl.getNeverEverFreezeUsersCount() > 0) {
                system.assertEquals(true, ctrl.getShowNoFreezeUsers());
            }
            else {
                system.assertEquals(false, ctrl.getShowNoFreezeUsers());
            }
        }
    }

    static testMethod void test_ShowFreezePanel() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            ctrl.setPageAction('freeze');
            system.assertEquals(true, ctrl.getShowFreezePanel());
            ctrl.swapAction();
            system.assertEquals(false, ctrl.getShowFreezePanel());
        }
    }

    static testMethod void test_ShowMeltPanel() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            ctrl.setPageAction('melt');
            system.assertEquals(true, ctrl.getShowMeltPanel());
            ctrl.swapAction();
            system.assertEquals(false, ctrl.getShowMeltPanel());
        }
    }

    static testMethod void test_ShowNotAllowedMessage() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(false, ctrl.getShowNotAllowedMessage());
        }

        system.runAs(testUserRegularProfile) {
            setupController();
            system.assertEquals(true, ctrl.getShowNotAllowedMessage());
        }

    }

    static testMethod void test_CanMelt() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(true, ctrl.getCanMelt());
        }

        system.runAs(testUserRegularProfile) {
            setupController();
            system.assertEquals(false, ctrl.getCanMelt());
        }
    }

    static testMethod void test_CanFreeze() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals(true, ctrl.getCanFreeze());
        }

        system.runAs(testUserRegularProfile) {
            setupController();
            system.assertEquals(false, ctrl.getCanFreeze());
        }
    }

    static testMethod void test_SwapAction() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            system.assertEquals('freeze', ctrl.getPageAction()); //Default value
            ctrl.swapAction();
            system.assertEquals('melt', ctrl.getPageAction());
            ctrl.swapAction();
            system.assertEquals('freeze', ctrl.getPageAction());
        }
    }

    static testMethod void test_FreezeAll() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            Integer preUsersToMeltCount = ctrl.getUsersToMeltCount();
            Integer preUsersToFreezeCount = ctrl.getUsersToFreezeCount();

            system.assertNotEquals(0, ctrl.getUsersToFreezeCount()); // Make sure we have users to freeze

            ctrl.freezeAll();

            system.assertEquals(0, ctrl.getUsersToFreezeCount()); // Make sure there are no users still to freeze

            system.assert(ctrl.getUsersToMeltCount() == preUsersToMeltCount + preUsersToFreezeCount); // Make sure there are more users to melt after freezing than before

            system.assertEquals('melt', ctrl.getPageAction()); // Should have changed to melt
        }
    }

    static testMethod void test_MeltAll() {
        setupTestData();

        system.runAs(testUserSysAdmin) {
            setupController();
            ctrl.freezeAll(); // First freeze some users to make sure we have users to melt

            Integer preUsersToMeltCount = ctrl.getUsersToMeltCount();
            Integer preUsersToFreezeCount = ctrl.getUsersToFreezeCount();

            system.assertNotEquals(0, preUsersToMeltCount);

            ctrl.meltAll();

            system.assertEquals(0, ctrl.getUsersToMeltCount()); // Make sure there are no users still to melt

            system.assert(ctrl.getUsersToFreezeCount() == preUsersToFreezeCount + preUsersToMeltCount);

            system.assertEquals('freeze', ctrl.getPageAction()); // Should have changed to freeze
        }
    }



    static void setupTestData() {
        Profile sysAdmProfile = TestUtils.usrProfile('System Administrator');
        testUserRegularProfile = TestUtils.createRandomUser();
        insert testUserRegularProfile;

        testUserSysAdmin =  TestUtils.createAdminUserOnce();

        system.runAs(testUserSysAdmin) {
            List<MassFreezeSecurity__c> mfsList = new List<MassFreezeSecurity__c>();

            mfsList.add(new MassFreezeSecurity__c(SetupOwnerId = sysAdmProfile.Id,
                                                NeverEverFreeze__c=true,
                                                HasPermissionToFreezeUsers__c=false,
                                                HasPermissionToMeltUsers__c=false));

            mfsList.add(new MassFreezeSecurity__c(SetupOwnerId = testUserSysAdmin.Id,
                                                NeverEverFreeze__c=true,
                                                HasPermissionToFreezeUsers__c=true,
                                                HasPermissionToMeltUsers__c=true));

            insert mfsList;
        }
    }

    static void setupController() {
        Test.setCurrentPageReference(Page.MassFreeze);

        ctrl = new MassFreezeController();
    }
}