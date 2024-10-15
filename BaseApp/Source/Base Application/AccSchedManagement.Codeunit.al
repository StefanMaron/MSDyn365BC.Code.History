﻿codeunit 8 AccSchedManagement
{
    TableNo = "Acc. Schedule Line";

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'DEFAULT';
        Text001: Label 'Default Schedule';
        Text002: Label 'Default Columns';
        Text012: Label 'You have entered an illegal value or a nonexistent row number.';
        Text013: Label 'You have entered an illegal value or a nonexistent column number.';
        Text016: Label '%1\\ %2 %3 %4.', Locked = true;
        Text017: Label 'The error occurred when the program tried to calculate:\';
        Text018: Label 'Acc. Sched. Line: Row No. = %1, Line No. = %2, Totaling = %3\', Comment = '%1 = Row No., %2= Line No., %3 = Totaling';
        Text019: Label 'Acc. Sched. Column: Column No. = %1, Line No. = %2, Formula  = %3', Comment = '%1 = Column No., %2= Line No., %3 = Formula';
        Text020: Label 'Because of circular references, the program cannot calculate a formula.';
        AccSchedName: Record "Acc. Schedule Name";
        AccountScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        AccSchedCellValue: Record "Acc. Sched. Cell Value" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        AddRepCurrency: Record Currency;
        AnalysisView: Record "Analysis View";
#if not CLEAN19
        AccScheduleResultsHeader: Record "Acc. Schedule Result Header";
#endif
        MatrixMgt: Codeunit "Matrix Management";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        AnalysisViewRead: Boolean;
        StartDate: Date;
        EndDate: Date;
        FiscalStartDate: Date;
        DivisionError: Boolean;
        PeriodError: Boolean;
        CallLevel: Integer;
        CallingAccSchedLineID: Integer;
        CallingColumnLayoutID: Integer;
        OldAccSchedLineFilters: Text;
        OldColumnLayoutFilters: Text;
        OldAccSchedLineName: Code[10];
        OldColumnLayoutName: Code[10];
        OldCalcAddCurr: Boolean;
        GLSetupRead: Boolean;
        Text021: Label 'Conversion of dimension totaling filter %1 results in a filter that becomes too long.';
        BasePercentLine: array[50] of Integer;
        Text022: Label 'You cannot have more than %1 lines with %2 of %3.';
        Text023: Label 'Formulas ending with a percent sign require %2 %1 on a line before it.';
        Text024: Label 'The %1 %3 on the %2 must equal the %4 %6 on the %5 when any Dimension Totaling is used in any Column.';
        ColumnFormulaMsg: Label 'Column formula: %1.';
#if not CLEAN19
        SaveResults: Boolean;
        Text26570: Label 'You must specify acc. schedule name.';
        Text26571: Label 'You must specify column layout name.';
        Text26572: Label 'You must specify date filter.';
        Text005: Label 'M';
        Text006: Label 'Q';
        Text007: Label 'Y';
        AccSchedExtensionManagement: Codeunit AccSchedExtensionManagement;
#endif
        RowFormulaMsg: Label 'Row formula: %1.';
        ColumnFormulaErrorMsg: Label 'Column formula: %1. \Error: %2.';
        Recalculate: Boolean;
        SystemGeneratedAccSchedQst: Label 'This account schedule may be automatically updated by the system, so any changes you make may be lost. Do you want to make a copy?';

    procedure OpenSchedule(var CurrentSchedName: Code[10]; var AccSchedLine: Record "Acc. Schedule Line")
    begin
        CheckTemplateAndSetFilter(CurrentSchedName, AccSchedLine);
    end;

    procedure OpenAndCheckSchedule(var CurrentSchedName: Code[10]; var AccSchedLine: Record "Acc. Schedule Line")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CopyAccountSchedule: Report "Copy Account Schedule";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        CheckTemplateAndSetFilter(CurrentSchedName, AccSchedLine);
        if AccSchedLine.IsEmpty() then
            exit;
        GeneralLedgerSetup.Get();
        if CurrentSchedName in
           [GeneralLedgerSetup."Acc. Sched. for Balance Sheet", GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt",
            GeneralLedgerSetup."Acc. Sched. for Income Stmt.", GeneralLedgerSetup."Acc. Sched. for Retained Earn."]
        then
            if ConfirmManagement.GetResponseOrDefault(SystemGeneratedAccSchedQst, true) then begin
                AccScheduleName.SetRange(Name, CurrentSchedName);
                CopyAccountSchedule.SetTableView(AccScheduleName);
                CopyAccountSchedule.RunModal;
                CurrentSchedName := CopyAccountSchedule.GetNewAccountScheduleName;
            end;
    end;

    local procedure CheckTemplateAndSetFilter(var CurrentSchedName: Code[10]; var AccSchedLine: Record "Acc. Schedule Line")
    begin
        CheckTemplateName(CurrentSchedName);
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
    end;

    local procedure CheckTemplateName(var CurrentSchedName: Code[10])
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        if not AccSchedName.Get(CurrentSchedName) then begin
            if not AccSchedName.FindFirst then begin
                AccSchedName.Init();
                AccSchedName.Name := Text000;
                AccSchedName.Description := Text001;
                AccSchedName.Insert();
                Commit();
            end;
            CurrentSchedName := AccSchedName.Name;
        end;
    end;

    procedure CheckName(CurrentSchedName: Code[10])
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        AccSchedName.Get(CurrentSchedName);
    end;

    procedure SetName(CurrentSchedName: Code[10]; var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
        if AccSchedLine.Find('-') then;
    end;

    procedure LookupName(CurrentSchedName: Code[10]; var EntrdSchedName: Text[10]): Boolean
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        AccSchedName.Name := CurrentSchedName;
        if PAGE.RunModal(0, AccSchedName) <> ACTION::LookupOK then
            exit(false);

        EntrdSchedName := AccSchedName.Name;
        exit(true);
    end;

    procedure OpenColumns(var CurrentColumnName: Code[10]; var ColumnLayout: Record "Column Layout")
    begin
        CheckColumnTemplateName(CurrentColumnName);
        ColumnLayout.FilterGroup(2);
        ColumnLayout.SetRange("Column Layout Name", CurrentColumnName);
        ColumnLayout.FilterGroup(0);
    end;

    local procedure CheckColumnTemplateName(var CurrentColumnName: Code[10])
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        if not ColumnLayoutName.Get(CurrentColumnName) then begin
            if not ColumnLayoutName.FindFirst then begin
                ColumnLayoutName.Init();
                ColumnLayoutName.Name := Text000;
                ColumnLayoutName.Description := Text002;
                ColumnLayoutName.Insert();
                Commit();
            end;
            CurrentColumnName := ColumnLayoutName.Name;
        end;
    end;

    procedure CheckColumnName(CurrentColumnName: Code[10])
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        ColumnLayoutName.Get(CurrentColumnName);
    end;

    procedure SetColumnName(CurrentColumnName: Code[10]; var ColumnLayout: Record "Column Layout")
    begin
        ColumnLayout.Reset();
        ColumnLayout.FilterGroup(2);
        ColumnLayout.SetRange("Column Layout Name", CurrentColumnName);
        ColumnLayout.FilterGroup(0);
    end;

    procedure CopyColumnsToTemp(NewColumnName: Code[10]; var TempColumnLayout: Record "Column Layout")
    var
        ColumnLayout: Record "Column Layout";
    begin
        TempColumnLayout.DeleteAll();
        ColumnLayout.SetRange("Column Layout Name", NewColumnName);
        if ColumnLayout.Find('-') then
            repeat
                TempColumnLayout := ColumnLayout;
                TempColumnLayout.Insert();
            until ColumnLayout.Next() = 0;
        if TempColumnLayout.Find('-') then;
    end;

    procedure LookupColumnName(CurrentColumnName: Code[10]; var EntrdColumnName: Text[10]): Boolean
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        ColumnLayoutName.Name := CurrentColumnName;
        if PAGE.RunModal(0, ColumnLayoutName) <> ACTION::LookupOK then
            exit(false);

        EntrdColumnName := ColumnLayoutName.Name;
        exit(true);
    end;

    procedure CheckAnalysisView(CurrentSchedName: Code[10]; CurrentColumnName: Code[10]; TestColumnName: Boolean)
    var
        ColumnLayout2: Record "Column Layout";
        AnyColumnDimensions: Boolean;
    begin
        if not AnalysisViewRead then begin
            AnalysisViewRead := true;
            if CurrentSchedName <> AccSchedName.Name then begin
                CheckTemplateName(CurrentSchedName);
                AccSchedName.Get(CurrentSchedName);
            end;
            if TestColumnName then
                if CurrentColumnName <> ColumnLayoutName.Name then begin
                    CheckColumnTemplateName(CurrentColumnName);
                    ColumnLayoutName.Get(CurrentColumnName);
                end;
            if AccSchedName."Analysis View Name" = '' then begin
                GetGLSetup;
                AnalysisView.Init();
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end else
                AnalysisView.Get(AccSchedName."Analysis View Name");
            if AccSchedName."Analysis View Name" <> ColumnLayoutName."Analysis View Name" then begin
                AnyColumnDimensions := false;
                ColumnLayout2.SetRange("Column Layout Name", ColumnLayoutName.Name);
                if ColumnLayout2.Find('-') then
                    repeat
                        AnyColumnDimensions :=
                          (ColumnLayout2."Dimension 1 Totaling" <> '') or
                          (ColumnLayout2."Dimension 2 Totaling" <> '') or
                          (ColumnLayout2."Dimension 3 Totaling" <> '') or
                          (ColumnLayout2."Dimension 4 Totaling" <> '');
                    until AnyColumnDimensions or (ColumnLayout2.Next() = 0);
                if AnyColumnDimensions then
                    Error(
                      Text024,
                      AccSchedName.FieldCaption("Analysis View Name"),
                      AccSchedName.TableCaption,
                      AccSchedName."Analysis View Name",
                      ColumnLayoutName.FieldCaption("Analysis View Name"),
                      ColumnLayoutName.TableCaption,
                      ColumnLayoutName."Analysis View Name");
            end;
        end;

        OnAfterCheckAnalysisView(AccSchedName, ColumnLayoutName);
    end;

    local procedure AccPeriodStartEnd(ColumnLayout: Record "Column Layout"; Date: Date; var StartDate: Date; var EndDate: Date)
    var
        Steps: Integer;
        Type: Option " ",Period,"Fiscal Year";
        RangeFromType: Option Int,CP,LP;
        RangeToType: Option Int,CP,LP;
        RangeFromInt: Integer;
        RangeToInt: Integer;
    begin
        if ColumnLayout."Comparison Period Formula" = '' then
            exit;

        ColumnLayout.ParsePeriodFormula(
          ColumnLayout."Comparison Period Formula", Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);

        AccountingPeriodMgt.AccPeriodStartEnd(
          Date, StartDate, EndDate, PeriodError, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
    end;

    local procedure InitBasePercents(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout")
    var
        BaseIdx: Integer;
    begin
        Clear(BasePercentLine);
        BaseIdx := 0;

        with AccSchedLine do begin
            SetRange("Schedule Name", "Schedule Name");
            if Find('-') then
                repeat
                    if "Totaling Type" = "Totaling Type"::"Set Base For Percent" then begin
                        BaseIdx := BaseIdx + 1;
                        if BaseIdx > ArrayLen(BasePercentLine) then
                            ShowError(
                              StrSubstNo(Text022, ArrayLen(BasePercentLine), FieldCaption("Totaling Type"), "Totaling Type"),
                              AccSchedLine, ColumnLayout);
                        BasePercentLine[BaseIdx] := "Line No.";
                    end;
                until Next() = 0;
        end;

        if BaseIdx = 0 then begin
            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Set Base For Percent";
            ShowError(
              StrSubstNo(Text023, AccSchedLine.FieldCaption("Totaling Type"), AccSchedLine."Totaling Type"),
              AccSchedLine, ColumnLayout);
        end;
    end;

    local procedure GetBasePercentLine(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"): Integer
    var
        BaseIdx: Integer;
    begin
        if BasePercentLine[1] = 0 then
            InitBasePercents(AccSchedLine, ColumnLayout);

        BaseIdx := ArrayLen(BasePercentLine);
        repeat
            if BasePercentLine[BaseIdx] <> 0 then
                if BasePercentLine[BaseIdx] < AccSchedLine."Line No." then
                    exit(BasePercentLine[BaseIdx]);
            BaseIdx := BaseIdx - 1;
        until BaseIdx = 0;

        AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Set Base For Percent";
        ShowError(
          StrSubstNo(Text023, AccSchedLine.FieldCaption("Totaling Type"), AccSchedLine."Totaling Type"),
          AccSchedLine, ColumnLayout);
    end;

    local procedure GetGLSetup() Result: Boolean
    begin
        if not GLSetupRead then
            Result := GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure CalcCell(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean): Decimal
    var
#if not CLEAN19
        AccScheduleResult: Record "Acc. Schedule Result Value";
#endif
        Result: Decimal;
    begin
        OnBeforeCalcCell(AccSchedLine, ColumnLayout, CalcAddCurr);

        AccountScheduleLine.CopyFilters(AccSchedLine);
        StartDate := AccountScheduleLine.GetRangeMin("Date Filter");
        if EndDate <> AccountScheduleLine.GetRangeMax("Date Filter") then begin
            EndDate := AccountScheduleLine.GetRangeMax("Date Filter");
            FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);
        end;
        DivisionError := false;
        PeriodError := false;
        CallLevel := 0;
        CallingAccSchedLineID := AccSchedLine."Line No.";
        CallingColumnLayoutID := ColumnLayout."Line No.";

        if (OldAccSchedLineFilters <> AccSchedLine.GetFilters) or
           (OldColumnLayoutFilters <> ColumnLayout.GetFilters) or
           (OldAccSchedLineName <> AccSchedLine."Schedule Name") or
           (OldColumnLayoutName <> ColumnLayout."Column Layout Name") or
           (OldCalcAddCurr <> CalcAddCurr) or
           Recalculate
        then begin
            AccSchedCellValue.Reset();
            AccSchedCellValue.DeleteAll();
            Clear(BasePercentLine);
            OldAccSchedLineFilters := AccSchedLine.GetFilters;
            OldColumnLayoutFilters := ColumnLayout.GetFilters;
            OldAccSchedLineName := AccSchedLine."Schedule Name";
            OldColumnLayoutName := ColumnLayout."Column Layout Name";
            OldCalcAddCurr := CalcAddCurr;
        end;

        Result := CalcCellValue(AccSchedLine, ColumnLayout, CalcAddCurr);
        FormatCellResult(AccSchedLine, ColumnLayout, CalcAddCurr, Result);

        OnBeforeCalcCellExit(AccSchedLine, ColumnLayout, CalcAddCurr, Result);
#if not CLEAN19
        // NAVCZ
        if SaveResults then begin
            AccScheduleResult."Result Code" := AccScheduleResultsHeader."Result Code";
            AccScheduleResult."Row No." := AccSchedLine."Line No.";
            AccScheduleResult."Column No." := ColumnLayout."Line No.";
            AccScheduleResult.Value := Result;
            AccScheduleResult.Insert();
        end;
        // NAVCZ
#endif
        exit(Result);
    end;

    local procedure FormatCellResult(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var Result: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatCellResult(AccSchedLine, ColumnLayout, CalcAddCurr, Result, IsHandled);
        if IsHandled then
            exit;

        with ColumnLayout do begin
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
            case "Show Indented Lines" of
                "Show Indented Lines"::"Indented Only":
                    if AccSchedLine.Indentation = 0 then
                        Result := 0;
                "Show Indented Lines"::"Non-Indented Only":
                    if AccSchedLine.Indentation > 0 then
                        Result := 0;
            end;
        end;

        if AccSchedLine."Show Opposite Sign" then
            Result := -Result;
    end;

    procedure CalcCellValue(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean): Decimal
    var
        GLAcc: Record "G/L Account";
        CostType: Record "Cost Type";
        CFAccount: Record "Cash Flow Account";
        Result: Decimal;
    begin
        Result := 0;
        OnBeforeCalcCellValue(AccSchedLine, ColumnLayout, CalcAddCurr, Result);

        if AccSchedLine.Totaling = '' then
            exit(Result);
#if not CLEAN19
        if AccSchedCellValue.Get(AccSchedLine."Schedule Name", AccSchedLine."Line No.", ColumnLayout."Line No.") then begin // NAVCZ
#else
        if AccSchedCellValue.Get(AccSchedLine."Line No.", ColumnLayout."Line No.") then begin
#endif
            Result := AccSchedCellValue.Value;
            DivisionError := DivisionError or AccSchedCellValue."Has Error";
            PeriodError := PeriodError or AccSchedCellValue."Period Error";
        end else begin
            if ColumnLayout."Column Type" = ColumnLayout."Column Type"::Formula then
                Result :=
                  EvaluateExpression(
                    false, ColumnLayout.Formula, AccSchedLine, ColumnLayout, CalcAddCurr)
            else
                if AccSchedLine."Totaling Type" in
                   [AccSchedLine."Totaling Type"::Formula, AccSchedLine."Totaling Type"::"Set Base For Percent"]
                then
                    Result :=
                      EvaluateExpression(
                        true, AccSchedLine.Totaling, AccSchedLine, ColumnLayout, CalcAddCurr)
                else
                    if (StartDate = 0D) or (EndDate = 0D) or (EndDate = DMY2Date(31, 12, 9999)) then begin
                        Result := 0;
                        PeriodError := true;
                    end else
                        case AccSchedLine."Totaling Type" of
                            AccSchedLine."Totaling Type"::"Posting Accounts",
                            AccSchedLine."Totaling Type"::"Total Accounts":
                                begin
                                    AccSchedLine.CopyFilters(AccountScheduleLine);
                                    SetGLAccRowFilters(GLAcc, AccSchedLine);
                                    SetGLAccColumnFilters(GLAcc, AccSchedLine, ColumnLayout);
                                    if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Posting Accounts") and
                                       (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                                    then begin
                                        GLAcc."Account Type" := GLAcc."Account Type"::Total;
                                        GLAcc.Totaling := AccSchedLine.Totaling;
                                        Result := Result + CalcGLAcc(GLAcc, AccSchedLine, ColumnLayout, CalcAddCurr);
                                    end else
                                        if GLAcc.Find('-') then
                                            repeat
                                                Result := Result + CalcGLAcc(GLAcc, AccSchedLine, ColumnLayout, CalcAddCurr);
                                            until GLAcc.Next() = 0;
#if not CLEAN17
                                    // NAVCZ
                                    with AccSchedLine do
                                        case Calc of
                                            Calc::"When Positive":
                                                if Result < 0 then
                                                    Result := 0;
                                            Calc::"When Negative":
                                                if Result > 0 then
                                                    Result := 0;
                                            Calc::Never:
                                                Result := 0;
                                        end;
                                    // NAVCZ
#endif
                                end;
                            AccSchedLine."Totaling Type"::"Cost Type",
                            AccSchedLine."Totaling Type"::"Cost Type Total":
                                begin
                                    AccSchedLine.CopyFilters(AccountScheduleLine);
                                    SetCostTypeRowFilters(CostType, AccSchedLine, ColumnLayout);
                                    SetCostTypeColumnFilters(CostType, AccSchedLine, ColumnLayout);
                                    if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cost Type") and
                                       (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                                    then begin
                                        CostType.Type := CostType.Type::Total;
                                        CostType.Totaling := AccSchedLine.Totaling;
                                        Result := Result + CalcCostType(CostType, AccSchedLine, ColumnLayout, CalcAddCurr);
                                    end else
                                        if CostType.Find('-') then
                                            repeat
                                                Result := Result + CalcCostType(CostType, AccSchedLine, ColumnLayout, CalcAddCurr);
                                            until CostType.Next() = 0;
                                end;
                            AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts",
                            AccSchedLine."Totaling Type"::"Cash Flow Total Accounts":
                                begin
                                    AccSchedLine.CopyFilters(AccountScheduleLine);
                                    SetCFAccRowFilter(CFAccount, AccSchedLine);
                                    SetCFAccColumnFilter(CFAccount, AccSchedLine, ColumnLayout);
                                    if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts") and
                                       (StrLen(AccSchedLine.Totaling) <= 30)
                                    then begin
                                        CFAccount."Account Type" := CFAccount."Account Type"::Total;
                                        CFAccount.Totaling := AccSchedLine.Totaling;
                                        Result := Result + CalcCFAccount(CFAccount, AccSchedLine, ColumnLayout);
                                    end else
                                        if CFAccount.Find('-') then
                                            repeat
                                                Result := Result + CalcCFAccount(CFAccount, AccSchedLine, ColumnLayout);
                                            until CFAccount.Next() = 0;
                                end;
#if not CLEAN19
                            // NAVCZ
                            AccSchedLine."Totaling Type"::Constant:
                                if not Evaluate(Result, AccSchedLine.Totaling) then
                                    ;
                            AccSchedLine."Totaling Type"::Custom:
                                begin
                                    AccSchedLine.CopyFilters(AccountScheduleLine);
                                    Result := AccSchedExtensionManagement.CalcCustomFunc(AccSchedLine, ColumnLayout, StartDate, EndDate);
                                end;
                        // NAVCZ
#endif
                        end;

            OnAfterCalcCellValue(AccSchedLine, ColumnLayout, Result, AccountScheduleLine, GLAcc);

            AccSchedCellValue."Row No." := AccSchedLine."Line No.";
            AccSchedCellValue."Column No." := ColumnLayout."Line No.";
            AccSchedCellValue.Value := Result;
            AccSchedCellValue."Has Error" := DivisionError;
            AccSchedCellValue."Period Error" := PeriodError;
#if not CLEAN19
            AccSchedCellValue."Schedule Name" := AccSchedLine."Schedule Name"; // NAVCZ
#endif
            AccSchedCellValue.Insert();
        end;

        OnCalcCellValueOnBeforeExit(AccSchedLine, ColumnLayout, CalcAddCurr, StartDate, EndDate, Result);
        exit(Result);
    end;

    local procedure CalcGLAcc(var GLAcc: Record "G/L Account"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean) ColValue: Decimal
    var
        GLEntry: Record "G/L Entry";
        GLBudgEntry: Record "G/L Budget Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AmountType: Enum "Account Schedule Amount Type";
        TestBalance: Boolean;
        Balance: Decimal;
        UseBusUnitFilter: Boolean;
        UseDimFilter: Boolean;
        IsHandled: Boolean;
    begin
        ColValue := 0;
        IsHandled := false;
        OnBeforeCalcGLAcc(GLAcc, AccSchedLine, ColumnLayout, CalcAddCurr, ColValue, IsHandled);
        if IsHandled then
            exit(ColValue);

        UseDimFilter := false;
        if AccSchedName.Name <> AccSchedLine."Schedule Name" then
            AccSchedName.Get(AccSchedLine."Schedule Name");

        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit(0);

        TestBalance :=
          AccSchedLine.Show in [AccSchedLine.Show::"When Positive Balance", AccSchedLine.Show::"When Negative Balance"];
        if ColumnLayout."Column Type" <> ColumnLayout."Column Type"::Formula then begin
            UseBusUnitFilter := (AccSchedLine.GetFilter("Business Unit Filter") <> '') or (ColumnLayout."Business Unit Totaling" <> '');
            UseDimFilter := HasDimFilter(AccSchedLine, ColumnLayout);
            case ColumnLayout."Ledger Entry Type" of
                ColumnLayout."Ledger Entry Type"::Entries:
                    if AccSchedName."Analysis View Name" = '' then
                        with GLEntry do begin
                            SetGLAccGLEntryFilters(GLAcc, GLEntry, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter);
                            case AmountType of
                                AmountType::"Net Amount":
                                    begin
                                        if CalcAddCurr then begin
                                            CalcSums("Additional-Currency Amount");
                                            ColValue := "Additional-Currency Amount";
                                        end else begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                        end;
                                        Balance := ColValue;
                                    end;
                                AmountType::"Debit Amount":
                                    if CalcAddCurr then begin
                                        if TestBalance then begin
                                            CalcSums("Add.-Currency Debit Amount", "Additional-Currency Amount");
                                            Balance := "Additional-Currency Amount";
                                        end else
                                            CalcSums("Add.-Currency Debit Amount");
                                        ColValue := "Add.-Currency Debit Amount";
                                    end else begin
                                        if TestBalance then begin
                                            CalcSums("Debit Amount", Amount);
                                            Balance := Amount;
                                        end else
                                            CalcSums("Debit Amount");
                                        ColValue := "Debit Amount";
                                    end;
                                AmountType::"Credit Amount":
                                    if CalcAddCurr then begin
                                        if TestBalance then begin
                                            CalcSums("Add.-Currency Credit Amount", "Additional-Currency Amount");
                                            Balance := "Additional-Currency Amount";
                                        end else
                                            CalcSums("Add.-Currency Credit Amount");
                                        ColValue := "Add.-Currency Credit Amount";
                                    end else begin
                                        if TestBalance then begin
                                            CalcSums("Credit Amount", Amount);
                                            Balance := Amount;
                                        end else
                                            CalcSums("Credit Amount");
                                        ColValue := "Credit Amount";
                                    end;
                            end;
                        end
                    else
                        with AnalysisViewEntry do begin
                            SetGLAccAnalysisViewEntryFilters(GLAcc, AnalysisViewEntry, AccSchedLine, ColumnLayout);
                            case AmountType of
                                AmountType::"Net Amount":
                                    begin
                                        if CalcAddCurr then begin
                                            CalcSums("Add.-Curr. Amount");
                                            ColValue := "Add.-Curr. Amount";
                                        end else begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                        end;
                                        Balance := ColValue;
                                    end;
                                AmountType::"Debit Amount":
                                    if CalcAddCurr then begin
                                        if TestBalance then begin
                                            CalcSums("Add.-Curr. Debit Amount", "Add.-Curr. Amount");
                                            Balance := "Add.-Curr. Amount";
                                        end else
                                            CalcSums("Add.-Curr. Debit Amount");
                                        ColValue := "Add.-Curr. Debit Amount";
                                    end else begin
                                        if TestBalance then begin
                                            CalcSums("Debit Amount", Amount);
                                            Balance := Amount;
                                        end else
                                            CalcSums("Debit Amount");
                                        ColValue := "Debit Amount";
                                    end;
                                AmountType::"Credit Amount":
                                    if CalcAddCurr then begin
                                        if TestBalance then begin
                                            CalcSums("Add.-Curr. Credit Amount", "Add.-Curr. Amount");
                                            Balance := "Add.-Curr. Amount";
                                        end else
                                            CalcSums("Add.-Curr. Credit Amount");
                                        ColValue := "Add.-Curr. Credit Amount";
                                    end else begin
                                        if TestBalance then begin
                                            CalcSums("Credit Amount", Amount);
                                            Balance := Amount;
                                        end else
                                            CalcSums("Credit Amount");
                                        ColValue := "Credit Amount";
                                    end;
                            end;
                        end;
                ColumnLayout."Ledger Entry Type"::"Budget Entries":
                    begin
                        if AccSchedName."Analysis View Name" = '' then
                            with GLBudgEntry do begin
                                SetGLAccGLBudgetEntryFilters(GLAcc, GLBudgEntry, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter);
                                case AmountType of
                                    AmountType::"Net Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                        end;
                                    AmountType::"Debit Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                            if ColValue < 0 then
                                                ColValue := 0;
                                        end;
                                    AmountType::"Credit Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := -Amount;
                                            if ColValue < 0 then
                                                ColValue := 0;
                                        end;
                                end;
                                Balance := Amount;
                            end
                        else
                            with AnalysisViewBudgetEntry do begin
                                SetGLAccAnalysisViewBudgetEntries(GLAcc, AnalysisViewBudgetEntry, AccSchedLine, ColumnLayout);
                                case AmountType of
                                    AmountType::"Net Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                        end;
                                    AmountType::"Debit Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := Amount;
                                            if ColValue < 0 then
                                                ColValue := 0;
                                        end;
                                    AmountType::"Credit Amount":
                                        begin
                                            CalcSums(Amount);
                                            ColValue := -Amount;
                                            if ColValue < 0 then
                                                ColValue := 0;
                                        end;
                                end;
                                Balance := Amount;
                            end;
                        if CalcAddCurr then
                            ColValue := CalcLCYToACY(ColValue);
                    end;
            end;

            OnBeforeTestBalance(
              GLAcc, AccSchedName, AccSchedLine, ColumnLayout, AmountType.AsInteger(), ColValue, CalcAddCurr, TestBalance, GLEntry, GLBudgEntry, Balance);

            if TestBalance then begin
                if AccSchedLine.Show = AccSchedLine.Show::"When Positive Balance" then
                    if Balance < 0 then
                        exit(0);
                if AccSchedLine.Show = AccSchedLine.Show::"When Negative Balance" then
                    if Balance > 0 then
                        exit(0);
            end;
        end;
        exit(ColValue);
    end;

    local procedure CalcCFAccount(var CFAccount: Record "Cash Flow Account"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout") ColValue: Decimal
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        AmountType: Enum "Account Schedule Amount Type";
        IsHandled: Boolean;
    begin
        ColValue := 0;
        IsHandled := false;
        OnBeforeCalcCFAcc(CFAccount, AccSchedLine, ColumnLayout, ColValue, IsHandled);
        if IsHandled then
            exit(ColValue);

        if AccSchedName.Name <> AccSchedLine."Schedule Name" then
            AccSchedName.Get(AccSchedLine."Schedule Name");

        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit(0);

        if ColumnLayout."Column Type" <> ColumnLayout."Column Type"::Formula then
            case ColumnLayout."Ledger Entry Type" of
                ColumnLayout."Ledger Entry Type"::Entries:
                    if AccSchedName."Analysis View Name" = '' then
                        with CFForecastEntry do begin
                            SetCFEntryFilters(CFAccount, CFForecastEntry, AccSchedLine, ColumnLayout);
                            case ColumnLayout."Amount Type" of
                                ColumnLayout."Amount Type"::"Net Amount":
                                    begin
                                        CalcSums("Amount (LCY)");
                                        ColValue := "Amount (LCY)";
                                    end;
                            end;
                        end
                    else
                        with AnalysisViewEntry do begin
                            SetCFAnalysisViewEntryFilters(CFAccount, AnalysisViewEntry, AccSchedLine, ColumnLayout);
                            case ColumnLayout."Amount Type" of
                                ColumnLayout."Amount Type"::"Net Amount":
                                    begin
                                        CalcSums(Amount);
                                        ColValue := Amount;
                                    end;
                            end;
                        end;
            end;

        exit(ColValue);
    end;

    local procedure CalcCellValueInAccSchedLines(SourceAccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; Expression: Text; CalcAddCurr: Boolean; IsFilter: Boolean) Result: Decimal
    var
        AccSchedLine: Record "Acc. Schedule Line";
        IsHandled: Boolean;
        CellValue: Decimal;
    begin
        AccSchedLine.SetRange("Schedule Name", SourceAccSchedLine."Schedule Name");
        AccSchedLine.SetFilter("Row No.", Expression);
        if AccSchedLine.Find('-') then
            repeat
                if AccSchedLine."Line No." <> SourceAccSchedLine."Line No." then begin
                    IsHandled := false;
                    OnEvaluateExpressionOnBeforeCalcAccSchedLineCellValue(
                        SourceAccSchedLine, AccSchedLine, ColumnLayout, CalcAddCurr, IsHandled, CellValue);
                    if IsHandled then
                        Result += CellValue
                    else
                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout, CalcAddCurr);
                end;
            until AccSchedLine.Next() = 0
#if not CLEAN19
        else begin
            GetGLSetup();
            AccSchedLine.SetRange("Schedule Name", GLSetup."Shared Account Schedule");
            if AccSchedLine.Find('-') then
                repeat
                    IsHandled := false;
                    OnEvaluateExpressionOnBeforeCalcAccSchedLineCellValue(
                        SourceAccSchedLine, AccSchedLine, ColumnLayout, CalcAddCurr, IsHandled, CellValue);
                    if IsHandled then
                        Result += CellValue
                    else
                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout, CalcAddCurr);
                until AccSchedLine.Next() = 0
#endif
            else begin
                IsHandled := false;
            OnCalcCellValueInAccSchedLinesOnBeforeShowError(
                SourceAccSchedLine, AccSchedLine, ColumnLayout, CalcAddCurr, CellValue,
                StartDate, EndDate, Result, IsHandled, Expression, DivisionError, PeriodError);
                if not IsHandled then
                    if IsFilter or (not Evaluate(Result, Expression)) then
                        ShowError(Text012, SourceAccSchedLine, ColumnLayout);
            end;
#if not CLEAN19
        end;
#endif
    end;

    local procedure CalcCellValueInColumnLayouts(SourceColumnLayout: Record "Column Layout"; AccSchedLine: Record "Acc. Schedule Line"; Expression: Text; CalcAddCurr: Boolean; IsFilter: Boolean) Result: Decimal
    var
        ColumnLayout: Record "Column Layout";
        IsHandled: Boolean;
        CellValue: Decimal;
    begin
        ColumnLayout.SetRange("Column Layout Name", SourceColumnLayout."Column Layout Name");
        ColumnLayout.SetFilter("Column No.", Expression);
        if ColumnLayout.Find('-') then
            repeat
                if ColumnLayout."Line No." <> SourceColumnLayout."Line No." then begin
                    IsHandled := false;
                    OnEvaluateExpressionOnBeforeCalcColumnLayoutCellValue(
                      SourceColumnLayout, AccSchedLine, ColumnLayout, CalcAddCurr, IsHandled, CellValue);
                    if IsHandled then
                        Result += CellValue
                    else
                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout, CalcAddCurr);
                end;
            until ColumnLayout.Next() = 0
        else
            if IsFilter or (not Evaluate(Result, Expression)) then
                ShowError(Text013, AccSchedLine, SourceColumnLayout);
    end;

    procedure SetGLAccRowFilters(var GLAcc: Record "G/L Account"; var AccSchedLine2: Record "Acc. Schedule Line")
    begin
        with AccSchedLine2 do
            case "Totaling Type" of
                "Totaling Type"::"Posting Accounts":
                    begin
                        GLAcc.SetFilter("No.", Totaling);
                        GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
                    end;
                "Totaling Type"::"Total Accounts":
                    begin
                        GLAcc.SetFilter("No.", Totaling);
                        GLAcc.SetFilter("Account Type", '<>%1', GLAcc."Account Type"::Posting);
                    end;
            end;

        OnAfterSetGLAccRowFilters(GLAcc, AccSchedLine2);
    end;

    local procedure SetGLAccGLEntryFilters(var GLAcc: Record "G/L Account"; var GLEntry: Record "G/L Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetGLAccGLEntryFilters(GLAcc, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter, IsHandled);
        if IsHandled then
            exit;

        with GLEntry do begin
            if UseBusUnitFilter then
                if UseDimFilter then
                    SetCurrentKey(
                      "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code")
                else
                    SetCurrentKey(
                      "G/L Account No.", "Business Unit Code", "Posting Date")
            else
                if UseDimFilter then
                    SetCurrentKey("G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code")
                else
                    SetCurrentKey("G/L Account No.", "Posting Date");
            if GLAcc.Totaling = '' then
                SetRange("G/L Account No.", GLAcc."No.")
            else
                SetFilter("G/L Account No.", GLAcc.Totaling);
            GLAcc.CopyFilter("Date Filter", "Posting Date");
            AccSchedLine.CopyFilter("Business Unit Filter", "Business Unit Code");
            AccSchedLine.CopyFilter("Dimension 1 Filter", "Global Dimension 1 Code");
            AccSchedLine.CopyFilter("Dimension 2 Filter", "Global Dimension 2 Code");
            FilterGroup(2);
            SetFilter("Global Dimension 1 Code", GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
            SetFilter("Global Dimension 2 Code", GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
            FilterGroup(8);
            SetFilter("Global Dimension 1 Code", GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
            SetFilter("Global Dimension 2 Code", GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
            SetFilter("Business Unit Code", ColumnLayout."Business Unit Totaling");
            FilterGroup(0);
        end;

        OnAfterSetGLAccGLEntryFilters(GLAcc, GLEntry, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter);
    end;

    local procedure SetGLAccGLBudgetEntryFilters(var GLAcc: Record "G/L Account"; var GLBudgetEntry: Record "G/L Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetGLAccGLBudgetEntryFilters(GLAcc, GLBudgetEntry, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter, IsHandled);
        if IsHandled then
            exit;

        with GLBudgetEntry do begin
            if UseBusUnitFilter or UseDimFilter then
                SetCurrentKey(
                  "Budget Name", "G/L Account No.", "Business Unit Code",
                  "Global Dimension 1 Code", "Global Dimension 2 Code",
                  "Budget Dimension 1 Code", "Budget Dimension 2 Code",
                  "Budget Dimension 3 Code", "Budget Dimension 4 Code", Date)
            else
                SetCurrentKey("Budget Name", "G/L Account No.", Date);
            if GLAcc.Totaling = '' then
                SetRange("G/L Account No.", GLAcc."No.")
            else
                SetFilter("G/L Account No.", GLAcc.Totaling);
            GLAcc.CopyFilter("Date Filter", Date);
            AccSchedLine.CopyFilter("G/L Budget Filter", "Budget Name");
            AccSchedLine.CopyFilter("Business Unit Filter", "Business Unit Code");
            AccSchedLine.CopyFilter("Dimension 1 Filter", "Global Dimension 1 Code");
            AccSchedLine.CopyFilter("Dimension 2 Filter", "Global Dimension 2 Code");
            FilterGroup(2);
            SetFilter("Global Dimension 1 Code", GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
            SetFilter("Global Dimension 2 Code", GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
            FilterGroup(8);
            SetFilter("Global Dimension 1 Code", GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
            SetFilter("Global Dimension 2 Code", GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
            SetFilter("Business Unit Code", ColumnLayout."Business Unit Totaling");
            FilterGroup(0);
        end;

        OnAfterSetGLAccGLBudgetEntryFilters(GLAcc, GLBudgetEntry, AccSchedLine, ColumnLayout, UseBusUnitFilter, UseDimFilter);
    end;

    local procedure SetGLAccAnalysisViewBudgetEntries(var GLAcc: Record "G/L Account"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with AnalysisViewBudgetEntry do begin
            if GLAcc.Totaling = '' then
                SetRange("G/L Account No.", GLAcc."No.")
            else
                SetFilter("G/L Account No.", GLAcc.Totaling);
            SetRange("Analysis View Code", AccSchedName."Analysis View Name");
            GLAcc.CopyFilter("Date Filter", "Posting Date");
            AccSchedLine.CopyFilter("G/L Budget Filter", "Budget Name");
            AccSchedLine.CopyFilter("Business Unit Filter", "Business Unit Code");
            CopyDimFilters(AccSchedLine);
            FilterGroup(2);
            SetDimFilters(
              GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
            FilterGroup(8);
            SetDimFilters(
              GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
            SetFilter("Business Unit Code", ColumnLayout."Business Unit Totaling");
            FilterGroup(0);
        end;

        OnAfterSetGLAccAnalysisViewBudgetEntries(GLAcc, AnalysisViewBudgetEntry, AccSchedLine, ColumnLayout);
    end;

    local procedure SetGLAccAnalysisViewEntryFilters(var GLAcc: Record "G/L Account"; var AnalysisViewEntry: Record "Analysis View Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with AnalysisViewEntry do begin
            SetRange("Analysis View Code", AccSchedName."Analysis View Name");
            SetRange("Account Source", "Account Source"::"G/L Account");
            if GLAcc.Totaling = '' then
                SetRange("Account No.", GLAcc."No.")
            else
                SetFilter("Account No.", GLAcc.Totaling);
            GLAcc.CopyFilter("Date Filter", "Posting Date");
            OnSetGLAccAnalysisViewEntryFiltersOnBeforeAccSchedLineCopyFilter(AccSchedLine, AnalysisViewEntry);
            AccSchedLine.CopyFilter("Business Unit Filter", "Business Unit Code");
            CopyDimFilters(AccSchedLine);
            FilterGroup(2);
            SetDimFilters(
              GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
            FilterGroup(8);
            SetDimFilters(
              GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
            SetFilter("Business Unit Code", ColumnLayout."Business Unit Totaling");
            FilterGroup(0);
        end;

        OnAfterSetGLAccAnalysisViewEntryFilters(GLAcc, AnalysisViewEntry, AccSchedLine, ColumnLayout);
    end;

    procedure SetCFAccRowFilter(var CFAccount: Record "Cash Flow Account"; var AccSchedLine2: Record "Acc. Schedule Line")
    begin
        with AccSchedLine2 do begin
            CopyFilter("Cash Flow Forecast Filter", CFAccount."Cash Flow Forecast Filter");

            case "Totaling Type" of
                "Totaling Type"::"Cash Flow Entry Accounts":
                    begin
                        CFAccount.SetFilter("No.", Totaling);
                        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
                    end;
                "Totaling Type"::"Cash Flow Total Accounts":
                    begin
                        CFAccount.SetFilter("No.", Totaling);
                        CFAccount.SetFilter("Account Type", '<>%1', CFAccount."Account Type"::Entry);
                    end;
            end;
        end;

        OnAfterSetCFAccRowFilter(CFAccount, AccSchedLine2);
    end;

    procedure SetGLAccColumnFilters(var GLAcc: Record "G/L Account"; AccSchedLine2: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate2: Date;
    begin
        with ColumnLayout do begin
            CalcColumnDates(ColumnLayout, FromDate, ToDate, FiscalStartDate2);
            case "Column Type" of
                "Column Type"::"Net Change":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            GLAcc.SetRange("Date Filter", FromDate, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            GLAcc.SetFilter("Date Filter", '..%1', ClosingDate(FromDate - 1)); // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            GLAcc.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Balance at Date":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Beginning Balance" then
                        GLAcc.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        GLAcc.SetRange("Date Filter", 0D, ToDate);
                "Column Type"::"Beginning Balance":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Balance at Date" then
                        GLAcc.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        GLAcc.SetRange(
                          "Date Filter", 0D, ClosingDate(FromDate - 1));
                "Column Type"::"Year to Date":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            GLAcc.SetRange("Date Filter", FiscalStartDate2, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            GLAcc.SetFilter("Date Filter", '..%1', ClosingDate(FiscalStartDate2 - 1)); // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            GLAcc.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Rest of Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            GLAcc.SetRange(
                              "Date Filter", CalcDate('<+1D>', ToDate), AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            GLAcc.SetRange("Date Filter", 0D, ToDate);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            GLAcc.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
                "Column Type"::"Entire Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            GLAcc.SetRange(
                              "Date Filter",
                              FiscalStartDate2,
                              AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            GLAcc.SetFilter("Date Filter", '..%1', ClosingDate(FiscalStartDate2 - 1)); // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            GLAcc.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
            end;
        end;

        OnAfterSetGLAccColumnFilters(GLAcc, AccSchedLine2, ColumnLayout)
    end;

    procedure SetCFAccColumnFilter(var CFAccount: Record "Cash Flow Account"; AccSchedLine2: Record "Acc. Schedule Line"; var ColumnLayout2: Record "Column Layout")
    var
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate2: Date;
    begin
        with ColumnLayout2 do begin
            CalcColumnDates(ColumnLayout2, FromDate, ToDate, FiscalStartDate2);
            case "Column Type" of
                "Column Type"::"Net Change":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CFAccount.SetRange("Date Filter", FromDate, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CFAccount.SetFilter("Date Filter", '..%1', ClosingDate(FromDate - 1));
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CFAccount.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Balance at Date":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Beginning Balance" then
                        CFAccount.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        CFAccount.SetRange("Date Filter", 0D, ToDate);
                "Column Type"::"Beginning Balance":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Balance at Date" then
                        CFAccount.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        CFAccount.SetRange(
                          "Date Filter", 0D, CalcDate('<-1D>', FromDate));
                "Column Type"::"Year to Date":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CFAccount.SetRange("Date Filter", FiscalStartDate2, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CFAccount.SetFilter("Date Filter", '..%1', FiscalStartDate2 - 1);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CFAccount.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Rest of Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CFAccount.SetRange(
                              "Date Filter",
                              CalcDate('<+1D>', ToDate), AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CFAccount.SetRange("Date Filter", 0D, ToDate);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CFAccount.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
                "Column Type"::"Entire Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CFAccount.SetRange(
                              "Date Filter",
                              FiscalStartDate2, AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CFAccount.SetFilter("Date Filter", '..%1', ClosingDate(FiscalStartDate2 - 1));
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CFAccount.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
            end;
        end;

        OnAfterSetCFAccColumnFilter(CFAccount, AccSchedLine2, ColumnLayout2);
    end;

    local procedure SetCFEntryFilters(var CFAccount: Record "Cash Flow Account"; var CFForecastEntry: Record "Cash Flow Forecast Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with CFForecastEntry do begin
            SetCurrentKey(
              "Cash Flow Account No.", "Cash Flow Forecast No.", "Global Dimension 1 Code",
              "Global Dimension 2 Code", "Cash Flow Date");
            if CFAccount.Totaling = '' then
                SetRange("Cash Flow Account No.", CFAccount."No.")
            else
                SetFilter("Cash Flow Account No.", CFAccount.Totaling);
            CFAccount.CopyFilter("Date Filter", "Cash Flow Date");
            AccSchedLine.CopyFilter("Cash Flow Forecast Filter", "Cash Flow Forecast No.");
            AccSchedLine.CopyFilter("Dimension 1 Filter", "Global Dimension 1 Code");
            AccSchedLine.CopyFilter("Dimension 2 Filter", "Global Dimension 2 Code");
            FilterGroup(2);
            SetFilter("Global Dimension 1 Code", AccSchedLine."Dimension 1 Totaling");
            SetFilter("Global Dimension 2 Code", AccSchedLine."Dimension 2 Totaling");
            FilterGroup(8);
            SetFilter("Global Dimension 1 Code", GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
            SetFilter("Global Dimension 2 Code", GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
            FilterGroup(0);
        end;
    end;

    local procedure SetCFAnalysisViewEntryFilters(var CFAccount: Record "Cash Flow Account"; var AnalysisViewEntry: Record "Analysis View Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with AnalysisViewEntry do begin
            SetRange("Analysis View Code", AccSchedName."Analysis View Name");
            SetRange("Account Source", "Account Source"::"Cash Flow Account");
            if CFAccount.Totaling = '' then
                SetRange("Account No.", CFAccount."No.")
            else
                SetFilter("Account No.", CFAccount.Totaling);
            CFAccount.CopyFilter("Date Filter", "Posting Date");
            AccSchedLine.CopyFilter("Cash Flow Forecast Filter", "Cash Flow Forecast No.");
            CopyDimFilters(AccSchedLine);
            FilterGroup(2);
            SetDimFilters(
              GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
            FilterGroup(8);
            SetDimFilters(
              GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
              GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
              GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
              GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
            FilterGroup(0);
        end;
    end;

    local procedure ApplyOperator(LeftResult: Decimal; RightResult: Decimal; Operator: Char; var DivisionError: Boolean) Result: Decimal
    begin
        case Operator of
            '^':
                Result := Power(LeftResult, RightResult);
            '%':
                if RightResult = 0 then begin
                    Result := 0;
                    DivisionError := true;
                end else
                    Result := 100 * LeftResult / RightResult;
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
    end;

    local procedure ParseExpression(Expression: Text; var i: Integer) IsExpression: Boolean
    var
        Parantheses: Integer;
        Operators: Text[8];
        OperatorNo: Integer;
    begin
        Parantheses := 0;
        IsExpression := false;
        Operators := '+-*/^%';
        OperatorNo := 1;
        repeat
            i := StrLen(Expression);
            repeat
                if Expression[i] = '(' then
                    Parantheses := Parantheses + 1
                else
                    if Expression[i] = ')' then
                        Parantheses := Parantheses - 1;
                if (Parantheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                    IsExpression := true
                else
                    i := i - 1;
            until IsExpression or (i <= 0);
            if not IsExpression then
                OperatorNo := OperatorNo + 1;
        until (OperatorNo > StrLen(Operators)) or IsExpression;
    end;

    local procedure EvaluateExpression(IsAccSchedLineExpression: Boolean; Expression: Text; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean): Decimal
    var
        AccSchedLine2: Record "Acc. Schedule Line";
        Result: Decimal;
        Operator: Char;
        LeftOperand: Text;
        RightOperand: Text;
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        MaxLevel: Integer;
    begin
        Result := 0;
        MaxLevel := 25;

        OnBeforeEvaluateExpression(AccSchedLine, ColumnLayout, MaxLevel);

        CallLevel := CallLevel + 1;
        if CallLevel > MaxLevel then
            ShowError(Text020, AccSchedLine, ColumnLayout);

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            IsExpression := ParseExpression(Expression, i);
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
                    IsAccSchedLineExpression, LeftOperand, AccSchedLine, ColumnLayout, CalcAddCurr);
                if (RightOperand = '') and (Operator = '%') and not IsAccSchedLineExpression and
                   (AccSchedLine."Totaling Type" <> AccSchedLine."Totaling Type"::"Set Base For Percent")
                then begin
                    AccSchedLine2.Copy(AccSchedLine);
                    AccSchedLine2."Line No." := GetBasePercentLine(AccSchedLine, ColumnLayout);
                    AccSchedLine2.Find;
                    RightResult :=
                      EvaluateExpression(
                        IsAccSchedLineExpression, LeftOperand, AccSchedLine2, ColumnLayout, CalcAddCurr);
                end else
                    RightResult :=
                      EvaluateExpression(
                        IsAccSchedLineExpression, RightOperand, AccSchedLine, ColumnLayout, CalcAddCurr);
                Result := ApplyOperator(LeftResult, RightResult, Operator, DivisionError);
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvaluateExpression(
                        IsAccSchedLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AccSchedLine, ColumnLayout, CalcAddCurr)
                else begin
                    IsFilter := IsExpressionFilter(Expression);
#if not CLEAN19
                    if (StrLen(Expression) > MaxStrLen(AccSchedLine."Row No.")) and (not IsFilter) then // NAVCZ
#else
                    if (StrLen(Expression) > 10) and (not IsFilter) then
#endif
                        Evaluate(Result, Expression)
                    else
                        Result := CalcCellValueInEvaluateExpression(IsAccSchedLineExpression, AccSchedLine, ColumnLayout, Expression, CalcAddCurr, IsFilter);
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    local procedure CalcCellValueInEvaluateExpression(IsAccSchedLineExpression: Boolean; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; Expression: Text; CalcAddCurr: Boolean; IsFilter: Boolean) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCellValueInEvaluateExpression(IsAccSchedLineExpression, AccSchedLine, ColumnLayout, Expression, CalcAddCurr, IsFilter, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IsAccSchedLineExpression then
            Result := CalcCellValueInAccSchedLines(AccSchedLine, ColumnLayout, Expression, CalcAddCurr, IsFilter)
        else
            Result := CalcCellValueInColumnLayouts(ColumnLayout, AccSchedLine, Expression, CalcAddCurr, IsFilter);
        exit(Result);
    end;

    procedure FormatCellAsText(var ColumnLayout2: Record "Column Layout"; Value: Decimal; CalcAddCurr: Boolean) ValueAsText: Text[30]
    begin
        ValueAsText := MatrixMgt.FormatValue(Value, ColumnLayout2."Rounding Factor", CalcAddCurr);

        if (ValueAsText <> '') and
           (ColumnLayout2."Column Type" = ColumnLayout2."Column Type"::Formula) and
           (StrPos(ColumnLayout2.Formula, '%') > 1)
        then
            ValueAsText := ValueAsText + '%';

        OnAfterFormatCellAsText(ColumnLayout2, ValueAsText);
    end;

    procedure GetDivisionError(): Boolean
    begin
        exit(DivisionError);
    end;

    procedure GetPeriodError(): Boolean
    begin
        exit(PeriodError);
    end;

    local procedure ShowError(MessageLine: Text; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
        AccSchedLine.SetRange("Line No.", CallingAccSchedLineID);
        if AccSchedLine.FindFirst then;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
        ColumnLayout.SetRange("Line No.", CallingColumnLayoutID);
        if ColumnLayout.FindFirst then;
        Error(Text016,
          MessageLine,
          Text017,
          StrSubstNo(Text018, AccSchedLine."Row No.", AccSchedLine."Line No.", AccSchedLine.Totaling),
          StrSubstNo(Text019, ColumnLayout."Column No.", ColumnLayout."Line No.", ColumnLayout.Formula));
    end;

    procedure InsertGLAccounts(var AccSchedLine: Record "Acc. Schedule Line")
    var
        GLAcc: Record "G/L Account";
        GLAccList: Page "G/L Account List";
        AccCounter: Integer;
        AccSchedLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertGLAccounts(AccSchedLine, IsHandled);
        if IsHandled then
            exit;

        GLAccList.LookupMode(true);
        if GLAccList.RunModal = ACTION::LookupOK then begin
            GLAccList.SetSelection(GLAcc);
            AccCounter := GLAcc.Count();
            if AccCounter > 0 then begin
                AccSchedLineNo := AccSchedLine."Line No.";
                MoveAccSchedLines(AccSchedLine, AccCounter);
                if GLAcc.FindSet then
                    repeat
                        AccSchedLine.Init();
                        AccSchedLineNo := AccSchedLineNo + 10000;
                        AccSchedLine."Line No." := AccSchedLineNo;
                        AccSchedLine.Description := GLAcc.Name;
                        AccSchedLine.Validate(Indentation, GLAcc.Indentation);
                        AccSchedLine.Bold := GLAcc."Account Type" <> GLAcc."Account Type"::Posting;
                        if GLAcc."Account Type" in
                           [GLAcc."Account Type"::Posting, GLAcc."Account Type"::Total, GLAcc."Account Type"::"End-Total"]
                        then begin
                            AccSchedLine.Totaling := GLAcc."No.";
                            AccSchedLine."Row No." := CopyStr(GLAcc."No.", 1, MaxStrLen(AccSchedLine."Row No."));
                        end;
                        if GLAcc."Account Type" in
                           [GLAcc."Account Type"::Total, GLAcc."Account Type"::"End-Total"]
                        then
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Total Accounts"
                        else
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Posting Accounts";
                        OnInsertGLAccountsOnBeforeAccSchedLineInsert(AccSchedLine, GLAcc);
                        AccSchedLine.Insert();
                    until GLAcc.Next() = 0;
            end;
        end;

        OnAfterInsertGLAccounts(AccSchedLine);
    end;

    procedure InsertCFAccounts(var AccSchedLine: Record "Acc. Schedule Line")
    var
        CashFlowAcc: Record "Cash Flow Account";
        CashFlowAccList: Page "Cash Flow Account List";
        AccCounter: Integer;
        AccSchedLineNo: Integer;
    begin
        CashFlowAccList.LookupMode(true);
        if CashFlowAccList.RunModal = ACTION::LookupOK then begin
            CashFlowAccList.SetSelection(CashFlowAcc);
            AccCounter := CashFlowAcc.Count();
            if AccCounter > 0 then begin
                AccSchedLineNo := AccSchedLine."Line No.";
                MoveAccSchedLines(AccSchedLine, AccCounter);
                if CashFlowAcc.FindSet then
                    repeat
                        AccSchedLine.Init();
                        AccSchedLineNo := AccSchedLineNo + 10000;
                        AccSchedLine."Line No." := AccSchedLineNo;
                        AccSchedLine.Description := CashFlowAcc.Name;
                        if CashFlowAcc."Account Type" in
                           [CashFlowAcc."Account Type"::Entry, CashFlowAcc."Account Type"::Total, CashFlowAcc."Account Type"::"End-Total"]
                        then begin
                            AccSchedLine.Totaling := CashFlowAcc."No.";
                            AccSchedLine."Row No." := CopyStr(CashFlowAcc."No.", 1, MaxStrLen(AccSchedLine."Row No."));
                        end;
                        if CashFlowAcc."Account Type" in
                           [CashFlowAcc."Account Type"::Total, CashFlowAcc."Account Type"::"End-Total"]
                        then
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Cash Flow Total Accounts"
                        else
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts";
                        AccSchedLine.Insert();
                    until CashFlowAcc.Next() = 0;
            end;
        end;
    end;

    procedure InsertCostTypes(var AccSchedLine: Record "Acc. Schedule Line")
    var
        CostType: Record "Cost Type";
        CostTypeList: Page "Cost Type List";
        AccCounter: Integer;
        AccSchedLineNo: Integer;
    begin
        CostTypeList.LookupMode(true);
        if CostTypeList.RunModal = ACTION::LookupOK then begin
            CostTypeList.SetSelection(CostType);
            AccCounter := CostType.Count();
            if AccCounter > 0 then begin
                AccSchedLineNo := AccSchedLine."Line No.";
                MoveAccSchedLines(AccSchedLine, AccCounter);
                if CostType.FindSet then
                    repeat
                        AccSchedLine.Init();
                        AccSchedLineNo := AccSchedLineNo + 10000;
                        AccSchedLine."Line No." := AccSchedLineNo;
                        AccSchedLine.Description := CostType.Name;
                        if CostType.Type in
                           [CostType.Type::"Cost Type", CostType.Type::Total, CostType.Type::"End-Total"]
                        then begin
                            AccSchedLine.Totaling := CostType."No.";
                            AccSchedLine."Row No." := CopyStr(CostType."No.", 1, MaxStrLen(AccSchedLine."Row No."));
                        end;
                        if CostType.Type in
                           [CostType.Type::Total, CostType.Type::"End-Total"]
                        then
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Cost Type Total"
                        else
                            AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Cost Type";
                        AccSchedLine.Insert();
                    until CostType.Next() = 0;
            end;
        end;
    end;

    local procedure IsExpressionFilter(Expression: Text) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsExpressionFilter(Expression, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(
          StrPos(Expression, '..') +
          StrPos(Expression, '|') +
          StrPos(Expression, '<') +
          StrPos(Expression, '>') +
          StrPos(Expression, '&') +
          StrPos(Expression, '=') > 0);
    end;

    local procedure ExchangeAmtAddCurrToLCY(AmountLCY: Decimal): Decimal
    begin
        GetGLSetup;
        exit(
          CurrExchRate.ExchangeAmtLCYToFCY(
            WorkDate, GLSetup."Additional Reporting Currency", AmountLCY,
            CurrExchRate.ExchangeRate(WorkDate, GLSetup."Additional Reporting Currency")));
    end;

    procedure SetAccSchedName(var NewAccSchedName: Record "Acc. Schedule Name")
    begin
        AccSchedName := NewAccSchedName;
    end;

    procedure GetDimTotalingFilter(DimNo: Integer; DimTotaling: Text[250]): Text[1024]
    var
        DimTotaling2: Text[250];
        DimTotalPart: Text[250];
        ResultFilter: Text[1024];
        ResultFilter2: Text[1024];
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
            ResultFilter2 := ConvDimTotalingFilter(DimNo, DimTotalPart);
            if ResultFilter2 <> '' then
                if StrLen(ResultFilter) + StrLen(ResultFilter2) + 1 > MaxStrLen(ResultFilter) then
                    Error(Text021, DimTotaling);

            if ResultFilter <> '' then
                ResultFilter := ResultFilter + '|';
            ResultFilter := CopyStr(ResultFilter + ResultFilter2, 1, MaxStrLen(ResultFilter));
        until i <= 0;
        exit(ResultFilter);
    end;

    local procedure ConvDimTotalingFilter(DimNo: Integer; DimTotaling: Text[250]): Text[1024]
    var
        DimVal: Record "Dimension Value";
        CostAccSetup: Record "Cost Accounting Setup";
        DimCode: Code[20];
        ResultFilter: Text[1024];
        DimValTotaling: Boolean;
    begin
        if CostAccSetup.Get then;
        if DimTotaling = '' then
            exit(DimTotaling);

        CheckAnalysisView(AccSchedName.Name, '', false);

        case DimNo of
            1:
                DimCode := AnalysisView."Dimension 1 Code";
            2:
                DimCode := AnalysisView."Dimension 2 Code";
            3:
                DimCode := AnalysisView."Dimension 3 Code";
            4:
                DimCode := AnalysisView."Dimension 4 Code";
            5:
                DimCode := CostAccSetup."Cost Center Dimension";
            6:
                DimCode := CostAccSetup."Cost Object Dimension";
            else
                OnConvDimTotalingFilterOnDimNoElseCase(DimNo, DimCode, AnalysisView, CostAccSetup);
        end;
        if DimCode = '' then
            exit(DimTotaling);

        DimVal.SetRange("Dimension Code", DimCode);
        DimVal.SetFilter(Code, DimTotaling);
        if DimVal.Find('-') then
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

    local procedure CalcCostType(var CostType: Record "Cost Type"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean) ColValue: Decimal
    var
        CostEntry: Record "Cost Entry";
        CostBudgEntry: Record "Cost Budget Entry";
        AmountType: Enum "Account Schedule Amount Type";
        UseDimFilter: Boolean;
        TestBalance: Boolean;
        Balance: Decimal;
        IsHandled: Boolean;
    begin
        ColValue := 0;
        IsHandled := false;
        OnBeforeCalcCostType(CostType, AccSchedLine, ColumnLayout, CalcAddCurr, ColValue, IsHandled);
        if IsHandled then
            exit(ColValue);

        if AccSchedName.Name <> AccSchedLine."Schedule Name" then
            AccSchedName.Get(AccSchedLine."Schedule Name");

        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit(0);

        TestBalance :=
          AccSchedLine.Show in [AccSchedLine.Show::"When Positive Balance", AccSchedLine.Show::"When Negative Balance"];

        if ColumnLayout."Column Type" <> ColumnLayout."Column Type"::Formula then begin
            UseDimFilter := HasDimFilter(AccSchedLine, ColumnLayout) or HasCostDimFilter(AccSchedLine);
            case ColumnLayout."Ledger Entry Type" of
                ColumnLayout."Ledger Entry Type"::Entries:
                    begin
                        SetCostEntryFilters(CostType, CostEntry, AccSchedLine, ColumnLayout, UseDimFilter);

                        case AmountType of
                            AmountType::"Net Amount":
                                begin
                                    if CalcAddCurr then begin
                                        CostEntry.CalcSums("Additional-Currency Amount");
                                        ColValue := CostEntry."Additional-Currency Amount";
                                    end else begin
                                        CostEntry.CalcSums(Amount);
                                        ColValue := CostEntry.Amount;
                                    end;
                                    Balance := ColValue;
                                end;
                            AmountType::"Debit Amount":
                                if CalcAddCurr then begin
                                    CostEntry.CalcSums("Add.-Currency Debit Amount", "Additional-Currency Amount");
                                    if TestBalance then
                                        Balance := CostEntry."Additional-Currency Amount";
                                    ColValue := CostEntry."Add.-Currency Debit Amount";
                                end else begin
                                    if TestBalance then begin
                                        CostEntry.CalcSums("Debit Amount", Amount);
                                        Balance := CostEntry.Amount;
                                    end else
                                        CostEntry.CalcSums("Debit Amount");
                                    ColValue := CostEntry."Debit Amount";
                                end;
                            AmountType::"Credit Amount":
                                if CalcAddCurr then begin
                                    CostEntry.CalcSums("Add.-Currency Credit Amount", "Additional-Currency Amount");
                                    if TestBalance then
                                        Balance := CostEntry."Additional-Currency Amount";
                                    ColValue := CostEntry."Add.-Currency Credit Amount";
                                end else begin
                                    if TestBalance then begin
                                        CostEntry.CalcSums("Credit Amount", Amount);
                                        Balance := CostEntry.Amount;
                                    end else
                                        CostEntry.CalcSums("Credit Amount");
                                    ColValue := CostEntry."Credit Amount";
                                end;
                        end;
                    end;
                ColumnLayout."Ledger Entry Type"::"Budget Entries":
                    begin
                        SetCostBudgetEntryFilters(CostType, CostBudgEntry, AccSchedLine, ColumnLayout);

                        CostBudgEntry.CalcSums(Amount);

                        case AmountType of
                            AmountType::"Net Amount":
                                ColValue := CostBudgEntry.Amount;
                            AmountType::"Debit Amount":
                                if CostBudgEntry.Amount > 0 then
                                    ColValue := CostBudgEntry.Amount;
                            AmountType::"Credit Amount":
                                if CostBudgEntry.Amount < 0 then
                                    ColValue := CostBudgEntry.Amount;
                        end;
                        Balance := CostBudgEntry.Amount;
                        if CalcAddCurr then
                            ColValue := CalcLCYToACY(ColValue);
                    end;
            end;

            if TestBalance then begin
                if AccSchedLine.Show = AccSchedLine.Show::"When Positive Balance" then
                    if Balance < 0 then
                        exit(0);
                if AccSchedLine.Show = AccSchedLine.Show::"When Negative Balance" then
                    if Balance > 0 then
                        exit(0);
            end;
        end;
        exit(ColValue);
    end;

    local procedure SetCostEntryFilters(var CostType: Record "Cost Type"; var CostEntry: Record "Cost Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseDimFilter: Boolean)
    begin
        with CostEntry do begin
            if UseDimFilter then
                SetCurrentKey("Cost Type No.", "Cost Center Code", "Cost Object Code")
            else
                SetCurrentKey("Cost Type No.", "Posting Date");
            if CostType.Totaling = '' then
                SetRange("Cost Type No.", CostType."No.")
            else
                SetFilter("Cost Type No.", CostType.Totaling);
            CostType.CopyFilter("Date Filter", "Posting Date");
            AccSchedLine.CopyFilter("Cost Center Filter", "Cost Center Code");
            AccSchedLine.CopyFilter("Cost Object Filter", "Cost Object Code");
            FilterGroup(2);
            SetFilter("Cost Center Code", GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
            SetFilter("Cost Object Code", GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
            FilterGroup(8);
            SetFilter("Cost Center Code", GetDimTotalingFilter(5, ColumnLayout."Cost Center Totaling"));
            SetFilter("Cost Object Code", GetDimTotalingFilter(6, ColumnLayout."Cost Object Totaling"));
            FilterGroup(0);
        end;

        OnAfterSetCostEntryFilters(CostType, CostEntry, AccSchedLine, ColumnLayout, UseDimFilter);
    end;

    local procedure SetCostBudgetEntryFilters(var CostType: Record "Cost Type"; var CostBudgetEntry: Record "Cost Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with CostBudgetEntry do begin
            SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
            if CostType.Totaling = '' then
                SetRange("Cost Type No.", CostType."No.")
            else
                SetFilter("Cost Type No.", CostType.Totaling);
            CostType.CopyFilter("Date Filter", Date);
            AccSchedLine.CopyFilter("Cost Budget Filter", "Budget Name");
            AccSchedLine.CopyFilter("Cost Center Filter", "Cost Center Code");
            AccSchedLine.CopyFilter("Cost Object Filter", "Cost Object Code");
            FilterGroup(2);
            SetFilter("Cost Center Code", GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
            SetFilter("Cost Object Code", GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
            FilterGroup(8);
            SetFilter("Cost Center Code", GetDimTotalingFilter(5, ColumnLayout."Cost Center Totaling"));
            SetFilter("Cost Object Code", GetDimTotalingFilter(6, ColumnLayout."Cost Object Totaling"));
            FilterGroup(0);
        end;

        OnAfterSetCostBudgetEntryFilters(CostType, CostBudgetEntry, AccSchedLine, ColumnLayout);
    end;

    procedure SetCostTypeRowFilters(var CostType: Record "Cost Type"; var AccSchedLine2: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        with AccSchedLine2 do begin
            case "Totaling Type" of
                "Totaling Type"::"Cost Type":
                    begin
                        CostType.SetFilter("No.", Totaling);
                        CostType.SetRange(Type, CostType.Type::"Cost Type");
                    end;
                "Totaling Type"::"Cost Type Total":
                    begin
                        CostType.SetFilter("No.", Totaling);
                        CostType.SetFilter(Type, '<>%1', CostType.Type::"Cost Type");
                    end;
            end;

            CostType.SetFilter("Cost Center Filter", GetFilter("Cost Center Filter"));
            CostType.SetFilter("Cost Object Filter", GetFilter("Cost Object Filter"));
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::"Budget Entries" then
                CostType.SetFilter("Budget Filter", GetFilter("Cost Budget Filter"));
        end;

        OnAfterSetCostTypeRowFilters(CostType, AccSchedLine2);
    end;

    procedure SetCostTypeColumnFilters(var CostType: Record "Cost Type"; AccSchedLine2: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate2: Date;
    begin
        with ColumnLayout do begin
            CalcColumnDates(ColumnLayout, FromDate, ToDate, FiscalStartDate2);
            case "Column Type" of
                "Column Type"::"Net Change":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CostType.SetRange("Date Filter", FromDate, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CostType.SetFilter("Date Filter", '<%1', FromDate);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CostType.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Balance at Date":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Beginning Balance" then
                        CostType.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        CostType.SetRange("Date Filter", 0D, ToDate);
                "Column Type"::"Beginning Balance":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Balance at Date" then
                        CostType.SetRange("Date Filter", 0D) // Force a zero return
                    else
                        CostType.SetRange(
                          "Date Filter", 0D, CalcDate('<-1D>', FromDate));
                "Column Type"::"Year to Date":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CostType.SetRange("Date Filter", FiscalStartDate2, ToDate);
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CostType.SetFilter("Date Filter", '<%1', FiscalStartDate2);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CostType.SetRange("Date Filter", 0D, ToDate);
                    end;
                "Column Type"::"Rest of Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CostType.SetRange(
                              "Date Filter", CalcDate('<+1D>', ToDate), AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CostType.SetRange("Date Filter", 0D, ToDate);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CostType.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
                "Column Type"::"Entire Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            CostType.SetRange(
                              "Date Filter", FiscalStartDate2, AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            CostType.SetFilter("Date Filter", '<%1', FiscalStartDate2);
                        AccSchedLine2."Row Type"::"Balance at Date":
                            CostType.SetRange("Date Filter", 0D, AccountingPeriodMgt.FindEndOfFiscalYear(ToDate));
                    end;
            end;
        end;

        OnAfterSetCostTypeColumnFilters(CostType, AccSchedLine2, ColumnLayout);
    end;

    procedure HasDimFilter(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"): Boolean
    begin
        exit((AccSchedLine."Dimension 1 Totaling" <> '') or
          (AccSchedLine."Dimension 2 Totaling" <> '') or
          (AccSchedLine."Dimension 3 Totaling" <> '') or
          (AccSchedLine."Dimension 4 Totaling" <> '') or
          (AccSchedLine.GetFilter("Dimension 1 Filter") <> '') or
          (AccSchedLine.GetFilter("Dimension 2 Filter") <> '') or
          (AccSchedLine.GetFilter("Dimension 3 Filter") <> '') or
          (AccSchedLine.GetFilter("Dimension 4 Filter") <> '') or
          (ColumnLayout."Dimension 1 Totaling" <> '') or
          (ColumnLayout."Dimension 2 Totaling" <> '') or
          (ColumnLayout."Dimension 3 Totaling" <> '') or
          (ColumnLayout."Dimension 4 Totaling" <> '') or
          (ColumnLayout."Cost Center Totaling" <> '') or
          (ColumnLayout."Cost Object Totaling" <> ''));
    end;

    local procedure HasCostDimFilter(var AccSchedLine: Record "Acc. Schedule Line"): Boolean
    begin
        exit((AccSchedLine."Cost Center Totaling" <> '') or
          (AccSchedLine."Cost Object Totaling" <> '') or
          (AccSchedLine.GetFilter("Cost Center Filter") <> '') or
          (AccSchedLine.GetFilter("Cost Object Filter") <> ''));
    end;

    procedure CalcColumnDates(ColumnLayout: Record "Column Layout"; var FromDate: Date; var ToDate: Date; var FiscalStartDate2: Date)
    var
        ComparisonDateFormula: DateFormula;
        ComparisonPeriodFormula: Code[20];
    begin
        ComparisonDateFormula := ColumnLayout."Comparison Date Formula";
        ComparisonPeriodFormula := ColumnLayout."Comparison Period Formula";

        if (Format(ComparisonDateFormula) <> '0') and (Format(ComparisonDateFormula) <> '') then begin
            FromDate := CalcDate(ComparisonDateFormula, StartDate);
            ToDate := CalcDate(ComparisonDateFormula, EndDate);
            if (StartDate = CalcDate('<-CM>', StartDate)) and
               (FromDate = CalcDate('<-CM>', FromDate)) and
               (EndDate = CalcDate('<CM>', EndDate))
            then
                ToDate := CalcDate('<CM>', ToDate);
            FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
        end else
            if ComparisonPeriodFormula <> '' then begin
                AccPeriodStartEnd(ColumnLayout, StartDate, FromDate, ToDate);
                FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
            end else begin
                FromDate := StartDate;
                ToDate := EndDate;
                FiscalStartDate2 := FiscalStartDate;
            end;
    end;

    local procedure MoveAccSchedLines(var AccSchedLine: Record "Acc. Schedule Line"; Place: Integer)
    var
        AccSchedLineNo: Integer;
        I: Integer;
    begin
        AccSchedLineNo := AccSchedLine."Line No.";
        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
        if AccSchedLine.Find('+') then
            repeat
                I := AccSchedLine."Line No.";
                if I > AccSchedLineNo then begin
                    AccSchedLine.Delete();
                    OnMoveAccSchedLinesOnAfterAccSchedLineDelete(AccSchedLine, Place);
                    AccSchedLine."Line No." := I + 10000 * Place;
                    AccSchedLine.Insert();
                    OnAfterAccSchedLineInsert(AccSchedLine);
                end;
            until (I <= AccSchedLineNo) or (AccSchedLine.Next(-1) = 0);
    end;

    procedure SetStartDateEndDate(NewStartDate: Date; NewEndDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    local procedure ConflictAmountType(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayoutAmtType: Enum "Account Schedule Amount Type"; var AmountType: Enum "Account Schedule Amount Type"): Boolean
    begin
        if (ColumnLayoutAmtType = AccSchedLine."Amount Type") or
           (AccSchedLine."Amount Type" = AccSchedLine."Amount Type"::"Net Amount")
        then
            AmountType := ColumnLayoutAmtType
        else
            if ColumnLayoutAmtType = ColumnLayoutAmtType::"Net Amount" then
                AmountType := AccSchedLine."Amount Type"
            else
                exit(true);
        exit(false);
    end;

    procedure DrillDown(TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line"; PeriodLength: Option)
    var
        AccScheduleOverview: Page "Acc. Schedule Overview";
        ErrorType: Option "None","Division by Zero","Period Error",Both;
    begin
        with AccScheduleLine do begin
            if TempColumnLayout."Column Type" = TempColumnLayout."Column Type"::Formula then begin
                CalcFieldError(ErrorType, "Line No.", TempColumnLayout."Line No.");
                if ErrorType <> ErrorType::None then
                    Message(StrSubstNo(ColumnFormulaErrorMsg, TempColumnLayout.Formula, Format(ErrorType)))
                else
                    Message(ColumnFormulaMsg, TempColumnLayout.Formula);
                exit;
            end;

            if "Totaling Type" in ["Totaling Type"::Formula, "Totaling Type"::"Set Base For Percent"] then begin
                AccScheduleOverview.SetAccSchedName("Schedule Name");
                AccScheduleOverview.SetTableView(AccScheduleLine);
                AccScheduleOverview.SetRecord(AccScheduleLine);
                AccScheduleOverview.SetPeriodType(PeriodLength);
                AccScheduleOverview.Run;
                exit;
            end;

            OnBeforeDrillDownOnAccounts(AccScheduleLine, TempColumnLayout, PeriodLength, StartDate, EndDate);

            if Totaling = '' then
                exit;
#if not CLEAN19
            // NAVCZ
            if "Totaling Type" = "Totaling Type"::Custom then begin
                AccSchedExtensionManagement.DrillDownAmount(
                  AccScheduleLine,
                  TempColumnLayout,
                  Totaling,
                  GetRangeMin("Date Filter"),
                  GetRangeMax("Date Filter"));
                exit;
            end;
            // NAVCZ
#endif

            if "Totaling Type" in ["Totaling Type"::"Cash Flow Entry Accounts", "Totaling Type"::"Cash Flow Total Accounts"] then
                DrillDownOnCFAccount(TempColumnLayout, AccScheduleLine)
            else
                DrillDownOnGLAccount(TempColumnLayout, AccScheduleLine);
        end;
    end;

    procedure DrillDownFromOverviewPage(TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line"; PeriodLength: Option)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownFromOverviewPage(TempColumnLayout, AccScheduleLine, PeriodLength, IsHandled);
        if IsHandled then
            exit;

        with AccScheduleLine do begin
            if ("Totaling Type" = "Totaling Type"::Formula) and
               (TempColumnLayout."Column Type" = TempColumnLayout."Column Type"::Formula)
            then
                Message(RowFormulaMsg, TempColumnLayout.Formula)
            else
                if "Totaling Type" in ["Totaling Type"::Formula, "Totaling Type"::"Set Base For Percent"] then
                    Message(RowFormulaMsg, Totaling)
                else
                    DrillDown(TempColumnLayout, AccScheduleLine, PeriodLength);
        end;
    end;

    local procedure DrillDownOnGLAccount(TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line")
    var
        GLAcc: Record "G/L Account";
        GLAccAnalysisView: Record "G/L Account (Analysis View)";
        CostType: Record "Cost Type";
        ChartOfAccsAnalysisView: Page "Chart of Accs. (Analysis View)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownOnGLAccount(TempColumnLayout, AccScheduleLine, IsHandled);
        if IsHandled then
            exit;

        with AccScheduleLine do
            if "Totaling Type" in ["Totaling Type"::"Cost Type", "Totaling Type"::"Cost Type Total"] then begin
                SetCostTypeRowFilters(CostType, AccScheduleLine, TempColumnLayout);
                SetCostTypeColumnFilters(CostType, AccScheduleLine, TempColumnLayout);
                CopyFilter("Cost Center Filter", CostType."Cost Center Filter");
                CopyFilter("Cost Object Filter", CostType."Cost Object Filter");
                CopyFilter("Cost Budget Filter", CostType."Budget Filter");
                CostType.FilterGroup(2);
                CostType.SetFilter("Cost Center Filter", GetDimTotalingFilter(1, "Cost Center Totaling"));
                CostType.SetFilter("Cost Object Filter", GetDimTotalingFilter(1, "Cost Object Totaling"));
                CostType.FilterGroup(8);
                CostType.SetFilter("Cost Center Filter", GetDimTotalingFilter(1, TempColumnLayout."Cost Center Totaling"));
                CostType.SetFilter("Cost Object Filter", GetDimTotalingFilter(1, TempColumnLayout."Cost Object Totaling"));
                CostType.FilterGroup(0);
                PAGE.Run(PAGE::"Chart of Cost Types", CostType);
            end else begin
                CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                CopyFilter("G/L Budget Filter", GLAcc."Budget Filter");
                SetGLAccRowFilters(GLAcc, AccScheduleLine);
                SetGLAccColumnFilters(GLAcc, AccScheduleLine, TempColumnLayout);
                AccSchedName.Get("Schedule Name");
                if AccSchedName."Analysis View Name" = '' then begin
                    OnDrillDownOnGLAccountOnBeforeCopyFiltersEmptyAnalysisViewName(AccScheduleLine, TempColumnLayout);
                    CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                    CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                    CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                    GLAcc.FilterGroup(2);
                    GLAcc.SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(1, "Dimension 1 Totaling"));
                    GLAcc.SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(2, "Dimension 2 Totaling"));
                    GLAcc.FilterGroup(8);
                    GLAcc.SetFilter("Business Unit Filter", TempColumnLayout."Business Unit Totaling");
                    GLAcc.SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(1, TempColumnLayout."Dimension 1 Totaling"));
                    GLAcc.SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(2, TempColumnLayout."Dimension 2 Totaling"));
                    GLAcc.FilterGroup(0);
                    PAGE.Run(PAGE::"Chart of Accounts (G/L)", GLAcc)
                end else begin
                    GLAcc.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
                    GLAcc.CopyFilter("Budget Filter", GLAccAnalysisView."Budget Filter");
                    GLAcc.CopyFilter("Business Unit Filter", GLAccAnalysisView."Business Unit Filter");
                    GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
                    GLAccAnalysisView.CopyDimFilters(AccScheduleLine);
                    GLAccAnalysisView.FilterGroup(2);
                    GLAccAnalysisView.SetDimFilters(
                      GetDimTotalingFilter(1, "Dimension 1 Totaling"), GetDimTotalingFilter(2, "Dimension 2 Totaling"),
                      GetDimTotalingFilter(3, "Dimension 3 Totaling"), GetDimTotalingFilter(4, "Dimension 4 Totaling"));
                    GLAccAnalysisView.FilterGroup(8);
                    GLAccAnalysisView.SetDimFilters(
                      GetDimTotalingFilter(1, TempColumnLayout."Dimension 1 Totaling"),
                      GetDimTotalingFilter(2, TempColumnLayout."Dimension 2 Totaling"),
                      GetDimTotalingFilter(3, TempColumnLayout."Dimension 3 Totaling"),
                      GetDimTotalingFilter(4, TempColumnLayout."Dimension 4 Totaling"));
                    GLAccAnalysisView.SetFilter("Business Unit Filter", TempColumnLayout."Business Unit Totaling");
                    GLAccAnalysisView.FilterGroup(0);
                    Clear(ChartOfAccsAnalysisView);
                    ChartOfAccsAnalysisView.InsertTempGLAccAnalysisViews(GLAcc);
                    ChartOfAccsAnalysisView.SetTableView(GLAccAnalysisView);
                    ChartOfAccsAnalysisView.Run;
                end;
            end;
    end;

    local procedure DrillDownOnCFAccount(TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line")
    var
        CFAccount: Record "Cash Flow Account";
        GLAccAnalysisView: Record "G/L Account (Analysis View)";
        ChartOfAccsAnalysisView: Page "Chart of Accs. (Analysis View)";
    begin
        with AccScheduleLine do begin
            CopyFilter("Cash Flow Forecast Filter", CFAccount."Cash Flow Forecast Filter");

            SetCFAccRowFilter(CFAccount, AccScheduleLine);
            SetCFAccColumnFilter(CFAccount, AccScheduleLine, TempColumnLayout);
            AccSchedName.Get("Schedule Name");
            if AccSchedName."Analysis View Name" = '' then begin
                CopyFilter("Dimension 1 Filter", CFAccount."Global Dimension 1 Filter");
                CopyFilter("Dimension 2 Filter", CFAccount."Global Dimension 2 Filter");
                CFAccount.FilterGroup(2);
                CFAccount.SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(1, "Dimension 1 Totaling"));
                CFAccount.SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(2, "Dimension 2 Totaling"));
                CFAccount.FilterGroup(8);
                CFAccount.SetFilter("Global Dimension 1 Filter", GetDimTotalingFilter(1, TempColumnLayout."Dimension 1 Totaling"));
                CFAccount.SetFilter("Global Dimension 2 Filter", GetDimTotalingFilter(2, TempColumnLayout."Dimension 2 Totaling"));
                CFAccount.FilterGroup(0);
                PAGE.Run(PAGE::"Chart of Cash Flow Accounts", CFAccount)
            end else begin
                CFAccount.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
                CFAccount.CopyFilter("Cash Flow Forecast Filter", GLAccAnalysisView."Cash Flow Forecast Filter");
                GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
                GLAccAnalysisView.CopyDimFilters(AccScheduleLine);
                GLAccAnalysisView.FilterGroup(2);
                GLAccAnalysisView.SetDimFilters(
                  GetDimTotalingFilter(1, "Dimension 1 Totaling"),
                  GetDimTotalingFilter(2, "Dimension 2 Totaling"),
                  GetDimTotalingFilter(3, "Dimension 3 Totaling"),
                  GetDimTotalingFilter(4, "Dimension 4 Totaling"));
                GLAccAnalysisView.FilterGroup(8);
                GLAccAnalysisView.SetDimFilters(
                  GetDimTotalingFilter(1, TempColumnLayout."Dimension 1 Totaling"),
                  GetDimTotalingFilter(2, TempColumnLayout."Dimension 2 Totaling"),
                  GetDimTotalingFilter(3, TempColumnLayout."Dimension 3 Totaling"),
                  GetDimTotalingFilter(4, TempColumnLayout."Dimension 4 Totaling"));
                GLAccAnalysisView.FilterGroup(0);
                Clear(ChartOfAccsAnalysisView);
                ChartOfAccsAnalysisView.InsertTempCFAccountAnalysisVie(CFAccount);
                ChartOfAccsAnalysisView.SetTableView(GLAccAnalysisView);
                ChartOfAccsAnalysisView.Run;
            end;
        end;
    end;

    procedure FindPeriod(var AccScheduleLine: Record "Acc. Schedule Line"; SearchText: Text[3]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period")
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        with AccScheduleLine do begin
            if GetFilter("Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
                if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                    PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
            SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                SetRange("Date Filter", GetRangeMin("Date Filter"));
        end;
    end;

    procedure CalcFieldError(var ErrorType: Option "None","Division by Zero","Period Error",Both; RowNo: Integer; ColumnNo: Integer)
    begin
        AccSchedCellValue.SetRange("Row No.", RowNo);
        AccSchedCellValue.SetRange("Column No.", ColumnNo);
        ErrorType := ErrorType::None;
        if AccSchedCellValue.FindFirst then
            case true of
                AccSchedCellValue."Has Error":
                    ErrorType := ErrorType::"Division by Zero";
                AccSchedCellValue."Period Error":
                    ErrorType := ErrorType::"Period Error";
                AccSchedCellValue."Has Error" and AccSchedCellValue."Period Error":
                    ErrorType := ErrorType::Both;
            end;

        AccSchedCellValue.SetRange("Row No.");
        AccSchedCellValue.SetRange("Column No.");
    end;

#if not CLEAN19
    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure ValidateFormula(AccScheduleLine: Record "Acc. Schedule Line")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayout: Record "Column Layout";
        SavedAccountScheduleLine: Record "Acc. Schedule Line";
    begin
        // NAVCZ
        AccScheduleName.Get(AccScheduleLine."Schedule Name");
        ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Net Change";
        AccScheduleLine.SetRange("Date Filter", Today);
        SavedAccountScheduleLine := AccScheduleLine;
        CalcCell(AccScheduleLine, ColumnLayout, false);
        AccScheduleLine := SavedAccountScheduleLine;
    end;

    [Obsolete('This procedure will be removed.', '19.0')]
    [Scope('OnPrem')]
    procedure SetDateFilter(DateFilter: Text[250]): Text[250]
    var
        Position: Integer;
        LengthDateFilter: Integer;
        Text002: Label '..CP';
        Text003: Label '..BD';
        Text004: Label '..ED';
        Text005: Label 'BD..';
        Text006: Label 'ED..';
        Text007: Label 'CP';
        Text008: Label 'BD';
        Text009: Label 'ED';
        ErrorDateFilter: Label 'Illegal value Date Filter = %1';
    begin
        // NAVCZ
        LengthDateFilter := StrLen(DateFilter);
        DateFilter := UpperCase(DateFilter);
        Position := StrPos(DateFilter, '.');
        if Position = 1
        then begin
            if CopyStr(DateFilter, 1, 4) = Text002 then
                if not (EndDate = 0D) then begin
                    if LengthDateFilter > 4 then
                        exit(StrSubstNo('%2..%1',
                            CalcDate(CopyStr(DateFilter, 5), EndDate),
                            CalcDate('<CY+1D-2Y>', EndDate)));

                    exit(StrSubstNo('..%1', CalcDate('<CY+1D-1Y-1D>', EndDate)));
                end else
                    exit(StrSubstNo('%2..%1',
                        WorkDate,
                        CalcDate('<CY+1D-1Y-1D>', WorkDate)));
            if CopyStr(DateFilter, 1, 4) = Text003 then
                if not (StartDate = 0D) then begin
                    if LengthDateFilter > 4 then
                        exit(StrSubstNo('..%1', CalcDate(CopyStr(DateFilter, 5),
                              CalcDate('<-1D>', StartDate))));

                    exit(StrSubstNo('..%1', CalcDate('<-1D>', StartDate)))
                end else
                    exit(StrSubstNo('..%1', CalcDate('<-1D>', WorkDate)));
            if CopyStr(DateFilter, 1, 4) = Text004 then
                if not (EndDate = 0D) then begin
                    if LengthDateFilter > 4 then
                        exit(StrSubstNo('..%1', CalcDate(CopyStr(DateFilter, 5), EndDate)));

                    exit(StrSubstNo('..%1', EndDate));
                end else
                    exit(StrSubstNo('..%1', CalcDate('<-1D>', WorkDate)));
        end else
            if Position = 3
            then begin
                if CopyStr(DateFilter, 1, 4) = Text005 then
                    if not (StartDate = 0D) then begin
                        if LengthDateFilter > 4 then
                            exit(StrSubstNo('%1..', CalcDate(CopyStr(DateFilter, 5), StartDate)));

                        exit(StrSubstNo('%1..', StartDate));
                    end else
                        exit(StrSubstNo('%1..', WorkDate));
                if CopyStr(DateFilter, 1, 4) = Text006 then
                    if not (EndDate = 0D) then begin
                        if LengthDateFilter > 4 then
                            exit(StrSubstNo('%1..', CalcDate(CopyStr(DateFilter, 5), CalcDate('<+1D>', EndDate))));

                        exit(StrSubstNo('%1..', CalcDate('<+1D>', EndDate)));
                    end else
                        exit(StrSubstNo('%1..', CalcDate('<+1D>', WorkDate)));
            end else
                if Position = 0
                then
                    case CopyStr(DateFilter, 1, 2) of
                        Text007, '':
                            if LengthDateFilter > 2 then begin
                                if not (StartDate = 0D) and not (EndDate = 0D) then
                                    exit(StrSubstNo('%1..%2',
                                        CalcDate(CopyStr(DateFilter, 3), StartDate),
                                        CalcDate(CopyStr(DateFilter, 3), EndDate)));

                                if not (EndDate = 0D) then
                                    exit(StrSubstNo('..%1',
                                        CalcDate(CopyStr(DateFilter, 3), EndDate)));

                                if not (StartDate = 0D) then
                                    exit(StrSubstNo('%1',
                                        CalcDate(CopyStr(DateFilter, 3), StartDate)));

                                exit(StrSubstNo('..%1',
                                    CalcDate(CopyStr(DateFilter, 3), WorkDate)))
                            end else begin
                                if not (StartDate = 0D) and not (EndDate = 0D) then
                                    exit(StrSubstNo('%1..%2', StartDate, EndDate));

                                if not (EndDate = 0D) then
                                    exit(StrSubstNo('..%1', EndDate));

                                if not (StartDate = 0D) then
                                    exit(StrSubstNo('%1', StartDate));

                                exit(StrSubstNo('..%1', WorkDate));
                            end;
                        Text008:
                            if not (StartDate = 0D) then begin
                                if LengthDateFilter > 2 then
                                    exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), StartDate)));

                                exit(StrSubstNo('%1', StartDate));
                            end else begin
                                if LengthDateFilter > 2 then
                                    exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), WorkDate)));

                                exit(StrSubstNo('%1', WorkDate));
                            end;
                        Text009:
                            if not (EndDate = 0D) then begin
                                if LengthDateFilter > 2 then
                                    exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), EndDate)));

                                exit(StrSubstNo('%1', EndDate));
                            end else begin
                                if LengthDateFilter > 2 then
                                    exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), WorkDate)));

                                exit(StrSubstNo('%1', WorkDate));
                            end;
                    end;
        Error(ErrorDateFilter, DateFilter);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure PrepareToSaveResults(AccScheduleName: Code[10]; ColumnLayoutName: Code[10]; DateFilter: Text[30]; Dim1Filter: Text[250]; Dim2Filter: Text[250]; Dim3Filter: Text[250]; Dim4Filter: Text[250]; Description: Text[50])
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleResultLine: Record "Acc. Schedule Result Line";
        AccScheduleResultColumn: Record "Acc. Schedule Result Column";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        // NAVCZ
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        GLSetup.TestField("Acc. Schedule Results Nos.");

        AccScheduleResultsHeader.Init();
        AccScheduleResultsHeader."Result Code" :=
          NoSeriesManagement.GetNextNo(GLSetup."Acc. Schedule Results Nos.", Today, true);
        AccScheduleResultsHeader."Acc. Schedule Name" := AccScheduleName;
        AccScheduleResultsHeader."Column Layout Name" := ColumnLayoutName;
        AccScheduleResultsHeader."Date Filter" := DateFilter;
        AccScheduleResultsHeader."User ID" := UserId;
        AccScheduleResultsHeader."Result Date" := Today;
        AccScheduleResultsHeader."Result Time" := Time;
        AccScheduleResultsHeader."Dimension 1 Filter" := Dim1Filter;
        AccScheduleResultsHeader."Dimension 2 Filter" := Dim2Filter;
        AccScheduleResultsHeader."Dimension 3 Filter" := Dim3Filter;
        AccScheduleResultsHeader."Dimension 4 Filter" := Dim4Filter;
        AccScheduleResultsHeader.Description := Description;
        AccScheduleResultsHeader.Insert();

        AccountScheduleLine.SetRange("Schedule Name", AccScheduleName);
        if AccountScheduleLine.FindSet then
            repeat
                AccScheduleResultLine.TransferFields(AccountScheduleLine);
                AccScheduleResultLine."Result Code" := AccScheduleResultsHeader."Result Code";
                AccScheduleResultLine.Insert();
            until AccountScheduleLine.Next() = 0;

        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        if ColumnLayout.FindSet then
            repeat
                AccScheduleResultColumn.TransferFields(ColumnLayout);
                AccScheduleResultColumn."Result Code" := AccScheduleResultsHeader."Result Code";
                AccScheduleResultColumn.Insert();
            until ColumnLayout.Next() = 0;

        SaveResults := true;
    end;

    [Obsolete('This procedure will be removed.', '19.0')]
    [Scope('OnPrem')]
    procedure SaveCellValues()
    var
        AccSchedCellValue1: Record "Acc. Sched. Cell Value";
    begin
        // NAVCZ
        if AccSchedCellValue.Find('-') then
            repeat
                AccSchedCellValue1 := AccSchedCellValue;
                if AccSchedCellValue1.Insert() then;
            until AccSchedCellValue.Next() = 0;
    end;

    [Obsolete('This procedure will be removed.', '19.0')]
    [Scope('OnPrem')]
    procedure GetCellValuesBuffer(var Buffer: Record "Acc. Sched. Cell Value")
    begin
        // NAVCZ
        if AccSchedCellValue.Find('-') then
            repeat
                Buffer := AccSchedCellValue;
                Buffer.Insert();
            until AccSchedCellValue.Next() = 0;
        // NAVCZ
    end;

    [Obsolete('This procedure will be removed.', '19.0')]
    [Scope('OnPrem')]
    procedure SetDateParameters(NewStartDate: Date; NewEndDate: Date)
    begin
        // NAVCZ
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CreateResults(AccSchedName: Code[10]; ColumnLayoutName: Code[10]; DateFilter: Text[30]; UseAmtsInAddCurr: Boolean)
    var
        ColumnLayout: Record "Column Layout";
        SaveAccScheduleResults: Page "Save Acc. Schedule Result";
        AccSchedManagement: Codeunit AccSchedManagement;
        Description: Text[30];
    begin
        // NAVCZ
        SaveAccScheduleResults.SetParameters(AccSchedName, ColumnLayoutName, DateFilter, UseAmtsInAddCurr);
        SaveAccScheduleResults.LookupMode(true);
        if SaveAccScheduleResults.RunModal = ACTION::LookupOK then begin
            SaveAccScheduleResults.GetParameters(AccSchedName, ColumnLayoutName, DateFilter, Description, UseAmtsInAddCurr);

            if AccSchedName = '' then
                Error(Text26570);
            if ColumnLayoutName = '' then
                Error(Text26571);
            if DateFilter = '' then
                Error(Text26572);

            AccSchedManagement.PrepareToSaveResults(AccSchedName, ColumnLayoutName, DateFilter, '', '', '', '', Description);

            AccountScheduleLine.SetRange("Schedule Name", AccSchedName);
            AccountScheduleLine.SetFilter("Date Filter", DateFilter);
            ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
            if AccountScheduleLine.FindSet then
                repeat
                    if ColumnLayout.FindSet then
                        repeat
                            AccSchedManagement.CalcCell(AccountScheduleLine, ColumnLayout, UseAmtsInAddCurr);
                        until ColumnLayout.Next() = 0;
                until AccountScheduleLine.Next() = 0;
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetPostingDateFilter(AccSchedLine2: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"): Text[100]
    var
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate2: Date;
    begin
        // NAVCZ
        with ColumnLayout do begin
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
                FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
            end else
                if "Comparison Period Formula" <> '' then begin
                    AccPeriodStartEnd(ColumnLayout, StartDate, FromDate, ToDate);
                    FiscalStartDate2 := AccountingPeriodMgt.FindFiscalYear(ToDate);
                end else begin
                    FromDate := StartDate;
                    ToDate := EndDate;
                    FiscalStartDate2 := FiscalStartDate;
                end;
            case "Column Type" of
                "Column Type"::"Net Change":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            exit(StrSubstNo('%1..%2', FromDate, ToDate));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            exit(StrSubstNo('<%1', FromDate));  // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            exit(StrSubstNo('..%1', ToDate));
                    end;
                "Column Type"::"Balance at Date":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Beginning Balance" then
                        exit('''''') // Force a zero return
                    else
                        exit(StrSubstNo('..%1', ToDate));
                "Column Type"::"Beginning Balance":
                    if AccSchedLine2."Row Type" = AccSchedLine2."Row Type"::"Balance at Date" then
                        exit('''''') // Force a zero return
                    else
                        exit(StrSubstNo('..%1', ClosingDate(FromDate - 1)));
                "Column Type"::"Year to Date":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            exit(StrSubstNo('%1..%2', FiscalStartDate2, ToDate));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            exit(StrSubstNo('<%1', FiscalStartDate2));  // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            exit(StrSubstNo('..%1', ToDate));
                    end;
                "Column Type"::"Rest of Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            exit(StrSubstNo('%1..%2', CalcDate('<+1D>', ToDate), AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2)));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            exit(StrSubstNo('..%1', ToDate));
                        AccSchedLine2."Row Type"::"Balance at Date":
                            exit(StrSubstNo('..%1', AccountingPeriodMgt.FindEndOfFiscalYear(ToDate)));
                    end;
                "Column Type"::"Entire Fiscal Year":
                    case AccSchedLine2."Row Type" of
                        AccSchedLine2."Row Type"::"Net Change":
                            exit(StrSubstNo('%1..%2', FiscalStartDate2, AccountingPeriodMgt.FindEndOfFiscalYear(FiscalStartDate2)));
                        AccSchedLine2."Row Type"::"Beginning Balance":
                            exit(StrSubstNo('<%1', FiscalStartDate2));  // always includes closing date
                        AccSchedLine2."Row Type"::"Balance at Date":
                            exit(StrSubstNo('..%1', AccountingPeriodMgt.FindEndOfFiscalYear(ToDate)));
                    end;
            end;
        end;
    end;
#endif
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    [Scope('OnPrem')]
    procedure CalcCorrectionCell(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean): Decimal
    var
        AccSchedLine2: Record "Acc. Schedule Line";
    begin
        // NAVCZ
        AccSchedLine2.SetRange("Schedule Name", AccSchedLine."Schedule Name");
        AccSchedLine2.SetRange("Row Correction", AccSchedLine."Row No.");
        if AccSchedLine2.FindFirst then begin
            AccSchedLine2.CopyFilters(AccSchedLine);
            exit(CalcCell(AccSchedLine2, ColumnLayout, CalcAddCurr));
        end;
        exit(0);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure EmptyLine(var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; CalcAddCurr: Boolean): Boolean
    var
        ColumnLayout: Record "Column Layout";
        NonZero: Boolean;
    begin
        // NAVCZ
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        if ColumnLayout.FindSet(false, false) then
            repeat
                NonZero := CalcCell(AccSchedLine, ColumnLayout, CalcAddCurr) <> 0;
            until (ColumnLayout.Next() = 0) or NonZero;
        exit(not NonZero);
    end;

#if not CLEAN19
    [Obsolete('This procedure will be removed.', '19.0')]
    [Scope('OnPrem')]
    procedure LineFilter(var Line: Record "Acc. Schedule Line"; Column: Record "Column Layout"; Show: Option " ","Non Zero",Zero)
    var
        OldLine: Record "Acc. Schedule Line";
        DecValue: Decimal;
    begin
        // NAVCZ
        if Show <> Show::" " then begin
            Line.MarkedOnly(false);
            Line.ClearMarks;

            OldLine := Line;
            Line.FindSet();
            repeat
                DecValue := CalcCell(Line, Column, false);

                case Show of
                    Show::Zero:
                        begin
                            if DecValue = 0 then
                                Line.Mark(true);
                        end;
                    Show::"Non Zero":
                        begin
                            if DecValue <> 0 then
                                Line.Mark(true);
                        end;
                end;
            until Line.Next() = 0;
            Line.MarkedOnly(true);
            Line."Schedule Name" := OldLine."Schedule Name";
            Line."Line No." := OldLine."Line No.";
            if not Line.Find then
                if Line.FindFirst then;
        end else begin
            Line.MarkedOnly(false);
            Line.ClearMarks;
        end;
    end;
#endif
    procedure ForceRecalculate(NewRecalculate: Boolean)
    begin
        Recalculate := NewRecalculate;
    end;

    local procedure CalcLCYToACY(ColValue: Decimal): Decimal
    begin
        if GetGLSetup then
            if GLSetup."Additional Reporting Currency" <> '' then
                AddRepCurrency.Get(GLSetup."Additional Reporting Currency");
        if GLSetup."Additional Reporting Currency" <> '' then
            exit(Round(ExchangeAmtAddCurrToLCY(ColValue), AddRepCurrency."Amount Rounding Precision"));
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccSchedLineInsert(var AccSchedLine: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcCellValue(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var Result: Decimal; var SourceAccScheduleLine: Record "Acc. Schedule Line"; var GLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAnalysisView(AccSchedName: Record "Acc. Schedule Name"; ColumnLayoutName: Record "Column Layout Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatCellAsText(var ColumnLayout2: Record "Column Layout"; var ValueAsText: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGLAccounts(var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccRowFilters(var GLAccount: Record "G/L Account"; var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCFAccRowFilter(var CashFlowAccount: Record "Cash Flow Account"; var AccScheduleLine: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccColumnFilters(var GLAccount: Record "G/L Account"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCFAccColumnFilter(var CashFlowAccount: Record "Cash Flow Account"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostTypeColumnFilters(var CostType: Record "Cost Type"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccGLEntryFilters(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccGLBudgetEntryFilters(var GLAcc: Record "G/L Account"; var GLBudgetEntry: Record "G/L Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccAnalysisViewEntryFilters(var GLAcc: Record "G/L Account"; var AnalysisViewEntry: Record "Analysis View Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccAnalysisViewBudgetEntries(var GLAcc: Record "G/L Account"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostEntryFilters(var CostType: Record "Cost Type"; var CostEntry: Record "Cost Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseDimFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostTypeRowFilters(var CostType: Record "Cost Type"; var AccSchedLine2: Record "Acc. Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostBudgetEntryFilters(var CostType: Record "Cost Type"; var CostBudgetEntry: Record "Cost Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCell(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcCellExit(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCellValueInEvaluateExpression(IsAccSchedLineExpression: Boolean; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; Expression: Text; CalcAddCurr: Boolean; IsFilter: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcCellValue(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcGLAcc(var GLAcc: Record "G/L Account"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var ColValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcCFAcc(var CFAccount: Record "Cash Flow Account"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var ColValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcCostType(var CostType: Record "Cost Type"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var ColValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatCellResult(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateExpression(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var MaxLevel: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsExpressionFilter(Expression: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBalance(var GLAccount: Record "G/L Account"; var AccScheduleName: Record "Acc. Schedule Name"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; AmountType: Integer; var ColValue: Decimal; CalcAddCurr: Boolean; var TestBalance: Boolean; var GLEntry: Record "G/L Entry"; var GLBudgetEntry: Record "G/L Budget Entry"; var Balance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownFromOverviewPage(var TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line"; PeriodLength: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOnAccounts(var AccScheduleLine: Record "Acc. Schedule Line"; var TempColumnLayout: Record "Column Layout" temporary; PeriodLength: Option; StartDate: Date; EndDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOnGLAccount(var TempColumnLayout: Record "Column Layout" temporary; var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLAccounts(var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGLAccGLEntryFilters(var GLAcc: Record "G/L Account"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGLAccGLBudgetEntryFilters(var GLAcc: Record "G/L Account"; var GLBudgetEntry: Record "G/L Budget Entry"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; UseBusUnitFilter: Boolean; UseDimFilter: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCellValueOnBeforeExit(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; StartDate: Date; EndDate: Date; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvDimTotalingFilterOnDimNoElseCase(DimNo: Integer; var DimCode: Code[20]; AnalysisView: Record "Analysis View"; CostAccountingSetup: Record "Cost Accounting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownOnGLAccountOnBeforeCopyFiltersEmptyAnalysisViewName(var AccScheduleLine: Record "Acc. Schedule Line"; var TempColumnLayout: Record "Column Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEvaluateExpressionOnBeforeCalcAccSchedLineCellValue(SourceAccSchedLine: Record "Acc. Schedule Line"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var IsHandled: Boolean; var CellValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEvaluateExpressionOnBeforeCalcColumnLayoutCellValue(SourceColumnLayout: Record "Column Layout"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var IsHandled: Boolean; var CellValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLAccountsOnBeforeAccSchedLineInsert(var AccSchedLine: Record "Acc. Schedule Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveAccSchedLinesOnAfterAccSchedLineDelete(var AccSchedLine: Record "Acc. Schedule Line"; Place: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCellValueInAccSchedLinesOnBeforeShowError(SourceAccScheduleLine: Record "Acc. Schedule Line"; var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; CalcAddCurr: Boolean; var CellValue: Decimal; StartDate: Date; EndDate: Date; var Result: Decimal; var IsHandled: Boolean; Expression: Text; var DivisionError: Boolean; var PeriodError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetGLAccAnalysisViewEntryFiltersOnBeforeAccSchedLineCopyFilter(var AccScheduleLine: Record "Acc. Schedule Line"; AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;
}

