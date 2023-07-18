codeunit 7302 "WMS Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'must not be %1';
        Text002: Label '\Do you still want to use this %1 ?';
        Text003: Label 'You must set-up a default location code for user %1.';
        Text004: Label '%1 to place (%2) exceeds the available capacity (%3) on %4 %5.';
        Text005: Label '%1 = ''%2'', %3 = ''%4'':\The total base quantity to take %5 must be equal to the total base quantity to place %6.';
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        Bin: Record Bin;
        TempErrorLog: Record "License Information" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseMgt: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ShowError: Boolean;
        NextLineNo: Integer;
        LogErrors: Boolean;
        Text006: Label 'You must enter a %1 in %2 %3 = %4, %5 = %6.';
        Text007: Label 'Cancelled.';
        Text008: Label 'Destination Name';
        Text009: Label 'Sales Order';
        Text010: Label 'You cannot change the %1 because this item journal line is created from warehouse entries.\%2 %3 is set up with %4 and therefore changes must be made in a %5. ';
        Text011: Label 'You cannot use %1 %2 because it is set up with %3.\Adjustments to this location must therefore be made in a %4.';
        Text012: Label 'You cannot reclassify %1 %2 because it is set up with %3.\You can change this location code by creating a %4.';
        Text013: Label 'You cannot change item tracking because it is created from warehouse entries.\The %1 is set up with warehouse tracking, and %2 %3 is set up with %4.\Adjustments to item tracking must therefore be made in a warehouse journal.';
        Text014: Label 'You cannot change item tracking because the %1 is set up with warehouse tracking and %2 %3 is set up with %4.\Adjustments to item tracking must therefore be made in a warehouse journal.';
        Text015: Label 'You cannot use a %1 because %2 %3 is set up with %4.';
        Text016: Label '%1 = ''%2'', %3 = ''%4'', %5 = ''%6'', %7 = ''%8'': The total base quantity to take %9 must be equal to the total base quantity to place %10.';
        UserIsNotWhseEmployeeErr: Label 'You must first set up user %1 as a warehouse employee.';
        UserIsNotWhseEmployeeAtWMSLocationErr: Label 'You must first set up user %1 as a warehouse employee at a location with the Bin Mandatory setting.', Comment = '%1: USERID';
        DefaultLocationNotDirectedPutawayPickErr: Label 'You must set up a location with the Directed Put-away and Pick setting and assign it to user %1.', Comment = '%1: USERID';

    procedure CreateWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; ItemJnlTemplateType: Option; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseJnlLine(ItemJnlLine, ItemJnlTemplateType, WhseJnlLine, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if ((not "Phys. Inventory") and (Quantity = 0) and ("Invoiced Quantity" = 0)) or
               ("Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation]) or
               Adjustment
            then
                exit(false);

            if ToTransfer then
                "Location Code" := "New Location Code";
            GetLocation("Location Code");
            OnCreateWhseJnlLineOnAfterGetLocation(ItemJnlLine, WhseJnlLine, Location);
            InitWhseJnlLine(ItemJnlLine, WhseJnlLine, "Quantity (Base)");
            SetZoneAndBins(ItemJnlLine, WhseJnlLine, ToTransfer);
            if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then begin
                WhseJnlLine.SetSource(DATABASE::"Item Journal Line", ItemJnlTemplateType, "Document No.", "Line No.", 0);
                WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            end else
                if "Job No." <> '' then begin
                    WhseJnlLine.SetSource(DATABASE::"Job Journal Line", ItemJnlTemplateType, "Document No.", "Line No.", 0);
                    WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
                end;
            WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
            if "Job No." = '' then
                WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Item Journal"
            else
                WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Job Journal";
            WhseJnlLine."Reference No." := "Document No.";
            TransferWhseItemTracking(WhseJnlLine, ItemJnlLine);
            WhseJnlLine.Description := Description;
            OnAfterCreateWhseJnlLine(WhseJnlLine, ItemJnlLine, ToTransfer);
            exit(true);
        end;
    end;

    procedure CreateWhseJnlLineFromOutputJnl(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"): Boolean
    begin
        OnBeforeCreateWhseJnlLineFromOutputJnl(ItemJnlLine);
        with ItemJnlLine do begin
            if Adjustment or
               ("Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation])
            then
                exit(false);

            TestField("Order Type", "Order Type"::Production);
            GetLocation("Location Code");
            TestField("Unit of Measure Code");
            InitWhseJnlLine(ItemJnlLine, WhseJnlLine, "Output Quantity (Base)");
            OnCreateWhseJnlLineFromOutputJnlOnAfterInitWhseJnlLine(WhseJnlLine, ItemJnlLine);
            SetZoneAndBinsForOutput(ItemJnlLine, WhseJnlLine);
            WhseJnlLine.SetSource(DATABASE::"Item Journal Line", 5, "Order No.", "Order Line No.", 0); // Output Journal
            WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            WhseJnlLine.SetWhseDocument(WhseJnlLine."Whse. Document Type"::Production, "Order No.", "Order Line No.");
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
            WhseJnlLine."Reference No." := "Order No.";
            TransferWhseItemTracking(WhseJnlLine, ItemJnlLine);
            OnAfterCreateWhseJnlLineFromOutputJnl(WhseJnlLine, ItemJnlLine);
        end;
    end;

    procedure CreateWhseJnlLineFromConsumJnl(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"): Boolean
    begin
        with ItemJnlLine do begin
            if Adjustment or
               ("Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation])
            then
                exit(false);

            TestField("Order Type", "Order Type"::Production);
            GetLocation("Location Code");
            TestField("Unit of Measure Code");
            InitWhseJnlLine(ItemJnlLine, WhseJnlLine, "Quantity (Base)");
            SetZoneAndBinsForConsumption(ItemJnlLine, WhseJnlLine);
            WhseJnlLine.SetSource(DATABASE::"Item Journal Line", 4, "Order No.", "Order Line No.", "Prod. Order Comp. Line No."); // Consumption Journal
            WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            WhseJnlLine.SetWhseDocument(WhseJnlLine."Whse. Document Type"::Production, "Order No.", "Order Line No.");
            WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
            WhseJnlLine."Reference No." := "Order No.";
            TransferWhseItemTracking(WhseJnlLine, ItemJnlLine);
            OnAfterCreateWhseJnlLineFromConsumJnl(WhseJnlLine, ItemJnlLine);
        end;
    end;

    procedure CheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean)
    var
        BinContent: Record "Bin Content";
        QtyAbsBase: Decimal;
        DeductQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLine(WhseJnlLine, SourceJnl, DecreaseQtyBase, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        GetItem(WhseJnlLine."Item No.");
        with WhseJnlLine do begin
            TestField("Location Code");
            GetLocation("Location Code");
            OnCheckWhseJnlLineOnAfterGetLocation(WhseJnlLine, Location, Item);

            if SourceJnl = SourceJnl::WhseJnl then
                CheckAdjBinCode(WhseJnlLine);

            CheckWhseJnlLineTracking(WhseJnlLine);

            if "Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::Movement] then
                if SourceJnl = SourceJnl::" " then begin
                    CheckWhseDocumentToZoneCode(WhseJnlLine);
                    if "To Bin Code" = '' then
                        Error(
                          Text006,
                          FieldCaption("Bin Code"), "Whse. Document Type",
                          FieldCaption("Whse. Document No."), "Whse. Document No.",
                          FieldCaption("Line No."), "Whse. Document Line No.");
                end else
                    if ("Entry Type" <> "Entry Type"::Movement) or ToTransfer then begin
                        CheckToZoneCode(WhseJnlLine);
                        TestField("To Bin Code");
                    end;
            if "Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::Movement] then
                if SourceJnl = SourceJnl::" " then begin
                    CheckWhseDocumentFromZoneCode(WhseJnlLine);
                    if "From Bin Code" = '' then
                        Error(
                          Text006,
                          FieldCaption("Bin Code"), "Whse. Document Type",
                          FieldCaption("Whse. Document No."), "Whse. Document No.",
                          FieldCaption("Line No."), "Whse. Document Line No.");
                end else
                    if ("Entry Type" <> "Entry Type"::Movement) or not ToTransfer then begin
                        if Location."Directed Put-away and Pick" then
                            TestField("From Zone Code");
                        TestField("From Bin Code");
                    end;

            QtyAbsBase := "Qty. (Absolute, Base)";
            IsHandled := false;
            OnCheckWhseJnlLineOnBeforeCheckBySourceJnl(WhseJnlLine, Bin, SourceJnl, BinContent, Location, DecreaseQtyBase, IsHandled);
            if not IsHandled then begin
                CheckDecreaseBinContent(WhseJnlLine, SourceJnl, DecreaseQtyBase);
                case SourceJnl of
                    SourceJnl::" ", SourceJnl::ItemJnl:
                        if ("To Bin Code" <> '') and ("To Bin Code" <> Location."Adjustment Bin Code") then
                            if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                                if ("Reference Document" = "Reference Document"::"Posted Rcpt.") or
                                       ("Reference Document" = "Reference Document"::"Posted Rtrn. Rcpt.") or
                                       ("Reference Document" = "Reference Document"::"Posted T. Receipt")
                                then
                                    DeductQty := 0
                                else
                                    DeductQty := "Qty. (Absolute, Base)";

                                if BinContent.Get("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
                                    BinContent.CheckIncreaseBinContent("Qty. (Absolute, Base)", DeductQty, Cubage, Weight, Cubage, Weight, true, false)
                                else begin
                                    GetBin("Location Code", "To Bin Code");
                                    Bin.CheckIncreaseBin(Bin.Code, "Item No.", "Qty. (Absolute)", Cubage, Weight, Cubage, Weight, true, false);
                                end;
                            end else
                                CheckWarehouseClass("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                    SourceJnl::OutputJnl, SourceJnl::ConsumpJnl:
                        if "To Bin Code" <> '' then
                            if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                                if BinContent.Get("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
                                    BinContent.CheckIncreaseBinContent("Qty. (Absolute)", "Qty. (Absolute)", Cubage, Weight, Cubage, Weight, true, false)
                                else begin
                                    GetBin("Location Code", "To Bin Code");
                                    Bin.CheckIncreaseBin(Bin.Code, "Item No.", "Qty. (Absolute)", Cubage, Weight, Cubage, Weight, true, false);
                                end
                            else
                                CheckWarehouseClass("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                    SourceJnl::WhseJnl:
                        if ("To Bin Code" <> '') and
                           ("To Bin Code" <> Location."Adjustment Bin Code") and
                           Location."Directed Put-away and Pick"
                        then begin
                            GetBin("Location Code", "To Bin Code");
                            Bin.CheckWhseClass("Item No.", false);
                        end;
                end;
            end;
            if QtyAbsBase <> "Qty. (Absolute, Base)" then begin
                Validate("Qty. (Absolute, Base)");
                Modify();
            end;
        end;

        OnAfterCheckWhseJnlLine(WhseJnlLine, SourceJnl, DecreaseQtyBase, ToTransfer, Item);
    end;

    local procedure CheckWarehouseClass(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        GetLocation(LocationCode);
        if Location."Check Whse. Class" and (BinCode <> '') then
            if BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode) then
                BinContent.CheckWhseClass(false)
            else begin
                GetBin(LocationCode, BinCode);
                Bin.CheckWhseClass(ItemNo, false);
            end;
    end;

    local procedure CheckDecreaseBinContent(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDecreaseBinContent(WhseJnlLine, SourceJnl, DecreaseQtyBase, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do
            case SourceJnl of
                SourceJnl::" ", SourceJnl::ItemJnl:
                    if ("From Bin Code" <> '') and
                       ("From Bin Code" <> Location."Adjustment Bin Code") and
                       Location."Directed Put-away and Pick"
                    then begin
                        BinContent.Get(
                          "Location Code", "From Bin Code",
                          "Item No.", "Variant Code", "Unit of Measure Code");
                        BinContent.CheckDecreaseBinContent("Qty. (Absolute)", "Qty. (Absolute, Base)", DecreaseQtyBase);
                    end;
                SourceJnl::OutputJnl, SourceJnl::ConsumpJnl:
                    if ("From Bin Code" <> '') and
                       Location."Directed Put-away and Pick"
                    then begin
                        BinContent.Get(
                          "Location Code", "From Bin Code",
                          "Item No.", "Variant Code", "Unit of Measure Code");
                        BinContent.CheckDecreaseBinContent("Qty. (Absolute)", "Qty. (Absolute, Base)", DecreaseQtyBase);
                    end;
                SourceJnl::WhseJnl:
                    if ("From Bin Code" <> '') and
                       ("From Bin Code" <> Location."Adjustment Bin Code") and
                       Location."Directed Put-away and Pick"
                    then begin
                        if not ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then begin
                            BinContent.Get(
                              "Location Code", "From Bin Code",
                              "Item No.", "Variant Code", "Unit of Measure Code");
                            BinContent.CheckDecreaseBinContent("Qty. (Absolute)", "Qty. (Absolute, Base)", DecreaseQtyBase);
                        end;
                    end;
            end;
    end;

    local procedure CheckWhseJnlLineTracking(var WhseJnlLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseJnlLineTracking(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                if ("Serial No." <> '') and
                   ("From Bin Code" <> '') and
                   ItemTrackingCode."SN Specific Tracking" and
                   ("From Bin Code" <> Location."Adjustment Bin Code") and
                   (((Location."Adjustment Bin Code" <> '') and
                     ("Entry Type" = "Entry Type"::Movement)) or
                    (("Entry Type" <> "Entry Type"::Movement) or
                     ("Source Document" = "Source Document"::"Reclass. Jnl.")))
                then
                    CheckSerialNo(
                      "Item No.", "Variant Code", "Location Code", "From Bin Code",
                      "Unit of Measure Code", "Serial No.", CalcReservEntryQuantity());

                if ("Lot No." <> '') and
                   ("From Bin Code" <> '') and
                   ItemTrackingCode."Lot Specific Tracking" and
                   ("From Bin Code" <> Location."Adjustment Bin Code") and
                   (((Location."Adjustment Bin Code" <> '') and
                     ("Entry Type" = "Entry Type"::Movement)) or
                    (("Entry Type" <> "Entry Type"::Movement) or
                     ("Source Document" = "Source Document"::"Reclass. Jnl.")))
                then
                    CheckLotNo(
                      "Item No.", "Variant Code", "Location Code", "From Bin Code",
                      "Unit of Measure Code", "Lot No.", CalcReservEntryQuantity());

                OnCheckWhseJnlLineOnAfterCheckTracking(WhseJnlLine, ItemTrackingCode, Location);
            end;
    end;

    local procedure CheckWhseDocumentToZoneCode(WhseJnlLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocumentToZoneCode(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do
            if Location."Directed Put-away and Pick" and ("To Zone Code" = '') then
                Error(
                  Text006,
                  FieldCaption("Zone Code"), "Whse. Document Type",
                  FieldCaption("Whse. Document No."), "Whse. Document No.",
                  FieldCaption("Line No."), "Whse. Document Line No.");
    end;

    local procedure CheckWhseDocumentFromZoneCode(WhseJnlLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocumentFromZoneCode(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do
            if Location."Directed Put-away and Pick" and ("From Zone Code" = '') then
                Error(
                  Text006,
                  FieldCaption("Zone Code"), "Whse. Document Type",
                  FieldCaption("Whse. Document No."), "Whse. Document No.",
                  FieldCaption("Line No."), "Whse. Document Line No.");
    end;

    local procedure CheckToZoneCode(WhseJnlLine: Record "Warehouse Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckToZoneCode(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" then
            WhseJnlLine.TestField("To Zone Code");
    end;

    local procedure CheckAdjBinCode(WhseJnlLine: Record "Warehouse Journal Line")
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        FieldCapTxt: Text;
    begin
        with WhseJnlLine do begin
            if "Entry Type" = "Entry Type"::Movement then
                exit;

            GetLocation("Location Code");
            if not Location."Directed Put-away and Pick" then
                exit;

            WarehouseJournalTemplate.Get("Journal Template Name");
            if WarehouseJournalTemplate.Type = WarehouseJournalTemplate.Type::Reclassification then
                exit;

            Location.TestField("Adjustment Bin Code");
            case "Entry Type" of
                "Entry Type"::"Positive Adjmt.":
                    if ("From Bin Code" <> '') and ("From Bin Code" <> Location."Adjustment Bin Code") then
                        FieldCapTxt := FieldCaption("From Bin Code");
                "Entry Type"::"Negative Adjmt.":
                    if ("To Bin Code" <> '') and ("To Bin Code" <> Location."Adjustment Bin Code") then
                        FieldCapTxt := FieldCaption("To Bin Code");
            end;
            if FieldCapTxt <> '' then
                Error(
                  Text006,
                  StrSubstNo('%1 = ''%2''', FieldCapTxt, Location."Adjustment Bin Code"),
                  "Whse. Document Type",
                  FieldCaption("Whse. Document No."), "Whse. Document No.",
                  FieldCaption("Line No."), "Line No.");
        end;
    end;

    procedure CheckItemJnlLineFieldChange(ItemJnlLine: Record "Item Journal Line"; xItemJnlLine: Record "Item Journal Line"; CurrFieldCaption: Text[30])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        BinContent: Record "Bin Content";
        WhseItemJnl: Page "Whse. Item Journal";
        WhsePhysInvJnl: Page "Whse. Phys. Invt. Journal";
        BinIsEligible: Boolean;
        IsHandled: Boolean;
        Cubage: Decimal;
        Weight: Decimal;
    begin
        IsHandled := false;
        OnBeforeCheckItemJnlLineFieldChange(ItemJnlLine, xItemJnlLine, CurrFieldCaption, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if ("Order Type" = "Order Type"::Production) and ("Entry Type" = "Entry Type"::Output) then
                if ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.") then
                    BinIsEligible := ("Location Code" = ProdOrderLine."Location Code") and ("Bin Code" = ProdOrderLine."Bin Code");
            if ("Order Type" = "Order Type"::Production) and ("Entry Type" = "Entry Type"::Consumption) then
                if ProdOrderComponent.Get(ProdOrderComponent.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.") then
                    BinIsEligible := ("Location Code" = ProdOrderComponent."Location Code") and ("Bin Code" = ProdOrderComponent."Bin Code");

            ShowError := CheckBinCodeChange("Location Code", "Bin Code", xItemJnlLine."Bin Code") and not BinIsEligible;
            if not ShowError then
                ShowError := CheckBinCodeChange("New Location Code", "New Bin Code", xItemJnlLine."New Bin Code");

            if ShowError then
                Error(Text015,
                  CurrFieldCaption,
                  LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));

            if "Entry Type" in
               ["Entry Type"::"Negative Adjmt.", "Entry Type"::"Positive Adjmt.", "Entry Type"::Sale, "Entry Type"::Purchase]
            then begin
                if ("Location Code" <> xItemJnlLine."Location Code") and (xItemJnlLine."Location Code" <> '') then begin
                    GetLocation(xItemJnlLine."Location Code");
                    ShowError := Location."Directed Put-away and Pick";
                end;

                if (("Item No." <> xItemJnlLine."Item No.") and (xItemJnlLine."Item No." <> '')) or
                   ((Quantity <> xItemJnlLine.Quantity) and (xItemJnlLine.Quantity <> 0)) or
                   ("Variant Code" <> xItemJnlLine."Variant Code") or
                   ("Unit of Measure Code" <> xItemJnlLine."Unit of Measure Code") or
                   ("Entry Type" <> xItemJnlLine."Entry Type") or
                   ("Phys. Inventory" and
                    ("Qty. (Phys. Inventory)" <> xItemJnlLine."Qty. (Phys. Inventory)") or
                    (Quantity <> xItemJnlLine.Quantity))
                then begin
                    GetLocation("Location Code");
                    ShowError := Location."Directed Put-away and Pick";
                end;

                if ShowError then begin
                    if "Phys. Inventory" then
                        Error(Text010,
                          CurrFieldCaption,
                          Location.TableCaption(), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                          WhsePhysInvJnl.Caption);

                    Error(Text010,
                      CurrFieldCaption,
                      Location.TableCaption(), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                      WhseItemJnl.Caption);
                end;
                GetLocation("Location Code");
                if not Location."Bin Mandatory" then
                    exit;
                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                    if ItemJnlLine."Bin Code" <> '' then begin
                        CalcCubageAndWeight(ItemJnlLine."Item No.", ItemJnlLine."Unit of Measure Code", ItemJnlLine.Quantity, Cubage, Weight);
                        if BinContent.Get(Location.Code, ItemJnlLine."Bin Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Unit of Measure Code") then
                            BinContent.CheckIncreaseBinContent(Quantity, 0, 0, 0, Cubage, Weight, false, false)
                        else begin
                            GetBin(Location.Code, ItemJnlLine."Bin Code");
                            Bin.CheckIncreaseBin(Bin.Code, ItemJnlLine."Item No.", ItemJnlLine.Quantity, 0, 0, Cubage, Weight, false, false);
                        end;
                    end
                end else
                    CheckWarehouseClass(Location.Code, ItemJnlLine."Bin Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Unit of Measure Code");
            end;
        end;
    end;

    internal procedure CheckWarehouse(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ItemUnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
        Cubage: Decimal;
        Weight: Decimal;
    begin
        GetLocation(LocationCode);
        if not Location."Bin Mandatory" then
            exit;
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
            if BinCode <> '' then begin
                CalcCubageAndWeight(ItemNo, ItemUnitOfMeasureCode, Quantity, Cubage, Weight);
                if BinContent.Get(Location.Code, BinCode, ItemNo, VariantCode, ItemUnitOfMeasureCode) then
                    BinContent.CheckIncreaseBinContent(Quantity, 0, 0, 0, Cubage, Weight, false, false)
                else begin
                    GetBin(LocationCode, BinCode);
                    Bin.CheckIncreaseBin(BinCode, ItemNo, Quantity, 0, 0, Cubage, Weight, false, false);
                end;
            end
        end else
            CheckWarehouseClass(Location.Code, BinCode, ItemNo, VariantCode, ItemUnitOfMeasureCode);
    end;

    procedure CheckItemJnlLineLocation(var ItemJnlLine: Record "Item Journal Line"; xItemJnlLine: Record "Item Journal Line")
    var
        WhseItemJnl: Page "Whse. Item Journal";
        TransferOrder: Page "Transfer Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemJnlLineLocation(ItemJnlLine, xItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if "Entry Type" in
               ["Entry Type"::"Negative Adjmt.", "Entry Type"::"Positive Adjmt.", "Entry Type"::Sale, "Entry Type"::Purchase]
            then
                if "Location Code" <> xItemJnlLine."Location Code" then begin
                    GetLocation(xItemJnlLine."Location Code");
                    if not Location."Directed Put-away and Pick" then begin
                        GetLocation("Location Code");
                        if Location."Directed Put-away and Pick" then
                            Error(Text011,
                              LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                              WhseItemJnl.Caption);
                    end;
                end;

            if "Entry Type" = "Entry Type"::Transfer then begin
                if ("New Location Code" <> "Location Code") and
                   (("Location Code" <> xItemJnlLine."Location Code") or
                    ("New Location Code" <> xItemJnlLine."New Location Code"))
                then begin
                    GetLocation("Location Code");
                    ShowError := Location."Directed Put-away and Pick";
                    if not Location."Directed Put-away and Pick" then begin
                        GetLocation("New Location Code");
                        ShowError := Location."Directed Put-away and Pick";
                    end;
                end;

                if ShowError then
                    Error(Text012,
                      LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"),
                      TransferOrder.Caption);
            end;
        end;
    end;

    procedure CheckItemTrackingChange(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingChange(TrackingSpecification, xTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        with TrackingSpecification do
            if ("Source Type" = DATABASE::"Item Journal Line") and
               ("Item No." <> '') and
               ("Location Code" <> '')
            then begin
                if "Source Subtype" in [0, 1, 2, 3] then
                    if not HasSameTracking(xTrackingSpecification) or
                       ((xTrackingSpecification."Expiration Date" <> 0D) and
                        ("Expiration Date" <> xTrackingSpecification."Expiration Date")) or
                       ("Quantity (Base)" <> xTrackingSpecification."Quantity (Base)")
                    then begin
                        GetLocation("Location Code");
                        if Location."Directed Put-away and Pick" then begin
                            GetItem("Item No.");
                            if ItemTrackingCode.IsWarehouseTracking() then
                                Error(Text013,
                                  LowerCase(Item.TableCaption()),
                                  LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));
                        end;
                    end;

                if IsReclass() then
                    if CheckTrackingSpecificationChangeNeeded(TrackingSpecification, xTrackingSpecification) then begin
                        GetLocation("Location Code");
                        if Location."Directed Put-away and Pick" then begin
                            GetItem("Item No.");
                            if ItemTrackingCode.IsWarehouseTracking() then
                                Error(Text014,
                                  LowerCase(Item.TableCaption()),
                                  LowerCase(Location.TableCaption()), Location.Code, Location.FieldCaption("Directed Put-away and Pick"));
                        end;
                    end;
            end;
    end;

    local procedure CheckBinCodeChange(LocationCode: Code[10]; BinCode: Code[20]; xRecBinCode: Code[20]): Boolean
    begin
        if (BinCode <> xRecBinCode) and (BinCode <> '') then begin
            GetLocation(LocationCode);
            exit(Location."Directed Put-away and Pick");
        end;

        exit(false);
    end;

    local procedure CheckTrackingSpecificationChangeNeeded(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification") CheckNeeded: Boolean
    begin
        CheckNeeded :=
            (TrackingSpecification."New Lot No." <> TrackingSpecification."Lot No.") and
            ((TrackingSpecification."Lot No." <> xTrackingSpecification."Lot No.") or
            (TrackingSpecification."New Lot No." <> xTrackingSpecification."New Lot No.")) or
            (TrackingSpecification."New Serial No." <> TrackingSpecification."Serial No.") and
            ((TrackingSpecification."Serial No." <> xTrackingSpecification."Serial No.") or
            (TrackingSpecification."New Serial No." <> xTrackingSpecification."New Serial No.")) or
            (TrackingSpecification."New Expiration Date" <> TrackingSpecification."Expiration Date") and
            ((TrackingSpecification."Expiration Date" <> xTrackingSpecification."Expiration Date") or
            (TrackingSpecification."New Expiration Date" <> xTrackingSpecification."New Expiration Date"));

        OnAfterCheckTrackingSpecificationChangeNeeded(TrackingSpecification, xTrackingSpecification, CheckNeeded);
    end;

    procedure CheckAdjmtBin(Location: Record Location; Quantity: Decimal; PosEntryType: Boolean)
    begin
        if not Location."Directed Put-away and Pick" then
            exit;

        Location.TestField(Code);
        Location.TestField("Adjustment Bin Code");
        GetBin(Location.Code, Location."Adjustment Bin Code");

        // Test whether bin movement is blocked for current Entry Type
        if (PosEntryType and (Quantity > 0)) or
           (not PosEntryType and (Quantity < 0))
        then
            ShowError := (Bin."Block Movement" in
                          [Bin."Block Movement"::Inbound, Bin."Block Movement"::All])
        else
            if (PosEntryType and (Quantity < 0)) or
               (not PosEntryType and (Quantity > 0))
            then
                ShowError := (Bin."Block Movement" in
                              [Bin."Block Movement"::Outbound, Bin."Block Movement"::All]);

        if ShowError then
            Bin.FieldError(
              "Block Movement",
              StrSubstNo(
                Text000,
                Bin."Block Movement"));
    end;

    procedure CheckInbOutbBin(LocationCode: Code[10]; BinCode: Code[20]; CheckInbound: Boolean)
    begin
        GetLocation(LocationCode);
        GetBin(LocationCode, BinCode);

        // Test whether bin movement is blocked for current Entry Type
        if CheckInbound then
            if Bin."Block Movement" in [Bin."Block Movement"::Inbound, Bin."Block Movement"::All] then
                Bin.FieldError("Block Movement", StrSubstNo(Text000, Bin."Block Movement"));

        if not CheckInbound then
            if Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All] then
                Bin.FieldError("Block Movement", StrSubstNo(Text000, Bin."Block Movement"));
    end;

    procedure CheckUserIsWhseEmployee()
    var
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUserIsWhseEmployee(Location, IsHandled);
        if IsHandled then
            exit;

        if UserId <> '' then begin
            WhseEmployee.SetRange("User ID", UserId);
            if WhseEmployee.IsEmpty() then
                Error(UserIsNotWhseEmployeeErr, UserId);
        end;
    end;

    procedure CalcCubageAndWeight(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; var Cubage: Decimal; var Weight: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCubageAndWeight(ItemNo, UOMCode, Qty, Cubage, Weight, IsHandled);
        if IsHandled then
            exit;

        if ItemNo <> '' then begin
            GetItemUnitOfMeasure(ItemNo, UOMCode);
            Cubage := Qty * ItemUnitOfMeasure.Cubage;
            Weight := Qty * ItemUnitOfMeasure.Weight;
        end else begin
            Cubage := 0;
            Weight := 0;
        end;
    end;

    procedure GetDefaultLocation(): Code[10]
    var
        WhseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        if UserId <> '' then begin
            WhseEmployee.SetCurrentKey(Default);
            WhseEmployee.SetRange(Default, true);
            WhseEmployee.SetRange("User ID", UserId);
            if not WhseEmployee.FindFirst() then
                Error(Text003, UserId);
            exit(WhseEmployee."Location Code");
        end;
    end;

    procedure GetWMSLocation(var CurrentLocationCode: Code[10])
    var
        Location: Record Location;
        WhseEmployee: Record "Warehouse Employee";
    begin
        CheckUserIsWhseEmployee();
        if WhseEmployee.Get(UserId, CurrentLocationCode) and Location.Get(CurrentLocationCode) then
            if Location."Bin Mandatory" then
                exit;

        WhseEmployee.SetRange("User ID", UserId);
        WhseEmployee.Find('-');
        repeat
            if Location.Get(WhseEmployee."Location Code") then
                if Location."Bin Mandatory" then begin
                    CurrentLocationCode := Location.Code;
                    exit;
                end;
        until WhseEmployee.Next() = 0;

        Error(UserIsNotWhseEmployeeAtWMSLocationErr, UserId);
    end;

    procedure GetDefaultDirectedPutawayAndPickLocation() LocationCode: Code[10]
    var
        Location: Record Location;
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultDirectedPutawayAndPickLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        if Location.Get(GetDefaultLocation()) then
            if Location."Directed Put-away and Pick" then
                exit(Location.Code)
            else begin
                WhseEmployee.SetCurrentKey(Default);
                WhseEmployee.SetRange(Default, false);
                WhseEmployee.SetRange("User ID", UserId);
                if (WhseEmployee.FindSet()) then
                    repeat
                        if Location.Get(WhseEmployee."Location Code") then
                            if Location."Directed Put-away and Pick" then
                                exit(Location.Code);
                    until WhseEmployee.Next() = 0;
            end;
        Error(DefaultLocationNotDirectedPutawayPickErr, UserId);
    end;

    procedure GetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]) Result: Boolean
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.FindFirst() then begin
            BinCode := BinContent."Bin Code";
            exit(true);
        end;
    end;

    procedure CheckDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey(Default);
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetFilter("Bin Code", '<>%1', BinCode);
        exit(not BinContent.IsEmpty);
    end;

    procedure CheckBalanceQtyToHandle(var WhseActivLine2: Record "Warehouse Activity Line")
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivLine3: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        QtyToPick: Decimal;
        QtyToPutAway: Decimal;
        ErrorText: Text[250];
    begin
        OnBeforeCheckBalanceQtyToHandle(WhseActivLine2);
        WhseActivLine.Copy(WhseActivLine2);

        WhseActivLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        WhseActivLine.SetRange("Action Type");
        if WhseActivLine.FindSet() then
            repeat
                if not TempWhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.") then begin
                    WhseActivLine3.Copy(WhseActivLine);

                    WhseActivLine3.SetRange("Item No.", WhseActivLine."Item No.");
                    WhseActivLine3.SetRange("Variant Code", WhseActivLine."Variant Code");
                    WhseActivLine3.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
                    OnCheckBalanceQtyToHandleOnAfterSetFilters(WhseActivLine3, WhseActivLine);

                    if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Take) or
                        (WhseActivLine2.GetFilter("Action Type") = '')
                    then begin
                        WhseActivLine3.SetRange("Action Type", WhseActivLine3."Action Type"::Take);
                        if WhseActivLine3.FindSet() then
                            repeat
                                QtyToPick := QtyToPick + WhseActivLine3."Qty. to Handle (Base)";
                                TempWhseActivLine := WhseActivLine3;
                                TempWhseActivLine.Insert();
                            until WhseActivLine3.Next() = 0;
                    end;

                    if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Place) or
                        (WhseActivLine2.GetFilter("Action Type") = '')
                    then begin
                        WhseActivLine3.SetRange("Action Type", WhseActivLine3."Action Type"::Place);
                        if WhseActivLine3.FindSet() then
                            repeat
                                QtyToPutAway := QtyToPutAway + WhseActivLine3."Qty. to Handle (Base)";
                                TempWhseActivLine := WhseActivLine3;
                                TempWhseActivLine.Insert();
                            until WhseActivLine3.Next() = 0;
                    end;

                    if QtyToPick <> QtyToPutAway then begin
                        ErrorText := GetWrongPickPutAwayQtyErrorText(WhseActivLine, WhseActivLine3, QtyToPick, QtyToPutAway);
                        HandleError(ErrorText);
                    end;

                    QtyToPick := 0;
                    QtyToPutAway := 0;
                end;
            until WhseActivLine.Next() = 0;
    end;

    local procedure GetWrongPickPutAwayQtyErrorText(WhseActivLine: Record "Warehouse Activity Line"; WhseActivLine3: Record "Warehouse Activity Line"; QtyToPick: Decimal; QtyToPutAway: Decimal) ErrorText: Text[250]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWrongPickPutAwayQtyErrorText(WhseActivLine3, QtyToPick, QtyToPutAway, ErrorText, IsHandled);
        if IsHandled then
            exit(ErrorText);

        with WhseActivLine do
            if WhseActivLine3.TrackingFilterExists() then
                ErrorText :=
                  StrSubstNo(
                    Text016,
                    WhseActivLine.FieldCaption("Item No."), WhseActivLine."Item No.",
                    WhseActivLine.FieldCaption("Variant Code"), WhseActivLine."Variant Code",
                    WhseActivLine.FieldCaption("Lot No."), WhseActivLine."Lot No.",
                    WhseActivLine.FieldCaption("Serial No."), WhseActivLine."Serial No.",
                    QtyToPick, QtyToPutAway)
            else
                ErrorText :=
                    StrSubstNo(
                    Text005,
                    WhseActivLine.FieldCaption("Item No."), WhseActivLine."Item No.",
                    WhseActivLine.FieldCaption("Variant Code"), WhseActivLine."Variant Code",
                    QtyToPick, QtyToPutAway);
    end;

    procedure CheckPutAwayAvailability(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal; Prohibit: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPutAwayAvailability(BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable, Prohibit, IsHandled);
        if IsHandled then
            exit;

        if ValueToPutAway <= ValueAvailable then
            exit;
        if Prohibit then
            Error(
              Text004, CheckFieldCaption, ValueToPutAway, ValueAvailable,
              CheckTableCaption, BinCode);

        ConfirmExceededCapacity(BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable);
    end;

    local procedure ConfirmExceededCapacity(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmExceededCapacity(IsHandled, BinCode, CheckFieldCaption, CheckTableCaption, ValueToPutAway, ValueAvailable);
        if IsHandled then
            exit;

        if not Confirm(
             StrSubstNo(
               Text004, CheckFieldCaption, ValueToPutAway, ValueAvailable,
               CheckTableCaption, BinCode) + StrSubstNo(Text002, CheckTableCaption), false)
        then
            Error(Text007);
    end;

    local procedure InitWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; QuantityBase: Decimal)
    begin
        with WhseJnlLine do begin
            Init();
            "Journal Template Name" := ItemJnlLine."Journal Template Name";
            "Journal Batch Name" := ItemJnlLine."Journal Batch Name";
            "Location Code" := ItemJnlLine."Location Code";
            "Item No." := ItemJnlLine."Item No.";
            "Registering Date" := ItemJnlLine."Posting Date";
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Variant Code" := ItemJnlLine."Variant Code";
            if ItemJnlLine."Qty. per Unit of Measure" = 0 then
                ItemJnlLine."Qty. per Unit of Measure" := 1;
            if Location."Directed Put-away and Pick" then begin
                Quantity := Round(QuantityBase / ItemJnlLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                "Unit of Measure Code" := ItemJnlLine."Unit of Measure Code";
                "Qty. per Unit of Measure" := ItemJnlLine."Qty. per Unit of Measure";
            end else begin
                Quantity := QuantityBase;
                "Unit of Measure Code" := GetBaseUOM(ItemJnlLine."Item No.");
                "Qty. per Unit of Measure" := 1;
            end;
            OnInitWhseJnlLineOnAfterGetQuantity(ItemJnlLine, WhseJnlLine, Location);

            "Qty. (Base)" := QuantityBase;
            "Qty. (Absolute)" := Abs(Quantity);
            "Qty. (Absolute, Base)" := Abs(QuantityBase);

            "Source Code" := ItemJnlLine."Source Code";
            "Reason Code" := ItemJnlLine."Reason Code";
            "Registering No. Series" := ItemJnlLine."Posting No. Series";
            if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                CalcCubageAndWeight(
                  ItemJnlLine."Item No.", ItemJnlLine."Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight);

            OnInitWhseJnlLineCopyFromItemJnlLine(WhseJnlLine, ItemJnlLine);
        end;
    end;

    procedure InitErrorLog()
    begin
        LogErrors := true;
        TempErrorLog.DeleteAll();
        NextLineNo := 1;
    end;

    local procedure HandleError(ErrorText: Text[250])
    var
        Position: Integer;
    begin
        if LogErrors then begin
            Position := StrPos(ErrorText, '\');
            if Position = 0 then
                InsertErrorLog(ErrorText)
            else begin
                repeat
                    InsertErrorLog(CopyStr(ErrorText, 1, Position - 1));
                    ErrorText := DelStr(ErrorText, 1, Position);
                    Position := StrPos(ErrorText, '\');
                until Position = 0;
                InsertErrorLog(ErrorText);
                InsertErrorLog('');
            end;
        end else
            Error(ErrorText);
    end;

    local procedure InsertErrorLog(ErrorText: Text[250])
    begin
        TempErrorLog."Line No." := NextLineNo;
        TempErrorLog.Text := ErrorText;
        TempErrorLog.Insert();
        NextLineNo := NextLineNo + 1;
    end;

    procedure GetWarehouseEmployeeLocationFilter(UserName: code[50]): Text
    var
        WarehouseEmployee: Record "Warehouse Employee";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Location: Record Location;
        AssignedLocations: List of [code[20]];
        WhseEmplLocationBuffer: Codeunit WhseEmplLocationBuffer;
        Filterstring: Text;
        LocationAllowed: Boolean;
        FilterTooLong: Boolean;
        HasLocationSubscribers: Boolean;
    begin
        // buffered?
        Filterstring := WhseEmplLocationBuffer.GetWarehouseEmployeeLocationFilter();
        if Filterstring <> '' then
            exit(Filterstring);
        Filterstring := StrSubstNo('%1', ''''''); // All users can see the blank location
        if UserName = '' then
            exit(Filterstring);
        WarehouseEmployee.SetRange("User ID", UserName);
        WarehouseEmployee.SetFilter("Location Code", '<>%1', '');
        IF WarehouseEmployee.Count > 1000 then  // if more, later filter length will exceed allowed length and it will use all values anyway
            exit(''); // can't filter to that many locations. Then remove filter
        IF WarehouseEmployee.FindSet() then
            REPEAT
                AssignedLocations.Add(WarehouseEmployee."Location Code");
                LocationAllowed := true;
                OnBeforeLocationIsAllowed(WarehouseEmployee."Location Code", LocationAllowed);
                if LocationAllowed then
                    Filterstring += '|' + StrSubstNo('''%1''', ConvertStr(WarehouseEmployee."Location Code", '''', '*'));
            UNTIL WarehouseEmployee.Next() = 0;
        if WhseEmplLocationBuffer.NeedToCheckLocationSubscribers() then
            if Location.FindSet() then
                repeat
                    if not AssignedLocations.Contains(Location.Code) then begin
                        LocationAllowed := false;
                        OnBeforeLocationIsAllowed(Location.Code, LocationAllowed);
                        if LocationAllowed then begin
                            Filterstring += '|' + StrSubstNo('''%1''', ConvertStr(Location.Code, '''', '*'));
                            FilterTooLong := StrLen(Filterstring) > 2000; // platform limitation on length
                            HasLocationSubscribers := true;
                        end;
                    end;
                until (location.Next() = 0) or FilterTooLong;
        WhseEmplLocationBuffer.SetHasLocationSubscribers(HasLocationSubscribers);
        if FilterTooLong then
            Filterstring := '*';
        WhseEmplLocationBuffer.SetWarehouseEmployeeLocationFilter(Filterstring);
        exit(Filterstring);
    end;

    procedure GetAllowedLocation(LocationCode: Code[10]): Code[10]
    var
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAllowedLocation(LocationCode, IsHandled);
        if IsHandled then
            exit(LocationCode);

        CheckUserIsWhseEmployee();
        if WhseEmployee.Get(UserId, LocationCode) then
            exit(LocationCode);
        exit(GetDefaultLocation());
    end;

    procedure LocationIsAllowed(LocationCode: Code[10]): Boolean
    var
        WhseEmployee: Record "Warehouse Employee";
        LocationAllowed: Boolean;
    begin
        LocationAllowed := WhseEmployee.Get(UserId, LocationCode) or (UserId = '');
        OnBeforeLocationIsAllowed(LocationCode, LocationAllowed);
        exit(LocationAllowed);
    end;

    procedure LocationIsAllowedToView(LocationCode: Code[10]): Boolean
    begin
        exit((LocationCode = '') or LocationIsAllowed(LocationCode))
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
        Bin.TestField(Code);

        GetLocation(LocationCode);
        if Location."Directed Put-away and Pick" then
            Bin.TestField("Zone Code");
    end;

    local procedure GetItemUnitOfMeasure(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    procedure GetBaseUOM(ItemNo: Code[20]): Code[10]
    begin
        GetItem(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo = Item."No." then
            exit;

        Item.Get(ItemNo);
        OnGetItemOnAfterGetItem(Item);
        if Item."Item Tracking Code" <> '' then
            ItemTrackingCode.Get(Item."Item Tracking Code")
        else
            Clear(ItemTrackingCode);
    end;

    local procedure GetProdOrderCompLine(var ProdOrderCompLine: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20];
                                                                                                            ProdOrderLineNo: Integer;
                                                                                                            ProdOrdCompLineNo: Integer): Boolean
    begin
        if (ProdOrderNo = '') or
           (ProdOrderLineNo = 0) or
           (ProdOrdCompLineNo = 0)
        then
            exit(false);
        if (ProdOrderCompLine.Status <> Status) or
(ProdOrderCompLine."Prod. Order No." <> ProdOrderNo) or
(ProdOrderCompLine."Prod. Order Line No." <> ProdOrderLineNo) or
(ProdOrderCompLine."Line No." <> ProdOrdCompLineNo)
then begin
            if ProdOrderCompLine.Get(Status, ProdOrderNo, ProdOrderLineNo, ProdOrdCompLineNo) then
                exit(true);

            exit(false);
        end;
        exit(true);
    end;

    procedure ShowWhseRcptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Reset();
        WhseRcptLine.SetRange("No.", WhseDocNo);
        WhseRcptLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Receipt Lines", WhseRcptLine);
    end;

    procedure ShowPostedWhseRcptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseRcptLine.Reset();
        PostedWhseRcptLine.SetRange("No.", WhseDocNo);
        PostedWhseRcptLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Posted Whse. Receipt Lines", PostedWhseRcptLine);
    end;

    procedure ShowWhseShptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Reset();
        WhseShptLine.SetRange("No.", WhseDocNo);
        WhseShptLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Shipment Lines", WhseShptLine);
    end;

    procedure ShowPostedWhseShptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShptLine.Reset();
        PostedWhseShptLine.SetCurrentKey("Whse. Shipment No.", "Whse Shipment Line No.");
        PostedWhseShptLine.SetRange("Whse. Shipment No.", WhseDocNo);
        PostedWhseShptLine.SetRange("Whse Shipment Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Posted Whse. Shipment Lines", PostedWhseShptLine);
    end;

    procedure ShowWhseInternalPutawayLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
    begin
        WhseInternalPutawayLine.Reset();
        WhseInternalPutawayLine.SetRange("No.", WhseDocNo);
        WhseInternalPutawayLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Internal Put-away Lines", WhseInternalPutawayLine);
    end;

    procedure ShowWhseInternalPickLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.Reset();
        WhseInternalPickLine.SetRange("No.", WhseDocNo);
        WhseInternalPickLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Whse. Internal Pick Lines", WhseInternalPickLine);
    end;

    procedure ShowProdOrderLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", WhseDocNo);
        ProdOrderLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Prod. Order Line List", ProdOrderLine);
    end;

    procedure ShowAssemblyLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", WhseDocNo);
        AssemblyLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Assembly Lines", AssemblyLine);
    end;

    local procedure ShowJobPlanningLine(WhseDocLineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job Contract Entry No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Job Planning Lines", JobPlanningLine);
    end;

    procedure ShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20];
                                                               WhseDocLineNo: Integer)
    begin
        case WhseActivityDocType of
            WhseActivityDocType::Receipt:
                ShowPostedWhseRcptLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::Shipment:
                ShowWhseShptLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Internal Put-away":
                ShowWhseInternalPutawayLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Internal Pick":
                ShowWhseInternalPickLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::Production:
                ShowProdOrderLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::"Movement Worksheet":
                ;
            WhseActivityDocType::Assembly:
                ShowAssemblyLine(WhseDocNo, WhseDocLineNo);
            WhseActivityDocType::Job:
                ShowJobPlanningLine(WhseDocLineNo);
        end;
    end;

    procedure ShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", SourceSubType);
                    SalesLine.SetRange("Document No.", SourceNo);
                    SalesLine.SetRange("Line No.", SourceLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowSalesLines(SalesLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(PAGE::"Sales Lines", SalesLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", SourceSubType);
                    PurchLine.SetRange("Document No.", SourceNo);
                    PurchLine.SetRange("Line No.", SourceLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowPurchLines(PurchLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                end;
            DATABASE::"Transfer Line":
                begin
                    TransLine.Reset();
                    TransLine.SetRange("Document No.", SourceNo);
                    TransLine.SetRange("Line No.", SourceLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowTransLines(TransLine, SourceNo, SourceLineNo, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(PAGE::"Transfer Lines", TransLine);
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Reset();
                    ProdOrderComp.SetRange(Status, SourceSubType);
                    ProdOrderComp.SetRange("Prod. Order No.", SourceNo);
                    ProdOrderComp.SetRange("Prod. Order Line No.", SourceLineNo);
                    ProdOrderComp.SetRange("Line No.", SourceSubLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowProdOrderComp(ProdOrderComp, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, IsHandled);
                    if not IsHandled then
                        case SourceSubType of
                            3: // Released
                                PAGE.RunModal(PAGE::"Prod. Order Comp. Line List", ProdOrderComp);
                        end;
                end;
            DATABASE::"Assembly Line":
                begin
                    AssemblyLine.SetRange("Document Type", SourceSubType);
                    AssemblyLine.SetRange("Document No.", SourceNo);
                    AssemblyLine.SetRange("Line No.", SourceLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowAssemblyLines(AssemblyLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(PAGE::"Assembly Lines", AssemblyLine);
                end;
            DATABASE::Job:
                ShowJobPlanningLine(SourceLineNo);
            DATABASE::"Service Line":
                begin
                    ServiceLine.SetRange("Document Type", SourceSubType);
                    ServiceLine.SetRange("Document No.", SourceNo);
                    ServiceLine.SetRange("Line No.", SourceLineNo);
                    IsHandled := false;
                    OnShowSourceDocLineOnBeforeShowServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Service Line List", ServiceLine);
                end;
            else
                OnShowSourceDocLine(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
        end;
    end;

    procedure ShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", SourceSubType);
                    SalesLine.SetRange("Document No.", SourceNo);
                    SalesLine.SetRange("Attached to Line No.", SourceLineNo);
                    PAGE.RunModal(PAGE::"Sales Lines", SalesLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Document Type", SourceSubType);
                    PurchLine.SetRange("Document No.", SourceNo);
                    PurchLine.SetRange("Attached to Line No.", SourceLineNo);
                    PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                end;
            DATABASE::"Service Line":
                begin
                    ServiceLine.SetRange("Document Type", SourceSubType);
                    ServiceLine.SetRange("Document No.", SourceNo);
                    ServiceLine.SetRange("Attached to Line No.", SourceLineNo);
                    PAGE.Run(PAGE::"Service Line List", ServiceLine);
                end;
            else
                OnShowSourceDocAttachedLines(SourceType, SourceSubType, SourceNo, SourceLineNo);
        end;
    end;

    procedure ShowPostedSourceDocument(PostedSourceDoc: Enum "Warehouse Shipment Posted Source Document"; PostedSourceNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        TransShipmentHeader: Record "Transfer Shipment Header";
        TransReceiptHeader: Record "Transfer Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPostedSourceDocument(PostedSourceDoc, PostedSourceNo, IsHandled);
        if IsHandled then
            exit;

        case PostedSourceDoc of
            PostedSourceDoc::"Posted Shipment":
                begin
                    SalesShipmentHeader.Reset();
                    SalesShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Sales Shipment", SalesShipmentHeader);
                end;
            PostedSourceDoc::"Posted Receipt":
                begin
                    PurchRcptHeader.Reset();
                    PurchRcptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            PostedSourceDoc::"Posted Return Shipment":
                begin
                    ReturnShipmentHeader.Reset();
                    ReturnShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Return Shipment", ReturnShipmentHeader);
                end;
            PostedSourceDoc::"Posted Return Receipt":
                begin
                    ReturnReceiptHeader.Reset();
                    ReturnReceiptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Return Receipt", ReturnReceiptHeader);
                end;
            PostedSourceDoc::"Posted Transfer Shipment":
                begin
                    TransShipmentHeader.Reset();
                    TransShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Shipment", TransShipmentHeader);
                end;
            PostedSourceDoc::"Posted Transfer Receipt":
                begin
                    TransReceiptHeader.Reset();
                    TransReceiptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Receipt", TransReceiptHeader);
                end;
            else
                OnShowPostedSourceDoc(PostedSourceDoc.AsInteger(), PostedSourceNo);
        end;
    end;

    procedure ShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        TransHeader: Record "Transfer Header";
        ProdOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSourceDocCard(SourceType, SourceSubtype, SourceNo, IsHandled);
        if IsHandled then
            exit;

        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesHeader.SetRange("Document Type", SourceSubType);
                    if SalesHeader.Get(SourceSubType, SourceNo) then
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                            PAGE.RunModal(PAGE::"Sales Order", SalesHeader)
                        else
                            PAGE.RunModal(PAGE::"Sales Return Order", SalesHeader);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchHeader.SetRange("Document Type", SourceSubType);
                    if PurchHeader.Get(SourceSubType, SourceNo) then
                        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
                            PAGE.RunModal(PAGE::"Purchase Order", PurchHeader)
                        else
                            PAGE.RunModal(PAGE::"Purchase Return Order", PurchHeader);
                end;
            DATABASE::"Transfer Line":
                begin
                    if TransHeader.Get(SourceNo) then
                        PAGE.RunModal(PAGE::"Transfer Order", TransHeader);
                end;
            DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component":
                begin
                    ProdOrder.SetRange(Status, SourceSubType);
                    if ProdOrder.Get(SourceSubType, SourceNo) then
                        PAGE.RunModal(PAGE::"Released Production Order", ProdOrder);
                end;
            DATABASE::"Assembly Line":
                begin
                    AssemblyHeader.SetRange("Document Type", SourceSubType);
                    if AssemblyHeader.Get(SourceSubType, SourceNo) then
                        PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                end;
            Database::Job:
                if Job.Get(SourceNo) then
                    Page.RunModal(Page::"Job Card", Job);
            else
                OnShowSourceDocCard(SourceType, SourceSubType, SourceNo);
        end;
    end;

    local procedure TransferWhseItemTracking(var WhseJnlLine: Record "Warehouse Journal Line"; ItemJnlLine: Record "Item Journal Line")
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJnlLine."Item No.", WhseItemTrackingSetup);

        IsHandled := false;
        OnBeforeTransferWhseItemTracking(WhseJnlLine, ItemJnlLine, WhseItemTrackingSetup, IsHandled);
        if IsHandled then
            exit;

        if not WhseItemTrackingSetup.TrackingRequired() then
            exit;

        if WhseItemTrackingSetup."Serial No. Required" then
            WhseJnlLine.TestField("Qty. per Unit of Measure", 1);

        WhseItemTrackingSetup.CopyTrackingFromItemJnlLine(ItemJnlLine);
        WhseJnlLine.CopyTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
        WhseJnlLine."Warranty Date" := ItemJnlLine."Warranty Date";
        WhseJnlLine."Expiration Date" := ItemJnlLine."Item Expiration Date";

        OnAfterTransferWhseItemTrkg(WhseJnlLine, ItemJnlLine);
    end;

    procedure SetTransferLine(TransferLine: Record "Transfer Line"; var WhseJnlLine: Record "Warehouse Journal Line"; PostingType: Option Shipment,Receipt; PostedDocNo: Code[20])
    begin
        with TransferLine do begin
            WhseJnlLine.SetSource(DATABASE::"Transfer Line", PostingType, "Document No.", "Line No.", 0);
            WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
            if PostingType = PostingType::Shipment then
                WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment"
            else
                WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Receipt";
            WhseJnlLine."Reference No." := PostedDocNo;
            WhseJnlLine."Entry Type" := PostingType;
        end;
    end;

    local procedure SetZoneAndBins(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean)
    var
        IsDirectedPutAwayAndPick: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetZoneAndBins(ItemJnlLine, WhseJnlLine, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if (("Entry Type" in
                 ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::"Assembly Output"]) and
                (Quantity > 0)) or
               (("Entry Type" in
                 ["Entry Type"::Sale, "Entry Type"::"Negative Adjmt.", "Entry Type"::"Assembly Consumption"]) and
                (Quantity < 0)) or
               ToTransfer
            then begin
                if "Entry Type" = "Entry Type"::Transfer then
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement
                else
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                IsDirectedPutAwayAndPick := Location."Directed Put-away and Pick";
                OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJnlLine, Location, IsDirectedPutAwayAndPick);
                if IsDirectedPutAwayAndPick then
                    if "Entry Type" in ["Entry Type"::"Assembly Output", "Entry Type"::"Assembly Consumption"] then
                        WhseJnlLine."To Bin Code" := "Bin Code"
                    else
                        WhseJnlLine."To Bin Code" := GetWhseJnlLineBinCode("Source Code", "Bin Code", Location."Adjustment Bin Code")
                else
                    if ToTransfer then
                        WhseJnlLine."To Bin Code" := "New Bin Code"
                    else
                        WhseJnlLine."To Bin Code" := "Bin Code";
                GetBin("Location Code", WhseJnlLine."To Bin Code");
                WhseJnlLine."To Zone Code" := Bin."Zone Code";
            end else
                if (("Entry Type" in
                     ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::"Assembly Output"]) and
                    (Quantity < 0)) or
                   (("Entry Type" in
                     ["Entry Type"::Sale, "Entry Type"::"Negative Adjmt.", "Entry Type"::"Assembly Consumption"]) and
                    (Quantity > 0)) or
                   (("Entry Type" = "Entry Type"::Transfer) and (not ToTransfer))
                then begin
                    if "Entry Type" = "Entry Type"::Transfer then
                        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement
                    else
                        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                    IsDirectedPutAwayAndPick := Location."Directed Put-away and Pick";
                    OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJnlLine, Location, IsDirectedPutAwayAndPick);
                    if IsDirectedPutAwayAndPick then
                        if "Entry Type" in ["Entry Type"::"Assembly Output", "Entry Type"::"Assembly Consumption"] then
                            WhseJnlLine."From Bin Code" := "Bin Code"
                        else
                            WhseJnlLine."From Bin Code" := GetWhseJnlLineBinCode("Source Code", "Bin Code", Location."Adjustment Bin Code")
                    else
                        WhseJnlLine."From Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WhseJnlLine."From Bin Code");
                        WhseJnlLine."From Zone Code" := Bin."Zone Code";
                        WhseJnlLine."From Bin Type Code" := Bin."Bin Type Code";
                    end;
                end else
                    if "Phys. Inventory" and (Quantity = 0) and ("Invoiced Quantity" = 0) then begin
                        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                        if Location."Directed Put-away and Pick" then
                            WhseJnlLine."To Bin Code" := Location."Adjustment Bin Code"
                        else
                            WhseJnlLine."To Bin Code" := "Bin Code";
                        GetBin("Location Code", WhseJnlLine."To Bin Code");
                        WhseJnlLine."To Zone Code" := Bin."Zone Code";
                    end;

        OnAfterSetZoneAndBins(WhseJnlLine, ItemJnlLine, Location, Bin);
    end;

    local procedure SetZoneAndBinsForOutput(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        with ItemJnlLine do
            if "Output Quantity" >= 0 then begin
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                WhseJnlLine."To Bin Code" := "Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin("Location Code", WhseJnlLine."To Bin Code");
                    WhseJnlLine."To Zone Code" := Bin."Zone Code";
                end;
            end else begin
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                WhseJnlLine."From Bin Code" := "Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin("Location Code", WhseJnlLine."From Bin Code");
                    WhseJnlLine."From Zone Code" := Bin."Zone Code";
                end;
            end;
    end;

    local procedure SetZoneAndBinsForConsumption(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line")
    var
        ProdOrderCompLine: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetZoneAndBinsForConsumption(ItemJnlLine, ProdOrderCompLine, WhseJnlLine, Location, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if GetProdOrderCompLine(
                 ProdOrderCompLine, ProdOrderCompLine.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.")
            then
                if Quantity > 0 then begin
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                    WhseJnlLine."From Bin Code" := "Bin Code";
                    if Location."Bin Mandatory" and Location."Require Pick" and Location."Require Shipment" then begin
                        OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJnlLine, ProdOrderCompLine);
                        if (ProdOrderCompLine."Planning Level Code" = 0) and
                           ((ProdOrderCompLine."Flushing Method" = ProdOrderCompLine."Flushing Method"::Manual) or
                            (ProdOrderCompLine."Flushing Method" = ProdOrderCompLine."Flushing Method"::"Pick + Backward") or
                            ((ProdOrderCompLine."Flushing Method" = ProdOrderCompLine."Flushing Method"::"Pick + Forward") and
                             (ProdOrderCompLine."Routing Link Code" <> '')))
                        then
                            CheckProdOrderCompLineQtyPickedBase(ProdOrderCompLine, ItemJnlLine);
                        GetBin("Location Code", WhseJnlLine."From Bin Code");
                        WhseJnlLine."From Zone Code" := Bin."Zone Code";
                        WhseJnlLine."From Bin Type Code" := Bin."Bin Type Code";
                    end;
                end else begin
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                    WhseJnlLine."To Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WhseJnlLine."To Bin Code");
                        WhseJnlLine."To Zone Code" := Bin."Zone Code";
                    end;
                end
            else
                if Quantity > 0 then begin
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                    WhseJnlLine."From Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WhseJnlLine."From Bin Code");
                        WhseJnlLine."From Zone Code" := Bin."Zone Code";
                        WhseJnlLine."From Bin Type Code" := Bin."Bin Type Code";
                    end;
                end else begin
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                    WhseJnlLine."To Bin Code" := "Bin Code";
                    if Location."Directed Put-away and Pick" then begin
                        GetBin("Location Code", WhseJnlLine."To Bin Code");
                        WhseJnlLine."To Zone Code" := Bin."Zone Code";
                    end;
                end;
    end;

    local procedure CheckProdOrderCompLineQtyPickedBase(var ProdOrderCompLine: Record "Prod. Order Component"; ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderCompLineQtyPickedBase(ProdOrderCompLine, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderCompLine."Qty. Picked (Base)" < ItemJnlLine."Quantity (Base)" then
            ProdOrderCompLine.FieldError("Qty. Picked (Base)");
    end;

    procedure SerialNoOnInventory(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[50]): Boolean
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        with WhseEntry do begin
            GetLocation(LocationCode);
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Variant Code",
              "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetFilter("Bin Code", '<>%1', Location."Adjustment Bin Code");
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            SetRange("Serial No.", SerialNo);
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)" > 0);
        end;
    end;

    local procedure CheckSerialNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; SerialNo: Code[50]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode);
        BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < Abs(QuantityBase) then
            BinContent.FieldError(
              "Quantity (Base)", StrSubstNo(Text000, Abs(QuantityBase) - 1));
    end;

    local procedure CheckLotNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; LotNo: Code[50]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLotNo(ItemNo, VariantCode, LocationCode, BinCode, UOMCode, LotNo, QuantityBase, IsHandled);
        if IsHandled then
            exit;

        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode);
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < Abs(QuantityBase) then
            BinContent.FieldError(
              "Quantity (Base)", StrSubstNo(Text000, BinContent."Quantity (Base)" - Abs(QuantityBase)));
    end;

    procedure BinLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Item Filter", ItemNo);
        Bin.SetRange("Variant Filter", VariantCode);
        if ZoneCode <> '' then
            Bin.SetRange("Zone Code", ZoneCode);

        OnBinLookUpOnAfterSetFilters(Bin);
        if PAGE.RunModal(0, Bin) = ACTION::LookupOK then
            exit(Bin.Code);
    end;

    procedure BinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; CurrBinCode: Code[20]): Code[20]
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(BinContentLookUp(LocationCode, ItemNo, VariantCode, ZoneCode, DummyItemTrackingSetup, CurrBinCode));
    end;

    procedure BinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; CurrBinCode: Code[20]) BinCode: Code[20]
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBinContentLookUp(LocationCode, ItemNo, VariantCode, ZoneCode, WhseItemTrackingSetup, CurrBinCode, BinCode, IsHandled);
        if IsHandled then
            exit(BinCode);

        GetItem(ItemNo);
        BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode);
        BinContent.SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        BinContent.SetRange("Bin Code", CurrBinCode);
        if BinContent.FindFirst() then;
        BinContent.SetRange("Bin Code");

        if PAGE.RunModal(0, BinContent) = ACTION::LookupOK then
            exit(BinContent."Bin Code");
    end;

    procedure FindBin(LocationCode: Code[10]; BinCode: Code[20]; ZoneCode: Code[10])
    var
        Bin2: Record Bin;
    begin
        if ZoneCode <> '' then begin
            Bin2.SetCurrentKey("Location Code", "Zone Code", Code);
            Bin2.SetRange("Location Code", LocationCode);
            Bin2.SetRange("Zone Code", ZoneCode);
            Bin2.SetRange(Code, BinCode);
            Bin2.FindFirst();
        end else
            Bin2.Get(LocationCode, BinCode);
    end;

    procedure FindBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10])
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinContent(LocationCode, BinCode, ItemNo, VariantCode, ZoneCode, IsHandled);
        if IsHandled then
            exit;

        BinContent.SetLoadFields("Location Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        BinContent.FindFirst();
    end;

    procedure CalcLineReservedQtyNotonInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        ReservQtyNotonInvt: Decimal;
    begin
        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        if SourceType = DATABASE::"Prod. Order Component" then begin
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceSubLineNo, true);
            ReservEntry.SetSourceFilter('', SourceLineNo);
        end else begin
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            ReservEntry.SetSourceFilter('', 0);
        end;
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetFilter("Expected Receipt Date", '<>%1', 0D);
        ReservEntry.SetFilter("Shipment Date", '<>%1', 0D);
        if ReservEntry.Find('-') then
            repeat
                ReservQtyNotonInvt := ReservQtyNotonInvt + Abs(ReservEntry."Quantity (Base)");
            until ReservEntry.Next() = 0;
        exit(ReservQtyNotonInvt);
    end;

    procedure GetCaption(DestType: Option " ",Customer,Vendor,Location,Item,Family,"Sales Order"; SourceDoc: Option " ","Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output"; Selection: Integer): Text[50]
    begin
        exit(
            GetCaptionClass(
                "Warehouse Destination Type".FromInteger(DestType),
                "Warehouse Activity Source Document".FromInteger(SourceDoc), Selection));
    end;

    procedure GetCaptionClass(DestType: Enum "Warehouse Destination Type"; SourceDoc: Enum "Warehouse Activity Source Document";
                                            Selection: Integer): Text[50]
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        Family: Record Family;
        SalesHeader: Record "Sales Header";
        WhseActivHdr: Record "Warehouse Activity Header";
    begin
        case Selection of
            0:
                case DestType of
                    DestType::Vendor:
                        exit(Vendor.TableCaption + ' ' + Vendor.FieldCaption("No."));
                    DestType::Customer:
                        exit(Customer.TableCaption + ' ' + Customer.FieldCaption("No."));
                    DestType::Location:
                        exit(Location.TableCaption + ' ' + Location.FieldCaption(Code));
                    DestType::Item:
                        exit(Item.TableCaption + ' ' + Item.FieldCaption("No."));
                    DestType::Family:
                        exit(Family.TableCaption + ' ' + Family.FieldCaption("No."));
                    DestType::"Sales Order":
                        exit(Text009 + ' ' + SalesHeader.FieldCaption("No."));
                    else
                        exit(WhseActivHdr.FieldCaption("Destination No."));
                end;
            1:
                case DestType of
                    DestType::Vendor:
                        exit(Vendor.TableCaption + ' ' + Vendor.FieldCaption(Name));
                    DestType::Customer:
                        exit(Customer.TableCaption + ' ' + Customer.FieldCaption(Name));
                    DestType::Location:
                        exit(Location.TableCaption + ' ' + Location.FieldCaption(Name));
                    DestType::Item:
                        exit(Item.TableCaption + ' ' + Item.FieldCaption(Description));
                    DestType::Family:
                        exit(Family.TableCaption + ' ' + Family.FieldCaption(Description));
                    DestType::"Sales Order":
                        exit(Text009 + ' ' + SalesHeader.FieldCaption("Sell-to Customer Name"));
                    else
                        exit(Text008);
                end;
            2:
                if SourceDoc in [
                                 SourceDoc::"Purchase Order",
                                 SourceDoc::"Purchase Return Order"]
                then
                    exit(PurchHeader.FieldCaption("Vendor Shipment No."))
                else
                    exit(WhseActivHdr.FieldCaption("External Document No."));
            3:
                case SourceDoc of
                    SourceDoc::"Purchase Order":
                        exit(PurchHeader.FieldCaption("Vendor Invoice No."));
                    SourceDoc::"Purchase Return Order":
                        exit(PurchHeader.FieldCaption("Vendor Cr. Memo No."));
                    else
                        exit(WhseActivHdr.FieldCaption("External Document No.2"));
                end;
        end;
    end;

    procedure GetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestNo: Code[20]): Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        Family: Record Family;
        SalesHeader: Record "Sales Header";
        DestinationEntityName: Text[100];
    begin
        case DestinationType of
            DestinationType::Customer:
                if Customer.Get(DestNo) then
                    exit(Customer.Name);
            DestinationType::Vendor:
                if Vendor.Get(DestNo) then
                    exit(Vendor.Name);
            DestinationType::Location:
                if Location.Get(DestNo) then
                    exit(Location.Name);
            DestinationType::Item:
                if Item.Get(DestNo) then
                    exit(Item.Description);
            DestinationType::Family:
                if Family.Get(DestNo) then
                    exit(Family.Description);
            DestinationType::"Sales Order":
                if SalesHeader.Get(SalesHeader."Document Type"::Order, DestNo) then
                    exit(SalesHeader."Sell-to Customer Name");
            else begin
                DestinationEntityName := '';
                OnGetDestinationEntityName(DestinationType, DestNo, DestinationEntityName);
                exit(DestinationEntityName);
            end;
        end;
    end;

    procedure GetATOSalesLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; var SalesLine: Record "Sales Line"): Boolean
    begin
        if SourceType <> DATABASE::"Sales Line" then
            exit(false);
        if SalesLine.Get(SourceSubtype, SourceID, SourceRefNo) then
            exit(SalesLine."Qty. to Asm. to Order (Base)" <> 0);
    end;

    local procedure SetFiltersOnATOInvtPick(SalesLine: Record "Sales Line"; var WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            SetRange("Activity Type", "Activity Type"::"Invt. Pick");
            SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, false);
            SetRange("Assemble to Order", true);
            SetTrackingFilterIfNotEmpty();
        end;
    end;

    procedure ATOInvtPickExists(SalesLine: Record "Sales Line"): Boolean
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        SetFiltersOnATOInvtPick(SalesLine, WhseActivityLine);
        exit(not WhseActivityLine.IsEmpty);
    end;

    procedure CalcQtyBaseOnATOInvtPick(SalesLine: Record "Sales Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBase: Decimal
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup);
        SetFiltersOnATOInvtPick(SalesLine, WhseActivityLine);
        if WhseActivityLine.FindSet() then
            repeat
                QtyBase += WhseActivityLine."Qty. Outstanding (Base)";
            until WhseActivityLine.Next() = 0;
    end;

    procedure CheckOutboundBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        CheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, false);
    end;

    procedure CheckInboundBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        CheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, true);
    end;

    local procedure SetFiltersOnATOWhseShpt(SalesLine: Record "Sales Line"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
        with WhseShptLine do begin
            SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
            SetRange("Assemble to Order", true);
        end;
    end;

    procedure ATOWhseShptExists(SalesLine: Record "Sales Line"): Boolean
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        SetFiltersOnATOWhseShpt(SalesLine, WhseShptLine);
        exit(not WhseShptLine.IsEmpty);
    end;

    local procedure CheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, CheckInbound, IsHandled);
        if not IsHandled then begin
            GetLocation(LocationCode);
            if Location."Directed Put-away and Pick" then
                if BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode) then begin
                    if (CheckInbound and
                        (BinContent."Block Movement" in [BinContent."Block Movement"::Inbound, BinContent."Block Movement"::All])) or
                       (not CheckInbound and
                        (BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]))
                    then
                        BinContent.FieldError("Block Movement");
                end else
                    if Location."Bin Mandatory" then begin
                        GetBin(LocationCode, BinCode);
                        if (CheckInbound and (Bin."Block Movement" in [Bin."Block Movement"::Inbound, Bin."Block Movement"::All])) or
                           (not CheckInbound and (Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All]))
                        then
                            Bin.FieldError("Block Movement");
                    end;
        end;
        OnAfterCheckBlockedBin(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, CheckInbound);
    end;

    local procedure GetWhseJnlLineBinCode(SourceCode: Code[10]; BinCode: Code[20]; AdjBinCode: Code[20]) Result: Code[20]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        Result := AdjBinCode;
        if BinCode <> '' then begin
            SourceCodeSetup.Get();
            if SourceCode = SourceCodeSetup."Service Management" then
                Result := BinCode;
        end;
        OnAfterGetWhseJnlLineBinCode(SourceCode, BinCode, AdjBinCode, SourceCodeSetup, Result);
    end;

    procedure GetLastOperationLocationCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        with RoutingLine do begin
            SetRange("Routing No.", RoutingNo);
            SetRange("Version Code", RoutingVersionCode);
            if FindLast() then
                exit(GetProdCenterLocationCode(Type, "No."));
        end;
    end;

    procedure GetLastOperationFromBinCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Option Manual,Forward,Backward,"Pick + Forward","Pick + Backward"): Code[20]
    var
        RoutingLine: Record "Routing Line";
    begin
        with RoutingLine do begin
            SetRange("Routing No.", RoutingNo);
            SetRange("Version Code", RoutingVersionCode);
            if FindLast() then
                exit(GetProdCenterBinCode(Type, "No.", LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    procedure GetProdRoutingLastOperationFromBinCode(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20];
                                                                          RoutingRefNo: Integer;
                                                                          RoutingNo: Code[20];
                                                                          LocationCode: Code[10]): Code[20]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        if ProdOrderRoutingLine.FindLast() then
            exit(GetProdCenterBinCode(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", LocationCode, false, 0));
    end;

    procedure GetPlanningRtngLastOperationFromBinCode(WkshTemplateName: Code[10]; WkshBatchName: Code[10]; WkshLineNo: Integer; LocationCode: Code[10]): Code[20]
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        with PlanningRoutingLine do begin
            SetRange("Worksheet Template Name", WkshTemplateName);
            SetRange("Worksheet Batch Name", WkshBatchName);
            SetRange("Worksheet Line No.", WkshLineNo);
            if FindLast() then
                exit(GetProdCenterBinCode(Type, "No.", LocationCode, false, 0));
        end;
    end;

    procedure GetProdCenterLocationCode(Type: Enum "Capacity Type"; No: Code[20]): Code[10]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case Type of
            Type::"Work Center":
                begin
                    WorkCenter.Get(No);
                    exit(WorkCenter."Location Code");
                end;
            Type::"Machine Center":
                begin
                    MachineCenter.Get(No);
                    exit(MachineCenter."Location Code");
                end;
        end;
    end;

    procedure GetProdCenterBinCode(Type: Enum "Capacity Type"; No: Code[20];
                                             LocationCode: Code[10];
                                             UseFlushingMethod: Boolean;
                                             FlushingMethod: Option Manual,Forward,Backward,"Pick + Forward","Pick + Backward"): Code[20]
    begin
        case Type of
            Type::"Work Center":
                exit(GetWorkCenterBinCode(No, LocationCode, UseFlushingMethod, "Flushing Method".FromInteger(FlushingMethod)));
            Type::"Machine Center":
                exit(GetMachineCenterBinCode(No, LocationCode, UseFlushingMethod, "Flushing Method".FromInteger(FlushingMethod)));
        end;
    end;

    local procedure GetMachineCenterBinCode(MachineCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        MachineCenter: Record "Machine Center";
    begin
        if MachineCenter.Get(MachineCenterNo) then begin
            if MachineCenter."Location Code" = LocationCode then
                exit(MachineCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));

            exit(GetWorkCenterBinCode(MachineCenter."Work Center No.", LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    local procedure GetWorkCenterBinCode(WorkCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get(WorkCenterNo) then
            if WorkCenter."Location Code" = LocationCode then
                exit(WorkCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingSpecificationChangeNeeded(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var CheckNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLine(var WhseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line"; ToTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromConsumJnl(var WhseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromOutputJnl(var WhseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseJnlLineBinCode(SourceCode: Code[10]; BinCode: Code[20]; AdjBinCode: Code[20]; SourceCodeSetup: Record "Source Code Setup"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetZoneAndBins(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line"; Location: Record Location; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferWhseItemTrkg(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinContentLookUp(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; CurrBinCode: Code[20]; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalanceQtyToHandle(var WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CheckInbound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDecreaseBinContent(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLineLocation(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLineFieldChange(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line"; CurrentFieldCaption: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLotNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; LotNo: Code[50]; QuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocumentFromZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocumentToZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckToZoneCode(WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingChange(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPutAwayAvailability(BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal; Prohibit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUserIsWhseEmployee(Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; SourceJnl: Option " ",ItemJnl,OutputJnl,ConsumpJnl,WhseJnl; DecreaseQtyBase: Decimal; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderCompLineQtyPickedBase(var ProdOrderCompLine: Record "Prod. Order Component"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmExceededCapacity(var IsHandled: Boolean; BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLineFromOutputJnl(ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemJnlTemplateType: Option; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAllowedLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultDirectedPutawayAndPickLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultLocation(var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWrongPickPutAwayQtyErrorText(var WhseActivLine: Record "Warehouse Activity Line"; QtyToPick: Decimal; QtyToPutAway: Decimal; var ErrorTxt: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLocationIsAllowed(LocationCode: Code[10]; var LocationAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostedSourceDocument(PostedSourceDoc: Enum "Warehouse Shipment Posted Source Document"; PostedSourceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetZoneAndBins(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinLookUpOnAfterSetFilters(var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBalanceQtyToHandleOnAfterSetFilters(var ToWarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnAfterCheckTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemTrackingCode: Record "Item Tracking Code"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnAfterGetLocation(var WarehouseJournalLine: Record "Warehouse Journal Line"; var Location: Record Location; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnAfterGetLocation(var ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineFromOutputJnlOnAfterInitWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseJnlLineTracking(var WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemOnAfterGetItem(var Item: Record "Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseJnlLineCopyFromItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowSalesLines(var SalesLine: Record "Sales Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowPurchLines(var PurchLine: Record "Purchase Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowServiceLines(var ServiceLine: Record "Service Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowTransLines(var TransferLine: Record "Transfer Line"; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowAssemblyLines(var AssemblyLine: Record "Assembly Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLineOnBeforeShowProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLineOnBeforeCheckBySourceJnl(var WhseJnlLine: Record "Warehouse Journal Line"; var Bin: Record Bin; SourceJnl: Option; var BinContent: Record "Bin Content"; Location: Record Location; DecreaseQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetZoneAndBinsForConsumption(ItemJnlLine: Record "Item Journal Line"; var ProdOrderCompLine: Record "Prod. Order Component"; var WhseJnlLine: Record "Warehouse Journal Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTransferWhseItemTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZoneAndBinsOnAfterCalcIsDirectedPutAwayAndPick(ItemJnlLine: Record "Item Journal Line"; Location: Record Location; var IsDirectedPutAwayAndPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWhseJnlLineOnAfterGetQuantity(ItemJnlLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; Location: Record Location)
    begin
    end;
    
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCubageAndWeight(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; var Cubage: Decimal; var Weight: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestNo: Code[20]; var DestinationName: Text[100])
    begin
    end;
}

