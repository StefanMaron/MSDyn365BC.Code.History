codeunit 136506 "New Time Sheet Experience"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;


    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
        IsInitialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DescriptionTxt: Label 'Week %1', Comment = '%1 - week number';
        PageDataCaptionTxt: Label '%1 (%2)', Comment = '%1 - start date, %2 - Description,';
        UserSetupStatusTxt: Label 'User Setup (%1 users in User Setup)', Comment = '%1 - number';
        ResourcesStatusTxt: Label 'Resources (%1 resources)', Comment = '%1 - number';
        EmployeesStatusTxt: Label 'Employees (%1 employees)', Comment = '%1 - number';
        CauseofAbsenceStatusTxt: Label 'Causes of Absence (%1 causes of absence)', Comment = '%1 - number';
        navUserEmailTxt: Label 'navuser@email.com', Locked = true;
        TimeSheetCardOwnerUserIDFilter: Text;
        TimeSheetArchiveCardOwnerUserIDFilter: Text;
        UnexpectedTxt: Label 'Unexpected message.';
        ReopenDisabledTxt: Label 'Reopen must be disabled';

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTimeSheetDescription()
    var
        ResourcesSetup: Record "Resources Setup";
        AccountingPeriod: Record "Accounting Period";
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
    begin
        // [FEATURE] [Create Time Sheet]
        // [SCENARIO 390634] Create Time Sheet report makes time sheet default description
        Initialize();

        // [GIVEN] Prepare time sheet resource
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        // [WHEN] Create Time Sheet report is being run for "Starting Date" = 25.01.2021
        ResourcesSetup.Get();
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        FindFirstDOW(LibraryRandom.RandDateFrom(AccountingPeriod."Starting Date", 30), Date, ResourcesSetup);
        TimeSheetCreate(Date."Period Start", 1, Resource."No.", TimeSheetHeader);

        // [THEN] Created Time Sheet Header has Description = "Week 5"
        Date.Reset();
        Date.SetRange("Period Type", Date."Period Type"::Week);
        Date.SetFilter("Period Start", '%1..', TimeSheetHeader."Starting Date");
        Date.FindFirst();
        TimeSheetHeader.TestField(Description, StrSubstNo(DescriptionTxt, Date."Period No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenActiveTimeSheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TeamMemberActivities: TestPage "Team Member Activities";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "Open Active Time Sheet" opens time sheet for work date period
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create 3 time sheets "1", "2" and "3"
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 3);

        // [GIVEN] Set WorkDate within period of time sheet "2" 
        TimeSheetHeader.SetRange("Starting Date", TimeSheetHeader."Starting Date" + 7);
        TimeSheetHeader.FindFirst();
        WorkDate(TimeSheetHeader."Starting Date" + 3);

        // [WHEN] Run action "Open Active Time Sheet" from Team Memeber Activities 
        TimeSheetCard.Trap();
        TeamMemberActivities.OpenView();
        TeamMemberActivities.OpenCurrentTimeSheet.Invoke();

        // [THEN] Time Sheet "2" is opened
        TimeSheetCard."No.".AssertEquals(TimeSheetHeader."No.");

        TimeSheetCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardSubmit()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Card page does submit lines
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
        // [WHEN] Run action "Submit"
        TimeSheetCard.Submit.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        // [THEN] Action "Reopen" is enabled
        Assert.IsTrue(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be enabled');
        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.Submit.Enabled(), 'Submit must be disabled');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardSubmitAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Subform page does submit lines
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
        // [WHEN] Run action "Submit"
        TimeSheetCard.TimeSheetLines.Submit.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        // [THEN] Action "Reopen" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be enabled');
        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopen()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Card page does submit lines
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.Submit.Enabled(), 'Submit must be disabled');
        // [WHEN] Run action "Reopen"
        TimeSheetCard.ReopenSubmitted.Invoke();

        // [THEN] All 5 lines are reopened
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Open);

        // [THEN] Action "Submit" is enabled
        Assert.IsTrue(TimeSheetCard.Submit.Enabled(), 'Submit must be enabled');
        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Submit on Time Sheet Subform page does submit lines
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);
        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Submit" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be disabled');
        // [WHEN] Run action "Reopen"
        TimeSheetCard.TimeSheetLines.ReopenSubmitted.Invoke();

        // [THEN] All 5 lines are reopened
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Open);

        // [THEN] Action "Submit" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.Submit.Enabled(), 'Submit must be enabled');
        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.ReopenSubmitted.Enabled(), 'Reopen must be disabled');
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetCard()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Manager time sheet list page opens Time Sheet Card page with manager actions
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);

        // [GIVEN] Open manager time sheet list
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        // [WHEN] Action "Edit Time Sheet" is selected
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [THEN] Time Sheet Card page opened 
        // [THEN] Manager actions are visible
        Assert.IsTrue(TimeSheetCard.Approve.Visible(), 'Approve must be visible');
        Assert.IsTrue(TimeSheetCard.Reject.Visible(), 'Reject must be visible');
        Assert.IsTrue(TimeSheetCard.ReopenApproved.Visible(), 'Reopen approved must be visible');

        // [THEN] Time sheet owner's actions are invisible
        Assert.IsFalse(TimeSheetCard.Submit.Visible(), 'Submit must be invisible');
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Visible(), 'Reopen submitted must be invisible');
        Assert.IsFalse(TimeSheetCard.CreateLinesFromJobPlanning.Visible(), 'CreateLinesFromJobPlanning must be invisible');
        Assert.IsFalse(TimeSheetCard.CopyLinesFromPrevTS.Visible(), 'CopyLinesFromPrevTS must be invisible');

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardApprove()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Approve on Time Sheet Card page does approve lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [THEN] Action "Reopen Approved" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenApproved.Enabled(), 'Reopen Approved must be disabled');
        // [WHEN] Run action "Approve"
        TimeSheetCard.Approve.Invoke();

        // [THEN] All 5 lines are approved
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Approved);

        // [THEN] Action "Reopen Approved" is enabled
        Assert.IsTrue(TimeSheetCard.ReopenApproved.Enabled(), 'Reopen Approved must be enabled');
        // [THEN] Action "Approve" is disabled
        Assert.IsFalse(TimeSheetCard.Approve.Enabled(), 'Approve must be disabled');

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardApproveAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Approve on Time Sheet Subform page does approve lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [THEN] Action "Reopen Approved" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.ReopenApproved.Enabled(), 'Reopen Approved must be disabled');
        // [WHEN] Run action "Approve"
        TimeSheetCard.TimeSheetLines.Approve.Invoke();

        // [THEN] All 5 lines are approved
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Approved);

        // [THEN] Action "Reopen Approved" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.ReopenApproved.Enabled(), 'Reopen Approved must be enabled');
        // [THEN] Action "Approve" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Approve.Enabled(), 'Approve must be disabled');

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReject()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reject on Time Sheet Card page does reject lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reject"
        TimeSheetCard.Reject.Invoke();

        // [THEN] All 5 lines are rejected
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Rejected);

        // [THEN] Action "Reopen Approved" is enabled
        Assert.IsTrue(TimeSheetCard.ReopenApproved.Enabled(), 'Reopen Approved must be enabled');
        // [THEN] Action "Reject" is disabled
        Assert.IsFalse(TimeSheetCard.Reject.Enabled(), 'Reject must be disabled');

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardRejectAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reject on Time Sheet Subform page does reject lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 submitted lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reject"
        TimeSheetCard.TimeSheetLines.Reject.Invoke();

        // [THEN] All 5 lines are rejected
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Rejected);

        // [THEN] Action "Reopen Approved" is enabled
        Assert.IsTrue(TimeSheetCard.TimeSheetLines.ReopenApproved.Enabled(), 'Reopen Approved must be enabled');
        // [THEN] Action "Reject" is disabled
        Assert.IsFalse(TimeSheetCard.TimeSheetLines.Reject.Enabled(), 'Reject must be disabled');

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenApproved()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reopen for approved lines on Time Sheet Card page does reopen lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 approved lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, true, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reopen"
        TimeSheetCard.ReopenApproved.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenApprovedAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reopen for approved lines on Time Sheet Subform page does reopen lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 approved lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, true, false);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reopen"
        TimeSheetCard.TimeSheetLines.ReopenApproved.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenRejected()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reopen for approved lines on Time Sheet Card page does reopen lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create time sheet with 5 rejected lines
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, true);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reopen"
        TimeSheetCard.ReopenApproved.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        TimeSheetCard.Close();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetCardReopenRejectedAllFromSubform()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action Reopen for approved lines on Time Sheet Subform page does reopen lines
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
        CreateTimeSheetWithLines(TimeSheetHeader, true, false, true);

        // [GIVEN] Open manager time sheet 
        ManagerTimeSheetList.OpenView();
        TimeSheetCard.Trap();
        ManagerTimeSheetList.Filter.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();

        // [WHEN] Run action "Reopen"
        TimeSheetCard.TimeSheetLines.ReopenApproved.Invoke();

        // [THEN] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);

        TimeSheetCard.Close();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetArchiveCard()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetArchiveList: TestPage "Time Sheet Archive List";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "View Time Sheet" of "Time Sheet Archive List" page opens "Time Sheet Archive Card" page
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create archived time sheet "TS01"
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Open Time Sheet Archives page
        TimeSheetArchiveList.OpenView();
        TimeSheetArchiveList.Filter.SetFilter("No.", TimeSheetHeaderArchive."No.");

        // [WHEN] Run action "View Time Sheet" 
        TimeSheetArchiveCard.Trap();
        TimeSheetArchiveList."&View Time Sheet".Invoke();

        // [THEN] Archived Time Sheet "TS01" is opened
        TimeSheetArchiveCard."No.".AssertEquals(TimeSheetHeaderArchive."No.");

        TimeSheetArchiveCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenTimeSheetArchiveManagerCard()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        ManagerTimeSheetArcList: TestPage "Manager Time Sheet Arc. List";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "View Time Sheet" of "Manager Time Sheet Arc. List" page opens "Time Sheet Archive Card" page
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create archived time sheet "TS01"
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Open Time Sheet Archives page
        ManagerTimeSheetArcList.OpenView();
        ManagerTimeSheetArcList.Filter.SetFilter("No.", TimeSheetHeaderArchive."No.");

        // [WHEN] Run action "View Time Sheet" 
        TimeSheetArchiveCard.Trap();
        ManagerTimeSheetArcList."&View Time Sheet".Invoke();

        // [THEN] Archived Time Sheet "TS01" is opened
        TimeSheetArchiveCard."No.".AssertEquals(TimeSheetHeaderArchive."No.");

        TimeSheetArchiveCard.Close();
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetListAdminActions_V2NotTimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Actions "Create Time Sheets", "Move Time Sheets to Archive" are invisible for not admin user on Time Sheet List page
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create user setup with Time Sheet Admin = Yes
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Open Time Sheet List page
        TimeSheetList.OpenView();

        // [THEN] Actions "Create Time Sheets", "Move Time Sheets to Archive" are invisible
        Assert.IsFalse(TimeSheetList."Create Time Sheets".Visible(), 'Create Time Sheets must be invisible');
        Assert.IsFalse(TimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be invisible');

        // [THEN] Action "Edit Time Sheet" is invisible
        Assert.IsFalse(TimeSheetList.EditTimeSheet.Visible(), 'Edit Time Sheet must be invisible');

        UserSetup.Delete();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetListAdminActions_V2TimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Actions "Create Time Sheets", "Move Time Sheets to Archive" are visible for time sheet admin on Time Sheet List page
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create user setup with Time Sheet Admin = Yes
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);

        // [WHEN] Open Time Sheet List page
        TimeSheetList.OpenView();

        // [THEN] Actions "Create Time Sheets", "Move Time Sheets to Archive" are visible
        Assert.IsTrue(TimeSheetList."Create Time Sheets".Visible(), 'Create Time Sheets must be visible');
        Assert.IsTrue(TimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be visible');
        // [THEN] Action "Edit Time Sheet" is invisible
        Assert.IsFalse(TimeSheetList.EditTimeSheet.Visible(), 'Edit Time Sheet must be invisible');
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetListAdminActions_NotTimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Actions "Create Time Sheets", "Move Time Sheets to Archive" are visible on Time Sheet List page for not admin user if New Timesheet feature is not enabled
        Initialize();

        // [GIVEN] Disable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(false);

        // [GIVEN] Create user setup with Time Sheet Admin = No
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Open Time Sheet List page
        TimeSheetList.OpenView();

        // [THEN] Actions "Create Time Sheets", "Move Time Sheets to Archive" are visible
        Assert.IsTrue(TimeSheetList."Create Time Sheets".Visible(), 'Create Time Sheets must be visible');
        Assert.IsTrue(TimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be visible');
        // [THEN] Action "Edit Time Sheet" is visible
        Assert.IsTrue(TimeSheetList.EditTimeSheet.Visible(), 'Edit Time Sheet must be visible');

        UserSetup.Delete();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListAdminActions_V2NotTimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "Move Time Sheets to Archive" is invisible for not admin user on Manager Time Sheet List page
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create user setup with Time Sheet Admin = No
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Open Time Sheet List page
        ManagerTimeSheetList.OpenView();

        // [THEN] Action "Move Time Sheets to Archive" is invisible
        Assert.IsFalse(ManagerTimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be invisible');

        // [THEN] Action "Edit Time Sheet" is invisible
        Assert.IsFalse(ManagerTimeSheetList."&Edit Time Sheet".Visible(), 'Edit Time Sheet must be invisible');

        UserSetup.Delete();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListAdminActions_V2TimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "Move Time Sheets to Archive" is visible for time sheet admin 
        Initialize();

        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);

        // [GIVEN] Create user setup with Time Sheet Admin = Yes
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);

        // [WHEN] Open Time Sheet List page
        ManagerTimeSheetList.OpenView();

        // [THEN] Action "Move Time Sheets to Archive" is visible
        Assert.IsTrue(ManagerTimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be visible');
        // [THEN] Action "Edit Time Sheet" is invisible
        Assert.IsFalse(ManagerTimeSheetList."&Edit Time Sheet".Visible(), 'Edit Time Sheet must be invisible');
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListAdminActions_NotTimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Action "Move Time Sheets to Archive" are visible for not admin user if New Timesheet feature is not enabled
        Initialize();

        // [GIVEN] Disable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(false);

        // [GIVEN] Create user setup with Time Sheet Admin = No
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Open Time Sheet List page
        ManagerTimeSheetList.OpenView();

        // [THEN] Action "Move Time Sheets to Archive" is visible
        Assert.IsTrue(ManagerTimeSheetList.MoveTimeSheetsToArchive.Visible(), 'Move Time Sheets to Archive must be visible');
        // [THEN] Action "Edit Time Sheet" is visible
        Assert.IsTrue(ManagerTimeSheetList."&Edit Time Sheet".Visible(), 'Edit Time Sheet must be visible');

        UserSetup.Delete();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetEnterDayValues()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
        DayQty: array[7] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390634] Data entered into Day1 - Day7 fields recorded correctly
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet
        CreateTimeSheet(TimeSheetHeader);

        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("Resource No.", TimeSheetHeader."Resource No.");

        // [WHEN] Fill in fields Day1 - Day7
        for i := 1 to 7 do
            DayQty[i] := LibraryRandom.RandDec(10, 2);
        TimeSheetCard.TimeSheetLines.Type.SetValue("Time Sheet Line Type"::Resource);
        TimeSheetCard.TimeSheetLines.Field1.SetValue(DayQty[1]);
        TimeSheetCard.TimeSheetLines.Field2.SetValue(DayQty[2]);
        TimeSheetCard.TimeSheetLines.Field3.SetValue(DayQty[3]);
        TimeSheetCard.TimeSheetLines.Field4.SetValue(DayQty[4]);
        TimeSheetCard.TimeSheetLines.Field5.SetValue(DayQty[5]);
        TimeSheetCard.TimeSheetLines.Field6.SetValue(DayQty[6]);
        TimeSheetCard.TimeSheetLines.Field7.SetValue(DayQty[7]);

        // [THEN] Time Sheet details recorded correctly
        VerifyTimeSheetDetailsQty(TimeSheetHeader."No.", DayQty);

        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetGetDataCaptionFull()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390634] Function GetTimeSheetDataCaption returns "%1 - %2 (%3)" when time sheet description is not empty
        Initialize();

        // [GIVEN] Create time sheet with "Starting Date" = "04.01.2021", Ending Date = "10.01.2021", Description = "Week 1"
        CreateTimeSheet(TimeSheetHeader);
        TimeSheetHeader.TestField(Description);

        // [THEN] Function GetTimeSheetDataCaption returns 
        Assert.AreEqual(
            StrSubstNo(
                PageDataCaptionTxt,
                Format(TimeSheetHeader."Starting Date", 0, 4),
                TimeSheetHeader.Description),
            TimeSheetManagement.GetTimeSheetDataCaption(TimeSheetHeader),
            'Invalid DataCaption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetGetDataCaptionShort()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390634] Function GetTimeSheetDataCaption returns "%1 - %2 (%3)" when time sheet description is empty
        Initialize();

        // [GIVEN] Create time sheet with "Starting Date" = "04.01.2021", Ending Date = "10.01.2021", Description = ""
        CreateTimeSheet(TimeSheetHeader);
        TimeSheetHeader.Description := '';
        TimeSheetHeader.Modify();

        // [THEN] Function GetTimeSheetDataCaption returns 
        Assert.AreEqual(
                Format(TimeSheetHeader."Starting Date", 0, 4),
            TimeSheetManagement.GetTimeSheetDataCaption(TimeSheetHeader),
            'Invalid DataCaption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep1Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 1 controls
        Initialize();

        // [WHEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [THEN] Action "Back" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be disabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep2Controls()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        CauseOfAbsence: Record "Cause of Absence";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Wizard step 2 actions
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 2 "Participants"
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] User Setup Status = User Setup (1 users in User Setup)
        TimeSheetSetupWizard.UserSetupStatus.AssertEquals(StrSubstNo(UserSetupStatusTxt, UserSetup.Count()));
        // [THEN] Resources Setup Status = Resources (5 resources)
        TimeSheetSetupWizard.ResourcesStatus.AssertEquals(StrSubstNo(ResourcesStatusTxt, Resource.Count()));
        // [THEN] Employees Setup Status = Employees (8 employees)
        TimeSheetSetupWizard.EmployeesStatus.AssertEquals(StrSubstNo(EmployeesStatusTxt, Employee.Count()));
        // [THEN] Cause of Absence Status = Causes of Absence (3 causes of absence)
        TimeSheetSetupWizard.CauseOfAbsenceStatus.AssertEquals(StrSubstNo(CauseofAbsenceStatusTxt, CauseOfAbsence.Count()));

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [HandlerFunctions('UserSetupModalHandler,ResourceListModalHandler,EmployeeListModalHandler,CausesOfAbsenceModalHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep2Actions()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Wizard step 2 actions
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();
        // [GIVEN] Goto the step 2 "Participants"
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Run drilldown for User Setup Status
        // [THEN] "User Setup" page opened
        TimeSheetSetupWizard.UserSetupStatus.Drilldown();

        // [WHEN] Run drilldown for Resources Status
        // [THEN] "Resource List" page opened
        TimeSheetSetupWizard.ResourcesStatus.Drilldown();

        // [WHEN] Run drilldown for Employee Status
        // [THEN] "Employee List" page opened
        TimeSheetSetupWizard.EmployeesStatus.Drilldown();

        // [WHEN] Run drilldown for Causes of Absence Status
        // [THEN] "Causes of Absence" page opened
        TimeSheetSetupWizard.CauseOfAbsenceStatus.Drilldown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 3 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3FirstWeekday()
    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard First Weekday
        Initialize();

        // [GIVEN] Set Resource Setup "Time Sheet First Weekday" = Monday
        TimeSheetHeader.DeleteAll();
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet First Weekday" := ResourcesSetup."Time Sheet First Weekday"::Monday;
        ResourcesSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Change First Day of Week to Saturday
        TimeSheetSetupWizard.FirstDayOfWeek.SetValue(ResourcesSetup."Time Sheet First Weekday"::Saturday);

        // [THEN] Resource Setup has "Time Sheet First Weekday" = Saturday
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet First Weekday", ResourcesSetup."Time Sheet First Weekday"::Saturday);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep3TimeSheetAdmin()
    var
        UserSetup: Record "User Setup";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard First Weekday
        Initialize();

        // [GIVEN] Create user setup with Time Sheet Admin = No
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 3 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Set Time Sheet Admin = current user
        TimeSheetSetupWizard.TimeSheetAdmin.SetValue(UserId);

        // [THEN] User Setup has "Time Sheet Admin" = true
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep4Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 4 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 4 "Resources"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep4TimeSheetByJobApproval()
    var
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard "Time Sheet by Job Approval"
        Initialize();

        // [GIVEN] Set Resource Setup "Time Sheet by Job Approval" = Never
        TimeSheetHeader.DeleteAll();
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet by Job Approval" := ResourcesSetup."Time Sheet by Job Approval"::Never;
        ResourcesSetup.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 4 "General"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [WHEN] Change "Time Sheet by Job Approval" to Always
        TimeSheetSetupWizard.TimeSheetByJobApproval.SetValue(ResourcesSetup."Time Sheet by Job Approval"::Always);

        // [THEN] Resource Setup has "Time Sheet by Job Approval" = Always
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet by Job Approval", ResourcesSetup."Time Sheet by Job Approval"::Always);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep5Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 5 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be enabled');
        // [THEN] Action "Finish" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TimeSheetWizardSkipStep5NoEmployees()
    var
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 5 skipped if no employees
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Delete all employees
        Employee.DeleteAll();

        // [WHEN] Goto the step 5 
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Step "Finish" opened
        Assert.IsTrue(TimeSheetSetupWizard.RunCreateTimeSheets.Visible(), 'Step Finish must be opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep6Controls()
    var
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 6 controls
        Initialize();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 6 "Finish"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Action "Back" is disabled
        Assert.IsTrue(TimeSheetSetupWizard.BackAction.Enabled(), 'Action Back must be enabled');
        // [THEN] Action "Next" is disabled
        Assert.IsFalse(TimeSheetSetupWizard.NextAction.Enabled(), 'Action Next must be disabled');
        // [THEN] Action "Finish" is enabled
        Assert.IsTrue(TimeSheetSetupWizard.FinishAction.Enabled(), 'Action Finish must be enabled');
    end;

    [Test]
    [HandlerFunctions('CreateTimeSheetsHandler')]
    [Scope('OnPrem')]
    procedure TimeSheetWizardStep6CreateTimeSheets()
    var
        UserSetup: Record "User Setup";
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 390633] Time Sheet Setup Wizard step 6 "Create Time Sheets"
        Initialize();

        // [GIVEN] Create user setup with Time Sheet Admin = Yes
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        Commit();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [GIVEN] Goto the step 6 "Finish"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [GIVEN] Set "Create Time Sheets" = Yes
        TimeSheetSetupWizard.RunCreateTimeSheets.SetValue(true);

        // [WHEN] Press "Finish"
        TimeSheetSetupWizard.FinishAction.Invoke();

        // [THEN] Report "Create Time Sheets" opened
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetHeaderResourceName()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        Resource: Record Resource;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404750] Time Sheet header has Resource Name field
        Initialize();

        // [GIVEN] Create time sheet for resource "R"
        CreateTimeSheet(TimeSheetHeader);
        // [GIVEN] Set name = "NNN" for resource "R"
        Resource.Get(TimeSheetHeader."Resource No.");
        Resource.Name := CopyStr(LibraryRandom.RandText(MaxStrLen(Resource.Name)), 1, MaxStrLen(Resource.Name));
        Resource.Modify();

        // [THEN] Time sheet "Resource Name" = "NNN"
        TimeSheetHeader.CalcFields("Resource Name");
        TimeSheetHeader.TestField("Resource Name", Resource.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardMatchEmployeeVsResource()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404725] Time Sheet Setup Wizard matches Employee with Resource by email
        Initialize();

        // [GIVEN] Create time sheet resource "R" for current user
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // [GIVEN] Set current user email = navuser@email.com
        UserSetup."E-Mail" := navUserEmailTxt;
        UserSetup.Modify();

        // [GIVEN] Create employee "E" with "Company email" = navuser@email.com
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Company E-Mail" := navUserEmailTxt;
        Employee.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Employee "E" matched with resource "R"
        Employee.Find();
        Employee.TestField("Resource No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetWizardMatchEmployeeVsResourceSaaS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        Employee: Record Employee;
        TimeSheetSetupWizard: TestPage "Time Sheet Setup Wizard";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404725] Time Sheet Setup Wizard matches Employee with Resource by user Authentication Email
        Initialize();

        // [GIVEN] Create time sheet resource "R" for current user
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // [GIVEN] Set current user "Authentication Email" = navuser@email.com
        SetCurrentUserAuthenticationEmail(navUserEmailTxt);

        // [GIVEN] Create employee "E" with "Company email" = navuser@email.com
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Company E-Mail" := navUserEmailTxt;
        Employee.Modify();

        // [GIVEN] Open "Time Sheet Setup Wizard"
        TimeSheetSetupWizard.OpenEdit();

        // [WHEN] Goto the step 5 "Employees"
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();
        TimeSheetSetupWizard.NextAction.Invoke();

        // [THEN] Employee "E" matched with resource "R"
        Employee.Find();
        Employee.TestField("Resource No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTimeSheetLinesWithDetails()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407324] "Copy lines from previous time sheet" copies time sheet details if TimeSheetV2Enabled
        Initialize();

        // [GIVEN] Create time sheet "1" with data
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetHeader, FromTimeSheetLine);
        // [GIVEN] Submit line
        TimeSheetApprovalManagement.Submit(FromTimeSheetLine);

        // [GIVEN] Create time sheet "2" without data
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 1, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for time sheet "2"
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time sheet details copied from "1" to "2"
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTimeSheetLinesWithDetails_ThreeWeeksApart()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 454717] "Copy lines from previous time sheet" copies time sheet details if TimeSheetV2Enabled.
        // [SCENARIO 454717] Create 4 time sheets (4 weeks) and delete 2 in the middle. Then copy lines from time sheet "1" to time sheet "4".
        Initialize();

        // [GIVEN] Create time sheet "1" with data
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetHeader, FromTimeSheetLine);

        // [GIVEN] Create time sheets "2", "3", "4" without data
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 3, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);

        // [GIVEN] Delete time sheets "2"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindFirst();
        ToTimeSheetHeader.Next();
        ToTimeSheetHeader.Delete(true);

        // [GIVEN] Delete time sheets "3"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindFirst();
        ToTimeSheetHeader.Next();
        ToTimeSheetHeader.Delete(true);

        // [GIVEN] Find the last, time sheets "4"
        ToTimeSheetHeader.SetRange("Resource No.", FromTimeSheetHeader."Resource No.");
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for time sheet "4"
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time sheet details copied from "1" to "4"
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterNotAdmin()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Current user is not time sheet admin
        UserSetup.Get(UserId);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UserSetup.Delete();
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterAdmin()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has no defult filter by owner id if current user is time sheet admin
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Current user is time sheet admin
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page is not filtered by Owner User Id
        Assert.AreEqual('', NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetCardDefaultFilterNoUserSetup()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Card page has defult filter by owner id if current user does not have user setup
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Create time sheet 
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Mock no user setup for current user
        UserSetup.Get(UserId);
        UserSetup.Delete();

        // [WHEN] Time Sheet card page is opened
        TimeSheetCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterNotAdmin()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Current user is not time sheet admin
        UserSetup.Get(UserId);
        UserSetup.Validate("Time Sheet Admin.", false);
        UserSetup.Modify();

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UserSetup.Delete();
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterAdmin()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has no defult filter by owner id if current user is time sheet admin
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Current user is time sheet admin
        UserSetup.Get(UserId);
        UserSetup.TestField("Time Sheet Admin.", true);

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page is not filtered by Owner User Id
        Assert.AreEqual('', NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveCardDefaultFilterNoUserSetup()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        UserSetup: Record "User Setup";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TimeSheetArchiveCard: TestPage "Time Sheet Archive Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 421062] Time Sheet Archive Card page has defult filter by owner id if current user is not time sheet admin
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [GIVEN] Mock time sheet archive
        MockArchivedTimeSheet(TimeSheetHeaderArchive);

        // [GIVEN] Mock no user setup for current user
        UserSetup.Get(UserId);
        UserSetup.Delete();

        // [WHEN] Time Sheet Archive card page is opened
        TimeSheetArchiveCard.OpenEdit();

        // [THEN] Page filtered by Owner User Id
        Assert.AreEqual(UserId(), NewTimeSheetExperience.GetTimeSheetArchiveCardOwnerUserIDFilter(), 'Invalid default owner id filter');
        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [HandlerFunctions('SuggestJobJnlLinesRequestPageHandler,ConfirmHandlerYes,MessageHandler')]
    procedure CopyTimeSheetLinesWithDetailsAfterPosting()
    var
        FromTimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetLine: Record "Time Sheet Line";
        ToTimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        JobJournalLine: Record "Job Journal Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [SCENARIO 421957] "Copy lines from previous time sheet" for Time Sheet which lines were posted.
        Initialize();

        // [GIVEN] Job "J" with Job Task "T".
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Time Sheet "S1" with one Time Sheet Line that has five Time Sheet Detail.
        // [GIVEN] Time Sheet Line has Job No. "J" and Job Task No. "T".
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheetLineWithTimeAllocaiton(FromTimeSheetLine, FromTimeSheetHeader, "Time Sheet Line Type"::Job, Job."No.", JobTask."Job Task No.");

        // [GIVEN] Submitted and approved Time Sheet Line.
        LibraryTimeSheet.SubmitAndApproveTimeSheetLine(FromTimeSheetLine);

        // [GIVEN] Job Journal Lines suggested from Time Sheet "S1" and posted.
        InitJobJournalLine(JobJournalLine);
        LibraryTimeSheet.RunSuggestJobJnlLinesReportForResourceInPeriod(
            JobJournalLine, FromTimeSheetHeader."Resource No.", WorkDate(), CalcDate('<1M>', WorkDate()));
        TimeSheetDetail.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
        Assert.RecordCount(JobJournalLine, TimeSheetDetail.Count);
        PostJobJournalLine(JobJournalLine);

        // [GIVEN] Create time sheet "S2" without Time Sheet Lines.
        TimeSheetCreate(FromTimeSheetHeader."Ending Date" + 1, 1, FromTimeSheetHeader."Resource No.", ToTimeSheetHeader);
        ToTimeSheetHeader.FindLast();

        // [WHEN] Run function "Copy lines from previous time sheet" for Time Sheet "S2".
        TimeSheetManagement.CopyPrevTimeSheetLines(ToTimeSheetHeader);

        // [THEN] Time Sheet Details were copied from "S1" to "S2" with Posted Quantity = 0.
        VerifyCopiedTimeSheetDetails(FromTimeSheetHeader, FromTimeSheetLine, ToTimeSheetHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTimeSheetListOnTeamMemberActivities()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        FromTimeSheetHeader: Record "Time Sheet Header";
        CreateTimeSheets: Report "Create Time Sheets";
        NewTimeSheetExperience: Codeunit "New Time Sheet Experience";
        TeamMemberActivities: TestPage "Team Member Activities";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // [SCENARIO 447634] Open Current Time sheet' in the role center through error when timesheet exist for some other dates
        Initialize();
#if not CLEAN22
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        BindSubscription(NewTimeSheetExperience);

        // [THEN] Deleteall the records created by other test automation for current user. 
        TimeSheetHeader.DeleteAll();

        // [GIVEN] Create resource and update Use time sheet as true.
        LibraryResource.CreateResourceWithUsers(Resource);
        Resource.Validate("Use Time Sheet", true);
        Resource.Modify(true);

        // [WHEN] User tries to run Report Create Time Sheets
        LibraryTimeSheet.CreateTimeSheet(FromTimeSheetHeader, true);
        CreateTimeSheets.InitParameters(FromTimeSheetHeader."Starting Date" + 1, 1, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // [THEN] Filter creating timesheet.
        WorkDate(FromTimeSheetHeader."Starting Date" - 1);
        TimeSheetHeader.SetFilter("Resource No.", Resource."No.");
        TimeSheetHeader.FindFirst();

        // [GIVEN] Try to open current timesheet and go to created time sheet record.  
        TimeSheetList.Trap();
        TeamMemberActivities.OpenView();
        TeamMemberActivities.OpenCurrentTimeSheet.Invoke();
        TimeSheetList.GoToRecord(TimeSheetHeader);

        // [VERIFY] time sheet list is not empty and it contain the creaeted timesheet record.
        Assert.AreEqual(Resource."No.", TimeSheetList."Resource No.".Value, '');

        UnbindSubscription(NewTimeSheetExperience);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure S458927_CreateLinesFromJobPlanning_SkipInvalidJobPlanningLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        Job: array[3] of Record Job;
        JobTask: array[3] of Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        DateRecord: Record Date;
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        // [FEATURE] [UT] [Create lines from job planning]
        // [SCENARIO 458927] "Create lines from job planning" skips "Job Planning Line" if Job.Blocked = All or Job.Status = Completed.
        // [SCENARIO 458927] Create 3 Jobs: J1 with Blocked = All, J2 with default Blocked and Status, J3 in Status = Completed.
        // [SCENARIO 458927] Verify that "Create lines from job planning" only processed J2.
        Initialize();

#if not CLEAN22
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif

        // [GIVEN] Set "Time Sheet by Job Approval" in "Resources Setup"
        ResourcesSetup.Get();
        ResourcesSetup."Time Sheet by Job Approval" := ResourcesSetup."Time Sheet by Job Approval"::Never;
        ResourcesSetup.Modify();

        // [GIVEN] Create Time Sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        Resource.Get(TimeSheetHeader."Resource No.");

        DateRecord.SetRange("Period Type", DateRecord."Period Type"::Date);
        DateRecord.SetFilter("Period Start", '%1..', TimeSheetHeader."Starting Date");
        DateRecord.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        DateRecord.FindFirst();

        // [GIVEN] Create Job "J1" with Blocked = All
        CreateJobWithJobPlanning(Resource, DateRecord, Job[1], JobTask[1], JobPlanningLine[1]);
        Job[1].Validate(Blocked, Job[1].Blocked::All);
        Job[1].Modify();

        // [GIVEN] Create Job "J2" with default Blocked and Status
        CreateJobWithJobPlanning(Resource, DateRecord, Job[2], JobTask[2], JobPlanningLine[2]);

        // [GIVEN] Create Job "J3" in Status = Completed
        CreateJobWithJobPlanning(Resource, DateRecord, Job[3], JobTask[3], JobPlanningLine[3]);
        Job[3].Validate(Status, Job[3].Status::Completed);
        Job[3].Modify();

        // [WHEN] Run action "Create lines from job planning"
        TimeSheetManagement.CreateLinesFromJobPlanning(TimeSheetHeader);

        // [THEN] Verify that only 1 line has been created
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.RecordCount(TimeSheetLine, 1);

        // [THEN] Verify that line is created for "J2"
        TimeSheetLine.FindFirst();
        TimeSheetLine.TestField(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.TestField("Job No.", Job[2]."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask[2]."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerify')]
    [Scope('OnPrem')]
    procedure VerifyEmpoloymentDateWarningTimeSheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetCard: TestPage "Time Sheet Card";
    begin
        // [SCENARIO 459803] Resources are able to enter time in time sheets prior to the date in their Employment Date field without error
        Initialize();

#if not CLEAN22
        // [GIVEN] Enable Time Sheet V2
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        // [GIVEN] Create time sheet with 5 open lines
        CreateTimeSheetWithLines(TimeSheetHeader, false, false, false);

        // [GIVEN] Add Employment Date greater thane timesheet creation date
        Resource.Get(TimeSheetHeader."Resource No.");
        Resource.Validate("Employment Date", CalcDate('<+1M>', TimeSheetHeader."Starting Date"));
        Resource.Modify();

        // [GIVEN] Open time sheet card
        TimeSheetCard.OpenEdit();
        TimeSheetCard.Filter.SetFilter("No.", TimeSheetHeader."No.");

        // [THEN] Action "Reopen" is disabled
        Assert.IsFalse(TimeSheetCard.ReopenSubmitted.Enabled(), ReopenDisabledTxt);

        // [WHEN] Run action "Submit"
        // [THEN] Verify Employment Date warning message on handler page.
        TimeSheetCard.Submit.Invoke();

        // [VERIFY] All 5 lines are submitted
        VerifyTimeSheetLinesStatus(TimeSheetHeader."No.", "Time Sheet Status"::Submitted);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";

    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Time Sheet Experience");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Time Sheet Experience");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
#if not CLEAN22
        LibraryTimeSheet.SetNewTimeSheetExperience(true);
#endif
        LibrarySetupStorage.Save(DATABASE::"Resources Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Time Sheet Experience");
    end;

    local procedure CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line")
    var
        i: Integer;
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        for i := 1 to 5 do
            LibraryTimeSheet.CreateTimeSheetDetail(
                TimeSheetLine, TimeSheetHeader."Starting Date" + i - 1, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateTimeSheetLineWithTimeAllocaiton(var TimeSheetLine: Record "Time Sheet Line"; TimeSheetHeader: Record "Time Sheet Header"; LineType: Enum "Time Sheet Line Type"; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        i: Integer;
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, LineType, JobNo, JobTaskNo, '', '');
        for i := 1 to 5 do
            LibraryTimeSheet.CreateTimeSheetDetail(
                TimeSheetLine, TimeSheetHeader."Starting Date" + i - 1, LibraryRandom.RandDecInRange(5, 15, 2));
    end;

    local procedure CreateTimeSheetWithLines(var TimeSheetHeader: Record "Time Sheet Header"; Submit: Boolean; Approve: Boolean; Reject: Boolean)
    var
        Resource: Record Resource;
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalManagement: Codeunit "Time Sheet Approval Management";
        i: Integer;
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        for i := 1 to LibraryRandom.RandIntInRange(3, 7) do begin
            CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
            if Submit then
                TimeSheetApprovalManagement.Submit(TimeSheetLine);
            if Approve then
                TimeSheetApprovalManagement.Approve(TimeSheetLine);
            if Reject then
                TimeSheetApprovalManagement.Reject(TimeSheetLine);
        end;
    end;

    local procedure CreateTimeSheet(var TimeSheetHeader: Record "Time Sheet Header")
    var
        Resource: Record Resource;
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
    end;

    local procedure MockArchivedTimeSheet(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Resource: Record Resource;
        TimeSheetManagement: Codeunit "Time Sheet Management";
    begin
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        CreateTimeSheetLineWithTimeAllocaiton(TimeSheetHeader, TimeSheetLine);
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.Validate(Posted, true);
        TimeSheetLine.Modify(true);

        TimeSheetManagement.MoveTimeSheetToArchive(TimeSheetHeader);
        TimeSheetHeaderArchive.Get(TimeSheetHeader."No.");
    end;

    local procedure CreateMultipleTimeSheet(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; NoOfTimeSheets: Integer)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        FindFirstDOW(AccountingPeriod."Starting Date", Date, ResourcesSetup);

        TimeSheetCreate(Date."Period Start", NoOfTimeSheets, Resource."No.", TimeSheetHeader);
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
    end;

    local procedure InitJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
    begin
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate."Increment Batch Name" := true;
        JobJournalTemplate.Modify();

        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        JobJournalLine.Init();
        JobJournalLine.Validate("Journal Template Name", JobJournalTemplate.Name);
        JobJournalLine.Validate("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.SetRange("Journal Template Name", JobJournalLine."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalLine."Journal Batch Name");
    end;

    local procedure PostJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    begin
        JobJournalLine.ModifyAll("Document No.", LibraryUtility.GenerateGUID());
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure TimeSheetCreate(Date: Date; NoOfPeriods: Integer; ResourceNo: Code[20]; var TimeSheetHeader: Record "Time Sheet Header")
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        CreateTimeSheets.InitParameters(Date, NoOfPeriods, ResourceNo, false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        TimeSheetHeader.FindFirst();
    end;

    local procedure SetCurrentUserAuthenticationEmail(AuthenticationEmail: Text[250])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId());
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := CopyStr(UserId(), 1, MaxStrLen(User."User Name"));
            User."Authentication Email" := AuthenticationEmail;
            User.Insert();
        end else begin
            User."Authentication Email" := AuthenticationEmail;
            User.Modify();
        end;
    end;

    local procedure FindFirstDOW(StartingDate: Date; var Date: Record Date; var ResourcesSetup: Record "Resources Setup")
    begin
        // find first DOW after accounting period starting date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', StartingDate);
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();
    end;

    local procedure SetupTSResourceUserID(var Resource: Record Resource; UserSetup: Record "User Setup")
    begin
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify();
    end;

    local procedure VerifyTimeSheetLinesStatus(TimeSheetHeaderNo: Code[20]; ExpectedStatus: Enum "Time Sheet Status")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetLine.FindSet();
        repeat
            TimeSheetLine.TestField(Status, ExpectedStatus);
        until TimeSheetLine.Next() = 0;
    end;

    local procedure VerifyTimeSheetDetailsQty(TimeSheetHeaderNo: Code[20]; DayQty: array[7] of Decimal)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        i: Integer;
    begin
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetDetail.FindSet();
        repeat
            i := i + 1;
            TimeSheetDetail.TestField(Quantity, DayQty[i]);
        until TimeSheetDetail.Next() = 0;
    end;

    local procedure VerifyCopiedTimeSheetDetails(FromTimeSheetHeader: Record "Time Sheet Header"; FromTimeSheetLine: Record "Time Sheet Line"; ToTimeSheetHeader: Record "Time Sheet Header")
    var
        ToTimeSheetLine: Record "Time Sheet Line";
        FromTimeSheetDetail: Record "Time Sheet Detail";
        ToTimeSheetDetail: Record "Time Sheet Detail";
    begin
        FromTimeSheetDetail.SetRange("Time Sheet No.", FromTimeSheetHeader."No.");
        FromTimeSheetDetail.SetRange("Time Sheet Line No.", FromTimeSheetLine."Line No.");
        FromTimeSheetDetail.FindSet();

        ToTimeSheetLine.SetRange("Time Sheet No.", ToTimeSheetHeader."No.");
        ToTimeSheetLine.FindFirst();
        ToTimeSheetDetail.SetRange("Time Sheet No.", ToTimeSheetHeader."No.");
        ToTimeSheetDetail.SetRange("Time Sheet Line No.", ToTimeSheetLine."Line No.");
        ToTimeSheetDetail.FindSet();

        repeat
            ToTimeSheetDetail.TestField(Posted, false);
            ToTimeSheetDetail.TestField(Status, "Time Sheet Status"::Open);
            ToTimeSheetDetail.TestField(Quantity, FromTimeSheetDetail.Quantity);
            ToTimeSheetDetail.TestField("Posted Quantity", 0);
            ToTimeSheetDetail.TestField(Date, ToTimeSheetLine."Time Sheet Starting Date" + (FromTimeSheetDetail."Date" - FromTimeSheetLine."Time Sheet Starting Date"));

            ToTimeSheetDetail.Next();
        until FromTimeSheetDetail.Next() = 0;
    end;

    local procedure CreateJobWithJobPlanning(Resource: Record Resource; Date: Record Date; var Job: Record Job; var JobTask: Record "Job Task"; var JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Planning Date" := Date."Period Start";
        JobPlanningLine."No." := Resource."No.";
        JobPlanningLine.Quantity := LibraryRandom.RandDec(10, 2);
        JobPlanningLine."Unit Cost" := LibraryRandom.RandDec(10, 2);
        JobPlanningLine.Insert();
    end;

    procedure GetTimeSheetCardOwnerUserIDFilter(): Text
    begin
        exit(TimeSheetCardOwnerUserIDFilter);
    end;

    procedure GetTimeSheetArchiveCardOwnerUserIDFilter(): Text
    begin
        exit(TimeSheetArchiveCardOwnerUserIDFilter);
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerify(Question: Text; var Reply: Boolean)
    var
        TimeSheetTxt: Label 'Time Sheet';
    begin
        Assert.IsTrue(StrPos(Question, TimeSheetTxt) > 0, UnexpectedTxt); // [VERIFY] Timesheet Employment Date message 
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserSetupModalHandler(var UserSetup: TestPage "User Setup")
    begin
        UserSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListModalHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeListModalHandler(var EmployeeList: TestPage "Employee List")
    begin
        EmployeeList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CausesOfAbsenceModalHandler(var CausesOfAbsence: TestPage "Causes of Absence")
    begin
        CausesOfAbsence.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateTimeSheetsHandler(var CreateTimeSheets: TestRequestPage "Create Time Sheets")
    begin
        CreateTimeSheets.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SuggestJobJnlLinesRequestPageHandler(var SuggestJobJnlLines: TestRequestPage "Suggest Job Jnl. Lines")
    begin
        SuggestJobJnlLines.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Time Sheet Card", 'OnAfterOnOpenPage', '', false, false)]
    local procedure OnAfterTimeSheetCardOpened(var TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetHeader.FilterGroup(2);
        TimeSheetCardOwnerUserIDFilter := TimeSheetHeader.GetFilter("Owner User ID");
        TimeSheetHeader.FilterGroup(2);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Time Sheet Archive Card", 'OnAfterOnOpenPage', '', false, false)]
    local procedure OnAfterTimeSheetArchiveCardOpened(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
        TimeSheetHeaderArchive.FilterGroup(2);
        TimeSheetArchiveCardOwnerUserIDFilter := TimeSheetHeaderArchive.GetFilter("Owner User ID");
        TimeSheetHeaderArchive.FilterGroup(2);
    end;
}