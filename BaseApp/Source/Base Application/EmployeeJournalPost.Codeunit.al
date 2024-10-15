codeunit 17384 "Employee Journal - Post"
{
    TableNo = "Employee Journal Line";

    trigger OnRun()
    begin
        EmplJnlLine.Copy(Rec);
        RunCode;
        Copy(EmplJnlLine);
    end;

    var
        EmplJnlTemplate: Record "Employee Journal Template";
        EmplJnlLine: Record "Employee Journal Line";
        EmplJnlPostBatch: Codeunit "Employee Journal - Post Batch";
        TempJnlBatchName: Code[10];
        Text001: Label 'Do you want to post the journal lines?';
        Text002: Label 'There is nothing to post.';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
        Text005: Label 'You are now in the %1 journal.';

    local procedure RunCode()
    begin
        with EmplJnlLine do begin
            EmplJnlTemplate.Get("Journal Template Name");
            EmplJnlTemplate.TestField("Force Posting Report", false);

            if not Confirm(Text001) then
                exit;

            TempJnlBatchName := "Journal Batch Name";

            EmplJnlPostBatch.Run(EmplJnlLine);

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
}

