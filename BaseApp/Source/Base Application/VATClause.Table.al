table 560 "VAT Clause"
{
    Caption = 'VAT Clause';
    DrillDownPageID = "VAT Clauses";
    LookupPageID = "VAT Clauses";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
        }
        field(10; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
        }
        field(10700; "SII Exemption Code"; Option)
        {
            Caption = 'SII Exemption Code';
            OptionCaption = ' ,E1 Exempt on account of Article 20,E2 Exempt on account of Article 21,E3 Exempt on account of Article 22,E4 Exempt under Articles 23 and 24,E5 Exempt on account of Article 25,E6 Exempt on other grounds';
            OptionMembers = " ","E1 Exempt on account of Article 20","E2 Exempt on account of Article 21","E3 Exempt on account of Article 22","E4 Exempt under Articles 23 and 24","E5 Exempt on account of Article 25","E6 Exempt on other grounds";
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
        VATClauseTranslation: Record "VAT Clause Translation";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATClauseTranslation.SetRange("VAT Clause Code", Code);
        VATClauseTranslation.DeleteAll;

        VATPostingSetup.SetRange("VAT Clause Code", Code);
        VATPostingSetup.ModifyAll("VAT Clause Code", '');
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime;
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    procedure TranslateDescription(Language: Code[10])
    var
        VATClauseTranslation: Record "VAT Clause Translation";
    begin
        if VATClauseTranslation.Get(Code, Language) then begin
            if VATClauseTranslation.Description <> '' then
                Description := VATClauseTranslation.Description;
            if VATClauseTranslation."Description 2" <> '' then
                "Description 2" := VATClauseTranslation."Description 2";
        end;
    end;
}

