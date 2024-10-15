codeunit 18748 "TDS Adjustment Post"
{
    var
        TempNoSeries: Record "No. Series" temporary;
        TDSJnlBatch: Record "TDS Journal Batch";
        NoSeriesMgt2: array[10] of Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocNo: Code[20];
        CheckLineLbl: Label 'Checking lines        #1######\', Comment = '#1=Line check';
        PostLineLbl: Label 'Posting lines         #2###### @3@@@@@@@@@@@@@\', Comment = '#2=Post Line';
        JnlLinePostMsg: Label 'Journal lines posted successfully.';
        JnlBatchNameLbl: Label 'Journal Batch Name    #4##########\\', Comment = '#4=Journal Batch Name';
        PostTDSAdjQst: Label 'Do you want to post the journal lines?';
        PostingNoSeriesErr: Label 'A maximum of %1 posting number series can be used in each journal.', Comment = '%1 Posting Number Series.,';

    procedure PostTaxJournal(var TDSJournalLine: Record "TDS Journal Line")
    var
        TDSJnlLine: Record "TDS Journal Line";
        LineCount: Integer;
        Window: Dialog;
    begin
        if not Confirm(PostTDSAdjQst) then
            Error('');
        CLEARALL();
        TDSJnlLine.Copy(TDSJournalLine);
        if TDSJnlLine.FindFirst() then begin
            Window.Open(JnlBatchNameLbl + CheckLineLbl + PostLineLbl);
            LineCount := 0;
        end;
        repeat
            CheckLine(TDSJnlLine);
            LineCount := LineCount + 1;
            Window.Update(4, TDSJnlLine."Journal Batch Name");
            Window.Update(1, LineCount);
        until TDSJnlLine.Next() = 0;
        LineCount := 0;
        if TDSJnlLine.FindFirst() then
            repeat
                PostGenJnlLine(TDSJnlLine);
                LineCount := LineCount + 1;
                Window.Update(4, TDSJnlLine."Journal Batch Name");
                Window.Update(2, LineCount);
                Window.Update(3, Round(LineCount / TDSJnlLine.Count() * 10000, 1));
            until TDSJnlLine.Next() = 0;
        TDSJnlLine.DeleteAll(true);
        Window.Close();
        Message(JnlLinePostMsg);
        TDSJournalLine := TDSJnlLine;
    end;

    procedure CheckLine(var TaxJnlLine: Record "TDS Journal Line")
    begin
        TaxJnlLine.TestField("Document No.");
        TaxJnlLine.TestField("Posting Date");
        TaxJnlLine.TestField("Account No.");
        TaxJnlLine.TestField("Bal. Account No.");
        TaxJnlLine.TestField(Amount);
    end;

    procedure PostGenJnlLine(var TDSJnlLine: Record "TDS Journal Line")
    begin
        IF (TDSJnlLine."Journal Batch Name" = '') and (TDSJnlLine."Journal Template Name" = '') then
            DocNo := TDSJnlLine."Document No."
        else
            DocNo := CheckDocumentNo(TDSJnlLine);
        InitGenJnlLine(TDSJnlLine);
    end;

    procedure InitGenJnlLine(var TDSJnlLine: Record "TDS Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Batch Name" := TDSJnlLine."Journal Batch Name";
        GenJnlLine."Journal Template Name" := TDSJnlLine."Journal Template Name";
        GenJnlLine."Line No." := TDSJnlLine."Line No.";
        GenJnlLine."Account Type" := TDSJnlLine."Account Type";
        GenJnlLine."Account No." := TDSJnlLine."Account No.";
        GenJnlLine."Posting Date" := TDSJnlLine."Posting Date";
        GenJnlLine."Document Type" := TDSJnlLine."Document Type";
        GenJnlLine."TDS Section Code" := TDSJnlLine."TDS Section Code";
        GenJnlLine."Work Tax Nature Of Deduction" := TDSJnlLine."Work Tax Nature Of Deduction";
        GenJnlLine."T.A.N. No." := TDSJnlLine."T.A.N. No.";
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."Posting No. Series" := TDSJnlLine."Posting No. Series";
        GenJnlLine.Description := TDSJnlLine.Description;
        GenJnlLine."TDS Adjustment" := true;
        GenJnlLine.VALIDATE(Amount, TDSJnlLine.Amount);
        GenJnlLine."Bal. Account Type" := TDSJnlLine."Bal. Account Type";
        GenJnlLine."Bal. Account No." := TDSJnlLine."Bal. Account No.";
        GenJnlLine."Shortcut Dimension 1 Code" := TDSJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TDSJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := TDSJnlLine."Dimension Set ID";
        GenJnlLine."Source Code" := TDSJnlLine."Source Code";
        GenJnlLine."Reason Code" := TDSJnlLine."Reason Code";
        GenJnlLine."Document Date" := TDSJnlLine."Document Date";
        GenJnlLine."External Document No." := TDSJnlLine."External Document No.";
        GenJnlLine."Location Code" := TDSJnlLine."Location Code";
        GenJnlLine."System-Created Entry" := true;
        if TDSJnlLine."TDS Base Amount" = 0 then
            GenJnlLine."Allow Zero-Amount Posting" := TRUE;
        RunGenJnlPostLine(GenJnlLine);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure CheckDocumentNo(TDSJnlLine2: Record "TDS Journal Line"): Code[20]
    var
        TDSJournalBatch: Record "TDS Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        PostingNoSeriesNo: Integer;
    begin
        if (TDSJnlLine2."Journal Template Name" = '') and (TDSJnlLine2."Journal Batch Name" = '') and (TDSJnlLine2."Document No." <> '') then
            exit(TDSJnlLine2."Document No.");
        TDSJournalBatch.GET(TDSJnlLine2."Journal Template Name", TDSJnlLine2."Journal Batch Name");
        if TDSJnlLine2."Posting No. Series" = '' then begin
            TDSJnlLine2."Posting No. Series" := TDSJournalBatch."No. Series";
            TDSJnlLine2."Document No." := NoSeriesMgt.GetNextNo(TDSJnlLine2."Posting No. Series", TDSJnlLine2."Posting Date", TRUE);
        end else
            if TDSJnlLine2."Document No." = LastDocNo then
                TDSJnlLine2."Document No." := ''
            else begin
                InsertNoSeries(TDSJnlLine2);
                LastDocNo := TDSJnlLine2."Document No.";
                EVALUATE(PostingNoSeriesNo, TempNoSeries.Description);
                TDSJnlLine2."Document No." :=
                  NoSeriesMgt2[PostingNoSeriesNo].GetNextNo(TDSJnlLine2."Posting No. Series", TDSJnlLine2."Posting Date", TRUE);
                LastPostedDocNo := TDSJnlLine2."Document No.";
            end;
        exit(TDSJnlLine2."Document No.");
    end;

    local procedure InsertNoSeries(TDSJnlLine: Record "TDS Journal Line")
    var
        NoOfPostingNoSeries: Integer;
    begin
        if not TempNoSeries.GET(TDSJnlLine."Posting No. Series") then begin
            NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
            if NoOfPostingNoSeries > ArrayLen(NoSeriesMgt2) then
                Error(
                  PostingNoSeriesErr,
                  ArrayLen(NoSeriesMgt2));
            TempNoSeries.Init();
            TempNoSeries.Code := TDSJnlLine."Posting No. Series";
            TempNoSeries.Description := Format(NoOfPostingNoSeries);
            TempNoSeries.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnCodeOnBeforeFinishPosting', '', false, false)]
    local procedure InsertTDSEntry(var GenJournalLine: Record "Gen. Journal Line"; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        TDSEntry: Record "TDS Entry";
        TDSConcessionalCode: Record "TDS Concessional Code";
        AllowedSections: Record "Allowed Sections";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        TDSJnlLine: Record "TDS Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        TDSJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        TDSJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        TDSJnlLine.SetRange("Line No.", GenJournalLine."Line No.");
        if (TDSJnlLine.FindFirst()) and (TDSJnlLine."TDS Adjusted") then
            IF (GenJournalLine."TDS Section Code" <> '') and (GenJournalLine."TDS Adjustment") then begin
                TDSEntry.Init();
                TDSEntry."Entry No." := GetNextTDSEntryNo();
                TDSEntry."Document No." := GenJournalLine."Document No.";
                TDSEntry."Posting Date" := GenJournalLine."Posting Date";
                TDSEntry."Account Type" := TDSEntry."Account Type"::"G/L Account";
                TDSEntry."Account No." := TDSJnlLine."Bal. Account No.";
                TDSEntry."Vendor No." := TDSJnlLine."Account No.";
                TDSEntry.Description := TDSJnlLine.Description;
                TDSEntry."Party Type" := TDSEntry."Party Type"::Vendor;
                TDSEntry."Party Account No." := TDSJnlLine."Account No.";
                TDSEntry.Section := GenJournalLine."TDS Section Code";
                TDSEntry."TDS Adjustment" := TDSJnlLine."TDS Adjustment";
                TDSEntry."Transaction No." := sender.GetNextTransactionNo();
                TDSEntry."TDS %" := TDSJnlLine."TDS %";
                TDSEntry."Surcharge %" := TDSJnlLine."Surcharge %";
                TDSEntry."eCESS %" := TDSJnlLine."eCESS %";
                TDSEntry."SHE Cess %" := TDSJnlLine."SHE Cess %";
                TDSEntry."Assessee Code" := TDSJnlLine."Assessee Code";
                TDSEntry."Work Tax Nature Of Deduction" := TDSJnlLine."Work Tax Nature Of Deduction";
                TDSEntry."Work Tax %" := TDSJnlLine."Work Tax %";
                TDSEntry."Concessional Code" := TDSJnlLine."Concessional Code";
                TDSEntry."TDS Adjustment" := GenJournalLine."TDS Adjustment";
                if Vendor.GET(TDSJnlLine."Account No.") then
                    TDSEntry."Deductee PAN No." := Vendor."P.A.N. No.";
                if TDSJnlLine."Work Tax %" <> 0 then begin
                    TDSPostingSetup.SetRange("TDS Section", GenJournalLine."TDS Section Code");
                    if TDSPostingSetup.FindFirst() then
                        TDSEntry."Work Tax Account" := TDSPostingSetup."Work Tax Account";
                    TDSEntry."Work Tax Base Amount" := TDSJnlLine."TDS Base Amount";
                end;
                TDSEntry."TDS Base Amount" := TDSJnlLine."TDS Base Amount";
                TDSEntry."Invoice Amount" := abs(TDSJnlLine."TDS Base Amount");
                TDSEntry."Surcharge Base Amount" := abs(TDSJnlLine."Surcharge Base Amount");
                TDSEntry."TDS Line Amount" := TDSJnlLine.Amount;
                TDSEntry."Work Tax Base Amount" := ABS(TDSJnlLine."Work Tax Base Amount");
                TDSEntry."User ID" := CopyStr(UserId, 1, 50);
                TDSEntry."Concessional Code" := TDSJnlLine."Concessional Code";
                TDSConcessionalCode.SetRange(Section, GenJournalLine."TDS Section Code");
                TDSConcessionalCode.SetRange("Vendor No.", TDSJnlLine."Account No.");
                if TDSConcessionalCode.FindFirst() then
                    TDSEntry."Concessional Form No." := TDSConcessionalCode."Certificate No.";
                TDSEntry."T.A.N. No." := GenJournalLine."T.A.N. No.";
                TDSEntry.TestField("T.A.N. No.");
                TDSEntry."Per Contract" := TDSJnlLine."Per Contract";
                TDSEntry."Original TDS Base Amount" := TDSEntry."TDS Base Amount";
                TDSEntry.Insert(true);
            END;
    END;

    local procedure GetNextTDSEntryNo(): Integer
    var
        TDSEntry: Record "TDS Entry";
    begin
        IF TDSEntry.FindLast() then
            exit(TDSEntry."Entry No." + 1)
        else
            exit(1);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnCodeOnBeforeFinishPosting', '', false, false)]
    local procedure InsertWorkTaxEntry(var GenJournalLine: Record "Gen. Journal Line"; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        TDSEntry: Record "TDS Entry";
        TDSJnlLine: Record "TDS Journal Line";
        TDSConcessionalCode: Record "TDS Concessional Code";
        Location: Record Location;
        CompInfo: Record "Company Information";
    begin
        if GenJournalLine."TDS Section Code" <> '' then
            if GenJournalLine."Work Tax Nature Of Deduction" <> '' then begin
                TDSJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                TDSJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
                TDSJnlLine.SetRange("Line No.", GenJournalLine."Line No.");
                if (TDSJnlLine.FindFirst()) and (TDSJnlLine."Work Tax") then begin
                    TDSEntry.Init();
                    TDSEntry."Entry No." := GetNextTDSEntryNo();
                    TDSEntry."Document Type" := TDSJnlLine."Document Type";
                    TDSEntry."Document No." := GenJournalLine."Document No.";
                    TDSEntry."Posting Date" := TDSJnlLine."Posting Date";
                    TDSEntry."Account Type" := TDSEntry."Account Type"::"G/L Account";
                    TDSEntry."Account No." := TDSJnlLine."Bal. Account No.";
                    TDSEntry.Description := TDSJnlLine.Description;
                    TDSEntry."Party Type" := TDSEntry."Party Type"::Vendor;
                    TDSEntry."Party Code" := TDSJnlLine."Account No.";
                    TDSEntry."Vendor No." := TDSJnlLine."Account No.";
                    TDSEntry.Section := TDSJnlLine."TDS Section Code";
                    TDSEntry."Assessee Code" := TDSJnlLine."Assessee Code";
                    TDSEntry."Transaction No." := sender.GetNextTransactionNo();
                    TDSEntry."Party Account No." := TDSJnlLine."Account No.";
                    TDSEntry."Work Tax Nature Of Deduction" := TDSJnlLine."Work Tax Nature Of Deduction";
                    TDSEntry."TDS Line Amount" := TDSJnlLine."TDS Amount";
                    TDSEntry."Work Tax %" := TDSJnlLine."Work Tax %";
                    TDSEntry."Work Tax Account" := TDSJnlLine."Bal. Account No.";
                    TDSEntry."Work Tax Base Amount" := ABS(TDSJnlLine."Work Tax Base Amount");
                    TDSEntry."User ID" := CopyStr(UserId, 1, 50);
                    TDSConcessionalCode.SetRange(Section, GenJournalLine."TDS Section Code");
                    TDSConcessionalCode.SetRange("Vendor No.", TDSJnlLine."Account No.");
                    if TDSConcessionalCode.FindFirst() then begin
                        TDSEntry."Concessional Code" := TDSConcessionalCode."Concessional Code";
                        TDSEntry."Concessional Form No." := TDSConcessionalCode."Certificate No.";
                    end;
                    TDSEntry."T.A.N. No." := TDSJnlLine."T.A.N. No.";
                    TDSEntry.TestField("T.A.N. No.");
                    TDSEntry.Insert(true);
                end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure UpdateTDSEntry(var GenJournalLine: Record "Gen. Journal Line")
    var
        TDSJnlLine: Record "TDS Journal Line";
        TDSEntry: Record "TDS Entry";
    begin
        TDSJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        TDSJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        TDSJnlLine.SetRange("Line No.", GenJournalLine."Line No.");
        if not TDSJnlLine.FindFirst() then
            exit;
        if TDSJnlLine.Adjustment then begin
            TDSEntry.Reset();
            TDSEntry.SetRange("Entry No.", TDSJnlLine."TDS Transaction No.");
            TDSEntry.SetRange("Document No.", TDSJnlLine."TDS Invoice No.");
            if TDSEntry.FindFirst() then begin
                TDSEntry.TestField("TDS Paid", false);
                TDSEntry."Challan Date" := TDSJnlLine."Challan Date";
                TDSEntry."Challan No." := TDSJnlLine."Challan No.";

                if TDSJnlLine."TDS % Applied" <> 0 then
                    TDSEntry."Adjusted TDS %" := TDSJnlLine."TDS % Applied"
                else
                    if (TDSJnlLine."TDS Adjusted") and (TDSJnlLine."TDS % Applied" = 0) then
                        TDSEntry."Adjusted TDS %" := TDSJnlLine."TDS % Applied"
                    else
                        if (not TDSJnlLine."TDS Adjusted") and (TDSJnlLine."TDS % Applied" = 0) then
                            TDSEntry."Adjusted TDS %" := TDSEntry."TDS %";

                if TDSJnlLine."Surcharge % Applied" <> 0 then
                    TDSEntry."Adjusted Surcharge %" := TDSJnlLine."Surcharge % Applied"
                else
                    if (TDSJnlLine."Surcharge Adjusted") and (TDSJnlLine."Surcharge % Applied" = 0) then
                        TDSEntry."Adjusted Surcharge %" := TDSJnlLine."Surcharge % Applied"
                    else
                        if (not TDSJnlLine."Surcharge Adjusted") and (TDSJnlLine."Surcharge % Applied" = 0) then
                            TDSEntry."Adjusted Surcharge %" := TDSEntry."Surcharge %";

                if TDSJnlLine."eCESS % Applied" <> 0 then
                    TDSEntry."Adjusted eCESS %" := TDSJnlLine."eCESS % Applied"
                else
                    if (TDSJnlLine."TDS eCess Adjusted") and (TDSJnlLine."eCESS % Applied" = 0) then
                        TDSEntry."Adjusted eCESS %" := TDSJnlLine."eCESS % Applied"
                    else
                        if (not TDSJnlLine."TDS eCess Adjusted") and (TDSJnlLine."eCESS % Applied" = 0) then
                            TDSEntry."Adjusted eCESS %" := TDSEntry."eCESS %";

                if TDSJnlLine."SHE Cess % Applied" <> 0 then
                    TDSEntry."Adjusted SHE CESS %" := TDSJnlLine."SHE Cess % Applied"
                else
                    if (TDSJnlLine."TDS SHE Cess Adjusted") and (TDSJnlLine."SHE Cess % Applied" = 0) then
                        TDSEntry."Adjusted SHE CESS %" := TDSJnlLine."SHE Cess % Applied"
                    else
                        if (not TDSJnlLine."TDS SHE Cess Adjusted") and (TDSJnlLine."SHE Cess % Applied" = 0) then
                            TDSEntry."Adjusted SHE CESS %" := TDSEntry."SHE Cess %";
                if TDSJnlLine."Work Tax" then begin
                    if TDSJnlLine.Adjustment and (TDSJnlLine."Work Tax % Applied" <> 0) then
                        TDSEntry."Adjusted Work Tax %" := TDSJnlLine."Work Tax % Applied";
                    if TDSJnlLine.Adjustment and (TDSJnlLine."Work Tax % Applied" = 0) and not TDSJnlLine."Reverse Work Tax" then
                        TDSEntry."Adjusted Work Tax %" := TDSJnlLine."Work Tax %";
                    if TDSJnlLine.Adjustment and (TDSJnlLine."Work Tax % Applied" = 0) and TDSJnlLine."Reverse Work Tax" then
                        TDSEntry."Adjusted Work Tax %" := TDSJnlLine."Work Tax %";
                    TDSEntry."Balance Work Tax Amount" := TDSJnlLine."W.T Amount";
                    TDSEntry."Work Tax Amount" := TDSEntry."Balance Work Tax Amount";
                    if TDSJnlLine."Work Tax Base Amount Adjusted" then begin
                        TDSEntry."Original Work Tax Base Amount" := TDSEntry."Work Tax Base Amount";
                        TDSEntry."Work Tax Base Amount" := TDSJnlLine."Work Tax Base Amount Applied";
                        TDSEntry."Work Tax Base Amount Adjusted" := TDSJnlLine."Work Tax Base Amount Adjusted";
                        TDSEntry."Work Tax Amount" := TDSJnlLine."W.T Amount";
                    end;
                end;
                if not TDSJnlLine."Work Tax" then begin
                    if (TDSJnlLine."Balance TDS Amount" <> 0) OR TDSJnlLine."TDS Adjusted" then
                        TDSEntry."TDS Amount" := TDSJnlLine."Balance TDS Amount";
                    TDSEntry."Remaining TDS Amount" := TDSEntry."TDS Amount";
                    if (TDSJnlLine."Balance Surcharge Amount" <> 0) OR TDSJnlLine."Surcharge Adjusted" then
                        TDSEntry."Surcharge Amount" := TDSJnlLine."Balance Surcharge Amount";
                    if (TDSJnlLine."Balance eCESS on TDS Amt" <> 0) OR TDSJnlLine."TDS eCess Adjusted" then
                        TDSEntry."eCESS Amount" := TDSJnlLine."Balance eCESS on TDS Amt";
                    if (TDSJnlLine."Bal. SHE Cess on TDS Amt" <> 0) OR TDSJnlLine."TDS SHE Cess Adjusted" then
                        TDSEntry."SHE Cess Amount" := TDSJnlLine."Bal. SHE Cess on TDS Amt";
                    TDSEntry."Remaining Surcharge Amount" := TDSEntry."Surcharge Amount";
                    TDSEntry."TDS Amount Including Surcharge" := TDSEntry."TDS Amount" + TDSEntry."Surcharge Amount";
                    TDSEntry."Total TDS Including SHE CESS" := TDSJnlLine."Bal. TDS Including SHE CESS";
                    TDSEntry."Bal. TDS Including SHE CESS" := TDSJnlLine."Bal. TDS Including SHE CESS";
                    TDSEntry.Adjusted := TDSJnlLine.Adjustment;
                    if TDSJnlLine."TDS Base Amount Adjusted" then begin
                        TDSEntry."TDS Base Amount" := TDSJnlLine."TDS Base Amount Applied";
                        TDSEntry."Invoice Amount" := TDSEntry."TDS Base Amount";
                        TDSEntry."TDS Base Amount Adjusted" := TDSJnlLine."TDS Base Amount Adjusted";
                        TDSEntry."Surcharge Base Amount" := TDSJnlLine."Surcharge Base Amount";
                    end;
                    if TDSJnlLine."TDS Adjusted" then
                        TDSEntry."Surcharge Base Amount" := TDSJnlLine."Surcharge Base Amount";
                end;
                TDSEntry.Modify()
            end;
        end;
    end;
}