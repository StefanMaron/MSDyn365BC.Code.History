codeunit 64 "Sales-Get Shipment"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        SalesHeader.Get("Document Type", "Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        SalesShptLine.SetCurrentKey("Bill-to Customer No.");
        SalesShptLine.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesShptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        SalesShptLine.SetRange("Currency Code", SalesHeader."Currency Code");
        SalesShptLine.SetRange("Authorized for Credit Card", false);
        OnRunAfterFilterSalesShpLine(SalesShptLine, SalesHeader);

        GetShipments.SetTableView(SalesShptLine);
        GetShipments.SetSalesHeader(SalesHeader);
        GetShipments.LookupMode := true;
        if GetShipments.RunModal <> ACTION::Cancel then;
    end;

    var
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetShipments: Page "Get Shipment Lines";
        Text002: Label 'Creating Sales Invoice Lines\';
        Text003: Label 'Inserted lines             #1######';

    procedure CreateInvLines(var SalesShptLine2: Record "Sales Shipment Line")
    var
        Window: Dialog;
        LineCount: Integer;
        TransferLine: Boolean;
        PrepmtAmtToDeductRounding: Decimal;
    begin
        with SalesShptLine2 do begin
            SetFilter("Qty. Shipped Not Invoiced", '<>0');
            OnCreateInvLinesOnBeforeFind(SalesShptLine2);
            if FindSet then begin
                SalesLine.LockTable();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                OnCreateInvLinesOnAfterSalesShptLineSetFilters(SalesShptLine2, SalesHeader);
                SalesLine."Document Type" := SalesHeader."Document Type";
                SalesLine."Document No." := SalesHeader."No.";
                Window.Open(Text002 + Text003);
                OnBeforeInsertLines(SalesHeader);

                repeat
                    LineCount := LineCount + 1;
                    Window.Update(1, LineCount);
                    if SalesShptHeader."No." <> "Document No." then begin
                        SalesShptHeader.Get("Document No.");
                        TransferLine := true;
                        if SalesShptHeader."Currency Code" <> SalesHeader."Currency Code" then begin
                            Message(
                              Text001,
                              SalesHeader.FieldCaption("Currency Code"),
                              SalesHeader.TableCaption, SalesHeader."No.",
                              SalesShptHeader.TableCaption, SalesShptHeader."No.");
                            TransferLine := false;
                        end;
                        if SalesShptHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No." then begin
                            Message(
                              Text001,
                              SalesHeader.FieldCaption("Bill-to Customer No."),
                              SalesHeader.TableCaption, SalesHeader."No.",
                              SalesShptHeader.TableCaption, SalesShptHeader."No.");
                            TransferLine := false;
                        end;
                        OnBeforeTransferLineToSalesDoc(SalesShptHeader, SalesShptLine2, SalesHeader, TransferLine);
                    end;
                    if TransferLine then begin
                        SalesShptLine := SalesShptLine2;
                        SalesShptLine.InsertInvLineFromShptLine(SalesLine);
                        CalcUpdatePrepmtAmtToDeductRounding(SalesShptLine, SalesLine, PrepmtAmtToDeductRounding);
                        if Type = Type::"Charge (Item)" then
                            GetItemChargeAssgnt(SalesShptLine2, SalesLine."Qty. to Invoice");
                    end;
                    OnAfterInsertLine(SalesShptLine, SalesLine);
                until Next = 0;

                OnAfterInsertLines(SalesHeader);
                CalcInvoiceDiscount(SalesLine);

                if TransferLine then
                    AdjustPrepmtAmtToDeductRounding(SalesLine, PrepmtAmtToDeductRounding);
            end;
        end;
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    procedure GetItemChargeAssgnt(var SalesShptLine: Record "Sales Shipment Line"; QtyToInvoice: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemChargeAssgnt(SalesShptLine, QtyToInvoice, IsHandled);
        if IsHandled then
            exit;

        if not SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.") then
            exit;

        ItemChargeAssgntSales.LockTable();
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
        if ItemChargeAssgntSales.FindFirst then begin
            ItemChargeAssgntSales.CalcSums("Qty. to Assign");
            if ItemChargeAssgntSales."Qty. to Assign" <> 0 then
                CopyItemChargeAssgnt(
                  SalesOrderLine, SalesShptLine, ItemChargeAssgntSales."Qty. to Assign", QtyToInvoice / ItemChargeAssgntSales."Qty. to Assign");
        end;
    end;

    local procedure CopyItemChargeAssgnt(SalesOrderLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        SalesShptLine2: Record "Sales Shipment Line";
        SalesLine2: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        InsertChargeAssgnt: Boolean;
        LineQtyToAssign: Decimal;
    begin
        with SalesOrderLine do begin
            ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
            ItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
            if ItemChargeAssgntSales.FindSet then
                repeat
                    if ItemChargeAssgntSales."Qty. to Assign" <> 0 then begin
                        ItemChargeAssgntSales2 := ItemChargeAssgntSales;
                        ItemChargeAssgntSales2."Qty. to Assign" :=
                          Round(QtyFactor * ItemChargeAssgntSales2."Qty. to Assign", UOMMgt.QtyRndPrecision);
                        SalesLine2.SetRange("Shipment No.", SalesShptLine."Document No.");
                        SalesLine2.SetRange("Shipment Line No.", SalesShptLine."Line No.");
                        if SalesLine2.FindSet then
                            repeat
                                SalesLine2.CalcFields("Qty. to Assign");
                                InsertChargeAssgnt := SalesLine2."Qty. to Assign" <> SalesLine2.Quantity;
                            until (SalesLine2.Next = 0) or InsertChargeAssgnt;

                        if InsertChargeAssgnt then begin
                            ItemChargeAssgntSales2."Document Type" := SalesLine2."Document Type";
                            ItemChargeAssgntSales2."Document No." := SalesLine2."Document No.";
                            ItemChargeAssgntSales2."Document Line No." := SalesLine2."Line No.";
                            ItemChargeAssgntSales2."Qty. Assigned" := 0;
                            LineQtyToAssign :=
                              ItemChargeAssgntSales2."Qty. to Assign" - GetQtyAssignedInNewLine(ItemChargeAssgntSales2);
                            InsertChargeAssgnt := LineQtyToAssign <> 0;
                            if InsertChargeAssgnt then begin
                                if Abs(QtyToAssign) < Abs(LineQtyToAssign) then
                                    ItemChargeAssgntSales2."Qty. to Assign" := QtyToAssign;
                                if Abs(SalesLine2.Quantity - SalesLine2."Qty. to Assign") <
                                   Abs(LineQtyToAssign)
                                then
                                    ItemChargeAssgntSales2."Qty. to Assign" :=
                                      SalesLine2.Quantity - SalesLine2."Qty. to Assign";
                                ItemChargeAssgntSales2.Validate("Unit Cost");

                                if ItemChargeAssgntSales2."Applies-to Doc. Type" = "Document Type" then begin
                                    ItemChargeAssgntSales2."Applies-to Doc. Type" := SalesLine2."Document Type";
                                    ItemChargeAssgntSales2."Applies-to Doc. No." := SalesLine2."Document No.";
                                    SalesShptLine2.SetCurrentKey("Order No.", "Order Line No.");
                                    SalesShptLine2.SetRange("Order No.", ItemChargeAssgntSales."Applies-to Doc. No.");
                                    SalesShptLine2.SetRange("Order Line No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                                    SalesShptLine2.SetFilter(Quantity, '<>0');
                                    if SalesShptLine2.FindFirst then begin
                                        SalesLine2.SetCurrentKey("Document Type", "Shipment No.", "Shipment Line No.");
                                        SalesLine2.SetRange("Document Type", "Document Type"::Invoice);
                                        SalesLine2.SetRange("Shipment No.", SalesShptLine2."Document No.");
                                        SalesLine2.SetRange("Shipment Line No.", SalesShptLine2."Line No.");
                                        if SalesLine2.FindFirst and (SalesLine2.Quantity <> 0) then
                                            ItemChargeAssgntSales2."Applies-to Doc. Line No." := SalesLine2."Line No."
                                        else
                                            InsertChargeAssgnt := false;
                                    end else
                                        InsertChargeAssgnt := false;
                                end;
                            end;
                        end;

                        if InsertChargeAssgnt and (ItemChargeAssgntSales2."Qty. to Assign" <> 0) then begin
                            ItemChargeAssgntSales2.Insert();
                            QtyToAssign := QtyToAssign - ItemChargeAssgntSales2."Qty. to Assign";
                        end;
                    end;
                until ItemChargeAssgntSales.Next = 0;
        end;
    end;

    local procedure GetQtyAssignedInNewLine(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"): Decimal
    begin
        with ItemChargeAssgntSales do begin
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            SetRange("Document Line No.", "Document Line No.");
            SetRange("Applies-to Doc. Type", "Applies-to Doc. Type");
            SetRange("Applies-to Doc. No.", "Applies-to Doc. No.");
            SetRange("Applies-to Doc. Line No.", "Applies-to Doc. Line No.");
            CalcSums("Qty. to Assign");
            exit("Qty. to Assign");
        end;
    end;

    local procedure CalcInvoiceDiscount(var SalesLine: Record "Sales Line")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Calc. Inv. Discount" then begin
            SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);
            OnAfterCalcInvoiceDiscount(SalesLine);
        end;
    end;

    local procedure CalcUpdatePrepmtAmtToDeductRounding(SalesShptLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; var RoundingAmount: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        Fraction: Decimal;
        FractionAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcUpdatePrepmtAmtToDeductRounding(SalesShptLine, SalesLine, RoundingAmount, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine."Prepayment %" > 0) and (SalesLine."Prepayment %" < 100) and
           (SalesLine."Document Type" = SalesLine."Document Type"::Invoice)
        then begin
            SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.");
            Fraction := SalesShptLine.Quantity / SalesOrderLine.Quantity;
            FractionAmount := Fraction * SalesOrderLine."Prepmt Amt to Deduct";
            RoundingAmount += SalesLine."Prepmt Amt to Deduct" - FractionAmount;
        end;
    end;

    local procedure AdjustPrepmtAmtToDeductRounding(var SalesLine: Record "Sales Line"; RoundingAmount: Decimal)
    begin
        if Round(RoundingAmount) <> 0 then begin
            SalesLine."Prepmt Amt to Deduct" -= Round(RoundingAmount);
            SalesLine.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscount(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLine(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdatePrepmtAmtToDeductRounding(SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; var RoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemChargeAssgnt(var SalesShipmentLine: Record "Sales Shipment Line"; QtyToInvoice: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToSalesDoc(SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentLine: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterSalesShptLineSetFilters(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeFind(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunAfterFilterSalesShpLine(var SalesShptLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header")
    begin
    end;
}

