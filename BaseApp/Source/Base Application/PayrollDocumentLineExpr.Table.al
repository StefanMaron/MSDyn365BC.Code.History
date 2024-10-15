table 17438 "Payroll Document Line Expr."
{
    Caption = 'Payroll Document Line Expr.';

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
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
                Field.SetRange(Class, Field.Class::Normal);
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
        field(21; "Result Value"; Decimal)
        {
            Caption = 'Result Value';
            Editable = false;
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
            Editable = false;
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
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.SetRange(TableNo, DATABASE::"Payroll Document Line");
                Field.SetRange(Type, Field.Type::Decimal);
                Field.SetRange(Class, Field.Class::Normal);
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
        field(32; "Logical Result"; Option)
        {
            Caption = 'Logical Result';
            OptionCaption = ' ,FALSE,TRUE';
            OptionMembers = " ","FALSE","TRUE";
        }
        field(33; "Logical Prefix"; Option)
        {
            Caption = 'Logical Prefix';
            OptionCaption = ' ,NOT';
            OptionMembers = " ","NOT";
        }
        field(34; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(35; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Line No.", "Calculation Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollDocLineExpr2.Reset;
        PayrollDocLineExpr2.SetRange("Document No.", "Document No.");
        PayrollDocLineExpr2.SetRange("Document Line No.", "Document Line No.");
        PayrollDocLineExpr2.SetRange("Calculation Line No.", "Calculation Line No.");
        PayrollDocLineExpr2.SetRange("Parent Line No.", "Line No.");
        PayrollDocLineExpr2.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        PayrollDocLineExpr2.Reset;
        PayrollDocLineExpr2.SetRange("Document No.", "Document No.");
        PayrollDocLineExpr2.SetRange("Document Line No.", "Document Line No.");
        PayrollDocLineExpr2.SetRange("Calculation Line No.", "Calculation Line No.");
        if PayrollDocLineExpr2.FindLast then
            "Line No." := PayrollDocLineExpr2."Line No." + 1
        else
            "Line No." := 1;
    end;

    var
        EMPTxt: Label 'EMP.%1';
        PERTxt: Label 'PER.%1';
        DOCTxt: Label 'DOC.%1';
        CONTxt: Label 'CON.%1';
        POSTxt: Label 'POS.%1';
        PayrollDocLineExpr2: Record "Payroll Document Line Expr.";
        "Field": Record "Field";
        ExprMgt: Codeunit "Payroll Expression Management";

    [Scope('OnPrem')]
    procedure Compose(Type: Option Expression,Result): Text[250]
    var
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        Expr: Text[250];
    begin
        Expr := '';
        PayrollDocLineExpr.Reset;
        PayrollDocLineExpr.SetRange("Document No.", "Document No.");
        PayrollDocLineExpr.SetRange("Document Line No.", "Document Line No.");
        PayrollDocLineExpr.SetRange("Calculation Line No.", "Calculation Line No.");
        PayrollDocLineExpr.SetRange(Level, Level + 1);
        PayrollDocLineExpr.SetRange("Parent Line No.", "Line No.");
        if PayrollDocLineExpr.FindSet then
            repeat
                case Type of
                    Type::Expression:
                        Expr := Expr + ExprMgt.FormatDocLineStatement(PayrollDocLineExpr);
                    Type::Result:
                        Expr := Expr +
                          DelChr(
                            StrSubstNo('%1%2%3%4',
                              Format(PayrollDocLineExpr."Left Bracket"),
                              Format(PayrollDocLineExpr."Result Value"),
                              Format(PayrollDocLineExpr."Right Bracket"),
                              Format(PayrollDocLineExpr.Operator)));
                end;
            until PayrollDocLineExpr.Next = 0;

        ExprMgt.CheckParenthesis(Expr);
        Expression := Expr;

        exit(Expr);
    end;

    [Scope('OnPrem')]
    procedure ExprAssistEdit()
    var
        PayrollDocLineExpr: Record "Payroll Document Line Expr.";
        PayrollDocLineVar: Record "Payroll Document Line Var.";
        PayrollDocExprLines: Page "Payroll Document Expr. Lines";
        PayrollElementVariables: Page "Payroll Element Variables";
    begin
        case Type of
            Type::Expression:
                begin
                    PayrollDocLineExpr.Reset;
                    PayrollDocLineExpr.SetRange("Document No.", "Document No.");
                    PayrollDocLineExpr.SetRange("Document Line No.", "Document Line No.");
                    PayrollDocLineExpr.SetRange("Calculation Line No.", "Calculation Line No.");
                    PayrollDocLineExpr.SetRange(Level, Level + 1);
                    PayrollDocLineExpr.SetRange("Parent Line No.", "Line No.");

                    PayrollDocExprLines.SetTableView(PayrollDocLineExpr);
                    PayrollDocExprLines.RunModal;
                    Clear(PayrollDocExprLines);

                    Compose(0);
                end;
            Type::Variable:
                begin
                    PayrollDocLineVar.Reset;
                    PayrollDocLineVar.SetRange("Element Code", "Element Code");
                    PayrollElementVariables.SetTableView(PayrollDocLineVar);
                    PayrollElementVariables.LookupMode(true);
                    PayrollElementVariables.Editable(false);
                    if ACTION::LookupOK = PayrollElementVariables.RunModal then begin
                        PayrollElementVariables.GetRecord(PayrollDocLineVar);
                        Expression := PayrollDocLineVar.Variable;
                    end;
                    Clear(PayrollElementVariables);
                end;
        end;
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

