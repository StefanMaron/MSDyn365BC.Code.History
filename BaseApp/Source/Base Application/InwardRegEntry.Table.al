table 11202 "Inward Reg. Entry"
{
    Caption = 'Inward Reg. Entry';
    ObsoleteReason = 'Replaced by extension';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(11; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(12; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(15; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(16; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(17; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(19; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(20; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(22; "Amount Including VAT (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
        }
        field(30; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(31; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
            Editable = false;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            Editable = false;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            Editable = false;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(50; "Ledger VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger VAT Amount';
        }
        field(51; "Ledger Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Debit Amount';
        }
        field(52; "Ledger Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Credit Amount';
        }
        field(60; "Ledger Add.-Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Add.-Amount';
        }
        field(61; "Ledger Add.-Debit"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Add.-Debit';
        }
        field(62; "Ledger Add.-Credit"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Add.-Credit';
        }
        field(63; "Ledger VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger VAT Amount (LCY)';
        }
        field(64; "Ledger Add.-VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledger Add.-VAT Amount';
        }
        field(65; "Add.-Currency Factor"; Decimal)
        {
            Caption = 'Add.-Currency Factor';
        }
        field(66; "Currency Date"; Date)
        {
            Caption = 'Currency Date';
        }
        field(70; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(71; "Vendor Invoice No."; Code[20])
        {
            Caption = 'Vendor Invoice No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "VAT Prod. Posting Group", "Gen. Prod. Posting Group")
        {
        }
        key(Key3; "Source Type", "Source No.")
        {
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "Document No.", "Entry No.")
        {
        }
        key(Key6; "Vendor No.", Open, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code")
        {
            SumIndexFields = "Amount (LCY)", "Amount Including VAT (LCY)";
        }
    }

    fieldgroups
    {
    }
}

