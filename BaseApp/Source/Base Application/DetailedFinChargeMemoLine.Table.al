table 11787 "Detailed Fin. Charge Memo Line"
{
    Caption = 'Detailed Fin. Charge Memo Line';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Finance Charge Memo No."; Code[20])
        {
            Caption = 'Finance Charge Memo No.';
            TableRelation = "Finance Charge Memo Header";
        }
        field(2; "Fin. Charge. Memo Line No."; Integer)
        {
            Caption = 'Fin. Charge. Memo Line No.';
            NotBlank = true;
            TableRelation = "Finance Charge Memo Line"."Line No.";
        }
        field(3; "Detailed Customer Entry No."; Integer)
        {
            Caption = 'Detailed Customer Entry No.';
            TableRelation = "Detailed Cust. Ledg. Entry";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(5; Days; Integer)
        {
            Caption = 'Days';
        }
        field(6; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
        }
        field(7; "Interest Amount"; Decimal)
        {
            Caption = 'Interest Amount';
        }
        field(8; "Interest Base Amount"; Decimal)
        {
            Caption = 'Interest Base Amount';
        }
        field(9; "Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            CalcFormula = Lookup("Detailed Cust. Ledg. Entry"."Entry Type" where("Entry No." = field("Detailed Customer Entry No.")));
            Caption = 'Entry Type';
            FieldClass = FlowField;
        }
        field(10; "Posting Date"; Date)
        {
            CalcFormula = Lookup("Detailed Cust. Ledg. Entry"."Posting Date" where("Entry No." = field("Detailed Customer Entry No.")));
            Caption = 'Posting Date';
            FieldClass = FlowField;
        }
        field(11; "Document Type"; Enum "Gen. Journal Document Type")
        {
            CalcFormula = Lookup("Detailed Cust. Ledg. Entry"."Document Type" where("Entry No." = field("Detailed Customer Entry No.")));
            Caption = 'Document Type';
            FieldClass = FlowField;
        }
        field(12; "Document No."; Code[20])
        {
            CalcFormula = Lookup("Detailed Cust. Ledg. Entry"."Document No." where("Entry No." = field("Detailed Customer Entry No.")));
            Caption = 'Document No.';
            FieldClass = FlowField;
        }
        field(13; "Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Lookup("Detailed Cust. Ledg. Entry".Amount where("Entry No." = field("Detailed Customer Entry No.")));
            Caption = 'Base Amount';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Finance Charge Memo No.", "Fin. Charge. Memo Line No.", "Detailed Customer Entry No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Interest Amount", "Interest Base Amount";
        }
    }

    fieldgroups
    {
    }
}

