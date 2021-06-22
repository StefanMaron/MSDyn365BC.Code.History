codeunit 6638 "Sales-Get Return Receipts"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        SalesHeader.Get("Document Type", "Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        ReturnRcptLine.SetCurrentKey("Bill-to Customer No.");
        ReturnRcptLine.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
        ReturnRcptLine.SetRange("Currency Code", SalesHeader."Currency Code");
        OnRunOnAfterSetReturnRcptLineFilters(ReturnRcptLine, SalesHeader);

        GetReturnRcptLines.SetTableView(ReturnRcptLine);
        GetReturnRcptLines.LookupMode := true;
        GetReturnRcptLines.SetSalesHeader(SalesHeader);
        GetReturnRcptLines.RunModal;
    end;

    var
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetReturnRcptLines: Page "Get Return Receipt Lines";

    procedure CreateInvLines(var ReturnRcptLine2: Record "Return Receipt Line")
    var
        DifferentCurrencies: Boolean;
    begin
        with ReturnRcptLine2 do begin
            SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
            if Find('-') then begin
                SalesLine.LockTable();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine."Document Type" := SalesHeader."Document Type";
                SalesLine."Document No." := SalesHeader."No.";

                repeat
                    if ReturnRcptHeader."No." <> "Document No." then begin
                        ReturnRcptHeader.Get("Document No.");
                        ReturnRcptHeader.TestField("Bill-to Customer No.", "Bill-to Customer No.");
                        DifferentCurrencies := false;
                        if ReturnRcptHeader."Currency Code" <> SalesHeader."Currency Code" then begin
                            Message(Text001,
                              SalesHeader.FieldCaption("Currency Code"),
                              SalesHeader.TableCaption, SalesHeader."No.",
                              ReturnRcptHeader.TableCaption, ReturnRcptHeader."No.");
                            DifferentCurrencies := true;
                        end;
                        OnBeforeTransferLineToSalesDoc(ReturnRcptHeader, ReturnRcptLine2, SalesHeader, DifferentCurrencies);
                    end;
                    if not DifferentCurrencies then begin
                        ReturnRcptLine := ReturnRcptLine2;
                        ReturnRcptLine.InsertInvLineFromRetRcptLine(SalesLine);
                        if Type = Type::"Charge (Item)" then
                            GetItemChargeAssgnt(ReturnRcptLine2, SalesLine."Qty. to Invoice");
                    end;
                until Next = 0;
            end;
        end;

        OnAfterCreateInvLines(SalesHeader);
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
    end;

    procedure GetItemChargeAssgnt(var ReturnRcptLine: Record "Return Receipt Line"; QtyToInv: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        with ReturnRcptLine do
            if SalesOrderLine.Get(SalesOrderLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.")
            then begin
                ItemChargeAssgntSales.LockTable();
                ItemChargeAssgntSales.Reset();
                ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
                ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
                ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
                if ItemChargeAssgntSales.FindFirst then begin
                    ItemChargeAssgntSales.CalcSums("Qty. to Assign");
                    if ItemChargeAssgntSales."Qty. to Assign" <> 0 then
                        CopyItemChargeAssgnt(
                          SalesOrderLine, ReturnRcptLine, ItemChargeAssgntSales."Qty. to Assign",
                          QtyToInv / ItemChargeAssgntSales."Qty. to Assign");
                end;
            end;
    end;

    local procedure CopyItemChargeAssgnt(SalesOrderLine: Record "Sales Line"; ReturnRcptLine: Record "Return Receipt Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        ReturnRcptLine2: Record "Return Receipt Line";
        SalesLine2: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        InsertChargeAssgnt: Boolean;
    begin
        with SalesOrderLine do begin
            ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
            ItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
            if ItemChargeAssgntSales.Find('-') then
                repeat
                    if ItemChargeAssgntSales."Qty. to Assign" <> 0 then begin
                        ItemChargeAssgntSales2 := ItemChargeAssgntSales;
                        ItemChargeAssgntSales2."Qty. to Assign" :=
                          Round(QtyFactor * ItemChargeAssgntSales2."Qty. to Assign", UOMMgt.QtyRndPrecision);
                        SalesLine2.SetRange("Return Receipt No.", ReturnRcptLine."Document No.");
                        SalesLine2.SetRange("Return Receipt Line No.", ReturnRcptLine."Line No.");
                        if SalesLine2.Find('-') then
                            repeat
                                SalesLine2.CalcFields("Qty. to Assign");
                                InsertChargeAssgnt := SalesLine2."Qty. to Assign" <> SalesLine2.Quantity;
                            until (SalesLine2.Next = 0) or InsertChargeAssgnt;

                        if InsertChargeAssgnt then begin
                            ItemChargeAssgntSales2."Document Type" := SalesLine2."Document Type";
                            ItemChargeAssgntSales2."Document No." := SalesLine2."Document No.";
                            ItemChargeAssgntSales2."Document Line No." := SalesLine2."Line No.";
                            ItemChargeAssgntSales2."Qty. Assigned" := 0;
                            if Abs(QtyToAssign) < Abs(ItemChargeAssgntSales2."Qty. to Assign") then
                                ItemChargeAssgntSales2."Qty. to Assign" := QtyToAssign;
                            if Abs(SalesLine2.Quantity - SalesLine2."Qty. to Assign") <
                               Abs(ItemChargeAssgntSales2."Qty. to Assign")
                            then
                                ItemChargeAssgntSales2."Qty. to Assign" :=
                                  SalesLine2.Quantity - SalesLine2."Qty. to Assign";
                            ItemChargeAssgntSales2.Validate("Unit Cost");

                            if ItemChargeAssgntSales2."Applies-to Doc. Type" = "Document Type" then begin
                                ItemChargeAssgntSales2."Applies-to Doc. Type" := SalesLine2."Document Type";
                                ItemChargeAssgntSales2."Applies-to Doc. No." := SalesLine2."Document No.";
                                ReturnRcptLine2.SetCurrentKey("Return Order No.", "Return Order Line No.");
                                ReturnRcptLine2.SetRange("Return Order No.", ItemChargeAssgntSales."Applies-to Doc. No.");
                                ReturnRcptLine2.SetRange("Return Order Line No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                                ReturnRcptLine2.SetFilter(Quantity, '<>0');
                                if ReturnRcptLine2.FindFirst then begin
                                    SalesLine2.SetCurrentKey("Document Type", "Shipment No.", "Shipment Line No.");
                                    SalesLine2.SetRange("Document Type", "Document Type"::"Credit Memo");
                                    SalesLine2.SetRange("Return Receipt No.", ReturnRcptLine2."Document No.");
                                    SalesLine2.SetRange("Return Receipt Line No.", ReturnRcptLine2."Line No.");
                                    if SalesLine2.Find('-') and (SalesLine2.Quantity <> 0) then
                                        ItemChargeAssgntSales2."Applies-to Doc. Line No." := SalesLine2."Line No."
                                    else
                                        InsertChargeAssgnt := false;
                                end else
                                    InsertChargeAssgnt := false;
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToSalesDoc(ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetReturnRcptLineFilters(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header")
    begin
    end;
}

