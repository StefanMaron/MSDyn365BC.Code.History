codeunit 232 "Gen. Jnl.-Post+Print"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        Code();
        Copy(GenJnlLine);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRefToPrint: RecordRef;
        GenJnlsScheduled: Boolean;
        TempJnlBatchName: Code[10];

        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the report(s)?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        with GenJnlLine do begin
            GenJnlTemplate.Get("Journal Template Name");
            if GenJnlTemplate."Force Posting Report" or
               (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
            then
                GenJnlTemplate.TestField("Posting Report ID");
            if GenJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            OnBeforePostJournalBatch(GenJnlLine, HideDialog);

            if not HideDialog then begin
                if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                    exit;
                if not GenJnlPostBatch.ConfirmPostingUnvoidableChecks("Journal Batch Name", "Journal Template Name") then
                    exit;
            end;

            TempJnlBatchName := "Journal Batch Name";

            IsHandled := false;
            OnAfterConfirmPostJournalBatch(GenJnlLine, IsHandled);
            if IsHandled then
                exit;

            GeneralLedgerSetup.Get();
            if GeneralLedgerSetup."Post & Print with Job Queue" then begin
                // Add job queue entry for each document no.
                GenJnlLine.SetCurrentKey("Document No.");
                while GenJnlLine.FindFirst() do begin
                    GenJnlsScheduled := true;
                    "Print Posted Documents" := true;
                    Modify();
                    GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                    GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
                end;

                if GenJnlsScheduled then
                    Message(JournalsScheduledMsg);
            end else begin
                CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
                OnAfterPostJournalBatch(GenJnlLine);

                RecRefToPrint.GetTable(GenJnlLine);
                BatchPostingPrintMgt.PrintJournal(RecRefToPrint);

                if not HideDialog then
                    if "Line No." = 0 then
                        Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
                    else
                        if TempJnlBatchName = "Journal Batch Name" then
                            Message(Text003)
                        else
                            Message(Text004, "Journal Batch Name");
            end;

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") or GeneralLedgerSetup."Post & Print with Job Queue" then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                OnGenJnlLineSetFilter(GenJnlLine);
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN20
    [Obsolete('Event is not raised anywhere', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLRegPostingReportPrint(var ReportID: Integer; ReqWindow: Boolean; SystemPrinter: Boolean; var GLRegister: Record "G/L Register"; var Handled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineSetFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

