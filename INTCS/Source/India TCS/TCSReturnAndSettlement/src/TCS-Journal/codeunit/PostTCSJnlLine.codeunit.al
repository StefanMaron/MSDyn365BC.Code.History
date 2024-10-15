codeunit 18871 "Post-TCS Jnl. Line"
{

    procedure PostTCSJournal(var TJLine: Record "TCS Journal Line")
    var
        TCSJnlLine: Record "TCS Journal Line";
        LineCount: Integer;
        Window: Dialog;
    begin
        if not Confirm(PostTCSAdjQst) then
            Error('');
        TCSJnlLine.COPY(TJLine);
        if TCSJnlLine.FindFirst() then begin
            Window.Open(JnlBatchNameLbl + CheckLineLbl + PostLineLbl);
            LineCount := 0;
        end;
        repeat
            CheckLines(TCSJnlLine);
            LineCount := LineCount + 1;
            Window.Update(4, TCSJnlLine."Journal Batch Name");
            Window.Update(1, LineCount);
        until TCSJnlLine.Next() = 0;
        LineCount := 0;
        if TCSJnlLine.FindFirst() then
            repeat
                PostGenJnlLine(TCSJnlLine);
                LineCount := LineCount + 1;
                Window.Update(4, TCSJnlLine."Journal Batch Name");
                Window.Update(2, LineCount);
                Window.Update(3, ROUND(LineCount / TCSJnlLine.Count() * 10000, 1));
            until TCSJnlLine.Next() = 0;
        Clear(GenJnlPostLine);
        TCSJnlLine.DeleteAll(True);
        Window.Close();
        Message(JnlLinePostMsg);
        TJLine := TCSJnlLine;
    end;

    procedure CheckLines(var TCSJnlLine: Record "TCS Journal Line")
    begin
        TCSJnlLine.TestField("Document No.");
        TCSJnlLine.TestField("Posting Date");
        TCSJnlLine.TestField("Account No.");
        TCSJnlLine.TestField("Bal. Account No.");
        TCSJnlLine.TestField(Amount);
    end;

    procedure PostGenJnlLine(var TCSJnlLine: Record "TCS Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if (TCSJnlLine."Journal Batch Name" = '') and (TCSJnlLine."Journal Template Name" = '') then
            DocNo := TCSJnlLine."Document No."
        Else
            DocNo := CheckDocumentNo(TCSJnlLine);
        InitGenJnlLine(TCSJnlLine);
    end;

    procedure InitGenJnlLine(var TCSJnlLine: Record "TCS Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Batch Name" := TCSJnlLine."Journal Batch Name";
        GenJnlLine."Journal Template Name" := TCSJnlLine."Journal Template Name";
        GenJnlLine."Line No." := TCSJnlLine."Line No.";
        GenJnlLine."Account Type" := TCSJnlLine."Account Type";
        GenJnlLine."Account No." := TCSJnlLine."Account No.";
        GenJnlLine."Posting Date" := TCSJnlLine."Posting Date";
        GenJnlLine."Document Type" := TCSJnlLine."Document Type";
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."Posting No. Series" := TCSJnlLine."Posting No. Series";
        GenJnlLine.Description := TCSJnlLine.Description;
        GenJnlLine.Validate(Amount, TCSJnlLine.Amount);
        GenJnlLine."Bal. Account Type" := TCSJnlLine."Bal. Account Type";
        GenJnlLine."Bal. Account No." := TCSJnlLine."Bal. Account No.";
        GenJnlLine."Shortcut Dimension 1 Code" := TCSJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TCSJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := TCSJnlLine."Dimension Set ID";
        GenJnlLine."Document Date" := TCSJnlLine."Document Date";
        GenJnlLine."External Document No." := TCSJnlLine."External Document No.";
        GenJnlLine."Location Code" := TCSJnlLine."Location Code";
        GenJnlLine."Source Code" := TCSJnlLine."Source Code";
        GenJnlLine."System-Created Entry" := true;
        if TCSJnlLine."TCS Base Amount" = 0 then
            GenJnlLine."Allow Zero-Amount Posting" := True;
        RunGenJnlPostLine(GenJnlLine);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure CheckDocumentNo(TCSJnlLine: Record "TCS Journal Line"): Code[20]
    var
        TCSJnlBatch: Record "TCS Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        PostingNoSeriesNo: Integer;
    begin
        if (TCSJnlLine."Journal Template Name" = '') and (TCSJnlLine."Journal Batch Name" = '') and (TCSJnlLine."Document No." <> '') then
            exit(TCSJnlLine."Document No.");
        TCSJnlBatch.GET(TCSJnlLine."Journal Template Name", TCSJnlLine."Journal Batch Name");
        if TCSJnlLine."Posting No. Series" = '' then begin
            TCSJnlLine."Posting No. Series" := TCSJnlBatch."No. Series";
            TCSJnlLine."Document No." := NoSeriesMgt.GetNextNo(TCSJnlLine."Posting No. Series", TCSJnlLine."Posting Date", TRUE);
        end else
            iF TCSJnlLine."Document No." = LastDocNo then
                TCSJnlLine."Document No." := LastPostedDocNo
            else begin
                InsertNoSeries(TCSJnlLine);
                LastDocNo := TCSJnlLine."Document No.";
                Evaluate(PostingNoSeriesNo, TempNoSeries.Description);
                TCSJnlLine."Document No." :=
                  NoSeriesMgt2[PostingNoSeriesNo].GetNextNo(TCSJnlLine."Posting No. Series", TCSJnlLine."Posting Date", TRUE);
                LastPostedDocNo := TCSJnlLine."Document No.";
            end;
        exit(TCSJnlLine."Document No.");
    end;

    local procedure InsertNoSeries(TCSJnlLine: Record "TCS Journal Line")
    var
        NoOfPostingNoSeries: Integer;
    begin
        if Not TempNoSeries.Get(TCSJnlLine."Posting No. Series") then begin
            NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
            if NoOfPostingNoSeries > ARRAYLEN(NoSeriesMgt2) then
                Error(
                  PostingNoSeriesErr,
                  ARRAYLEN(NoSeriesMgt2));
            TempNoSeries.Init();
            TempNoSeries.Code := TCSJnlLine."Posting No. Series";
            TempNoSeries.Description := FORMAT(NoOfPostingNoSeries);
            TempNoSeries.Insert();
        end;
    end;

    var
        TempNoSeries: Record "No. Series" temporary;
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocNo: Code[20];
        CheckLineLbl: Label 'Checking lines        #1######\', Comment = '#1=Line check';
        PostLineLbl: Label 'Posting lines         #2###### @3@@@@@@@@@@@@@\', Comment = '#2=Post Line';
        JnlLinePostMsg: Label 'Journal lines posted successfully.';
        JnlBatchNameLbl: Label 'Journal Batch Name    #4##########\\', Comment = '#4=Journal Batch Name';
        PostTCSAdjQst: Label 'Do you want to post the journal lines?';
        PostingNoSeriesErr: Label 'A maximum of %1 posting number series can be used in each journal.', Comment = '%1Posting Number Series.,';
}