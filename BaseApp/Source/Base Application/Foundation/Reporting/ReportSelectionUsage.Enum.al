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
    value(36; "S.Return") { Caption = 'Sales Return Order'; }
    value(37; "P.Return") { Caption = 'Purchase Return Order'; }
    value(38; "S.Shipment") { Caption = 'Sales Shipment'; }
    value(39; "S.Ret.Rcpt.") { Caption = 'Sales Return Receipt'; }
    value(40; "S.Work Order") { Caption = 'Sales Work Order'; }
    value(41; "Invt.Period Test") { Caption = 'Invt.Period Test'; }
    value(43; "S.Test Prepmt.") { Caption = 'Sales Test Prepayment'; }
    value(44; "P.Test Prepmt.") { Caption = 'Purchase Test Prepayment'; }
    value(45; "S.Arch.Quote") { Caption = 'Sales Archive Quote'; }
    value(46; "S.Arch.Order") { Caption = 'Sales Archive Order'; }
    value(47; "P.Arch.Quote") { Caption = 'Purchase Archive Quote'; }
    value(48; "P.Arch.Order") { Caption = 'Purchase Archive Order'; }
    value(49; "S.Arch.Return") { Caption = 'Sales Archive Return'; }
    value(50; "P.Arch.Return") { Caption = 'Purchase Archive Return'; }
    value(51; "Asm.Order") { Caption = 'Assembly Order'; }
    value(52; "P.Asm.Order") { Caption = 'Posted Assembly Order'; }
    value(53; "S.Order Pick Instruction") { Caption = 'Sales Order Pick Instruction'; }
    value(60; "Posted Payment Reconciliation") { Caption = 'Posted Payment Reconciliation'; }
    value(84; "P.V.Remit.") { Caption = 'Purchase Vendor Remittance'; }
    value(85; "C.Statement") { Caption = 'Customer Statement'; }
    value(86; "V.Remittance") { Caption = 'Vendor Remittance'; }
    value(87; "JQ") { Caption = 'Project Quote'; }
    value(88; "S.Invoice Draft") { Caption = 'Sales Invoice Draft'; }
    value(89; "Pro Forma S. Invoice") { Caption = 'Pro Forma Sales Invoice'; }
    value(90; "S.Arch.Blanket") { Caption = 'Sales Archive Blanket Order'; }
    value(91; "P.Arch.Blanket") { Caption = 'Purchase Archive Blanket Order'; }
    value(92; "Phys.Invt.Order Test") { Caption = 'Phys. Inventory Order Test'; }
    value(93; "Phys.Invt.Order") { Caption = 'Phys. Inventory Order'; }
    value(94; "P.Phys.Invt.Order") { Caption = 'Posted Phys. Inventory Order'; }
    value(95; "Phys.Invt.Rec.") { Caption = 'Phys. Inventory Recording'; }
    value(96; "P.Phys.Invt.Rec.") { Caption = 'Posted Phys. Inventory Recording'; }
    value(97; "USI") { Caption = 'Unposted Sales Invoice'; }
    value(98; "USCM") { Caption = 'Unposted Sales Credit Memo'; }
    value(99; "UCI") { Caption = 'Unposted Cash Incoming Order'; }
    value(100; "UCO") { Caption = 'Unposted Cash Outhoing Order'; }
    value(101; "CB") { Caption = 'Cash Book'; }
    value(102; "CI") { Caption = 'Cash Ingoing Order'; }
    value(103; "CO") { Caption = 'Cash Outgoing Order'; }
    value(104; "UAS") { Caption = 'Unposted Advance Statement'; }
    value(105; "AS") { Caption = 'Advance Statement'; }
    value(106; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(107; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(109; "P.Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    value(110; "P.Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(111; "P.Direct Transfer") { Caption = 'Posted Direct Transfer'; }
    value(112; "UFAW") { Caption = 'Unposted FA Withdraw'; }
    value(113; "UFAR") { Caption = 'Unposted FA Release'; }
    value(114; "UFAM") { Caption = 'Unposted FA Movement'; }
    value(115; "FAW") { Caption = 'FA Withdraw'; }
    value(116; "FAR") { Caption = 'FA Release'; }
    value(117; "FAM") { Caption = 'FA Movement'; }
    value(118; "FAJ") { Caption = 'FA Journal'; }
    value(119; "FARJ") { Caption = 'FA Recurring Journal'; }
    value(120; "PIJ") { Caption = 'Phys. Inventory Journal'; }
    value(121; "UPI") { Caption = 'Unposted Purchase Invoice'; }
    value(122; "IRJ") { Caption = 'Item Reclassification Journal'; }
    value(123; "UPCM") { Caption = 'Unposted Purchase Credit Memo'; }
    value(125; "SOPI") { Caption = 'SOPI'; }
    value(126; "UCSD") { Caption = 'Unposted Corrective Sales Document'; }
    value(127; "CSI") { Caption = 'Corrective Sales Invoice'; }
    value(128; "CSCM") { Caption = 'Corrective Sales Credit Memo'; }
    value(129; "Job Task Quote") { Caption = 'Project Task Quote'; }
    value(130; "VAT Statement") { Caption = 'VAT Statement'; }
    value(131; "Sales VAT Acc. Proof") { Caption = 'Sales VAT Acc. Proof'; }
    value(132; "VAT Statement Schedule") { Caption = 'VAT Statement Schedule'; }
}

