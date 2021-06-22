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

    procedure InsertLine(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; AccountType: Option)
    begin
        "Line No." := LineNo;
        "Account Type" := AccountType;
        "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
        "Entry No." := TempLedgerEntryMatchingBuffer."Entry No.";
        "Due Date" := TempLedgerEntryMatchingBuffer."Due Date";
        "Document No." := TempLedgerEntryMatchingBuffer."Document No.";
        Insert;
    end;
}

