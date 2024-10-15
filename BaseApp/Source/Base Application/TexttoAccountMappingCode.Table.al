table 11703 "Text-to-Account Mapping Code"
{
    Caption = 'Text-to-Account Mapping Code';
#if not CLEAN19
    LookupPageID = "Text-to-Account Mapping Codes";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

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

