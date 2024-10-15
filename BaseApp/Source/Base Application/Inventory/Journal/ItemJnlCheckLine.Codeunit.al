namespace Microsoft.Inventory.Journal;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using System.Security.User;
using Microsoft.Manufacturing.Setup;

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
        Text1130000: Label 'You cannot post these lines because you have not entered a WIP quantity on one or more of the lines.';

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

        if ItemJournalLine.EmptyLine() then begin
            if not ItemJournalLine.IsValueEntryForDeletedItem() then
                exit;
        end else
            if not ItemJournalLine.OnlyStopTime() then
                ItemJournalLine.TestField("Item No.", ErrorInfo.Create());

        if Item.Get(ItemJournalLine."Item No.") then
            Item.TestField("Base Unit of Measure", ErrorInfo.Create());

        IsHandled := false;
        OnAfterGetItem(Item, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        ItemJournalLine.TestField("Document No.", ErrorInfo.Create());
        ItemJournalLine.TestField("Gen. Prod. Posting Group", ErrorInfo.Create());

        CheckDates(ItemJournalLine);

        IsHandled := false;
        OnBeforeCheckLocation(ItemJournalLine, IsHandled);
        if not IsHandled then
            if InvtSetup."Location Mandatory" and
                (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
               (ItemJournalLine.Quantity <> 0) and
               not ItemJournalLine.Adjustment and
               not ItemJournalLine.Correction
            then begin
                ShouldCheckLocationCode := (ItemJournalLine.Type <> ItemJournalLine.Type::Resource) and (Item.Type = Item.Type::Inventory) and
                   (not ItemJournalLine."Direct Transfer" or (ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Transfer Shipment"));
                OnRunCheckOnAfterCalcShouldCheckLocationCode(ItemJournalLine, ShouldCheckLocationCode);
                if ShouldCheckLocationCode then
                    ItemJournalLine.TestField("Location Code", ErrorInfo.Create());
                if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer) and
                   (not ItemJournalLine."Direct Transfer" or (ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Transfer Receipt"))
                then
                    ItemJournalLine.TestField("New Location Code", ErrorInfo.Create())
                else
                    ItemJournalLine.TestField("New Location Code", '', ErrorInfo.Create());
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

        ShouldCheckDiscountAmount := ItemJournalLine."Entry Type" in [ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Negative Adjmt."];
        OnRunCheckOnAfterCalcShouldCheckDiscountAmount(ItemJournalLine, ShouldCheckDiscountAmount);
        if ShouldCheckDiscountAmount then
            ItemJournalLine.TestField("Discount Amount", 0, ErrorInfo.Create());

        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then begin
            if (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
               (ItemJournalLine."Item Charge No." = '') and
               not ItemJournalLine.Adjustment
            then
                ItemJournalLine.TestField(Amount, 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Discount Amount", 0, ErrorInfo.Create());
            if (ItemJournalLine.Quantity < 0) and not ItemJournalLine.Correction then
                ItemJournalLine.FieldError(Quantity, ErrorInfo.Create(StrSubstNo(Text003, ItemJournalLine.FieldCaption("Entry Type"), ItemJournalLine."Entry Type"), true));
            if ItemJournalLine.Quantity <> ItemJournalLine."Invoiced Quantity" then
                ItemJournalLine.FieldError("Invoiced Quantity", ErrorInfo.Create(StrSubstNo(Text004, ItemJournalLine.FieldCaption(Quantity)), true));
        end;

        if not ItemJournalLine."Phys. Inventory" then begin
            CheckEmptyQuantity(ItemJournalLine);
            ItemJournalLine.TestField("Qty. (Calculated)", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Qty. (Phys. Inventory)", 0, ErrorInfo.Create());
        end else
            CheckPhysInventory(ItemJournalLine);

        CheckOutputFields(ItemJournalLine);

        ShouldCheckApplication := ItemJournalLine."Applies-from Entry" <> 0;
        OnRunCheckOnAfterCalcShouldCheckApplication(ItemJournalLine, ShouldCheckApplication);
        if ShouldCheckApplication then begin
            ItemLedgEntry.Get(ItemJournalLine."Applies-from Entry");
            ItemLedgEntry.TestField("Item No.", ItemJournalLine."Item No.", ErrorInfo.Create());
            ItemLedgEntry.TestField("Variant Code", ItemJournalLine."Variant Code", ErrorInfo.Create());
            ItemLedgEntry.TestField(Positive, false, ErrorInfo.Create());
            if ItemJournalLine."Applies-to Entry" = ItemJournalLine."Applies-from Entry" then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text011,
                            ItemJournalLine.FieldCaption("Applies-to Entry"),
                            ItemJournalLine.FieldCaption("Applies-from Entry")),
                        true));
        end;

        if (ItemJournalLine."Entry Type" in [ItemJournalLine."Entry Type"::Consumption, ItemJournalLine."Entry Type"::Output]) and
           not (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::Revaluation) and
           not ItemJournalLine.OnlyStopTime()
        then begin
            ItemJournalLine.TestField("Source No.", ErrorInfo.Create());
            ItemJournalLine.TestField("Order Type", ItemJournalLine."Order Type"::Production, ErrorInfo.Create());
            ShouldCheckItemNo := not CalledFromAdjustment and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Output);
            OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine, ProdOrderLine, CalledFromAdjustment, ShouldCheckItemNo);
            if ShouldCheckItemNo then
                if CheckFindProdOrderLine(ProdOrderLine, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.") then begin
                    ItemJournalLine.TestField("Item No.", ProdOrderLine."Item No.", ErrorInfo.Create());
                    OnAfterCheckFindProdOrderLine(ItemJournalLine, ProdOrderLine);
                end;

            if ItemJournalLine.Subcontracting then begin
                IsHandled := false;
                OnBeforeCheckSubcontracting(ItemJournalLine, IsHandled);
                if not IsHandled then begin
                    WorkCenter.Get(ItemJournalLine."Work Center No.");
                    WorkCenter.TestField("Subcontractor No.", ErrorInfo.Create());
                end;
            end;
            if not CalledFromInvtPutawayPick then
                CheckWarehouse(ItemJournalLine);
        end;

        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Assembly Consumption" then
            CheckWarehouse(ItemJournalLine);

        IsHandled := false;
        OnRunCheckOnBeforeTestFieldAppliesToEntry(ItemJournalLine, IsHandled);
        if not isHandled then
            if (ItemJournalLine."Value Entry Type" <> ItemJournalLine."Value Entry Type"::"Direct Cost") or (ItemJournalLine."Item Charge No." <> '') then
                if ItemJournalLine."Inventory Value Per" = ItemJournalLine."Inventory Value Per"::" " then
                    ItemJournalLine.TestField("Applies-to Entry", ErrorInfo.Create());

        CheckDimensions(ItemJournalLine);

        if (ItemJournalLine."Entry Type" in
            [ItemJournalLine."Entry Type"::Purchase, ItemJournalLine."Entry Type"::Sale, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Negative Adjmt."]) and
           (not GenJnlPostPreview.IsActive())
        then
            ItemJournalLine.CheckItemJournalLineRestriction();

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

        if (ItemJnlLine."Quantity (Base)" = 0) and (ItemJnlLine."Invoiced Qty. (Base)" = 0) and
           ((ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and
           (ItemJnlLine."Output Quantity (Base)" = 0) and (ItemJnlLine."Scrap Quantity (Base)" = 0) and
           (not ItemJnlLine."WIP Item") and ItemJnlLine.TimeIsEmpty())
        then
            Error(ErrorInfo.Create(Text007, true));
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and
           (ItemJnlLine."WIP Quantity" <> 0) and
           (not ItemJnlLine."WIP Item") and
           ItemJnlLine.TimeIsEmpty()
        then
            Error(ErrorInfo.Create(Text1130000, true));
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
        ProdOrderLine.SetFilter(Status, '>=%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Line No.", LineNo);
        exit(ProdOrderLine.FindFirst());
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

        case ItemJnlLine."Entry Type" of // Need to check if the item and location require warehouse handling
            ItemJnlLine."Entry Type"::Output:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) and CheckWarehouseLastOutputOperation(ItemJnlLine) then begin
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
                         Database::"Prod. Order Line", 3, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.", 0, ItemJnlLine.Quantity)
                    then
                        ShowError := true;
                end;
            ItemJnlLine."Entry Type"::Consumption:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Prod. Order Component",
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
                         Database::"Assembly Line",
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

    local procedure WhseOrderHandlingRequired(ItemJnlLine: Record "Item Journal Line"; LocationToCheck: Record Location): Boolean
    var
        InvtPutAwayLocation: Boolean;
        InvtPickLocation: Boolean;
        WarehousePickLocation: Boolean;
    begin
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Output:
                begin
                    InvtPutAwayLocation := LocationToCheck."Prod. Output Whse. Handling" = Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
                    if WarehousePickLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);
                end;
            ItemJnlLine."Entry Type"::Consumption:
                begin
                    InvtPutAwayLocation := LocationToCheck."Prod. Output Whse. Handling" = Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
                    if WarehousePickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);
                end;
            ItemJnlLine."Entry Type"::"Assembly Consumption":
                begin
                    InvtPutAwayLocation := not LocationToCheck."Require Receive" and LocationToCheck."Require Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
                    if WarehousePickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);
                end;
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

        if (ItemJnlLine."Item Charge No." <> '') or (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::"Direct Cost") or (ItemJnlLine.Quantity = 0) then
            exit;

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            GetLocation(ItemJnlLine."New Location Code");
            CheckNewBinCode(ItemJnlLine);
        end else begin
            GetLocation(ItemJnlLine."Location Code");
            if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
                exit;
        end;

        if ItemJnlLine."Drop Shipment" or ItemJnlLine.OnlyStopTime() or (ItemJnlLine."Quantity (Base)" = 0) or ItemJnlLine.Adjustment or CalledFromAdjustment then
            exit;

        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and not ItemJnlLine.LastOutputOperation(ItemJnlLine) then
            exit;

        IsHandled := false;
        OnCheckBinsOnBeforeCheckNonZeroQuantity(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if not IsHandled then
            if ItemJnlLine.Quantity <> 0 then
                case ItemJnlLine."Entry Type" of
                    ItemJnlLine."Entry Type"::Purchase,
                  ItemJnlLine."Entry Type"::"Positive Adjmt.",
                  ItemJnlLine."Entry Type"::Output,
                  ItemJnlLine."Entry Type"::"Assembly Output":
                        WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity > 0);
                    ItemJnlLine."Entry Type"::Sale,
                  ItemJnlLine."Entry Type"::"Negative Adjmt.",
                  ItemJnlLine."Entry Type"::Consumption,
                  ItemJnlLine."Entry Type"::"Assembly Consumption":
                        WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity < 0);
                    ItemJnlLine."Entry Type"::Transfer:
                        begin
                            GetLocation(ItemJnlLine."Location Code");
                            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                                WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity < 0);
                            if (ItemJnlLine."New Location Code" <> '') and (ItemJnlLine."New Bin Code" <> '') then
                                WMSManagement.CheckInbOutbBin(ItemJnlLine."New Location Code", ItemJnlLine."New Bin Code", ItemJnlLine.Quantity > 0);
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
        ItemJnlLine.TestField("Posting Date", ErrorInfo.Create());
        if ItemJnlLine."Posting Date" <> NormalDate(ItemJnlLine."Posting Date") then
            ItemJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text000, true));

        OnBeforeDateNotAllowed(ItemJnlLine, DateCheckDone);
        if not DateCheckDone then
            UserSetupManagement.CheckAllowedPostingDate(ItemJnlLine."Posting Date");

        ShouldShowError := not InvtPeriod.IsValidDate(ItemJnlLine."Posting Date");
        OnCheckDatesOnAfterCalcShouldShowError(ItemJnlLine, ShouldShowError, CalledFromAdjustment);
        if ShouldShowError then
            InvtPeriod.ShowError(ItemJnlLine."Posting Date");

        if ItemJnlLine."Document Date" <> 0D then
            if ItemJnlLine."Document Date" <> NormalDate(ItemJnlLine."Document Date") then
                ItemJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));
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

        if not ItemJnlLine.IsValueEntryForDeletedItem() and not ItemJnlLine.Correction and not CalledFromAdjustment then begin
            if not DimMgt.CheckDimIDComb(ItemJnlLine."Dimension Set ID") then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            DimCombBlockedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimCombErr()),
                        true));
            if ItemJnlLine."Item Charge No." = '' then begin
                TableID[1] := Database::Item;
                No[1] := ItemJnlLine."Item No.";
            end else begin
                TableID[1] := Database::"Item Charge";
                No[1] := ItemJnlLine."Item Charge No.";
            end;
            TableID[2] := Database::"Salesperson/Purchaser";
            No[2] := ItemJnlLine."Salespers./Purch. Code";
            TableID[3] := Database::"Work Center";
            No[3] := ItemJnlLine."Work Center No.";

            if ItemJnlLine."New Dimension Set ID" <> 0 then begin
                TableID[4] := Database::Location;
                No[4] := ItemJnlLine."Location Code";
                CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
                TableID[4] := Database::Location;
                No[4] := ItemJnlLine."New Location Code";
                CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."New Dimension Set ID");
            end else begin
                TableID[4] := Database::Location;
                No[4] := ItemJnlLine."Location Code";
                TableID[5] := Database::Location;
                No[5] := ItemJnlLine."New Location Code";

                if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) then begin
                    CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
                    if (DimMgt.CheckDefaultDimensionHasCodeMandatory(TableID, No)) and
                       (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
                    then
                        CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."New Dimension Set ID");
                end else
                    CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
            end;

            if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
               (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
            then
                if not DimMgt.CheckDimIDComb(ItemJnlLine."Dimension Set ID") then begin
                    if ItemJnlLine."Line No." <> 0 then
                        Error(
                            ErrorInfo.Create(
                                StrSubstNo(DimCausedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr()),
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

        if not
           (ItemJnlLine."Entry Type" in
            [ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::"Negative Adjmt."])
        then begin
            ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Positive Adjmt.";
            ItemJnlLine3."Entry Type" := ItemJnlLine3."Entry Type"::"Negative Adjmt.";
            ItemJnlLine.FieldError(
                "Entry Type",
                ErrorInfo.Create(
                    StrSubstNo(
                        Text005, ItemJnlLine2."Entry Type", ItemJnlLine3."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
        end;
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt.") and
           (ItemJnlLine."Qty. (Phys. Inventory)" - ItemJnlLine."Qty. (Calculated)" <> ItemJnlLine.Quantity)
        then
            ItemJnlLine.FieldError(
                Quantity,
                 ErrorInfo.Create(
                    StrSubstNo(
                        Text006, ItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"), ItemJnlLine.FieldCaption("Qty. (Calculated)"),
                        ItemJnlLine.FieldCaption("Entry Type"), ItemJnlLine."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt.") and
           (ItemJnlLine."Qty. (Calculated)" - ItemJnlLine."Qty. (Phys. Inventory)" <> ItemJnlLine.Quantity)
        then
            ItemJnlLine.FieldError(
                Quantity,
                ErrorInfo.Create(
                    StrSubstNo(
                        Text006, ItemJnlLine.FieldCaption("Qty. (Calculated)"), ItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"),
                        ItemJnlLine.FieldCaption("Entry Type"), ItemJnlLine."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
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

        if ((ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Transfer) or (ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Transfer)) and
               not ItemJnlLine.Adjustment
        then begin
            CheckInTransitLocation(ItemJnlLine."Location Code");
            CheckInTransitLocation(ItemJnlLine."New Location Code");
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

    local procedure CheckDimensionsAfterAssignDimTableIDs(
        ItemJnlLine: Record "Item Journal Line";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimSetID: Integer)
    begin
        OnCheckDimensionsOnAfterAssignDimTableIDs(ItemJnlLine, TableID, No);
        if not DimMgt.CheckDimValuePosting(TableID, No, DimSetID) then begin
            if ItemJnlLine."Line No." <> 0 then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(DimCausedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr()),
                    true));
            Error(ErrorInfo.Create(StrSubstNo(DimMgt.GetDimValuePostingErr()), true));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPickLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignWhsePickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var WhsePickLocation: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeTestFieldAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

