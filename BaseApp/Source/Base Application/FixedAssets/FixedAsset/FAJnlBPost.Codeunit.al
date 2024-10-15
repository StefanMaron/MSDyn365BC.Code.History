namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;

codeunit 5637 "FA. Jnl.-B.Post"
{
    TableNo = "FA Journal Batch";

    trigger OnRun()
    begin
        FAJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(FAJnlBatch);
    end;

    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAJnlLine: Record "FA Journal Line";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
        JournalWithErrors: Boolean;

        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';

    local procedure "Code"()
    var
        DeprBook: Record "Depreciation Book";
    begin
        with FAJnlBatch do begin
            FAJnlTemplate.Get("Journal Template Name");
            FAJnlTemplate.TestField("Force Posting Report", false);

            if not Confirm(Text000, false) then
                exit;

            DeprBook.CompressingWarning();
            Find('-');
            repeat
                FAJnlLine."Journal Template Name" := "Journal Template Name";
                FAJnlLine."Journal Batch Name" := Name;
                FAJnlLine."Line No." := 1;
                Clear(FAJnlPostBatch);
                if FAJnlPostBatch.Run(FAJnlLine) then
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

