codeunit 70 "Purch.-Calc.Discount"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        TempPurchHeader: Record "Purchase Header";
        TempPurchLine: Record "Purchase Line";
    begin
        PurchLine.Copy(Rec);

        TempPurchHeader.Get("Document Type", "Document No.");
        UpdateHeader := true;
        CalculateInvoiceDiscount(TempPurchHeader, TempPurchLine);

        if Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then;
    end;

    var
        Text000: Label 'Service Charge';
        PurchLine: Record "Purchase Line";
        VendInvDisc: Record "Vendor Invoice Disc.";
        VendPostingGr: Record "Vendor Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        UpdateHeader: Boolean;

    procedure CalculateInvoiceDiscount(var PurchHeader: Record "Purchase Header"; var PurchLine2: Record "Purchase Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TempServiceChargeLine: Record "Purchase Line" temporary;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        IsHandled: Boolean;
    begin
        PurchSetup.Get();

        IsHandled := false;
        OnBeforeCalcPurchaseDiscount(PurchHeader, IsHandled, PurchLine2, UpdateHeader);
        if IsHandled then
            exit;

        with PurchLine do begin
            LockTable();
            PurchHeader.TestField("Vendor Posting Group");
            VendPostingGr.Get(PurchHeader."Vendor Posting Group");

            PurchLine2.Reset();
            PurchLine2.SetRange("Document Type", "Document Type");
            PurchLine2.SetRange("Document No.", "Document No.");
            PurchLine2.SetFilter(Type, '<>0');
            PurchLine2.SetRange("System-Created Entry", true);
            PurchLine2.SetRange(Type, PurchLine2.Type::"G/L Account");
            PurchLine2.SetRange("No.", VendPostingGr."Service Charge Acc.");
            if PurchLine2.FindSet(true, false) then
                repeat
                    PurchLine2."Direct Unit Cost" := 0;
                    PurchLine2.Modify();
                    TempServiceChargeLine := PurchLine2;
                    TempServiceChargeLine.Insert();
                until PurchLine2.Next = 0;

            PurchLine2.Reset();
            PurchLine2.SetRange("Document Type", "Document Type");
            PurchLine2.SetRange("Document No.", "Document No.");
            PurchLine2.SetFilter(Type, '<>0');
            if PurchLine2.Find('-') then;
            PurchLine2.CalcVATAmountLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
            InvDiscBase :=
              TempVATAmountLine.GetTotalInvDiscBaseAmount(
                PurchHeader."Prices Including VAT", PurchHeader."Currency Code");
            ChargeBase :=
              TempVATAmountLine.GetTotalLineAmount(
                PurchHeader."Prices Including VAT", PurchHeader."Currency Code");

            if UpdateHeader then
                PurchHeader.Modify();

            if PurchHeader."Posting Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := PurchHeader."Posting Date";

            VendInvDisc.GetRec(
              PurchHeader."Invoice Disc. Code", PurchHeader."Currency Code", CurrencyDate, ChargeBase);

            if VendInvDisc."Service Charge" <> 0 then begin
                Currency.Initialize(PurchHeader."Currency Code");
                if not UpdateHeader then
                    PurchLine2.SetPurchHeader(PurchHeader);
                if not TempServiceChargeLine.IsEmpty then begin
                    TempServiceChargeLine.FindLast;
                    PurchLine2.Get("Document Type", "Document No.", TempServiceChargeLine."Line No.");
                    if PurchHeader."Prices Including VAT" then
                        PurchLine2.Validate(
                          "Direct Unit Cost",
                          Round(
                            (1 + PurchLine2."VAT %" / 100) * VendInvDisc."Service Charge",
                            Currency."Unit-Amount Rounding Precision"))
                    else
                        PurchLine2.Validate("Direct Unit Cost", VendInvDisc."Service Charge");
                    PurchLine2.Modify();
                end else begin
                    PurchLine2.Reset();
                    PurchLine2.SetRange("Document Type", "Document Type");
                    PurchLine2.SetRange("Document No.", "Document No.");
                    PurchLine2.Find('+');
                    PurchLine2.Init();
                    if not UpdateHeader then
                        PurchLine2.SetPurchHeader(PurchHeader);
                    PurchLine2."Line No." := PurchLine2."Line No." + 10000;
                    PurchLine2.Type := PurchLine2.Type::"G/L Account";
                    PurchLine2.Validate("No.", VendPostingGr.GetServiceChargeAccount);
                    PurchLine2.Description := Text000;
                    PurchLine2.Validate(Quantity, 1);
                    if PurchLine2."Document Type" in
                       [PurchLine2."Document Type"::"Return Order", PurchLine2."Document Type"::"Credit Memo"]
                    then
                        PurchLine2.Validate("Return Qty. to Ship", PurchLine2.Quantity)
                    else
                        PurchLine2.Validate("Qty. to Receive", PurchLine2.Quantity);
                    if PurchHeader."Prices Including VAT" then
                        PurchLine2.Validate(
                          "Direct Unit Cost",
                          Round(
                            (1 + PurchLine2."VAT %" / 100) * VendInvDisc."Service Charge",
                            Currency."Unit-Amount Rounding Precision"))
                    else
                        PurchLine2.Validate("Direct Unit Cost", VendInvDisc."Service Charge");
                    PurchLine2."System-Created Entry" := true;
                    PurchLine2.Insert();
                end;
                PurchLine2.CalcVATAmountLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
            end else
                if TempServiceChargeLine.FindSet(false, false) then
                    repeat
                        if (TempServiceChargeLine."Receipt No." = '') and (TempServiceChargeLine."Qty. Rcd. Not Invoiced (Base)" = 0) then begin
                            PurchLine2 := TempServiceChargeLine;
                            PurchLine2.Delete(true);
                        end;
                    until TempServiceChargeLine.Next = 0;

            if VendInvDiscRecExists(PurchHeader."Invoice Disc. Code") then begin
                if InvDiscBase <> ChargeBase then
                    VendInvDisc.GetRec(
                      PurchHeader."Invoice Disc. Code", PurchHeader."Currency Code", CurrencyDate, InvDiscBase);

                DiscountNotificationMgt.NotifyAboutMissingSetup(
                  PurchSetup.RecordId, PurchHeader."Gen. Bus. Posting Group",
                  PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Line Discounts");

                PurchHeader."Invoice Discount Calculation" := PurchHeader."Invoice Discount Calculation"::"%";
                PurchHeader."Invoice Discount Value" := VendInvDisc."Discount %";
                if UpdateHeader then
                    PurchHeader.Modify();

                TempVATAmountLine.SetInvoiceDiscountPercent(
                  VendInvDisc."Discount %", PurchHeader."Currency Code",
                  PurchHeader."Prices Including VAT", PurchSetup."Calc. Inv. Disc. per VAT ID",
                  PurchHeader."VAT Base Discount %");

                PurchLine2.UpdateVATOnLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
                UpdatePrepmtLineAmount(PurchHeader);
            end;
        end;

        PurchCalcDiscByType.ResetRecalculateInvoiceDisc(PurchHeader);
        OnAfterCalcPurchaseDiscount(PurchHeader);
    end;

    local procedure VendInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.SetRange(Code, InvDiscCode);
        exit(VendInvDisc.FindFirst);
    end;

    procedure CalculateIncDiscForHeader(var PurchHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        if not PurchSetup."Calc. Inv. Discount" then
            exit;
        with PurchHeader do begin
            PurchLine."Document Type" := "Document Type";
            PurchLine."Document No." := "No.";
            UpdateHeader := true;
            CalculateInvoiceDiscount(PurchHeader, PurchLine);
        end;
    end;

    procedure CalculateInvoiceDiscountOnLine(var PurchLineToUpdate: Record "Purchase Line")
    var
        PurchHeaderTemp: Record "Purchase Header";
    begin
        PurchLine.Copy(PurchLineToUpdate);

        PurchHeaderTemp.Get(PurchLine."Document Type", PurchLine."Document No.");
        UpdateHeader := false;
        CalculateInvoiceDiscount(PurchHeaderTemp, PurchLine);

        if PurchLineToUpdate.Get(PurchLineToUpdate."Document Type", PurchLineToUpdate."Document No.", PurchLineToUpdate."Line No.") then;
    end;

    local procedure UpdatePrepmtLineAmount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (PurchaseHeader."Invoice Discount Calculation" = PurchaseHeader."Invoice Discount Calculation"::"%") and
           (PurchaseHeader."Prepayment %" > 0) and (PurchaseHeader."Invoice Discount Value" > 0) and
           (PurchaseHeader."Invoice Discount Value" + PurchaseHeader."Prepayment %" >= 100)
        then
            with PurchaseLine do begin
                SetRange("Document Type", PurchaseHeader."Document Type");
                SetRange("Document No.", PurchaseHeader."No.");
                if FindSet(true) then
                    repeat
                        if not ZeroAmountLine(0) and ("Prepayment %" = PurchaseHeader."Prepayment %") then begin
                            "Prepmt. Line Amount" := Amount;
                            Modify;
                        end;
                    until Next = 0;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line"; UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

