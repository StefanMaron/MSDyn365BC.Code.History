table 5068 Salutation
{
    Caption = 'Salutation';
    LookupPageID = Salutations;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
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
        SalutationFormula: Record "Salutation Formula";
    begin
        SalutationFormula.SetRange("Salutation Code", Code);
        SalutationFormula.DeleteAll();
    end;
}

