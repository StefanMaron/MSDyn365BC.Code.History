table 323 "VAT Business Posting Group"
{
    Caption = 'VAT Business Posting Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Business Posting Groups";
    LookupPageID = "VAT Business Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(12100; "Default Sales Operation Type"; Code[20])
        {
            Caption = 'Default Sales Operation Type';
            TableRelation = "No. Series" WHERE("No. Series Type" = CONST(Sales));
        }
        field(12101; "Default Purch. Operation Type"; Code[20])
        {
            Caption = 'Default Purch. Operation Type';
            TableRelation = "No. Series" WHERE("No. Series Type" = CONST(Purchase));
        }
        field(12102; "Check VAT Exemption"; Boolean)
        {
            Caption = 'Check VAT Exemption';
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

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
        "Last Modified Date Time" := CurrentDateTime;
    end;
}

