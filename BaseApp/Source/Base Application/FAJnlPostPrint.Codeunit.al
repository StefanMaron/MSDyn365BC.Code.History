codeunit 5670 "FA. Jnl.-Post+Print"
{
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        FAJnlLine.Copy(Rec);
        Code;
        Copy(FAJnlLine);
    end;

    var
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlLine: Record "FA Journal Line";
        FAReg: Record "FA Register";
        TempJnlBatchName: Code[10];

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        with FAJnlLine do begin
            FAJnlTemplate.Get("Journal Template Name");
            FAJnlTemplate.TestField("Posting Report ID");
            FAJnlTemplate.TestField("Maint. Posting Report ID");
            if FAJnlTemplate.Recurring and (GetFilter("FA Posting Date") <> '') then
                FieldError("FA Posting Date", Text000);

            HideDialog := false;
            OnBeforePostJournalBatch(FAJnlLine, HideDialog);
            if not HideDialog then
                if not Confirm(Text001, false) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"FA Jnl.-Post Batch", FAJnlLine);

            if FAReg.Get("Line No.") then begin
                FAReg.SetRecFilter;
                if FAReg."From Entry No." > 0 then
                    REPORT.Run(FAJnlTemplate."Posting Report ID", false, false, FAReg);
                if FAReg."From Maintenance Entry No." > 0 then
                    REPORT.Run(FAJnlTemplate."Maint. Posting Report ID", false, false, FAReg);
            end;

            if "Line No." = 0 then
                Message(Text002)
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                      Text004,
                      "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset;
                FilterGroup := 2;
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup := 0;
                "Line No." := 1;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var FAJournalLine: Record "FA Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

