table 2840 "Native - Gen. Settings Buffer"
{
    Caption = 'Native - Gen. Settings Buffer';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'These objects will be removed';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Currency Symbol"; Text[10])
        {
            Caption = 'Currency Symbol';
            DataClassification = SystemMetadata;
        }
        field(3; "Paypal Email Address"; Text[250])
        {
            Caption = 'Paypal Email Address';
            DataClassification = SystemMetadata;
        }
        field(4; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Language Locale ID"; Integer)
        {
            Caption = 'Language Locale ID';
            DataClassification = SystemMetadata;
        }
        field(6; "Language Code"; Text[50])
        {
            Caption = 'Language Code';
            DataClassification = SystemMetadata;
        }
        field(7; "Language Display Name"; Text[80])
        {
            Caption = 'Language Display Name';
            DataClassification = SystemMetadata;
        }
        field(50; "Default Tax ID"; Guid)
        {
            Caption = 'Default Tax ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51; "Defauilt Tax Description"; Text[100])
        {
            Caption = 'Defauilt Tax Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(52; "Default Payment Terms ID"; Guid)
        {
            Caption = 'Default Payment Terms ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(53; "Def. Pmt. Term Description"; Text[50])
        {
            Caption = 'Def. Pmt. Term Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(54; "Default Payment Method ID"; Guid)
        {
            Caption = 'Default Payment Method ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(55; "Def. Pmt. Method Description"; Text[50])
        {
            Caption = 'Def. Pmt. Method Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(56; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(57; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(58; "VAT/Tax Rounding Precision"; Decimal)
        {
            Caption = 'VAT/Tax Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(59; "Quantity Rounding Precision"; Decimal)
        {
            Caption = 'Quantity Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60; EnableSync; Boolean)
        {
            Caption = 'EnableSync';
            DataClassification = SystemMetadata;
        }
        field(61; EnableSyncCoupons; Boolean)
        {
            Caption = 'EnableSyncCoupons';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
