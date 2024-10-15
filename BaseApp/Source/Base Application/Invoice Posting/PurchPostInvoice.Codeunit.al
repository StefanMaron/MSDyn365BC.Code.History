﻿codeunit 816 "Purch. Post Invoice" implements "Invoice Posting"
{
    Permissions = TableData "Invoice Posting Buffer" = imd;

    var
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TempInvoicePostingBufferReverseCharge: Record "Invoice Posting Buffer" temporary;
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        JobPostLine: Codeunit "Job Post-Line";
        RemSalesTaxAmt: Decimal;
        RemSalesTaxAmtACY: Decimal;
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        GenProdPostingGrDiscErr: Label 'You must enter a value in %1 for %2 %3 if you want to post discounts for that line.', Comment = '%1 = Gen. Prod. Posting Group, %2 - Line No. field name, %3 - line number';
        IncorrectInterfaceErr: Label 'This implementation designed to post Purchase Header table only.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Purchase Header" then
            error(IncorrectInterfaceErr);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)
    begin
        HideProgressWindow := NewHideProgressWindow;
    end;

    procedure SetParameters(NewInvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        InvoicePostingParameters := NewInvoicePostingParameters;
    end;

    procedure SetTotalLines(TotalDocumentLine: Variant; TotalDocumentLineLCY: Variant)
    begin
        TotalPurchLine := TotalDocumentLine;
        TotalPurchLineLCY := TotalDocumentLineLCY;
    end;

    procedure ClearBuffers()
    begin
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        TempInvoicePostingBuffer.DeleteAll();
        TempInvoicePostingBufferReverseCharge.DeleteAll();
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        AdjAmount: Decimal;
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        DeferralAccount: Code[20];
        PurchAccount: Code[20];
        InvDiscAccount: code[20];
        LineDiscAccount: code[20];
        IsHandled: Boolean;
        InvoiceDiscountPosting: Boolean;
        LineDiscountPosting: Boolean;
    begin
        PurchHeader := DocumentHeaderVar;
        PurchLine := DocumentLineVar;
        PurchLineACY := DocumentLineACYVar;

        IsHandled := false;
        OnBeforePrepareLine(PurchHeader, PurchLine, PurchLineACY, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        PurchSetup.Get();
        GetGenPostingSetup(GenPostingSetup, PurchLine);

        OnPrepareLineOnBeforePreparePurchase(PurchHeader, PurchLine);
        InvoicePostingBuffer.PreparePurchase(PurchLine);

        InitTotalAmounts(
            PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY,
            TotalVATBase, TotalVATBaseACY);

        OnPrepareLineOnAfterAssignAmounts(PurchLine, PurchLineACY, TotalAmount, TotalAmountACY);

        if PurchLine."Deferral Code" <> '' then
            GetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDeferACY, DeferralAccount);

        InvoiceDiscountPosting := PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"];
        OnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader, PurchLine, InvoiceDiscountPosting);
        if InvoiceDiscountPosting then begin
            IsHandled := false;
            OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(
                TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine,
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
                if InvoicePostingParameters."Tax Type" = InvoicePostingParameters."Tax Type"::"Sales Tax" then
                    InvoicePostingBuffer.ClearVATFields();
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                    if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                        PrepareLineFADiscount(
                          InvoicePostingBuffer, GenPostingSetup, PurchLine."No.",
                          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
                        InvoicePostingBuffer.SetAccount(
                          GenPostingSetup.GetPurchInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"Fixed Asset";
                    end else begin
                        IsHandled := false;
                        InvDiscAccount := '';
                        OnPrepareLineOnBeforeSetInvoiceDiscAccount(PurchLine, GenPostingSetup, InvDiscAccount, IsHandled);
                        if not IsHandled then
                            InvDiscAccount := GenPostingSetup.GetPurchInvDiscAccount();
                        InvoicePostingBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        OnPrepareLineOnAfterSetInvoiceDiscAccount(PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                    end;
                end;
            end;
        end;

        LineDiscountPosting := PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"];
        OnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader, PurchLine, LineDiscountPosting);
        if LineDiscountPosting then begin
            IsHandled := false;
            OnPrepareLineOnBeforeCalcLineDiscountPosting(
               TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
                if InvoicePostingParameters."Tax Type" = InvoicePostingParameters."Tax Type"::"Sales Tax" then
                    InvoicePostingBuffer.ClearVATFields();
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    GenPostingSetup.TestField("Purch. Line Disc. Account");
                    if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                        PrepareLineFADiscount(
                          InvoicePostingBuffer, GenPostingSetup, PurchLine."No.",
                          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
                        InvoicePostingBuffer.SetAccount(
                          GenPostingSetup.GetPurchLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"Fixed Asset";
                    end else begin
                        IsHandled := false;
                        LineDiscAccount := '';
                        OnPrepareLineOnBeforeSetLineDiscAccount(PurchLine, GenPostingSetup, LineDiscAccount, IsHandled);
                        if not IsHandled then
                            LineDiscAccount := GenPostingSetup.GetPurchLineDiscAccount();
                        InvoicePostingBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        OnPrepareLineOnAfterSetLineDiscAccount(PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                    end;
                end;
            end;
        end;

        OnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine, TotalAmount, TotalAmountACY, PurchHeader.GetUseDate());
        DeferralUtilities.AdjustTotalAmountForDeferrals(
          PurchLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);

        IsHandled := false;
        OnPrepareLineOnBeforeSetAmounts(
            PurchLine, PurchLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
                if PurchLine."Deferral Code" <> '' then
                    InvoicePostingBuffer.SetAmounts(
                        TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
                else
                    InvoicePostingBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference");
            end else
                if (not PurchLine."Use Tax") or (PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Sales Tax") then
                    InvoicePostingBuffer.SetAmounts(
                        TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
                else
                    InvoicePostingBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference");

        if InvoicePostingParameters."Tax Type" = InvoicePostingParameters."Tax Type"::"Sales Tax" then begin
            InvoicePostingBuffer.ClearVATFields();
            if PurchLine."Tax To Be Expensed" <> 0 then begin
                RemSalesTaxAmtACY := RemSalesTaxAmtACY + PurchLineACY."Tax To Be Expensed";
                InvoicePostingBuffer."Amount (ACY)" += Round(RemSalesTaxAmtACY, Currency."Amount Rounding Precision");
                RemSalesTaxAmtACY := RemSalesTaxAmtACY - Round(RemSalesTaxAmtACY, Currency."Amount Rounding Precision");
                RemSalesTaxAmt += PurchLine."Tax To Be Expensed";
                InvoicePostingBuffer.Amount += Round(RemSalesTaxAmt);
                RemSalesTaxAmt := RemSalesTaxAmt - Round(RemSalesTaxAmt);
            end;
        end;

        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, PurchLine);

        PurchAccount := GetPurchAccount(PurchLine, GenPostingSetup);

        OnPrepareLineOnBeforeSetAccount(PurchHeader, PurchLine, PurchAccount);
        InvoicePostingBuffer.SetAccount(PurchAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostingBuffer."Deferral Code" := PurchLine."Deferral Code";
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, PurchLine);
        UpdateInvoicePostingBuffer(InvoicePostingBuffer);

        OnPrepareLineOnAfterUpdateInvoicePostingBuffer(PurchHeader, PurchLine, InvoicePostingBuffer, TempInvoicePostingBuffer);

        if PurchLine."Deferral Code" <> '' then begin
            OnPrepareLineOnBeforePrepareDeferralLine(
                PurchLine, InvoicePostingBuffer, PurchHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
            PrepareDeferralLine(
                PurchHeader, PurchLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                AmtToDefer, AmtToDeferACY, DeferralAccount, PurchAccount);
            OnPrepareLineOnAfterPrepareDeferralLine(
                PurchLine, InvoicePostingBuffer, PurchHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;

        with PurchLine do
            if "Prepayment Line" then
                if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                    AdjAmount := -"Prepmt. Amount Inv. (LCY)";
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, "No.", AdjAmount, PurchHeader."Currency Code" = '');
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, PurchPostPrepayments.GetCorrBalAccNo(PurchHeader, AdjAmount > 0),
                        -AdjAmount, PurchHeader."Currency Code" = '');
                end else
                    if ("Prepayment %" = 100) and ("Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                        TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                            InvoicePostingBuffer, PurchPostPrepayments.GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"),
                            "Prepmt. VAT Amount Inv. (LCY)", PurchHeader."Currency Code" = '');

        InsertTempInvoicePostingBufferReverseCharge(TempInvoicePostingBuffer);
    end;

    local procedure InsertTempInvoicePostingBufferReverseCharge(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        TempInvoicePostingBufferReverseCharge := TempInvoicePostingBuffer;
        if not TempInvoicePostingBufferReverseCharge.Insert() then
            TempInvoicePostingBufferReverseCharge.Modify();
    end;

    local procedure GetPurchAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup") PurchAccountNo: Code[20]
    begin
        if (PurchLine.Type = PurchLine.Type::"G/L Account") or (PurchLine.Type = PurchLine.Type::"Fixed Asset") then
            PurchAccountNo := PurchLine."No."
        else
            if PurchLine.IsCreditDocType() then
                PurchAccountNo := GenPostingSetup.GetPurchCrMemoAccount()
            else
                PurchAccountNo := GenPostingSetup.GetPurchAccount();

        OnAfterGetPurchAccount(PurchLine, GenPostingSetup, PurchAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostingBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then
                    InvoicePostingBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount")
                else
                    InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
        end;

        OnAfterCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    local procedure CalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostingBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then
                    InvoicePostingBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount")
                else
                    InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
        end;

        OnAfterCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    local procedure InitTotalAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVAT := PurchLine."Amount Including VAT" - PurchLine.Amount;
        TotalVATACY := PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
        TotalAmount := PurchLine.Amount;
        TotalAmountACY := PurchLineACY.Amount;
        TotalVATBase := PurchLine."VAT Base Amount";
        TotalVATBaseACY := PurchLineACY."VAT Base Amount";

        OnAfterInitTotalAmounts(PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    local procedure PrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal)
    var
        DeprBook: Record "Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareLineFADiscount(InvoicePostingBuffer, GenPostingSetup, IsHandled);
        if IsHandled then
            exit;

        DeprBook.Get(InvoicePostingBuffer."Depreciation Book Code");
        if DeprBook."Subtract Disc. in Purch. Inv." then begin
            InvoicePostingBuffer.SetAccount(AccountNo, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            UpdateInvoicePostingBuffer(InvoicePostingBuffer);
            InvoicePostingBuffer.ReverseAmounts();
            InvoicePostingBuffer.SetAccount(
              GenPostingSetup.GetPurchFADiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
            UpdateInvoicePostingBuffer(InvoicePostingBuffer);
            InvoicePostingBuffer.ReverseAmounts();
        end;
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
        end;

        TempInvoicePostingBuffer.Update(InvoicePostingBuffer, InvDefLineNo, DeferralLineNo);
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        JobPurchLine: Record "Purchase Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        PurchHeader := DocumentHeaderVar;

        OnBeforePostLines(PurchHeader, TempInvoicePostingBuffer);

        LineCount := 0;

        CalculateVATAmounts(PurchHeader, TempInvoicePostingBuffer);

        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostingBuffer.ApplyRoundingForFinalPosting();
                PrepareGenJnlLine(PurchHeader, TempInvoicePostingBuffer, GenJnlLine);

                OnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
                GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
                OnPostLinesOnAfterGenJnlLinePost(
                    GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);

                if (TempInvoicePostingBuffer."Job No." <> '') and
                   (TempInvoicePostingBuffer.Type = TempInvoicePostingBuffer.Type::"G/L Account")
                then begin
                    SetJobLineFilters(JobPurchLine, TempInvoicePostingBuffer);
                    JobPostLine.PostJobPurchaseLines(JobPurchLine.GetView(), GLEntryNo);
                end;
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := TempInvoicePostingBuffer.Amount;

        TempInvoicePostingBuffer.DeleteAll();
    end;

    local procedure PrepareGenJnlLine(var PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            InitGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            CopyFromPurchHeader(PurchHeader);

            InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
            OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);

            if InvoicePostingBuffer.Type <> InvoicePostingBuffer.Type::"Prepmt. Exch. Rate Difference" then
                "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
            if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                case InvoicePostingBuffer."FA Posting Type" of
                    InvoicePostingBuffer."FA Posting Type"::"Acquisition Cost":
                        "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                    InvoicePostingBuffer."FA Posting Type"::Maintenance:
                        "FA Posting Type" := "FA Posting Type"::Maintenance;
                    InvoicePostingBuffer."FA Posting Type"::Appreciation:
                        "FA Posting Type" := "FA Posting Type"::Appreciation;
                end;
                InvoicePostingBuffer.CopyToGenJnlLineFA(GenJnlLine);
            end;
        end;

        OnAfterPrepareGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", InvoicePostingBuffer."Entry Description",
            InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
            InvoicePostingBuffer."Dimension Set ID", PurchHeader."Reason Code");
    end;

    procedure PrepareJobLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchHeader := DocumentHeaderVar;
        PurchLine := DocumentLineVar;
        PurchLineACY := DocumentLineACYVar;

        if PurchHeader.IsCreditDocType() then
            PurchCrMemoHdr.Get(InvoicePostingParameters."Document No.")
        else
            PurchInvHeader.Get(InvoicePostingParameters."Document No.");

        JobPostLine.PostJobOnPurchaseLine(
            PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, InvoicePostingParameters."Source Code");
    end;

    local procedure SetJobLineFilters(var JobPurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        JobPurchLine.Reset();
        JobPurchLine.SetRange("Job No.", InvoicePostingBuffer."Job No.");
        JobPurchLine.SetRange("No.", InvoicePostingBuffer."G/L Account");
        JobPurchLine.SetRange("Gen. Bus. Posting Group", InvoicePostingBuffer."Gen. Bus. Posting Group");
        JobPurchLine.SetRange("Gen. Prod. Posting Group", InvoicePostingBuffer."Gen. Prod. Posting Group");
        JobPurchLine.SetRange("VAT Bus. Posting Group", InvoicePostingBuffer."VAT Bus. Posting Group");
        JobPurchLine.SetRange("VAT Prod. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
        JobPurchLine.SetRange("Dimension Set ID", InvoicePostingBuffer."Dimension Set ID");

        OnAfterSetJobLineFilters(JobPurchLine, InvoicePostingBuffer);
    end;

    procedure CheckCreditLine(PurchHeaderVar: Variant; PurchLineVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader := PurchHeaderVar;
        PurchLine := PurchLineVar;

        if PurchLine.IsCreditDocType() then
            if (PurchLine."Job No." <> '') and (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Qty. to Invoice" <> 0) then
                JobPostLine.CheckItemQuantityPurchCredit(PurchHeader, PurchLine);
    end;

    procedure PostLedgerEntry(PurchHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        PurchHeader := PurchHeaderVar;

        IsHandled := false;
        OnBeforePostLedgerEntry(PurchHeader, TotalPurchLine, TotalPurchLineLCY, InvoicePostingParameters, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Vendor;
            "Account No." := PurchHeader."Pay-to Vendor No.";
            CopyFromPurchHeader(PurchHeader);
            SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
            "System-Created Entry" := true;

            CopyFromPurchHeaderApplyTo(PurchHeader);
            CopyFromPurchHeaderPayment(PurchHeader);

            InitGenJnlLineAmountFieldsFromTotalPurchLine(GenJnlLine, PurchHeader);

            OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure InitGenJnlLineAmountFieldsFromTotalPurchLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            Amount := -TotalPurchLine."Amount Including VAT";
            "Source Currency Amount" := -TotalPurchLine."Amount Including VAT";
            "Amount (LCY)" := -TotalPurchLineLCY."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalPurchLineLCY.Amount;
            "Inv. Discount (LCY)" := -TotalPurchLineLCY."Inv. Discount Amount";
            if PurchHeader."IRS 1099 Code" <> '' then begin
                "IRS 1099 Code" := PurchHeader."IRS 1099 Code";
                "IRS 1099 Amount" := -Round(PurchHeader."IRS 1099 Amount");
            end;
        end;
    end;

    procedure PostBalancingEntry(PurchHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        PurchHeader := PurchHeaderVar;

        FindVendorLedgerEntry(VendLedgEntry2);

        with GenJnlLine do begin
            InitNewLine(
              PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."Posting Description",
              PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
              PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

            CopyDocumentFields(
                "Gen. Journal Document Type"::" ", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Vendor;
            "Account No." := PurchHeader."Pay-to Vendor No.";
            CopyFromPurchHeader(PurchHeader);
            SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");

            if PurchHeader.IsCreditDocType() then
                "Document Type" := "Document Type"::Refund
            else
                "Document Type" := "Document Type"::Payment;

            SetApplyToDocNo(PurchHeader, GenJnlLine);

            Amount := TotalPurchLine."Amount Including VAT" + VendLedgEntry2."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            VendLedgEntry2.CalcFields(Amount);
            if VendLedgEntry2.Amount = 0 then
                "Amount (LCY)" := TotalPurchLineLCY."Amount Including VAT"
            else
                "Amount (LCY)" :=
                  TotalPurchLineLCY."Amount Including VAT" +
                  Round(VendLedgEntry2."Remaining Pmt. Disc. Possible" / VendLedgEntry2."Adjusted Currency Factor");
            "Allow Zero-Amount Posting" := true;

            OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure SetApplyToDocNo(PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := PurchHeader."Bal. Account No.";
            "Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
            "Applies-to Doc. No." := InvoicePostingParameters."Document No.";
        end;

        OnAfterSetApplyToDocNo(GenJnlLine, PurchHeader);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        VendorLedgerEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        VendorLedgerEntry.FindLast();
    end;

    local procedure GetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(PurchLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if PurchLine.IsCreditDocType() then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure CalculateVATAmounts(PurchHeader: Record "Purchase Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBaseAmount: Decimal;
        VATBaseAmountACY: Decimal;
        VATAmount: Decimal;
        VATAmountACY: Decimal;
        VATAmountRemainder: Decimal;
        VATAmountACYRemainder: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateVATAmounts(PurchHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        VATAmountRemainder := 0;
        VATAmountACYRemainder := 0;

        if InvoicePostingBuffer.FindSet() then
            repeat
                case InvoicePostingBuffer."VAT Calculation Type" of
                    InvoicePostingBuffer."VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            VATPostingSetup.Get(InvoicePostingBuffer."VAT Bus. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
                            OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(VATPostingSetup);

                            VATBaseAmount := InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100);
                            VATBaseAmountACY := InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100);

                            if PurchHeader."Currency Code" <> '' then
                                VATBaseAmount := CurrExchRate.ExchangeAmtLCYToFCY(
                                    PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                    VATBaseAmount, PurchHeader."Currency Factor");

                            VATAmount := VATBaseAmount * VATPostingSetup."VAT %" / 100;
                            VATAmountACY := VATBaseAmountACY * VATPostingSetup."VAT %" / 100;

                            TempInvoicePostingBufferReverseCharge := InvoicePostingBuffer;
                            if TempInvoicePostingBufferReverseCharge.Find() then begin
                                VATAmountRemainder += VATAmount;
                                InvoicePostingBuffer."VAT Amount" := Round(VATAmountRemainder);
                                VATAmountRemainder -= InvoicePostingBuffer."VAT Amount";

                                if PurchHeader."Currency Code" <> '' then
                                    InvoicePostingBuffer."VAT Amount" := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                                            PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                            InvoicePostingBuffer."VAT Amount", PurchHeader."Currency Factor"));

                                VATAmountACYRemainder += VATAmountACY;
                                InvoicePostingBuffer."VAT Amount (ACY)" := Round(VATAmountACYRemainder, Currency."Amount Rounding Precision");
                                VATAmountACYRemainder -= InvoicePostingBuffer."VAT Amount (ACY)";

                                InvoicePostingBuffer."VAT Base Amount" := Round(InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                InvoicePostingBuffer."VAT Base Amount (ACY)" := Round(InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                            end else begin
                                InvoicePostingBuffer."VAT Amount" := Round(VATAmount);
                                InvoicePostingBuffer."VAT Amount (ACY)" := Round(VATAmountACY, Currency."Amount Rounding Precision");

                                InvoicePostingBuffer."VAT Base Amount" := Round(InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                InvoicePostingBuffer."VAT Base Amount (ACY)" := Round(InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                            end;
                            InvoicePostingBuffer.Modify();
                        end;
                end;
            until InvoicePostingBuffer.Next() = 0;
    end;

    local procedure PrepareDeferralLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
    begin
        DeferralTemplate.Get(PurchLine."Deferral Code");

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            if TempDeferralHeader."Amount to Defer" <> 0 then begin
                DeferralUtilities.FilterDeferralLines(
                  TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
                  PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");

                DeferralPostingBuffer.PreparePurch(PurchLine, InvoicePostingParameters."Document No.");
                DeferralPostingBuffer."Posting Date" := PurchHeader."Posting Date";
                DeferralPostingBuffer.Description := PurchHeader."Posting Description";
                DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                OnPrepareDeferralLineOnBeforeDeferralPostingBufferPrepareInitialAmounts(
                    DeferralPostingBuffer, PurchHeader, PurchLine, AmountLCY, AmountACY,
                    RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, PurchAccount);
                DeferralPostingBuffer.PrepareInitialAmounts(
                  AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount);
                DeferralPostingBuffer.Update(DeferralPostingBuffer);
                if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                    DeferralPostingBuffer.PrepareRemainderPurchase(
                      PurchLine, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount, InvDefLineNo);
                    DeferralPostingBuffer.Update(DeferralPostingBuffer);
                end;

                if TempDeferralLine.FindSet() then
                    repeat
                        if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                            DeferralPostingBuffer.PreparePurch(PurchLine, InvoicePostingParameters."Document No.");
                            DeferralPostingBuffer.InitFromDeferralLine(TempDeferralLine);
                            if PurchLine.IsCreditDocType() then
                                DeferralPostingBuffer.ReverseAmounts();
                            DeferralPostingBuffer."G/L Account" := PurchAccount;
                            DeferralPostingBuffer."Deferral Account" := DeferralAccount;
                            DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                            DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                            DeferralPostingBuffer.Update(DeferralPostingBuffer);
                        end else
                            Error(ZeroDeferralAmtErr, PurchLine."No.", PurchLine."Deferral Code");

                    until TempDeferralLine.Next() = 0

                else
                    Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code");
            end else
                Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
        end else
            Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
    end;

    procedure CalcDeferralAmounts(PurchHeaderVar: Variant; PurchLineVar: Variant; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
    begin
        PurchHeader := PurchHeaderVar;
        PurchLine := PurchLineVar;

        if DeferralHeader.Get(
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            Currency.Initialize(PurchHeader."Currency Code", true);
            TempDeferralHeader := DeferralHeader;
            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", PurchHeader."Currency Factor"));
            TempDeferralHeader.Insert();

            with DeferralLine do begin
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                  DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                  PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
                if FindSet() then begin
                    TotalDeferralCount := Count;
                    repeat
                        DeferralCount := DeferralCount + 1;
                        TempDeferralLine.Init();
                        TempDeferralLine := DeferralLine;

                        if DeferralCount = TotalDeferralCount then begin
                            TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                            TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                        end else begin
                            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                                TempDeferralLine.Amount :=
                                  Round(TempDeferralLine.Amount *
                                    PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");

                            TempDeferralLine."Amount (LCY)" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                  TempDeferralLine.Amount, PurchHeader."Currency Factor"));
                            TotalAmount := TotalAmount + TempDeferralLine.Amount;
                            TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                        end;
                        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, PurchLine, DeferralCount, TotalDeferralCount);
                        TempDeferralLine.Insert();
                    until Next() = 0;
                end;
            end;
        end;
    end;

    procedure CreatePostedDeferralSchedule(PurchLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        PurchLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
    begin
        PurchLine := PurchLineVar;

        if PurchLine."Deferral Code" = '' then
            exit;

        if DeferralTemplate.Get(PurchLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '',
                NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount, PurchLine."Buy-from Vendor No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
                TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
                PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            if TempDeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                      TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next() = 0;
        end;

        OnAfterCreatePostedDeferralSchedule(PurchLine, PostedDeferralHeader);
    end;

    local procedure GetGenPostingSetup(var GenPostingSetup: Record "General Posting Setup"; PurchLine: Record "Purchase Line")
    begin
        if GLSetup."VAT in Use" then
            GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group")
        else
            if (PurchLine.Type.AsInteger() >= PurchLine.Type::"G/L Account".AsInteger()) and
               ((PurchLine."Qty. to Invoice" <> 0) or (PurchLine."Qty. to Receive" <> 0))
            then
                if PurchLine.Type in [PurchLine.Type::"G/L Account", PurchLine.Type::"Fixed Asset"] then
                    if (((PurchSetup."Discount Posting" = PurchSetup."Discount Posting"::"Invoice Discounts") and
                         (PurchLine."Inv. Discount Amount" <> 0)) or
                        ((PurchSetup."Discount Posting" = PurchSetup."Discount Posting"::"Line Discounts") and
                         (PurchLine."Line Discount Amount" <> 0)) or
                        ((PurchSetup."Discount Posting" = PurchSetup."Discount Posting"::"All Discounts") and
                         ((PurchLine."Inv. Discount Amount" <> 0) or (PurchLine."Line Discount Amount" <> 0))))
                    then begin
                        if not GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group") then
                            if PurchLine."Gen. Prod. Posting Group" = '' then
                                Error(
                                  GenProdPostingGrDiscErr,
                                  PurchLine.FieldName("Gen. Prod. Posting Group"), PurchLine.FieldName("Line No."), PurchLine."Line No.")
                            else
                                GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
                    end else
                        Clear(GenPostingSetup)
                else
                    GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralSchedule(PurchLine: Record "Purchase Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTotalAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobPurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateVATAmounts(PurchHeader: Record "Purchase Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(PurchHeader: Record "Purchase Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var PurchHeader: Record "Purchase Header"; TotalPurchLine: Record "Purchase Line"; TotalPurchLineLCY: Record "Purchase Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; PurchLine: Record "Purchase Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var SalesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePreparePurchase(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforeDeferralPostingBufferPrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    begin
    end;
}
