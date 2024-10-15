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
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account";
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
        field(11700; "No. of Match to Doc. No."; Integer)
        {
            Caption = 'No. of Match to Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(11701; "No. of Match to V. Symbol"; Integer)
        {
            Caption = 'No. of Match to V. Symbol';
            DataClassification = SystemMetadata;
        }
        field(11702; "No. of Match to S. Symbol"; Integer)
        {
            Caption = 'No. of Match to S. Symbol';
            DataClassification = SystemMetadata;
        }
        field(11703; "No. of Match to C. Symbol"; Integer)
        {
            Caption = 'No. of Match to C. Symbol';
            DataClassification = SystemMetadata;
        }
        field(30000; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(31001; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
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

    procedure AddMatchCandidate(LineNo: Integer; EntryNo: Integer; NewQuality: Integer; Type: Option; AccountNo: Code[20])
    var
        BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer";
    begin
        BankStatementMatchingBuffer.Init;
        BankStatementMatchingBuffer."Line No." := LineNo;
        BankStatementMatchingBuffer."Entry No." := EntryNo;
        BankStatementMatchingBuffer."Account No." := AccountNo;
        BankStatementMatchingBuffer."Account Type" := Type;
        BankStatementMatchingBuffer.Quality := NewQuality;
        if Get(LineNo, EntryNo, Type, AccountNo) then begin
            Rec := BankStatementMatchingBuffer;
            Modify
        end else begin
            Rec := BankStatementMatchingBuffer;
            Insert
        end;
    end;

    procedure AddMatchCandidateForAdvanceLetter(LineNo: Integer; Quality2: Integer; Type: Option; AccountNo: Code[20]; LetterNo: Code[20])
    var
        EntryNo: Integer;
    begin
        // NAVCZ
        EntryNo := AdvanceLetterOffset;

        Reset;
        SetRange("Line No.", LineNo);
        SetFilter("Entry No.", '%1..', EntryNo);
        if FindLast then
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

    procedure InsertOrUpdateOneToManyRule(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; RelatedPartyMatched: Option; AccountType: Option; RemainingAmount: Decimal; BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
        Init;
        SetRange("Line No.", LineNo);
        SetRange("Account Type", AccountType);
        SetRange("Account No.", TempLedgerEntryMatchingBuffer."Account No.");
        SetRange("Entry No.", -1);
        SetRange("One to Many Match", true);

        if not FindFirst then begin
            "Line No." := LineNo;
            "Account Type" := AccountType;
            "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
            "Entry No." := -1;
            "One to Many Match" := true;
            "No. of Entries" := 1;
            "Related Party Matched" := RelatedPartyMatched;
            UpdateMatchCounters(BankPmtApplRule); // NAVCZ
            Insert;
        end else begin // NAVCZ
            "No. of Entries" += 1;
            UpdateMatchCounters(BankPmtApplRule); // NAVCZ
        end; // NAVCZ

        "Total Remaining Amount" += RemainingAmount;
        Modify(true);
    end;

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
}

