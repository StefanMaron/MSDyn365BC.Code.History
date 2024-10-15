namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.GeneralLedger.Account;

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
            ObsoleteState = Removed;
            ObsoleteTag = '20.0';
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
        field(11000000; "Acc.No. Pmt./Rcpt. in Process"; Code[20])
        {
            Caption = 'Acc.No. Pmt./Rcpt. in Process';
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if "Acc.No. Pmt./Rcpt. in Process" <> '' then begin
                    GLAccount.Get("Acc.No. Pmt./Rcpt. in Process");
                    GLAccount.TestField(GLAccount."Account Type", GLAccount."Account Type"::Posting);
                    GLAccount.TestField(GLAccount."Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");

                    if GLAccount."Direct Posting" then
                        Message(Text1000000 + Text1000001, GLAccount."No.", GLAccount.FieldCaption(GLAccount."Direct Posting"));
                end;
            end;
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

    var
        Text1000000: Label 'Manual posting is possible on General Ledger Account %1. ';
        Text1000001: Label 'This can be changed by turning off %2.';

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;
}

