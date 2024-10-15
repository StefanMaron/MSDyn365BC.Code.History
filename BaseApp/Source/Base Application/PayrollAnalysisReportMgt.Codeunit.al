codeunit 14960 "Payroll Analysis Report Mgt."
{
    TableNo = "Payroll Analysis Line";

    trigger OnRun()
    begin
        SetFilter("Row No.", TryExpression);
    end;

    var
        Text001: Label 'DEFAULT';
        Text002: Label 'Default Lines';
        Text003: Label 'Default Columns';
        Text005: Label 'M';
        Text006: Label 'Q';
        Text007: Label 'Y';
        Text021: Label 'Conversion of dimension totaling filter %1 results in a filter that becomes too long.';
        Text023: Label 'Column formula: %1';
        Text024: Label 'Row formula: %1';
        OrigPayrollAnalysisLineFilters: Record "Payroll Analysis Line";
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
        PayrollAnalysisCellValue: Record "Payroll Analysis Cell Value" temporary;
        StartDate: Date;
        EndDate: Date;
        PayrollStartDate: Date;
        DivisionError: Boolean;
        PeriodError: Boolean;
        FormulaError: Boolean;
        CyclicError: Boolean;
        CallLevel: Integer;
        OldPayrollAnalysisLineFilters: Text;
        OldPayrollAnalysisColumnFilters: Text;
        OldPayrollAnalysisLineTemplate: Code[10];
        TryExpression: Text[250];
        Text025: Label 'Analysis view cannot be used for %1 if %2 is not empty for %3.';
        Text026: Label 'Analysis view cannot be used for %1 if %2 is %3 for %4.';

    [Scope('OnPrem')]
    procedure LookupReportName(var CurrentReportName: Code[10]): Boolean
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        PayrollAnalysisReportName.Name := CurrentReportName;
        if PAGE.RunModal(0, PayrollAnalysisReportName) = ACTION::LookupOK then begin
            CurrentReportName := PayrollAnalysisReportName.Name;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckReportName(CurrentReportName: Code[10])
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        if CurrentReportName <> '' then
            PayrollAnalysisReportName.Get(CurrentReportName);
    end;

    [Scope('OnPrem')]
    procedure OpenAnalysisLines(var CurrentLineTemplate: Code[10]; var PayrollAnalysisLine: Record "Payroll Analysis Line")
    begin
        CheckAnalysisLineTemplName2(CurrentLineTemplate);
        PayrollAnalysisLine.FilterGroup := 2;
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", CurrentLineTemplate);
        PayrollAnalysisLine.FilterGroup := 0;
    end;

    local procedure CheckAnalysisLineTemplName2(var CurrentAnalysisLineTempl: Code[10])
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        if not PayrollAnalysisLineTemplate.Get(CurrentAnalysisLineTempl) then begin
            if not PayrollAnalysisLineTemplate.FindFirst then begin
                PayrollAnalysisLineTemplate.Init();
                PayrollAnalysisLineTemplate.Name := Text001;
                PayrollAnalysisLineTemplate.Description := Text002;
                PayrollAnalysisLineTemplate.Insert(true);
                Commit();
            end;
            CurrentAnalysisLineTempl := PayrollAnalysisLineTemplate.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAnalysisLineTemplName(CurrentAnalysisLineTempl: Code[10]; var PayrollAnalysisLine: Record "Payroll Analysis Line")
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        PayrollAnalysisLineTemplate.Get(CurrentAnalysisLineTempl);
    end;

    [Scope('OnPrem')]
    procedure SetAnalysisLineTemplName(CurrentAnalysisLineTempl: Code[10]; var PayrollAnalysisLine: Record "Payroll Analysis Line")
    begin
        PayrollAnalysisLine.FilterGroup := 2;
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", CurrentAnalysisLineTempl);
        PayrollAnalysisLine.FilterGroup := 0;
        if PayrollAnalysisLine.FindFirst then;
    end;

    [Scope('OnPrem')]
    procedure LookupAnalysisLineTemplName(var CurrentAnalysisLineTempl: Code[10]; var PayrollAnalysisLine: Record "Payroll Analysis Line"): Boolean
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        Commit();
        PayrollAnalysisLineTemplate.Name := PayrollAnalysisLine.GetRangeMax("Analysis Line Template Name");
        if PAGE.RunModal(0, PayrollAnalysisLineTemplate) = ACTION::LookupOK then begin
            CheckAnalysisLineTemplName(PayrollAnalysisLineTemplate.Name, PayrollAnalysisLine);
            CurrentAnalysisLineTempl := PayrollAnalysisLineTemplate.Name;
            SetAnalysisLineTemplName(CurrentAnalysisLineTempl, PayrollAnalysisLine);
            exit(true);
        end;
        OpenAnalysisLines(CurrentAnalysisLineTempl, PayrollAnalysisLine);
    end;

    [Scope('OnPrem')]
    procedure OpenAnalysisLinesForm(var PayrollAnalysisLine2: Record "Payroll Analysis Line"; CurrentAnalysisLineTempl: Code[10])
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisLines: Page "Payroll Analysis Lines";
    begin
        Commit();
        PayrollAnalysisLine.Copy(PayrollAnalysisLine2);
        PayrollAnalysisLines.SetCurrentAnalysisLineTempl(CurrentAnalysisLineTempl);
        PayrollAnalysisLines.SetTableView(PayrollAnalysisLine);
        PayrollAnalysisLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure OpenAnalysisColumnsForm(var PayrollAnalysisLine: Record "Payroll Analysis Line"; CurrentColumnTempl: Code[10])
    var
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
        PayrollAnalysisColumns: Page "Payroll Analysis Columns";
    begin
        Commit();
        PayrollAnalysisColumns.SetTableView(PayrollAnalysisColumn);
        PayrollAnalysisColumns.SetCurrentColumnName(CurrentColumnTempl);
        PayrollAnalysisColumns.RunModal;
    end;

    [Scope('OnPrem')]
    procedure OpenColumns(var CurrentColumnTempl: Code[10]; var PayrollAnalysisLine: Record "Payroll Analysis Line"; var PayrollAnalysisColumn: Record "Payroll Analysis Column")
    begin
        CheckColumnTemplate(CurrentColumnTempl);
        PayrollAnalysisColumn.FilterGroup := 2;
        PayrollAnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTempl);
        PayrollAnalysisColumn.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure OpenColumns2(CurrentColumnTempl: Code[10]; var PayrollAnalysisColumn: Record "Payroll Analysis Column")
    begin
        PayrollAnalysisColumn.FilterGroup := 2;
        PayrollAnalysisColumn.SetRange("Analysis Column Template", CurrentColumnTempl);
        PayrollAnalysisColumn.FilterGroup := 0;
    end;

    local procedure CheckColumnTemplate(var CurrentColumnName: Code[10])
    var
        PayrollAnalysisColumnTemplate: Record "Payroll Analysis Column Tmpl.";
    begin
        if not PayrollAnalysisColumnTemplate.Get(CurrentColumnName) then begin
            if not PayrollAnalysisColumnTemplate.FindFirst then begin
                PayrollAnalysisColumnTemplate.Init();
                PayrollAnalysisColumnTemplate.Name := Text001;
                PayrollAnalysisColumnTemplate.Description := Text003;
                PayrollAnalysisColumnTemplate.Insert(true);
                Commit();
            end;
            CurrentColumnName := PayrollAnalysisColumnTemplate.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetColumnTemplate(CurrentColumnTemplate: Code[10])
    var
        PayrollAnalysisColumnTemplate: Record "Payroll Analysis Column Tmpl.";
    begin
        PayrollAnalysisColumnTemplate.Get(CurrentColumnTemplate);
    end;

    [Scope('OnPrem')]
    procedure SetColumnName(CurrentColumnName: Code[10]; var PayrollAnalysisColumn: Record "Payroll Analysis Column")
    begin
        PayrollAnalysisColumn.FilterGroup := 2;
        PayrollAnalysisColumn.SetRange("Analysis Column Template", CurrentColumnName);
        PayrollAnalysisColumn.FilterGroup := 0;
        if PayrollAnalysisColumn.FindFirst then;
    end;

    [Scope('OnPrem')]
    procedure LookupColumnName(var CurrentColumnName: Code[10]): Boolean
    var
        PayrollAnalysisColumnTemplate: Record "Payroll Analysis Column Tmpl.";
    begin
        PayrollAnalysisColumnTemplate.Name := CurrentColumnName;
        if PAGE.RunModal(0, PayrollAnalysisColumnTemplate) = ACTION::LookupOK then begin
            CurrentColumnName := PayrollAnalysisColumnTemplate.Name;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyColumnsToTemp(var PayrollAnalysisLine: Record "Payroll Analysis Line"; ColumnName: Code[10]; var TempPayrollAnalysisColumn: Record "Payroll Analysis Column")
    var
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
    begin
        TempPayrollAnalysisColumn.DeleteAll();
        PayrollAnalysisColumn.SetRange("Analysis Column Template", ColumnName);
        if PayrollAnalysisColumn.FindSet then
            repeat
                TempPayrollAnalysisColumn := PayrollAnalysisColumn;
                TempPayrollAnalysisColumn.Insert();
            until PayrollAnalysisColumn.Next() = 0;
        if TempPayrollAnalysisColumn.FindFirst then;
    end;

    [Scope('OnPrem')]
    procedure FindPayrollYear(BalanceDate: Date): Date
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.SetCurrentKey("Starting Date");
        PayrollPeriod.SetRange("New Payroll Year", true);
        PayrollPeriod.SetRange("Starting Date", 0D, BalanceDate);
        if PayrollPeriod.FindLast then
            exit(PayrollPeriod."Starting Date");
        PayrollPeriod.Reset();
        PayrollPeriod.FindFirst;
        exit(PayrollPeriod."Starting Date");
    end;

    local procedure FindEndOfPayrollYear(BalanceDate: Date): Date
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.SetRange("New Payroll Year", true);
        PayrollPeriod.SetFilter("Starting Date", '>%1', FindPayrollYear(BalanceDate));
        if PayrollPeriod.FindFirst then
            exit(CalcDate('<-1D>', PayrollPeriod."Starting Date"));
        exit(99991231D);
    end;

    local procedure AccPeriodStartEnd(Formula: Code[20]; Date: Date; var StartDate: Date; var EndDate: Date)
    var
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
        PayrollPeriod: Record "Payroll Period";
        PayrollPeriodPY: Record "Payroll Period";
        Steps: Integer;
        Type: Option " ",Period,"Payroll Year","Payroll Halfyear","Payroll Quarter";
        CurrentPeriodNo: Integer;
        RangeFromType: Option Int,CP,LP;
        RangeToType: Option Int,CP,LP;
        RangeFromInt: Integer;
        RangeToInt: Integer;
    begin
        if Formula = '' then
            exit;

        PayrollAnalysisColumn.ParsePeriodFormula(
          Formula, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);

        // Find current period
        PayrollPeriod.SetFilter("Starting Date", '<=%1', Date);
        if not PayrollPeriod.Find('+') then begin
            PayrollPeriod.Reset();
            if Steps < 0 then
                PayrollPeriod.Find('-')
            else
                PayrollPeriod.Find('+')
        end;
        PayrollPeriod.Reset();

        case Type of
            Type::Period:
                begin
                    if PayrollPeriod.Next(Steps) <> Steps then
                        PeriodError := true;
                    StartDate := PayrollPeriod."Starting Date";
                    EndDate := PayrollPeriod."Ending Date";
                end;
            Type::"Payroll Year":
                begin
                    PayrollPeriodPY := PayrollPeriod;
                    while not PayrollPeriodPY."New Payroll Year" do
                        if PayrollPeriodPY.Find('<') then
                            CurrentPeriodNo += 1
                        else
                            PayrollPeriodPY."New Payroll Year" := true;
                    PayrollPeriodPY.SetRange("New Payroll Year", true);
                    PayrollPeriodPY.Next(Steps);

                    AccPeriodStartOrEnd(PayrollPeriodPY, CurrentPeriodNo, RangeFromType, RangeFromInt, false, StartDate);
                    AccPeriodStartOrEnd(PayrollPeriodPY, CurrentPeriodNo, RangeToType, RangeToInt, true, EndDate);
                end;
        end;
    end;

    local procedure AccPeriodEndDate(StartDate: Date): Date
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod."Starting Date" := StartDate;
        if PayrollPeriod.Find('>') then
            exit(PayrollPeriod."Starting Date" - 1);
        exit(99991231D);
    end;

    local procedure AccPeriodGetPeriod(var PayrollPeriod: Record "Payroll Period"; AccPeriodNo: Integer)
    begin
        case true of
            AccPeriodNo > 0:
                begin
                    PayrollPeriod.Next(AccPeriodNo);
                    exit;
                end;
            AccPeriodNo = 0:
                exit;
            AccPeriodNo < 0:
                begin
                    PayrollPeriod.SetRange("New Payroll Year", true);
                    if not PayrollPeriod.Find('>') then begin
                        PayrollPeriod.Reset();
                        PayrollPeriod.Find('+');
                        exit;
                    end;
                    PayrollPeriod.Reset();
                    PayrollPeriod.Find('<');
                    exit;
                end;
        end;
    end;

    local procedure AccPeriodStartOrEnd(PayrollPeriod: Record "Payroll Period"; CurrentPeriodNo: Integer; RangeType: Option Int,CP,LP; RangeInt: Integer; EndDate: Boolean; var Date: Date)
    begin
        case RangeType of
            RangeType::CP:
                AccPeriodGetPeriod(PayrollPeriod, CurrentPeriodNo);
            RangeType::LP:
                AccPeriodGetPeriod(PayrollPeriod, -1);
            RangeType::Int:
                AccPeriodGetPeriod(PayrollPeriod, RangeInt - 1);
        end;
        if EndDate then
            Date := AccPeriodEndDate(PayrollPeriod."Starting Date")
        else
            Date := PayrollPeriod."Starting Date";
    end;

    [Scope('OnPrem')]
    procedure CalcCell(var PayrollAnalysisLine: Record "Payroll Analysis Line"; var PayrollAnalysisColumn: Record "Payroll Analysis Column"; DrillDown: Boolean): Decimal
    var
        Result: Decimal;
    begin
        if DrillDown and
           ((PayrollAnalysisColumn."Column Type" = PayrollAnalysisColumn."Column Type"::Formula) or
            (PayrollAnalysisLine.Type = PayrollAnalysisLine.Type::Formula))
        then begin
            if PayrollAnalysisColumn."Column Type" = PayrollAnalysisColumn."Column Type"::Formula then
                Message(Text023, PayrollAnalysisColumn.Formula)
            else
                Message(Text024, PayrollAnalysisLine.Expression);
            exit(0);
        end;

        OrigPayrollAnalysisLineFilters.CopyFilters(PayrollAnalysisLine);

        StartDate := PayrollAnalysisLine.GetRangeMin("Date Filter");
        if EndDate <> PayrollAnalysisLine.GetRangeMax("Date Filter") then begin
            EndDate := PayrollAnalysisLine.GetRangeMax("Date Filter");
            PayrollStartDate := FindPayrollYear(EndDate);
        end;
        DivisionError := false;
        PeriodError := false;
        FormulaError := false;
        CyclicError := false;
        CallLevel := 0;

        if (OldPayrollAnalysisLineFilters <> PayrollAnalysisLine.GetFilters) or
           (OldPayrollAnalysisColumnFilters <> PayrollAnalysisColumn.GetFilters) or
           (OldPayrollAnalysisLineTemplate <> PayrollAnalysisLine."Analysis Line Template Name") or
           (OldPayrollAnalysisLineTemplate <> PayrollAnalysisColumn."Analysis Column Template")
        then begin
            PayrollAnalysisCellValue.Reset();
            PayrollAnalysisCellValue.DeleteAll();
            OldPayrollAnalysisLineFilters := PayrollAnalysisLine.GetFilters;
            OldPayrollAnalysisColumnFilters := PayrollAnalysisColumn.GetFilters;
            OldPayrollAnalysisLineTemplate := PayrollAnalysisLine."Analysis Line Template Name";
            OldPayrollAnalysisLineTemplate := PayrollAnalysisColumn."Analysis Column Template";
        end;

        Result := CalcCellValue(PayrollAnalysisLine, PayrollAnalysisColumn, DrillDown);
        with PayrollAnalysisColumn do begin
            case Show of
                Show::"When Positive":
                    if Result < 0 then
                        Result := 0;
                Show::"When Negative":
                    if Result > 0 then
                        Result := 0;
            end;
            if "Show Opposite Sign" then
                Result := -Result;
        end;
        if PayrollAnalysisLine."Show Opposite Sign" then
            Result := -Result;
        exit(Result);
    end;

    local procedure CalcCellValue(PayrollAnalysisLine: Record "Payroll Analysis Line"; PayrollAnalysisColumn: Record "Payroll Analysis Column"; DrillDown: Boolean): Decimal
    var
        PayrollStatisticsBuf: Record "Payroll Statistics Buffer";
        Result: Decimal;
    begin
        Result := 0;
        if PayrollAnalysisLine.Expression <> '' then begin
            case true of
                PayrollAnalysisCellValue.Get(PayrollAnalysisLine."Line No.", PayrollAnalysisColumn."Line No.") and not DrillDown:
                    begin
                        Result := PayrollAnalysisCellValue.Value;
                        DivisionError := DivisionError or PayrollAnalysisCellValue.Error;
                        PeriodError := PeriodError or PayrollAnalysisCellValue."Period Error";
                        FormulaError := FormulaError or PayrollAnalysisCellValue."Formula Error";
                        CyclicError := CyclicError or PayrollAnalysisCellValue."Cyclic Error";
                        exit(Result);
                    end;
                PayrollAnalysisColumn."Column Type" = PayrollAnalysisColumn."Column Type"::Formula:
                    Result :=
                      EvaluateExpression(
                        false, PayrollAnalysisColumn.Formula, PayrollAnalysisLine, PayrollAnalysisColumn);
                PayrollAnalysisLine.Type = PayrollAnalysisLine.Type::Formula:
                    Result :=
                      EvaluateExpression(
                        true, PayrollAnalysisLine.Expression, PayrollAnalysisLine, PayrollAnalysisColumn);
                (StartDate = 0D) or (EndDate in [0D, 99991231D]):
                    begin
                        Result := 0;
                        PeriodError := true;
                    end;
                else
                    if PayrollAnalysisLineTemplate.Name <> PayrollAnalysisLine."Analysis Line Template Name" then
                        PayrollAnalysisLineTemplate.Get(PayrollAnalysisLine."Analysis Line Template Name");
                    PayrollAnalysisLine.CopyFilters(OrigPayrollAnalysisLineFilters);
                    SetRowFilters(PayrollStatisticsBuf, PayrollAnalysisLine);
                    SetColumnFilters(PayrollStatisticsBuf, PayrollAnalysisColumn);

                    Result := Result + CalcPayrollStatistics(PayrollStatisticsBuf, PayrollAnalysisLine, PayrollAnalysisColumn, DrillDown);
            end;

            if not DrillDown then begin
                PayrollAnalysisCellValue."Row No." := PayrollAnalysisLine."Line No.";
                PayrollAnalysisCellValue."Column No." := PayrollAnalysisColumn."Line No.";
                PayrollAnalysisCellValue.Value := Result;
                PayrollAnalysisCellValue.Error := DivisionError;
                PayrollAnalysisCellValue."Period Error" := PeriodError;
                PayrollAnalysisCellValue."Formula Error" := FormulaError;
                PayrollAnalysisCellValue."Cyclic Error" := CyclicError;
                if PayrollAnalysisCellValue.Insert() then;
            end;
        end;
        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure SetRowFilters(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; var PayrollAnalysisLine: Record "Payroll Analysis Line")
    begin
        with PayrollAnalysisLine do begin
            if "Element Type Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Element Type Filter", "Element Type Filter");

            if "Element Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Element Filter", "Element Filter");

            if "Calc Group Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Calc Group Filter", "Calc Group Filter");

            case "Use PF Accum. System Filter" of
                "Use PF Accum. System Filter"::Yes:
                    PayrollStatisticsBuf.SetRange("Use PF Accum. System Filter", true);
                "Use PF Accum. System Filter"::No:
                    PayrollStatisticsBuf.SetRange("Use PF Accum. System Filter", false);
            end;

            case Type of
                Type::"Payroll Element":
                    PayrollStatisticsBuf.SetFilter("Element Filter", Expression);
                Type::"Payroll Element Group":
                    PayrollStatisticsBuf.SetFilter("Element Group Filter", Expression);
                Type::Employee:
                    PayrollStatisticsBuf.SetFilter("Employee Filter", Expression);
                Type::"Org. Unit":
                    PayrollStatisticsBuf.SetFilter("Org. Unit Filter", Expression);
            end;

            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                CheckLineFilters(PayrollAnalysisLine);

            case "Income Tax Base Filter" of
                "Income Tax Base Filter"::Yes:
                    PayrollStatisticsBuf.SetRange("Income Tax Base Filter", true);
                "Income Tax Base Filter"::No:
                    PayrollStatisticsBuf.SetRange("Income Tax Base Filter", false);
            end;

            if "Work Mode Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Work Mode Filter", "Work Mode Filter");

            if "Disability Group Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Disability Group Filter", "Disability Group Filter");

            if "Contract Type Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Contract Type Filter", "Contract Type Filter");

            if "Payment Source Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Payment Source Filter", "Payment Source Filter");

            if "Insurance Fee Category Filter" <> '' then
                PayrollStatisticsBuf.SetFilter("Insurance Fee Category Filter", "Insurance Fee Category Filter");

            if GetFilter("Employee Filter") <> '' then begin
                PayrollStatisticsBuf.FilterGroup := 2;
                CopyFilter("Employee Filter", PayrollStatisticsBuf."Employee Filter");
                PayrollStatisticsBuf.FilterGroup := 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetColumnFilters(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; var PayrollAnalysisColumn: Record "Payroll Analysis Column")
    var
        FromDate: Date;
        ToDate: Date;
        PayrollStartDate2: Date;
    begin
        with PayrollAnalysisColumn do begin
            if (Format("Comparison Date Formula") <> '0') and (Format("Comparison Date Formula") <> '') then begin
                FromDate := CalcDate("Comparison Date Formula", StartDate);
                if (EndDate = CalcDate('<CM>', EndDate)) and
                   ((StrPos(Format("Comparison Date Formula"), Text005) > 0) or
                    (StrPos(Format("Comparison Date Formula"), Text006) > 0) or
                    (StrPos(Format("Comparison Date Formula"), Text007) > 0))
                then
                    ToDate := CalcDate('<CM>', CalcDate("Comparison Date Formula", EndDate))
                else
                    ToDate := CalcDate("Comparison Date Formula", EndDate);
                PayrollStartDate2 := FindPayrollYear(ToDate);
            end else
                if "Comparison Period Formula" <> '' then begin
                    AccPeriodStartEnd("Comparison Period Formula", StartDate, FromDate, ToDate);
                    PayrollStartDate2 := FindPayrollYear(ToDate);
                end else begin
                    FromDate := StartDate;
                    ToDate := EndDate;
                    PayrollStartDate2 := PayrollStartDate;
                end;
            case "Column Type" of
                "Column Type"::"Net Change":
                    PayrollStatisticsBuf.SetRange("Date Filter", FromDate, ToDate);
                "Column Type"::"Balance at Date":
                    PayrollStatisticsBuf.SetRange("Date Filter", 0D, ToDate);
                "Column Type"::"Beginning Balance":
                    PayrollStatisticsBuf.SetRange(
                      "Date Filter", 0D, CalcDate('<-1D>', FromDate));
                "Column Type"::"Year to Date":
                    PayrollStatisticsBuf.SetRange(
                      "Date Filter", PayrollStartDate2, ToDate);
                "Column Type"::"Rest of Payroll Year":
                    PayrollStatisticsBuf.SetRange(
                      "Date Filter",
                      CalcDate('<+1D>', ToDate),
                      FindEndOfPayrollYear(PayrollStartDate2));
                "Column Type"::"Entire Payroll Year":
                    PayrollStatisticsBuf.SetRange(
                      "Date Filter",
                      PayrollStartDate2,
                      FindEndOfPayrollYear(PayrollStartDate2));
            end;
        end;
    end;

    local procedure EvaluateExpression(IsAnalysisLineExpression: Boolean; Expression: Text[250]; PayrollAnalysisLine: Record "Payroll Analysis Line"; PayrollAnalysisColumn: Record "Payroll Analysis Column"): Decimal
    var
        Result: Decimal;
        Parentheses: Integer;
        Operator: Char;
        LeftOperand: Text[250];
        RightOperand: Text[250];
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        PayrollAnalysisLineID: Integer;
    begin
        Result := 0;

        CallLevel := CallLevel + 1;
        if CallLevel > 25 then begin
            CyclicError := true;
            exit;
        end;

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Parentheses := 0;
            IsExpression := false;
            Operators := '+-*/^';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parentheses := Parentheses + 1
                    else
                        if Expression[i] = ')' then
                            Parentheses := Parentheses - 1;
                    if (Parentheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                        IsExpression := true
                    else
                        i := i - 1;
                until IsExpression or (i <= 0);
                if not IsExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or IsExpression;
            if IsExpression then begin
                if i > 1 then
                    LeftOperand := CopyStr(Expression, 1, i - 1)
                else
                    LeftOperand := '';
                if i < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, i + 1)
                else
                    RightOperand := '';
                Operator := Expression[i];
                LeftResult :=
                  EvaluateExpression(
                    IsAnalysisLineExpression, LeftOperand, PayrollAnalysisLine, PayrollAnalysisColumn);
                RightResult :=
                  EvaluateExpression(
                    IsAnalysisLineExpression, RightOperand, PayrollAnalysisLine, PayrollAnalysisColumn);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then begin
                            Result := 0;
                            DivisionError := true;
                        end else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvaluateExpression(
                        IsAnalysisLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        PayrollAnalysisLine, PayrollAnalysisColumn)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 10) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else
                        if IsAnalysisLineExpression then begin
                            PayrollAnalysisLine.SetRange("Analysis Line Template Name", PayrollAnalysisLine."Analysis Line Template Name");
                            PayrollAnalysisLine.SetFilter("Row No.", Expression);
                            PayrollAnalysisLineID := PayrollAnalysisLine."Line No.";
                            if not FormulaError then begin
                                if PayrollAnalysisLine.FindSet then
                                    repeat
                                        if PayrollAnalysisLine."Line No." <> PayrollAnalysisLineID then
                                            Result := Result + CalcCellValue(PayrollAnalysisLine, PayrollAnalysisColumn, false);
                                    until PayrollAnalysisLine.Next() = 0
                                else
                                    if IsFilter or (not Evaluate(Result, Expression)) then
                                        FormulaError := true;
                            end;
                        end else begin
                            PayrollAnalysisColumn.SetRange("Analysis Column Template", PayrollAnalysisColumn."Analysis Column Template");
                            PayrollAnalysisColumn.SetFilter("Column No.", Expression);
                            PayrollAnalysisLineID := PayrollAnalysisColumn."Line No.";
                            if not FormulaError then begin
                                if PayrollAnalysisColumn.FindSet then
                                    repeat
                                        if PayrollAnalysisColumn."Line No." <> PayrollAnalysisLineID then
                                            Result := Result + CalcCellValue(PayrollAnalysisLine, PayrollAnalysisColumn, false);
                                    until PayrollAnalysisColumn.Next() = 0
                                else
                                    if IsFilter or (not Evaluate(Result, Expression)) then
                                        FormulaError := true;
                            end;
                        end;
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    local procedure CalcPayrollStatistics(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; var PayrollAnalysisLine: Record "Payroll Analysis Line"; var PayrollAnalysisColumn: Record "Payroll Analysis Column"; DrillDown: Boolean): Decimal
    var
        ColValue: Decimal;
    begin
        ColValue := 0;

        if PayrollAnalysisLineTemplate.Name <> PayrollAnalysisLine."Analysis Line Template Name" then
            PayrollAnalysisLineTemplate.Get(PayrollAnalysisLine."Analysis Line Template Name");

        if PayrollAnalysisColumn."Column Type" <> PayrollAnalysisColumn."Column Type"::Formula then begin
            with PayrollStatisticsBuf do
                if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                    PayrollAnalysisLine.CopyFilter("Dimension 1 Filter", "Global Dimension 1 Filter");
                    PayrollAnalysisLine.CopyFilter("Dimension 2 Filter", "Global Dimension 2 Filter");
                    if "Employee Filter" <> '' then
                        PayrollAnalysisLine.CopyFilter("Employee Filter", "Employee Filter");
                    PayrollAnalysisLine.CopyFilter("Insurance Fee Category Filter", "Insurance Fee Category Filter");
                    FilterGroup := 2;
                    SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 1 Totaling"));
                    SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 2 Totaling"));
                    FilterGroup := 0;
                end else begin
                    SetFilter("Analysis View Filter", PayrollAnalysisLineTemplate."Payroll Analysis View Code");
                    PayrollAnalysisLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Filter");
                    PayrollAnalysisLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Filter");
                    PayrollAnalysisLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Filter");
                    PayrollAnalysisLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Filter");
                    FilterGroup := 2;
                    SetFilter("Dimension 1 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 1 Totaling"));
                    SetFilter("Dimension 2 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 2 Totaling"));
                    SetFilter("Dimension 3 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 3 Totaling"));
                    SetFilter("Dimension 4 Filter", GetDimTotalingFilter(PayrollAnalysisLine."Dimension 4 Totaling"));
                    FilterGroup := 0;
                end;

            if DrillDown then
                DrillDownAmount(PayrollStatisticsBuf, PayrollAnalysisColumn)
            else
                case PayrollAnalysisColumn."Amount Type" of
                    PayrollAnalysisColumn."Amount Type"::"Payroll Amount":
                        ColValue := CalcPayrollAmount(PayrollStatisticsBuf);
                    PayrollAnalysisColumn."Amount Type"::"Taxable Amount":
                        ColValue := CalcTaxableAmount(PayrollStatisticsBuf);
                    PayrollAnalysisColumn."Amount Type"::Quantity:
                        begin
                            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                                Error(
                                  Text026,
                                  PayrollAnalysisLineTemplate.GetRecDescription,
                                  PayrollAnalysisColumn.FieldCaption("Amount Type"),
                                  PayrollAnalysisColumn."Amount Type",
                                  PayrollAnalysisColumn.GetRecDescription);

                            ColValue := CalcQuantity(PayrollStatisticsBuf);
                        end;
                    PayrollAnalysisColumn."Amount Type"::"Payment Days":
                        begin
                            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                                Error(
                                  Text026,
                                  PayrollAnalysisLineTemplate.GetRecDescription,
                                  PayrollAnalysisColumn.FieldCaption("Amount Type"),
                                  PayrollAnalysisColumn."Amount Type",
                                  PayrollAnalysisColumn.GetRecDescription);

                            ColValue := CalcPaymentDays(PayrollStatisticsBuf);
                        end;
                    PayrollAnalysisColumn."Amount Type"::"Number of Employees":
                        begin
                            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                                Error(
                                  Text026,
                                  PayrollAnalysisLineTemplate.GetRecDescription,
                                  PayrollAnalysisColumn.FieldCaption("Amount Type"),
                                  PayrollAnalysisColumn."Amount Type",
                                  PayrollAnalysisColumn.GetRecDescription);

                            ColValue := CalcNumberOfEmployees(PayrollStatisticsBuf);
                        end;
                end;
        end;
        exit(ColValue);
    end;

    [Scope('OnPrem')]
    procedure IsValidAnalysisExpression(var PayrollAnalysisLine: Record "Payroll Analysis Line"; Expression: Text[250]): Boolean
    var
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
    begin
        PayrollAnalysisReportMgt.SetExpression(Expression);
        if PayrollAnalysisReportMgt.Run(PayrollAnalysisLine) then
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetDimTotalingFilter(DimTotaling: Text[80]): Text[1024]
    var
        DimTotaling2: Text[80];
        DimTotalPart: Text[80];
        ResultFilter: Text;
        ResultFilter2: Text;
        i: Integer;
    begin
        if DimTotaling = '' then
            exit(DimTotaling);
        DimTotaling2 := DimTotaling;
        repeat
            i := StrPos(DimTotaling2, '|');
            if i > 0 then begin
                DimTotalPart := CopyStr(DimTotaling2, 1, i - 1);
                if i < StrLen(DimTotaling2) then
                    DimTotaling2 := CopyStr(DimTotaling2, i + 1)
                else
                    DimTotaling2 := '';
            end else
                DimTotalPart := DimTotaling2;
            ResultFilter2 := ConvDimTotalingFilter(DimTotalPart);
            if ResultFilter2 <> '' then
                if StrLen(ResultFilter) + StrLen(ResultFilter2) + 1 > MaxStrLen(ResultFilter) then
                    Error(Text021, DimTotaling);

            if ResultFilter <> '' then
                ResultFilter := ResultFilter + '|';
            ResultFilter := ResultFilter + ResultFilter2;
        until i <= 0;
        exit(ResultFilter);
    end;

    local procedure ConvDimTotalingFilter(DimTotaling: Text[80]): Text
    var
        DimVal: Record "Dimension Value";
        DimCode: Code[20];
        ResultFilter: Text[1024];
        DimValTotaling: Boolean;
    begin
        if DimTotaling = '' then
            exit(DimTotaling);

        if DimCode = '' then
            exit(DimTotaling);

        DimVal.SetRange("Dimension Code", DimCode);
        DimVal.SetFilter(Code, DimTotaling);
        if DimVal.FindSet then
            repeat
                DimValTotaling :=
                  DimVal."Dimension Value Type" in
                  [DimVal."Dimension Value Type"::Total, DimVal."Dimension Value Type"::"End-Total"];
                if DimValTotaling and (DimVal.Totaling <> '') then begin
                    if StrLen(ResultFilter) + StrLen(DimVal.Totaling) + 1 > MaxStrLen(ResultFilter) then
                        Error(Text021, DimTotaling);
                    if ResultFilter <> '' then
                        ResultFilter := ResultFilter + '|';
                    ResultFilter := ResultFilter + DimVal.Totaling;
                end;
            until (DimVal.Next() = 0) or not DimValTotaling;

        if DimValTotaling then
            exit(ResultFilter);

        exit(DimTotaling);
    end;

    local procedure CalcPayrollAmount(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"): Decimal
    begin
        with PayrollStatisticsBuf do begin
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                CalcFields("Payroll Amount");
                exit("Payroll Amount");
            end;

            CalcFields("Analysis - Payroll Amount");
            exit("Analysis - Payroll Amount");
        end;
    end;

    local procedure CalcTaxableAmount(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"): Decimal
    begin
        with PayrollStatisticsBuf do begin
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                CalcFields("Taxable Amount");
                exit("Taxable Amount");
            end;

            CalcFields("Analysis - Taxable Amount");
            exit("Analysis - Taxable Amount");
        end;
    end;

    local procedure CalcQuantity(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"): Decimal
    begin
        with PayrollStatisticsBuf do
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                CalcFields(Quantity);
                exit(Quantity);
            end;
    end;

    local procedure CalcPaymentDays(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"): Decimal
    begin
        with PayrollStatisticsBuf do
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                CalcFields("Payment Days");
                exit("Payment Days");
            end;
    end;

    local procedure CalcNumberOfEmployees(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"): Decimal
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        TempEmployee: Record Employee temporary;
    begin
        if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
            FilterPayrolLedterEntry(PayrollStatisticsBuf, PayrollLedgerEntry);
            if PayrollLedgerEntry.FindSet then
                repeat
                    if not TempEmployee.Get(PayrollLedgerEntry."Employee No.") then begin
                        TempEmployee."No." := PayrollLedgerEntry."Employee No.";
                        TempEmployee.Insert();
                    end;
                until PayrollLedgerEntry.Next() = 0;
            exit(TempEmployee.Count);
        end;
    end;

    local procedure DrillDownAmount(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; PayrollAnalysisColumn: Record "Payroll Analysis Column")
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
    begin
        with PayrollStatisticsBuf do
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" = '' then begin
                FilterPayrolLedterEntry(PayrollStatisticsBuf, PayrollLedgerEntry);
                case PayrollAnalysisColumn."Amount Type" of
                    PayrollAnalysisColumn."Amount Type"::"Payroll Amount":
                        PAGE.Run(0, PayrollLedgerEntry, PayrollLedgerEntry."Payroll Amount");
                    PayrollAnalysisColumn."Amount Type"::"Taxable Amount":
                        PAGE.Run(0, PayrollLedgerEntry, PayrollLedgerEntry."Taxable Amount");
                    PayrollAnalysisColumn."Amount Type"::Quantity:
                        PAGE.Run(0, PayrollLedgerEntry, PayrollLedgerEntry.Quantity);
                    PayrollAnalysisColumn."Amount Type"::"Payment Days":
                        PAGE.Run(0, PayrollLedgerEntry, PayrollLedgerEntry."Payment Days");
                end
            end else begin
                FilterPayrollAnalyViewEntry(PayrollStatisticsBuf, PayrollAnalysisViewEntry);
                case PayrollAnalysisColumn."Amount Type" of
                    PayrollAnalysisColumn."Amount Type"::"Payroll Amount":
                        PAGE.Run(0, PayrollAnalysisViewEntry, PayrollAnalysisViewEntry."Payroll Amount");
                    PayrollAnalysisColumn."Amount Type"::"Taxable Amount":
                        PAGE.Run(0, PayrollAnalysisViewEntry, PayrollAnalysisViewEntry."Taxable Amount");
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure FilterPayrolLedterEntry(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; var PayrollLedgerEntry: Record "Payroll Ledger Entry")
    begin
        with PayrollStatisticsBuf do begin
            if GetFilter("Element Type Filter") <> '' then
                CopyFilter("Element Type Filter", PayrollLedgerEntry."Element Type");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", PayrollLedgerEntry."Posting Date");

            if GetFilter("Element Filter") <> '' then
                CopyFilter("Element Filter", PayrollLedgerEntry."Element Code");

            if GetFilter("Calc Group Filter") <> '' then
                CopyFilter("Calc Group Filter", PayrollLedgerEntry."Calc Group");

            if GetFilter("Employee Filter") <> '' then
                CopyFilter("Employee Filter", PayrollLedgerEntry."Employee No.");

            FilterGroup(2);
            if GetFilter("Employee Filter") <> '' then begin
                PayrollLedgerEntry.FilterGroup(2);
                CopyFilter("Employee Filter", PayrollLedgerEntry."Employee No.");
                PayrollLedgerEntry.FilterGroup(0);
            end;
            FilterGroup(0);

            if GetFilter("Org. Unit Filter") <> '' then
                CopyFilter("Org. Unit Filter", PayrollLedgerEntry."Org. Unit Code");

            if GetFilter("Element Group Filter") <> '' then
                CopyFilter("Element Group Filter", PayrollLedgerEntry."Element Group");

            if GetFilter("Use PF Accum. System Filter") <> '' then
                CopyFilter("Use PF Accum. System Filter", PayrollLedgerEntry."Use PF Accum. System");

            if GetFilter("Work Mode Filter") <> '' then
                CopyFilter("Work Mode Filter", PayrollLedgerEntry."Work Mode");

            if GetFilter("Disability Group Filter") <> '' then
                CopyFilter("Disability Group Filter", PayrollLedgerEntry."Disability Group");

            if GetFilter("Contract Type Filter") <> '' then
                CopyFilter("Contract Type Filter", PayrollLedgerEntry."Contract Type");

            if GetFilter("Payment Source Filter") <> '' then
                CopyFilter("Payment Source Filter", PayrollLedgerEntry."Payment Source");

            if GetFilter("Insurance Fee Category Filter") <> '' then
                CopyFilter("Insurance Fee Category Filter", PayrollLedgerEntry."Insurance Fee Category Code");

            if GetFilter("Income Tax Base Filter") <> '' then
                CopyFilter("Income Tax Base Filter", PayrollLedgerEntry."Income Tax Base");

            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", PayrollLedgerEntry."Global Dimension 1 Code");

            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", PayrollLedgerEntry."Global Dimension 2 Code");

            FilterGroup := 2;
            PayrollLedgerEntry.FilterGroup := 2;
            if GetFilter("Global Dimension 1 Filter") <> '' then
                CopyFilter("Global Dimension 1 Filter", PayrollLedgerEntry."Global Dimension 1 Code");
            if GetFilter("Global Dimension 2 Filter") <> '' then
                CopyFilter("Global Dimension 2 Filter", PayrollLedgerEntry."Global Dimension 2 Code");
            FilterGroup := 0;
            PayrollLedgerEntry.FilterGroup := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FilterPayrollAnalyViewEntry(var PayrollStatisticsBuf: Record "Payroll Statistics Buffer"; var PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry")
    begin
        with PayrollStatisticsBuf do begin
            CopyFilter("Analysis View Filter", PayrollAnalysisViewEntry."Analysis View Code");

            if GetFilter("Element Type Filter") <> '' then
                CopyFilter("Element Type Filter", PayrollAnalysisViewEntry."Payroll Element Type");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", PayrollAnalysisViewEntry."Posting Date");

            if GetFilter("Element Filter") <> '' then
                CopyFilter("Element Filter", PayrollAnalysisViewEntry."Element Code");

            if GetFilter("Calc Group Filter") <> '' then
                CopyFilter("Calc Group Filter", PayrollAnalysisViewEntry."Calc Group");

            if GetFilter("Employee Filter") <> '' then
                CopyFilter("Employee Filter", PayrollAnalysisViewEntry."Employee No.");

            FilterGroup(2);
            if GetFilter("Employee Filter") <> '' then begin
                PayrollAnalysisViewEntry.FilterGroup(2);
                CopyFilter("Employee Filter", PayrollAnalysisViewEntry."Employee No.");
                PayrollAnalysisViewEntry.FilterGroup(0);
            end;
            FilterGroup(0);

            if GetFilter("Org. Unit Filter") <> '' then
                CopyFilter("Org. Unit Filter", PayrollAnalysisViewEntry."Org. Unit Code");

            if GetFilter("Element Group Filter") <> '' then
                CopyFilter("Element Group Filter", PayrollAnalysisViewEntry."Element Group");

            if GetFilter("Use PF Accum. System Filter") <> '' then
                CopyFilter("Use PF Accum. System Filter", PayrollAnalysisViewEntry."Use PF Accum. System");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", PayrollAnalysisViewEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", PayrollAnalysisViewEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", PayrollAnalysisViewEntry."Dimension 3 Value Code");

            FilterGroup := 2;
            PayrollAnalysisViewEntry.FilterGroup := 2;
            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", PayrollAnalysisViewEntry."Dimension 1 Value Code");
            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", PayrollAnalysisViewEntry."Dimension 2 Value Code");
            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", PayrollAnalysisViewEntry."Dimension 3 Value Code");
            FilterGroup := 0;
            PayrollAnalysisViewEntry.FilterGroup := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetExpression(Expression: Text[250])
    begin
        TryExpression := Expression;
    end;

    [Scope('OnPrem')]
    procedure GetDivisionError(): Boolean
    begin
        exit(DivisionError);
    end;

    [Scope('OnPrem')]
    procedure GetPeriodError(): Boolean
    begin
        exit(PeriodError);
    end;

    [Scope('OnPrem')]
    procedure GetFormulaError(): Boolean
    begin
        exit(FormulaError);
    end;

    [Scope('OnPrem')]
    procedure GetCyclicError(): Boolean
    begin
        exit(CyclicError);
    end;

    [Scope('OnPrem')]
    procedure ValidateFilter(var "Filter": Text; RecNo: Integer; FieldNumber: Integer; ConvertToNumbers: Boolean)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollStatisticsBuffer: Record "Payroll Statistics Buffer";
    begin
        case RecNo of
            DATABASE::"Payroll Analysis Line":
                case FieldNumber of
                    PayrollAnalysisLine.FieldNo("Element Type Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Element Type Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Element Type Filter");
                        end;
                    PayrollAnalysisLine.FieldNo("Work Mode Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Work Mode Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Work Mode Filter");
                        end;
                    PayrollAnalysisLine.FieldNo("Disability Group Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Disability Group Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Disability Group Filter");
                        end;
                    PayrollAnalysisLine.FieldNo("Contract Type Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Contract Type Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Contract Type Filter");
                        end;
                    PayrollAnalysisLine.FieldNo("Payment Source Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Payment Source Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Payment Source Filter");
                        end;
                    PayrollAnalysisLine.FieldNo("Calc Group Filter"):
                        begin
                            PayrollStatisticsBuffer.SetFilter("Calc Group Filter", Filter);
                            Filter := PayrollStatisticsBuffer.GetFilter("Calc Group Filter");
                        end;
                end;
        end;

        if ConvertToNumbers then
            ConvertOptionNameToNo(Filter, RecNo, FieldNumber);
    end;

    [Scope('OnPrem')]
    procedure ConvertOptionNameToNo(var "Filter": Text[250]; RecNo: Integer; FieldNumber: Integer)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollStatisticsBuffer: Record "Payroll Statistics Buffer";
        VarInteger: Integer;
        OptionNo: Integer;
        OptionName: Text[30];
    begin
        while true do begin
            case RecNo of
                DATABASE::"Payroll Analysis Line":
                    case FieldNumber of
                        PayrollAnalysisLine.FieldNo("Element Type Filter"):
                            begin
                                PayrollStatisticsBuffer."Element Type Filter" := OptionNo;
                                OptionName := Format(PayrollStatisticsBuffer."Element Type Filter");
                            end;
                        PayrollAnalysisLine.FieldNo("Work Mode Filter"):
                            begin
                                PayrollStatisticsBuffer."Work Mode Filter" := OptionNo;
                                OptionName := Format(PayrollStatisticsBuffer."Work Mode Filter");
                            end;
                        PayrollAnalysisLine.FieldNo("Disability Group Filter"):
                            begin
                                PayrollStatisticsBuffer."Disability Group Filter" := OptionNo;
                                OptionName := Format(PayrollStatisticsBuffer."Disability Group Filter");
                            end;
                        PayrollAnalysisLine.FieldNo("Contract Type Filter"):
                            begin
                                PayrollStatisticsBuffer."Contract Type Filter" := OptionNo;
                                OptionName := Format(PayrollStatisticsBuffer."Contract Type Filter");
                            end;
                        PayrollAnalysisLine.FieldNo("Payment Source Filter"):
                            begin
                                PayrollStatisticsBuffer."Payment Source Filter" := OptionNo;
                                OptionName := Format(PayrollStatisticsBuffer."Payment Source Filter");
                            end;
                    end;
            end;

            if Evaluate(VarInteger, OptionName) then
                if VarInteger = OptionNo then
                    exit;

            FindAndReplace(Filter, OptionName, Format(OptionNo));
            OptionNo += 1;
        end;
    end;

    local procedure FindAndReplace(var "Filter": Text[250]; FindWhat: Text[30]; ReplaceWith: Text[30])
    var
        Position: Integer;
    begin
        while true do begin
            Position := StrPos(Filter, FindWhat);
            if Position = 0 then
                exit;
            Filter := InsStr(DelStr(Filter, Position, StrLen(FindWhat)), ReplaceWith, Position);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckLineFilters(PayrollAnalysisLine: Record "Payroll Analysis Line")
    begin
        if PayrollAnalysisLine."Income Tax Base Filter" > 0 then
            Error(
              Text025,
              PayrollAnalysisLineTemplate.GetRecDescription,
              PayrollAnalysisLine.FieldCaption("Income Tax Base Filter"),
              PayrollAnalysisLine.GetRecDescription);

        if PayrollAnalysisLine."Work Mode Filter" <> '' then
            Error(
              Text025,
              PayrollAnalysisLineTemplate.GetRecDescription,
              PayrollAnalysisLine.FieldCaption("Work Mode Filter"),
              PayrollAnalysisLine.GetRecDescription);

        if PayrollAnalysisLine."Disability Group Filter" <> '' then
            Error(
              Text025,
              PayrollAnalysisLineTemplate.GetRecDescription,
              PayrollAnalysisLine.FieldCaption("Disability Group Filter"),
              PayrollAnalysisLine.GetRecDescription);

        if PayrollAnalysisLine."Contract Type Filter" <> '' then
            Error(
              Text025,
              PayrollAnalysisLineTemplate.GetRecDescription,
              PayrollAnalysisLine.FieldCaption("Contract Type Filter"),
              PayrollAnalysisLine.GetRecDescription);

        if PayrollAnalysisLine."Payment Source Filter" <> '' then
            Error(
              Text025,
              PayrollAnalysisLineTemplate.GetRecDescription,
              PayrollAnalysisLine.FieldCaption("Payment Source Filter"),
              PayrollAnalysisLine.GetRecDescription);
    end;
}

