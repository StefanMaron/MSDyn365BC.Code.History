codeunit 66 "Purch - Calc Disc. By Type"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Copy(Rec);

        if PurchHeader.Get("Document Type", "Document No.") then begin
            ApplyDefaultInvoiceDiscount(PurchHeader."Invoice Discount Value", PurchHeader);
            // on new order might be no line
            if Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then;
        end;
    end;

    var
        InvDiscBaseAmountIsZeroErr: Label 'There is no amount that you can apply an invoice discount to.';

    procedure ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount: Decimal; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        if not ShouldRedistributeInvoiceDiscountAmount(PurchHeader) then
            exit;

        IsHandled := false;
        OnBeforeApplyDefaultInvoiceDiscount(PurchHeader, IsHandled);
        if not IsHandled then
            if PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::Amount then
                ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchHeader)
            else
                ApplyInvDiscBasedOnPct(PurchHeader);

        ResetRecalculateInvoiceDisc(PurchHeader);
    end;

    procedure ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount: Decimal; var PurchHeader: Record "Purchase Header")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        InvDiscBaseAmount: Decimal;
    begin
        with PurchHeader do begin

            PurchSetup.Get();
            DiscountNotificationMgt.NotifyAboutMissingSetup(
                PurchSetup.RecordId, "Gen. Bus. Posting Group",
                PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Line Discounts");

            PurchLine.SetRange("Document No.", "No.");
            PurchLine.SetRange("Document Type", "Document Type");

            PurchLine.CalcVATAmountLines(0, PurchHeader, PurchLine, TempVATAmountLine);

            InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, "Currency Code");

            if (InvDiscBaseAmount = 0) and (InvoiceDiscountAmount > 0) then
                Error(InvDiscBaseAmountIsZeroErr);

            TempVATAmountLine.SetInvoiceDiscountAmount(InvoiceDiscountAmount, "Currency Code",
              "Prices Including VAT", "VAT Base Discount %");

            PurchLine.UpdateVATOnLines(0, PurchHeader, PurchLine, TempVATAmountLine);

            "Invoice Discount Calculation" := "Invoice Discount Calculation"::Amount;
            "Invoice Discount Value" := InvoiceDiscountAmount;

            ResetRecalculateInvoiceDisc(PurchHeader);

            Modify;
        end;
    end;

    local procedure ApplyInvDiscBasedOnPct(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchHeader do begin
            PurchLine.SetRange("Document No.", "No.");
            PurchLine.SetRange("Document Type", "Document Type");
            if PurchLine.FindFirst then begin
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
                Get("Document Type", "No.");
            end;
        end;
    end;

    procedure GetVendInvoiceDiscountPct(PurchLine: Record "Purchase Line"): Decimal
    var
        PurchHeader: Record "Purchase Header";
        InvoiceDiscountValue: Decimal;
        AmountIncludingVATDiscountAllowed: Decimal;
        AmountDiscountAllowed: Decimal;
    begin
        with PurchHeader do begin
            if not Get(PurchLine."Document Type", PurchLine."Document No.") then
                exit(0);

            CalcFields("Invoice Discount Amount");
            if "Invoice Discount Amount" = 0 then
                exit(0);

            case "Invoice Discount Calculation" of
                "Invoice Discount Calculation"::"%":
                    begin
                        // Only if VendorInvDisc table is empty header is not updated
                        if not VendorInvDiscRecExists("Invoice Disc. Code") then
                            exit(0);

                        exit("Invoice Discount Value");
                    end;
                "Invoice Discount Calculation"::None,
                "Invoice Discount Calculation"::Amount:
                    begin
                        InvoiceDiscountValue := "Invoice Discount Amount";

                        CalcAmountWithDiscountAllowed(PurchHeader, AmountIncludingVATDiscountAllowed, AmountDiscountAllowed);

                        if AmountDiscountAllowed + InvoiceDiscountValue = 0 then
                            exit(0);

                        if "Prices Including VAT" then
                            exit(Round(InvoiceDiscountValue / (AmountIncludingVATDiscountAllowed + InvoiceDiscountValue) * 100, 0.01));

                        exit(Round(InvoiceDiscountValue / AmountDiscountAllowed * 100, 0.01));
                    end;
            end;
        end;

        exit(0);
    end;

    procedure ShouldRedistributeInvoiceDiscountAmount(PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldRedistributeInvoiceDiscountAmount(PurchHeader, IsHandled);
        if IsHandled then
            exit(true);

        PurchHeader.CalcFields("Recalculate Invoice Disc.");
        if not PurchHeader."Recalculate Invoice Disc." then
            exit(false);

        if (PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::Amount) and
           (PurchHeader."Invoice Discount Value" = 0)
        then
            exit(false);

        PurchPayablesSetup.Get();
        if (not ApplicationAreaMgmtFacade.IsFoundationEnabled and
            (not PurchPayablesSetup."Calc. Inv. Discount" and
             (PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::None)))
        then
            exit(false);

        exit(true);
    end;

    procedure ResetRecalculateInvoiceDisc(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Recalculate Invoice Disc.", true);
        PurchLine.ModifyAll("Recalculate Invoice Disc.", false);

        OnAfterResetRecalculateInvoiceDisc(PurchHeader);
    end;

    local procedure VendorInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorInvoiceDisc.SetRange(Code, InvDiscCode);
        exit(not VendorInvoiceDisc.IsEmpty);
    end;

    procedure InvoiceDiscIsAllowed(InvDiscCode: Code[20]): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if not PurchasesPayablesSetup."Calc. Inv. Discount" then
            exit(true);

        exit(not VendorInvDiscRecExists(InvDiscCode));
    end;

    local procedure CalcAmountWithDiscountAllowed(PurchHeader: Record "Purchase Header"; var AmountIncludingVATDiscountAllowed: Decimal; var AmountDiscountAllowed: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetRange("Allow Invoice Disc.", true);
            CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");
            AmountIncludingVATDiscountAllowed := "Amount Including VAT";
            AmountDiscountAllowed := Amount + "Inv. Discount Amount";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDefaultInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldRedistributeInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

