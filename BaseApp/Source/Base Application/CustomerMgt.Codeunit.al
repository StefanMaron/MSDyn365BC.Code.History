codeunit 1302 "Customer Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        FiscalYearTotals: Boolean;

    procedure AvgDaysToPay(CustNo: Code[20]): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        AvgDaysToPay: Decimal;
        TotalDaysToPay: Decimal;
        TotalNoOfInv: Integer;
    begin
        with CustLedgEntry do begin
            AvgDaysToPay := 0;
            SetCurrentKey("Customer No.", "Posting Date");
            SetFilterForPostedDocs(CustLedgEntry, CustNo, "Document Type"::Invoice);
            SetRange(Open, false);

            if FindSet() then
                repeat
                    case true of
                        "Closed at Date" > "Posting Date":
                            UpdateDaysToPay("Closed at Date" - "Posting Date", TotalDaysToPay, TotalNoOfInv);
                        "Closed by Entry No." <> 0:
                            if CustLedgEntry2.Get("Closed by Entry No.") then
                                UpdateDaysToPay(CustLedgEntry2."Posting Date" - "Posting Date", TotalDaysToPay, TotalNoOfInv);
                        else begin
                                CustLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                CustLedgEntry2.SetRange("Closed by Entry No.", "Entry No.");
                                if CustLedgEntry2.FindFirst() then
                                    UpdateDaysToPay(CustLedgEntry2."Posting Date" - "Posting Date", TotalDaysToPay, TotalNoOfInv);
                            end;
                    end;
                until Next() = 0;
        end;

        if TotalNoOfInv <> 0 then
            AvgDaysToPay := TotalDaysToPay / TotalNoOfInv;

        exit(AvgDaysToPay);
    end;

    local procedure UpdateDaysToPay(NoOfDays: Integer; var TotalDaysToPay: Decimal; var TotalNoOfInv: Integer)
    begin
        TotalDaysToPay += NoOfDays;
        TotalNoOfInv += 1;
    end;

    procedure CalculateStatistic(Customer: Record Customer; var AdjmtCostLCY: Decimal; var AdjCustProfit: Decimal; var AdjProfitPct: Decimal; var CustInvDiscAmountLCY: Decimal; var CustPaymentsLCY: Decimal; var CustSalesLCY: Decimal; var CustProfit: Decimal)
    begin
        Customer.SetFilter("Date Filter", GetCurrentYearFilter());
        Customer.CalcFields("Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Payments (LCY)");

        CalculateStatisticsWithCurrentCustomerValues(Customer, AdjmtCostLCY, AdjCustProfit, AdjProfitPct, CustInvDiscAmountLCY, CustPaymentsLCY, CustSalesLCY, CustProfit)
    end;

    procedure CalculateStatisticsWithCurrentCustomerValues(var Customer: Record Customer; var AdjmtCostLCY: Decimal; var AdjCustProfit: Decimal; var AdjProfitPct: Decimal; var CustInvDiscAmountLCY: Decimal; var CustPaymentsLCY: Decimal; var CustSalesLCY: Decimal; var CustProfit: Decimal)
    var
        CostCalcuMgt: Codeunit "Cost Calculation Management";
    begin
        // Costs (LCY):
        CustSalesLCY := Customer."Sales (LCY)";
        CustProfit := Customer."Profit (LCY)" + CostCalcuMgt.NonInvtblCostAmt(Customer);
        AdjmtCostLCY := CustSalesLCY - CustProfit + CostCalcuMgt.CalcCustActualCostLCY(Customer);
        AdjCustProfit := CustProfit + AdjmtCostLCY;

        // Profit %
        if Customer."Sales (LCY)" <> 0 then
            AdjProfitPct := Round(100 * AdjCustProfit / Customer."Sales (LCY)", 0.1)
        else
            AdjProfitPct := 0;

        CustInvDiscAmountLCY := Customer."Inv. Discounts (LCY)";

        CustPaymentsLCY := Customer."Payments (LCY)";
    end;

    procedure CalcAmountsOnPostedInvoices(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(CustNo, RecCount, CustLedgEntry."Document Type"::Invoice));
    end;

    procedure CalcAmountsOnPostedCrMemos(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        exit(CalcAmountsOnPostedDocs(CustNo, RecCount, CustLedgEntry."Document Type"::"Credit Memo"));
    end;

    procedure CalcAmountsOnOrders(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesHeader."Document Type"::Order));
    end;

    procedure CalcAmountsOnQuotes(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesHeader."Document Type"::Quote));
    end;

    local procedure CalcAmountsOnPostedDocs(CustNo: Code[20]; var RecCount: Integer; DocType: Enum "Gen. Journal Document Type"): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            SetFilterForPostedDocs(CustLedgEntry, CustNo, DocType);

            RecCount := Count;

            CalcSums("Sales (LCY)");
            exit("Sales (LCY)");
        end;
    end;

    procedure CalculateAmountsWithVATOnUnpostedDocuments(CustNo: Code[20]): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesLine: Record "Sales Line";
        Result: Decimal;
    begin
        if CustNo = '' then
            exit;
        SetFilterForUnpostedLines(SalesLine, CustNo, SalesLine."Document Type"::Invoice, true);
        SalesLine.CalcSums("Outstanding Amount (LCY)");
        Result := SalesLine."Outstanding Amount (LCY)";

        SetFilterForUnpostedLines(SalesLine, CustNo, SalesLine."Document Type"::"Credit Memo", true);
        SalesLine.CalcSums("Outstanding Amount (LCY)");
        Result -= SalesLine."Outstanding Amount (LCY)";

        exit(Result);
    end;

    procedure CalculateAmountsOnUnpostedInvoices(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesLine."Document Type"::Invoice));
    end;

    procedure CalculateAmountsOnUnpostedCrMemos(CustNo: Code[20]; var RecCount: Integer): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        exit(CalculateAmountsOnUnpostedDocs(CustNo, RecCount, SalesLine."Document Type"::"Credit Memo"));
    end;

    local procedure CalculateAmountsOnUnpostedDocs(CustNo: Code[20]; var RecCount: Integer; DocumentType: Enum "Sales Document Type") Result: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
        SalesOutstdAmountOnVAT: Query "Sales Outstd. Amount On VAT";
        Factor: Integer;
    begin
        RecCount := 0;
        Result := 0;
        if CustNo = '' then
            exit;

        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        RecCount := SalesHeader.Count();

        case DocumentType of
            "Sales Document Type"::Invoice,
        "Sales Document Type"::Order,
        "Sales Document Type"::Quote:
                Factor := 1;
            "Sales Document Type"::"Credit Memo":
                Factor := -1;
        end;
        SalesOutstdAmountOnVAT.SetRange(Document_Type, DocumentType);
        SalesOutstdAmountOnVAT.SetRange(Bill_to_Customer_No_, CustNo);
        SalesOutstdAmountOnVAT.Open();
        while SalesOutstdAmountOnVAT.Read() do
            Result += Factor * SalesOutstdAmountOnVAT.Sum_Outstanding_Amount__LCY_ * 100 / (100 + SalesOutstdAmountOnVAT.VAT__);
        SalesOutstdAmountOnVAT.Close();

        exit(Round(Result));
    end;

    procedure DrillDownOnPostedInvoices(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        with SalesInvoiceHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetFilter("Posting Date", GetCurrentYearFilter());

            PAGE.Run(PAGE::"Posted Sales Invoices", SalesInvoiceHeader);
        end;
    end;

    procedure DrillDownOnPostedCrMemo(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with SalesCrMemoHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetFilter("Posting Date", GetCurrentYearFilter());

            PAGE.Run(PAGE::"Posted Sales Credit Memos", SalesCrMemoHeader);
        end;
    end;

    procedure DrillDownOnOrders(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        with SalesHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetRange("Document Type", "Document Type"::Order);

            PAGE.Run(PAGE::"Sales Order List", SalesHeader);
        end;
    end;

    procedure DrillDownOnQuotes(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        with SalesHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetRange("Document Type", "Document Type"::Quote);

            PAGE.Run(PAGE::"Sales Quotes", SalesHeader);
        end;
    end;

    procedure DrillDownMoneyOwedExpected(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, -1);
        PAGE.Run(PAGE::"Sales List", SalesHeader)
    end;

    procedure DrillDownOnUnpostedInvoices(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, SalesHeader."Document Type"::Invoice.AsInteger());
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeader)
    end;

    procedure DrillDownOnUnpostedCrMemos(CustNo: Code[20])
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SetFilterForUnpostedDocs(SalesHeader, CustNo, SalesHeader."Document Type"::"Credit Memo".AsInteger());
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeader)
    end;

    local procedure SetFilterForUnpostedDocs(var SalesHeader: Record "Sales Header"; CustNo: Code[20]; DocumentType: Integer)
    begin
        with SalesHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetFilter("Posting Date", GetCurrentYearFilter());

            if DocumentType = -1 then
                SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo")
            else
                SetRange("Document Type", DocumentType);
        end;
    end;

    local procedure SetFilterForUnpostedLines(var SalesLine: Record "Sales Line"; CustNo: Code[20]; DocumentType: Enum "Sales Document Type"; Posted: Boolean)
    begin
        with SalesLine do begin
            SetRange("Bill-to Customer No.", CustNo);
            if Posted then
                SetFilter("Posting Date", GetCurrentYearFilter());

            SetRange("Document Type", DocumentType);
        end;

        OnAfterSetFilterForUnpostedLines(SalesLine);
    end;

    local procedure SetFilterForPostedDocs(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        with CustLedgEntry do begin
            SetRange("Customer No.", CustNo);
            SetFilter("Posting Date", GetCurrentYearFilter());
            SetRange("Document Type", DocumentType);
        end;

        OnAfterSetFilterForPostedDocs(CustLedgEntry);
    end;

    procedure GetCurrentYearFilter(): Text[30]
    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CustDateFilter: Text[30];
        CustDateName: Text[30];
        SkipSetFilter: Boolean;
    begin
        SkipSettingFilter(SkipSetFilter);
        if SkipSetFilter then
            exit(CustDateFilter);

        if FiscalYearTotals then
            DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter, CustDateName, WorkDate(), 0)
        else
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter, CustDateName, WorkDate(), 0);

        exit(CustDateFilter);
    end;

    procedure GetTotalSales(CustNo: Code[20]) Result: Decimal
    var
        Totals: Decimal;
        AmountOnPostedInvoices: Decimal;
        AmountOnPostedCrMemos: Decimal;
        AmountOnOutstandingInvoices: Decimal;
        AmountOnOutstandingCrMemos: Decimal;
        NoPostedInvoices: Integer;
        NoPostedCrMemos: Integer;
        NoOutstandingInvoices: Integer;
        NoOutstandingCrMemos: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTotalSales(CustNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        AmountOnPostedInvoices := CalcAmountsOnPostedInvoices(CustNo, NoPostedInvoices);
        AmountOnPostedCrMemos := CalcAmountsOnPostedCrMemos(CustNo, NoPostedCrMemos);

        AmountOnOutstandingInvoices := CalculateAmountsOnUnpostedInvoices(CustNo, NoOutstandingInvoices);
        AmountOnOutstandingCrMemos := CalculateAmountsOnUnpostedCrMemos(CustNo, NoOutstandingCrMemos);

        Totals := AmountOnPostedInvoices + AmountOnPostedCrMemos + AmountOnOutstandingInvoices + AmountOnOutstandingCrMemos;
        exit(Totals)
    end;

    procedure GetYTDSales(CustNo: Code[20]): Decimal
    var
        Totals: Decimal;
    begin
        FiscalYearTotals := true;
        Totals := GetTotalSales(CustNo);
        FiscalYearTotals := false;
        exit(Totals);
    end;

    procedure CalculateShipToBillToOptions(var ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address"; var BillToOptions: Option "Default (Customer)","Another Customer","Custom Address"; var SalesHeader: Record "Sales Header")
    var
        ShipToNameEqualsSellToName: Boolean;
    begin
        with SalesHeader do begin
            ShipToNameEqualsSellToName :=
              ("Ship-to Name" = "Sell-to Customer Name") and ("Ship-to Name 2" = "Sell-to Customer Name 2");

            case true of
                ("Ship-to Code" = '') and ShipToNameEqualsSellToName and ShipToAddressEqualsSellToAddress():
                    ShipToOptions := ShipToOptions::"Default (Sell-to Address)";
                ("Ship-to Code" = '') and
              (not ShipToNameEqualsSellToName or not ShipToAddressEqualsSellToAddress()):
                    ShipToOptions := ShipToOptions::"Custom Address";
                "Ship-to Code" <> '':
                    ShipToOptions := ShipToOptions::"Alternate Shipping Address";
            end;

            case true of
                ("Bill-to Customer No." = "Sell-to Customer No.") and BillToAddressEqualsSellToAddress():
                    BillToOptions := BillToOptions::"Default (Customer)";
                ("Bill-to Customer No." = "Sell-to Customer No.") and (not BillToAddressEqualsSellToAddress()):
                    BillToOptions := BillToOptions::"Custom Address";
                "Bill-to Customer No." <> "Sell-to Customer No.":
                    BillToOptions := BillToOptions::"Another Customer";
            end;
        end;

        OnAfterCalculateShipToBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterForPostedDocs(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterForUnpostedLines(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotalSales(CustNo: Code[20]; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure SkipSettingFilter(var SkipSetFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateShipToBillToOptions(var ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address"; var BillToOptions: Option "Default (Customer)","Another Customer","Custom Address"; SalesHeader: Record "Sales Header")
    begin
    end;
}

