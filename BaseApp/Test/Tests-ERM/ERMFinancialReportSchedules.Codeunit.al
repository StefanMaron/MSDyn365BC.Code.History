codeunit 135005 "ERM Financial Report Schedules"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    [Test]
    procedure StartEndDateFilterFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the start and end date filter formulas will dynamically set the date filter on the financial report
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a start and end date filter formula
        FinancialReport.Get(AccScheduleName.Name);
        Evaluate(FinancialReport.StartDateFilterFormula, '-CY');
        Evaluate(FinancialReport.EndDateFilterFormula, 'CY');
        FinancialReport.Modify();

        // [WHEN] The financial report is opened
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // [THEN] The date filter is set based on the formulas
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
    end;

    [Test]
    procedure DateFilterPeriodFormula()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the date filter period formula will dynamically set the date filter on the financial report
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a date filter period formula
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.DateFilterPeriodFormula := 'FY[1..LP]'; // Current fiscal year first period to last period
        FinancialReport.DateFilterPeriodFormulaLID := 1033; // en-US
        FinancialReport.Modify();

        // [WHEN] The financial report is opened
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);

        // [THEN] The date filter is set based on the formula
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
    end;

    [Test]
    procedure StartEndDateFilterFormulaOverride()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
    begin
        // [SCENARIO] Setting the start and end date filter formulas on the page will clear the period formula
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with a period formula
        FinancialReport.Get(AccScheduleName.Name);
        FinancialReport.DateFilterPeriodFormula := 'FY[1..LP]';
        FinancialReport.DateFilterPeriodFormulaLID := 1033;
        FinancialReport.Modify();

        // [WHEN] The start and end date filter formulas are set on the page
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        AccSchedOverview.StartDateFilterFormula.SetValue('CM+1D');
        AccSchedOverview.EndDateFilterFormula.SetValue('CM+1M');

        // [THEN] The date filter is updated based on the new formulas, and the period formula is cleared
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<CM+1D>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<CM+1M>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
        AccSchedOverview.Close();
        FinancialReport.Find();
        Assert.AreEqual('', FinancialReport.DateFilterPeriodFormula, 'The date filter period formula should be empty');
        Assert.AreEqual(0, FinancialReport.DateFilterPeriodFormulaLID, 'The date filter period formula language ID should be 0');
    end;

    [Test]
    procedure DateFilterPeriodFormulaOverride()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        AccSchedOverview: TestPage "Acc. Schedule Overview";
        LastLangId: Integer;
    begin
        // [SCENARIO] Setting the period formula on the page will clear the start and end date filter formulas
        Initialize();
        LibraryERM.CreateAccScheduleName(AccScheduleName);

        // [GIVEN] A financial report with start and end date filter formulas
        FinancialReport.Get(AccScheduleName.Name);
        Evaluate(FinancialReport.StartDateFilterFormula, '-CY');
        Evaluate(FinancialReport.EndDateFilterFormula, 'CY');
        FinancialReport.Modify();

        // [WHEN] The period formula is set on the page
        AccSchedOverview.Trap();
        OpenAccountScheduleOverviewPage(AccScheduleName.Name);
        LastLangId := GlobalLanguage();
        GlobalLanguage(1033);
        AccSchedOverview.DateFilterPeriodFormula.SetValue('1P');
        GlobalLanguage(LastLangId);

        // [THEN] The date filter is updated based on the new formula, and the start and end date filter formulas are cleared
        AccScheduleLine.SetFilter("Date Filter", AccSchedOverview.DateFilter.Value());
        Assert.AreEqual(CalcDate('<CM+1D>', WorkDate()), AccScheduleLine.GetRangeMin("Date Filter"), 'The date filter starting range is not correct');
        Assert.AreEqual(CalcDate('<1M+CM>', WorkDate()), AccScheduleLine.GetRangeMax("Date Filter"), 'The date filter ending range is not correct');
        AccSchedOverview.Close();
        FinancialReport.Find();
        Assert.AreEqual('', Format(FinancialReport.StartDateFilterFormula), 'The start date filter formula should be empty');
        Assert.AreEqual('', Format(FinancialReport.EndDateFilterFormula), 'The end date filter formula should be empty');
    end;

    local procedure Initialize()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        if IsInitialized then
            exit;

        FinancialReportMgt.Initialize();
        IsInitialized := true;
        Commit();
    end;

    local procedure OpenAccountScheduleOverviewPage(Name: Code[10])
    var
        FinancialReports: TestPage "Financial Reports";
    begin
        FinancialReports.OpenEdit();
        FinancialReports.FILTER.SetFilter(Name, Name);
        FinancialReports.Overview.Invoke();
    end;
}
