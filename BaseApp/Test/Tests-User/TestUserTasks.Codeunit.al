codeunit 134769 "Test User Tasks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User Tasks]
        Init;
    end;

    var
        User1: Record User;
        User2: Record User;
        UserTaskGroup1: Record "User Task Group";
        UserTaskGroupMember: Record "User Task Group Member";
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestUserCard()
    var
        UserTaskCard: TestPage "User Task Card";
        BaseDate: DateTime;
    begin
        // [SCENARIO] Test the User Task Card page.

        // [GIVEN] The User Tasks Card page.
        // [WHEN] The Page opens.
        // [THEN] Various fields are defaulted.
        BaseDate := CreateDateTime(20121212D, 000000T);
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard.Title.Value('Task 1');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime, 'Start DateTime should be 0DT');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Created DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Created DateTime');
        Assert.AreEqual('', UserTaskCard.MultiLineTextControl.Value, 'Unexpected value in the Task Description');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('5');

        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Start DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Start DateTime');

        // [WHEN] The Percent Completed field is updated to be = 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('100');
        Assert.AreNearlyEqual(CurrentDateTime - BaseDate, UserTaskCard."Completed DateTime".AsDateTime - BaseDate,
          60000, 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be less that 100
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('15');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime, 'Unexpected Completed DateTime');

        // [WHEN] The Percent Completed field is updated to be 0
        // [THEN] Various fields are defaulted.
        UserTaskCard."Percent Complete".Value('0');
        Assert.AreEqual(0DT, UserTaskCard."Completed DateTime".AsDateTime, 'Unexpected Completed DateTime');
        Assert.AreEqual(0DT, UserTaskCard."Start DateTime".AsDateTime, 'Unexpected Start Date Time');

        // [WHEN] The Completed Date field is updated.
        // [THEN] Various fields are defaulted.
        UserTaskCard."Completed DateTime".Value(Format(CurrentDateTime));
        Assert.AreEqual(100, UserTaskCard."Percent Complete".AsInteger, 'Unexpected Percent Complete');

        // [WHEN] The user creates a hyper link using the object selection controls.

        // [WHEN] The user tries to creates a hyper link using page of type card.
        // [THEN] An error message is raised, handler below.
        UserTaskCard."Object Type".Value('Page');
        asserterror UserTaskCard."Object ID".Value('21');

        UserTaskCard.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('UserTaskRecurrenceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestUserCardRecurrence()
    var
        UserTask: Record "User Task";
        UserTaskGroup: Record "User Task Group";
        UserTaskGroupMember: Record "User Task Group Member";
        UserTaskCard: TestPage "User Task Card";
        CountBefore: Integer;
        Increment: Integer;
        TaskTitle: Text[250];
    begin
        // [FEATURE] [User Task Group] [UI]
        // [SCENARIO 417919] Stan create task via "Occurence" field on Task Card page and updating of assignment fields causes update on all tasks having the same "Parent ID"
        Init();

        LibraryVariableStorage.Clear();
        CountBefore := UserTask.Count();
        Increment := LibraryRandom.RandIntInRange(3, 7);
        TaskTitle := CopyStr(LibraryRandom.RandText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [GIVEN] Task Group "TG", and User "A".
        CreateUserTaskGroup(UserTaskGroup);
        AddUserToUserTaskGroupByCode(User1."User Security ID", UserTaskGroup.Code);

        // [GIVEN] User Task "UT" without assignment
        UserTaskCard.OpenNew();
        UserTaskCard.Title.Value(TaskTitle);
        UserTaskCard.Close();

        UserTask.FindLast();
        UserTask.TestField(Title, TaskTitle);

        // [GIVEN] Stan specified 5 occurencies for "UT"
        LibraryVariableStorage.Enqueue(Increment);

        UserTaskCard.OpenEdit();
        UserTaskCard.Filter.SetFilter(ID, Format(UserTask.ID));
        UserTaskCard.Recurrence.Invoke();
        UserTaskCard.OK().Invoke();

        // [GIVEN] New tasks created. (Source (1) + New (4)) = 5
        Assert.RecordCount(UserTask, CountBefore + Increment);

        // [GIVEN] All of them have the same "Parent ID" = "UT"
        UserTask.SetRange("Parent ID", UserTask.ID);
        Assert.RecordCount(UserTask, Increment);

        // [GIVEN] Specified "User Task Group Assigned To" with "TG" on "UT"
        UserTaskCard.OpenEdit();
        UserTaskCard.Filter.SetFilter(ID, Format(UserTask.ID));
        UserTaskCard."User Task Group Assigned To".SetValue(UserTaskGroup.Code);
        UserTaskCard.OK().Invoke();

        // [GIVEN] System assigned "TG" to all tasks "Parent ID" = "UT"
        UserTask.SetRange("User Task Group Assigned To", UserTaskGroup.Code);
        Assert.RecordCount(UserTask, Increment);

        // [WHEN] Stan assigns "A" to task "UT"
        UserTask.Find();
        UserTask.Validate("Assigned To", User1."User Security ID");
        UserTask.Modify(true);

        Assert.RecordCount(UserTask, 0);

        // [THEN] System cleared "User Task Group Assigned To" on all task having "Parent ID" = "UT"
        // [THEN] System assigned "A" to all task having "Parent ID" = "UT"
        UserTask.SetRange("User Task Group Assigned To", '');
        UserTask.SetRange("Assigned To", User1."User Security ID");
        Assert.RecordCount(UserTask, Increment);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestUserPurge()
    var
        UserTask: Record "User Task";
    begin
        // [SCENARIO] Test the User Task purge.

        // [GIVEN] Several Task records with different creators.
        UserTask.DeleteAll();
        UserTask.Init();
        UserTask."Created By" := User1."User Security ID";
        UserTask."Assigned To" := User2."User Security ID";
        UserTask.Insert();

        Clear(UserTask);
        UserTask.Init();
        UserTask."Created By" := User2."User Security ID";
        UserTask."Assigned To" := User1."User Security ID";
        UserTask.Insert();

        // [WHEN] The task purge is asked to delete tasks for User1
        // [THEN] Those records are deleted, tasks created by User2 remain.

        Assert.AreEqual(2, UserTask.Count, 'Unexpected record count prior to purge');
        Commit();

        REPORT.Run(REPORT::"User Task Utility");

        Assert.AreEqual(1, UserTask.Count, 'Unexpected record count prior to purge');
        Assert.IsTrue(UserTask.FindFirst, 'Expected record to be found');
        Assert.AreEqual(User2."User Security ID", UserTask."Created By", 'Expected Task for User2 not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WinEncodingInDescriptionBLOB()
    var
        UserTask: Record "User Task";
        UserTask2: Record "User Task";
    begin
        // FEATURE] [UT]
        // [SCENARIO 253612] Task Description field in User Task table must be set accordingly to its encoding
        UserTask.Init();
        UserTask.SetDescription('Vytvorení úcetního období pro rok 2018');
        UserTask.Insert();

        UserTask2.Get(UserTask.ID);
        Assert.AreEqual('Vytvorení úcetního období pro rok 2018', UserTask2.GetDescription, 'Unexpected value in the Task Description');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestRenameUser()
    var
        User: Record User;
        FieldRec: Record "Field";
        Company: Record Company;
        TableInformation: Record "Table Information";
        TempTablesAlreadyInserted: Record Integer temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        UserMgt: Codeunit "User Management";
    begin
        // [GIVEN] Create data for tables with fields having relation with User table
        Company.FindFirst();
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        FieldRec.SetRange(RelationTableNo, DATABASE::User);
        FieldRec.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        FieldRec.SetFilter(Type, '%1|%2', FieldRec.Type::Code, FieldRec.Type::Text);
        if FieldRec.FindSet() then
            repeat
                TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                TableInformation.SetRange("Table No.", FieldRec.TableNo);
                if TableInformation.FindFirst then begin
                    RecRef.Open(FieldRec.TableNo, false, Company.Name);
                    if TempTablesAlreadyInserted.Get(FieldRec.TableNo) then begin
                        RecRef.FindFirst();
                        FldRef := RecRef.Field(FieldRec."No.");
                        FldRef.Value('OLD');
                        RecRef.Modify();
                    end else begin
                        RecRef.DeleteAll();
                        RecRef.Init();
                        FldRef := RecRef.Field(FieldRec."No.");
                        FldRef.Value('OLD');
                        RecRef.Insert();
                        TempTablesAlreadyInserted.Init();
                        TempTablesAlreadyInserted.Number := FieldRec.TableNo;
                        TempTablesAlreadyInserted.Insert();
                    end;
                    RecRef.Close();
                end;
            until FieldRec.Next() = 0;

        // [WHEN] RenameUser is invoked
        UserMgt.RenameUser('OLD', 'NEW');

        // [THEN] The data in the table fields has been updated
        if FieldRec.FindSet() then
            repeat
                TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                TableInformation.SetRange("Table No.", FieldRec.TableNo);
                if TableInformation.FindFirst then begin
                    RecRef.Open(FieldRec.TableNo, false, Company.Name);
                    FldRef := RecRef.Field(FieldRec."No.");
                    FldRef.SetRange('NEW');
                    Assert.AreEqual(1, RecRef.Count(), StrSubstNo('Records with new username should exist in %1.', TableInformation."Table Name"));
                    RecRef.Close();
                end;
            until FieldRec.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Init()
    var
        UserTask: Record "User Task";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        UserTask.DeleteAll();

        LibraryPermissions.CreateUser(User1, '', false);
        LibraryPermissions.CreateUser(User2, '', false);

        // Create user task groups
        CreateUserTaskGroup(UserTaskGroup1);
        AddUserToUserTaskGroupByCode(User1."User Security ID", 'GroupA');
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure EnsurePageLinkedToTaskCanBeOpened()
    var
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Ensure linked page to user task card page can be opened by an action on the page.

        // [GIVEN] A task user card page with a valid page type associated with it.
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard."Object Type".Value('page');
        UserTaskCard."Object ID".Value('22');

        // [WHEN] An action on the user card page is clicked to open up linked page to task
        // [THEN] Linked page opens up handled by CustomerListPageHandler
        UserTaskCard."Go To Task Item".Invoke;

        UserTaskCard.OK.Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureUserTaskCanBeAssignedToUserTaskGroup()
    var
        UserTask: Record "User Task";
        UserTaskCard: TestPage "User Task Card";
    begin
        // [SCENARIO] Ensure a user task can be assigned to user task group

        // [GIVEN] Creating a new user task.
        UserTaskCard.Trap;
        UserTaskCard.OpenNew;
        UserTaskCard.Title.Value := 'Test User Task';
        UserTaskCard."User Task Group Assigned To".Value(UserTaskGroup1.Code);

        // [WHEN] user task card page is closed
        UserTaskCard.OK.Invoke;

        // [THEN] Find User task created and verify that group code is assigned
        UserTask.SetFilter(Title, 'Test User Task');
        UserTask.FindFirst;
        Assert.AreEqual(UserTaskGroup1.Code, UserTask."User Task Group Assigned To", 'Group code was not assigned to user task.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: Page "Customer List")
    begin
        // Handles customer list page opening from user task card.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var UserTaskPurge: TestRequestPage "User Task Utility")
    begin
        UserTaskPurge."User Task".SetFilter("Created By", User1."User Security ID");
        UserTaskPurge.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserTaskRecurrenceModalPageHandler(var UserTaskRecurrence: TestPage "User Task Recurrence")
    var
        DateFormulaVar: DateFormula;
    begin
        UserTaskRecurrence.RecurringStartDate.SetValue(DT2Date(CurrentDateTime()));
        Evaluate(DateFormulaVar, '<1D>');
        UserTaskRecurrence.Recurrence.SetValue(DateFormulaVar);
        UserTaskRecurrence.Occurrences.SetValue(LibraryVariableStorage.DequeueInteger());
        UserTaskRecurrence.OK.Invoke();
    end;

    [Scope('OnPrem')]
    procedure CreateUserTaskGroup(var UserTaskGroup: Record "User Task Group")
    begin
        UserTaskGroup.Init();
        UserTaskGroup.Code := LibraryUtility.GenerateGUID();
        UserTaskGroup.Description := LibraryUtility.GenerateGUID();
        UserTaskGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddUserToUserTaskGroupByCode(UserSecID: Guid; GroupCode: Code[20])
    begin
        if UserTaskGroupMember.Get(GroupCode, UserSecID) then
            exit;
        UserTaskGroupMember.Init();
        UserTaskGroupMember."User Task Group Code" := GroupCode;
        UserTaskGroupMember."User Security ID" := UserSecID;
        UserTaskGroupMember.Insert(true);
    end;
}

