codeunit 1022 "Job Jnl.-Post+Print"
{
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        Code();
        Copy(JobJnlLine);
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JobReg: Record "Job Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

        Text000: Label 'cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        with JobJnlLine do begin
            JobJnlTemplate.Get("Journal Template Name");
            JobJnlTemplate.TestField("Posting Report ID");
            if JobJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            HideDialog := false;
            OnBeforePostJournalBatch(JobJnlLine, HideDialog);
            if not HideDialog then
                if not Confirm(Text001) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJnlLine);

            if JobReg.Get("Line No.") then begin
                JobReg.SetRecFilter();
                IsHandled := false;
                OnBeforePrintJobReg(JobReg, IsHandled);
                if not IsHandled then
                    REPORT.Run(JobJnlTemplate."Posting Report ID", false, false, JobReg);
            end;

            if "Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                      Text004 +
                      Text005,
                      "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var JobJournalLine: Record "Job Journal Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintJobReg(var JobRegister: Record "Job Register"; var IsHandled: Boolean)
    begin
    end;
}

