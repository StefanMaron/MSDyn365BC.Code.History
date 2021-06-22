table 261 "Intrastat Jnl. Template"
{
    Caption = 'Intrastat Jnl. Template';
    LookupPageID = "Intrastat Jnl. Template List";
    ReplicateData = true;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Checklist Report ID"; Integer)
        {
            Caption = 'Checklist Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"Intrastat Journal";
                "Checklist Report ID" := REPORT::"Intrastat - Checklist";
            end;
        }
        field(15; "Checklist Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Checklist Report ID")));
            Caption = 'Checklist Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", Name);
        IntrastatJnlLine.DeleteAll();
        IntrastatJnlBatch.SetRange("Journal Template Name", Name);
        IntrastatJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
}

