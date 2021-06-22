codeunit 138029 "O365 Trial Balance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Trial Balance] [SMB]
        isInitialized := false;
    end;

    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ExpectedAmount: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Trial Balance");
        LibraryVariableStorage.Clear;
        LibraryApplicationArea.EnableFoundationSetup;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Trial Balance");

        if not LibraryFiscalYear.AccountingPeriodsExists then
            LibraryFiscalYear.CreateFiscalYear;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Trial Balance");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrialBalanceIsCachedWhenTrialBalancePageIsOpened()
    var
        TrialBalanceCacheInfo: Record "Trial Balance Cache Info";
        TrialBalanceCache: Record "Trial Balance Cache";
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        TrialBalance: TestPage "Trial Balance";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        I: Integer;
    begin
        // [SCENARIO] Trial Balance handles lack of accounting periods gracefully.
        Initialize;

        // [GIVEN] No Accounting periods
        TrialBalanceCacheInfo.DeleteAll();
        TrialBalanceCache.DeleteAll();

        // [WHEN] Opening the Trial Balance page
        TrialBalance.OpenEdit;

        // [THEN] the Trial Balance opens with no errors and shows a single column
        Assert.IsFalse(TrialBalanceCacheInfo.IsEmpty, 'Trial Balance Info record is not added.');
        Assert.IsFalse(TrialBalanceCache.IsEmpty, 'Trial Balance Info record is not added.');
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        TrialBalanceCache.FindSet;
        I := 1;
        repeat
            Assert.AreEqual(Descriptions[I], TrialBalanceCache.Description, 'Description is not set correctly.');
            Assert.AreEqual(Values[I, 1], TrialBalanceCache."Period 1 Amount", 'Period 1 amount is not set correctly.');
            Assert.AreEqual(Values[I, 2], TrialBalanceCache."Period 2 Amount", 'Period 2 amount is not set correctly.');
            if I = 1 then begin
                Assert.AreEqual(PeriodCaptionTxt[1], TrialBalanceCache."Period 1 Caption", 'Period 1 caption is not set correctly.');
                Assert.AreEqual(PeriodCaptionTxt[2], TrialBalanceCache."Period 2 Caption", 'Period 2 caption is not set correctly.');
            end;
            I := I + 1;
        until TrialBalanceCache.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrialBalanceMatchesAccSchedOverview()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
    begin
        Initialize;
        OpenAccSchedOverviewPage(AccScheduleOverview);

        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);
        CompareResults(AccScheduleOverview, Values);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviousNext()
    var
        TrialBalanceMgt: Codeunit "Trial Balance Mgt.";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        Descriptions: array[9] of Text[80];
        Values: array[9, 2] of Decimal;
        PeriodCaptionTxt: array[2] of Text;
        I: Integer;
        NoOfColumns: Integer;
    begin
        Initialize;
        OpenAccSchedOverviewPage(AccScheduleOverview);
        TrialBalanceMgt.LoadData(Descriptions, Values, PeriodCaptionTxt, 2);

        NoOfColumns := 2;
        for I := 1 to 2 do begin
            AccScheduleOverview.PreviousPeriod.Invoke;
            TrialBalanceMgt.PreviousPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            CompareResults(AccScheduleOverview, Values);
        end;

        for I := 1 to 2 do begin
            AccScheduleOverview.NextPeriod.Invoke;
            TrialBalanceMgt.NextPeriod(Descriptions, Values, PeriodCaptionTxt, NoOfColumns);
            CompareResults(AccScheduleOverview, Values);
        end;
    end;

    [Test]
    [HandlerFunctions('CheckAmountOnGLAccountHandler')]
    [Scope('OnPrem')]
    procedure TestDrillDownOnGLAccounts()
    var
        TrialBalance: TestPage "Trial Balance";
    begin
        Initialize;
        TrialBalance.OpenEdit;

        // Test drill down on GL Accounts
        // Row 1
        ExpectedAmount := -TrialBalance.CurrentPeriodValues1.AsDEcimal;
        TrialBalance.CurrentPeriodValues1.DrillDown;

        ExpectedAmount := -TrialBalance.CurrentPeriodMinusOneValues1.AsDEcimal;
        TrialBalance.CurrentPeriodMinusOneValues1.DrillDown;

        // Row 2
        ExpectedAmount := -TrialBalance.CurrentPeriodValues2.AsDEcimal;
        TrialBalance.CurrentPeriodValues2.DrillDown;

        ExpectedAmount := -TrialBalance.CurrentPeriodMinusOneValues2.AsDEcimal;
        TrialBalance.CurrentPeriodMinusOneValues2.DrillDown;

        // Row 5
        ExpectedAmount := TrialBalance.CurrentPeriodValues5.AsDEcimal;
        TrialBalance.CurrentPeriodValues5.DrillDown;

        ExpectedAmount := TrialBalance.CurrentPeriodMinusOneValues5.AsDEcimal;
        TrialBalance.CurrentPeriodMinusOneValues5.DrillDown;

        // Row 8
        ExpectedAmount := TrialBalance.CurrentPeriodValues8.AsDEcimal;
        TrialBalance.CurrentPeriodValues8.DrillDown;

        ExpectedAmount := TrialBalance.CurrentPeriodMinusOneValues8.AsDEcimal;
        TrialBalance.CurrentPeriodMinusOneValues8.DrillDown;

        // Row 9
        ExpectedAmount := -TrialBalance.CurrentPeriodValues9.AsDEcimal;
        TrialBalance.CurrentPeriodValues9.DrillDown;

        ExpectedAmount := -TrialBalance.CurrentPeriodMinusOneValues9.AsDEcimal;
        TrialBalance.CurrentPeriodMinusOneValues9.DrillDown;
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFormulas()
    var
        TrialBalance: TestPage "Trial Balance";
    begin
        Initialize;
        TrialBalance.OpenEdit;

        // Test drill down on Formulas
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues3.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues3.AsDEcimal);
        TrialBalance.CurrentPeriodValues3.DrillDown;
        LibraryVariableStorage.Enqueue(30);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues3.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues3.AsDEcimal);
        TrialBalance.CurrentPeriodMinusOneValues3.DrillDown;

        LibraryVariableStorage.Enqueue(40);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues4.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues4.AsDEcimal);
        TrialBalance.CurrentPeriodValues4.DrillDown;
        LibraryVariableStorage.Enqueue(40);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues4.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues4.AsDEcimal);
        TrialBalance.CurrentPeriodMinusOneValues4.DrillDown;

        LibraryVariableStorage.Enqueue(60);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues6.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues6.AsDEcimal);
        TrialBalance.CurrentPeriodValues6.DrillDown;
        LibraryVariableStorage.Enqueue(60);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues6.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues6.AsDEcimal);
        TrialBalance.CurrentPeriodMinusOneValues6.DrillDown;

        LibraryVariableStorage.Enqueue(70);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues7.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues7.AsDEcimal);
        TrialBalance.CurrentPeriodValues7.DrillDown;
        LibraryVariableStorage.Enqueue(70);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodValues7.AsDEcimal);
        LibraryVariableStorage.Enqueue(TrialBalance.CurrentPeriodMinusOneValues7.AsDEcimal);
        TrialBalance.CurrentPeriodMinusOneValues7.DrillDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoErrorsOnEmptyAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        TrialBalance: TestPage "Trial Balance";
    begin
        // [SCENARIO] Trial Balance handles lack of accounting periods gracefully.
        Initialize;

        // [GIVEN] No Accounting periods
        AccountingPeriod.DeleteAll();

        // [WHEN] Opening the Trial Balance page
        TrialBalance.OpenEdit;

        // [THEN] the Trial Balance opens with no errors and shows a single column
        Assert.IsTrue(TrialBalance.CurrentPeriodValues1.Visible, 'Current period should be visible');
        Assert.IsFalse(TrialBalance.CurrentPeriodMinusOneValues1.Visible, 'Current period minus one should not be visible');
    end;

    local procedure OpenAccSchedOverviewPage(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        TrialBalanceSetup: Record "Trial Balance Setup";
        AccountScheduleNames: TestPage "Account Schedule Names";
        TrialAccSchedName: Code[10];
    begin
        TrialBalanceSetup.Get();
        TrialAccSchedName := TrialBalanceSetup."Account Schedule Name";

        AccountScheduleNames.OpenEdit;
        AccountScheduleNames.FILTER.SetFilter(Name, TrialAccSchedName);
        AccScheduleOverview.Trap;

        AccountScheduleNames.Overview.Invoke;
        AccScheduleOverview.PeriodType.SetValue(PeriodType::"Accounting Period");
    end;

    local procedure CompareResults(AccScheduleOverview: TestPage "Acc. Schedule Overview"; Values: array[9, 2] of Decimal)
    var
        I: Integer;
    begin
        I := 1;
        AccScheduleOverview.First;
        repeat
            Assert.AreEqual(AccScheduleOverview.ColumnValues1.AsDEcimal, Round(Values[I, 2]), 'Data in column 1 does not match');
            Assert.AreEqual(AccScheduleOverview.ColumnValues2.AsDEcimal, Round(Values[I, 1]), 'Data in column 2 does not match');
            I := I + 1;
        until not AccScheduleOverview.Next;
    end;

    [PageHandler]
    [HandlerFunctions('CheckAmountOnGLAccountHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountOnGLAccountHandler(var ChartofAccountsGL: TestPage "Chart of Accounts (G/L)")
    var
        ActualAmount: Decimal;
    begin
        ActualAmount := 0;
        ChartofAccountsGL.First;
        repeat
            ActualAmount := ActualAmount + ChartofAccountsGL."Net Change".AsDEcimal;
        until not ChartofAccountsGL.Next;

        Assert.AreEqual(ExpectedAmount, ActualAmount, 'Wrong amount on GL page');
        ChartofAccountsGL.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        RowNo: Variant;
        Amount1: Variant;
        Amount2: Variant;
    begin
        LibraryVariableStorage.Dequeue(RowNo);
        LibraryVariableStorage.Dequeue(Amount2);
        LibraryVariableStorage.Dequeue(Amount1);
        Assert.AreEqual(
          RowNo,
          AccScheduleOverview."Row No.".AsInteger,
          'Unexpected account schedule line selected in the overview page.');
        Assert.AreEqual(
          Round(Amount1),
          AccScheduleOverview.ColumnValues1.AsDEcimal,
          'Unexpected amount shown in account schedule overview page.');
        Assert.AreEqual(
          Round(Amount2),
          AccScheduleOverview.ColumnValues2.AsDEcimal,
          'Unexpected amount shown in account schedule overview page.');

        AccScheduleOverview.Close;
    end;
}

