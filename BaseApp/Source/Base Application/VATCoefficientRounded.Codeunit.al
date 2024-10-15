codeunit 31095 "VAT Coefficient Rounded"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of VAT Coefficient will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";

    procedure RoundSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        with SalesLine do begin
            if ("VAT Calculation Type" <> "VAT Calculation Type"::"Normal VAT") or
               ("VAT %" = 0) or not SalesHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount := RoundAmount("Amount Including VAT", "VAT %", SalesHeader."VAT Base Discount %", "VAT Difference", SalesHeader."Currency Code");
        end;
    end;

    procedure RoundSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        with SalesInvoiceLine do begin
            if ("VAT Calculation Type" <> "VAT Calculation Type"::"Normal VAT") or
               ("VAT %" = 0) or not SalesInvoiceHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount :=
              RoundAmount("Amount Including VAT", "VAT %", SalesInvoiceHeader."VAT Base Discount %", "VAT Difference", SalesInvoiceHeader."Currency Code");
        end;
    end;

    procedure RoundSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        with SalesCrMemoLine do begin
            if ("VAT Calculation Type" <> "VAT Calculation Type"::"Normal VAT") or
               ("VAT %" = 0) or not SalesCrMemoHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount :=
              RoundAmount("Amount Including VAT", "VAT %", SalesCrMemoHeader."VAT Base Discount %", "VAT Difference", SalesCrMemoHeader."Currency Code");
        end;
    end;

    procedure RoundPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        with PurchaseLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not PurchaseHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount := RoundAmount("Amount Including VAT", "VAT %", PurchaseHeader."VAT Base Discount %", "VAT Difference", PurchaseHeader."Currency Code");
            "Ext. Amount (LCY)" :=
              RoundAmount("Ext.Amount Including VAT (LCY)", "VAT %", PurchaseHeader."VAT Base Discount %", "Ext. VAT Difference (LCY)", PurchaseHeader."Currency Code");
        end;
    end;

    procedure RoundPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        with PurchInvLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not PurchInvHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount := RoundAmount("Amount Including VAT", "VAT %", PurchInvHeader."VAT Base Discount %", "VAT Difference", PurchInvHeader."Currency Code");
            "Ext. Amount (LCY)" :=
              RoundAmount("Ext.Amount Including VAT (LCY)", "VAT %", PurchInvHeader."VAT Base Discount %", "Ext. VAT Difference (LCY)", PurchInvHeader."Currency Code");
        end;
    end;

    procedure RoundPurchaseCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        with PurchCrMemoLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not PurchCrMemoHdr."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount := RoundAmount("Amount Including VAT", "VAT %", PurchCrMemoHdr."VAT Base Discount %", "VAT Difference", PurchCrMemoHdr."Currency Code");
        end;
    end;

    procedure RoundServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        with ServiceLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not ServiceHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount := RoundAmount("Amount Including VAT", "VAT %", ServiceHeader."VAT Base Discount %", "VAT Difference", ServiceHeader."Currency Code");
        end;
    end;

    procedure RoundServiceInvoiceLine(var ServiceInvoiceLine: Record "Service Invoice Line"; ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        with ServiceInvoiceLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not ServiceInvoiceHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount :=
              RoundAmount("Amount Including VAT", "VAT %", ServiceInvoiceHeader."VAT Base Discount %", "VAT Difference", ServiceInvoiceHeader."Currency Code");
        end;
    end;

    procedure RoundServiceCrMemoLine(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceCrMemoLine do begin
            if (not ("VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])) or
               ("VAT %" = 0) or not ServiceCrMemoHeader."Prices Including VAT"
            then
                exit;

            if not IsRoundVATCoeffEnabled() then
                exit;

            Amount :=
              RoundAmount("Amount Including VAT", "VAT %", ServiceCrMemoHeader."VAT Base Discount %", "VAT Difference", ServiceCrMemoHeader."Currency Code");
        end;
    end;

    local procedure RoundAmount(AmountIncludingVAT: Decimal; VATPerc: Decimal; VATBaseDiscountPerc: Decimal; VATDifference: Decimal; CurrencyCode: Code[10]): Decimal
    var
        RoundingPrecision: Decimal;
        RoundingDirection: Text[1];
    begin
        GetCurrency(CurrencyCode);

        GLSetup.Get();
        GLSetup.GetRoundingParamenters(Currency, RoundingPrecision, RoundingDirection);
        GLSetup.TestField("VAT Coeff. Rounding Precision");
        exit(
          AmountIncludingVAT -
          Round(
            AmountIncludingVAT * Round(VATPerc / (100 + VATPerc), GLSetup."VAT Coeff. Rounding Precision") *
            (1 - VATBaseDiscountPerc / 100), RoundingPrecision, RoundingDirection) - VATDifference);
    end;

    local procedure IsRoundVATCoeffEnabled(): Boolean
    begin
        GLSetup.Get();
        exit(GLSetup."Round VAT Coeff.");
    end;

    local procedure GetCurrency(CurrencyCode: Code[10])
    begin
        Currency.Initialize(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnRoundAmountOnBeforeIncrAmount', '', false, false)]
    local procedure RoundSalesLineOnRoundAmountOnBeforeIncrAmount(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineQty: Decimal; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
        RoundSalesLine(SalesLine, SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnRoundAmountOnBeforeIncrAmount', '', false, false)]
    local procedure RoundPurchaseLineOnRoundAmountOnBeforeIncrAmount(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchLineQty: Decimal; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
        RoundPurchaseLine(PurchaseLine, PurchaseHeader);
    end;
}

