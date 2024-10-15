table 12134 "Withholding Exceptional Event"
{
    Caption = 'Withholding Tax Exceptional Event';
    LookupPageId = "Withholding Exceptional Events";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}
