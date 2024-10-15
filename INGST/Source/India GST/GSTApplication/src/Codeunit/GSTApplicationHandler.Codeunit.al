codeunit 18430 "GST Application Handler"
{
    var
        OnlineVendorLedgerEntry: Record "Vendor Ledger Entry";
        OnlineCustLedgerEntry: Record "Cust. Ledger Entry";
        GSTPostingBuffer: array[2] of Record "GST Posting Buffer" temporary;
        GSTApplSessionMgt: Codeunit "GST Application Session Mgt.";
        GSTPurchaseApplicationMgt: Codeunit "GST Purchase Application Mgt.";
        GSTSalesApplicationMgt: Codeunit "GST Sales Application Mgt.";
        GSTApplicationLibrary: Codeunit "GST Application Library";
        GSTTransactionType: Enum "Detail Ledger Transaction Type";
        TransactionNo: Integer;
        UnApplicationErr: Label 'Unapplication is not allowed as Credit Adjustment is posted against this transaction.';
        GSTInvoiceLiabilityErr: Label 'Cr. & Libty. Adjustment Type should be Liability Reverse or Blank.';

    local procedure SetGSTApplicationSourcePurch(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        var GenJnlLine: Record "Gen. Journal Line";
        Vend: Record Vendor;
        var IsAmountToApplyCheckHandled: Boolean)
    begin
        if (GenJnlLine."Applies-to ID" <> '') or (GenJnlLine."Applies-to Doc. No." <> '') then
            GenJnlLine.TestField("GST on Advance Payment", false);
        GSTApplSessionMgt.SetGSTApplicationSourcePurch(NewCVLedgEntryBuf."Transaction No.", Vend."No.");
    end;

    local procedure SetGSTApplicationSourceSales(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        var GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        var IsAmountToApplyCheckHandled: Boolean)
    begin
        if (GenJnlLine."Applies-to ID" <> '') or (GenJnlLine."Applies-to Doc. No." <> '') then
            GenJnlLine.TestField("GST on Advance Payment", false);
        GSTApplSessionMgt.SetGSTApplicationSourceSales(NewCVLedgEntryBuf."Transaction No.", Cust."No.");
    end;

    local procedure SetGSTApplicationAmount(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        var AppliedAmount: Decimal;
        var AppliedAmountLCY: Decimal;
        var OldAppliedAmount: Decimal)
    begin
        GSTApplSessionMgt.SetGSTApplicationAmount(AppliedAmount, AppliedAmountLCY);
    end;

    local procedure SetOnlineCustLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        GSTApplSessionMgt.SetOnlineCustLedgerEntry(CustLedgerEntry);
    end;

    local procedure SetOnlineVendLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GSTApplSessionMgt.SetOnlineVendLedgerEntry(VendorLedgerEntry);
    end;

    local procedure PostGSTPurchaseApplication(
        var GenJournalLine: Record "Gen. Journal Line";
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldGSTLedgEnt: Record "Detailed GST Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        InvoiceGSTAmount: Decimal;
        AppliedGSTAmount: Decimal;
        InvoiceBase: Decimal;
        TransactionType: Enum "Detail Ledger Transaction Type";
        TotalTDSInclSHECessAmount: Decimal;
    begin
        if AmountToApply = 0 then
            exit;
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Refund then
            exit;
        if GenJournalLine."Offline Application" then begin
            if not VendorLedgerEntry.Get(CVLedgerEntryBuffer."Entry No.") then
                exit;
            if not ApplyingVendorLedgerEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
                exit;
            if VendorLedgerEntry."GST on Advance Payment" and VendorLedgerEntry."GST Reverse Charge" then begin
                GSTPurchaseApplicationMgt.GetPurchaseInvoiceAmountOffline(
                  VendorLedgerEntry, ApplyingVendorLedgerEntry, GenJournalLine, ApplyingVendorLedgerEntry."Total TDS Including SHE CESS");
                if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                    GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                      TransactionType::Purchase, ApplyingVendorLedgerEntry."Document Type",
                      ApplyingVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", VendorLedgerEntry."GST Group Code",
                      AmountToApply, CVLedgerEntryBuffer."Remaining Amt. (LCY)", VendorLedgerEntry."Entry No.", false,
                      InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase)
                else
                    GSTApplicationLibrary.GetApplicationRemainingAmount(
                      TransactionType::Purchase, ApplyingVendorLedgerEntry."Document Type",
                      ApplyingVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", VendorLedgerEntry."GST Group Code",
                      AmountToApply, CVLedgerEntryBuffer."Remaining Amt. (LCY)", VendorLedgerEntry."Entry No.", false,
                      InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase);
                GSTApplicationLibrary.CheckGroupAmount(
                  ApplyingVendorLedgerEntry."Document Type",
                  ApplyingVendorLedgerEntry."Document No.", AmountToApply, InvoiceBase,
                  VendorLedgerEntry."GST Group Code");
                PostPurchaseGSTApplicationGL(GenJournalLine, VendorLedgerEntry."Document No.",
                  ApplyingVendorLedgerEntry."Document No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Entry No.",
                  VendorLedgerEntry."GST Group Code", ApplyingVendorLedgerEntry."Transaction No.");
            end else
                if ApplyingVendorLedgerEntry."GST on Advance Payment" and ApplyingVendorLedgerEntry."GST Reverse Charge" then begin
                    GSTPurchaseApplicationMgt.GetPurchaseInvoiceAmountWithPaymentOffline(
                      VendorLedgerEntry, ApplyingVendorLedgerEntry, GenJournalLine, VendorLedgerEntry."Total TDS Including SHE CESS");
                    if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                        GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                          TransactionType::Purchase, VendorLedgerEntry."Document Type",
                          VendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."GST Group Code",
                          AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)", ApplyingVendorLedgerEntry."Entry No.", false,
                          InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase)
                    else
                        GSTApplicationLibrary.GetApplicationRemainingAmount(
                          TransactionType::Purchase, VendorLedgerEntry."Document Type",
                          VendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."GST Group Code",
                          AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)", ApplyingVendorLedgerEntry."Entry No.", false,
                          InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase); // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)" 
                    GSTApplicationLibrary.CheckGroupAmount(
                      VendorLedgerEntry."Document Type",
                      VendorLedgerEntry."Document No.", AmountToApply, InvoiceBase,
                      ApplyingVendorLedgerEntry."GST Group Code");
                    PostPurchaseGSTApplicationGL(GenJournalLine, ApplyingVendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.",
                      ApplyingVendorLedgerEntry."Transaction No.", ApplyingVendorLedgerEntry."Entry No.",
                      ApplyingVendorLedgerEntry."GST Group Code", VendorLedgerEntry."Transaction No.");
                end else
                    PostGSTWithNormalPaymentOffline(
                      GenJournalLine, CVLedgerEntryBuffer, OldCVLedgerEntryBuffer, AmountToApply);
            GSTApplSessionMgt.PostApplicationGenJournalLine(GenJnlPostLine);
        end else begin
            if not ApplyingVendorLedgerEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
                exit;
            GSTApplSessionMgt.GetOnlineVendLedgerEntry(OnlineVendorLedgerEntry);
            if ApplyingVendorLedgerEntry."GST on Advance Payment" then begin
                TotalTDSInclSHECessAmount := GSTApplSessionMgt.GetTotalTDSInclSHECessAmount();
                GSTPurchaseApplicationMgt.GetPurchaseInvoiceAmountWithPaymentOffline(
                  OnlineVendorLedgerEntry, ApplyingVendorLedgerEntry,
                  GenJournalLine, TotalTDSInclSHECessAmount); // To Check OnlineVendorLedgerEntry."Total TDS Including SHE CESS"
                if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                    GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                      TransactionType::Purchase, OnlineVendorLedgerEntry."Document Type",
                      OnlineVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.",
                      ApplyingVendorLedgerEntry."GST Group Code", AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)",
                      ApplyingVendorLedgerEntry."Entry No.", false, InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase) // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)" 
                else
                    GSTApplicationLibrary.GetApplicationRemainingAmount(
                      TransactionType::Purchase, OnlineVendorLedgerEntry."Document Type",
                      OnlineVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.",
                      ApplyingVendorLedgerEntry."GST Group Code", AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)",
                      ApplyingVendorLedgerEntry."Entry No.", false, InvoiceGSTAmount, AppliedGSTAmount, InvoiceBase); // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)" 
                GSTApplicationLibrary.CheckGroupAmountJnl(
                  OnlineVendorLedgerEntry."Document Type", OnlineVendorLedgerEntry."Document No.", AmountToApply, InvoiceBase,
                  ApplyingVendorLedgerEntry."GST Group Code");
                PostPurchaseGSTApplicationGL(GenJournalLine, ApplyingVendorLedgerEntry."Document No.", OnlineVendorLedgerEntry."Document No.",
                  ApplyingVendorLedgerEntry."Transaction No.", ApplyingVendorLedgerEntry."Entry No.",
                  ApplyingVendorLedgerEntry."GST Group Code", OnlineVendorLedgerEntry."Transaction No.");
            end else
                PostGSTWithNormalPaymentOnline(
                  GenJournalLine, CVLedgerEntryBuffer, OldCVLedgerEntryBuffer, AmountToApply);
        end;
    end;

    local procedure PostPurchaseGSTApplicationGL(
        var GenJournalLine: Record "Gen. Journal Line";
        PaymentDocNo: Code[20];
        InvoiceNo: Code[20];
        TransactionNo: Integer;
        PaymentEntryNo: Integer;
        GSTGroupCode: Code[20];
        InvoiceTransactionNo: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GSTLedgerEntry: Record "GST Ledger Entry";
        ApplyGSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ApplyDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ApplyDetailedGSTLedgerEntry2: Record "Detailed GST Ledger Entry";
        GSTApplicationBuffer: Record "GST Application Buffer";
        GSTApplicationBuffer2: Record "GST Application Buffer";
        TransactionType: Enum "Detail Ledger Transaction Type";
        GSTGLAccountType: Enum "GST GL Account Type";
        AccountNo: Code[20];
        BalanceAccountNo: Code[20];
        BalanceAccountNo2: Code[20];
        AppliedBase: Decimal;
        AppliedAmount: Decimal;
        RemainingBase: Decimal;
        RemainingAmount: Decimal;
        ApplicableRemainingGSTAmount: Decimal;
        ApplicationRatio: Decimal;
        AppliedBaseAmountInvoiceLCY: Decimal;
        AppliedAmountInvoiceLCY: Decimal;
        HigherInvoiceExchangeRate: Boolean;
    begin
        SourceCodeSetup.Get();
        GSTApplicationBuffer.SetRange("Transaction Type", GSTApplicationBuffer."Transaction Type"::Purchase);
        GSTApplicationBuffer.SetRange("Account No.", GenJournalLine."Account No.");
        GSTApplicationBuffer.SetRange("Original Document Type", GSTApplicationBuffer."Original Document Type"::Payment);
        GSTApplicationBuffer.SetRange("Original Document No.", PaymentDocNo);
        GSTApplicationBuffer.SetRange("Applied Doc. Type", GSTApplicationBuffer."Applied Doc. Type"::Invoice);
        GSTApplicationBuffer.SetRange("Applied Doc. No.", InvoiceNo);
        GSTApplicationBuffer.SetRange("GST Group Code", GSTGroupCode);
        if GSTApplicationBuffer.FindSet() then
            repeat
                DetailedGSTLedgerEntry.SetCurrentKey(
                  "Transaction Type", "Source No.", "CLE/VLE Entry No.", "Document Type", "Document No.", "GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
                DetailedGSTLedgerEntry.SetRange("Source No.", GenJournalLine."Account No.");
                DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Invoice);
                if GenJournalLine."Purch. Invoice Type" = GenJournalLine."Purch. Invoice Type"::" " then
                    DetailedGSTLedgerEntry.SetRange("Document No.", GSTApplicationBuffer."Applied Doc. No.")
                else
                    DetailedGSTLedgerEntry.SetRange("Document No.", GenJournalLine."Old Document No.");
                DetailedGSTLedgerEntry.SetRange("GST Group Code", GSTApplicationBuffer."GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
                DetailedGSTLedgerEntry.SetRange("GST Component Code", GSTApplicationBuffer."GST Component Code");
                DetailedGSTLedgerEntry.SetRange("Remaining Amount Closed", false);
                DetailedGSTLedgerEntry.SetRange("GST Exempted Goods", false);
                if DetailedGSTLedgerEntry.FindSet() then begin
                    RemainingBase := GSTApplicationBuffer."Applied Base Amount";
                    RemainingAmount := GSTApplicationBuffer."Applied Amount";
                    GSTPostingBuffer[1].DeleteAll();
                    GSTApplicationLibrary.CheckGSTAccountingPeriod(GenJournalLine."Posting Date");
                    repeat
                        if (RemainingBase <> 0) and (DetailedGSTLedgerEntry."Remaining Base Amount" > 0) then begin
                            Clear(ApplicableRemainingGSTAmount);
                            if DetailedGSTLedgerEntry."RCM Exempt Transaction" then
                                ApplicableRemainingGSTAmount := DetailedGSTLedgerEntry."Remaining Base Amount" *
                                  GSTApplicationBuffer."Applied Amount" / GSTApplicationBuffer."Applied Base Amount"
                            else
                                ApplicableRemainingGSTAmount := DetailedGSTLedgerEntry."Remaining GST Amount";
                            ApplicationRatio := 1;
                            if (GSTApplicationBuffer."Currency Factor" <> DetailedGSTLedgerEntry."Currency Factor") and
                               (GSTApplicationBuffer."Currency Factor" > DetailedGSTLedgerEntry."Currency Factor") and
                               (DetailedGSTLedgerEntry."GST Group Type" = DetailedGSTLedgerEntry."GST Group Type"::Service)
                            then begin
                                GSTApplicationBuffer2.SetRange("Transaction Type", GSTApplicationBuffer2."Transaction Type"::Purchase);
                                GSTApplicationBuffer2.SetRange("Account No.", GSTApplicationBuffer."Account No.");
                                GSTApplicationBuffer2.SetRange("Original Document Type", GSTApplicationBuffer."Applied Doc. Type");
                                GSTApplicationBuffer2.SetRange("Original Document No.", GSTApplicationBuffer."Applied Doc. No.");
                                GSTApplicationBuffer2.SetRange("Applied Doc. Type", GSTApplicationBuffer."Applied Doc. Type"::Payment);
                                GSTApplicationBuffer2.SetRange("Applied Doc. No.", GSTApplicationBuffer."Original Document No.");
                                GSTApplicationBuffer2.SetRange("GST Group Code", GSTApplicationBuffer."GST Group Code");
                                GSTApplicationBuffer2.SetRange("GST Component Code", GSTApplicationBuffer."GST Component Code");
                                if GSTApplicationBuffer2.FindFirst() then
                                    ApplicationRatio := GSTApplicationBuffer."Total Base(LCY)" / Round(GSTApplicationBuffer."Amt to Apply" / GSTApplicationBuffer2."Currency Factor");
                            end;
                            GSTApplicationLibrary.GetAppliedAmount(
                              Abs(RemainingBase), Abs(RemainingAmount),
                              Abs(DetailedGSTLedgerEntry."Remaining Base Amount" * ApplicationRatio),
                              Abs(ApplicableRemainingGSTAmount * ApplicationRatio), AppliedBase, AppliedAmount);
                            CreateDetailedGSTApplicationEntry(
                              ApplyDetailedGSTLedgerEntry, DetailedGSTLedgerEntry, GenJournalLine,
                              InvoiceNo, AppliedBase, Round(AppliedAmount), GSTApplicationBuffer."Original Document No.");
                            if ApplyDetailedGSTLedgerEntry."RCM Exempt Transaction" then begin
                                ApplyDetailedGSTLedgerEntry."GST %" := Abs(Round(ApplyDetailedGSTLedgerEntry."GST Amount" * 100 /
                                ApplyDetailedGSTLedgerEntry."GST Base Amount"));
                                if (ApplyDetailedGSTLedgerEntry."GST Group Type" = ApplyDetailedGSTLedgerEntry."GST Group Type"::Service) and
                                   (ApplyDetailedGSTLedgerEntry.Type = ApplyDetailedGSTLedgerEntry.Type::"G/L Account") and
                                   (ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::"Non-Availment")
                                then
                                    ApplyDetailedGSTLedgerEntry."Amount Loaded on Item" := ApplyDetailedGSTLedgerEntry."GST Amount";
                            end;
                            if ApplyDetailedGSTLedgerEntry."GST Group Type" = ApplyDetailedGSTLedgerEntry."GST Group Type"::Service then
                                ApplyDetailedGSTLedgerEntry."Credit Availed" := true
                            else
                                if ApplyDetailedGSTLedgerEntry."GST Vendor Type" = ApplyDetailedGSTLedgerEntry."GST Vendor Type"::Unregistered then
                                    ApplyDetailedGSTLedgerEntry."Credit Availed" := false;
                            if (ApplyDetailedGSTLedgerEntry."Associated Enterprises") or
                               (ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::"Non-Availment")
                            then
                                ApplyDetailedGSTLedgerEntry."Credit Availed" := false;
                            ApplyDetailedGSTLedgerEntry."RCM Exempt" := false;
                            if DetailedGSTLedgerEntry."RCM Exempt Transaction" then
                                if (ApplyDetailedGSTLedgerEntry."GST Group Type" = ApplyDetailedGSTLedgerEntry."GST Group Type"::Goods) then
                                    ApplyDetailedGSTLedgerEntry."Liable to Pay" := true
                                else
                                    if (ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::Availment) then
                                        ApplyDetailedGSTLedgerEntry."Credit Availed" := true
                                    else
                                        if (ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::"Non-Availment") then
                                            ApplyDetailedGSTLedgerEntry."Credit Availed" := false;
                            ApplyDetailedGSTLedgerEntry.Paid := false;
                            ApplyDetailedGSTLedgerEntry."CLE/VLE Entry No." := PaymentEntryNo;
                            ApplyDetailedGSTLedgerEntry.Insert(true);
                            AppliedBaseAmountInvoiceLCY := 0;
                            HigherInvoiceExchangeRate := false;
                            AppliedBaseAmountInvoiceLCY :=
                              CalculateAndFillGSTPostingBufferForexFluctuation(
                                GSTApplicationBuffer, 0, HigherInvoiceExchangeRate);
                            if AppliedBaseAmountInvoiceLCY <> 0 then begin
                                AppliedBaseAmountInvoiceLCY := Abs(AppliedBaseAmountInvoiceLCY) - Abs(GSTApplicationBuffer."Applied Base Amount");
                                GSTApplicationBuffer."Amt to Apply (Applied)" := GSTApplicationBuffer."Amt to Apply" / Abs(GSTApplicationBuffer."Applied Base Amount") * AppliedBase;
                                GSTApplicationBuffer.Modify();
                                AppliedBaseAmountInvoiceLCY := Round(Abs(AppliedBaseAmountInvoiceLCY * GSTApplicationBuffer."Amt to Apply (Applied)" / GSTApplicationBuffer."Amt to Apply"));
                                AppliedAmountInvoiceLCY := Round(AppliedBaseAmountInvoiceLCY * GSTApplicationBuffer."GST %" / 100);
                                CreateDetailedGSTApplicationEntry(
                                  ApplyDetailedGSTLedgerEntry2, DetailedGSTLedgerEntry, GenJournalLine,
                                  InvoiceNo, AppliedBaseAmountInvoiceLCY, AppliedAmountInvoiceLCY, GSTApplicationBuffer."Original Document No.");
                                ApplyDetailedGSTLedgerEntry2."Forex Fluctuation" := true;
                                ApplyDetailedGSTLedgerEntry2.Quantity := 0;
                                if ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::"Non-Availment" then
                                    ApplyDetailedGSTLedgerEntry2."Amount Loaded on Item" := ApplyDetailedGSTLedgerEntry2."GST Amount";
                                if (GSTApplicationBuffer."Currency Factor" < DetailedGSTLedgerEntry."Currency Factor") and
                                   (ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::Availment)
                                then
                                    ApplyDetailedGSTLedgerEntry2."Credit Availed" := true;
                                if (GSTApplicationBuffer."Currency Factor" > DetailedGSTLedgerEntry."Currency Factor") and
                                   (ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::"Non-Availment")
                                then
                                    ApplyDetailedGSTLedgerEntry2."Fluctuation Amt. Credit" := true;
                                ApplyDetailedGSTLedgerEntry2.Insert(true);
                                FillGSTPostingBufferWithApplication(ApplyDetailedGSTLedgerEntry2, true, HigherInvoiceExchangeRate);
                            end;
                            GSTApplicationLibrary.GetApplicationDocTypeFromGSTDocumentType(DetailedGSTLedgerEntry."Application Doc. Type", ApplyDetailedGSTLedgerEntry."Document Type");
                            DetailedGSTLedgerEntry."Application Doc. No" := ApplyDetailedGSTLedgerEntry."Document No.";
                            if (GSTApplicationBuffer."Currency Factor" <> DetailedGSTLedgerEntry."Currency Factor") and
                               (GSTApplicationBuffer."Currency Factor" > DetailedGSTLedgerEntry."Currency Factor")
                            then begin
                                DetailedGSTLedgerEntry."Remaining Base Amount" -= AppliedBase + AppliedBaseAmountInvoiceLCY;
                                if not GSTApplicationBuffer."RCM Exempt" then
                                    DetailedGSTLedgerEntry."Remaining GST Amount" -= AppliedAmount + AppliedAmountInvoiceLCY;
                            end else begin
                                DetailedGSTLedgerEntry."Remaining Base Amount" -= AppliedBase;
                                if not GSTApplicationBuffer."RCM Exempt" then
                                    DetailedGSTLedgerEntry."Remaining GST Amount" -= AppliedAmount;
                            end;
                            DetailedGSTLedgerEntry."Remaining Amount Closed" := DetailedGSTLedgerEntry."Remaining Base Amount" = 0;
                            DetailedGSTLedgerEntry.Modify();
                            RemainingBase := Abs(RemainingBase) - Abs(AppliedBase);
                            RemainingAmount := Abs(RemainingAmount) - Abs(AppliedAmount);
                            FillGSTPostingBufferWithApplication(ApplyDetailedGSTLedgerEntry, false, false);
                        end;
                    until DetailedGSTLedgerEntry.Next() = 0;
                    if GSTPostingBuffer[1].FindLast() then
                        repeat
                            GetCreditAccountAdvancePayment(DetailedGSTLedgerEntry, GSTPostingBuffer[1], AccountNo, BalanceAccountNo, BalanceAccountNo2);
                            CreateApplicationGSTLedger(
                              GSTPostingBuffer[1], ApplyDetailedGSTLedgerEntry, GenJournalLine."Posting Date",
                              SourceCodeSetup."Purchase Entry Application", ApplyDetailedGSTLedgerEntry."Payment Type",
                              AccountNo, BalanceAccountNo, BalanceAccountNo2, '');
                            PostPurchaseApplicationGLEntries(
                              GenJournalLine, false, AccountNo, BalanceAccountNo, BalanceAccountNo2, GSTPostingBuffer[1]."GST Amount",
                              ApplyDetailedGSTLedgerEntry."RCM Exempt Transaction");
                        until GSTPostingBuffer[1].Next(-1) = 0;
                end;
            until GSTApplicationBuffer.Next() = 0;
        GSTApplicationLibrary.DeletePaymentAplicationBuffer(TransactionType::Purchase, PaymentEntryNo);
        GSTApplicationLibrary.DeleteInvoiceApplicationBufferOffline(
          TransactionType::Purchase, GenJournalLine."Account No.", GSTApplicationBuffer."Original Document Type"::Invoice, InvoiceNo);
    end;

    local procedure PostGSTWithNormalPaymentOffline(
        var GenJournalLine: Record "Gen. Journal Line";
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        TransactionType: Enum "Detail Ledger Transaction Type";
    begin
        if not ApplyingVendorLedgerEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
            exit;
        if not VendorLedgerEntry.Get(CVLedgerEntryBuffer."Entry No.") then
            exit;
        case ApplyingVendorLedgerEntry."Document Type" of
            ApplyingVendorLedgerEntry."Document Type"::Invoice:
                begin
                    if VendorLedgerEntry."GST on Advance Payment" then
                        exit;
                    if not ApplyingVendorLedgerEntry."GST Reverse Charge" then
                        exit;
                    if not GSTApplicationLibrary.DoesGSTExist(TransactionType::Purchase, ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.") then
                        exit;
                    VendorLedgerEntry.TestField("Document Type", VendorLedgerEntry."Document Type"::Payment);
                    ApplyingVendorLedgerEntry.TestField("Currency Code", VendorLedgerEntry."Currency Code");
                    if VendorLedgerEntry."GST Group Code" <> '' then
                        ApplyingVendorLedgerEntry.TestField("TDS Section Code", VendorLedgerEntry."TDS Section Code");
                    if not GSTApplicationLibrary.FillAppBufferInvoice(
                         TransactionType::Purchase, ApplyingVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.",
                         ApplyingVendorLedgerEntry."Total TDS Including SHE CESS", OldCVLedgerEntryBuffer."Amount to Apply", VendorLedgerEntry."Original Currency Factor")
                    then
                        exit;
                    GSTApplicationLibrary.AllocateGSTWithNormalPayment(
                      ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.", AmountToApply);
                    PostPurchGSTApplicationNormalPaymentGL(
                      GenJournalLine, VendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Document No.",
                      ApplyingVendorLedgerEntry."Transaction No.", VendorLedgerEntry."RCM Exempt", VendorLedgerEntry."Original Currency Factor",
                      Round(Abs(OldCVLedgerEntryBuffer."Amount to Apply" / VendorLedgerEntry."Original Currency Factor")));
                end;
            ApplyingVendorLedgerEntry."Document Type"::Payment, ApplyingVendorLedgerEntry."Document Type"::" ":
                begin
                    if ApplyingVendorLedgerEntry."GST on Advance Payment" then
                        exit;
                    if not VendorLedgerEntry."GST Reverse Charge" then
                        exit;
                    if not GSTApplicationLibrary.DoesGSTExist(TransactionType::Purchase, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.") then
                        exit;
                    ApplyingVendorLedgerEntry.TestField("Document Type", ApplyingVendorLedgerEntry."Document Type"::Payment);
                    ApplyingVendorLedgerEntry.TestField("Currency Code", VendorLedgerEntry."Currency Code");
                    if VendorLedgerEntry."GST Group Code" <> '' then
                        ApplyingVendorLedgerEntry.TestField(ApplyingVendorLedgerEntry."TDS Section Code", VendorLedgerEntry."TDS Section Code");
                    if not GSTApplicationLibrary.FillAppBufferInvoice(
                         TransactionType::Purchase, VendorLedgerEntry."Document No.",
                         VendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.",
                         VendorLedgerEntry."Total TDS Including SHE CESS", ApplyingVendorLedgerEntry."Amount to Apply", ApplyingVendorLedgerEntry."Original Currency Factor")
                    then
                        exit;
                    GSTApplicationLibrary.AllocateGSTWithNormalPayment(
                      VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.",
                      AmountToApply);
                    PostPurchGSTApplicationNormalPaymentGL(
                      GenJournalLine, ApplyingVendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.",
                      VendorLedgerEntry."Transaction No.", ApplyingVendorLedgerEntry."RCM Exempt", ApplyingVendorLedgerEntry."Original Currency Factor",
                      Round(ApplyingVendorLedgerEntry."Amount to Apply" / ApplyingVendorLedgerEntry."Original Currency Factor"));
                end;
        end;
    end;

    local procedure PostGSTWithNormalPaymentOnline(
        var GenJournalLine: Record "Gen. Journal Line";
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        AmountToApply: Decimal)
    var
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        TransactionType: Enum "Detail Ledger Transaction Type";
        TotalTDSInclSHECessAmount: Decimal;
    begin
        if not ApplyingVendorLedgerEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
            exit;
        case ApplyingVendorLedgerEntry."Document Type" of
            ApplyingVendorLedgerEntry."Document Type"::Invoice:
                begin
                    if OnlineVendorLedgerEntry."GST on Advance Payment" then
                        exit;
                    if not ApplyingVendorLedgerEntry."GST Reverse Charge" then
                        exit;
                    if not GSTApplicationLibrary.DoesGSTExist(TransactionType::Purchase, ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.") then
                        exit;
                    OnlineVendorLedgerEntry.TestField("Document Type", OnlineVendorLedgerEntry."Document Type"::Payment);
                    ApplyingVendorLedgerEntry.TestField("Currency Code", OnlineVendorLedgerEntry."Currency Code");
                    GenJournalLine.TestField("Work Tax Nature Of Deduction", '');

                    if not GSTApplicationLibrary.FillAppBufferInvoice(
                         TransactionType::Purchase, ApplyingVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Vendor No.", OnlineVendorLedgerEntry."Document No.",
                         ApplyingVendorLedgerEntry."Total TDS Including SHE CESS", ApplyingVendorLedgerEntry."Amount to Apply",
                         CVLedgerEntryBuffer."Original Currency Factor")
                    then
                        exit;
                    GSTApplicationLibrary.AllocateGSTWithNormalPayment(
                      ApplyingVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.", AmountToApply);
                    PostPurchGSTApplicationNormalPaymentGL(
                      GenJournalLine, OnlineVendorLedgerEntry."Document No.", ApplyingVendorLedgerEntry."Document No.",
                      ApplyingVendorLedgerEntry."Transaction No.", OnlineVendorLedgerEntry."RCM Exempt", CVLedgerEntryBuffer."Original Currency Factor",
                      Round(Abs(ApplyingVendorLedgerEntry."Amount to Apply" / CVLedgerEntryBuffer."Original Currency Factor")));
                end;
            ApplyingVendorLedgerEntry."Document Type"::Payment, ApplyingVendorLedgerEntry."Document Type"::" ":
                begin
                    if ApplyingVendorLedgerEntry."GST on Advance Payment" then
                        exit;
                    if not OnlineVendorLedgerEntry."GST Reverse Charge" then
                        exit;
                    if not GSTApplicationLibrary.DoesGSTExist(TransactionType::Purchase, OnlineVendorLedgerEntry."Vendor No.", OnlineVendorLedgerEntry."Document No.") then
                        exit;
                    ApplyingVendorLedgerEntry.TestField("Document Type", ApplyingVendorLedgerEntry."Document Type"::Payment);
                    TotalTDSInclSHECessAmount := GSTApplSessionMgt.GetTotalTDSInclSHECessAmount();
                    if not GSTApplicationLibrary.FillAppBufferInvoice(
                         TransactionType::Purchase, OnlineVendorLedgerEntry."Document No.",
                         OnlineVendorLedgerEntry."Vendor No.", ApplyingVendorLedgerEntry."Document No.",
                         TotalTDSInclSHECessAmount, ApplyingVendorLedgerEntry."Amount to Apply", ApplyingVendorLedgerEntry."Original Currency Factor") //OnlineVendorLedgerEntry."Total TDS Including SHE CESS"
                    then
                        exit;
                    ApplyingVendorLedgerEntry.TestField("Currency Code", OnlineVendorLedgerEntry."Currency Code");
                    GenJournalLine.TestField("Work Tax Nature Of Deduction", '');
                    GSTApplicationLibrary.AllocateGSTWithNormalPayment(
                      OnlineVendorLedgerEntry."Vendor No.", OnlineVendorLedgerEntry."Document No.",
                      AmountToApply);
                    PostPurchGSTApplicationNormalPaymentGL(
                      GenJournalLine, ApplyingVendorLedgerEntry."Document No.", OnlineVendorLedgerEntry."Document No.",
                      OnlineVendorLedgerEntry."Transaction No.", ApplyingVendorLedgerEntry."RCM Exempt", OldCVLedgerEntryBuffer."Original Currency Factor",
                      Round(ApplyingVendorLedgerEntry."Amount to Apply" / ApplyingVendorLedgerEntry."Original Currency Factor"));
                end;
        end;
    end;

    local procedure PostPurchGSTApplicationNormalPaymentGL(
        var GenJournalLine: Record "Gen. Journal Line";
        PaymentDocNo: Code[20];
        InvoiceNo: Code[20];
        TransactionNo: Integer;
        RCMExempt: Boolean;
        PaymentCurrencyFactor: Decimal;
        PaymentOriginalAmountLCY: Decimal)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GSTLedgerEntry: Record "GST Ledger Entry";
        ApplyGSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ApplyDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ApplyDetailedGSTLedgerEntry2: Record "Detailed GST Ledger Entry";
        GSTApplicationBuffer: Record "GST Application Buffer";
        GSTApplicationBuffer2: Record "GST Application Buffer";
        TransactionType: Enum "Detail Ledger Transaction Type";
        GSTGLAccountType: Enum "GST GL Account Type";
        AccountNo: Code[20];
        AccountNo2: Code[20];
        BalanceAccountNo: Code[20];
        BalanceAccountNo2: Code[20];
        AppliedBase: Decimal;
        AppliedAmount: Decimal;
        RemainingBase: Decimal;
        RemainingAmount: Decimal;
        ApplicableRemainingGSTAmount: Decimal;
        ApplicationRatio: Decimal;
        AppliedBaseAmountInvoiceLCY: Decimal;
        AppliedAmountInvoiceLCY: Decimal;
        HigherInvoiceExchangeRate: Boolean;
    begin
        SourceCodeSetup.Get();
        GSTApplicationBuffer.SetRange("Transaction Type", GSTApplicationBuffer."Transaction Type"::Purchase);
        GSTApplicationBuffer.SetRange("Account No.", GenJournalLine."Account No.");
        GSTApplicationBuffer.SetRange("Original Document Type", GSTApplicationBuffer."Original Document Type"::Invoice);
        GSTApplicationBuffer.SetRange("Original Document No.", InvoiceNo);
        GSTApplicationBuffer.SetRange("Applied Doc. Type", GSTApplicationBuffer."Applied Doc. Type"::Payment);
        GSTApplicationBuffer.SetRange("Applied Doc. No.", PaymentDocNo);
        if GSTApplicationBuffer.FindSet() then
            repeat
                DetailedGSTLedgerEntry.SetCurrentKey(
                  "Transaction Type", "Source No.", "CLE/VLE Entry No.", "Document Type", "Document No.", "GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
                DetailedGSTLedgerEntry.SetRange("Source No.", GenJournalLine."Account No.");
                DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Invoice);
                DetailedGSTLedgerEntry.SetRange("Document No.", InvoiceNo);
                DetailedGSTLedgerEntry.SetRange("GST Group Code", GSTApplicationBuffer."GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
                DetailedGSTLedgerEntry.SetRange("GST Component Code", GSTApplicationBuffer."GST Component Code");
                DetailedGSTLedgerEntry.SetRange("GST Exempted Goods", false);
                DetailedGSTLedgerEntry.SetRange("Remaining Amount Closed", false);
                if DetailedGSTLedgerEntry.FindSet() then begin
                    RemainingBase := GSTApplicationBuffer."Applied Base Amount";
                    RemainingAmount := GSTApplicationBuffer."Applied Amount";
                    GSTPostingBuffer[1].DeleteAll();
                    GSTApplicationLibrary.CheckGSTAccountingPeriod(GenJournalLine."Posting Date");
                    repeat
                        if (RemainingBase <> 0) and (DetailedGSTLedgerEntry."Remaining Base Amount" > 0) then begin
                            ApplicationRatio := 1;
                            if (PaymentCurrencyFactor <> DetailedGSTLedgerEntry."Currency Factor") and
                               (DetailedGSTLedgerEntry."Currency Code" <> '') and
                               (PaymentCurrencyFactor > DetailedGSTLedgerEntry."Currency Factor") and
                               (DetailedGSTLedgerEntry."GST Group Type" = DetailedGSTLedgerEntry."GST Group Type"::Service)
                            then
                                ApplicationRatio := PaymentOriginalAmountLCY / Round(GSTApplicationBuffer."Amt to Apply" / GSTApplicationBuffer."Currency Factor");
                            GSTApplicationLibrary.GetAppliedAmount(
                              Abs(RemainingBase), Abs(RemainingAmount), Abs(DetailedGSTLedgerEntry."Remaining Base Amount" * ApplicationRatio),
                              Abs(DetailedGSTLedgerEntry."Remaining GST Amount" * ApplicationRatio), AppliedBase, AppliedAmount);
                            CreateDetailedGSTApplicationEntry(
                              ApplyDetailedGSTLedgerEntry, DetailedGSTLedgerEntry, GenJournalLine,
                              InvoiceNo, AppliedBase, AppliedAmount, GSTApplicationBuffer."Original Document No.");
                            ApplyDetailedGSTLedgerEntry.Paid := false;
                            ApplyDetailedGSTLedgerEntry."Payment Type" := ApplyDetailedGSTLedgerEntry."Payment Type"::Normal;
                            ApplyDetailedGSTLedgerEntry."Original Doc. No." := PaymentDocNo;
                            ApplyDetailedGSTLedgerEntry."Credit Availed" :=
                              ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::Availment;
                            if not RCMExempt then
                                ApplyDetailedGSTLedgerEntry."Liable to Pay" := true;
                            if RCMExempt then begin
                                ApplyDetailedGSTLedgerEntry."RCM Exempt Transaction" := RCMExempt;
                                ApplyDetailedGSTLedgerEntry."Liable to Pay" := false;
                                ApplyDetailedGSTLedgerEntry."Credit Availed" := false;
                                if (ApplyDetailedGSTLedgerEntry."GST Group Type" = ApplyDetailedGSTLedgerEntry."GST Group Type"::Service) and
                                   (ApplyDetailedGSTLedgerEntry.Type = ApplyDetailedGSTLedgerEntry.Type::"G/L Account") and
                                   (ApplyDetailedGSTLedgerEntry."GST Credit" = ApplyDetailedGSTLedgerEntry."GST Credit"::"Non-Availment")
                                then
                                    ApplyDetailedGSTLedgerEntry."Amount Loaded on Item" := ApplyDetailedGSTLedgerEntry."GST Amount";
                            end;
                            ApplyDetailedGSTLedgerEntry.Insert(true);
                            AppliedBaseAmountInvoiceLCY := 0;
                            HigherInvoiceExchangeRate := false;
                            AppliedBaseAmountInvoiceLCY :=
                              CalculateAndFillGSTPostingBufferForexFluctuation(
                                GSTApplicationBuffer, PaymentCurrencyFactor, HigherInvoiceExchangeRate);
                            if AppliedBaseAmountInvoiceLCY <> 0 then begin
                                AppliedBaseAmountInvoiceLCY := Abs(AppliedBaseAmountInvoiceLCY) - Abs(GSTApplicationBuffer."Applied Base Amount");
                                GSTApplicationBuffer."Amt to Apply (Applied)" := GSTApplicationBuffer."Amt to Apply" / Abs(GSTApplicationBuffer."Applied Base Amount") * AppliedBase;
                                GSTApplicationBuffer.Modify();
                                AppliedBaseAmountInvoiceLCY := Round(Abs(AppliedBaseAmountInvoiceLCY * GSTApplicationBuffer."Amt to Apply (Applied)" / GSTApplicationBuffer."Amt to Apply"));
                                AppliedAmountInvoiceLCY := Round(AppliedBaseAmountInvoiceLCY * GSTApplicationBuffer."GST %" / 100);
                                CreateDetailedGSTApplicationEntry(
                                  ApplyDetailedGSTLedgerEntry2, DetailedGSTLedgerEntry, GenJournalLine,
                                  InvoiceNo, AppliedBaseAmountInvoiceLCY, AppliedAmountInvoiceLCY, GSTApplicationBuffer."Original Document No.");
                                ApplyDetailedGSTLedgerEntry2."Forex Fluctuation" := true;
                                ApplyDetailedGSTLedgerEntry2."Payment Type" := ApplyDetailedGSTLedgerEntry2."Payment Type"::Normal;
                                ApplyDetailedGSTLedgerEntry2."Original Doc. No." := PaymentDocNo;
                                ApplyDetailedGSTLedgerEntry2.Quantity := 0;
                                if ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::"Non-Availment" then
                                    ApplyDetailedGSTLedgerEntry2."Amount Loaded on Item" := ApplyDetailedGSTLedgerEntry2."GST Amount";
                                if PaymentCurrencyFactor < DetailedGSTLedgerEntry."Currency Factor" then
                                    if ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::"Non-Availment" then
                                        ApplyDetailedGSTLedgerEntry2."Liable to Pay" := true
                                    else
                                        if ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::Availment then begin
                                            ApplyDetailedGSTLedgerEntry2."Credit Availed" := true;
                                            ApplyDetailedGSTLedgerEntry2."Liable to Pay" := true;
                                        end;
                                if (PaymentCurrencyFactor > DetailedGSTLedgerEntry."Currency Factor") and
                                   (ApplyDetailedGSTLedgerEntry2."GST Credit" = ApplyDetailedGSTLedgerEntry2."GST Credit"::"Non-Availment")
                                then
                                    ApplyDetailedGSTLedgerEntry2."Fluctuation Amt. Credit" := true;
                                ApplyDetailedGSTLedgerEntry2.Insert(true);
                                FillGSTPostingBufferWithApplication(ApplyDetailedGSTLedgerEntry2, true, HigherInvoiceExchangeRate);
                            end;
                            GSTApplicationLibrary.GetApplicationDocTypeFromGSTDocumentType(DetailedGSTLedgerEntry."Application Doc. Type", ApplyDetailedGSTLedgerEntry."Document Type");
                            DetailedGSTLedgerEntry."Application Doc. No" := ApplyDetailedGSTLedgerEntry."Document No.";
                            if (PaymentCurrencyFactor <> DetailedGSTLedgerEntry."Currency Factor") and
                               (PaymentCurrencyFactor > DetailedGSTLedgerEntry."Currency Factor")
                            then begin
                                DetailedGSTLedgerEntry."Remaining Base Amount" -= AppliedBase + AppliedBaseAmountInvoiceLCY;
                                DetailedGSTLedgerEntry."Remaining GST Amount" -= AppliedAmount + AppliedAmountInvoiceLCY;
                            end else begin
                                DetailedGSTLedgerEntry."Remaining Base Amount" -= AppliedBase;
                                DetailedGSTLedgerEntry."Remaining GST Amount" -= AppliedAmount;
                            end;
                            DetailedGSTLedgerEntry."Remaining Amount Closed" := DetailedGSTLedgerEntry."Remaining Base Amount" = 0;
                            DetailedGSTLedgerEntry.Modify();
                            RemainingBase := Abs(RemainingBase) - Abs(AppliedBase);
                            RemainingAmount := Abs(RemainingAmount) - Abs(AppliedAmount);
                            FillGSTPostingBufferWithApplication(ApplyDetailedGSTLedgerEntry, false, false);
                        end;
                    until DetailedGSTLedgerEntry.Next() = 0;
                    if GSTPostingBuffer[1].FindLast() then
                        repeat
                            GetCreditAccountNormalPayment(
                              DetailedGSTLedgerEntry, GSTPostingBuffer[1], AccountNo, AccountNo2,
                              BalanceAccountNo, BalanceAccountNo2, RCMExempt);
                            CreateApplicationGSTLedger(
                              GSTPostingBuffer[1], ApplyDetailedGSTLedgerEntry, GenJournalLine."Posting Date",
                              SourceCodeSetup."Purchase Entry Application", ApplyDetailedGSTLedgerEntry."Payment Type",
                              AccountNo, BalanceAccountNo, BalanceAccountNo2, AccountNo2);
                            PostNormalPaymentApplicationGLEntries(
                              GenJournalLine, false, AccountNo, AccountNo2, BalanceAccountNo,
                              BalanceAccountNo2, GSTPostingBuffer[1]."GST Amount");
                        until GSTPostingBuffer[1].Next(-1) = 0;
                end;
            until GSTApplicationBuffer.Next() = 0;
        GSTApplicationLibrary.DeleteInvoiceApplicationBufferOffline(
          TransactionType::Purchase, GenJournalLine."Account No.", GSTApplicationBuffer."Original Document Type"::Invoice, InvoiceNo);
    end;

    local procedure GetCreditAccountAdvancePayment(
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTPostingBuffer: Record "GST Posting Buffer";
        var AccountNo: Code[20];
        var BalanceAccountNo: Code[20];
        var BalanceAccountNo2: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GSTGLAccountType: Enum "GST GL Account Type";
    begin
        Clear(AccountNo);
        Clear(BalanceAccountNo);
        Clear(BalanceAccountNo2);
        if GSTPostingBuffer."GST Group Type" = GSTPostingBuffer."GST Group Type"::Goods then
            if DetailedGSTLedgerEntry."GST Vendor Type" = "GST Vendor Type"::Unregistered then begin
                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                BalanceAccountNo :=
                  GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
            end;
        if GSTPostingBuffer."GST Group Type" = GSTPostingBuffer."GST Group Type"::Service then
            if DetailedGSTLedgerEntry."Associated Enterprises" then begin
                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
            end else
                if not GSTPostingBuffer."Forex Fluctuation" then
                    if GSTPostingBuffer.Availment then begin
                        AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        if not DetailedGSTLedgerEntry."RCM Exempt Transaction" then
                            BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        BalanceAccountNo2 :=
                          GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        if DetailedGSTLedgerEntry."Input Service Distribution" then begin
                            AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Acc. Interim (Dist)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            BalanceAccountNo2 := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Acc. (Dist)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        end;
                    end else begin
                        AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        if not DetailedGSTLedgerEntry."RCM Exempt Transaction" then
                            BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code")
                        else
                            BalanceAccountNo := GSTPostingBuffer."Account No.";
                    end else
                    case GSTPostingBuffer.Availment of
                        true:
                            if GSTPostingBuffer."Higher Inv. Exchange Rate" then begin
                                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                                BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            end else begin
                                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                                BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            end;
                        false:
                            if GSTPostingBuffer."Higher Inv. Exchange Rate" then begin
                                if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then begin
                                    GeneralPostingSetup.Get(
                                      GSTPostingBuffer."Gen. Bus. Posting Group", GSTPostingBuffer."Gen. Prod. Posting Group");
                                    AccountNo := GeneralPostingSetup."Purch. Account"
                                end else
                                    if GSTPostingBuffer.Type in [GSTPostingBuffer.Type::"G/L Account",
                                                                 GSTPostingBuffer.Type::"Fixed Asset"]
                                    then
                                        AccountNo := GSTPostingBuffer."Account No.";
                                BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                                if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then
                                    PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", true, false)
                                else
                                    if GSTPostingBuffer.Type = GSTPostingBuffer.Type::"Fixed Asset" then
                                        PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", true, true)
                            end else begin
                                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                                if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then begin
                                    GeneralPostingSetup.Get(
                                      GSTPostingBuffer."Gen. Bus. Posting Group", GSTPostingBuffer."Gen. Prod. Posting Group");
                                    BalanceAccountNo := GeneralPostingSetup."Purch. Account";
                                end else
                                    if GSTPostingBuffer.Type in [GSTPostingBuffer.Type::"G/L Account",
                                                                 GSTPostingBuffer.Type::"Fixed Asset"]
                                    then
                                        BalanceAccountNo := GSTPostingBuffer."Account No.";
                                if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then
                                    PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", false, false)
                                else
                                    if GSTPostingBuffer.Type = GSTPostingBuffer.Type::"Fixed Asset" then
                                        PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", false, true)
                            end;
                    end;
    end;

    local procedure PostPurchaseApplicationGLEntries(
        var GenJournalLine: Record "Gen. Journal Line";
        UnApplication: Boolean;
        AccountNo: Code[20];
        BalanceAccountNo: Code[20];
        BalanceAccountNo2: Code[20];
        GSTAmount: Decimal;
        RCMExempt: Boolean)
    begin
        if GSTAmount = 0 then
            exit;

        if UnApplication then begin
            if BalanceAccountNo2 <> '' then
                if not RCMExempt then
                    PostToGLEntry(GenJournalLine, AccountNo, Abs(GSTAmount) + Abs(GSTAmount), GenJournalLine."System-Created Entry")
                else
                    PostToGLEntry(GenJournalLine, AccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry")
            else
                PostToGLEntry(GenJournalLine, AccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if BalanceAccountNo <> '' then
                PostToGLEntry(GenJournalLine, BalanceAccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if BalanceAccountNo2 <> '' then
                PostToGLEntry(GenJournalLine, BalanceAccountNo2, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
        end else begin
            if BalanceAccountNo2 <> '' then
                if not RCMExempt then
                    PostToGLEntry(GenJournalLine, AccountNo, -(Abs(GSTAmount) + Abs(GSTAmount)), GenJournalLine."System-Created Entry")
                else
                    PostToGLEntry(GenJournalLine, AccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry")
            else
                PostToGLEntry(GenJournalLine, AccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if BalanceAccountNo <> '' then
                PostToGLEntry(GenJournalLine, BalanceAccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if BalanceAccountNo2 <> '' then
                PostToGLEntry(GenJournalLine, BalanceAccountNo2, Abs(GSTAmount), GenJournalLine."System-Created Entry");
        end;
    end;

    local procedure GetCreditAccountNormalPayment(
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTPostingBuffer: Record "GST Posting Buffer";
        var AccountNo: Code[20];
        var AccountNo2: Code[20];
        var BalanceAccountNo: Code[20];
        var BalanceAccountNo2: Code[20];
        RCMExempt: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GSTGLAccountType: Enum "GST GL Account Type";
    begin
        Clear(AccountNo);
        Clear(AccountNo2);
        Clear(BalanceAccountNo);
        Clear(BalanceAccountNo2);

        if GSTPostingBuffer.Availment then
            case GSTPostingBuffer."Forex Fluctuation" of
                false:
                    begin
                        if not RCMExempt then begin
                            AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            AccountNo2 := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            BalanceAccountNo2 := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        end else
                            if RCMExempt then begin
                                AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                                BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            end;
                        if DetailedGSTLedgerEntry."Input Service Distribution" then begin
                            AccountNo2 := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Acc. Interim (Dist)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                            BalanceAccountNo2 := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Acc. (Dist)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        end;
                    end;
                true:
                    if GSTPostingBuffer."Higher Inv. Exchange Rate" then begin
                        AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                    end else begin
                        AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Receivable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                    end;
            end else
            case GSTPostingBuffer."Forex Fluctuation" of
                true:
                    if GSTPostingBuffer."Higher Inv. Exchange Rate" then begin
                        if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then begin
                            GeneralPostingSetup.Get(GSTPostingBuffer."Gen. Bus. Posting Group", GSTPostingBuffer."Gen. Prod. Posting Group");
                            AccountNo := GeneralPostingSetup."Purch. Account"
                        end else
                            if GSTPostingBuffer.Type in [GSTPostingBuffer.Type::"G/L Account",
                                                         GSTPostingBuffer.Type::"Fixed Asset"]
                            then
                                AccountNo := GSTPostingBuffer."Account No.";
                        BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then
                            PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", true, false)
                        else
                            if GSTPostingBuffer.Type = GSTPostingBuffer.Type::"Fixed Asset" then
                                PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", true, true)
                    end else begin
                        AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                        if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then begin
                            GeneralPostingSetup.Get(GSTPostingBuffer."Gen. Bus. Posting Group", GSTPostingBuffer."Gen. Prod. Posting Group");
                            BalanceAccountNo := GeneralPostingSetup."Purch. Account";
                        end else
                            if GSTPostingBuffer.Type in [GSTPostingBuffer.Type::"G/L Account",
                                                         GSTPostingBuffer.Type::"Fixed Asset"]
                            then
                                BalanceAccountNo := GSTPostingBuffer."Account No.";
                        if GSTPostingBuffer.Type = GSTPostingBuffer.Type::Item then
                            PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", false, false)
                        else
                            if GSTPostingBuffer.Type = GSTPostingBuffer.Type::"Fixed Asset" then
                                PostRevaluationEntry(GSTPostingBuffer, DetailedGSTLedgerEntry."Document No.", false, true)
                    end;
                false:
                    begin
                        if not RCMExempt then
                            AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code")
                        else
                            AccountNo := GSTPostingBuffer."Account No.";
                        BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", DetailedGSTLedgerEntry."Location State Code", GSTPostingBuffer."GST Component Code");
                    end;
            end;
    end;

    local procedure PostNormalPaymentApplicationGLEntries(
        var GenJournalLine: Record "Gen. Journal Line";
        UnApplication: Boolean;
        AccountNo: Code[20];
        AccountNo2: Code[20];
        BalanceAccountNo: Code[20];
        BalanceAccountNo2: Code[20];
        GSTAmount: Decimal)
    begin
        if GSTAmount = 0 then
            exit;

        if UnApplication then begin
            PostToGLEntry(GenJournalLine, AccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            PostToGLEntry(GenJournalLine, BalanceAccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if AccountNo2 <> '' then begin
                PostToGLEntry(GenJournalLine, AccountNo2, Abs(GSTAmount), GenJournalLine."System-Created Entry");
                PostToGLEntry(GenJournalLine, BalanceAccountNo2, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            end;
        end else begin
            PostToGLEntry(GenJournalLine, AccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            PostToGLEntry(GenJournalLine, BalanceAccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            if AccountNo2 <> '' then begin
                PostToGLEntry(GenJournalLine, AccountNo2, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
                PostToGLEntry(GenJournalLine, BalanceAccountNo2, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            end;
        end;
    end;

    local procedure PostRevaluationEntry(
        GSTPostingBuffer: Record "GST Posting Buffer";
        DocumentNo: Code[20];
        CreditValue: Boolean;
        FixedAsset: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        EntryNo: Integer;
        Ctr: Integer;
    begin
        case FixedAsset of
            false:
                begin
                    ValueEntry.Reset();
                    ValueEntry.SetRange("Document No.", DocumentNo);
                    ValueEntry.SetRange("Document Line No.", GSTPostingBuffer."Document Line No.");
                    if ValueEntry.FindFirst() then begin
                        if not ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                            exit;
                        if GSTPostingBuffer."GST Amount" <> 0 then begin
                            ItemJournalLine.Init();
                            ItemJournalLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
                            ItemJournalLine."Document Date" := ItemLedgerEntry."Posting Date";
                            ItemJournalLine.Validate("Document No.", ValueEntry."Document No.");
                            ItemJournalLine."Document Line No." := ItemLedgerEntry."Document Line No.";
                            ItemJournalLine."External Document No." := ItemLedgerEntry."External Document No.";
                            ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Purchase);
                            ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::Revaluation;
                            ItemJournalLine.Validate("Item No.", ItemLedgerEntry."Item No.");
                            ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Vendor;
                            ItemJournalLine."Source No." := ItemLedgerEntry."Source No.";
                            ItemJournalLine."Gen. Bus. Posting Group" := GSTPostingBuffer."Gen. Bus. Posting Group";
                            ItemJournalLine."Gen. Prod. Posting Group" := GSTPostingBuffer."Gen. Prod. Posting Group";
                            SourceCodeSetup.Get();
                            ItemJournalLine."Source Code" := SourceCodeSetup."Revaluation Journal";
                            ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
                            if CreditValue then
                                ItemJournalLine.Validate("Unit Cost (Revalued)", (ItemJournalLine."Unit Cost (Revalued)" + GSTPostingBuffer."GST Amount" / ItemLedgerEntry.Quantity))
                            else
                                ItemJournalLine.Validate("Unit Cost (Revalued)", (ItemJournalLine."Unit Cost (Revalued)" - GSTPostingBuffer."GST Amount" / ItemLedgerEntry.Quantity));
                            Ctr := ItemJournalLine2."Line No." + 1;
                            ItemJournalLine2.Init();
                            ItemJournalLine2.TransferFields(ItemJournalLine);
                            ItemJournalLine2."Line No." := Ctr;
                            ItemJnlPostLine.Run(ItemJournalLine2);
                        end;
                    end;
                end;
            true:
                begin
                    FALedgerEntry.FindLast();
                    EntryNo := FALedgerEntry."Entry No." + 1;
                    FALedgerEntry.Reset();
                    FALedgerEntry.SetRange("Document No.", DocumentNo);
                    FALedgerEntry.SetRange("FA No.", GSTPostingBuffer."No.");
                    if FALedgerEntry.FindFirst() then begin
                        FALedgerEntry2.Copy(FALedgerEntry);
                        FALedgerEntry2."Entry No." := EntryNo;
                        if CreditValue then begin
                            FALedgerEntry2.Amount := GSTPostingBuffer."GST Amount";
                            FALedgerEntry2."Amount (LCY)" := GSTPostingBuffer."GST Amount";
                            FALedgerEntry2."Debit Amount" := GSTPostingBuffer."GST Amount";
                            FALedgerEntry2."Bal. Account No." := GSTPostingBuffer."Bal. Account No."
                        end else begin
                            FALedgerEntry2.Amount := Abs(GSTPostingBuffer."GST Amount");
                            FALedgerEntry2."Amount (LCY)" := Abs(GSTPostingBuffer."GST Amount");
                            FALedgerEntry2."Debit Amount" := Abs(GSTPostingBuffer."GST Amount");
                            FALedgerEntry2."Bal. Account No." := GSTPostingBuffer."Account No.";
                        end;
                        FALedgerEntry2.Insert(true);
                    end;
                end;
        end;
    end;

    local procedure PostGSTSalesApplication(
        var GenJournalLine: Record "Gen. Journal Line";
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgEntry: Record "Cust. Ledger Entry";
        DtldGSTLedgEnt: Record "Detailed GST Ledger Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        TransactionType: Enum "Detail Ledger Transaction Type";
        GSTGroupRemAmount: Decimal;
        InvoiceGSTAmount: Decimal;
        AppliedGSTAmount: Decimal;
        InvoiceAmount: Decimal;
        TotalTCSInclSHECess: Decimal;
    begin
        if AmountToApply = 0 then
            exit;
        if GenJournalLine."Offline Application" then begin
            if not CustLedgerEntry.Get(CVLedgerEntryBuffer."Entry No.") then
                exit;
            if not ApplyingCustLedgEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
                exit;
            if CustLedgerEntry."GST on Advance Payment" then begin
                TotalTCSInclSHECess := GSTApplicationLibrary.GetTotalTCSInclSHECessAmount(ApplyingCustLedgEntry."Transaction No.");
                GSTSalesApplicationMgt.GetSalesInvoiceAmountOffline(
                  CustLedgerEntry, ApplyingCustLedgEntry, TotalTCSInclSHECess); // ApplyingCustLedgEntry."Total TDS/TCS Incl SHE CESS"
                if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                    GSTGroupRemAmount :=
                      GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                        TransactionType::Sales, ApplyingCustLedgEntry."Document Type",
                        ApplyingCustLedgEntry."Document No.", ApplyingCustLedgEntry."Customer No.", CustLedgerEntry."GST Group Code",
                        AmountToApply, CVLedgerEntryBuffer."Remaining Amt. (LCY)", CustLedgerEntry."Entry No.", true,
                        InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount)
                else
                    GSTGroupRemAmount :=
                      GSTApplicationLibrary.GetApplicationRemainingAmount(
                        TransactionType::Sales, ApplyingCustLedgEntry."Document Type",
                        ApplyingCustLedgEntry."Document No.", ApplyingCustLedgEntry."Customer No.", CustLedgerEntry."GST Group Code",
                        AmountToApply, CVLedgerEntryBuffer."Remaining Amt. (LCY)", CustLedgerEntry."Entry No.", true,
                        InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount);
                AmountToApply := GSTGroupRemAmount;
                GSTApplicationLibrary.CheckGroupAmount(
                  ApplyingCustLedgEntry."Document Type",
                  ApplyingCustLedgEntry."Document No.", AmountToApply, GSTGroupRemAmount,
                  CustLedgerEntry."GST Group Code");
                PostSaleGSTApplicationGL(GenJournalLine, CustLedgerEntry."Document No.",
                  ApplyingCustLedgEntry."Document No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Entry No.",
                  CustLedgerEntry."GST Group Code", ApplyingCustLedgEntry."Transaction No.");
            end else
                if ApplyingCustLedgEntry."GST on Advance Payment" then begin
                    TotalTCSInclSHECess := GSTApplicationLibrary.GetTotalTCSInclSHECessAmount(CustLedgerEntry."Transaction No.");
                    GSTSalesApplicationMgt.GetSalesInvoiceAmountWithPaymentOffline(
                      CustLedgerEntry, ApplyingCustLedgEntry, TotalTCSInclSHECess); // CustLedgerEntry."Total TDS/TCS Incl SHE CESS"
                    if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                        GSTGroupRemAmount :=
                          GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                            TransactionType::Sales, CustLedgerEntry."Document Type",
                            CustLedgerEntry."Document No.", ApplyingCustLedgEntry."Customer No.", ApplyingCustLedgEntry."GST Group Code",
                            AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)", ApplyingCustLedgEntry."Entry No.", true,
                            InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount) // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)" 
                    else
                        GSTGroupRemAmount :=
                          GSTApplicationLibrary.GetApplicationRemainingAmount(
                            TransactionType::Sales, CustLedgerEntry."Document Type",
                            CustLedgerEntry."Document No.", ApplyingCustLedgEntry."Customer No.", ApplyingCustLedgEntry."GST Group Code",
                            AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)", ApplyingCustLedgEntry."Entry No.", true,
                            InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount); // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)" 
                    if Abs(AmountToApply) > Abs(GSTGroupRemAmount) then
                        AmountToApply := GSTGroupRemAmount;
                    GSTApplicationLibrary.CheckGroupAmount(
                      CustLedgerEntry."Document Type",
                      CustLedgerEntry."Document No.", AmountToApply, GSTGroupRemAmount * -1,
                      ApplyingCustLedgEntry."GST Group Code");
                    PostSaleGSTApplicationGL(GenJournalLine, ApplyingCustLedgEntry."Document No.", CustLedgerEntry."Document No.",
                      ApplyingCustLedgEntry."Transaction No.", ApplyingCustLedgEntry."Entry No.",
                      ApplyingCustLedgEntry."GST Group Code", CustLedgerEntry."Transaction No.");
                end;

            GSTApplSessionMgt.PostApplicationGenJournalLine(GenJnlPostLine);
        end else begin
            if not ApplyingCustLedgEntry.Get(OldCVLedgerEntryBuffer."Entry No.") then
                exit;
            GSTApplSessionMgt.GetOnlineCustLedgerEntry(OnlineCustLedgerEntry);
            if ApplyingCustLedgEntry."GST on Advance Payment" then begin
                GSTApplicationLibrary.ApplyCurrencyFactorInvoice(true);
                TotalTCSInclSHECess := GSTApplSessionMgt.GetTotalTCSInclSHECessAmount();
                GSTSalesApplicationMgt.GetSalesInvoiceAmountWithPaymentOffline(
                  OnlineCustLedgerEntry, ApplyingCustLedgEntry, TotalTCSInclSHECess); // OnlineCustLedgerEntry."Total TDS/TCS Incl SHE CESS"
                TotalTCSInclSHECess := GSTApplicationLibrary.GetTotalTCSInclSHECessAmount(OldCVLedgerEntryBuffer."Transaction No.");
                if OldCVLedgerEntryBuffer."Currency Code" <> '' then
                    GSTGroupRemAmount :=
                      GSTApplicationLibrary.GetApplicationRemainingAmountLCY(
                        TransactionType::Sales, OnlineCustLedgerEntry."Document Type",
                        OnlineCustLedgerEntry."Document No.", ApplyingCustLedgEntry."Customer No.", ApplyingCustLedgEntry."GST Group Code",
                        AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)" + TotalTCSInclSHECess,
                        ApplyingCustLedgEntry."Entry No.", true,
                        InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount) // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)"  // OldCVLedgerEntryBuffer."Total TDS Including SHECESS"
                else
                    GSTGroupRemAmount :=
                      GSTApplicationLibrary.GetApplicationRemainingAmount(
                        TransactionType::Sales, OnlineCustLedgerEntry."Document Type",
                        OnlineCustLedgerEntry."Document No.", ApplyingCustLedgEntry."Customer No.", ApplyingCustLedgEntry."GST Group Code",
                        AmountToApply, OldCVLedgerEntryBuffer."Amount (LCY)" + TotalTCSInclSHECess,
                        ApplyingCustLedgEntry."Entry No.", true,
                        InvoiceGSTAmount, AppliedGSTAmount, InvoiceAmount); // OldCVLedgerEntryBuffer."Remaining Amt. (LCY)"  // OldCVLedgerEntryBuffer."Total TDS Including SHECESS"
                GSTGroupRemAmount += GSTApplicationLibrary.GetPartialRoundingAmt(AmountToApply, GSTGroupRemAmount);
                if Abs(AmountToApply) > Abs(GSTGroupRemAmount) then
                    AmountToApply := GSTGroupRemAmount;
                GSTApplicationLibrary.CheckGroupAmount(
                  OnlineCustLedgerEntry."Document Type",
                  OnlineCustLedgerEntry."Document No.", AmountToApply, GSTGroupRemAmount * -1,
                  ApplyingCustLedgEntry."GST Group Code");
                PostSaleGSTApplicationGL(GenJournalLine, ApplyingCustLedgEntry."Document No.", OnlineCustLedgerEntry."Document No.",
                  ApplyingCustLedgEntry."Transaction No.", ApplyingCustLedgEntry."Entry No.",
                  ApplyingCustLedgEntry."GST Group Code", OnlineCustLedgerEntry."Transaction No.");
            end;
        end;
    end;

    local procedure PostSaleGSTApplicationGL(
        var GenJournalLine: Record "Gen. Journal Line";
        PaymentDocNo: Code[20];
        InvoiceNo: Code[20];
        TransactionNo: Integer;
        EntryNo: Integer;
        GSTGroupCode: Code[20];
        InvoiceTransactionNo: Integer)
    var
        ApplyGSTLedgerEntry: Record "GST Ledger Entry";
        ApplyDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTApplicationBuffer: Record "GST Application Buffer";
        SourceCodeSetup: Record "Source Code Setup";
        TransactionType: Enum "Detail Ledger Transaction Type";
        GSTGLAccountType: Enum "GST GL Account Type";
        AccountNo: Code[20];
        BalanceAccountNo: Code[20];
        AppliedBase: Decimal;
        AppliedAmount: Decimal;
        RemainingBase: Decimal;
        RemainingAmount: Decimal;
    begin
        SourceCodeSetup.Get();
        GSTApplicationBuffer.SetRange("Transaction Type", GSTApplicationBuffer."Transaction Type"::Sales);
        GSTApplicationBuffer.SetRange("Account No.", GenJournalLine."Account No.");
        GSTApplicationBuffer.SetRange("Original Document Type", GSTApplicationBuffer."Original Document Type"::Payment);
        GSTApplicationBuffer.SetRange("Original Document No.", PaymentDocNo);
        GSTApplicationBuffer.SetRange("Applied Doc. Type", GSTApplicationBuffer."Applied Doc. Type"::Invoice);
        GSTApplicationBuffer.SetRange("Applied Doc. No.", InvoiceNo);
        GSTApplicationBuffer.SetRange("GST Group Code", GSTGroupCode);
        if GSTApplicationBuffer.FindSet() then
            repeat
                DetailedGSTLedgerEntry.SetCurrentKey(
                  "Transaction Type", "Source No.", "CLE/VLE Entry No.", "Document Type", "Document No.", "GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                DetailedGSTLedgerEntry.SetRange("Source No.", GenJournalLine."Account No.");
                DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Invoice);
                DetailedGSTLedgerEntry.SetRange("Document No.", GSTApplicationBuffer."Applied Doc. No.");
                DetailedGSTLedgerEntry.SetRange("GST Group Code", GSTApplicationBuffer."GST Group Code");
                DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
                DetailedGSTLedgerEntry.SetRange("GST Component Code", GSTApplicationBuffer."GST Component Code");
                DetailedGSTLedgerEntry.SetRange("Remaining Amount Closed", false);
                DetailedGSTLedgerEntry.SetRange("GST Exempted Goods", false);
                if DetailedGSTLedgerEntry.FindFirst() then begin
                    RemainingBase := GSTApplicationBuffer."Applied Base Amount";
                    RemainingAmount := GSTApplicationBuffer."Applied Amount";
                    GSTPostingBuffer[1].DeleteAll();
                    GSTApplicationLibrary.CheckGSTAccountingPeriod(GenJournalLine."Posting Date");
                    repeat
                        if (RemainingBase <> 0) and (DetailedGSTLedgerEntry."Remaining Base Amount" < 0) then begin
                            GSTApplicationLibrary.GetAppliedAmount(Abs(RemainingBase), Abs(RemainingAmount),
                              Abs(DetailedGSTLedgerEntry."Remaining Base Amount"),
                              Abs(DetailedGSTLedgerEntry."Remaining GST Amount"), AppliedBase, AppliedAmount);
                            CreateDetailedGSTApplicationEntry(
                              ApplyDetailedGSTLedgerEntry, DetailedGSTLedgerEntry, GenJournalLine,
                              InvoiceNo, AppliedBase * -1, AppliedAmount * -1, GSTApplicationBuffer."Original Document No.");
                            ApplyDetailedGSTLedgerEntry.Paid := false;
                            ApplyDetailedGSTLedgerEntry."CLE/VLE Entry No." := EntryNo;
                            ApplyDetailedGSTLedgerEntry.Insert(true);
                            GSTApplicationLibrary.GetApplicationDocTypeFromGSTDocumentType(DetailedGSTLedgerEntry."Application Doc. Type", ApplyDetailedGSTLedgerEntry."Document Type");
                            DetailedGSTLedgerEntry."Application Doc. No" := ApplyDetailedGSTLedgerEntry."Document No.";
                            DetailedGSTLedgerEntry."Remaining Base Amount" += AppliedBase;
                            DetailedGSTLedgerEntry."Remaining GST Amount" += AppliedAmount;
                            DetailedGSTLedgerEntry."Remaining Amount Closed" := DetailedGSTLedgerEntry."Remaining Base Amount" = 0;
                            DetailedGSTLedgerEntry.Modify();
                            RemainingBase := Abs(RemainingBase) - Abs(AppliedBase);
                            RemainingAmount := Abs(RemainingAmount) - Abs(AppliedAmount);
                            FillGSTPostingBufferWithApplication(ApplyDetailedGSTLedgerEntry, false, false);
                        end;
                    until DetailedGSTLedgerEntry.Next() = 0;
                    AccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payable Account", ApplyDetailedGSTLedgerEntry."Location State Code", ApplyDetailedGSTLedgerEntry."GST Component Code");
                    BalanceAccountNo := GSTApplicationLibrary.GetGSTGLAccountNo(GSTGLAccountType::"Payables Account (Interim)", ApplyDetailedGSTLedgerEntry."Location State Code", ApplyDetailedGSTLedgerEntry."GST Component Code");
                    if GSTPostingBuffer[1].FindLast() then
                        repeat
                            CreateApplicationGSTLedger(
                              GSTPostingBuffer[1], ApplyDetailedGSTLedgerEntry,
                              GenJournalLine."Posting Date", SourceCodeSetup."Sales Entry Application", ApplyDetailedGSTLedgerEntry."Payment Type",
                              AccountNo, BalanceAccountNo, '', '');
                            PostSalesApplicationGLEntries(GenJournalLine, AccountNo, BalanceAccountNo, false, GSTPostingBuffer[1]."GST Amount");
                        until GSTPostingBuffer[1].Next(-1) = 0;
                end;
            until GSTApplicationBuffer.Next() = 0;
        GSTApplicationLibrary.DeletePaymentAplicationBuffer(TransactionType::Sales, EntryNo);
        GSTApplicationLibrary.DeleteInvoiceApplicationBufferOffline(
          TransactionType::Sales, GenJournalLine."Account No.", GSTApplicationBuffer."Original Document Type"::Invoice, InvoiceNo);
    end;

    local procedure PostSalesApplicationGLEntries(
        var GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
        UnApplication: Boolean;
        GSTAmount: Decimal)
    begin
        if GSTAmount = 0 then
            exit;
        if UnApplication then begin
            PostToGLEntry(GenJournalLine, AccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
            PostToGLEntry(GenJournalLine, BalAccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
        end else begin
            PostToGLEntry(GenJournalLine, AccountNo, Abs(GSTAmount), GenJournalLine."System-Created Entry");
            PostToGLEntry(GenJournalLine, BalAccountNo, -Abs(GSTAmount), GenJournalLine."System-Created Entry");
        end;
    end;

    local procedure CreateDetailedGSTApplicationEntry(
        var ApplyDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        AppliedBase: Decimal;
        AppliedAmount: Decimal;
        PaymentDoc: Code[20])
    begin
        ApplyDetailedGSTLedgerEntry.Init();
        ApplyDetailedGSTLedgerEntry.TransferFields(DetailedGSTLedgerEntry);
        ApplyDetailedGSTLedgerEntry."Entry No." := 0;
        ApplyDetailedGSTLedgerEntry."Entry Type" := ApplyDetailedGSTLedgerEntry."Entry Type"::Application;
        ApplyDetailedGSTLedgerEntry."Posting Date" := GenJournalLine."Posting Date";
        ApplyDetailedGSTLedgerEntry."Document Type" := ApplyDetailedGSTLedgerEntry."Document Type"::Invoice;
        ApplyDetailedGSTLedgerEntry."Document No." := InvoiceNo;
        ApplyDetailedGSTLedgerEntry."Original Doc. Type" := ApplyDetailedGSTLedgerEntry."Original Doc. Type"::Payment;
        ApplyDetailedGSTLedgerEntry."Original Doc. No." := PaymentDoc;
        GSTApplicationLibrary.GetApplicationDocTypeFromGenJournalDocumentType(ApplyDetailedGSTLedgerEntry."Application Doc. Type", GenJournalLine."Document Type");
        ApplyDetailedGSTLedgerEntry."Application Doc. No" := GenJournalLine."Document No.";
        ApplyDetailedGSTLedgerEntry."Payment Type" := ApplyDetailedGSTLedgerEntry."Payment Type"::Advance;
        ApplyDetailedGSTLedgerEntry."Transaction No." := TransactionNo;
        ApplyDetailedGSTLedgerEntry."Applied From Entry No." := DetailedGSTLedgerEntry."Entry No.";
        ApplyDetailedGSTLedgerEntry."GST Base Amount" := -AppliedBase;
        ApplyDetailedGSTLedgerEntry."GST Amount" := -AppliedAmount;
        ApplyDetailedGSTLedgerEntry."Remaining Base Amount" := 0;
        ApplyDetailedGSTLedgerEntry."Remaining GST Amount" := 0;
        ApplyDetailedGSTLedgerEntry.Positive := ApplyDetailedGSTLedgerEntry."GST Amount" > 0;
        ApplyDetailedGSTLedgerEntry."User ID" := UserId;
        ApplyDetailedGSTLedgerEntry."Amount Loaded on Item" := 0;
        if DetailedGSTLedgerEntry."GST Amount" <> 0 then
            ApplyDetailedGSTLedgerEntry.Quantity := Round(-DetailedGSTLedgerEntry.Quantity * Abs(ApplyDetailedGSTLedgerEntry."GST Amount" / DetailedGSTLedgerEntry."GST Amount"), 0.01)
        else
            ApplyDetailedGSTLedgerEntry.Quantity := -DetailedGSTLedgerEntry.Quantity;
    end;

    local procedure FillGSTPostingBufferWithApplication(
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ForexFluctuation: Boolean;
        HigherInvoiceExchangeRate: Boolean)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        Clear(GSTPostingBuffer[1]);
        if DetailedGSTLedgerEntry."Transaction Type" = DetailedGSTLedgerEntry."Transaction Type"::Purchase then
            GSTPostingBuffer[1]."Transaction Type" := GSTPostingBuffer[1]."Transaction Type"::Purchase
        else
            GSTPostingBuffer[1]."Transaction Type" := GSTPostingBuffer[1]."Transaction Type"::Sales;

        GSTPostingBuffer[1].Type := DetailedGSTLedgerEntry.Type;
        GSTPostingBuffer[1]."Gen. Bus. Posting Group" := DetailedGSTLedgerEntry."Gen. Bus. Posting Group";
        GSTPostingBuffer[1]."Gen. Prod. Posting Group" := DetailedGSTLedgerEntry."Gen. Prod. Posting Group";
        if DetailedGSTLedgerEntry."Transaction Type" = DetailedGSTLedgerEntry."Transaction Type"::Purchase then
            if DetailedGSTLedgerEntry."GST Group Type" = "GST Group Type"::Service then
                GSTPostingBuffer[1]."GST Group Type" := GSTPostingBuffer[1]."GST Group Type"::Service
            else
                GSTPostingBuffer[1]."GST Group Type" := GSTPostingBuffer[1]."GST Group Type"::Goods;
        GSTPostingBuffer[1]."GST Base Amount" := DetailedGSTLedgerEntry."GST Base Amount";
        GSTPostingBuffer[1]."GST Amount" := DetailedGSTLedgerEntry."GST Amount";
        if (GSTPostingBuffer[1]."GST Group Type" = GSTPostingBuffer[1]."GST Group Type"::Service) and
           (DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::"Non-Availment") and DetailedGSTLedgerEntry."RCM Exempt Transaction"
        then begin
            DetailedGSTLedgerEntry.TestField(Type, DetailedGSTLedgerEntry.Type::"G/L Account");
            GSTPostingBuffer[1]."Account No." := DetailedGSTLedgerEntry."No."
        end else
            GSTPostingBuffer[1]."Account No." := DetailedGSTLedgerEntry."G/L Account No.";
        GSTPostingBuffer[1]."GST %" := DetailedGSTLedgerEntry."GST %";
        GSTPostingBuffer[1]."GST Component Code" := DetailedGSTLedgerEntry."GST Component Code";
        GSTPostingBuffer[1]."GST Reverse Charge" := DetailedGSTLedgerEntry."Reverse Charge";
        if DetailedGSTLedgerEntry."GST Credit" = DetailedGSTLedgerEntry."GST Credit"::Availment then
            GSTPostingBuffer[1].Availment := true;
        GSTPostingBuffer[1]."Normal Payment" := DetailedGSTLedgerEntry."Payment Type" = "Payment Type"::Normal;
        GSTPostingBuffer[1]."Forex Fluctuation" := ForexFluctuation;
        GSTPostingBuffer[1]."Higher Inv. Exchange Rate" := HigherInvoiceExchangeRate;
        if GSTPostingBuffer[1]."Forex Fluctuation" then
            GSTPostingBuffer[1]."Document Line No." := DetailedGSTLedgerEntry."Document Line No.";
        if GSTPostingBuffer[1]."Forex Fluctuation" and not GSTPostingBuffer[1].Availment then
            if GSTPostingBuffer[1].Type = GSTPostingBuffer[1].Type::"Fixed Asset" then begin
                FADepreciationBook.Get(DetailedGSTLedgerEntry."No.", DetailedGSTLedgerEntry."Depreciation Book Code");
                FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
                FAPostingGroup.TestField("Acquisition Cost Account");
                GSTPostingBuffer[1]."Account No." := FAPostingGroup."Acquisition Cost Account";
                GSTPostingBuffer[1]."No." := DetailedGSTLedgerEntry."No.";
            end else
                if GSTPostingBuffer[1].Type = GSTPostingBuffer[1].Type::"G/L Account" then
                    GSTPostingBuffer[1]."Account No." := DetailedGSTLedgerEntry."No.";
        UpdateGSTPostingBufferWithApplication();
    end;

    local procedure UpdateGSTPostingBufferWithApplication()
    begin
        GSTPostingBuffer[2] := GSTPostingBuffer[1];
        if GSTPostingBuffer[2].Find() then begin
            GSTPostingBuffer[2]."GST Base Amount" += GSTPostingBuffer[1]."GST Base Amount";
            GSTPostingBuffer[2]."GST Amount" += GSTPostingBuffer[1]."GST Amount";
            GSTPostingBuffer[2].Modify();
        end else
            GSTPostingBuffer[1].Insert();
    end;

    local procedure CalculateAndFillGSTPostingBufferForexFluctuation(
        GSTApplicationBuffer: Record "GST Application Buffer";
        PaymentCurrencyFactor: Decimal;
        var HigherInvoiceExchangeRate: Boolean) AppliedBaseAmountInvoiceLCY: Decimal
    var
        GSTApplicationBuffer2: Record "GST Application Buffer";
    begin
        if PaymentCurrencyFactor = 0 then begin
            GSTApplicationBuffer2.SetRange("Transaction Type", GSTApplicationBuffer2."Transaction Type"::Purchase);
            GSTApplicationBuffer2.SetRange("Account No.", GSTApplicationBuffer."Account No.");
            GSTApplicationBuffer2.SetRange("Original Document Type", GSTApplicationBuffer."Applied Doc. Type");
            GSTApplicationBuffer2.SetRange("Original Document No.", GSTApplicationBuffer."Applied Doc. No.");
            GSTApplicationBuffer2.SetRange("Applied Doc. Type", GSTApplicationBuffer2."Applied Doc. Type"::Payment);
            GSTApplicationBuffer2.SetRange("Applied Doc. No.", GSTApplicationBuffer."Original Document No.");
            GSTApplicationBuffer2.SetRange("GST Group Code", GSTApplicationBuffer."GST Group Code");
            GSTApplicationBuffer2.SetRange("GST Component Code", GSTApplicationBuffer."GST Component Code");
            if GSTApplicationBuffer2.FindFirst() then
                if GSTApplicationBuffer2."Currency Factor" <> GSTApplicationBuffer."Currency Factor" then
                    if GSTApplicationBuffer2."Currency Factor" < GSTApplicationBuffer."Currency Factor" then
                        AppliedBaseAmountInvoiceLCY :=
                          Round(GSTApplicationBuffer."Applied Base Amount" * GSTApplicationBuffer."Currency Factor" / GSTApplicationBuffer2."Currency Factor")
                    else
                        if GSTApplicationBuffer2."Currency Factor" > GSTApplicationBuffer."Currency Factor" then
                            AppliedBaseAmountInvoiceLCY :=
                              Round(GSTApplicationBuffer."Applied Base Amount" * GSTApplicationBuffer2."Currency Factor" / GSTApplicationBuffer."Currency Factor");
            HigherInvoiceExchangeRate := GSTApplicationBuffer2."Currency Factor" < GSTApplicationBuffer."Currency Factor";
        end else begin
            if (GSTApplicationBuffer."Currency Factor" <> PaymentCurrencyFactor) and
               (GSTApplicationBuffer."Currency Code" <> '')
            then
                if GSTApplicationBuffer."Currency Factor" < PaymentCurrencyFactor then
                    AppliedBaseAmountInvoiceLCY :=
                      Round(Abs(GSTApplicationBuffer."Applied Base Amount") * PaymentCurrencyFactor / GSTApplicationBuffer."Currency Factor")
                else
                    if GSTApplicationBuffer."Currency Factor" > PaymentCurrencyFactor then
                        AppliedBaseAmountInvoiceLCY :=
                          Round(GSTApplicationBuffer."Applied Base Amount" * GSTApplicationBuffer."Currency Factor" / PaymentCurrencyFactor);
            HigherInvoiceExchangeRate := GSTApplicationBuffer."Currency Factor" < PaymentCurrencyFactor;
        end;
    end;

    local procedure CreateApplicationGSTLedger(
        GSTPostingBuffer: Record "GST Posting Buffer";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        PostingDate: Date;
        SourceCode: Code[10];
        PaymentType: Enum "Payment Type";
        AccountNo: Code[20];
        BalanceAccountNo: Code[20];
        BalanceAccountNo2: Code[20];
        AccountNo2: Code[20])
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
    begin
        GSTLedgerEntry.Init();
        GSTLedgerEntry."Entry No." := 0;
        GSTLedgerEntry."Entry Type" := "Entry Type"::Application;
        GSTLedgerEntry."Gen. Bus. Posting Group" := GSTPostingBuffer."Gen. Bus. Posting Group";
        GSTLedgerEntry."Gen. Prod. Posting Group" := GSTPostingBuffer."Gen. Prod. Posting Group";
        GSTLedgerEntry."Posting Date" := PostingDate;
        GSTLedgerEntry."Document No." := DetailedGSTLedgerEntry."Document No.";
        GSTApplicationLibrary.GetDetailedGSTDocumentTypeFromGSTDocumentType(GSTLedgerEntry."Document Type", DetailedGSTLedgerEntry."Document Type");
        GSTLedgerEntry."Currency Code" := DetailedGSTLedgerEntry."Currency Code";
        GSTLedgerEntry."Currency Factor" := DetailedGSTLedgerEntry."Currency Factor";
        GSTApplicationLibrary.GetGSTLedgerTransactionTypeFromDetailLedgerTransactioType(GSTLedgerEntry."Transaction Type", DetailedGSTLedgerEntry."Transaction Type");
        GSTLedgerEntry."GST Base Amount" := GSTPostingBuffer."GST Base Amount";
        GSTLedgerEntry."GST Amount" := GSTPostingBuffer."GST Amount";
        case DetailedGSTLedgerEntry."Source Type" of
            DetailedGSTLedgerEntry."Source Type"::Vendor:
                GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::Vendor;
            DetailedGSTLedgerEntry."Source Type"::Customer:
                GSTLedgerEntry."Source Type" := GSTLedgerEntry."Source Type"::Customer;
        end;
        GSTLedgerEntry."Source No." := DetailedGSTLedgerEntry."Source No.";
        GSTLedgerEntry."Source Code" := SourceCode;
        GSTLedgerEntry."Payment Type" := PaymentType;
        GSTLedgerEntry."Reason Code" := DetailedGSTLedgerEntry."Reason Code";
        GSTLedgerEntry."Transaction No." := DetailedGSTLedgerEntry."Transaction No.";
        GSTLedgerEntry."Input Service Distribution" := DetailedGSTLedgerEntry."Input Service Distribution";
        GSTLedgerEntry."External Document No." := DetailedGSTLedgerEntry."External Document No.";
        GSTApplicationLibrary.GetPurchGroupTypeFromGSTGroupType(GSTLedgerEntry."Purchase Group Type", GSTPostingBuffer."GST Group Type");
        GSTLedgerEntry."GST Component Code" := GSTPostingBuffer."GST Component Code";
        GSTLedgerEntry."Reverse Charge" := GSTPostingBuffer."GST Reverse Charge";
        GSTLedgerEntry.Availment := GSTPostingBuffer.Availment;
        GSTLedgerEntry."User ID" := UserId;
        GSTLedgerEntry."Account No." := AccountNo;
        GSTLedgerEntry."Bal. Account No." := BalanceAccountNo;
        GSTLedgerEntry."Bal. Account No. 2" := BalanceAccountNo2;
        GSTLedgerEntry."Account No. 2" := AccountNo2;
        GSTLedgerEntry.Insert(true);
    end;

    local procedure PostToGLEntry(
        var GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        Amount: Decimal;
        SystemCreatedEntry: Boolean)
    begin
        GSTApplSessionMgt.CreateApplicationGenJournallLine(GenJournalLine, GLAccountNo, Amount, true);
    end;

    local procedure ApplyGSTApplicationCreditMemo(
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        TransactionType: Enum "Detail Ledger Transaction Type";
        Offline: Boolean)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CreditMemoNo: Code[20];
    begin
        if (CVLedgerEntryBuffer."Document Type" <> CVLedgerEntryBuffer."Document Type"::"Credit Memo") and
          (OldCVLedgerEntryBuffer."Document Type" <> OldCVLedgerEntryBuffer."Document Type"::"Credit Memo") then
            exit;
        if (CVLedgerEntryBuffer."Document Type" <> CVLedgerEntryBuffer."Document Type"::Invoice) and
          (OldCVLedgerEntryBuffer."Document Type" <> OldCVLedgerEntryBuffer."Document Type"::Invoice) then
            exit;

        if CVLedgerEntryBuffer."Document Type" = CVLedgerEntryBuffer."Document Type"::"Credit Memo" then
            CreditMemoNo := CVLedgerEntryBuffer."Document No."
        else
            CreditMemoNo := OldCVLedgerEntryBuffer."Document No.";
        DetailedGSTLedgerEntry.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Document Line No.");
        DetailedGSTLedgerEntry.SetRange("Transaction Type", TransactionType);
        DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::"Credit Memo");
        DetailedGSTLedgerEntry.SetRange("Document No.", CreditMemoNo);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange(UnApplied, false);
    end;

    local procedure GSTUnapplicationRestrictionPurch(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ApplicationEntryNo: Integer;
        DocTypeTxt: Text;
        GSTDocType: Enum "GST Document Type";
    begin
        DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
        DtldVendLedgEntry2.SetRange(Unapplied, false);
        if DtldVendLedgEntry2.FindSet() then
            repeat
                if DtldVendLedgEntry2."Entry No." > ApplicationEntryNo then
                    ApplicationEntryNo := DtldVendLedgEntry2."Entry No.";
            until DtldVendLedgEntry2.Next() = 0;

        if VendorLedgerEntry."GST Reverse Charge" then
            case VendorLedgerEntry."Document Type" of
                VendorLedgerEntry."Document Type"::Invoice:
                    begin
                        DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Invoice);
                        DetailedGSTLedgerEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
                        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::Application);
                        DetailedGSTLedgerEntry.SetRange("GST Group Type", DetailedGSTLedgerEntry."GST Group Type"::Service);
                        DetailedGSTLedgerEntry.SetRange("Credit Availed", true);
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type", DetailedGSTLedgerEntry."Credit Adjustment Type"::"Credit Reversal");
                        if not DetailedGSTLedgerEntry.IsEmpty then
                            Error(UnApplicationErr);
                        DetailedGSTLedgerEntry.SetRange("Credit Availed");
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type");
                        DetailedGSTLedgerEntry.SetRange("Credit Availed", false);
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type", DetailedGSTLedgerEntry."Credit Adjustment Type"::"Credit Availment");
                        if not DetailedGSTLedgerEntry.IsEmpty then
                            Error(UnApplicationErr);
                    end;
                VendorLedgerEntry."Document Type"::Payment:
                    begin
                        if not DetailedVendorLedgEntry.Get(ApplicationEntryNo) then
                            exit;
                        DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Invoice);
                        DetailedGSTLedgerEntry.SetRange("Document No.", DetailedVendorLedgEntry."Document No.");
                        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::Application);
                        DetailedGSTLedgerEntry.SetRange("GST Group Type", DetailedGSTLedgerEntry."GST Group Type"::Service);
                        DetailedGSTLedgerEntry.SetRange("Credit Availed", true);
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type", DetailedGSTLedgerEntry."Credit Adjustment Type"::"Credit Reversal");
                        if not DetailedGSTLedgerEntry.IsEmpty then
                            Error(UnApplicationErr);
                        DetailedGSTLedgerEntry.SetRange("Credit Availed");
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type");
                        DetailedGSTLedgerEntry.SetRange("Credit Availed", false);
                        DetailedGSTLedgerEntry.SetRange("Credit Adjustment Type", DetailedGSTLedgerEntry."Credit Adjustment Type"::"Credit Availment");
                        if not DetailedGSTLedgerEntry.IsEmpty then
                            Error(UnApplicationErr);
                    end;
            end;

        DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange("Source No.", VendorLedgerEntry."Vendor No.");
        DocTypeTxt := Format(VendorLedgerEntry."Document Type");
        Evaluate(GSTDocType, DocTypeTxt);
        DetailedGSTLedgerEntry.SetRange("Document Type", GSTDocType);
        DetailedGSTLedgerEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        if DetailedGSTLedgerEntry.FindFirst() then
            if (DetailedGSTLedgerEntry."Cr. & Libty. Adjustment Type" = DetailedGSTLedgerEntry."Cr. & Libty. Adjustment Type"::Generate) and
               ((DetailedGSTLedgerEntry."GST Base Amount" - DetailedGSTLedgerEntry."AdjustmentBase Amount") < DtldVendLedgEntry2."Amount (LCY)") then
                Error(GSTInvoiceLiabilityErr);
    end;

    local procedure UnApplyGSTApplication(
        GenJournalLine: Record "Gen. Journal Line";
        TransactionType: Enum "Detail Ledger Transaction Type";
        TransactionNo: Integer;
        DocumentNo: Code[20])
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Refund then
            exit;
        DetailedGSTLedgerEntry.SetCurrentKey("Transaction No.");
        DetailedGSTLedgerEntry.SetRange("Transaction No.", TransactionNo);
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Transaction Type", TransactionType);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::Application);
        DetailedGSTLedgerEntry.SetRange(UnApplied, false);
        if DetailedGSTLedgerEntry.FindSet() then begin
            CreateUnapplicationGSTLedger(GenJournalLine, TransactionType, TransactionNo, DocumentNo, DetailedGSTLedgerEntry."RCM Exempt Transaction");
            GSTPostingBuffer[1].DeleteAll();
            repeat
                InsertUnApplicationDetailedGSTLedgerEntry(DetailedGSTLedgerEntry);
            until DetailedGSTLedgerEntry.Next() = 0;
        end;
    end;

    local procedure InsertUnApplicationDetailedGSTLedgerEntry(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry")
    var
        DetailedGSTLedgerEntryNew: Record "Detailed GST Ledger Entry";
        DetailedGSTLedgerEntryOld: Record "Detailed GST Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        DetailedGSTLedgerEntryNew.Init();
        DetailedGSTLedgerEntryNew.TransferFields(DetailedGSTLedgerEntry);
        DetailedGSTLedgerEntryNew."Entry No." := 0;
        DetailedGSTLedgerEntryNew."Document No." := DetailedGSTLedgerEntryNew."Document No.";
        DetailedGSTLedgerEntryNew."Transaction No." := TransactionNo;
        DetailedGSTLedgerEntryNew."Entry Type" := DetailedGSTLedgerEntryNew."Entry Type"::Application;
        DetailedGSTLedgerEntryNew."GST Base Amount" := -DetailedGSTLedgerEntry."GST Base Amount";
        DetailedGSTLedgerEntryNew."GST Amount" := -DetailedGSTLedgerEntry."GST Amount";
        DetailedGSTLedgerEntryNew.Quantity := -DetailedGSTLedgerEntry.Quantity;
        DetailedGSTLedgerEntryNew."Applied From Entry No." := DetailedGSTLedgerEntry."Entry No.";
        DetailedGSTLedgerEntryNew.UnApplied := true;
        DetailedGSTLedgerEntryNew."User ID" := UserId;
        DetailedGSTLedgerEntryNew.Positive := DetailedGSTLedgerEntryNew."GST Amount" > 0;
        DetailedGSTLedgerEntryNew.Paid := false;
        DetailedGSTLedgerEntryNew."Amount Loaded on Item" := -DetailedGSTLedgerEntry."Amount Loaded on Item";
        DetailedGSTLedgerEntryNew.Insert(true);
        DetailedGSTLedgerEntryOld.Get(DetailedGSTLedgerEntry."Entry No.");
        DetailedGSTLedgerEntryOld.UnApplied := true;
        DetailedGSTLedgerEntryOld.Modify(true);
        if not DetailedGSTLedgerEntryNew."Forex Fluctuation" then begin
            DetailedGSTLedgerEntryOld.Get(DetailedGSTLedgerEntry."Applied From Entry No.");
            DetailedGSTLedgerEntryOld."Remaining Base Amount" += DetailedGSTLedgerEntryNew."GST Base Amount";
            DetailedGSTLedgerEntryOld."Remaining GST Amount" += DetailedGSTLedgerEntryNew."GST Amount";
            DetailedGSTLedgerEntryOld."Remaining Amount Closed" := false;
            DetailedGSTLedgerEntryOld.Modify();
        end else begin
            VendorLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntryNew."Original Doc. Type");
            VendorLedgerEntry.SetRange("Document No.", DetailedGSTLedgerEntryNew."Original Doc. No.");
            VendorLedgerEntry.SetRange("Vendor No.", DetailedGSTLedgerEntryNew."Source No.");
            if VendorLedgerEntry.FindFirst() then
                if VendorLedgerEntry."Original Currency Factor" > DetailedGSTLedgerEntryNew."Currency Factor" then begin
                    DetailedGSTLedgerEntryOld.Get(DetailedGSTLedgerEntry."Applied From Entry No.");
                    DetailedGSTLedgerEntryOld."Remaining Base Amount" += DetailedGSTLedgerEntryNew."GST Base Amount";
                    DetailedGSTLedgerEntryOld."Remaining GST Amount" += DetailedGSTLedgerEntryNew."GST Amount";
                    DetailedGSTLedgerEntryOld."Remaining Amount Closed" := false;
                    DetailedGSTLedgerEntryOld.Modify();
                end;
        end;
        UnapplyFluctuationRevaluationEntry(DetailedGSTLedgerEntryNew);
    end;

    local procedure CreateUnapplicationGSTLedger(
        GenJournalLine: Record "Gen. Journal Line";
        TransactionType: Enum "Detail Ledger Transaction Type";
        TransactionNo: Integer;
        DocumentNo: Code[20];
        RCMExempt: Boolean)
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
        GSTLedgerTransactionType: Enum "GST Ledger Transaction Type";
    begin
        GSTApplicationLibrary.GetGSTLedgerTransactionTypeFromDetailLedgerTransactioType(GSTLedgerTransactionType, TransactionType);
        GSTLedgerEntry.SetCurrentKey("Transaction No.");
        GSTLedgerEntry.SetRange("Transaction No.", TransactionNo);
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);
        GSTLedgerEntry.SetRange("Transaction Type", GSTLedgerTransactionType);
        GSTLedgerEntry.SetRange("Entry Type", "Entry Type"::Application);
        GSTLedgerEntry.SetRange(UnApplied, false);
        if GSTLedgerEntry.FindSet() then
            repeat
                InsertUnApplicationGSTLedgerEntry(GSTLedgerEntry, TransactionNo, GenJournalLine."Source Code");
                if GSTLedgerEntry."Transaction Type" = GSTLedgerEntry."Transaction Type"::Sales then
                    PostSalesApplicationGLEntries(GenJournalLine, GSTLedgerEntry."Account No.", GSTLedgerEntry."Bal. Account No.", true, GSTLedgerEntry."GST Amount")
                else
                    if GSTLedgerEntry."Payment Type" = GSTLedgerEntry."Payment Type"::Normal then
                        PostNormalPaymentApplicationGLEntries(
                          GenJournalLine, true, GSTLedgerEntry."Account No.", GSTLedgerEntry."Account No. 2", GSTLedgerEntry."Bal. Account No.",
                          GSTLedgerEntry."Bal. Account No. 2", GSTLedgerEntry."GST Amount")
                    else
                        PostPurchaseApplicationGLEntries(GenJournalLine, true, GSTLedgerEntry."Account No.", GSTLedgerEntry."Bal. Account No.",
                        GSTLedgerEntry."Bal. Account No. 2", GSTLedgerEntry."GST Amount", RCMExempt);
            until GSTLedgerEntry.Next() = 0;
    end;

    local procedure InsertUnApplicationGSTLedgerEntry(GSTLedgerEntry: Record "GST Ledger Entry"; TransactionNo: Integer; SourceCode: Code[20])
    var
        GSTLedgerEntryNew: Record "GST Ledger Entry";
        GSTLedgerEntryOld: Record "GST Ledger Entry";
    begin
        GSTLedgerEntryNew.Init();
        GSTLedgerEntryNew.TransferFields(GSTLedgerEntry);
        GSTLedgerEntryNew."Entry No." := 0;
        GSTLedgerEntryNew."Document Type" := GSTLedgerEntryNew."Document Type"::Invoice;
        GSTLedgerEntryNew."Document No." := GSTLedgerEntry."Document No.";
        GSTLedgerEntryNew."Transaction No." := TransactionNo;
        GSTLedgerEntryNew."Source Code" := SourceCode;
        GSTLedgerEntryNew."GST Base Amount" := -GSTLedgerEntry."GST Base Amount";
        GSTLedgerEntryNew."GST Amount" := -GSTLedgerEntry."GST Amount";
        GSTLedgerEntryNew."User ID" := UserId;
        GSTLedgerEntryNew.UnApplied := true;
        GSTLedgerEntryNew.Insert(true);
        GSTLedgerEntryOld.Get(GSTLedgerEntry."Entry No.");
        GSTLedgerEntryOld.UnApplied := true;
        GSTLedgerEntryOld.Modify(true);
    end;

    local procedure UnapplyFluctuationRevaluationEntry(DetailedGSTLedgerEntry4: Record "Detailed GST Ledger Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        EntryNo: Integer;
    begin
        if DetailedGSTLedgerEntry4."Forex Fluctuation" and
           (DetailedGSTLedgerEntry4."GST Credit" = DetailedGSTLedgerEntry4."GST Credit"::"Non-Availment")
        then
            if DetailedGSTLedgerEntry4.Type = DetailedGSTLedgerEntry4.Type::Item then begin
                ValueEntry.Reset();
                ValueEntry.SetRange("Document No.", DetailedGSTLedgerEntry4."Document No.");
                ValueEntry.SetRange("Document Line No.", DetailedGSTLedgerEntry4."Document Line No.");
                if ValueEntry.FindFirst() then begin
                    if not ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                        exit;
                    if DetailedGSTLedgerEntry4."GST Amount" <> 0 then begin
                        ItemJournalLine.Init();
                        ItemJournalLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
                        ItemJournalLine."Document Date" := ItemLedgerEntry."Posting Date";
                        ItemJournalLine.Validate("Document No.", ValueEntry."Document No.");
                        ItemJournalLine."Document Line No." := ItemLedgerEntry."Document Line No.";
                        ItemJournalLine."External Document No." := ItemLedgerEntry."External Document No.";
                        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Purchase);
                        ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::Revaluation;
                        ItemJournalLine.Validate("Item No.", ItemLedgerEntry."Item No.");
                        ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Vendor;
                        ItemJournalLine."Source No." := ItemLedgerEntry."Source No.";
                        ItemJournalLine."Gen. Bus. Posting Group" := DetailedGSTLedgerEntry4."Gen. Bus. Posting Group";
                        ItemJournalLine."Gen. Prod. Posting Group" := DetailedGSTLedgerEntry4."Gen. Prod. Posting Group";
                        SourceCodeSetup.Get();
                        ItemJournalLine."Source Code" := SourceCodeSetup."Revaluation Journal";
                        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
                        if DetailedGSTLedgerEntry4."Fluctuation Amt. Credit" then
                            ItemJournalLine.Validate(
                              "Unit Cost (Revalued)",
                              ItemJournalLine."Unit Cost (Revalued)" + DetailedGSTLedgerEntry4."GST Amount" / ItemLedgerEntry.Quantity)
                        else
                            ItemJournalLine.Validate(
                              "Unit Cost (Revalued)",
                              ItemJournalLine."Unit Cost (Revalued)" - DetailedGSTLedgerEntry4."GST Amount" / ItemLedgerEntry.Quantity);
                        ItemJournalLine2.Init();
                        ItemJournalLine2.TransferFields(ItemJournalLine);
                        ItemJnlPostLine.Run(ItemJournalLine2);
                    end;
                end;
            end else
                if DetailedGSTLedgerEntry4.Type = DetailedGSTLedgerEntry4.Type::"Fixed Asset" then begin
                    FALedgerEntry.FindLast();
                    EntryNo := FALedgerEntry."Entry No." + 1;
                    FALedgerEntry.Reset();
                    FALedgerEntry.SetRange("Document No.", DetailedGSTLedgerEntry4."Document No.");
                    FALedgerEntry.SetRange("FA No.", DetailedGSTLedgerEntry4."No.");
                    if FALedgerEntry.FindFirst() then begin
                        FALedgerEntry2.Copy(FALedgerEntry);
                        FALedgerEntry2."Entry No." := EntryNo;
                        if DetailedGSTLedgerEntry4."Fluctuation Amt. Credit" then begin
                            FALedgerEntry2.Amount := DetailedGSTLedgerEntry4."GST Amount";
                            FALedgerEntry2."Amount (LCY)" := DetailedGSTLedgerEntry4."GST Amount";
                            FALedgerEntry2."Debit Amount" := DetailedGSTLedgerEntry4."GST Amount";
                        end else begin
                            FALedgerEntry2.Amount := Abs(DetailedGSTLedgerEntry4."GST Amount");
                            FALedgerEntry2."Amount (LCY)" := Abs(DetailedGSTLedgerEntry4."GST Amount");
                            FALedgerEntry2."Debit Amount" := Abs(DetailedGSTLedgerEntry4."GST Amount");
                        end;
                        FALedgerEntry2.Insert(true);
                    end;
                end;
    end;

    local procedure UnApplyGSTApplicationCreditMemo(TransactionType: Enum "Detail Ledger Transaction Type"; DocumentNo: Code[20])
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Document Line No.");
        DetailedGSTLedgerEntry.SetRange("Transaction Type", TransactionType);
        DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::"Credit Memo");
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange(UnApplied, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforeApplyVendLedgEntry(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        var GenJnlLine: Record "Gen. Journal Line";
        Vend: Record Vendor;
        var IsAmountToApplyCheckHandled: Boolean)
    begin
        SetGSTApplicationSourcePurch(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Vend, IsAmountToApplyCheckHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforeApplyCustLedgEntry(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        var GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        var IsAmountToApplyCheckHandled: Boolean)
    begin
        SetGSTApplicationSourceSales(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Cust, IsAmountToApplyCheckHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterFindAmtForAppln', '', false, false)]
    local procedure OnAfterFindAmtForAppln(
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        var AppliedAmount: Decimal;
        var AppliedAmountLCY: Decimal;
        var OldAppliedAmount: Decimal)
    begin
        SetGSTApplicationAmount(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount, AppliedAmountLCY, OldAppliedAmount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CV Ledger Entry Buffer", 'OnAfterCopyFromCustLedgerEntry', '', false, false)]
    local procedure OnAfterCopyCVLedgEntryBufFromCustLedgerEntry(
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        SetOnlineCustLedgerEntry(CustLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CV Ledger Entry Buffer", 'OnAfterCopyFromVendLedgerEntry', '', false, false)]
    local procedure OnAfterCopyCVLedgEntryBufFFromVendLedgerEntry(
        var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        SetOnlineVendLedgerEntry(VendorLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnBeforePostApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(
        var GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GenJournalLine."Offline Application" := true;
        GenJournalLine."Currency Code" := VendorLedgerEntry."Currency Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(
        var GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        GenJournalLine."Offline Application" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateAmountOnAfterAssignAmountLCY', '', false, false)]
    local procedure GenJnlLineOnValidateAmountOnAfterAssignAmountLCY(var sender: Record "Gen. Journal Line"; var AmountLCY: Decimal)
    begin
        if (sender."Journal Template Name" = '') and (sender."Journal Batch Name" = '') then
            sender.SetSuppressCommit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostApply', '', false, false)]
    local procedure OnAfterPostApply(
        GenJnlLine: Record "Gen. Journal Line";
        var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        AppliedForeignCurrAmt: Decimal;
        VendNo: Code[20];
        CustNo: Code[20];
        AppliedAmt: Decimal;
        AppliedAmtLCY: Decimal;
    begin
        GSTApplSessionMgt.GetGSTTransactionType(GSTTransactionType);
        case GSTTransactionType of
            GSTTransactionType::Purchase:
                begin
                    GSTApplSessionMgt.GetGSTApplicationSourcePurch(TransactionNo, GSTTransactionType, VendNo);
                    GSTApplSessionMgt.GetGSTApplicationAmount(AppliedAmt, AppliedAmtLCY);
                    if Vendor.Get(VendNo) then begin
                        if GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::Payment] then
                            if OldCVLedgEntryBuf."Currency Code" <> '' then begin
                                if NewCVLedgEntryBuf."Original Currency Factor" > OldCVLedgEntryBuf."Original Currency Factor" then begin
                                    AppliedForeignCurrAmt := Round(AppliedAmt / NewCVLedgEntryBuf."Adjusted Currency Factor");
                                    PostGSTPurchaseApplication(GenJnlLine, NewCVLedgEntryBuf, OldCVLedgEntryBuf, AppliedForeignCurrAmt);
                                end else
                                    PostGSTPurchaseApplication(GenJnlLine, NewCVLedgEntryBuf, OldCVLedgEntryBuf, AppliedAmtLCY);
                            end else
                                PostGSTPurchaseApplication(GenJnlLine, NewCVLedgEntryBuf, OldCVLedgEntryBuf, AppliedAmtLCY);
                        ApplyGSTApplicationCreditMemo(
                          NewCVLedgEntryBuf,
                          OldCVLedgEntryBuf,
                          GSTTransactionType::Purchase,
                          GenJnlLine."Offline Application");
                    end;
                end;
            GSTTransactionType::Sales:
                begin
                    GSTApplSessionMgt.GetGSTApplicationSourceSales(TransactionNo, GSTTransactionType, CustNo);
                    GSTApplSessionMgt.GetGSTApplicationAmount(AppliedAmt, AppliedAmtLCY);
                    if Customer.Get(CustNo) then begin
                        if GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::Payment] then
                            PostGSTSalesApplication(GenJnlLine, NewCVLedgEntryBuf, OldCVLedgEntryBuf, AppliedAmtLCY);
                        ApplyGSTApplicationCreditMemo(
                          NewCVLedgEntryBuf,
                          OldCVLedgEntryBuf,
                          GSTTransactionType::Sales,
                          GenJnlLine."Offline Application");
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithCheck', '', false, false)]
    local procedure OnGenJnlPostLineOnAfterRunWithCheck(sender: Codeunit "Gen. Jnl.-Post Line")
    begin
        GSTApplSessionMgt.PostApplicationGenJournalLine(sender);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterRunWithoutCheck', '', false, false)]
    local procedure OnGenJnlPostLineOnAfterRunWithOutCheck(sender: Codeunit "Gen. Jnl.-Post Line")
    begin
        GSTApplSessionMgt.PostApplicationGenJournalLine(sender);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnBeforePostUnapplyVendLedgEntry', '', false, false)]
    local procedure OnBeforePostUnapplyVendLedgEntry(
        var GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        GSTUnapplicationRestrictionPurch(VendorLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldVendLedgEntryUnapply', '', false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntryUnapply(
        var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        TransactionType: Enum "Detail Ledger Transaction Type";
    begin
        if OldDtldVendLedgEntry."Initial Document Type" = OldDtldVendLedgEntry."Initial Document Type"::"Credit Memo" then
            if VendorLedgerEntry2.Get(OldDtldVendLedgEntry."Vendor Ledger Entry No.") then
                UnApplyGSTApplicationCreditMemo(TransactionType::Purchase, VendorLedgerEntry2."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendor', '', false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendor(
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        var VendorPostingGroup: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        TransactionType: Enum "Detail Ledger Transaction Type";
    begin
        UnApplyGSTApplication(GenJournalLine, TransactionType::Purchase, DetailedVendorLedgEntry."Transaction No.", DetailedVendorLedgEntry."Document No.");
        GSTApplSessionMgt.PostApplicationGenJournalLine(GenJnlPostLine);
        GSTApplSessionMgt.ClearAllSessionVariables();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryUnapply(
        var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        TransactionType: Enum "Detail Ledger Transaction Type";
    begin
        if OldDtldCustLedgEntry."Initial Document Type" = OldDtldCustLedgEntry."Initial Document Type"::"Credit Memo" then
            if CustLedgerEntry2.Get(OldDtldCustLedgEntry."Cust. Ledger Entry No.") then
                UnApplyGSTApplicationCreditMemo(TransactionType::Sales, CustLedgerEntry2."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeCreateGLEntriesForTotalAmountsUnapply', '', false, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapply(
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        var CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        TransactionType: Enum "Detail Ledger Transaction Type";
    begin
        UnApplyGSTApplication(GenJournalLine, TransactionType::Sales, DetailedCustLedgEntry."Transaction No.", DetailedCustLedgEntry."Document No.");
        GSTApplSessionMgt.PostApplicationGenJournalLine(GenJnlPostLine);
        GSTApplSessionMgt.ClearAllSessionVariables();
    end;
}