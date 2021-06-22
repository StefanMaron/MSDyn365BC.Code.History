codeunit 5777 "Whse. Validate Source Line"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'must not be changed when a %1 for this %2 exists: ';
        Text001: Label 'The %1 cannot be deleted when a related %2 exists.';
        Text002: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.';
        WhseActivLine: Record "Warehouse Activity Line";
        TableCaptionValue: Text[100];

    procedure SalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::"Sales Line", NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.", 0,
             NewSalesLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewSalesLine);
        OldRecRef.GetTable(OldSalesLine);
        with NewSalesLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Drop Shipment"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Purchase Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Purch. Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Job No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Ship"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Assemble to Order"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Shipment Date"));
        end;

        OnAfterSalesLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure SalesLineDelete(var SalesLine: Record "Sales Line")
    begin
        if WhseLinesExist(
             DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.",
             SalesLine."Line No.", 0, SalesLine.Quantity)
        then
            Error(Text001, SalesLine.TableCaption, TableCaptionValue);

        OnAfterSalesLineDelete(SalesLine);
    end;

    procedure ServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::"Service Line", NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.", 0,
             NewServiceLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewServiceLine);
        OldRecRef.GetTable(OldServiceLine);
        with NewServiceLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
        end;

        OnAfterServiceLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure ServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        if WhseLinesExist(
             DATABASE::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.",
             ServiceLine."Line No.", 0, ServiceLine.Quantity)
        then
            Error(Text001, ServiceLine.TableCaption, TableCaptionValue);

        OnAfterServiceLineDelete(ServiceLine);
    end;

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, StrSubstNo(Text000, TableCaptionValue, NewRecRef.Caption));
    end;

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    begin
        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, ErrorMessage);
    end;

    local procedure VerifyFieldHasSameValue(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    var
        FirstFieldRef: FieldRef;
        SecondFieldRef: FieldRef;
    begin
        FirstFieldRef := FirstRecordRef.Field(FieldNumber);
        SecondFieldRef := SecondRecordRef.Field(FieldNumber);

        if Format(FirstFieldRef.Value) <> Format(SecondFieldRef.Value) then
            FirstFieldRef.FieldError(ErrorMessage);
    end;

    procedure PurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        if not WhseLinesExist(
             DATABASE::"Purchase Line", NewPurchLine."Document Type", NewPurchLine."Document No.",
             NewPurchLine."Line No.", 0, NewPurchLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewPurchLine);
        OldRecRef.GetTable(OldPurchLine);
        with NewPurchLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Drop Shipment"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Sales Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Sales Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order Sales No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order Sales Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Job No."));
            if not OverReceiptMgt.IsQuantityUpdatedFromWarehouseOverReceipt(NewPurchLine) then
                VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Receive"));
        end;

        OnAfterPurchaseLineVerifyChange(NewPurchLine, OldPurchLine, NewRecRef, OldRecRef);
    end;

    procedure PurchaseLineDelete(var PurchLine: Record "Purchase Line")
    begin
        if WhseLinesExist(
             DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.", 0, PurchLine.Quantity)
        then
            Error(Text001, PurchLine.TableCaption, TableCaptionValue);

        OnAfterPurchaseLineDelete(PurchLine);
    end;

    procedure TransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    begin
        with NewTransLine do begin
            if WhseLinesExist(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity) then begin
                TransLineCommonVerification(NewTransLine, OldTransLine);
                if "Qty. to Ship" <> OldTransLine."Qty. to Ship" then
                    FieldError("Qty. to Ship", StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;

            if WhseLinesExist(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity) then begin
                TransLineCommonVerification(NewTransLine, OldTransLine);
                if "Qty. to Receive" <> OldTransLine."Qty. to Receive" then
                    FieldError("Qty. to Receive", StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;
        end;

        OnAfterTransLineVerifyChange(NewTransLine, OldTransLine);
    end;

    local procedure TransLineCommonVerification(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        with NewTransLine do begin
            if "Item No." <> OldTransLine."Item No." then
                FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            if "Variant Code" <> OldTransLine."Variant Code" then
                FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            if "Unit of Measure Code" <> OldTransLine."Unit of Measure Code" then
                FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            IsHandled := false;
            OnTransLineCommonVerificationOnBeforeQuantityCheck(NewTransLine, OldTransLine, IsHandled);
            if not IsHandled then
                if Quantity <> OldTransLine.Quantity then
                    FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, TableCaption));
        end;
    end;

    procedure TransLineDelete(var TransLine: Record "Transfer Line")
    begin
        with TransLine do begin
            if WhseLinesExist(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity) then
                Error(Text001, TableCaption, TableCaptionValue);
            if WhseLinesExist(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity) then
                Error(Text001, TableCaption, TableCaptionValue);
        end;

        OnAfterTransLineDelete(TransLine);
    end;

    procedure WhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal): Boolean
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if not WhseRcptLine.ReadPermission then
            exit;
        if ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 1))
        then begin
            WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            if not WhseRcptLine.IsEmpty then begin
                TableCaptionValue := WhseRcptLine.TableCaption;
                exit(true);
            end;
        end;

        if ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 0)) or
           ((SourceType = DATABASE::"Service Line") and (SourceSubType = 1))
        then begin
            WhseShptLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            if not WhseShptLine.IsEmpty then begin
                TableCaptionValue := WhseShptLine.TableCaption;
                exit(true);
            end;
        end;

        WhseActivLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, true);
        if not WhseActivLine.IsEmpty then begin
            TableCaptionValue := WhseActivLine.TableCaption;
            exit(true);
        end;

        TableCaptionValue := '';
        exit(false);
    end;

    procedure WhseLinesExistWithTableCaptionOut(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValueOut: Text[100]): Boolean
    var
        Success: Boolean;
    begin
        Success := WhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty);
        TableCaptionValueOut := TableCaptionValue;
        exit(Success);
    end;

    procedure ProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::"Prod. Order Component", NewProdOrderComp.Status, NewProdOrderComp."Prod. Order No.",
             NewProdOrderComp."Prod. Order Line No.", NewProdOrderComp."Line No.", NewProdOrderComp.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewProdOrderComp);
        OldRecRef.GetTable(OldProdOrderComp);
        with NewProdOrderComp do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Status));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Item No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity per"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Expected Quantity"));
        end;

        OnAfterProdComponentVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure ProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
        if WhseLinesExist(
             DATABASE::"Prod. Order Component",
             ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.",
             ProdOrderComp."Line No.", ProdOrderComp.Quantity)
        then
            Error(Text001, ProdOrderComp.TableCaption, TableCaptionValue);

        OnAfterProdComponentDelete(ProdOrderComp);
    end;

    procedure ItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        AssemblyLine: Record "Assembly Line";
        ProdOrderComp: Record "Prod. Order Component";
        Location: Record Location;
        LinesExist: Boolean;
        QtyChecked: Boolean;
        QtyRemainingToBePicked: Decimal;
    begin
        with NewItemJnlLine do begin
            case "Entry Type" of
                "Entry Type"::"Assembly Consumption":
                    begin
                        TestField("Order Type", "Order Type"::Assembly);
                        if Location.Get("Location Code") and Location."Require Pick" and Location."Require Shipment" then
                            if AssemblyLine.Get(AssemblyLine."Document Type"::Order, "Order No.", "Order Line No.") and
                               (Quantity >= 0)
                            then begin
                                QtyRemainingToBePicked := Quantity - AssemblyLine.CalcQtyPickedNotConsumed;
                                if QtyRemainingToBePicked > 0 then
                                    Error(Text002, "Order No.", QtyRemainingToBePicked);
                                QtyChecked := true;
                            end;

                        LinesExist := false;
                    end;
                "Entry Type"::Consumption:
                    begin
                        TestField("Order Type", "Order Type"::Production);
                        if Location.Get("Location Code") and Location."Require Pick" and Location."Require Shipment" then
                            if ProdOrderComp.Get(
                                 ProdOrderComp.Status::Released,
                                 "Order No.", "Order Line No.", "Prod. Order Comp. Line No.") and
                               (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::Manual) and
                               (Quantity >= 0)
                            then begin
                                QtyRemainingToBePicked :=
                                  Quantity - CalcNextLevelProdOutput(ProdOrderComp) -
                                  ProdOrderComp."Qty. Picked" + ProdOrderComp."Expected Quantity" - ProdOrderComp."Remaining Quantity";
                                if QtyRemainingToBePicked > 0 then
                                    Error(Text002, "Order No.", QtyRemainingToBePicked);
                                QtyChecked := true;
                            end;

                        LinesExist :=
                          WhseLinesExist(
                            DATABASE::"Prod. Order Component", 3, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.", Quantity);
                    end;
                "Entry Type"::Output:
                    begin
                        TestField("Order Type", "Order Type"::Production);
                        LinesExist :=
                          WhseLinesExist(
                            DATABASE::"Prod. Order Line", 3, "Order No.", "Order Line No.", 0, Quantity);
                    end;
                else
                    LinesExist := false;
            end;

            if LinesExist then begin
                if ("Item No." <> OldItemJnlLine."Item No.") and
                   (OldItemJnlLine."Item No." <> '')
                then
                    FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Variant Code" <> OldItemJnlLine."Variant Code") and
                   (OldItemJnlLine."Variant Code" <> '')
                then
                    FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Location Code" <> OldItemJnlLine."Location Code") and
                   (OldItemJnlLine."Location Code" <> '')
                then
                    FieldError("Location Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Unit of Measure Code" <> OldItemJnlLine."Unit of Measure Code") and
                   (OldItemJnlLine."Unit of Measure Code" <> '')
                then
                    FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if (Quantity <> OldItemJnlLine.Quantity) and
                   (OldItemJnlLine.Quantity <> 0) and
                   not QtyChecked
                then
                    FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;
        end;

        OnAfterItemLineVerifyChange(NewItemJnlLine, OldItemJnlLine);
    end;

    procedure ProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::"Prod. Order Line", NewProdOrderLine.Status, NewProdOrderLine."Prod. Order No.",
             NewProdOrderLine."Line No.", 0, NewProdOrderLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewProdOrderLine);
        OldRecRef.GetTable(OldProdOrderLine);
        with NewProdOrderLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Status));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Item No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
        end;

        OnAfterProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine, NewRecRef, OldRecRef);
    end;

    procedure ProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        with ProdOrderLine do
            if WhseLinesExist(
                 DATABASE::"Prod. Order Line", Status, "Prod. Order No.", "Line No.", 0, Quantity)
            then
                Error(Text001, TableCaption, TableCaptionValue);

        OnAfterProdOrderLineDelete(ProdOrderLine);
    end;

    procedure AssemblyLineVerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        Location: Record Location;
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if OldAssemblyLine.Type <> OldAssemblyLine.Type::Item then
            exit;

        if not WhseLinesExist(
             DATABASE::"Assembly Line", NewAssemblyLine."Document Type", NewAssemblyLine."Document No.",
             NewAssemblyLine."Line No.", 0, NewAssemblyLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewAssemblyLine);
        OldRecRef.GetTable(OldAssemblyLine);
        with NewAssemblyLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Document Type"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Document No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity per"));
            if Location.Get("Location Code") and not Location."Require Shipment" then
                VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity to Consume"));
        end;

        OnAfterAssemblyLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure AssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        if WhseLinesExist(
             DATABASE::"Assembly Line", AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.", 0,
             AssemblyLine.Quantity)
        then
            Error(Text001, AssemblyLine.TableCaption, TableCaptionValue);

        OnAfterAssemblyLineDelete(AssemblyLine);
    end;

    procedure CalcNextLevelProdOutput(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        Item: Record Item;
        WhseEntry: Record "Warehouse Entry";
        ProdOrderLine: Record "Prod. Order Line";
        OutputBase: Decimal;
    begin
        Item.Get(ProdOrderComp."Item No.");
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            exit(0);

        ProdOrderLine.SetRange(Status, ProdOrderComp.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderLine.SetRange("Item No.", ProdOrderComp."Item No.");
        ProdOrderLine.SetRange("Planning Level Code", ProdOrderComp."Planning Level Code");
        if ProdOrderLine.FindFirst then begin
            WhseEntry.SetSourceFilter(
              DATABASE::"Item Journal Line", 5, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", true); // Output Journal
            WhseEntry.SetRange("Reference No.", ProdOrderLine."Prod. Order No.");
            WhseEntry.SetRange("Item No.", ProdOrderLine."Item No.");
            WhseEntry.CalcSums(Quantity);
            OutputBase := WhseEntry.Quantity;
        end;

        exit(OutputBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineDelete(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineDelete(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLineCommonVerificationOnBeforeQuantityCheck(var OldTransferLine: Record "Transfer Line"; var NewTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;
}

