table 255 "VAT Statement Template"
{
    Caption = 'VAT Statement Template';
    LookupPageID = "VAT Statement Template List";
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
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    "Page ID" := PAGE::"VAT Statement";
                "VAT Statement Report ID" := REPORT::"VAT Statement";
            end;
        }
        field(7; "VAT Statement Report ID"; Integer)
        {
            Caption = 'VAT Statement Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "VAT Statement Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("VAT Statement Report ID")));
            Caption = 'VAT Statement Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11760; "XML Format"; Option)
        {
            Caption = 'XML Format';
            OptionCaption = 'DPHDP2,DPHDP3';
            OptionMembers = DPHDP2,DPHDP3;
        }
        field(11761; "Allow Comments/Attachments"; Boolean)
        {
            Caption = 'Allow Comments/Attachments';

            trigger OnValidate()
            begin
                if not "Allow Comments/Attachments" then
                    if not Confirm(Text1220000, false, TableCaption, Name) then
                        "Allow Comments/Attachments" := true
                    else
                        DeleteAllCommentsAttachments;
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
        VATStmtLine.SetRange("Statement Template Name", Name);
        VATStmtLine.DeleteAll;
        VATStmtName.SetRange("Statement Template Name", Name);
        VATStmtName.DeleteAll;
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        VATStmtName: Record "VAT Statement Name";
        VATStmtLine: Record "VAT Statement Line";
        Text1220000: Label 'This will delete all Comments/Attachments related to %1 %2. Do you want to continue?';

    local procedure DeleteAllCommentsAttachments()
    var
        CommentLine: Record "VAT Statement Comment Line";
        Attachment: Record "VAT Statement Attachment";
    begin
        // NAVCZ
        CommentLine.SetRange("VAT Statement Template Name", Name);
        CommentLine.DeleteAll;
        Attachment.SetRange("VAT Statement Template Name", Name);
        Attachment.DeleteAll;
    end;
}

