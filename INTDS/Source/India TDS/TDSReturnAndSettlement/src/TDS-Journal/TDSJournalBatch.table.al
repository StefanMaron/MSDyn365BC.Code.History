table 18746 "TDS Journal Batch"
{
    Caption = 'Tax Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageId = "TDS Journal Batches";
    DrillDownPageId = "TDS Journal Batches";
    Extensible = true;
    Access = Public;
    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "TDS Journal Template";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    ModifyLines(FIELDNO("Reason Code"));
                    MODIFY();
                end;
            end;
        }
        field(5; "Bal. Account Type"; Enum "TDS Bal. Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(6; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = CONST(Customer)) Customer
            else
            if ("Bal. Account Type" = CONST(Vendor)) Vendor
            else
            if ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" THEN
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        field(7; "No. Series"; Code[10])
        {
            Caption = 'No. Series';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    TDSJnlTemplate.GET("Journal Template Name");
                    if "No. Series" = "Posting No. Series" THEN
                        VALIDATE("Posting No. Series", '');
                end;
            end;
        }
        field(8; "Posting No. Series"; Code[10])
        {
            Caption = 'Posting No. Series';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") AND ("Posting No. Series" <> '') THEN
                    FIELDERROR("Posting No. Series", STRSUBSTNO(PostingNoSeriesErr, "Posting No. Series"));
                ModifyLines(FIELDNO("Posting No. Series"));
                MODIFY();
            end;
        }
        field(9; "Template Type"; Enum "TDS Template Type")
        {
            CalcFormula = Lookup ("TDS Journal Template".Type WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location;

            trigger OnValidate()
            begin
                if "Location Code" <> xRec."Location Code" then begin
                    ModifyLinesVouchers(FIELDNO("Location Code"));
                    MODIFY();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    var
        TDSJnlTemplate: Record "TDS Journal Template";
        TDSJnlLine: Record "TDS Journal Line";
        PostingNoSeriesErr: Label 'must not be %1', Comment = '%1 = Posting No. Series ';

    trigger OnDelete()
    begin
        TDSJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
        TDSJnlLine.SETRANGE("Journal Batch Name", Name);
        TDSJnlLine.DELETEALL(TRUE);
    end;

    trigger OnInsert()
    begin
        LOCKTABLE();
        TDSJnlTemplate.GET("Journal Template Name");
    end;

    procedure SetupNewBatch()
    begin
        TDSJnlTemplate.GET("Journal Template Name");
        "Bal. Account Type" := TDSJnlTemplate."Bal. Account Type";
        "Bal. Account No." := TDSJnlTemplate."Bal. Account No.";
        "No. Series" := TDSJnlTemplate."No. Series";
        "Posting No. Series" := TDSJnlTemplate."Posting No. Series";
        "Reason Code" := TDSJnlTemplate."Reason Code";
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.GET(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TESTFIELD("Direct Posting", TRUE);
        end;
    end;

    procedure ModifyLines(i: Integer)
    begin
        TDSJnlLine.LOCKTABLE();
        TDSJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
        TDSJnlLine.SETRANGE("Journal Batch Name", Name);
        if TDSJnlLine.FindSet() then
            repeat
                case i of
                    FIELDNO("Reason Code"):
                        TDSJnlLine.VALIDATE("Reason Code", "Reason Code");
                    FIELDNO("Posting No. Series"):
                        TDSJnlLine.VALIDATE("Posting No. Series", "Posting No. Series");
                end;
                TDSJnlLine.MODIFY(TRUE);
            until TDSJnlLine.NEXT() = 0;
    end;

    procedure ModifyLinesVouchers(CurrFieldNo: Integer)
    begin
        TDSJnlLine.LOCKTABLE();
        TDSJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
        TDSJnlLine.SETRANGE("Journal Batch Name", Name);
        if TDSJnlLine.FINDFIRST() then
            case CurrFieldNo of
                FIELDNO("Location Code"):
                    TDSJnlLine.MODIFYALL("Location Code", "Location Code");
                FIELDNO("Posting No. Series"):
                    TDSJnlLine.MODIFYALL("Posting No. Series", "Posting No. Series");
            end;
    end;
}

