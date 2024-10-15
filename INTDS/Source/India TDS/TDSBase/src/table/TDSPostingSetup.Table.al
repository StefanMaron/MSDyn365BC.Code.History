table 18691 "TDS Posting Setup"
{
    Caption = 'TDS Posting Setup';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "TDS Posting Setup";
    LookupPageId = "TDS Posting Setup";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "TDS Section"; Code[10])
        {
            Caption = 'TDS Section';
            TableRelation = "TDS Section";
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(2; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(3; "TDS Account"; Code[20])
        {
            Caption = 'TDS Account';
            TableRelation = "G/L Account";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                CheckGLAcc("TDS Account", true);
            end;
        }
        field(4; "Work Tax Account"; Code[20])
        {
            Caption = 'Work Tax Account';
            TableRelation = "G/L Account";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                CheckGLAcc("Work Tax Account", true);
            end;
        }
        field(5; "TDS Receivable Account"; Code[20])
        {
            Caption = 'TDS Receivable Account';
            TableRelation = "G/L Account";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                CheckGLAcc("TDS Receivable Account", true);
            end;
        }
    }

    keys
    {
        key(PK; "TDS Section", "Effective Date")
        {
            Clustered = true;
        }
    }

    local procedure CheckGLAcc(AccNo: code[20]; CheckDirectPosting: boolean)
    var
        GlAcc: Record "G/L Account";
    begin
        IF AccNo <> '' THEN BEGIN
            GLAcc.GET(AccNo);
            GLAcc.CheckGLAcc();
            IF CheckDirectPosting THEN
                GLAcc.TESTFIELD("Direct Posting", TRUE);
        end;
    end;
}