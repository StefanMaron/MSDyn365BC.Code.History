table 344 "VAT Reporting Code"
{
    Caption = 'VAT Reporting Code';
    LookupPageID = "VAT Reporting Codes";

    fields
    {
        field(1; Code; Code[20])
        {
        }
        field(2; Description; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }
}
