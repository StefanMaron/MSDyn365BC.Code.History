codeunit 5780 "Whse. Cross-Dock Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseLine: Record "Purchase Line";
        WhseMgt: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceType2: Integer;
        UseCrossDocking: Boolean;
        TemplateName: Code[10];
        NameNo: Code[20];
        LocationCode: Code[10];

    procedure GetUseCrossDock(var UseCrossDock: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Item.Get(ItemNo);
        if SKU.Get(LocationCode, ItemNo) then
            Item."Use Cross-Docking" := SKU."Use Cross-Docking";

        if Item."Use Cross-Docking" and Location."Use Cross-Docking" then
            UseCrossDock := true
        else
            UseCrossDock := false;
    end;

    procedure CalculateCrossDockLines(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    var
        TempWhseRcptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempWhseRcptLineWthSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        SetTemplate(NewTemplateName, NewNameNo, NewLocationCode);
        if TemplateName <> '' then
            exit;

        SeparateWhseRcptLinesWthSpecOrder(TempWhseRcptLineNoSpecOrder, TempWhseRcptLineWthSpecOrder, TempItemVariant);
        FilterCrossDockOpp(WhseCrossDockOpp);
        CalcCrossDockWithoutSpecOrder(WhseCrossDockOpp, TempWhseRcptLineNoSpecOrder, TempItemVariant);
        CalcCrossDockForSpecialOrder(WhseCrossDockOpp, TempWhseRcptLineWthSpecOrder);
    end;

    local procedure CalcCrossDockForSpecialOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var TempWhseRcptLine: Record "Warehouse Receipt Line" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with TempWhseRcptLine do
            if Find('-') then
                repeat
                    WhseRcptLine.Get("No.", "Line No.");
                    WhseCrossDockOpp.SetRange("Source Line No.", "Line No.");
                    WhseCrossDockOpp.DeleteAll();
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    CalculateCrossDock(
                      WhseCrossDockOpp, "Item No.", "Variant Code", LocationCode,
                      RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");

                    UpdateQtyToCrossDock(
                      WhseRcptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);
                until Next = 0;
    end;

    local procedure CalcCrossDockWithoutSpecOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var TempWhseRcptLine: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        NewItemVariant: Boolean;
    begin
        if TempItemVariant.FindSet then begin
            FilterWhseRcptLine(TempWhseRcptLine);
            repeat
                NewItemVariant := true;
                with TempWhseRcptLine do begin
                    SetRange("Item No.", TempItemVariant."Item No.");
                    SetRange("Variant Code", TempItemVariant.Code);
                    if Find('-') then
                        repeat
                            WhseRcptLine.Get("No.", "Line No.");
                            WhseCrossDockOpp.SetRange("Source Line No.", "Line No.");
                            WhseCrossDockOpp.DeleteAll();
                            if NewItemVariant then begin
                                GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                CalculateCrossDock(
                                  WhseCrossDockOpp, "Item No.", "Variant Code", LocationCode,
                                  RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");
                            end;
                            if NewItemVariant or (RemainingNeededQtyBase <> 0) then
                                UpdateQtyToCrossDock(
                                  WhseRcptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);

                            NewItemVariant := false;
                        until (Next = 0) or (RemainingNeededQtyBase = 0);
                end;
            until TempItemVariant.Next = 0;
        end;
    end;

    local procedure CalcRemainingNeededQtyBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; QtyToHandleBase: Decimal) RemainingNeededQtyBase: Decimal
    var
        Dummy: Decimal;
    begin
        CalcCrossDockedItems(ItemNo, VariantCode, '', LocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(LocationCode, ItemNo, VariantCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then begin
            RemainingNeededQtyBase := QtyToCrossDockBase - QtyToHandleBase;
            QtyToCrossDockBase := QtyToHandleBase
        end else
            RemainingNeededQtyBase := 0;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    procedure CalculateCrossDockLine(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; var QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; LineNo: Integer; QtyToHandleBase: Decimal)
    var
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        Dummy: Decimal;
    begin
        FilterCrossDockOpp(CrossDockOpp);
        CrossDockOpp.SetRange("Source Line No.", LineNo);
        CrossDockOpp.DeleteAll();

        CalculateCrossDock(
          CrossDockOpp, ItemNo, VariantCode, LocationCode, QtyNeededBase, QtyOnPickBase, QtyPickedBase, LineNo);

        CalcCrossDockedItems(ItemNo, VariantCode, '', LocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(LocationCode, ItemNo, VariantCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then
            QtyToCrossDockBase := QtyToHandleBase;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    local procedure CalculateCrossDock(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer)
    var
        Location: Record Location;
        QtyOnPick: Decimal;
        QtyPicked: Decimal;
        CrossDockDate: Date;
    begin
        Location.Get(LocationCode);
        if Format(Location."Cross-Dock Due Date Calc.") <> '' then
            CrossDockDate := CalcDate(Location."Cross-Dock Due Date Calc.", WorkDate)
        else
            CrossDockDate := WorkDate;

        CalcCrossDockToSalesOrder(CrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToTransferOrder(CrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToProdOrderComponent(CrossDockOpp, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToServiceOrder(CrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);

        CrossDockOpp.CalcSums("Qty. Needed (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");
        QtyNeededSumBase := CrossDockOpp."Qty. Needed (Base)";
        QtyOnPickSumBase := CrossDockOpp."Pick Qty. (Base)";
        QtyPickedSumBase := CrossDockOpp."Picked Qty. (Base)";
    end;

    local procedure InsertCrossDockLine(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; QtyOutstanding: Decimal; QtyOutstandingBase: Decimal; QtyOnPick: Decimal; QtyOnPickBase: Decimal; QtyPicked: Decimal; QtyPickedBase: Decimal; UOMCode: Code[10]; QtyPerUOM: Decimal; DueDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LineNo: Integer)
    begin
        if HasSpecialOrder and (SourceType <> DATABASE::"Sales Line") then
            exit;
        if (QtyOutstandingBase - QtyOnPickBase - QtyPickedBase) <= 0 then
            exit;

        with CrossDockOpp do begin
            Init;
            "Source Template Name" := TemplateName;
            "Source Name/No." := NameNo;
            "Source Line No." := LineNo;
            "Line No." := "Line No." + 10000;
            "To Source Type" := SourceType;
            "To Source Subtype" := SourceSubType;
            "To Source No." := SourceNo;
            "To Source Line No." := SourceLineNo;
            "To Source Subline No." := SourceSubLineNo;
            "To Source Document" := WhseMgt.GetSourceDocument("To Source Type", "To Source Subtype");
            "Due Date" := DueDate;
            "To-Src. Unit of Measure Code" := UOMCode;
            "To-Src. Qty. per Unit of Meas." := QtyPerUOM;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            "Location Code" := LocationCode;

            SubtractExistingCrossDockOppQtysToSource(CrossDockOpp);

            "Qty. Needed (Base)" := Maximum("Qty. Needed (Base)" + QtyOutstandingBase - QtyOnPickBase - QtyPickedBase, 0);
            "Qty. Needed" := Maximum("Qty. Needed" + QtyOutstanding - QtyOnPick - QtyPicked, 0);

            "Pick Qty. (Base)" := Maximum("Pick Qty. (Base)" + QtyOnPickBase, 0);
            "Pick Qty." := Maximum("Pick Qty." + QtyOnPick, 0);

            "Picked Qty. (Base)" := Maximum("Picked Qty. (Base)" + QtyPickedBase, 0);
            "Picked Qty." := Maximum("Picked Qty." + QtyPicked, 0);

            Insert;
        end;
    end;

    procedure ShowCrossDock(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; SourceTemplateName: Code[10]; SourceNameNo: Code[20]; SourceLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        CrossDockForm: Page "Cross-Dock Opportunities";
        QtyToCrossDock: Decimal;
    begin
        with CrossDockOpp do begin
            FilterGroup(2);
            SetRange("Source Template Name", SourceTemplateName);
            SetRange("Source Name/No.", SourceNameNo);
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            FilterGroup(0);
        end;
        ReceiptLine.Get(SourceNameNo, SourceLineNo);
        CrossDockForm.SetValues(ItemNo, VariantCode, LocationCode, SourceTemplateName, SourceNameNo, SourceLineNo,
          ReceiptLine."Unit of Measure Code", ReceiptLine."Qty. per Unit of Measure");
        CrossDockForm.LookupMode(true);
        CrossDockForm.SetTableView(CrossDockOpp);
        if CrossDockForm.RunModal = ACTION::LookupOK then begin
            CrossDockForm.GetValues(QtyToCrossDock);
            QtyToCrossDock := QtyToCrossDock / ReceiptLine."Qty. per Unit of Measure";
            if ReceiptLine."Qty. to Receive" < QtyToCrossDock then
                QtyToCrossDock := ReceiptLine."Qty. to Receive";
            ReceiptLine.Validate("Qty. to Cross-Dock", QtyToCrossDock);
            ReceiptLine.Modify();
            OnShowCrossDockOnAfterReceiptLineModify(ReceiptLine);
        end;
    end;

    procedure CalcCrossDockedItems(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; var QtyCrossDockedUOMBase: Decimal; var QtyCrossDockedAllUOMBase: Decimal)
    var
        BinContent: Record "Bin Content";
        QtyAvailToPickBase: Decimal;
    begin
        QtyCrossDockedUOMBase := 0;
        QtyCrossDockedAllUOMBase := 0;
        with BinContent do begin
            Reset;
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", true);
            if Find('-') then
                repeat
                    QtyAvailToPickBase := CalcQtyAvailToPick(0);
                    if "Unit of Measure Code" = UOMCode then
                        QtyCrossDockedUOMBase := QtyCrossDockedUOMBase + QtyAvailToPickBase;
                    QtyCrossDockedAllUOMBase := QtyCrossDockedAllUOMBase + QtyAvailToPickBase;
                until Next = 0;
        end;
    end;

    procedure CalcCrossDockReceivedNotCrossDocked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]) ReceivedNotCrossDockedQty: Decimal
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ReceivedCrossDockedQty: Decimal;
    begin
        ReceivedNotCrossDockedQty := 0;

        with PostedWhseReceiptLine do begin
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetFilter(Status, '%1|%2', Status::" ", Status::"Partially Put Away");
            SetFilter("Cross-Dock Bin Code", '<>%1', '');
            if FindSet then
                repeat
                    // calculate received, yet not put-away quantity, that is assumed to be put-away in a cross-dock bin
                    ReceivedCrossDockedQty := CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine);
                    ReceivedNotCrossDockedQty +=
                      Minimum(
                        Maximum("Qty. Cross-Docked (Base)" - ReceivedCrossDockedQty, 0),
                        "Qty. (Base)" - "Qty. Put Away (Base)");
                until Next = 0;
        end;
    end;

    procedure ShowBinContentsCrossDocked(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; FilterOnUOM: Boolean)
    var
        BinContent: Record "Bin Content";
        BinContentLookup: Page "Bin Contents List";
    begin
        with BinContent do begin
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", true);
            if FilterOnUOM then
                SetRange("Unit of Measure Code", UOMCode);
        end;
        with BinContentLookup do begin
            SetTableView(BinContent);
            Initialize(LocationCode);
            RunModal;
        end;
        Clear(BinContentLookup);
    end;

    local procedure GetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        if SourceType = DATABASE::"Purchase Line" then begin
            PurchaseLine.Get(SourceSubtype, SourceNo, SourceLineNo);
            SourceType2 := SourceType;
        end;
    end;

    local procedure CalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        QtyOnPickBase := 0;
        QtyPickedBase := 0;
        with WhseShptLine do begin
            Reset;
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            SetRange("Source Type", SourceType);
            SetRange("Source Subtype", SourceSubtype);
            SetRange("Source No.", SourceNo);
            SetRange("Source Line No.", SourceLineNo);
            if Find('-') then
                repeat
                    CalcFields("Pick Qty. (Base)", "Pick Qty.");
                    QtyOnPick := QtyOnPick + "Pick Qty.";
                    QtyOnPickBase := QtyOnPickBase + "Pick Qty. (Base)";
                    QtyPicked := QtyPicked + "Qty. Picked";
                    QtyPickedBase := QtyPickedBase + "Qty. Picked (Base)";
                until Next = 0;
            if QtyPickedBase = 0 then begin
                QtyPicked := Qty - OutstandingQty;
                QtyPickedBase := QtyBase - OutstandingQtyBase;
            end;
        end;
    end;

    procedure SetTemplate(NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
        TemplateName := NewTemplateName;
        NameNo := NewNameNo;
        LocationCode := NewLocationCode;
    end;

    local procedure SeparateWhseRcptLinesWthSpecOrder(var TempWhseRcptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary; var TempWhseRcptLineWthSpecOrder: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        FilterWhseRcptLine(WhseRcptLine);
        with WhseRcptLine do
            if FindSet then
                repeat
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    if HasSpecialOrder then begin
                        TempWhseRcptLineWthSpecOrder := WhseRcptLine;
                        TempWhseRcptLineWthSpecOrder.Insert();
                    end else begin
                        TempWhseRcptLineNoSpecOrder := WhseRcptLine;
                        TempWhseRcptLineNoSpecOrder.Insert();
                        InsertToItemList(WhseRcptLine, TempItemVariant);
                    end;
                until Next = 0;
    end;

    local procedure InsertToItemList(WhseRcptLine: Record "Warehouse Receipt Line"; var TempItemVariant: Record "Item Variant" temporary)
    begin
        with TempItemVariant do begin
            Init;
            "Item No." := WhseRcptLine."Item No.";
            Code := WhseRcptLine."Variant Code";
            if Insert() then;
        end;
    end;

    local procedure FilterWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
        with WhseRcptLine do begin
            SetRange("No.", NameNo);
            SetRange("Location Code", LocationCode);
            SetFilter("Qty. to Receive", '>0');
        end;
    end;

    local procedure FilterCrossDockOpp(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    begin
        with WhseCrossDockOpp do begin
            SetRange("Source Template Name", TemplateName);
            SetRange("Source Name/No.", NameNo);
            SetRange("Location Code", LocationCode);
        end;
    end;

    local procedure UpdateQtyToCrossDock(var WhseRcptLine: Record "Warehouse Receipt Line"; var RemainingNeededQtyBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal)
    begin
        with WhseRcptLine do begin
            GetUseCrossDock(UseCrossDocking, "Location Code", "Item No.");
            if not UseCrossDocking then
                exit;

            RemainingNeededQtyBase :=
              CalcRemainingNeededQtyBase(
                "Item No.", "Variant Code", RemainingNeededQtyBase,
                QtyToCrossDockBase, QtyOnCrossDockBase, "Qty. to Receive (Base)");
            Validate("Qty. to Cross-Dock", Round(QtyToCrossDockBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
            "Qty. to Cross-Dock (Base)" := QtyToCrossDockBase;
            Modify;
        end;

        OnAfterUpdateQtyToCrossDock(WhseRcptLine);
    end;

    local procedure HasSpecialOrder(): Boolean
    begin
        exit((SourceType2 = DATABASE::"Purchase Line") and PurchaseLine."Special Order");
    end;

    local procedure SubtractExistingCrossDockOppQtysToSource(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    var
        ExistingWhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity";
    begin
        with ExistingWhseCrossDockOpp do begin
            SetRange("To Source Type", WhseCrossDockOpp."To Source Type");
            SetRange("To Source Subtype", WhseCrossDockOpp."To Source Subtype");
            SetRange("To Source No.", WhseCrossDockOpp."To Source No.");
            SetRange("To Source Line No.", WhseCrossDockOpp."To Source Line No.");
            SetRange("To Source Subline No.", WhseCrossDockOpp."To Source Subline No.");
            SetRange("Item No.", WhseCrossDockOpp."Item No.");
            SetRange("Variant Code", WhseCrossDockOpp."Variant Code");
            CalcSums("Qty. to Cross-Dock (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");

            WhseCrossDockOpp."Qty. Needed" :=
              -Round("Qty. to Cross-Dock (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision);
            WhseCrossDockOpp."Qty. Needed (Base)" := -"Qty. to Cross-Dock (Base)";
            WhseCrossDockOpp."Pick Qty." :=
              -Round("Pick Qty. (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision);
            WhseCrossDockOpp."Pick Qty. (Base)" := -"Pick Qty. (Base)";
            WhseCrossDockOpp."Picked Qty." :=
              -Round("Picked Qty. (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision);
            WhseCrossDockOpp."Picked Qty. (Base)" := -"Picked Qty. (Base)";
        end;
    end;

    local procedure CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            SetRange("Whse. Document Type", "Whse. Document Type"::Receipt);
            SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
            SetFilter("Bin Code", PostedWhseReceiptLine."Cross-Dock Bin Code");
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)");
        end;
    end;

    local procedure CalcCrossDockToSalesOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with SalesLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Drop Shipment", false);
            SetRange("Location Code", LocationCode);
            SetRange("Shipment Date", 0D, CrossDockDate);
            SetFilter("Outstanding Qty. (Base)", '>0');
            if HasSpecialOrder then begin
                SetRange("Document No.", PurchaseLine."Special Order Sales No.");
                SetRange("Line No.", PurchaseLine."Special Order Sales Line No.");
            end else
                SetRange("Special Order", false);
            if Find('-') then
                repeat
                    if WhseRequest.Get(WhseRequest.Type::Outbound, "Location Code", DATABASE::"Sales Line", "Document Type", "Document No.") and
                       (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                    then begin
                        CalculatePickQty(
                          DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.",
                          QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, Quantity, "Quantity (Base)",
                          "Outstanding Quantity", "Outstanding Qty. (Base)");
                        InsertCrossDockLine(
                          WhseCrossDockOpp,
                          DATABASE::"Sales Line", "Document Type", "Document No.", "Line No.", 0,
                          Quantity, "Quantity (Base)", QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                          "Unit of Measure Code", "Qty. per Unit of Measure", "Shipment Date",
                          "No.", "Variant Code", LineNo);
                    end;
                until Next = 0;
        end;
    end;

    local procedure CalcCrossDockToTransferOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with TransferLine do begin
            SetRange("Transfer-from Code", LocationCode);
            SetRange(Status, Status::Released);
            SetRange("Derived From Line No.", 0);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Shipment Date", 0D, CrossDockDate);
            SetFilter("Outstanding Qty. (Base)", '>0');
            if Find('-') then
                repeat
                    if WhseRequest.Get(WhseRequest.Type::Outbound, "Transfer-from Code", DATABASE::"Transfer Line", 0, "Document No.") and
                       (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                    then begin
                        CalculatePickQty(
                          DATABASE::"Transfer Line", 0, "Document No.", "Line No.",
                          QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, Quantity, "Quantity (Base)",
                          "Outstanding Quantity", "Outstanding Qty. (Base)");
                        InsertCrossDockLine(
                          WhseCrossDockOpp,
                          DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0,
                          Quantity, "Quantity (Base)",
                          QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                          "Unit of Measure Code", "Qty. per Unit of Measure", "Shipment Date",
                          "Item No.", "Variant Code", LineNo);
                    end;
                until Next = 0;
        end;
    end;

    local procedure CalcCrossDockToProdOrderComponent(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        with ProdOrderComponent do begin
            SetRange(Status, Status::Released);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Location Code", LocationCode);
            SetRange("Due Date", 0D, CrossDockDate);
            SetRange("Flushing Method", "Flushing Method"::Manual);
            SetRange("Planning Level Code", 0);
            SetFilter("Remaining Qty. (Base)", '>0');
            if Find('-') then
                repeat
                    CalcFields("Pick Qty. (Base)");
                    InsertCrossDockLine(
                      WhseCrossDockOpp,
                      DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Line No.", "Prod. Order Line No.",
                      "Remaining Quantity", "Remaining Qty. (Base)",
                      "Pick Qty.", "Pick Qty. (Base)", "Qty. Picked", "Qty. Picked (Base)",
                      "Unit of Measure Code", "Qty. per Unit of Measure", "Due Date",
                      "Item No.", "Variant Code", LineNo);
                until Next = 0;
        end;
    end;

    local procedure CalcCrossDockToServiceOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with ServiceLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Location Code", LocationCode);
            SetRange("Needed by Date", 0D, CrossDockDate);
            SetFilter("Outstanding Qty. (Base)", '>0');
            if Find('-') then
                repeat
                    if WhseRequest.Get(WhseRequest.Type::Outbound, "Location Code", DATABASE::"Service Line", "Document Type", "Document No.") and
                       (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                    then begin
                        CalculatePickQty(
                          DATABASE::"Service Line", "Document Type", "Document No.", "Line No.",
                          QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, Quantity, "Quantity (Base)",
                          "Outstanding Quantity", "Outstanding Qty. (Base)");
                        InsertCrossDockLine(
                          WhseCrossDockOpp,
                          DATABASE::"Service Line", "Document Type", "Document No.", "Line No.", 0,
                          Quantity, "Quantity (Base)",
                          QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                          "Unit of Measure Code", "Qty. per Unit of Measure", "Needed by Date",
                          "No.", "Variant Code", LineNo);
                    end;
                until Next = 0;
        end;
    end;

    local procedure Maximum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 <= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQtyToCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCrossDockOnAfterReceiptLineModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;
}

