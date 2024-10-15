table 31048 "Credits Setup"
{
    Caption = 'Credits Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Credit Nos."; Code[20])
        {
            Caption = 'Credit Nos.';
            TableRelation = "No. Series";
        }
        field(15; "Credit Bal. Account No."; Code[20])
        {
            Caption = 'Credit Bal. Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Credit Bal. Account No.", false, false);
            end;
        }
        field(20; "Max. Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Max. Rounding Amount';
        }
        field(25; "Debit Rounding Account"; Code[20])
        {
            Caption = 'Debit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Debit Rounding Account", false, false);
            end;
        }
        field(30; "Credit Rounding Account"; Code[20])
        {
            Caption = 'Credit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Credit Rounding Account", false, false);
            end;
        }
        field(35; "Credit Proposal By"; Option)
        {
            Caption = 'Credit Proposal By';
            OptionCaption = 'Registration No.,Bussiness Relation';
            OptionMembers = "Registration No.","Bussiness Relation";
        }
        field(40; "Show Empty when not Found"; Boolean)
        {
            Caption = 'Show Empty when not Found';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CheckGLAcc(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
            if CheckProdPostingGroup then
                GLAcc.TestField("Gen. Prod. Posting Group");
            if CheckDirectPosting then
                GLAcc.TestField("Direct Posting", true);
        end;
    end;
}

