codeunit 231 "Gen. Jnl.-Post"
{
    EventSubscriberInstance = Manual;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Copy(Rec);
        Code(GenJnlLine);
        Copy(GenJnlLine);
    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
        Text005: Label 'Using %1 for Declining Balance can result in misleading numbers for subsequent years. You should manually check the postings and correct them if necessary. Do you want to continue?';
        Text006: Label '%1 in %2 must not be equal to %3 in %4.', Comment = 'Source Code in Genenral Journal Template must not be equal to Job G/L WIP in Source Code Setup.';
        GenJnlsScheduled: Boolean;
        PreviewMode: Boolean;

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        FALedgEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        ConfirmManagement: Codeunit "Confirm Management";
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        OnBeforeCode(GenJnlLine, HideDialog);

        with GenJnlLine do begin
            GenJnlTemplate.Get("Journal Template Name");
            if GenJnlTemplate.Type = GenJnlTemplate.Type::Jobs then begin
                SourceCodeSetup.Get();
                if GenJnlTemplate."Source Code" = SourceCodeSetup."Job G/L WIP" then
                    Error(Text006, GenJnlTemplate.FieldCaption("Source Code"), GenJnlTemplate.TableCaption(),
                      SourceCodeSetup.FieldCaption("Job G/L WIP"), SourceCodeSetup.TableCaption());
            end;
            GenJnlTemplate.TestField("Force Posting Report", false);
            if GenJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            OnCodeOnAfterCheckTemplate(GenJnlLine);

            if not (PreviewMode or HideDialog) then
                if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                    exit;

            if "Account Type" = "Account Type"::"Fixed Asset" then begin
                FALedgEntry.SetRange("FA No.", "Account No.");
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
                if FALedgEntry.FindFirst() and "Depr. Acquisition Cost" and not HideDialog then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text005, FieldCaption("Depr. Acquisition Cost")), true) then
                        exit;
            end;

            if not HideDialog then
                if not GenJnlPostBatch.ConfirmPostingUnvoidableChecks("Journal Batch Name", "Journal Template Name") then
                    exit;

            TempJnlBatchName := "Journal Batch Name";

            GeneralLedgerSetup.Get();
            GenJnlPostBatch.SetPreviewMode(PreviewMode);
            if GeneralLedgerSetup."Post with Job Queue" and not PreviewMode then begin
                // Add job queue entry for each document no.
                GenJnlLine.SetCurrentKey("Document No.");
                while GenJnlLine.FindFirst() do begin
                    GenJnlsScheduled := true;
                    GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                    GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
                end;

                if GenJnlsScheduled then
                    Message(JournalsScheduledMsg);
            end else begin
                IsHandled := false;
                OnBeforeGenJnlPostBatchRun(GenJnlLine, IsHandled);
                if IsHandled then
                    exit;

                GenJnlPostBatch.Run(GenJnlLine);

                OnCodeOnAfterGenJnlPostBatchRun(GenJnlLine);

                if PreviewMode then
                    exit;

                ShowPostResultMessage(GenJnlLine, TempJnlBatchName);
            end;

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") or GeneralLedgerSetup."Post with Job Queue" then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                OnGenJnlLineSetFilter(GenJnlLine);
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;

    local procedure ShowPostResultMessage(var GenJnlLine: Record "Gen. Journal Line"; TempJnlBatchName: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPostResultMessage(GenJnlLine, TempJnlBatchName, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do
            if "Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                    Text004,
                    "Journal Batch Name");
    end;

    procedure Preview(var GenJournalLineSource: Record "Gen. Journal Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        BindSubscription(GenJnlPost);
        GenJnlPostPreview.Preview(GenJnlPost, GenJournalLineSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostBatchRun(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostResultMessage(var GenJnlLine: Record "Gen. Journal Line"; TempJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGenJnlPostBatchRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheckTemplate(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        GenJnlPost := Subscriber;
        GenJournalLine.Copy(RecVar);
        PreviewMode := true;
        Result := GenJnlPost.Run(GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineSetFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

