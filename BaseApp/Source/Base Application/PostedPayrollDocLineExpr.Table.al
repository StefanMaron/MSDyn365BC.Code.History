table 17461 "Posted Payroll Doc. Line Expr."
{
    Caption = 'Posted Payroll Doc. Line Expr.';

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
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."));
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
            TableRelation = "Posted Payroll Document";
        }
        field(35; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Posted Payroll Document Line"."Line No." WHERE("Document No." = FIELD("Document No."));
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

    [Scope('OnPrem')]
    procedure ViewExpression()
    var
        PostedPayrollDocLineExpr: Record "Posted Payroll Doc. Line Expr.";
        PostedPayrDocExprLines: Page "Posted Payr. Doc. Expr. Lines";
    begin
        case Type of
            Type::Expression:
                begin
                    PostedPayrollDocLineExpr.Reset;
                    PostedPayrollDocLineExpr.SetRange("Document No.", "Document No.");
                    PostedPayrollDocLineExpr.SetRange("Document Line No.", "Document Line No.");
                    PostedPayrollDocLineExpr.SetRange("Calculation Line No.", "Calculation Line No.");
                    PostedPayrollDocLineExpr.SetRange(Level, Level + 1);
                    PostedPayrollDocLineExpr.SetRange("Parent Line No.", "Line No.");

                    PostedPayrDocExprLines.SetTableView(PostedPayrollDocLineExpr);
                    PostedPayrDocExprLines.RunModal;
                    Clear(PostedPayrDocExprLines);
                end;
        end;
    end;
}

