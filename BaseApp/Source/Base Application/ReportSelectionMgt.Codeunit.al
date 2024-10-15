codeunit 1901 "Report Selection Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure InitReportSelectionSales()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionSales;

        with ReportSelections do begin
            InitReportUsage(Usage::"Pro Forma S. Invoice");
            InitReportUsage(Usage::"S.Invoice Draft");
            InitReportUsage(Usage::"S.Quote");
            InitReportUsage(Usage::"S.Blanket");
            InitReportUsage(Usage::"S.Order");
            InitReportUsage(Usage::"S.Work Order");
            InitReportUsage(Usage::"S.Invoice");
            InitReportUsage(Usage::"S.Return");
            InitReportUsage(Usage::"S.Cr.Memo");
            InitReportUsage(Usage::"S.Shipment");
            InitReportUsage(Usage::"S.Ret.Rcpt.");
            InitReportUsage(Usage::"S.Test");
            InitReportUsage(Usage::"S.Test Prepmt.");
            InitReportUsage(Usage::"S.Arch.Quote");
            InitReportUsage(Usage::"S.Arch.Order");
            InitReportUsage(Usage::"S.Arch.Return");
            InitReportUsage(Usage::"S.Arch.Blanket");
            InitReportUsage(Usage::"S.Order Pick Instruction");
            InitReportUsage(Usage::USI);
            InitReportUsage(Usage::USCM);
            InitReportUsage(Usage::UCSD);
            InitReportUsage(Usage::CSI);
            InitReportUsage(Usage::CSCM);
        end;

        OnAfterInitReportSelectionSales;
    end;

    procedure InitReportSelectionPurch()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionPurch();

        with ReportSelections do begin
            InitReportUsage(Usage::"P.Quote");
            InitReportUsage(Usage::"P.Blanket");
            InitReportUsage(Usage::"P.Order");
            InitReportUsage(Usage::"P.Invoice");
            InitReportUsage(Usage::"P.Return");
            InitReportUsage(Usage::"P.Cr.Memo");
            InitReportUsage(Usage::"P.Receipt");
            InitReportUsage(Usage::"P.Ret.Shpt.");
            InitReportUsage(Usage::"P.Test");
            InitReportUsage(Usage::"P.Test Prepmt.");
            InitReportUsage(Usage::"P.Arch.Quote");
            InitReportUsage(Usage::"P.Arch.Order");
            InitReportUsage(Usage::"P.Arch.Return");
            InitReportUsage(Usage::"P.Arch.Blanket");
            InitReportUsage(Usage::UPI);
            InitReportUsage(Usage::UPCM);
            InitReportUsage(Usage::UAS);
            InitReportUsage(Usage::AS);
        end;

        OnAfterInitReportSelectionPurch;
    end;

    procedure InitReportSelectionInvt()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionInvt();

        with ReportSelections do begin
            InitReportUsage(Usage::Inv1);
            InitReportUsage(Usage::Inv2);
            InitReportUsage(Usage::Inv3);
            InitReportUsage(Usage::"Invt.Period Test");
            InitReportUsage(Usage::"Prod.Order");
            InitReportUsage(Usage::"Phys.Invt.Order Test");
            InitReportUsage(Usage::"Phys.Invt.Order");
            InitReportUsage(Usage::"P.Phys.Invt.Order");
            InitReportUsage(Usage::"Phys.Invt.Rec.");
            InitReportUsage(Usage::"P.Phys.Invt.Rec.");
            InitReportUsage(Usage::"Asm.Order");
            InitReportUsage(Usage::"P.Asm.Order");
            InitReportUsage(Usage::UIS);
            InitReportUsage(Usage::IS);
            InitReportUsage(Usage::UIR);
            InitReportUsage(Usage::IR);
            InitReportUsage(Usage::PIJ);
            InitReportUsage(Usage::IRJ);
        end;

        OnAfterInitReportSelectionInvt;
    end;

    procedure InitReportSelectionBank()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionBank();

        with ReportSelections do begin
            InitReportUsage(Usage::"B.Stmt");
            InitReportUsage(Usage::"B.Recon.Test");
            InitReportUsage(Usage::"B.Check");
            InitReportUsage(Usage::CB);
            InitReportUsage(Usage::UCI);
            InitReportUsage(Usage::UCO);
            InitReportUsage(Usage::CI);
            InitReportUsage(Usage::CO);
        end;

        OnAfterInitReportSelectionBank;
    end;

    procedure InitReportSelectionCust()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionCust();

        with ReportSelections do begin
            InitReportUsage(Usage::Reminder);
            InitReportUsage(Usage::"Fin.Charge");
            InitReportUsage(Usage::"Rem.Test");
            InitReportUsage(Usage::"F.C.Test");
            InitReportUsage(Usage::"C.Statement");
        end;

        OnAfterInitReportSelectionCust;
    end;

    procedure InitReportSelectionServ()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionServ();

        with ReportSelections do begin
            InitReportUsage(Usage::"SM.Quote");
            InitReportUsage(Usage::"SM.Order");
            InitReportUsage(Usage::"SM.Invoice");
            InitReportUsage(Usage::"SM.Credit Memo");
            InitReportUsage(Usage::"SM.Shipment");
            InitReportUsage(Usage::"SM.Contract Quote");
            InitReportUsage(Usage::"SM.Contract");
            InitReportUsage(Usage::"SM.Test");
        end;

        OnAfterInitReportSelectionServ;
    end;

    procedure InitReportSelectionProd()
    var
        ReportSelections: Record "Report Selections";
    begin
        OnBeforeInitReportSelectionProd();

        with ReportSelections do begin
            InitReportUsage(Usage::M1);
            InitReportUsage(Usage::M2);
            InitReportUsage(Usage::M3);
        end;

        OnAfterInitReportSelectionProd;
    end;

    procedure InitReportSelectionWhse()
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
    begin
        OnBeforeInitReportSelectionWhse();

        with ReportSelectionWhse do begin
            InitReportUsageWhse(Usage::Pick);
            InitReportUsageWhse(Usage::"Put-away");
            InitReportUsageWhse(Usage::Movement);
            InitReportUsageWhse(Usage::"Invt. Pick");
            InitReportUsageWhse(Usage::"Invt. Put-away");
            InitReportUsageWhse(Usage::"Invt. Movement");
            InitReportUsageWhse(Usage::Receipt);
            InitReportUsageWhse(Usage::"Posted Receipt");
            InitReportUsageWhse(Usage::Shipment);
            InitReportUsageWhse(Usage::"Posted Shipment");
        end;

        OnAfterInitReportSelectionWhse;
    end;

    procedure InitReportSelectionFixedAssets()
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            InitReportUsage(Usage::UFAW);
            InitReportUsage(Usage::FAW);
            InitReportUsage(Usage::UFAM);
            InitReportUsage(Usage::FAM);
            InitReportUsage(Usage::UFAR);
            InitReportUsage(Usage::FAR);
            InitReportUsage(Usage::FARJ);
            InitReportUsage(Usage::FAJ);
        end;
    end;

    procedure InitReportUsage(ReportUsage: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do
            case ReportUsage of
                Usage::"Pro Forma S. Invoice":
                    InsertRepSelection(Usage::"Pro Forma S. Invoice", '1', REPORT::"Standard Sales - Pro Forma Inv", true, false, true);
                Usage::"S.Invoice Draft":
                    InsertRepSelection(Usage::"S.Invoice Draft", '1', REPORT::"Standard Sales - Draft Invoice", true, false, true);
                Usage::"S.Quote":
                    InsertRepSelection(Usage::"S.Quote", '1', REPORT::"Sales - Quote", true, false, true);
                Usage::"S.Blanket":
                    InsertRepSelection(Usage::"S.Blanket", '1', REPORT::"Blanket Sales Order", true, false, true);
                Usage::"S.Order":
                    begin
                        InsertRepSelection(Usage::"S.Order", '1', REPORT::"Order Confirmation", false, false, true);
                        InsertRepSelection(Usage::"S.Order", '2', REPORT::"Order Proforma-Invoice (A)", true, false, false);
                        InsertRepSelection(Usage::"S.Order", '3', REPORT::"Order Factura-Invoice (A)", false, false, false);
                        InsertRepSelection(Usage::"S.Order", '4', REPORT::"Order Item Shipment TORG-12", true, false, false);
                        InsertRepSelection(Usage::"S.Order", '5', REPORT::"Order Item Waybill 1-T", false, false, false);
                        InsertRepSelection(Usage::"S.Order", '6', REPORT::"Sales Shipment M-15", false, false, false);
                        InsertRepSelection(Usage::"S.Order", '7', REPORT::"Pick Instruction", false, false, true);
                    end;
                Usage::"S.Work Order":
                    InsertRepSelection(Usage::"S.Work Order", '1', REPORT::"Work Order", true, false, true);
                Usage::"S.Invoice":
                    begin
                        InsertRepSelection(Usage::"S.Invoice", '2', REPORT::"Posted Factura-Invoice (A)", true, false, false);
                        InsertRepSelection(Usage::"S.Invoice", '3', REPORT::"Posted Inv. Shipment TORG-12", true, false, false);
                        InsertRepSelection(Usage::"S.Invoice", '4', REPORT::"Posted Inv. Item Waybill 1-T", false, false, false);
                        InsertRepSelection(Usage::"S.Invoice", '5', REPORT::"Posted Sales Shipment M-15", false, false, false);
                    end;
                Usage::"S.Return":
                    begin
                        InsertRepSelection(Usage::"S.Return", '1', REPORT::"Return Order Confirmation", true, false, true);
                        InsertRepSelection(Usage::"S.Return", '2', REPORT::"Order Proforma-Invoice (A)", true, false, true);
                        InsertRepSelection(Usage::"S.Return", '3', REPORT::"Order Factura-Invoice (A)", false, false, true);
                        InsertRepSelection(Usage::"S.Return", '4', REPORT::"Order Item Shipment TORG-12", true, false, true);
                        InsertRepSelection(Usage::"S.Return", '5', REPORT::"Order Item Waybill 1-T", false, false, true);
                        InsertRepSelection(Usage::"S.Return", '6', REPORT::"Sales Shipment M-15", false, false, true);
                    end;
                Usage::"S.Cr.Memo":
                    begin
                        InsertRepSelection(Usage::"S.Cr.Memo", '1', REPORT::"Sales - Credit Memo", false, false, true);
                        InsertRepSelection(Usage::"S.Cr.Memo", '2', REPORT::"Posted Cr. M. Factura-Invoice", true, false, false);
                        InsertRepSelection(Usage::"S.Cr.Memo", '3', REPORT::"Posted Cr. M. Shipment TORG-12", false, false, false);
                    end;
                Usage::"S.Shipment":
                    begin
                        InsertRepSelection(Usage::"S.Shipment", '1', REPORT::"Sales - Shipment", false, false, true);
                        InsertRepSelection(Usage::"S.Shipment", '2', REPORT::"Posted Ship. Shipment TORG-12", true, false, false);
                        InsertRepSelection(Usage::"S.Shipment", '3', REPORT::"Posted Ship. Item Waybill 1-T", false, false, false);
                    end;
                Usage::"S.Ret.Rcpt.":
                    InsertRepSelection(Usage::"S.Ret.Rcpt.", '1', REPORT::"Sales - Return Receipt", true, false, true);
                Usage::"S.Test":
                    InsertRepSelection(Usage::"S.Test", '1', REPORT::"Sales Document - Test", true, false, true);
                Usage::"P.Quote":
                    InsertRepSelection(Usage::"P.Quote", '1', REPORT::"Purchase - Quote", true, false, true);
                Usage::"P.Blanket":
                    InsertRepSelection(Usage::"P.Blanket", '1', REPORT::"Blanket Purchase Order", true, false, true);
                Usage::"P.Order":
                    begin
                        InsertRepSelection(Usage::"P.Order", '1', REPORT::Order, true, false, true);
                        InsertRepSelection(Usage::"P.Order", '2', REPORT::"Purchase Receipt M-4", true, false, false);
                        InsertRepSelection(Usage::"P.Order", '3', REPORT::"Purch. FA Receipt FA-14", true, false, false);
                        InsertRepSelection(Usage::"P.Order", '4', REPORT::"Act Items Receipt M-7", true, false, false);
                        InsertRepSelection(Usage::"P.Order", '5', REPORT::"Items Receipt Act TORG-1", false, false, false);
                        InsertRepSelection(Usage::"P.Order", '6', REPORT::"Receipt Deviations TORG-2", false, true, false);
                    end;
                Usage::"P.Invoice":
                    begin
                        InsertRepSelection(Usage::"P.Invoice", '1', REPORT::"Posted Purchase Receipt M-4", true, false, false);
                        InsertRepSelection(Usage::"P.Invoice", '2', REPORT::"Posted Purch. FA Receipt FA-14", false, false, false);
                        InsertRepSelection(Usage::"P.Invoice", '3', REPORT::"Pstd. Purch. Factura-Invoice", false, false, false);
                    end;
                Usage::"P.Return":
                    InsertRepSelection(Usage::"P.Return", '1', REPORT::"Return Order", true, false, true);
                Usage::"P.Cr.Memo":
                    InsertRepSelection(Usage::"P.Cr.Memo", '1', REPORT::"Purchase - Credit Memo", true, false, true);
                Usage::"P.Receipt":
                    InsertRepSelection(Usage::"P.Receipt", '1', REPORT::"Purchase - Receipt", true, false, true);
                Usage::"P.Ret.Shpt.":
                    InsertRepSelection(Usage::"P.Ret.Shpt.", '1', REPORT::"Purchase - Return Shipment", true, false, true);
                Usage::"P.Test":
                    InsertRepSelection(Usage::"P.Test", '1', REPORT::"Purchase Document - Test", true, false, true);
                Usage::"B.Stmt":
                    InsertRepSelection(Usage::"B.Stmt", '1', REPORT::"Bank Account Statement", true, false, true);
                Usage::"B.Recon.Test":
                    InsertRepSelection(Usage::"B.Recon.Test", '1', REPORT::"Bank Acc. Recon. - Test", true, false, true);
                Usage::"B.Check":
                    InsertRepSelection(Usage::"B.Check", '1', REPORT::"Bank Payment Order", true, false, true);
                Usage::Reminder:
                    InsertRepSelection(Usage::Reminder, '1', REPORT::Reminder, true, false, true);
                Usage::"Fin.Charge":
                    InsertRepSelection(Usage::"Fin.Charge", '1', REPORT::"Finance Charge Memo", true, false, true);
                Usage::"Rem.Test":
                    InsertRepSelection(Usage::"Rem.Test", '1', REPORT::"Reminder - Test", true, false, true);
                Usage::"F.C.Test":
                    InsertRepSelection(Usage::"F.C.Test", '1', REPORT::"Finance Charge Memo - Test", true, false, true);
                Usage::Inv1:
                    begin
                        InsertRepSelection(Usage::Inv1, '1', REPORT::"Transfer Order TORG-13", true, false, false);
                        InsertRepSelection(Usage::Inv1, '2', REPORT::"Shipment Request M-11", false, false, false);
                    end;
                Usage::Inv2:
                    begin
                        InsertRepSelection(Usage::Inv2, '1', REPORT::"Transfer Shipment TORG-13", true, false, false);
                        InsertRepSelection(Usage::Inv2, '2', REPORT::"Shipment Request M-11", false, false, true);
                    end;
                Usage::Inv3:
                    begin
                        InsertRepSelection(Usage::Inv3, '1', REPORT::"Transfer Receipt TORG-13", true, false, false);
                        InsertRepSelection(Usage::Inv3, '2', REPORT::"Shipment Request M-11", false, false, true);
                    end;
                Usage::"Invt.Period Test":
                    InsertRepSelection(Usage::"Invt.Period Test", '1', REPORT::"Close Inventory Period - Test", true, false, true);
                Usage::"Prod.Order":
                    InsertRepSelection(Usage::"Prod.Order", '1', REPORT::"Prod. Order - Job Card", true, false, true);
                Usage::"Phys.Invt.Order Test":
                    InsertRepSelection(Usage::"Phys.Invt.Order Test", '1', REPORT::"Phys. Invt. Order - Test", true, false, true);
                Usage::"Phys.Invt.Order":
                    InsertRepSelection(Usage::"Phys.Invt.Order", '1', REPORT::"Phys. Invt. Order Diff. List", true, false, true);
                Usage::"P.Phys.Invt.Order":
                    InsertRepSelection(Usage::"P.Phys.Invt.Order", '1', REPORT::"Posted Phys. Invt. Order Diff.", true, false, true);
                Usage::"Phys.Invt.Rec.":
                    InsertRepSelection(Usage::"Phys.Invt.Rec.", '1', REPORT::"Phys. Invt. Recording", true, false, true);
                Usage::"P.Phys.Invt.Rec.":
                    InsertRepSelection(Usage::"P.Phys.Invt.Rec.", '1', REPORT::"Posted Phys. Invt. Recording", true, false, true);
                Usage::M1:
                    InsertRepSelection(Usage::M1, '1', REPORT::"Prod. Order - Job Card", true, false, true);
                Usage::M2:
                    InsertRepSelection(Usage::M2, '1', REPORT::"Prod. Order - Mat. Requisition", true, false, true);
                Usage::M3:
                    InsertRepSelection(Usage::M3, '1', REPORT::"Prod. Order - Shortage List", true, false, true);
                Usage::"SM.Quote":
                    InsertRepSelection(Usage::"SM.Quote", '1', REPORT::"Service Quote", true, false, true);
                Usage::"SM.Order":
                    InsertRepSelection(Usage::"SM.Order", '1', REPORT::"Service Order", true, false, true);
                Usage::"SM.Invoice":
                    InsertRepSelection(Usage::"SM.Invoice", '1', REPORT::"Service - Invoice", true, false, true);
                Usage::"SM.Credit Memo":
                    InsertRepSelection(Usage::"SM.Credit Memo", '1', REPORT::"Service - Credit Memo", true, false, true);
                Usage::"SM.Shipment":
                    InsertRepSelection(Usage::"SM.Shipment", '1', REPORT::"Service - Shipment", true, false, true);
                Usage::"SM.Contract Quote":
                    InsertRepSelection(Usage::"SM.Contract Quote", '1', REPORT::"Service Contract Quote", true, false, true);
                Usage::"SM.Contract":
                    InsertRepSelection(Usage::"SM.Contract", '1', REPORT::"Service Contract", true, false, true);
                Usage::"SM.Test":
                    InsertRepSelection(Usage::"SM.Test", '1', REPORT::"Service Document - Test", true, false, true);
                Usage::"Asm.Order":
                    InsertRepSelection(Usage::"Asm.Order", '1', REPORT::"Assembly Order", true, false, true);
                Usage::"P.Asm.Order":
                    InsertRepSelection(Usage::"P.Asm.Order", '1', REPORT::"Posted Assembly Order", true, false, true);
                Usage::"S.Test Prepmt.":
                    InsertRepSelection(Usage::"S.Test Prepmt.", '1', REPORT::"Sales Prepmt. Document Test", true, false, true);
                Usage::"P.Test Prepmt.":
                    InsertRepSelection(Usage::"P.Test Prepmt.", '1', REPORT::"Purchase Prepmt. Doc. - Test", true, false, true);
                Usage::"S.Arch.Quote":
                    InsertRepSelection(Usage::"S.Arch.Quote", '1', REPORT::"Archived Sales Quote", true, false, true);
                Usage::"S.Arch.Order":
                    InsertRepSelection(Usage::"S.Arch.Order", '1', REPORT::"Archived Sales Order", true, false, true);
                Usage::"P.Arch.Quote":
                    InsertRepSelection(Usage::"P.Arch.Quote", '1', REPORT::"Archived Purchase Quote", true, false, true);
                Usage::"P.Arch.Order":
                    InsertRepSelection(Usage::"P.Arch.Order", '1', REPORT::"Archived Purchase Order", true, false, true);
                Usage::"P.Arch.Return":
                    InsertRepSelection(Usage::"P.Arch.Return", '1', REPORT::"Arch.Purch. Return Order", true, false, true);
                Usage::"S.Arch.Return":
                    InsertRepSelection(Usage::"S.Arch.Return", '1', REPORT::"Arch. Sales Return Order", true, false, true);
                Usage::"S.Arch.Blanket":
                    InsertRepSelection(Usage::"S.Arch.Blanket", '1', REPORT::"Archived Blanket Sales Order", true, false, true);
                Usage::"P.Arch.Blanket":
                    InsertRepSelection(Usage::"P.Arch.Blanket", '1', REPORT::"Archived Blanket Purch. Order", true, false, true);
                Usage::"S.Order Pick Instruction":
                    InsertRepSelection(Usage::"S.Order Pick Instruction", '1', REPORT::"Pick Instruction", true, false, true);
                Usage::"C.Statement":
                    InsertRepSelection(Usage::"C.Statement", '1', REPORT::"Standard Statement", true, false, true);
                Usage::USI:
                    begin
                        InsertRepSelection(Usage::USI, '1', REPORT::"Order Proforma-Invoice (A)", true, false, true);
                        InsertRepSelection(Usage::USI, '2', REPORT::"Order Factura-Invoice (A)", false, false, true);
                        InsertRepSelection(Usage::USI, '3', REPORT::"Order Item Shipment TORG-12", true, false, true);
                        InsertRepSelection(Usage::USI, '4', REPORT::"Order Item Waybill 1-T", false, false, true);
                        InsertRepSelection(Usage::USI, '5', REPORT::"Sales Shipment M-15", false, false, true);
                    end;
                Usage::USCM:
                    InsertRepSelection(Usage::USCM, '1', REPORT::"Order Factura-Invoice (A)", false, false, true);
                Usage::UCSD:
                    InsertRepSelection(Usage::UCSD, '1', REPORT::"Sales Corr. Factura-Invoice", true, false, false);
                Usage::CSI:
                    InsertRepSelection(Usage::CSI, '1', REPORT::"Pstd. Sales Corr. Fact. Inv.", true, false, false);
                Usage::CSCM:
                    InsertRepSelection(Usage::CSCM, '1', REPORT::"Pstd. Sales Corr. Cr. M. Fact.", true, false, false);
                Usage::UPI:
                    begin
                        InsertRepSelection(Usage::UPI, '1', REPORT::"Purchase Receipt M-4", true, false, true);
                        InsertRepSelection(Usage::UPI, '2', REPORT::"Purch. FA Receipt FA-14", true, false, true);
                        InsertRepSelection(Usage::UPI, '3', REPORT::"Act Items Receipt M-7", true, false, true);
                        InsertRepSelection(Usage::UPI, '4', REPORT::"Items Receipt Act TORG-1", false, false, true);
                    end;
                Usage::UPCM:
                    InsertRepSelection(Usage::UPCM, '1', REPORT::"Act Items Receipt M-7", true, false, true);
                Usage::UAS:
                    InsertRepSelection(Usage::UAS, '1', REPORT::"Advance Statement", true, false, false);
                Usage::AS:
                    InsertRepSelection(Usage::AS, '1', REPORT::"Posted Advance Statement", true, false, false);
                Usage::UIS:
                    InsertRepSelection(Usage::UIS, '1', REPORT::"Item Write-off act TORG-16", false, false, false);
                Usage::IS:
                    InsertRepSelection(Usage::IS, '1', REPORT::"Posted Item Write-off TORG-16", false, false, false);
                Usage::UIR:
                    begin
                        InsertRepSelection(Usage::UIR, '1', REPORT::"Act Items Receipt M-7", true, false, true);
                        InsertRepSelection(Usage::UIR, '2', REPORT::"Items Receipt Act TORG-1", false, false, true);
                        InsertRepSelection(Usage::UIR, '3', REPORT::"Receipt Deviations TORG-2", false, true, true);
                    end;
                Usage::IR:
                    begin
                        InsertRepSelection(Usage::IR, '1', REPORT::"Act Items Receipt M-7", true, false, true);
                        InsertRepSelection(Usage::IR, '2', REPORT::"Items Receipt Act TORG-1", false, false, true);
                        InsertRepSelection(Usage::IR, '3', REPORT::"Receipt Deviations TORG-2", false, true, true);
                    end;
                Usage::PIJ:
                    begin
                        InsertRepSelection(Usage::PIJ, '1', REPORT::"Phys. Inventory Form INV-3", false, false, false);
                        InsertRepSelection(Usage::PIJ, '2', REPORT::"Phys. Inventory Form INV-19", false, false, false);
                    end;
                Usage::IRJ:
                    begin
                        InsertRepSelection(Usage::IRJ, '1', REPORT::"Item Reclass. TORG-13", true, false, false);
                        InsertRepSelection(Usage::IRJ, '2', REPORT::"Shipment Request M-11", false, false, true);
                    end;
                Usage::CB:
                    InsertRepSelection(Usage::CB, '1', REPORT::"Cash Report CO-4", true, false, false);
                Usage::UCI:
                    InsertRepSelection(Usage::UCI, '1', REPORT::"Cash Ingoing Order", true, false, false);
                Usage::UCO:
                    InsertRepSelection(Usage::UCO, '1', REPORT::"Cash Outgoing Order", true, false, false);
                Usage::CI:
                    InsertRepSelection(Usage::CI, '1', REPORT::"Posted Cash Ingoing Order", true, false, false);
                Usage::CO:
                    InsertRepSelection(Usage::CO, '1', REPORT::"Posted Cash Outgoing Order", true, false, false);
                Usage::UFAW:
                    begin
                        InsertRepSelection(Usage::UFAW, '1', REPORT::"FA Write-off Act FA-4", true, false, false);
                        InsertRepSelection(Usage::UFAW, '2', REPORT::"FA Writeoff Act FA-4a", true, false, false);
                    end;
                Usage::FAW:
                    begin
                        InsertRepSelection(Usage::FAW, '1', REPORT::"FA Posted Writeoff Act FA-4", true, false, false);
                        InsertRepSelection(Usage::FAW, '2', REPORT::"Posted FA Writeoff Act FA-4a", true, false, false);
                    end;
                Usage::UFAM:
                    begin
                        InsertRepSelection(Usage::UFAM, '1', REPORT::"FA Movement FA-2", true, false, false);
                        InsertRepSelection(Usage::UFAM, '2', REPORT::"FA Movement FA-3", true, false, false);
                        InsertRepSelection(Usage::UFAM, '3', REPORT::"FA Movement FA-15", true, false, false);
                    end;
                Usage::FAM:
                    begin
                        InsertRepSelection(Usage::FAM, '1', REPORT::"FA Posted Movement FA-2", true, false, false);
                        InsertRepSelection(Usage::FAM, '2', REPORT::"FA Posted Movement FA-3", true, false, false);
                        InsertRepSelection(Usage::FAM, '3', REPORT::"Posted FA Movement FA-15", true, false, false);
                    end;
                Usage::UFAR:
                    InsertRepSelection(Usage::UFAR, '1', REPORT::"FA Release Act FA-1", true, false, false);
                Usage::FAR:
                    InsertRepSelection(Usage::FAR, '1', REPORT::"FA Posted Release Act FA-1", true, false, false);
                Usage::FARJ:
                    begin
                        InsertRepSelection(Usage::FARJ, '1', REPORT::"FA Phys. Inventory INV-1", true, false, false);
                        InsertRepSelection(Usage::FARJ, '2', REPORT::"FA Comparative Sheet INV-18", false, false, false);
                    end;
                Usage::FAJ:
                    begin
                        InsertRepSelection(Usage::FAJ, '1', REPORT::"FA Phys. Inventory INV-1a", true, true, false);
                        InsertRepSelection(Usage::FAJ, '2', REPORT::"Inventory for Deferrals INV-11", false, true, false);
                        InsertRepSelection(Usage::FAJ, '3', REPORT::"FA Comparative Sheet INV-18", true, false, true);
                        InsertRepSelection(Usage::FAJ, '4', REPORT::"FA Phys. Inventory INV-1", false, false, true);
                    end;
                else
                    OnInitReportUsage(ReportUsage);
            end;
    end;

    procedure InitReportUsageWhse(ReportUsage: Integer)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
    begin
        with ReportSelectionWhse do
            case ReportUsage of
                Usage::Pick:
                    InsertRepSelectionWhse(Usage::Pick, '1', REPORT::"Picking List");
                Usage::"Put-away":
                    InsertRepSelectionWhse(Usage::"Put-away", '1', REPORT::"Put-away List");
                Usage::Movement:
                    InsertRepSelectionWhse(Usage::Movement, '1', REPORT::"Movement List");
                Usage::"Invt. Pick":
                    InsertRepSelectionWhse(Usage::"Invt. Pick", '1', REPORT::"Picking List");
                Usage::"Invt. Put-away":
                    InsertRepSelectionWhse(Usage::"Invt. Put-away", '1', REPORT::"Put-away List");
                Usage::"Invt. Movement":
                    InsertRepSelectionWhse(Usage::"Invt. Movement", '1', REPORT::"Movement List");
                Usage::Receipt:
                    InsertRepSelectionWhse(Usage::Receipt, '1', REPORT::"Whse. - Receipt");
                Usage::"Posted Receipt":
                    InsertRepSelectionWhse(Usage::"Posted Receipt", '1', REPORT::"Whse. - Posted Receipt");
                Usage::Shipment:
                    InsertRepSelectionWhse(Usage::Shipment, '1', REPORT::"Whse. - Shipment");
                Usage::"Posted Shipment":
                    InsertRepSelectionWhse(Usage::"Posted Shipment", '1', REPORT::"Whse. - Posted Shipment");
                else
                    OnInitReportUsageWhse(ReportUsage);
            end;
    end;

    local procedure InsertRepSelection(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer; Default: Boolean; ExcelExport: Boolean; UseForEmailAttachment: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init;
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Default := Default;
            ReportSelections."Excel Export" := ExcelExport;
            ReportSelections."Use for Email Attachment" := UseForEmailAttachment;
            ReportSelections.Insert;
        end;
    end;

    procedure InsertRepSelectionWhse(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
    begin
        if not ReportSelectionWhse.Get(ReportUsage, Sequence) then begin
            ReportSelectionWhse.Init;
            ReportSelectionWhse.Usage := ReportUsage;
            ReportSelectionWhse.Sequence := Sequence;
            ReportSelectionWhse."Report ID" := ReportID;
            ReportSelectionWhse.Insert;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionSales()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionPurch()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionInvt()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionBank()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionCust()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionServ()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionProd()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitReportSelectionWhse()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionSales()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionPurch()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionInvt()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionBank()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionCust()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionServ()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionProd()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReportSelectionWhse()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportUsage(ReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportUsageWhse(ReportUsage: Integer)
    begin
    end;
}

