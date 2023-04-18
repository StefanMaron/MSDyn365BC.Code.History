codeunit 241 "Item Jnl.-Post"
{
    EventSubscriberInstance = Manual;
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        ItemJnlLine.Copy(Rec);
        Code();
        Copy(ItemJnlLine);
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        HideDialog: Boolean;

        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';

    local procedure "Code"()
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(ItemJnlLine, HideDialog, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            ItemJnlTemplate.Get("Journal Template Name");
            ItemJnlTemplate.TestField("Force Posting Report", false);
            if ItemJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            if not HideDialog then
                if not PreviewMode then
                    if not Confirm(Text001, false) then
                        exit;

            TempJnlBatchName := "Journal Batch Name";

            ItemJnlPostBatch.SetSuppressCommit(SuppressCommit or PreviewMode);
            OnCodeOnBeforeItemJnlPostBatchRun(ItemJnlLine);
            ItemJnlPostBatch.Run(ItemJnlLine);

            OnCodeOnAfterItemJnlPostBatchRun(ItemJnlLine, HideDialog, SuppressCommit);

            if not HideDialog then
                if not PreviewMode then
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
        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure Preview(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJnlPost: Codeunit "Item Jnl.-Post";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(ItemJnlPost);
        GenJnlPostPreview.Preview(ItemJnlPost, ItemJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
    begin
        ItemJournalLine.Copy(RecVar);
        ItemJnlPost.SetPreviewMode(true);
        Result := ItemJnlPost.Run(ItemJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterItemJnlPostBatchRun(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeItemJnlPostBatchRun(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

