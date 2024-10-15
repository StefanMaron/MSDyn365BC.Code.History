namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;

codeunit 5633 "FA Jnl.-Post Batch"
{
    Permissions = TableData "FA Journal Batch" = rimd;
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        FAJnlLine.Copy(Rec);
        Code();
        Rec := FAJnlLine;
    end;

    var
        FAJnlLine: Record "FA Journal Line";
        FAJnlLine2: Record "FA Journal Line";
        FAJnlLine3: Record "FA Journal Line";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAReg: Record "FA Register";
        FALedgEntry: Record "FA Ledger Entry";
        FAJnlSetup: Record "FA Journal Setup";
        FAJnlCheckLine: Codeunit "FA Jnl.-Check Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        FARegNo: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        SetupCombErr: Label 'must not be specified when %1 = %2 in %3', Comment = 'must not be specified when G/L Integration - Derogatory = TRUE in Depreciation Book';
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
    begin
        FAJnlLine.SetRange("Journal Template Name", FAJnlLine."Journal Template Name");
        FAJnlLine.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
        OnCodeOnBeforeLockTable(FAJnlLine);
        FAJnlLine.LockTable();

        OnCodeOnCheckSuppressCommit(FAJnlLine, SuppressCommit);

        FAJnlTemplate.Get(FAJnlLine."Journal Template Name");
        FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
        OnCodeOnAfterLockTable(FAJnlBatch);

        if FAJnlTemplate.Recurring then begin
            FAJnlLine.SetRange("FA Posting Date", 0D, WorkDate());
            FAJnlLine.SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
        end;

        if not FAJnlLine.Find('=><') then begin
            if PreviewMode then
                GenJnlPostPreview.ThrowError();
            FAJnlLine."Line No." := 0;
            if not SuppressCommit then
                Commit();
            exit;
        end;

        if GuiAllowed() then begin
            IsHandled := false;
            OnCodeOnBeforeWindowOpen(IsHandled);
            if not IsHandled then begin
                if FAJnlTemplate.Recurring then
                    Window.Open(
                      Text001 +
                      Text002 +
                      Text003 +
                      Text004)
                else
                    Window.Open(
                      Text001 +
                      Text002 +
                      Text005);
                Window.Update(1, FAJnlLine."Journal Batch Name");
            end;
        end;
        // Check lines
        LineCount := 0;
        StartLineNo := FAJnlLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed() then begin
                IsHandled := false;
                OnCodeOnBeforeWindowUpdate(IsHandled);
                if not IsHandled then
                    Window.Update(2, LineCount);
            end;
            CheckRecurringLine(FAJnlLine);
            FAJnlCheckLine.CheckFAJnlLine(FAJnlLine);
            if FAJnlLine.Next() = 0 then
                FAJnlLine.Find('-');
        until FAJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCount;

        FALedgEntry.LockTable();
        if FALedgEntry.FindLast() then;
        FAReg.LockTable();
        if FAReg.FindLast() then
            FARegNo := FAReg."No." + 1
        else
            FARegNo := 1;
        // Post lines
        PostLines();
        OnCodeOnAfterPostLines(FAJnlLine);

        if FAReg.FindLast() then;
        if FAReg."No." <> FARegNo then
            FARegNo := 0;

        FAJnlLine.Init();
        FAJnlLine."Line No." := FARegNo;
        // Update/delete lines
        IsHandled := false;
        OnCodeOnBeforeUpdateDeleteLines(FAJnlLine, IsHandled);
        if not IsHandled then
            if FARegNo <> 0 then
                if FAJnlTemplate.Recurring then begin
                    LineCount := 0;
                    FAJnlLine2.CopyFilters(FAJnlLine);
                    FAJnlLine2.Find('-');
                    repeat
                        LineCount := LineCount + 1;
                        if GuiAllowed() then begin
                            IsHandled := false;
                            OnCodeOnBeforeWindowUpdate(IsHandled);
                            if not IsHandled then begin
                                Window.Update(5, LineCount);
                                Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                            end;
                        end;
                        if FAJnlLine2."FA Posting Date" <> 0D then
                            FAJnlLine2.Validate("FA Posting Date", CalcDate(FAJnlLine2."Recurring Frequency", FAJnlLine2."FA Posting Date"));
                        if FAJnlLine2."Recurring Method" <> FAJnlLine2."Recurring Method"::"F Fixed" then
                            ZeroAmounts(FAJnlLine2);
                        FAJnlLine2.Modify();
                    until FAJnlLine2.Next() = 0;
                end else begin
                    FAJnlLine2.CopyFilters(FAJnlLine);
                    FAJnlLine2.SetFilter("FA No.", '<>%1', '');
                    if FAJnlLine2.Find('+') then;
                    // Remember the last line
                    FAJnlLine3.Copy(FAJnlLine);
                    OnCodeOnBeforeFAJnlLine3DeleteAll(FAJnlLine3, FAJnlLine);
                    FAJnlLine3.DeleteAll();
                    FAJnlLine3.Reset();
                    FAJnlLine3.SetRange("Journal Template Name", FAJnlLine."Journal Template Name");
                    FAJnlLine3.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
                    if FAJnlTemplate."Increment Batch Name" then
                        if not FAJnlLine3.FindLast() then
                            if IncStr(FAJnlLine."Journal Batch Name") <> '' then begin
                                FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
                                FAJnlBatch.Delete();
                                FAJnlSetup.IncFAJnlBatchName(FAJnlBatch);
                                FAJnlBatch.Name := IncStr(FAJnlLine."Journal Batch Name");
                                if FAJnlBatch.Insert() then;
                                FAJnlLine."Journal Batch Name" := FAJnlBatch.Name;
                            end;

                    CreateNewFAJnlLine();
                end;
        NoSeriesBatch.SaveState();

        OnBeforeCommit(FARegNo);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        OnRunOnBeforeCommit(FAJnlLine, SuppressCommit);
        if not SuppressCommit then
            Commit();
        Clear(FAJnlCheckLine);
        Clear(FAJnlPostLine);

        IsHandled := false;
        OnRunOnBeforeUpdateAnalysisViewUpdateAll(FAJnlLine, SuppressCommit, IsHandled);
        if not IsHandled then
            UpdateAnalysisView.UpdateAll(0, true);
        if not SuppressCommit then
            Commit();
    end;

    local procedure CreateNewFAJnlLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewFAJnlLine(FAJnlLine, FAJnlLine2, FAJnlLine3, IsHandled);
        if IsHandled then
            exit;

        FAJnlLine3.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
        if (FAJnlBatch."No. Series" = '') and not FAJnlLine3.FindLast() then begin
            FAJnlLine3.Init();
            FAJnlLine3."Journal Template Name" := FAJnlLine."Journal Template Name";
            FAJnlLine3."Journal Batch Name" := FAJnlLine."Journal Batch Name";
            FAJnlLine3."Line No." := 10000;
            FAJnlLine3.Insert();
            FAJnlLine3.SetUpNewLine(FAJnlLine2);
            FAJnlLine3.Modify();
        end;
    end;

    local procedure CheckRecurringLine(var FAJnlLine2: Record "FA Journal Line")
    var
        DummyDateFormula: DateFormula;
    begin
        if FAJnlLine2."FA No." <> '' then
            if FAJnlTemplate.Recurring then begin
                FAJnlLine2.TestField("Recurring Method");
                FAJnlLine2.TestField("Recurring Frequency");
                if FAJnlLine2."Recurring Method" = FAJnlLine2."Recurring Method"::"V Variable" then
                    FAJnlLine2.TestField(Amount);
            end else begin
                FAJnlLine2.TestField("Recurring Method", 0);
                FAJnlLine2.TestField("Recurring Frequency", DummyDateFormula);
            end;
    end;

    local procedure MakeRecurringTexts(var FAJnlLine2: Record "FA Journal Line")
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if (FAJnlLine2."FA No." <> '') and (FAJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(FAJnlLine2."FA Posting Date", FAJnlLine2."Document No.", FAJnlLine2.Description);
    end;

    local procedure ZeroAmounts(var FAJnlLine: Record "FA Journal Line")
    begin
        FAJnlLine.Amount := 0;
        FAJnlLine."Debit Amount" := 0;
        FAJnlLine."Credit Amount" := 0;
        FAJnlLine."Salvage Value" := 0;
    end;

    [Scope('OnPrem')]
    procedure MakeDerogFAJnlLine(var NewFAJnlLine: Record "FA Journal Line"; FAJnlLine: Record "FA Journal Line"): Boolean
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
    begin
        NewFAJnlLine.Copy(FAJnlLine);
        DeprBook.SetRange("Derogatory Calculation", FAJnlLine."Depreciation Book Code");
        if DeprBook.FindFirst() then
            if FADeprBook.Get(NewFAJnlLine."FA No.", DeprBook.Code) then begin
                NewFAJnlLine.Validate("Depreciation Book Code", DeprBook.Code);
                exit(true);
            end;
        exit(false);
    end;

    local procedure CreateAndPostDerogatoryEntry(SourceFAJournalLine: Record "FA Journal Line")
    var
        DepreciationBook: Record "Depreciation Book";
        DerogDepreciationBook: Record "Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        DerogFAJnlLine: Record "FA Journal Line";
        CalculateAcqCostDepr: Codeunit "Calculate Acq. Cost Depr.";
        DerogatoryAmount: Decimal;
    begin
        if (SourceFAJournalLine."FA Posting Type" <> SourceFAJournalLine."FA Posting Type"::"Acquisition Cost") or
           (not SourceFAJournalLine."Depr. Acquisition Cost")
        then
            exit;

        DepreciationBook.Get(SourceFAJournalLine."Depreciation Book Code");
        DerogDepreciationBook.SetRange("Derogatory Calculation", DepreciationBook.Code);
        if not DerogDepreciationBook.FindFirst() then
            exit;

        CalculateAcqCostDepr.DerogatoryCalc(
          DerogatoryAmount, SourceFAJournalLine."FA No.", DerogDepreciationBook.Code, SourceFAJournalLine.Amount);

        if DerogatoryAmount = 0 then
            exit;

        if DepreciationBook."G/L Integration - Derogatory" then
            SourceFAJournalLine.FieldError(
              "Depr. Acquisition Cost", StrSubstNo(SetupCombErr,
                DepreciationBook.FieldCaption("G/L Integration - Derogatory"), true, DepreciationBook.TableCaption()));
        // Insert/post G/L + FA entries for primary depreciation book
        FAJnlLine.TransferFields(SourceFAJournalLine);
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Derogatory);
        FAJnlLine.Validate(Amount, DerogatoryAmount);
        FAJnlLine.Validate("Depr. until FA Posting Date", false);
        FAJnlLine.Validate("Depr. Acquisition Cost", false);
        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);

        // Post FA ledger entry for secondary book
        MakeDerogFAJnlLine(DerogFAJnlLine, FAJnlLine);
        FAJnlPostLine.FAJnlPostLine(DerogFAJnlLine, true);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure PostLines()
    var
        DerogFAJnlLine: Record "FA Journal Line";
        IsHandled: Boolean;
    begin
        LineCount := 0;
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        FAJnlLine.Find('-');
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed() then begin
                IsHandled := false;
                OnPostLinesOnBeforeWindowUpdate(IsHandled);
                if not IsHandled then begin
                    Window.Update(3, LineCount);
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                end;
            end;
            CheckFAJnlLineDocumentNo();
            if not (FAJnlLine."FA No." = '') then
                LastDocNo2 := FAJnlLine."Document No.";
            MakeRecurringTexts(FAJnlLine);
            if FAJnlLine."Posting No. Series" = '' then
                FAJnlLine."Posting No. Series" := FAJnlBatch."No. Series"
            else
                if not (FAJnlLine."FA No." = '') then
                    if FAJnlLine."Document No." = LastDocNo then
                        FAJnlLine."Document No." := LastPostedDocNo
                    else begin
                        LastDocNo := FAJnlLine."Document No.";
                        OnPostLinesOnBeforeGetNextNoSeries(FAJnlLine);
                        FAJnlLine."Document No." := NoSeriesBatch.GetNextNo(FAJnlLine."Posting No. Series", FAJnlLine."FA Posting Date");
                        OnPostLinesOnAfterGetNextNoSeries(FAJnlLine);
                        LastPostedDocNo := FAJnlLine."Document No.";
                    end;
            OnPostLinesOnBeforeFAJnlPostLine(FAJnlLine, FAJnlPostLine);
            FAJnlPostLine.FAJnlPostLine(FAJnlLine, false);
            if MakeDerogFAJnlLine(DerogFAJnlLine, FAJnlLine) then begin
                if FAJnlLine."FA Error Entry No." <> 0 then
                    DerogFAJnlLine."FA Error Entry No." := FAJnlPostLine.GetNextMatchingFALedgEntry(FAJnlLine, FAJnlLine."FA Error Entry No.", DerogFAJnlLine."Depreciation Book Code");
                FAJnlPostLine.FAJnlPostLine(DerogFAJnlLine, false);
                OnPostLinesOnAfterFAJnlPostLine(FAJnlLine);
                CreateAndPostDerogatoryEntry(FAJnlLine);
            end;
        until FAJnlLine.Next() = 0;
    end;

    local procedure CheckFAJnlLineDocumentNo()
    var
        NoSeries: Record "No. Series";
        IsHandled: Boolean;
        CompareNextNo: Code[20];
    begin
        IsHandled := false;
        OnBeforeCheckFAJnlLineDocumentNo(FAJnlLine, FAJnlBatch, IsHandled);
        if IsHandled then
            exit;

        if not (FAJnlLine."FA No." = '') and (FAJnlBatch."No. Series" <> '') and (FAJnlLine."Document No." <> LastDocNo2) then begin
            CompareNextNo := NoSeriesBatch.GetNextNo(FAJnlBatch."No. Series", FAJnlLine."FA Posting Date");
            NoSeries.Get(FAJnlBatch."No. Series");
            if NoSeries."Manual Nos." then
                if FAJnlLine."Document No." <> CompareNextNo then
                    exit;
            FAJnlLine.TestField(FAJnlLine."Document No.", CompareNextNo);
        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAJnlLineDocumentNo(FAJnlLine: Record "FA Journal Line"; FAJnlBatch: Record "FA Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommit(FARegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewFAJnlLine(var FAJnlLine: Record "FA Journal Line"; var FAJnlLine2: Record "FA Journal Line"; var FAJnlLine3: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeFAJnlLine3DeleteAll(var FAJnlLine3: Record "FA Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeLockTable(var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterFAJnlPostLine(var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterLockTable(var FAJournalBatch: Record "FA Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWindowOpen(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeUpdateDeleteLines(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWindowUpdate(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeWindowUpdate(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGetNextNoSeries(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGetNextNoSeries(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeFAJnlPostLine(var FAJournalLine: Record "FA Journal Line"; var FAJnlPostLine: Codeunit "FA Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnCheckSuppressCommit(var FAJournalLine: Record "FA Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommit(var FAJournalLine: Record "FA Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeUpdateAnalysisViewUpdateAll(var FAJournalLine: Record "FA Journal Line"; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostLines(var FAJournalLine: Record "FA Journal Line")
    begin
    end;
}

