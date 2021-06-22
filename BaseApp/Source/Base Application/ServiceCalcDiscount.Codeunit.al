codeunit 5950 "Service-Calc. Discount"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Copy(Rec);

        TempServHeader.Get("Document Type", "Document No.");
        TemporaryHeader := false;
        CalculateInvoiceDiscount(TempServHeader, ServiceLine, TempServiceLine);

        Rec := ServiceLine;
    end;

    var
        Text000: Label 'Service Charge';
        TempServHeader: Record "Service Header";
        TempServiceLine: Record "Service Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        CustPostingGr: Record "Customer Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        TemporaryHeader: Boolean;

    local procedure CalculateInvoiceDiscount(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceLine2: Record "Service Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        ServiceChargeLineNo: Integer;
        ApplyServiceCharge: Boolean;
    begin
        OnBeforeCalcServDiscount(ServHeader);

        SalesSetup.Get();
        with ServiceLine do begin
            LockTable();
            ServHeader.TestField("Customer Posting Group");
            CustPostingGr.Get(ServHeader."Customer Posting Group");

            if not IsServiceChargeUpdated(ServiceLine) then begin
                ServiceLine2.Reset();
                ServiceLine2.SetRange("Document Type", "Document Type");
                ServiceLine2.SetRange("Document No.", "Document No.");
                ServiceLine2.SetRange("System-Created Entry", true);
                ServiceLine2.SetRange(Type, ServiceLine2.Type::"G/L Account");
                ServiceLine2.SetRange("No.", CustPostingGr.GetServiceChargeAccount);
                if ServiceLine2.Find('+') then begin
                    ServiceChargeLineNo := ServiceLine2."Line No.";
                    ServiceLine2.Validate("Unit Price", 0);
                    ServiceLine2.Modify();
                end;
                ApplyServiceCharge := true;
            end;

            ServiceLine2.Reset();
            ServiceLine2.SetRange("Document Type", "Document Type");
            ServiceLine2.SetRange("Document No.", "Document No.");
            ServiceLine2.SetFilter(Type, '<>0');
            if ServiceLine2.Find('-') then;
            ServiceLine2.CalcVATAmountLines(0, ServHeader, ServiceLine2, TempVATAmountLine, false);
            InvDiscBase :=
              TempVATAmountLine.GetTotalInvDiscBaseAmount(
                ServHeader."Prices Including VAT", ServHeader."Currency Code");
            ChargeBase :=
              TempVATAmountLine.GetTotalLineAmount(
                ServHeader."Prices Including VAT", ServHeader."Currency Code");

            if not TemporaryHeader then
                ServHeader.Modify();

            if ("Document Type" in ["Document Type"::Quote]) and
               (ServHeader."Posting Date" = 0D)
            then
                CurrencyDate := WorkDate
            else
                CurrencyDate := ServHeader."Posting Date";

            CustInvDisc.GetRec(
              ServHeader."Invoice Disc. Code", ServHeader."Currency Code", CurrencyDate, ChargeBase);

            if ApplyServiceCharge then
                if CustInvDisc."Service Charge" <> 0 then begin
                    Currency.Initialize(ServHeader."Currency Code");
                    if TemporaryHeader then
                        ServiceLine2.SetServHeader(ServHeader);
                    if ServiceChargeLineNo <> 0 then begin
                        ServiceLine2.Get("Document Type", "Document No.", ServiceChargeLineNo);
                        if ServHeader."Prices Including VAT" then
                            ServiceLine2.Validate(
                              "Unit Price",
                              Round(
                                (1 + ServiceLine2."VAT %" / 100) * CustInvDisc."Service Charge",
                                Currency."Unit-Amount Rounding Precision"))
                        else
                            ServiceLine2.Validate("Unit Price", CustInvDisc."Service Charge");
                        ServiceLine2.Modify();
                    end else begin
                        ServiceLine2.Reset();
                        ServiceLine2.SetRange("Document Type", "Document Type");
                        ServiceLine2.SetRange("Document No.", "Document No.");
                        ServiceLine2.Find('+');
                        ServiceLine2.Init();
                        if TemporaryHeader then
                            ServiceLine2.SetServHeader(ServHeader);
                        ServiceLine2."Line No." := ServiceLine2."Line No." + GetNewServiceLineNoBias(ServiceLine2);
                        ServiceLine2.Type := ServiceLine2.Type::"G/L Account";
                        ServiceLine2.Validate("No.", CustPostingGr.GetServiceChargeAccount);
                        ServiceLine2.Description := Text000;
                        ServiceLine2.Validate(Quantity, 1);
                        if ServHeader."Prices Including VAT" then
                            ServiceLine2.Validate(
                              "Unit Price",
                              Round(
                                (1 + ServiceLine2."VAT %" / 100) * CustInvDisc."Service Charge",
                                Currency."Unit-Amount Rounding Precision"))
                        else
                            ServiceLine2.Validate("Unit Price", CustInvDisc."Service Charge");
                        ServiceLine2."System-Created Entry" := true;
                        ServiceLine2.Insert();
                    end;
                    ServiceLine2.CalcVATAmountLines(0, ServHeader, ServiceLine2, TempVATAmountLine, false);
                end else
                    if ServiceChargeLineNo <> 0 then begin
                        ServiceLine2.Get("Document Type", "Document No.", ServiceChargeLineNo);
                        ServiceLine2.Delete(true);
                    end;

            if CustInvDiscRecExists(ServHeader."Invoice Disc. Code") then begin
                if InvDiscBase <> ChargeBase then
                    CustInvDisc.GetRec(
                      ServHeader."Invoice Disc. Code", ServHeader."Currency Code", CurrencyDate, InvDiscBase);

                DiscountNotificationMgt.NotifyAboutMissingSetup(
                  SalesSetup.RecordId, ServHeader."Gen. Bus. Posting Group",
                  SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Line Discounts");

                ServHeader."Invoice Discount Calculation" := ServHeader."Invoice Discount Calculation"::"%";
                ServHeader."Invoice Discount Value" := CustInvDisc."Discount %";
                if not TemporaryHeader then
                    ServHeader.Modify();

                TempVATAmountLine.SetInvoiceDiscountPercent(
                  CustInvDisc."Discount %", ServHeader."Currency Code",
                  ServHeader."Prices Including VAT", SalesSetup."Calc. Inv. Disc. per VAT ID",
                  ServHeader."VAT Base Discount %");

                ServiceLine2.SetServHeader(ServHeader);
                ServiceLine2.UpdateVATOnLines(0, ServHeader, ServiceLine2, TempVATAmountLine);
            end;
        end;

        OnAfterCalcServDiscount(ServHeader);
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst);
    end;

    procedure CalculateWithServHeader(var TempServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line")
    begin
        TemporaryHeader := true;
        if ServiceLine.Get(TempServiceLine."Document Type", TempServiceLine."Document No.", TempServiceLine."Line No.") then
            CalculateInvoiceDiscount(TempServHeader, ServiceLine, TempServiceLine);
    end;

    procedure CalculateIncDiscForHeader(var TempServiceHeader: Record "Service Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        SalesSetup.Get();
        if not SalesSetup."Calc. Inv. Discount" then
            exit;
        with TempServiceHeader do begin
            ServiceLine2."Document Type" := "Document Type";
            ServiceLine2."Document No." := "No.";
            ServiceLine.Copy(ServiceLine2);
            CalculateInvoiceDiscount(TempServiceHeader, ServiceLine2, ServiceLine);
        end;
    end;

    local procedure GetNewServiceLineNoBias(ServiceLineParam: Record "Service Line"): Integer
    var
        ServLin: Record "Service Line";
        LineAdd: Integer;
    begin
        LineAdd := 10000;
        while ServLin.Get(ServiceLineParam."Document Type", ServiceLineParam."Document No.", ServiceLineParam."Line No." + LineAdd) and
              (LineAdd > 1)
        do
            LineAdd := Round(LineAdd / 2, 1, '<');
        exit(LineAdd);
    end;

    local procedure IsServiceChargeUpdated(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLine1: Record "Service Line";
    begin
        with ServiceLine do begin
            ServiceLine1.Reset();
            ServiceLine1.SetRange("Document Type", "Document Type");
            ServiceLine1.SetRange("Document No.", "Document No.");
            ServiceLine1.SetRange("System-Created Entry", true);
            ServiceLine1.SetRange(Type, ServiceLine1.Type::"G/L Account");
            ServiceLine1.SetRange("No.", CustPostingGr."Service Charge Acc.");
            exit(ServiceLine1.FindLast);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcServDiscount(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServDiscount(var ServiceHeader: Record "Service Header")
    begin
    end;
}

