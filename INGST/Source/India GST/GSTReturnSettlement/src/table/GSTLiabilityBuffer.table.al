table 18320 "GST Liability Buffer"
{
    Caption = 'GST Liability Buffer';

    fields
    {
        field(1; "Transaction Type"; Enum "GST Buffer Transaction Type")
        {
            Caption = 'Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Original Document Type"; Enum "Current Doc. Type")
        {
            Caption = 'Original Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Component";
        }
        field(6; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Applied Doc. Type"; Enum "Current Doc. Type")
        {
            Caption = 'Applied Doc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Applied Doc. No."; Code[20])
        {
            Caption = 'Applied Doc. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Applied Amount"; Decimal)
        {
            Caption = 'Applied Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Current Doc. Type"; Enum "Current Doc. Type")
        {
            Caption = 'Current Doc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Application Type"; Enum "Application Type")
        {
            Caption = 'Application Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Applied Doc. Type(Posted)"; Enum "Current Doc. Type")
        {
            Caption = 'Applied Doc. Type(Posted)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Applied Doc. No.(Posted)"; Code[20])
        {
            Caption = 'Applied Doc. No.(Posted)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "GST Group Type"; enum "GST Buffer Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "CLE/VLE Entry No."; Integer)
        {
            Caption = 'CLE/VLE Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = if ("Transaction Type" = const(Purchase)) Vendor."No."
            else
            if ("Transaction Type" = const(Sale)) Customer."No.";
        }
        field(19; "Applied Base Amount"; Decimal)
        {
            Caption = 'Applied Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "GST Cess"; Boolean)
        {
            Caption = 'GST Cess';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(21; "Charge To Cust/Vend"; Decimal)
        {
            Caption = 'Charge To Cust/Vend';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = EndUserIdentifiableInformation;
            DecimalPlaces = 1 : 6;
        }
        field(24; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "TDS/TCS Amount"; Decimal)
        {
            Caption = 'TDS/TCS Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(27; "GST Credit"; Enum "Detail GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "GST Inv. Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "RCM Exempt"; Boolean)
        {
            Caption = 'RCM Exempt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "GST %"; Decimal)
        {
            Caption = 'GST %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "GST Jurisdiction Type"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Original Line No."; Integer)
        {
            Caption = 'Original Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Transaction Type", "Account No.", "Original Document Type", "Original Document No.", "Transaction No.", "GST Group Code", Exempted, "GST Component Code")
        {
            Clustered = true;
        }
        key(Key2; "Transaction No.", "CLE/VLE Entry No.")
        {
        }
        key(Key3; "CLE/VLE Entry No.")
        {
        }
    }
}