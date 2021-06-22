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

    procedure InitReportUsage(ReportUsage: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do
            case ReportUsage of
                Usage::"Pro Forma S. Invoice":
                    InsertRepSelection(Usage::"Pro Forma S. Invoice", '1', REPORT::"Standard Sales - Pro Forma Inv");
                Usage::"S.Invoice Draft":
                    InsertRepSelection(Usage::"S.Invoice Draft", '1', REPORT::"Standard Sales - Draft Invoice");
                Usage::"S.Quote":
                    InsertRepSelection(Usage::"S.Quote", '1', REPORT::"Standard Sales - Quote");
                Usage::"S.Blanket":
                    InsertRepSelection(Usage::"S.Blanket", '1', REPORT::"Blanket Sales Order");
                Usage::"S.Order":
                    InsertRepSelection(Usage::"S.Order", '1', REPORT::"Standard Sales - Order Conf.");
                Usage::"S.Work Order":
                    InsertRepSelection(Usage::"S.Work Order", '1', REPORT::"Work Order");
                Usage::"S.Invoice":
                    InsertRepSelection(Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
                Usage::"S.Return":
                    InsertRepSelection(Usage::"S.Return", '1', REPORT::"Return Order Confirmation");
                Usage::"S.Cr.Memo":
                    InsertRepSelection(Usage::"S.Cr.Memo", '1', REPORT::"Standard Sales - Credit Memo");
                Usage::"S.Shipment":
                    InsertRepSelection(Usage::"S.Shipment", '1', REPORT::"Sales - Shipment");
                Usage::"S.Ret.Rcpt.":
                    InsertRepSelection(Usage::"S.Ret.Rcpt.", '1', REPORT::"Sales - Return Receipt");
                Usage::"S.Test":
                    InsertRepSelection(Usage::"S.Test", '1', REPORT::"Sales Document - Test");
                Usage::"P.Quote":
                    InsertRepSelection(Usage::"P.Quote", '1', REPORT::"Purchase - Quote");
                Usage::"P.Blanket":
                    InsertRepSelection(Usage::"P.Blanket", '1', REPORT::"Blanket Purchase Order");
                Usage::"P.Order":
                    InsertRepSelection(Usage::"P.Order", '1', REPORT::Order);
                Usage::"P.Invoice":
                    InsertRepSelection(Usage::"P.Invoice", '1', REPORT::"Purchase - Invoice");
                Usage::"P.Return":
                    InsertRepSelection(Usage::"P.Return", '1', REPORT::"Return Order");
                Usage::"P.Cr.Memo":
                    InsertRepSelection(Usage::"P.Cr.Memo", '1', REPORT::"Purchase - Credit Memo");
                Usage::"P.Receipt":
                    InsertRepSelection(Usage::"P.Receipt", '1', REPORT::"Purchase - Receipt");
                Usage::"P.Ret.Shpt.":
                    InsertRepSelection(Usage::"P.Ret.Shpt.", '1', REPORT::"Purchase - Return Shipment");
                Usage::"P.Test":
                    InsertRepSelection(Usage::"P.Test", '1', REPORT::"Purchase Document - Test");
                Usage::"B.Stmt":
                    InsertRepSelection(Usage::"B.Stmt", '1', REPORT::"Bank Account Statement");
                Usage::"B.Recon.Test":
                    InsertRepSelection(Usage::"B.Recon.Test", '1', REPORT::"Bank Acc. Recon. - Test");
                Usage::"B.Check":
                    InsertRepSelection(Usage::"B.Check", '1', REPORT::Check);
                Usage::Reminder:
                    InsertRepSelection(Usage::Reminder, '1', REPORT::Reminder);
                Usage::"Fin.Charge":
                    InsertRepSelection(Usage::"Fin.Charge", '1', REPORT::"Finance Charge Memo");
                Usage::"Rem.Test":
                    InsertRepSelection(Usage::"Rem.Test", '1', REPORT::"Reminder - Test");
                Usage::"F.C.Test":
                    InsertRepSelection(Usage::"F.C.Test", '1', REPORT::"Finance Charge Memo - Test");
                Usage::Inv1:
                    InsertRepSelection(Usage::Inv1, '1', REPORT::"Transfer Order");
                Usage::Inv2:
                    InsertRepSelection(Usage::Inv2, '1', REPORT::"Transfer Shipment");
                Usage::Inv3:
                    InsertRepSelection(Usage::Inv3, '1', REPORT::"Transfer Receipt");
                Usage::"Invt.Period Test":
                    InsertRepSelection(Usage::"Invt.Period Test", '1', REPORT::"Close Inventory Period - Test");
                Usage::"Prod.Order":
                    InsertRepSelection(Usage::"Prod.Order", '1', REPORT::"Prod. Order - Job Card");
                Usage::"Phys.Invt.Order Test":
                    InsertRepSelection(Usage::"Phys.Invt.Order Test", '1', REPORT::"Phys. Invt. Order - Test");
                Usage::"Phys.Invt.Order":
                    InsertRepSelection(Usage::"Phys.Invt.Order", '1', REPORT::"Phys. Invt. Order Diff. List");
                Usage::"P.Phys.Invt.Order":
                    InsertRepSelection(Usage::"P.Phys.Invt.Order", '1', REPORT::"Posted Phys. Invt. Order Diff.");
                Usage::"Phys.Invt.Rec.":
                    InsertRepSelection(Usage::"Phys.Invt.Rec.", '1', REPORT::"Phys. Invt. Recording");
                Usage::"P.Phys.Invt.Rec.":
                    InsertRepSelection(Usage::"P.Phys.Invt.Rec.", '1', REPORT::"Posted Phys. Invt. Recording");
                Usage::M1:
                    InsertRepSelection(Usage::M1, '1', REPORT::"Prod. Order - Job Card");
                Usage::M2:
                    InsertRepSelection(Usage::M2, '1', REPORT::"Prod. Order - Mat. Requisition");
                Usage::M3:
                    InsertRepSelection(Usage::M3, '1', REPORT::"Prod. Order - Shortage List");
                Usage::"SM.Quote":
                    InsertRepSelection(Usage::"SM.Quote", '1', REPORT::"Service Quote");
                Usage::"SM.Order":
                    InsertRepSelection(Usage::"SM.Order", '1', REPORT::"Service Order");
                Usage::"SM.Invoice":
                    InsertRepSelection(Usage::"SM.Invoice", '1', REPORT::"Service - Invoice");
                Usage::"SM.Credit Memo":
                    InsertRepSelection(Usage::"SM.Credit Memo", '1', REPORT::"Service - Credit Memo");
                Usage::"SM.Shipment":
                    InsertRepSelection(Usage::"SM.Shipment", '1', REPORT::"Service - Shipment");
                Usage::"SM.Contract Quote":
                    InsertRepSelection(Usage::"SM.Contract Quote", '1', REPORT::"Service Contract Quote");
                Usage::"SM.Contract":
                    InsertRepSelection(Usage::"SM.Contract", '1', REPORT::"Service Contract");
                Usage::"SM.Test":
                    InsertRepSelection(Usage::"SM.Test", '1', REPORT::"Service Document - Test");
                Usage::"Asm.Order":
                    InsertRepSelection(Usage::"Asm.Order", '1', REPORT::"Assembly Order");
                Usage::"P.Asm.Order":
                    InsertRepSelection(Usage::"P.Asm.Order", '1', REPORT::"Posted Assembly Order");
                Usage::"S.Test Prepmt.":
                    InsertRepSelection(Usage::"S.Test Prepmt.", '1', REPORT::"Sales Prepmt. Document Test");
                Usage::"P.Test Prepmt.":
                    InsertRepSelection(Usage::"P.Test Prepmt.", '1', REPORT::"Purchase Prepmt. Doc. - Test");
                Usage::"S.Arch.Quote":
                    InsertRepSelection(Usage::"S.Arch.Quote", '1', REPORT::"Archived Sales Quote");
                Usage::"S.Arch.Order":
                    InsertRepSelection(Usage::"S.Arch.Order", '1', REPORT::"Archived Sales Order");
                Usage::"P.Arch.Quote":
                    InsertRepSelection(Usage::"P.Arch.Quote", '1', REPORT::"Archived Purchase Quote");
                Usage::"P.Arch.Order":
                    InsertRepSelection(Usage::"P.Arch.Order", '1', REPORT::"Archived Purchase Order");
                Usage::"P.Arch.Return":
                    InsertRepSelection(Usage::"P.Arch.Return", '1', REPORT::"Arch.Purch. Return Order");
                Usage::"S.Arch.Return":
                    InsertRepSelection(Usage::"S.Arch.Return", '1', REPORT::"Arch. Sales Return Order");
                Usage::"S.Arch.Blanket":
                    InsertRepSelection(Usage::"S.Arch.Blanket", '1', REPORT::"Archived Blanket Sales Order");
                Usage::"P.Arch.Blanket":
                    InsertRepSelection(Usage::"P.Arch.Blanket", '1', REPORT::"Archived Blanket Purch. Order");
                Usage::"S.Order Pick Instruction":
                    InsertRepSelection(Usage::"S.Order Pick Instruction", '1', REPORT::"Pick Instruction");
                Usage::"C.Statement":
                    InsertRepSelection(Usage::"C.Statement", '1', REPORT::"Standard Statement");
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

    local procedure InsertRepSelection(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;
    end;

    procedure InsertRepSelectionWhse(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
    begin
        if not ReportSelectionWhse.Get(ReportUsage, Sequence) then begin
            ReportSelectionWhse.Init();
            ReportSelectionWhse.Usage := ReportUsage;
            ReportSelectionWhse.Sequence := Sequence;
            ReportSelectionWhse."Report ID" := ReportID;
            ReportSelectionWhse.Insert();
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

