namespace Microsoft.FixedAssets.Journal;

codeunit 5644 "FA Reclass. Jnl.-Transfer"
{
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    begin
        FAReclassJnlLine.Copy(Rec);
        Code();
        Rec.Copy(FAReclassJnlLine);
    end;

    var
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        JnlBatchName2: Code[10];

        Text000: Label 'Do you want to reclassify the journal lines?';
        Text001: Label 'There is nothing to reclassify.';
        Text002: Label 'The journal lines were successfully reclassified.';
        Text003: Label 'The journal lines were successfully reclassified. You are now in the %1 journal.';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(FAReclassJnlLine, IsHandled);
        if IsHandled then
            exit;

        with FAReclassJnlLine do begin
            FAReclassJnlTempl.Get("Journal Template Name");

            if not Confirm(Text000, false) then
                exit;

            JnlBatchName2 := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"FA Reclass. Transfer Batch", FAReclassJnlLine);

            if "Line No." = 0 then
                Message(Text001)
            else
                if JnlBatchName2 = "Journal Batch Name" then
                    Message(Text002)
                else
                    Message(
                      Text003,
                      "Journal Batch Name");

            if not Find('=><') or (JnlBatchName2 <> "Journal Batch Name") then begin
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
    local procedure OnBeforeCode(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

