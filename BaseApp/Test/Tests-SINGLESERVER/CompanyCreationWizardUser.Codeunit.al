codeunit 139318 "Company Creation Wizard - User"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company Creation Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure CreateCompanyWithoutUsersTest()
    var
#if not CLEAN22
        UserGroupMember: Record "User Group Member";
#endif
        Company: Record Company;
        User: Record User;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Option "ENU=Evaluation - Sample Data","Production - Setup Data Only","No Data","Advanced Evaluation - Complete Sample Data","Create New - No Data";
        NewCompanyName: Text[30];
    begin
        // [SCENARIO] Not choosing any user in the Company Creation Wizard creates company without any user

        // [GIVEN] Company Creation Wizard is opened

        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), Database::Company);

        // Company Creation Wizard
        CompanyCreationWizard.Trap();
        Page.Run(Page::"Company Creation Wizard");

        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.ActionBack.Invoke(); // Welcome page
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.CompanyName.SetValue(NewCompanyName);
        CompanyCreationWizard.CompanyData.SetValue(NewCompanyData::"No Data"); // Set to None to avoid lengthy data import
        CompanyCreationWizard.ActionNext.Invoke(); // Manage Users page
        CompanyCreationWizard.ActionNext.Invoke(); // That's it page

        // [WHEN] Company Creation Wizard is finished without adding any users
        CompanyCreationWizard.ActionFinish.Invoke();

        // [THEN] Company is created without any users
        Assert.RecordIsEmpty(User);
#if not CLEAN22
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordIsEmpty(UserGroupMember);
#endif
    end;

    [Test]
    [HandlerFunctions('UserLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCompanyWithUsersTest()
    var
        User1: Record User;
        User2: Record User;
#if not CLEAN22
        UserGroup1: Record "User Group";
        UserGroup2: Record "User Group";
        UserGroup3: Record "User Group";
        UserGroupMember: Record "User Group Member";
#endif
        AccessControl: Record "Access Control";
        Company: Record Company;
        AzureADPlan: Codeunit "Azure AD Plan";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Option "ENU=Evaluation - Sample Data","Production - Setup Data Only","No Data","Advanced Evaluation - Complete Sample Data","Create New - No Data";
        NewCompanyName: Text[30];
        PlanAID: Guid;
        PlanBID: Guid;
    begin
        // [SCENARIO] Not choosing any user in the Company Creation Wizard creates company with users
        // [GIVEN] User, Plan and UserPlan are setup
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);

        // Add current as admin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        Commit();

        // Add User1
        LibraryPermissions.CreateUser(User1, '', false);

        // Add User2
        LibraryPermissions.CreateUser(User2, '', false);

        // Add PlanA
        PlanAID := AzureADPlanTestLibrary.CreatePlan('PlanA');
        Assert.AreEqual(true, AzureADPlan.DoesPlanExist(PlanAID), 'test requirement not passed');

#if not CLEAN22
        // Add UG1 and UG2 -> to PlanA
        LibraryPermissions.CreateUserGroup(UserGroup1, '');
        LibraryPermissions.CreateUserGroup(UserGroup2, '');
        LibraryPermissions.AddUserGroupToPlan(UserGroup1.Code, PlanAID);
        LibraryPermissions.AddUserGroupToPlan(UserGroup2.Code, PlanAID);
#endif
        // Add PS1 and PS2 to PlanA
        LibraryPermissions.CreatePermissionSetInPlan('PS1', PlanAID);
        LibraryPermissions.CreatePermissionSetInPlan('PS2', PlanAID);

        // Add PlanB
        PlanBID := AzureADPlanTestLibrary.CreatePlan('PlanB');
        Assert.AreEqual(true, AzureADPlan.DoesPlanExist(PlanBID), 'test requirement not passed');

#if not CLEAN22
        // Add UG3 -> to PlanB
        LibraryPermissions.CreateUserGroup(UserGroup3, '');
        LibraryPermissions.AddUserGroupToPlan(UserGroup3.Code, PlanBID);
#endif
        // Add PS3 to PlanB
        LibraryPermissions.CreatePermissionSetInPlan('PS3', PlanBID);

        // Add User1 to PlanA
        LibraryPermissions.AddUserToPlan(User1."User Security ID", PlanAID);

        // Add User2 to PlanB
        LibraryPermissions.AddUserToPlan(User2."User Security ID", PlanBID);

        // [WHEN] Company Creation Wizard run and users are added
        CompanyCreationWizard.Trap;
        PAGE.Run(PAGE::"Company Creation Wizard");

        CompanyCreationWizard.ActionNext.Invoke; // Basic Information page
        CompanyCreationWizard.ActionBack.Invoke; // Welcome page
        CompanyCreationWizard.ActionNext.Invoke; // Basic Information page
        CompanyCreationWizard.CompanyName.SetValue(NewCompanyName);
        CompanyCreationWizard.CompanyData.SetValue(NewCompanyData::"No Data"); // Set to None to avoid lengthy data import
        CompanyCreationWizard.ActionNext.Invoke; // Manage Users page
        Commit();

        // Add User1 UserLookupModalPageHandler
        LibraryVariableStorage.Enqueue(User1);
        CompanyCreationWizard.ManageUserLabel.DrillDown;

        CompanyCreationWizard.First;
        Assert.IsFalse(CompanyCreationWizard.Next, 'More than one item was found in the list.');

        Assert.IsTrue(CompanyCreationWizard.First, 'No rows found in the User List.');
        CompanyCreationWizard.ActionNext.Invoke; // That's it page
        CompanyCreationWizard.ActionFinish.Invoke;

#if not CLEAN22
        // [THEN] Users are added to the newly added company
        UserGroupMember.SetRange("User Security ID", User1."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        UserGroupMember.SetRange("User Group Code", UserGroup1.Code);
        Assert.RecordCount(UserGroupMember, 1);

        UserGroupMember.SetRange("User Security ID", User1."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        UserGroupMember.SetRange("User Group Code", UserGroup2.Code);
        Assert.RecordCount(UserGroupMember, 1);

        UserGroupMember.SetRange("User Security ID", User2."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordIsEmpty(UserGroupMember);
#endif
        // [THEN] Users have the expected permissions associated with their plans
        AccessControl.SetRange("Company Name", NewCompanyName);

        // User 1 gets PS1 and PS2
        AccessControl.SetRange("User Security ID", User1."User Security ID");
        Assert.RecordCount(AccessControl, 2);

        AccessControl.SetRange("Role ID", 'PS1');
        Assert.RecordCount(AccessControl, 1);
        AccessControl.FindFirst();
        Assert.AreEqual(AccessControl."Role ID", 'PS1', 'Expected to have the permission set associated with the plan assigned.');

        AccessControl.SetRange("Role ID", 'PS2');
        Assert.RecordCount(AccessControl, 1);
        AccessControl.FindFirst();
        Assert.AreEqual(AccessControl."Role ID", 'PS2', 'Expected to have the permission set associated with the plan assigned.');

        // User 2 was not selected on the "Manage users" page, so they get no permissions
        AccessControl.SetRange("User Security ID", User2."User Security ID");
        Assert.RecordCount(AccessControl, 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserLookupModalPageHandler(var UserLookUp: TestPage "User Lookup")
    var
        User: Record User;
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        User := Variant;
        UserLookup.FILTER.SetFilter("User Security ID", User."User Security ID");
        UserLookup.OK.Invoke;
    end;
}

