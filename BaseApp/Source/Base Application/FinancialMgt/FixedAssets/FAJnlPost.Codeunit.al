codeunit 5636 "FA. Jnl.-Post"
{
    EventSubscriberInstance = Manual;
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        FAJnlLine.Copy(Rec);
        Code();
        Copy(FAJnlLine);
    end;

    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlLine: Record "FA Journal Line";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];
        PreviewMode: Boolean;

        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCode(FAJnlLine);

        with FAJnlLine do begin
            FAJnlTemplate.Get("Journal Template Name");
            FAJnlTemplate.TestField("Force Posting Report", false);
            if FAJnlTemplate.Recurring and (GetFilter("FA Posting Date") <> '') then
                FieldError("FA Posting Date", Text000);

            if not ConfirmPost() then
                exit;

            TempJnlBatchName := "Journal Batch Name";

            FAJnlPostBatch.SetPreviewMode(PreviewMode);
            FAJnlPostBatch.Run(FAJnlLine);

            if not PreviewMode then begin
                IsHandled := false;
                OnCodeOnBeforeShowMessage(FAJnlLine, IsHandled);
                if not IsHandled then
                    if "Line No." = 0 then
                        Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
                    else
                        if TempJnlBatchName = "Journal Batch Name" then
                            Message(Text003)
                        else
                            Message(
                              Text004,
                              "Journal Batch Name");

                if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                    Reset();
                    FilterGroup := 2;
                    SetRange("Journal Template Name", "Journal Template Name");
                    SetRange("Journal Batch Name", "Journal Batch Name");
                    FilterGroup := 0;
                    "Line No." := 1;
                end;
            end;
        end;
    end;

    local procedure ConfirmPost() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPost(FAJnlLine, PreviewMode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not PreviewMode then
            if not Confirm(Text001, false) then
                exit(false);

        exit(true);
    end;

    procedure Preview(var FAJournalLine: Record "FA Journal Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        FAJnlPost: Codeunit "FA. Jnl.-Post";
    begin
        BindSubscription(FAJnlPost);
        GenJnlPostPreview.Preview(FAJnlPost, FAJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        FAJnlPost: Codeunit "FA. Jnl.-Post";
    begin
        FAJnlPost := Subscriber;
        PreviewMode := true;
        Result := FAJnlPost.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var FAJnlLine: Record "FA Journal Line"; PreviewMode: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeShowMessage(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

