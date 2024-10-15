table 2000000 "Payment Journal Template"
{
    Caption = 'Payment Journal Template';
    DataCaptionFields = Name;
    LookupPageID = "EB Payment Journal Templates";

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
                PaymentJnlLine.SetRange("Journal Template Name", Name);
                PaymentJnlLine.ModifyAll("Source Code", "Source Code");
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
        field(19; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
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
        PaymJnlBatch.SetRange("Journal Template Name", Name);
        PaymJnlBatch.DeleteAll(true);
        PaymentJnlLine.SetRange("Journal Template Name", Name);
        PaymentJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
        SourceCodeSetup.Get;
        "Source Code" := SourceCodeSetup."Payment Journal";
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
}

