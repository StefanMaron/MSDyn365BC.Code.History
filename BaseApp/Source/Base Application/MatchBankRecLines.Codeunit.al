codeunit 1252 "Match Bank Rec. Lines"
{

    trigger OnRun()
    begin
    end;

    var
        MatchSummaryMsg: Label '%1 reconciliation lines out of %2 are matched.\\';
        MatchDetailsTxt: Label 'This statement line matched the corresponding bank account ledger entry on the following fields: %1.', Comment = '%1 - a comma-separated list of field captions.';
        MatchedManuallyTxt: Label 'This statement line was matched manually.';
        MissingMatchMsg: Label 'Text shorter than %1 characters cannot be matched.';
        ProgressBarMsg: Label 'Please wait while the operation is being completed.';
        ManyToManyNotSupportedErr: Label 'Many-to-Many matchings are not supported';
        OverwriteExistingMatchesTxt: Label 'There are lines in this statement that are already matched with ledger entries.\\ Do you want to overwrite the existing matches?';
        Relation: Option "One-to-One","One-to-Many","Many-to-One";
        MatchLengthTreshold: Integer;
        NormalizingFactor: Integer;

    procedure MatchManually(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var SelectedBankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        SelectedBankAccLECount: Integer;
        SelectedBankAccRecLinesCount: Integer;
    begin
        SelectedBankAccLECount := SelectedBankAccountLedgerEntry.Count();
        SelectedBankAccRecLinesCount := SelectedBankAccReconciliationLine.Count();

        if SelectedBankAccLECount > 1 then
            if SelectedBankAccRecLinesCount > 1 then
                Error(ManyToManyNotSupportedErr);

        if SelectedBankAccLECount >= SelectedBankAccRecLinesCount then
            PerformOneToOneOrManyMatch(SelectedBankAccReconciliationLine, SelectedBankAccountLedgerEntry, Relation::"One-to-Many")
        else
            PerformManyToOneMatch(SelectedBankAccReconciliationLine, SelectedBankAccountLedgerEntry);
    end;

    local procedure PerformManyToOneMatch(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var SelectedBankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
    begin
        if SelectedBankAccountLedgerEntry.FindFirst() then begin
            BankAccountLedgerEntry.Get(SelectedBankAccountLedgerEntry."Entry No.");
            BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);

            if SelectedBankAccReconciliationLine.FindSet() then
                repeat
                    BankAccReconciliationLine.GetBySystemId(SelectedBankAccReconciliationLine.SystemId);
                    if BankAccReconciliationLine.Type <> BankAccReconciliationLine.Type::"Bank Account Ledger Entry" then
                        exit;

                    BankAccEntrySetReconNo.ApplyEntries(BankAccReconciliationLine, BankAccountLedgerEntry, Relation::"Many-to-One");
                    PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine, MatchedManuallyTxt);

                until SelectedBankAccReconciliationLine.Next() = 0;
        end;
    end;

    local procedure PerformOneToOneOrManyMatch(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var SelectedBankAccountLedgerEntry: Record "Bank Account Ledger Entry"; Relation: Option "One-to-One","One-to-Many","Many-to-One")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
    begin
        if SelectedBankAccReconciliationLine.FindFirst then begin
            BankAccReconciliationLine.Get(
              SelectedBankAccReconciliationLine."Statement Type",
              SelectedBankAccReconciliationLine."Bank Account No.",
              SelectedBankAccReconciliationLine."Statement No.",
              SelectedBankAccReconciliationLine."Statement Line No.");
            if BankAccReconciliationLine.Type <> BankAccReconciliationLine.Type::"Bank Account Ledger Entry" then
                exit;

            if SelectedBankAccountLedgerEntry.FindSet then begin
                repeat
                    BankAccountLedgerEntry.Get(SelectedBankAccountLedgerEntry."Entry No.");
                    BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);
                    BankAccEntrySetReconNo.ApplyEntries(BankAccReconciliationLine, BankAccountLedgerEntry, Relation);
                    PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine, MatchedManuallyTxt);
                until SelectedBankAccountLedgerEntry.Next() = 0;
            end;
        end;
    end;

    local procedure RemoveMatchesFromRecLines(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
        CheckEntrySetReconNo: Codeunit "Check Entry Set Recon.-No.";
    begin
        if SelectedBankAccReconciliationLine.FindSet() then
            repeat
                BankAccReconciliationLine.Get(
                  SelectedBankAccReconciliationLine."Statement Type",
                  SelectedBankAccReconciliationLine."Bank Account No.",
                  SelectedBankAccReconciliationLine."Statement No.",
                  SelectedBankAccReconciliationLine."Statement Line No.");

                case BankAccReconciliationLine.Type of
                    BankAccReconciliationLine.Type::"Bank Account Ledger Entry":
                        begin
                            BankAccountLedgerEntry.SetCurrentKey("Bank Account No.", Open);
                            BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
                            BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
                            BankAccountLedgerEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                            BankAccountLedgerEntry.SetRange(Open, true);
                            BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
                            if BankAccountLedgerEntry.FindSet() then
                                repeat
                                    BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);
                                until BankAccountLedgerEntry.Next() = 0;

                            BankAccountLedgerEntry.Reset();
                            BankAccReconciliationLine.FilterManyToOneMatches(BankAccRecMatchBuffer);
                            if BankAccRecMatchBuffer.FindSet() then
                                repeat
                                    BankAccountLedgerEntry.Get(BankAccRecMatchBuffer."Ledger Entry No.");
                                    BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);
                                until BankAccRecMatchBuffer.Next() = 0;
                        end;
                    BankAccReconciliationLine.Type::"Check Ledger Entry":
                        begin
                            CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
                            CheckLedgEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
                            CheckLedgEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
                            CheckLedgEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
                            CheckLedgEntry.SetRange("Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
                            CheckLedgEntry.SetRange(Open, true);
                            if CheckLedgEntry.FindSet() then
                                repeat
                                    CheckEntrySetReconNo.RemoveApplication(CheckLedgEntry);
                                until CheckLedgEntry.Next() = 0;
                        end;
                end;
            until SelectedBankAccReconciliationLine.Next() = 0;
    end;

    procedure RemoveMatch(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var SelectedBankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
        CheckEntrySetReconNo: Codeunit "Check Entry Set Recon.-No.";
    begin
        RemoveMatchesFromRecLines(SelectedBankAccReconciliationLine);

        if SelectedBankAccountLedgerEntry.FindSet() then
            repeat
                case SelectedBankAccountLedgerEntry."Statement Status" of
                    SelectedBankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied":
                        begin
                            BankAccountLedgerEntry.Get(SelectedBankAccountLedgerEntry."Entry No.");
                            BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);
                        end;
                    SelectedBankAccountLedgerEntry."Statement Status"::"Check Entry Applied":
                        begin
                            CheckLedgEntry.Reset();
                            CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                            CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", SelectedBankAccountLedgerEntry."Entry No.");
                            CheckLedgEntry.SetRange(Open, true);
                            if CheckLedgEntry.FindSet() then
                                repeat
                                    CheckEntrySetReconNo.RemoveApplication(CheckLedgEntry);
                                until CheckLedgEntry.Next() = 0;
                        end;
                end;
            until SelectedBankAccountLedgerEntry.Next() = 0;
    end;

    procedure MatchSingle(BankAccReconciliation: Record "Bank Acc. Reconciliation"; DateRange: Integer)
    var
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        ConfirmManagement: Codeunit "Confirm Management";
        BankRecMatchCandidates: Query "Bank Rec. Match Candidates";
        Window: Dialog;
        Score: Integer;
        CountMatchCandidates: Integer;
        AmountMatched: Boolean;
        DocumentNoMatched: Boolean;
        ExternalDocumentNoMatched: Boolean;
        TransactionDateMatched: Boolean;
        RelatedPartyMatched: Boolean;
        DescriptionMatched: Boolean;
        Overwrite: Boolean;
        ListOfMatchFields: Text;
        FilterDate: Date;
    begin
        TempBankStatementMatchingBuffer.DeleteAll();

        FilterDate := BankAccReconciliation.MatchCandidateFilterDate();

        BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
        BankAccReconciliationLine.SetFilter("Applied Entries", '<>%1', 0);
        if BankAccReconciliationLine.FindSet() then
            Overwrite := ConfirmManagement.GetResponseOrDefault(OverwriteExistingMatchesTxt, false);

        if not Overwrite then
            BankRecMatchCandidates.SetRange(Rec_Line_Applied_Entries, 0)
        else begin
            BankAccReconciliationLine.Reset();
            BankAccReconciliationLine.SetFilter("Bank Account No.", BankAccReconciliation."Bank Account No.");
            BankAccReconciliationLine.SetFilter("Statement No.", BankAccReconciliation."Statement No.");

            RemoveMatchesFromRecLines(BankAccReconciliationLine);
        end;

        Window.Open(ProgressBarMsg);
        CountMatchCandidates := 0;
        SetMatchLengthTreshold(4);
        SetNormalizingFactor(10);
        BankRecMatchCandidates.SetRange(Rec_Line_Bank_Account_No, BankAccReconciliation."Bank Account No.");
        BankRecMatchCandidates.SetRange(Rec_Line_Statement_No, BankAccReconciliation."Statement No.");


        if FilterDate <> 0D then
            BankRecMatchCandidates.SetFilter(Posting_Date, '<=' + Format(FilterDate));
        if BankRecMatchCandidates.Open then
            while BankRecMatchCandidates.Read do begin
                CountMatchCandidates += 1;
                Score := CalculateMatchScore(BankRecMatchCandidates, DateRange);

                if Score > 2 then begin
                    TempBankStatementMatchingBuffer.AddMatchCandidate(BankRecMatchCandidates.Rec_Line_Statement_Line_No,
                      BankRecMatchCandidates.Entry_No, Score, "Gen. Journal Account Type"::"G/L Account", '');

                    AmountMatched := (BankRecMatchCandidates.Rec_Line_Difference = BankRecMatchCandidates.Remaining_Amount);
                    TransactionDateMatched := (BankRecMatchCandidates.Rec_Line_Transaction_Date = BankRecMatchCandidates.Posting_Date);
                    RelatedPartyMatched := (GetDescriptionMatchScore(BankRecMatchCandidates.Rec_Line_RltdPty_Name, BankRecMatchCandidates.Description, BankRecMatchCandidates.Document_No, BankRecMatchCandidates.External_Document_No) > 0);
                    DocumentNoMatched := (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Description, BankRecMatchCandidates.Document_No, GetMatchLengthTreshold(), GetNormalizingFactor()) = GetNormalizingFactor()) or (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Transaction_Info, BankRecMatchCandidates.Document_No, GetMatchLengthTreshold(), GetNormalizingFactor()) = GetNormalizingFactor());
                    ExternalDocumentNoMatched := (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Description, BankRecMatchCandidates.External_Document_No, GetMatchLengthTreshold(), GetNormalizingFactor()) = GetNormalizingFactor()) or (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Transaction_Info, BankRecMatchCandidates.External_Document_No, GetMatchLengthTreshold(), GetNormalizingFactor()) = GetNormalizingFactor());
                    DescriptionMatched := (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Description, BankRecMatchCandidates.Description, GetMatchLengthTreshold(), GetNormalizingFactor()) >= 0.8 * GetNormalizingFactor()) or (RecordMatchMgt.CalculateStringNearness(BankRecMatchCandidates.Rec_Line_Transaction_Info, BankRecMatchCandidates.Description, GetMatchLengthTreshold(), GetNormalizingFactor()) >= 0.8 * GetNormalizingFactor());

                    ListOfMatchFields := ListOfMatchedFields(AmountMatched, DocumentNoMatched, ExternalDocumentNoMatched, TransactionDateMatched, RelatedPartyMatched, DescriptionMatched);
                    TempBankStatementMatchingBuffer."Match Details" := StrSubstNo(MatchDetailsTxt, ListOfMatchFields);
                    TempBankStatementMatchingBuffer.Modify();
                end;
            end;

        SaveOneToOneMatching(TempBankStatementMatchingBuffer, BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.");

        OnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates, TempBankStatementMatchingBuffer);

        Window.Close;
        ShowMatchSummary(BankAccReconciliation);
    end;

    local procedure ListOfMatchedFields(AmountMatched: Boolean; DocumentNoMatched: Boolean; ExternalDocumentNoMatched: Boolean; TransactionDateMatched: Boolean; RelatedPartyMatched: Boolean; DescriptionMatched: Boolean): Text
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ListOfFields: Text;
        Comma: Text;
    begin
        Comma := ', ';
        if AmountMatched then
            ListOfFields += BankAccountLedgerEntry.FieldCaption(BankAccountLedgerEntry."Remaining Amount");

        if DocumentNoMatched then begin
            if ListOfFields <> '' then
                ListOfFields += Comma;
            ListOfFields += BankAccountLedgerEntry.FieldCaption(BankAccountLedgerEntry."Document No.");
        end;

        if ExternalDocumentNoMatched then begin
            if ListOfFields <> '' then
                ListOfFields += Comma;
            ListOfFields += BankAccountLedgerEntry.FieldCaption(BankAccountLedgerEntry."External Document No.");
        end;

        if TransactionDateMatched then begin
            if ListOfFields <> '' then
                ListOfFields += Comma;
            ListOfFields += BankAccountLedgerEntry.FieldCaption(BankAccountLedgerEntry."Posting Date");
        end;

        if RelatedPartyMatched or DescriptionMatched then begin
            if ListOfFields <> '' then
                ListOfFields += Comma;
            ListOfFields += BankAccountLedgerEntry.FieldCaption(BankAccountLedgerEntry.Description);
        end;

        exit(ListOfFields);
    end;

    local procedure CalculateMatchScore(var BankRecMatchCandidates: Query "Bank Rec. Match Candidates"; DateRange: Integer): Integer
    var
        Score: Integer;
    begin
        if BankRecMatchCandidates.Rec_Line_Difference = BankRecMatchCandidates.Remaining_Amount then
            Score += 13;

        Score += GetDescriptionMatchScore(BankRecMatchCandidates.Rec_Line_Description, BankRecMatchCandidates.Description,
            BankRecMatchCandidates.Document_No, BankRecMatchCandidates.External_Document_No);

        Score += GetDescriptionMatchScore(BankRecMatchCandidates.Rec_Line_RltdPty_Name, BankRecMatchCandidates.Description,
            BankRecMatchCandidates.Document_No, BankRecMatchCandidates.External_Document_No);

        Score += GetDescriptionMatchScore(BankRecMatchCandidates.Rec_Line_Transaction_Info, BankRecMatchCandidates.Description,
            BankRecMatchCandidates.Document_No, BankRecMatchCandidates.External_Document_No);

        if BankRecMatchCandidates.Rec_Line_Transaction_Date <> 0D then
            case true of
                BankRecMatchCandidates.Rec_Line_Transaction_Date = BankRecMatchCandidates.Posting_Date:
                    Score += 1;
                Abs(BankRecMatchCandidates.Rec_Line_Transaction_Date - BankRecMatchCandidates.Posting_Date) > DateRange:
                    Score := 0;
            end;

        exit(Score);
    end;

    local procedure SaveOneToOneMatching(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetCurrentKey(Quality);
        TempBankStatementMatchingBuffer.Ascending(false);

        if TempBankStatementMatchingBuffer.FindSet then
            repeat
                BankAccountLedgerEntry.Get(TempBankStatementMatchingBuffer."Entry No.");
                BankAccReconciliationLine.Get(
                  BankAccReconciliationLine."Statement Type"::"Bank Reconciliation",
                  BankAccountNo, StatementNo,
                  TempBankStatementMatchingBuffer."Line No.");
                if BankAccEntrySetReconNo.ApplyEntries(BankAccReconciliationLine, BankAccountLedgerEntry, Relation::"One-to-One") then
                    PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine, TempBankStatementMatchingBuffer."Match Details");
            until TempBankStatementMatchingBuffer.Next() = 0;
    end;

    local procedure ShowMatchSummary(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        FinalText: Text;
        AdditionalText: Text;
        TotalCount: Integer;
        MatchedCount: Integer;
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange(Type, BankAccReconciliationLine.Type::"Bank Account Ledger Entry");
        TotalCount := BankAccReconciliationLine.Count();

        BankAccReconciliationLine.SetFilter("Applied Entries", '<>%1', 0);
        MatchedCount := BankAccReconciliationLine.Count();

        if MatchedCount < TotalCount then
            AdditionalText := StrSubstNo(MissingMatchMsg, Format(GetMatchLengthTreshold));
        FinalText := StrSubstNo(MatchSummaryMsg, MatchedCount, TotalCount) + AdditionalText;
        Message(FinalText);
    end;

    local procedure GetDescriptionMatchScore(BankRecDescription: Text; BankEntryDescription: Text; DocumentNo: Code[20]; ExternalDocumentNo: Code[35]): Integer
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Nearness: Integer;
        Score: Integer;
        MatchLengthTreshold: Integer;
        NormalizingFactor: Integer;
    begin
        BankRecDescription := RecordMatchMgt.Trim(BankRecDescription);
        BankEntryDescription := RecordMatchMgt.Trim(BankEntryDescription);

        MatchLengthTreshold := GetMatchLengthTreshold;
        NormalizingFactor := GetNormalizingFactor;
        Score := 0;

        Nearness := RecordMatchMgt.CalculateStringNearness(BankRecDescription, DocumentNo,
            MatchLengthTreshold, NormalizingFactor);
        if Nearness = NormalizingFactor then
            Score += 11;

        Nearness := RecordMatchMgt.CalculateStringNearness(BankRecDescription, ExternalDocumentNo,
            MatchLengthTreshold, NormalizingFactor);
        if Nearness = NormalizingFactor then
            Score += Nearness;

        Nearness := RecordMatchMgt.CalculateStringNearness(BankRecDescription, BankEntryDescription,
            MatchLengthTreshold, NormalizingFactor);
        if Nearness >= 0.8 * NormalizingFactor then
            Score += Nearness;

        exit(Score);
    end;

    procedure SetMatchLengthTreshold(NewMatchLengthThreshold: Integer)
    begin
        MatchLengthTreshold := NewMatchLengthThreshold;
    end;

    procedure SetNormalizingFactor(NewNormalizingFactor: Integer)
    begin
        NormalizingFactor := NewNormalizingFactor;
    end;

    local procedure GetMatchLengthTreshold(): Integer
    begin
        exit(MatchLengthTreshold);
    end;

    local procedure GetNormalizingFactor(): Integer
    begin
        exit(NormalizingFactor);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates: Integer; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    begin
    end;
}

