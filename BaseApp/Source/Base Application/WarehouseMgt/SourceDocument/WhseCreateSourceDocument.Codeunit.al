codeunit 5750 "Whse.-Create Source Document"
{

    trigger OnRun()
    begin
    end;

    procedure FromSalesLine2ShptLine(WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line") Result: Boolean
    var
        AsmHeader: Record "Assembly Header";
        TotalOutstandingWhseShptQty: Decimal;
        TotalOutstandingWhseShptQtyBase: Decimal;
        ATOWhseShptLineQty: Decimal;
        ATOWhseShptLineQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromSalesLine2ShptLine(SalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesLine.CalcFields("Whse. Outstanding Qty.", "ATO Whse. Outstanding Qty.",
          "Whse. Outstanding Qty. (Base)", "ATO Whse. Outstd. Qty. (Base)");
        TotalOutstandingWhseShptQty := Abs(SalesLine."Outstanding Quantity") - SalesLine."Whse. Outstanding Qty.";
        TotalOutstandingWhseShptQtyBase := Abs(SalesLine."Outstanding Qty. (Base)") - SalesLine."Whse. Outstanding Qty. (Base)";
        if SalesLine.AsmToOrderExists(AsmHeader) then begin
            ATOWhseShptLineQty := AsmHeader."Remaining Quantity" - SalesLine."ATO Whse. Outstanding Qty.";
            ATOWhseShptLineQtyBase := AsmHeader."Remaining Quantity (Base)" - SalesLine."ATO Whse. Outstd. Qty. (Base)";
            OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WhseShptHeader, AsmHeader, SalesLine, ATOWhseShptLineQty, ATOWhseShptLineQtyBase);
            if ATOWhseShptLineQtyBase > 0 then begin
                if not CreateShptLineFromSalesLine(WhseShptHeader, SalesLine, ATOWhseShptLineQty, ATOWhseShptLineQtyBase, true) then
                    exit(false);
                TotalOutstandingWhseShptQty -= ATOWhseShptLineQty;
                TotalOutstandingWhseShptQtyBase -= ATOWhseShptLineQtyBase;
            end;
        end;

        OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(
          WhseShptHeader, SalesLine, TotalOutstandingWhseShptQty, TotalOutstandingWhseShptQtyBase);

        if TotalOutstandingWhseShptQtyBase > 0 then
            exit(CreateShptLineFromSalesLine(WhseShptHeader, SalesLine, TotalOutstandingWhseShptQty, TotalOutstandingWhseShptQtyBase, false));
        exit(true);
    end;

    local procedure CreateShptLineFromSalesLine(WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; WhseShptLineQty: Decimal; WhseShptLineQtyBase: Decimal; AssembleToOrder: Boolean): Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        with WhseShptLine do begin
            InitNewLine(WhseShptHeader."No.");
            SetSource(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
            SalesLine.TestField("Unit of Measure Code");
            SetItemData(
              SalesLine."No.", SalesLine.Description, SalesLine."Description 2", SalesLine."Location Code",
              SalesLine."Variant Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
              SalesLine."Qty. Rounding Precision", SalesLine."Qty. Rounding Precision (Base)");
            OnAfterInitNewWhseShptLine(WhseShptLine, WhseShptHeader, SalesLine, AssembleToOrder);
            SetQtysOnShptLine(WhseShptLine, WhseShptLineQty, WhseShptLineQtyBase);
            "Assemble to Order" := AssembleToOrder;
            if SalesLine."Document Type" = SalesLine."Document Type"::Order then
                "Due Date" := SalesLine."Planned Shipment Date";
            if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
                "Due Date" := WorkDate();
            if WhseShptHeader."Shipment Date" = 0D then
                "Shipment Date" := SalesLine."Shipment Date"
            else
                "Shipment Date" := WhseShptHeader."Shipment Date";
            "Destination Type" := "Destination Type"::Customer;
            "Destination No." := SalesLine."Sell-to Customer No.";
            "Shipping Advice" := SalesHeader."Shipping Advice";
            if "Location Code" = WhseShptHeader."Location Code" then
                "Bin Code" := WhseShptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := SalesLine."Bin Code";
            UpdateShptLine(WhseShptLine, WhseShptHeader);
            OnBeforeCreateShptLineFromSalesLine(WhseShptLine, WhseShptHeader, SalesLine, SalesHeader);
            CreateShptLine(WhseShptLine);
            OnAfterCreateShptLineFromSalesLine(WhseShptLine, WhseShptHeader, SalesLine, SalesHeader);
            exit(not HasErrorOccured());
        end;
    end;

    procedure SalesLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line"): Boolean
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLine2ReceiptLine(WhseReceiptHeader, SalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        WhseReceiptLine.InitNewLine(WhseReceiptHeader."No.");
        WhseReceiptLine.SetSource(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Unit of Measure Code");
        WhseReceiptLine.SetItemData(
            SalesLine."No.", SalesLine.Description, SalesLine."Description 2", SalesLine."Location Code",
            SalesLine."Variant Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
            SalesLine."Qty. Rounding Precision", SalesLine."Qty. Rounding Precision (Base)");
        OnSalesLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, SalesLine);
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order:
                begin
                    WhseReceiptLine.Validate("Qty. Received", Abs(SalesLine."Quantity Shipped"));
                    WhseReceiptLine."Due Date" := SalesLine."Planned Shipment Date";
                end;
            SalesLine."Document Type"::"Return Order":
                begin
                    WhseReceiptLine.Validate("Qty. Received", Abs(SalesLine."Return Qty. Received"));
                    WhseReceiptLine."Due Date" := WorkDate();
                end;
        end;
        SetQtysOnRcptLine(WhseReceiptLine, Abs(SalesLine.Quantity), Abs(SalesLine."Quantity (Base)"));
        WhseReceiptLine."Starting Date" := SalesLine."Shipment Date";
        if WhseReceiptLine."Location Code" = WhseReceiptHeader."Location Code" then
            WhseReceiptLine."Bin Code" := WhseReceiptHeader."Bin Code";
        if WhseReceiptLine."Bin Code" = '' then
            WhseReceiptLine."Bin Code" := SalesLine."Bin Code";
        OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(WhseReceiptLine, SalesLine);
        UpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader);
        OnBeforeCreateReceiptLineFromSalesLine(WhseReceiptLine, WhseReceiptHeader, SalesLine);
        CreateReceiptLine(WhseReceiptLine);
        OnAfterCreateRcptLineFromSalesLine(WhseReceiptLine, WhseReceiptHeader, SalesLine);
        exit(not WhseReceiptLine.HasErrorOccured());
    end;

    procedure FromServiceLine2ShptLine(WhseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"): Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        ServiceHeader: Record "Service Header";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromService2ShptLine(WhseShptHeader, ServiceLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        WhseShptLine.InitNewLine(WhseShptHeader."No.");
        WhseShptLine.SetSource(DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.");
        ServiceLine.TestField("Unit of Measure Code");
        WhseShptLine.SetItemData(
            ServiceLine."No.", ServiceLine.Description, ServiceLine."Description 2", ServiceLine."Location Code",
            ServiceLine."Variant Code", ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure",
            ServiceLine."Qty. Rounding Precision", ServiceLine."Qty. Rounding Precision (Base)");
        OnFromServiceLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, ServiceLine);
        SetQtysOnShptLine(WhseShptLine, Abs(ServiceLine."Outstanding Quantity"), Abs(ServiceLine."Outstanding Qty. (Base)"));
        if ServiceLine."Document Type" = ServiceLine."Document Type"::Order then
            WhseShptLine."Due Date" := ServiceLine.GetDueDate();
        if WhseShptHeader."Shipment Date" = 0D then
            WhseShptLine."Shipment Date" := ServiceLine.GetShipmentDate()
        else
            WhseShptLine."Shipment Date" := WhseShptHeader."Shipment Date";
        WhseShptLine."Destination Type" := "Warehouse Destination Type"::Customer;
        WhseShptLine."Destination No." := ServiceLine."Bill-to Customer No.";
        WhseShptLine."Shipping Advice" := ServiceHeader."Shipping Advice";
        if WhseShptLine."Location Code" = WhseShptHeader."Location Code" then
            WhseShptLine."Bin Code" := WhseShptHeader."Bin Code";
        if WhseShptLine."Bin Code" = '' then
            WhseShptLine."Bin Code" := ServiceLine."Bin Code";
        UpdateShptLine(WhseShptLine, WhseShptHeader);
        OnFromServiceLine2ShptLineOnBeforeCreateShptLine(WhseShptLine, WhseShptHeader, ServiceHeader, ServiceLine);
        CreateShptLine(WhseShptLine);
        OnAfterCreateShptLineFromServiceLine(WhseShptLine, WhseShptHeader, ServiceLine);
        exit(not WhseShptLine.HasErrorOccured());
    end;

    procedure FromPurchLine2ShptLine(WhseShptHeader: Record "Warehouse Shipment Header"; PurchLine: Record "Purchase Line") Result: Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromPurchLine2ShptLine(PurchLine, Result, IsHandled, WhseShptHeader);
        if IsHandled then
            exit(Result);

        with WhseShptLine do begin
            InitNewLine(WhseShptHeader."No.");
            SetSource(DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            PurchLine.TestField("Unit of Measure Code");
            SetItemData(
              PurchLine."No.", PurchLine.Description, PurchLine."Description 2", PurchLine."Location Code",
              PurchLine."Variant Code", PurchLine."Unit of Measure Code", PurchLine."Qty. per Unit of Measure",
              PurchLine."Qty. Rounding Precision", PurchLine."Qty. Rounding Precision (Base)");
            OnFromPurchLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, PurchLine);
            SetQtysOnShptLine(WhseShptLine, Abs(PurchLine."Outstanding Quantity"), Abs(PurchLine."Outstanding Qty. (Base)"));
            if PurchLine."Document Type" = PurchLine."Document Type"::Order then
                "Due Date" := PurchLine."Expected Receipt Date";
            if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then
                "Due Date" := WorkDate();
            if WhseShptHeader."Shipment Date" = 0D then
                "Shipment Date" := PurchLine."Planned Receipt Date"
            else
                "Shipment Date" := WhseShptHeader."Shipment Date";
            "Destination Type" := "Destination Type"::Vendor;
            "Destination No." := PurchLine."Buy-from Vendor No.";
            if "Location Code" = WhseShptHeader."Location Code" then
                "Bin Code" := WhseShptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := PurchLine."Bin Code";
            UpdateShptLine(WhseShptLine, WhseShptHeader);
            OnFromPurchLine2ShptLineOnBeforeCreateShptLine(WhseShptLine, WhseShptHeader, PurchLine);
            OnBeforeCreateShptLineFromPurchLine(WhseShptLine, WhseShptHeader, PurchLine);
            CreateShptLine(WhseShptLine);
            OnAfterCreateShptLineFromPurchLine(WhseShptLine, WhseShptHeader, PurchLine);
            exit(not HasErrorOccured());
        end;
    end;

    procedure PurchLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchLine: Record "Purchase Line"): Boolean
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchLine2ReceiptLine(WhseReceiptHeader, PurchLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with WhseReceiptLine do begin
            InitNewLine(WhseReceiptHeader."No.");
            SetSource(DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            PurchLine.TestField("Unit of Measure Code");
            SetItemData(
              PurchLine."No.", PurchLine.Description, PurchLine."Description 2", PurchLine."Location Code",
              PurchLine."Variant Code", PurchLine."Unit of Measure Code", PurchLine."Qty. per Unit of Measure",
              PurchLine."Qty. Rounding Precision", PurchLine."Qty. Rounding Precision (Base)");
            IsHandled := false;
            OnPurchLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, PurchLine, IsHandled);
            if not IsHandled then begin
                case PurchLine."Document Type" of
                    PurchLine."Document Type"::Order:
                        begin
                            Validate("Qty. Received", Abs(PurchLine."Quantity Received"));
                            "Due Date" := PurchLine."Expected Receipt Date";
                        end;
                    PurchLine."Document Type"::"Return Order":
                        begin
                            Validate("Qty. Received", Abs(PurchLine."Return Qty. Shipped"));
                            "Due Date" := WorkDate();
                        end;
                end;
                SetQtysOnRcptLine(WhseReceiptLine, Abs(PurchLine.Quantity), Abs(PurchLine."Quantity (Base)"));
            end;
            OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(WhseReceiptLine, PurchLine);
            "Starting Date" := PurchLine."Planned Receipt Date";
            if "Location Code" = WhseReceiptHeader."Location Code" then
                "Bin Code" := WhseReceiptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := PurchLine."Bin Code";
            UpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader);
            OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader, PurchLine);
            CreateReceiptLine(WhseReceiptLine);
            OnAfterCreateRcptLineFromPurchLine(WhseReceiptLine, WhseReceiptHeader, PurchLine);
            exit(not HasErrorOccured());
        end;
    end;

    procedure FromTransLine2ShptLine(WhseShptHeader: Record "Warehouse Shipment Header"; TransLine: Record "Transfer Line") Result: Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        TransHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromTransLine2ShptLine(TransLine, Result, IsHandled, WhseShptHeader);
        if IsHandled then
            exit(Result);

        with WhseShptLine do begin
            InitNewLine(WhseShptHeader."No.");
            SetSource(DATABASE::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.");
            TransLine.TestField("Unit of Measure Code");
            SetItemData(
              TransLine."Item No.", TransLine.Description, TransLine."Description 2", TransLine."Transfer-from Code",
              TransLine."Variant Code", TransLine."Unit of Measure Code", TransLine."Qty. per Unit of Measure",
              TransLine."Qty. Rounding Precision", TransLine."Qty. Rounding Precision (Base)");
            OnFromTransLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, TransLine);
            SetQtysOnShptLine(WhseShptLine, TransLine."Outstanding Quantity", TransLine."Outstanding Qty. (Base)");
            "Due Date" := TransLine."Shipment Date";
            if WhseShptHeader."Shipment Date" = 0D then
                "Shipment Date" := WorkDate()
            else
                "Shipment Date" := WhseShptHeader."Shipment Date";
            "Destination Type" := "Destination Type"::Location;
            "Destination No." := TransLine."Transfer-to Code";
            if TransHeader.Get(TransLine."Document No.") then
                "Shipping Advice" := TransHeader."Shipping Advice";
            if "Location Code" = WhseShptHeader."Location Code" then
                "Bin Code" := WhseShptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := TransLine."Transfer-from Bin Code";
            UpdateShptLine(WhseShptLine, WhseShptHeader);
            OnBeforeCreateShptLineFromTransLine(WhseShptLine, WhseShptHeader, TransLine, TransHeader);
            CreateShptLine(WhseShptLine);
            OnAfterCreateShptLineFromTransLine(WhseShptLine, WhseShptHeader, TransLine, TransHeader);
            exit(not HasErrorOccured());
        end;
    end;

    procedure TransLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; TransLine: Record "Transfer Line") Result: Boolean
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        UnitOfMeasureMgt: Codeunit "Unit of Measure Management";
        WhseInbndOtsdgQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransLine2ReceiptLine(WhseReceiptHeader, TransLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with WhseReceiptLine do begin
            InitNewLine(WhseReceiptHeader."No.");
            SetSource(DATABASE::"Transfer Line", 1, TransLine."Document No.", TransLine."Line No.");
            TransLine.TestField("Unit of Measure Code");
            SetItemData(
              TransLine."Item No.", TransLine.Description, TransLine."Description 2", TransLine."Transfer-to Code",
              TransLine."Variant Code", TransLine."Unit of Measure Code", TransLine."Qty. per Unit of Measure",
              TransLine."Qty. Rounding Precision", TransLine."Qty. Rounding Precision (Base)");
            OnTransLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, TransLine);
            Validate("Qty. Received", TransLine."Quantity Received");
            TransLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
            WhseInbndOtsdgQty :=
              UnitOfMeasureMgt.CalcQtyFromBase(
                TransLine."Item No.", TransLine."Variant Code", TransLine."Unit of Measure Code",
                TransLine."Whse. Inbnd. Otsdg. Qty (Base)", TransLine."Qty. per Unit of Measure");
            SetQtysOnRcptLine(
              WhseReceiptLine,
              TransLine."Quantity Received" + TransLine."Qty. in Transit" - WhseInbndOtsdgQty,
              TransLine."Qty. Received (Base)" + TransLine."Qty. in Transit (Base)" - TransLine."Whse. Inbnd. Otsdg. Qty (Base)");
            "Due Date" := TransLine."Receipt Date";
            "Starting Date" := WorkDate();
            if "Location Code" = WhseReceiptHeader."Location Code" then
                "Bin Code" := WhseReceiptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := TransLine."Transfer-To Bin Code";
            OnBeforeUpdateRcptLineFromTransLine(WhseReceiptLine, TransLine);
            UpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader);
            CreateReceiptLine(WhseReceiptLine);
            OnAfterCreateRcptLineFromTransLine(WhseReceiptLine, WhseReceiptHeader, TransLine);
            exit(not HasErrorOccured());
        end;
    end;

    local procedure CreateShptLine(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        Item: Record Item;
    begin
        with WhseShptLine do begin
            Item."No." := "Item No.";
            Item.ItemSKUGet(Item, "Location Code", "Variant Code");
            "Shelf No." := Item."Shelf No.";
            OnBeforeWhseShptLineInsert(WhseShptLine);
            Insert();
            OnAfterWhseShptLineInsert(WhseShptLine);
            CreateWhseItemTrackingLines();
        end;

        OnAfterCreateShptLine(WhseShptLine);
    end;

    local procedure SetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Qty: Decimal; QtyBase: Decimal)
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtysOnShptLine(WarehouseShipmentLine, Qty, QtyBase, IsHandled);
        if IsHandled then
            exit;

        with WarehouseShipmentLine do begin
            Quantity := Qty;
            "Qty. (Base)" := QtyBase;
            InitOutstandingQtys();
            CheckSourceDocLineQty();
            if Location.Get("Location Code") then
                CheckBin(0, 0);
        end;
    end;

    local procedure CreateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReceiptLine(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        with WhseReceiptLine do begin
            Item."No." := "Item No.";
            Item.ItemSKUGet(Item, "Location Code", "Variant Code");
            "Shelf No." := Item."Shelf No.";
            Status := GetLineStatus();
            OnBeforeWhseReceiptLineInsert(WhseReceiptLine);
            Insert();
            OnAfterWhseReceiptLineInsert(WhseReceiptLine);
        end;
    end;

    local procedure SetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    begin
        with WarehouseReceiptLine do begin
            Quantity := Qty;
            "Qty. (Base)" := QtyBase;
            InitOutstandingQtys();
        end;

        OnAfterSetQtysOnRcptLine(WarehouseReceiptLine, Qty, QtyBase);
    end;

    local procedure UpdateShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShptLine(WhseShptLine, WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        with WhseShptLine do begin
            if WhseShptHeader."Zone Code" <> '' then
                Validate("Zone Code", WhseShptHeader."Zone Code");
            if WhseShptHeader."Bin Code" <> '' then
                Validate("Bin Code", WhseShptHeader."Bin Code");
        end;
    end;

    local procedure UpdateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader, IsHandled);
        if not IsHandled then begin
            with WhseReceiptLine do begin
                if WhseReceiptHeader."Zone Code" <> '' then
                    Validate("Zone Code", WhseReceiptHeader."Zone Code");
                if WhseReceiptHeader."Bin Code" <> '' then
                    Validate("Bin Code", WhseReceiptHeader."Bin Code");
                if WhseReceiptHeader."Cross-Dock Zone Code" <> '' then
                    Validate("Cross-Dock Zone Code", WhseReceiptHeader."Cross-Dock Zone Code");
                if WhseReceiptHeader."Cross-Dock Bin Code" <> '' then
                    Validate("Cross-Dock Bin Code", WhseReceiptHeader."Cross-Dock Bin Code");
            end;
            OnAfterUpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader);
        end;
    end;

    procedure CheckIfFromSalesLine2ShptLine(SalesLine: Record "Sales Line"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfSalesLine2ShptLine(SalesLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if SalesLine.IsNonInventoriableItem() then
            exit(false);

        SalesLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(Abs(SalesLine."Outstanding Qty. (Base)") > Abs(SalesLine."Whse. Outstanding Qty. (Base)"));
    end;

    procedure CheckIfFromServiceLine2ShptLin(ServiceLine: Record "Service Line"): Boolean
    begin
        ServiceLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(
          (Abs(ServiceLine."Outstanding Qty. (Base)") > Abs(ServiceLine."Whse. Outstanding Qty. (Base)")) and
          (ServiceLine."Qty. to Consume (Base)" = 0));
    end;

    procedure CheckIfSalesLine2ReceiptLine(SalesLine: Record "Sales Line"): Boolean
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfSalesLine2ReceiptLine(SalesLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if SalesLine.IsNonInventoriableItem() then
            exit(false);

        with WhseReceiptLine do begin
            WhseManagement.SetSourceFilterForWhseRcptLine(
              WhseReceiptLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
            CalcSums("Qty. Outstanding (Base)");
            exit(Abs(SalesLine."Outstanding Qty. (Base)") > Abs("Qty. Outstanding (Base)"));
        end;
    end;

    procedure CheckIfFromPurchLine2ShptLine(PurchLine: Record "Purchase Line"): Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfPurchLine2ShptLine(PurchLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLine.IsNonInventoriableItem() then
            exit(false);

        with WhseShptLine do begin
            SetSourceFilter(DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.", false);
            CalcSums("Qty. Outstanding (Base)");
            exit(Abs(PurchLine."Outstanding Qty. (Base)") > "Qty. Outstanding (Base)");
        end;
    end;

    procedure CheckIfPurchLine2ReceiptLine(PurchLine: Record "Purchase Line"): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfPurchLine2ReceiptLine(PurchLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLine.IsNonInventoriableItem() then
            exit(false);

        PurchLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(Abs(PurchLine."Outstanding Qty. (Base)") > Abs(PurchLine."Whse. Outstanding Qty. (Base)"));
    end;

    procedure CheckIfFromTransLine2ShptLine(TransLine: Record "Transfer Line"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTransLine2ShipmentLine(TransLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        if Location.GetLocationSetup(TransLine."Transfer-from Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);

        TransLine.CalcFields("Whse Outbnd. Otsdg. Qty (Base)");
        exit(TransLine."Outstanding Qty. (Base)" > TransLine."Whse Outbnd. Otsdg. Qty (Base)");
    end;

    procedure CheckIfTransLine2ReceiptLine(TransLine: Record "Transfer Line"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTransLine2ReceiptLine(TransLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        TransLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
        if Location.GetLocationSetup(TransLine."Transfer-to Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);
        exit(TransLine."Qty. in Transit (Base)" > TransLine."Whse. Inbnd. Otsdg. Qty (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewWhseShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; AssembleToOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfSalesLine2ReceiptLine(var SalesLine: Record "Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfSalesLine2ShptLine(var SalesLine: Record "Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPurchLine2ReceiptLine(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPurchLine2ShptLine(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceiptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromPurchLine2ShptLine(var PurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromTransLine2ShptLine(var TransLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromSalesLine2ShptLine(var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var TransLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromPurchLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromTransLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; var TotalOutstandingWhseShptQty: Decimal; var TotalOutstandingWhseShptQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromService2ShptLine(WarehouseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; AsmHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line"; var ATOWhseShptLineQty: Decimal; var ATOWhseShptLineQtyBase: Decimal)
    begin
    end;
}

