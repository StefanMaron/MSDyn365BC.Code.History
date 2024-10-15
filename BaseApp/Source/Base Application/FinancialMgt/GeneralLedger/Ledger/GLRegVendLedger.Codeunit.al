// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Purchases.Payables;

codeunit 237 "G/L Reg.-Vend.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VendLedgEntry.SetCurrentKey("Transaction No.");
        VendLedgEntry.SetRange("Transaction No.", Rec."No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
}

