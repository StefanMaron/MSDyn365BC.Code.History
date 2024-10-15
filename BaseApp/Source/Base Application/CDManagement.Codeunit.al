codeunit 12407 "CD Management"
{

    var
        InventoryNotAvailableErr: Label '%1 %2 is not available in inventory, it has already been reserved for another document, or the quantity available is lower than the quantity to handle specified on the line.', Comment = '%1 = CD No. Caption; %2 = CD No. Value';

    // Tracking Specification subscribers

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterClearTracking', '', false, false)]
    local procedure TrackingSpecificationClearTracking(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure TrackingSpecificationClearTrackingFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingBlank', '', false, false)]
    local procedure TrackingSpecificationSetTrackingBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."CD No." := FromTrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyNewTrackingFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationCopyNewTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."New CD No." := FromTrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
        TrackingSpecification."CD No." := EntrySummary."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TrackingSpecification."CD No." := ItemLedgerEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure TrackingSpecificationOnAfterCopyTrackingFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        TrackingSpecification."CD No." := ItemTrackingSetup."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservEntry: Record "Reservation Entry")
    begin
        TrackingSpecification."CD No." := ReservEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        TrackingSpecification."CD No." := WhseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromWhseItemTrackingLine(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        TrackingSpecification."CD No." := WhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterBlank', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromEntrySummary', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
        TrackingSpecification.SetRange("CD No.", EntrySummary."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemJnlLine', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
        TrackingSpecification.SetRange("CD No.", ItemJournalLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TrackingSpecification.SetRange("CD No.", ItemLedgerEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        TrackingSpecification.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.SetRange("CD No.", ReservationEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetNewTrackingFilterFromNewReservEntry', '', false, false)]
    local procedure TrackingSpecificationSetNewTrackingFilterFromNewReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.SetRange("New CD No.", ReservationEntry."New CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("CD No.", FromTrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        TrackingSpecification.SetRange("CD No.", WhseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterTestTrackingFieldsAreBlank', '', false, false)]
    local procedure TrackingSpecificationTestTrackingFieldsAreBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.TestField("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterTrackingExist', '', false, false)]
    local procedure TrackingSpecificationTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (TrackingSpecification."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterHasSameTracking', '', false, false)]
    local procedure TrackingSpecificationHasSameTracking(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (TrackingSpecification."CD No." = FromTrackingSpecification."CD No.");
    end;

    // Reservation Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameTracking', '', false, false)]
    local procedure ReservationEntryHasSameTracking(ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."CD No." = FromReservationEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure ReservationEntryHasSameNewTracking(ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."New CD No." = FromReservationEntry."New CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameTrackingWithSpec', '', false, false)]
    local procedure ReservationEntryHasSamesTrackingWithSpec(ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."CD No." = TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearTracking', '', false, false)]
    local procedure ReservationEntryClearTracking(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearNewTracking', '', false, false)]
    local procedure ReservationEntryClearNewTracking(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."New CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure ReservationEntryClearTrackingFilter(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ReservationEntry."CD No." := ItemLedgerEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromItemTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ReservationEntry."CD No." := ItemTrackingSetup."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromInvtProfile', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromInvtProfile(var ReservationEntry: Record "Reservation Entry"; InventoryProfile: Record "Inventory Profile")
    begin
        ReservationEntry."CD No." := InventoryProfile."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."CD No." := FromReservationEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromReservEntryNewTracking', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromReservEntryNewTracking(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."CD No." := FromReservationEntry."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry."CD No." := TrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseActivLine', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseActivLine(var ReservationEntry: Record "Reservation Entry"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        ReservationEntry."CD No." := WarehouseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseEntry(var ReservationEntry: Record "Reservation Entry"; WhseEntry: Record "Warehouse Entry")
    begin
        ReservationEntry."CD No." := WhseEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseItemTrackingLine(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry."CD No." := WhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetNewTrackingFromItemJnlLine', '', false, false)]
    local procedure ReservationEntryCopyNewTrackingFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEntry."New CD No." := ItemJournalLine."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetNewTrackingFromTrackingSpecification', '', false, false)]
    local procedure ReservationEntrySetNewTrackingFromTrackingSpecification(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry."New CD No." := TrackingSpecification."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyNewTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ReservationEntryCopyNewTrackingFromWhseItemTrackingLine(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry."New CD No." := WhseItemTrackingLine."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFiltersToReservEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFiltersToReservEntry(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.CopyFilter("CD No.", FilterReservEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterFilterLinesForTracking', '', false, false)]
    local procedure ReservationEntryFilterLinesForTracking(var ReservEntry: Record "Reservation Entry"; CalcReservEntry: Record "Reservation Entry"; Positive: Boolean)
    var
        FieldFilter: Text;
    begin
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"CD No.") then
            ReservEntry.SetFilter("CD No.", FieldFilter);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterBlank(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemJnlLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEntry.SetRange("CD No.", ItemJournalLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ReservationEntry.SetRange("CD No.", ItemLedgEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ReservationEntry.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSetupIfNotBlank(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."CD No." <> '' then
            ReservationEntry.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("CD No.", FromReservationEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromTrackingSpec', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry.SetRange("CD No.", TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromSpecIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromSpecIfNotBlank(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecification."CD No." <> '' then
            ReservationEntry.SetRange("CD No.", TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseActivityLine(var ReservationEntry: Record "Reservation Entry"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        ReservationEntry.SetRange("CD No.", WhseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseJnlLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseJnlLine(var ReservationEntry: Record "Reservation Entry"; WhseJournalLine: Record "Warehouse Journal Line")
    begin
        ReservationEntry.SetRange("CD No.", WhseJournalLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseSpec', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseSpec(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry.SetRange("CD No.", WhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseActivityLineIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseActivityLineIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            ReservationEntry.SetRange("CD No.", WhseActivityLine."CD No.")
        else
            ReservationEntry.SetFilter("CD No.", '%1|%2', WhseActivityLine."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupNotBlankIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseItemTrackingSetupNotBlankIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            ReservationEntry.SetFilter("CD No.", '<>%1', '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseItemTrackingSetupIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                ReservationEntry.SetRange("CD No.", WhseItemTrackingSetup."CD No.")
            else
                ReservationEntry.SetFilter("CD No.", '%1|%2', WhseItemTrackingSetup."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterToItemIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterToItemIfRequired(ReservationEntry: Record "Reservation Entry"; var Item: Record Item)
    begin
        if ReservationEntry."CD No." <> '' then
            Item.SetRange("CD No. Filter", ReservationEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterGetItemTrackingEntryType', '', false, false)]
    local procedure ReservationEntryGetItemTrackingEntryType(ReservationEntry: Record "Reservation Entry"; var TrackingEntryType: Enum "Item Tracking Entry Type")
    begin
        if ReservationEntry."CD No." = '' then
            exit;

        case true of
            (ReservationEntry."Lot No." = '') and (ReservationEntry."Serial No." = ''):
                TrackingEntryType := "Item Tracking Entry Type"::"CD No.";
            (ReservationEntry."Lot No." <> '') and (ReservationEntry."Serial No." = ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Lot and CD No.";
            (ReservationEntry."Lot No." = '') and (ReservationEntry."Serial No." <> ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Serial and CD No.";
            (ReservationEntry."Lot No." <> '') and (ReservationEntry."Serial No." <> ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Lot and Serial and CD No.";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure ReservationEntryTrackingExists(ReservationEntry: Record "Reservation Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ReservationEntry."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterNewTrackingExists', '', false, false)]
    local procedure ReservationEntryNewTrackingExists(ReservationEntry: Record "Reservation Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ReservationEntry."New CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterGetTrackingText', '', false, false)]
    local procedure ReservationEntryGetTrackingText(ReservationEntry: Record "Reservation Entry"; var TrackingText: Text)
    begin
        TrackingText := TrackingText + ' ' + ReservationEntry."CD No.";
    end;

    // Item Ledger Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemLedgerEntryTrackingExists(ItemLedgerEntry: Record "Item Ledger Entry"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (ItemLedgerEntry."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemLedgerEntryCopyTrackingFromItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry."CD No." := ItemJnlLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterCopyTrackingFromNewItemJnlLine', '', false, false)]
    local procedure ItemLedgerEntryCopyTrackingFromNewItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry."CD No." := ItemJnlLine."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; FromItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("CD No.", FromItemLedgerEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemJournalLine', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemJournalLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry.SetRange("CD No.", ItemJournalLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemTrackingSetup(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ItemLedgerEntry.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemTrackingSetupIfNotBlank(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."CD No." <> '' then
            ItemLedgerEntry.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromSpec(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemLedgerEntry.SetRange("CD No.", TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure ItemLedgerEntryClearTrackingFilter(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterTestTrackingEqualToTrackingSpec', '', false, false)]
    local procedure ItemLedgerEntryTestTrackingEqualToTrackingSpec(ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemLedgerEntry.TestField("CD No.", TrackingSpecification."CD No.");
    end;

    // Job Ledger Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Ledger Entry", 'OnAfterCopyTrackingFromJobJnlLine', '', false, false)]
    local procedure JobLedgerEntryCopyTrackingFromJobJnlLine(var JobLedgerEntry: Record "Job Ledger Entry"; JobJnlLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."CD No." := JobJnlLine."CD No.";
    end;

    // Job Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure JobJournalLineCopyTrackingFromItemLedgEntry(var JobJournalLine: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        JobJournalLine."CD No." := ItemLedgEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterCopyTrackingFromJobPlanningLine', '', false, false)]
    local procedure JobJournalLineCopyTrackingFromJobPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine."CD No." := JobPlanningLine."CD No.";
    end;

    // Job Planning Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterCopyTrackingFromJobJnlLine', '', false, false)]
    local procedure JobPlanningLineCopyTrackingFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJnlLine: Record "Job Journal Line")
    begin
        JobPlanningLine."CD No." := JobJnlLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterCopyTrackingFromJobLedgEntry', '', false, false)]
    local procedure JobPlanningLineCopyTrackingFromJobLedgEntry(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
        JobPlanningLine."CD No." := JobLedgEntry."CD No.";
    end;

    // Entry Summary subscribers

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterHasSameTracking', '', false, false)]
    local procedure EntrySummaryHasSameTracking(ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary"; var SameTracking: Boolean)
    begin
        SameTracking := SameTracking and (ToEntrySummary."CD No." = FromEntrySummary."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ToEntrySummary."CD No." := ItemTrackingSetup."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
        ToEntrySummary."CD No." := FromReservEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromSpec(var ToEntrySummary: Record "Entry Summary"; TrackingSpecification: Record "Tracking Specification")
    begin
        ToEntrySummary."CD No." := TrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromEntrySummary', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromEntrySummary(var ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary")
    begin
        ToEntrySummary.SetRange("CD No.", FromEntrySummary."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ToEntrySummary.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
        ToEntrySummary.SetRange("CD No.", FromReservEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromSpec(var ToEntrySummary: Record "Entry Summary"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        ToEntrySummary.SetRange("CD No.", FromTrackingSpecification."CD No.");
    end;

    // Item Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterClearTracking', '', false, false)]
    local procedure ItemJournalLineClearTracking(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemJournalLineCopyTrackingFromItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine."CD No." := ItemLedgEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure ItemJournalLineCopyTrackingFromSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine."CD No." := TrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyNewTrackingFromNewSpec', '', false, false)]
    local procedure ItemJournalLineCopyNewTrackingFromNewSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine."New CD No." := TrackingSpecification."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemJournalLineTrackingExists(var ItemJournalLine: Record "Item Journal Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (ItemJournalLine."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure ItemJournalLineHasSameNewTracking(ItemJournalLine: Record "Item Journal Line"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ItemJournalLine."CD No." = ItemJournalLine."New CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingIsEmpty', '', false, false)]
    local procedure ItemJournalLineCheckTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.TestField("CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckNewTrackingIsEmpty', '', false, false)]
    local procedure ItemJournalLineCheckNewTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.TestField("New CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingEqualItemLedgEntry', '', false, false)]
    local procedure ItemJournalLineCheckTrackingEqualItemLedgEntry(ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine.TestField("CD No.", ItemLedgerEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingEqualTrackingSpecification', '', false, false)]
    local procedure ItemJournalLineCheckTrackingEqualTrackingSpecification(ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine.TestField("CD No.", TrackingSpecification."CD No.");
    end;

    // Item Entry Relation

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromItemLedgEntry(var ItemEntryRelation: Record "Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemEntryRelation."CD No." := ItemLedgerEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromItemJnlLine(var ItemEntryRelation: Record "Item Entry Relation"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemEntryRelation."CD No." := ItemJnlLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemEntryRelation."CD No." := TrackingSpecification."CD No.";
    end;

    // Item Tracking Setup subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromEntrySummary(var ItemTrackingSetup: Record "Item Tracking Setup"; EntrySummary: Record "Entry Summary")
    begin
        ItemTrackingSetup."CD No." := EntrySummary."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromBinContentBuffer', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromBinContentBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
        ItemTrackingSetup."CD No." := BinContentBuffer."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemLedgerEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemLedgerEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemTrackingSetup."CD No." := ItemLedgerEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemJnlLine(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemTrackingSetup."CD No." := ItemJnlLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemTrackingSetup(var ItemTrackingSetup: Record "Item Tracking Setup"; FromItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ItemTrackingSetup."CD No." := FromItemTrackingSetup."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromReservEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
    begin
        ItemTrackingSetup."CD No." := ReservEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemTrackingSetup."CD No." := TrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseActivityLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        ItemTrackingSetup."CD No." := WhseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseEntry: Record "Warehouse Entry")
    begin
        ItemTrackingSetup."CD No." := WhseEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseItemTrackingLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ItemTrackingSetup."CD No." := WhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterSetTrackingFilterForItem', '', false, false)]
    local procedure ItemTrackingSetupSetTrackingFilterForItem(ItemTrackingSetup: Record "Item Tracking Setup"; var Item: Record Item)
    begin
        if ItemTrackingSetup."CD No." <> '' then
            Item.SetRange("CD No. Filter", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemTrackingSetupTrackingExists(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ItemTrackingSetup."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterTrackingRequired', '', false, false)]
    local procedure ItemTrackingSetupTrackingRequired(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingRequired: Boolean)
    begin
        IsTrackingRequired := IsTrackingRequired or ItemTrackingSetup."CD No. Required";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCheckTrackingMismatch', '', false, false)]
    local procedure ItemTrackingSetupCheckTrackingMismatch(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; TrackingSpecification: Record "Tracking Specification")
    begin
        if ItemTrackingSetup."CD No." <> '' then
            ItemTrackingSetup."CD No. Mismatch" :=
                ItemTrackingCode."CD Specific Tracking" and (TrackingSpecification."CD No." <> ItemTrackingSetup."CD No.");
    end;

    // Warehouse Activity Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure WhseActivityLineTrackingExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (WarehouseActivityLine."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTrackingFilterExists', '', false, false)]
    local procedure WhseActivityLineTrackingFilterExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingFilterExist: Boolean)
    begin
        IsTrackingFilterExist := IsTrackingFilterExist or (WarehouseActivityLine.GetFilter("CD No.") <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterClearTracking', '', false, false)]
    local procedure WhseActivityLineClearTracking(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine."CD No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WhseActivityLineClearTrackingFilter(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        WarehouseActivityLine."CD No." := TrackingSpecification."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        WarehouseActivityLine."CD No." := WhseItemTrackingSetup."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromPostedWhseRcptLine', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromPostedWhseRcptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        WarehouseActivityLine."CD No." := PostedWhseRcptLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromWhseItemTrackingLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WarehouseActivityLine."CD No." := WhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterIfNotEmpty', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterIfNotEmpty(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if WarehouseActivityLine."CD No." <> '' then
            WarehouseActivityLine.SetRange("CD No.", WarehouseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
        WarehouseActivityLine.SetFilter("CD No.", BinContent.GetFilter("CD No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromBinContentBuffer', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromBinContentBuffer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContentBuffer: Record "Bin Content Buffer")
    begin
        WarehouseActivityLine.SetRange("CD No.", BinContentBuffer."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        WarehouseActivityLine.SetRange("CD No.", ItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromReservEntry(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
        WarehouseActivityLine.SetRange("CD No.", ReservEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromReservEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromReservEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."CD No." <> '' then
            WarehouseActivityLine.SetRange("CD No.", ReservEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        if WhseItemTrackingLine."CD No." <> '' then
            WarehouseActivityLine.SetRange("CD No.", WhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("CD No.", FromWarehouseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            WarehouseActivityLine.SetRange("CD No.", WhseItemTrackingSetup."CD No.")
        else
            WarehouseActivityLine.SetFilter("CD No.", '%1|%2', WhseItemTrackingSetup."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                WarehouseActivityLine.SetRange("CD No.", WhseItemTrackingSetup."CD No.")
            else
                WarehouseActivityLine.SetFilter("CD No.", '%1|%2', WhseItemTrackingSetup."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToItemIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToItemIfRequired(var Item: Record Item; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."CD No." <> '' then begin
            if WhseItemTrackingSetup."CD No. Required" then
                Item.SetRange("CD No. Filter", WarehouseActivityLine."CD No.")
            else
                Item.SetFilter("CD No. Filter", '%1|%2', WarehouseActivityLine."CD No.", '')
        end else
            Item.SetRange("CD No. Filter");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToItemLedgEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToItemLedgEntryIfRequired(var ItemLedgerEntry: Record "Item Ledger Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                ItemLedgerEntry.SetRange("CD No.", WarehouseActivityLine."CD No.")
            else
                ItemLedgerEntry.SetFilter("CD No.", '%1|%2', WarehouseActivityLine."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToWhseEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToWhseEntryIfRequired(var WhseEntry: Record "Warehouse Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                WhseEntry.SetRange("CD No.", WarehouseActivityLine."CD No.")
            else
                WhseEntry.SetFilter("CD No.", '%1|%2', WarehouseActivityLine."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTestTrackingIfRequired', '', false, false)]
    local procedure WhseActivityLineTestTrackingIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            WarehouseActivityLine.TestField("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterLookupTrackingSummary', '', false, false)]
    local procedure WhseActivityLineLookupTrackingSummary(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
        if TrackingType <> TrackingType::"CD No." then
            exit;

        if TempTrackingSpecification."CD No." <> '' then begin
            WarehouseActivityLine.Validate("CD No.", TempTrackingSpecification."CD No.");
            WarehouseActivityLine.Modify();
        end;
    end;

    // Bin Content

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterClearTrackingFilters', '', false, false)]
    local procedure BinContentClearTrackingFilters(var BinContent: Record "Bin Content")
    begin
        BinContent.SetRange("CD No. Filter");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromTrackingSpecification', '', false, false)]
    local procedure BinContentSetTrackingFilterFromTrackingSpecification(var BinContent: Record "Bin Content"; TrackingSpecification: Record "Tracking Specification")
    begin
        BinContent.SetRange("CD No. Filter", TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhsEntryIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseEntryIfNotBlank(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
        if WarehouseEntry."CD No." <> '' then
            BinContent.SetRange("CD No. Filter", WarehouseEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseActivityLineIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseActivityLineIfNotBlank(var BinContent: Record "Bin Content"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        if WhseActivityLine."CD No." <> '' then
            BinContent.SetRange("CD No. Filter", WhseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseItemTrackingLine', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseItemTrackingLine(var BinContent: Record "Bin Content"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        BinContent.SetRange("CD No. Filter", WhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetup', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseItemTrackingSetup(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        BinContent.SetRange("CD No. Filter", WhseItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            BinContent.SetRange("CD No. Filter", WhseItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupifNotBlankIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                BinContent.SetRange("CD No. Filter", WhseItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            BinContent.SetRange("CD No. Filter", WhseItemTrackingSetup."CD No.")
        else
            BinContent.SetFilter("CD No. Filter", '%1|%2', WhseItemTrackingSetup."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromBinContentBufferIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromBinContentBufferIfRequired(var BinContent: Record "Bin Content"; BinContentBuffer: Record "Bin Content Buffer"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            BinContent.SetRange("CD No. Filter", BinContentBuffer."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterTrackingFiltersExist', '', false, false)]
    local procedure BinContentTrackingFiltersExist(var BinContent: Record "Bin Content"; var IsTrackingFiltersExist: Boolean)
    begin
        IsTrackingFiltersExist := IsTrackingFiltersExist or (BinContent.GetFilter("CD No. Filter") <> '');
    end;

    // Bin Content Buffer

    [EventSubscriber(ObjectType::Table, Database::"Bin Content Buffer", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure BinContentBufferCopyTrackingFromWhseActivityLine(var BinContentBuffer: Record "Bin Content Buffer"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        BinContentBuffer."CD No." := WhseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content Buffer", 'OnAfterCopyTrackingFromWhseItemTrackingSetup', '', false, false)]
    local procedure BinContentBufferCopyTrackingFromWhseItemTrackingSetup(var BinContentBuffer: Record "Bin Content Buffer"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        BinContentBuffer."CD No." := WhseItemTrackingSetup."CD No.";
    end;

    // Warehouse Entry

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WarehouseEntryClearTrackingFilter(var WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseEntry.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; FromWarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseEntry."CD No." := FromWarehouseEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromWhseJnlLine', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseEntry."CD No." := WarehouseJournalLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromNewWhseJnlLine', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromNewWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if WarehouseJournalLine."New CD No." <> '' then
            WarehouseEntry."CD No." := WarehouseJournalLine."New CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterIfNotBlank(var WhseEntry: Record "Warehouse Entry")
    begin
        if WhseEntry."CD No." <> '' then
            WhseEntry.SetRange("CD No.", WhseEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromBinContent(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
        WarehouseEntry.SetFilter("CD No.", BinContent.GetFilter("CD No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromBinContentBuffer', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromBinContentBuffer(var WarehouseEntry: Record "Warehouse Entry"; BinContentBuffer: Record "Bin Content Buffer")
    begin
        WarehouseEntry.SetRange("CD No.", BinContentBuffer."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            WarehouseEntry.SetRange("CD No.", WhseItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No." <> '' then
            if WhseItemTrackingSetup."CD No. Required" then
                WarehouseEntry.SetRange("CD No.", WhseItemTrackingSetup."CD No.")
            else
                WarehouseEntry.SetFilter("CD No.", '%1|%2', WhseItemTrackingSetup."CD No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromWhseEntry', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromWhseEntry(var WhseEntry: Record "Warehouse Entry"; FromWhseEntry: Record "Warehouse Entry")
    begin
        WhseEntry.SetRange("CD No.", FromWhseEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromReservEntryIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromReservEntryIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."CD No." <> '' then
            WarehouseEntry.SetRange("CD No.", ReservEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No." <> '' then
            WarehouseEntry.SetRange("CD No.", WhseItemTrackingSetup."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure WarehouseEntryTrackingExists(WhseEntry: Record "Warehouse Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (WhseEntry."CD No." <> '');
    end;

    // Warehouse Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCheckTrackingIfRequired', '', false, false)]
    local procedure WarehouseJournalLineEntryCheckTrackingIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            WhseJnlLine.TestField("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromItemLedgEntry(var WhseJnlLine: Record "Warehouse Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        WhseJnlLine."CD No." := ItemLedgEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromWhseActivityLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseJournalLine."CD No." := WarehouseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromWhseEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseJournalLine."CD No." := WarehouseEntry."CD No.";
    end;

    // Whse. Item Entry Relation

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Entry Relation", 'OnAfterInitFromTrackingSpec', '', false, false)]
    local procedure WhseItemEntryRelationInitFromTrackingSpec(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
        WhseItemEntryRelation."CD No." := TrackingSpecification."CD No.";
    end;

    // Whse. Item Tracking Line

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCheckTrackingIfRequired', '', false, false)]
    local procedure WhseItemTrackingLineInitFromTrackingSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."CD No. Required" then
            WhseItemTrackingLine.TestField("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WhseItemTrackingLineClearTrackingFilter(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromEntrySummary(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntrySummary: Record "Entry Summary")
    begin
        WhseItemTrackingLine."CD No." := EntrySummary."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromItemLedgEntry(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        WhseItemTrackingLine."CD No." := ItemLedgerEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromPostedWhseReceiptine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromPostedWhseReceiptLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        WhseItemTrackingLine."CD No." := PostedWhseReceiptLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromReservEntry(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
        WhseItemTrackingLine."CD No." := ReservationEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromPostedWhseRcptLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromPostedWhseRcptLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        WhseItemTrackingLine."CD No." := PostedWhseRcptLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromWhseActivityLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseItemTrackingLine."CD No." := WhseActivityLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine."CD No." := FromWhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromRelation', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromRelation(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        WhseItemTrackingLine."CD No." := WhseItemEntryRelation."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromBinContent(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var BinContent: Record "Bin Content")
    begin
        WhseItemTrackingLine.SetFilter("CD No.", BinContent.GetFilter("CD No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromRelation(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        WhseItemTrackingLine.SetRange("CD No.", WhseItemEntryRelation."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromReservEntry(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
        WhseItemTrackingLine.SetRange("CD No.", ReservationEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("CD No.", FromWhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromWhseActivityLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseItemTrackingLine.SetRange("CD No.", WhseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("CD No.", FromWhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure WhseItemTrackingLineHasSameNewTracking(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (WhseItemTrackingLine."New CD No." = WhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterHasSameTrackingWithItemEntryRelation', '', false, false)]
    local procedure WhseItemTrackingLineHasSameTrackingWithItemEntryRelation(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        IsSameTracking := IsSameTracking and (WhseItemEntryRelation."CD No." = WhseItemTrackingLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure WhseItemTrackingLineTrackingExists(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (WhseItemTrackingLine."CD No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterLookupTrackingSummary', '', false, false)]
    local procedure WhseItemTrackingLineLookupTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
        if TrackingType = TrackingType::"CD No." then
            if TempTrackingSpecification."CD No." <> '' then
                WhseItemTrackingLine.Validate("CD No.", TempTrackingSpecification."CD No.");
    end;

    // Item Tracing Buffer

    [EventSubscriber(ObjectType::Table, Database::"Item Tracing Buffer", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemTracingBufferCopyTrackingFromItemLedgEntry(var ItemTracingBuffer: Record "Item Tracing Buffer"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemTracingBuffer."CD No." := ItemLedgEntry."CD No.";
    end;

    // Inventory Profile

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromItemLedgEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        InventoryProfile."CD No." := ItemLedgEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromInvtProfile', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
        InventoryProfile."CD No." := FromInventoryProfile."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromReservEntry(var InventoryProfile: Record "Inventory Profile"; ReservEntry: Record "Reservation Entry")
    begin
        InventoryProfile."CD No." := ReservEntry."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterSetTrackingFilter', '', false, false)]
    local procedure InventoryProfileSetTrackingFilter(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
        if FromInventoryProfile."CD No." <> '' then
            InventoryProfile.SetRange("CD No.", FromInventoryProfile."CD No.")
        else
            InventoryProfile.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterTrackingExists', '', false, false)]
    local procedure InventoryProfileTrackingExists(InventoryProfile: Record "Inventory Profile"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (InventoryProfile."CD No." <> '');
    end;

    // Posted Whse. Receipt Line
    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterCopyTrackingFromWhseItemEntryRelation', '', false, false)]
    local procedure PostedWhseReceiptLineCopyTrackingFromWhseItemEntryRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        PostedWhseReceiptLine."CD No." := WhseItemEntryRelation."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure PostedWhseReceiptLineCopyTrackingFromWhseItemTrackingLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        PostedWhseReceiptLine."CD No." := WhseItemTrackingLine."CD No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure PostedWhseReceiptLineSetTrackingFilterFromItemLedgEntry(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        PostedWhseReceiptLine.SetRange("CD No.", ItemLedgEntry."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure PostedWhseReceiptLineSetTrackingFilterFromRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        PostedWhseReceiptLine.SetRange("CD No.", WhseItemEntryRelation."CD No.");
    end;

    // Registered Whse. Activity Line

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure RegisteredWhseActivityLineClearTrackingFilter(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
        RegisteredWhseActivityLine.SetRange("CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromRelation(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        RegisteredWhseActivityLine.SetRange("CD No.", WhseItemEntryRelation."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        RegisteredWhseActivityLine.SetRange("CD No.", TrackingSpecification."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        RegisteredWhseActivityLine.SetRange("CD No.", WarehouseActivityLine."CD No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromWhseSpec', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromWhseSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        RegisteredWhseActivityLine.SetRange("CD No.", WhseItemTrackingLine."CD No.");
    end;

    // ReservEngineMgt codeunit

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnAfterItemTrackingMismatch', '', false, false)]
    local procedure ReservEngineMgtItemTrackingMismatch(ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsMismatch: Boolean)
    begin
        if (ReservationEntry."CD No." <> '') and (ItemTrackingSetup."CD No." <> '') then
            if (ReservationEntry."CD No." <> ItemTrackingSetup."CD No.") then
                IsMismatch := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnCheckReservedItemTrkgOnCkeckTypeElseCase', '', false, false)]
    local procedure CheckReservedItemTrkgOnCkeckTypeElseCase(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        LineReservedQty: Decimal;
        AvailQtyFromOtherResvLines: Decimal;
    begin
        if CheckType <> CheckType::"CD No." then
            exit;

        Item.Get(WarehouseActivityLine."Item No.");
        Item.SetRange("Location Filter", WarehouseActivityLine."Location Code");
        Item.SetRange("Variant Filter", WarehouseActivityLine."Variant Code");
        Item.SetRange("CD No. Filter", ItemTrkgCode);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        WhseItemTrackingSetup."CD No." := CopyStr(ItemTrkgCode, 1, MaxStrLen(WhseItemTrackingSetup."CD No."));
        LineReservedQty :=
            WhseAvailMgt.CalcLineReservedQtyOnInvt(
            WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
            WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", true,
            WhseItemTrackingSetup, TempWhseActivLine);
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", WarehouseActivityLine."Item No.");
        ReservEntry.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        ReservEntry.SetRange("Location Code", WarehouseActivityLine."Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("CD No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, true);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", false);
                if ((ReservEntry2."Source Type" <> WarehouseActivityLine."Source Type") or
                    (ReservEntry2."Source Subtype" <> WarehouseActivityLine."Source Subtype") or
                    (ReservEntry2."Source ID" <> WarehouseActivityLine."Source No.") or
                    (((ReservEntry2."Source Ref. No." <> WarehouseActivityLine."Source Line No.") and
                        (ReservEntry2."Source Type" <> DATABASE::"Prod. Order Component")) or
                        (((ReservEntry2."Source Prod. Order Line" <> WarehouseActivityLine."Source Line No.") or
                        (ReservEntry2."Source Ref. No." <> WarehouseActivityLine."Source Subline No.")) and
                        (ReservEntry2."Source Type" = DATABASE::"Prod. Order Component"))))
                    and (ReservEntry2."CD No." = '') then
                    AvailQtyFromOtherResvLines := AvailQtyFromOtherResvLines + Abs(ReservEntry2."Quantity (Base)");
            until ReservEntry.Next() = 0;

        if (Item.Inventory - Abs(Item."Reserved Qty. on Inventory") +
            LineReservedQty + AvailQtyFromOtherResvLines +
            WhseAvailMgt.CalcReservQtyOnPicksShips(
                WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.",
                WarehouseActivityLine."Variant Code", TempWhseActivLine)) < WarehouseActivityLine."Qty. to Handle (Base)"
        then
            Error(InventoryNotAvailableErr, WarehouseActivityLine.FieldCaption("CD No."), ItemTrkgCode);
    end;
}