table 17422 "Payroll Element Expression"
{
    Caption = 'Payroll Element Expression';

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(2; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
        }
        field(3; "Calculation Line No."; Integer)
        {
            Caption = 'Calculation Line No.';
        }
        field(4; Level; Integer)
        {
            Caption = 'Level';
        }
        field(5; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(8; Comparison; Option)
        {
            Caption = 'Comparison';
            OptionCaption = ' ,=0,<>0,>0,<0,>=0,<=0';
            OptionMembers = " ","=0","<>0",">0","<0",">=0","<=0";
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Constant,Variable,Field,Expression';
            OptionMembers = Constant,Variable,"Field",Expression;
        }
        field(10; "Table No."; Integer)
        {
            Caption = 'Table No.';
            Editable = false;
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(11; "Table Name"; Text[30])
        {
            CalcFormula = Lookup (AllObj."Object Name" WHERE("Object Type" = CONST(Table)));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."),
                                               ObsoleteState = FILTER(<> Removed));

            trigger OnLookup()
            var
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.SetRange(TableNo, "Table No.");
                if "Source Table" = "Source Table"::Document then
                    Field.SetRange(Type, Field.Type::Decimal)
                else
                    Field.SetRange(Type);
                Field.SetRange(Class, Field.Class::Normal, Field.Class::FlowField);
                if FieldSelection.Open(Field) then
                    Validate("Field No.", Field."No.");
            end;

            trigger OnValidate()
            var
                FieldName: Text[32];
            begin
                CalcFields("Field Name");
                FieldName := "Field Name";
                if StrPos(FieldName, ' ') > 0 then
                    FieldName := StrSubstNo('"%1"', FieldName);

                case "Source Table" of
                    "Source Table"::Employee:
                        Expression := StrSubstNo(EMPTxt, FieldName);
                    "Source Table"::Person:
                        Expression := StrSubstNo(PERTxt, FieldName);
                    "Source Table"::Document:
                        Expression := StrSubstNo(DOCTxt, FieldName);
                    "Source Table"::Contract:
                        Expression := StrSubstNo(CONTxt, FieldName);
                    "Source Table"::Position:
                        Expression := StrSubstNo(POSTxt, FieldName);
                end;
            end;
        }
        field(13; "Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = FIELD("Table No."),
                                                        "No." = FIELD("Field No.")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = ' ,Integer,Decimal,Text,Date';
            OptionMembers = " ","Integer",Decimal,Text,Date;
        }
        field(15; Expression; Text[250])
        {
            Caption = 'Expression';
        }
        field(16; Operator; Option)
        {
            Caption = 'Operator';
            OptionCaption = ' ,+,-,*,/,;';
            OptionMembers = " ","+","-","*","/",";";
        }
        field(17; "Left Bracket"; Option)
        {
            Caption = 'Left Bracket';
            OptionCaption = ' ,(';
            OptionMembers = " ","(";
        }
        field(18; "Right Bracket"; Option)
        {
            Caption = 'Right Bracket';
            OptionCaption = ' ,)';
            OptionMembers = " ",")";
        }
        field(19; "Index No."; Integer)
        {
            Caption = 'Index No.';
        }
        field(20; "Source Table"; Option)
        {
            Caption = 'Source Table';
            OptionCaption = ' ,Document,AE Data,Employee,Person,Contract,Position';
            OptionMembers = " ",Document,"AE Data",Employee,Person,Contract,Position;

            trigger OnValidate()
            begin
                TestField(Type, Type::Field);

                case "Source Table" of
                    "Source Table"::Document:
                        "Table No." := DATABASE::"Payroll Document Line";
                    "Source Table"::"AE Data":
                        "Table No." := DATABASE::"Payroll Document Line AE";
                    "Source Table"::Employee:
                        "Table No." := DATABASE::Employee;
                    "Source Table"::Person:
                        "Table No." := DATABASE::Person;
                    "Source Table"::Contract:
                        "Table No." := DATABASE::"Labor Contract";
                    "Source Table"::Position:
                        "Table No." := DATABASE::Position;
                end;
            end;
        }
        field(22; "Error Code"; Code[10])
        {
            Caption = 'Error Code';
            Editable = false;
            TableRelation = "Payroll Calculation Error";
        }
        field(23; "Error Text"; Text[50])
        {
            CalcFormula = Lookup ("Payroll Calculation Error".Description WHERE(Code = FIELD("Error Code")));
            Caption = 'Error Text';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Assign to Variable"; Text[30])
        {
            Caption = 'Assign to Variable';

            trigger OnLookup()
            begin
                PayrollElementVariable.Reset();
                PayrollElementVariable.SetRange("Element Code", "Element Code");
                PayrollElementVariable.SetRange("Period Code", "Period Code");
                if PAGE.RunModal(0, PayrollElementVariable) = ACTION::LookupOK then
                    Validate("Assign to Variable", PayrollElementVariable.Variable);
            end;

            trigger OnValidate()
            begin
                if ("Assign to Variable" <> '') and
                   (not PayrollElementVariable.Get("Element Code", "Period Code", "Assign to Variable"))
                then begin
                    PayrollElementVariable.Init();
                    PayrollElementVariable."Element Code" := "Element Code";
                    PayrollElementVariable."Period Code" := "Period Code";
                    PayrollElementVariable.Variable := "Assign to Variable";
                    PayrollElementVariable.Insert();
                end;
            end;
        }
        field(25; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding Precision';
        }
        field(26; "Rounding Type"; Option)
        {
            Caption = 'Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(27; "Assign to Field No."; Integer)
        {
            Caption = 'Assign to Field No.';
            TableRelation = Field."No." WHERE(TableNo = CONST(17415),
                                               Type = CONST(Decimal),
                                               Class = CONST(Normal));

            trigger OnLookup()
            var
                PayrollDocLine: Record "Payroll Document Line";
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
                    Validate("Assign to Field No.", Field."No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("Assign to Field Name");
            end;
        }
        field(28; "Assign to Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = CONST(17415),
                                                        "No." = FIELD("Assign to Field No.")));
            Caption = 'Assign to Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Logical Suffix"; Option)
        {
            Caption = 'Logical Suffix';
            OptionCaption = ' ,AND,OR,XOR';
            OptionMembers = " ","AND","OR","XOR";

            trigger OnValidate()
            begin
                TestField(Level, 0);
            end;
        }
        field(33; "Logical Prefix"; Option)
        {
            Caption = 'Logical Prefix';
            OptionCaption = ' ,NOT';
            OptionMembers = " ","NOT";
        }
    }

    keys
    {
        key(Key1; "Element Code", "Period Code", "Calculation Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollElementExpr2.Reset();
        PayrollElementExpr2.SetRange("Element Code", "Element Code");
        PayrollElementExpr2.SetRange("Period Code", "Period Code");
        PayrollElementExpr2.SetRange("Calculation Line No.", "Calculation Line No.");
        PayrollElementExpr2.SetRange("Parent Line No.", "Line No.");
        PayrollElementExpr2.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        PayrollElementExpr2.Reset();
        PayrollElementExpr2.SetRange("Element Code", "Element Code");
        PayrollElementExpr2.SetRange("Period Code", "Period Code");
        PayrollElementExpr2.SetRange("Calculation Line No.", "Calculation Line No.");
        if PayrollElementExpr2.FindLast then
            "Line No." := PayrollElementExpr2."Line No." + 1
        else
            "Line No." := 1;
    end;

    var
        PayrollElementExpr2: Record "Payroll Element Expression";
        PayrollElementVariable: Record "Payroll Element Variable";
        "Field": Record "Field";
        ExprMgt: Codeunit "Payroll Expression Management";
        EMPTxt: Label 'EMP.%1';
        PERTxt: Label 'PER.%1';
        DOCTxt: Label 'DOC.%1';
        CONTxt: Label 'CON.%1';
        POSTxt: Label 'POS.%1';

    [Scope('OnPrem')]
    procedure Compose(): Text[250]
    var
        PayrollElementExpr: Record "Payroll Element Expression";
        Expr: Text[250];
    begin
        Expr := '';
        PayrollElementExpr.Reset();
        PayrollElementExpr.SetRange("Element Code", "Element Code");
        PayrollElementExpr.SetRange("Period Code", "Period Code");
        PayrollElementExpr.SetRange("Calculation Line No.", "Calculation Line No.");
        PayrollElementExpr.SetRange(Level, Level + 1);
        PayrollElementExpr.SetRange("Parent Line No.", "Line No.");
        if PayrollElementExpr.FindSet then
            repeat
                Expr := Expr + ExprMgt.FormatElementStatement(PayrollElementExpr);
            until PayrollElementExpr.Next = 0;

        ExprMgt.CheckParenthesis(Expr);
        Expression := Expr;

        exit(Expr);
    end;

    [Scope('OnPrem')]
    procedure ExprAssistEdit()
    var
        PayrollElementExpr: Record "Payroll Element Expression";
        PayrollExpression: Page "Payroll Expression";
        Variables: Page "Payroll Element Variables";
    begin
        case Type of
            Type::Expression:
                begin
                    PayrollElementExpr.Reset();
                    PayrollElementExpr.SetRange("Element Code", "Element Code");
                    PayrollElementExpr.SetRange("Period Code", "Period Code");
                    PayrollElementExpr.SetRange("Calculation Line No.", "Calculation Line No.");
                    PayrollElementExpr.SetRange(Level, Level + 1);
                    PayrollElementExpr.SetRange("Parent Line No.", "Line No.");

                    PayrollExpression.SetTableView(PayrollElementExpr);
                    PayrollExpression.SetFromElementExpr(Rec);
                    PayrollExpression.RunModal;
                    Clear(PayrollExpression);

                    Compose;
                end;
            Type::Variable:
                begin
                    PayrollElementVariable.Reset();
                    PayrollElementVariable.SetRange("Element Code", "Element Code");
                    PayrollElementVariable.SetRange("Period Code", "Period Code");
                    Variables.SetTableView(PayrollElementVariable);
                    Variables.LookupMode(true);
                    if ACTION::LookupOK = Variables.RunModal then begin
                        Variables.GetRecord(PayrollElementVariable);
                        Expression := PayrollElementVariable.Variable;
                    end;
                    Clear(Variables);
                end;
        end;
    end;
}

