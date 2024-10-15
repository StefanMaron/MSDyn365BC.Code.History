codeunit 139125 ReportCatalogTests
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Report Catalog]
    end;

    var
        SmallBusinessReportCatalogCU: Codeunit "Small Business Report Catalog";
        FileManagement: Codeunit "File Management";
        LibraryUtility: Codeunit "Library - Utility";
        SavedPDFFile: Text;

    [Test]
    [HandlerFunctions('CustomerStatementReportHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReport()
    begin
        SmallBusinessReportCatalogCU.RunCustomerStatementReport(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceReport()
    begin
        SmallBusinessReportCatalogCU.RunDetailTrialBalanceReport(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerStatementReportHandler(var CustomerStatement: TestRequestPage Statement)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DateChoice: Option "Due Date","Posting Date";
    begin
        CustomerStatement.ShowOverdueEntries.AssertEquals(false);
        CustomerStatement.IncludeAllCustomerswithLE.AssertEquals(false);
        CustomerStatement.IncludeAllCustomerswithBalance.AssertEquals(true);
        CustomerStatement.IncludeReversedEntries.AssertEquals(false);
        CustomerStatement.IncludeUnappliedEntries.AssertEquals(false);
        CustomerStatement.IncludeAgingBand.AssertEquals(false);
        CustomerStatement.AgingBandPeriodLengt.AssertEquals('1M+CM');
        CustomerStatement.AgingBandby.AssertEquals(DateChoice::"Due Date");
        CustomerStatement.LogInteraction.AssertEquals(true);

        CustomerStatement."Start Date".AssertEquals(AccountingPeriodMgt.FindFiscalYear(WorkDate()));
        CustomerStatement."End Date".AssertEquals(WorkDate());

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        CustomerStatement.SaveAsPdf(SavedPDFFile);
        LibraryUtility.CheckFileNotEmpty(SavedPDFFile);
    end;
}

