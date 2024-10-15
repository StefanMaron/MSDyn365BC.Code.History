codeunit 17301 "Tax Diff.-Post Jnl. Line"
{
    Permissions = TableData "FA Ledger Entry" = rm,
                  TableData "Tax Diff. Register" = imd,
                  TableData "Tax Diff. Ledger Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffReg: Record "Tax Diff. Register";
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
        FE: Record "Fixed Asset";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NextEntryNo: Integer;
        Text1003: Label '=%1 can not be less than %2=%3';
        Text1004: Label 'Wrong posting order. Start balance of tax difference changed.';
        Text1005: Label 'must be %1';
        Text1006: Label 'Depr. bonus for %1 has been already recovered.';

    local procedure "Code"()
    var
        TaxDiffPostGroup: Record "Tax Diff. Posting Group";
        PostingDate: Date;
    begin
        CheckJnlLine;

        with TaxDiffEntry do begin
            if NextEntryNo = 0 then begin
                LockTable;
                if FindLast then
                    NextEntryNo := "Entry No.";

                TaxDiffReg.LockTable;
                if TaxDiffReg.FindLast then
                    TaxDiffReg."No." := TaxDiffReg."No." + 1
                else
                    TaxDiffReg."No." := 1;
                TaxDiffReg.Init;
                TaxDiffReg."Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
                TaxDiffReg."Creation Date" := Today;
                TaxDiffReg."User ID" := UserId;
                TaxDiffReg.Insert;
            end;
            NextEntryNo := NextEntryNo + 1;

            Init;
            TransferFields(TaxDiffJnlLine, false);
            "Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
            "Transaction No." := 0;
            "Entry No." := NextEntryNo;
        end;

        with TaxDiffJnlLine do begin
            TaxDiffPostGroup.Get("Tax Diff. Posting Group");

            PostingDate := "Posting Date";
            case "Tax Diff. Type" of
                "Tax Diff. Type"::Constant:
                    begin
                        if "Asset Tax Amount" <> 0 then begin
                            TaxDiffPostGroup.TestField("CTA Tax Account");
                            TaxDiffPostGroup.TestField("CTA Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."CTA Tax Account",
                              TaxDiffPostGroup."CTA Account",
                              "Asset Tax Amount", PostingDate);
                        end;
                        if "Liability Tax Amount" <> 0 then begin
                            TaxDiffPostGroup.TestField("CTL Tax Account");
                            TaxDiffPostGroup.TestField("CTL Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."CTL Account",
                              TaxDiffPostGroup."CTL Tax Account",
                              "Liability Tax Amount", PostingDate);
                        end;
                    end;
                "Tax Diff. Type"::"Temporary":
                    begin
                        if "Asset Tax Amount" <> 0 then begin
                            TaxDiffPostGroup.TestField("DTA Tax Account");
                            TaxDiffPostGroup.TestField("DTA Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTA Account",
                              TaxDiffPostGroup."DTA Tax Account",
                              "Asset Tax Amount", PostingDate);
                        end;
                        if "Liability Tax Amount" <> 0 then begin
                            TaxDiffPostGroup.TestField("DTL Tax Account");
                            TaxDiffPostGroup.TestField("DTL Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTL Tax Account",
                              TaxDiffPostGroup."DTL Account",
                              "Liability Tax Amount", PostingDate);
                        end;
                        if "Disposal Date" <> 0D then
                            PostingDate := "Disposal Date";
                        if "Disposal Mode" = "Disposal Mode"::"Write Down" then begin
                            if "Disposal Tax Amount" > 0 then begin
                                TestField("DTL Ending Balance", 0);
                                TaxDiffPostGroup.TestField("DTA Disposal Account");
                                TaxDiffPostGroup.TestField("DTA Account");
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."DTA Disposal Account",
                                  TaxDiffPostGroup."DTA Account",
                                  "Disposal Tax Amount", PostingDate);
                            end;
                            if "Disposal Tax Amount" < 0 then begin
                                TestField("DTA Ending Balance", 0);
                                TaxDiffPostGroup.TestField("DTL Disposal Account");
                                TaxDiffPostGroup.TestField("DTL Account");
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."DTL Account",
                                  TaxDiffPostGroup."DTL Disposal Account",
                                  -"Disposal Tax Amount", PostingDate);
                            end;
                        end;
                        if "Disposal Mode" = "Disposal Mode"::Transform then begin
                            if "Disposal Tax Amount" > 0 then begin
                                TestField("DTL Ending Balance", 0);
                                TaxDiffPostGroup.TestField("DTA Transfer Bal. Account");
                                TaxDiffPostGroup.TestField("DTA Account");
                                TaxDiffPostGroup.TestField("CTL Transfer Tax Account");
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."DTA Transfer Bal. Account",
                                  TaxDiffPostGroup."DTA Account",
                                  "Disposal Tax Amount", PostingDate);
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."CTL Transfer Tax Account",
                                  TaxDiffPostGroup."DTA Transfer Bal. Account",
                                  "Disposal Tax Amount", PostingDate);
                            end;
                            if "Disposal Tax Amount" < 0 then begin
                                TestField("DTA Ending Balance", 0);
                                TaxDiffPostGroup.TestField("DTL Transfer Bal. Account");
                                TaxDiffPostGroup.TestField("DTL Account");
                                TaxDiffPostGroup.TestField("CTA Transfer Tax Account");
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."DTL Account",
                                  TaxDiffPostGroup."DTL Transfer Bal. Account",
                                  -"Disposal Tax Amount", PostingDate);
                                GenJnlLineCreate(
                                  TaxDiffPostGroup."DTL Transfer Bal. Account",
                                  TaxDiffPostGroup."CTA Transfer Tax Account",
                                  -"Disposal Tax Amount", PostingDate);
                            end;
                        end;
                    end;
            end;
        end;

        TaxDiffEntry.Insert;

        with TaxDiffReg do begin
            Get("No.");
            if "From Entry No." = 0 then
                "From Entry No." := NextEntryNo;
            "To Entry No." := NextEntryNo;
            Modify;
        end;
    end;

    local procedure GenJnlLineCreate(AccountNo: Code[20]; BalAccountNo: Code[20]; PostingAmount: Decimal; PostingDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GenJnlLine.Init;
        GenJnlLine."Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine.Description := TaxDiffJnlLine.Description;
        GenJnlLine."Reason Code" := TaxDiffJnlLine."Reason Code";
        GenJnlLine."Document No." := TaxDiffJnlLine."Document No.";
        GenJnlLine."Account No." := AccountNo;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Amount := PostingAmount;
        GenJnlLine."Shortcut Dimension 1 Code" := TaxDiffJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TaxDiffJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Source Code" := TaxDiffJnlLine."Source Code";
        GenJnlLine."Bal. Account No." := BalAccountNo;
        GenJnlLine."Dimension Set ID" := TaxDiffJnlLine."Dimension Set ID";

        GenJnlPostLine.RunWithCheck(GenJnlLine);

        if TaxDiffEntry."Transaction No." = 0 then begin
            GenJnlPostLine.GetGLReg(GLReg);
            GLEntry.Get(GLReg."To Entry No.");
            TaxDiffEntry."Transaction No." := GLEntry."Transaction No.";
        end;
    end;

    local procedure CheckJnlLine()
    var
        TaxDiffJnlLine0: Record "Tax Diff. Journal Line";
    begin
        with TaxDiffJnlLine do begin
            TestField("Posting Date");
            TestField("Document No.");
            TestField("Tax Diff. Code");
            TestField("Tax Factor");
            TestField("Tax Diff. Posting Group");

            if "Source Type" <> "Source Type"::" " then
                TestField("Source No.");

            if ("Source Type" = "Source Type"::"Future Expense") and ("Source No." <> '') then begin
                FE.Get("Source No.");
                FE.TestField("Tax Difference Code");
                TestField("Tax Diff. Code", FE."Tax Difference Code");
            end;

            if "Source No." <> '' then
                DeprBonusRecover;

            if "Disposal Date" <> 0D then
                if "Disposal Mode" = "Disposal Mode"::" " then
                    TestField("Disposal Date", 0D)
                else
                    if "Disposal Date" < "Posting Date" then
                        FieldError(
                          "Disposal Date", StrSubstNo(Text1003, "Disposal Date", FieldCaption("Posting Date"), "Posting Date"));

            if "Partial Disposal" then
                TestField("Disposal Mode");

            TaxDiffJnlLine0 := TaxDiffJnlLine;
            TaxDiffJnlLine0."DTA Starting Balance" := 0;
            TaxDiffJnlLine0."DTL Starting Balance" := 0;
            TaxDiffJnlLine0."Partial Disposal" := false;
            TaxDiffJnlLine0.GetStartingAmount;
            if "Partial Disposal" then
                PreparePartiotionalDisposal
            else
                if (TaxDiffJnlLine0."DTA Starting Balance" <> "DTA Starting Balance") or
                   (TaxDiffJnlLine0."DTL Starting Balance" <> "DTL Starting Balance")
                then
                    Error(Text1004);
        end;
    end;

    [Scope('OnPrem')]
    procedure RunWithCheck(var Rec: Record "Tax Diff. Journal Line")
    begin
        TaxDiffJnlLine.Copy(Rec);
        Code;
        Rec := TaxDiffJnlLine;
    end;

    local procedure PreparePartiotionalDisposal()
    begin
        if TaxDiffJnlLine."Disposal Tax Amount" < 0 then
            TaxDiffJnlLine."DTL Ending Balance" := -TaxDiffJnlLine."Disposal Tax Amount"
        else
            TaxDiffJnlLine."DTA Ending Balance" := TaxDiffJnlLine."Disposal Tax Amount";
    end;

    local procedure DeprBonusRecover()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        with TaxDiffJnlLine do
            if "Depr. Bonus Recovery" then begin
                TaxRegisterSetup.Get;
                TaxRegisterSetup.TestField("Tax Depreciation Book");
                FALedgerEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
                FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                FALedgerEntry.SetRange("FA No.", "Source No.");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                FALedgerEntry.SetRange("Depr. Bonus", true);
                FALedgerEntry.CalcSums(Amount);

                if "Amount (Tax)" <> -FALedgerEntry.Amount then
                    FieldError("Amount (Tax)", StrSubstNo(Text1005, -FALedgerEntry.Amount));

                if FALedgerEntry.FindSet then
                    repeat
                        if FALedgerEntry."Depr. Bonus Recovery Date" <> 0D then
                            Error(Text1006, "Source No.");
                    until FALedgerEntry.Next = 0;
                FALedgerEntry.ModifyAll("Depr. Bonus Recovery Date", "Posting Date");
            end;
    end;
}

