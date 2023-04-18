codeunit 6648 "Purch.-Get Return Shipments"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    begin
        CheckHeader(Rec);

        ReturnShptLine.SetCurrentKey("Pay-to Vendor No.");
        ReturnShptLine.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
        ReturnShptLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
        ReturnShptLine.SetRange("Currency Code", PurchHeader."Currency Code");
        OnRunOnAfterSetReturnShptLineFilters(ReturnShptLine, PurchHeader);

        GetReturnShptLines.SetTableView(ReturnShptLine);
        GetReturnShptLines.LookupMode := true;
        GetReturnShptLines.SetPurchHeader(PurchHeader);
        GetReturnShptLines.RunModal();
    end;

    var
        Text000: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetReturnShptLines: Page "Get Return Shipment Lines";

    procedure CreateInvLines(var ReturnShptLine2: Record "Return Shipment Line")
    var
        DifferentCurrencies: Boolean;
        ShouldInsertReturnRcptLine: Boolean;
    begin
        with ReturnShptLine2 do begin
            SetFilter("Return Qty. Shipped Not Invd.", '<>0');
            OnCreateInvLinesOnAfterReturnShptLine2SetFilters(ReturnShptLine2);
            if Find('-') then begin
                PurchLine.LockTable();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                PurchLine."Document Type" := PurchHeader."Document Type";
                PurchLine."Document No." := PurchHeader."No.";

                repeat
                    if ReturnShptHeader."No." <> "Document No." then begin
                        ReturnShptHeader.Get("Document No.");
                        CheckReturnShptPayToVendorNo(ReturnShptHeader, PurchHeader, ReturnShptLine2);
                        DifferentCurrencies := false;
                        if ReturnShptHeader."Currency Code" <> PurchHeader."Currency Code" then begin
                            Message(Text000,
                              PurchHeader.FieldCaption("Currency Code"),
                              PurchHeader.TableCaption(), PurchHeader."No.",
                              ReturnShptHeader.TableCaption(), ReturnShptHeader."No.");
                            DifferentCurrencies := true;
                        end;
                        OnBeforeTransferLineToPurchaseDoc(ReturnShptHeader, ReturnShptLine2, PurchHeader, DifferentCurrencies);
                    end;
                    ShouldInsertReturnRcptLine := not DifferentCurrencies;
                    OnCreateInvLinesOnAfterCalcShouldInsertReturnRcptLine(ReturnShptHeader, ReturnShptLine2, PurchHeader, ShouldInsertReturnRcptLine, PurchLine);
                    if ShouldInsertReturnRcptLine then begin
                        ReturnShptLine := ReturnShptLine2;
                        CheckReturnShipmentLineVATBusPostingGroup(ReturnShptLine, PurchHeader);
                        ReturnShptLine.InsertInvLineFromRetShptLine(PurchLine);
                        if Type = Type::"Charge (Item)" then
                            GetItemChargeAssgnt(ReturnShptLine2, PurchLine."Qty. to Invoice");
                    end;
                    OnCreateInvLinesOnAfterLoopIteration(ReturnShptHeader, ReturnShptLine2, PurchHeader, PurchLine, ShouldInsertReturnRcptLine);
                until Next() = 0;
            end;
        end;

        OnAfterCreateInvLines(PurchHeader);
    end;

    local procedure CheckHeader(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckHeader(PurchHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::"Credit Memo");
        PurchHeader.TestField(Status, PurchHeader.Status::Open);
    end;

    local procedure CheckReturnShipmentLineVATBusPostingGroup(ReturnShipmentLine: Record "Return Shipment Line"; PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnShipmentLineVATBusPostingGroup(ReturnShipmentLine, PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        ReturnShipmentLine.TestField("VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group");
    end;

    local procedure CheckReturnShptPayToVendorNo(ReturnShptHeader: Record "Return Shipment Header"; PurchHeader: Record "Purchase Header"; ReturnShptLine: Record "Return Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnShptPayToVendorNo(ReturnShptHeader, PurchHeader, ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        ReturnShptHeader.TestField("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
    end;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    begin
        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::"Credit Memo");
    end;

    procedure GetItemChargeAssgnt(var ReturnShptLine: Record "Return Shipment Line"; QtyToInv: Decimal)
    var
        PurchOrderLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        with ReturnShptLine do
            if PurchOrderLine.Get(
                 PurchOrderLine."Document Type"::"Return Order",
                 "Return Order No.", "Return Order Line No.")
            then begin
                ItemChargeAssgntPurch.LockTable();
                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", PurchOrderLine."Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", PurchOrderLine."Document No.");
                ItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderLine."Line No.");
                if ItemChargeAssgntPurch.FindFirst() then begin
                    ItemChargeAssgntPurch.CalcSums("Qty. to Assign");
                    if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then
                        CopyItemChargeAssgnt(
                          PurchOrderLine, ReturnShptLine, ItemChargeAssgntPurch."Qty. to Assign",
                          QtyToInv / ItemChargeAssgntPurch."Qty. to Assign");
                end;
            end;
    end;

    local procedure CopyItemChargeAssgnt(PurchOrderLine: Record "Purchase Line"; ReturnShptLine: Record "Return Shipment Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        ReturnShptLine2: Record "Return Shipment Line";
        PurchLine2: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        InsertChargeAssgnt: Boolean;
    begin
        with PurchOrderLine do begin
            ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
            ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
            ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
            if ItemChargeAssgntPurch.Find('-') then
                repeat
                    if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then begin
                        ItemChargeAssgntPurch2 := ItemChargeAssgntPurch;
                        ItemChargeAssgntPurch2."Qty. to Assign" :=
                          Round(QtyFactor * ItemChargeAssgntPurch2."Qty. to Assign", UOMMgt.QtyRndPrecision);
                        PurchLine2.SetRange("Return Shipment No.", ReturnShptLine."Document No.");
                        PurchLine2.SetRange("Return Shipment Line No.", ReturnShptLine."Line No.");
                        if PurchLine2.Find('-') then
                            repeat
                                PurchLine2.CalcFields("Qty. to Assign");
                                InsertChargeAssgnt := PurchLine2."Qty. to Assign" <> PurchLine2.Quantity;
                            until (PurchLine2.Next() = 0) or InsertChargeAssgnt;

                        if InsertChargeAssgnt then begin
                            ItemChargeAssgntPurch2."Document Type" := PurchLine2."Document Type";
                            ItemChargeAssgntPurch2."Document No." := PurchLine2."Document No.";
                            ItemChargeAssgntPurch2."Document Line No." := PurchLine2."Line No.";
                            ItemChargeAssgntPurch2."Qty. Assigned" := 0;
                            if Abs(QtyToAssign) < Abs(ItemChargeAssgntPurch2."Qty. to Assign") then
                                ItemChargeAssgntPurch2."Qty. to Assign" := QtyToAssign;
                            if Abs(PurchLine2.Quantity - PurchLine2."Qty. to Assign") <
                               Abs(ItemChargeAssgntPurch2."Qty. to Assign")
                            then
                                ItemChargeAssgntPurch2."Qty. to Assign" :=
                                  PurchLine2.Quantity - PurchLine2."Qty. to Assign";
                            ItemChargeAssgntPurch2.Validate("Unit Cost");

                            if ItemChargeAssgntPurch2."Applies-to Doc. Type" = "Document Type" then begin
                                ItemChargeAssgntPurch2."Applies-to Doc. Type" := PurchLine2."Document Type";
                                ItemChargeAssgntPurch2."Applies-to Doc. No." := PurchLine2."Document No.";
                                ReturnShptLine2.SetCurrentKey("Return Order No.", "Return Order Line No.");
                                ReturnShptLine2.SetRange("Return Order No.", ItemChargeAssgntPurch."Applies-to Doc. No.");
                                ReturnShptLine2.SetRange("Return Order Line No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                                ReturnShptLine2.SetFilter(Quantity, '<>0');
                                if ReturnShptLine2.FindFirst() then begin
                                    PurchLine2.SetCurrentKey("Document Type", "Receipt No.", "Receipt Line No.");
                                    PurchLine2.SetRange("Document Type", PurchLine2."Document Type"::"Credit Memo");
                                    PurchLine2.SetRange("Return Shipment No.", ReturnShptLine2."Document No.");
                                    PurchLine2.SetRange("Return Shipment Line No.", ReturnShptLine2."Line No.");
                                    OnCopyItemChargeAssgntOnBeforeFindPurchLine2(PurchLine2, ItemChargeAssgntPurch2);
                                    if PurchLine2.Find('-') and (PurchLine2.Quantity <> 0) then begin
                                        OnCopyItemChargeAssgntOnAfterFindPurchLine2(PurchLine2, ItemChargeAssgntPurch2);
                                        ItemChargeAssgntPurch2."Applies-to Doc. Line No." := PurchLine2."Line No."
                                    end else
                                        InsertChargeAssgnt := false;
                                end else
                                    InsertChargeAssgnt := false;
                            end;
                        end;

                        if InsertChargeAssgnt and (ItemChargeAssgntPurch2."Qty. to Assign" <> 0) then begin
                            ItemChargeAssgntPurch2.Insert();
                            QtyToAssign := QtyToAssign - ItemChargeAssgntPurch2."Qty. to Assign";
                        end;
                    end;
                until ItemChargeAssgntPurch.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnShptPayToVendorNo(ReturnShipmentHeader: Record "Return Shipment Header"; PurchaseHeader: Record "Purchase Header"; ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToPurchaseDoc(ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseHeader: Record "Purchase Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterCalcShouldInsertReturnRcptLine(var ReturnShipmentHeader: Record "Return Shipment Header"; var ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseHeader: Record "Purchase Header"; var ShouldInsertReturnRcptLine: Boolean; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterReturnShptLine2SetFilters(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterLoopIteration(ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentLine2: Record "Return Shipment Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; ShouldInsertReturnRcptLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetReturnShptLineFilters(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnShipmentLineVATBusPostingGroup(ReturnShipmentLine: Record "Return Shipment Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemChargeAssgntOnAfterFindPurchLine2(var PurchLine2: Record "Purchase Line"; var ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemChargeAssgntOnBeforeFindPurchLine2(var PurchLine2: Record "Purchase Line"; var ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)");
    begin
    end;
}

