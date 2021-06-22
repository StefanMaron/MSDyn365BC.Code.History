codeunit 134444 "ERM Test Account Categories"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category] [Account Schedule]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ExpectedAccSchedName: Code[10];
        IsInitialized: Boolean;
        MoreThanOneLineErr: Label 'Account schedule %1 must have more than one line.', Comment = '%1 - account schedule name';
        NumbeOfLinesOneErr: Label 'Account schedule %1 can only have one line.', Comment = '%1 - account schedule name';

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestBalanceSheet()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Balance Sheet";

        // Execution
        REPORT.Run(REPORT::"Balance Sheet");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomeStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Income Stmt.";

        // Execution
        REPORT.Run(REPORT::"Income Statement");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestCashFlowStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt";

        // Execution
        REPORT.Run(REPORT::"Statement of Cashflows");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('AccSchedReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestRetainedEarningsStatement()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Init
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        ExpectedAccSchedName := GeneralLedgerSetup."Acc. Sched. for Retained Earn.";

        // Execution
        REPORT.Run(REPORT::"Retained Earnings Statement");

        // Validation is done in the request page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccountCategoriesLookupHandler')]
    [Scope('OnPrem')]
    procedure AccountSubcategoryLookupDoesntInsertTheGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccountCardPage: TestPage "G/L Account Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284151] Account Subcategory Lookup on G/L Account Card page doesn't insert current record

        // [GIVEN] G/L Account Card page was open
        GLAccountCardPage.OpenNew;

        // [WHEN] Lookup is invoked for Account Subcategory
        GLAccountCardPage.SubCategoryDescription.Lookup;
        // Handled by GLAccountCategoriesLookupHandler

        // [THEN] G/L Account with blank "No." wasn't inserted
        GLAccount.SetRange("No.", '');
        Assert.RecordIsEmpty(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSubcategoryValidateDoesntInsertTheGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCardPage: TestPage "G/L Account Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 284151] Account Subcategory Validate on G/L Account Card page doesn't insert current record

        // [GIVEN] G/L Account Card page was open
        GLAccountCardPage.OpenNew;

        // [GIVEN] A G/L Account Category
        CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] "Account Category" was set
        GLAccountCardPage."Account Category".SetValue(GLAccountCategory."Account Category");

        // [WHEN] Validating Account Subcategory
        GLAccountCardPage.SubCategoryDescription.SetValue(GLAccountCategory.Description);

        // [THEN] G/L Account with blank "No." wasn't inserted
        GLAccount.SetRange("No.", '');
        Assert.RecordIsEmpty(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OptionDialogForGenerateAccountSchedules')]
    procedure GenerateAccSchedulesConfirmOverwrite()
    var
        GLSetup: Record "General Ledger Setup";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287114] When user choose Overwrite option for "Generate Account Schedules" action existent account schedules are overwritten
        Initialize();

        // [GIVEN] G/L Setup with filled account schedule names
        ClearStandardAccSchedules();
        UpdateGLSetupWithStandardAccScheduleNames();

        // [GIVEN] Set 1 line for each standard account schedule
        CreateDummyStandardAccSchedules();

        // [WHEN] Action "Generate Account Schedules" is being run from page "G/L Account Categories" with option "Overwrite existent"
        LibraryVariableStorage.Enqueue(2);
        GLAccountCategories.OpenEdit();
        GLAccountCategories.GenerateAccSched.Invoke();

        // [THEN] Standard account schedules are re-initialized 
        GLSetup.Get();
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Balance Sheet");
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Cash Flow Stmt");
        // Income statement check skipped because it is empty by default for some countries
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Retained Earn.");
    end;

    [Test]
    [HandlerFunctions('OptionDialogForGenerateAccountSchedules')]
    [Scope('OnPrem')]
    procedure GenerateAccSchedulesConfirmCreateNew()
    var
        GLSetup: Record "General Ledger Setup";
        SavedGLSetup: Record "General Ledger Setup";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287114] When user choose Overwrite option for "Generate Account Schedules" action existent account schedules are overwritten
        Initialize();

        // [GIVEN] G/L Setup with filled account schedule names
        ClearStandardAccSchedules();
        UpdateGLSetupWithStandardAccScheduleNames();

        // [GIVEN] Set 1 line for each standard account schedule
        CreateDummyStandardAccSchedules();
        GLSetup.Get();
        SavedGLSetup := GLSetup;

        // [WHEN] Action "Generate Account Schedules" is being run from page "G/L Account Categories" with option "Create new" 
        LibraryVariableStorage.Enqueue(1);
        GLAccountCategories.OpenEdit();
        GLAccountCategories.GenerateAccSched.Invoke();

        // [THEN] Existing Standard account schedules are not changed
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Balance Sheet");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Cash Flow Stmt");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Income Stmt.");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Retained Earn.");

        // [THEN] New account schedules created
        GLSetup.Get();
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Balance Sheet");
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Cash Flow Stmt");
        // Income statement check skipped because it is empty by default for some countries
        VerifyNumberOfAccScheduleLinesMoreThanOne(GLSetup."Acc. Sched. for Retained Earn.");
    end;

    [Test]
    [HandlerFunctions('OptionDialogForGenerateAccountSchedules')]
    [Scope('OnPrem')]
    procedure GenerateAccSchedulesDoNotConfirm()
    var
        GLSetup: Record "General Ledger Setup";
        SavedGLSetup: Record "General Ledger Setup";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287114] When user press Cancel for "Generate Account Schedules" action nothing happend
        Initialize();

        // [GIVEN] G/L Setup with filled account schedule names
        ClearStandardAccSchedules();
        UpdateGLSetupWithStandardAccScheduleNames();

        // [GIVEN] Set 1 line for each standard account schedule
        CreateDummyStandardAccSchedules();
        GLSetup.Get();
        SavedGLSetup := GLSetup;

        // [WHEN] Action "Generate Account Schedules" is being run from page "G/L Account Categories" with "Cacnel" 
        LibraryVariableStorage.Enqueue(0);
        GLAccountCategories.OpenEdit();
        GLAccountCategories.GenerateAccSched.Invoke();

        // [THEN] Existing Standard account schedules are not changed
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Balance Sheet");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Cash Flow Stmt");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Income Stmt.");
        VerifyNumberOfAccScheduleLinesIsOne(SavedGLSetup."Acc. Sched. for Retained Earn.");

        // [THEN] General ledger setup fields not changed
        GLSetup.Get();
        GLSetup.TestField("Acc. Sched. for Balance Sheet", SavedGLSetup."Acc. Sched. for Balance Sheet");
        GLSetup.TestField("Acc. Sched. for Cash Flow Stmt", SavedGLSetup."Acc. Sched. for Cash Flow Stmt");
        GLSetup.TestField("Acc. Sched. for Income Stmt.", SavedGLSetup."Acc. Sched. for Income Stmt.");
        GLSetup.TestField("Acc. Sched. for Retained Earn.", SavedGLSetup."Acc. Sched. for Retained Earn.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateAccSchedulesNoConfirmation()
    var
        GLSetup: Record "General Ledger Setup";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287114] When account schedule codes are not defined in the GLSetup then no confirmation dialog wen user run "Generate Account Schedules" action
        Initialize();

        // [GIVEN] G/L Setup with empty account schedule names
        UpdateGLSetupWithEmptyAccScheduleNames();

        // [WHEN] Action "Generate Account Schedules" is being run from page "G/L Account Categories"
        GLAccountCategories.OpenEdit();
        GLAccountCategories.GenerateAccSched.Invoke();

        // [THEN] Account schedules created without confirmation
        GLSetup.Get();
        GLSetup.TestField("Acc. Sched. for Balance Sheet");
        GLSetup.TestField("Acc. Sched. for Cash Flow Stmt");
        GLSetup.TestField("Acc. Sched. for Income Stmt.");
        GLSetup.TestField("Acc. Sched. for Retained Earn.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
    end;

    local procedure CreateGLAccountCategory(var GLAccountCategory: Record "G/L Account Category")
    begin
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        GLAccountCategory.Validate(Description, LibraryUtility.GenerateGUID);
        GLAccountCategory.Modify();
    end;

    local procedure CreateDummyStandardAccSchedules()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        CreateDummyAccSchedLine(GLSetup."Acc. Sched. for Balance Sheet");
        CreateDummyAccSchedLine(GLSetup."Acc. Sched. for Cash Flow Stmt");
        CreateDummyAccSchedLine(GLSetup."Acc. Sched. for Income Stmt.");
        CreateDummyAccSchedLine(GLSetup."Acc. Sched. for Retained Earn.");
    end;

    local procedure CreateDummyAccSchedLine(AccountScheduleName: Code[10])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.SetRange("Schedule Name", AccountScheduleName);
        if AccScheduleLine.FindLast() then;
        AccScheduleLine.Init();
        AccScheduleLine."Schedule Name" := AccountScheduleName;
        AccScheduleLine."Line No." := AccScheduleLine."Line No." + 10000;
        AccScheduleLine.Insert();
    end;

    local procedure GetNumberOfAccSchedLines(AccountScheduleName: Code[10]): Integer
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.SetRange("Schedule Name", AccountScheduleName);
        exit(AccScheduleLine.Count());
    end;

    local procedure UpdateGLSetupWithStandardAccScheduleNames()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.InitializeStandardAccountSchedules();
    end;

    local procedure UpdateGLSetupWithEmptyAccScheduleNames()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Acc. Sched. for Balance Sheet" := '';
        GLSetup."Acc. Sched. for Cash Flow Stmt" := '';
        GLSetup."Acc. Sched. for Income Stmt." := '';
        GLSetup."Acc. Sched. for Retained Earn." := '';
        GLSetup.Modify();
    end;

    local procedure ClearStandardAccSchedules()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Acc. Sched. for Balance Sheet");
        ClearStandardAccSchedule(GLSetup."Acc. Sched. for Balance Sheet");

        GLSetup.TestField("Acc. Sched. for Cash Flow Stmt");
        ClearStandardAccSchedule(GLSetup."Acc. Sched. for Cash Flow Stmt");

        GLSetup.TestField("Acc. Sched. for Income Stmt.");
        ClearStandardAccSchedule(GLSetup."Acc. Sched. for Income Stmt.");

        GLSetup.TestField("Acc. Sched. for Retained Earn.");
        ClearStandardAccSchedule(GLSetup."Acc. Sched. for Retained Earn.");
    end;

    local procedure ClearStandardAccSchedule(AccountScheduleName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.Get(AccountScheduleName);
        AccScheduleName.Delete(true);
    end;

    local procedure VerifyNumberOfAccScheduleLinesMoreThanOne(AccScheduleName: Code[10])
    begin
        Assert.IsTrue(GetNumberOfAccSchedLines(AccScheduleName) > 1, StrSubstNo(MoreThanOneLineErr, AccScheduleName));
    end;

    local procedure VerifyNumberOfAccScheduleLinesIsOne(AccScheduleName: Code[10])
    begin
        Assert.AreEqual(1, GetNumberOfAccSchedLines(AccScheduleName), StrSubstNo(NumbeOfLinesOneErr, AccScheduleName));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountCategoriesLookupHandler(var GLAccountCategoriesPage: TestPage "G/L Account Categories")
    begin
        GLAccountCategoriesPage.First;
        GLAccountCategoriesPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccSchedReportRequestPageHandler(var AccountSchedule: TestRequestPage "Account Schedule")
    begin
        Assert.AreEqual(ExpectedAccSchedName, AccountSchedule.AccSchedNam.Value, '');
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OptionDialogForGenerateAccountSchedules(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;
}

