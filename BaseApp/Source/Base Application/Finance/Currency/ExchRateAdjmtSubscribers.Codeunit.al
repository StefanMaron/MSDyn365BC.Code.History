// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 597 "Exch. Rate Adjmt. Subscribers"
{
    var
        GLSetup: Record "General Ledger Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterSetDtldCustLedgEntryFilters', '', false, false)]
    local procedure SetDtldCustLedgEntryFilters(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        DtldCustLedgEntry.SetRange("Agreement No.", CustLedgEntry."Agreement No.");
        if GLSetup."Enable Russian Accounting" then
            DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterSetDtldVendLedgEntryFilters', '', false, false)]
    local procedure SetDtldVendLedgEntryFilters(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        DtldVendLedgEntry.SetRange("Agreement No.", VendLedgEntry."Agreement No.");
        if GLSetup."Enable Russian Accounting" then
            DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);

    end;

}