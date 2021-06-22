codeunit 139400 "Permissions Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        PermissionSetBasicTxt: Label 'PermS-Basic-Test';
        PermissionSetFinancialReportsTxt: Label 'PermS-FinRep-Test';
        PermissionSetJournalsEditTxt: Label 'PermS-JournEdit-Test';
        PermissionSetJournalsPostTxt: Label 'PermS-JournPost-Test';
        PlanSmallBusinessTxt: Label 'Plan-SmallB-Test';
        PlanOffice365Txt: Label 'Plan-Office365-Test';
        PlanOffice365ExtraTxt: Label 'Plan-Office365Ext-Test';
        QueryNameTok: Label 'Users In User Group';
        UserCassieTxt: Label 'User-Cassie-Test';
        UserDebraTxt: Label 'User-Debra-Test';
        UserGroupAccountantPostingTxt: Label 'UserGroup-AccP-Test';
        UserGroupAccountantTxt: Label 'UserGroup-Acc-Test';
        UserGroupAuditorTxt: Label 'UserGroup-Aud-Test';
        UserGroupFinanceTxt: Label 'UserGroup-Finance';
        LibraryPermissionsVerify: Codeunit "Library - Permissions Verify";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryPlainTextFile: Codeunit "Library - Plain Text File";
        Assert: Codeunit Assert;
        WrongUserGroupCodeErr: Label 'Wron user group exported.';
        PermissionSetLinePatternTok: Label '"%1","%2"';
        ImportEmptyFileErr: Label 'Cannot import the specified XML document because the file is empty.';

    [Test]
    [Scope('OnPrem')]
    procedure LastPlanRemovedFromUserInSaaS()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PlanID: Guid;
        Cassie: Guid;
    begin
        // [SCENARIO] Last plan removed from user, marks it as "to review" by the security admin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] Plan Office365
        PlanID := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);
        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        // [GIVEN] Cassie is part of Office365
        LibraryPermissions.AddUserToPlan(Cassie, PlanID);
        // [GIVEN] Cassie is not marked for review by the security admin
        UserSecurityStatus.LoadUsers;
        UserSecurityStatus.Get(Cassie);
        UserSecurityStatus.Reviewed := true;
        UserSecurityStatus.Modify(true);

        UserSecurityStatus.LoadUsers;
        UserSecurityStatus.Get(Cassie);
        Assert.IsTrue(UserSecurityStatus.Reviewed, 'User Cassie should have status = reviewed');

        // [WHEN] Cassie is removed from the plan
        AzureADPlanTestLibrary.RemoveUserFromPlan(Cassie, PlanID);
        UserSecurityStatus.LoadUsers;

        // [THEN] Cassie is marked as Reviewed = FALSE
        UserSecurityStatus.Get(Cassie);
        Assert.IsFalse(UserSecurityStatus.Reviewed, 'User Cassie should have status = not reviewed');

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserWithoutPlansKeepReviewedStatusForOnPrem()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Cassie: Guid;
    begin
        // [SCENARIO] When a user has no plans, the reviewed status is not changed for OnPrem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        // [GIVEN] Cassie is not marked for review by the security admin
        UserSecurityStatus.LoadUsers;
        UserSecurityStatus.Get(Cassie);
        UserSecurityStatus.Reviewed := true;
        UserSecurityStatus.Modify(true);

        // [WHEN] User Security Status is reloaded
        UserSecurityStatus.LoadUsers;

        // [THEN] Cassie is still marked as Reviewed = TRUE
        UserSecurityStatus.Get(Cassie);
        Assert.IsTrue(UserSecurityStatus.Reviewed, 'User Cassie should have status = reviewed');

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadUsersInTableUserSecurityStatus()
    var
        UserSecurityStatus: Record "User Security Status";
        PlanID: Guid;
        Cassie: Guid;
        Debra: Guid;
    begin
        // [SCENARIO] Last plan removed from user, tags it as "to review" by the security admin

        // [GIVEN] Plan Office365
        PlanID := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);
        // [GIVEN] User Cassie, user Debra
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        Debra := LibraryPermissions.CreateUserWithName(UserDebraTxt);

        // [GIVEN] Cassie and Debra are part of Office365
        LibraryPermissions.AddUserToPlan(Cassie, PlanID);
        LibraryPermissions.AddUserToPlan(Debra, PlanID);

        // [WHEN] Loading users into UserSecurityStatus
        UserSecurityStatus.LoadUsers;

        // [THEN] Users are Cassie and Debra have been added to UserSecurityStatus
        Assert.IsTrue(UserSecurityStatus.Get(Cassie), 'Cassie doesn''t exist in table UserSecurityStatus');
        Assert.IsFalse(UserSecurityStatus.Reviewed, 'Cassie should be tagged as Not Reviewed');
        Assert.IsTrue(UserSecurityStatus.Get(Debra), 'Debra doesn''t exist in table UserSecurityStatus');
        Assert.IsFalse(UserSecurityStatus.Reviewed, 'Debra should be tagged as Not Reviewed');
        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserGroupAddedToPlan()
    var
        AzureADPlanTestLibraries: Codeunit "Azure AD Plan Test Library";
        PlanID: Guid;
    begin
        // [SCENARIO] User Group added to Plan, sunshine

        // [GIVEN] Plan Office365
        PlanID := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);

        // [GIVEN] Permission sets: Journals-Edit, Journals-Post, Financial Reports. All included in Plan Office365
        LibraryPermissions.CreatePermissionSetInPlan(PermissionSetJournalsEditTxt, PlanID);
        LibraryPermissions.CreatePermissionSetInPlan(PermissionSetJournalsPostTxt, PlanID);
        LibraryPermissions.CreatePermissionSetInPlan(PermissionSetFinancialReportsTxt, PlanID);

        // [GIVEN] User Group Finance, containing permission sets Journals-Edit, Journals-Post
        LibraryPermissions.CreateUserGroupWithCode(UserGroupFinanceTxt);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSetJournalsEditTxt, UserGroupFinanceTxt);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSetJournalsPostTxt, UserGroupFinanceTxt);

        // [WHEN] Accountant is added to Office365
        LibraryPermissions.AddUserGroupToPlan(UserGroupFinanceTxt, PlanID);

        // [THEN] It succeeds (the permission sets are enough)
        LibraryPermissionsVerify.UserGroupIsInPlan(UserGroupFinanceTxt, PlanID);
        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserGroupDeleted()
    var
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanIDDummy: Guid;
        PlanIDOffice365: Guid;
    begin
        // [SCENARIO] When a User Group is deleted, the related data is cleaned-up
        // [GIVEN] Permission sets: Basic, JournalsEdit
        LibraryPermissions.CreatePermissionSetWithCode(PermissionSetBasicTxt);
        LibraryPermissions.CreatePermissionSetWithCode(PermissionSetJournalsEditTxt);
        // [GIVEN] Plans: Dummy, Office365
        PlanIDDummy := AzureADPlanTestLibrary.CreatePlan(PlanSmallBusinessTxt);
        LibraryPermissions.AddPermissionSetToPlan(PermissionSetBasicTxt, PlanIDDummy);
        PlanIDOffice365 := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);
        LibraryPermissions.AddPermissionSetToPlan(PermissionSetBasicTxt, PlanIDOffice365);
        LibraryPermissions.AddPermissionSetToPlan(PermissionSetJournalsEditTxt, PlanIDOffice365);
        // [GIVEN] User groups: Accountant, Finance
        LibraryPermissions.CreateUserGroupWithCode(UserGroupAccountantTxt);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSetBasicTxt, UserGroupAccountantTxt);
        LibraryPermissions.CreateUserGroupWithCode(UserGroupFinanceTxt);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSetBasicTxt, UserGroupFinanceTxt);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSetJournalsEditTxt, UserGroupFinanceTxt);
        // [GIVEN] Accountant in plan Dummy
        LibraryPermissions.AddUserGroupToPlan(UserGroupAccountantTxt, PlanIDDummy);
        // [GIVEN] Finance in Office365
        LibraryPermissions.AddUserGroupToPlan(UserGroupFinanceTxt, PlanIDOffice365);

        // [WHEN] Accountant user group is deleted
        LibraryPermissions.RemoveUserGroup(UserGroupAccountantTxt);

        // [THEN] Related User Group Member records are removed
        LibraryPermissionsVerify.UserGroupMembersDoNotExist(UserGroupAccountantTxt);
        // [THEN] Related User Group Permission Set records are removed
        LibraryPermissionsVerify.UserGroupPermissionSetsDoNotExist(UserGroupAccountantTxt);
        // [THEN] Related User Group Plan records are removed
        LibraryPermissionsVerify.UserGroupPlansDoNotExist(UserGroupAccountantTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsersInUserGroupQuery()
    var
        Cassie: Guid;
        Debra: Guid;
    begin
        // [SCENARIO] Query UserByUserGroup is returning correct values when user groups and users exist
        // [GIVEN] Cassie and Debra, two users
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        Debra := LibraryPermissions.CreateUserWithName(UserDebraTxt);
        // [GIVEN] User Group Accountant, containing both Cassie and Debra
        LibraryPermissions.CreateUserGroupWithCode(UserGroupAccountantTxt);
        LibraryPermissions.AddUserToUserGroupByCode(Cassie, UserGroupAccountantTxt);
        LibraryPermissions.AddUserToUserGroupByCode(Debra, UserGroupAccountantTxt);
        // [GIVEN] User Group Auditor, containing Cassie
        LibraryPermissions.CreateUserGroupWithCode(UserGroupAuditorTxt);
        LibraryPermissions.AddUserToUserGroupByCode(Cassie, UserGroupAuditorTxt);
        // [GIVEN] User Group Finance, containing nobody
        LibraryPermissions.CreateUserGroupWithCode(UserGroupFinanceTxt);

        // [WHEN] The query is run

        // [THEN] User Group Accountant has two users
        RunAndValidateUsersInUserGroupQuery(UserGroupAccountantTxt, 2);
        // [THEN] User Group Auditor has one user
        RunAndValidateUsersInUserGroupQuery(UserGroupAuditorTxt, 1);
        // [THEN] User Group Finance has zero users
        RunAndValidateUsersInUserGroupQuery(UserGroupFinanceTxt, 0);
        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserIsAssignedNewUserGroup()
    var
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        DummyPlanID: Guid;
        PlanID: Guid;
        UserID: Guid;
    begin
        // [SCENARIO] User is assigned a new role (user group), sunshine scenario

        // [GIVEN] Unused plan (to test multiple selection when searching for users in plans)
        DummyPlanID := AzureADPlanTestLibrary.CreatePlan(PlanSmallBusinessTxt);
        // [GIVEN] Plan A
        PlanID := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);
        // [GIVEN] User Groups Accountant, part of both plans
        LibraryPermissions.CreateUserGroupInPlan(UserGroupAccountantTxt, DummyPlanID);
        LibraryPermissions.AddUserGroupToPlan(UserGroupAccountantTxt, PlanID);
        // [GIVEN] User Cassie, which is not assigned any user group
        UserID := LibraryPermissions.CreateUserInPlan(UserCassieTxt, PlanID);
        LibraryPermissions.RemoveUserFromAllUserGroups(UserID);

        // [WHEN] User group Accountant is assigned to Cassie
        LibraryPermissions.AddUserToUserGroupByCode(UserID, UserGroupAccountantTxt);

        // [THEN] No error is thrown. The operation succeeds because the user is in Plan A, and has sufficient permissions
        LibraryPermissionsVerify.UserIsInUserGroup(UserID, UserGroupAccountantTxt);
        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUserCardSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserCard: TestPage "User Card";
    begin
        // [GIVEN] Running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Opening the user card page
        UserCard.OpenView;

        // [THEN] A series of PaaS/onPrem controls are not visible/editable
        Assert.IsFalse(UserCard."License Type".Visible, 'License Type control on the User card should not be visible');
        Assert.IsFalse(UserCard."Expiry Date".Visible, 'Expiry Date control on the User card should not be visible');
        Assert.IsFalse(UserCard.ACSStatus.Visible, 'ACS Access Status control on the User card should not be visible');
        Assert.IsFalse(UserCard.Password.Visible, 'Password control on the User card should not be visible');
        Assert.IsFalse(UserCard."Change Password".Visible, 'Change Password control on the User card should not be visible');
        Assert.IsFalse(UserCard.AcsSetup.Visible, 'ACS Setup action on the User card should not be visible');
        Assert.IsFalse(UserCard.ChangePassword.Visible, 'Change Password action on the User card should not be visible');
        Assert.IsFalse(UserCard."Full Name".Editable, 'Full name control on the User card should not be editable');
        Assert.IsFalse(UserCard."Authentication Email".Editable, 'Authentication email on User Card should not be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUsersListPaaSOnPrem()
    var
        User: Record User;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UsersPage: TestPage Users;
    begin
        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Opening the user list page
        UsersPage.OpenView;

        // [THEN] "Add myself as SUPER" is visible is there are no users already defined
        if User.Count = 0 then
            Assert.IsTrue(UsersPage.AddMeAsSuper.Visible, 'AddMeAsSuper action on Users page should be visible');
        // [THEN] A series of PaaS/onPrem controls are visible/editable
        Assert.IsTrue(UsersPage."Windows User Name".Visible, 'Windows User Name control on Users page should not be visible');
        Assert.IsTrue(UsersPage."License Type".Visible, 'License Type control on Users page should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUsersListSaas()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Users: TestPage Users;
    begin
        // [FEATURE] [UI] [Users]
        // [SCENARIO 283675] Windows User Name field on Users page invisible in SaaS

        // [GIVEN] A system setup as SaaS solution
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Users page is being opened
        Users.OpenView;

        // [THEN] Field Windows User Name is invisible
        Assert.IsFalse(Users."Windows User Name".Visible, 'Windows User Name should be invisible');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUserSecurityActivitiesPage()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserSecurityActivities: TestPage "User Security Activities";
    begin
        // [SCENARIO] Visibility of controls on the User Security Activities page when running PaaS or on-prem

        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Users security activities page is opened
        UserSecurityActivities.OpenView;

        // [THEN] SaaS-related cues are not visible
        Assert.IsFalse(UserSecurityActivities."Users - Without Subscriptions".Visible,
          'Users without subscription plans on User Security Acticities page should not be visible');
        Assert.IsFalse(UserSecurityActivities."Users - Not Group Members".Visible,
          'Users without group memberships on User Security Acticities page should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfNavigationToOfficePortalOnUserSecurityStatusPage()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserSecurityStatusList: TestPage "User Security Status List";
    begin
        // [SCENARIO] Navigation to Azure AD plan assignment to users should only be visible in SaaS. Idem for plans.

        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Users security status list page is opened
        UserSecurityStatusList.OpenView;

        // [THEN] SaaS navigation controls are not visible
        Assert.IsFalse(UserSecurityStatusList."Manage plan assignments".Visible,
          'Navigation to azure plan assignment should not be visible');
        Assert.IsFalse(UserSecurityStatusList."Belongs To Subscription Plan".Visible, 'Plan related information should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure D365BusFullAccessShouldHaveRIMDPermissionsOnUserGroupMember()
    var
        UserGroupMember: Record "User Group Member";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Cassie: Guid;
    begin
        // [SCENARIO] D365 Bus Full Access should have RIMD on User Group Member
        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] D365 Full Bus Permission Set
        // [GIVEN] Some permission sets, some users
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        LibraryPermissions.CreateUserGroupWithCode(UserGroupFinanceTxt);
        // [WHEN] Attempting insert/delete on User Group Member
        LibraryLowerPermissions.SetO365BusFull;
        UserGroupMember.Init;
        UserGroupMember."User Security ID" := Cassie;
        UserGroupMember."User Group Code" := UserGroupFinanceTxt;
        UserGroupMember.Insert;
        UserGroupMember.Delete;
        // [THEN] No error is thrown

        LibraryLowerPermissions.SetOutsideO365Scope;
        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure D365BusFullAccessShouldHaveAdvancedPermissions()
    var
        HRConfidentialCommentLine: Record "HR Confidential Comment Line";
        PlanningErrorLog: Record "Planning Error Log";
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        ServiceCue: Record "Service Cue";
        OutlookSynchEntity: Record "Outlook Synch. Entity";
        ReturnsRelatedDocument: Record "Returns-Related Document";
        OutlookSynchSetupDetail: Record "Outlook Synch. Setup Detail";
        ServiceShipmentBuffer: Record "Service Shipment Buffer";
        CauseOfInactivity: Record "Cause of Inactivity";
        MiniformHeader: Record "Miniform Header";
        CurrentSalesperson: Record "Current Salesperson";
        WarehouseWorkerWMSCue: Record "Warehouse Worker WMS Cue";
        OutlookSynchField: Record "Outlook Synch. Field";
        GroundsForTermination: Record "Grounds for Termination";
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
        InternalMovementHeader: Record "Internal Movement Header";
        UserDefaultStyleSheet: Record "User Default Style Sheet";
        OutlookSynchLookupName: Record "Outlook Synch. Lookup Name";
        OutlookSynchDependency: Record "Outlook Synch. Dependency";
        MiscArticle: Record "Misc. Article";
        WarehouseWMSCue: Record "Warehouse WMS Cue";
        ATOSalesBuffer: Record "ATO Sales Buffer";
        OutlookSynchLink: Record "Outlook Synch. Link";
        JobWIPBuffer: Record "Job WIP Buffer";
        Relative: Record Relative;
        FaultAreaSymptomCode: Record "Fault Area/Symptom Code";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        CertificateOfSupply: Record "Certificate of Supply";
        ContactDuplDetailsBuffer: Record "Contact Dupl. Details Buffer";
        PlanningBuffer: Record "Planning Buffer";
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
        ResourcePriceChange: Record "Resource Price Change";
        StandardServiceCode: Record "Standard Service Code";
        MiniformFunction: Record "Miniform Function";
        OutstandingBankTransaction: Record "Outstanding Bank Transaction";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseBasicCue: Record "Warehouse Basic Cue";
        ManufacturingCue: Record "Manufacturing Cue";
        LotBinBuffer: Record "Lot Bin Buffer";
        Confidential: Record Confidential;
        StandardServiceLine: Record "Standard Service Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        Union: Record Union;
        MiniformLine: Record "Miniform Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
        OutlookSynchEntityElement: Record "Outlook Synch. Entity Element";
        JobDifferenceBuffer: Record "Job Difference Buffer";
        JobBuffer: Record "Job Buffer";
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        EmploymentContract: Record "Employment Contract";
        Qualification: Record Qualification;
        InternalMovementLine: Record "Internal Movement Line";
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
        MiniformFunctionGroup: Record "Miniform Function Group";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
        AssemblyCommentLine: Record "Assembly Comment Line";
        OutlookSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
    begin
        // [SCENARIO] D365 Bus Full Access should have Advanced Permissions
        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan;

        // Verify
        Assert.IsTrue(HRConfidentialCommentLine.ReadPermission, 'HRConfidentialCommentLine does not have read permission');
        Assert.IsTrue(PlanningErrorLog.ReadPermission, 'PlanningErrorLog does not have read permission');
        Assert.IsTrue(TimeSheetCommentLine.ReadPermission, 'TimeSheetCommentLine does not have read permission');
        Assert.IsTrue(ServiceCue.ReadPermission, 'ServiceCue does not have read permission');
        Assert.IsTrue(OutlookSynchEntity.ReadPermission, 'OutlookSynchEntity does not have read permission');
        Assert.IsTrue(ReturnsRelatedDocument.ReadPermission, 'ReturnsRelatedDocument does not have read permission');
        Assert.IsTrue(OutlookSynchSetupDetail.ReadPermission, 'OutlookSynchSetupDetail does not have read permission');
        Assert.IsTrue(ServiceShipmentBuffer.ReadPermission, 'ServiceShipmentBuffer does not have read permission');
        Assert.IsTrue(CauseOfInactivity.ReadPermission, 'CauseofInactivity does not have read permission');
        Assert.IsTrue(MiniformHeader.ReadPermission, 'MiniformHeader does not have read permission');
        Assert.IsTrue(CurrentSalesperson.ReadPermission, 'CurrentSalesperson does not have read permission');
        Assert.IsTrue(WarehouseWorkerWMSCue.ReadPermission, 'WarehouseWorkerWMSCue does not have read permission');
        Assert.IsTrue(OutlookSynchField.ReadPermission, 'OutlookSynchField does not have read permission');
        Assert.IsTrue(GroundsForTermination.ReadPermission, 'GroundsforTermination does not have read permission');
        Assert.IsTrue(OutlookSynchUserSetup.ReadPermission, 'OutlookSynchUserSetup does not have read permission');
        Assert.IsTrue(InternalMovementHeader.ReadPermission, 'InternalMovementHeader does not have read permission');
        Assert.IsTrue(UserDefaultStyleSheet.ReadPermission, 'UserDefaultStyleSheet does not have read permission');
        Assert.IsTrue(OutlookSynchLookupName.ReadPermission, 'OutlookSynchLookupName does not have read permission');
        Assert.IsTrue(OutlookSynchDependency.ReadPermission, 'OutlookSynchDependency does not have read permission');
        Assert.IsTrue(MiscArticle.ReadPermission, 'MiscArticle does not have read permission');
        Assert.IsTrue(WarehouseWMSCue.ReadPermission, 'WarehouseWMSCue does not have read permission');
        Assert.IsTrue(ATOSalesBuffer.ReadPermission, 'ATOSalesBuffer does not have read permission');
        Assert.IsTrue(OutlookSynchLink.ReadPermission, 'OutlookSynchLink does not have read permission');
        Assert.IsTrue(JobWIPBuffer.ReadPermission, 'JobWIPBuffer does not have read permission');
        Assert.IsTrue(Relative.ReadPermission, 'Relative does not have read permission');
        Assert.IsTrue(FaultAreaSymptomCode.ReadPermission, 'FaultAreaSymptomCode does not have read permission');
        Assert.IsTrue(StandardCostWorksheetName.ReadPermission, 'StandardCostWorksheetName does not have read permission');
        Assert.IsTrue(CertificateOfSupply.ReadPermission, 'CertificateofSupply does not have read permission');
        Assert.IsTrue(ContactDuplDetailsBuffer.ReadPermission, 'ContactDuplDetailsBuffer does not have read permission');
        Assert.IsTrue(PlanningBuffer.ReadPermission, 'PlanningBuffer does not have read permission');
        Assert.IsTrue(StandardCostWorksheet.ReadPermission, 'StandardCostWorksheet does not have read permission');
        Assert.IsTrue(ResourcePriceChange.ReadPermission, 'ResourcePriceChange does not have read permission');
        Assert.IsTrue(StandardServiceCode.ReadPermission, 'StandardServiceCode does not have read permission');
        Assert.IsTrue(MiniformFunction.ReadPermission, 'MiniformFunction does not have read permission');
        Assert.IsTrue(OutstandingBankTransaction.ReadPermission, 'OutstandingBankTransaction does not have read permission');
        Assert.IsTrue(WhseItemTrackingLine.ReadPermission, 'WhseItemTrackingLine does not have read permission');
        Assert.IsTrue(WarehouseBasicCue.ReadPermission, 'WarehouseBasicCue does not have read permission');
        Assert.IsTrue(ManufacturingCue.ReadPermission, 'ManufacturingCue does not have read permission');
        Assert.IsTrue(LotBinBuffer.ReadPermission, 'LotBinBuffer does not have read permission');
        Assert.IsTrue(Confidential.ReadPermission, 'Confidential does not have read permission');
        Assert.IsTrue(StandardServiceLine.ReadPermission, 'StandardServiceLine does not have read permission');
        Assert.IsTrue(RegisteredInvtMovementLine.ReadPermission, 'RegisteredInvtMovementLine does not have read permission');
        Assert.IsTrue(Union.ReadPermission, 'Union does not have read permission');
        Assert.IsTrue(MiniformLine.ReadPermission, 'MiniformLine does not have read permission');
        Assert.IsTrue(StandardServiceItemGrCode.ReadPermission, 'StandardServiceItemGrCode does not have read permission');
        Assert.IsTrue(RegisteredInvtMovementHdr.ReadPermission, 'RegisteredInvtMovementHdr does not have read permission');
        Assert.IsTrue(TimeSheetCmtLineArchive.ReadPermission, 'TimeSheetCmtLineArchive does not have read permission');
        Assert.IsTrue(OutlookSynchEntityElement.ReadPermission, 'OutlookSynchEntityElement does not have read permission');
        Assert.IsTrue(JobDifferenceBuffer.ReadPermission, 'JobDifferenceBuffer does not have read permission');
        Assert.IsTrue(JobBuffer.ReadPermission, 'JobBuffer does not have read permission');
        Assert.IsTrue(OutlookSynchFilter.ReadPermission, 'OutlookSynchFilter does not have read permission');
        Assert.IsTrue(EmploymentContract.ReadPermission, 'EmploymentContract does not have read permission');
        Assert.IsTrue(Qualification.ReadPermission, 'Qualification does not have read permission');
        Assert.IsTrue(InternalMovementLine.ReadPermission, 'InternalMovementLine does not have read permission');
        Assert.IsTrue(EmployeeStatisticsGroup.ReadPermission, 'EmployeeStatisticsGroup does not have read permission');
        Assert.IsTrue(MiniformFunctionGroup.ReadPermission, 'MiniformFunctionGroup does not have read permission');
        Assert.IsTrue(WhereUsedBaseCalendar.ReadPermission, 'WhereUsedBaseCalendar does not have read permission');
        Assert.IsTrue(AssemblyCommentLine.ReadPermission, 'AssemblyCommentLine does not have read permission');
        Assert.IsTrue(OutlookSynchOptionCorrel.ReadPermission, 'OutlookSynchOptionCorrel does not have read permission');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportUserGroupsWithFilters()
    var
        UserGroupSet: array[3] of Record "User Group";
        UserGroup: Record "User Group";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ServerFileName: Text;
    begin
        // [SCENARIO 229591] User Groups Export now takes into account the Filters set for User Groups.
        // [GIVEN] 3 User Groups "UG1", "UG2" and "UG3".
        LibraryPermissions.CreateUserGroup(UserGroupSet[1], LibraryUtility.GenerateGUID);
        LibraryPermissions.CreateUserGroup(UserGroupSet[2], LibraryUtility.GenerateGUID);
        LibraryPermissions.CreateUserGroup(UserGroupSet[3], LibraryUtility.GenerateGUID);

        // [GIVEN] A filter applied for UserGroup table to show "UG1" and "UG2" only.
        UserGroup.SetFilter(Code, '%1|%2', UserGroupSet[1].Code, UserGroupSet[2].Code);

        // [WHEN] Export of the User Group is invoked for UserGroup record.
        FileName := UserGroup.ExportUserGroups(FileManagement.ClientTempFileName('xml'));
        ServerFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.CopyClientFile(FileName, ServerFileName, true);

        // [THEN] Exported file contains only "UG1" and "UG2" User Groups.
        VerifyExportedUserGroupsWithFilters(UserGroupSet, ServerFileName);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportImportUserGroups()
    var
        UserGroup: Record "User Group";
        UserGroupImport: Record "User Group";
        AllProfile: Record "All Profile";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ServerFileName: Text;
    begin
        // [SCENARIO 263678] User Groups export / import takes into account field "Default Profile ID"
        // [GIVEN] User Group "G" with "Default Profile ID" = "Profile A"
        LibraryPermissions.CreateUserGroup(UserGroup, LibraryUtility.GenerateGUID);
        AllProfile.FindFirst;
        UserGroup."Default Profile ID" := AllProfile."Profile ID";
        UserGroup.Modify;

        // [GIVEN] "G" exported to file "F"
        // [GIVEN] "G" deleted
        UserGroup.SetRecFilter;

        FileName := UserGroup.ExportUserGroups(FileManagement.ClientTempFileName('xml'));
        ServerFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.CopyClientFile(FileName, ServerFileName, true);

        UserGroup.Delete;

        // [WHEN] Import user groups from file "F"
        UserGroupImport.ImportUserGroups(ServerFileName);

        // [THEN] "G" restored with "Default Profile ID" = "Profile A"
        UserGroupImport.Get(UserGroup.Code);
        UserGroupImport.TestField("Default Profile ID", UserGroup."Default Profile ID");

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillPermissionSetBufferWhenFiltered()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
        NullGUID: Guid;
        RecordCountBeforeFiltered: Integer;
    begin
        // [SCENARIO 291532] Refilling Permission Set Buffer doesn't invoke an error when filtered

        // [GIVEN] Created Permission Set
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID, NullGUID);

        // [GIVEN] Filled Permission Set Buffer
        TempPermissionSetBuffer.FillRecordBuffer;
        RecordCountBeforeFiltered := TempPermissionSetBuffer.Count;

        // [GIVEN] Filtered Permission Set Buffer by "Role ID"
        TempPermissionSetBuffer.SetFilter("Role ID", TenantPermissionSet."Role ID");

        // [WHEN] Refilled Permission Set Buffer with the the filter
        TempPermissionSetBuffer.FillRecordBuffer;
        TempPermissionSetBuffer.SetRange("Role ID");

        // [THEN] The number of entries in unfiltered Permission Set Buffer remains unchanged
        Assert.RecordCount(TempPermissionSetBuffer, RecordCountBeforeFiltered);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportImportUserGroupsWithTennantPermission()
    var
        UserGroup: Record "User Group";
        UserGroupImport: Record "User Group";
        TenantPermissionSet: Record "Tenant Permission Set";
        UserGroupPermissionSet: Record "User Group Permission Set";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ServerFileName: Text;
        NullGUID: Guid;
    begin
        // [SCENARIO 294966] User Groups import restores 'User-defined' Permission Sets
        // [GIVEN] User Group "G" and one Permission Set with Scope = Tenant
        LibraryPermissions.CreateUserGroup(UserGroup, LibraryUtility.GenerateGUID);
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID, NullGUID);
        AddTenantPermissionSetToUserGroup(TenantPermissionSet, UserGroup.Code);

        // [GIVEN] "G" exported to file "F"
        // [GIVEN] "G" deleted
        UserGroup.SetRecFilter;

        FileName := UserGroup.ExportUserGroups(FileManagement.ClientTempFileName('xml'));
        ServerFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.CopyClientFile(FileName, ServerFileName, true);

        UserGroup.Delete;

        // [WHEN] Import user groups from file "F"
        UserGroupImport.ImportUserGroups(ServerFileName);

        // [THEN] Permission Set is restored
        UserGroupPermissionSet.SetRange("Role ID", TenantPermissionSet."Role ID");
        UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
        Assert.RecordIsNotEmpty(UserGroupPermissionSet);

        TearDown;
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportImportUserGroupsWithSystemPermission()
    var
        UserGroup: Record "User Group";
        UserGroupImport: Record "User Group";
        PermissionSet: Record "Permission Set";
        UserGroupPermissionSet: Record "User Group Permission Set";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ServerFileName: Text;
    begin
        // [SCENARIO 294966] User Groups import restores 'System' Permission Sets
        // [GIVEN] User Group "G"and one Permission Set with Scope = System
        LibraryPermissions.CreateUserGroup(UserGroup, LibraryUtility.GenerateGUID);
        LibraryPermissions.CreatePermissionSet(PermissionSet, LibraryUtility.GenerateGUID);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet."Role ID", UserGroup.Code);

        // [GIVEN] "G" exported to file "F"
        // [GIVEN] "G" deleted
        UserGroup.SetRecFilter;

        FileName := UserGroup.ExportUserGroups(FileManagement.ClientTempFileName('xml'));
        ServerFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.CopyClientFile(FileName, ServerFileName, true);

        UserGroup.Delete;

        // [WHEN] Import user groups from file "F"
        UserGroupImport.ImportUserGroups(ServerFileName);

        // [THEN] Permission Set is restored
        UserGroupPermissionSet.SetRange("Role ID", PermissionSet."Role ID");
        UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
        Assert.RecordIsNotEmpty(UserGroupPermissionSet);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicPermissionSetHasReadOnlyPermissionForProfiles()
    var
        Permission: Record Permission;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 305828] User with BASIC permission set must have Read permissions to "Tenant Profile" and "All Profile"
        Assert.IsTrue(Permission.GET('BASIC', Permission."Object Type"::"Table Data", DATABASE::"Tenant Profile"),
          'The BASIC permission set has to have the read permissions for table Tenant Profile');
        Assert.IsTrue(Permission."Read Permission" = Permission."Read Permission"::Yes,
          'The BASIC permission set has to have the read permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Insert Permission" = Permission."Insert Permission"::Yes,
          'The BASIC permission set should not have the insert permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Delete Permission" = Permission."Delete Permission"::Yes,
          'The BASIC permission set should not have the delete permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Modify Permission" = Permission."Modify Permission"::Yes,
          'The BASIC permission set should not have the modify permissions for table Tenant Profile');

        Assert.IsTrue(Permission.GET('BASIC', Permission."Object Type"::"Table Data", DATABASE::"All Profile"),
          'The BASIC permission set has to have the read permissions for table All Profile');
        Assert.IsTrue(Permission."Read Permission" = Permission."Read Permission"::Yes,
          'The BASIC permission set has to have the read permissions for table All Profile');
        Assert.IsFalse(Permission."Insert Permission" = Permission."Insert Permission"::Yes,
          'The BASIC permission set should not have the insert permissions for table All Profile');
        Assert.IsFalse(Permission."Modify Permission" = Permission."Modify Permission"::Yes,
          'The BASIC permission set should not have the modify permissions for table All Profile');
        Assert.IsFalse(Permission."Delete Permission" = Permission."Delete Permission"::Yes,
          'The BASIC permission set should not have the delete permissions for table All Profile');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPermissionSets()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        FileOutStream: OutStream;
        FileContent: BigText;
        TextPosition: Integer;
        FileName: Text;
    begin
        // [FEATURE] [Export] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can export Permission Sets and Tenant Permission Sets via XML PORT 9171 in a single run
        CreatePermissionSet(PermissionSet);
        CreateTenantPermissionSet(TenantPermissionSet);
        FileName := FileManagement.ServerTempFileName('txt');

        ExportFile.Create(FileName);
        ExportFile.CreateOutStream(FileOutStream);

        XMLPORT.Export(XMLPORT::"Import/Export Permission Sets", FileOutStream);

        ExportFile.Close;

        LibraryTextFileValidation.ReadTextFile(FileName, FileContent);

        TextPosition := FileContent.TextPos(PermissionSet."Role ID");
        Assert.IsTrue(TextPosition > 1, 'Permission set is not found in exported file');

        TextPosition := FileContent.TextPos(TenantPermissionSet."Role ID");
        Assert.IsTrue(TextPosition > 1, 'Tenant permission set is not found in exported file');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSystemAndTenantPermissions()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        Permission: Record Permission;
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        XMLBuffer: Record "XML Buffer";
        TempXMLBuffer: Record "XML Buffer" temporary;
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        FileOutStream: OutStream;
        FileName: Text;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Export] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 292106] Stan can export system permisions and tenant permissions via XML PORT 9173 in a single run

        // [GIVEN] System permission set "PS1" with two permissions "PS1_1" and "PS1_2"
        LibraryPermissions.CreatePermissionSet(PermissionSet, 'PS1');
        LibraryPermissions.AddPermission(PermissionSet."Role ID", Permission."Object Type"::"Table Data", Database::"Sales Header");
        LibraryPermissions.AddPermission(PermissionSet."Role ID", Permission."Object Type"::"Table Data", Database::"Purchase Header");
        // [GIVEN] Tenant permission set "PS1" with "PS1_1_1" permissions (tenant "Role Id" = system "Role Id" )
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'PS1', ZeroGuid);
        LibraryPermissions.AddTenantPermission(ZeroGuid, TenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", Database::"Sales Header");
        // [GIVEN] Tenant permission set "PS2" with permission "PS2_1"
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'PS2', ZeroGuid);
        LibraryPermissions.AddTenantPermission(ZeroGuid, TenantPermission."Role ID", TenantPermission."Object Type"::"Table Data", Database::"Service Header");

        // [WHEN] Export system and tenant permission sets "PS1"
        AggregatePermissionSet.SetFilter("Role ID", 'PS1');
        FileName := FileManagement.ServerTempFileName('txt');
        ExportFile.Create(FileName);
        ExportFile.CreateOutStream(FileOutStream);
        Xmlport.Export(Xmlport::"Export Permission Sets", FileOutStream, AggregatePermissionSet);
        ExportFile.Close;
        XMLBuffer.Load(FileName);

        // [THEN] Permission sets "PS1" are exported, both system and tenant. "PS2" is not exported.
        TempXMLBuffer.Reset();
        TempXMLBuffer.DeleteAll();
        XMLBuffer.FindNodesByXPath(TempXMLBuffer, 'PermissionSets/PermissionSet');
        Assert.RecordCount(TempXMLBuffer, 2);
        Assert.AreEqual('System', TempXMLBuffer.GetAttributeValue('Scope'), 'Scope attribute for system permission set was not exported.');
        TempXMLBuffer.Next();
        Assert.AreEqual('Tenant', TempXMLBuffer.GetAttributeValue('Scope'), 'Scope attribute for tenant permission set was not exported.');

        // [THEN] System permissions "PS1_1" and "PS1_2" and tenant "PS1_1_1" are exported
        TempXMLBuffer.Reset();
        TempXMLBuffer.DeleteAll();
        XMLBuffer.FindNodesByXPath(TempXMLBuffer, 'PermissionSets/PermissionSet/Permission');
        Assert.RecordCount(TempXMLBuffer, 2);
        TempXMLBuffer.Reset();
        TempXMLBuffer.DeleteAll();
        XMLBuffer.FindNodesByXPath(TempXMLBuffer, 'PermissionSets/PermissionSet/TenantPermission');
        Assert.RecordCount(TempXMLBuffer, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportSystemAndTenantPermissions()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        Permission: Record Permission;
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        XMLBuffer: Record "XML Buffer";
        TempXMLBuffer: Record "XML Buffer" temporary;
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        ImportFile: File;
        FileOutStream: OutStream;
        FileInStream: InStream;
        FileName: Text;
        ZeroGuid: Guid;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 292106] Stan can import system permisions and tenant permissions via XML PORT 9174 in a single run

        // [GIVEN] System permission set "PS1" with two permissions "PS11_1" and "PS11_2"
        LibraryPermissions.CreatePermissionSet(PermissionSet, 'PS11');
        LibraryPermissions.AddPermission(PermissionSet."Role ID", Permission."Object Type"::"Table Data", Database::"Sales Header");
        LibraryPermissions.AddPermission(PermissionSet."Role ID", Permission."Object Type"::"Table Data", Database::"Purchase Header");
        // [GIVEN] Tenant permission set "PS1" with "PS11_1_1" permissions (tenant "Role Id" = system "Role Id" )
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, 'PS11', ZeroGuid);
        LibraryPermissions.AddTenantPermission(ZeroGuid, TenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", Database::"Sales Header");
        TenantPermission.Get(ZeroGuid, TenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", Database::"Sales Header");
        TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::Yes;
        TenantPermission.Modify();
        // [GIVEN] Permissions are exported and deleted
        AggregatePermissionSet.SetFilter("Role ID", 'PS11');
        FileName := FileManagement.ServerTempFileName('txt');
        ExportFile.Create(FileName);
        ExportFile.CreateOutStream(FileOutStream);
        Xmlport.Export(Xmlport::"Export Permission Sets", FileOutStream, AggregatePermissionSet);
        ExportFile.Close;
        PermissionSet.Get('PS11');
        PermissionSet.Delete(true);
        TenantPermissionSet.Get(ZeroGuid, 'PS11');
        TenantPermissionSet.Delete(true);
        // [WHEN] Import permissions
        ImportFile.Open(FileName);
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPORT::"Import Tenant Permission Sets", FileInStream);
        // [THEN] System "PS1" with "PS11_1" and "PS11_2" are in the "Permission Set" and "Permission"
        PermissionSet.Get('PS11');
        Permission.Get('PS11', Permission."Object Type"::"Table Data", Database::"Sales Header");
        Permission.Get('PS11', Permission."Object Type"::"Table Data", Database::"Purchase Header");
        // [THEN] Tenant "PS11" with "PS11_1_1" is in the "Tenant Permission Set" and "Tenant Permission"
        TenantPermissionSet.Get(ZeroGuid, 'PS11');
        TenantPermission.Get(ZeroGuid, 'PS11', Permission."Object Type"::"Table Data", Database::"Sales Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_01()
    var
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan cannot import empty file as permission sets
        FileFullPath := LibraryPlainTextFile.Create('txt');
        LibraryPlainTextFile.Close;

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        asserterror XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);
        Assert.ExpectedError(ImportEmptyFileErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_02()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
        Guids: array[2] of Text;
        RecordCount: array[2] of Integer;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can import permission sets only via XMLPORT 9171
        FileFullPath := LibraryPlainTextFile.Create('txt');
        RecordCount[1] := PermissionSet.Count;
        RecordCount[2] := TenantPermissionSet.Count;

        Guids[1] := LibraryUtility.GenerateGUID;
        Guids[2] := LibraryUtility.GenerateGUID;

        LibraryPlainTextFile.AddLine(StrSubstNo(PermissionSetLinePatternTok, Guids[1], Guids[2]));

        LibraryPlainTextFile.Close;

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);

        PermissionSet.Get(Guids[1]);
        PermissionSet.TestField(Name, Guids[2]);

        Assert.RecordCount(PermissionSet, RecordCount[1] + 1);
        Assert.RecordCount(TenantPermissionSet, RecordCount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_03()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
        Guids: array[2] of Text;
        RecordCount: array[2] of Integer;
        NullGuid: Guid;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can import tenant permission sets only via XMLPORT 9171
        FileFullPath := LibraryPlainTextFile.Create('txt');
        RecordCount[1] := PermissionSet.Count;
        RecordCount[2] := TenantPermissionSet.Count;
        Clear(NullGuid);

        Guids[1] := LibraryUtility.GenerateGUID;
        Guids[2] := LibraryUtility.GenerateGUID;

        LibraryPlainTextFile.AddLine('');
        LibraryPlainTextFile.AddLine('');
        LibraryPlainTextFile.AddLine(StrSubstNo(PermissionSetLinePatternTok, Guids[1], Guids[2]));

        LibraryPlainTextFile.Close;

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);

        TenantPermissionSet.Get(NullGuid, Guids[1]);
        TenantPermissionSet.TestField(Name, Guids[2]);

        Assert.RecordCount(PermissionSet, RecordCount[1]);
        Assert.RecordCount(TenantPermissionSet, RecordCount[2] + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_04()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
        Guids: array[4] of Text;
        RecordCount: array[2] of Integer;
        NullGuid: Guid;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can import permission sets and tenant permission sets via XMLPORT 9171 in a single run
        FileFullPath := LibraryPlainTextFile.Create('txt');
        RecordCount[1] := PermissionSet.Count;
        RecordCount[2] := TenantPermissionSet.Count;
        Clear(NullGuid);

        Guids[1] := LibraryUtility.GenerateGUID;
        Guids[2] := LibraryUtility.GenerateGUID;
        Guids[3] := LibraryUtility.GenerateGUID;
        Guids[4] := LibraryUtility.GenerateGUID;

        LibraryPlainTextFile.AddLine(StrSubstNo(PermissionSetLinePatternTok, Guids[1], Guids[2]));
        LibraryPlainTextFile.AddLine('');
        LibraryPlainTextFile.AddLine(StrSubstNo(PermissionSetLinePatternTok, Guids[3], Guids[4]));

        LibraryPlainTextFile.Close;

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);

        PermissionSet.Get(Guids[1]);
        PermissionSet.TestField(Name, Guids[2]);

        TenantPermissionSet.Get(NullGuid, Guids[3]);
        TenantPermissionSet.TestField(Name, Guids[4]);

        Assert.RecordCount(PermissionSet, RecordCount[1] + 1);
        Assert.RecordCount(TenantPermissionSet, RecordCount[2] + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AggregatePermissionSetRoleIdSelectionFilterUT()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSet: Record "Permission Set";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RoleId: array[5] of Code[10];
        RoleIdFilter: Text;
        SelectedRoleIdFilter: Text;
        i: Integer;
        NullGuid: Guid;
    begin
        // [SCENARIO 292106] Return selection filter from the Aggregate Permission Set, used for multiple permission set filtering
        // [GIVEN] 5 "Permission Set"
        for i := 1 to 5 do begin
            RoleId[i] := LibraryUtility.GenerateGUID();
            LibraryPermissions.CreatePermissionSet(PermissionSet, RoleId[i]);
        end;
        // [GIVEN] Filter for "Permisson Set"
        RoleIdFilter := RoleId[1] + '..' + RoleId[3] + '|' + RoleId[5];
        PermissionSet.SetFilter("Role ID", RoleIdFilter);
        // [GIVEN] "Aggregate Permission Set" marked according to "Permission Set"
        PermissionSet.FindSet();
        repeat
            if AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, NullGuid, PermissionSet."Role ID") then
                AggregatePermissionSet.Mark(true);
        until PermissionSet.Next() = 0;
        AggregatePermissionSet.MarkedOnly(true);
        // [WHEN] Get "Role Id" selection filter for "Aggregate Permission Set"
        SelectedRoleIdFilter := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(AggregatePermissionSet);
        // [THEN] Function returns the same filter as was originally applied
        Assert.AreEqual(RoleIdFilter, SelectedRoleIdFilter, 'Role Id selection filter is wrong.');
    end;


    local procedure AddTenantPermissionSetToUserGroup(TenantPermissionSet: Record "Tenant Permission Set"; UserGroupCode: Code[20])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.Init;
        UserGroupPermissionSet."User Group Code" := UserGroupCode;
        UserGroupPermissionSet."User Group Name" := UserGroupCode;
        UserGroupPermissionSet."Role ID" := TenantPermissionSet."Role ID";
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::Tenant;
        UserGroupPermissionSet."App ID" := TenantPermissionSet."App ID";
        UserGroupPermissionSet.Insert(true);
    end;

    local procedure CreatePermissionSet(var PermissionSet: Record "Permission Set")
    begin
        PermissionSet.Init;
        PermissionSet."Role ID" := LibraryUtility.GenerateGUID;
        PermissionSet.Name := LibraryUtility.GenerateGUID;
        PermissionSet.Insert;
    end;

    local procedure CreateTenantPermissionSet(var TenantPermissionSet: Record "Tenant Permission Set")
    begin
        TenantPermissionSet.Init;
        TenantPermissionSet."Role ID" := LibraryUtility.GenerateGUID;
        TenantPermissionSet.Name := LibraryUtility.GenerateGUID;
        TenantPermissionSet.Insert;
    end;

    local procedure TearDown()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        AzureADPlanTestLibrary.DeletePlan(PlanSmallBusinessTxt);
        AzureADPlanTestLibrary.DeletePlan(PlanOffice365ExtraTxt);
        AzureADPlanTestLibrary.DeletePlan(PlanOffice365Txt);
        DeleteUser(UserCassieTxt);
        DeleteUser(UserDebraTxt);
        DeleteTestUserGroupAndPermissionSet(UserGroupAccountantTxt);
        DeleteTestUserGroupAndPermissionSet(UserGroupAccountantPostingTxt);
        DeleteTestUserGroupAndPermissionSet(UserGroupAuditorTxt);
        DeleteTestUserGroupAndPermissionSet(UserGroupFinanceTxt);
        UserSecurityStatus.LoadUsers;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure DeleteTestUserGroupAndPermissionSet(UserGroupCode: Code[20])
    var
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindFirst then
            UserGroupMember.DeleteAll;

        UserGroupPlan.SetRange("User Group Code", UserGroupCode);
        UserGroupPlan.DeleteAll(true);

        UserGroup.SetRange(Code, UserGroupCode);
        if UserGroup.FindFirst then
            UserGroup.DeleteAll(true); // it will delete the associated UserGroupPermissionSet records too
    end;

    local procedure DeleteUser(UserName: Code[50])
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete;
            User.Delete;
        end;
    end;

    local procedure RunAndValidateUsersInUserGroupQuery(UserGroupCode: Text; ExpectedNumberOfUsers: Integer)
    var
        UsersInUserGroups: Query "Users in User Groups";
    begin
        UsersInUserGroups.SetRange(UserGroupCode, UserGroupCode);
        Assert.IsTrue(UsersInUserGroups.Open, StrSubstNo('Cannot open query %1', QueryNameTok));
        if ExpectedNumberOfUsers = 0 then
            Assert.IsFalse(
              UsersInUserGroups.Read,
              StrSubstNo('The query %1 should return zero users for user group %2', QueryNameTok, UserGroupCode))
        else begin
            Assert.IsTrue(
              UsersInUserGroups.Read, StrSubstNo('The query %1 for user group %2 is empty', QueryNameTok, UserGroupCode));
            Assert.AreEqual(
              ExpectedNumberOfUsers, UsersInUserGroups.NumberOfUsers, StrSubstNo('Unexpected number of users in user group %1', UserGroupCode));
        end;
        UsersInUserGroups.Close;
    end;

    [TestPermissions(TestPermissions::NonRestrictive)]
    local procedure VerifyExportedUserGroupsWithFilters(UserGroupSet: array[3] of Record "User Group"; FileName: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FileName, XmlDocument);
        XMLDOMManagement.FindNodes(XmlDocument.DocumentElement, '/UserGroups/UserGroup', XmlNodeList);
        Assert.AreEqual(UserGroupSet[1].Code, XmlNodeList.ItemOf(0).SelectSingleNode('Code').InnerText, WrongUserGroupCodeErr);
        Assert.AreEqual(UserGroupSet[2].Code, XmlNodeList.ItemOf(1).SelectSingleNode('Code').InnerText, WrongUserGroupCodeErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(MessageText: Text[1024])
    begin
    end;
}

