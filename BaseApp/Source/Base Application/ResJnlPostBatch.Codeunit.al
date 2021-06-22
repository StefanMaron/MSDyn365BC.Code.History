codeunit 213 "Res. Jnl.-Post Batch"
{
    Permissions = TableData "Res. Journal Batch" = imd;
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        ResJnlLine.Copy(Rec);
        Code;
        Rec := ResJnlLine;
    end;

    var
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: Label 'A maximum of %1 posting number series can be used in each journal.';
        Text007: Label '<Month Text>', Locked = true;
        AccountingPeriod: Record "Accounting Period";
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        ResJnlLine2: Record "Res. Journal Line";
        ResJnlLine3: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        ResReg: Record "Resource Register";
        NoSeries: Record "No. Series" temporary;
        ResJnlCheckLine: Codeunit "Res. Jnl.-Check Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        Window: Dialog;
        ResRegNo: Integer;
        StartLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        LineCount: Integer;
        NoOfRecords: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        with ResJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LockTable();

            ResJnlTemplate.Get("Journal Template Name");
            ResJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            if ResJnlTemplate.Recurring then begin
                SetRange("Posting Date", 0D, WorkDate);
                SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
            end;

            if not Find('=><') then begin
                "Line No." := 0;
                Commit();
                exit;
            end;

            if ResJnlTemplate.Recurring then
                Window.Open(
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004)
            else
                Window.Open(
                  Text001 +
                  Text002 +
                  Text005);
            Window.Update(1, "Journal Batch Name");

            // Check lines
            LineCount := 0;
            StartLineNo := "Line No.";
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                CheckRecurringLine(ResJnlLine);
                ResJnlCheckLine.RunCheck(ResJnlLine);
                if Next = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            NoOfRecords := LineCount;

            // Find next register no.
            ResLedgEntry.LockTable();
            if ResLedgEntry.FindLast then;
            ResReg.LockTable();
            if ResReg.FindLast and (ResReg."To Entry No." = 0) then
                ResRegNo := ResReg."No."
            else
                ResRegNo := ResReg."No." + 1;

            // Post lines
            LineCount := 0;
            LastDocNo := '';
            LastDocNo2 := '';
            LastPostedDocNo := '';
            Find('-');
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                if not EmptyLine and
                   (ResJnlBatch."No. Series" <> '') and
                   ("Document No." <> LastDocNo2)
                then
                    TestField("Document No.", NoSeriesMgt.GetNextNo(ResJnlBatch."No. Series", "Posting Date", false));
                if not EmptyLine then
                    LastDocNo2 := "Document No.";
                MakeRecurringTexts(ResJnlLine);
                if "Posting No. Series" = '' then
                    "Posting No. Series" := ResJnlBatch."No. Series"
                else
                    if not EmptyLine then
                        if "Document No." = LastDocNo then
                            "Document No." := LastPostedDocNo
                        else begin
                            if not NoSeries.Get("Posting No. Series") then begin
                                NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
                                if NoOfPostingNoSeries > ArrayLen(NoSeriesMgt2) then
                                    Error(
                                      Text006,
                                      ArrayLen(NoSeriesMgt2));
                                NoSeries.Code := "Posting No. Series";
                                NoSeries.Description := Format(NoOfPostingNoSeries);
                                NoSeries.Insert();
                            end;
                            LastDocNo := "Document No.";
                            Evaluate(PostingNoSeriesNo, NoSeries.Description);
                            "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "Posting Date", false);
                            LastPostedDocNo := "Document No.";
                        end;
                ResJnlPostLine.RunWithCheck(ResJnlLine);
            until Next = 0;

            // Copy register no. and current journal batch name to the res. journal
            if not ResReg.FindLast or (ResReg."No." <> ResRegNo) then
                ResRegNo := 0;

            Init;
            "Line No." := ResRegNo;

            // Update/delete lines
            if ResRegNo <> 0 then
                if ResJnlTemplate.Recurring then begin
                    // Recurring journal
                    LineCount := 0;
                    ResJnlLine2.CopyFilters(ResJnlLine);
                    ResJnlLine2.Find('-');
                    repeat
                        LineCount := LineCount + 1;
                        Window.Update(5, LineCount);
                        Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                        if ResJnlLine2."Posting Date" <> 0D then
                            ResJnlLine2.Validate("Posting Date", CalcDate(ResJnlLine2."Recurring Frequency", ResJnlLine2."Posting Date"));
                        if (ResJnlLine2."Recurring Method" = ResJnlLine2."Recurring Method"::Variable) and
                           (ResJnlLine2."Resource No." <> '')
                        then begin
                            ResJnlLine2.Quantity := 0;
                            ResJnlLine2."Total Cost" := 0;
                            ResJnlLine2."Total Price" := 0;
                        end;
                        ResJnlLine2.Modify();
                    until ResJnlLine2.Next = 0;
                end else begin
                    // Not a recurring journal
                    ResJnlLine2.CopyFilters(ResJnlLine);
                    ResJnlLine2.SetFilter("Resource No.", '<>%1', '');
                    if ResJnlLine2.Find('+') then; // Remember the last line
                    ResJnlLine3.Copy(ResJnlLine);
                    ResJnlLine3.DeleteAll();
                    ResJnlLine3.Reset();
                    ResJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
                    ResJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                    if ResJnlTemplate."Increment Batch Name" then
                        if not ResJnlLine3.FindLast then
                            if IncStr("Journal Batch Name") <> '' then begin
                                ResJnlBatch.Delete();
                                ResJnlBatch.Name := IncStr("Journal Batch Name");
                                if ResJnlBatch.Insert() then;
                                "Journal Batch Name" := ResJnlBatch.Name;
                            end;

                    ResJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                    if (ResJnlBatch."No. Series" = '') and not ResJnlLine3.FindLast then begin
                        ResJnlLine3.Init();
                        ResJnlLine3."Journal Template Name" := "Journal Template Name";
                        ResJnlLine3."Journal Batch Name" := "Journal Batch Name";
                        ResJnlLine3."Line No." := 10000;
                        ResJnlLine3.Insert();
                        ResJnlLine3.SetUpNewLine(ResJnlLine2);
                        ResJnlLine3.Modify();
                    end;
                end;
            if ResJnlBatch."No. Series" <> '' then
                NoSeriesMgt.SaveNoSeries;
            if NoSeries.Find('-') then
                repeat
                    Evaluate(PostingNoSeriesNo, NoSeries.Description);
                    NoSeriesMgt2[PostingNoSeriesNo].SaveNoSeries;
                until NoSeries.Next = 0;

            Commit();
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        Commit();
    end;

    local procedure CheckRecurringLine(var ResJnlLine2: Record "Res. Journal Line")
    var
        DummyDateFormula: DateFormula;
    begin
        with ResJnlLine2 do
            if "Resource No." <> '' then
                if ResJnlTemplate.Recurring then begin
                    TestField("Recurring Method");
                    TestField("Recurring Frequency");
                    if "Recurring Method" = "Recurring Method"::Variable then
                        TestField(Quantity);
                end else begin
                    TestField("Recurring Method", 0);
                    TestField("Recurring Frequency", DummyDateFormula);
                end;
    end;

    local procedure MakeRecurringTexts(var ResJnlLine2: Record "Res. Journal Line")
    begin
        with ResJnlLine2 do
            if ("Resource No." <> '') and ("Recurring Method" <> 0) then begin // Not recurring
                Day := Date2DMY("Posting Date", 1);
                Week := Date2DWY("Posting Date", 2);
                Month := Date2DMY("Posting Date", 2);
                MonthText := Format("Posting Date", 0, Text007);
                AccountingPeriod.SetRange("Starting Date", 0D, "Posting Date");
                if not AccountingPeriod.FindLast then
                    AccountingPeriod.Name := '';
                "Document No." :=
                  DelChr(
                    PadStr(
                      StrSubstNo("Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen("Document No.")),
                    '>');
                Description :=
                  DelChr(
                    PadStr(
                      StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen(Description)),
                    '>');
            end;
    end;
}

