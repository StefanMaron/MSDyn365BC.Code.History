namespace Microsoft.Foundation.Address;

using System.Globalization;

table 11 "Country/Region Translation"
{
    Caption = 'Country/Region Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            NotBlank = true;
            TableRelation = "Country/Region";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

