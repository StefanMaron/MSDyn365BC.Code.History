table 11787 "Detailed Fin. Charge Memo Line"
{
    Caption = 'Detailed Fin. Charge Memo Line';
    DrillDownPageID = "Detailed Fin. Ch. Memo Lines";
    LookupPageID = "Detailed Fin. Ch. Memo Lines";

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
        field(9; "Entry Type"; Option)
        {
            CalcFormula = Lookup ("Detailed Cust. Ledg. Entry"."Entry Type" WHERE("Entry No." = FIELD("Detailed Customer Entry No.")));
            Caption = 'Entry Type';
            FieldClass = FlowField;
            OptionCaption = ',Initial Entry,Application,Unrealized Loss,Unrealized Gain,Realized Loss,Realized Gain,Payment Discount,Payment Discount (VAT Excl.),Payment Discount (VAT Adjustment),Appln. Rounding,Correction of Remaining Amount,Payment Tolerance,Payment Discount Tolerance,Payment Tolerance (VAT Excl.),Payment Tolerance (VAT Adjustment),Payment Discount Tolerance (VAT Excl.),Payment Discount Tolerance (VAT Adjustment)';
            OptionMembers = ,"Initial Entry",Application,"Unrealized Loss","Unrealized Gain","Realized Loss","Realized Gain","Payment Discount","Payment Discount (VAT Excl.)","Payment Discount (VAT Adjustment)","Appln. Rounding","Correction of Remaining Amount","Payment Tolerance","Payment Discount Tolerance","Payment Tolerance (VAT Excl.)","Payment Tolerance (VAT Adjustment)","Payment Discount Tolerance (VAT Excl.)","Payment Discount Tolerance (VAT Adjustment)";
        }
        field(10; "Posting Date"; Date)
        {
            CalcFormula = Lookup ("Detailed Cust. Ledg. Entry"."Posting Date" WHERE("Entry No." = FIELD("Detailed Customer Entry No.")));
            Caption = 'Posting Date';
            FieldClass = FlowField;
        }
        field(11; "Document Type"; Option)
        {
            CalcFormula = Lookup ("Detailed Cust. Ledg. Entry"."Document Type" WHERE("Entry No." = FIELD("Detailed Customer Entry No.")));
            Caption = 'Document Type';
            FieldClass = FlowField;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(12; "Document No."; Code[20])
        {
            CalcFormula = Lookup ("Detailed Cust. Ledg. Entry"."Document No." WHERE("Entry No." = FIELD("Detailed Customer Entry No.")));
            Caption = 'Document No.';
            FieldClass = FlowField;
        }
        field(13; "Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Lookup ("Detailed Cust. Ledg. Entry".Amount WHERE("Entry No." = FIELD("Detailed Customer Entry No.")));
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

