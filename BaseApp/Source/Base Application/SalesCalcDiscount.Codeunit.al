codeunit 60 "Sales-Calc. Discount"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        SalesLine.Copy(Rec);

        TempSalesHeader.Get("Document Type", "Document No.");
        UpdateHeader := true;
        CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);

        if Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then;
    end;

    var
        Text000: Label 'Service Charge';
        TempSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        CustPostingGr: Record "Customer Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        UpdateHeader: Boolean;

    local procedure CalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine2: Record "Sales Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        TempServiceChargeLine: Record "Sales Line" temporary;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        if UpdateHeader then
            SalesHeader.Find; // To ensure we have the latest - otherwise update fails.

        IsHandled := false;
        OnBeforeCalcSalesDiscount(SalesHeader, IsHandled, SalesLine2, UpdateHeader);
        if IsHandled then
            exit;

        with SalesLine do begin
            LockTable();
            SalesHeader.TestField("Customer Posting Group");
            CustPostingGr.Get(SalesHeader."Customer Posting Group");

            SalesLine2.Reset();
            SalesLine2.SetRange("Document Type", "Document Type");
            SalesLine2.SetRange("Document No.", "Document No.");
            SalesLine2.SetRange("System-Created Entry", true);
            SalesLine2.SetRange(Type, SalesLine2.Type::"G/L Account");
            SalesLine2.SetRange("No.", CustPostingGr."Service Charge Acc.");
            if SalesLine2.FindSet(true, false) then
                repeat
                    SalesLine2."Unit Price" := 0;
                    SalesLine2.Modify();
                    TempServiceChargeLine := SalesLine2;
                    TempServiceChargeLine.Insert();
                until SalesLine2.Next = 0;

            SalesLine2.Reset();
            SalesLine2.SetRange("Document Type", "Document Type");
            SalesLine2.SetRange("Document No.", "Document No.");
            SalesLine2.SetFilter(Type, '<>0');
            if SalesLine2.FindFirst then;
            SalesLine2.CalcVATAmountLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
            InvDiscBase :=
              TempVATAmountLine.GetTotalInvDiscBaseAmount(
                SalesHeader."Prices Including VAT", SalesHeader."Currency Code");
            ChargeBase :=
              TempVATAmountLine.GetTotalLineAmount(
                SalesHeader."Prices Including VAT", SalesHeader."Currency Code");

            if UpdateHeader then
                SalesHeader.Modify();

            if SalesHeader."Posting Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := SalesHeader."Posting Date";

            CustInvDisc.GetRec(
              SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", CurrencyDate, ChargeBase);

            if CustInvDisc."Service Charge" <> 0 then begin
                Currency.Initialize(SalesHeader."Currency Code");
                if not UpdateHeader then
                    SalesLine2.SetSalesHeader(SalesHeader);
                if not TempServiceChargeLine.IsEmpty then begin
                    TempServiceChargeLine.FindLast;
                    SalesLine2.Get("Document Type", "Document No.", TempServiceChargeLine."Line No.");
                    SetSalesLineServiceCharge(SalesHeader, SalesLine2);
                    SalesLine2.Modify();
                end else begin
                    SalesLine2.Reset();
                    SalesLine2.SetRange("Document Type", "Document Type");
                    SalesLine2.SetRange("Document No.", "Document No.");
                    SalesLine2.FindLast;
                    SalesLine2.Init();
                    if not UpdateHeader then
                        SalesLine2.SetSalesHeader(SalesHeader);
                    SalesLine2."Line No." := SalesLine2."Line No." + 10000;
                    SalesLine2."System-Created Entry" := true;
                    SalesLine2.Type := SalesLine2.Type::"G/L Account";
                    SalesLine2.Validate("No.", CustPostingGr.GetServiceChargeAccount);
                    SalesLine2.Description := Text000;
                    SalesLine2.Validate(Quantity, 1);

                    OnAfterValidateSalesLine2Quantity(SalesHeader, SalesLine2, CustInvDisc);

                    if SalesLine2."Document Type" in
                       [SalesLine2."Document Type"::"Return Order", SalesLine2."Document Type"::"Credit Memo"]
                    then
                        SalesLine2.Validate("Return Qty. to Receive", SalesLine2.Quantity)
                    else
                        SalesLine2.Validate("Qty. to Ship", SalesLine2.Quantity);
                    SetSalesLineServiceCharge(SalesHeader, SalesLine2);
                    SalesLine2.Insert();
                end;
                SalesLine2.CalcVATAmountLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
            end else
                if TempServiceChargeLine.FindSet(false, false) then
                    repeat
                        if (TempServiceChargeLine."Shipment No." = '') and (TempServiceChargeLine."Qty. Shipped Not Invoiced" = 0) then begin
                            SalesLine2 := TempServiceChargeLine;
                            SalesLine2.Delete(true);
                        end;
                    until TempServiceChargeLine.Next = 0;

            if CustInvDiscRecExists(SalesHeader."Invoice Disc. Code") then begin
                OnAfterCustInvDiscRecExists(SalesHeader);
                if InvDiscBase <> ChargeBase then
                    CustInvDisc.GetRec(
                      SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", CurrencyDate, InvDiscBase);

                DiscountNotificationMgt.NotifyAboutMissingSetup(
                  SalesSetup.RecordId, SalesHeader."Gen. Bus. Posting Group",
                  SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Line Discounts");

                SalesHeader."Invoice Discount Calculation" := SalesHeader."Invoice Discount Calculation"::"%";
                SalesHeader."Invoice Discount Value" := CustInvDisc."Discount %";
                if UpdateHeader then
                    SalesHeader.Modify();

                TempVATAmountLine.SetInvoiceDiscountPercent(
                  CustInvDisc."Discount %", SalesHeader."Currency Code",
                  SalesHeader."Prices Including VAT", SalesSetup."Calc. Inv. Disc. per VAT ID",
                  SalesHeader."VAT Base Discount %");

                SalesLine2.SetSalesHeader(SalesHeader);
                SalesLine2.UpdateVATOnLines(0, SalesHeader, SalesLine2, TempVATAmountLine);
                UpdatePrepmtLineAmount(SalesHeader);
            end;
        end;

        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesHeader);
        OnAfterCalcSalesDiscount(SalesHeader);
    end;

    local procedure SetSalesLineServiceCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesLineServiceCharge(SalesHeader, SalesLine, CustInvDisc, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Prices Including VAT" then
            SalesLine.Validate(
                "Unit Price",
                Round((1 + SalesLine."VAT %" / 100) * CustInvDisc."Service Charge", Currency."Unit-Amount Rounding Precision"))
        else
            SalesLine.Validate("Unit Price", CustInvDisc."Service Charge");
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst);
    end;

    procedure CalculateWithSalesHeader(var TempSalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line")
    var
        FilterSalesLine: Record "Sales Line";
    begin
        FilterSalesLine.Copy(TempSalesLine);
        SalesLine := TempSalesLine;

        UpdateHeader := false;
        CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);

        TempSalesLine.Copy(FilterSalesLine);
    end;

    procedure CalculateInvoiceDiscountOnLine(var SalesLineToUpdate: Record "Sales Line")
    begin
        SalesLine.Copy(SalesLineToUpdate);

        TempSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        UpdateHeader := false;
        CalculateInvoiceDiscount(TempSalesHeader, SalesLine);

        if SalesLineToUpdate.Get(SalesLineToUpdate."Document Type", SalesLineToUpdate."Document No.", SalesLineToUpdate."Line No.") then;
    end;

    procedure CalculateIncDiscForHeader(var TempSalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if not SalesSetup."Calc. Inv. Discount" then
            exit;
        with TempSalesHeader do begin
            SalesLine."Document Type" := "Document Type";
            SalesLine."Document No." := "No.";
            UpdateHeader := true;
            CalculateInvoiceDiscount(TempSalesHeader, TempSalesLine);
        end;
    end;

    local procedure UpdatePrepmtLineAmount(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        if (SalesHeader."Invoice Discount Calculation" = SalesHeader."Invoice Discount Calculation"::"%") and
           (SalesHeader."Prepayment %" > 0) and (SalesHeader."Invoice Discount Value" > 0) and
           (SalesHeader."Invoice Discount Value" + SalesHeader."Prepayment %" >= 100)
        then
            with SalesLine do begin
                SetRange("Document Type", SalesHeader."Document Type");
                SetRange("Document No.", SalesHeader."No.");
                if FindSet(true) then
                    repeat
                        if not ZeroAmountLine(0) and ("Prepayment %" = SalesHeader."Prepayment %") then begin
                            "Prepmt. Line Amount" := Amount;
                            Modify;
                        end;
                    until Next = 0;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesDiscount(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; var UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSalesDiscount(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustInvDiscRecExists(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateSalesLine2Quantity(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesLineServiceCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc."; var IsHandled: Boolean)
    begin
    end;
}

