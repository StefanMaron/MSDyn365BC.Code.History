table 18248 "Posted Jnl. Bank Charges"
{
    Caption = 'Posted Jnl. Bank Charges';

    fields
    {
        field(1; "GL Entry No."; Integer)
        {
            Caption = 'GL Entry No.';
            Editable = false;
            TableRelation = "G/L Entry";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Bank Charge"; Code[10])
        {
            Caption = 'Bank Charge';
            Editable = false;
            TableRelation = "Bank Charge";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            Editable = false;
            MinValue = 0;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group" WHERE(
                "GST Group Type" = FILTER(Service),
                "Reverse Charge" = FILTER(false));
        }
        field(8; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Foreign Exchange"; Boolean)
        {
            Caption = 'Foreign Exchange';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(13; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(14; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "GST Credit"; Enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "GST Jurisdiction Type"; ENum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "GST Bill to/Buy From State"; Code[10])
        {
            Caption = 'GST Bill to/Buy From State';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(19; "Location  Reg. No."; Code[20])
        {
            Caption = 'Location  Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(20; "GST Registration Status"; Enum "Bank Registration Status")
        {
            Caption = 'GST Registration Status';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(21; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(22; "GST Inv. Rounding Type"; ENum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(23; "Nature of Supply"; Enum "GST Nature of Supply")
        {
            Caption = 'Nature of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "External Document No."; Code[40])
        {
            Caption = 'External Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; LCY; Boolean)
        {
            Caption = 'LCY';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; Reversed; Boolean)
        {
            Caption = 'Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "GST Document Type"; Enum "BankCharges DocumentType")
        {
            Caption = 'GST Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "GL Entry No.", "Bank Charge")
        {
            Clustered = true;
        }
    }
}

