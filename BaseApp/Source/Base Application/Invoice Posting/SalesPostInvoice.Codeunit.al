codeunit 815 "Sales Post Invoice" implements "Invoice Posting"
{
    Permissions = TableData "Invoice Posting Buffer" = imd;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        JobPostLine: Codeunit "Job Post-Line";
        SalesPostInvoiceEvents: Codeunit "Sales Post Invoice Events";
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        IncorrectInterfaceErr: Label 'This implementation designed to post Sales Header table only.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Sales Header" then
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
        TotalSalesLine := TotalDocumentLine;
        TotalSalesLineLCY := TotalDocumentLineLCY;
    end;

    procedure ClearBuffers()
    begin
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        TempInvoicePostingBuffer.DeleteAll();
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
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
        SalesAccount: Code[20];
        InvDiscAccount: code[20];
        LineDiscAccount: code[20];
        IsHandled: Boolean;
        InvoiceDiscountPosting: Boolean;
        LineDiscountPosting: Boolean;
    begin
        SalesHeader := DocumentHeaderVar;
        SalesLine := DocumentLineVar;
        SalesLineACY := DocumentLineACYVar;

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforePrepareLine(SalesHeader, SalesLine, SalesLineACY, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        SalesSetup.Get();
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField(Blocked, false);

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforePrepareSales(SalesHeader, SalesLine, GenPostingSetup);
        InvoicePostingBuffer.PrepareSales(SalesLine);

        InitTotalAmounts(
            SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY,
            TotalVATBase, TotalVATBaseACY);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterAssignAmounts(SalesLine, SalesLineACY, TotalAmount, TotalAmountACY);

        if SalesLine."Deferral Code" <> '' then
            GetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount);

        InvoiceDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader, SalesLine, InvoiceDiscountPosting);
        if InvoiceDiscountPosting then begin
            IsHandled := false;
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(
                TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine,
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    InvDiscAccount := '';
                    SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
                    if not IsHandled then
                        InvDiscAccount := GenPostingSetup.GetSalesInvDiscAccount();
                    InvoicePostingBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        LineDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader, SalesLine, LineDiscountPosting);
        if LineDiscountPosting then begin
            IsHandled := false;
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcLineDiscountPosting(
               TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    LineDiscAccount := '';
                    SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetLineDiscAccount(SalesLine, GenPostingSetup, LineDiscAccount, IsHandled);
                    if not IsHandled then
                        LineDiscAccount := GenPostingSetup.GetSalesLineDiscAccount();
                    InvoicePostingBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine, TotalAmount, TotalAmountACY, SalesHeader.GetUseDate());
        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
            SalesLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAmounts(
            SalesLine, SalesLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            InvoicePostingBuffer.SetAmounts(
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, SalesLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then
            InvoicePostingBuffer.SetSalesTaxForSalesLine(SalesLine);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, SalesLine);

        SalesAccount := GetSalesAccount(SalesLine, GenPostingSetup);

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAccount(SalesHeader, SalesLine, SalesAccount);
        InvoicePostingBuffer.SetAccount(SalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostingBuffer."Deferral Code" := SalesLine."Deferral Code";
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, SalesLine);
        UpdateInvoicePostingBuffer(InvoicePostingBuffer, false);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(
            SalesHeader, SalesLine, InvoicePostingBuffer, TempInvoicePostingBuffer);

        if SalesLine."Deferral Code" <> '' then begin
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforePrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
            PrepareDeferralLine(
                SalesHeader, SalesLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                AmtToDefer, AmtToDeferACY, DeferralAccount, SalesAccount);
            SalesPostInvoiceEvents.RunOnPrepareLineOnAfterPrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;

        if SalesLine."Prepayment Line" then
            if SalesLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
                AdjAmount := -SalesLine."Prepmt. Amount Inv. (LCY)";
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, SalesLine."No.", AdjAmount, SalesHeader."Currency Code" = '');
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, SalesPostPrepayments.GetCorrBalAccNo(SalesHeader, AdjAmount > 0),
                    -AdjAmount, SalesHeader."Currency Code" = '');
            end else
                if (SalesLine."Prepayment %" = 100) and (SalesLine."Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, SalesPostPrepayments.GetInvRoundingAccNo(SalesHeader."Customer Posting Group"),
                        SalesLine."Prepmt. VAT Amount Inv. (LCY)", SalesHeader."Currency Code" = '');
    end;

    local procedure GetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup") SalesAccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, IsHandled);
        if not IsHandled then
            if (SalesLine.Type = SalesLine.Type::"G/L Account") or (SalesLine.Type = SalesLine.Type::"Fixed Asset") then
                SalesAccountNo := SalesLine."No."
            else
                if SalesLine.IsCreditDocType() then
                    SalesAccountNo := GenPostingSetup.GetSalesCrMemoAccount()
                else
                    SalesAccountNo := GenPostingSetup.GetSalesAccount();

        SalesPostInvoiceEvents.RunOnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount");

        SalesPostInvoiceEvents.RunOnAfterCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    local procedure CalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount");

        SalesPostInvoiceEvents.RunOnAfterCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    local procedure InitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVAT := SalesLine."Amount Including VAT" - SalesLine.Amount;
        TotalVATACY := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
        TotalAmount := SalesLine.Amount;
        TotalAmountACY := SalesLineACY.Amount;
        TotalVATBase := SalesLine."VAT Base Amount";
        TotalVATBaseACY := SalesLineACY."VAT Base Amount";

        SalesPostInvoiceEvents.RunOnAfterInitTotalAmounts(SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean)
    var
        RestoreFAType: Boolean;
    begin
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
            if ForceGLAccountType then begin
                RestoreFAType := true;
                InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
            end;
        end;

        TempInvoicePostingBuffer.Update(InvoicePostingBuffer, InvDefLineNo, DeferralLineNo);

        if RestoreFAType then
            TempInvoicePostingBuffer.Type := TempInvoicePostingBuffer.Type::"Fixed Asset";
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        JobSalesLine: Record "Sales Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        SalesHeader := DocumentHeaderVar;

        SalesPostInvoiceEvents.RunOnBeforePostLines(SalesHeader, TempInvoicePostingBuffer);

        LineCount := 0;
        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostingBuffer.ApplyRoundingForFinalPosting();
                PrepareGenJnlLine(SalesHeader, TempInvoicePostingBuffer, GenJnlLine);

                SalesPostInvoiceEvents.RunOnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
                GLEntryNo := RunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
                SalesPostInvoiceEvents.RunOnPostLinesOnAfterGenJnlLinePost(
                    GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);

                if (TempInvoicePostingBuffer."Job No." <> '') and
                   (TempInvoicePostingBuffer.Type = TempInvoicePostingBuffer.Type::"G/L Account")
                then begin
                    SetJobLineFilters(JobSalesLine, TempInvoicePostingBuffer);
                    JobPostLine.PostJobSalesLines(JobSalesLine.GetView(), GLEntryNo);
                end;
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := -TempInvoicePostingBuffer.Amount;

        SalesPostInvoiceEvents.RunOnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(
            SalesHeader, GenJnlPostLine, TotalSalesLine, TotalSalesLineLCY, InvoicePostingParameters);
        TempInvoicePostingBuffer.DeleteAll();
    end;

    local procedure PrepareGenJnlLine(var SalesHeader: Record "Sales Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        InitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine.CopyFromSalesHeader(SalesHeader);

        InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := InvoicePostingBuffer."Journal Templ. Name";
        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
        SalesPostInvoiceEvents.RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

        if InvoicePostingBuffer.Type <> InvoicePostingBuffer.Type::"Prepmt. Exch. Rate Difference" then
            GenJnlLine."Gen. Posting Type" := "General Posting Type"::Sale;
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            GenJnlLine."FA Posting Type" := "Gen. Journal Line FA Posting Type"::Disposal;
            InvoicePostingBuffer.CopyToGenJnlLineFA(GenJnlLine);
        end;

        SalesPostInvoiceEvents.RunOnAfterPrepareGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeInitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", InvoicePostingBuffer."Entry Description",
            InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
            InvoicePostingBuffer."Dimension Set ID", SalesHeader."Reason Code");
    end;

    procedure PrepareJobLine(SalesHeaderVar: Variant; SalesLineVar: Variant; SalesLineACYVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
    begin
        SalesHeader := SalesHeaderVar;
        SalesLine := SalesLineVar;
        SalesLineACY := SalesLineACYVar;

        JobPostLine.PostInvoiceContractLine(SalesHeader, SalesLine);
    end;

    local procedure SetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        JobSalesLine.Reset();
        JobSalesLine.SetRange("Job No.", InvoicePostingBuffer."Job No.");
        JobSalesLine.SetRange("No.", InvoicePostingBuffer."G/L Account");
        JobSalesLine.SetRange("Gen. Bus. Posting Group", InvoicePostingBuffer."Gen. Bus. Posting Group");
        JobSalesLine.SetRange("Gen. Prod. Posting Group", InvoicePostingBuffer."Gen. Prod. Posting Group");
        JobSalesLine.SetRange("VAT Bus. Posting Group", InvoicePostingBuffer."VAT Bus. Posting Group");
        JobSalesLine.SetRange("VAT Prod. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
        JobSalesLine.SetRange("Dimension Set ID", InvoicePostingBuffer."Dimension Set ID");

        SalesPostInvoiceEvents.RunOnAfterSetJobLineFilters(JobSalesLine, InvoicePostingBuffer);
    end;

    procedure CheckCreditLine(SalesHeaderVar: Variant; SalesLineVar: Variant)
    begin
    end;

    procedure PostLedgerEntry(SalesHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforePostLedgerEntry(
            SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, InvoicePostingParameters, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", SalesHeader."Posting Description",
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
            SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := "Gen. Journal Account Type"::Customer;
        GenJnlLine."Account No." := SalesHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromSalesHeader(SalesHeader);
        GenJnlLine.SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

        GenJnlLine."System-Created Entry" := true;

        GenJnlLine.CopyFromSalesHeaderApplyTo(SalesHeader);
        GenJnlLine.CopyFromSalesHeaderPayment(SalesHeader);

        InitGenJnlLineAmountFieldsFromTotalSalesLine(GenJnlLine, SalesHeader);

        SalesPostInvoiceEvents.RunOnPostLedgerEntryOnBeforeGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        SalesPostInvoiceEvents.RunOnPostLedgerEntryOnAfterGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure InitGenJnlLineAmountFieldsFromTotalSalesLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeInitGenJnlLineAmountFieldsFromTotalLines(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := -TotalSalesLine."Amount Including VAT";
        GenJnlLine."Source Currency Amount" := -TotalSalesLine."Amount Including VAT";
        GenJnlLine."Amount (LCY)" := -TotalSalesLineLCY."Amount Including VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalSalesLineLCY.Amount;
        GenJnlLine."Profit (LCY)" := -(TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)");
        GenJnlLine."Inv. Discount (LCY)" := -TotalSalesLineLCY."Inv. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", -TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
    end;

    procedure PostBalancingEntry(SalesHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        EntryFound: Boolean;
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        EntryFound := false;
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeFindCustLedgEntry(
           SalesHeader, TotalSalesLine, InvoicePostingParameters, CustLedgEntry2, EntryFound, IsHandled);
        if IsHandled then
            exit;

        if not EntryFound then
            FindCustLedgEntry(CustLedgEntry2);

        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnAfterFindCustLedgEntry(CustLedgEntry2);

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", SalesHeader."Posting Description",
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
            SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            "Gen. Journal Document Type"::" ", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := "Gen. Journal Account Type"::Customer;
        GenJnlLine."Account No." := SalesHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromSalesHeader(SalesHeader);
        GenJnlLine.SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

        if SalesHeader.IsCreditDocType() then
            GenJnlLine."Document Type" := "Gen. Journal Document Type"::Refund
        else
            GenJnlLine."Document Type" := "Gen. Journal Document Type"::Payment;

        SetApplyToDocNo(SalesHeader, GenJnlLine);

        SetAmountsForBalancingEntry(SalesHeader, CustLedgEntry2, GenJnlLine);

        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnAfterGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure SetAmountsForBalancingEntry(SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeSetAmountsForBalancingEntry(CustLedgEntry, GenJnlLine, TotalSalesLine, TotalSalesLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := TotalSalesLine."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        CustLedgEntry.CalcFields(Amount);
        if CustLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalSalesLineLCY."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalSalesLineLCY."Amount Including VAT" +
              Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
    end;

    local procedure SetApplyToDocNo(SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := "Gen. Journal Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := SalesHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
        GenJnlLine."Applies-to Doc. No." := InvoicePostingParameters."Document No.";

        SalesPostInvoiceEvents.RunOnAfterSetApplyToDocNo(GenJnlLine, SalesHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        CustLedgEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        CustLedgEntry.FindLast();
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"): Integer
    begin
        SalesPostInvoiceEvents.RunOnBeforeRunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure GetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeGetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount, IsHandled);
        if IsHandled then
            exit;

        DeferralTemplate.Get(SalesLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if not SalesLine.IsCreditDocType() then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure PrepareDeferralLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
    begin
        DeferralTemplate.Get(SalesLine."Deferral Code");

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            if TempDeferralHeader."Amount to Defer" <> 0 then begin
                DeferralUtilities.FilterDeferralLines(
                  TempDeferralLine, "Deferral Document Type"::Sales.AsInteger(), '', '',
                  SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

                DeferralPostingBuffer.PrepareSales(SalesLine, InvoicePostingParameters."Document No.");
                DeferralPostingBuffer."Posting Date" := SalesHeader."Posting Date";
                DeferralPostingBuffer.Description := SalesHeader."Posting Description";
                DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                SalesPostInvoiceEvents.RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(
                    DeferralPostingBuffer, SalesHeader, SalesLine, AmountLCY, AmountACY,
                    RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, SalesAccount);
                DeferralPostingBuffer.PrepareInitialAmounts(
                  AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount);
                DeferralPostingBuffer.Update(DeferralPostingBuffer);
                if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                    DeferralPostingBuffer.PrepareRemainderSales(
                      SalesLine, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount, InvDefLineNo);
                    DeferralPostingBuffer.Update(DeferralPostingBuffer);
                end;

                if TempDeferralLine.FindSet() then
                    repeat
                        if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                            DeferralPostingBuffer.PrepareSales(SalesLine, InvoicePostingParameters."Document No.");
                            DeferralPostingBuffer.InitFromDeferralLine(TempDeferralLine);
                            if not SalesLine.IsCreditDocType() then
                                DeferralPostingBuffer.ReverseAmounts();
                            DeferralPostingBuffer."G/L Account" := SalesAccount;
                            DeferralPostingBuffer."Deferral Account" := DeferralAccount;
                            DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                            DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                            DeferralPostingBuffer.Update(DeferralPostingBuffer);
                        end else
                            Error(ZeroDeferralAmtErr, SalesLine."No.", SalesLine."Deferral Code");

                    until TempDeferralLine.Next() = 0

                else
                    Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
            end else
                Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code")
        end else
            Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
    end;

    procedure CalcDeferralAmounts(SalesHeaderVar: Variant; SalesLineVar: Variant; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
    begin
        SalesHeader := SalesHeaderVar;
        SalesLine := SalesLineVar;

        if DeferralHeader.Get(
             "Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            Currency.Initialize(SalesHeader."Currency Code", true);
            TempDeferralHeader := DeferralHeader;
            if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    SalesLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesHeader.GetUseDate(), SalesHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", SalesHeader."Currency Factor"));
            SalesPostInvoiceEvents.RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, SalesLine);
            TempDeferralHeader.Insert();

            DeferralUtilities.FilterDeferralLines(
                DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
            TotalAmount := 0;
            TotalAmountLCY := 0;
            if DeferralLine.FindSet() then begin
                TotalDeferralCount := DeferralLine.Count();
                repeat
                    DeferralCount := DeferralCount + 1;
                    TempDeferralLine.Init();
                    TempDeferralLine := DeferralLine;
                    if DeferralCount = TotalDeferralCount then begin
                        TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                        TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                    end else begin
                        if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                            TempDeferralLine.Amount :=
                                Round(TempDeferralLine.Amount *
                                    SalesLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
                        TempDeferralLine."Amount (LCY)" :=
                            Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  SalesHeader.GetUseDate(), SalesHeader."Currency Code",
                                  TempDeferralLine.Amount, SalesHeader."Currency Factor"));
                        TotalAmount := TotalAmount + TempDeferralLine.Amount;
                        TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                    end;
                    SalesPostInvoiceEvents.RunOnBeforeTempDeferralLineInsert(
                        TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
                    TempDeferralLine.Insert();
                until DeferralLine.Next() = 0;
            end;
        end;
    end;

    procedure CreatePostedDeferralSchedule(SalesLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
        IsHandled: Boolean;
    begin
        SalesLine := SalesLineVar;

        if SalesLine."Deferral Code" = '' then
            exit;

        SalesPostInvoiceEvents.RunOnBeforeCreatePostedDeferralSchedule(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if DeferralTemplate.Get(SalesLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             "Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '',
                NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount, SalesLine."Sell-to Customer No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
                TempDeferralLine, "Deferral Document Type"::Sales.AsInteger(), '', '',
                SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
            if TempDeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                        TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next() = 0;
        end;

        SalesPostInvoiceEvents.RunOnAfterCreatePostedDeferralSchedule(SalesLine, PostedDeferralHeader);
    end;

#if not CLEAN20
    [Obsolete('Replaced by RunOnAfterCalcInvoiceDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [Obsolete('Replaced by RunOnAfterCalcLineDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [Obsolete('Replaced by RunOnAfterCreatePostedDeferralScheduleFromSalesDoc in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralScheduleFromSalesDoc(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [Obsolete('Replaced by RunOnAfterGetSalesAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    [Obsolete('Replaced by RunOnAfterPrepareGenJnlLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [Obsolete('Replaced by RunOnAfterSetApplyToDocNo in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [Obsolete('Replaced by RunOnAfterSetJobLineFilters in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [Obsolete('Replaced by RunOnBeforeCalcInvoiceDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforeCalcLineDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforeInitGenJnlLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforePostLines in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforePostLedgerEntry in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforePrepareLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforeSetAmountsForBalancingEntry in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnBeforeTempDeferralLineInsert in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [Obsolete('Replaced by RunOnPostBalancingEntryOnBeforeFindCustLedgEntry in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPostLedgerEntryOnAfterGenJnlPostLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPostLedgerEntryOnBeforeGenJnlPostLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPostBalancingEntryOnAfterGenJnlPostLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPostBalancingEntryOnBeforeGenJnlPostLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPostBalancingEntryOnAfterFindCustLedgEntry in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterAssignAmounts in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterSetAmounts in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterFillInvoicePostingBuffer in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeAdjustTotalAmounts in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeSetAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeSetAmounts in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterSetInvoiceDiscAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterSetLineDiscAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeCalcLineDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPostLinesOnAfterGenJnlLinePost in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    [Obsolete('Replaced by RunOnPostLinesOnBeforeGenJnlLinePost in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterSetInvoiceDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterSetLineDiscountPosting in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterPrepareDeferralLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforePrepareDeferralLine in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforePrepareSales in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeSetInvoiceDiscAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by RunOnPrepareLineOnBeforeSetLineDiscAccount in codeunit Sales Post Invoice Subscr.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;
#endif
}
