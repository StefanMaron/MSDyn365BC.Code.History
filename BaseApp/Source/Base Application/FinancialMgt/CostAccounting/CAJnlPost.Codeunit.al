codeunit 1108 "CA Jnl.-Post"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostJnlLine.Copy(Rec);
        Code();
        Rec := CostJnlLine;
    end;

    var
        CostJnlLine: Record "Cost Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    local procedure "Code"()
    var
        TempJnlBatchName: Code[10];
    begin
        with CostJnlLine do begin
            if not Confirm(Text001) then
                exit;

            TempJnlBatchName := "Journal Batch Name";
            CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJnlLine);

            if "Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(Text004, "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;
}

