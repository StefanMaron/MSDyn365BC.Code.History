namespace Microsoft.Bank.Setup;

table 1210 "SWIFT Code"
{
    Caption = 'SWIFT Code';
    LookupPageID = "SWIFT Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
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
        fieldgroup(Brick; "Code", Name)
        {
        }
    }
}

