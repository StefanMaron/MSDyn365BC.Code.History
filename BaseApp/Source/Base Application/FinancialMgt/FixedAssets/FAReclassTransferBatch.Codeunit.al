codeunit 5643 "FA Reclass. Transfer Batch"
{
    Permissions = TableData "FA Reclass. Journal Batch" = rimd;
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    begin
        FAReclassJnlLine.Copy(Rec);
        Code();
        Rec := FAReclassJnlLine;
    end;

    var
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlLine2: Record "FA Reclass. Journal Line";
        FAReclassJnlLine3: Record "FA Reclass. Journal Line";
        FAReclassCheckLine: Codeunit "FA Reclass. Check Line";
        FAReclassTransferLine: Codeunit "FA Reclass. Transfer Line";
        Window: Dialog;
        OneFAReclassDone: Boolean;
        LineCounter: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;

        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';

    local procedure "Code"()
    begin
        with FAReclassJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LockTable();

            FAReclassJnlTempl.Get("Journal Template Name");
            FAReclassJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            if not Find('=><') then begin
                "Line No." := 0;
                exit;
            end;

            Window.Open(
              Text001 +
              Text002 +
              Text003);
            Window.Update(1, "Journal Batch Name");

            LineCounter := 0;
            StartLineNo := "Line No.";
            repeat
                LineCounter := LineCounter + 1;
                Window.Update(2, LineCounter);
                FAReclassCheckLine.Run(FAReclassJnlLine);
                if Next() = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            NoOfRecords := LineCounter;

            LineCounter := 0;
            OneFAReclassDone := false;
            SetCurrentKey("Journal Template Name", "Journal Batch Name", "FA Posting Date");
            Find('-');
            repeat
                LineCounter := LineCounter + 1;
                Window.Update(3, LineCounter);
                Window.Update(4, Round(LineCounter / NoOfRecords * 10000, 1));
                FAReclassTransferLine.FAReclassLine(FAReclassJnlLine, OneFAReclassDone);
            until Next() = 0;

            Init();
            if OneFAReclassDone then
                "Line No." := 1
            else
                "Line No." := 0;

            if OneFAReclassDone then begin
                FAReclassJnlLine2.CopyFilters(FAReclassJnlLine);
                FAReclassJnlLine2.SetFilter("FA No.", '<>%1', '');
                if FAReclassJnlLine2.FindLast() then; // Remember the last line
                DeleteAll();

                FAReclassJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
                FAReclassJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                if FAReclassJnlTempl."Increment Batch Name" then
                    if not FAReclassJnlLine3.FindLast() then
                        if IncStr("Journal Batch Name") <> '' then begin
                            FAReclassJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                            FAReclassJnlBatch.Delete();
                            FAReclassJnlBatch.Name := IncStr("Journal Batch Name");
                            if FAReclassJnlBatch.Insert() then;
                            "Journal Batch Name" := FAReclassJnlBatch.Name;
                        end;

                FAReclassJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                if not FAReclassJnlLine3.FindLast() then begin
                    FAReclassJnlLine3.Init();
                    FAReclassJnlLine3."Journal Template Name" := "Journal Template Name";
                    FAReclassJnlLine3."Journal Batch Name" := "Journal Batch Name";
                    FAReclassJnlLine3."Line No." := 10000;
                    FAReclassJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                    FAReclassJnlLine3."Posting Date" := FAReclassJnlLine2."Posting Date";
                    OnBeforeFAReclassJnlLineInsert(FAReclassJnlLine, FAReclassJnlLine2, FAReclassJnlLine3);
                    FAReclassJnlLine3.Insert();
                end;
            end;

            Commit();
            Clear(FAReclassCheckLine);
            Clear(FAReclassTransferLine);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAReclassJnlLineInsert(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var FAReclassJournalLine2: Record "FA Reclass. Journal Line"; var FAReclassJournalLine3: Record "FA Reclass. Journal Line")
    begin
    end;
}

