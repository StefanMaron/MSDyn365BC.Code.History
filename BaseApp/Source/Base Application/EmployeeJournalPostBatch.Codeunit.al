codeunit 17383 "Employee Journal - Post Batch"
{
    TableNo = "Employee Journal Line";

    trigger OnRun()
    begin
        EmplJnlLine.Copy(Rec);
        RunCode;
        Rec := EmplJnlLine;
    end;

    var
        EmplJnlTemplate: Record "Employee Journal Template";
        EmplJnlBatch: Record "Employee Journal Batch";
        EmplJnlLine: Record "Employee Journal Line";
        EmplJnlLine2: Record "Employee Journal Line";
        EmplJnlLine3: Record "Employee Journal Line";
        PayrollReg: Record "Payroll Register";
        NoSeries: Record "No. Series" temporary;
        EmplJnlCheckLine: Codeunit "Employee Journal - Check Line";
        EmplJnlPostLine: Codeunit "Employee Journal - Post Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        Window: Dialog;
        PayrollRegNo: Integer;
        StartLineNo: Integer;
        LineCount: Integer;
        NoOfRecords: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;
        Text000: Label 'cannot exceed %1 characters';
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: Label 'A maximum of %1 posting number series can be used in each journal.';

    local procedure RunCode()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        with EmplJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LockTable();

            EmplJnlTemplate.Get("Journal Template Name");
            EmplJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if StrLen(IncStr(EmplJnlBatch.Name)) > MaxStrLen(EmplJnlBatch.Name) then
                EmplJnlBatch.FieldError(
                  Name,
                  StrSubstNo(
                    Text000,
                    MaxStrLen(EmplJnlBatch.Name)));

            if not Find('=><') then begin
                "Line No." := 0;
                Commit();
                exit;
            end;

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
                EmplJnlCheckLine.Run(EmplJnlLine);
                if Next() = 0 then
                    Find('-');
            until "Line No." = StartLineNo;
            NoOfRecords := LineCount;

            // Find next register no.
            PayrollReg.LockTable();
            if PayrollReg.FindLast then
                PayrollRegNo := PayrollReg."No." + 1
            else
                PayrollRegNo := 1;

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
                   (EmplJnlBatch."No. Series" <> '') and
                   ("Document No." <> LastDocNo2)
                then
                    TestField("Document No.", NoSeriesMgt.GetNextNo(EmplJnlBatch."No. Series", "Posting Date", false));
                LastDocNo2 := "Document No.";
                if "Posting No. Series" = '' then
                    "Posting No. Series" := EmplJnlBatch."No. Series"
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
                EmplJnlPostLine.RunWithCheck(EmplJnlLine);
            until Next() = 0;

            // Copy register no. and current journal batch name to the Employee journal
            if not PayrollReg.FindLast or (PayrollReg."No." < PayrollRegNo) then
                PayrollRegNo := 0;

            Init;
            "Line No." := PayrollRegNo;

            // Update/delete lines
            if PayrollRegNo <> 0 then begin
                EmplJnlLine2.CopyFilters(EmplJnlLine);
                EmplJnlLine2.SetFilter("Employee No.", '<>%1', '');
                if EmplJnlLine2.FindLast then; // Remember the last line
                EmplJnlLine3.Copy(EmplJnlLine);
                if EmplJnlLine3.FindSet(true, false) then
                    repeat
                        EmplJnlLine3.Delete();
                    until EmplJnlLine3.Next() = 0;
                EmplJnlLine3.Reset();
                EmplJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
                EmplJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                if not EmplJnlLine3.Find('+') then
                    if IncStr("Journal Batch Name") <> '' then begin
                        EmplJnlBatch.Delete();
                        EmplJnlBatch.Name := IncStr("Journal Batch Name");
                        if EmplJnlBatch.Insert() then;
                        "Journal Batch Name" := EmplJnlBatch.Name;
                    end;

                EmplJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
                if (EmplJnlBatch."No. Series" = '') and not EmplJnlLine3.Find('+') then begin
                    EmplJnlLine3.Init();
                    EmplJnlLine3."Journal Template Name" := "Journal Template Name";
                    EmplJnlLine3."Journal Batch Name" := "Journal Batch Name";
                    EmplJnlLine3."Line No." := 10000;
                    EmplJnlLine3.Insert();
                    EmplJnlLine3.SetUpNewLine(EmplJnlLine2);
                    EmplJnlLine3.Modify();
                end;
            end;
            if EmplJnlBatch."No. Series" <> '' then
                NoSeriesMgt.SaveNoSeries;
            if NoSeries.Find('-') then
                repeat
                    Evaluate(PostingNoSeriesNo, NoSeries.Description);
                    NoSeriesMgt2[PostingNoSeriesNo].SaveNoSeries;
                until NoSeries.Next() = 0;

            Commit();
        end;
        UpdateAnalysisView.UpdateAll(0, true);
        Commit();
    end;
}

