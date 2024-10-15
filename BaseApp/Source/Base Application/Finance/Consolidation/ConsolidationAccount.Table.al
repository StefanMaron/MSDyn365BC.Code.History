namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment;

table 1829 "Consolidation Account"
{
    Caption = 'Consolidation Account';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Income/Balance"; Option)
        {
            Caption = 'Income/Balance';
            OptionCaption = 'Income Statement,Balance Sheet';
            OptionMembers = "Income Statement","Balance Sheet";
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure PopulateAccounts()
    begin
        InsertData('10100', 'Checking account', 1, true);
    end;

    local procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; IncomeBalance: Option; DirectPosting: Boolean)
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        ConsolidationAccount.Init();
        ConsolidationAccount.Validate("No.", AccountNo);
        ConsolidationAccount.Validate(Name, AccountName);
        ConsolidationAccount.Validate("Direct Posting", DirectPosting);
        ConsolidationAccount.Validate("Income/Balance", IncomeBalance);
        ConsolidationAccount.Insert();
    end;

    procedure PopulateConsolidationAccountsForExistingCompany(ConsolidatedCompany: Text[50])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.ChangeCompany(ConsolidatedCompany);
        GLAccount.Reset();
        GLAccount.SetFilter("Account Type", Format(GLAccount."Account Type"::Posting));
        if GLAccount.Find('-') then
            repeat
                InsertData(GLAccount."No.", GLAccount.Name, GLAccount."Income/Balance", GLAccount."Direct Posting");
            until GLAccount.Next() = 0;
    end;

    procedure ValidateCountry(CountryCode: Code[2]): Boolean
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        if StrPos(ApplicationSystemConstants.ApplicationVersion(), CountryCode) = 1 then
            exit(true);

        exit(false);
    end;
}

