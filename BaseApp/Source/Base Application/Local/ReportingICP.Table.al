table 11403 "Reporting ICP"
{
    Caption = 'Reporting ICP';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(5; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(15; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(20; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "EU 3-Party Trade", "Country/Region Code", "VAT Registration No.")
        {
        }
    }

    fieldgroups
    {
    }
}

