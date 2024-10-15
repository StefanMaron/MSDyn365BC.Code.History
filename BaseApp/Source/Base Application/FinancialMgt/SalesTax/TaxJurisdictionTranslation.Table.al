namespace Microsoft.Finance.SalesTax;

using System.Globalization;

table 327 "Tax Jurisdiction Translation"
{
    Caption = 'Tax Jurisdiction Translation';

    fields
    {
        field(1; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
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
        field(10020; "Print Description"; Text[30])
        {
            Caption = 'Print Description';
        }
    }

    keys
    {
        key(Key1; "Tax Jurisdiction Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

