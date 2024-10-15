namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

table 1249 "Bank Stmt Multiple Match Line"
{
    Caption = 'Bank Stmt Multiple Match Line';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
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
        field(30000; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31001; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
    }

    keys
    {
        key(Key1; "Line No.", "Entry No.", "Account Type", "Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertLine(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
        "Line No." := LineNo;
        "Account Type" := AccountType.AsInteger();
        "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
        "Entry No." := TempLedgerEntryMatchingBuffer."Entry No.";
        "Due Date" := TempLedgerEntryMatchingBuffer."Due Date";
        "Document No." := TempLedgerEntryMatchingBuffer."Document No.";
        OnInsertLineOnBeforeInsert(Rec, TempLedgerEntryMatchingBuffer, LineNo, AccountType);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnBeforeInsert(var BankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
    end;
}

