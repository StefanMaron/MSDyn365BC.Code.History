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
                if Next = 0 then
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
                    until FAJnlLine2.Next = 0;
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
                until NoSeries.Next = 0;

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

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostLines()
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
                if not ("FA No." = '') and
                   (FAJnlBatch."No. Series" <> '') and
                   ("Document No." <> LastDocNo2)
                then
                    TestField("Document No.", NoSeriesMgt.GetNextNo(FAJnlBatch."No. Series", "FA Posting Date", false));
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
                OnPostLinesOnAfterFAJnlPostLine(FAJnlLine);
            until Next = 0;
        end;
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

