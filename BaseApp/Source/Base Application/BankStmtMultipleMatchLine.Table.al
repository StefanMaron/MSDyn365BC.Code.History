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
        }
        field(11701; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(11702; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
        }
        field(30000; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(31001; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
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
        // NAVCZ
        "Variable Symbol" := TempLedgerEntryMatchingBuffer."Variable Symbol";
        "Specific Symbol" := TempLedgerEntryMatchingBuffer."Specific Symbol";
        "Constant Symbol" := TempLedgerEntryMatchingBuffer."Constant Symbol";
        // NAVCZ
        Insert;
    end;

    [Scope('OnPrem')]
    procedure InsertLineForAdvanceLetter(AdvanceLetterMatchingBuffer: Record "Advance Letter Matching Buffer" temporary; LineNo: Integer; AccountType: Option)
    begin
        // NAVCZ
        "Line No." := LineNo;
        "Account Type" := AccountType;
        "Account No." := AdvanceLetterMatchingBuffer."Account No.";
        "Entry No." := GetNextEntryNo;
        "Due Date" := AdvanceLetterMatchingBuffer."Due Date";
        "Document No." := AdvanceLetterMatchingBuffer."Letter No.";
        "Letter Type" := AdvanceLetterMatchingBuffer."Letter Type";
        "Letter No." := AdvanceLetterMatchingBuffer."Letter No.";
        "Variable Symbol" := AdvanceLetterMatchingBuffer."Variable Symbol";
        "Specific Symbol" := AdvanceLetterMatchingBuffer."Specific Symbol";
        "Constant Symbol" := AdvanceLetterMatchingBuffer."Constant Symbol";
        Insert;
    end;

    local procedure GetNextEntryNo(): Integer
    var
        BankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line";
        EntryNo: Integer;
    begin
        // NAVCZ
        BankStmtMultipleMatchLine.Copy(Rec);
        Reset;
        SetRange("Line No.", "Line No.");
        SetRange("Account Type", "Account Type");
        SetRange("Account No.", "Account No.");
        SetFilter("Entry No.", '<=0');
        if FindFirst then
            EntryNo := "Entry No." - 1
        else
            EntryNo := -1;
        Copy(BankStmtMultipleMatchLine);
        exit(EntryNo);
    end;
}

