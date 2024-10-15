table 31101 "VAT Control Report Line"
{
    Caption = 'VAT Control Report Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Control Report No."; Code[20])
        {
            Caption = 'Control Report No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "VAT Control Rep. Section Code"; Code[20])
        {
            Caption = 'VAT Control Rep. Section Code';
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(12; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
        }
        field(13; "Original Document VAT Date"; Date)
        {
            Caption = 'Original Document VAT Date';
        }
        field(15; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
        }
        field(16; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(17; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(18; "Tax Registration No."; Text[20])
        {
            Caption = 'Tax Registration No.';
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(21; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(30; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(31; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        field(32; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        field(35; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
            Editable = false;
        }
        field(36; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        field(40; "VAT Rate"; Option)
        {
            Caption = 'VAT Rate';
            OptionCaption = ' ,Base,Reduced,Reduced 2';
            OptionMembers = " ",Base,Reduced,"Reduced 2";
        }
        field(41; "Commodity Code"; Code[10])
        {
            Caption = 'Commodity Code';
        }
        field(42; "Supplies Mode Code"; Option)
        {
            Caption = 'Supplies Mode Code';
            OptionCaption = ' ,par. 89,par. 90';
            OptionMembers = " ","par. 89","par. 90";
        }
        field(43; "Corrections for Bad Receivable"; Option)
        {
            Caption = 'Corrections for Bad Receivable';
            OptionCaption = ' ,Insolvency Proceedings (p.44),Bad Receivable (p.46 resp. 74a)';
            OptionMembers = " ","Insolvency Proceedings (p.44)","Bad Receivable (p.46 resp. 74a)";
        }
        field(44; "Insolvency Proceedings (p.44)"; Boolean)
        {
            Caption = 'Insolvency Proceedings (p.44)';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by "Corrections for Bad Receivable"';
            ObsoleteTag = '15.0';
        }
        field(45; "Ratio Use"; Boolean)
        {
            Caption = 'Ratio Use';
        }
        field(46; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(47; "Birth Date"; Date)
        {
            Caption = 'Birth Date';
        }
        field(48; "Place of stay"; Text[50])
        {
            Caption = 'Place of stay';
        }
        field(50; "Exclude from Export"; Boolean)
        {
            Caption = 'Exclude from Export';
        }
        field(60; "Closed by Document No."; Code[20])
        {
            Caption = 'Closed by Document No.';
            Editable = false;
        }
        field(61; "Closed Date"; Date)
        {
            Caption = 'Closed Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Control Report No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Control Report No.", "Posting Date")
        {
        }
        key(Key3; "Control Report No.", "VAT Date")
        {
        }
        key(Key4; "Closed by Document No.")
        {
        }
    }

    fieldgroups
    {
    }

}
