codeunit 5817 "Undo Posting Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'You cannot undo line %1 because there is not sufficient content in the receiving bins.';
        Text002: Label 'You cannot undo line %1 because warehouse put-away lines have already been created.';
        Text003: Label 'You cannot undo line %1 because warehouse activity lines have already been posted.';
        Text004: Label 'You must delete the related %1 before you undo line %2.';
        Text005: Label 'You cannot undo line %1 because warehouse receipt lines have already been created.';
        Text006: Label 'You cannot undo line %1 because warehouse shipment lines have already been created.';
        Text007: Label 'The items have been picked. If you undo line %1, the items will remain in the shipping area until you put them away.\Do you still want to undo the shipment?';
        Text008: Label 'You cannot undo line %1 because warehouse receipt lines have already been posted.';
        Text009: Label 'You cannot undo line %1 because warehouse put-away lines have already been posted.';
        Text010: Label 'You cannot undo line %1 because inventory pick lines have already been posted.';
        Text011: Label 'You cannot undo line %1 because there is an item charge assigned to it on %2 Doc No. %3 Line %4.';
        Text012: Label 'You cannot undo line %1 because an item charge has already been invoiced.';
        Text013: Label 'Item ledger entries are missing for line %1.';
        Text014: Label 'You cannot undo line %1, because a revaluation has already been posted.';
        Text015: Label 'You cannot undo posting of item %1 with variant ''%2'' and unit of measure %3 because it is not available at location %4, bin code %5. The required quantity is %6. The available quantity is %7.';
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";

    procedure TestSalesShptLine(SalesShptLine: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesShptLine do
            TestAllTransactions(DATABASE::"Sales Shipment Line",
              "Document No.", "Line No.",
              DATABASE::"Sales Line",
              SalesLine."Document Type"::Order,
              "Order No.",
              "Order Line No.");
    end;

    procedure TestServShptLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        with ServShptLine do
            TestAllTransactions(DATABASE::"Service Shipment Line",
              "Document No.", "Line No.",
              DATABASE::"Service Line",
              ServLine."Document Type"::Order,
              "Order No.",
              "Order Line No.");
    end;

    procedure TestPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchRcptLine do
            TestAllTransactions(DATABASE::"Purch. Rcpt. Line",
              "Document No.", "Line No.",
              DATABASE::"Purchase Line",
              PurchLine."Document Type"::Order,
              "Order No.",
              "Order Line No.");
    end;

    procedure TestReturnShptLine(ReturnShptLine: Record "Return Shipment Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        with ReturnShptLine do
            TestAllTransactions(DATABASE::"Return Shipment Line",
              "Document No.", "Line No.",
              DATABASE::"Purchase Line",
              PurchLine."Document Type"::"Return Order",
              "Return Order No.",
              "Return Order Line No.");
    end;

    procedure TestReturnRcptLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        SalesLine: Record "Sales Line";
    begin
        with ReturnRcptLine do
            TestAllTransactions(DATABASE::"Return Receipt Line",
              "Document No.", "Line No.",
              DATABASE::"Sales Line",
              SalesLine."Document Type"::"Return Order",
              "Return Order No.",
              "Return Order Line No.");
    end;

    procedure TestAsmHeader(PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
    begin
        with PostedAsmHeader do
            TestAllTransactions(DATABASE::"Posted Assembly Header",
              "No.", 0,
              DATABASE::"Assembly Header",
              AsmHeader."Document Type"::Order,
              "Order No.",
              0);
    end;

    procedure TestAsmLine(PostedAsmLine: Record "Posted Assembly Line")
    var
        AsmLine: Record "Assembly Line";
    begin
        with PostedAsmLine do
            TestAllTransactions(DATABASE::"Posted Assembly Line",
              "Document No.", "Line No.",
              DATABASE::"Assembly Line",
              AsmLine."Document Type"::Order,
              "Order No.",
              "Order Line No.");
    end;

    local procedure TestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        OnBeforeTestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not TestPostedWhseReceiptLine(
             UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then begin
            TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        end;

        if not (UndoType in [DATABASE::"Purch. Rcpt. Line", DATABASE::"Return Receipt Line"]) then
            TestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not (UndoType in [DATABASE::"Sales Shipment Line", DATABASE::"Return Shipment Line", DATABASE::"Service Shipment Line"]) then
            TestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);

        TestItemChargeAssignmentPurch(UndoType, UndoLineNo, SourceID, SourceRefNo);
        TestItemChargeAssignmentSales(UndoType, UndoLineNo, SourceID, SourceRefNo);
    end;

    local procedure TestPostedWhseReceiptLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
    begin
        case UndoType of
            DATABASE::"Posted Assembly Line":
                begin
                    TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
                    exit(true);
                end;
            DATABASE::"Posted Assembly Header":
                begin
                    PostedAsmHeader.Get(UndoID);
                    if not PostedAsmHeader.IsAsmToOrder then
                        TestWarehouseBinContent(SourceType, SourceSubtype, SourceID, SourceRefNo, PostedAsmHeader."Quantity (Base)");
                    exit(true);
                end;
        end;

        if not WhseUndoQty.FindPostedWhseRcptLine(
             PostedWhseReceiptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then
            exit(false);

        TestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine);
        TestWarehouseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestRgstrdWhseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestWhseWorksheetLine2(UndoLineNo, PostedWhseReceiptLine);
        exit(true);
    end;

    local procedure TestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        with WarehouseEntry do begin
            if PostedWhseReceiptLine."Location Code" = '' then
                exit;
            Location.Get(PostedWhseReceiptLine."Location Code");
            if Location."Bin Mandatory" then begin
                SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
                SetRange("Item No.", PostedWhseReceiptLine."Item No.");
                SetRange("Location Code", PostedWhseReceiptLine."Location Code");
                SetRange("Variant Code", PostedWhseReceiptLine."Variant Code");
                if Location."Directed Put-away and Pick" then
                    SetFilter("Bin Type Code", GetBinTypeFilter(0)); // Receiving area
                CalcSums("Qty. (Base)");
                if "Qty. (Base)" < PostedWhseReceiptLine."Qty. (Base)" then
                    Error(Text001, UndoLineNo);
            end;
        end;
    end;

    local procedure TestWarehouseBinContent(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; UndoQtyBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        QtyAvailToTake: Decimal;
    begin
        with WhseEntry do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not FindFirst then
                exit;

            BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
            QtyAvailToTake := BinContent.CalcQtyAvailToTake(0);
            if QtyAvailToTake < UndoQtyBase then
                Error(Text015,
                  "Item No.",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Location Code",
                  "Bin Code",
                  UndoQtyBase,
                  QtyAvailToTake);
        end;
    end;

    local procedure TestWarehouseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with WarehouseActivityLine do begin
            SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
            SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            SetRange("Whse. Document Type", "Whse. Document Type"::Receipt);
            SetRange("Activity Type", "Activity Type"::"Put-away");
            SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
            if not IsEmpty then
                Error(Text002, UndoLineNo);
        end;
    end;

    local procedure TestRgstrdWhseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        with RegisteredWhseActivityLine do begin
            SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            SetRange("Whse. Document Type", "Whse. Document Type"::Receipt);
            SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
            if not IsEmpty then
                Error(Text003, UndoLineNo);
        end;
    end;

    local procedure TestWhseWorksheetLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        with WhseWorksheetLine do begin
            SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            SetRange("Whse. Document Type", "Whse. Document Type"::Receipt);
            SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
            if not IsEmpty then
                Error(Text004, TableCaption, UndoLineNo);
        end;
    end;

    local procedure TestWarehouseActivityLine(UndoType: Integer; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with WarehouseActivityLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
            if not IsEmpty then begin
                if UndoType = DATABASE::"Assembly Line" then
                    Error(Text002, UndoLineNo);
                Error(Text003, UndoLineNo);
            end;
        end;
    end;

    local procedure TestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with RegisteredWhseActivityLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
            SetRange("Activity Type", "Activity Type"::"Put-away");
            if not IsEmpty then
                Error(Text002, UndoLineNo);
        end;
    end;

    local procedure TestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with WarehouseReceiptLine do begin
            WhseManagement.SetSourceFilterForWhseRcptLine(WarehouseReceiptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                Error(Text005, UndoLineNo);
        end;
    end;

    local procedure TestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with WarehouseShipmentLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                Error(Text006, UndoLineNo);
        end;
    end;

    local procedure TestPostedWhseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with PostedWhseShipmentLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                if not Confirm(Text007, true, UndoLineNo) then
                    Error('');
        end;
    end;

    local procedure TestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with WhseWorksheetLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                Error(Text008, UndoLineNo);
        end;
    end;

    local procedure TestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with PostedInvtPutAwayLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                Error(Text009, UndoLineNo);
        end;
    end;

    local procedure TestPostedInvtPickLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        with PostedInvtPickLine do begin
            SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
            if not IsEmpty then
                Error(Text010, UndoLineNo);
        end;
    end;

    local procedure TestItemChargeAssignmentPurch(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        with ItemChargeAssignmentPurch do begin
            SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            case UndoType of
                DATABASE::"Purch. Rcpt. Line":
                    SetRange("Applies-to Doc. Type", "Applies-to Doc. Type"::Receipt);
                DATABASE::"Return Shipment Line":
                    SetRange("Applies-to Doc. Type", "Applies-to Doc. Type"::"Return Shipment");
                else
                    exit;
            end;
            SetRange("Applies-to Doc. No.", SourceID);
            SetRange("Applies-to Doc. Line No.", SourceRefNo);
            if not IsEmpty then
                if FindFirst then
                    Error(Text011, UndoLineNo, "Document Type", "Document No.", "Line No.");
        end;
    end;

    local procedure TestItemChargeAssignmentSales(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        with ItemChargeAssignmentSales do begin
            SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            case UndoType of
                DATABASE::"Sales Shipment Line":
                    SetRange("Applies-to Doc. Type", "Applies-to Doc. Type"::Shipment);
                DATABASE::"Return Receipt Line":
                    SetRange("Applies-to Doc. Type", "Applies-to Doc. Type"::"Return Receipt");
                else
                    exit;
            end;
            SetRange("Applies-to Doc. No.", SourceID);
            SetRange("Applies-to Doc. Line No.", SourceRefNo);
            if not IsEmpty then
                if FindFirst then
                    Error(Text011, UndoLineNo, "Document Type", "Document No.", "Line No.");
        end;
    end;

    local procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick): Text[1024]
    var
        BinType: Record "Bin Type";
        "Filter": Text[1024];
    begin
        with BinType do begin
            case Type of
                Type::Receive:
                    SetRange(Receive, true);
                Type::Ship:
                    SetRange(Ship, true);
                Type::"Put Away":
                    SetRange("Put Away", true);
                Type::Pick:
                    SetRange(Pick, true);
            end;
            if Find('-') then
                repeat
                    Filter := StrSubstNo('%1|%2', Filter, Code);
                until Next = 0;
            if Filter <> '' then
                Filter := CopyStr(Filter, 2);
        end;
        exit(Filter);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer)
    begin
        CheckItemLedgEntries(TempItemLedgEntry, LineRef, false);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemRec: Record Item;
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        with TempItemLedgEntry do begin
            Find('-'); // Assertion: will fail if not found.
            ValueEntry.SetCurrentKey("Item Ledger Entry No.");
            ItemRec.Get("Item No.");
            if ItemRec.IsNonInventoriableType then
                exit;

            repeat
                OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(TempItemLedgEntry);
                if Positive then begin
                    if ("Job No." = '') and
                       not (("Order Type" = "Order Type"::Assembly) and
                            PostedATOLink.Get(PostedATOLink."Assembly Document Type"::Assembly, "Document No."))
                    then
                        if InvoicedEntry then
                            TestField("Remaining Quantity", Quantity - "Invoiced Quantity")
                        else
                            TestField("Remaining Quantity", Quantity);
                end else
                    if InvoicedEntry then
                        TestField("Shipped Qty. Not Returned", Quantity - "Invoiced Quantity")
                    else
                        TestField("Shipped Qty. Not Returned", Quantity);

                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);

                ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                if ValueEntry.Find('-') then
                    repeat
                        if ValueEntry."Item Charge No." <> '' then
                            Error(Text012, LineRef);
                        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                            Error(Text014, LineRef);
                    until ValueEntry.Next = 0;

                if ItemRec."Costing Method" = ItemRec."Costing Method"::Specific then
                    TestField("Serial No.");
            until Next = 0;
        end; // WITH
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    begin
        PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToItemLedgEntry, UndoQty, UndoQtyBase, TempItemLedgEntry, TempItemEntryRelation, false);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary; InvoicedEntry: Boolean)
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NonDistrQuantity: Decimal;
        NonDistrQuantityBase: Decimal;
    begin
        if InvoicedEntry then begin
            TempApplyToItemLedgEntry.SetRange("Completely Invoiced", false);
            if TempApplyToItemLedgEntry.IsEmpty then begin
                TempApplyToItemLedgEntry.SetRange("Completely Invoiced");
                exit;
            end;
        end;
        TempApplyToItemLedgEntry.Find('-'); // Assertion: will fail if not found.
        if ItemJnlLine."Job No." = '' then
            ItemJnlLine.TestField(Correction, true);
        NonDistrQuantity := -UndoQty;
        NonDistrQuantityBase := -UndoQtyBase;
        repeat
            if ItemJnlLine."Job No." = '' then
                ItemJnlLine."Applies-to Entry" := TempApplyToItemLedgEntry."Entry No."
            else
                ItemJnlLine."Applies-to Entry" := 0;

            ItemJnlLine."Item Shpt. Entry No." := 0;
            ItemJnlLine."Quantity (Base)" := -TempApplyToItemLedgEntry.Quantity;
            ItemJnlLine.CopyTrackingFromItemLedgEntry(TempApplyToItemLedgEntry);

            // Quantity is filled in according to UOM:
            ItemTrackingMgt.AdjustQuantityRounding(
              NonDistrQuantity, ItemJnlLine.Quantity,
              NonDistrQuantityBase, ItemJnlLine."Quantity (Base)");

            NonDistrQuantity := NonDistrQuantity - ItemJnlLine.Quantity;
            NonDistrQuantityBase := NonDistrQuantityBase - ItemJnlLine."Quantity (Base)";

            OnBeforePostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);
            PostItemJnlLine(ItemJnlLine);

            UndoValuePostingFromJob(ItemJnlLine, ItemApplicationEntry, TempApplyToItemLedgEntry);

            TempItemEntryRelation."Item Entry No." := ItemJnlLine."Item Shpt. Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemJnlLine(ItemJnlLine);
            OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemJnlLine);
            TempItemEntryRelation.Insert();
            TempItemLedgEntry := TempApplyToItemLedgEntry;
            TempItemLedgEntry.Insert();
        until TempApplyToItemLedgEntry.Next = 0;
    end;

    procedure CollectItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal; EntryRef: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TempItemLedgEntry.Reset();
        if not TempItemLedgEntry.IsEmpty then
            TempItemLedgEntry.DeleteAll();
        if EntryRef <> 0 then begin
            ItemLedgEntry.Get(EntryRef); // Assertion: will fail if no entry exists.
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.Insert();
        end else begin
            if SourceType in [DATABASE::"Sales Shipment Line",
                              DATABASE::"Return Shipment Line",
                              DATABASE::"Service Shipment Line",
                              DATABASE::"Posted Assembly Line"]
            then
                BaseQty := BaseQty * -1;
            if not
               ItemTrackingMgt.CollectItemEntryRelation(
                 TempItemLedgEntry, SourceType, 0, DocumentNo, '', 0, LineNo, BaseQty)
            then
                Error(Text013, LineNo);
        end;
    end;

    local procedure UndoValuePostingFromJob(ItemJnlLine: Record "Item Journal Line"; ItemApplicationEntry: Record "Item Application Entry"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoValuePostingFromJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Job No." <> '' then begin
            Clear(ItemJnlPostLine);
            FindItemReceiptApplication(ItemApplicationEntry, TempApplyToItemLedgEntry."Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(TempApplyToItemLedgEntry."Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
            FindItemShipmentApplication(ItemApplicationEntry, ItemJnlLine."Item Shpt. Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(ItemApplicationEntry."Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
        end;
    end;

    procedure UpdatePurchLine(PurchLine: Record "Purchase Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xPurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
    begin
        PurchSetup.Get();
        with PurchLine do begin
            xPurchLine := PurchLine;
            case "Document Type" of
                "Document Type"::"Return Order":
                    begin
                        "Return Qty. Shipped" := "Return Qty. Shipped" - UndoQty;
                        "Return Qty. Shipped (Base)" := "Return Qty. Shipped (Base)" - UndoQtyBase;
                        InitOutstanding;
                        if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                            "Qty. to Receive" := 0
                        else
                            InitQtyToShip;
                        UpdateWithWarehouseReceive;
                    end;
                "Document Type"::Order:
                    begin
                        "Quantity Received" := "Quantity Received" - UndoQty;
                        "Qty. Received (Base)" := "Qty. Received (Base)" - UndoQtyBase;
                        InitOutstanding;
                        if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                            "Qty. to Receive" := 0
                        else
                            InitQtyToReceive;
                        UpdateWithWarehouseReceive;
                    end;
                else
                    FieldError("Document Type");
            end;
            Modify;
            RevertPostedItemTracking(TempUndoneItemLedgEntry, "Expected Receipt Date");
            xPurchLine."Quantity (Base)" := 0;
            ReservePurchLine.VerifyQuantity(PurchLine, xPurchLine);

            OnAfterUpdatePurchline(PurchLine);
        end;
    end;

    procedure UpdateSalesLine(SalesLine: Record "Sales Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xSalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
    begin
        SalesSetup.Get();
        with SalesLine do begin
            xSalesLine := SalesLine;
            case "Document Type" of
                "Document Type"::"Return Order":
                    begin
                        "Return Qty. Received" := "Return Qty. Received" - UndoQty;
                        "Return Qty. Received (Base)" := "Return Qty. Received (Base)" - UndoQtyBase;
                        OnUpdateSalesLineOnBeforeInitOustanding(SalesLine, UndoQty, UndoQtyBase);
                        InitOutstanding;
                        if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then
                            "Qty. to Ship" := 0
                        else
                            InitQtyToReceive;
                        UpdateWithWarehouseShip;
                    end;
                "Document Type"::Order:
                    begin
                        "Quantity Shipped" := "Quantity Shipped" - UndoQty;
                        "Qty. Shipped (Base)" := "Qty. Shipped (Base)" - UndoQtyBase;
                        OnUpdateSalesLineOnBeforeInitOustanding(SalesLine, UndoQty, UndoQtyBase);
                        InitOutstanding;
                        if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then
                            "Qty. to Ship" := 0
                        else
                            InitQtyToShip;
                        UpdateWithWarehouseShip;
                    end;
                else
                    FieldError("Document Type");
            end;
            Modify;
            RevertPostedItemTracking(TempUndoneItemLedgEntry, "Shipment Date");
            xSalesLine."Quantity (Base)" := 0;
            ReserveSalesLine.VerifyQuantity(SalesLine, xSalesLine);

            OnAfterUpdateSalesLine(SalesLine);
        end;
    end;

    procedure UpdateServLine(ServLine: Record "Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xServLine: Record "Service Line";
        ReserveServLine: Codeunit "Service Line-Reserve";
    begin
        with ServLine do begin
            xServLine := ServLine;
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        "Quantity Shipped" := "Quantity Shipped" - UndoQty;
                        "Qty. Shipped (Base)" := "Qty. Shipped (Base)" - UndoQtyBase;
                        "Qty. to Consume" := 0;
                        "Qty. to Consume (Base)" := 0;
                        InitOutstanding;
                        InitQtyToShip;
                    end;
                else
                    FieldError("Document Type");
            end;
            Modify;
            RevertPostedItemTracking(TempUndoneItemLedgEntry, "Posting Date");
            xServLine."Quantity (Base)" := 0;
            ReserveServLine.VerifyQuantity(ServLine, xServLine);

            OnAfterUpdateServLine(ServLine);
        end;
    end;

    procedure UpdateServLineCnsm(var ServLine: Record "Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ServHeader: Record "Service Header";
        xServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ReserveServLine: Codeunit "Service Line-Reserve";
        ServCalcDiscount: Codeunit "Service-Calc. Discount";
    begin
        with ServLine do begin
            xServLine := ServLine;
            case "Document Type" of
                "Document Type"::Order:
                    begin
                        "Quantity Consumed" := "Quantity Consumed" - UndoQty;
                        "Qty. Consumed (Base)" := "Qty. Consumed (Base)" - UndoQtyBase;
                        "Quantity Shipped" := "Quantity Shipped" - UndoQty;
                        "Qty. Shipped (Base)" := "Qty. Shipped (Base)" - UndoQtyBase;
                        "Qty. to Invoice" := 0;
                        "Qty. to Invoice (Base)" := 0;
                        InitOutstanding;
                        InitQtyToShip;
                        Validate("Line Discount %");
                        ConfirmAdjPriceLineChange;
                        Modify;

                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then begin
                            ServHeader.Get("Document Type", "Document No.");
                            ServCalcDiscount.CalculateWithServHeader(ServHeader, ServLine, ServLine);
                        end;
                    end;
                else
                    FieldError("Document Type");
            end;
            Modify;
            RevertPostedItemTracking(TempUndoneItemLedgEntry, "Posting Date");
            xServLine."Quantity (Base)" := 0;
            ReserveServLine.VerifyQuantity(ServLine, xServLine);
        end;
    end;

    local procedure RevertPostedItemTracking(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; AvailabilityDate: Date)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        with TempItemLedgEntry do
            if Find('-') then begin
                repeat
                    TrackingSpecification.Get("Entry No.");
                    if not TrackingIsATO(TrackingSpecification) then begin
                        ReservEntry.Init();
                        ReservEntry.TransferFields(TrackingSpecification);
                        ReservEntry.Validate("Quantity (Base)");
                        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                        if ReservEntry.Positive then
                            ReservEntry."Expected Receipt Date" := AvailabilityDate
                        else
                            ReservEntry."Shipment Date" := AvailabilityDate;
                        ReservEntry."Entry No." := 0;
                        ReservEntry.UpdateItemTracking;
                        ReservEntry.Insert();

                        TempReservEntry := ReservEntry;
                        TempReservEntry.Insert();
                    end;
                    TrackingSpecification.Delete();
                until Next = 0;
                ReservEngineMgt.UpdateOrderTracking(TempReservEntry);
            end;
    end;

    procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        PostJobConsumptionBeforePurch: Boolean;
    begin
        Clear(ItemJnlLine2);
        ItemJnlLine2 := ItemJnlLine;

        if ItemJnlLine2."Job No." <> '' then
            PostJobConsumptionBeforePurch := PostItemJnlLineForJob(ItemJnlLine, ItemJnlLine2);

        ItemJnlPostLine.Run(ItemJnlLine);

        if ItemJnlLine2."Job No." <> '' then
            if not PostJobConsumptionBeforePurch then begin
                SetItemJnlLineAppliesToEntry(ItemJnlLine2, ItemJnlLine."Item Shpt. Entry No.");
                ItemJnlPostLine.Run(ItemJnlLine2);
            end;
    end;

    local procedure PostItemJnlLineForJob(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlLine2: Record "Item Journal Line"): Boolean
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineForJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Negative Adjmt.";
        Job.Get(ItemJnlLine2."Job No.");
        ItemJnlLine2."Source No." := Job."Bill-to Customer No.";
        ItemJnlLine2."Source Type" := ItemJnlLine2."Source Type"::Customer;
        ItemJnlLine2."Discount Amount" := 0;
        if ItemJnlLine2.IsPurchaseReturn then begin
            ItemJnlPostLine.Run(ItemJnlLine2);
            SetItemJnlLineAppliesToEntry(ItemJnlLine, ItemJnlLine2."Item Shpt. Entry No.");
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetItemJnlLineAppliesToEntry(var ItemJnlLine: Record "Item Journal Line"; AppliesToEntry: Integer)
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        if Item.Type = Item.Type::Inventory then
            ItemJnlLine."Applies-to Entry" := AppliesToEntry;
    end;

    local procedure TrackingIsATO(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        with TrackingSpecification do begin
            if "Source Type" <> DATABASE::"Sales Line" then
                exit(false);
            if not "Prohibit Cancellation" then
                exit(false);

            ATOLink.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.");
            ATOLink.SetRange(Type, ATOLink.Type::Sale);
            ATOLink.SetRange("Document Type", "Source Subtype");
            ATOLink.SetRange("Document No.", "Source ID");
            ATOLink.SetRange("Document Line No.", "Source Ref. No.");
            exit(not ATOLink.IsEmpty);
        end;
    end;

    procedure TransferSourceValues(var ItemJnlLine: Record "Item Journal Line"; EntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        with ItemLedgEntry do begin
            Get(EntryNo);
            ItemJnlLine."Source Type" := "Source Type";
            ItemJnlLine."Source No." := "Source No.";
            ItemJnlLine."Country/Region Code" := "Country/Region Code";
        end;

        with ValueEntry do begin
            SetRange("Item Ledger Entry No.", EntryNo);
            FindFirst;
            ItemJnlLine."Source Posting Group" := "Source Posting Group";
            ItemJnlLine."Salespers./Purch. Code" := "Salespers./Purch. Code";
        end;
    end;

    procedure ReapplyJobConsumption(ItemRcptEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReapplyJobConsumption(ItemRcptEntryNo, IsHandled);
        if IsHandled then
            exit;

        // Purchase receipt and job consumption are reapplied with with fixed cost application
        FindItemReceiptApplication(ItemApplnEntry, ItemRcptEntryNo);
        ItemJnlPostLine.UnApply(ItemApplnEntry);
        ItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemJnlPostLine.ReApply(ItemLedgEntry, ItemApplnEntry."Outbound Item Entry No.");
    end;

    procedure FindItemReceiptApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemRcptEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemRcptEntryNo);
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemRcptEntryNo);
        ItemApplnEntry.FindFirst;
    end;

    procedure FindItemShipmentApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemShipmentEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemShipmentEntryNo);
        ItemApplnEntry.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchaseLineOverRcptQty(PurchaseLine: Record "Purchase Line"; OverRcptQty: Decimal)
    begin
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine."Over-Receipt Quantity" += OverRcptQty;
        PurchaseLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchline(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServLine(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineForJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReapplyJobConsumption(ItemRcptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPickLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedWhseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseActivityLine(UndoType: Option; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoValuePostingFromJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeInitOustanding(var SalesLine: Record "Sales Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal)
    begin
    end;
}

