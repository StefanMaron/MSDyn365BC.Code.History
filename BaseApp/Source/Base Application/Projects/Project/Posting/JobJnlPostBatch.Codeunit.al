namespace Microsoft.Projects.Project.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;

codeunit 1013 "Job Jnl.-Post Batch"
{
    Permissions = TableData "Job Journal Batch" = rimd,
                  TableData "Job Journal Line" = rimd;
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        JobJnlLine.SetAutoCalcFields();
        Code();
        Rec := JobJnlLine;
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        JobJnlLine2: Record "Job Journal Line";
        JobJnlLine3: Record "Job Journal Line";
        JobLedgEntry: Record "Job Ledger Entry";
        JobReg: Record "Job Register";
        JobJnlCheckLine: Codeunit "Job Jnl.-Check Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        JobRegNo: Integer;
        StartLineNo: Integer;
        LineCount: Integer;
        NoOfRecords: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        SuppressCommit: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
    begin
        OnBeforeCode(JobJnlLine, SuppressCommit);

        JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
        JobJnlLine.SetFilter(Quantity, '<> 0');
        OnCodeOnAfterFilterJobJnlLine(JobJnlLine);
        JobJnlLine.LockTable();

        JobJnlTemplate.Get(JobJnlLine."Journal Template Name");
        JobJnlBatch.Get(JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");

        if JobJnlTemplate.Recurring then begin
            JobJnlLine.SetRange("Posting Date", 0D, WorkDate());
            JobJnlLine.SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
        end;

        if not JobJnlLine.Find('=><') then begin
            JobJnlLine."Line No." := 0;
            if not SuppressCommit then
                Commit();
            exit;
        end;

        if GuiAllowed() then begin
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
            Window.Update(1, JobJnlLine."Journal Batch Name");
        end;

        // Check lines
        OnCodeOnBeforeCheckLines(JobJnlLine);
        LineCount := 0;
        StartLineNo := JobJnlLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed() then
                Window.Update(2, LineCount);
            CheckRecurringLine(JobJnlLine);
            JobJnlCheckLine.RunCheck(JobJnlLine);
            OnAfterCheckJnlLine(JobJnlLine);
            if JobJnlLine.Next() = 0 then
                JobJnlLine.Find('-');
        until JobJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCount;

        // Find next register no.
        JobLedgEntry.LockTable();
        if JobLedgEntry.FindLast() then;
        JobReg.LockTable();
        if JobReg.FindLast() and (JobReg."To Entry No." = 0) then
            JobRegNo := JobReg."No."
        else
            JobRegNo := JobReg."No." + 1;

        // Post lines
        LineCount := 0;
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        JobJnlLine.Find('-');
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed() then begin
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;
            if not JobJnlLine.EmptyLine() and
                (JobJnlBatch."No. Series" <> '') and
                (JobJnlLine."Document No." <> LastDocNo2)
            then
                JobJnlLine.TestField("Document No.", NoSeriesBatch.GetNextNo(JobJnlBatch."No. Series", JobJnlLine."Posting Date"));
            if not JobJnlLine.EmptyLine() then
                LastDocNo2 := JobJnlLine."Document No.";
            MakeRecurringTexts(JobJnlLine);
            if JobJnlLine."Posting No. Series" = '' then begin
                JobJnlLine."Posting No. Series" := JobJnlBatch."No. Series";
                IsHandled := false;
                OnBeforeTestDocumentNo(JobJnlLine, IsHandled);
                if not IsHandled then
                    JobJnlLine.TestField("Document No.");
            end else
                if not JobJnlLine.EmptyLine() then
                    if (JobJnlLine."Document No." = LastDocNo) and (JobJnlLine."Document No." <> '') then
                        JobJnlLine."Document No." := LastPostedDocNo
                    else begin
                        LastDocNo := JobJnlLine."Document No.";
                        JobJnlLine."Document No." := NoSeriesBatch.GetNextNo(JobJnlLine."Posting No. Series", JobJnlLine."Posting Date");
                        LastPostedDocNo := JobJnlLine."Document No.";
                    end;
            OnBeforeJobJnlPostLine(JobJnlLine);
            JobJnlPostLine.RunWithCheck(JobJnlLine);
            OnAfterJobJnlPostLine(JobJnlLine);
        until JobJnlLine.Next() = 0;

        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");

        OnCodeOnAfterMakeMultiLevelAdjmt(JobJnlLine);

        // Copy register no. and current journal batch name to the job journal
        if not JobReg.FindLast() or (JobReg."No." <> JobRegNo) then
            JobRegNo := 0;

        JobJnlLine.Init();
        JobJnlLine."Line No." := JobRegNo;

        UpdateAndDeleteLines();
        OnAfterPostJnlLines(JobJnlBatch, JobJnlLine, JobRegNo);

        if not SuppressCommit then
            Commit();

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        if not SuppressCommit then
            Commit();
    end;

    local procedure CheckRecurringLine(var JobJnlLine2: Record "Job Journal Line")
    var
        TempDateFormula: DateFormula;
    begin
        if JobJnlLine2."No." <> '' then
            if JobJnlTemplate.Recurring then begin
                JobJnlLine2.TestField("Recurring Method");
                JobJnlLine2.TestField("Recurring Frequency");
                if JobJnlLine2."Recurring Method" = JobJnlLine2."Recurring Method"::Variable then
                    JobJnlLine2.TestField(Quantity);
            end else begin
                JobJnlLine2.TestField("Recurring Method", 0);
                JobJnlLine2.TestField("Recurring Frequency", TempDateFormula);
            end;
    end;

    local procedure MakeRecurringTexts(var JobJnlLine2: Record "Job Journal Line")
    begin
        if (JobJnlLine2."No." <> '') and (JobJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(JobJnlLine2."Posting Date", JobJnlLine2."Document No.", JobJnlLine2.Description);
    end;

    local procedure UpdateAndDeleteLines()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateAndDeleteLines(JobJnlLine);

        if JobRegNo <> 0 then
            if JobJnlTemplate.Recurring then begin
                // Recurring journal
                LineCount := 0;
                JobJnlLine2.CopyFilters(JobJnlLine);
                JobJnlLine2.Find('-');
                repeat
                    LineCount := LineCount + 1;
                    if GuiAllowed() then begin
                        Window.Update(5, LineCount);
                        Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                    end;
                    if JobJnlLine2."Posting Date" <> 0D then
                        JobJnlLine2.Validate("Posting Date", CalcDate(JobJnlLine2."Recurring Frequency", JobJnlLine2."Posting Date"));
                    if (JobJnlLine2."Recurring Method" = JobJnlLine2."Recurring Method"::Variable) and
                        (JobJnlLine2."No." <> '')
                    then
                        JobJnlLine2.DeleteAmounts();
                    JobJnlLine2.Modify();
                until JobJnlLine2.Next() = 0;
            end else begin
                // Not a recurring journal
                JobJnlLine2.CopyFilters(JobJnlLine);
                JobJnlLine2.SetFilter("No.", '<>%1', '');
                if JobJnlLine2.Find() then; // Remember the last line
                JobJnlLine3.Copy(JobJnlLine);
                IsHandled := false;
                OnBeforeDeleteNonRecJnlLines(JobJnlLine3, IsHandled, JobJnlLine, JobJnlLine2);
                if not IsHandled then begin
                    JobJnlLine3.DeleteAll();
                    JobJnlLine3.Reset();
                    JobJnlLine3.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
                    JobJnlLine3.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
                    if JobJnlTemplate."Increment Batch Name" then
                        if not JobJnlLine3.FindLast() then
                            if IncStr(JobJnlLine."Journal Batch Name") <> '' then begin
                                JobJnlBatch.Delete();
                                JobJnlBatch.Name := IncStr(JobJnlLine."Journal Batch Name");
                                if JobJnlBatch.Insert() then;
                                JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;
                            end;
                    JobJnlLine3.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
                    IsHandled := false;
                    OnUpdateAndDeleteLinesOnBeforeSetUpNewLine(JobJnlBatch, JobJnlLine3, IsHandled);
                    if not IsHandled then
                        if (JobJnlBatch."No. Series" = '') and not JobJnlLine3.FindLast() and (JobRegNo = 0) then begin
                            JobJnlLine3.Init();
                            JobJnlLine3."Journal Template Name" := JobJnlLine."Journal Template Name";
                            JobJnlLine3."Journal Batch Name" := JobJnlLine."Journal Batch Name";
                            JobJnlLine3."Line No." := 10000;
                            JobJnlLine3.Insert();
                            JobJnlLine3.SetUpNewLine(JobJnlLine2);
                            JobJnlLine3.Modify();
                        end;
                end;
            end;

        NoSeriesBatch.SaveState();
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
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
    local procedure OnBeforeCode(var JobJournalLine: Record "Job Journal Line"; var SuppressCommit: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterFilterJobJnlLine(var JobJournalLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckLines(var JobJournalLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterMakeMultiLevelAdjmt(var JobJournalLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeSetUpNewLine(JobJnlBatch: Record "Job Journal Batch"; var JobJnlLine3: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

