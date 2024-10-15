namespace Microsoft.Bank.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Reconciliation;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.AccessControl;

table 271 "Bank Account Ledger Entry"
{
    Caption = 'Bank Account Ledger Entry';
    DrillDownPageID = "Bank Account Ledger Entries";
    LookupPageID = "Bank Account Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
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
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(22; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
        }
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(52; "Bal. Account No."; Code[20])
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
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(55; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(56; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(57; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(64; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(65; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(66; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(70; "Check Ledger Entries"; Integer)
        {
            CalcFormula = count("Check Ledger Entry" where("Bank Account Ledger Entry No." = field("Entry No.")));
            Caption = 'Check Ledger Entries';
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key3; "Bank Account No.", Open, "Posting Date", "Statement No.", "Statement Status", "Statement Line No.")
        {
        }
        key(Key4; "Document Type", "Bank Account No.", "Posting Date")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount;
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
        key(Key6; "Transaction No.")
        {
        }
        key(Key7; "Bank Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(key8; "Statement No.", "Statement Line No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Bank Account No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }
    trigger OnInsert()
    begin
        UpdateBankAccReconciliationLine();
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Bank Account No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Our Contact Code" := GenJnlLine."Salespers./Purch. Code";
        "Source Code" := GenJnlLine."Source Code";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "Currency Code" := GenJnlLine."Currency Code";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        if GenJnlLine."Linked Table ID" <> 0 then
            SetBankAccReconciliationLine(GenJnlLine);

        OnAfterCopyFromGenJnlLine(Rec, GenJnlLine);
    end;

    local procedure SetBankAccReconciliationLine(GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if GenJnlLine."Linked Table ID" <> Database::"Bank Acc. Reconciliation Line" then
            exit;
        if IsNullGuid(GenJnlLine."Linked System ID") then
            exit;
        if not BankAccReconciliationLine.GetBySystemId(GenJnlLine."Linked System ID") then
            exit;
        if "Bank Account No." <> BankAccReconciliationLine."Bank Account No." then
            exit;
        "Statement Status" := "Statement Status"::"Bank Acc. Entry Applied";
        "Statement No." := BankAccReconciliationLine."Statement No.";
        "Statement Line No." := BankAccReconciliationLine."Statement Line No.";
    end;

    local procedure UpdateBankAccReconciliationLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Statement No." = '' then
            exit;
        if not BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", "Bank Account No.", "Statement No.", "Statement Line No.") then
            exit;
        if (BankAccReconciliationLine."Statement Amount" = Amount) or (BankAccReconciliationLine.Difference = Amount) then begin
            BankAccReconciliationLine."Applied Amount" += Amount;
            BankAccReconciliationLine.Difference := BankAccReconciliationLine."Statement Amount" - BankAccReconciliationLine."Applied Amount";
            BankAccReconciliationLine."Applied Entries" += 1;
            BankAccReconciliationLine.Modify();
        end else begin
            "Statement Status" := "Statement Status"::Open;
            "Statement No." := '';
            "Statement Line No." := 0;
        end;
    end;

    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if (Amount > 0) and (not Correction) or
           (Amount < 0) and Correction
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0;
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0;
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;

        OnAfterUpdateDebitCredit(Rec, Correction);
    end;

    procedure GetAppliedStatementNo(): Code[20]
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", Rec."Bank Account No.");
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", Rec."Entry No.");
        CheckLedgerEntry.SetRange(Open, true);
        CheckLedgerEntry.SetRange("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
        CheckLedgerEntry.SetFilter("Statement No.", '<>%1', '');
        CheckLedgerEntry.SetFilter("Statement Line No.", '<>%1', 0);
        if not CheckLedgerEntry.IsEmpty() then
            exit(CheckLedgerEntry."Statement No.");

        if ((Rec."Statement Status" = Rec."Statement Status"::"Bank Acc. Entry Applied") and
           (Rec."Statement No." <> '') and (Rec."Statement Line No." <> 0)) then
            exit(Rec."Statement No.");

        exit('');
    end;

    procedure IsApplied(): Boolean
    begin
        exit(GetAppliedStatementNo() <> '');
    end;

    procedure SetStyle(): Text
    begin
        if IsApplied() then
            exit('Favorable');

        exit('');
    end;

    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    procedure CopyFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20])
    begin
        Init();
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        Description := BankAccountLedgerEntry.Description;
        Amount := BankAccountLedgerEntry.Amount;
        "Statement No." := StatementNo;
        Insert();
    end;

    procedure SetBankReconciliationCandidatesFilter(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        FilterDate: Date;
    begin
        Rec.Reset();
        Rec.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        Rec.SetRange("Statement Status", Rec."Statement Status"::Open);
        Rec.SetFilter("Remaining Amount", '<>%1', 0);
        Rec.SetRange("Reversed", false); // PR 30730

        FilterDate := BankAccReconciliation.MatchCandidateFilterDate();
        if FilterDate <> 0D then
            Rec.SetFilter("Posting Date", '<=%1', FilterDate);

        // Records sorted by posting date to optimize matching
        Rec.SetCurrentKey("Posting Date");
        Rec.SetAscending("Posting Date", true);

        OnAfterSetBankReconciliationCandidatesFilter(Rec);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromGenJnlLine(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDebitCredit(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; Correction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetBankReconciliationCandidatesFilter(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;
}

