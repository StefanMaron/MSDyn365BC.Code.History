codeunit 233 "Gen. Jnl.-B.Post"
{
    TableNo = "Gen. Journal Batch";

    trigger OnRun()
    begin
        GenJnlBatch.Copy(Rec);
        Code;
        Copy(GenJnlBatch);
    end;

    var
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
        JournalsScheduledMsg: Label 'Journals have been scheduled for posting.';
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        GenJnlsScheduled: Boolean;
        JnlWithErrors: Boolean;

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        OrderByDocNoAndLineNo: Boolean;
    begin
        // If simple view is used then order gen. journal lines by doc no. and line no.
        if GenJnlManagement.GetJournalSimplePageModePreference(PAGE::"General Journal") then
            OrderByDocNoAndLineNo := true;
        with GenJnlBatch do begin
            GenJnlTemplate.Get("Journal Template Name");
            GenJnlTemplate.TestField("Force Posting Report", false);

            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                exit;

            Find('-');
            repeat
                GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", Name);
                if OrderByDocNoAndLineNo then
                    GenJnlLine.SetCurrentKey("Document No.", "Line No.");
                if GenJnlLine.FindFirst then begin
                    GeneralLedgerSetup.Get();
                    if GeneralLedgerSetup."Post with Job Queue" then begin
                        // Add job queue entry for each document no.
                        GenJnlLine.SetCurrentKey("Document No.");
                        while GenJnlLine.FindFirst() do begin
                            GenJnlsScheduled := true;
                            GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                            GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
                        end;
                        GenJnlLine.SetFilter("Document No.", '<>%1', '');
                    end else begin
                        Clear(GenJnlPostBatch);
                        if GenJnlPostBatch.Run(GenJnlLine) then
                            Mark(false)
                        else begin
                            Mark(true);
                            JnlWithErrors := true;
                        end;
                    end;
                end;
            until Next = 0;

            if GenJnlsScheduled then
                Message(JournalsScheduledMsg);

            if not GeneralLedgerSetup."Post with Job Queue" then
                if not JnlWithErrors then
                    Message(Text001)
                else begin
                    MarkedOnly(true);
                    Message(
                      Text002 +
                      Text003);
                end;

            if not Find('=><') or GeneralLedgerSetup."Post with Job Queue" then begin
                Reset;
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                FilterGroup(0);
                Name := '';
            end;
        end;
    end;
}

