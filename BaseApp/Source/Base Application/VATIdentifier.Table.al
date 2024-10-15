table 11767 "VAT Identifier"
{
    Caption = 'VAT Identifier';
    LookupPageID = "VAT Identifiers";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; Description; Text[80])
        {
            Caption = 'Description';
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
    }

    trigger OnDelete()
    var
        VATIdentifierTranslate: Record "VAT Identifier Translate";
    begin
        VATIdentifierTranslate.SetRange("VAT Identifier Code", Code);
        VATIdentifierTranslate.DeleteAll;
    end;
}

