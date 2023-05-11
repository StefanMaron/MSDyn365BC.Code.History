codeunit 21 "Item Jnl.-Check Line"
{
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        Location: Record Location;
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        DimMgt: Codeunit DimensionManagement;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;

        Text000: Label 'cannot be a closing date';
        Text003: Label 'must not be negative when %1 is %2';
        Text004: Label 'must have the same value as %1';
        Text005: Label 'must be %1 or %2 when %3 is %4';
        Text006: Label 'must equal %1 - %2 when %3 is %4 and %5 is %6';
        Text007: Label 'You cannot post these lines because you have not entered a quantity on one or more of the lines. ';
        DimCombBlockedErr: Label 'The combination of dimensions used in item journal line %1, %2, %3 is blocked. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No.';
        DimCausedErr: Label 'A dimension used in item journal line %1, %2, %3 has caused an error. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No.';
        Text011: Label '%1 must not be equal to %2';
        Text012: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.';
        UseInTransitLocationErr: Label 'You can use In-Transit location %1 for transfer orders only.';

    procedure RunCheck(var ItemJournalLine: Record "Item Journal Line")
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
        ShouldCheckApplication: Boolean;
        ShouldCheckDiscountAmount: Boolean;
        ShouldCheckLocationCode: Boolean;
        ShouldCheckItemNo: Boolean;
    begin
        GLSetup.Get();
        InvtSetup.Get();

        with ItemJournalLine do begin
            if EmptyLine() then begin
                if not IsValueEntryForDeletedItem() then
                    exit;
            end else
                if not OnlyStopTime() then
                    TestField("Item No.", ErrorInfo.Create());

            if Item.Get("Item No.") then
                Item.TestField("Base Unit of Measure", ErrorInfo.Create());

            IsHandled := false;
            OnAfterGetItem(Item, ItemJournalLine, IsHandled);
            if IsHandled then
                exit;

            TestField("Document No.", ErrorInfo.Create());
            TestField("Gen. Prod. Posting Group", ErrorInfo.Create());

            CheckDates(ItemJournalLine);

            IsHandled := false;
            OnBeforeCheckLocation(ItemJournalLine, IsHandled);
            if not IsHandled then
                if InvtSetup."Location Mandatory" and
                    ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   (Quantity <> 0) and
                   not Adjustment
                then begin
                    ShouldCheckLocationCode := (Type <> Type::Resource) and (Item.Type = Item.Type::Inventory) and
                       (not "Direct Transfer" or ("Document Type" = "Document Type"::"Transfer Shipment"));
                    OnRunCheckOnAfterCalcShouldCheckLocationCode(ItemJournalLine, ShouldCheckLocationCode);
                    if ShouldCheckLocationCode then
                        TestField("Location Code", ErrorInfo.Create());
                    if ("Entry Type" = "Entry Type"::Transfer) and
                       (not "Direct Transfer" or ("Document Type" = "Document Type"::"Transfer Receipt"))
                    then
                        TestField("New Location Code", ErrorInfo.Create())
                    else
                        TestField("New Location Code", '', ErrorInfo.Create());
                    if GLSetup."Journal Templ. Name Mandatory" and
                        (InvtSetup."Automatic Cost Posting" or InvtSetup."Expected Cost Posting to G/L")
                    then begin
                        InvtSetup.TestField("Invt. Cost Jnl. Template Name", ErrorInfo.Create());
                        InvtSetup.TestField("Invt. Cost Jnl. Batch Name", ErrorInfo.Create());
                    end;
                end;

            CheckVariantMandatory(ItemJournalLine, Item);

            CheckInTransitLocations(ItemJournalLine);

            if Item.IsInventoriableType() then
                CheckBins(ItemJournalLine)
            else
                ItemJournalLine.TestField("Bin Code", '', ErrorInfo.Create());

            ShouldCheckDiscountAmount := "Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."];
            OnRunCheckOnAfterCalcShouldCheckDiscountAmount(ItemJournalLine, ShouldCheckDiscountAmount);
            if ShouldCheckDiscountAmount then
                TestField("Discount Amount", 0, ErrorInfo.Create());

            if "Entry Type" = "Entry Type"::Transfer then begin
                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '') and
                   not Adjustment
                then
                    TestField(Amount, 0, ErrorInfo.Create());
                TestField("Discount Amount", 0, ErrorInfo.Create());
                if (Quantity < 0) and not Correction then
                    FieldError(Quantity, ErrorInfo.Create(StrSubstNo(Text003, FieldCaption("Entry Type"), "Entry Type"), true));
                if Quantity <> "Invoiced Quantity" then
                    FieldError("Invoiced Quantity", ErrorInfo.Create(StrSubstNo(Text004, FieldCaption(Quantity)), true));
            end;

            if not "Phys. Inventory" then begin
                CheckEmptyQuantity(ItemJournalLine);
                TestField("Qty. (Calculated)", 0, ErrorInfo.Create());
                TestField("Qty. (Phys. Inventory)", 0, ErrorInfo.Create());
            end else
                CheckPhysInventory(ItemJournalLine);

            CheckOutputFields(ItemJournalLine);

            ShouldCheckApplication := "Applies-from Entry" <> 0;
            OnRunCheckOnAfterCalcShouldCheckApplication(ItemJournalLine, ShouldCheckApplication);
            if ShouldCheckApplication then begin
                ItemLedgEntry.Get("Applies-from Entry");
                ItemLedgEntry.TestField("Item No.", "Item No.", ErrorInfo.Create());
                ItemLedgEntry.TestField("Variant Code", "Variant Code", ErrorInfo.Create());
                ItemLedgEntry.TestField(Positive, false, ErrorInfo.Create());
                if "Applies-to Entry" = "Applies-from Entry" then
                    Error(
                        ErrorInfo.Create(
                            StrSubstNo(
                                Text011,
                                FieldCaption("Applies-to Entry"),
                                FieldCaption("Applies-from Entry")),
                            true));
            end;

            if ("Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output]) and
               not ("Value Entry Type" = "Value Entry Type"::Revaluation) and
               not OnlyStopTime()
            then begin
                TestField("Source No.", ErrorInfo.Create());
                TestField("Order Type", "Order Type"::Production, ErrorInfo.Create());
                ShouldCheckItemNo := not CalledFromAdjustment and ("Entry Type" = "Entry Type"::Output);
                OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine, ProdOrderLine, CalledFromAdjustment, ShouldCheckItemNo);
                if ShouldCheckItemNo then
                    if CheckFindProdOrderLine(ProdOrderLine, "Order No.", "Order Line No.") then begin
                        TestField("Item No.", ProdOrderLine."Item No.", ErrorInfo.Create());
                        OnAfterCheckFindProdOrderLine(ItemJournalLine, ProdOrderLine);
                    end;

                if Subcontracting then begin
                    IsHandled := false;
                    OnBeforeCheckSubcontracting(ItemJournalLine, IsHandled);
                    if not IsHandled then begin
                        WorkCenter.Get("Work Center No.");
                        WorkCenter.TestField("Subcontractor No.", ErrorInfo.Create());
                    end;
                end;
                if not CalledFromInvtPutawayPick then
                    CheckWarehouse(ItemJournalLine);
            end;

            if "Entry Type" = "Entry Type"::"Assembly Consumption" then
                CheckWarehouse(ItemJournalLine);

            if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or ("Item Charge No." <> '') then
                if "Inventory Value Per" = "Inventory Value Per"::" " then
                    TestField("Applies-to Entry", ErrorInfo.Create());

            CheckDimensions(ItemJournalLine);

            if ("Entry Type" in
                ["Entry Type"::Purchase, "Entry Type"::Sale, "Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) and
               (not GenJnlPostPreview.IsActive())
            then
                CheckItemJournalLineRestriction();
        end;

        OnAfterCheckItemJnlLine(ItemJournalLine, CalledFromInvtPutawayPick, CalledFromAdjustment);
    end;

    local procedure CheckOutputFields(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOutputFields(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine."Entry Type" <> ItemJournalLine."Entry Type"::Output then begin
            ItemJournalLine.TestField("Run Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Setup Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Stop Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Output Quantity", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Scrap Quantity", 0, ErrorInfo.Create());
        end;
    end;

    local procedure CheckEmptyQuantity(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmptyQuantity(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if "Entry Type" = "Entry Type"::Output then begin
                if ("Output Quantity (Base)" = 0) and ("Scrap Quantity (Base)" = 0) and
                   TimeIsEmpty() and ("Invoiced Qty. (Base)" = 0)
                then
                    Error(ErrorInfo.Create(Text007, true))
            end else
                if ("Quantity (Base)" = 0) and ("Invoiced Qty. (Base)" = 0) then
                    Error(ErrorInfo.Create(Text007, true));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure CheckFindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; LineNo: Integer): Boolean
    begin
        with ProdOrderLine do begin
            SetFilter(Status, '>=%1', Status::Released);
            SetRange("Prod. Order No.", ProdOrderNo);
            SetRange("Line No.", LineNo);
            exit(FindFirst());
        end;
    end;

    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    local procedure CheckWarehouse(ItemJnlLine: Record "Item Journal Line")
    var
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (ItemJnlLine.Quantity = 0) or
           (ItemJnlLine."Item Charge No." <> '') or
           (ItemJnlLine."Value Entry Type" in
            [ItemJnlLine."Value Entry Type"::Revaluation, ItemJnlLine."Value Entry Type"::Rounding]) or
           ItemJnlLine.Adjustment
        then
            exit;

        GetLocation(ItemJnlLine."Location Code");
        if Location."Directed Put-away and Pick" then
            exit;

        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Output:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then begin
                    if (ItemJnlLine.Quantity < 0) and (ItemJnlLine."Applies-to Entry" = 0) then begin
                        ReservationEntry.InitSortingAndFilters(false);
                        ItemJnlLine.SetReservationFilters(ReservationEntry);
                        ReservationEntry.ClearTrackingFilter();
                        if ReservationEntry.FindSet() then
                            repeat
                                if ReservationEntry."Appl.-to Item Entry" = 0 then
                                    ShowError := true;
                            until (ReservationEntry.Next() = 0) or ShowError
                        else
                            ShowError := CheckWarehouseLastOutputOperation(ItemJnlLine);
                    end;

                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Prod. Order Line", 3, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.", 0, ItemJnlLine.Quantity)
                    then
                        ShowError := true;
                end;
            ItemJnlLine."Entry Type"::Consumption:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Prod. Order Component",
                         3,
                         ItemJnlLine."Order No.",
                         ItemJnlLine."Order Line No.",
                         ItemJnlLine."Prod. Order Comp. Line No.",
                         ItemJnlLine.Quantity)
                    then
                        ShowError := true;
            ItemJnlLine."Entry Type"::"Assembly Consumption":
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Assembly Line",
                         AssemblyLine."Document Type"::Order.AsInteger(),
                         ItemJnlLine."Order No.",
                         ItemJnlLine."Order Line No.",
                         0,
                         ItemJnlLine.Quantity)
                    then
                        ShowError := true;
        end;
        if ShowError then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text012,
                        ItemJnlLine.FieldCaption("Entry Type"),
                        ItemJnlLine."Entry Type",
                        ItemJnlLine.FieldCaption("Order No."),
                        ItemJnlLine."Order No.",
                        ItemJnlLine.FieldCaption("Order Line No."),
                        ItemJnlLine."Order Line No."),
                    true));
    end;

    local procedure CheckWarehouseLastOutputOperation(ItemJnlLine: Record "Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouseLastOutputOperation(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ItemJnlLine.LastOutputOperation(ItemJnlLine);
    end;

    local procedure WhseOrderHandlingRequired(ItemJnlLine: Record "Item Journal Line"; Location: Record Location): Boolean
    var
        InvtPutAwayLocation: Boolean;
        InvtPickLocation: Boolean;
    begin
        InvtPutAwayLocation := not Location."Require Receive" and Location."Require Put-away";
        OnAfterAssignInvtPutAwayRequired(ItemJnlLine, Location, InvtPutAwayLocation);
        if InvtPutAwayLocation then
            case ItemJnlLine."Entry Type" of
                ItemJnlLine."Entry Type"::Output:
                    if ItemJnlLine.Quantity >= 0 then
                        exit(true);
                ItemJnlLine."Entry Type"::Consumption,
              ItemJnlLine."Entry Type"::"Assembly Consumption":
                    if ItemJnlLine.Quantity < 0 then
                        exit(true);
            end;

        InvtPickLocation := not Location."Require Shipment" and Location."Require Pick";
        OnAfterAssignInvtPickRequired(ItemJnlLine, Location, InvtPickLocation);
        if InvtPickLocation then
            case ItemJnlLine."Entry Type" of
                ItemJnlLine."Entry Type"::Output:
                    if ItemJnlLine.Quantity < 0 then
                        exit(true);
                ItemJnlLine."Entry Type"::Consumption,
              ItemJnlLine."Entry Type"::"Assembly Consumption":
                    if ItemJnlLine.Quantity >= 0 then
                        exit(true);
            end;

        exit(false);
    end;

    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
    end;

    local procedure CheckBins(ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBins(ItemJnlLine, IsHandled, CalledFromAdjustment);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if ("Item Charge No." <> '') or ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or (Quantity = 0) then
                exit;

            if "Entry Type" = "Entry Type"::Transfer then begin
                GetLocation("New Location Code");
                CheckNewBinCode(ItemJnlLine);
            end else begin
                GetLocation("Location Code");
                if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
                    exit;
            end;

            if "Drop Shipment" or OnlyStopTime() or ("Quantity (Base)" = 0) or Adjustment or CalledFromAdjustment then
                exit;

            if ("Entry Type" = "Entry Type"::Output) and not LastOutputOperation(ItemJnlLine) then
                exit;

            IsHandled := false;
            OnCheckBinsOnBeforeCheckNonZeroQuantity(ItemJnlLine, CalledFromAdjustment, IsHandled);
            if not IsHandled then
                if Quantity <> 0 then
                    case "Entry Type" of
                        "Entry Type"::Purchase,
                      "Entry Type"::"Positive Adjmt.",
                      "Entry Type"::Output,
                      "Entry Type"::"Assembly Output":
                            WMSManagement.CheckInbOutbBin("Location Code", "Bin Code", Quantity > 0);
                        "Entry Type"::Sale,
                      "Entry Type"::"Negative Adjmt.",
                      "Entry Type"::Consumption,
                      "Entry Type"::"Assembly Consumption":
                            WMSManagement.CheckInbOutbBin("Location Code", "Bin Code", Quantity < 0);
                        "Entry Type"::Transfer:
                            begin
                                GetLocation("Location Code");
                                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                                    WMSManagement.CheckInbOutbBin("Location Code", "Bin Code", Quantity < 0);
                                if ("New Location Code" <> '') and ("New Bin Code" <> '') then
                                    WMSManagement.CheckInbOutbBin("New Location Code", "New Bin Code", Quantity > 0);
                            end;
                    end;
        end;
    end;

    local procedure CheckNewBinCode(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNewBinCode(ItemJnlLine, Location, IsHandled);
        if IsHandled then
            exit;

        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
            ItemJnlLine.TestField("New Bin Code", ErrorInfo.Create());
    end;

    local procedure CheckDates(ItemJnlLine: Record "Item Journal Line")
    var
        InvtPeriod: Record "Inventory Period";
        UserSetupManagement: Codeunit "User Setup Management";
        DateCheckDone: Boolean;
        ShouldShowError: Boolean;
    begin
        with ItemJnlLine do begin
            TestField("Posting Date", ErrorInfo.Create());
            if "Posting Date" <> NormalDate("Posting Date") then
                FieldError("Posting Date", ErrorInfo.Create(Text000, true));

            OnBeforeDateNotAllowed(ItemJnlLine, DateCheckDone);
            if not DateCheckDone then
                UserSetupManagement.CheckAllowedPostingDate("Posting Date");

            ShouldShowError := not InvtPeriod.IsValidDate("Posting Date");
            OnCheckDatesOnAfterCalcShouldShowError(ItemJnlLine, ShouldShowError, CalledFromAdjustment);
            if ShouldShowError then
                InvtPeriod.ShowError("Posting Date");

            if "Document Date" <> 0D then
                if "Document Date" <> NormalDate("Document Date") then
                    FieldError("Document Date", ErrorInfo.Create(Text000, true));
        end;
    end;

    local procedure CheckDimensions(ItemJnlLine: Record "Item Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if not IsValueEntryForDeletedItem() and not Correction and not CalledFromAdjustment then begin
                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    Error(
                        ErrorInfo.Create(
                            StrSubstNo(
                                DimCombBlockedErr, "Journal Template Name", "Journal Batch Name", "Line No.", DimMgt.GetDimCombErr()),
                            true));
                if "Item Charge No." = '' then begin
                    TableID[1] := DATABASE::Item;
                    No[1] := "Item No.";
                end else begin
                    TableID[1] := DATABASE::"Item Charge";
                    No[1] := "Item Charge No.";
                end;
                TableID[2] := DATABASE::"Salesperson/Purchaser";
                No[2] := "Salespers./Purch. Code";
                TableID[3] := DATABASE::"Work Center";
                No[3] := "Work Center No.";
                TableID[4] := DATABASE::Location;
                No[4] := "Location Code";
                TableID[5] := DATABASE::Location;
                No[5] := "New Location Code";
                OnCheckDimensionsOnAfterAssignDimTableIDs(ItemJnlLine, TableID, No);
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then begin
                    if "Line No." <> 0 then
                        Error(
                            ErrorInfo.Create(
                                StrSubstNo(DimCausedErr, "Journal Template Name", "Journal Batch Name", "Line No.", DimMgt.GetDimValuePostingErr()),
                            true));
                    Error(ErrorInfo.Create(StrSubstNo(DimMgt.GetDimValuePostingErr()), true));
                end;
                if ("Entry Type" = "Entry Type"::Transfer) and
                   ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then
                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then begin
                        if "Line No." <> 0 then
                            Error(
                                ErrorInfo.Create(
                                    StrSubstNo(DimCausedErr, "Journal Template Name", "Journal Batch Name", "Line No.", DimMgt.GetDimValuePostingErr()),
                                true));
                        Error(ErrorInfo.Create(StrSubstNo(DimMgt.GetDimValuePostingErr()), true));
                    end;
            end;
    end;

    local procedure CheckPhysInventory(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPhysInventory(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            if not
               ("Entry Type" in
                ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."])
            then begin
                ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Positive Adjmt.";
                ItemJnlLine3."Entry Type" := ItemJnlLine3."Entry Type"::"Negative Adjmt.";
                FieldError(
                    "Entry Type",
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text005, ItemJnlLine2."Entry Type", ItemJnlLine3."Entry Type", FieldCaption("Phys. Inventory"), true),
                        true));
            end;
            if ("Entry Type" = "Entry Type"::"Positive Adjmt.") and
               ("Qty. (Phys. Inventory)" - "Qty. (Calculated)" <> Quantity)
            then
                FieldError(
                    Quantity,
                     ErrorInfo.Create(
                        StrSubstNo(
                            Text006, FieldCaption("Qty. (Phys. Inventory)"), FieldCaption("Qty. (Calculated)"),
                            FieldCaption("Entry Type"), "Entry Type", FieldCaption("Phys. Inventory"), true),
                        true));
            if ("Entry Type" = "Entry Type"::"Negative Adjmt.") and
               ("Qty. (Calculated)" - "Qty. (Phys. Inventory)" <> Quantity)
            then
                FieldError(
                    Quantity,
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text006, FieldCaption("Qty. (Calculated)"), FieldCaption("Qty. (Phys. Inventory)"),
                            FieldCaption("Entry Type"), "Entry Type", FieldCaption("Phys. Inventory"), true),
                        true));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; CalledFromInvtPutawayPick: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    local procedure CheckInTransitLocation(LocationCode: Code[10])
    begin
        if Location.IsInTransit(LocationCode) then
            Error(ErrorInfo.Create(StrSubstNo(UseInTransitLocationErr, LocationCode), true));
    end;

    local procedure CheckInTransitLocations(var ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInTransitLocations(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do
            if (("Entry Type" <> "Entry Type"::Transfer) or ("Order Type" <> "Order Type"::Transfer)) and
               not Adjustment
            then begin
                CheckInTransitLocation("Location Code");
                CheckInTransitLocation("New Location Code");
            end;
    end;

    local procedure CheckVariantMandatory(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVariantMandatory(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine."Item Charge No." <> '' then
            exit;

        if ItemJournalLine."Inventory Value Per" in [ItemJournalLine."Inventory Value Per"::Item, ItemJournalLine."Inventory Value Per"::Location] then
            exit;

        if Item.IsVariantMandatory(InvtSetup."Variant Mandatory if Exists") then
            ItemJournalLine.TestField("Variant Code", ErrorInfo.Create());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPickLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPutAwayRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPutAwayLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFindProdOrderLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBins(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInTransitLocations(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocation(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSubcontracting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouseLastOutputOperation(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOutputFields(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDateNotAllowed(ItemJnlLine: Record "Item Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPhysInventory(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmptyQuantity(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNewBinCode(ItemJnlLine: Record "Item Journal Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinsOnBeforeCheckNonZeroQuantity(ItemJnlLine: Record "Item Journal Line"; var CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDatesOnAfterCalcShouldShowError(var ItemJournalLine: Record "Item Journal Line"; var ShouldShowError: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var ItemJnlLine: Record "Item Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; CalledFromAdjustment: Boolean; var ShouldCheckItemNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckLocationCode(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckLocationCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckDiscountAmount(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckDiscountAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVariantMandatory(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckApplication(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckApplication: Boolean)
    begin
    end;
}

