codeunit 244 "Item Jnl.-B.Post+Print"
{
    TableNo = "Item Journal Batch";

    trigger OnRun()
    begin
        ItemJnlBatch.Copy(Rec);
        Code;
        Rec := ItemJnlBatch;
    end;

    var
        Text000: Label 'Do you want to post the journals and print the posting report?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemReg: Record "Item Register";
        WhseReg: Record "Warehouse Register";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        JnlWithErrors: Boolean;

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        with ItemJnlBatch do begin
            ItemJnlTemplate.Get("Journal Template Name");
            ItemJnlTemplate.TestField("Posting Report ID");

            HideDialog := false;
            OnBeforePostJournalBatch(ItemJnlBatch, HideDialog);
            if not HideDialog then
                if not Confirm(Text000, false) then
                    exit;

            Find('-');
            repeat
                ItemJnlLine."Journal Template Name" := "Journal Template Name";
                ItemJnlLine."Journal Batch Name" := Name;
                ItemJnlLine."Line No." := 1;
                Clear(ItemJnlPostBatch);
                if ItemJnlPostBatch.Run(ItemJnlLine) then begin
                    OnAfterPostJournalBatch(ItemJnlBatch);
                    Mark(false);
                    if ItemReg.Get(ItemJnlPostBatch.GetItemRegNo) then begin
                        ItemReg.SetRecFilter;
                        REPORT.Run(ItemJnlTemplate."Posting Report ID", false, false, ItemReg);
                    end;

                    if WhseReg.Get(ItemJnlPostBatch.GetWhseRegNo) then begin
                        WhseReg.SetRecFilter;
                        REPORT.Run(ItemJnlTemplate."Whse. Register Report ID", false, false, WhseReg);
                    end;
                end else begin
                    Mark(true);
                    JnlWithErrors := true;
                end;
            until Next = 0;

            if not JnlWithErrors then
                Message(Text001)
            else
                Message(
                  Text002 +
                  Text003);

            if not Find('=><') then begin
                Reset;
                Name := '';
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var ItemJournalBatch: Record "Item Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; var HideDialog: Boolean)
    begin
    end;
}

