codeunit 762 "Acc. Sched. Chart Management"
{

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        GLSetupLoaded: Boolean;

        DuplicateRowDescriptionsMsg: Label 'Row Definition %1 has duplicate Description values.';
        DuplicateColumnHeaderMsg: Label 'Column Definition %1 has duplicate Column Header values.';
        ColumnFormulaMsg: Label 'Column formula: %1.';
        DefaultAccSchedTok: Label 'DEFAULT', Comment = 'The default name of the chart setup.';
        DefinitionsModifiedMsg: Label 'The row definition or column definition has been modified since the chart setup was created. Please reset your chart setup.';

    procedure GetSetupRecordset(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; ChartName: Text[60]; Move: Integer)
    begin
        FindRecordset(AccountSchedulesChartSetup, ChartName);
        if (AccountSchedulesChartSetup.Count <= 1) or (Move = 0) then
            exit;

        if AccountSchedulesChartSetup.Next(Move) = 0 then
            if Move < 0 then
                AccountSchedulesChartSetup.FindLast()
            else
                AccountSchedulesChartSetup.FindFirst();

        AccountSchedulesChartSetup.SetLastViewed();
    end;

    local procedure FindRecordset(var AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; ChartName: Text[60])
    var
        Found: Boolean;
    begin
        with AccountSchedulesChartSetup do begin
            SetFilter("User ID", '%1|%2', UserId, '');

            if Get(UserId, ChartName) or Get('', ChartName) then begin
                SetLastViewed();
                exit;
            end;

            SetRange("Last Viewed", true);
            Found := FindLast();
            SetRange("Last Viewed");
            if Found then
                exit;

            if FindFirst() then begin
                SetLastViewed();
                exit;
            end;

            Init();
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            Name := DefaultAccSchedTok;
            "Base X-Axis on" := "Base X-Axis on"::Period;
            "Start Date" := WorkDate();
            "Period Length" := "Period Length"::Day;
            "Last Viewed" := true;
            Insert();
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer"; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccScheduleOverview: Page "Acc. Schedule Overview";
    begin
        GetAccScheduleAndColumnLayoutForDrillDown(AccScheduleLine, ColumnLayout, BusChartBuf, AccountSchedulesChartSetup);

        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::Formula then begin
            Message(ColumnFormulaMsg, ColumnLayout.Formula);
            exit;
        end;

        if AccScheduleLine."Totaling Type" in [AccScheduleLine."Totaling Type"::Formula,
                                               AccScheduleLine."Totaling Type"::"Set Base For Percent"]
        then begin
            AccScheduleOverview.SetAccSchedName(AccScheduleLine."Schedule Name");
            AccScheduleOverview.SetTableView(AccScheduleLine);
            AccScheduleOverview.SetRecord(AccScheduleLine);
            AccScheduleOverview.SetViewOnlyMode(true);
            AccScheduleOverview.SetPeriodType(BusChartBuf."Period Length");
            AccScheduleOverview.Run();
            exit;
        end;

        if AccScheduleLine.Totaling = '' then
            exit;

        case AccScheduleLine."Totaling Type" of
            AccScheduleLine."Totaling Type"::"Posting Accounts",
            AccScheduleLine."Totaling Type"::"Total Accounts":
                DrillDownOnGLAccount(AccScheduleLine, ColumnLayout);
            AccScheduleLine."Totaling Type"::"Cost Type",
            AccScheduleLine."Totaling Type"::"Cost Type Total":
                DrillDownOnCostType(AccScheduleLine, ColumnLayout);
            AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts",
            AccScheduleLine."Totaling Type"::"Cash Flow Total Accounts":
                DrillDownOnCFAccount(AccScheduleLine, ColumnLayout);
            else
                OnDrillDownTotalingTypeElseCase(AccScheduleLine, ColumnLayout, BusChartBuf);
        end;
    end;

    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer"; Period: Option " ",Next,Previous; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        BusChartMapColumn: Record "Business Chart Map";
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        AccSchedChartSetupLine2: Record "Acc. Sched. Chart Setup Line";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        FromDate: Date;
        ToDate: Date;
        NoOfPeriods: Integer;
        PeriodCounter: Integer;
        XCounter: Integer;
    begin
        CheckDuplicateAccScheduleLineDescription(AccountSchedulesChartSetup."Account Schedule Name");
        CheckDuplicateColumnLayoutColumnHeader(AccountSchedulesChartSetup."Column Layout Name");

        with BusChartBuf do begin
            "Period Length" := AccountSchedulesChartSetup."Period Length";

            case AccountSchedulesChartSetup."Base X-Axis on" of
                AccountSchedulesChartSetup."Base X-Axis on"::Period:
                    if Period = Period::" " then begin
                        FromDate := 0D;
                        ToDate := 0D;
                    end else
                        if FindMidColumn(BusChartMapColumn) then
                            GetPeriodFromMapColumn(BusChartMapColumn.Index, FromDate, ToDate);
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                    if ("Period Filter Start Date" = 0D) and (AccountSchedulesChartSetup."Start Date" <> 0D) then
                        InitializePeriodFilter(AccountSchedulesChartSetup."Start Date", AccountSchedulesChartSetup."End Date")
                    else
                        RecalculatePeriodFilter("Period Filter Start Date", "Period Filter End Date", Period);
            end;

            Initialize();
            case AccountSchedulesChartSetup."Base X-Axis on" of
                AccountSchedulesChartSetup."Base X-Axis on"::Period:
                    begin
                        SetPeriodXAxis();
                        NoOfPeriods := AccountSchedulesChartSetup."No. of Periods";
                        CalcAndInsertPeriodAxis(BusChartBuf, AccountSchedulesChartSetup, Period, NoOfPeriods, FromDate, ToDate);
                    end;
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                    SetXAxis(AccScheduleLine.FieldCaption(Description), "Data Type"::String);
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                    SetXAxis(ColumnLayout.FieldCaption("Column Header"), "Data Type"::String);
            end;

            AddMeasures(BusChartBuf, AccountSchedulesChartSetup);

            case AccountSchedulesChartSetup."Base X-Axis on" of
                AccountSchedulesChartSetup."Base X-Axis on"::Period:
                    begin
                        FindFirstColumn(BusChartMapColumn);
                        for PeriodCounter := 1 to NoOfPeriods do begin
                            AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine);
                            AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
                            if AccSchedChartSetupLine.FindSet() then
                                repeat
                                    GetPeriodFromMapColumn(PeriodCounter - 1, FromDate, ToDate);
                                    AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
                                    if (not AccScheduleLine.Get(
                                          AccSchedChartSetupLine."Account Schedule Name", AccSchedChartSetupLine."Account Schedule Line No.")) or
                                       (not ColumnLayout.Get(
                                          AccSchedChartSetupLine."Column Layout Name", AccSchedChartSetupLine."Column Layout Line No."))
                                    then
                                        Error(DefinitionsModifiedMsg);
                                    SetValue(
                                      AccSchedChartSetupLine."Measure Name", PeriodCounter - 1,
                                      RoundAmount(AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false)));
                                until AccSchedChartSetupLine.Next() = 0;
                        end;
                    end;
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                    begin
                        AccountSchedulesChartSetup.SetLinkToDimensionLines(AccSchedChartSetupLine);
                        AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
                        AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine2);
                        AccSchedChartSetupLine2.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine2."Chart Type"::" ");
                        XCounter := 0;
                        AccScheduleLine.SetRange("Date Filter", "Period Filter Start Date", "Period Filter End Date");
                        if AccSchedChartSetupLine.FindSet() then
                            repeat
                                AddColumn(AccSchedChartSetupLine."Measure Name");
                                if not AccScheduleLine.Get(
                                     AccSchedChartSetupLine."Account Schedule Name", AccSchedChartSetupLine."Account Schedule Line No.")
                                then
                                    Error(DefinitionsModifiedMsg);
                                if AccSchedChartSetupLine2.FindSet() then
                                    repeat
                                        if not ColumnLayout.Get(
                                             AccSchedChartSetupLine2."Column Layout Name", AccSchedChartSetupLine2."Column Layout Line No.")
                                        then
                                            Error(DefinitionsModifiedMsg);
                                        SetValue(
                                          AccSchedChartSetupLine2."Measure Name", XCounter,
                                          RoundAmount(AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false)));
                                    until AccSchedChartSetupLine2.Next() = 0;
                                XCounter += 1;
                            until AccSchedChartSetupLine.Next() = 0;
                    end;
                AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                    begin
                        AccountSchedulesChartSetup.SetLinkToDimensionLines(AccSchedChartSetupLine);
                        AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
                        AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine2);
                        AccSchedChartSetupLine2.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine2."Chart Type"::" ");
                        AccScheduleLine.SetRange("Date Filter", "Period Filter Start Date", "Period Filter End Date");
                        XCounter := 0;
                        if AccSchedChartSetupLine.FindSet() then
                            repeat
                                AddColumn(AccSchedChartSetupLine."Measure Name");
                                if not ColumnLayout.Get(AccSchedChartSetupLine."Column Layout Name", AccSchedChartSetupLine."Column Layout Line No.") then
                                    Error(DefinitionsModifiedMsg);
                                if AccSchedChartSetupLine2.FindSet() then
                                    repeat
                                        if not AccScheduleLine.Get(
                                             AccSchedChartSetupLine2."Account Schedule Name", AccSchedChartSetupLine2."Account Schedule Line No.")
                                        then
                                            Error(DefinitionsModifiedMsg);
                                        SetValue(
                                          AccSchedChartSetupLine2."Measure Name", XCounter,
                                          RoundAmount(AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false)));
                                    until AccSchedChartSetupLine2.Next() = 0;
                                XCounter += 1;
                            until AccSchedChartSetupLine.Next() = 0;
                    end;
            end;
        end;
    end;

    local procedure AddMeasures(var BusChartBuf: Record "Business Chart Buffer"; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        BusChartType: Enum "Business Chart Type";
    begin
        with AccSchedChartSetupLine do begin
            AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine);
            SetFilter("Chart Type", '<>%1', "Chart Type"::" ");
            if FindSet() then
                repeat
                    case "Chart Type" of
                        "Chart Type"::Line:
                            BusChartType := BusChartBuf."Chart Type"::Line;
                        "Chart Type"::StepLine:
                            BusChartType := BusChartBuf."Chart Type"::StepLine;
                        "Chart Type"::Column:
                            BusChartType := BusChartBuf."Chart Type"::Column;
                        "Chart Type"::StackedColumn:
                            BusChartType := BusChartBuf."Chart Type"::StackedColumn;
                    end;
                    BusChartBuf.AddDecimalMeasure("Measure Name", "Measure Value", BusChartType);
                until Next() = 0;
        end;
    end;

    local procedure CalcAndInsertPeriodAxis(var BusChartBuf: Record "Business Chart Buffer"; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup"; Period: Option ,Next,Previous; MaxPeriodNo: Integer; StartDate: Date; EndDate: Date)
    var
        PeriodDate: Date;
    begin
        if (StartDate = 0D) and (AccountSchedulesChartSetup."Start Date" <> 0D) then
            PeriodDate := CalcDate(StrSubstNo('<-1%1>', BusChartBuf.GetPeriodLength()), AccountSchedulesChartSetup."Start Date")
        else begin
            BusChartBuf.RecalculatePeriodFilter(StartDate, EndDate, Period);
            PeriodDate := CalcDate(StrSubstNo('<-%1%2>', MaxPeriodNo - (MaxPeriodNo div 2), BusChartBuf.GetPeriodLength()), EndDate);
        end;

        BusChartBuf.AddPeriods(GetCorrectedDate(BusChartBuf, PeriodDate, 1), GetCorrectedDate(BusChartBuf, PeriodDate, MaxPeriodNo));
    end;

    procedure GetCorrectedDate(BusChartBuf: Record "Business Chart Buffer"; InputDate: Date; PeriodNo: Integer) OutputDate: Date
    begin
        OutputDate := CalcDate(StrSubstNo('<%1%2>', PeriodNo, BusChartBuf.GetPeriodLength()), InputDate);
        if BusChartBuf."Period Length" <> BusChartBuf."Period Length"::Day then
            OutputDate := CalcDate(StrSubstNo('<C%1>', BusChartBuf.GetPeriodLength()), OutputDate);
    end;

    local procedure GetAccScheduleAndColumnLayoutForDrillDown(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var BusChartBuf: Record "Business Chart Buffer"; AccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    var
        XName: Variant;
        FromDate: Date;
        ToDate: Date;
        MeasureValueString: Text;
        AccScheduleLineLineNo: Integer;
        ColumnLayoutLineNo: Integer;
    begin
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                begin
                    BusChartBuf."Period Length" := AccountSchedulesChartSetup."Period Length";
                    ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
                    FromDate := BusChartBuf.CalcFromDate(ToDate);
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(AccScheduleLineLineNo, CopyStr(MeasureValueString, 1, StrPos(MeasureValueString, ' ') - 1));
                    AccScheduleLine.Get(AccountSchedulesChartSetup."Account Schedule Name", AccScheduleLineLineNo);
                    Evaluate(ColumnLayoutLineNo, CopyStr(MeasureValueString, StrPos(MeasureValueString, ' ') + 1));
                    ColumnLayout.Get(AccountSchedulesChartSetup."Column Layout Name", ColumnLayoutLineNo);
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line":
                begin
                    FromDate := BusChartBuf."Period Filter Start Date";
                    ToDate := BusChartBuf."Period Filter End Date";
                    AccountSchedulesChartSetup.FilterAccSchedLines(AccScheduleLine);
                    BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", XName);
                    AccScheduleLine.SetRange(Description, Format(XName));
                    AccScheduleLine.FindFirst();
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(ColumnLayoutLineNo, MeasureValueString);
                    ColumnLayout.Get(AccountSchedulesChartSetup."Column Layout Name", ColumnLayoutLineNo);
                end;
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                begin
                    FromDate := BusChartBuf."Period Filter Start Date";
                    ToDate := BusChartBuf."Period Filter End Date";
                    AccountSchedulesChartSetup.FilterColumnLayout(ColumnLayout);
                    BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", XName);
                    ColumnLayout.SetRange("Column Header", Format(XName));
                    ColumnLayout.FindFirst();
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(AccScheduleLineLineNo, MeasureValueString);
                    AccScheduleLine.Get(AccountSchedulesChartSetup."Account Schedule Name", AccScheduleLineLineNo);
                end;
        end;

        AccScheduleLine.SetRange("Date Filter", FromDate, ToDate);
        AccSchedManagement.SetStartDateEndDate(FromDate, ToDate);
    end;

    procedure CheckDuplicateAccScheduleLineDescription(AccScheduleName: Code[10])
    var
        AccScheduleLineQuery: Query "Acc. Sched. Line Desc. Count";
    begin
        AccScheduleLineQuery.SetRange(Schedule_Name, AccScheduleName);
        AccScheduleLineQuery.Open();
        if AccScheduleLineQuery.Read() then
            Error(DuplicateRowDescriptionsMsg, AccScheduleName);
    end;

    procedure CheckDuplicateColumnLayoutColumnHeader(ColumnLayoutName: Code[10])
    var
        ColumnLayoutQuery: Query "Colm. Layt. Colm. Header Count";
    begin
        ColumnLayoutQuery.SetRange(Column_Layout_Name, ColumnLayoutName);
        ColumnLayoutQuery.SetFilter(Column_Header, '<>''''');

        ColumnLayoutQuery.Open();
        if ColumnLayoutQuery.Read() then
            Error(DuplicateColumnHeaderMsg, ColumnLayoutName);
    end;

    local procedure DrillDownOnCFAccount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        CFAccount: Record "Cash Flow Account";
        AccSchedName: Record "Acc. Schedule Name";
        GLAccAnalysisView: Record "G/L Account (Analysis View)";
        ChartOfAccsAnalysisView: Page "Chart of Accs. (Analysis View)";
    begin
        AccSchedManagement.SetCFAccRowFilter(CFAccount, AccScheduleLine);
        AccSchedManagement.SetCFAccColumnFilter(CFAccount, AccScheduleLine, ColumnLayout);
        AccSchedName.Get(AccScheduleLine."Schedule Name");
        if AccSchedName."Analysis View Name" = '' then begin
            CFAccount.FilterGroup(2);
            CFAccount.SetFilter(
              "Global Dimension 1 Filter", AccSchedManagement.GetDimTotalingFilter(1, AccScheduleLine."Dimension 1 Totaling"));
            CFAccount.SetFilter(
              "Global Dimension 2 Filter", AccSchedManagement.GetDimTotalingFilter(2, AccScheduleLine."Dimension 2 Totaling"));
            CFAccount.FilterGroup(8);
            CFAccount.SetFilter(
              "Global Dimension 1 Filter", AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
            CFAccount.SetFilter(
              "Global Dimension 2 Filter", AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
            CFAccount.FilterGroup(0);
            PAGE.Run(PAGE::"Chart of Cash Flow Accounts", CFAccount)
        end else begin
            CFAccount.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
            CFAccount.CopyFilter("Cash Flow Forecast Filter", GLAccAnalysisView."Cash Flow Forecast Filter");
            GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
            GLAccAnalysisView.FilterGroup(2);
            GLAccAnalysisView.SetDimFilters(
              AccSchedManagement.GetDimTotalingFilter(1, AccScheduleLine."Dimension 1 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(2, AccScheduleLine."Dimension 2 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(3, AccScheduleLine."Dimension 3 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(4, AccScheduleLine."Dimension 4 Totaling"));
            GLAccAnalysisView.FilterGroup(8);
            GLAccAnalysisView.SetDimFilters(
              AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
            GLAccAnalysisView.FilterGroup(0);
            Clear(ChartOfAccsAnalysisView);
            ChartOfAccsAnalysisView.InsertTempCFAccountAnalysisVie(CFAccount);
            ChartOfAccsAnalysisView.SetTableView(GLAccAnalysisView);
            ChartOfAccsAnalysisView.Run();
        end;
    end;

    local procedure DrillDownOnCostType(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        CostType: Record "Cost Type";
    begin
        AccSchedManagement.SetCostTypeRowFilters(CostType, AccScheduleLine, ColumnLayout);
        AccSchedManagement.SetCostTypeColumnFilters(CostType, AccScheduleLine, ColumnLayout);
        PAGE.Run(PAGE::"Chart of Cost Types", CostType);
    end;

    local procedure DrillDownOnGLAccount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        GLAcc: Record "G/L Account";
        GLAccAnalysisView: Record "G/L Account (Analysis View)";
        AccSchedName: Record "Acc. Schedule Name";
        ChartOfAccsAnalysisView: Page "Chart of Accs. (Analysis View)";
        Dimension1Totaling: Code[1024];
        Dimension2Totaling: Code[1024];
    begin
        AccSchedManagement.SetGLAccRowFilters(GLAcc, AccScheduleLine);
        AccSchedManagement.SetGLAccColumnFilters(GLAcc, AccScheduleLine, ColumnLayout);
        AccSchedName.Get(AccScheduleLine."Schedule Name");
        if AccSchedName."Analysis View Name" = '' then begin
            GLAcc.FilterGroup(2);
            Dimension1Totaling := AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling");
            Dimension2Totaling := AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling");
            GLAcc.SetFilter("Global Dimension 1 Filter", Dimension1Totaling);
            GLAcc.SetFilter("Global Dimension 2 Filter", Dimension2Totaling);
            GLAcc.FilterGroup(8);
            GLAcc.SetFilter("Business Unit Filter", ColumnLayout."Business Unit Totaling");
            if Dimension1Totaling <> '' then
                GLAcc.SetFilter("Global Dimension 1 Filter", Dimension1Totaling);
            if Dimension2Totaling <> '' then
                GLAcc.SetFilter("Global Dimension 2 Filter", Dimension2Totaling);
            GLAcc.FilterGroup(0);
            PAGE.Run(PAGE::"Chart of Accounts (G/L)", GLAcc)
        end else begin
            GLAcc.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
            GLAcc.CopyFilter("Budget Filter", GLAccAnalysisView."Budget Filter");
            GLAcc.CopyFilter("Business Unit Filter", GLAccAnalysisView."Business Unit Filter");
            GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
            GLAccAnalysisView.FilterGroup(2);
            GLAccAnalysisView.SetDimFilters(
              AccSchedManagement.GetDimTotalingFilter(1, AccScheduleLine."Dimension 1 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(2, AccScheduleLine."Dimension 2 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(3, AccScheduleLine."Dimension 3 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(4, AccScheduleLine."Dimension 4 Totaling"));
            GLAccAnalysisView.FilterGroup(8);
            GLAccAnalysisView.SetDimFilters(
              AccSchedManagement.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
              AccSchedManagement.GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
            GLAccAnalysisView.SetFilter("Business Unit Filter", ColumnLayout."Business Unit Totaling");
            GLAccAnalysisView.FilterGroup(0);
            OnDrillDownOnGLAccountOnBeforeRunChartOfAccsAnalysisView(GLAcc, ColumnLayout);
            Clear(ChartOfAccsAnalysisView);
            ChartOfAccsAnalysisView.InsertTempGLAccAnalysisViews(GLAcc);
            ChartOfAccsAnalysisView.SetTableView(GLAccAnalysisView);
            ChartOfAccsAnalysisView.Run();
        end;
    end;

    procedure SelectAll(AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line"; IsMeasure: Boolean)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Get(AccSchedChartSetupLine."User ID", AccSchedChartSetupLine.Name);
        if IsMeasure then
            AccountSchedulesChartSetup.SetMeasureChartTypesToDefault(AccSchedChartSetupLine)
        else
            AccountSchedulesChartSetup.SetDimensionChartTypesToDefault(AccSchedChartSetupLine);
    end;

    procedure DeselectAll(AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line"; IsMeasure: Boolean)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Get(AccSchedChartSetupLine."User ID", AccSchedChartSetupLine.Name);
        if IsMeasure then
            AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine)
        else
            AccountSchedulesChartSetup.SetLinkToDimensionLines(AccSchedChartSetupLine);
        AccSchedChartSetupLine.ModifyAll("Chart Type", AccSchedChartSetupLine."Chart Type"::" ");
    end;

    procedure GetAccSchedMgtRef(var RefAccSchedManagement: Codeunit AccSchedManagement)
    begin
        RefAccSchedManagement := AccSchedManagement;
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    begin
        if not GLSetupLoaded then begin
            GeneralLedgerSetup.Get();
            GLSetupLoaded := true;
        end;

        exit(Round(Amount, GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownOnGLAccountOnBeforeRunChartOfAccsAnalysisView(var GLAccount: Record "G/L Account"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownTotalingTypeElseCase(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var BusChartBuf: Record "Business Chart Buffer")
    begin
    end;
}

