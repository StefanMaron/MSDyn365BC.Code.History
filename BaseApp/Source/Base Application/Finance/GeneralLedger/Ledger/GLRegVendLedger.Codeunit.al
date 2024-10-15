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
        if GLEntry.Get(Rec."From Entry No.") then
            FromTransNo := GLEntry."Transaction No.";
        if GLEntry.Get(Rec."To Entry No.") then
            ToTransNo := GLEntry."Transaction No.";

        VendLedgEntry.SetRange("Transaction No.", FromTransNo, ToTransNo);
        VendLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        FromTransNo: Integer;
        ToTransNo: Integer;
}

