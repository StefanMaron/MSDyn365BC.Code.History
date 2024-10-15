table 10688 "VAT Note"
{
    Caption = 'VAT Note';
    LookupPageID = "VAT Notes";

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