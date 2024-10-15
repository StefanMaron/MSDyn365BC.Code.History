table 10670 "SAF-T Setup"
{
    DataClassification = CustomerContent;
    Caption = 'SAF-T Setup';
    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Primary Key';
        }
        field(2; "Dimension No. Series Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Dimension No. Series Code';
            TableRelation = "No. Series";
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with Dimension No.';
            ObsoleteTag = '17.0';
        }
        field(3; "Last Tax Code"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Last Tax Code';
        }
        field(4; "Not Applicable VAT Code"; Code[20])
        {
            Caption = 'Not Applicable VAT Code';
            DataClassification = CustomerContent;
            TableRelation = "VAT Code";
        }
        field(5; "Dimension No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Dimension No.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
