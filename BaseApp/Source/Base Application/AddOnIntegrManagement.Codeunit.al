codeunit 5403 AddOnIntegrManagement
{
    Permissions = TableData "Manufacturing Setup" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        RndgSetupRead: Boolean;

    procedure CheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    var
        CheckReceiptOrderStatus: Codeunit "Check Prod. Order Status";
        Checked: Boolean;
    begin
        OnBeforeCheckReceiptOrderStatus(SalesLine, Checked);
        if Checked then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        CheckReceiptOrderStatus.SalesLineCheck(SalesLine);
    end;

    procedure ValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with PurchLine do begin
            TestField(Type, Type::Item);

            if ProdOrder.Get(ProdOrder.Status::Released, "Prod. Order No.") then begin
                ProdOrder.TestField(Blocked, false);
                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
                ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                ProdOrderLine.SetRange("Item No.", "No.");
                if ProdOrderLine.FindFirst then
                    "Routing No." := ProdOrderLine."Routing No.";
                Item.Get("No.");
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
            end;
        end;
    end;

    procedure ResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
        with ReqLine do begin
            "Prod. Order Line No." := 0;
            "Routing No." := '';
            "Routing Reference No." := 0;
            "Operation No." := '';
            "Work Center No." := '';
        end;
    end;

    procedure ValidateProdOrderOnReqLine(var ReqLine: Record "Requisition Line")
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with ReqLine do begin
            TestField(Type, Type::Item);

            if ProdOrder.Get(ProdOrder.Status::Released, "Prod. Order No.") then begin
                ProdOrder.TestField(Blocked, false);
                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
                ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                ProdOrderLine.SetRange("Item No.", "No.");
                if ProdOrderLine.FindFirst then begin
                    "Routing No." := ProdOrderLine."Routing No.";
                    "Routing Reference No." := ProdOrderLine."Line No.";
                    "Prod. Order Line No." := ProdOrderLine."Line No.";
                    "Requester ID" := UserId;
                end;
                Item.Get("No.");
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
            end;
        end;
    end;

    procedure InitMfgSetup()
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        with MfgSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;
    end;

    procedure TransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; ReqLine: Record "Requisition Line")
    var
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        with ReqLine do begin
            PurchOrderLine."Routing No." := "Routing No.";
            PurchOrderLine."Routing Reference No." := "Routing Reference No.";
            PurchOrderLine."Operation No." := "Operation No.";
            PurchOrderLine.Validate("Work Center No.", "Work Center No.");
            if "Prod. Order No." <> '' then
                if "Work Center No." <> '' then begin
                    WorkCenter.Get(PurchOrderLine."Work Center No.");
                    if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Time then begin
                        ProdOrderRtngLine.Get(
                          ProdOrderRtngLine.Status::Released, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                        MfgSetup.Get();
                        CostCalcMgt.GetRndgSetup(GLSetup, Currency, RndgSetupRead);
                        if MfgSetup."Cost Incl. Setup" and (Quantity <> 0) then begin
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" *
                                (ProdOrderRtngLine."Setup Time" /
                                 Quantity +
                                 ProdOrderRtngLine."Run Time"),
                                GLSetup."Unit-Amount Rounding Precision");
                        end else
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" * ProdOrderRtngLine."Run Time",
                                GLSetup."Unit-Amount Rounding Precision");
                    end else
                        PurchOrderLine."Overhead Rate" := WorkCenter."Overhead Rate";
                    PurchOrderLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                    PurchOrderLine."Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                    PurchOrderLine.Validate("Direct Unit Cost", "Direct Unit Cost");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptOrderStatus(SalesLine: Record "Sales Line"; var Checked: Boolean)
    begin
    end;
}

