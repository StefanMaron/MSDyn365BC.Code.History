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
        OnBeforePrepareLine(SalesHeader, SalesLine, SalesLineACY, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        SalesSetup.Get();
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        OnPrepareLineOnBeforePrepareSales(SalesHeader, SalesLine);
        InvoicePostingBuffer.PrepareSales(SalesLine);

        TotalVAT := SalesLine."Amount Including VAT" - SalesLine.Amount;
        TotalVATACY := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
        TotalAmount := SalesLine.Amount;
        TotalAmountACY := SalesLineACY.Amount;
        TotalVATBase := SalesLine."VAT Base Amount";
        TotalVATBaseACY := SalesLineACY."VAT Base Amount";

        OnPrepareLineOnAfterAssignAmounts(SalesLine, SalesLineACY, TotalAmount, TotalAmountACY);

        if SalesLine."Deferral Code" <> '' then
            GetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount);

        InvoiceDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader, SalesLine, InvoiceDiscountPosting);
        if InvoiceDiscountPosting then begin
            IsHandled := false;
            OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(
                TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine,
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    InvDiscAccount := '';
                    OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
                    if not IsHandled then
                        InvDiscAccount := GenPostingSetup.GetSalesInvDiscAccount();
                    InvoicePostingBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        LineDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader, SalesLine, LineDiscountPosting);
        if LineDiscountPosting then begin
            IsHandled := false;
            OnPrepareLineOnBeforeCalcLineDiscountPosting(
               TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    LineDiscAccount := '';
                    OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine, GenPostingSetup, LineDiscAccount, IsHandled);
                    if not IsHandled then
                        LineDiscAccount := GenPostingSetup.GetSalesLineDiscAccount();
                    InvoicePostingBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    OnPrepareLineOnAfterSetLineDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine, TotalAmount, TotalAmountACY, SalesHeader.GetUseDate());
        DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
            SalesLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY);

        IsHandled := false;
        OnPrepareLineOnBeforeSetAmounts(
            SalesLine, SalesLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            InvoicePostingBuffer.SetAmounts(
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, SalesLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, SalesLine);

        SalesAccount := GetSalesAccount(SalesLine, GenPostingSetup);

        OnPrepareLineOnBeforeSetAccount(SalesHeader, SalesLine, SalesAccount);
        InvoicePostingBuffer.SetAccount(SalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostingBuffer."Deferral Code" := SalesLine."Deferral Code";
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, SalesLine);
        UpdateInvoicePostingBuffer(InvoicePostingBuffer, false);

        OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader, SalesLine, InvoicePostingBuffer, TempInvoicePostingBuffer);

        if SalesLine."Deferral Code" <> '' then begin
            OnPrepareLineOnBeforePrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
            PrepareDeferralLine(
                SalesHeader, SalesLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                AmtToDefer, AmtToDeferACY, DeferralAccount, SalesAccount);
            OnPrepareLineOnAfterPrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;

        with SalesLine do
            if "Prepayment Line" then
                if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                    AdjAmount := -"Prepmt. Amount Inv. (LCY)";
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, "No.", AdjAmount, SalesHeader."Currency Code" = '');
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, SalesPostPrepayments.GetCorrBalAccNo(SalesHeader, AdjAmount > 0),
                        -AdjAmount, SalesHeader."Currency Code" = '');
                end else
                    if ("Prepayment %" = 100) and ("Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                        TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                            InvoicePostingBuffer, SalesPostPrepayments.GetInvRoundingAccNo(SalesHeader."Customer Posting Group"),
                            "Prepmt. VAT Amount Inv. (LCY)", SalesHeader."Currency Code" = '');
    end;

    local procedure GetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup") SalesAccountNo: Code[20]
    begin
        if (SalesLine.Type = SalesLine.Type::"G/L Account") or (SalesLine.Type = SalesLine.Type::"Fixed Asset") then
            SalesAccountNo := SalesLine."No."
        else
            if SalesLine.IsCreditDocType() then
                SalesAccountNo := GenPostingSetup.GetSalesCrMemoAccount()
            else
                SalesAccountNo := GenPostingSetup.GetSalesAccount();

        OnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount");

        OnAfterCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    local procedure CalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount");

        OnAfterCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
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

        OnBeforePostLines(SalesHeader, TempInvoicePostingBuffer);

        LineCount := 0;
        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostingBuffer.ApplyRoundingForFinalPosting();
                PrepareGenJnlLine(SalesHeader, TempInvoicePostingBuffer, GenJnlLine);

                OnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
                GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
                OnPostLinesOnAfterGenJnlLinePost(
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

        TempInvoicePostingBuffer.DeleteAll();
    end;

    local procedure PrepareGenJnlLine(SalesHeader: Record "Sales Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            InitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            CopyFromSalesHeader(SalesHeader);

            InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
            OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

            if InvoicePostingBuffer.Type <> InvoicePostingBuffer.Type::"Prepmt. Exch. Rate Difference" then
                "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                "FA Posting Type" := "FA Posting Type"::Disposal;
                InvoicePostingBuffer.CopyToGenJnlLineFA(GenJnlLine);
            end;
        end;

        OnAfterPrepareGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", InvoicePostingBuffer."Entry Description",
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

        OnAfterSetJobLineFilters(JobSalesLine, InvoicePostingBuffer);
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
        OnBeforePostLedgerEntry(SalesHeader, TotalSalesLine, TotalSalesLineLCY, SuppressCommit, PreviewMode, InvoicePostingParameters, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."Posting Description",
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := SalesHeader."Bill-to Customer No.";
            CopyFromSalesHeader(SalesHeader);
            SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

            "System-Created Entry" := true;

            CopyFromSalesHeaderApplyTo(SalesHeader);
            CopyFromSalesHeaderPayment(SalesHeader);

            Amount := -TotalSalesLine."Amount Including VAT";
            "Source Currency Amount" := -TotalSalesLine."Amount Including VAT";
            "Amount (LCY)" := -TotalSalesLineLCY."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalSalesLineLCY.Amount;
            "Profit (LCY)" := -(TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)");
            "Inv. Discount (LCY)" := -TotalSalesLineLCY."Inv. Discount Amount";

            OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, SuppressCommit, PreviewMode, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, SuppressCommit, GenJnlPostLine);
        end;
    end;

    procedure PostBalancingEntry(SalesHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        EntryFound: Boolean;
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        EntryFound := false;
        IsHandled := false;
        OnPostBalancingEntryOnBeforeFindCustLedgEntry(
           SalesHeader, TotalSalesLine, InvoicePostingParameters, CustLedgEntry, EntryFound, IsHandled);
        if IsHandled then
            exit;

        if not EntryFound then
            FindCustLedgEntry(CustLedgEntry);

        OnPostBalancingEntryOnAfterFindCustLedgEntry(CustLedgEntry);

        with GenJnlLine do begin
            InitNewLine(
              SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."Posting Description",
              SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
              SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

            CopyDocumentFields(
                "Gen. Journal Document Type"::" ", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := SalesHeader."Bill-to Customer No.";
            CopyFromSalesHeader(SalesHeader);
            SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

            if SalesHeader.IsCreditDocType() then
                "Document Type" := "Document Type"::Refund
            else
                "Document Type" := "Document Type"::Payment;

            SetApplyToDocNo(SalesHeader, GenJnlLine);

            SetAmountsForBalancingEntry(CustLedgEntry, GenJnlLine);

            OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, SuppressCommit, PreviewMode, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure SetAmountsForBalancingEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetAmountsForBalancingEntry(CustLedgEntry, GenJnlLine, TotalSalesLine, TotalSalesLineLCY, IsHandled);
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
    end;

    local procedure SetApplyToDocNo(SalesHeader: Record "Sales Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := SalesHeader."Bal. Account No.";
            "Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
            "Applies-to Doc. No." := InvoicePostingParameters."Document No.";
        end;

        OnAfterSetApplyToDocNo(GenJnlLine, SalesHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        CustLedgEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        CustLedgEntry.FindLast();
    end;

    local procedure GetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
    begin
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
            TempDeferralHeader.Insert();

            with DeferralLine do begin
                DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                  DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                  DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
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
                        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
                        TempDeferralLine.Insert();
                    until Next() = 0;
                end;
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
    begin
        SalesLine := SalesLineVar;

        if SalesLine."Deferral Code" = '' then
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

        OnAfterCreatePostedDeferralScheduleFromSalesDoc(SalesLine, PostedDeferralHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralScheduleFromSalesDoc(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var nvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
