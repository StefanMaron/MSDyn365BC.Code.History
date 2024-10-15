namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

table 980 "Payment Registration Setup"
{
    Caption = 'Payment Registration Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                "Journal Batch Name" := '';
            end;
        }
        field(3; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));

            trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
            begin
                if not GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                    exit;

                case GenJournalBatch."Bal. Account Type" of
                    GenJournalBatch."Bal. Account Type"::"G/L Account":
                        Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
                    GenJournalBatch."Bal. Account Type"::"Bank Account":
                        Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                    else
                        Validate("Bal. Account Type", "Bal. Account Type"::" ");
                end;

                if GenJournalBatch."Bal. Account No." <> '' then
                    Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
            end;
        }
        field(4; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = ' ,G/L Account,Bank Account';
            OptionMembers = " ","G/L Account","Bank Account";

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(5; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(6; "Use this Account as Def."; Boolean)
        {
            Caption = 'Use this Account as Def.';
            InitValue = true;
        }
        field(7; "Auto Fill Date Received"; Boolean)
        {
            Caption = 'Auto Fill Date Received';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        ValidateMandatoryFields(true);
    end;

    procedure GetGLBalAccountType(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TestField("Bal. Account Type");
        case "Bal. Account Type" of
            "Bal. Account Type"::"Bank Account":
                exit(GenJnlLine."Bal. Account Type"::"Bank Account".AsInteger());
            "Bal. Account Type"::"G/L Account":
                exit(GenJnlLine."Bal. Account Type"::"G/L Account".AsInteger());
        end;
    end;

    procedure ValidateMandatoryFields(ShowError: Boolean): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if ShowError then begin
            TestField("Journal Template Name");
            TestField("Journal Batch Name");

            TestField("Bal. Account Type");
            TestField("Bal. Account No.");

            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            exit(true);
        end;

        if "Journal Template Name" = '' then
            exit(false);

        if "Journal Batch Name" = '' then
            exit(false);

        if "Bal. Account Type" = "Bal. Account Type"::" " then
            exit(false);

        if "Bal. Account No." = '' then
            exit(false);

        if not GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(false);

        if GenJnlBatch."No. Series" = '' then
            exit(false);

        exit(true);
    end;
}

