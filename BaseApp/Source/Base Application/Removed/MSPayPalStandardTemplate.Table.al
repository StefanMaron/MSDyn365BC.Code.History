table 7861 "MS- PayPal Standard Template"
{
    Caption = 'MS- PayPal Standard Template';
    ObsoleteReason = 'This table is no longer used by any user.';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            NotBlank = true;
        }
        field(8; "Terms of Service"; Text[250])
        {
            Caption = 'Terms of Service';
            ExtendedDatatype = URL;
        }
        field(11; Logo; BLOB)
        {
            Caption = 'Logo';
            SubType = Bitmap;
        }
        field(12; "Target URL"; BLOB)
        {
            Caption = 'Target URL';
            SubType = Bitmap;
        }
        field(13; "Logo URL"; BLOB)
        {
            Caption = 'Logo URL';
            SubType = Bitmap;
        }
        field(14; "Logo Last Update DateTime"; DateTime)
        {
            Caption = 'Logo Last Update DateTime';
        }
        field(15; "Logo Update Frequency"; Duration)
        {
            Caption = 'Logo Update Frequency';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Description; Description)
        {
        }
    }
}

