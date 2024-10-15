table 17407 "Payroll Calculation Line"
{
    Caption = 'Payroll Calculation Line';
    LookupPageID = "Payroll Calculation Lines";

    fields
    {
        field(1; "Function Code"; Text[30])
        {
            Caption = 'Function Code';
            TableRelation = "Payroll Calculation Function";
        }
        field(2; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(5; "Range Type"; Option)
        {
            Caption = 'Range Type';
            OptionCaption = ' ,Deduction,Tax Deduction,Exclusion,Deduct. Benefit,Tax Abatement,Limit + Tax %,Frequency,Coordination,Increase Salary,Quantity';
            OptionMembers = " ",Deduction,"Tax Deduction",Exclusion,"Deduct. Benefit","Tax Abatement","Limit + Tax %",Frequency,Coordination,"Increase Salary",Quantity;

            trigger OnValidate()
            begin
                if "Range Type" <> xRec."Range Type" then
                    "Range Code" := '';
            end;
        }
        field(6; "Range Code"; Text[20])
        {
            Caption = 'Range Code';

            trigger OnLookup()
            begin
                PayrollRangeHeader.Reset();
                PayrollRangeHeader.SetRange("Element Code", "Element Code");
                PayrollRangeHeader.SetFilter("Period Code", '..%1', "Period Code");
                if "Range Type" <> 0 then
                    PayrollRangeHeader.SetRange("Range Type", "Range Type");
                if PAGE.RunModal(0, PayrollRangeHeader) = ACTION::LookupOK then begin
                    "Range Type" := PayrollRangeHeader."Range Type";
                    "Range Code" := PayrollRangeHeader.Code;
                end;
            end;

            trigger OnValidate()
            begin
                PayrollRangeHeader.Reset();
                PayrollRangeHeader.SetRange("Element Code", "Element Code");
                PayrollRangeHeader.SetFilter("Period Code", '..%1', "Period Code");
                if "Range Type" <> 0 then
                    PayrollRangeHeader.SetRange("Range Type", "Range Type");
                PayrollRangeHeader.SetFilter(Code, "Range Code");
                PayrollRangeHeader.FindLast;
            end;
        }
        field(7; "Base Amount Code"; Code[10])
        {
            Caption = 'Base Amount Code';
            TableRelation = "Payroll Base Amount".Code WHERE("Element Code" = FIELD("Element Code"));

            trigger OnValidate()
            begin
                if "Base Amount Code" <> '' then
                    TestField("Function Code");
            end;
        }
        field(8; "Time Activity Group"; Code[20])
        {
            Caption = 'Time Activity Group';
            TableRelation = "Time Activity Group";

            trigger OnValidate()
            begin
                if "Time Activity Group" <> '' then
                    TestField("Function Code");
            end;
        }
        field(9; Variable; Text[30])
        {
            Caption = 'Variable';

            trigger OnLookup()
            begin
                PayrollElementVariable.Reset();
                PayrollElementVariable.SetRange("Element Code", "Element Code");
                PayrollElementVariable.SetRange("Period Code", "Period Code");
                if PAGE.RunModal(0, PayrollElementVariable) = ACTION::LookupOK then
                    Validate(Variable, PayrollElementVariable.Variable);
            end;

            trigger OnValidate()
            begin
                if (Variable <> '') and (not PayrollElementVariable.Get("Element Code", "Period Code", Variable)) then begin
                    PayrollElementVariable.Init();
                    PayrollElementVariable."Element Code" := "Element Code";
                    PayrollElementVariable."Period Code" := "Period Code";
                    PayrollElementVariable.Variable := Variable;
                    PayrollElementVariable.Insert();
                end;
            end;
        }
        field(10; Structured; Boolean)
        {
            CalcFormula = Exist ("Payroll Element Expression" WHERE("Element Code" = FIELD("Element Code"),
                                                                    "Period Code" = FIELD("Period Code"),
                                                                    "Calculation Line No." = FIELD("Line No."),
                                                                    Level = CONST(0),
                                                                    "Parent Line No." = CONST(0)));
            Caption = 'Structured';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Expression; Text[250])
        {
            Caption = 'Expression';

            trigger OnValidate()
            var
                LinesFound: Boolean;
            begin
                if Expression <> '' then
                    TestField("Function Code", '');

                ExprMgt.CheckParenthesis(Expression);

                CalcFields(Structured);
                if Structured then
                    Error(Text002);

                if Expression <> '' then begin
                    LinesFound := false;
                    PayrollCalculationLine.Reset();
                    if PayrollCalculationLine.FindSet then
                        repeat
                            if PayrollCalculationLine.Expression = Expression then begin
                                PayrollCalculationLine.CalcFields(Structured);
                                if PayrollCalculationLine.Structured then begin
                                    LinesFound := true;
                                    PayrollElementExpr.Reset();
                                    PayrollElementExpr.SetRange("Element Code", PayrollCalculationLine."Element Code");
                                    PayrollElementExpr.SetRange("Calculation Line No.", PayrollCalculationLine."Line No.");
                                    if PayrollElementExpr.FindSet then
                                        repeat
                                            PayrollElementExpr2 := PayrollElementExpr;
                                            PayrollElementExpr2."Element Code" := "Element Code";
                                            PayrollElementExpr2."Calculation Line No." := "Line No.";
                                            PayrollElementExpr2.Insert();
                                        until PayrollElementExpr.Next = 0;
                                end;
                            end;
                        until LinesFound or (PayrollCalculationLine.Next = 0);
                end;
            end;
        }
        field(13; "Result Field No."; Integer)
        {
            Caption = 'Result Field No.';
            TableRelation = Field."No." WHERE(TableNo = CONST(17415),
                                               Class = CONST(Normal),
                                               Type = FILTER(Decimal));

            trigger OnLookup()
            var
                PayrollDocLine: Record "Payroll Document Line";
                "Field": Record "Field";
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.SetRange(TableNo, DATABASE::"Payroll Document Line");
                Field.SetRange(Type, Field.Type::Decimal);
                Field.SetRange(Class, Field.Class::Normal);
                Field.SetFilter("No.", '%1|%2|%3|%4',
                  PayrollDocLine.FieldNo("Payroll Amount"),
                  PayrollDocLine.FieldNo("Taxable Amount"),
                  PayrollDocLine.FieldNo("Corr. Amount"),
                  PayrollDocLine.FieldNo("AE Daily Earnings"));
                if FieldSelection.Open(Field) then
                    Validate("Result Field No.", Field."No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("Result Field Name");
            end;
        }
        field(14; "Result Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = CONST(17415),
                                                        "No." = FIELD("Result Field No.")));
            Caption = 'Result Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
        }
        field(16; "AE Setup Code"; Code[10])
        {
            Caption = 'AE Setup Code';
            TableRelation = "AE Calculation Setup"."Setup Code" WHERE(Type = CONST(Calculation));
        }
        field(19; "Result Flag"; Option)
        {
            Caption = 'Result Flag';
            OptionCaption = ' ,Exception,Stop';
            OptionMembers = " ",Exception,Stop;
        }
        field(20; "Statement 1"; Option)
        {
            Caption = 'Statement 1';
            OptionCaption = ' ,IF,THEN,ELSE,ENDIF';
            OptionMembers = " ","IF","THEN","ELSE",ENDIF;

            trigger OnValidate()
            begin
                if "Statement 1" <> 0 then
                    TestField("Function Code", '');
            end;
        }
        field(21; "Statement 2"; Option)
        {
            Caption = 'Statement 2';
            OptionCaption = ' ,MIN,MAX,ABS,GOTO,STOP';
            OptionMembers = " ","MIN","MAX",ABS,GOTO,STOP;

            trigger OnValidate()
            begin
                if "Statement 2" <> 0 then
                    TestField("Function Code", '');
            end;
        }
        field(22; "IF Level"; Integer)
        {
            Caption = 'IF Level';
        }
        field(25; Label; Text[10])
        {
            Caption = 'Label';
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(58; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding Precision';
        }
        field(59; "Rounding Type"; Option)
        {
            Caption = 'Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
    }

    keys
    {
        key(Key1; "Element Code", "Period Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollElementExpr.Reset();
        PayrollElementExpr.SetRange("Element Code", "Element Code");
        PayrollElementExpr.SetRange("Period Code", "Period Code");
        PayrollElementExpr.SetRange("Calculation Line No.", "Line No.");
        PayrollElementExpr.DeleteAll(true);

        PayrollElementVariable.Reset();
        PayrollElementVariable.SetRange("Element Code", "Element Code");
        PayrollElementVariable.SetRange("Period Code", "Period Code");
        PayrollElementVariable.SetRange(Variable, Variable);
        PayrollElementVariable.DeleteAll(true);
    end;

    var
        PayrollCalculationLine: Record "Payroll Calculation Line";
        PayrollElementExpr: Record "Payroll Element Expression";
        PayrollElementExpr2: Record "Payroll Element Expression";
        PayrollElementVariable: Record "Payroll Element Variable";
        PayrollRangeHeader: Record "Payroll Range Header";
        ExprMgt: Codeunit "Payroll Expression Management";
        Text001: Label 'DOC.%1 = ';
        Text002: Label 'Use AssistEdit to edit structured expression.';

    [Scope('OnPrem')]
    procedure ExprAssistEdit()
    var
        PayrollCalculationLines: Page "Payroll Calculation Lines";
        PayrollExprEditor: Page "Payroll Expression";
    begin
        TestField("Line No.");

        if "Statement 2" = "Statement 2"::GOTO then begin // label
            PayrollCalculationLine.Reset();
            PayrollCalculationLine.FilterGroup(2);
            PayrollCalculationLine.SetRange("Element Code", "Element Code");
            PayrollCalculationLine.SetRange("Period Code", "Period Code");
            PayrollCalculationLine.SetFilter(Label, '<>%1', '');
            PayrollCalculationLine.FilterGroup(0);

            PayrollCalculationLines.SetTableView(PayrollCalculationLine);
            PayrollCalculationLines.LookupMode(true);
            PayrollCalculationLines.Editable(false);
            if PayrollCalculationLines.RunModal = ACTION::LookupOK then begin
                PayrollCalculationLines.GetRecord(PayrollCalculationLine);
                Expression := PayrollCalculationLine.Label;
            end;
        end else begin
            PayrollElementExpr.Reset();
            PayrollElementExpr.FilterGroup(2);
            PayrollElementExpr.SetRange("Element Code", "Element Code");
            PayrollElementExpr.SetRange("Period Code", "Period Code");
            PayrollElementExpr.SetRange("Calculation Line No.", "Line No.");
            PayrollElementExpr.SetRange(Level, 0);
            PayrollElementExpr.SetRange("Parent Line No.", 0);
            PayrollElementExpr.FilterGroup(0);

            PayrollExprEditor.SetTableView(PayrollElementExpr);
            PayrollExprEditor.SetFromCalcLine(Rec);
            PayrollExprEditor.RunModal;
            Clear(PayrollExprEditor);

            Expression := '';
            if PayrollElementExpr.FindSet then
                repeat
                    Expression := Expression +
                      ExprMgt.FormatElementStatement(PayrollElementExpr);
                until PayrollElementExpr.Next = 0;

            Expression := DelChr(Expression, '>', ' ');
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowCodeLine() LineText: Text[1024]
    begin
        LineText := '';
        if Label <> '' then
            LineText := LineText + Format(Label) + ': ';
        if Variable <> '' then
            LineText := LineText + Format(Variable) + ' = ';
        if "Result Field No." <> 0 then begin
            CalcFields("Result Field Name");
            LineText := LineText +
              StrSubstNo(Text001, "Result Field Name");
        end;
        if "Statement 1" <> 0 then
            LineText := LineText + Format("Statement 1") + ' ';
        if "Statement 2" <> 0 then
            LineText := LineText + Format("Statement 2") + ' ';
        if Expression <> '' then
            LineText := LineText + Format(Expression) + ' ';
        if "Function Code" <> '' then
            LineText := LineText + Format("Function Code");

        if ("Base Amount Code" <> '') or ("Time Activity Group" <> '') or ("Range Code" <> '') then
            LineText := LineText + '( ';
        if "Base Amount Code" <> '' then
            LineText := LineText + Format("Base Amount Code");
        if "Time Activity Group" <> '' then begin
            if "Base Amount Code" <> '' then
                LineText := LineText + ' ; ' + Format("Time Activity Group")
            else
                LineText := LineText + Format("Time Activity Group");
        end;
        if "Range Code" <> '' then begin
            if "Time Activity Group" <> '' then
                LineText := LineText + ' ; ' + Format("Range Code")
            else
                LineText := LineText + Format("Range Code");
        end;
        if ("Base Amount Code" <> '') or ("Time Activity Group" <> '') or ("Range Code" <> '') then
            LineText := LineText + ' )';

        exit(LineText);
    end;
}

