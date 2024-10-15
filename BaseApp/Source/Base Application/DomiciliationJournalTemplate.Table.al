table 2000020 "Domiciliation Journal Template"
{
    Caption = 'Domiciliation Journal Template';
    DataCaptionFields = Name;
    LookupPageID = "Domicil. Journal Templates";

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
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Page));
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                DomiciliationJnlLine.SetRange("Journal Template Name", Name);
                DomiciliationJnlLine.ModifyAll("Source Code", "Source Code");
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(15; "Test Report Name"; Text[80])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Test Report ID")));
            Caption = 'Test Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Name"; Text[80])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Page ID")));
            Caption = 'Page Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
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
        DomiciliationJnlBatch.SetRange("Journal Template Name", Name);
        DomiciliationJnlBatch.DeleteAll(true);
        DomiciliationJnlLine.SetRange("Journal Template Name", Name);
        DomiciliationJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
        SourceCodeSetup.Get;
        "Source Code" := SourceCodeSetup."Domiciliation Journal";
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        DomiciliationJnlBatch: Record "Domiciliation Journal Batch";
        DomiciliationJnlLine: Record "Domiciliation Journal Line";
}

