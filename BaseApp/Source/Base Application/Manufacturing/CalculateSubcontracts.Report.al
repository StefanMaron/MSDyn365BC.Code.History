report 99001015 "Calculate Subcontracts"
{
    Caption = 'Calculate Subcontracts';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Subcontractor No.";
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING(Type, "No.") WHERE(Status = CONST(Released), Type = CONST("Work Center"), "Routing Status" = FILTER(< Finished));
                RequestFilterFields = "Prod. Order No.", "Starting Date";

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, "Prod. Order No.");

                    ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderLine.SetRange("Routing No.", "Routing No.");
                    ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
                    OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(ProdOrderLine, "Prod. Order Routing Line");
                    if ProdOrderLine.Find('-') then begin
                        DeleteRepeatedReqLines();
                        repeat
                            BaseQtyToPurch :=
                                CostCalcMgt.CalcQtyAdjdForRoutingScrap(
                                    CostCalcMgt.CalcQtyAdjdForBOMScrap(
                                        ProdOrderLine."Quantity (Base)", ProdOrderLine."Scrap %"),
                                        "Scrap Factor % (Accumulated)", "Fixed Scrap Qty. (Accum.)") -
                                (CostCalcMgt.CalcOutputQtyBaseOnPurchOrder(ProdOrderLine, "Prod. Order Routing Line") +
                                 CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, "Prod. Order Routing Line"));
                            QtyToPurch := Round(BaseQtyToPurch / ProdOrderLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                            OnAfterCalcQtyToPurch(ProdOrderLine, QtyToPurch);
                            if QtyToPurch > 0 then
                                InsertReqWkshLine();
                        until ProdOrderLine.Next() = 0;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Subcontractor No." = '' then
                    CurrReport.Skip();

                Window.Update(1, "No.");
            end;

            trigger OnPreDataItem()
            begin
                ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
                ReqLine.DeleteAll();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        MfgSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ReqWkshTmpl.Get(ReqLine."Worksheet Template Name");
        ReqWkShName.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine.LockTable();

        if ReqLine.FindLast() then
            ReqLine.Init();

        Window.Open(Text000 + Text001);
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkShName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        GLSetup: Record "General Ledger Setup";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        BaseQtyToPurch: Decimal;
        QtyToPurch: Decimal;
        GLSetupRead: Boolean;

        Text000: Label 'Processing Work Centers   #1##########\';
        Text001: Label 'Processing Orders         #2########## ';

    procedure SetWkShLine(NewReqLine: Record "Requisition Line")
    begin
        ReqLine := NewReqLine;
    end;

    local procedure InsertReqWkshLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReqWkshLine("Prod. Order Routing Line", "Work Center", ReqLine, IsHandled, ProdOrderLine);
        if IsHandled then
            exit;

        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        with ReqLine do begin
            SetSubcontracting(true);
            BlockDynamicTracking(true);

            Init();
            "Line No." := "Line No." + 10000;
            Validate(Type, Type::Item);
            Validate("No.", ProdOrderLine."Item No.");
            Validate("Variant Code", ProdOrderLine."Variant Code");
            Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
            Validate(Quantity, QtyToPurch);
            GetGLSetup();
            IsHandled := false;
            OnBeforeValidateUnitCost(ReqLine, "Work Center", IsHandled, ProdOrderLine, "Prod. Order Routing Line");
            if not IsHandled then
                if Quantity <> 0 then begin
                    if "Work Center"."Unit Cost Calculation" = "Work Center"."Unit Cost Calculation"::Units then
                        Validate(
                            "Direct Unit Cost",
                            Round(
                                "Prod. Order Routing Line"."Direct Unit Cost" * ProdOrderLine."Qty. per Unit of Measure",
                                GLSetup."Unit-Amount Rounding Precision"))
                    else
                        Validate(
                            "Direct Unit Cost",
                            Round(
                                ("Prod. Order Routing Line"."Expected Operation Cost Amt." - "Prod. Order Routing Line"."Expected Capacity Ovhd. Cost") /
                                ProdOrderLine."Total Exp. Oper. Output (Qty.)",
                                GLSetup."Unit-Amount Rounding Precision"));
                end else
                    Validate("Direct Unit Cost", 0);
            "Qty. per Unit of Measure" := 0;
            "Quantity (Base)" := 0;
            "Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
            "Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
            "Prod. Order No." := ProdOrderLine."Prod. Order No.";
            "Prod. Order Line No." := ProdOrderLine."Line No.";
            "Due Date" := "Prod. Order Routing Line"."Ending Date";
            "Requester ID" := UserId;
            "Location Code" := ProdOrderLine."Location Code";
            "Bin Code" := ProdOrderLine."Bin Code";
            "Routing Reference No." := "Prod. Order Routing Line"."Routing Reference No.";
            "Routing No." := "Prod. Order Routing Line"."Routing No.";
            "Operation No." := "Prod. Order Routing Line"."Operation No.";
            "Work Center No." := "Prod. Order Routing Line"."Work Center No.";
            Validate("Vendor No.", "Work Center"."Subcontractor No.");
            Description := "Prod. Order Routing Line".Description;
            SetVendorItemNo();
            OnAfterTransferProdOrderRoutingLine(ReqLine, "Prod. Order Routing Line");

            // If purchase order already exist we will change this if possible
            PurchLine.Reset();
            PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange(Type, PurchLine.Type::Item);
            PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            PurchLine.SetRange("Routing No.", "Prod. Order Routing Line"."Routing No.");
            PurchLine.SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
            PurchLine.SetRange("Planning Flexibility", PurchLine."Planning Flexibility"::Unlimited);
            PurchLine.SetRange("Quantity Received", 0);
            if PurchLine.FindFirst() then begin
                Validate(Quantity, Quantity + PurchLine."Outstanding Quantity");
                "Quantity (Base)" := 0;
                "Replenishment System" := "Replenishment System"::Purchase;
                "Ref. Order No." := PurchLine."Document No.";
                "Ref. Order Type" := "Ref. Order Type"::Purchase;
                "Ref. Line No." := PurchLine."Line No.";
                if PurchLine."Expected Receipt Date" = "Due Date" then
                    "Action Message" := "Action Message"::"Change Qty."
                else
                    "Action Message" := "Action Message"::"Resched. & Chg. Qty.";
                "Accept Action Message" := true;
            end else begin
                "Replenishment System" := "Replenishment System"::"Prod. Order";
                "Ref. Order No." := ProdOrderLine."Prod. Order No.";
                "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
                "Ref. Order Status" := ProdOrderLine.Status.AsInteger();
                "Ref. Line No." := ProdOrderLine."Line No.";
                "Action Message" := "Action Message"::New;
                "Accept Action Message" := true;
            end;

            if "Ref. Order No." <> '' then
                GetDimFromRefOrderLine(true);

            OnBeforeReqWkshLineInsert(ReqLine, ProdOrderLine);
            Insert();
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure DeleteRepeatedReqLines()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        with RequisitionLine do begin
            SetRange(Type, Type::Item);
            SetRange("No.", ProdOrderLine."Item No.");
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
            OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(RequisitionLine, ProdOrderLine, "Prod. Order Routing Line");
            DeleteAll(true);
        end;
    end;

    local procedure SetVendorItemNo()
    var
        ItemVendor: Record "Item Vendor";
    begin
        if ReqLine."No." = '' then
            exit;

        if Item."No." <> ReqLine."No." then begin
            Item.SetLoadFields("No.");
            Item.Get(ReqLine."No.");
        end;

        ItemVendor.Init();
        ItemVendor."Vendor No." := ReqLine."Vendor No.";
        ItemVendor."Variant Code" := ReqLine."Variant Code";
        Item.FindItemVend(ItemVendor, ReqLine."Location Code");
        ReqLine.Validate("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyToPurch(ProdOrderLine: Record "Prod. Order Line"; var QtyToPurch: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderRoutingLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReqWkshLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; var WorkCenter: Record "Work Center"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqWkshLineInsert(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;
}

