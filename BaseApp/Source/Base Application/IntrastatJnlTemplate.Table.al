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
        field(31060; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            TableRelation = "Registration Country/Region"."Country/Region Code" WHERE("Account Type" = CONST("Company Information"),
                                                                                       "Account No." = FILTER(''));
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';

            trigger OnValidate()
            var
                IntrJnlBatch: Record "Intrastat Jnl. Batch";
            begin
                if Confirm(UpdateFieldQst, true, IntrJnlBatch.FieldCaption("Perform. Country/Region Code"), IntrJnlBatch.TableCaption) then begin
                    IntrJnlBatch.SetRange("Journal Template Name", Name);
                    IntrJnlBatch.ModifyAll("Perform. Country/Region Code", "Perform. Country/Region Code");
                    Modify;
                end;
            end;
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
        IntrastatJnlLine.DeleteAll;
        IntrastatJnlBatch.SetRange("Journal Template Name", Name);
        IntrastatJnlBatch.DeleteAll;
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        UpdateFieldQst: Label 'Do you want to update the %1 field on all %2?';
}

