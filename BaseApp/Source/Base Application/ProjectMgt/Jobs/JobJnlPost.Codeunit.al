codeunit 1021 "Job Jnl.-Post"
{
    TableNo = "Job Journal Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        Code();
        Copy(JobJnlLine);
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

        Text000: Label 'cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';

    local procedure "Code"()
    var
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
    begin
        OnBeforeCode(JobJnlLine, HideDialog, SuppressCommit);

        with JobJnlLine do begin
            JobJnlTemplate.Get("Journal Template Name");
            JobJnlTemplate.TestField("Force Posting Report", false);
            if JobJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            IsHandled := false;
            OnCodeOnBeforeConfirm(JobJnlLine, IsHandled);
            if not PreviewMode then
                if not IsHandled then
                    if not Confirm(Text001) then
                        exit;

            OnCodeOnAfterConfirm(JobJnlLine);

            TempJnlBatchName := "Journal Batch Name";

            JobJnlPostBatch.SetSuppressCommit(SuppressCommit or PreviewMode);
            JobJnlPostBatch.Run(JobJnlLine);

            if PreviewMode then
                GenJnlPostPreview.ThrowError();

            if not HideDialog then
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

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    internal procedure Preview(var JobJournalLine: Record "Job Journal Line")
    var
        JobJnlPost: Codeunit "Job Jnl.-Post";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(JobJnlPost);
        GenJnlPostPreview.Preview(JobJnlPost, JobJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        JobJournalLine: Record "Job Journal Line";
        JobJnlPost: Codeunit "Job Jnl.-Post";
    begin
        JobJournalLine.Copy(RecVar);
        JobJnlPost.SetPreviewMode(true);
        Result := JobJnlPost.Run(JobJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var JobJnlLine: Record "Job Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterConfirm(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeConfirm(JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

