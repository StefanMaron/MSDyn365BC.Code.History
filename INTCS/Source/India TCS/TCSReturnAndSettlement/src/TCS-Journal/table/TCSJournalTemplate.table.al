table 18871 "TCS Journal Template"
{
    Caption = 'TCS Journal Template';
    LookupPageId = "TCS Journal Template List";
    DrillDownPageId = "TCS Journal Template List";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; Name; Code[10])
        {
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Description; Text[80])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Source Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
            trigger OnValidate()
            var
                TCSJnlLine: Record "TCS Journal Line";
            begin
                TCSJnlLine.SetRange("Journal Template Name", Name);
                TCSJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        field(4; "Form ID"; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Form Name"; Text[80])
        {
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Page),
                                                                           "Object ID" = FIELD("Form ID")));
        }
        field(6; "Bal. Account Type"; Enum "Bal. Account Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(7; "Bal. Account No."; Code[20])
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
        field(8; "No. Series"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                If "No. Series" <> '' Then
                    If "No. Series" = "Posting No. Series" Then
                        "Posting No. Series" := '';
            end;
        }
        field(9; "Posting No. Series"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                ValueErr: Label 'must not be %1', Comment = '%1=The value';
            begin
                If ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') Then
                    FieldError("Posting No. Series", STRSUBSTNO(ValueErr, "Posting No. Series"));
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
        fieldgroup(DropDown; Name, Description)
        {
        }
    }

    trigger OnDelete()
    var
        TCSJnlBatch: Record "TCS Journal Batch";
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.SetRange("Journal Template Name", Name);
        TCSJnlLine.DeleteAll(True);
        TCSJnlBatch.SetRange("Journal Template Name", Name);
        TCSJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Form ID", Page::"TCS Adjustment Journal");
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
}