codeunit 1021 "Job Jnl.-Post"
{
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        Code;
        Copy(JobJnlLine);
    end;

    var
        Text000: Label 'cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
    begin
        OnBeforeCode(JobJnlLine, HideDialog, SuppressCommit);

        with JobJnlLine do begin
            JobJnlTemplate.Get("Journal Template Name");
            JobJnlTemplate.TestField("Force Posting Report", false);
            if JobJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            if not Confirm(Text001) then
                exit;

            OnCodeOnAftreConfirm(JobJnlLine);

            TempJnlBatchName := "Journal Batch Name";

            JobJnlPostBatch.SetSuppressCommit(SuppressCommit);
            JobJnlPostBatch.Run(JobJnlLine);

            if not HideDialog then
                if "Line No." = 0 then
                    Message(Text002)
                else
                    if TempJnlBatchName = "Journal Batch Name" then
                        Message(Text003)
                    else
                        Message(
                          Text004 +
                          Text005,
                          "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset;
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var JobJnlLine: Record "Job Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAftreConfirm(var JobJnlLine: Record "Job Journal Line")
    begin
    end;
}

