namespace Microsoft.Finance.SalesTax;

using System.Globalization;

table 316 "Tax Area Translation"
{
    Caption = 'Tax Area Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            NotBlank = true;
            TableRelation = "Tax Area";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Tax Area Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

