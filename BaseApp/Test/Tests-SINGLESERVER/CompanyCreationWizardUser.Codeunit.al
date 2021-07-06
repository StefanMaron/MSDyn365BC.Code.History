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
        UserGroupMember: Record "User Group Member";
        Company: Record Company;
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
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordIsEmpty(UserGroupMember);
    end;

    [Test]
    [HandlerFunctions('UserLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCompanyWithUsersTest()
    var
        User1: Record User;
        User2: Record User;
        User3: Record User;
        UserGroup1: Record "User Group";
        UserGroup2: Record "User Group";
        UserGroup3: Record "User Group";
        UserGroupMember: Record "User Group Member";
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
        // [GIVEN] User, Plan, UserPlan and UserGroupPlan is setup
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);

        // Add current as admin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        Commit();

        // Add User1
        LibraryPermissions.CreateUser(User1, '', false);

        // Add User2
        LibraryPermissions.CreateUser(User2, '', false);

        // Add User3
        LibraryPermissions.CreateUser(User3, '', false);

        // Add PlanA
        PlanAID := AzureADPlanTestLibrary.CreatePlan('PlanA');
        Assert.AreEqual(true, AzureADPlan.DoesPlanExist(PlanAID), 'test requirement not passed');

        // Add UG1 -> to PlanA
        LibraryPermissions.CreateUserGroup(UserGroup1, '');
        LibraryPermissions.AddUserGroupToPlan(UserGroup1.Code, PlanAID);

        // Add PlanB
        PlanBID := AzureADPlanTestLibrary.CreatePlan('PlanB');
        Assert.AreEqual(true, AzureADPlan.DoesPlanExist(PlanBID), 'test requirement not passed');

        // Add UG2 -> to PlanB
        // Add UG3 -> to PlanB
        LibraryPermissions.CreateUserGroup(UserGroup2, '');
        LibraryPermissions.CreateUserGroup(UserGroup3, '');
        LibraryPermissions.AddUserGroupToPlan(UserGroup2.Code, PlanBID);
        LibraryPermissions.AddUserGroupToPlan(UserGroup3.Code, PlanBID);

        // Add User1 to PlanA
        LibraryPermissions.AddUserToPlan(User1."User Security ID", PlanAID);

        // Add User2 to PlanB
        LibraryPermissions.AddUserToPlan(User2."User Security ID", PlanBID);

        // Add User3 to PlanB
        LibraryPermissions.AddUserToPlan(User3."User Security ID", PlanBID);

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

        // Add User1 and User2
        LibraryVariableStorage.Enqueue(User1);
        CompanyCreationWizard.ManageUserLabel.DrillDown;

        CompanyCreationWizard.First;
        Assert.IsFalse(CompanyCreationWizard.Next, 'More than one item was found in the list.');

        Assert.IsTrue(CompanyCreationWizard.First, 'No rows found in the User List.');
        CompanyCreationWizard.ActionNext.Invoke; // That's it page
        CompanyCreationWizard.ActionFinish.Invoke;

        // [THEN] Users are added to the newly added company
        UserGroupMember.SetRange("User Security ID", User1."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordCount(UserGroupMember, 1);

        UserGroupMember.SetRange("User Security ID", User2."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordIsEmpty(UserGroupMember);

        UserGroupMember.SetRange("User Security ID", User3."User Security ID");
        UserGroupMember.SetRange("Company Name", NewCompanyName);
        Assert.RecordIsEmpty(UserGroupMember);
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

