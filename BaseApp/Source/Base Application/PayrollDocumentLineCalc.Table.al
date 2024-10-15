table 17459 "Payroll Document Line Calc."
{
    Caption = 'Payroll Document Line Calc.';
    LookupPageID = "Payroll Document Calc. Lines";

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
        }
        field(6; "Range Code"; Text[20])
        {
            Caption = 'Range Code';
            TableRelation = "Payroll Range Header".Code WHERE("Element Code" = FIELD("Element Code"),
                                                               "Range Type" = FIELD("Range Type"));
        }
        field(7; "Base Amount Code"; Code[10])
        {
            Caption = 'Base Amount Code';
            TableRelation = "Payroll Base Amount".Code WHERE("Element Code" = FIELD("Element Code"));
        }
        field(8; "Time Activity Group"; Code[20])
        {
            Caption = 'Time Activity Group';
            TableRelation = "Time Activity Group";
        }
        field(9; Variable; Text[30])
        {
            Caption = 'Variable';
            TableRelation = "Payroll Document Line Var.".Variable WHERE("Document No." = FIELD("Document No."),
                                                                         "Document Line No." = FIELD("Document Line No."));
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
        }
        field(12; "Result Value"; Decimal)
        {
            Caption = 'Result Value';
            Editable = false;
        }
        field(13; "Result Field No."; Integer)
        {
            Caption = 'Result Field No.';
            TableRelation = Field."No." WHERE(TableNo = CONST(17415),
                                               Class = CONST(Normal),
                                               Type = FILTER(Decimal));
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
        }
        field(21; "Statement 2"; Option)
        {
            Caption = 'Statement 2';
            OptionCaption = ' ,MIN,MAX,ABS,GOTO,STOP,ROUND';
            OptionMembers = " ","MIN","MAX",ABS,GOTO,STOP,ROUND;
        }
        field(22; "IF Level"; Integer)
        {
            Caption = 'IF Level';
        }
        field(23; "Logical Result"; Option)
        {
            Caption = 'Logical Result';
            OptionCaption = ' ,FALSE,TRUE';
            OptionMembers = " ","FALSE","TRUE";
        }
        field(24; "No. of Runs"; Integer)
        {
            Caption = 'No. of Runs';
            Editable = false;
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
        field(60; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(61; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'DOC.%1 = ';

    [Scope('OnPrem')]
    procedure ViewExpression()
    var
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PayrollDocExprLines: Page "Payroll Document Expr. Lines";
    begin
        TestField("Document No.");
        TestField("Line No.");

        PayrollDocLineExpr.Reset();
        PayrollDocLineExpr.FilterGroup(2);
        PayrollDocLineExpr.SetRange("Document No.", "Document No.");
        PayrollDocLineExpr.SetRange("Document Line No.", "Document Line No.");
        PayrollDocLineExpr.SetRange("Calculation Line No.", "Line No.");
        PayrollDocLineExpr.SetRange(Level, 0);
        PayrollDocLineExpr.SetRange("Parent Line No.", 0);
        PayrollDocLineExpr.FilterGroup(0);

        PayrollDocExprLines.Editable(false);
        PayrollDocExprLines.SetTableView(PayrollDocLineExpr);
        PayrollDocExprLines.RunModal;
        Clear(PayrollDocExprLines);
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

    [Scope('OnPrem')]
    procedure Rounding(Value: Decimal): Decimal
    begin
        exit(Round(Value, GetRoundingPrecision, GetRoundingDirection));
    end;

    [Scope('OnPrem')]
    procedure GetRoundingDirection(): Text[1]
    begin
        case "Rounding Type" of
            "Rounding Type"::Nearest:
                exit('=');
            "Rounding Type"::Up:
                exit('>');
            "Rounding Type"::Down:
                exit('<');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRoundingPrecision(): Decimal
    begin
        if "Rounding Precision" = 0 then
            "Rounding Precision" := 0.01;
        exit("Rounding Precision");
    end;
}

