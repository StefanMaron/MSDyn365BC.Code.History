table 1250 "Bank Statement Matching Buffer"
{
    Caption = 'Bank Statement Matching Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; Quality; Integer)
        {
            Caption = 'Quality';
            DataClassification = SystemMetadata;
        }
        field(4; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(10; "One to Many Match"; Boolean)
        {
            Caption = 'One to Many Match';
            DataClassification = SystemMetadata;
        }
        field(11; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
            DataClassification = SystemMetadata;
        }
        field(12; "Total Remaining Amount"; Decimal)
        {
            Caption = 'Total Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(13; "Related Party Matched"; Option)
        {
            Caption = 'Related Party Matched';
            DataClassification = SystemMetadata;
            OptionCaption = 'Not Considered,Fully,Partially,No';
            OptionMembers = "Not Considered",Fully,Partially,No;
        }
        field(14; "Match Details"; Text[250])
        {
            Caption = 'Match Details';
            DataClassification = SystemMetadata;
        }
        field(13600; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: DescriptionBankStatment';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(13601; "Match Status"; Option)
        {
            Caption = 'Match Status';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: MatchStatus';
            ObsoleteState = Removed;
            OptionCaption = ' ,NoMatch,Duplicate,IsPaid,Partial,Extra,Fully';
            OptionMembers = " ",NoMatch,Duplicate,IsPaid,Partial,Extra,Fully;
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "Line No.", "Entry No.", "Account Type", "Account No.")
        {
            Clustered = true;
        }
        key(Key2; Quality, "No. of Entries")
        {
        }
    }

    fieldgroups
    {
    }

    procedure AddMatchCandidate(LineNo: Integer; EntryNo: Integer; NewQuality: Integer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer";
    begin
        BankStatementMatchingBuffer.Init();
        BankStatementMatchingBuffer."Line No." := LineNo;
        BankStatementMatchingBuffer."Entry No." := EntryNo;
        BankStatementMatchingBuffer."Account No." := AccountNo;
        BankStatementMatchingBuffer."Account Type" := AccountType;
        BankStatementMatchingBuffer.Quality := NewQuality;
        if Get(LineNo, EntryNo, AccountType, AccountNo) then begin
            Rec := BankStatementMatchingBuffer;
            Modify
        end else begin
            Rec := BankStatementMatchingBuffer;
            Insert
        end;
    end;

    procedure InsertOrUpdateOneToManyRule(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; RelatedPartyMatched: Option; AccountType: Enum "Gen. Journal Account Type"; RemainingAmount: Decimal)
    begin
        Init;
        SetRange("Line No.", LineNo);
        SetRange("Account Type", AccountType);
        SetRange("Account No.", TempLedgerEntryMatchingBuffer."Account No.");
        SetRange("Entry No.", -1);
        SetRange("One to Many Match", true);

        if not FindFirst() then begin
            "Line No." := LineNo;
            "Account Type" := AccountType;
            "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
            "Entry No." := -1;
            "One to Many Match" := true;
            "No. of Entries" := 1;
            "Related Party Matched" := RelatedPartyMatched;
            Insert;
        end else
            "No. of Entries" += 1;

        "Total Remaining Amount" += RemainingAmount;
        Modify(true);
    end;
}

