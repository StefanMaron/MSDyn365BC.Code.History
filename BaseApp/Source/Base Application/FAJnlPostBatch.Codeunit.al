codeunit 5633 "FA Jnl.-Post Batch"
{
    Permissions = TableData "FA Journal Batch" = imd;
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        FAJnlLine.Copy(Rec);
        Code;
        Rec := FAJnlLine;
    end;

    var
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: Label 'A maximum of %1 posting number series can be used in each journal.';
        Text007: Label '<Month Text>', Locked = true;
        FAJnlLine: Record "FA Journal Line";
        FAJnlLine2: Record "FA Journal Line";
        FAJnlLine3: Record "FA Journal Line";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAReg: Record "FA Register";
        FALedgEntry: Record "FA Ledger Entry";
        NoSeries: Record "No. Series" temporary;
        FAJnlSetup: Record "FA Journal Setup";
        FAJnlCheckLine: Codeunit "FA Jnl.-Check Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        Window: Dialog;
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        FARegNo: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;
        PreviewMode: Boolean;
        SetupCombErr: Label 'must not be specified when %1 = %2 in %3', Comment = 'must not be specified when G/L Integration - Derogatory = TRUE in Depreciation Book';

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        with FAJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LockTable();

            FAJnlTemplate.Get("Journal Template Name");
            FAJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            if FAJnlTemplate.Recurring then begin
                SetRange("FA Posting Date", 0D, WorkDate);
                SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
            end;

            if not Find('=><') then begin
                if PreviewMode then
                    GenJnlPostPreview.ThrowError;
                "Line No." := 0;
                Commit();
                exit;
            end;

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
            Window.Update(1, "Journal Batch Name");

            // Check lines
            LineCount := 0;
            StartLineNo := "Line No.";
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                CheckRecurringLine(FAJnlLine);
                FAJnlCheckLine.CheckFAJnlLine(FAJnlLine);
                if Next() = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            NoOfRecords := LineCount;

            FALedgEntry.LockTable();
            if FALedgEntry.FindLast then;
            FAReg.LockTable();
            if FAReg.FindLast then
                FARegNo := FAReg."No." + 1
            else
                FARegNo := 1;

            // Post lines
            PostLines;

            if FAReg.FindLast then;
            if FAReg."No." <> FARegNo then
                FARegNo := 0;

            Init;
            "Line No." := FARegNo;

            // Update/delete lines
            if FARegNo <> 0 then
                if FAJnlTemplate.Recurring then begin
                    LineCount := 0;
                    FAJnlLine2.CopyFilters(FAJnlLine);
                    FAJnlLine2.Find('-');
                    repeat
                        LineCount := LineCount + 1;
                        Window.Update(5, LineCount);
                        Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                        if FAJnlLine2."FA Posting Date" <> 0D then
                            FAJnlLine2.Validate("FA Posting Date", CalcDate(FAJnlLine2."Recurring Frequency", FAJnlLine2."FA Posting Date"));
                        if FAJnlLine2."Recurring Method" <> FAJnlLine2."Recurring Method"::"F Fixed" then
                            ZeroAmounts(FAJnlLine2);
                        FAJnlLine2.Modify();
                    until FAJnlLine2.Next() = 0;
                end else begin
                    FAJnlLine2.CopyFilters(FAJnlLine);
                    FAJnlLine2.SetFilter("FA No.", '<>%1', '');
                    if FAJnlLine2.Find('+') then; // Remember the last line
                    FAJnlLine3.Copy(FAJnlLine);
                    FAJnlLine3.DeleteAll();
                    FAJnlLine3.Reset();
                    FAJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
                    FAJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                    if FAJnlTemplate."Increment Batch Name" then
                        if not FAJnlLine3.FindLast then
                            if IncStr("Journal Batch Name") <> '' then begin
                                FAJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                                FAJnlBatch.Delete();
                                FAJnlSetup.IncFAJnlBatchName(FAJnlBatch);
                                FAJnlBatch.Name := IncStr("Journal Batch Name");
                                if FAJnlBatch.Insert() then;
                                "Journal Batch Name" := FAJnlBatch.Name;
                            end;

                    FAJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                    if (FAJnlBatch."No. Series" = '') and not FAJnlLine3.FindLast then begin
                        FAJnlLine3.Init();
                        FAJnlLine3."Journal Template Name" := "Journal Template Name";
                        FAJnlLine3."Journal Batch Name" := "Journal Batch Name";
                        FAJnlLine3."Line No." := 10000;
                        FAJnlLine3.Insert();
                        FAJnlLine3.SetUpNewLine(FAJnlLine2);
                        FAJnlLine3.Modify();
                    end;
                end;
            if FAJnlBatch."No. Series" <> '' then
                NoSeriesMgt.SaveNoSeries;
            if NoSeries.Find('-') then
                repeat
                    Evaluate(PostingNoSeriesNo, NoSeries.Description);
                    NoSeriesMgt2[PostingNoSeriesNo].SaveNoSeries;
                until NoSeries.Next() = 0;

            OnBeforeCommit(FARegNo);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            Clear(FAJnlCheckLine);
            Clear(FAJnlPostLine);
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        Commit();
    end;

    local procedure CheckRecurringLine(var FAJnlLine2: Record "FA Journal Line")
    var
        DummyDateFormula: DateFormula;
    begin
        with FAJnlLine2 do
            if "FA No." <> '' then
                if FAJnlTemplate.Recurring then begin
                    TestField("Recurring Method");
                    TestField("Recurring Frequency");
                    if "Recurring Method" = "Recurring Method"::"V Variable" then
                        TestField(Amount);
                end else begin
                    TestField("Recurring Method", 0);
                    TestField("Recurring Frequency", DummyDateFormula);
                end;
    end;

    local procedure MakeRecurringTexts(var FAJnlLine2: Record "FA Journal Line")
    var
        AccountingPeriod: Record "Accounting Period";
        Day: Integer;
        Month: Integer;
        Week: Integer;
        MonthText: Text[30];
    begin
        with FAJnlLine2 do
            if ("FA No." <> '') and ("Recurring Method" <> 0) then begin
                Day := Date2DMY("FA Posting Date", 1);
                Week := Date2DWY("FA Posting Date", 2);
                Month := Date2DMY("FA Posting Date", 2);
                MonthText := Format("FA Posting Date", 0, Text007);
                AccountingPeriod.SetRange("Starting Date", 0D, "FA Posting Date");
                if not AccountingPeriod.FindLast then
                    AccountingPeriod.Name := '';
                "Document No." :=
                  DelChr(
                    PadStr(
                      StrSubstNo("Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen("Document No.")),
                    '>');
                Description :=
                  DelChr(
                    PadStr(
                      StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen(Description)),
                    '>');
            end;
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
        if DeprBook.FindFirst then
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
        if not DerogDepreciationBook.FindFirst then
            exit;

        CalculateAcqCostDepr.DerogatoryCalc(
          DerogatoryAmount, SourceFAJournalLine."FA No.", DerogDepreciationBook.Code, SourceFAJournalLine.Amount);

        if DerogatoryAmount = 0 then
            exit;

        if DepreciationBook."G/L Integration - Derogatory" then
            SourceFAJournalLine.FieldError(
              "Depr. Acquisition Cost", StrSubstNo(SetupCombErr,
                DepreciationBook.FieldCaption("G/L Integration - Derogatory"), true, DepreciationBook.TableCaption));

        // Insert/post G/L + FA entries for primary depreciation book
        with FAJnlLine do begin
            TransferFields(SourceFAJournalLine);
            Validate("FA Posting Type", "FA Posting Type"::Derogatory);
            Validate(Amount, DerogatoryAmount);
            Validate("Depr. until FA Posting Date", false);
            Validate("Depr. Acquisition Cost", false);
        end;
        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);

        // Post FA ledger entry for secondary book
        MakeDerogFAJnlLine(DerogFAJnlLine, FAJnlLine);
        FAJnlPostLine.FAJnlPostLine(DerogFAJnlLine, true);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostLines()
    var
        DerogFAJnlLine: Record "FA Journal Line";
    begin
        with FAJnlLine do begin
            LineCount := 0;
            LastDocNo := '';
            LastDocNo2 := '';
            LastPostedDocNo := '';
            Find('-');
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                CheckFAJnlLineDocumentNo();
                if not ("FA No." = '') then
                    LastDocNo2 := "Document No.";
                MakeRecurringTexts(FAJnlLine);
                if "Posting No. Series" = '' then
                    "Posting No. Series" := FAJnlBatch."No. Series"
                else
                    if not ("FA No." = '') then
                        if "Document No." = LastDocNo then
                            "Document No." := LastPostedDocNo
                        else begin
                            if not NoSeries.Get("Posting No. Series") then begin
                                NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
                                if NoOfPostingNoSeries > ArrayLen(NoSeriesMgt2) then
                                    Error(
                                      Text006,
                                      ArrayLen(NoSeriesMgt2));
                                NoSeries.Code := "Posting No. Series";
                                NoSeries.Description := Format(NoOfPostingNoSeries);
                                NoSeries.Insert();
                            end;
                            LastDocNo := "Document No.";
                            Evaluate(PostingNoSeriesNo, NoSeries.Description);
                            "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "FA Posting Date", false);
                            LastPostedDocNo := "Document No.";
                        end;
                FAJnlPostLine.FAJnlPostLine(FAJnlLine, false);
                if MakeDerogFAJnlLine(DerogFAJnlLine, FAJnlLine) then begin
                    if "FA Error Entry No." <> 0 then
                        DerogFAJnlLine."FA Error Entry No." := FAJnlPostLine.GetNextMatchingFALedgEntry(FAJnlLine, FAJnlLine."FA Error Entry No.", DerogFAJnlLine."Depreciation Book Code");
                    FAJnlPostLine.FAJnlPostLine(DerogFAJnlLine, false);
                    OnPostLinesOnAfterFAJnlPostLine(FAJnlLine);
                    CreateAndPostDerogatoryEntry(FAJnlLine);
                end;
            until Next() = 0;
        end;
    end;

    local procedure CheckFAJnlLineDocumentNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAJnlLineDocumentNo(FAJnlLine, FAJnlBatch, IsHandled);
        if IsHandled then
            exit;

        with FAJnlLine do
            if not ("FA No." = '') and
               (FAJnlBatch."No. Series" <> '') and
               ("Document No." <> LastDocNo2)
            then
                TestField("Document No.", NoSeriesMgt.GetNextNo(FAJnlBatch."No. Series", "FA Posting Date", false));
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
    local procedure OnPostLinesOnAfterFAJnlPostLine(var FAJnlLine: Record "FA Journal Line")
    begin
    end;
}

