table 18813 "TCS Posting Setup"
{
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "TCS Posting Setup";
    DrillDownPageId = "TCS Posting Setup";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "TCS Nature of Collection"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TCS Nature Of Collection";
            NotBlank = true;
        }

        field(2; "Effective Date"; Date)
        {
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(3; "TCS Account No."; code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("TCS Account No.", FALSE);
            end;
        }
    }

    keys
    {
        key(PK; "TCS Nature of Collection", "effective date")
        {
            Clustered = true;
        }
    }
    procedure CheckGLAcc(AccNo: code[20]; CheckDirectPosting: boolean)
    var
        GlAcc: Record "G/L Account";
    begin
        IF AccNo <> '' then begin
            GLAcc.GET(AccNo);
            GLAcc.CheckGLAcc();
            IF CheckDirectPosting then
                GLAcc.TestField("Direct Posting", TRUE);
        end;
    end;
}