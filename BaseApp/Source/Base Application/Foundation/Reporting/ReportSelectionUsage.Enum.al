﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

enum 77 "Report Selection Usage"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "S.Quote") { Caption = 'Sales Quote'; }
    value(1; "S.Order") { Caption = 'Sales Order'; }
    value(2; "S.Invoice") { Caption = 'Sales Invoice'; }
    value(3; "S.Cr.Memo") { Caption = 'Sales Credit Memo'; }
    value(4; "S.Test") { Caption = 'Sales Test'; }
    value(5; "P.Quote") { Caption = 'Purchase Quote'; }
    value(6; "P.Order") { Caption = 'Purchase Order'; }
    value(7; "P.Invoice") { Caption = 'Purchase Invoice'; }
    value(8; "P.Cr.Memo") { Caption = 'Purchase Credit Memo'; }
    value(9; "P.Receipt") { Caption = 'Purchase Receipt'; }
    value(10; "P.Ret.Shpt.") { Caption = 'Purchase Return Shipment'; }
    value(11; "P.Test") { Caption = 'Purchase Test'; }
    value(12; "B.Stmt") { Caption = 'Bank Statement'; }
    value(13; "B.Recon.Test") { Caption = 'Bank Reconciliation Test'; }
    value(14; "B.Check") { Caption = 'Bank Check'; }
    value(15; "Reminder") { Caption = 'Reminder'; }
    value(16; "Fin.Charge") { Caption = 'Finance Charge'; }
    value(17; "Rem.Test") { Caption = 'Reminder Test'; }
    value(18; "F.C.Test") { Caption = 'Finance Charge Test'; }
    value(19; "Prod.Order") { Caption = 'Production Order'; }
    value(20; "S.Blanket") { Caption = 'Sales Blanket Order'; }
    value(21; "P.Blanket") { Caption = 'Purchase Blanket Order'; }
    value(22; "M1") { Caption = 'Job Card'; }
    value(23; "M2") { Caption = 'Mat. & Requisition'; }
    value(24; "M3") { Caption = 'Shortage List'; }
    value(25; "M4") { Caption = 'Gantt Chart'; }
    value(26; "Inv1") { Caption = 'Transfer Order'; }
    value(27; "Inv2") { Caption = 'Transfer Shipment'; }
    value(28; "Inv3") { Caption = 'Transfer Receipt'; }
    value(29; "SM.Quote") { Caption = 'Service Quote'; }
    value(30; "SM.Order") { Caption = 'Service Order'; }
    value(31; "SM.Invoice") { Caption = 'Service Invoice'; }
    value(32; "SM.Credit Memo") { Caption = 'Service Credit Memo'; }
    value(33; "SM.Contract Quote") { Caption = 'Service Contract Quote'; }
    value(34; "SM.Contract") { Caption = 'Service Contract'; }
    value(35; "SM.Test") { Caption = 'Service Test'; }
    value(36; "S.Return") { Caption = 'Sales Return Order'; }
    value(37; "P.Return") { Caption = 'Purchase Return Order'; }
    value(38; "S.Shipment") { Caption = 'Sales Shipment'; }
    value(39; "S.Ret.Rcpt.") { Caption = 'Sales Return Receipt'; }
    value(40; "S.Work Order") { Caption = 'Sales Work Order'; }
    value(41; "Invt.Period Test") { Caption = 'Invt.Period Test'; }
    value(42; "SM.Shipment") { Caption = 'Service Shipment'; }
    value(43; "S.Test Prepmt.") { Caption = 'Sales Test Prepayment'; }
    value(44; "P.Test Prepmt.") { Caption = 'Purchase Test Prepayment'; }
    value(45; "S.Arch.Quote") { Caption = 'Sales Archive Quote'; }
    value(46; "S.Arch.Order") { Caption = 'Sales Archice Order'; }
    value(47; "P.Arch.Quote") { Caption = 'Purchase Archive Quote'; }
    value(48; "P.Arch.Order") { Caption = 'Purchase Archive Order'; }
    value(49; "S.Arch.Return") { Caption = 'Sales Archive Return'; }
    value(50; "P.Arch.Return") { Caption = 'Purchase Archive Return'; }
    value(51; "Asm.Order") { Caption = 'Assembly Order'; }
    value(52; "P.Asm.Order") { Caption = 'Posted Assembly Order'; }
    value(53; "S.Order Pick Instruction") { Caption = 'Sales Order Pick Instruction'; }
    value(54; "WHT Certificate") { Caption = 'Withholding Tax Certificate'; }
    value(55; "P.TaxInvoice") { Caption = 'Purchase Tax Invoice'; }
    value(56; "S.TaxInvoice") { Caption = 'Sales Tax Invoice'; }
    value(57; "P.TaxCreditMemo") { Caption = 'Purchase Tax Credit Memo'; }
    value(58; "S.TaxCreditMemo") { Caption = 'Sales Tax Credit Memo'; }
    value(60; "Posted Payment Reconciliation") { Caption = 'Posted Payment Reconciliation'; }
    value(84; "P.V.Remit.") { Caption = 'Purchase Vendor Remittance'; }
    value(85; "C.Statement") { Caption = 'Customer Statement'; }
    value(86; "V.Remittance") { Caption = 'Vendor Remittance'; }
    value(87; "JQ") { Caption = 'Job Quote'; }
    value(88; "S.Invoice Draft") { Caption = 'Sales Invoice Draft'; }
    value(89; "Pro Forma S. Invoice") { Caption = 'Pro Forma Sales Invoice'; }
    value(90; "S.Arch.Blanket") { Caption = 'Sales Archive Blanket Order'; }
    value(91; "P.Arch.Blanket") { Caption = 'Purchase Archive Blanket Order'; }
    value(92; "Phys.Invt.Order Test") { Caption = 'Phys. Inventory Order Test'; }
    value(93; "Phys.Invt.Order") { Caption = 'Phys. Inventory Order'; }
    value(94; "P.Phys.Invt.Order") { Caption = 'Posted Phys. Inventory Order'; }
    value(95; "Phys.Invt.Rec.") { Caption = 'Phys. Inventory Recording'; }
    value(96; "P.Phys.Invt.Rec.") { Caption = 'Posted Phys. Inventory Recording'; }
    value(106; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(107; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(109; "P.Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    value(110; "P.Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(111; "P.Direct Transfer") { Caption = 'Posted Direct Transfer'; }
    value(112; "Job Task Quote") { Caption = 'Project Task Quote'; }
}

