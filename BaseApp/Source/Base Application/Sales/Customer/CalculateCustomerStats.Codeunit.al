// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

codeunit 9082 "Calculate Customer Stats."
{
    trigger OnRun()
    var
        Customer: record Customer;
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CustomerNo: Code[20];
        BalanceAsVendor: Decimal;
        LinkedVendorNo: Code[20];
    begin
        Params := Page.GetBackgroundParameters();
        CustomerNo := CopyStr(Params.Get(GetCustomerNoLabel()), 1, MaxStrLen(CustomerNo));
        if not Customer.Get(CustomerNo) then
            exit;

        BalanceAsVendor := Customer.GetBalanceAsVendor(LinkedVendorNo);

        Results.Add(GetBalanceAsVendorLabel(), Format(BalanceAsVendor));
        Results.Add(GetLinkedVendorNoLabel(), Format(LinkedVendorNo));
        Results.Add(GetLastPaymentDateLabel(), Format(CalcLastPaymentDate(CustomerNo)));
        Results.Add(GetTotalAmountLCYLabel(), Format(Customer.GetTotalAmountLCY()));
        Results.Add(GetOverdueBalanceLabel(), Format(Customer.CalcOverdueBalance()));
        Results.Add(GetSalesLCYLabel(), Format(Customer.GetSalesLCY()));
        Results.Add(GetInvoicedPrepmtAmountLCYLabel(), Format(Customer.GetInvoicedPrepmtAmountLCY()));

        OnCalculateCustomerStatistics(Params, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        LastPaymentDateLbl: label 'Last Payment Date', Locked = true;
        TotalAmountLCYLbl: label 'Total Amount LCY', Locked = true;
        OverdueBalanceLbl: label 'Overdue Balance', Locked = true;
        SalesLCYLbl: label 'Sales LCY', Locked = true;
        InvoicedPrepmtAmountLCYLbl: label 'Invoiced Prepmt Amount LCY', Locked = true;
        CustomerNoLbl: label 'Customer No.', Locked = true;
        BalanceAsVendorLbl: Label 'BalanceAsVendor', Locked = true;
        LinkedVendorNoLbl: Label 'LinkedVendorNo', Locked = true;

    local procedure SetFilterLastPaymentDateEntry(CustomerNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Reversed, false);
    end;

    local procedure CalcLastPaymentDate(CustomerNo: Code[20]): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SetFilterLastPaymentDateEntry(CustomerNo, CustLedgerEntry);
        if CustLedgerEntry.FindLast() then;
        exit(CustLedgerEntry."Posting Date");
    end;

    internal procedure GetLastPaymentDateLabel(): Text
    begin
        exit(LastPaymentDateLbl);
    end;

    internal procedure GetTotalAmountLCYLabel(): Text
    begin
        exit(TotalAmountLCYLbl);
    end;

    internal procedure GetOverdueBalanceLabel(): Text
    begin
        exit(OverdueBalanceLbl);
    end;

    internal procedure GetSalesLCYLabel(): Text
    begin
        exit(SalesLCYLbl);
    end;

    internal procedure GetInvoicedPrepmtAmountLCYLabel(): Text
    begin
        exit(InvoicedPrepmtAmountLCYLbl);
    end;

    internal procedure GetCustomerNoLabel(): Text
    begin
        exit(CustomerNoLbl);
    end;

    internal procedure GetBalanceAsVendorLabel(): Text
    begin
        exit(BalanceAsVendorLbl);
    end;

    internal procedure GetLinkedVendorNoLabel(): Text
    begin
        exit(LinkedVendorNoLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCustomerStatistics(Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
    end;
}
