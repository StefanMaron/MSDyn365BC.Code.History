codeunit 142068 "UT Account Schedule"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Account Schedule]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('AccountScheduleLayoutRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountScheduleName()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        // Purpose of the test is to validate Acc. Schedule Name - OnAfterGetRecord trigger of Report ID - 10000.
        // Setup: Create Acc. Schedule Name.
        Initialize;
        CreateAccScheduleName(AccScheduleLine);

        // Exercise.
        REPORT.Run(REPORT::"Account Schedule Layout");  // Opens AccountScheduleLayoutRequestPageHandler.

        // Verify: Verify Filters that Acc. Schedule Name is updated on Report Account Schedule Layout.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'AccSchedFilter', StrSubstNo('%1: %2', AccScheduleLine.FieldCaption("Schedule Name"), AccScheduleLine."Schedule Name"));
        LibraryReportDataset.AssertElementWithValueExists('SubTitle', 'for ' + AccScheduleLine.Description);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageAccScheduleOverview()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        AccountScheduleNames: TestPage "Account Schedule Names";
    begin
        // Purpose of the test is to validate Acc. Schedule Overview - OnOpenPage trigger of Page ID - 490.
        // Setup: Create Account Schedule.
        CreateAccScheduleName(AccScheduleLine);
        AccountScheduleNames.OpenEdit;
        AccountScheduleNames.FILTER.SetFilter(Name, AccScheduleLine."Schedule Name");
        AccScheduleOverview.Trap;

        // Exercise.
        AccountScheduleNames.Overview.Invoke;

        // Verify: New Created Schedule Name exist in Acc. Schedule Overview.
        AccScheduleOverview.CurrentSchedName.SetValue(AccScheduleLine."Schedule Name");
        AccScheduleOverview.Close;
        AccountScheduleNames.Close;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateAccScheduleName(var AccScheduleLine: Record "Acc. Schedule Line")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.Name := LibraryUTUtility.GetNewCode10;
        AccScheduleName.Description := AccScheduleName.Name;
        AccScheduleName.Insert;
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;
        AccScheduleLine.Description := AccScheduleName.Description;
        AccScheduleLine.Insert;
        LibraryVariableStorage.Enqueue(AccScheduleLine."Schedule Name");  // Enqueue required for AccountScheduleLayoutRequestPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleLayoutRequestPageHandler(var AccountScheduleLayout: TestRequestPage "Account Schedule Layout")
    var
        ScheduleName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ScheduleName);
        AccountScheduleLayout."Acc. Schedule Line".SetFilter("Schedule Name", ScheduleName);
        AccountScheduleLayout.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

