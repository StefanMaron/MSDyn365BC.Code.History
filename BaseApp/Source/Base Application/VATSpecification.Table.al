table 10687 "VAT Specification"
{
    Caption = 'VAT Code';
    LookupPageID = "VAT Specifications";

    fields
    {
        field(1; "Code"; Code[50])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "VAT Report Value"; Text[250])
        {
            Caption = 'VAT Report Value';
        }
    }
}
