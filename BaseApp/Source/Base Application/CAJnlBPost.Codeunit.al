codeunit 1107 "CA Jnl.-B. Post"
{
    TableNo = "Cost Journal Batch";

    trigger OnRun()
    begin
        CostJnlBatch.Copy(Rec);
        Code;
        Rec := CostJnlBatch;
    end;

    var
        CostJnlBatch: Record "Cost Journal Batch";
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'Not all journals were posted. The journals that were not successfully posted are now marked.';

    local procedure "Code"()
    var
        CostJnlLine: Record "Cost Journal Line";
        CAJnlPostBatch: Codeunit "CA Jnl.-Post Batch";
        JnlWithErrors: Boolean;
    begin
        with CostJnlBatch do begin
            if not Confirm(Text000) then
                exit;

            Find('-');
            repeat
                CostJnlLine."Journal Template Name" := "Journal Template Name";
                CostJnlLine."Journal Batch Name" := Name;
                CostJnlLine."Line No." := 1;
                Clear(CAJnlPostBatch);
                if CAJnlPostBatch.Run(CostJnlLine) then
                    Mark(false)
                else begin
                    Mark(true);
                    JnlWithErrors := true;
                end;
            until Next = 0;

            if not JnlWithErrors then
                Message(Text001)
            else
                Message(Text002);

            if not Find('=><') then begin
                Reset;
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                FilterGroup(0);
                Name := '';
            end;
        end;
    end;
}

