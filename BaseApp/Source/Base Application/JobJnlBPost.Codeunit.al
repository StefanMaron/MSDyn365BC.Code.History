codeunit 1023 "Job Jnl.-B.Post"
{
    TableNo = "Job Journal Batch";

    trigger OnRun()
    begin
        JobJnlBatch.Copy(Rec);
        Code;
        Copy(JobJnlBatch);
    end;

    var
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostbatch: Codeunit "Job Jnl.-Post Batch";
        JnlWithErrors: Boolean;

    local procedure "Code"()
    begin
        with JobJnlBatch do begin
            JobJnlTemplate.Get("Journal Template Name");
            JobJnlTemplate.TestField("Force Posting Report", false);

            if not Confirm(Text000) then
                exit;

            Find('-');
            repeat
                JobJnlLine."Journal Template Name" := "Journal Template Name";
                JobJnlLine."Journal Batch Name" := Name;
                JobJnlLine."Line No." := 1;
                Clear(JobJnlPostbatch);
                if JobJnlPostbatch.Run(JobJnlLine) then
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

