namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

table 1296 "Posted Payment Recon. Line"
{
    Caption = 'Posted Payment Recon. Line';
    PasteIsValid = false;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Posted Payment Recon. Hdr"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Amount';
        }
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Difference';
        }
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            Editable = false;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry,Difference';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry",Difference;
        }
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            Editable = false;
        }
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
        }
        field(14; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(15; "Related-Party Name"; Text[250])
        {
            Caption = 'Related-Party Name';
        }
        field(16; "Additional Transaction Info"; Text[100])
        {
            Caption = 'Additional Transaction Info';
        }
        field(17; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(18; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        field(23; "Applied Document No."; Text[250])
        {
            Caption = 'Applied Document No.';
        }
        field(24; "Applied Entry No."; Text[250])
        {
            Caption = 'Applied Entry No.';
        }
        field(70; "Transaction ID"; Text[250])
        {
            Caption = 'Transaction ID';
        }
        field(71; Reconciled; Boolean)
        {
            Caption = 'Reconciled';
        }
        field(11700; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11701; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11702; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11705; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11710; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11711; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11715; "Statement Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Statement Amount (LCY)';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11716; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11717; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11720; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,,,,,Refund';
            OptionMembers = " ",Payment,,,,,Refund;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11725; "Difference (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Difference (LCY)';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11726; "Applied Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount (LCY)';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31000; "Advance Letter Link Code"; Code[30])
        {
            Caption = 'Advance Letter Link Code';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc2: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc2."No." then
            exit(BankAcc2."Currency Code");

        if BankAcc2.Get("Bank Account No.") then
            exit(BankAcc2."Currency Code");

        exit('');
    end;
}

