// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Sales.Receivables;

codeunit 236 "G/L Reg.-Cust.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        CustLedgEntry.SetCurrentKey("Transaction No.");
        CustLedgEntry.SetRange("Transaction No.", Rec."No.");
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
}

