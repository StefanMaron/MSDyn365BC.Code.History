table 18869 "TCS Journal Batch"
{
    Caption = 'TCS Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageId = "TCS Journal Batches";
    DrillDownPageId = "TCS Journal Batches";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            NotBlank = true;
            TableRelation = "TCS Journal Template";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Name; Code[10])
        {
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; Description; Text[50])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Bal. Account Type"; Enum "Bal. Account Type")
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(5; "Bal. Account No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = If ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            Else
            If ("Bal. Account Type" = const(Customer)) Customer
            Else
            If ("Bal. Account Type" = const(Vendor)) Vendor
            Else
            If ("Bal. Account Type" = const("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                If "Bal. Account Type" = "Bal. Account Type"::"G/L Account" Then
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        field(6; "No. Series"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                TCSJnlTemplate: Record "TCS Journal Template";
            begin
                If "No. Series" <> '' Then Begin
                    TCSJnlTemplate.Get("Journal Template Name");
                    If "No. Series" = "Posting No. Series" Then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(7; "Posting No. Series"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                ValueErr: Label 'must not be %1', Comment = '%1=The value.';
            begin
                If ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') Then
                    FIELDError("Posting No. Series", STRSUBSTNO(ValueErr, "Posting No. Series"));
                ModifyLines(FieldNo("Posting No. Series"));
                Modify();
            end;
        }
        field(8; "Location Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location;

            trigger OnValidate()
            begin
                If "Location Code" <> xRec."Location Code" Then Begin
                    ModifyLinesVouchers(FieldNo("Location Code"));
                    Modify();
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

    trigger OnDelete()
    var
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", Name);
        TCSJnlLine.DeleteAll(True);
    end;

    trigger OnInsert()
    var
        TCSJnlTemplate: Record "TCS Journal Template";
    begin
        LockTable();
        TCSJnlTemplate.Get("Journal Template Name");
    end;

    procedure SetupNewBatch()
    var
        TCSJnlTemplate: Record "TCS Journal Template";
    begin
        TCSJnlTemplate.Get("Journal Template Name");
        "Bal. Account Type" := TCSJnlTemplate."Bal. Account Type";
        "Bal. Account No." := TCSJnlTemplate."Bal. Account No.";
        "No. Series" := TCSJnlTemplate."No. Series";
        "Posting No. Series" := TCSJnlTemplate."Posting No. Series";
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        If AccNo <> '' Then Begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Direct Posting", True);
        end;
    end;

    procedure ModifyLines(i: Integer)
    var
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.LockTable();
        TCSJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", Name);
        If TCSJnlLine.FindSet() Then
            repeat
                Case i Of
                    FieldNo("Posting No. Series"):
                        TCSJnlLine.Validate("Posting No. Series", "Posting No. Series");
                end;
                TCSJnlLine.Modify(True);
            until TCSJnlLine.Next() = 0;
    end;

    procedure ModifyLinesVouchers(CurrFieldNo: Integer)
    var
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.LockTable();
        TCSJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", Name);
        If TCSJnlLine.FindFirst() Then
            Case CurrFieldNo Of
                FieldNo("Location Code"):
                    TCSJnlLine.ModifyAll("Location Code", "Location Code");
                FieldNo("Posting No. Series"):
                    TCSJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
            end;
    end;
}