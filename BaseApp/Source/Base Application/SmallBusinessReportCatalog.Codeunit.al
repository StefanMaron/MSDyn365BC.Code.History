codeunit 9025 "Small Business Report Catalog"
{

    trigger OnRun()
    begin
    end;

    var
        ToFileNameTxt: Label 'DetailTrialBalance.xlsx';

    procedure RunAgedAccountsReceivableReport(UseRequestPage: Boolean)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
    begin
        Evaluate(PeriodLength, '<30D>');
        AgedAccountsReceivable.InitializeRequest(
          WorkDate, AgingBy::"Posting Date", PeriodLength, false, false, HeadingType::"Date Interval", false);
        AgedAccountsReceivable.UseRequestPage(UseRequestPage);

        AgedAccountsReceivable.Run;
    end;

    procedure RunAgedAccountsPayableReport(UseRequestPage: Boolean)
    var
        AgedAccountsPayable: Report "Aged Accounts Payable";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
    begin
        Evaluate(PeriodLength, '<30D>');
        AgedAccountsPayable.InitializeRequest(
          WorkDate, AgingBy::"Posting Date", PeriodLength, false, false, HeadingType::"Date Interval", false);
        AgedAccountsPayable.UseRequestPage(UseRequestPage);

        AgedAccountsPayable.Run;
    end;

    procedure RunCustomerTop10ListReport(UseRequestPage: Boolean)
    var
        CustomerTop10ListReport: Report "Customer - Top 10 List";
        ChartType: Option "Bar chart","Pie chart";
        ShowType: Option "Sales (LCY)","Balance (LCY)";
    begin
        CustomerTop10ListReport.InitializeRequest(ChartType::"Bar chart", ShowType::"Sales (LCY)", 10);
        CustomerTop10ListReport.UseRequestPage(UseRequestPage);
        CustomerTop10ListReport.Run;
    end;

    procedure RunVendorTop10ListReport(UseRequestPage: Boolean)
    var
        VendorTop10ListReport: Report "Vendor - Top 10 List";
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
    begin
        VendorTop10ListReport.InitializeRequest(ShowType::"Purchases (LCY)", 10);
        VendorTop10ListReport.UseRequestPage(UseRequestPage);
        VendorTop10ListReport.Run;
    end;

    procedure RunCustomerStatementReport(UseRequestPage: Boolean)
    var
        CustomerStatementReport: Report Statement;
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        NewPrintEntriesDue: Boolean;
        NewPrintAllHavingEntry: Boolean;
        NewPrintAllHavingBal: Boolean;
        NewPrintReversedEntries: Boolean;
        NewPrintUnappliedEntries: Boolean;
        NewIncludeAgingBand: Boolean;
        NewPeriodLength: Text[30];
        NewDateChoice: Option;
        NewLogInteraction: Boolean;
        NewStartDate: Date;
        NewEndDate: Date;
        DateChoice: Option "Due Date","Posting Date";
    begin
        // Use default parameters when you launch the request page, with Start/End Date being the YTD of current financial year
        NewPrintEntriesDue := false;
        NewPrintAllHavingEntry := false;
        NewPrintAllHavingBal := true;
        NewPrintReversedEntries := false;
        NewPrintUnappliedEntries := false;
        NewIncludeAgingBand := false;
        NewPeriodLength := '<1M+CM>';
        NewDateChoice := DateChoice::"Due Date";
        NewLogInteraction := true;

        NewStartDate := AccountingPeriodMgt.FindFiscalYear(WorkDate);
        NewEndDate := WorkDate;

        CustomerStatementReport.InitializeRequest(
          NewPrintEntriesDue, NewPrintAllHavingEntry, NewPrintAllHavingBal, NewPrintReversedEntries,
          NewPrintUnappliedEntries, NewIncludeAgingBand, NewPeriodLength, NewDateChoice,
          NewLogInteraction, NewStartDate, NewEndDate);
        CustomerStatementReport.UseRequestPage(UseRequestPage);
        CustomerStatementReport.Run;
    end;

    procedure RunTrialBalanceReport(UseRequestPage: Boolean)
    var
        TrialBalance: Report "Trial Balance";
    begin
        TrialBalance.UseRequestPage(UseRequestPage);

        TrialBalance.Run;
    end;

    [Scope('OnPrem')]
    procedure RunDetailTrialBalanceReport(UseRequestPage: Boolean)
    var
        DetailTrialBalance: Report "Detail Trial Balance";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        ToFile: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunDetailTrialBalanceReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        DetailTrialBalance.UseRequestPage(UseRequestPage);

        FileName := FileMgt.ServerTempFileName('xlsx');
        // Render report on the server
        DetailTrialBalance.SaveAsExcel(FileName);

        ToFile := ToFileNameTxt;
        Download(FileName, '', FileMgt.Magicpath, '', ToFile);
        Erase(FileName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunDetailTrialBalanceReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;
}

