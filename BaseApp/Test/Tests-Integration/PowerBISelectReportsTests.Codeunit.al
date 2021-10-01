#if not CLEAN19
codeunit 139089 "PowerBI Select Reports Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Power BI] [Report Selection] [UI]
    end;

    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        Assert: Codeunit Assert;
        LibraryPowerBIServiceMgt: Codeunit "Library - Power BI Service Mgt";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestPageShowsNoReportsTextWhenUserHasNoReports()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Open the Power BI Report Selection page with no reports in user's PBI account
        Init;

        // [GIVEN] Account has no reports

        // [WHEN] Page is opened
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [THEN] Page opens with the no-reports text showing
        Assert.IsTrue(PowerBIReportSelectionTestPage.NoReportsError.Visible, '"No reports" message should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPageOpensWithReportsFromUserAccount()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        // [SCENARIO] User's Power BI account has reports before opening Power BI Report Selection page
        Init;

        // [GIVEN] Report buffer table has values
        FillReportList(1, true);

        // [WHEN] Page is opened
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelection.SetContext(LibraryPowerBIServiceMgt.GetContext);
        PowerBIReportSelection.Run;

        // [THEN] Page opens successfully with correct data loaded
        PowerBIReportSelectionTestPage.First;
        Assert.IsFalse(PowerBIReportSelectionTestPage.NoReportsError.Visible, '"No reports" message should be hidden.');
        PowerBIReportSelectionTestPage.ReportName.AssertEquals('Report 1');
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetNameFilterFiltersVisibleReports()
    var
        PowerBIReportSelectionPage: Page "Power BI Report Selection";
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Call SetNameFilter method before opening Power BI Report Selection page
        Init;
        FillReportList(2, false);

        // [GIVEN] SetNameFilter has been called
        PowerBIReportSelectionPage.SetNameFilter('2');

        // [WHEN] Page is opened
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelectionPage.Run;

        // [THEN] Page opens with filtered results
        Assert.AreEqual('@*2*', PowerBIReportSelectionTestPage.FILTER.GetFilter(ReportName),
          'Report name should have a wildcard filter for the given name.');
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals('Report 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOkSavesEnabledRow()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        ReportId: Guid;
    begin
        // [SCENARIO] Enable a disabled row and click OK
        Init;
        ReportId := CreateGuid;
        AddReportToList(ReportId, 'Report 1', false);

        // [GIVEN] Page is open with no reports enabled
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [WHEN] User enables the report and clicks OK
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.Enabled.SetValue(true);
        PowerBIReportSelectionTestPage.OK.Invoke;

        // [THEN] Row with correct values is added to Report Configuration table
        Assert.AreEqual(1, PowerBIReportConfiguration.Count, 'Configuration table should have the new row.');
        PowerBIReportConfiguration.FindFirst;
        PowerBIReportConfiguration.TestField("Report ID", ReportId);
        PowerBIReportConfiguration.TestField("User Security ID", UserSecurityId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOkSavesDisabledRow()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Disable an enabled row and click OK
        Init;
        PowerBIReportConfiguration.Init();
        PowerBIReportConfiguration."Report ID" := CreateGuid;
        PowerBIReportConfiguration."User Security ID" := UserSecurityId;
        PowerBIReportConfiguration.Insert();

        // [GIVEN] Page is open with a report already enabled
        AddReportToList(PowerBIReportConfiguration."Report ID", 'Report 1', true);
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [WHEN] User disables the report and clicks OK
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.Enabled.SetValue(false);
        PowerBIReportSelectionTestPage.OK.Invoke;

        // [THEN] Existing row is removed from Report Configuration table
        Assert.AreEqual(0, PowerBIReportConfiguration.Count, 'Configuration table should have removed the row.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetContextUpdatesPageContext()
    var
        PowerBIReportSelectionPage: Page "Power BI Report Selection";
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        ReportId1: Guid;
        ReportId2: Guid;
        Context1: Text[30];
        Context2: Text[30];
    begin
        // [SCENARIO] Use SetContext to only save reports for a specific page
        Init;
        ReportId1 := CreateGuid;
        Context1 := 'ORDER PROCESSOR';
        ReportId2 := CreateGuid;
        Context2 := 'BUSINESS MANAGER';

        // [GIVEN] Reports are already enabled for one context, SetContext called for a different context
        PowerBIReportConfiguration.Init();
        PowerBIReportConfiguration."Report ID" := ReportId1;
        PowerBIReportConfiguration."User Security ID" := UserSecurityId;
        PowerBIReportConfiguration.Context := Context1;
        PowerBIReportConfiguration.Insert();

        AddReportToList(ReportId1, 'Report 1', false);
        AddReportToList(ReportId2, 'Report 2', false);

        PowerBIReportSelectionPage.SetContext(Context2);
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelectionPage.Run;

        // [WHEN] User enables a report and saves
        PowerBIReportSelectionTestPage.Last;
        PowerBIReportSelectionTestPage.Enabled.SetValue(true);
        PowerBIReportSelectionTestPage.OK.Invoke;

        // [THEN] Report Configuration table updates row for the correct context only
        PowerBIReportConfiguration.SetRange("Report ID", ReportId1);
        PowerBIReportConfiguration.SetRange(Context, Context1);
        Assert.AreEqual(1, PowerBIReportConfiguration.Count, 'Configuration table should still have row for old context.');
        PowerBIReportConfiguration.SetRange("Report ID", ReportId2);
        PowerBIReportConfiguration.SetRange(Context, Context2);
        Assert.AreEqual(1, PowerBIReportConfiguration.Count, 'Configuration table should have added row for new context.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFocusingEnabledRowUpdatesButtons()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        // [SCENARIO] Focus an enabled row and see Enable/Disable buttons' clickability change
        Init;
        FillReportList(1, true);

        // [GIVEN] Page is open
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelection.SetContext(LibraryPowerBIServiceMgt.GetContext);
        PowerBIReportSelection.Run;

        // [WHEN] User focuses an enabled row
        PowerBIReportSelectionTestPage.First;

        // [THEN] Disable button is active, Enable button is inactive
        Assert.IsTrue(PowerBIReportSelectionTestPage.DisableReport.Enabled, 'Disable Report button should be active.');
        Assert.IsFalse(PowerBIReportSelectionTestPage.EnableReport.Enabled, 'Enable Report button should be inactive.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFocusingDisabledRowUpdatesButtons()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Focus a disabled row and see Enable/Disable buttons' clickability change
        Init;
        FillReportList(1, false);

        // [GIVEN] Page is open
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [WHEN] User focuses a disabled row
        PowerBIReportSelectionTestPage.First;

        // [THEN] Enable button is active, Disable button is inactive
        Assert.IsTrue(PowerBIReportSelectionTestPage.EnableReport.Enabled, 'Enable Report button should be active.');
        Assert.IsFalse(PowerBIReportSelectionTestPage.DisableReport.Enabled, 'Disable Report button should be inactive.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEnableButtonEnablesReport()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Focus a disabled row and click the Enable button
        Init;
        FillReportList(1, false);

        // [GIVEN] Page is open
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [WHEN] User clicks Enable button on a disabled row
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.EnableReport.Invoke;

        // [THEN] Row becomes enabled
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisableButtonDisablesReport()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        // [SCENARIO] Focus an enabled row and click the Disable button
        Init;
        FillReportList(1, true);

        // [GIVEN] Page is open
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelection.SetContext(LibraryPowerBIServiceMgt.GetContext);
        PowerBIReportSelection.Run;

        // [WHEN] User clicks Disable button on an enabled row
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.DisableReport.Invoke;

        // [THEN] Row becomes disabled
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRefreshButtonSeesNewReportsInAccount()
    var
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
    begin
        // [SCENARIO] Click the Refresh button after adding new reports to PBI account
        Init;

        // [GIVEN] Report list starts empty
        PowerBIReportSelectionTestPage.Trap;
        PAGE.Run(PAGE::"Power BI Report Selection");

        // [WHEN] Report added and Refresh is clicked
        AddReportToList(CreateGuid, 'Report 1', false);
        PowerBIReportSelectionTestPage.Refresh.Invoke;

        // [THEN] Page data refreshes
        PowerBIReportSelectionTestPage.Last;
        Assert.IsFalse(PowerBIReportSelectionTestPage.NoReportsError.Visible, '"No reports" message should be hidden.');
        PowerBIReportSelectionTestPage.ReportName.AssertEquals('Report 1');

        // [WHEN] New report added and Refresh clicked again
        AddReportToList(CreateGuid, 'Report 2', false);
        PowerBIReportSelectionTestPage.Refresh.Invoke;

        // [THEN] Page data refreshes
        PowerBIReportSelectionTestPage.Last;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals('Report 2');
    end;

    local procedure Init()
    begin
        // Sets all tables and settings back to initial state so each test can run with a blank slate.
        if not IsInitialized then begin
            LibraryPowerBIServiceMgt.SetupMockPBIService;
            BindSubscription(LibraryPowerBIServiceMgt);
            IsInitialized := true;
        end;

        PowerBIReportConfiguration.Reset();
        PowerBIReportConfiguration.DeleteAll();
        LibraryPowerBIServiceMgt.ClearReports;
    end;

    local procedure AddReportToList(Id: Guid; Name: Text[100]; Enabled: Boolean)
    begin
        // Helper function to add a row with the given report name and enabled/disabled status to the mocked Power BI report account.
        LibraryPowerBIServiceMgt.AddReport(Id, Name, Enabled);
    end;

    local procedure FillReportList(ReportCount: Integer; Enabled: Boolean)
    var
        i: Integer;
    begin
        // Helper function fill the mocked Power BI account with the given number of fake reports.
        if ReportCount > 0 then
            for i := 1 to ReportCount do
                AddReportToList(CreateGuid, 'Report ' + Format(i), Enabled);
    end;
}
#endif
