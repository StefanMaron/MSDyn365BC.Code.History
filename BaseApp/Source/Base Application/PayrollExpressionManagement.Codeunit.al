codeunit 17414 "Payroll Expression Management"
{

    trigger OnRun()
    begin
    end;

    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        DivisionError: Boolean;
        Text001: Label 'The parenthesis at position %1 is misplaced.';
        Text002: Label 'You cannot have two consecutive operators. The error occurred at position %1.';
        Text003: Label 'There is an operand missing after position %1.';
        Text004: Label 'There are more left parentheses than right parentheses.';
        Text005: Label 'There are more right parentheses than left parentheses.';
        Text017: Label '%1\\The error occurred when the program tried to calculate:\Acc. Sched. Line: Row No. = %1, Line No. = %2, Totaling = %3\Acc. Sched. Column: Column No. = %4, Line No. = %5, Formula  = %6.';
        CallingLineID: Integer;
        Text030: Label 'Please use either %1 or %2.';
        Text031: Label 'Variable %1 has value %2.';
        Text032: Label 'Option cannot be converted to Boolean value.';
        XDOC: Label 'DOC';

    [Scope('OnPrem')]
    procedure EvaluateExpr(var PayrollDocLine: Record "Payroll Document Line"; PayrollDocLineCalc: Record "Payroll Document Line Calc."; var PayrollDocLineVar: Record "Payroll Document Line Var." temporary; NewExpression: Text[250]; ExprLevel: Integer; ParentLineNo: Integer; var DecimalResult: Decimal; var LogicalResult: Option)
    var
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PrevPayrollDocLineExpr: Record "Payroll Document Line Expr.";
        ExprResult: Text[250];
    begin
        // Error codes:
        //
        // 001 - Expression is not constant
        // 002 - Field must be Decimal
        // 003 - Local variable is not calculated
        // 004 - Global variable is not calculated
        // 006 - Journal line does not exist

        // Calculate Expression
        if NewExpression <> '' then begin

            DecimalResult := 0;
            ExprResult := '';

            PayrollDocLineExpr.Reset();
            PayrollDocLineExpr.SetRange("Document No.", PayrollDocLine."Document No.");
            PayrollDocLineExpr.SetRange("Document Line No.", PayrollDocLine."Line No.");
            PayrollDocLineExpr.SetRange("Calculation Line No.", PayrollDocLineCalc."Line No.");
            PayrollDocLineExpr.SetRange("Parent Line No.", ParentLineNo);
            PayrollDocLineExpr.SetRange(Level, ExprLevel);
            if PayrollDocLineExpr.FindSet then
                repeat
                    CalcSimpleExpr(PayrollDocLine, PayrollDocLineCalc, PayrollDocLineExpr, PayrollDocLineVar);
                    if PayrollDocLineExpr.Comparison <> 0 then begin
                        PayrollDocLineExpr."Logical Result" := SetCondition(PayrollDocLineExpr);
                        if LogicalResult = 0 then begin
                            if PayrollDocLineExpr."Logical Prefix" = PayrollDocLineExpr."Logical Prefix"::"NOT" then
                                LogicalResult := Boolean2Option(not Option2Boolean(PayrollDocLineExpr."Logical Result"))
                            else
                                LogicalResult := Boolean2Option(Option2Boolean(PayrollDocLineExpr."Logical Result"));
                        end else
                            case PrevPayrollDocLineExpr."Logical Suffix" of
                                PrevPayrollDocLineExpr."Logical Suffix"::"AND":
                                    if PayrollDocLineExpr."Logical Prefix" = PayrollDocLineExpr."Logical Prefix"::"NOT" then
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) and
                                            (not Option2Boolean(PayrollDocLineExpr."Logical Result")))
                                    else
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) and
                                            Option2Boolean(PayrollDocLineExpr."Logical Result"));
                                PrevPayrollDocLineExpr."Logical Suffix"::"OR":
                                    if PayrollDocLineExpr."Logical Prefix" = PayrollDocLineExpr."Logical Prefix"::"NOT" then
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) or
                                            (not Option2Boolean(PayrollDocLineExpr."Logical Result")))
                                    else
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) or
                                            Option2Boolean(PayrollDocLineExpr."Logical Result"));
                                PrevPayrollDocLineExpr."Logical Suffix"::"XOR":
                                    if PayrollDocLineExpr."Logical Prefix" = PayrollDocLineExpr."Logical Prefix"::"NOT" then
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) xor
                                            (not Option2Boolean(PayrollDocLineExpr."Logical Result")))
                                    else
                                        LogicalResult :=
                                          Boolean2Option(
                                            Option2Boolean(LogicalResult) xor
                                            Option2Boolean(PayrollDocLineExpr."Logical Result"));
                            end;
                    end else begin
                        PayrollDocLineExpr.TestField("Logical Prefix", 0);
                        PayrollDocLineExpr.TestField("Logical Suffix", 0);
                    end;
                    SaveExprResult(PayrollDocLine, PayrollDocLineExpr, PayrollDocLineVar);

                    if (ExprLevel = 0) and
                       (PayrollDocLineCalc."Statement 2" in
                        [PayrollDocLineCalc."Statement 2"::MIN, PayrollDocLineCalc."Statement 2"::MAX])
                    then begin
                        case PayrollDocLineCalc."Statement 2" of
                            PayrollDocLineCalc."Statement 2"::MIN:
                                if DecimalResult = 0 then
                                    DecimalResult := PayrollDocLineExpr."Result Value"
                                else
                                    if DecimalResult > PayrollDocLineExpr."Result Value" then
                                        DecimalResult := PayrollDocLineExpr."Result Value";
                            PayrollDocLineCalc."Statement 2"::MAX:
                                if DecimalResult = 0 then
                                    DecimalResult := PayrollDocLineExpr."Result Value"
                                else
                                    if DecimalResult < PayrollDocLineExpr."Result Value" then
                                        DecimalResult := PayrollDocLineExpr."Result Value";
                        end
                    end else begin
                        if PayrollDocLineExpr."Result Value" < 0 then begin
                            PayrollDocLineExpr."Left Bracket" := PayrollDocLineExpr."Left Bracket"::"(";
                            PayrollDocLineExpr."Right Bracket" := PayrollDocLineExpr."Right Bracket"::")"
                        end;
                        ExprResult := ExprResult +
                          DelChr(Format(PayrollDocLineExpr."Left Bracket")) +
                          DelChr(Format(PayrollDocLineExpr."Result Value")) +
                          DelChr(Format(PayrollDocLineExpr."Right Bracket")) +
                          DelChr(Format(PayrollDocLineExpr.Operator));
                    end;
                    PrevPayrollDocLineExpr := PayrollDocLineExpr;
                until PayrollDocLineExpr.Next = 0;

            if ExprResult <> '' then
                DecimalResult := PayrollDocLineExpr.Rounding(CalcResultExpr(ExprResult));

            if PayrollDocLineCalc."Statement 2" = PayrollDocLineCalc."Statement 2"::ABS then
                DecimalResult := Abs(DecimalResult);
        end else
            DecimalResult := 0;
    end;

    [Scope('OnPrem')]
    procedure CalcResultExpr(Expression: Text[250]): Decimal
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
        Operators: Text[8];
        OperatorNo: Integer;
    begin
        if Evaluate(Result, Expression) then
            exit(Result);

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
                  CalcResultExpr(LeftOperand);
                if (RightOperand = '') and (Operator = '%') then begin
                    RightResult :=
                      CalcResultExpr(LeftOperand);
                end else
                    RightResult :=
                      CalcResultExpr(RightOperand);
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
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      CalcResultExpr(CopyStr(Expression, 2, StrLen(Expression) - 2));
        end;

        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure CalcSimpleExpr(var PayrollDocLine: Record "Payroll Document Line"; PayrollDocLineCalc: Record "Payroll Document Line Calc."; var PayrollDocLineExpr: Record "Payroll Document Line Expr."; var PayrollDocLineVar: Record "Payroll Document Line Var." temporary)
    begin
        PayrollDocLineExpr."Result Value" := 0;
        PayrollDocLineExpr."Error Code" := '';
        case PayrollDocLineExpr.Type of
            PayrollDocLineExpr.Type::Constant:
                CalcConstant(PayrollDocLineExpr);
            PayrollDocLineExpr.Type::Variable:
                CalcVariable(PayrollDocLine, PayrollDocLineExpr, PayrollDocLineVar);
            PayrollDocLineExpr.Type::Field:
                CalcField(PayrollDocLine, PayrollDocLineExpr);
            PayrollDocLineExpr.Type::Expression:
                begin
                    EvaluateExpr(
                      PayrollDocLine, PayrollDocLineCalc, PayrollDocLineVar,
                      PayrollDocLineExpr.Expression, PayrollDocLineExpr.Level + 1, PayrollDocLineExpr."Line No.",
                      PayrollDocLineExpr."Result Value", PayrollDocLineExpr."Logical Result");
                    SaveExprResult(PayrollDocLine, PayrollDocLineExpr, PayrollDocLineVar);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveExprResult(var PayrollDocLine: Record "Payroll Document Line"; var PayrollDocLineExpr: Record "Payroll Document Line Expr."; var PayrollDocLineVar: Record "Payroll Document Line Var.")
    begin
        // Save result of expression calculation to variable
        if PayrollDocLineExpr."Assign to Variable" <> '' then begin
            if PayrollDocLineVar.Get(
                 PayrollDocLine."Document No.",
                 PayrollDocLine."Line No.",
                 PayrollDocLineExpr."Assign to Variable")
            then begin
                PayrollDocLineVar.Value := PayrollDocLineExpr.Rounding(PayrollDocLineExpr."Result Value");
                PayrollDocLineVar.Calculated := true;
                PayrollDocLineVar.Error := DivisionError;
                PayrollDocLineVar.Modify();
            end else begin
                PayrollDocLineVar.Init();
                PayrollDocLineVar."Document No." := PayrollDocLine."Document No.";
                PayrollDocLineVar."Document Line No." := PayrollDocLine."Line No.";
                PayrollDocLineVar."Element Code" := PayrollDocLine."Element Code";
                PayrollDocLineVar."Line No." := PayrollDocLine."Line No.";
                PayrollDocLineVar.Variable := PayrollDocLineExpr."Assign to Variable";
                PayrollDocLineVar.Value := PayrollDocLineExpr.Rounding(PayrollDocLineExpr."Result Value");
                PayrollDocLineVar.Calculated := true;
                PayrollDocLineVar.Error := DivisionError;
                PayrollDocLineVar.Insert();
            end;
            CheckStops(PayrollDocLineVar);
        end;
        // Save result of expression calculation to field
        if PayrollDocLineExpr."Assign to Field No." <> 0 then begin
            RecRef.Open(DATABASE::"Payroll Document Line");
            RecRef.GetTable(PayrollDocLine);
            FldRef := RecRef.Field(PayrollDocLineExpr."Assign to Field No.");
            FldRef.Value(PayrollDocLineExpr.Rounding(PayrollDocLineExpr."Result Value"));
            RecRef.SetTable(PayrollDocLine);
            RecRef.Modify();
            RecRef.Close;
        end;
        PayrollDocLineExpr.Modify();
    end;

    [Scope('OnPrem')]
    procedure CalcConstant(var PayrollDocLineExpr: Record "Payroll Document Line Expr.")
    begin
        if not Evaluate(PayrollDocLineExpr."Result Value", PayrollDocLineExpr.Expression) then
            PayrollDocLineExpr."Error Code" := '001';
        PayrollDocLineExpr.Modify();
    end;

    [Scope('OnPrem')]
    procedure CalcVariable(PayrollDocLine: Record "Payroll Document Line"; var PayrollDocLineExpr: Record "Payroll Document Line Expr."; var PayrollDocLineVar: Record "Payroll Document Line Var.")
    begin
        if PayrollDocLineVar.Get(
             PayrollDocLine."Document No.",
             PayrollDocLine."Line No.",
             PayrollDocLineExpr.Expression)
        then
            if PayrollDocLineVar.Calculated then
                PayrollDocLineExpr."Result Value" := PayrollDocLineVar.Value
            else
                PayrollDocLineExpr."Error Code" := '003'
        else
            PayrollDocLineExpr."Error Code" := '003';
        PayrollDocLineExpr.Modify();
    end;

    [Scope('OnPrem')]
    procedure CalcField(var PayrollDocLine: Record "Payroll Document Line"; var PayrollDocLineExpr: Record "Payroll Document Line Expr.")
    var
        Employee: Record Employee;
        Person: Record Person;
        Position: Record Position;
    begin
        PayrollDocLineExpr.TestField("Table No.");
        PayrollDocLineExpr.TestField("Field No.");
        Employee.Get(PayrollDocLine."Employee No.");
        case PayrollDocLineExpr."Table No." of
            DATABASE::Employee:
                RecRef.GetTable(Employee);
            DATABASE::Person:
                begin
                    Person.Get(Employee."Person No.");
                    RecRef.GetTable(Person);
                end;
            DATABASE::Position:
                begin
                    Position.Get(Employee."Position No.");
                    RecRef.GetTable(Position);
                end;
            DATABASE::"Payroll Document Line":
                RecRef.GetTable(PayrollDocLine);
        end;
        FldRef := RecRef.Field(PayrollDocLineExpr."Field No.");
        if FldRef.Type = FieldType::Decimal then begin
            if FldRef.Class = FieldClass::FlowField then
                FldRef.CalcField;
            PayrollDocLineExpr."Result Value" := FldRef.Value;
            PayrollDocLineExpr."Result Value" :=
              PayrollDocLineExpr.Rounding(PayrollDocLineExpr."Result Value");
        end else
            PayrollDocLineExpr."Error Code" := '002';
        RecRef.Close;
        PayrollDocLineExpr.Modify();
    end;

    [Scope('OnPrem')]
    procedure CalcExpression(var PayrollDocLine: Record "Payroll Document Line"; var PayrollDocLineCalc: Record "Payroll Document Line Calc."; var PayrollDocLineVar: Record "Payroll Document Line Var." temporary): Decimal
    var
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        ExprResult: Text[250];
    begin
        CalcSimpleExpr(PayrollDocLine, PayrollDocLineCalc, PayrollDocLineExpr, PayrollDocLineVar);
        ExprResult := ExprResult +
          DelChr(Format(PayrollDocLineExpr."Left Bracket")) +
          DelChr(Format(PayrollDocLineExpr."Result Value")) +
          DelChr(Format(PayrollDocLineExpr."Right Bracket")) +
          DelChr(Format(PayrollDocLineExpr.Operator));

        // calculate resulted expression
        PayrollDocLineCalc."Result Value" :=
          PayrollDocLineCalc.Rounding(CalcResultExpr(ExprResult));

        // Save result of expression calculation
        if PayrollDocLineCalc.Variable <> '' then begin
            if PayrollDocLineVar.Get(
                 PayrollDocLine."Document No.",
                 PayrollDocLine."Line No.",
                 PayrollDocLineCalc.Variable)
            then begin
                PayrollDocLineVar.Value := PayrollDocLineExpr.Rounding(PayrollDocLineCalc."Result Value");
                PayrollDocLineVar.Calculated := true;
                PayrollDocLineVar.Error := DivisionError;
                PayrollDocLineVar.Modify();
            end else begin
                PayrollDocLineVar.Init();
                PayrollDocLineVar."Document No." := PayrollDocLine."Document No.";
                PayrollDocLineVar."Document Line No." := PayrollDocLine."Line No.";
                PayrollDocLineVar."Element Code" := PayrollDocLine."Element Code";
                PayrollDocLineVar."Line No." := PayrollDocLine."Line No.";
                PayrollDocLineVar.Variable := PayrollDocLineCalc.Variable;
                PayrollDocLineVar.Value := PayrollDocLineExpr.Rounding(PayrollDocLineCalc."Result Value");
                PayrollDocLineVar.Calculated := true;
                PayrollDocLineVar.Error := DivisionError;
                PayrollDocLineVar.Insert();
            end;
            CheckStops(PayrollDocLineVar);
        end;

        exit(PayrollDocLineCalc."Result Value");
    end;

    [Scope('OnPrem')]
    procedure SetCondition(PayrollDocLineExpr: Record "Payroll Document Line Expr."): Integer
    var
        LogicalResult: Option " ","FALSE","TRUE";
    begin
        with PayrollDocLineExpr do begin
            TestField(Comparison);
            case Comparison of
                Comparison::"=0":
                    begin
                        if "Result Value" = 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
                Comparison::"<>0":
                    begin
                        if "Result Value" <> 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
                Comparison::">0":
                    begin
                        if "Result Value" > 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
                Comparison::"<0":
                    begin
                        if "Result Value" < 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
                Comparison::">=0":
                    begin
                        if "Result Value" >= 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
                Comparison::"<=0":
                    begin
                        if "Result Value" <= 0 then
                            exit(LogicalResult::"TRUE");

                        exit(LogicalResult::"FALSE");
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatElementStatement(ExprSetup: Record "Payroll Element Expression"): Text[250]
    var
        ExprText: Text[250];
    begin
        ExprText := '';
        if (ExprSetup."Assign to Variable" <> '') and (ExprSetup."Assign to Field No." <> 0) then
            Error(Text030, ExprSetup.FieldCaption("Assign to Variable"), ExprSetup.FieldCaption("Assign to Field No."));
        if ExprSetup."Assign to Variable" <> '' then
            ExprText := ExprText + Format(ExprSetup."Assign to Variable") + ' = ';
        if ExprSetup."Assign to Field No." <> 0 then begin
            ExprSetup.CalcFields("Assign to Field Name");
            if StrPos(ExprSetup."Assign to Field Name", ' ') > 0 then
                ExprSetup."Assign to Field Name" := StrSubstNo('"%1"', ExprSetup."Assign to Field Name");
            ExprText := ExprText +
              StrSubstNo(XDOC + '.%1 = ', ExprSetup."Assign to Field Name");
        end;
        if ExprSetup."Left Bracket" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Left Bracket") + ' ';
        if ExprSetup."Logical Prefix" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Logical Prefix") + ' ';
        if ExprSetup.Expression <> '' then
            ExprText := ExprText + Format(ExprSetup.Expression) + ' ';
        if ExprSetup.Comparison <> 0 then
            ExprText := ExprText + Format(ExprSetup.Comparison) + ' ';
        if ExprSetup."Right Bracket" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Right Bracket") + ' ';
        if ExprSetup."Logical Suffix" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Logical Suffix") + ' ';
        if ExprSetup.Operator <> 0 then
            ExprText := ExprText + Format(ExprSetup.Operator) + ' ';

        exit(ExprText);
    end;

    [Scope('OnPrem')]
    procedure FormatDocLineStatement(ExprSetup: Record "Payroll Document Line Expr."): Text[250]
    var
        ExprText: Text[250];
    begin
        ExprText := '';
        if (ExprSetup."Assign to Variable" <> '') and (ExprSetup."Assign to Field No." <> 0) then
            Error(Text030, ExprSetup.FieldCaption("Assign to Variable"), ExprSetup.FieldCaption("Assign to Field No."));
        if ExprSetup."Assign to Variable" <> '' then
            ExprText := ExprText + Format(ExprSetup."Assign to Variable") + ' = ';
        if ExprSetup."Assign to Field No." <> 0 then begin
            ExprSetup.CalcFields("Assign to Field Name");
            if StrPos(ExprSetup."Assign to Field Name", ' ') > 0 then
                ExprSetup."Assign to Field Name" := StrSubstNo('"%1"', ExprSetup."Assign to Field Name");
            ExprText := ExprText +
              StrSubstNo(XDOC + '.%1 = ', ExprSetup."Assign to Field Name");
        end;
        if ExprSetup."Left Bracket" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Left Bracket") + ' ';
        if ExprSetup."Logical Prefix" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Logical Prefix") + ' ';
        if ExprSetup.Expression <> '' then
            ExprText := ExprText + Format(ExprSetup.Expression) + ' ';
        if ExprSetup.Comparison <> 0 then
            ExprText := ExprText + Format(ExprSetup.Comparison) + ' ';
        if ExprSetup."Right Bracket" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Right Bracket") + ' ';
        if ExprSetup."Logical Suffix" <> 0 then
            ExprText := ExprText + Format(ExprSetup."Logical Suffix") + ' ';
        if ExprSetup.Operator <> 0 then
            ExprText := ExprText + Format(ExprSetup.Operator) + ' ';

        exit(ExprText);
    end;

    [Scope('OnPrem')]
    procedure ShowError(MessageLine: Text[100]; var PayrollDocLineCalc: Record "Payroll Document Line Calc.")
    begin
        PayrollDocLineCalc.SetRange("Element Code", PayrollDocLineCalc."Element Code");
        PayrollDocLineCalc.SetRange("Line No.", CallingLineID);
        if PayrollDocLineCalc.Find('-') then;
        Error(
          StrSubstNo(Text017, MessageLine),
          PayrollDocLineCalc.Variable, PayrollDocLineCalc."Line No.", PayrollDocLineCalc.Expression);
    end;

    [Scope('OnPrem')]
    procedure CheckParenthesis(Expression: Text[250])
    var
        i: Integer;
        ParenthesesLevel: Integer;
        HasOperator: Boolean;
    begin
        ParenthesesLevel := 0;
        for i := 1 to StrLen(Expression) do begin
            if Expression[i] = '(' then
                ParenthesesLevel := ParenthesesLevel + 1
            else
                if Expression[i] = ')' then
                    ParenthesesLevel := ParenthesesLevel - 1;
            if ParenthesesLevel < 0 then
                Error(Text001, i);
            if Expression[i] in ['+', '-', '*', '/', '^'] then begin
                if HasOperator then
                    Error(Text002, i);

                HasOperator := true;
                if i = StrLen(Expression) then
                    Error(Text003, i);

                if Expression[i + 1] = ')' then
                    Error(Text003, i);
            end else
                HasOperator := false;
        end;
        if ParenthesesLevel > 0 then
            Error(Text004);

        if ParenthesesLevel < 0 then
            Error(Text005);
    end;

    [Scope('OnPrem')]
    procedure CheckStops(PayrollDocLineVar: Record "Payroll Document Line Var.")
    var
        PayrollExprStop: Record "Payroll Calculation Stop";
    begin
        with PayrollExprStop do begin
            SetRange("Element Code", PayrollDocLineVar."Element Code");
            SetRange(Variable, PayrollDocLineVar.Variable);
            if FindSet then
                repeat
                    if Value = PayrollDocLineVar.Value then
                        Error(Text031, Variable, Value);
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ClearResults(PayrollDocLine: Record "Payroll Document Line")
    var
        PayrollDocLineVar: Record "Payroll Document Line Var.";
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PayrollDocLineCalc: Record "Payroll Document Line Calc.";
    begin
        PayrollDocLineVar.Reset();
        PayrollDocLineVar.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineVar.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineVar.DeleteAll();

        PayrollDocLineExpr.Reset();
        PayrollDocLineExpr.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineExpr.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineExpr.ModifyAll("Result Value", 0);
        PayrollDocLineExpr.ModifyAll("Logical Result", 0);

        PayrollDocLineCalc.Reset();
        PayrollDocLineCalc.SetRange("Document No.", PayrollDocLine."Document No.");
        PayrollDocLineCalc.SetRange("Document Line No.", PayrollDocLine."Line No.");
        PayrollDocLineCalc.ModifyAll("Result Value", 0);
        PayrollDocLineCalc.ModifyAll("Logical Result", 0);
        PayrollDocLineCalc.ModifyAll("No. of Runs", 0);
    end;

    [Scope('OnPrem')]
    procedure Boolean2Option(Condition: Boolean): Integer
    begin
        if Condition then
            exit(2);

        exit(1);
    end;

    [Scope('OnPrem')]
    procedure Option2Boolean(Value: Integer): Boolean
    begin
        if Value = 2 then
            exit(true);

        if Value = 1 then
            exit(false);

        Error(Text032);
    end;
}

