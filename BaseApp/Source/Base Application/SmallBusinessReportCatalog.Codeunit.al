codeunit 9025 "Small Business Report Catalog"
{

    trigger OnRun()
    begin
    end;

    var
        ToFileNameTxt: Label 'DetailTrialBalance.xlsx';

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

