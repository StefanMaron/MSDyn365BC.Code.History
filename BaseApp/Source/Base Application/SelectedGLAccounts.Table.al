table 10727 "Selected G/L Accounts"
{
    Caption = 'Selected G\L Accounts';
    DataCaptionFields = "No.", Name;
    LookupPageID = "G/L Account List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

