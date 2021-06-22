codeunit 272 "Res. Jnl.-Post+Print"
{
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        ResJnlLine.Copy(Rec);
        Code;
        Copy(ResJnlLine);
    end;

    var
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlLine: Record "Res. Journal Line";
        ResReg: Record "Resource Register";
        TempJnlBatchName: Code[10];

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        with ResJnlLine do begin
            ResJnlTemplate.Get("Journal Template Name");
            ResJnlTemplate.TestField("Posting Report ID");
            if ResJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            HideDialog := false;
            OnBeforePostJournalBatch(ResJnlLine, HideDialog);
            if not HideDialog then
                if not Confirm(Text001) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"Res. Jnl.-Post Batch", ResJnlLine);

            OnAfterPostJournalBatch(ResJnlLine);

            if ResReg.Get("Line No.") then begin
                ResReg.SetRecFilter;
                REPORT.Run(ResJnlTemplate."Posting Report ID", false, false, ResReg);
            end;

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
    local procedure OnAfterPostJournalBatch(var ResJournalLine: Record "Res. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ResJournalLine: Record "Res. Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

