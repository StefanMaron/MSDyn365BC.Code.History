table 18355 "Service Transfer Shpt. Line"
{
    Caption = 'Service Transfer Shpt. Line';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(3; "Transfer From G/L Account No."; Code[20])
        {
            Caption = 'Transfer From G/L Account No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "G/L Account" where("Direct Posting" = const(true));
        }
        field(4; "Transfer To G/L Account No."; Code[20])
        {
            Caption = 'Transfer To G/L Account No.';
            Editable = false;
            TableRelation = "G/L Account" where("Direct Posting" = const(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Transfer Price"; Decimal)
        {
            Caption = 'Transfer Price';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(6; "Ship Control A/C No."; Code[20])
        {
            Caption = 'Ship Control A/C No.';
            Editable = false;
            TableRelation = "G/L Account" where("Direct Posting" = const(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Receive Control A/C No."; Code[20])
        {
            Caption = 'Receive Control A/C No.';
            Editable = false;
            TableRelation = "G/L Account" where("Direct Posting" = const(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Shipped; Boolean)
        {
            Caption = 'Shipped';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(11; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(12; "SAC Code"; Code[10])
        {
            Caption = 'SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(16; "GST Rounding Type"; enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(17; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18; "From G/L Account Description"; Text[100])
        {
            Caption = 'From G/L Account Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "To G/L Account Description"; Text[100])
        {
            Caption = 'To G/L Account Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
