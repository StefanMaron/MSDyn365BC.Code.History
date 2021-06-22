table 6565 "Item Tracking Setup"
{
    Caption = 'Item Tracking Code';
    DataCaptionFields = "Code";
    #pragma warning disable AS0034
    TableType = Temporary;
    #pragma warning restore AS0034

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; "Serial No. Required"; Boolean)
        {
            Caption = 'Serial No. Required';

        }
        field(11; "Lot No. Required"; Boolean)
        {
            Caption = 'Lot No. Required';

        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Serial No. Info Required"; Boolean)
        {
            Caption = 'Serial No. Info Required';
        }
        field(31; "Lot No. Info Required"; Boolean)
        {
            Caption = 'Lot No. Info Required';
        }
        field(40; "Serial No. Mismatch"; Boolean)
        {
            Caption = 'Serial No. Mismatch';
        }
        field(41; "Lot No. Mismatch"; Boolean)
        {
            Caption = 'Lot No. Mismatch';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyTrackingFromEntrySummary(EntrySummary: Record "Entry Summary");
    begin
        "Serial No." := EntrySummary."Serial No.";
        "Lot No." := EntrySummary."Lot No.";

        OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    procedure CopyTrackingFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer");
    begin
        "Serial No." := BinContentBuffer."Serial No.";
        "Lot No." := BinContentBuffer."Lot No.";

        OnAfterCopyTrackingFromBinContentBuffer(Rec, BinContentBuffer);
    end;

    procedure CopyTrackingFromItemJournalLine(ItemJournalLine: Record "Item Journal Line");
    begin
        "Serial No." := ItemJournalLine."Serial No.";
        "Lot No." := ItemJournalLine."Lot No.";

        OnAfterCopyTrackingFromItemJournalLine(Rec, ItemJournalLine);
    end;

    procedure CopyTrackingFromItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry");
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line");
    begin
        "Serial No." := ItemJnlLine."Serial No.";
        "Lot No." := ItemJnlLine."Lot No.";

        OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingFromItemTrackingSetup(FromItemTrackingSetup: Record "Item Tracking Setup");
    begin
        "Serial No." := FromItemTrackingSetup."Serial No.";
        "Lot No." := FromItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, FromItemTrackingSetup);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry");
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification");
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line");
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry");
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line");
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterForItem(var Item: Record Item)
    begin
        if "Serial No." <> '' then
            Item.SetRange("Serial No. Filter", "Serial No.");
        if "Lot No." <> '' then
            Item.SetRange("Lot No. Filter", "Lot No.");

        OnAfterSetTrackingFilterForItem(Item, Rec);
    end;

    procedure CheckTrackingMismatch(TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        if "Serial No." <> '' then
            "Serial No. Mismatch" :=
                ItemTrackingCode."SN Specific Tracking" and (TrackingSpecification."Serial No." <> "Serial No.");
        if "Lot No." <> '' then
            "Lot No. Mismatch" :=
                ItemTrackingCode."Lot Specific Tracking" and (TrackingSpecification."Lot No." <> "Lot No.");

        OnAfterCheckTrackingMismatch(Rec, TrackingSpecification, ItemTrackingCode);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean;
    begin
        IsTrackingExists := ("Serial No." <> '') or ("Lot No." <> '');
        OnAfterTrackingExists(Rec, IsTrackingExists);
    end;

    procedure TrackingRequired() IsTrackingRequired: Boolean;
    begin
        IsTrackingRequired := "Serial No. Required" or "Lot No. Required";
        OnAfterTrackingRequired(Rec, IsTrackingRequired);
    end;

    procedure TrackingMismatch() IsTrackingMismatch: Boolean;
    begin
        IsTrackingMismatch := "Serial No. Mismatch" or "Lot No. Mismatch";
        OnAfterTrackingMismatch(Rec, IsTrackingMismatch);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingMismatch(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromBinContentBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromEntrySummary(var ItemTrackingSetup: Record "Item Tracking Setup"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var ItemTrackingSetup: Record "Item Tracking Setup"; FromItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJournalLine(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgerEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJnlLine(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForItem(var Item: Record Item; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingRequired(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingMismatch(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingMismatch: Boolean)
    begin
    end;
}

