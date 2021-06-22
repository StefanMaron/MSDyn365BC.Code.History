codeunit 1113 "CA Jnl.-Post+Print"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostJnlLine.Copy(Rec);
        Code;
        Copy(CostJnlLine);
    end;

    var
        CostJnlLine: Record "Cost Journal Line";
        CostReg: Record "Cost Register";
        CostJnlTemplate: Record "Cost Journal Template";
        Text001: Label 'Do you want to post the journal lines?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    local procedure "Code"()
    var
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
    begin
        with CostJnlLine do begin
            CostJnlTemplate.Get("Journal Template Name");
            CostJnlTemplate.TestField("Posting Report ID");

            HideDialog := false;
            OnBeforePostJournalBatch(CostJnlLine, HideDialog);
            if not HideDialog then
                if not Confirm(Text001) then
                    exit;

            TempJnlBatchName := "Journal Batch Name";
            CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJnlLine);
            CostReg.Get("Line No.");
            CostReg.SetRecFilter;
            REPORT.Run(CostJnlTemplate."Posting Report ID", false, false, CostReg);

            if "Line No." = 0 then
                Message(Text002)
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(Text004, "Journal Batch Name");

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
    local procedure OnBeforePostJournalBatch(var CostJournalLine: Record "Cost Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

