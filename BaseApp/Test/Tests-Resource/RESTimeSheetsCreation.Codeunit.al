codeunit 136503 "RES Time Sheets Creation"
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
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Text001Err: Label 'Rolling back changes...';
        NonExistentUserErr: Label 'NON EXISTENT USER ID';
        ErrorGeneratedIncorrectErr: Label 'Incorrect Error Message';
        NewUserIDTok: Label 'NEWUSERID';
        SameUserIDMessageErr: Label 'User ID should be modified';
        ResourceIsNotDeletedErr: Label 'Resource is not deleted';
        YouCannotDeleteResourceErr: Label 'You cannot delete Resource %1 because unprocessed time sheet lines exist for this resource.';
        FirstWeekDayCannotBeChangedErr: Label 'Time Sheet First Weekday cannot be changed, because there is at least one time sheet.';
#if not CLEAN22
        DynamicDayCaptionIsNotCorrectErr: Label 'Dynamic Day Caption Is No Correct';
#endif
        TypeMustBeEqualToJobErr: Label 'Type must be equal to ''Project''  in Time Sheet Line: Time Sheet No.=%1, Line No.=0.';
        TimesheetDetailValueIncorrectErr: Label 'Time Sheet Day Time Allocation incorrect';
#if not CLEAN22
        StatusMustBeOpenOrRejectedErr: Label 'Status must be Open or Rejected in line with Time Sheet No.=''%1'', Line No.=''10000''.', Comment = 'Status must be Open or Rejected in Time Sheet Line Time Sheet No.=''xxx'', Line No.=''xxx''.';
        StatusShouldBeSumbittedErr: Label 'Status field value should be Submitted';
        StatusShouldBeOpenErr: Label 'Status Should be Open';
        TimesheetLineTypeIsIncorrectErr: Label 'Time Sheet Line Type is incorrect';
        TimesheetLineStatusIncorrectErr: Label 'Time Sheet Line Status is incorrect';
        ThereIsNothingToSubmitErr: Label 'There is nothing to submit for line with Time Sheet No.=%1, Line No.=10000.';
#endif
        LibraryResource: Codeunit "Library - Resource";
#if not CLEAN22
        IncorrectPostingDateErr: Label 'Incorrect Posting Date';
        IncorrectEntryTypeErr: Label 'Incorrect Entry Type';
        IncorrectUserIDErr: Label 'Incorrect User ID';
#endif
        IncorrectCostValueErr: Label 'Incorrect Cost Value';
#if not CLEAN22
        LibraryHumanResource: Codeunit "Library - Human Resource";
#endif
        RecRef: RecordRef;
        ThereIsNoEmployeeLinkedWithResErr: Label 'There is no employee linked with resource %1.';
        DayTimeAllocation: array[7] of Decimal;
        UseTimeSheetCannotBeChangedErr: Label 'Use Time Sheet cannot be changed since unprocessed time sheet lines exist for this resource.';
        TimeSheetsHaveBeenMovedtoArchErr: Label '%1 time sheets have been moved to archive.';
        YouHaveChangedADimensionMsg: Label 'You have changed a dimension';
        DoYouWantToUpdateTheLinesQst: Label 'Do you want to update the lines?';
        GlobalJobNo: Code[20];
        GlobalJobTaskNo: Code[20];
        GlobalTSAllocationValues: array[9] of Decimal;
        GlobalTimeSheetNo: Code[20];
        GlobalTextVariable: Code[20];
#if not CLEAN22
        TSLineType: Option " ",Resource,Job,Service,Absence,"Assembly Order";
#endif
        TimeSheetDoesNotExistErr: Label 'Time Sheet does not exist';
#if not CLEAN22
        IncorrectTimeSheetNoOpenedErr: Label 'Incorrect Time Sheet No. opened';
#endif
        IncorrectTSArchiveNoOpenedErr: Label 'Incorrect Manager Time Sheet Archive No. opened';
        IncorrectPostingEntryOpenedErr: Label 'Incorrect Posting Entry No. page opened';
        IncorrectPostingEntryQuantityErr: Label 'Incorrect Posting Entry Quantity';
        IncorrectAllocationQuantityErr: Label 'Incorrect Allocation Quantity';
        IsInitialized: Boolean;
        LineCountErr: Label 'Number of %1 entries is wrong';
        IncorrectHRUnitOfMeasureTableRelationErr: Label 'The field Unit of Measure Code of table Cause of Absence contains a value (%1) that cannot be found in the related table (Human Resource Unit of Measure)', Locked = true;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RES Time Sheets Creation");
        SetUp();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RES Time Sheets Creation");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RES Time Sheets Creation");
    end;

    local procedure SetUp()
    var
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.Initialize();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        ResourcesSetup.Get();
        // clear "Time Sheet Owner User ID"
        Resource.ModifyAll("Time Sheet Owner User ID", '');
    end;

    local procedure TearDown()
    begin
        asserterror Error(Text001Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkResourceToNonExistUser()
    var
        Resource: Record Resource;
    begin
        // Test case checks that Resource cannot be linked with non-existent USER ID
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Fill 'User ID' field with non-existent User ID
        asserterror Resource.Validate("Time Sheet Owner User ID", NonExistentUserErr);
        // 3. Verify: Verify User does not exist error message.
        Assert.AssertPrimRecordNotFound();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkResourceToNonExistManager()
    var
        Resource: Record Resource;
    begin
        // Test case checks that Resource cannot be linked with non-existent Time Sheet Owner USER ID
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Fill 'Manager User ID' field with non-existent User ID
        asserterror Resource.Validate("Time Sheet Approver User ID", NonExistentUserErr);
        // 3. Verify: Verify User does not exist error message.
        Assert.AssertPrimRecordNotFound();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeResourceUserIDNoTS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
    begin
        // Test case checks that Resource field Time Sheet Owner User ID can be changed
        Initialize();

        // 1. Create User ID, Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 2. Add new User ID
        if not UserSetup.Get(NewUserIDTok) then begin
            UserSetup."User ID" := NewUserIDTok;
            UserSetup.Insert();
        end;
        // 3. Modify Time Sheet Owner User ID field
        Resource.Validate("Time Sheet Owner User ID", NewUserIDTok);
        // 4. Check that Time Sheet Owner User ID was modified
        Assert.AreEqual(Resource."Time Sheet Owner User ID", NewUserIDTok, SameUserIDMessageErr);
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResourceLinkedWithUserID()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        ResourceNo: Text[30];
    begin
        // Test case checks that Resource cannot be linked with non-existent USER ID
        Initialize();

        // 1. Create User Setup (User ID)
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        // 4. Delete Resource
        ResourceNo := Resource."No.";
        Resource.Delete();

        Resource.Reset();
        Resource.SetRange("No.", ResourceNo);
        // 5. Check that Resource was deleted
        Assert.IsFalse(Resource.FindFirst(), ResourceIsNotDeletedErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResourceWithUseTimesheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Test case check that Resource with non-posted Timesheets cannot be deleted
        Initialize();

        // 1. Create User Setup, Resource, Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Try to Delete Resource
        asserterror Resource.Delete(true);
        // 3. Verify: Verify User cannot be deleted error message.
        Assert.ExpectedError(StrSubstNo(YouCannotDeleteResourceErr, Resource."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetFuncRemoveWithUseTS()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // Test case check that "Use Time Sheet" option cannot be unchecked when not posted Time Sheet exists
        Initialize();

        // 1. Create User Setup, Resource, Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Try to set Use Time Sheet = False (Turn off Time Sheet functionality for Resource)
        asserterror Resource.Validate("Use Time Sheet", false);
        // 3. Verify: Verify Field cannot be changed error message.
        Assert.IsTrue(StrPos(GetLastErrorText, UseTimeSheetCannotBeChangedErr) > 0, ErrorGeneratedIncorrectErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetForMultipleResource()
    var
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        Resource1: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Resource2: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Test case check creation of Time Sheets for multiple Resources
        Initialize();

        // 1. Create user setup (User ID1, User ID2)
        LibraryTimeSheet.CreateUserSetup(UserSetup1, false);
        LibraryTimeSheet.CreateUserSetup(UserSetup2, false);
        // 2. Create Resource 1 and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource1);
        SetupTSResourceUserID(Resource1, UserSetup1);
        // 3. Create Resource 2 and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource2);
        SetupTSResourceUserID(Resource2, UserSetup2);

        // 4. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // 5. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // 6. Create 1 Time Sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, StrSubstNo('%1|%2', Resource1."No.", Resource2."No."), false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();

        // 7. Verify that time sheet is created for both Resources
        TimeSheetHeader.SetRange("Resource No.", Resource1."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);
        TimeSheetHeader.SetRange("Resource No.", Resource2."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetResourceNoUseTS()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Test case checks that Time Sheets are not created for Resource with Use Time Sheet = false
        Initialize();

        // 1. Create user setup (User ID1)
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);

        // 2. Create Resource and setup Time Sheet functionality
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Set Use Time Sheet = false for Resource
        Resource.Validate("Use Time Sheet", false);
        Resource.Modify();

        // 4. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // 5. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // 6. Create Time sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // 7. Verify that time sheet is not created as Use Time Sheet = false for Resource
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsFalse(TimeSheetHeader.FindFirst(), 'Time sheet is created, but should not.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePeriodTimesheet()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
    begin
        // Test case checks that Time Sheets cannot be created twice for the same period
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create 1 extra time sheet for the same period
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 3. Verify that extra time sheet was not created
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.Count = 1, 'Time Sheet is not created');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetRandomFirstWeekDay()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        // Test case checks that if Time Sheet First Weekday = Any Day of week, created time sheets begin from the same day
        Initialize();

        // 1. Create User Setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        // 4. Set Time Sheet First Weekday = random day of week in Resources Setup
        ResourcesSetup.FindFirst();
        ResourcesSetup."Time Sheet First Weekday" := LibraryRandom.RandInt(6);
        ResourcesSetup.Modify();
        // 5. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 6. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 7. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 8. Verify time sheet was created and Start Date = First Weekday
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), TimeSheetDoesNotExistErr);
        Assert.IsTrue(
          Date2DWY(TimeSheetHeader."Starting Date", 1) = ResourcesSetup."Time Sheet First Weekday" + 1,
          'Time Sheet first weekday differs from Resources Setup');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetChangeFWeekDayError()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        TempInt1: Integer;
        TempInt2: Integer;
    begin
        // Test case checks error appears when trying to change Time Sheet First Weekday with already created Time Sheets
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        // 3. Setup Time Sheet functionality for Resource
        SetupTSResourceUserID(Resource, UserSetup);
        TempInt1 := LibraryRandom.RandInt(6);
        // 4. Set Time Sheet First Weekday = any day of week in Resources Setup
        ResourcesSetup.FindFirst();
        ResourcesSetup."Time Sheet First Weekday" := TempInt1;
        ResourcesSetup.Modify();
        // 5. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 6. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 7. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 8. Verify time sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
        // 9. Select another random day of week that differs from defined in setup
        repeat
            TempInt2 := LibraryRandom.RandInt(6);
        until TempInt2 <> TempInt1;
        // 10. Try to change Time Sheet First Weekday
        asserterror ResourcesSetup.Validate("Time Sheet First Weekday", TempInt2);
        // 11. check that correct error message appears
        Assert.IsTrue(StrPos(GetLastErrorText, FirstWeekDayCannotBeChangedErr) > 0, ErrorGeneratedIncorrectErr);

        TearDown();
    end;

#if not CLEAN22
    [Test]
    [HandlerFunctions('TimeSheetLineJobDetailHandler')]
    [Scope('OnPrem')]
    procedure TimesheetJobTaskLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. can be filled in lines
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job
        LibraryJob.CreateJob(Job);
        // 3. Set Person Responsible = created Resource
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();
        // 4. Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        // 5. Add Job Task Custom Description
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();
        // 6. Open Time Sheet and create Job type line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheet.Type.Value := GetTSLineTypeOption(TSLineType::Job);

        GlobalJobNo := Job."No.";
        GlobalJobTaskNo := JobTask."Job Task No.";
        TimeSheet.Description.AssistEdit();

        // 7. Validate Description, Job No., Job Task No. fields
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindLast();
        TimeSheetLine.TestField("Job No.", Job."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask."Job Task No.");
        TimeSheetLine.TestField(Description, JobTask.Description);

        TimeSheet.OK().Invoke();
        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetCheckLeapYear()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        TimeSheet: TestPage "Time Sheet";
        YearMod: Decimal;
        TempDate: Date;
        TempText: Text[30];
    begin
        // Test case checks that Days represented in one Timesheet for Leap Year are correct
        Initialize();

        // 1. Create User Setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find next leap year
        ResourcesSetup.Init();
        TempDate := WorkDate();
        repeat
            TempDate := CalcDate('<+1Y>', TempDate);
            YearMod := Date2DMY(TempDate, 3) mod 4;
        until YearMod = 0;
        TempDate := DMY2Date(29, 2, Date2DMY(TempDate, 3));
        Date.SetRange("Period Type", Date."Period Type"::Date);
        TempDate := CalcDate('<-6D>', TempDate);
        Date.SetFilter("Period Start", '%1..', TempDate);
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();
        // 4. Create 1 new Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 5. Open Time Sheet and create line of Resource Type
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        // 6. Verify Time Sheet table captions are correct
        TempDate := Date."Period Start";
        TempText := CopyStr(TimeSheet.Field1.Caption, 1, StrLen(TimeSheet.Field1.Caption) - 4);
        Assert.AreEqual(Format(Date2DMY(TempDate, 1)), TempText, DynamicDayCaptionIsNotCorrectErr);
        TempDate := CalcDate('<+1D>', TempDate);
        TempText := CopyStr(TimeSheet.Field2.Caption, 1, StrLen(TimeSheet.Field2.Caption) - 4);
        Assert.AreEqual(Format(Date2DMY(TempDate, 1)), TempText, DynamicDayCaptionIsNotCorrectErr);
        TempDate := CalcDate('<+1D>', TempDate);
        TempText := CopyStr(TimeSheet.Field3.Caption, 1, StrLen(TimeSheet.Field3.Caption) - 4);
        Assert.AreEqual(Format(Date2DMY(TempDate, 1)), TempText, DynamicDayCaptionIsNotCorrectErr);
        TempDate := CalcDate('<+1D>', TempDate);
        TempText := CopyStr(TimeSheet.Field4.Caption, 1, StrLen(TimeSheet.Field4.Caption) - 4);
        Assert.AreEqual(Format(Date2DMY(TempDate, 1)), TempText, DynamicDayCaptionIsNotCorrectErr);
        TempDate := CalcDate('<+1D>', TempDate);
        TempText := CopyStr(TimeSheet.Field5.Caption, 1, StrLen(TimeSheet.Field5.Caption) - 4);
        Assert.AreEqual(Format(Date2DMY(TempDate, 1)), TempText, DynamicDayCaptionIsNotCorrectErr);
        TempDate := CalcDate('<+1D>', TempDate);
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetResourceLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet Line with Type = Resource can be created
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and create Resource Type line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        // 3. Validate Description, Type fields
        TimeSheet.Type.AssertEquals(GetTSLineTypeOption(TSLineType::Resource));
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobTaskforResource()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. cannot be filled for line of Resource type
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job
        LibraryJob.CreateJob(Job);
        // 3. Set Person Responsible = created Resource
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();
        // 4. Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        // 5. Set custom Job Task Description
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();
        // 6. Open Time Sheet and add line with type Resource but fill Job No.
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetHeader."No.";
        asserterror TimeSheetLine.Validate("Job No.", Job."No.");
        // 7. Validate correct error message appeared
        Assert.ExpectedError(StrSubstNo(TypeMustBeEqualToJobErr, TimeSheetHeader."No."));

        TearDown();
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetLineEveryDayModify()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
        TimeSheet2: TestPage "Time Sheet";
        TimeSheet3: TestPage "Time Sheet";
    begin
        // Test case to check that values for Time distribution can be modified
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and add Time Sheet line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Reopen Time Sheet, check time allocation and modify time allocation
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet2);
        ValidateTimeAllocation(DayTimeAllocation, TimeSheet2);
        // to check trigger for zero value;
        DayTimeAllocation[3] := 0;
        GenerateTimeAllocation(DayTimeAllocation, TimeSheet2);
        TimeSheet2.Field3.Value := Format(DayTimeAllocation[3]);
        TimeSheet2.OK().Invoke();
        // 4. Reopen Time Sheet, validate changed values
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet3);
        ValidateTimeAllocation(DayTimeAllocation, TimeSheet3);
        TimeSheet3.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetSwitchBetween()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheet: TestPage "Time Sheet";
        DayTimeAllocation1: array[5] of Decimal;
        DayTimeAllocation2: array[5] of Decimal;
    begin
        // Test case to check that user can switch between Time Sheets directly from Time Sheet page
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        // 2. Create Time Sheets lines
        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 3. Add Time Sheet line
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        GenerateTimeAllocation(DayTimeAllocation1, TimeSheet);
        // 4. Press Next Period
        TimeSheet.NextPeriod.Invoke();
        // 5. Validate correct Time Sheet opened
        TimeSheetHeader.FindLast();
        Assert.AreEqual(TimeSheet.CurrTimeSheetNo.Value, TimeSheetHeader."No.", 'Time Sheet No. is not correct');
        // 6. Add Time Sheet Line
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        GenerateTimeAllocation(DayTimeAllocation2, TimeSheet);
        // 7. Press Previous Period
        TimeSheet.PreviousPeriod.Invoke();
        // 8. Verify values on different Time Sheet pages
        TimeSheetHeader.FindFirst();
        Assert.AreEqual(TimeSheet.CurrTimeSheetNo.Value, TimeSheetHeader."No.", 'Time Sheet No. is not correct');
        // 9. Validate time allocation values are correct
        ValidateTimeAllocation(DayTimeAllocation1, TimeSheet);
        // 10. Press Next Period
        TimeSheet.NextPeriod.Invoke();
        TimeSheetHeader.FindLast();
        Assert.AreEqual(TimeSheet.CurrTimeSheetNo.Value, TimeSheetHeader."No.", 'Time Sheet No. is not correct');
        // 11. Validate time allocation values are correct
        ValidateTimeAllocation(DayTimeAllocation2, TimeSheet);
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetModifySubmittedLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that user cannot modify sumbitted Time Sheet lines
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and fill Time allocation
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit Time Sheet
        TimeSheet.Submit.Invoke();
        // 4. Verify Time Sheet line values cannot be changed
        asserterror TimeSheet.Field1.Value := Format(GetRandomDecimal());
        Assert.ExpectedError(StrSubstNo(StatusMustBeOpenOrRejectedErr, TimeSheet.CurrTimeSheetNo.Value));
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetModifyApprovedLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet1: TestPage "Time Sheet";
        TimeSheetNo: Code[20];
    begin
        // Verify that Time Sheet line cannot be edited in Approved state
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and fill Time allocation
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit Time Sheet
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        TimeSheet.OK().Invoke();
        // 4. Open Manager Time Sheet and Validate correct Time Sheet opened
        ApproveTimeSheet(TimeSheetNo, 1);
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        // 6. Validate Manager Time Sheet line Status has been changed to 'Approved'
        Assert.AreEqual(GetTSLineStatusOption(3), ManagerTimeSheet.Status.Value, TimesheetLineStatusIncorrectErr);
        ManagerTimeSheet.OK().Invoke();
        // 7. Open created Time Sheet
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet1);
        // 8. Try to modify Time allocation for first day of week
        asserterror TimeSheet1.Field1.Value := Format(GetRandomDecimal());
        // 9. Expecting there was 'Status must not be Approved in Time Sheet Line ...' error message
        Assert.ExpectedError(StrSubstNo(StatusMustBeOpenOrRejectedErr, TimeSheet1.CurrTimeSheetNo.Value));
        TimeSheet1.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetSubmitLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that after Time Sheet line was submitted - status has changed
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and add line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit Time Sheet
        TimeSheet.Submit.Invoke();
        // 4. Validate Status = Submitted
        Assert.AreEqual(GetTSLineStatusOption(1), TimeSheet.Status.Value, StatusShouldBeSumbittedErr);
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetSubmitEmptyLine()
    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that line with non-distributed time cannot be submitted
        Initialize();

        // 0. Set Time Sheet Submission Policy = Stop and Show Empty Line Error
        if ResourcesSetup.Get() then
            if ResourcesSetup."Time Sheet Submission Policy" <> ResourcesSetup."Time Sheet Submission Policy"::"Stop and Show Empty Line Error" then begin
                ResourcesSetup."Time Sheet Submission Policy" := ResourcesSetup."Time Sheet Submission Policy"::"Stop and Show Empty Line Error";
                ResourcesSetup.Modify();
            end;

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Ppen Time Sheet and add line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        // 3. Submit Time Sheet
        asserterror TimeSheet.Submit.Invoke();
        // 4. Verify error message 'There is nothing to submit...'
        Assert.ExpectedError(StrSubstNo(ThereIsNothingToSubmitErr, TimeSheet.CurrTimeSheetNo.Value));

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetSubmitReopenLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that after Time Sheet line was submitted, user can Reopen it
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and create line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit Time Sheet
        TimeSheet.Submit.Invoke();
        // 4. Reopen Time Sheet
        TimeSheet.Reopen.Invoke();
        // 5. Validate Status = Open value
        Assert.AreEqual(GetTSLineStatusOption(0), TimeSheet.Status.Value, StatusShouldBeOpenErr);
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('TimeSheetLineResDetailHndl,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerValidateFields()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TempDate: Date;
        TimeSheetNo: Code[20];
    begin
        // Verify that after Time Sheet line was submitted all the fields values are the same in Manager Time Sheet
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and fill the fields
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        GlobalTextVariable := TimeSheetNo + Format(GetRandomDecimal());
        TimeSheet.Description.AssistEdit();

        TimeSheet.Submit.Invoke();
        // 4. Open Manager Time Sheet and Validate common fields
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        Assert.AreEqual(TimeSheetHeader."No.", ManagerTimeSheet.CurrTimeSheetNo.Value,
          'Time Sheet No. field is incorrect');
        Assert.AreEqual(TimeSheetHeader."Resource No.", ManagerTimeSheet.ResourceNo.Value,
          'Time Sheet Resource No. field is incorrect');
        Evaluate(TempDate, ManagerTimeSheet.StartingDate.Value);
        Assert.AreEqual(TimeSheetHeader."Starting Date", TempDate, 'Time Sheet Starting Date field is incorrect');
        Evaluate(TempDate, ManagerTimeSheet.EndingDate.Value);
        Assert.AreEqual(TimeSheetHeader."Ending Date", TempDate, 'Time Sheet Ending Date field is incorrect');
        Assert.AreEqual(GlobalTextVariable, ManagerTimeSheet.Description.Value,
          'Time Sheet line Description is incorrect');
        Assert.AreEqual(TimeSheet.Status.Value, ManagerTimeSheet.Status.Value,
          TimesheetLineTypeIsIncorrectErr);
        Assert.AreEqual(TimeSheet.Field1.Value, ManagerTimeSheet.Field1.Value,
          'Time Sheet line field value is incorrect');
        Assert.AreEqual(TimeSheet.Field2.Value, ManagerTimeSheet.Field2.Value,
          'Time Sheet line field value is incorrect');
        Assert.AreEqual(TimeSheet.Field3.Value, ManagerTimeSheet.Field3.Value,
          'Time Sheet line field value is incorrect');
        Assert.AreEqual(TimeSheet.Field4.Value, ManagerTimeSheet.Field4.Value,
          'Time Sheet line field value is incorrect');
        Assert.AreEqual(TimeSheet.Field5.Value, ManagerTimeSheet.Field5.Value,
          'Time Sheet line field value is incorrect');

        ManagerTimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerRejectLines()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet1: TestPage "Time Sheet";
        TimeSheetNo: Code[20];
    begin
        // Verify that Time Sheet line can be Rejected from Manager Time Sheet
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and create line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        TimeSheet.OK().Invoke();
        // 4. Open Manager Time Sheet and Reject Time Sheet
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        Assert.AreEqual(TimeSheetHeader."No.", ManagerTimeSheet.CurrTimeSheetNo.Value,
          'Time Sheet No. is incorrect');
        ManagerTimeSheet.Reject.Invoke();
        Assert.AreEqual(GetTSLineStatusOption(2), ManagerTimeSheet.Status.Value, TimesheetLineStatusIncorrectErr);
        ManagerTimeSheet.OK().Invoke();
        // 5. Open Time Sheet
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet1);
        // 6. Validate that Time Sheet line Status has been changed to 'Rejected'
        Assert.AreEqual(GetTSLineStatusOption(2), TimeSheet1.Status.Value, TimesheetLineStatusIncorrectErr);
        TimeSheet1.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerApproveLines()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet1: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet line can be Approved from Manager Time Sheet, validate Time Sheet page line status
        Initialize();

        // 1. Create User Setup, Resource, Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Open Manager Time Sheet
        ApproveTimeSheet(TimeSheetHeader."No.", 1);
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        // 3. Validate Manager Time Sheet line Status has been changed to 'Approved'
        Assert.AreEqual(GetTSLineStatusOption(3), ManagerTimeSheet.Status.Value, TimesheetLineStatusIncorrectErr);
        ManagerTimeSheet.OK().Invoke();
        // 4. Open Time Sheet
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet1);
        // 5.Validate Time Sheet line Status has been changed to 'Approved'
        Assert.AreEqual(GetTSLineStatusOption(3), TimeSheet1.Status.Value, TimesheetLineStatusIncorrectErr);
        TimeSheet1.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerApproveReopen()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet line can be Reopened from Manager Time Sheet, validate Time Sheet page line status
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Open Manager Time Sheet
        ApproveTimeSheet(TimeSheetHeader."No.", 1);
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        Assert.AreEqual(GetTSLineStatusOption(3), ManagerTimeSheet.Status.Value, TimesheetLineTypeIsIncorrectErr);
        // 3. Reopen
        ManagerTimeSheet.Reopen.Invoke();
        // 4. Validate that Manager Time Sheet line Status has been changed to 'Submitted'
        Assert.AreEqual(GetTSLineStatusOption(1), ManagerTimeSheet.Status.Value, TimesheetLineTypeIsIncorrectErr);
        ManagerTimeSheet.OK().Invoke();
        // 5. Open Time Sheet
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 6. Validate that Time Sheet line Status has been changed to 'Submitted'
        Assert.AreEqual(GetTSLineStatusOption(1), TimeSheet.Status.Value, TimesheetLineTypeIsIncorrectErr);
        TimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetManagerSwitchBetween()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheet: TestPage "Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet1No: Code[20];
        TimeSheet2No: Code[20];
        DayTimeAllocation1: array[5] of Decimal;
        DayTimeAllocation2: array[5] of Decimal;
        TimeSheetNo: Code[20];
    begin
        // Test case to check that user can switch between Time Sheets directly from Manager Time Sheet page
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        TimeSheetHeader.FindFirst();
        TimeSheet1No := TimeSheetHeader."No.";
        TimeSheetHeader.FindLast();
        TimeSheet2No := TimeSheetHeader."No.";
        // 2. Open Time Sheet 1 and fill line
        TimeSheet.OpenEdit();
        TimeSheet.CurrTimeSheetNo.Value := TimeSheet1No;
        TimeSheet.ResourceNo.AssertEquals(Resource."No.");
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        GenerateTimeAllocation(DayTimeAllocation1, TimeSheet);
        // 8. Switch to Next Time Sheet and fill lines
        TimeSheet.NextPeriod.Invoke();
        TimeSheetHeader.FindLast();
        Assert.AreEqual(TimeSheet2No, TimeSheet.CurrTimeSheetNo.Value, 'Time Sheet No. is not correct');
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        GenerateTimeAllocation(DayTimeAllocation2, TimeSheet);
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.OK().Invoke();
        // 9. Open Manager Time Sheet
        ManagerTimeSheet.OpenEdit();
        // 10. Switch to Previous Period Time Sheet and Validate values
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        ManagerTimeSheet.PreviousPeriod.Invoke();
        Assert.AreEqual(TimeSheet1No, ManagerTimeSheet.CurrTimeSheetNo.Value,
          'Time Sheet No. is incorrect');
        ValidateManagerTimeAllocation(DayTimeAllocation1, ManagerTimeSheet);
        // 11. Switch to Next Period Time Sheet and Validate values
        ManagerTimeSheet.NextPeriod.Invoke();
        Assert.AreEqual(TimeSheet2No, ManagerTimeSheet.CurrTimeSheetNo.Value,
          'Time Sheet No. is incorrect');
        ValidateManagerTimeAllocation(DayTimeAllocation2, ManagerTimeSheet);
        ManagerTimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerDeclineApprove()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet line can be Rejected, then Submitted and approved
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        TimeSheetApprovalMgt.ReopenApproved(TimeSheetLine);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 2. Open Manager Time Sheet, Reject
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        ManagerTimeSheet.Reject.Invoke();
        ManagerTimeSheet.OK().Invoke();
        // 3. Open Time Sheet and Submit again
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheet.Submit.Invoke();
        TimeSheet.OK().Invoke();
        // 4. Open Manager Time Sheet, approve and validate 'Approved' status
        ApproveTimeSheet(TimeSheetHeader."No.", 1);
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        Assert.AreEqual(GetTSLineStatusOption(3), ManagerTimeSheet.Status.Value, TimesheetLineStatusIncorrectErr);
        ManagerTimeSheet.OK().Invoke();

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetResourcePosting()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
    begin
        // Verify that Approved Time Sheet line with Type = Resource can be suggested to Resource Journal
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        // 5. Clean Resource Journal and run Suggest Lines from Time Sheet batch Job
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 6. Validate Resource Journal lines and values
        ValidateResourceJournal(TimeSheetHeader."Starting Date", DayTimeAllocation, Resource, 5);

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetResourceSuggestByDate()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResJnlLine: Record "Res. Journal Line";
        TimeSheet: TestPage "Time Sheet";
        TimeSheetNo: Code[20];
    begin
        // Verify that Approved Time Sheet line with Type = Resource can be suggested to Resource Journal,
        // filtering by Date
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and create Time Sheet line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Submit
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        // 4. Open Manager Time Sheet and Approve line
        ApproveTimeSheet(TimeSheetNo, 1);
        // 5. Clean Resource Journal and run Suggest Lines from Time Sheet batch Job -
        // Ending Date = Time Sheet."Ending Date" - 5 days
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader,
          CalcDate('<-5D>', TimeSheetHeader."Ending Date"));
        // 6. Validate Resource Journal lines and values
        ValidateResourceJournal(TimeSheetHeader."Starting Date", DayTimeAllocation, Resource, 2);
        // 7. Validate lines not included in Suggest Lines job filter are not created
        ResJnlLine.Reset();
        ResJnlLine.SetFilter(Quantity, Format(DayTimeAllocation[3]));
        Assert.IsFalse(ResJnlLine.FindSet(), 'This line should not be suggested');
        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetResMultipleSuggest()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        ResJnlLine: Record "Res. Journal Line";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheet: TestPage "Time Sheet";
        DayTimeAllocation1: array[11] of Decimal;
        DayTimeAllocation2: array[5] of Decimal;
        Counter: Integer;
    begin
        // Verify that Approved Time Sheets with can be suggested to Resource Journal,
        // Multiple Time Sheets
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        // 2. Open Time Sheet and add Time Sheet line with time allocation
        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        GenerateTimeAllocation2(DayTimeAllocation1, TimeSheetHeader, TimeSheetLine);
        // 3. Submit
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheet.Submit.Invoke();
        // 4. Switch to Next Time Sheet and add Time Sheet line with time allocation
        TimeSheet.NextPeriod.Invoke();
        TimeSheetHeader.FindLast();
        Assert.AreEqual(TimeSheet.CurrTimeSheetNo.Value, TimeSheetHeader."No.", 'Time Sheet No. is not correct');
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        GenerateTimeAllocation(DayTimeAllocation2, TimeSheet);
        // 5. Submit
        TimeSheet.Submit.Invoke();
        TimeSheet.OK().Invoke();
        // 6. Approve both Time Sheets
        ApproveTimeSheet(TimeSheetHeader."No.", 1);
        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        ApproveTimeSheet(TimeSheetHeader."No.", 1);

        // 7. Delete all exisiting Resource Journal lines
        PrepareResourceJournal(ResJnlLine);
        // 8. Create resource journal lines based on approved time sheet line
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader,
          CalcDate('<+10D>', TimeSheetHeader."Starting Date"));

        for Counter := 1 to 4 do
            DayTimeAllocation1[Counter + 7] := DayTimeAllocation2[Counter];

        // 9. Validate lines and fields values for both Time Sheets
        ValidateResourceJournalLines(TimeSheetHeader."Starting Date", DayTimeAllocation1, Resource, 11);
        // 10. Validate that line out of period was not created
        ResJnlLine.Reset();
        ResJnlLine.SetFilter(Quantity, Format(DayTimeAllocation2[5]));
        Assert.IsFalse(ResJnlLine.FindSet(), 'This line should not be suggested');

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetResPartApproved()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        ResJnlLine: Record "Res. Journal Line";
        TimeSheet: TestPage "Time Sheet";
        TempDate: Date;
        TempDayAllocation: array[2] of Decimal;
        TimeSheetNo: Code[20];
    begin
        // Verify that Approved Time Sheets can be suggested to Resource Journal,
        // Partialy approved
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        // 2. Open Time Sheet and add line
        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);

        TempDayAllocation[1] := GetRandomDecimal();
        TimeSheet.Field1.Value := Format(TempDayAllocation[1]);
        // 3. Submit
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();

        // 4. Open next period Time Sheet and add line
        TimeSheet.NextPeriod.Invoke();
        TimeSheetHeader.FindLast();
        Assert.AreEqual(TimeSheet.CurrTimeSheetNo.Value, TimeSheetHeader."No.", 'Time Sheet No. is not correct');
        TimeSheet.New();
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        TempDayAllocation[2] := GetRandomDecimal();
        TimeSheet.Field1.Value := Format(TempDayAllocation[2]);
        TimeSheet.Submit.Invoke();

        // 5. Open Manager Time Sheet and Approve line
        ApproveTimeSheet(TimeSheetNo, 1);

        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        // 6. Create resource journal lines based on approved time sheet line
        TempDate := TimeSheetHeader."Starting Date";
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader,
          CalcDate('<+10D>', TimeSheetHeader."Starting Date"));
        // 7. Set Filter to show only one line and Validate that
        ResJnlLine.Reset();
        ResJnlLine.SetFilter(Quantity, Format(TempDayAllocation[1]));
        ResJnlLine.FindFirst();
        Assert.AreEqual(TempDate, ResJnlLine."Posting Date", IncorrectPostingDateErr);
        Assert.AreEqual(Resource."Unit Price" * TempDayAllocation[1],
          ResJnlLine."Total Price", IncorrectCostValueErr);
        ResJnlLine.Reset();
        ResJnlLine.SetFilter(Quantity, Format(DayTimeAllocation[3]));
        Assert.IsFalse(ResJnlLine.FindSet(), 'This line should not be suggested');
        TearDown();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobPosting()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Job1: Record Job;
        JobTask1: Record "Job Task";
        Job2: Record Job;
        JobTask2: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        TempDec1: Decimal;
        TempDec2: Decimal;
    begin
        // Verify that approved Job Time Sheet lines are correctly suggested for Multiple Jobs

        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job, Job Task, Job Planning Lines
        CreateJobPlanning(Resource, Job1, JobTask1, Date);
        CreateJobPlanning(Resource, Job2, JobTask2, Date);

        // 3. create and approve 2 Job type lines
        TempDec1 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job1."No.", JobTask1."Job Task No.", TimeSheetHeader."Starting Date", TempDec1);

        TempDec2 := GetRandomDecimal();
        CreateJobTSLineApprove(TimeSheetHeader, Job2."No.", JobTask2."Job Task No.", TimeSheetHeader."Starting Date", TempDec2);

        // 5. Open Job Journal and suggest lines from Time Sheet
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, StrSubstNo('%1|%2', Job1."No.", Job2."No."),
          StrSubstNo('%1|%2', JobTask1."Job Task No.", JobTask2."Job Task No."));
        // 6. Validate Lines for Job 1
        ValidateJobJournal(TimeSheetHeader, JobTask1, TempDec1);
        ValidateJobJournal(TimeSheetHeader, JobTask2, TempDec2);
        TearDown();
    end;

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure FactBoxActivityDetails()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheet: TestPage "Time Sheet";
        TimeSheet1: TestPage "Time Sheet";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        PageFieldValue: Decimal;
        SumFieldValue: Decimal;
        TempDec: array[4] of Decimal;
        TimeSheetNo: Code[20];
    begin
        // Verify that Time Sheet page Activity FactBox shows correct values
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 1);
        // 2. Open Time Sheet and add line, which will be submitted
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        TempDec[1] := CreateCustomTimeSheetLine(TimeSheet, TSLineType::Resource, 'To submit');
        // 3. Submit
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        // 4. Open Time Sheet and add line, which will be rejected later
        TempDec[2] := CreateCustomTimeSheetLine(TimeSheet, TSLineType::Resource, 'To Reject');
        // 5. Submit
        TimeSheet.Submit.Invoke();
        // 6. Open Time Sheet and add line, which will be approved later
        TempDec[3] := CreateCustomTimeSheetLine(TimeSheet, TSLineType::Resource, 'To Approve');
        // 7. Submit
        TimeSheet.Submit.Invoke();
        // 8. Open Time Sheet and add line, which will stay opened
        TempDec[4] := CreateCustomTimeSheetLine(TimeSheet, TSLineType::Resource, 'To be Opened');
        TimeSheet.OK().Invoke();
        // 9. Open Manager Time Sheet
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        ManagerTimeSheet.FILTER.SetFilter(Description, 'To Reject');
        // 10. Reject line
        ManagerTimeSheet.Reject.Invoke();
        ManagerTimeSheet.FILTER.SetFilter(Description, 'To Approve');
        // 11. Approve line
        ManagerTimeSheet.Approve.Invoke();
        ManagerTimeSheet.OK().Invoke();
        // 12. Open Time Sheet page and validate field values of Fact box
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet1);
        Evaluate(PageFieldValue, TimeSheet1.TimeSheetStatusFactBox.OpenQty.Value);
        SumFieldValue := PageFieldValue;
        Assert.AreEqual(TempDec[4], PageFieldValue, 'Open field has wrong value');
        Evaluate(PageFieldValue, TimeSheet1.TimeSheetStatusFactBox.SubmittedQty.Value);
        SumFieldValue := SumFieldValue + PageFieldValue;
        Assert.AreEqual(TempDec[1], PageFieldValue, 'Submitted field has wrong value');
        Evaluate(PageFieldValue, TimeSheet1.TimeSheetStatusFactBox.RejectedQty.Value);
        SumFieldValue := SumFieldValue + PageFieldValue;
        Assert.AreEqual(TempDec[2], PageFieldValue, 'Rejected field has wrong value');
        Evaluate(PageFieldValue, TimeSheet1.TimeSheetStatusFactBox.ApprovedQty.Value);
        SumFieldValue := SumFieldValue + PageFieldValue;
        Assert.AreEqual(TempDec[3], PageFieldValue, 'Approved field has wrong value');
        Evaluate(PageFieldValue, TimeSheet1.TimeSheetStatusFactBox.TotalQuantity.Value);
        Assert.AreEqual(SumFieldValue, PageFieldValue, 'Total field has wrong value');
        TimeSheet1.OK().Invoke();

        TearDown();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetAbsenceWOutEmployee()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        CauseOfAbsence: Record "Cause of Absence";
    begin
        // Verify that Time Sheet line with Type Absence cannot be created when no Employee is linked with Resource
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create new Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find random Cause of Absence
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        // 4. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 5. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 6. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 7. Try to create line with Cause of Absence Code
        asserterror
          LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '', CauseOfAbsence.Code);
        Assert.ExpectedError(StrSubstNo(ThereIsNoEmployeeLinkedWithResErr, TimeSheetHeader."Resource No."));

        TearDown();
    end;

#if not CLEAN22
    [Test]
    [HandlerFunctions('TimeSheetLineAbsDetailHndl')]
    [Scope('OnPrem')]
    procedure TimesheetAbsenceApprovePost()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
        Employee: Record Employee;
        CauseOfAbsence: Record "Cause of Absence";
        EmployeeAbsence: Record "Employee Absence";
        TimeSheet: TestPage "Time Sheet";
        DayTimeAllocation: array[7] of Decimal;
        Counter: Integer;
        TempDate: Date;
    begin
        // Verify that Time Sheet line with Type Absence can be posted. Validate fields.
        Initialize();

        // 1. Create User Setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 4. Create new Employee
        LibraryHumanResource.CreateEmployee(Employee);
        // 5. Find random Cause of Absence
        FindCauseOfAbsence(CauseOfAbsence);
        // 6. Link Resource to Employee
        Employee.Validate("Resource No.", Resource."No.");
        Employee.Modify();
        // 7. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 8. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 9. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 10. Open Time Sheet and create Absence type line

        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '', CauseOfAbsence.Code);
        GenerateTimeAllocation2(DayTimeAllocation, TimeSheetHeader, TimeSheetLine);
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        GlobalTextVariable := CauseOfAbsence.Code;
        TimeSheet.Description.AssistEdit();

        // 11. Submit and approve
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        TempDate := CalcDate('<-1D>', Date."Period Start");
        // 12. Open Employee Absences and validate all lines created
        EmployeeAbsence.Reset();
        EmployeeAbsence.SetRange("Employee No.", Employee."No.");
        for Counter := 1 to 7 do begin
            TempDate := CalcDate('<+1D>', TempDate);
            EmployeeAbsence.SetFilter("From Date", Format(TempDate));
            EmployeeAbsence.FindFirst();
            Assert.AreEqual(CauseOfAbsence.Code, EmployeeAbsence."Cause of Absence Code",
              'Employee Absences incorrect Cause of Absence Code');
            Assert.AreEqual(CauseOfAbsence.Description, EmployeeAbsence.Description, 'Employee Absences incorrect Description');
            Assert.AreEqual(DayTimeAllocation[Counter], EmployeeAbsence.Quantity, 'Employee Absences incorrect Quantity');
            Assert.AreEqual(Resource."Base Unit of Measure", EmployeeAbsence."Unit of Measure Code",
              'Employee Absences incorrect Unit of Measure Code');
        end;

        TearDown();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimesheetJobPlanningReport()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        ResourcesSetup: Record "Resources Setup";
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. are suggested by report if option Create lines from Job Planning is On
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 4. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 5. Create Job, Job Task and Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 6. Create time sheet
        CreateTimeSheets.InitParameters(Date."Period Start", 1, Resource."No.", true, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // 7. Validate Time Sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
        // 8. Validate that lines were successfully suggested by report with correct Job No./Job Task No.
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindLast();
        TimeSheetLine.TestField(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.TestField("Job No.", Job."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask."Job Task No.");

        TearDown();
    end;

#if not CLEAN22
    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimesheetJobPlanningTSPage()
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
        AccountingPeriod: Record "Accounting Period";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        ResourcesSetup: Record "Resources Setup";
        TimeSheet: TestPage "Time Sheet";
    begin
        // Verify that Time Sheet fields Job No./Job Task No. are suggested by report if option Create lines from Job Planning is On
        Initialize();

        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 4. find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 5. Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 6. Create 1 Time Sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
        // 7. Open Time Sheet and create Job type line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 8. Run CreateLinesFromJobPlanning action
        TimeSheet.CreateLinesFromJobPlanning.Invoke();
        // 9. Validate that lines were successfully suggested by report with correct Job No./Job Task No.
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindLast();
        TimeSheetLine.TestField(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.TestField("Job No.", Job."No.");
        TimeSheetLine.TestField("Job Task No.", JobTask."Job Task No.");

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('TSArchiveHandlMSG,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimesheetMoveToArchive()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        ResJnlLine: Record "Res. Journal Line";
        MoveTimeSheetsToArchive: Report "Move Time Sheets to Archive";
        TimeSheet: TestPage "Time Sheet";
        DayTimeAllocation1: array[7] of Decimal;
        DayTimeAllocation2: array[7] of Decimal;
        TimeSheet1No: Code[20];
        TimeSheetStartingDate: Date;
        TimeSheetNo: Code[20];
    begin
        // Test case to check that Time Sheet can be moved to Archive
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 3. Remember values
        TimeSheet1No := TimeSheetHeader."No.";
        TimeSheetStartingDate := TimeSheetHeader."Starting Date";
        // 4. Create Time Sheets lines
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        // 5. Add Time Sheet line with Type = Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        GenerateTimeAllocation2(DayTimeAllocation1, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // 6. Add Time Sheet line with Type = Job
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        GenerateTimeAllocation2(DayTimeAllocation2, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        // 8. Suggest Job Journal Lines
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, Job."No.", JobTask."Job Task No.");
        // 9. Post Job Journal Lines
        PostJobJournal(JobJnlLine, TimeSheetHeader);
        // 10. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 11. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 12. Move Time Sheets to Archive
        TimeSheetHeader.SetRange("No.", TimeSheetNo);
        MoveTimeSheetsToArchive.SetTableView(TimeSheetHeader);
        MoveTimeSheetsToArchive.UseRequestPage(false);
        MoveTimeSheetsToArchive.Run();
        // 13. Validate Time Sheet Archive fields values
        TimeSheetHeaderArchive.Get(TimeSheet1No);
        TimeSheetHeaderArchive.TestField("Starting Date", TimeSheetStartingDate);
        TimeSheetHeaderArchive.TestField("Ending Date", CalcDate('<+6d>', TimeSheetStartingDate));
        TimeSheetHeaderArchive.TestField("Resource No.", Resource."No.");

        TimeSheetLineArchive.SetRange("Time Sheet No.", TimeSheetHeaderArchive."No.");
        TimeSheetLineArchive.FindSet();
        TimeSheetLineArchive.TestField(Type, TimeSheetLineArchive.Type::Resource);
        ValidateArchiveTimeAllocation(DayTimeAllocation1, TimeSheetHeaderArchive, TimeSheetLineArchive);

        TimeSheetLineArchive.Next();
        TimeSheetLineArchive.TestField(Type, TimeSheetLineArchive.Type::Job);
        TimeSheetLineArchive.TestField("Job No.", Job."No.");
        TimeSheetLineArchive.TestField("Job Task No.", JobTask."Job Task No.");
        ValidateArchiveTimeAllocation(DayTimeAllocation2, TimeSheetHeaderArchive, TimeSheetLineArchive);

        // 14. Check that Time Sheet moved to Archive no longer exist
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("No.", TimeSheet1No);
        Assert.IsFalse(TimeSheetHeader.FindSet(), 'Time Sheet Header exist but it should not');

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetModifyAfterPost()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResJnlLine: Record "Res. Journal Line";
        TimeSheet: TestPage "Time Sheet";
        TimeSheetNo: Code[20];
    begin
        // Test case to check that Time Sheet cannot be modified after posting lines
        Initialize();


        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Time Sheets lines
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 3. Add Time Sheet line with Type = Resource
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 4. Submit Time Sheet
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        TimeSheet.Close();
        // 5. Approve Time Sheet
        ApproveTimeSheet(TimeSheetNo, 1);
        // 6. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 7. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 8. Try to Modify Time Sheet line and Validate Error message
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        asserterror TimeSheet.Field1.Value := Format(GetRandomDecimal());
        Assert.ExpectedError(StrSubstNo(StatusMustBeOpenOrRejectedErr, TimeSheetHeader."No."));

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimesheetResourceDimCheck()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        ResJnlLine: Record "Res. Journal Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
        TimeSheet: TestPage "Time Sheet";
        DimensionSetID: Integer;
        Counter: Integer;
        TimeSheetNo: Code[20];
    begin
        // Test case to check that suggested Resource Journal line has Dimension the same as for Resource Card
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Dimension and Dimension Value for Resource
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionResource(DefaultDimension, Resource."No.", Dimension.Code, DimensionValue.Code);
        // 3. Create Time Sheets lines
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 4. Add Time Sheet line with Type = Resource
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 5. Submit Time Sheet
        TimeSheetNo := TimeSheet.CurrTimeSheetNo.Value();
        TimeSheet.Submit.Invoke();
        // 6. Approve Time Sheet
        ApproveTimeSheet(TimeSheetNo, 1);
        // 7. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 8. Verify Resource Journal Lines have Dimension Code and Dimension value the same as for Resource
        ResJnlLine.Reset();
        ResJnlLine.SetRange("Resource No.", Resource."No.");
        for Counter := 1 to 5 do begin
            ResJnlLine.Next();
            DimensionSetID := ResJnlLine."Dimension Set ID";
            VerifyDimInJournalDimSet(Dimension.Code, DimensionValue.Code, DimensionSetID);
        end;
        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('JobDimHandlMSG')]
    [Scope('OnPrem')]
    procedure TimesheetJobDimensionCheck()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        LibraryDimension: Codeunit "Library - Dimension";
        TimeSheet: TestPage "Time Sheet";
        DimensionSetID: Integer;
    begin
        // Test case to check that suggested Job Journal line has Dimension the same as for Job Card
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Dimension and Dimension Value for Resource
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        // 3. Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.",
          Dimension.Code, DimensionValue.Code);
        // 4. Create Time Sheets lines
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        // 5. Add Time Sheet line with Type = Job
        AddJobTimeSheetLine(TimeSheetHeader, Job, JobTask);
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindFirst();
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // 8. Suggest Resource Journal Lines
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, Job."No.", JobTask."Job Task No.");
        // 9. Verify Job Journal Lines have Dimension Code and Dimension value the same as for Job
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        JobJnlLine.FindFirst();
        DimensionSetID := JobJnlLine."Dimension Set ID";
        VerifyDimInJournalDimSet(Dimension.Code, DimensionValue.Code, DimensionSetID);
        TearDown();
    end;
#endif

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimesheetPostedStatus()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJnlLine: Record "Job Journal Line";
        ResJnlLine: Record "Res. Journal Line";
        DayTimeAllocation1: array[7] of Decimal;
        DayTimeAllocation2: array[7] of Decimal;
    begin
        // Test case to check that Time Sheet line after posting has Posted = True value
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 3. Add Time Sheet line with Type = Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Description := Format(CreateGuid());
        TimeSheetLine.Modify();
        GenerateTimeAllocation2(DayTimeAllocation1, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // 4. Add Time Sheet line with Type = Job
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        GenerateTimeAllocation2(DayTimeAllocation2, TimeSheetHeader, TimeSheetLine);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        // 5. Suggest Job Journal Lines
        SuggestJobJournalLines(JobJnlLine, TimeSheetHeader, Job."No.", JobTask."Job Task No.");
        // 6. Post Job Journal Lines
        PostJobJournal(JobJnlLine, TimeSheetHeader);
        // 7. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 8. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 9. Validate both Time Sheet lines have Posted = True
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindSet();
        repeat
            TimeSheetLine.TestField(Posted, true);
        until TimeSheetLine.Next() = 0;

        TearDown();
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetActualScheduledSummary()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheet: TestPage "Time Sheet";
        DayTimeAllocation1: array[7] of Decimal;
        DayTimeAllocation2: array[7] of Decimal;
        DayTimeAllocationSched: array[7] of Decimal;
    begin
        // Test case to check Period Summary Fact box in Time Sheet page
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2.1 Create Job, Job Task, Job Planning lines
        CreateJobPlanning(Resource, Job, JobTask, Date);
        // 2.2 Generate Resource Capacity values for 5 days, beginning from Time Sheet 1st day
        GenerateResourceCapacity(Resource, Date."Period Start", 5, DayTimeAllocationSched);
        // 3. Add Time Sheet line with Type = Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        GenerateTimeAllocation2(DayTimeAllocation1, TimeSheetHeader, TimeSheetLine);

        // 4. Add Time Sheet line with Type = Job
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        GenerateTimeAllocation2(DayTimeAllocation2, TimeSheetHeader, TimeSheetLine);
        // 5. Validate values on Period Summary FactBox
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        ValidateActualSchedSummaryFactBox(TimeSheet, DayTimeAllocation1, DayTimeAllocation2, DayTimeAllocationSched);
        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [HandlerFunctions('TimeSheetAllocationHandler')]
    [Scope('OnPrem')]
    procedure TimesheetTimeAllocationPage()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Date: Record Date;
        ResJnlLine: Record "Res. Journal Line";
        TimeSheetPage: TestPage "Time Sheet";
        DayTimeAllocation: array[7] of Decimal;
    begin
        // Test case to check that Time Sheet line after posting has Posted = True value
        Initialize();

        // 1. Create Resource and 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 3. Add Time Sheet line with Type = Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        GenerateTimeAllocation2(DayTimeAllocation, TimeSheetHeader, TimeSheetLine);
        // 4. Submit and Approve
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
        // 7. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 8. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 9. Open Time Sheet and Time Sheet Allocation page
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheetPage);
        TimeSheetPage."Time Sheet Allocation".Invoke();
        // 10. Validate values on Time Sheet Allocation page
        ValidateTSAllocationPageValues(DayTimeAllocation);
        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetOpenFromTSList()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheet: TestPage "Time Sheet";
        TimeSheetList: TestPage "Time Sheet List";
    begin
        // Test case to check that user can switch between Time Sheets directly from Time Sheet page
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        // 6. Open Time Sheet List page
        TimeSheetList.OpenView();
        // 7. Set filter to only one Time Sheet
        TimeSheetList.FILTER.SetFilter("No.", TimeSheetHeader."No.");
        TimeSheet.Trap();
        // 8. Run Edit Time Sheet
        TimeSheetList.EditTimeSheet.Invoke();
        // 9. Validate Correct Time Sheet was opened
        Assert.AreEqual(TimeSheetHeader."No.", TimeSheet.CurrTimeSheetNo.Value, IncorrectTimeSheetNoOpenedErr);

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetOpenFromList()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        ManagerTimeSheetList: TestPage "Manager Time Sheet List";
        Counter: Integer;
    begin
        // Test case to check that user can switch between Time Sheets directly from Manager Time Sheet page
        Initialize();

        // 1. Create Resource and 2 Time Sheets
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        // 2. Generate Line for both Time Sheets
        FindFirstTimeSheet(TimeSheetHeader, Resource."No.");
        for Counter := 1 to 2 do begin
            LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
            GenerateTimeAllocation2(DayTimeAllocation, TimeSheetHeader, TimeSheetLine);
            TimeSheetApprovalMgt.Submit(TimeSheetLine);
            TimeSheetHeader.Next();
        end;
        // 3. Open Manager Time Sheet from Manager Time Sheet List
        ManagerTimeSheetList.OpenView();
        ManagerTimeSheetList.FILTER.SetFilter("No.", TimeSheetHeader."No.");
        ManagerTimeSheet.Trap();
        ManagerTimeSheetList."&Edit Time Sheet".Invoke();
        // 4. Validate opened Manager Time Sheet list No. is correct
        Assert.AreEqual(TimeSheetHeader."No.", ManagerTimeSheet.CurrTimeSheetNo.Value, IncorrectTimeSheetNoOpenedErr);

        TearDown();
    end;
#endif

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimesheetTimeAllocModify()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
    begin
        // Test case to check that values for Time distribution can be modified
        Initialize();

        // 1. Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // 2. Open Time Sheet and add Time Sheet line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, true);
        // 3. Modify Time Sheet Allocation for Random day
        DayTimeAllocation[3] := GetRandomDecimal();
        TimeSheet.Field3.Value := Format(DayTimeAllocation[3]);
        TimeSheet.Close();
        // 4. Reopen Time Sheet, validate changed values
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        ValidateTimeAllocation(DayTimeAllocation, TimeSheet);
        TimeSheet.Close();

        TearDown();
    end;
#endif

    [Test]
    [HandlerFunctions('TimeSheetPostingEntryHandler')]
    [Scope('OnPrem')]
    procedure TimesheetPostingEntriesValidate()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
    begin
        // Test case to validate Posting Entries page values
        Initialize();

        Clear(GlobalTimeSheetNo);
        // 1. Create Time Sheet with Resource Type Line
        LibraryTimeSheet.InitResourceScenario(TimeSheetHeader, TimeSheetLine, true);
        Resource.Get(TimeSheetHeader."Resource No.");
        GlobalTimeSheetNo := TimeSheetHeader."No.";
        // 6. Suggest Resource Journal Lines
        SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
        // 7. Post Resource Journal lines
        PostResourceJournal(ResJnlLine, TimeSheetHeader);
        // 8. Open Posting Entries page from Manager Time Sheet and validate values
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := GlobalTimeSheetNo;
        ManagerTimeSheet."Posting E&ntries".Invoke();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('TSArchiveHandlMSG,TimeSheetPostingEntryHandler')]
    [Scope('OnPrem')]
    procedure TimesheetManagerArchivePage()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ResJnlLine: Record "Res. Journal Line";
        MoveTimeSheetsToArchive: Report "Move Time Sheets to Archive";
        ManagerTimeSheetArchive: TestPage "Manager Time Sheet Archive";
        ManagerTSArchiveList: TestPage "Manager Time Sheet Arc. List";
        TimeSheet2No: Code[20];
        Counter: Integer;
    begin
        // Test case to check that Manager can overview archived Time Sheets
        Initialize();

        // 1. Create Resource and 2 Time Sheets, Submit, Approve, Suggest and post Resource Lines
        CreateMultipleTimeSheet(Resource, TimeSheetHeader, 2);
        GlobalTimeSheetNo := TimeSheetHeader."No.";
        for Counter := 1 to 2 do begin
            LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
            GenerateTimeAllocation2(DayTimeAllocation, TimeSheetHeader, TimeSheetLine);
            TimeSheetApprovalMgt.Submit(TimeSheetLine);
            TimeSheetApprovalMgt.Approve(TimeSheetLine);
            ResJnlLine.Reset();
            SuggestResourceJnlLines(ResJnlLine, TimeSheetHeader, TimeSheetHeader."Ending Date");
            PostResourceJournal(ResJnlLine, TimeSheetHeader);
            TimeSheetHeader.Next();
        end;
        TimeSheet2No := TimeSheetHeader."No.";
        // 2. Move Time Sheets to Archive
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        MoveTimeSheetsToArchive.SetTableView(TimeSheetHeader);
        MoveTimeSheetsToArchive.UseRequestPage(false);
        MoveTimeSheetsToArchive.Run();
        // 3. Open Manager Time Sheet Archive List, then open Manager Time Sheet and validate No.
        ManagerTSArchiveList.OpenView();
        ManagerTSArchiveList.FILTER.SetFilter("No.", GlobalTimeSheetNo);
        ManagerTimeSheetArchive.Trap();
        ManagerTSArchiveList."&View Time Sheet".Invoke();
        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, GlobalTimeSheetNo, IncorrectTSArchiveNoOpenedErr);
        // 4. Validate Previous/Next Period works correctly
        ManagerTimeSheetArchive.CurrTimeSheetNo.Value := GlobalTimeSheetNo;
        ManagerTimeSheetArchive."&Next Period".Invoke();

        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, TimeSheet2No, IncorrectTSArchiveNoOpenedErr);
        ManagerTimeSheetArchive."&Previous Period".Invoke();
        Assert.AreEqual(ManagerTimeSheetArchive.CurrTimeSheetNo.Value, GlobalTimeSheetNo, IncorrectTSArchiveNoOpenedErr);
        // 5. Open Posting Entries and validate
        ManagerTimeSheetArchive."Posting E&ntries".Invoke();
        TearDown();
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetDetailNotCreatedForZeroDayAmount()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        TimeSheet: TestPage "Time Sheet";
        TimeAllocation: array[5] of Decimal;
    begin
        // [SCENARIO 360297] Check Time Sheet Detail Lines are not created for columns(dates) with zero value
        Initialize();

        // [GIVEN] Time Sheet Document
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        AddTimeSheetLine(TSLineType::Resource, TimeSheet, false);
        // [WHEN] User set values in columns(dates) of zero/non-zero values on Time Sheet Page
        TimeAllocation[1] := LibraryRandom.RandInt(8);
        TimeAllocation[2] := 0;
        TimeAllocation[3] := LibraryRandom.RandInt(8);
        TimeAllocation[4] := 0;
        TimeAllocation[5] := LibraryRandom.RandInt(8);

        AssignTimeSheetDayValues(TimeSheet, TimeAllocation);
        TimeSheet.OK().Invoke();
        // [THEN] Time Sheet Detail Lines are not generated for dates with zero values in columns
        VerifyTimeSheetDetailLinesCount(TimeSheetHeader."No.", 3);

        TearDown();
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetVerifyMyTimeSheetsCurrentUserTSOwner()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        InitialRecordCount: Integer;
        PostRecordCount: Integer;
    begin
        // Verify that Time Sheet fields Job No./Job Task No. can be filled in lines
        Initialize();


        // [GIVEN] Get a record count of My Time Sheets for current user before creating a timesheet
        InitialRecordCount := GetMyTimeSheetRecordCount();

        // [WHEN] User setup, Resource, and 1 Time Sheet created with current user
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Record count for current user has increased by 1.
        Assert.AreEqual(PostRecordCount, InitialRecordCount + 1, 'Count of MyTimeSheet records should have increased.');

        // [WHEN] Time Sheet Header is deleted
        TimeSheetHeader.Delete(true);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Number of records is back to what it was when test was started
        Assert.AreEqual(PostRecordCount, InitialRecordCount, 'Count of MyTimeSheet records is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TimeSheetVerifyMyTimeSheetsNoTSOwner()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        InitialRecordCount: Integer;
        PostRecordCount: Integer;
    begin
        // Verify that Time Sheet fields Job No./Job Task No. can be filled in lines
        Initialize();


        // [GIVEN] Get a record count of My Time Sheets for current user before creating a timesheet
        InitialRecordCount := GetMyTimeSheetRecordCount();

        // [WHEN] User setup, Resource, and 1 Time Sheet created with non-current user
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, false);
        Commit();
        PostRecordCount := GetMyTimeSheetRecordCount();

        // [THEN] Same number of records exist for current user after creating the timesheet
        Assert.AreEqual(PostRecordCount, InitialRecordCount, 'Count of MyTimeSheet records should still be the same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AssignHumanResourceUOMForCauseOfAbsence()
    var
        CauseOfAbsence: Record "Cause of Absence";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        // [FEATURE] [UT] [Employee] [Unit of Measure]
        // [SCENARIO 382310] Stan can assign "Human Resource Unit of Measure" in "Cause of Absense"

        Initialize();
        LibraryTimeSheet.CreateHRUnitOfMeasure(HumanResourceUnitOfMeasure, 1);
        CauseOfAbsence.Init();
        CauseOfAbsence.Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);

        CauseOfAbsence.TestField("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ErrorWhenAssignNormalUOMForCauseOfAbsence()
    var
        CauseOfAbsence: Record "Cause of Absence";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [UT] [Employee] [Unit of Measure]
        // [SCENARIO 382310] Stan cannot assign normal "Unit of Measure" in "Cause of Absense"

        Initialize();
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CauseOfAbsence.Init();
        asserterror CauseOfAbsence.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        Assert.ExpectedError(StrSubstNo(IncorrectHRUnitOfMeasureTableRelationErr, UnitOfMeasure.Code));
    end;

#if not CLEAN22
    [Test]
    [HandlerFunctions('ValidateTimeSheetLineJobDetailHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobWithStatusCompletedNotShowingInTimeSheetJobNoList()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        Date: Record Date;
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
        TimeSheet: TestPage "Time Sheet";
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 439193] It is possible to select a Job in the Time Sheet even if the status of the Job is completed.
        Initialize();

        // [GIVEN] Create User setup, Resource, 1 Time Sheet
        GenerateResourceTimeSheet(Resource, Date, TimeSheetHeader, true);
        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);
        // [GIVEN] Set Person Responsible = created Resource
        Job.Validate("Person Responsible", Resource."No.");
        Job.Modify();
        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Add Job Task Custom Description
        JobTask.Validate(Description, 'Job Task Description Test');
        JobTask.Modify();

        // [THEN] Update the Job Status to Completed.
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard.Status.SetValue(Job.Status::Completed);
        JobCard.Close();

        // [GIVEN] Open TimeSheet and create Job type line
        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TimeSheet.Type.Value := GetTSLineTypeOption(TSLineType::Job);

        GlobalJobNo := Job."No.";
        GlobalJobTaskNo := JobTask."Job Task No.";
        // [VERIFY] Open TimeSheet LineJob Detail page and validate the Completed job.
        TimeSheet.Description.AssistEdit();

        TearDown();
    end;
#endif

    local procedure FindResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJournalTemplate);
        LibraryResource.FindResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
    end;

    local procedure SetupTSResourceUserID(var Resource: Record Resource; UserSetup: Record "User Setup")
    begin
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID");
        Resource.Modify();
    end;

    local procedure TimeSheetCreate(Date: Date; NoOfPeriods: Integer; var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header")
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        // Create time sheet
        CreateTimeSheets.InitParameters(Date, NoOfPeriods, Resource."No.", false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
        // Validate Time Sheet was created
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);
    end;

    [Normal]
    local procedure ValidateTimeSheetCreated(var TimeSheetHeader: Record "Time Sheet Header"; Resource: Record Resource)
    begin
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetFilter("Resource No.", Resource."No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst(), 'Time Sheet is not created');
    end;

    local procedure FindFirstDOW(AccountingPeriod: Record "Accounting Period"; var Date: Record Date; var ResourcesSetup: Record "Resources Setup")
    begin
        // find first DOW after accounting period starting date
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", '%1..', AccountingPeriod."Starting Date");
        Date.SetRange("Period No.", ResourcesSetup."Time Sheet First Weekday" + 1);
        Date.FindFirst();
    end;

    local procedure FindJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        JobJournalTemplate.SetRange(Recurring, false);
        LibraryTimeSheet.FindJobJournalTemplate(JobJournalTemplate);
        LibraryTimeSheet.FindJobJournalBatch(JobJournalBatch, JobJournalTemplate.Name);
    end;

#if not CLEAN22
    local procedure GenerateTimeAllocation(var DayTimeAllocation: array[5] of Decimal; var TimeSheet: TestPage "Time Sheet")
    var
        Counter: Integer;
    begin
        for Counter := 1 to 5 do
            DayTimeAllocation[Counter] := GetRandomDecimal();

        AssignTimeSheetDayValues(TimeSheet, DayTimeAllocation);
    end;
#endif

    local procedure GenerateTimeAllocation2(var DayTimeAllocation: array[7] of Decimal; TimeSheetHeader: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line")
    var
        Counter: Integer;
    begin
        for Counter := 1 to 7 do begin
            DayTimeAllocation[Counter] := GetRandomDecimal();
            LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date" + Counter - 1, DayTimeAllocation[Counter]);
        end;
    end;

#if not CLEAN22
    local procedure ValidateTimeAllocation(DayTimeAllocation: array[5] of Decimal; var TimeSheet: TestPage "Time Sheet")
    var
        PageFieldValue: Decimal;
    begin
        Evaluate(PageFieldValue, TimeSheet.Field1.Value);
        Assert.AreEqual(DayTimeAllocation[1], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, TimeSheet.Field2.Value);
        Assert.AreEqual(DayTimeAllocation[2], PageFieldValue, TimesheetDetailValueIncorrectErr);
        if TimeSheet.Field3.Value <> '' then begin
            Evaluate(PageFieldValue, TimeSheet.Field3.Value);
            Assert.AreEqual(DayTimeAllocation[3], PageFieldValue, TimesheetDetailValueIncorrectErr);
        end;
        Evaluate(PageFieldValue, TimeSheet.Field4.Value);
        Assert.AreEqual(DayTimeAllocation[4], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, TimeSheet.Field5.Value);
        Assert.AreEqual(DayTimeAllocation[5], PageFieldValue, TimesheetDetailValueIncorrectErr);
    end;
#endif

    local procedure ValidateManagerTimeAllocation(DayTimeAllocation: array[5] of Decimal; var ManagerTimeSheet: TestPage "Manager Time Sheet")
    var
        PageFieldValue: Decimal;
    begin
        Evaluate(PageFieldValue, ManagerTimeSheet.Field1.Value);
        Assert.AreEqual(DayTimeAllocation[1], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, ManagerTimeSheet.Field2.Value);
        Assert.AreEqual(DayTimeAllocation[2], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, ManagerTimeSheet.Field3.Value);
        Assert.AreEqual(DayTimeAllocation[3], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, ManagerTimeSheet.Field4.Value);
        Assert.AreEqual(DayTimeAllocation[4], PageFieldValue, TimesheetDetailValueIncorrectErr);
        Evaluate(PageFieldValue, ManagerTimeSheet.Field5.Value);
        Assert.AreEqual(DayTimeAllocation[5], PageFieldValue, TimesheetDetailValueIncorrectErr);
    end;

    local procedure ValidateArchiveTimeAllocation(DayTimeAllocation: array[5] of Decimal; TimeSheetHeaderArchive: Record "Time Sheet Header Archive"; TimeSheetLineArchive: Record "Time Sheet Line Archive")
    var
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        i: Integer;
    begin
        for i := 1 to 5 do begin
            TimeSheetDetailArchive.Get(
              TimeSheetHeaderArchive."No.", TimeSheetLineArchive."Line No.", TimeSheetHeaderArchive."Starting Date" + i - 1);
            TimeSheetDetailArchive.TestField(Quantity, DayTimeAllocation[i]);
        end;
    end;

    local procedure ValidateCostPrice(Resource: Record Resource; DayAllocation: Decimal; ResJournalLine: Record "Res. Journal Line")
    begin
        Assert.AreEqual(Resource."Direct Unit Cost", ResJournalLine."Direct Unit Cost",
          IncorrectCostValueErr);
        Assert.AreEqual(Resource."Unit Cost", ResJournalLine."Unit Cost",
          IncorrectCostValueErr);
        Assert.AreEqual(Resource."Unit Cost" * DayAllocation,
          ResJournalLine."Total Cost", IncorrectCostValueErr);
        Assert.AreEqual(Resource."Unit Price",
          ResJournalLine."Unit Price", IncorrectCostValueErr);
        Assert.AreEqual(Resource."Unit Price" * DayAllocation,
          ResJournalLine."Total Price", IncorrectCostValueErr);
    end;

    local procedure GetOptionValue(OptionString: Text[1024]; OptionNumber: Integer): Text[250]
    var
        I: Integer;
    begin
        for I := 1 to OptionNumber do
            OptionString := DelStr(OptionString, 1, StrPos(OptionString, ','));

        if StrPos(OptionString, ',') = 0 then
            exit(OptionString);

        exit(CopyStr(OptionString, 1, StrPos(OptionString, ',') - 1));
    end;

    local procedure OptionValueToText(InputInteger: Integer; OptionString: Text[1024]) OutputText: Text[250]
    begin
        if (InputInteger >= 0) and (InputInteger <= GetOptionsQuantity(OptionString)) then begin
            OutputText := GetOptionValue(OptionString, InputInteger);
            if StrPos(OutputText, '-') <> 0 then
                OutputText := CopyStr(OutputText, 1, StrPos(OutputText, '-') - 1);
        end;
    end;

    local procedure GetOptionsQuantity(OptionString: Text[1024]): Integer
    var
        Counter: Integer;
        CommaPosition: Integer;
    begin
        if StrPos(OptionString, ',') = 0 then
            exit(0);

        repeat
            CommaPosition := StrPos(OptionString, ',');
            OptionString := DelStr(OptionString, 1, CommaPosition);
            Counter := Counter + 1;
        until CommaPosition = 0;

        exit(Counter - 1);
    end;

    local procedure GetTSLineTypeOption(TimeSheetLineOption: Integer) OptionText: Text[250]
    var
        FieldRef: FieldRef;
    begin
        RecRef.Close();
        RecRef.Open(DATABASE::"Time Sheet Line");
        FieldRef := RecRef.Field(5);
        OptionText := OptionValueToText(TimeSheetLineOption, FieldRef.OptionCaption);
    end;

    local procedure GetTSLineStatusOption(TimeSheetLineOption: Integer) OptionText: Text[250]
    var
        FieldRef: FieldRef;
    begin
        RecRef.Close();
        RecRef.Open(DATABASE::"Time Sheet Line");
        FieldRef := RecRef.Field(20);
        OptionText := OptionValueToText(TimeSheetLineOption, FieldRef.OptionCaption);
    end;

    local procedure FindCauseOfAbsence(var CauseOfAbsence: Record "Cause of Absence")
    var
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
    begin
        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        with CauseOfAbsence do
            if "Unit of Measure Code" = '' then begin
                HumanResourceUnitOfMeasure.FindFirst();
                Validate("Unit of Measure Code", HumanResourceUnitOfMeasure.Code);
                Modify(true);
            end;
    end;

#if not CLEAN22
    local procedure TimeSheetPageOpen(Resource: Record Resource; TimeSheetHeader: Record "Time Sheet Header"; var TimeSheet: TestPage "Time Sheet")
    begin
        TimeSheet.OpenEdit();
        TimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        TimeSheet.ResourceNo.AssertEquals(Resource."No.");
    end;
#endif

    local procedure GenerateResourceTimeSheet(var Resource: Record Resource; var Date: Record Date; var TimeSheetHeader: Record "Time Sheet Header"; CurrentUser: Boolean)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        ResourcesSetup: Record "Resources Setup";
    begin
        // create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, CurrentUser);
        // Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);

        // find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);

        // find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);

        // create time sheet
        TimeSheetCreate(Date."Period Start", 1, Resource, TimeSheetHeader);
    end;

    local procedure SuggestResourceJnlLines(var ResJnlLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; EndDate: Date)
    var
        SuggestResJnlLines: Report "Suggest Res. Jnl. Lines";
    begin
        PrepareResourceJournal(ResJnlLine);
        SuggestResJnlLines.InitParameters(
          ResJnlLine,
          TimeSheetHeader."Resource No.",
          TimeSheetHeader."Starting Date",
          EndDate);
        SuggestResJnlLines.UseRequestPage(false);
        SuggestResJnlLines.Run();
    end;

    local procedure PrepareResourceJournal(var ResJnlLine: Record "Res. Journal Line")
    var
        ResJnlBatch: Record "Res. Journal Batch";
    begin
        // Empty Resource Journal Line table
        FindResourceJournalBatch(ResJnlBatch);
        ResJnlLine.Reset();
        ResJnlLine.DeleteAll();

        ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
        ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
    end;

#if not CLEAN22
    local procedure ValidateResourceJournal(Date: Date; DayTimeAllocation: array[5] of Decimal; Resource: Record Resource; ExtCount: Integer)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ResJournalLine: Record "Res. Journal Line";
        TimeSheet: TestPage "Time Sheet";
        Counter: Integer;
        TempDate: Date;
    begin
        // Set Filter to show only one line and validate fields
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);

        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TempDate := CalcDate('<-1D>', Date);
        for Counter := 1 to ExtCount do begin
            ResJournalLine.Reset();
            ResJournalLine.SetFilter(Quantity, Format(DayTimeAllocation[Counter]));
            if ResJournalLine.FindFirst() then begin
                TempDate := CalcDate('<+1D>', TempDate);
                Assert.AreEqual(TempDate, ResJournalLine."Posting Date", IncorrectPostingDateErr);
                Assert.AreEqual(ResJournalLine."Entry Type"::Usage, ResJournalLine."Entry Type", IncorrectEntryTypeErr);
                Assert.AreEqual(TimeSheetHeader."Resource No.", ResJournalLine."Resource No.", IncorrectUserIDErr);
                ValidateCostPrice(Resource, DayTimeAllocation[Counter], ResJournalLine);
            end
        end;
    end;
#endif

#if not CLEAN22
    local procedure ValidateResourceJournalLines(Date: Date; DayTimeAllocation: array[5] of Decimal; Resource: Record Resource; ExtCount: Integer)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ResJournalLine: Record "Res. Journal Line";
        TimeSheet: TestPage "Time Sheet";
        Counter: Integer;
        TempDate: Date;
    begin
        // Set Filter to show only one line and validate fields
        ValidateTimeSheetCreated(TimeSheetHeader, Resource);

        TimeSheetPageOpen(Resource, TimeSheetHeader, TimeSheet);
        TempDate := CalcDate('<-1D>', Date);

        ResJournalLine.SetRange("Resource No.", Resource."No.");
        ResJournalLine.FindSet();

        for Counter := 1 to ExtCount do begin
            TempDate := CalcDate('<+1D>', TempDate);
            ResJournalLine.TestField(Quantity, DayTimeAllocation[Counter]);
            Assert.AreEqual(TempDate, ResJournalLine."Posting Date", IncorrectPostingDateErr);
            Assert.AreEqual(ResJournalLine."Entry Type"::Usage, ResJournalLine."Entry Type", IncorrectEntryTypeErr);
            Assert.AreEqual(TimeSheetHeader."Resource No.", ResJournalLine."Resource No.", IncorrectUserIDErr);
            ValidateCostPrice(Resource, DayTimeAllocation[Counter], ResJournalLine);

            ResJournalLine.Next();
        end;
    end;
#endif

    local procedure PostResourceJournal(ResJnlLine: Record "Res. Journal Line"; TimeSheetHeader: Record "Time Sheet Header")
    var
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        // find and post created journal lines
        ResJnlLine.Reset();
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
        ResJnlLine.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        Assert.IsTrue(ResJnlLine.FindSet(), 'Resource journal lines have not been found');
        Clear(ResJnlPostLine);
        repeat
            ResJnlPostLine.Run(ResJnlLine);
        until ResJnlLine.Next() = 0;
    end;

    local procedure CreateJobPlanning(Resource: Record Resource; var Job: Record Job; var JobTask: Record "Job Task"; Date: Record Date)
    var
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
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
        JobPlanningLine.Quantity := GetRandomDecimal();
        JobPlanningLine."Unit Cost" := GetRandomDecimal();
        JobPlanningLine.Insert();
    end;

    local procedure SuggestJobJournalLines(var JobJnlLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; JobNo: Text[30]; JobTaskNo: Text[30])
    var
        SuggestJobJnlLines: Report "Suggest Job Jnl. Lines";
    begin
        PrepareJobJournal(JobJnlLine);
        SuggestJobJnlLines.InitParameters(
          JobJnlLine,
          TimeSheetHeader."Resource No.",
          JobNo,
          JobTaskNo,
          TimeSheetHeader."Starting Date",
          TimeSheetHeader."Ending Date");
        SuggestJobJnlLines.UseRequestPage(false);
        SuggestJobJnlLines.Run();
    end;

    local procedure PrepareJobJournal(var JobJnlLine: Record "Job Journal Line")
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlLine.Reset();
        JobJnlLine.DeleteAll();

        FindJobJournalBatch(JobJnlBatch);
        JobJnlLine."Journal Template Name" := JobJnlBatch."Journal Template Name";
        JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;
    end;

    local procedure ValidateJobJournal(TimeSheetHeader: Record "Time Sheet Header"; JobTask: Record "Job Task"; Qty: Decimal)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.Reset();
        JobJournalLine.SetFilter("Time Sheet No.", TimeSheetHeader."No.");
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Resource);
        JobJournalLine.SetRange("No.", TimeSheetHeader."Resource No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.IsTrue(JobJournalLine.FindFirst(), StrSubstNo('Job journal line %1 is not found', JobJournalLine.GetFilters));
        Assert.AreEqual(Qty, JobJournalLine.Quantity, 'Incorrect Quantity field value');
    end;

    local procedure PostJobJournal(JobJnlLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header")
    var
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        // find and post created journal lines
        JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetRange(Type, JobJnlLine.Type::Resource);
        JobJnlLine.SetRange("No.", TimeSheetHeader."Resource No.");
        Assert.IsTrue(JobJnlLine.FindSet(), 'Job journal lines have not been found');
        Clear(JobJnlPostLine);
        repeat
            JobJnlPostLine.Run(JobJnlLine);
        until JobJnlLine.Next() = 0;
    end;

#if not CLEAN22
    local procedure AddTimeSheetLine(LineType: Integer; var TimeSheet: TestPage "Time Sheet"; GenerateTimeAlloc: Boolean)
    begin
        TimeSheet.Type.Value := GetTSLineTypeOption(LineType);
        TimeSheet.Description.Value := 'Time Sheet Line Description';
        if GenerateTimeAlloc then
            GenerateTimeAllocation(DayTimeAllocation, TimeSheet);
    end;
#endif

    local procedure AddJobTimeSheetLine(TimeSheetHeader: Record "Time Sheet Header"; Job: Record Job; JobTask: Record "Job Task"): Decimal
    var
        TimeSheetLine: Record "Time Sheet Line";
        TempDec: Decimal;
    begin
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.", JobTask."Job Task No.", '', '');
        TempDec := GetRandomDecimal();
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", TempDec);
        exit(TempDec);
    end;

    local procedure GetRandomDecimal(): Decimal
    begin
        exit(LibraryRandom.RandInt(9999) / 100);
    end;

    local procedure ApproveTimeSheet(TimeSheetNo: Code[20]; "Count": Integer)
    var
        ManagerTimeSheet: TestPage "Manager Time Sheet";
        Counter: Integer;
        FilterValue: Text[250];
    begin
        // This function opens Manager Time and approves number of lines defined as parameter.
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetNo;
        for Counter := 1 to Count do begin
            FilterValue := StrSubstNo('%1|%2', GetTSLineStatusOption(1), GetTSLineStatusOption(2));
            ManagerTimeSheet.FILTER.SetFilter(Status, FilterValue);
            ManagerTimeSheet.Approve.Invoke();
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TSArchiveHandlMSG(Message: Text[1024])
    begin
        if StrPos(Message, StrSubstNo(TimeSheetsHaveBeenMovedtoArchErr, 1)) < 0 then
            Assert.Fail(CopyStr('Incorrect message: ' + Message, 1, MaxStrLen(Message)));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure JobDimHandlMSG(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, YouHaveChangedADimensionMsg) > 0,
          StrPos(Message, DoYouWantToUpdateTheLinesQst) > 0:
                Reply := true;
            else
                Assert.Fail(CopyStr('Incorrect confirm question: ' + Message, 1, MaxStrLen(Message)));
        end;
    end;

    local procedure VerifyDimInJournalDimSet(ShortcutDimCode: Code[20]; ShortcutDimValueCode: Code[20]; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionSetEntry."Dimension Value Code", ShortcutDimValueCode,
          'Wrong Dimension value on gen. Jnl. line dimension');
    end;

#if not CLEAN22
    local procedure ValidateActualSchedSummaryFactBox(TimeSheet: TestPage "Time Sheet"; DayTimeAllocation1: array[5] of Decimal; DayTimeAllocation2: array[5] of Decimal; DayTimeAllocationSched: array[5] of Decimal)
    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        Assert.AreEqual(
          TimeSheetMgt.FormatActualSched(DayTimeAllocation1[1] + DayTimeAllocation2[1], DayTimeAllocationSched[1]),
          Format(TimeSheet.ActualSchedSummaryFactBox.FirstDaySummary),
          'Incorrect Period Summary day value');
        Assert.AreEqual(
          TimeSheetMgt.FormatActualSched(DayTimeAllocation1[2] + DayTimeAllocation2[2], DayTimeAllocationSched[2]),
          Format(TimeSheet.ActualSchedSummaryFactBox.SecondDaySummary),
          'Incorrect Period Summary day value');
        Assert.AreEqual(
          TimeSheetMgt.FormatActualSched(DayTimeAllocation1[3] + DayTimeAllocation2[3], DayTimeAllocationSched[3]),
          Format(TimeSheet.ActualSchedSummaryFactBox.ThirdDaySummary),
          'Incorrect Period Summary day value');
        Assert.AreEqual(
          TimeSheetMgt.FormatActualSched(DayTimeAllocation1[4] + DayTimeAllocation2[4], DayTimeAllocationSched[4]),
          Format(TimeSheet.ActualSchedSummaryFactBox.ForthDaySummary),
          'Incorrect Period Summary day value');
        Assert.AreEqual(
          TimeSheetMgt.FormatActualSched(DayTimeAllocation1[5] + DayTimeAllocation2[5], DayTimeAllocationSched[5]),
          Format(TimeSheet.ActualSchedSummaryFactBox.FifthDaySummary),
          'Incorrect Period Summary day value');
    end;
#endif

#if not CLEAN22
    local procedure CreateCustomTimeSheetLine(TimeSheet: TestPage "Time Sheet"; TypeValue: Integer; Description: Text[30]): Decimal
    var
        TempDec: Decimal;
    begin
        TimeSheet.FILTER.SetFilter(Status, GetTSLineStatusOption(0));
        TimeSheet.Type.Value := GetTSLineTypeOption(TypeValue);
        TimeSheet.Description.Value := Description;
        TempDec := GetRandomDecimal();
        TimeSheet.Field1.Value := Format(TempDec);
        exit(TempDec);
    end;
#endif

    local procedure GenerateResourceCapacity(Resource: Record Resource; PeriodStart: Date; DaysToGenerate: Integer; var GenerateAllocation: array[14] of Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        Counter: Integer;
        NextEntryNo: Integer;
    begin
        ResCapacityEntry.Reset();
        ResCapacityEntry.FindLast();
        NextEntryNo := ResCapacityEntry."Entry No.";
        for Counter := 1 to DaysToGenerate do begin
            NextEntryNo := NextEntryNo + 1;
            ResCapacityEntry.Init();
            ResCapacityEntry."Entry No." := NextEntryNo;
            ResCapacityEntry."Resource No." := Resource."No.";
            ResCapacityEntry.Date := PeriodStart;
            ResCapacityEntry.Capacity := LibraryRandom.RandInt(800) / 100;
            ResCapacityEntry.Insert();
            GenerateAllocation[Counter] := ResCapacityEntry.Capacity;
            PeriodStart := CalcDate('<+1D>', PeriodStart);
        end;
    end;

    local procedure FindFirstTimeSheet(var TimeSheetHeader: Record "Time Sheet Header"; ResourceNo: Code[20])
    begin
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        TimeSheetHeader.FindFirst();
    end;

#if not CLEAN22
    local procedure AssignTimeSheetDayValues(var TimeSheet: TestPage "Time Sheet"; TimeAllocation: array[5] of Decimal)
    begin
        TimeSheet.Field1.Value := Format(TimeAllocation[1]);
        TimeSheet.Field2.Value := Format(TimeAllocation[2]);
        TimeSheet.Field3.Value := Format(TimeAllocation[3]);
        TimeSheet.Field4.Value := Format(TimeAllocation[4]);
        TimeSheet.Field5.Value := Format(TimeAllocation[5]);
    end;
#endif

    local procedure VerifyTimeSheetDetailLinesCount(TimeSheetHeaderNo: Code[20]; NoOfLines: Integer)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        // Verify No of Time Sheet Detail Lines
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        Assert.AreEqual(NoOfLines, TimeSheetDetail.Count, StrSubstNo(LineCountErr, TimeSheetDetail.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        TimeSheetLineJobDetail."Job No.".Value := GlobalJobNo;
        TimeSheetLineJobDetail."Job Task No.".Value := GlobalJobTaskNo;
        TimeSheetLineJobDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ValidateTimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        asserterror TimeSheetLineJobDetail."Job No.".Value := GlobalJobNo;
        TimeSheetLineJobDetail.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetAllocationHandler(var TimeSheetAllocation: TestPage "Time Sheet Allocation")
    begin
        // Handles Time Sheet Allocation page and fills Global values for verification
        Evaluate(GlobalTSAllocationValues[1], TimeSheetAllocation.TotalQty.Value);
        Evaluate(GlobalTSAllocationValues[2], TimeSheetAllocation.AllocatedQty.Value);
        Evaluate(GlobalTSAllocationValues[3], TimeSheetAllocation.DateQuantity1.Value);
        Evaluate(GlobalTSAllocationValues[4], TimeSheetAllocation.DateQuantity2.Value);
        Evaluate(GlobalTSAllocationValues[5], TimeSheetAllocation.DateQuantity3.Value);
        Evaluate(GlobalTSAllocationValues[6], TimeSheetAllocation.DateQuantity4.Value);
        Evaluate(GlobalTSAllocationValues[7], TimeSheetAllocation.DateQuantity5.Value);
        Evaluate(GlobalTSAllocationValues[8], TimeSheetAllocation.DateQuantity6.Value);
        Evaluate(GlobalTSAllocationValues[9], TimeSheetAllocation.DateQuantity7.Value);
        TimeSheetAllocation.OK().Invoke();
    end;

    local procedure ValidateTSAllocationPageValues(DayTimeAllocation: array[7] of Decimal)
    var
        Counter: Integer;
        "Sum": Decimal;
    begin
        Clear(Sum);
        for Counter := 1 to 7 do begin
            Assert.AreEqual(DayTimeAllocation[Counter], GlobalTSAllocationValues[Counter + 2], IncorrectAllocationQuantityErr);
            Sum := Sum + DayTimeAllocation[Counter];
        end;
        Assert.AreEqual(Sum, GlobalTSAllocationValues[1], IncorrectAllocationQuantityErr);
        Assert.AreEqual(Sum, GlobalTSAllocationValues[2], IncorrectAllocationQuantityErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetPostingEntryHandler(var TSPostingEntriesPage: TestPage "Time Sheet Posting Entries")
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
        Navigate: TestPage Navigate;
        TempDecimal: Decimal;
    begin
        // Handles Time Sheet Allocation page and validates
        TimeSheetPostingEntry.Reset();
        TimeSheetPostingEntry.SetRange("Time Sheet No.", GlobalTimeSheetNo);
        TimeSheetPostingEntry.FindFirst();
        Evaluate(TempDecimal, TSPostingEntriesPage.Quantity.Value);
        Assert.AreEqual(GlobalTimeSheetNo, Format(TSPostingEntriesPage."Time Sheet No.".Value), IncorrectPostingEntryOpenedErr);
        Assert.AreEqual(TimeSheetPostingEntry.Quantity, TempDecimal, IncorrectPostingEntryQuantityErr);
        // Validate Navigate can be opened from the page
        Navigate.Trap();
        TSPostingEntriesPage."&Navigate".Invoke();
        Navigate.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineResDetailHndl(var TimeSheetLineResDetail: TestPage "Time Sheet Line Res. Detail")
    begin
        TimeSheetLineResDetail.Description.Value := GlobalTextVariable;
        TimeSheetLineResDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineAbsDetailHndl(var TimeSheetLineAbsDetail: TestPage "Time Sheet Line Absence Detail")
    begin
        TimeSheetLineAbsDetail.Description.Value := GlobalTextVariable;
        TimeSheetLineAbsDetail.OK().Invoke();
    end;

    local procedure CreateJobTSLineApprove(TimeSheetHeader: Record "Time Sheet Header"; JobNo: Code[20]; JobTaskNo: Code[20]; Date: Date; Qty: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, JobNo, JobTaskNo, '', '');
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, Date, Qty);
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);
    end;

    local procedure CreateMultipleTimeSheet(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; NoOfTimeSheets: Integer)
    var
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
        ResourcesSetup: Record "Resources Setup";
    begin
        // 1. Create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        // 2. Create Resource
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        SetupTSResourceUserID(Resource, UserSetup);
        // 3. Find first open accounting period
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        // 4. Find first DOW after accounting period starting date
        FindFirstDOW(AccountingPeriod, Date, ResourcesSetup);
        // 5. Create 2 Time Sheets
        TimeSheetCreate(Date."Period Start", NoOfTimeSheets, Resource, TimeSheetHeader);
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [HandlerFunctions('NavigateHandler')]
    [Scope('OnPrem')]
    procedure NavigateHandler(var Navigate: TestPage Navigate)
    begin
        // Handles Navigate Page
        Navigate.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure GetMyTimeSheetRecordCount(): Integer
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.SetRange("User ID", UserId);
        exit(MyTimeSheets.Count);
    end;
}

