page 31093 "Acc. Sched. Formula Drill-Down"
{
    Caption = 'Acc. Sched. Formula Drill-Down';
    PageType = Worksheet;
    SourceTable = "Acc. Sched. Expression Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(Formula; Formula)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Formula';
                Editable = false;
                ToolTip = 'Specifies the formula of acc. sched. ';
            }
            repeater(Control1220004)
            {
                Editable = false;
                ShowCaption = false;
                field("Acc. Sched. Row No."; "Acc. Sched. Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account schedule row.';
                }
                field("Totaling Type"; "Totaling Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totaling type for the account schedule line. The type determines which accounts within the totaling interval you specify in the Totaling field will be totaled.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies expression of acc. sched. ';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies amount';

                    trigger OnDrillDown()
                    var
                        GLAcc: Record "G/L Account";
                        GLAccAnalysisView: Record "G/L Account (Analysis View)";
                        AccSchedLine: Record "Acc. Schedule Line";
                        ChartOfAccsAnalysisView: Page "Chart of Accs. (Analysis View)";
                        AccSchedFormulaDrillDown: Page "Acc. Sched. Formula Drill-Down";
                    begin
                        AccSchedName.Get(SourceAccScheduleLine."Schedule Name");
                        AccSchedLine.Copy(SourceAccScheduleLine);
                        AccSchedLine.Totaling := Expression;
                        AccSchedLine."Totaling Type" := "Totaling Type";
                        StartDate := AccSchedLine.GetRangeMin("Date Filter");
                        EndDate := AccSchedLine.GetRangeMax("Date Filter");

                        AccSchedMgt.SetDateParameters(StartDate, EndDate);

                        if SourceColumnLayout."Column Type" = SourceColumnLayout."Column Type"::Formula then
                            Message(ColumnFormulaMsg, SourceColumnLayout.Formula)
                        else
                            case "Totaling Type" of
                                "Totaling Type"::Constant:
                                    Message(LineConstantMsg, Expression);
                                "Totaling Type"::Formula:
                                    begin
                                        AccSchedFormulaDrillDown.InitParameters(AccSchedLine, SourceColumnLayout, TempAccSchedCellValue);
                                        AccSchedFormulaDrillDown.Run;
                                    end;
                                "Totaling Type"::Custom:
                                    AccSchedExtensionMgt.DrillDownAmount(
                                      AccSchedLine,
                                      SourceColumnLayout,
                                      Expression,
                                      StartDate,
                                      EndDate);
                                "Totaling Type"::"Set Base For Percent":
                                    Message(RowFormulaMsg, Expression);
                                else
                                    if Expression <> '' then begin
                                        AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                                        AccSchedLine.CopyFilter("G/L Budget Filter", GLAcc."Budget Filter");
                                        AccSchedMgt.SetGLAccRowFilters(GLAcc, AccSchedLine);
                                        AccSchedMgt.SetGLAccColumnFilters(GLAcc, AccSchedLine, SourceColumnLayout);
                                        if AccSchedName."Analysis View Name" = '' then begin
                                            AccSchedLine.CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                                            AccSchedLine.CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                                            AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                                            GLAcc.FilterGroup(2);
                                            GLAcc.SetFilter("Global Dimension 1 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(1, "Dimension 1 Totaling"));
                                            GLAcc.SetFilter("Global Dimension 2 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(2, "Dimension 2 Totaling"));
                                            GLAcc.FilterGroup(6);
                                            GLAcc.SetFilter(
                                              "Global Dimension 1 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Totaling"));
                                            GLAcc.SetFilter(
                                              "Global Dimension 2 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Totaling"));
                                            GLAcc.SetFilter("Business Unit Filter", SourceColumnLayout."Business Unit Totaling");
                                            GLAcc.FilterGroup(0);
                                            PAGE.Run(PAGE::"Chart of Accounts (G/L)", GLAcc)
                                        end else begin
                                            GLAcc.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
                                            GLAcc.CopyFilter("Budget Filter", GLAccAnalysisView."Budget Filter");
                                            GLAcc.CopyFilter("Business Unit Filter", GLAccAnalysisView."Business Unit Filter");
                                            GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
                                            AccSchedLine.CopyFilter("Dimension 1 Filter", GLAccAnalysisView."Dimension 1 Filter");
                                            AccSchedLine.CopyFilter("Dimension 2 Filter", GLAccAnalysisView."Dimension 2 Filter");
                                            AccSchedLine.CopyFilter("Dimension 3 Filter", GLAccAnalysisView."Dimension 3 Filter");
                                            AccSchedLine.CopyFilter("Dimension 4 Filter", GLAccAnalysisView."Dimension 4 Filter");
                                            GLAccAnalysisView.FilterGroup(2);
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 1 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(1, "Dimension 1 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 2 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(2, "Dimension 2 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 3 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(3, "Dimension 3 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 4 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(4, "Dimension 4 Totaling"));
                                            GLAccAnalysisView.FilterGroup(6);
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 1 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 2 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 3 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(3, SourceColumnLayout."Dimension 3 Totaling"));
                                            GLAccAnalysisView.SetFilter(
                                              "Dimension 4 Filter",
                                              AccSchedMgt.GetDimTotalingFilter(4, SourceColumnLayout."Dimension 4 Totaling"));
                                            GLAccAnalysisView.SetFilter("Business Unit Filter", SourceColumnLayout."Business Unit Totaling");
                                            GLAccAnalysisView.FilterGroup(0);
                                            Clear(ChartOfAccsAnalysisView);
                                            ChartOfAccsAnalysisView.InsertTempGLAccAnalysisViews(GLAcc);
                                            ChartOfAccsAnalysisView.SetTableView(GLAccAnalysisView);
                                            ChartOfAccsAnalysisView.Run;
                                        end;
                                    end;
                            end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        AccSchedName: Record "Acc. Schedule Name";
        SourceAccScheduleLine: Record "Acc. Schedule Line";
        SourceColumnLayout: Record "Column Layout";
        TempAccSchedCellValue: Record "Acc. Sched. Cell Value" temporary;
        AccSchedMgt: Codeunit AccSchedManagement;
        AccSchedExtensionMgt: Codeunit AccSchedExtensionManagement;
        Formula: Text[250];
        StartDate: Date;
        EndDate: Date;
        EntryNo: Integer;
        ColumnFormulaMsg: Label 'Column formula: %1.';
        RowFormulaMsg: Label 'Row formula: %1.';
        LineConstantMsg: Label 'Row constant: %1.';

    [Scope('OnPrem')]
    procedure InitParameters(var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedCellValue: Record "Acc. Sched. Cell Value")
    begin
        SourceAccScheduleLine.Copy(AccSchedLine);
        AccSchedLine.TestField("Totaling Type", AccSchedLine."Totaling Type"::Formula);
        SourceColumnLayout := ColumnLayout;
        Formula := AccSchedLine.Totaling;

        if AccSchedCellValue.FindFirst then
            repeat
                TempAccSchedCellValue.TransferFields(AccSchedCellValue);
                if TempAccSchedCellValue.Insert then;
            until AccSchedCellValue.Next = 0;

        EvaluateExpression(true, AccSchedLine.Totaling, AccSchedLine, SourceColumnLayout);
    end;

    local procedure EvaluateExpression(IsAccSchedLineExpression: Boolean; Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"): Decimal
    var
        Result: Decimal;
        Parantheses: Integer;
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
        AccSchedLineID: Integer;
    begin
        GLSetup.Get;

        Expression := DelChr(Expression, '<>', '');
        if StrLen(Expression) > 0 then begin
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
                    IsAccSchedLineExpression, LeftOperand, AccSchedLine, ColumnLayout);
                RightResult :=
                  EvaluateExpression(
                    IsAccSchedLineExpression, RightOperand, AccSchedLine, ColumnLayout);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '%':
                        if RightResult = 0 then
                            Result := 0
                        else
                            Result := 100 * LeftResult / RightResult;
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then
                            Result := 0
                        else
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
                        IsAccSchedLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AccSchedLine, ColumnLayout)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 20) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else
                        if IsAccSchedLineExpression then begin
                            AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                            AccSchedLine.SetFilter("Row No.", Expression);
                            AccSchedLineID := AccSchedLine."Line No.";
                            if AccSchedLine.FindSet then
                                repeat
                                    if AccSchedLine."Line No." <> AccSchedLineID then
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                until AccSchedLine.Next = 0
                            else begin
                                AccSchedLine.SetRange("Schedule Name", GLSetup."Shared Account Schedule");
                                if AccSchedLine.FindFirst then
                                    repeat
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                    until AccSchedLine.Next = 0;
                            end
                        end else begin
                            ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
                            ColumnLayout.SetFilter("Column No.", Expression);
                            AccSchedLineID := ColumnLayout."Line No.";
                            if ColumnLayout.FindSet then
                                repeat
                                    if ColumnLayout."Line No." <> AccSchedLineID then
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                until ColumnLayout.Next = 0
                        end;
                end;
        end;
        exit(Result);
    end;

    local procedure CalcCellValue(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"): Decimal
    var
        Result: Decimal;
    begin
        if TempAccSchedCellValue.Get(AccSchedLine."Schedule Name", AccSchedLine."Line No.", ColumnLayout."Line No.") then
            Result := TempAccSchedCellValue.Value;

        AddFormulasExpression(AccSchedLine, Result);
        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure AddFormulasExpression(AccSchedLine: Record "Acc. Schedule Line"; Result: Decimal)
    begin
        EntryNo += 1;

        Init;
        "Entry No." := EntryNo;
        Expression := AccSchedLine.Totaling;
        Amount := Result;
        "Acc. Sched. Row No." := AccSchedLine."Row No.";
        "Totaling Type" := AccSchedLine."Totaling Type";
        "Dimension 1 Totaling" := AccSchedLine."Dimension 1 Totaling";
        "Dimension 2 Totaling" := AccSchedLine."Dimension 2 Totaling";
        "Dimension 3 Totaling" := AccSchedLine."Dimension 3 Totaling";
        "Dimension 4 Totaling" := AccSchedLine."Dimension 4 Totaling";
        Insert;
    end;
}

