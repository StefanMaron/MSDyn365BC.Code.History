codeunit 9656 "Report Layout Update Log"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure ViewLog(IReportChangeLogCollection: DotNet IReportChangeLogCollection)
    var
        TempReportLayoutUpdateLog: Record "Report Layout Update Log" temporary;
    begin
        if ApplyLogEntriesToTableData(TempReportLayoutUpdateLog, IReportChangeLogCollection) > 0 then
            PAGE.RunModal(PAGE::"Report Layout Update Log", TempReportLayoutUpdateLog);
    end;

    local procedure ApplyLogEntriesToTableData(var TempReportLayoutUpdateLog: Record "Report Layout Update Log" temporary; IReportChangeLogCollection: DotNet IReportChangeLogCollection): Integer
    var
        IReportChangeLog: DotNet IReportChangeLog;
        LogCollection: DotNet ReportChangeLogCollection;
        intValue: Integer;
        startValue: Integer;
    begin
        if IsNull(IReportChangeLogCollection) then
            exit(0);
        LogCollection := IReportChangeLogCollection;

        // TODO: FOREACH IReportChangeLog IN IReportChangeLogCollection DO BEGIN
        foreach IReportChangeLog in LogCollection do begin
            startValue += 1;
            with TempReportLayoutUpdateLog do begin
                Init();
                "No." := startValue;
                intValue := IReportChangeLog.Status;
                Status := intValue;
                "Field Name" := IReportChangeLog.ElementName;
                Message := IReportChangeLog.Message;
                "Report ID" := IReportChangeLog.ReportId;
                "Layout Description" := IReportChangeLog.LayoutName;
                intValue := IReportChangeLog.LayoutFormat;
                if intValue = 0 then
                    intValue := 1;
                "Layout Type" := intValue - 1;
                Insert();
            end;
        end;

        exit(startValue - 1);
    end;
}

