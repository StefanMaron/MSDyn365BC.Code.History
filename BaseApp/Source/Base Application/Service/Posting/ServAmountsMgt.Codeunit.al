﻿namespace Microsoft.Service.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
#if not CLEAN23
using Microsoft.Finance.ReceivablesPayables;
#endif
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
#if not CLEAN23
using Microsoft.Service.Pricing;
using System.Environment.Configuration;
#endif

codeunit 5986 "Serv-Amounts Mgt."
{
    Permissions = TableData "General Posting Setup" = rimd,
#if not CLEAN23
                  TableData "Invoice Post. Buffer" = rimd,
#endif
                  TableData "VAT Amount Line" = rimd,
                  TableData "Dimension Buffer" = rimd,
                  TableData "Service Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        UOMMgt: Codeunit "Unit of Measure Management";
#if not CLEAN23
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        FALineNo: Integer;
#endif
        RoundingLineNo: Integer;
        Text016: Label 'VAT Amount';
        Text017: Label '%1% VAT';
        RoundingLineIsInserted: Boolean;
        IsInitialized: Boolean;
        SuppressCommit: Boolean;

    procedure Initialize(CurrencyCode: Code[10])
    begin
        RoundingLineIsInserted := false;
        GetCurrency(CurrencyCode, Currency);
        SalesSetup.Get();
        IsInitialized := true;
    end;

    procedure GetDimensions(DimensionEntryNo: Integer; var TempDimBuf: Record "Dimension Buffer")
    begin
        DimBufMgt.GetDimensions(DimensionEntryNo, TempDimBuf);
    end;

    procedure Finalize()
    begin
        IsInitialized := false;
    end;

#if not CLEAN23
    [Obsolete('Replaced by FillInvoicePostBuffer().', '19.0')]
    procedure FillInvPostingBuffer(var InvPostingBuffer: array[2] of Record "Invoice Post. Buffer" temporary; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillInvPostingBuffer(InvPostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        FillInvoicePostBuffer(InvPostingBuffer[2], ServiceLine, ServiceLineACY, ServiceHeader);
    end;
#endif

#pragma warning disable AS0072
#if not CLEAN23 
    [Obsolete('Replaced by new implementation in ServicePostInvoice codeunit', '20.0')]
    procedure FillInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        ServCost: Record "Service Cost";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillInvoicePostBuffer(TempInvoicePostBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            if (ServiceLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
               (ServiceLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
            then
                GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");

        InvoicePostBuffer.PrepareService(ServiceLine);

        TotalVAT := ServiceLine."Amount Including VAT" - ServiceLine.Amount;
        TotalVATACY := ServiceLineACY."Amount Including VAT" - ServiceLineACY.Amount;
        TotalAmount := ServiceLine.Amount;
        TotalAmountACY := ServiceLineACY.Amount;
        TotalVATBase := ServiceLine."VAT Base Amount";
        TotalVATBaseACY := ServiceLineACY."VAT Base Amount";

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            InvPostingBufferCalcInvoiceDiscountAmount(InvoicePostBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostBuffer.SetAccount(
                  GenPostingSetup.GetSalesInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                if ServiceLine."Line Discount %" = 100 then begin
                    InvoicePostBuffer."VAT Base Amount" := 0;
                    InvoicePostBuffer."VAT Base Amount (ACY)" := 0;
                    InvoicePostBuffer."VAT Amount" := 0;
                    InvoicePostBuffer."VAT Amount (ACY)" := 0;
                end;
                UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, ServiceLine);
            end;
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            InvPostingBufferCalcLineDiscountAmount(InvoicePostBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostBuffer.Amount <> 0) or (InvoicePostBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostBuffer.SetAccount(
                  GenPostingSetup.GetSalesLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, ServiceLine);
            end;
        end;

        InvoicePostBuffer.SetAmounts(
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, ServiceLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        case ServiceLine.Type of
            ServiceLine.Type::"G/L Account":
                InvoicePostBuffer.SetAccount(ServiceLine."No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            ServiceLine.Type::Cost:
                begin
                    ServCost.Get(ServiceLine."No.");
                    InvoicePostBuffer.SetAccount(ServCost."Account No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                end
            else
                if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetSalesCrMemoAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY)
                else
                    InvoicePostBuffer.SetAccount(
                      GenPostingSetup.GetSalesAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        end;
        InvoicePostBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);

        OnAfterFillInvoicePostBuffer(InvoicePostBuffer, ServiceLine, TempInvoicePostBuffer, SuppressCommit, ServiceLineACY);

        UpdateInvoicePostBuffer(TempInvoicePostBuffer, InvoicePostBuffer, ServiceLine);

        OnAfterFillInvoicePostBufferProcedure(InvoicePostBuffer, ServiceLine, TempInvoicePostBuffer, SuppressCommit, ServiceLineACY);
    end;
#pragma warning restore AS0072

    local procedure InvPostingBufferCalcInvoiceDiscountAmount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInvPostingBufferCalcInvoiceDiscountAmount(InvoicePostBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(
              -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount");
    end;

    local procedure InvPostingBufferCalcLineDiscountAmount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInvPostingBufferCalcLineDiscountAmount(InvoicePostBuffer, ServiceLine, ServiceLineACY, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostBuffer.CalcDiscountNoVAT(
              -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount")
        else
            InvoicePostBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount");
    end;

    local procedure UpdateInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceLine: Record "Service Line")
    begin
        InvoicePostBuffer."Dimension Set ID" := ServiceLine."Dimension Set ID";
        if InvoicePostBuffer.Type = InvoicePostBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostBuffer."Fixed Asset Line No." := FALineNo;
        end;
        InvoicePostBuffer.FillInvPostingBufferPrimaryKey();

        OnBeforeUpdateInvPostBuffer(InvoicePostBuffer);

        TempInvoicePostBuffer.Update(InvoicePostBuffer);

        OnAfterUpdateInvPostBuffer(InvoicePostBuffer, TempInvoicePostBuffer);
    end;
#endif

    procedure DivideAmount(QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempVATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line")
    var
        ChargeableQty: Decimal;
        LineAmountExpected: Decimal;
        LineDiscountAmountExpected: Decimal;
    begin
        if RoundingLineInserted() and (RoundingLineNo = ServiceLine."Line No.") then
            exit;

        OnBeforeDivideAmount(ServiceHeader, ServiceLine, QtyType, ServLineQty, TempVATAmountLine, TempVATAmountLineRemainder);

        if ServLineQty = 0 then begin
            ServiceLine."Line Amount" := 0;
            ServiceLine."Line Discount Amount" := 0;
            ServiceLine."Inv. Discount Amount" := 0;
            ServiceLine."VAT Base Amount" := 0;
            ServiceLine.Amount := 0;
            ServiceLine."Amount Including VAT" := 0;
        end else begin
            if TempVATAmountLine.Get(ServiceLine."VAT Identifier", ServiceLine."VAT Calculation Type", ServiceLine."Tax Group Code", false, ServiceLine."Line Amount" >= 0) then;
            if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Sales Tax" then
                ServiceLine."VAT %" := TempVATAmountLine."VAT %";
            TempVATAmountLineRemainder := TempVATAmountLine;
            if not TempVATAmountLineRemainder.Find() then begin
                TempVATAmountLineRemainder.Init();
                TempVATAmountLineRemainder.Insert();
            end;

            case QtyType of
                QtyType::Shipping:
                    if (ServiceLine."Qty. to Consume" <> 0) or (ServLineQty <= ServiceLine.MaxQtyToInvoice()) then
                        ChargeableQty := ServLineQty
                    else
                        ChargeableQty := ServiceLine.MaxQtyToInvoice();
                QtyType::Invoicing:
                    ChargeableQty := ServLineQty;
                else
                    ChargeableQty := ServiceLine.CalcChargeableQty();
            end;

            LineAmountExpected := Round(ChargeableQty * ServiceLine."Unit Price", Currency."Amount Rounding Precision");
            OnDivideAmountOnAfterCalcLineAmountExpected(ServiceLine, ChargeableQty, LineAmountExpected);
            if AmountsDifferByMoreThanRoundingPrecision(LineAmountExpected, ServiceLine."Line Amount", Currency."Amount Rounding Precision") then
                ServiceLine."Line Amount" := LineAmountExpected;

            if ServLineQty <> ServiceLine.Quantity then begin
                LineDiscountAmountExpected := Round(ServiceLine."Line Amount" * ServiceLine."Line Discount %" / 100, Currency."Amount Rounding Precision");
                if AmountsDifferByMoreThanRoundingPrecision(LineDiscountAmountExpected, ServiceLine."Line Discount Amount", Currency."Amount Rounding Precision") then
                    ServiceLine."Line Discount Amount" := LineDiscountAmountExpected;
            end;

            ServiceLine."Line Amount" := ServiceLine."Line Amount" - ServiceLine."Line Discount Amount";

            if ServiceLine."Allow Invoice Disc." and (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) then
                if QtyType = QtyType::Invoicing then
                    ServiceLine."Inv. Discount Amount" := ServiceLine."Inv. Disc. Amount to Invoice"
                else begin
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" +
                      TempVATAmountLine."Invoice Discount Amount" * ServiceLine."Line Amount" /
                      TempVATAmountLine."Inv. Disc. Base Amount";
                    ServiceLine."Inv. Discount Amount" :=
                      Round(
                        TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                      TempVATAmountLineRemainder."Invoice Discount Amount" - ServiceLine."Inv. Discount Amount";
                end;

            if ServiceHeader."Prices Including VAT" then begin
                if (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount" = 0) or
                   (ServiceLine."Line Amount" = 0)
                then begin
                    TempVATAmountLineRemainder."VAT Amount" := 0;
                    TempVATAmountLineRemainder."Amount Including VAT" := 0;
                end else begin
                    TempVATAmountLineRemainder."VAT Amount" +=
                      TempVATAmountLine."VAT Amount" * ServiceLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                    TempVATAmountLineRemainder."Amount Including VAT" +=
                      TempVATAmountLine."Amount Including VAT" * ServiceLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                end;
                if ServiceLine."Line Discount %" <> 100 then
                    ServiceLine."Amount Including VAT" :=
                      Round(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision")
                else
                    ServiceLine."Amount Including VAT" := 0;
                ServiceLine.Amount :=
                  Round(ServiceLine."Amount Including VAT", Currency."Amount Rounding Precision") -
                  Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                ServiceLine."VAT Base Amount" :=
                  Round(
                    ServiceLine.Amount * (1 - ServiceHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                TempVATAmountLineRemainder."Amount Including VAT" :=
                  TempVATAmountLineRemainder."Amount Including VAT" - ServiceLine."Amount Including VAT";
                TempVATAmountLineRemainder."VAT Amount" :=
                  TempVATAmountLineRemainder."VAT Amount" - ServiceLine."Amount Including VAT" + ServiceLine.Amount;
            end else
                if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Full VAT" then begin
                    if ServiceLine."Line Discount %" <> 100 then
                        ServiceLine."Amount Including VAT" := ServiceLine.CalcLineAmount()
                    else
                        ServiceLine."Amount Including VAT" := 0;
                    ServiceLine.Amount := 0;
                    ServiceLine."VAT Base Amount" := 0;
                end else begin
                    ServiceLine.Amount := ServiceLine.CalcLineAmount();
                    ServiceLine."VAT Base Amount" :=
                      Round(
                        ServiceLine.Amount * (1 - ServiceHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                    if TempVATAmountLine."VAT Base" = 0 then
                        TempVATAmountLineRemainder."VAT Amount" := 0
                    else
                        TempVATAmountLineRemainder."VAT Amount" +=
                          TempVATAmountLine."VAT Amount" * ServiceLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
                    if ServiceLine."Line Discount %" <> 100 then
                        ServiceLine."Amount Including VAT" :=
                          ServiceLine.Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision")
                    else
                        ServiceLine."Amount Including VAT" := 0;
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - ServiceLine."Amount Including VAT" + ServiceLine.Amount;
                end;

            TempVATAmountLineRemainder.Modify();
        end;

        OnAfterDivideAmount(ServiceHeader, ServiceLine, QtyType, ServLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    procedure RoundAmount(ServLineQty: Decimal; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; var ServiceLineACY: Record "Service Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        NoVAT: Boolean;
        UseDate: Date;
    begin
        OnBeforeRoundAmount(ServiceHeader, ServiceLine, ServLineQty);

        IncrAmount(ServiceLine, TotalServiceLine, ServiceHeader."Prices Including VAT");
        Increment(TotalServiceLine."Net Weight", Round(ServLineQty * ServiceLine."Net Weight", UOMMgt.WeightRndPrecision()));
        Increment(TotalServiceLine."Gross Weight", Round(ServLineQty * ServiceLine."Gross Weight", UOMMgt.WeightRndPrecision()));
        Increment(TotalServiceLine."Unit Volume", Round(ServLineQty * ServiceLine."Unit Volume", UOMMgt.CubageRndPrecision()));
        Increment(TotalServiceLine.Quantity, ServLineQty);
        if ServiceLine."Units per Parcel" > 0 then
            Increment(
              TotalServiceLine."Units per Parcel",
              Round(ServLineQty / ServiceLine."Units per Parcel", 1, '>'));

        TempServiceLine := ServiceLine;
        ServiceLineACY := ServiceLine;

        if ServiceHeader."Currency Code" <> '' then begin
            if (ServiceLine."Document Type" in [ServiceLine."Document Type"::Quote]) and
               (ServiceHeader."Posting Date" = 0D)
            then
                UseDate := WorkDate()
            else
                UseDate := ServiceHeader."Posting Date";

            NoVAT := ServiceLine.Amount = ServiceLine."Amount Including VAT";
            ServiceLine."Amount Including VAT" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."Amount Including VAT", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."Amount Including VAT";
            if NoVAT then
                ServiceLine.Amount := ServiceLine."Amount Including VAT"
            else
                ServiceLine.Amount :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine.Amount, ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY.Amount;
            ServiceLine."Line Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."Line Amount", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."Line Amount";
            ServiceLine."Line Discount Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."Line Discount Amount", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."Line Discount Amount";
            ServiceLine."Inv. Discount Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."Inv. Discount Amount", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."Inv. Discount Amount";
            ServiceLine."VAT Difference" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."VAT Difference", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."VAT Difference";
        end;
        ServiceLine."VAT Base Amount" :=
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              UseDate, ServiceHeader."Currency Code",
              TotalServiceLine."VAT Base Amount", ServiceHeader."Currency Factor")) -
          TotalServiceLineLCY."VAT Base Amount";

        OnRoundAmountOnBeforeIncrAmount(ServiceLine, TotalServiceLine, TotalServiceLineLCY, UseDate, NoVAT);
        IncrAmount(ServiceLine, TotalServiceLineLCY, ServiceHeader."Prices Including VAT");
        Increment(TotalServiceLineLCY."Unit Cost (LCY)", Round(ServLineQty * ServiceLine."Unit Cost (LCY)"));
    end;

    procedure ReverseAmount(var ServiceLine: Record "Service Line")
    begin
        ServiceLine."Qty. to Ship" := -ServiceLine."Qty. to Ship";
        ServiceLine."Qty. to Ship (Base)" := -ServiceLine."Qty. to Ship (Base)";
        ServiceLine."Qty. to Invoice" := -ServiceLine."Qty. to Invoice";
        ServiceLine."Qty. to Invoice (Base)" := -ServiceLine."Qty. to Invoice (Base)";
        ServiceLine."Qty. to Consume" := -ServiceLine."Qty. to Consume";
        ServiceLine."Qty. to Consume (Base)" := -ServiceLine."Qty. to Consume (Base)";
        ServiceLine."Line Amount" := -ServiceLine."Line Amount";
        ServiceLine.Amount := -ServiceLine.Amount;
        ServiceLine."VAT Base Amount" := -ServiceLine."VAT Base Amount";
        ServiceLine."VAT Difference" := -ServiceLine."VAT Difference";
        ServiceLine."Amount Including VAT" := -ServiceLine."Amount Including VAT";
        ServiceLine."Line Discount Amount" := -ServiceLine."Line Discount Amount";
        ServiceLine."Inv. Discount Amount" := -ServiceLine."Inv. Discount Amount";

        OnAfterReverseAmount(ServiceLine);
    end;

    procedure InvoiceRounding(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var LastLineRetrieved: Boolean; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        TempServiceLineForCalc: Record "Service Line" temporary;
        RoundingServiceLine: Record "Service Line";
        CustPostingGr: Record "Customer Posting Group";
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalServiceLine."Amount Including VAT" -
            Round(
              TotalServiceLine."Amount Including VAT",
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection()),
            Currency."Amount Rounding Precision");

        OnBeforeInvoiceRoundingAmount(
          ServiceHeader, TotalServiceLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit);
        if InvoiceRoundingAmount <> 0 then begin
            CustPostingGr.Get(ServiceHeader."Customer Posting Group");
            ServiceLine.Init();
            BiggestLineNo += 10000;
            ServiceLine."System-Created Entry" := true;
            OnInvoiceRoundingAmountOnBeforeCheckUseTempData(ServiceHeader, ServiceLine);
            if UseTempData then begin
                ServiceLine."Line No." := 0;
                ServiceLine.Type := ServiceLine.Type::"G/L Account";
                TempServiceLineForCalc := ServiceLine;
                TempServiceLineForCalc.Validate("No.", CustPostingGr.GetInvRoundingAccount());
                ServiceLine := TempServiceLineForCalc;
            end else begin
                ServiceLine."Line No." := BiggestLineNo;
                RoundingServiceLine := ServiceLine;
                RoundingServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
                RoundingServiceLine.Validate("No.", CustPostingGr.GetInvRoundingAccount());
                ServiceLine := RoundingServiceLine;
            end;
            OnInvoiceRoundingAmountOnAfterCheckUseTempData(ServiceHeader, ServiceLine);

            ServiceLine."Tax Area Code" := '';
            ServiceLine."Tax Liable" := false;
            ServiceLine.Validate(ServiceLine.Quantity, 1);
            if ServiceHeader."Prices Including VAT" then
                ServiceLine.Validate(ServiceLine."Unit Price", InvoiceRoundingAmount)
            else
                ServiceLine.Validate(
                  ServiceLine."Unit Price",
                  Round(
                    InvoiceRoundingAmount /
                    (1 + (1 - ServiceHeader."VAT Base Discount %" / 100) * ServiceLine."VAT %" / 100),
                    Currency."Amount Rounding Precision"));
            ServiceLine.Validate(ServiceLine."Amount Including VAT", InvoiceRoundingAmount);
            ServiceLine."Line No." := BiggestLineNo;

            LastLineRetrieved := false;
            RoundingLineIsInserted := true;
            RoundingLineNo := ServiceLine."Line No.";
        end;
    end;

    local procedure IncrAmount(ServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; PricesIncludingVAT: Boolean)
    begin
        if PricesIncludingVAT or
           (ServiceLine."VAT Calculation Type" <> ServiceLine."VAT Calculation Type"::"Full VAT")
        then
            Increment(TotalServiceLine."Line Amount", ServiceLine."Line Amount");
        Increment(TotalServiceLine.Amount, ServiceLine.Amount);
        Increment(TotalServiceLine."VAT Base Amount", ServiceLine."VAT Base Amount");
        Increment(TotalServiceLine."VAT Difference", ServiceLine."VAT Difference");
        Increment(TotalServiceLine."Amount Including VAT", ServiceLine."Amount Including VAT");
        Increment(TotalServiceLine."Line Discount Amount", ServiceLine."Line Discount Amount");
        Increment(TotalServiceLine."Inv. Discount Amount", ServiceLine."Inv. Discount Amount");
        Increment(TotalServiceLine."Inv. Disc. Amount to Invoice", ServiceLine."Inv. Disc. Amount to Invoice");

        OnAfterIncrAmount(TotalServiceLine, ServiceLine);
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure RoundingLineInserted(): Boolean
    begin
        exit(RoundingLineIsInserted);
    end;

    procedure GetRoundingLineNo(): Integer
    begin
        exit(RoundingLineNo);
    end;

    procedure SumServiceLines(var NewServHeader: Record "Service Header"; QtyType: Option General,Invoicing,Shipping,Consuming; var NewTotalServLine: Record "Service Line"; var NewTotalServLineLCY: Record "Service Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        OldServLine: Record "Service Line";
    begin
        SumServiceLinesTemp(
          NewServHeader, OldServLine, QtyType, NewTotalServLine, NewTotalServLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    procedure SumServiceLinesTemp(var NewServHeader: Record "Service Header"; var OldServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming; var NewTotalServLine: Record "Service Line"; var NewTotalServLineLCY: Record "Service Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        TempServiceLine: Record "Service Line";
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ServiceLineACY: Record "Service Line";
    begin
        if not IsInitialized then
            Initialize(NewServHeader."Currency Code");

        ServHeader := NewServHeader;
        SumServiceLines2(ServHeader, ServLine, OldServLine, TempServiceLine,
          TotalServiceLine, TotalServiceLineLCY, ServiceLineACY, QtyType, false, true, TotalAdjCostLCY);

        if (QtyType = QtyType::Shipping) and (OldServLine."Qty. to Consume" <> 0) then begin
            TotalServiceLineLCY.Amount := 0;
            TotalServiceLine."Amount Including VAT" := 0;
            ProfitLCY := 0;
            VATAmount := 0;
        end else begin
            ProfitLCY := TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)";
            VATAmount := TotalServiceLine."Amount Including VAT" - TotalServiceLine.Amount;
        end;

        if TotalServiceLineLCY.Amount = 0 then
            ProfitPct := 0
        else
            ProfitPct := Round(ProfitLCY / TotalServiceLineLCY.Amount * 100, 0.1);
        if TotalServiceLine."VAT %" = 0 then
            VATAmountText := Text016
        else
            VATAmountText := StrSubstNo(Text017, TotalServiceLine."VAT %");
        NewTotalServLine := TotalServiceLine;
        NewTotalServLineLCY := TotalServiceLineLCY;
    end;

    local procedure SumServiceLines2(var ServHeader: Record "Service Header"; var NewServLine: Record "Service Line"; var OldServLine: Record "Service Line"; var TempServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; var ServiceLineACY: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts; InsertServLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal)
    var
        ServLine: Record "Service Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ServLineQty: Decimal;
        LastLineRetrieved: Boolean;
        AdjCostLCY: Decimal;
        BiggestLineNo: Integer;
        IsHandled: Boolean;
    begin
        TotalAdjCostLCY := 0;
        if not IsInitialized then
            Initialize(ServHeader."Currency Code");
        TempVATAmountLineRemainder.DeleteAll();
        OldServLine.CalcVATAmountLines(QtyType, ServHeader, OldServLine, TempVATAmountLine, false);
        GLSetup.Get();
        SalesSetup.Get();
        GetCurrency(ServHeader."Currency Code", Currency);
        OldServLine.SetRange("Document Type", ServHeader."Document Type");
        OldServLine.SetRange("Document No.", ServHeader."No.");

        IsHandled := false;
        OnSumServiceLines2OnBeforeSetTypeFilters(OldServLine, ServHeader, QtyType, IsHandled);
        if not IsHandled then
            case QtyType of
                QtyType::ServLineItems:
                    OldServLine.SetRange(Type, OldServLine.Type::Item);
                QtyType::ServLineResources:
                    OldServLine.SetRange(Type, OldServLine.Type::Resource);
                QtyType::ServLineCosts:
                    OldServLine.SetFilter(Type, '%1|%2', OldServLine.Type::Cost, OldServLine.Type::"G/L Account");
            end;

        RoundingLineIsInserted := false;
        if OldServLine.Find('-') then
            repeat
                if not RoundingLineInserted() then
                    ServLine := OldServLine;
                case QtyType of
                    QtyType::Invoicing:
                        ServLineQty := ServLine."Qty. to Invoice";
                    QtyType::Consuming:
                        begin
                            ServLineQty := ServLine."Qty. to Consume";
                            ServLine."Unit Price" := 0;
                            ServLine."Inv. Discount Amount" := 0;
                        end;
                    QtyType::Shipping:
                        begin
                            if ServHeader."Document Type" = ServHeader."Document Type"::"Credit Memo" then
                                ServLineQty := ServLine.Quantity
                            else
                                ServLineQty := ServLine."Qty. to Ship";
                            if OldServLine."Qty. to Consume" <> 0 then begin
                                ServLine."Unit Price" := 0;
                                ServLine."Inv. Discount Amount" := 0;
                                ServLine.Amount := 0;
                            end
                        end;
                    else
                        ServLineQty := ServLine.Quantity;
                end;

                DivideAmount(QtyType,
                  ServLineQty,
                  ServHeader,
                  ServLine,
                  TempVATAmountLine,
                  TempVATAmountLineRemainder);

                ServLine.Quantity := ServLineQty;
                if ServLineQty <> 0 then begin
                    if (ServLine.Amount <> 0) and not RoundingLineInserted() then
                        if TotalServiceLine.Amount = 0 then
                            TotalServiceLine."VAT %" := ServLine."VAT %"
                        else
                            if TotalServiceLine."VAT %" <> ServLine."VAT %" then
                                TotalServiceLine."VAT %" := 0;
                    RoundAmount(ServLineQty, ServHeader, ServLine, TempServiceLine,
                      TotalServiceLine, TotalServiceLineLCY, ServiceLineACY);

                    if not (QtyType in [QtyType::Shipping]) and
                       not InsertServLine and CalcAdCostLCY
                    then begin
                        AdjCostLCY := CostCalcMgt.CalcServLineCostLCY(ServLine, QtyType);
                        TotalAdjCostLCY := TotalAdjCostLCY + GetServLineAdjCostLCY(ServLine, QtyType, AdjCostLCY);
                    end;

                    ServLine := TempServiceLine;
                end;
                if InsertServLine then begin
                    NewServLine := ServLine;
                    if NewServLine.Insert() then;
                end;
                IsHandled := false;
                OnSumServiceLines2OnBeforeInvoiceRounding(ServHeader, ServLine, OldServLine, TotalServiceLine, QtyType, LastLineRetrieved, IsHandled);
                if not IsHandled then
                    if RoundingLineInserted() then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := MAX(BiggestLineNo, OldServLine."Line No.");
                        LastLineRetrieved := OldServLine.Next() = 0;
                        if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                            InvoiceRounding(ServHeader, ServLine, TotalServiceLine,
                              LastLineRetrieved, true, BiggestLineNo);
                    end;
            until LastLineRetrieved;
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]; var Currency2: Record Currency)
    begin
        if CurrencyCode = '' then
            Currency2.InitRoundingPrecision()
        else begin
            Currency2.Get(CurrencyCode);
            Currency2.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetServiceLines(var NewServiceHeader: Record "Service Header"; var NewServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming)
    var
        OldServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line";
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ServiceLineACY: Record "Service Line";
        TotalAdjCostLCY: Decimal;
    begin
        if not IsInitialized then
            Initialize(NewServiceHeader."Currency Code");

        SumServiceLines2(NewServiceHeader, NewServiceLine,
          OldServiceLine, TempServiceLine, TotalServiceLine, TotalServiceLineLCY, ServiceLineACY,
          QtyType, true, false, TotalAdjCostLCY);
    end;

    procedure "MAX"(number1: Integer; number2: Integer): Integer
    begin
        if number1 > number2 then
            exit(number1);
        exit(number2);
    end;

    local procedure GetServLineAdjCostLCY(ServLine2: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts; AdjCostLCY: Decimal): Decimal
    begin
        if ServLine2."Document Type" in [ServLine2."Document Type"::Order, ServLine2."Document Type"::Invoice] then
            AdjCostLCY := -AdjCostLCY;

        case true of
            ServLine2."Shipment No." <> '':
                exit(AdjCostLCY);
            (QtyType = QtyType::General) or (QtyType = QtyType::ServLineItems) or
          (QtyType = QtyType::ServLineResources) or (QtyType = QtyType::ServLineCosts):
                exit(Round(ServLine2."Outstanding Quantity" * ServLine2."Unit Cost (LCY)") + AdjCostLCY);
            ServLine2."Document Type" in [ServLine2."Document Type"::Order, ServLine2."Document Type"::Invoice]:
                begin
                    if (ServLine2."Qty. to Invoice" > ServLine2."Qty. to Ship") or (ServLine2."Qty. to Consume" > 0) then
                        exit(Round(ServLine2."Qty. to Ship" * ServLine2."Unit Cost (LCY)") + AdjCostLCY);
                    exit(Round(ServLine2."Qty. to Invoice" * ServLine2."Unit Cost (LCY)"));
                end;
            ServLine2."Document Type" = ServLine2."Document Type"::"Credit Memo":
                exit(Round(ServLine2."Qty. to Invoice" * ServLine2."Unit Cost (LCY)"));
        end;
    end;

    procedure GetLastLineNo(ServLine: Record "Service Line"): Integer
    begin
        ServLine.SetRange("Document Type", ServLine."Document Type");
        ServLine.SetRange("Document No.", ServLine."Document No.");
        if ServLine.FindLast() then;
        exit(ServLine."Line No.");
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure AmountsDifferByMoreThanRoundingPrecision(Amount1: Decimal; Amount2: Decimal; RoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(Amount1 - Amount2)) > RoundingPrecision);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDivideAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceLine: Record "Service Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; SuppressCommit: Boolean; ServiceLineACY: Record "Service Line")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBufferProcedure(var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceLine: Record "Service Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; SuppressCommit: Boolean; ServiceLineACY: Record "Service Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmount(var TotalServiceLine: Record "Service Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseAmount(var ServiceLine: Record "Service Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvPostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by event OnBeforeFillInvoicePostBuffer().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvPostingBuffer(var InvPostingBuffer: array[2] of Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDivideAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceRoundingAmount(var ServiceHeader: Record "Service Header"; var AmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostingBufferCalcInvoiceDiscountAmount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostingBufferCalcLineDiscountAmount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServLineQty: Decimal)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by new implementation event in codeunit ServicePostInvoice', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvPostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnDivideAmountOnAfterCalcLineAmountExpected(var ServiceLine: Record "Service Line"; var ChargeableQty: Decimal; var LineAmountExpected: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(var ServiceLine: Record "Service Line"; TotalServiceLine: Record "Service Line"; TotalServiceLineLCY: Record "Service Line"; UseDate: Date; NoVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumServiceLines2OnBeforeSetTypeFilters(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; QtyType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvoiceRoundingAmountOnBeforeCheckUseTempData(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvoiceRoundingAmountOnAfterCheckUseTempData(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumServiceLines2OnBeforeInvoiceRounding(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts; var LastLineRetrieved: Boolean; var IsHandled: Boolean)
    begin
    end;
}

