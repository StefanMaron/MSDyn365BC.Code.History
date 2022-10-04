codeunit 5673 "Insurance Jnl.-B.Post+Print"
{
    TableNo = "Insurance Journal Batch";

    trigger OnRun()
    begin
        InsuranceJnlBatch.Copy(Rec);
        Code();
        Copy(InsuranceJnlBatch);
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceReg: Record "Insurance Register";
        InsuranceJnlPostBatch: Codeunit "Insurance Jnl.-Post Batch";
        JournalWithErrors: Boolean;

        Text000: Label 'Do you want to post the journals and print the posting report?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        with InsuranceJnlBatch do begin
            InsuranceJnlTempl.Get("Journal Template Name");
            InsuranceJnlTempl.TestField("Posting Report ID");

            HideDialog := false;
            OnBeforePostJournalBatch(InsuranceJnlBatch, HideDialog);
            if not HideDialog then
                if not Confirm(Text000, false) then
                    exit;

            Find('-');
            repeat
                InsuranceJnlLine."Journal Template Name" := "Journal Template Name";
                InsuranceJnlLine."Journal Batch Name" := Name;
                InsuranceJnlLine."Line No." := 1;

                Clear(InsuranceJnlPostBatch);
                if InsuranceJnlPostBatch.Run(InsuranceJnlLine) then begin
                    if InsuranceReg.Get(InsuranceJnlLine."Line No.") then begin
                        InsuranceReg.SetRecFilter();
                        REPORT.Run(InsuranceJnlTempl."Posting Report ID", false, false, InsuranceReg);
                    end;
                    Mark(false);
                end
                else begin
                    Mark(true);
                    JournalWithErrors := true;
                end;
            until Next() = 0;

            if not JournalWithErrors then
                Message(Text001)
            else
                Message(
                  Text002 +
                  Text003);

            if not Find('=><') then begin
                Reset();
                FilterGroup := 2;
                SetRange("Journal Template Name", "Journal Template Name");
                FilterGroup := 0;
                Name := '';
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch"; var HideDialog: Boolean)
    begin
    end;
}

