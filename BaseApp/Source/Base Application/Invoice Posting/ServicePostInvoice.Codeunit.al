codeunit 817 "Service Post Invoice" implements "Invoice Posting"
{
    var
        SalesSetup: Record "Sales & Receivables Setup";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        IncorrectInterfaceErr: Label 'This implementation designed to post Service Header table only.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Service Header" then
            error(IncorrectInterfaceErr);
    end;

    procedure ClearBuffers()
    begin
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
        TotalServiceLine := TotalDocumentLine;
        TotalServiceLineLCY := TotalDocumentLineLCY;
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineACY: Record "Service Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        ServCost: Record "Service Cost";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        IsHandled: Boolean;
    begin
        ServiceHeader := DocumentHeaderVar;
        ServiceLine := DocumentLineVar;
        ServiceLineACY := DocumentLineACYVar;

        IsHandled := false;
        //OnBeforeFillInvoicePostBuffer(TempInvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            if (ServiceLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
               (ServiceLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
            then
                GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");

        InvoicePostingBuffer.PrepareService(ServiceLine);

        TotalVAT := ServiceLine."Amount Including VAT" - ServiceLine.Amount;
        TotalVATACY := ServiceLineACY."Amount Including VAT" - ServiceLineACY.Amount;
        TotalAmount := ServiceLine.Amount;
        TotalAmountACY := ServiceLineACY.Amount;
        TotalVATBase := ServiceLine."VAT Base Amount";
        TotalVATBaseACY := ServiceLineACY."VAT Base Amount";

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            InvPostingBufferCalcInvoiceDiscountAmount(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostingBuffer.SetAccount(
                  GenPostingSetup.GetSalesInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                if ServiceLine."Line Discount %" = 100 then begin
                    InvoicePostingBuffer."VAT Base Amount" := 0;
                    InvoicePostingBuffer."VAT Base Amount (ACY)" := 0;
                    InvoicePostingBuffer."VAT Amount" := 0;
                    InvoicePostingBuffer."VAT Amount (ACY)" := 0;
                end;
                UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
            end;
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            InvPostingBufferCalcLineDiscountAmount(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostingBuffer.SetAccount(
                  GenPostingSetup.GetSalesLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
            end;
        end;

        InvoicePostingBuffer.SetAmounts(
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, ServiceLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        case ServiceLine.Type of
            ServiceLine.Type::"G/L Account":
                InvoicePostingBuffer.SetAccount(ServiceLine."No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            ServiceLine.Type::Cost:
                begin
                    ServCost.Get(ServiceLine."No.");
                    InvoicePostingBuffer.SetAccount(ServCost."Account No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                end
            else
                if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                    InvoicePostingBuffer.SetAccount(
                      GenPostingSetup.GetSalesCrMemoAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY)
                else
                    InvoicePostingBuffer.SetAccount(
                      GenPostingSetup.GetSalesAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        end;
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);

        //OnAfterFillInvoicePostBuffer(InvoicePostBuffer, ServiceLine, TempInvoicePostingBuffer, SuppressCommit, ServiceLineACY);

        UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
    end;

    local procedure InvPostingBufferCalcInvoiceDiscountAmount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //OnBeforeInvPostingBufferCalcInvoiceDiscountAmount(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
              -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount");
    end;

    local procedure InvPostingBufferCalcLineDiscountAmount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //OnBeforeInvPostingBufferCalcLineDiscountAmount(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
              -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount");
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
        InvoicePostingBuffer."Dimension Set ID" := ServiceLine."Dimension Set ID";
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
        end;

        //OnBeforeUpdateInvPostBuffer(InvoicePostingBuffer);
        TempInvoicePostingBuffer.Update(InvoicePostingBuffer);
        //OnAfterUpdateInvPostBuffer(InvoicePostingBuffer);
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        ServiceHeader: Record "Service Header";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        ServiceHeader := DocumentHeaderVar;

        LineCount := 0;
        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                PrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader, TempInvoicePostingBuffer, GenJnlLine);

                // OnBeforePostInvoicePostBuffer(GenJnlLine, TempInvoicePostingBuffer, ServiceHeader, GenJnlPostLine);
                GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
            // OnAfterPostInvoicePostBuffer(GenJnlLine, TempInvoicePostingBuffer, ServiceHeader, GLEntryNo, GenJnlPostLine);
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := TempInvoicePostingBuffer.Amount;
    end;

    local procedure PrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader: Record "Service Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            InitNewLine(
              ServiceHeader."Posting Date", ServiceHeader."Document Date", InvoicePostingBuffer."Entry Description",
              InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
              InvoicePostingBuffer."Dimension Set ID", ServiceHeader."Reason Code");

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            CopyFromServiceHeader(ServiceHeader);

            InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
        end;
    end;

    procedure CheckCreditLine(SalesHeaderVar: Variant; SalesLineVar: Variant)
    begin
    end;

    procedure PostLedgerEntry(ServiceHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ServiceHeader: Record "Service Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        ServiceHeader := ServiceHeaderVar;

        with GenJnlLine do begin
            InitNewLine(
              ServiceHeader."Posting Date", ServiceHeader."Document Date", ServiceHeader."Posting Description",
              ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
              ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

            CopyDocumentFields(
                InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := ServiceHeader."Bill-to Customer No.";
            CopyFromServiceHeader(ServiceHeader);
            SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

            CopyFromServiceHeaderApplyTo(ServiceHeader);
            CopyFromServiceHeaderPayment(ServiceHeader);

            Amount := -TotalServiceLine."Amount Including VAT";
            "Source Currency Amount" := -TotalServiceLine."Amount Including VAT";
            "Amount (LCY)" := -TotalServiceLineLCY."Amount Including VAT";
            "Sales/Purch. (LCY)" := -TotalServiceLineLCY.Amount;
            "Profit (LCY)" := -(TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)");
            "Inv. Discount (LCY)" := -TotalServiceLineLCY."Inv. Discount Amount";
            "System-Created Entry" := true;

            OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        end;
    end;

    procedure PostBalancingEntry(ServiceHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ServiceHeader: Record "Service Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        ServiceHeader := ServiceHeaderVar;

        CustLedgEntry.FindLast();

        with GenJnlLine do begin
            InitNewLine(
              ServiceHeader."Posting Date", ServiceHeader."Document Date", ServiceHeader."Posting Description",
              ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
              ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

            if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
                CopyDocumentFields(
                    "Document Type"::Refund, InvoicePostingParameters."Document No.",
                    InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '')
            else
                CopyDocumentFields("Document Type"::Payment, InvoicePostingParameters."Document No.",
                    InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

            "Account Type" := "Account Type"::Customer;
            "Account No." := ServiceHeader."Bill-to Customer No.";
            CopyFromServiceHeader(ServiceHeader);
            SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

            SetApplyToDocNo(ServiceHeader, GenJnlLine);

            Amount := TotalServiceLine."Amount Including VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
            "Source Currency Amount" := Amount;
            CustLedgEntry.CalcFields(Amount);
            if CustLedgEntry.Amount = 0 then
                "Amount (LCY)" := TotalServiceLineLCY."Amount Including VAT"
            else
                "Amount (LCY)" :=
                  TotalServiceLineLCY."Amount Including VAT" +
                  Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");

            OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        end;
    end;

    local procedure SetApplyToDocNo(ServiceHeader: Record "Service Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            if ServiceHeader."Bal. Account Type" = ServiceHeader."Bal. Account Type"::"Bank Account" then
                "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := ServiceHeader."Bal. Account No.";
            "Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
            "Applies-to Doc. No." := InvoicePostingParameters."Document No.";
        end;
    end;

    procedure PrepareJobLine(SalesHeaderVar: Variant; SalesLineVar: Variant; SalesLineACYVar: Variant)
    begin
    end;

    procedure CalcDeferralAmounts(ServiceHeaderVar: Variant; ServiceLineVar: Variant; OriginalDeferralAmount: Decimal)
    begin
    end;

    procedure CreatePostedDeferralSchedule(ServiceLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

}