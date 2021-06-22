table 6565 "Item Tracking Setup"
{
    Caption = 'Item Tracking Code';
    DataCaptionFields = "Code";

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

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry");
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
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

    procedure TrackingExists(): Boolean;
    begin
        exit(("Serial No." <> '') or ("Lot No." <> ''));
    end;

    procedure TrackingRequired(): Boolean;
    begin
        exit("Serial No. Required" or "Lot No. Required");
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
    local procedure OnAfterCopyTrackingFromReservEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
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
}

