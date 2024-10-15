namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Security.AccessControl;

table 272 "Check Ledger Entry"
{
    Caption = 'Check Ledger Entry';
    DrillDownPageID = "Check Ledger Entries";
    LookupPageID = "Check Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        field(10; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(11; "Check Type"; Option)
        {
            Caption = 'Check Type';
            OptionCaption = 'Total Check,Partial Check';
            OptionMembers = "Total Check","Partial Check";
        }
        field(12; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
        }
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Printed,Voided,Posted,Financially Voided,Test Print,Exported,Transmitted';
            OptionMembers = ,Printed,Voided,Posted,"Financially Voided","Test Print",Exported,Transmitted;
        }
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Printed,Voided,Posted,Financially Voided';
            OptionMembers = " ",Printed,Voided,Posted,"Financially Voided";
        }
        field(15; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(24; "Data Exch. Voided Entry No."; Integer)
        {
            Caption = 'Data Exch. Voided Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(25; "Positive Pay Exported"; Boolean)
        {
            Caption = 'Positive Pay Exported';
        }
        field(26; "Record ID to Print"; RecordId)
        {
            Caption = 'Record ID to Print';
            DataClassification = SystemMetadata;
#if not CLEAN24            
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by Print Gen Jnl Line SystemId field';
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Print Gen Jnl Line SystemId field';
            ObsoleteTag = '27.0';
#endif
        }
        field(27; "Print Gen Jnl Line SystemId"; Guid)
        {
            Caption = 'SystemId to Print';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Check Date")
        {
        }
        key(Key3; "Bank Account No.", "Entry Status", "Check No.", "Statement Status")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Print Gen Jnl Line SystemId")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NothingToExportErr: Label 'There is nothing to export.';

    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Bank Account No." := BankAccLedgEntry."Bank Account No.";
        "Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        Description := BankAccLedgEntry.Description;
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
        "Entry Status" := "Entry Status"::Posted;
        Open := true;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Check Date" := BankAccLedgEntry."Posting Date";
        "Check No." := BankAccLedgEntry."Document No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    procedure ExportCheckFile()
    var
        BankAcc: Record "Bank Account";
    begin
        if not FindSet() then
            Error(NothingToExportErr);

        if not BankAcc.Get("Bank Account No.") then
            Error(NothingToExportErr);

        if BankAcc.GetPosPayExportCodeunitID() > 0 then
            CODEUNIT.Run(BankAcc.GetPosPayExportCodeunitID(), Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Pos. Pay", Rec);
    end;

    procedure GetPayee() Payee: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
    begin
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if "Bal. Account No." <> '' then begin
                    GLAccount.Get("Bal. Account No.");
                    Payee := GLAccount.Name;
                end;
            "Bal. Account Type"::Customer:
                if "Bal. Account No." <> '' then begin
                    Customer.Get("Bal. Account No.");
                    Payee := Customer.Name;
                end;
            "Bal. Account Type"::Vendor:
                if "Bal. Account No." <> '' then begin
                    Vendor.Get("Bal. Account No.");
                    Payee := Vendor.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                if "Bal. Account No." <> '' then begin
                    BankAccount.Get("Bal. Account No.");
                    Payee := BankAccount.Name;
                end;
            "Bal. Account Type"::"Fixed Asset":
                Payee := "Bal. Account No.";
            "Bal. Account Type"::Employee:
                if "Bal. Account No." <> '' then begin
                    Employee.Get("Bal. Account No.");
                    Payee := Employee.FullName();
                end;
        end;

        OnAfterGetPayee(Rec, Payee);
    end;

    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromBankAccLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPayee(CheckLedgerEntry: Record "Check Ledger Entry"; var Payee: Text[100])
    begin
    end;
}

