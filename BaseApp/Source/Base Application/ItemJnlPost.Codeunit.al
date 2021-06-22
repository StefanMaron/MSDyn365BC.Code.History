codeunit 241 "Item Jnl.-Post"
{
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        ItemJnlLine.Copy(Rec);
        Code;
        Copy(ItemJnlLine);
    end;

    var
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        TempJnlBatchName: Code[10];

    local procedure "Code"()
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        SuppressCommit := false;
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
                if not Confirm(Text001, false) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            ItemJnlPostBatch.SetSuppressCommit(SuppressCommit);
            ItemJnlPostBatch.Run(ItemJnlLine);

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;
}

