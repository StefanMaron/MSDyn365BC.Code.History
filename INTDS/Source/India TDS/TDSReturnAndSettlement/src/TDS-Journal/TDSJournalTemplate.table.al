table 18748 "TDS Journal Template"
{
    Caption = 'Tax Journal Template';
    Extensible = true;
    Access = Public;
    LookupPageId = "TDS Journal Template List";
    DrillDownPageId = "TDS Journal Template List";
    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Form ID"; Integer)
        {
            Caption = 'Form ID';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                IF "Form ID" = 0 THEN
                    VALIDATE(Type);
            end;
        }
        field(4; Type; Enum "TDS Template Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Type';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";

            trigger OnValidate()
            var
                TDSJnlLine: Record "TDS Journal Line";
            begin
                TDSJnlLine.SETRANGE("Journal Template Name", Name);
                TDSJnlLine.MODIFYALL("Source Code", "Source Code");
                Modify();
            end;
        }
        field(6; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Reason Code";
        }
        field(7; "Form Name"; Text[80])
        {
            Caption = 'Form Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Form ID")));
        }
        field(8; "Bal. Account Type"; enum "TDS Bal. Account Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bal. Account Type';
            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(9; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" = "Bal. Account Type"::"G/L Account" THEN
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        field(10; "No. Series"; Code[10])
        {
            Caption = 'No. Series';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                IF "No. Series" <> '' THEN
                    IF "No. Series" = "Posting No. Series" THEN
                        "Posting No. Series" := '';
            end;
        }
        field(11; "Posting No. Series"; Code[10])
        {
            Caption = 'Posting No. Series';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                PostingNoSeriesErr: Label 'must not be %1', Comment = '%1 = Posting No.Series';
            begin
                IF ("Posting No. Series" = "No. Series") AND ("Posting No. Series" <> '') THEN
                    FIELDERROR("Posting No. Series", STRSUBSTNO(PostingNoSeriesErr, "Posting No. Series"));
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
        fieldgroup(DropDown; Name, Description, Type)
        {
        }
    }
    trigger OnDelete()
    var
        TDSJnlBatch: Record "TDS Journal Batch";
        TDSJnlLine: Record "TDS Journal Line";
    begin
        TDSJnlLine.SETRANGE("Journal Template Name", Name);
        TDSJnlLine.DELETEALL(TRUE);
        TDSJnlBatch.SETRANGE("Journal Template Name", Name);
        TDSJnlBatch.DELETEALL();
    end;

    trigger OnInsert()
    begin
        VALIDATE("Form ID");
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' THEN begin
            GLAcc.GET(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TESTFIELD("Direct Posting", TRUE);
        end;
    end;
}

