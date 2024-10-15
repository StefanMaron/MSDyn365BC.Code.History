// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 10201 "Transfer Custom Fields"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These methods are not used anymore';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    procedure GenJnlLineTOGenLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var GenLedgEntry: Record "G/L Entry")
    begin
    end;

    procedure GenJnlLineTOTaxEntry(var GenJnlLine: Record "Gen. Journal Line"; var TaxEntry: Record "VAT Entry")
    begin
    end;

    procedure GenJnlLineTOCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    procedure GenJnlLineTOVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    procedure GenJnlLineTOBankAccLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    procedure BankAccLedgEntryTOChkLedgEntry(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;

    procedure VendLedgEntryTOCVLedgEntryBuf(var VendLedgEntry: Record "Vendor Ledger Entry"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    procedure CVLedgEntryBufTOVendLedgEntry(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    procedure CustLedgEntryTOCVLedgEntryBuf(var CustLedgEntry: Record "Cust. Ledger Entry"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    procedure CVLedgEntryBufTOCustLedgEntry(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    procedure ItemJnlLineTOItemLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    procedure ItemJnlLineTOPhysInvtLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry")
    begin
    end;

    procedure ItemJnlLineTOValueEntry(var ItemJnlLine: Record "Item Journal Line"; var ValueEntry: Record "Value Entry")
    begin
    end;

    procedure JobJnlLineTOResJnlLine(var JobJnlLine: Record "Job Journal Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    procedure JobJnlLineTOItemJnlLine(var JobJnlLine: Record "Job Journal Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    procedure JobJnlLineTOGenJnlLine(var JobJnlLine: Record "Job Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    procedure JobJnlLineTOJobLedgEntry(var JobJnlLine: Record "Job Journal Line"; var JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    procedure ResJnlLineTOResLedgEntry(var ResJnlLine: Record "Res. Journal Line"; var ResLedgEntry: Record "Res. Ledger Entry")
    begin
    end;
}

