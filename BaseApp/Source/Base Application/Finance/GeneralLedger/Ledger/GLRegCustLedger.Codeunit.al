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
        if GLEntry.Get(Rec."From Entry No.") then
            FromTransNo := GLEntry."Transaction No.";
        if GLEntry.Get(Rec."To Entry No.") then
            ToTransNo := GLEntry."Transaction No.";

        CustLedgEntry.SetRange("Transaction No.", FromTransNo, ToTransNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        FromTransNo: Integer;
        ToTransNo: Integer;
}

