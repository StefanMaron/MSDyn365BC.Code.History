codeunit 5645 "FA Reclass. Jnl.-B.Transfer"
{
    TableNo = "FA Reclass. Journal Batch";

    trigger OnRun()
    begin
        FAReclassJnlBatch.Copy(Rec);
        Code();
        Copy(FAReclassJnlBatch);
    end;

    var
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        FAReclassTransferBatch: Codeunit "FA Reclass. Transfer Batch";
        JournalWithErrors: Boolean;

        Text000: Label 'Do you want to reclassify the journals?';
        Text001: Label 'The journals were successfully reclassified.';
        Text002: Label 'It was not possible to reclassify all of the journals. ';
        Text003: Label 'The journals that were not successfully reclassified are now marked.';

    local procedure "Code"()
    begin
        with FAReclassJnlBatch do begin
            FAReclassJnlTempl.Get("Journal Template Name");

            if not Confirm(Text000, false) then
                exit;

            Find('-');
            repeat
                FAReclassJnlLine."Journal Template Name" := "Journal Template Name";
                FAReclassJnlLine."Journal Batch Name" := Name;
                FAReclassJnlLine."Line No." := 1;

                Clear(FAReclassTransferBatch);
                if FAReclassTransferBatch.Run(FAReclassJnlLine) then
                    Mark(false)
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
}

