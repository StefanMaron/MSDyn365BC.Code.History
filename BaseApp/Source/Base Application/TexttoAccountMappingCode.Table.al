table 11703 "Text-to-Account Mapping Code"
{
    Caption = 'Text-to-Account Mapping Code';
    LookupPageID = "Text-to-Account Mapping Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
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
        TexttoAccountMapping: Record "Text-to-Account Mapping";
    begin
        TexttoAccountMapping.SetRange("Text-to-Account Mapping Code", Code);
        TexttoAccountMapping.DeleteAll();
    end;
}

