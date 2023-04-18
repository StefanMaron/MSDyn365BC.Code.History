codeunit 5672 "Insurance Jnl.-Post+Print"
{
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        InsuranceJnlLine.Copy(Rec);
        Code();
        Copy(InsuranceJnlLine);
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceReg: Record "Insurance Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

        Text000: Label 'Do you want to post the journal lines and print the posting report?';
        Text002: Label 'The journal lines were successfully posted.';
        Text003: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        with InsuranceJnlLine do begin
            InsuranceJnlTempl.Get("Journal Template Name");
            InsuranceJnlTempl.TestField("Posting Report ID");

            HideDialog := false;
            OnBeforePostJournalBatch(InsuranceJnlLine, HideDialog);
            if not HideDialog then
                if not Confirm(Text000, false) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"Insurance Jnl.-Post Batch", InsuranceJnlLine);

            if InsuranceReg.Get("Line No.") then begin
                InsuranceReg.SetRecFilter();
                REPORT.Run(InsuranceJnlTempl."Posting Report ID", false, false, InsuranceReg);
            end;

            if "Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text002)
                else
                    Message(
                      Text003,
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var InsuranceJournalLine: Record "Insurance Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

