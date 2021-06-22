codeunit 273 "Res. Jnl.-B.Post"
{
    TableNo = "Res. Journal Batch";

    trigger OnRun()
    begin
        ResJnlBatch.Copy(Rec);
        Code;
        Rec := ResJnlBatch;
    end;

    var
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        ResJnlPostBatch: Codeunit "Res. Jnl.-Post Batch";
        JnlWithErrors: Boolean;

    local procedure "Code"()
    begin
        with ResJnlBatch do begin
            ResJnlTemplate.Get("Journal Template Name");
            ResJnlTemplate.TestField("Force Posting Report", false);

            if not Confirm(Text000) then
                exit;

            Find('-');
            repeat
                ResJnlLine."Journal Template Name" := "Journal Template Name";
                ResJnlLine."Journal Batch Name" := Name;
                ResJnlLine."Line No." := 1;
                Clear(ResJnlPostBatch);
                if ResJnlPostBatch.Run(ResJnlLine) then
                    Mark(false)
                else begin
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
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                FilterGroup(0);
                Name := '';
            end;
        end;
    end;
}

