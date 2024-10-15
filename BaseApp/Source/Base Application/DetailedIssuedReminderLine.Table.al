table 11790 "Detailed Issued Reminder Line"
{
    Caption = 'Detailed Issued Reminder Line';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Issued Reminder No."; Code[20])
        {
            Caption = 'Issued Reminder No.';
            TableRelation = "Issued Reminder Header";
        }
        field(2; "Issued Reminder Line No."; Integer)
        {
            Caption = 'Issued Reminder Line No.';
            NotBlank = true;
            TableRelation = "Issued Reminder Line"."Line No.";
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
        key(Key1; "Issued Reminder No.", "Issued Reminder Line No.", "Detailed Customer Entry No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Interest Amount", "Interest Base Amount";
        }
    }

    fieldgroups
    {
    }
}

