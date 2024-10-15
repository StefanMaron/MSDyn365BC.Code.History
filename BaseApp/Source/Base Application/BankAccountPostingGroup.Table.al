table 277 "Bank Account Posting Group"
{
    Caption = 'Bank Account Posting Group';
    DrillDownPageID = "Bank Account Posting Groups";
    LookupPageID = "Bank Account Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "G/L Bank Account No."; Code[20])
        {
            Caption = 'G/L Bank Account No.';
            ObsoleteReason = 'Moved to G/L Account No.';
            ObsoleteTag = '15.0';
            ObsoleteState = Pending;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("G/L Bank Account No.");
            end;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("G/L Account No.");
            end;
        }
        field(7000000; "Liabs. for Disc. Bills Acc."; Code[20])
        {
            Caption = 'Liabs. for Disc. Bills Acc.';
            TableRelation = "G/L Account";
        }
        field(7000001; "Bank Services Acc."; Code[20])
        {
            Caption = 'Bank Services Acc.';
            TableRelation = "G/L Account";
        }
        field(7000002; "Discount Interest Acc."; Code[20])
        {
            Caption = 'Discount Interest Acc.';
            TableRelation = "G/L Account";
        }
        field(7000003; "Rejection Expenses Acc."; Code[20])
        {
            Caption = 'Rejection Expenses Acc.';
            TableRelation = "G/L Account";
        }
        field(7000004; "Liabs. for Factoring Acc."; Code[20])
        {
            Caption = 'Liabs. for Factoring Acc.';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "G/L Account No.")
        {
        }
        fieldgroup(Brick; "Code")
        {
        }
    }

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
        end;
    end;

    procedure GetGLBankAccountNo(): Code[20]
    begin
        TestField("G/L Account No.");
        exit("G/L Account No.");
    end;
}

