codeunit 250 "Gen. Jnl.-Post via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        GenJrnlLine: record "Gen. Journal Line";
        OrigGenJrnlLine: Record "Gen. Journal Line";
        GenJrnlTemplate: Record "Gen. Journal Template";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        PrintPostDocuments: Boolean;
    begin
        TestField("Record ID to Process");
        RecRef.Get("Record ID to Process");
        RecRef.SetTable(GenJrnlLine);
        PrintPostDocuments := GenJrnlLine."Print Posted Documents";

        GenJrnlTemplate.Get(GenJrnlLine."Journal Template Name");
        if GenJrnlTemplate.Recurring then
            ExecuteRecurringGeneralJournalsLogic(GenJrnlLine);

        OrigGenJrnlLine.Copy(GenJrnlLine);
        GenJrnlLine.SetRange("Journal Template Name", GenJrnlLine."Journal Template Name");
        GenJrnlLine.SetRange("Journal Batch Name", GenJrnlLine."Journal Batch Name");
        GenJrnlLine.SetRange("Document No.", GenJrnlLine."Document No.");
        GenJrnlLine.FindSet();
        SetJobQueueStatus(GenJrnlLine, GenJrnlLine."Job Queue Status"::Posting);

        if not CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJrnlLine) then begin
            SetJobQueueStatus(GenJrnlLine, GenJrnlLine."Job Queue Status"::Error);
            Error(GetLastErrorText);
        end;

        if PrintPostDocuments then begin
            RecRefToPrint.GetTable(GenJrnlLine);
            BatchPostingPrintMgt.PrintJournal(RecRefToPrint);
        end;

        ClearBackgroundPostingInfo(OrigGenJrnlLine);
    end;

    var
        PostDescription: Label 'Post journal lines for journal template %1, journal batch %2, document no. %3.', Comment = '%1 = template name, %2 = batch name, %3 = document no. Example: Post journal lines for journal template GENERAL, journal batch DEFAULT, document no. G00123.';
        PostAndPrintDescription: Label 'Post and print journal lines for journal template %1, journal batch %2, document no. %3.', Comment = '%1 = template name, %2 = batch name, %3 = document no. Example: Post and print journal lines for journal template GENERAL, journal batch DEFAULT, document no. G00123.';
        Confirmation: Label 'Journal lines have been scheduled for posting.';
        WrongJobQueueStatus: Label 'Journal lines cannot be posted because they have already been scheduled for posting. Choose the Remove from Job Queue action to reset the job queue status and then post again.';

    local procedure SetJobQueueStatus(var GenJrnlLine: Record "Gen. Journal Line"; NewStatus: Option)
    begin
        GenJrnlLine.LockTable();
        if GenJrnlLine.Find() then begin
            GenJrnlLine.SetRange("Journal Template Name", GenJrnlLine."Journal Template Name");
            GenJrnlLine.SetRange("Journal Batch Name", GenJrnlLine."Journal Batch Name");
            GenJrnlLine.SetRange("Document No.", GenJrnlLine."Document No.");
            GenJrnlLine.ModifyAll("Job Queue Status", NewStatus);
            Commit();
        end;
    end;

    procedure EnqueueGenJrnlLine(var GenJrnlLine: Record "Gen. Journal Line")
    begin
        EnqueueGenJrnlLineWithUI(GenJrnlLine, true);
    end;

    procedure EnqueueGenJrnlLineWithUI(var GenJrnlLine: Record "Gen. Journal Line"; WithUI: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeEnqueueGenJrnlLine(GenJrnlLine, Handled);
        if Handled then
            exit;

        with GenJrnlLine do begin
            if not ("Job Queue Status" in ["Job Queue Status"::" ", "Job Queue Status"::Error]) then
                Error(WrongJobQueueStatus);
            OnBeforeReleaseGenJrnlLine(GenJrnlLine);
            "Job Queue Entry ID" := EnqueueJobEntry(GenJrnlLine);
            Modify();

            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            SetRange("Document No.", "Document No.");
            ModifyAll("Job Queue Status", "Job Queue Status"::"Scheduled for Posting");
            ModifyAll("Job Queue Entry ID", "Job Queue Entry ID");

            if GuiAllowed then
                if WithUI then
                    Message(Confirmation);
        end;
    end;

    local procedure EnqueueJobEntry(GenJrnlLine: Record "Gen. Journal Line"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            Clear(ID);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Gen. Jnl.-Post via Job Queue";
            "Record ID to Process" := GenJrnlLine.RecordId;
            "Earliest Start Date/Time" := CreateDateTime(Today(), Time());
            FillJobEntryFromGeneralLedgerSetup(JobQueueEntry);
            FillJobEntryGeneralLedgerDescription(JobQueueEntry, GenJrnlLine);
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
            exit(ID);
        end;
    end;

    local procedure FillJobEntryFromGeneralLedgerSetup(var JobQueueEntry: Record "Job Queue Entry")
    var
        GeneralLedgerSetup: record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        with JobQueueEntry do begin
            "Notify On Success" := GeneralLedgerSetup."Notify On Success";
            "Job Queue Category Code" := GeneralLedgerSetup."Job Queue Category Code";
        end;
    end;

    local procedure FillJobEntryGeneralLedgerDescription(var JobQueueEntry: Record "Job Queue Entry"; GenJrnlLine: Record "Gen. Journal Line")
    begin
        with JobQueueEntry do begin
            if GenJrnlLine."Print Posted Documents" then
                Description := PostAndPrintDescription
            else
                Description := PostDescription;
            Description :=
              CopyStr(StrSubstNo(Description, GenJrnlLine."Journal Template Name", GenJrnlLine."Journal Batch Name", GenJrnlLine."Document No."), 1, MaxStrLen(Description));
        end;
    end;

    procedure CancelQueueEntry(var GenJrnlLine: Record "Gen. Journal Line")
    begin
        with GenJrnlLine do
            if "Job Queue Status" <> "Job Queue Status"::" " then begin
                DeleteJobs(GenJrnlLine);
                SetJobQueueStatus(GenJrnlLine, "Job Queue Status"::" ");
            end;
    end;

    local procedure DeleteJobs(GenJrnlLine: Record "Gen. Journal Line")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with GenJrnlLine do begin
            if not IsNullGuid("Job Queue Entry ID") then
                JobQueueEntry.SetRange(ID, "Job Queue Entry ID");
            JobQueueEntry.SetRange("Record ID to Process", RecordId);
            if not JobQueueEntry.IsEmpty() then
                JobQueueEntry.DeleteAll(true);
        end;
    end;

    local procedure ClearBackgroundPostingInfo(GenJrnlLine: Record "Gen. Journal Line")
    var
        EmptyGuid: Guid;
    begin
        GenJrnlLine.SetRange("Journal Template Name", GenJrnlLine."Journal Template Name");
        GenJrnlLine.SetRange("Journal Batch Name", GenJrnlLine."Journal Batch Name");
        GenJrnlLine.SetRange("Document No.", GenJrnlLine."Document No.");
        GenJrnlLine.ModifyAll("Job Queue Status", GenJrnlLine."Job Queue Status"::" ");
        GenJrnlLine.ModifyAll("Job Queue Entry ID", EmptyGuid);
        GenJrnlLine.ModifyAll("Print Posted Documents", false);
    end;

    local procedure ExecuteRecurringGeneralJournalsLogic(GenJrnlLine: Record "Gen. Journal Line")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PostingDateError: Label 'is not within your range of allowed posting dates';
    begin
        if GenJnlCheckLine.DateNotAllowed(GenJrnlLine."Posting Date", GenJrnlLine."Journal Template Name") then begin
            SetJobQueueStatus(GenJrnlLine, GenJrnlLine."Job Queue Status"::Error);
            GenJrnlLine.FieldError("Posting Date", PostingDateError);
        end;

        // If the template is Recurring and WorkDate() < GenJrnlLine."Posting Date", update the WorkDate to allow background posting of lines that are set to post in the future.  
        // In the UI, users can modify the WorkDate to allow this.
        if WorkDate() < GenJrnlLine."Posting Date" then
            WorkDate := WorkDate(GenJrnlLine."Posting Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnqueueGenJrnlLine(var GenJrnlLine: Record "Gen. Journal Line"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseGenJrnlLine(var GenJrnlLine: Record "Gen. Journal Line")
    begin
    end;
}

