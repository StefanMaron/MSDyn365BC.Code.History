codeunit 18247 "Validate Bank Charges Amount"
{
    [EventSubscriber(ObjectType::Table, database::"Journal Bank Charges", 'OnBeforeValidateEvent', 'Amount', false, false)]
    Local procedure CheckValidation(var Rec: Record "Journal Bank Charges")
    var
        JnlBankChargesDummy: Record "Journal Bank Charges";
        GenJnlLine: Record "Gen. Journal Line";
        JnlBankCharges: Record "Journal Bank Charges";
    begin
        JnlBankChargesDummy.setrange("Journal Template Name", Rec."Journal Template Name");
        JnlBankChargesDummy.setrange("Journal Batch Name", Rec."Journal Batch Name");
        JnlBankChargesDummy.setrange("Line No.", Rec."Line No.");
        JnlBankChargesDummy.setrange("Foreign Exchange", true);
        if JnlBankChargesDummy.Count > 1 then
            Error(GSTBankChargeFxBoolErr);
        JnlBankChargesDummy.setrange("Foreign Exchange");
        GenJnlLine.Get(rec."Journal Template Name", rec."Journal Batch Name", Rec."Line No.");
        if GenJnlLine."Bank Charge" and (JnlBankChargesDummy.Count > 1) then
            error(GSTBankChargeBoolErr);
        if JnlBankChargesDummy.FindSet() then
            repeat
                JnlBankCharges.CheckBankChargeAmountSign(GenJnlLine, JnlBankChargesDummy);
                CalculateGSTAmounts(JnlBankChargesDummy);
            until JnlBankChargesDummy.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithoutCheck', '', false, false)]
    local procedure OnGenJnlPostLineOnAfterRunWithOutCheck(sender: Codeunit "Gen. Jnl.-Post Line")
    var
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
    begin
        JnlBankChargesSessionMgt.PostGSTBakChargesGenJournalLine(sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteGenJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            DeleteJournalBankCharges(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnBeforeBankAccLedgEntryInsert', '', false, false)]
    local procedure PostBankChargesEntries(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
        InitPostedJnlBankCharge(GenJournalLine, 1);
    end;

    [EventSubscriber(ObjectType::codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnBeforeBankAccLedgEntryInsert', '', false, false)]
    local procedure IncludeChargeAmount(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
        DummySignOfBankAccLedgAmount: Integer;
    begin
        BankChargeAmount := JnlBankChargesSessionMgt.GetBankChargeAmount();
        if BankChargeAmount <> 0 then
            UpdateBankChargeAmt(BankAccountLedgerEntry, GenJournalLine, GenJournalLine."Amount (LCY)", DummySignOfBankAccLedgAmount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Use Case Event Library", 'OnAddUseCaseEventstoLibrary', '', false, false)]
    local procedure OnAddUseCaseEventstoLibrary()
    var
        TaxUseCaseCU: Codeunit "Use Case Event Library";
    begin
        TaxUseCaseCU.AddUseCaseEventToLibrary('OnAfterAmountUpdate', Database::"Journal Bank Charges", 'After Update Amount For Bank Charges');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Journal Bank Charges", 'OnAfterValidateEvent', 'Amount', false, false)]
    local procedure HandleBankChargeUseCase(var Rec: Record "Journal Bank Charges")
    var
        GenJnlLine: Record "Gen. Journal Line";
        TaxCaseExecution: Codeunit "Use Case Execution";
    begin
        if GenJnlLine.Get(Rec."Journal Template Name", Rec."Journal Batch Name", rec."Line No.") then;
        TaxCaseExecution.HandleEvent('OnAfterAmountUpdate', Rec, GenJnlLine."Currency Code", GenJnlLine."Currency Factor");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tax Transaction Value", 'OnBeforeTableFilterApplied', '', false, false)]
    local procedure OnBeforeTableFilterApplied(var TaxRecordID: RecordId; TemplateNameFilter: Text; BatchFilter: Text; LineNoFilter: Integer)
    var
        JnlBankCharges: Record "Journal Bank Charges";
    begin
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", TemplateNameFilter);
        JnlBankCharges.setrange("Journal Batch Name", BatchFilter);
        JnlBankCharges.setrange("Line No.", LineNoFilter);
        if JnlBankCharges.Findfirst() then
            TaxRecordID := JnlBankCharges.RecordId();
    end;

    [EventSubscriber(ObjectType::codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnBeforeInitBankAccLedgEntry', '', false, false)]
    local Procedure PostBankCharges(var GenJournalLine: Record "Gen. Journal Line"; var NextTransactionNo: Integer; var NextEntryNo: Integer)
    var
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
    begin
        JnlBankChargesSessionMgt.SetTransactionNo(NextTransactionNo);
        JnlBankChargesSessionMgt.SetNextEntryNo(NextEntryNo);
        InsertDetaildGSTBufferBankCharge(GenJournalLine);
        InitPostedJnlBankCharge(GenJournalLine, 0);
    end;

    local procedure InsertDetaildGSTBufferBankCharge(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
        JnlBankCharges: Record "Journal Bank Charges";
        TaxTransValue: Record "Tax Transaction Value";
        TaxTypeSetup: Record "Tax Type Setup";
        TaxComponent: Record "Tax Component";
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        Location: Record Location;
        BankAccount: Record "Bank Account";
        TaxRecordID: RecordId;
        GSTComponentCode: Text[10];
        LineNo: Integer;
    begin
        LineNo := GetDetailGSTEntryBufferNextLineNo();

        GLSetup.Get();
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJnlLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJnlLine."Line No.");
        if JnlBankCharges.Findset() then
            repeat
                TaxRecordID := JnlBankCharges.RecordId();
                if not TaxTypeSetup.Get() then
                    exit;

                TaxTypeSetup.TestField(code);
                TaxTransValue.Reset();
                TaxTransValue.setrange("Tax Type", TaxTypeSetup.Code);
                TaxTransValue.setrange("Tax Record ID", TaxRecordId);
                TaxTransValue.setrange("Value Type", TaxTransValue."Value Type"::COMPONENT);
                if TaxTransValue.Findset() then
                    repeat
                        TaxComponent.setrange("Tax Type", TaxTypeSetup.Code);
                        TaxComponent.setrange(ID, TaxTransValue."Value ID");
                        if TaxComponent.Findfirst() then
                            GSTComponentCode := TaxComponent.Name;

                        DetailedGSTEntryBuffer.Init();
                        DetailedGSTEntryBuffer."Entry No." := LineNo;
                        LineNo += 10000;
                        DetailedGSTEntryBuffer."Transaction Type" := DetailedGSTEntryBuffer."Transaction Type"::Purchase;
                        DetailedGSTEntryBuffer."Line No." := GenJnlLine."Line No.";
                        DetailedGSTEntryBuffer."Jnl. Bank Charge" := JnlBankCharges."Bank Charge";
                        DetailedGSTEntryBuffer."Bank Charge Entry" := True;
                        DetailedGSTEntryBuffer."Journal Template Name" := JnlBankCharges."Journal Template Name";
                        DetailedGSTEntryBuffer."Journal Batch Name" := JnlBankCharges."Journal Batch Name";
                        DetailedGSTEntryBuffer."Document No." := GenJnlLine."Document No.";
                        DetailedGSTEntryBuffer."Posting Date" := GenJnlLine."Posting Date";
                        DetailedGSTEntryBuffer."Source Type" := "Source Type"::"Bank Account";
                        DetailedGSTEntryBuffer."HSN/SAC Code" := JnlBankCharges."HSN/SAC Code";
                        DetailedGSTEntryBuffer."GST Group Type" := JnlBankCharges."GST Group Type";
                        DetailedGSTEntryBuffer."Location Code" := GenJnlLine."Location Code";
                        DetailedGSTEntryBuffer."GST Component Code" := GSTComponentCode;
                        DetailedGSTEntryBuffer."GST Group Code" := JnlBankCharges."GST Group Code";
                        DetailedGSTEntryBuffer."GST Base Amount" := JnlBankCharges."Amount (LCY)";
                        DetailedGSTEntryBuffer."GST %" := TaxTransValue.Percent;
                        DetailedGSTEntryBuffer.Quantity := 1;
                        if not JnlBankCharges.Exempted then
                            DetailedGSTEntryBuffer."GST Amount" := TaxTransValue.Amount
                        else
                            DetailedGSTEntryBuffer.Exempted := True;
                        DetailedGSTEntryBuffer."Currency Code" := GenJnlLine."Currency Code";
                        if DetailedGSTEntryBuffer."Currency Code" <> '' then
                            DetailedGSTEntryBuffer."Currency Factor" := GenJnlLine."Currency Factor"
                        else
                            DetailedGSTEntryBuffer."Currency Factor" := 1;
                        DetailedGSTEntryBuffer."GST Amount" := TaxTransValue.Amount;
                        DetailedGSTEntryBuffer."GST Rounding Precision" := GLSetup."GST Rounding Precision";
                        DetailedGSTEntryBuffer."GST Rounding Type" := GLSetup."GST Rounding Type";
                        DetailedGSTEntryBuffer."GST Inv. Rounding Precision" := JnlBankCharges."GST Inv. Rounding Precision";
                        DetailedGSTEntryBuffer."GST Inv. Rounding Type" := JnlBankCharges."GST Inv. Rounding Type";
                        DetailedGSTEntryBuffer."GST on Advance Payment" := GenJnlLine."GST on Advance Payment";
                        Location.Get(DetailedGSTEntryBuffer."Location Code");
                        DetailedGSTEntryBuffer."Location  Reg. No." := Location."GST Registration No.";
                        GenJnlLine.TestField("Location State Code");
                        DetailedGSTEntryBuffer."Location State Code" := GenJnlLine."Location State Code";
                        DetailedGSTEntryBuffer."Input Service Distribution" := GenJnlLine."GST Input Service Distribution";
                        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Bank Account" then
                            if GenJnlLine."Bal. Account No." <> '' then
                                BankAccount.Get(GenJnlLine."Bal. Account No.");
                        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Bank Account" then
                            if GenJnlLine."Account No." <> '' then
                                BankAccount.Get(GenJnlLine."Account No.");
                        DetailedGSTEntryBuffer."Buyer/Seller Reg. No." := BankAccount."GST Registration No.";
                        DetailedGSTEntryBuffer."Buyer/Seller State Code" := BankAccount."State Code";
                        DetailedGSTEntryBuffer."Source No." := BankAccount."No.";
                        if JnlBankCharges."GST Credit" = JnlBankCharges."GST Credit"::"Non-Availment" then
                            DetailedGSTEntryBuffer."Non-Availment" := True;
                        if DetailedGSTEntryBuffer."Non-Availment" then begin
                            DetailedGSTEntryBuffer."GST Input/Output Credit Amount" := 0;
                            DetailedGSTEntryBuffer."Amount Loaded on Item" := TaxTransValue.Amount
                        end else begin
                            DetailedGSTEntryBuffer."Amount Loaded on Item" := 0;
                            DetailedGSTEntryBuffer."GST Input/Output Credit Amount" := TaxTransValue.Amount;
                        end;
                        if (DetailedGSTEntryBuffer."GST Amount" > 0) then
                            DetailedGSTEntryBuffer.Insert();
                    until TaxTransValue.Next() = 0;
            until JnlBankCharges.Next() = 0;
    end;

    local procedure GetDetailGSTEntryBufferNextLineNo(): Integer
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        NextLineNo: Integer;
    begin
        if DetailedGSTEntryBuffer.FindLast() then
            NextLineNo := DetailedGSTEntryBuffer."Line No.";
        exit(NextLineNo + 10000);
    end;

    local procedure UpdateBankChargeAmt(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AmountLCY: Decimal; SignOfBankAccLedgAmount: Integer)
    var
        DocType: Enum "BankCharges DocumentType";
    begin
        DocType := GetBankChargeDocType(GenJournalLine);
        if DocType <> DocType::" " then begin
            if DocType = DocType::Invoice then
                SignOfBankAccLedgAmount := -1
            else
                SignOfBankAccLedgAmount := 1
        end else
            if AmountLCY > 0 then begin
                if AmountLCY > BankChargeAmount then
                    SignOfBankAccLedgAmount := ABS(BankAccountLedgerEntry.Amount) / BankAccountLedgerEntry.Amount
                else
                    SignOfBankAccLedgAmount := 1;
            end else
                SignOfBankAccLedgAmount := ABS(BankAccountLedgerEntry.Amount) / BankAccountLedgerEntry.Amount;

        BankAccountLedgerEntry.Amount += (SignOfBankAccLedgAmount * BankChargeAmount) + BankChargeAmount;
        BankAccountLedgerEntry."Amount (LCY)" += (SignOfBankAccLedgAmount * BankChargeAmount) + BankChargeAmount;
        BankChargeAmount := (SignOfBankAccLedgAmount * BankChargeAmount);
        GenJournalLine."Amount (LCY)" += BankChargeAmount;
    end;

    local procedure GetBankChargeDocType(GenJournalLine: Record "Gen. Journal Line"): Enum "BankCharges DocumentType"
    var
        JnlBankCharges: Record "Journal Bank Charges";
    begin
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        if JnlBankCharges.Findfirst() then
            exit(JnlBankCharges."GST Document Type");
    end;


    local procedure DeleteDetailedGSTBufferBankCharges(var JnlBankCharges: Record "Journal Bank Charges")
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Journal Template Name", "Journal Batch Name", "Line No.", "Jnl. Bank Charge");
        DetailedGSTEntryBuffer.setrange("Journal Template Name", JnlBankCharges."Journal Template Name");
        DetailedGSTEntryBuffer.setrange("Journal Batch Name", JnlBankCharges."Journal Batch Name");
        DetailedGSTEntryBuffer.setrange("Line No.", JnlBankCharges."Line No.");
        DetailedGSTEntryBuffer.setrange("Jnl. Bank Charge", JnlBankCharges."Bank Charge");
        if DetailedGSTEntryBuffer.Findset() then
            DetailedGSTEntryBuffer.Deleteall();
    end;

    local Procedure InitPostedJnlBankCharge(GenJnlLine: Record "Gen. Journal Line"; ExecutionOption: option ReturnTotChgAmount,PostGLEntriesForBankChg)
    var
        JnlBankCharges: Record "Journal Bank Charges";
        GLSetup: Record "General Ledger Setup";
        BankCharge: Record "Bank Charge";
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
        DeleteJnlBankChgRecords: Boolean;
        GSTRounding: Decimal;
        BankChargeGSTInvAmt: Decimal;
    begin
        if (GenJnlLine."Journal Template Name" = '') or (GenJnlLine."Journal Batch Name" = '') then
            exit;
        CheckMultiLineBankChargesInvRounding(GenJnlLine);
        GLSetup.Get();
        CheckSameBankChargeForeignExchange(GenJnlLine);
        CheckBankChargeDocumentType(GenJnlLine);
        CheckSameBankChargeSign(GenJnlLine);
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJnlLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJnlLine."Line No.");
        JnlBankCharges.setrange("Foreign Exchange", True);
        if JnlBankCharges.Findset() and (JnlBankCharges.Count > 1) then
            Error(GSTBankChargeFxBoolErr);
        JnlBankCharges.setrange("Foreign Exchange");
        if JnlBankCharges.IsEmpty() then
            exit;

        GSTPostingBuffer[1].Deleteall();
        if JnlBankCharges.Findset() then begin
            if GenJnlLine."Bank Charge" and (JnlBankCharges."GST Group Code" <> '') and (JnlBankCharges.COUNT > 1) then
                Error(GSTBankChargeBoolErr);
            if GenJnlLine."GST Input Service Distribution" and (JnlBankCharges.GETGSTBaseAmount(JnlBankCharges.RecordId) <> 0) then
                GenJnlLine.TestField("GST Input Service Distribution", FALSE);
            repeat
                Clear(BankChargeCodeGSTAmount);
                Clear(BankChargeGSTAmount);
                if JnlBankCharges."GST Group Code" <> '' then
                    if GenJnlLine."Document Type" IN [GenJnlLine."Document Type"::Payment,
                                                      GenJnlLine."Document Type"::Refund]
                    then
                        PostBankChargeGST(GenJnlLine, JnlBankCharges);
                BankChargeGSTAmount := GetBankChargeCodeAmount(JnlBankCharges, FALSE);
                BankChargeCodeGSTAmount := GetBankChargeCodeAmount(JnlBankCharges, True);
                BankChargeGSTInvAmt += GetBankChargeCodeAmount(JnlBankCharges, FALSE);

                if JnlBankCharges."GST Inv. Rounding Precision" <> 0 then
                    GSTRounding :=
                      -Round(BankChargeGSTAmount -
                        Round(
                          BankChargeGSTAmount,
                          JnlBankCharges."GST Inv. Rounding Precision",
                          JnlBankCharges.GSTInvoiceRoundingDirection()),
                         GLSetup."GST Rounding Precision");
                if ExecutionOption = ExecutionOption::ReturnTotChgAmount then
                    BankChargeAmount += ABS(JnlBankCharges."Amount (LCY)" + BankChargeGSTAmount + GSTRounding);

                if ExecutionOption = ExecutionOption::PostGLEntriesForBankChg then begin
                    BankCharge.Get(JnlBankCharges."Bank Charge");

                    if JnlBankCharges."GST Group Code" <> '' then
                        if GenJnlLine."Document Type" IN [GenJnlLine."Document Type"::Payment,
                                                          GenJnlLine."Document Type"::Refund]
                        then
                            PostBankChargeGST(GenJnlLine, JnlBankCharges);
                    FillGSTPostingBufferBankCharge(JnlBankCharges, GenJnlLine);
                    if JnlBankCharges."GST Group Code" <> '' then
                        if GenJnlLine."Document Type" IN [GenJnlLine."Document Type"::Payment,
                                                          GenJnlLine."Document Type"::Refund]
                        then
                            InsertPostedJnlBankCharges(JnlBankCharges, GenJnlLine)
                        else
                            exit
                    else
                        InsertPostedJnlBankCharges(JnlBankCharges, GenJnlLine);
                    if JnlBankCharges.Amount + BankChargeCodeGSTAmount <> 0 then
                        JnlBankChargesSessionMgt.CreateGSTBankChargesGenJournallLine(GenJnlLine, BankCharge.Account, (JnlBankCharges.Amount + BankChargeCodeGSTAmount), (JnlBankCharges."Amount (LCY)" + BankChargeCodeGSTAmount));
                    DeleteJnlBankChgRecords := True;
                end;
            until JnlBankCharges.Next() = 0;
            if ExecutionOption = ExecutionOption::ReturnTotChgAmount then
                JnlBankChargesSessionMgt.SetBankChargeAmount(BankChargeAmount);
            if JnlBankCharges."GST Inv. Rounding Precision" <> 0 then
                GSTRounding :=
                  -Round(BankChargeGSTInvAmt -
                    Round(
                      BankChargeGSTInvAmt,
                      JnlBankCharges."GST Inv. Rounding Precision",
                      JnlBankCharges.GSTInvoiceRoundingDirection()),
                      GLSetup."GST Rounding Precision");
            if ExecutionOption = ExecutionOption::PostGLEntriesForBankChg then begin
                PostGSTOnBankCharge(GenJnlLine);
                GLSetup.Get();
                if (GSTRounding <> 0) then
                    JnlBankChargesSessionMgt.CreateGSTBankChargesGenJournallLine(GenJnlLine, GLSetup."GST Inv. Rounding Account", GSTRounding, GSTRounding);
            end;
            if DeleteJnlBankChgRecords then begin
                JnlBankCharges.Deleteall();
                JnlBankChargesSessionMgt.SetBankChargeAmount(0);
            end;
        end;
    end;

    local procedure PostGSTOnBankCharge(GenJnlLine: Record "Gen. Journal Line")
    var
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
    begin
        if GSTPostingBuffer[1].FindLast() then begin
            repeat
                if (GSTPostingBuffer[1]."Account No." <> '') and (GSTPostingBuffer[1]."GST Amount" <> 0) then
                    JnlBankChargesSessionMgt.CreateGSTBankChargesGenJournallLine(GenJnlLine, GSTPostingBuffer[1]."Account No.", GSTPostingBuffer[1]."GST Amount", GSTPostingBuffer[1]."GST Amount");
                PostedDocNo := GenJnlLine."Document No.";
                InsertGSTLedgerEntryBankCharges(GSTPostingBuffer[1], GenJnlLine, JnlBankChargesSessionMgt.GetTranxactionNo());
            until GSTPostingBuffer[1].Next(-1) = 0;
            InsertDetailedGSTLedgEntryBankCharges(GenJnlLine, JnlBankChargesSessionMgt.GetTranxactionNo());
        end;
    end;

    local procedure InsertGSTLedgerEntryBankCharges(GSTPostingBuffer: Record "GST Posting Buffer"; GenJournalLine: Record "Gen. Journal Line"; NextTransactionNo: Integer)
    var
        BankAccount: Record "Bank Account";
        GSTLedgerEntry: Record "GST Ledger Entry";
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
    begin
        GSTLedgerEntry.Init();
        GSTLedgerEntry."Entry No." := 0;
        GSTLedgerEntry."Gen. Bus. Posting Group" := GSTPostingBuffer."Gen. Bus. Posting Group";
        GSTLedgerEntry."Gen. Prod. Posting Group" := GSTPostingBuffer."Gen. Prod. Posting Group";
        GSTLedgerEntry."Posting Date" := GenJournalLine."Posting Date";
        GSTLedgerEntry."Document No." := GenJournalLine."Document No.";
        GSTLedgerEntry."GST Amount" := GSTPostingBuffer."GST Amount";
        GSTLedgerEntry."GST Base Amount" := GSTPostingBuffer."GST Base Amount";
        GSTLedgerEntry."Currency Code" := GenJournalLine."Currency Code";
        GSTLedgerEntry."Currency Factor" := GenJournalLine."Currency Factor";
        GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::"Bank Account";
        GSTLedgerEntry."Transaction Type" := GSTLedgerEntry."Transaction Type"::Purchase;
        if BankAccount.Get(GenJournalLine."Bal. Account No.") then
            GSTLedgerEntry."Source No." := GenJournalLine."Bal. Account No."
        else
            if BankAccount.Get(GenJournalLine."Account No.") then
                GSTLedgerEntry."Source No." := GenJournalLine."Account No.";
        GSTLedgerEntry."User ID" := Copystr(USERID, 1, MaxStrLen(GSTLedgerEntry."User ID"));
        GSTLedgerEntry."Source Code" := GenJournalLine."Source Code";
        GSTLedgerEntry."Reason Code" := GenJournalLine."Reason Code";
        GSTLedgerEntry.Availment := GSTPostingBuffer.Availment;
        GSTLedgerEntry."Transaction No." := JnlBankChargesSessionMgt.GetTranxactionNo();
        GSTLedgerEntry."GST Component Code" := GSTPostingBuffer."GST Component Code";
        if GSTLedgerEntry."GST Base Amount" > 0 then
            GSTLedgerEntry."Document Type" := GSTLedgerEntry."Document Type"::Invoice
        else
            GSTLedgerEntry."Document Type" := GSTLedgerEntry."Document Type"::"Credit Memo";
        GSTLedgerEntry.Insert(True);
    end;

    local procedure InsertDetailedGSTLedgEntryBankCharges(GenJournalLine: Record "Gen. Journal Line"; NextTransactionNo: Integer)
    var
        BankAccount: Record "Bank Account";
        BankCharge: Record "Bank Charge";
        JnlBankCharges: Record "Journal Bank Charges";
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        DocumentTypeTxt: Text;
        GSTDocumentType: Enum "original Doc Type";
        EntryNo: Integer;
    begin
        EntryNo := GetNextGSTDetailEntryNo();
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        if JnlBankCharges.Findset() then
            repeat
                DetailedGSTEntryBuffer.SETCURRENTKEY("Transaction Type", "Journal Template Name", "Journal Batch Name", "Line No.");
                DetailedGSTEntryBuffer.setrange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Purchase);
                DetailedGSTEntryBuffer.setrange("Journal Template Name", JnlBankCharges."Journal Template Name");
                DetailedGSTEntryBuffer.setrange("Journal Batch Name", JnlBankCharges."Journal Batch Name");
                DetailedGSTEntryBuffer.setrange("Line No.", JnlBankCharges."Line No.");
                DetailedGSTEntryBuffer.setrange("Jnl. Bank Charge", JnlBankCharges."Bank Charge");
                if DetailedGSTEntryBuffer.Findset() then
                    repeat
                        DetailedGSTLedgerEntry.Init();
                        DetailedGSTLedgerEntry."Entry No." := EntryNo;
                        EntryNo += 1;
                        DetailedGSTLedgerEntry."Entry Type" := DetailedGSTLedgerEntry."Entry Type"::"Initial Entry";
                        DetailedGSTLedgerEntry."Transaction No." := NextTransactionNo;
                        DetailedGSTLedgerEntry."Document No." := GenJournalLine."Document No.";
                        DetailedGSTLedgerEntry."Posting Date" := DetailedGSTEntryBuffer."Posting Date";
                        DetailedGSTEntryBuffer.TestField("Location Code");
                        DetailedGSTEntryBuffer.TestField("Location  Reg. No.");
                        DetailedGSTEntryBuffer.TestField("Location State Code");
                        DetailedGSTLedgerEntry."Location State Code" := DetailedGSTEntryBuffer."Location State Code";
                        DetailedGSTLedgerEntry."Location Code" := DetailedGSTEntryBuffer."Location Code";
                        DetailedGSTLedgerEntry."GST Vendor Type" := "GST Vendor Type"::Registered;
                        DetailedGSTLedgerEntry."Location  Reg. No." := DetailedGSTEntryBuffer."Location  Reg. No.";
                        DetailedGSTLedgerEntry."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
                        DetailedGSTLedgerEntry."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
                        DetailedGSTLedgerEntry."GST Exempted Goods" := DetailedGSTEntryBuffer.Exempted;
                        DetailedGSTLedgerEntry."Nature of Supply" := DetailedGSTLedgerEntry."Nature of Supply"::B2B;
                        DetailedGSTLedgerEntry."GST Rounding Type" := DetailedGSTEntryBuffer."GST Rounding Type";
                        DetailedGSTLedgerEntry."GST Rounding Precision" := DetailedGSTEntryBuffer."GST Rounding Precision";
                        DetailedGSTLedgerEntry."GST Inv. Rounding Type" := DetailedGSTEntryBuffer."GST Inv. Rounding Type";
                        DetailedGSTLedgerEntry."GST Inv. Rounding Precision" := DetailedGSTEntryBuffer."GST Inv. Rounding Precision";
                        DetailedGSTLedgerEntry."original Doc. No." := DetailedGSTLedgerEntry."Document No.";
                        DocumentTypeTxt := Format(DetailedGSTLedgerEntry."Document Type");
                        Evaluate(GSTDocumentType, DocumentTypeTxt);
                        DetailedGSTLedgerEntry."original Doc. Type" := GSTDocumentType;
                        DetailedGSTLedgerEntry."HSN/SAC Code" := DetailedGSTEntryBuffer."HSN/SAC Code";
                        DetailedGSTLedgerEntry."GST Group Type" := DetailedGSTEntryBuffer."GST Group Type";
                        DetailedGSTLedgerEntry."CLE/VLE Entry No." := 0;
                        DetailedGSTLedgerEntry."Buyer/Seller State Code" := DetailedGSTEntryBuffer."Buyer/Seller State Code";
                        DetailedGSTLedgerEntry."Buyer/Seller Reg. No." := DetailedGSTEntryBuffer."Buyer/Seller Reg. No.";
                        if BankAccount.Get(GenJournalLine."Bal. Account No.") then
                            DetailedGSTLedgerEntry."Source No." := GenJournalLine."Bal. Account No."
                        else
                            if BankAccount.Get(GenJournalLine."Account No.") then
                                DetailedGSTLedgerEntry."Source No." := GenJournalLine."Account No.";
                        if DetailedGSTLedgerEntry."Location State Code" <> DetailedGSTLedgerEntry."Buyer/Seller State Code" then
                            DetailedGSTLedgerEntry."GST Jurisdiction Type" := DetailedGSTLedgerEntry."GST Jurisdiction Type"::Interstate
                        else
                            DetailedGSTLedgerEntry."GST Jurisdiction Type" := DetailedGSTLedgerEntry."GST Jurisdiction Type"::Intrastate;
                        if not DetailedGSTEntryBuffer."Non-Availment" then
                            DetailedGSTLedgerEntry."GST Credit" := DetailedGSTLedgerEntry."GST Credit"::Availment
                        else
                            DetailedGSTLedgerEntry."GST Credit" := DetailedGSTLedgerEntry."GST Credit"::"Non-Availment";
                        DetailedGSTLedgerEntry."Credit Availed" := DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::Availment;
                        DetailedGSTLedgerEntry."Source Type" := "Source Type"::"Bank Account";
                        DetailedGSTLedgerEntry.Type := DetailedGSTLedgerEntry.Type::"G/L Account";
                        DetailedGSTLedgerEntry."Transaction Type" := DetailedGSTLedgerEntry."Transaction Type"::Purchase;
                        BankCharge.Get(JnlBankCharges."Bank Charge");
                        DetailedGSTLedgerEntry."No." := BankCharge.Account;
                        DetailedGSTLedgerEntry."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
                        if DetailedGSTLedgerEntry."Credit Availed" then
                            DetailedGSTLedgerEntry."G/L Account No." := GetGSTReceivableAccountNo(DetailedGSTLedgerEntry."Location State Code", DetailedGSTLedgerEntry."GST Component Code")
                        else
                            DetailedGSTLedgerEntry."G/L Account No." := DetailedGSTLedgerEntry."No.";
                        DetailedGSTLedgerEntry."GST Group Code" := DetailedGSTEntryBuffer."GST Group Code";
                        DetailedGSTLedgerEntry."Document Line No." := DetailedGSTEntryBuffer."Line No.";
                        DetailedGSTLedgerEntry."GST Base Amount" := DetailedGSTEntryBuffer."GST Base Amount";
                        DetailedGSTLedgerEntry."GST Amount" := DetailedGSTEntryBuffer."GST Amount";
                        if DetailedGSTLedgerEntry."GST Base Amount" > 0 then begin
                            DetailedGSTLedgerEntry."Document Type" := DetailedGSTLedgerEntry."Document Type"::Invoice;
                            DetailedGSTLedgerEntry.Quantity := 1;
                            DetailedGSTLedgerEntry.Positive := True;
                        end else begin
                            DetailedGSTLedgerEntry."Document Type" := DetailedGSTLedgerEntry."Document Type"::"Credit Memo";
                            DetailedGSTLedgerEntry.Quantity := -1;
                        end;
                        DetailedGSTLedgerEntry."GST %" := DetailedGSTEntryBuffer."GST %";
                        if DetailedGSTLedgerEntry."GST Exempted Goods" then
                            DetailedGSTLedgerEntry."GST %" := 0;
                        if DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::"Non-Availment" then
                            DetailedGSTLedgerEntry."Amount Loaded on Item" := DetailedGSTLedgerEntry."GST Amount";
                        if JnlBankCharges.LCY then
                            DetailedGSTLedgerEntry."Currency Factor" := 1
                        else begin
                            DetailedGSTLedgerEntry."Currency Code" := GenJournalLine."Currency Code";
                            DetailedGSTLedgerEntry."Currency Factor" := GenJournalLine."Currency Factor";
                        end;
                        DetailedGSTLedgerEntry."User ID" := copystr(USERID, 1, MaxStrLen(DetailedGSTLedgerEntry."User ID"));
                        DetailedGSTLedgerEntry.Cess := DetailedGSTEntryBuffer.Cess;
                        DetailedGSTLedgerEntry."Component Calc. Type" := DetailedGSTEntryBuffer."Component Calc. Type";
                        DetailedGSTLedgerEntry."Jnl. Bank Charge" := JnlBankCharges."Bank Charge";
                        DetailedGSTLedgerEntry."Bank Charge Entry" := DetailedGSTLedgerEntry."Jnl. Bank Charge" <> '';
                        DetailedGSTLedgerEntry."External Document No." := JnlBankCharges."External Document No.";
                        DetailedGSTLedgerEntry."Foreign Exchange" := JnlBankCharges."Foreign Exchange";
                        DetailedGSTLedgerEntry.TestField("HSN/SAC Code");
                        DetailedGSTLedgerEntry.Insert(True);
                    until DetailedGSTEntryBuffer.Next() = 0;
                DeleteDetailedGSTBufferBankCharges(JnlBankCharges);
            until JnlBankCharges.Next() = 0;
    end;

    local procedure GetNextGSTDetailEntryNo(): Integer
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        EntryNo: Integer;
    begin
        if DetailedGSTLedgerEntry.FindLast() then
            EntryNo := DetailedGSTLedgerEntry."Entry No.";
        exit(EntryNo + 1);
    end;

    local Procedure CheckMultiLineBankChargesInvRounding(GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankCharges: Record "Journal Bank Charges";
        GSTInvRounding: Decimal;
        GSTInvRoundingType: Enum "GST Inv Rounding Type";
    begin
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        JnlBankCharges.SetFilter("GST Group Code", '<>%1', '');
        if JnlBankCharges.Findset() then begin
            GSTInvRounding := JnlBankCharges."GST Inv. Rounding Precision";
            GSTInvRoundingType := JnlBankCharges."GST Inv. Rounding Type";
            repeat
                JnlBankCharges.TestField("GST Inv. Rounding Precision", GSTInvRounding);
                JnlBankCharges.TestField("GST Inv. Rounding Type", GSTInvRoundingType);
            until JnlBankCharges.Next() = 0;
        end;
    end;

    local procedure CheckBankChargeDocumentType(GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankCharges: Record "Journal Bank Charges";
        DocType: Enum "BankCharges DocumentType";
    begin
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        JnlBankCharges.SetFilter("GST Document Type", '%1|%2', JnlBankCharges."GST Document Type"::Invoice, JnlBankCharges."GST Document Type"::"Credit Memo");
        if JnlBankCharges.Findset() then begin
            DocType := JnlBankCharges."GST Document Type";
            repeat
                JnlBankCharges.TestField("GST Document Type", DocType);
            until JnlBankCharges.Next() = 0;
        end;
    end;

    local procedure CheckSameBankChargeForeignExchange(GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankCharges: Record "Journal Bank Charges";
        Sign: Integer;
        ForeignExch: Boolean;
    begin
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        JnlBankCharges.setrange("Foreign Exchange", True);
        if JnlBankCharges.Findfirst() then begin
            ForeignExch := True;
            if JnlBankCharges.GETGSTBaseAmount(JnlBankCharges.RecordId) > 0 then
                Sign := 1
            else
                if JnlBankCharges.GETGSTBaseAmount(JnlBankCharges.RecordId) < 0 then
                    Sign := -1;
        end;
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        if JnlBankCharges.Findset() then
            repeat
                if ForeignExch and ((JnlBankCharges.Amount > 0) and (Sign = -1)) or ((JnlBankCharges.Amount < 0) and (Sign = 1)) then
                    Error(DiffSignErr);
            until JnlBankCharges.Next() = 0;
    end;

    local procedure CheckSameBankChargeSign(GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankCharges: Record "Journal Bank Charges";
        Sign: Integer;
    begin
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        if JnlBankCharges.Findfirst() then
            if JnlBankCharges.Amount > 0 then
                Sign := 1
            else
                if JnlBankCharges.Amount < 0 then
                    Sign := -1;

        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        if JnlBankCharges.Findset() then
            repeat
                if ((JnlBankCharges.Amount > 0) and (Sign = -1)) or ((JnlBankCharges.Amount < 0) and (Sign = 1)) then
                    Error(DiffSignErr);
            until JnlBankCharges.Next() = 0;
    end;

    local Procedure PostBankChargeGST(GenJournalLine: Record "Gen. Journal Line"; JnlBankCharges: Record "Journal Bank Charges")
    var
        BankCharge: Record "Bank Charge";
    begin
        BankCharge.Get(JnlBankCharges."Bank Charge");
        CheckGSTValidationsBankCharge(GenJournalLine, JnlBankCharges);
        JnlBankCharges.CheckBankChargeAmountSign(GenJournalLine, JnlBankCharges);
    end;

    local Procedure CheckGSTValidationsBankCharge(GenJournalLine: Record "Gen. Journal Line"; JnlBankCharges: Record "Journal Bank Charges")
    var
        BankCharge: Record "Bank Charge";
    begin
        if GenJournalLine."Bank Charge" then begin
            BankCharge.Get(JnlBankCharges."Bank Charge");
            if ((GenJournalLine.Amount > 0) and (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment)) or
               ((GenJournalLine.Amount < 0) and (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Refund))
            then begin
                GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"G/L Account");
                GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
                BankCharge.TestField(Account, GenJournalLine."Account No.");
            end else
                if ((GenJournalLine.Amount < 0) and (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment)) or
                   ((GenJournalLine.Amount > 0) and (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Refund))
                then begin
                    GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"Bank Account");
                    GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
                    BankCharge.TestField(Account, GenJournalLine."Bal. Account No.");
                end;
        end;
    end;

    local Procedure GetBankChargeCodeAmount(JnlBankCharges: Record "Journal Bank Charges"; NonAvailment: Boolean): Decimal
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        BankGSTAmount: Decimal;
    begin
        SetFilterForBankCharge(DetailedGSTEntryBuffer, JnlBankCharges);
        if not DetailedGSTEntryBuffer.Findset() then
            exit(0);
        repeat
            if NonAvailment then
                BankGSTAmount += DetailedGSTEntryBuffer."Amount Loaded on Item"
            else
                BankGSTAmount += DetailedGSTEntryBuffer."GST Amount";
        until DetailedGSTEntryBuffer.Next() = 0;
        exit(BankGSTAmount);
    end;

    local Procedure SetFilterForBankCharge(var DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer"; JnlBankCharges: Record "Journal Bank Charges")
    begin
        DetailedGSTEntryBuffer.SetCurrentKey("Transaction Type", "Journal Template Name", "Journal Batch Name", "Line No.");
        DetailedGSTEntryBuffer.setrange("Transaction Type", DetailedGSTEntryBuffer."Transaction Type"::Purchase);
        DetailedGSTEntryBuffer.setrange("Journal Template Name", JnlBankCharges."Journal Template Name");
        DetailedGSTEntryBuffer.setrange("Journal Batch Name", JnlBankCharges."Journal Batch Name");
        DetailedGSTEntryBuffer.setrange("Line No.", JnlBankCharges."Line No.");
        DetailedGSTEntryBuffer.setrange("Source Type", "Source Type"::"Bank Account");
        DetailedGSTEntryBuffer.setrange("Jnl. Bank Charge", JnlBankCharges."Bank Charge");
    end;

    local Procedure FillGSTPostingBufferBankCharge(JnlBankCharges: Record "Journal Bank Charges"; GenJournalLine: Record "Gen. Journal Line")
    var
        DetailedGSTEntryBuffer: Record "Detailed GST Entry Buffer";
        Vendor: Record Vendor;
        Customer: Record Customer;
    begin
        SetFilterForBankCharge(DetailedGSTEntryBuffer, JnlBankCharges);
        if DetailedGSTEntryBuffer.Findset() then
            repeat
                Clear(GSTPostingBuffer[1]);
                GSTPostingBuffer[1]."Transaction Type" := GSTPostingBuffer[1]."Transaction Type"::Purchase;
                GSTPostingBuffer[1]."Gen. Bus. Posting Group" := GenJournalLine."Gen. Bus. Posting Group";
                GSTPostingBuffer[1]."Gen. Prod. Posting Group" := GenJournalLine."Gen. Prod. Posting Group";
                GSTPostingBuffer[1]."Global Dimension 1 Code" := GenJournalLine."Shortcut Dimension 1 Code";
                GSTPostingBuffer[1]."Global Dimension 2 Code" := GenJournalLine."Shortcut Dimension 2 Code";
                GSTPostingBuffer[1]."GST Group Code" := DetailedGSTEntryBuffer."GST Group Code";
                GSTPostingBuffer[1]."GST Component Code" := DetailedGSTEntryBuffer."GST Component Code";
                GSTPostingBuffer[1]."Party Code" := DetailedGSTEntryBuffer."Source No.";
                if not DetailedGSTEntryBuffer."Non-Availment" then begin
                    GSTPostingBuffer[1].Availment := True;
                    GSTPostingBuffer[1]."Account No." :=
                    GetGSTReceivableAccountNo(DetailedGSTEntryBuffer."Location State Code", DetailedGSTEntryBuffer."GST Component Code");
                end;
                GSTPostingBuffer[1]."GST Base Amount" := DetailedGSTEntryBuffer."GST Base Amount";
                GSTPostingBuffer[1]."GST Amount" := DetailedGSTEntryBuffer."GST Amount";
                UpdateGSTPostingBufferBankCharge();
            until DetailedGSTEntryBuffer.Next() = 0;
    end;

    local Procedure UpdateGSTPostingBufferBankCharge()
    begin
        GSTPostingBuffer[2] := GSTPostingBuffer[1];
        if GSTPostingBuffer[2].Find() then begin
            GSTPostingBuffer[2]."GST Base Amount" += GSTPostingBuffer[1]."GST Base Amount";
            GSTPostingBuffer[2]."GST Amount" += GSTPostingBuffer[1]."GST Amount";
            GSTPostingBuffer[2].Modify();
        end else
            GSTPostingBuffer[1].Insert();
    end;

    local procedure InsertPostedJnlBankCharges(JnlBankCharges: Record "Journal Bank Charges"; GenJnlLine: Record "Gen. Journal Line")
    var
        PostedJnlBankCharges: Record "Posted Jnl. Bank Charges";
        BankAccount: Record "Bank Account";
        JnlBankChargesSessionMgt: Codeunit "GST Bank Charge Session Mgt.";
    begin
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Bank Account" then
            if GenJnlLine."Bal. Account No." <> '' then
                BankAccount.Get(GenJnlLine."Bal. Account No.");
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Bank Account" then
            if GenJnlLine."Account No." <> '' then
                BankAccount.Get(GenJnlLine."Account No.");
        PostedJnlBankCharges.Init();
        PostedJnlBankCharges."GL Entry No." := JnlBankChargesSessionMgt.GETEntryNo();
        PostedJnlBankCharges."Bank Charge" := JnlBankCharges."Bank Charge";
        PostedJnlBankCharges.Amount := JnlBankCharges.Amount;
        PostedJnlBankCharges."Amount (LCY)" := JnlBankCharges."Amount (LCY)";
        PostedJnlBankCharges."Document No." := GenJnlLine."Document No.";
        PostedJnlBankCharges."Posting Date" := GenJnlLine."Posting Date";
        if JnlBankCharges."GST Group Code" <> '' then begin
            if GenJnlLine."Bank Charge" then begin
                PostedJnlBankCharges.Amount := ABS(GenJnlLine.Amount);
                PostedJnlBankCharges."Amount (LCY)" := ABS(GenJnlLine."Amount (LCY)");
            end;
            PostedJnlBankCharges."GST Group Code" := JnlBankCharges."GST Group Code";
            PostedJnlBankCharges."GST Group Type" := JnlBankCharges."GST Group Type";
            PostedJnlBankCharges."Foreign Exchange" := JnlBankCharges."Foreign Exchange";
            PostedJnlBankCharges."HSN/SAC Code" := JnlBankCharges."HSN/SAC Code";
            PostedJnlBankCharges.Exempted := JnlBankCharges.Exempted;
            PostedJnlBankCharges."GST Credit" := JnlBankCharges."GST Credit";
            if GenJnlLine."Location State Code" <> GenJnlLine."GST Bill-to/BuyFrom State Code" then
                PostedJnlBankCharges."GST Jurisdiction Type" := PostedJnlBankCharges."GST Jurisdiction Type"::Interstate
            else
                PostedJnlBankCharges."GST Jurisdiction Type" := PostedJnlBankCharges."GST Jurisdiction Type"::Intrastate;
            PostedJnlBankCharges."GST Bill to/Buy From State" := BankAccount."State Code";
            PostedJnlBankCharges."Location State Code" := GenJnlLine."Location State Code";
            PostedJnlBankCharges."Location  Reg. No." := GenJnlLine."Location GST Reg. No.";
            PostedJnlBankCharges."GST Registration Status" := JnlBankCharges."GST Registration Status";
            PostedJnlBankCharges."GST Inv. Rounding Precision" := JnlBankCharges."GST Inv. Rounding Precision";
            PostedJnlBankCharges."GST Inv. Rounding Type" := JnlBankCharges."GST Inv. Rounding Type";
            PostedJnlBankCharges."Nature of Supply" := PostedJnlBankCharges."Nature of Supply"::B2B;
            PostedJnlBankCharges."External Document No." := JnlBankCharges."External Document No.";
            PostedJnlBankCharges."Transaction No." := JnlBankChargesSessionMgt.GetTranxactionNo();
            PostedJnlBankCharges.LCY := JnlBankCharges.LCY;
            PostedJnlBankCharges."GST Document Type" := JnlBankCharges."GST Document Type";
        end;
        PostedJnlBankCharges.Insert(True);
    end;

    local procedure GetGSTReceivableAccountNo(GSTStateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
        GSTComponentID: Integer;
    begin
        GSTComponentID := GetGSTComponentID(GSTComponentCode);
        GSTPostingSetup.Get(GSTStateCode, GSTComponentID);
        GSTPostingSetup.TestField("Receivable Account");
        exit(GSTPostingSetup."Receivable Account");
    end;

    local procedure GetGSTComponentID(GSTComponentCode: Code[10]): Integer
    var
        TaxComponent: Record "Tax Component";
    begin
        TaxComponent.setrange(Name, GSTComponentCode);
        TaxComponent.Findfirst();
        exit(TaxComponent.ID);
    end;

    local procedure DeleteJournalBankCharges(var GenJournalLine: Record "Gen. Journal Line")
    var
        JnlBankCharges: Record "Journal Bank Charges";
    begin
        JnlBankCharges.Reset();
        JnlBankCharges.setrange("Journal Template Name", GenJournalLine."Journal Template Name");
        JnlBankCharges.setrange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        JnlBankCharges.setrange("Line No.", GenJournalLine."Line No.");
        JnlBankCharges.Deleteall();
    end;

    local procedure CalculateGSTAmounts(JnlBankCharges: Record "journal Bank Charges")
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        Sign: Integer;
    begin
        if (JnlBankCharges."Journal Template Name" = '') or (JnlBankCharges."Journal Batch Name" = '') then
            exit;
        GenJnlLine.Get(JnlBankCharges."Journal Template Name", JnlBankCharges."Journal Batch Name", JnlBankCharges."Line No.");
        if (JnlBankCharges."GST Document Type" = JnlBankCharges."GST Document Type"::" ")
            and (JnlBankCharges."GST Group Code" <> '') and not GenJnlLine."Bank Charge" then
            JnlBankCharges.TestField("GST Document Type");
        if not (GenJnlLine."Document Type" IN [GenJnlLine."Document Type"::Payment,
                                               GenJnlLine."Document Type"::Refund])
        then
            exit;
        if JnlBankCharges."GST Group Code" = '' then
            exit;
        if JnlBankCharges."GST Group Code" <> '' then begin
            JnlBankCharges.TestField("GST Group Type");
            JnlBankCharges.TestField("HSN/SAC Code");
            if GenJnlLine."Bal. Account No." <> '' then
                BankAccount.Get(GenJnlLine."Bal. Account No.")
            else
                BankAccount.Get(GenJnlLine."Account No.");
            BankAccount.TestField("GST Registration No.");
            BankAccount.TestField("State Code");
            GenJnlLine.TestField("Location Code");
            GenJnlLine.TestField("Location State Code");
            Location.Get(GenJnlLine."Location Code");
            Location.TestField("State Code");
            Location.TestField("GST Registration No.");
            JnlBankCharges.TestField("External Document No.");
        end;
    end;

    var
        GSTPostingBuffer: Array[2] of Record "GST Posting Buffer" temporary;
        BankChargeCodeGSTAmount: Decimal;
        BankChargeGSTAmount: Decimal;
        BankChargeAmount: Decimal;
        PostedDocNo: Code[20];
        GSTBankChargeBoolErr: Label 'You Can not have multiple Bank Charges, when Bank Charge Boolean in General Journal Line is True.';
        GSTBankChargeFxBoolErr: label 'You Can not have multiple Bank Charges with Foreign Exchange True.';
        DiffSignErr: label 'All bank charge lines must have same sign Amount.';
}