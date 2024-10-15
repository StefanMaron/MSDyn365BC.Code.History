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
        field(11700; "No. of Match to Doc. No."; Integer)
        {
            Caption = 'No. of Match to Doc. No.';
            DataClassification = SystemMetadata;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11701; "No. of Match to V. Symbol"; Integer)
        {
            Caption = 'No. of Match to V. Symbol';
            DataClassification = SystemMetadata;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11702; "No. of Match to S. Symbol"; Integer)
        {
            Caption = 'No. of Match to S. Symbol';
            DataClassification = SystemMetadata;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11703; "No. of Match to C. Symbol"; Integer)
        {
            Caption = 'No. of Match to C. Symbol';
            DataClassification = SystemMetadata;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(30000; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(31001; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
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

#if not CLEAN19
    [Obsolete('Merge to W1.', '19.0')]
    procedure AddMatchCandidateForAdvanceLetter(LineNo: Integer; Quality2: Integer; Type: Option; AccountNo: Code[20]; LetterNo: Code[20])
    var
        EntryNo: Integer;
    begin
        // NAVCZ
        EntryNo := AdvanceLetterOffset;

        Reset;
        SetRange("Line No.", LineNo);
        SetFilter("Entry No.", '%1..', EntryNo);
        if FindLast() then
            EntryNo := "Entry No." + 1;

        AddMatchCandidate(LineNo, EntryNo, Quality2, Type, AccountNo);

        case Type of
            "Account Type"::Customer:
                "Letter Type" := "Letter Type"::Sales;
            "Account Type"::Vendor:
                "Letter Type" := "Letter Type"::Purchase;
        end;

        "Letter No." := LetterNo;
        Modify;
    end;

#endif
#if CLEAN19
    procedure InsertOrUpdateOneToManyRule(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; RelatedPartyMatched: Option; AccountType: Enum "Gen. Journal Account Type"; RemainingAmount: Decimal)
#else
    [Obsolete('Merge to W1.', '19.0')]
    procedure InsertOrUpdateOneToManyRule(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; RelatedPartyMatched: Option; AccountType: Enum "Gen. Journal Account Type"; RemainingAmount: Decimal; BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
#endif
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
#if not CLEAN19
            UpdateMatchCounters(BankPmtApplRule); // NAVCZ
#endif
            Insert;
#if CLEAN19
        end else
            "No. of Entries" += 1;
#else
        end else begin // NAVCZ
            "No. of Entries" += 1;
            UpdateMatchCounters(BankPmtApplRule); // NAVCZ
        end; // NAVCZ
#endif

        "Total Remaining Amount" += RemainingAmount;
        Modify(true);
    end;
#if not CLEAN19

    [Obsolete('Merge to W1.', '19.0')]
    procedure InsertOrUpdateOneToManyRuleForAdvanceLetter(TempAdvanceLetterMatchingBuffer: Record "Advance Letter Matching Buffer" temporary; BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; LineNo: Integer; AccountType: Option; RemainingAmount: Decimal)
    var
        TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
    begin
        // NAVCZ
        TempLedgerEntryMatchingBuffer."Account No." := TempAdvanceLetterMatchingBuffer."Account No.";
        InsertOrUpdateOneToManyRule(
          TempLedgerEntryMatchingBuffer, LineNo, BankPmtApplRule."Related Party Matched",
          AccountType, RemainingAmount, BankPmtApplRule);
    end;

    [Obsolete('Merge to W1.', '19.0')]
    procedure AdvanceLetterOffset(): Integer
    begin
        // NAVCZ
        exit(1000000000);
    end;

    local procedure UpdateMatchCounters(BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
        // NAVCZ
        if BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" = BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes then
            "No. of Match to Doc. No." += 1;
        if BankPmtApplRule."Variable Symbol Matched" = BankPmtApplRule."Variable Symbol Matched"::Yes then
            "No. of Match to V. Symbol" += 1;
        if BankPmtApplRule."Specific Symbol Matched" = BankPmtApplRule."Specific Symbol Matched"::Yes then
            "No. of Match to S. Symbol" += 1;
        if BankPmtApplRule."Constant Symbol Matched" = BankPmtApplRule."Constant Symbol Matched"::Yes then
            "No. of Match to C. Symbol" += 1;
    end;
#endif
}

