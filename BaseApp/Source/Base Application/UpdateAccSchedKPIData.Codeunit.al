codeunit 197 "Update Acc. Sched. KPI Data"
{
    Permissions = TableData "Acc. Sched. KPI Web Srv. Setup" = rim,
                  TableData "Acc. Sched. KPI Buffer" = rimd;

    trigger OnRun()
    begin
        InitSetupData;
    end;

    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer";
        TempAccScheduleLine: Record "Acc. Schedule Line" temporary;
        TempColumnLayout: Record "Column Layout" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        NoOfActiveAccSchedLines: Integer;
        NoOfLines: Integer;
        LastLineNo: Integer;
        StartDate: Date;
        EndDate: Date;
        LastClosedDate: Date;
        UpdateFromDate: Date;
        Date: Date;
        UpdatingMsg: Label 'Updating buffer table @1@@@@@@@@@@@@@@@@@@@', Comment = '@1 is a number';

    local procedure InitSetupData()
    var
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        GLEntry: Record "G/L Entry";
        LogInManagement: Codeunit LogInManagement;
        Window: Dialog;
        i: Integer;
    begin
        AccSchedKPIWebSrvSetup.LockTable();
        if not AccSchedKPIWebSrvSetup.Get then begin
            AccSchedKPIWebSrvSetup.Init();
            AccSchedKPIWebSrvSetup.Insert();
        end;
        if AccSchedKPIWebSrvSetup."Data Time To Live (hours)" < 1 then
            AccSchedKPIWebSrvSetup."Data Time To Live (hours)" := 24;
        if not AccSchedKPIBuffer.IsEmpty then
            if AccSchedKPIWebSrvSetup."Data Last Updated" >
               CurrentDateTime - AccSchedKPIWebSrvSetup."Data Time To Live (hours)" * 3600000
            then
                exit;

        if AccSchedKPIWebSrvSetup."Last G/L Entry Included" > 0 then begin
            GLEntry.SetFilter("Entry No.", '>%1', AccSchedKPIWebSrvSetup."Last G/L Entry Included");
            GLEntry.SetCurrentKey("Posting Date");
        end;
        if not GLEntry.FindFirst then
            exit; // nothing to update

        Window.Open(UpdatingMsg);
        if not GuiAllowed then
            WorkDate := LogInManagement.GetDefaultWorkDate;

        if AccSchedKPIWebSrvSetup."Last G/L Entry Included" = 0 then begin
            AccSchedKPIBuffer.DeleteAll();
            UpdateFromDate := 0D;
        end else begin
            UpdateFromDate := GLEntry."Posting Date";
            AccSchedKPIBuffer.SetFilter(Date, '>=%1', UpdateFromDate);
            AccSchedKPIBuffer.DeleteAll();
            AccSchedKPIBuffer.Reset();
            if AccSchedKPIBuffer.FindLast then
                LastLineNo := AccSchedKPIBuffer."No.";
        end;

        if not AccSchedKPIWebSrvLine.FindSet then
            exit;
        AccScheduleLine.SetRange(Show, AccScheduleLine.Show::Yes);
        AccScheduleLine.SetFilter(Totaling, '<>%1', '');
        repeat
            AccScheduleLine.SetRange("Schedule Name", AccSchedKPIWebSrvLine."Acc. Schedule Name");
            if AccScheduleLine.FindSet then
                repeat
                    NoOfActiveAccSchedLines += 1;
                    TempAccScheduleLine := AccScheduleLine;
                    TempAccScheduleLine."Line No." := NoOfActiveAccSchedLines;
                    TempAccScheduleLine.Insert();
                until AccScheduleLine.Next = 0;
        until AccSchedKPIWebSrvLine.Next = 0;

        OnInitSetupDataAnAfterTempAccScheduleLineInsert(TempAccScheduleLine, NoOfActiveAccSchedLines);

        with ColumnLayout do begin
            // Net Change Actual
            InsertTempColumn("Column Type"::"Net Change", "Ledger Entry Type"::Entries, false);
            // Balance at Date Actual
            InsertTempColumn("Column Type"::"Balance at Date", "Ledger Entry Type"::Entries, false);
            // Net Change Budget
            InsertTempColumn("Column Type"::"Net Change", "Ledger Entry Type"::"Budget Entries", false);
            // Balance at Date Budget
            InsertTempColumn("Column Type"::"Balance at Date", "Ledger Entry Type"::"Budget Entries", false);
            // Net Change Actual Last Year
            InsertTempColumn("Column Type"::"Net Change", "Ledger Entry Type"::Entries, true);
            // Balance at Date Actual Last Year
            InsertTempColumn("Column Type"::"Balance at Date", "Ledger Entry Type"::Entries, true);
            // Net Change Budget Last Year
            InsertTempColumn("Column Type"::"Net Change", "Ledger Entry Type"::"Budget Entries", true);
            // Balance at Date Budget Last Year
            InsertTempColumn("Column Type"::"Balance at Date", "Ledger Entry Type"::"Budget Entries", true);
        end;

        AccSchedKPIWebSrvSetup.GetPeriodLength(NoOfLines, StartDate, EndDate);
        NoOfLines *= NoOfActiveAccSchedLines;
        LastClosedDate := AccSchedKPIWebSrvSetup.GetLastClosedAccDate;

        for i := 0 to NoOfLines - 1 do begin
            if i mod 10 = 0 then
                Window.Update(1, 10000 * i div NoOfLines);
            CalcValues(i);
        end;

        AccSchedKPIWebSrvSetup."Data Last Updated" := CurrentDateTime;
        GLEntry.Reset();
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := GLEntry.GetLastEntryNo();
        AccSchedKPIWebSrvSetup.Modify();
        Commit();
        Window.Close;
    end;

    local procedure InsertTempColumn(ColumnType: Option; EntryType: Option; LastYear: Boolean)
    begin
        with TempColumnLayout do begin
            if FindLast then;
            Init;
            "Line No." += 10000;
            "Column Type" := ColumnType;
            "Ledger Entry Type" := EntryType;
            if LastYear then
                Evaluate("Comparison Date Formula", '<-1Y>');
            Insert;
        end;
    end;

    local procedure CalcValues(Number: Integer)
    var
        ToDate: Date;
        ColNo: Integer;
        CalculatedValue: Decimal;
    begin
        Date := AccSchedKPIWebSrvSetup.CalcNextStartDate(StartDate, Number div NoOfActiveAccSchedLines);
        if Date < UpdateFromDate then
            exit;

        ToDate := AccSchedKPIWebSrvSetup.CalcNextStartDate(Date, 1) - 1;
        TempAccScheduleLine.FindSet;
        if Number mod NoOfActiveAccSchedLines > 0 then
            TempAccScheduleLine.Next(Number mod NoOfActiveAccSchedLines);
        TempAccScheduleLine.SetRange("Date Filter", Date, ToDate);
        TempAccScheduleLine.SetRange("G/L Budget Filter", AccSchedKPIWebSrvSetup."G/L Budget Name");

        LastLineNo += 1;
        AccSchedKPIBuffer.Init();
        AccSchedKPIBuffer."No." := LastLineNo;
        AccSchedKPIBuffer.Date := Date;
        AccSchedKPIBuffer."Closed Period" := Date <= LastClosedDate;
        AccSchedKPIBuffer."Account Schedule Name" := TempAccScheduleLine."Schedule Name";
        AccSchedKPIBuffer."KPI Code" := CopyStr(TempAccScheduleLine."Row No.", 1, MaxStrLen(AccSchedKPIBuffer."KPI Code"));
        AccSchedKPIBuffer."KPI Name" := CopyStr(TempAccScheduleLine.Description, 1, MaxStrLen(AccSchedKPIBuffer."KPI Name"));

        ColNo := 0;
        TempColumnLayout.FindSet;
        repeat
            CalculatedValue := AccSchedManagement.CalcCell(TempAccScheduleLine, TempColumnLayout, false);
            OnCalcValuesOnAfterCalculateValue(TempAccScheduleLine, TempColumnLayout, CalculatedValue);

            ColNo += 1;
            case ColNo of
                1:
                    AccSchedKPIBuffer."Net Change Actual" := CalculatedValue;
                2:
                    AccSchedKPIBuffer."Balance at Date Actual" := CalculatedValue;
                3:
                    AccSchedKPIBuffer."Net Change Budget" := CalculatedValue;
                4:
                    AccSchedKPIBuffer."Balance at Date Budget" := CalculatedValue;
                5:
                    AccSchedKPIBuffer."Net Change Actual Last Year" := CalculatedValue;
                6:
                    AccSchedKPIBuffer."Balance at Date Act. Last Year" := CalculatedValue;
                7:
                    AccSchedKPIBuffer."Net Change Budget Last Year" := CalculatedValue;
                8:
                    AccSchedKPIBuffer."Balance at Date Bud. Last Year" := CalculatedValue;
                9:
                    AccSchedKPIBuffer."Net Change Forecast" := CalculatedValue;
                10:
                    AccSchedKPIBuffer."Balance at Date Forecast" := CalculatedValue;
            end;
        until TempColumnLayout.Next = 0;

        // Forecasted values
        with AccSchedKPIWebSrvSetup do
            if (("Forecasted Values Start" = "Forecasted Values Start"::"After Latest Closed Period") and
                not AccSchedKPIBuffer."Closed Period") or
               (("Forecasted Values Start" = "Forecasted Values Start"::"After Current Date") and (Date > WorkDate))
            then begin
                AccSchedKPIBuffer."Net Change Forecast" := AccSchedKPIBuffer."Net Change Budget"; // Net Change Budget
                AccSchedKPIBuffer."Balance at Date Forecast" := AccSchedKPIBuffer."Balance at Date Budget"; // Balance at Date Budget
            end else begin
                AccSchedKPIBuffer."Net Change Forecast" := AccSchedKPIBuffer."Net Change Actual"; // Net Change Actual
                AccSchedKPIBuffer."Balance at Date Forecast" := AccSchedKPIBuffer."Balance at Date Actual"; // Balance at Date Actual
            end;
        AccSchedKPIBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcValuesOnAfterCalculateValue(var TempAccScheduleLine: Record "Acc. Schedule Line" temporary; var TempColumnLayout: Record "Column Layout" temporary; var CalculatedValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSetupDataAnAfterTempAccScheduleLineInsert(var TempAccScheduleLine: Record "Acc. Schedule Line" temporary; var NoOfLines: Integer)
    begin
    end;
}

