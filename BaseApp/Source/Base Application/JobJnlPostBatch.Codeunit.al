codeunit 1013 "Job Jnl.-Post Batch"
{
    Permissions = TableData "Job Journal Batch" = imd;
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        JobJnlLine.SetAutoCalcFields;
        Code;
        Rec := JobJnlLine;
    end;

    var
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: Label 'A maximum of %1 posting number series can be used in each journal.';
        Text007: Label '<Month Text>', Locked = true;
        AccountingPeriod: Record "Accounting Period";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLine2: Record "Job Journal Line";
        JobJnlLine3: Record "Job Journal Line";
        JobLedgEntry: Record "Job Ledger Entry";
        JobReg: Record "Job Register";
        NoSeries: Record "No. Series" temporary;
        JobJnlCheckLine: Codeunit "Job Jnl.-Check Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        Window: Dialog;
        JobRegNo: Integer;
        StartLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        LineCount: Integer;
        NoOfRecords: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;

    local procedure "Code"()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
    begin
        with JobJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LockTable();

            JobJnlTemplate.Get("Journal Template Name");
            JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            if JobJnlTemplate.Recurring then begin
                SetRange("Posting Date", 0D, WorkDate);
                SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
            end;

            if not Find('=><') then begin
                "Line No." := 0;
                Commit();
                exit;
            end;

            if JobJnlTemplate.Recurring then
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
                CheckRecurringLine(JobJnlLine);
                JobJnlCheckLine.RunCheck(JobJnlLine);
                OnAfterCheckJnlLine(JobJnlLine);
                if Next = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            NoOfRecords := LineCount;

            // Find next register no.
            JobLedgEntry.LockTable();
            if JobLedgEntry.FindLast then;
            JobReg.LockTable();
            if JobReg.FindLast and (JobReg."To Entry No." = 0) then
                JobRegNo := JobReg."No."
            else
                JobRegNo := JobReg."No." + 1;

            // Post lines
            LineCount := 0;
            LastDocNo := '';
            LastDocNo2 := '';
            LastPostedDocNo := '';
            Find('-');
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                if not EmptyLine and
                   (JobJnlBatch."No. Series" <> '') and
                   ("Document No." <> LastDocNo2)
                then
                    TestField("Document No.", NoSeriesMgt.GetNextNo(JobJnlBatch."No. Series", "Posting Date", false));
                if not EmptyLine then
                    LastDocNo2 := "Document No.";
                MakeRecurringTexts(JobJnlLine);
                if "Posting No. Series" = '' then begin
                    "Posting No. Series" := JobJnlBatch."No. Series";
                    IsHandled := false;
                    OnBeforeTestDocumentNo(JobJnlLine, IsHandled);
                    if not IsHandled then
                        TestField("Document No.");
                end else
                    if not EmptyLine then
                        if ("Document No." = LastDocNo) and ("Document No." <> '') then
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
                            "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "Posting Date", false);
                            LastPostedDocNo := "Document No.";
                        end;
                OnBeforeJobJnlPostLine(JobJnlLine);
                JobJnlPostLine.RunWithCheck(JobJnlLine);
                OnAfterJobJnlPostLine(JobJnlLine);
            until Next = 0;

            InvtSetup.Get();
            if InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            then begin
                InvtAdjmt.SetProperties(true, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            // Copy register no. and current journal batch name to the job journal
            if not JobReg.FindLast or (JobReg."No." <> JobRegNo) then
                JobRegNo := 0;

            Init;
            "Line No." := JobRegNo;

            UpdateAndDeleteLines;
            OnAfterPostJnlLines(JobJnlBatch, JobJnlLine, JobRegNo);

            Commit();
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Commit();
    end;

    local procedure CheckRecurringLine(var JobJnlLine2: Record "Job Journal Line")
    var
        TempDateFormula: DateFormula;
    begin
        with JobJnlLine2 do
            if "No." <> '' then
                if JobJnlTemplate.Recurring then begin
                    TestField("Recurring Method");
                    TestField("Recurring Frequency");
                    if "Recurring Method" = "Recurring Method"::Variable then
                        TestField(Quantity);
                end else begin
                    TestField("Recurring Method", 0);
                    TestField("Recurring Frequency", TempDateFormula);
                end;
    end;

    local procedure MakeRecurringTexts(var JobJnlLine2: Record "Job Journal Line")
    begin
        with JobJnlLine2 do
            if ("No." <> '') and ("Recurring Method" <> 0) then begin // Not recurring
                Day := Date2DMY("Posting Date", 1);
                Week := Date2DWY("Posting Date", 2);
                Month := Date2DMY("Posting Date", 2);
                MonthText := Format("Posting Date", 0, Text007);
                AccountingPeriod.SetRange("Starting Date", 0D, "Posting Date");
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

    local procedure UpdateAndDeleteLines()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateAndDeleteLines(JobJnlLine);

        with JobJnlLine do begin
            if JobRegNo <> 0 then
                if JobJnlTemplate.Recurring then begin
                    // Recurring journal
                    LineCount := 0;
                    JobJnlLine2.CopyFilters(JobJnlLine);
                    JobJnlLine2.Find('-');
                    repeat
                        LineCount := LineCount + 1;
                        Window.Update(5, LineCount);
                        Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                        if JobJnlLine2."Posting Date" <> 0D then
                            JobJnlLine2.Validate("Posting Date", CalcDate(JobJnlLine2."Recurring Frequency", JobJnlLine2."Posting Date"));
                        if (JobJnlLine2."Recurring Method" = JobJnlLine2."Recurring Method"::Variable) and
                           (JobJnlLine2."No." <> '')
                        then
                            JobJnlLine2.DeleteAmounts;
                        JobJnlLine2.Modify();
                    until JobJnlLine2.Next = 0;
                end else begin
                    // Not a recurring journal
                    JobJnlLine2.CopyFilters(JobJnlLine);
                    JobJnlLine2.SetFilter("No.", '<>%1', '');
                    if JobJnlLine2.Find then; // Remember the last line
                    JobJnlLine3.Copy(JobJnlLine);
                    IsHandled := false;
                    OnBeforeDeleteNonRecJnlLines(JobJnlLine3, IsHandled, JobJnlLine, JobJnlLine2);
                    if not IsHandled then begin
                        JobJnlLine3.DeleteAll();
                        JobJnlLine3.Reset();
                        JobJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
                        JobJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                        if JobJnlTemplate."Increment Batch Name" then
                            if not JobJnlLine3.FindLast then
                                if IncStr("Journal Batch Name") <> '' then begin
                                    JobJnlBatch.Delete();
                                    JobJnlBatch.Name := IncStr("Journal Batch Name");
                                    if JobJnlBatch.Insert() then;
                                    "Journal Batch Name" := JobJnlBatch.Name;
                                end;
                        JobJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                        if (JobJnlBatch."No. Series" = '') and not JobJnlLine3.FindLast then begin
                            JobJnlLine3.Init();
                            JobJnlLine3."Journal Template Name" := "Journal Template Name";
                            JobJnlLine3."Journal Batch Name" := "Journal Batch Name";
                            JobJnlLine3."Line No." := 10000;
                            JobJnlLine3.Insert();
                            JobJnlLine3.SetUpNewLine(JobJnlLine2);
                            JobJnlLine3.Modify();
                        end;
                    end;
                end;

            if JobJnlBatch."No. Series" <> '' then
                NoSeriesMgt.SaveNoSeries;
            if NoSeries.Find('-') then
                repeat
                    Evaluate(PostingNoSeriesNo, NoSeries.Description);
                    NoSeriesMgt2[PostingNoSeriesNo].SaveNoSeries;
                until NoSeries.Next = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckJnlLine(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlPostLine(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJnlLines(var JobJournalBatch: Record "Job Journal Batch"; var JobJournalLine: Record "Job Journal Line"; JobRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobJnlPostLine(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteNonRecJnlLines(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean; var FromJobJournalLine: Record "Job Journal Line"; var JobJournalLine2: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDocumentNo(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAndDeleteLines(var JobJournalLine: Record "Job Journal Line")
    begin
    end;
}

