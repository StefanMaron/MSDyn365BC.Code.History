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
        BankAccountRecTotalAndMatchedLinesLbl: Label 'Total Bank Statement Lines: %1, of those applied: %2', Locked = true;
        AutomatchEventNameTelemetryTxt: Label 'Automatch', Locked = true;
        BankAccountRecCategoryLbl: Label 'AL Bank Account Rec', Locked = true;
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
        LineCount: Integer;
    begin
        if SelectedBankAccountLedgerEntry.FindFirst() then begin
            BankAccountLedgerEntry.Get(SelectedBankAccountLedgerEntry."Entry No.");
            BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);

            LineCount := SelectedBankAccReconciliationLine.Count();
            BankAccEntrySetReconNo.SetLineCount(LineCount);

            if SelectedBankAccReconciliationLine.FindSet() then
                repeat
                    BankAccReconciliationLine.GetBySystemId(SelectedBankAccReconciliationLine.SystemId);
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
        if SelectedBankAccReconciliationLine.FindFirst() then begin
            BankAccReconciliationLine.Get(
              SelectedBankAccReconciliationLine."Statement Type",
              SelectedBankAccReconciliationLine."Bank Account No.",
              SelectedBankAccReconciliationLine."Statement No.",
              SelectedBankAccReconciliationLine."Statement Line No.");

            if SelectedBankAccountLedgerEntry.FindSet() then
                repeat
                    BankAccountLedgerEntry.Get(SelectedBankAccountLedgerEntry."Entry No.");
                    BankAccEntrySetReconNo.RemoveApplication(BankAccountLedgerEntry);
                    BankAccEntrySetReconNo.ApplyEntries(BankAccReconciliationLine, BankAccountLedgerEntry, Relation);
                    PaymentMatchingDetails.CreatePaymentMatchingDetail(BankAccReconciliationLine, MatchedManuallyTxt);
                until SelectedBankAccountLedgerEntry.Next() = 0;
        end;
    end;

    procedure RemoveMatchesFromRecLines(var SelectedBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
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

#if not CLEAN21
    [Obsolete('Use BankAccReconciliationAutoMatch instead', '21.0')]
    procedure MatchSingle(BankAccReconciliation: Record "Bank Acc. Reconciliation"; DateRange: Integer)
    var
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        CountMatchCandidates: Integer;
    begin
        BankAccReconciliationAutoMatch(BankAccReconciliation, DateRange);
        OnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates, TempBankStatementMatchingBuffer);
    end;
#endif

    /// <summary>
    /// Algorithm for auto matching used in the Bank Acc. Reconciliation page.
    /// It updates matched Bank Account Ledger Entries by applying them and setting their Statement No., Statement Line No., etc.
    /// </summary>
    /// <param name="BankAccReconciliation"></param>
    /// <param name="DaysTolerance"></param>
    procedure BankAccReconciliationAutoMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; DaysTolerance: Integer)
    var
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary;
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ProgressDialog: Dialog;
        Overwrite: Boolean;
        RemovedPreviouslyAssigned: Boolean;
        BankAccRecLineCounter: Integer;
    begin
        FeatureTelemetry.LogUptake('0000JLB', BankAccReconciliation.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::Used);
        Overwrite := true;
        BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
        BankAccReconciliationLine.SetFilter("Applied Entries", '<>%1', 0);
        if not BankAccReconciliationLine.IsEmpty() then begin
            Overwrite := ConfirmManagement.GetResponseOrDefault(OverwriteExistingMatchesTxt, false);

            if Overwrite then begin
                BankAccReconciliationLine.Reset();
                BankAccReconciliationLine.SetFilter("Bank Account No.", BankAccReconciliation."Bank Account No.");
                BankAccReconciliationLine.SetFilter("Statement No.", BankAccReconciliation."Statement No.");
                RemoveMatchesFromRecLines(BankAccReconciliationLine);
            end;
        end;

        if GuiAllowed() then
            ProgressDialog.Open(ProgressBarMsg);
        // Lines to match
        BankAccReconciliationLine.Reset();
        BankAccReconciliationLine.FilterBankRecLinesByDate(BankAccReconciliation, Overwrite);
        // Candidate Bank Account Ledger Entries
        BankAccountLedgerEntry.SetBankReconciliationCandidatesFilter(BankAccReconciliation);
        InitializeBLEMatchingTempTable(TempBankAccLedgerEntryMatchingBuffer, BankAccountLedgerEntry);

        // Both candidate Bank Account Ledger Entries and lines to match are sorted by dates as this can be used to
        // easily get rid of many matching candidates outside the range.
        // Bank Rec. Lines may have an empty Transaction date, they are sorted first and these will
        // be attempted to match with every other candidate.

        repeat
            TempBankStatementMatchingBuffer.DeleteAll();
            RemovedPreviouslyAssigned := false;
            if not TempBankAccLedgerEntryMatchingBuffer.IsEmpty() then
                if BankAccReconciliationLine.FindSet() then
                    repeat
                       // If there are no candidate Bank Account Ledger Entries left, we can stop as there will be no other match
                        if TempBankAccLedgerEntryMatchingBuffer.IsEmpty() then
                            break;
                        AttemptToMatch(BankAccReconciliationLine, TempBankAccLedgerEntryMatchingBuffer, DaysTolerance, TempBankStatementMatchingBuffer, RemovedPreviouslyAssigned);
                        BankAccRecLineCounter += 1
                    until (BankAccReconciliationLine.Next() = 0);

            SaveOneToOneMatching(TempBankStatementMatchingBuffer, BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
            if RemovedPreviouslyAssigned then begin
                BankAccountLedgerEntry.SetBankReconciliationCandidatesFilter(BankAccReconciliation);
                InitializeBLEMatchingTempTable(TempBankAccLedgerEntryMatchingBuffer, BankAccountLedgerEntry);
                BankAccReconciliationLine.Reset();
                BankAccReconciliationLine.FilterBankRecLinesByDate(BankAccReconciliation, false);
            end;
        until not RemovedPreviouslyAssigned;

        if GuiAllowed() then
            ProgressDialog.Close();
        ShowMatchSummary(BankAccReconciliation);
        FeatureTelemetry.LogUsage('0000JLC', BankAccReconciliation.GetBankReconciliationTelemetryFeatureName(), AutomatchEventNameTelemetryTxt);
    end;

    /// <summary>
    /// Given a BankAccReconciliationLine it attempts to find a match from the non-empty temporary table candidates in
    /// TempBankAccLedgerEntryMatchingBuffer. It considers DaysTolerance as configuration parameter.
    /// 
    /// It uses the assumption that entries in TempBankAccLedgerEntryMatchingBuffer are sorted ascendingly by Posting Date and that
    /// subsequent calls during an automatch have their Transaction Date increasing as well.
    /// 
    /// If a match is found, the match details are inserted in the TempBankStatementMatchingBuffer. Multiple matches can be inserted.
    /// 
    /// </summary>
    /// <param name="BankAccReconciliationLine">Record loaded with the line to find a match for, subsequent calls make the assumption that it was called on a set ordered by Transaction Date</param>
    /// <param name="TempBankAccLedgerEntryMatchingBuffer">Candidate Bank Account Ledger Entries to consider for the match sorted by Posting Date</param>
    /// <param name="DaysTolerance">Days of tolerance allowed</param>
    /// <param name="TempBankStatementMatchingBuffer">Temporary table where the match is inserted if found</param>
    local procedure AttemptToMatch(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; DaysTolerance: Integer; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var RemovedPreviouslyAssigned: Boolean)
    var
        TempBestBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        TempMatchingDetailsBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankTransactionTooEarly: Boolean;
        BankTransactionTooLate: Boolean;
        ShouldContinueTryingToMatch: Boolean;
    begin
        TempBestBankStatementMatchingBuffer.Reset();
        if not TempBankAccLedgerEntryMatchingBuffer.FindSet() then
            exit;
        repeat
            // Date assumptions are only considered when Bank Rec. Line has Transaction Date <> 0
            if BankAccReconciliationLine."Transaction Date" <> 0D then begin
                BankTransactionTooEarly := (BankAccReconciliationLine."Transaction Date" - TempBankAccLedgerEntryMatchingBuffer."Posting Date") > DaysTolerance;
                BankTransactionTooLate := (TempBankAccLedgerEntryMatchingBuffer."Posting Date" - BankAccReconciliationLine."Transaction Date") > DaysTolerance;
            end;

            // Subsequent calls to this method are with Bank Rec Lines sorted ascending by Transaction date, therefore
            // if a candidate BLE is too early for this Bank Rec Line, it will be too early for posterior calls as well.
            // These are removed from the candidates for optimization.
            if BankTransactionTooEarly then
                TempBankAccLedgerEntryMatchingBuffer.Delete();

            if (not BankTransactionTooEarly) and (not BankTransactionTooLate) then begin
                TempMatchingDetailsBankStatementMatchingBuffer.Reset();
                if MatchingIsAcceptable(BankAccReconciliationLine, TempBankAccLedgerEntryMatchingBuffer, TempMatchingDetailsBankStatementMatchingBuffer) then begin
                    if MatchingIsHighConfidence(TempMatchingDetailsBankStatementMatchingBuffer) then
                        if AddMatchToCandidatesIfBetter(TempBankStatementMatchingBuffer, TempMatchingDetailsBankStatementMatchingBuffer, RemovedPreviouslyAssigned) then
                            exit;
                    if MatchIsBetter(TempMatchingDetailsBankStatementMatchingBuffer, TempBestBankStatementMatchingBuffer) then
                        if BestMatchingCandidateForBankAccountLedgerEntryIsWorse(TempBankStatementMatchingBuffer, TempMatchingDetailsBankStatementMatchingBuffer) then
                            TempBestBankStatementMatchingBuffer.Copy(TempMatchingDetailsBankStatementMatchingBuffer);
                end
            end;
            // If the candidate is too late, then we can stop already as Bank Ledger Entries are sorted by Posting Date (BankTransactionTooLate will always be true after)
            ShouldContinueTryingToMatch := (TempBankAccLedgerEntryMatchingBuffer.Next() <> 0) and (not BankTransactionTooLate);
        until not ShouldContinueTryingToMatch;
        if TempBestBankStatementMatchingBuffer."Entry No." <> 0 then
            AddMatchToCandidatesIfBetter(TempBankStatementMatchingBuffer, TempBestBankStatementMatchingBuffer, RemovedPreviouslyAssigned);
    end;

    local procedure AddMatchToCandidatesIfBetter(var CandidatesBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var ToAddBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var RemovedPreviouslyAssigned: Boolean): Boolean
    begin
        CandidatesBankStatementMatchingBuffer.SetRange("Entry No.", ToAddBankStatementMatchingBuffer."Entry No.");
        if CandidatesBankStatementMatchingBuffer.IsEmpty() then begin
            CandidatesBankStatementMatchingBuffer.SetRange("Entry No.");
            AddMatchingCandidate(CandidatesBankStatementMatchingBuffer, ToAddBankStatementMatchingBuffer);
            exit(true);
        end;
        if BestMatchingCandidateForBankAccountLedgerEntryIsWorse(CandidatesBankStatementMatchingBuffer, ToAddBankStatementMatchingBuffer) then begin
            RemovedPreviouslyAssigned := true;
            CandidatesBankStatementMatchingBuffer.SetRange("Entry No.");
            RemoveBestMatchingCandidateForBankAccountLedgerEntry(CandidatesBankStatementMatchingBuffer, ToAddBankStatementMatchingBuffer."Entry No.");
            AddMatchingCandidate(CandidatesBankStatementMatchingBuffer, ToAddBankStatementMatchingBuffer);
            exit(true);
        end;
        exit(false)
    end;

    local procedure RemoveBestMatchingCandidateForBankAccountLedgerEntry(var CandidatesBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccountLedgerEntryNo: Integer)
    begin
        CandidatesBankStatementMatchingBuffer.SetRange("Entry No.", BankAccountLedgerEntryNo);
        CandidatesBankStatementMatchingBuffer.FindFirst();
        CandidatesBankStatementMatchingBuffer.Delete();
        CandidatesBankStatementMatchingBuffer.SetRange("Entry No.");
    end;

    local procedure BestMatchingCandidateForBankAccountLedgerEntryIsWorse(var CandidatesBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var ToAddBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    var
        Result: Boolean;
    begin
        CandidatesBankStatementMatchingBuffer.SetRange("Entry No.", ToAddBankStatementMatchingBuffer."Entry No.");
        if CandidatesBankStatementMatchingBuffer.IsEmpty() then begin
            CandidatesBankStatementMatchingBuffer.SetRange("Entry No.");
            exit(true);
        end;
        Result := MatchIsBetter(ToAddBankStatementMatchingBuffer, CandidatesBankStatementMatchingBuffer);
        CandidatesBankStatementMatchingBuffer.SetRange("Entry No.");
        exit(Result);
    end;

    local procedure AddMatchingCandidate(var CandidatesBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var ToAddBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    begin
        CandidatesBankStatementMatchingBuffer.Copy(ToAddBankStatementMatchingBuffer);
        CandidatesBankStatementMatchingBuffer.Insert();
    end;

    /// <summary>
    /// Returns true if TempBankStatementMatchingBuffer is better than TempToCompareBankStatementMatchingBuffer
    /// </summary>
    /// <param name="TempBankStatementMatchingBuffer"></param>
    /// <param name="TempToCompareBankStatementMatchingBuffer"></param>
    /// <returns></returns>
    local procedure MatchIsBetter(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; TempToCompareBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    var
        AmountDifferenceSmaller: Boolean;
        DateDifferenceSmaller: Boolean;
        TextMatchingBetter: Boolean;
    begin
        if TempToCompareBankStatementMatchingBuffer."Entry No." = 0 then
            exit(true);

        AmountDifferenceSmaller := Abs(TempBankStatementMatchingBuffer."Amount Difference") < Abs(TempToCompareBankStatementMatchingBuffer."Amount Difference");
        DateDifferenceSmaller := Abs(TempBankStatementMatchingBuffer."Date Difference") < Abs(TempToCompareBankStatementMatchingBuffer."Date Difference");
        TextMatchingBetter := IsTextMatchingBetter(TempBankStatementMatchingBuffer, TempToCompareBankStatementMatchingBuffer);
        if AmountDifferenceSmaller then
            exit(true);

        if Abs(TempBankStatementMatchingBuffer."Amount Difference") > Abs(TempToCompareBankStatementMatchingBuffer."Amount Difference") then
            exit(false);

        if TextMatchingBetter then
            exit(true);

        if GetMaxTextScore(TempBankStatementMatchingBuffer) < GetMaxTextScore(TempToCompareBankStatementMatchingBuffer) then
            exit(false);

        exit(DateDifferenceSmaller);
    end;

    /// <summary>
    /// Returns true if the text matchings in TempBankStatementMatchingBuffer are better than TempToCompareBankStatementMatchingBuffer
    /// </summary>
    /// <param name="TempBankStatementMatchingBuffer"></param>
    /// <param name="TempToCompareBankStatementMatchingBuffer"></param>
    /// <returns></returns>
    local procedure IsTextMatchingBetter(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempToCompareBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    var
        FirstExactScore: Integer;
        SecondExactScore: Integer;
    begin
        FirstExactScore := GetMaxTextExactScore(TempBankStatementMatchingBuffer);
        SecondExactScore := GetMaxTextExactScore(TempToCompareBankStatementMatchingBuffer);
        if FirstExactScore > SecondExactScore then
            exit(true);
        exit(GetMaxTextScore(TempBankStatementMatchingBuffer) > GetMaxTextScore(TempToCompareBankStatementMatchingBuffer));
    end;

    /// <summary>
    /// Returns a number between 0-100 representing the best score obtained by string nearness in that match
    /// </summary>
    /// <param name="TempBankStatementMatchingBuffer"></param>
    /// <returns></returns>
    local procedure GetMaxTextScore(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Integer
    var
        MaxTextScore: Integer;
    begin
        MaxTextScore := GetMaxTextNearnessScore(TempBankStatementMatchingBuffer);
        if MaxTextScore < GetMaxTextExactScore(TempBankStatementMatchingBuffer) then
            MaxTextScore := GetMaxTextExactScore(TempBankStatementMatchingBuffer);
        exit(MaxTextScore);
    end;

    local procedure GetMaxTextNearnessScore(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Integer
    var
        MaxTextScore: Integer;
    begin
        MaxTextScore := TempBankStatementMatchingBuffer."Doc. No. Score";
        if MaxTextScore < TempBankStatementMatchingBuffer."Ext. Doc. No. Score" then
            MaxTextScore := TempBankStatementMatchingBuffer."Ext. Doc. No. Score";
        if MaxTextScore < TempBankStatementMatchingBuffer."Description Score" then
            MaxTextScore := TempBankStatementMatchingBuffer."Description Score";
        exit(MaxTextScore);
    end;

    local procedure GetMaxTextExactScore(TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Integer
    var
        MaxTextScore: Integer;
    begin
        MaxTextScore := TempBankStatementMatchingBuffer."Doc. No. Exact Score";
        if MaxTextScore < TempBankStatementMatchingBuffer."Ext. Doc. No. Exact Score" then
            MaxTextScore := TempBankStatementMatchingBuffer."Ext. Doc. No. Exact Score";
        if MaxTextScore < TempBankStatementMatchingBuffer."Description Exact Score" then
            MaxTextScore := TempBankStatementMatchingBuffer."Description Exact Score";
        exit(MaxTextScore);
    end;

    local procedure MatchingIsHighConfidence(TempMatchingDetailsBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    begin
        exit((TempMatchingDetailsBankStatementMatchingBuffer."Date Difference" = 0) and
            (TempMatchingDetailsBankStatementMatchingBuffer."Amount Difference" = 0) and
            (GetMaxTextNearnessScore(TempMatchingDetailsBankStatementMatchingBuffer) >= 95) and
            (GetMaxTextExactScore(TempMatchingDetailsBankStatementMatchingBuffer) >= 95));
    end;

    local procedure MatchingIsAcceptable(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var TempMatchingDetailsBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary): Boolean
    var
        AmountMatched: Boolean;
        AmountClose: Boolean;
        TransactionDateMatched: Boolean;
        DocumentNoMatched: Boolean;
        ExternalDocumentNoMatched: Boolean;
        DescriptionMatched: Boolean;
        ListOfMatchFields: Text;
    begin
        // We compute and load all the required information about their match
        TempMatchingDetailsBankStatementMatchingBuffer.Init();
        if BankAccReconciliationLine."Transaction Date" = 0D then
            TempMatchingDetailsBankStatementMatchingBuffer."Date Difference" := 0
        else
            TempMatchingDetailsBankStatementMatchingBuffer."Date Difference" := TempBankAccLedgerEntryMatchingBuffer."Posting Date" - BankAccReconciliationLine."Transaction Date";
        TempMatchingDetailsBankStatementMatchingBuffer."Amount Difference" := TempBankAccLedgerEntryMatchingBuffer."Remaining Amount" - BankAccReconciliationLine.Difference;

        TempMatchingDetailsBankStatementMatchingBuffer."Doc. No. Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer."Document No.", BankAccReconciliationLine, false);
        TempMatchingDetailsBankStatementMatchingBuffer."Ext. Doc. No. Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer."External Document No.", BankAccReconciliationLine, false);
        TempMatchingDetailsBankStatementMatchingBuffer."Description Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer.Description, BankAccReconciliationLine, false);

        TempMatchingDetailsBankStatementMatchingBuffer."Doc. No. Exact Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer."Document No.", BankAccReconciliationLine, true);
        TempMatchingDetailsBankStatementMatchingBuffer."Ext. Doc. No. Exact Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer."External Document No.", BankAccReconciliationLine, true);
        TempMatchingDetailsBankStatementMatchingBuffer."Description Exact Score" := BankReconciliationLineTextSimilarityScore(TempBankAccLedgerEntryMatchingBuffer.Description, BankAccReconciliationLine, true);

        TempMatchingDetailsBankStatementMatchingBuffer."Line No." := BankAccReconciliationLine."Statement Line No.";
        TempMatchingDetailsBankStatementMatchingBuffer."Entry No." := TempBankAccLedgerEntryMatchingBuffer."Entry No.";
        TempMatchingDetailsBankStatementMatchingBuffer."Account Type" := "Gen. Journal Account Type"::"G/L Account";
        TempMatchingDetailsBankStatementMatchingBuffer."Account No." := '';

        AmountMatched := (TempMatchingDetailsBankStatementMatchingBuffer."Amount Difference" = 0);
        if BankAccReconciliationLine."Transaction Date" <> 0D then
            TransactionDateMatched := (TempMatchingDetailsBankStatementMatchingBuffer."Date Difference" = 0);
        DocumentNoMatched := (TempMatchingDetailsBankStatementMatchingBuffer."Doc. No. Score" >= 80) or (TempMatchingDetailsBankStatementMatchingBuffer."Doc. No. Exact Score" = 100);
        ExternalDocumentNoMatched := (TempMatchingDetailsBankStatementMatchingBuffer."Ext. Doc. No. Score" >= 80) or (TempMatchingDetailsBankStatementMatchingBuffer."Ext. Doc. No. Exact Score" = 100);
        DescriptionMatched := (TempMatchingDetailsBankStatementMatchingBuffer."Description Score" >= 80) or (TempMatchingDetailsBankStatementMatchingBuffer."Description Exact Score" = 100);

        ListOfMatchFields := ListOfMatchedFields(AmountMatched, DocumentNoMatched, ExternalDocumentNoMatched, TransactionDateMatched, false, DescriptionMatched);
        TempMatchingDetailsBankStatementMatchingBuffer."Match Details" := StrSubstNo(MatchDetailsTxt, ListOfMatchFields);

        AmountClose := IsAmountClose(TempBankAccLedgerEntryMatchingBuffer."Remaining Amount", BankAccReconciliationLine.Difference);
        exit(((DocumentNoMatched or ExternalDocumentNoMatched or DescriptionMatched) and AmountClose) or AmountMatched);
    end;


    local procedure IsAmountClose(TargetAmount: Decimal; StatementAmount: Decimal): Boolean
    var
        Ratio: Decimal;
    begin
        if (TargetAmount = 0) or (StatementAmount = 0) then
            exit(false);
        if not SameSign(TargetAmount, StatementAmount) then
            exit(false);
        Ratio := Abs(StatementAmount) / Abs(TargetAmount);
        exit((Ratio > 0.6) and (Ratio < 1.1));
    end;

    local procedure SameSign(Amount1: Decimal; Amount2: Decimal): Boolean
    begin
        if (Amount1 = 0) or (Amount2 = 0) then
            exit(false);
        exit((Amount1 div Abs(Amount1)) = (Amount2 div Abs(Amount2)));
    end;

    /// <summary>
    /// Returns a number between 0 and 100, representing the best match between TextToMatch and the BankAccReconciliationLine fields.
    /// </summary>
    /// <param name="TextToMatch"></param>
    /// <param name="BankAccReconciliationLine"></param>
    /// <param name="Exact"></param>
    /// <returns>Returns a number between 0 and 100, representing the TextToMatch matching any of the BankaccReconciliationLine fields.</returns>
    local procedure BankReconciliationLineTextSimilarityScore(TextToMatch: Text; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Exact: Boolean): Integer
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Score: Integer;
        Max: Integer;
    begin
        if Exact then
            Score := RecordMatchMgt.CalculateExactStringNearness(BankAccReconciliationLine.Description, TextToMatch, 100)
        else
            Score := RecordMatchMgt.CalculateStringNearness(BankAccReconciliationLine.Description, TextToMatch, 4, 100);

        if Exact then
            Max := RecordMatchMgt.CalculateExactStringNearness(BankAccReconciliationLine."Related-Party Name", TextToMatch, 100)
        else
            Max := RecordMatchMgt.CalculateStringNearness(BankAccReconciliationLine."Related-Party Name", TextToMatch, 4, 100);

        if Max < Score then
            Max := Score;

        if Exact then
            Score := RecordMatchMgt.CalculateExactStringNearness(BankAccReconciliationLine."Additional Transaction Info", TextToMatch, 100)
        else
            Score := RecordMatchMgt.CalculateStringNearness(BankAccReconciliationLine."Additional Transaction Info", TextToMatch, 4, 100);

        if Max < Score then
            Max := Score;
        exit(Max);
    end;

    local procedure InitializeBLEMatchingTempTable(var TempBankAccLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        TempBankAccLedgerEntryMatchingBuffer.Reset();
        TempBankAccLedgerEntryMatchingBuffer.DeleteAll();
        if not BankAccountLedgerEntry.FindSet() then
            exit;
        repeat
            TempBankAccLedgerEntryMatchingBuffer.InsertFromBankAccLedgerEntry(BankAccountLedgerEntry);
        until BankAccountLedgerEntry.Next() = 0;
        TempBankAccLedgerEntryMatchingBuffer.SetCurrentKey("Posting Date");
        TempBankAccLedgerEntryMatchingBuffer.SetAscending("Posting Date", true);
    end;

    procedure ListOfMatchedFields(AmountMatched: Boolean; DocumentNoMatched: Boolean; ExternalDocumentNoMatched: Boolean; TransactionDateMatched: Boolean; RelatedPartyMatched: Boolean; DescriptionMatched: Boolean): Text
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

    procedure SaveOneToOneMatching(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccEntrySetReconNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
    begin
        // seems to be only used by auto match
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetCurrentKey(Quality);
        TempBankStatementMatchingBuffer.Ascending(false);

        if TempBankStatementMatchingBuffer.FindSet() then
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

    procedure ShowMatchSummary(BankAccReconciliation: Record "Bank Acc. Reconciliation")
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
        TotalCount := BankAccReconciliationLine.Count();

        BankAccReconciliationLine.SetFilter("Applied Entries", '<>%1', 0);
        MatchedCount := BankAccReconciliationLine.Count();

        Session.LogMessage('0000KML', StrSubstNo(BankAccountRecTotalAndMatchedLinesLbl, TotalCount, MatchedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);

        if MatchedCount < TotalCount then
            AdditionalText := StrSubstNo(MissingMatchMsg, Format(GetMatchLengthTreshold()));
        FinalText := StrSubstNo(MatchSummaryMsg, MatchedCount, TotalCount) + AdditionalText;
        Message(FinalText);
    end;

    procedure GetDescriptionMatchScore(BankRecDescription: Text; BankEntryDescription: Text; DocumentNo: Code[20]; ExternalDocumentNo: Code[35]): Integer
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Nearness: Integer;
        Score: Integer;
        MatchLengthTreshold: Integer;
        NormalizingFactor: Integer;
    begin
        BankRecDescription := RecordMatchMgt.Trim(BankRecDescription);
        BankEntryDescription := RecordMatchMgt.Trim(BankEntryDescription);

        MatchLengthTreshold := GetMatchLengthTreshold();
        NormalizingFactor := GetNormalizingFactor();
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

    procedure GetMatchLengthTreshold(): Integer
    begin
        exit(MatchLengthTreshold);
    end;

    procedure GetNormalizingFactor(): Integer
    begin
        exit(NormalizingFactor);
    end;

#if not CLEAN21
    [IntegrationEvent(false, false)]
    [Obsolete('Use BankAccReconciliationAutoMatch instead', '21.0')]
    local procedure OnAfterMatchBankRecLinesMatchSingle(CountMatchCandidates: Integer; TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    begin
    end;
#endif
}

