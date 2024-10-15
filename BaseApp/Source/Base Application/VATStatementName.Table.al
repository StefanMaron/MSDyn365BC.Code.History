table 257 "VAT Statement Name"
{
    Caption = 'VAT Statement Name';
    LookupPageID = "VAT Statement Names";

    fields
    {
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            NotBlank = true;
            TableRelation = "VAT Statement Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(11760; Comments; Integer)
        {
            CalcFormula = Count("VAT Statement Comment Line" WHERE("VAT Statement Template Name" = FIELD("Statement Template Name"),
                                                                    "VAT Statement Name" = FIELD(Name)));
            Caption = 'Comments';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11761; Attachments; Integer)
        {
            CalcFormula = Count("VAT Statement Attachment" WHERE("VAT Statement Template Name" = FIELD("Statement Template Name"),
                                                                  "VAT Statement Name" = FIELD(Name)));
            Caption = 'Attachments';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11762; "Date Row Filter"; Date)
        {
            Caption = 'Date Row Filter';
            FieldClass = FlowFilter;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
    }

    keys
    {
        key(Key1; "Statement Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATStmtLine.SetRange("Statement Template Name", "Statement Template Name");
        VATStmtLine.SetRange("Statement Name", Name);
        VATStmtLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        VATStmtLine.SetRange("Statement Template Name", xRec."Statement Template Name");
        VATStmtLine.SetRange("Statement Name", xRec.Name);
        while VATStmtLine.FindFirst do
            VATStmtLine.Rename("Statement Template Name", Name, VATStmtLine."Line No.");
    end;

    var
        VATStmtLine: Record "VAT Statement Line";
}

