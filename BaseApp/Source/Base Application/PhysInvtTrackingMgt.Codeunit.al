codeunit 5889 "Phys. Invt. Tracking Mgt."
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Pstd. Phys. Invt. Tracking" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";

    procedure SuggestUseTrackingLines(Item: Record Item): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if Item."Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get(Item."Item Tracking Code");

        exit(
          ItemTrackingCode."SN Specific Tracking" or
          ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking" or
          ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking" or
          ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" or
          ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or
          ItemTrackingCode."Lot Specific Tracking" or
          ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" or
          ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking" or
          ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking" or
          ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking"
          );
    end;

    procedure GetTrackingNosFromWhse(Item: Record Item): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if Item."Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get(Item."Item Tracking Code");

        if (ItemTrackingCode."SN Specific Tracking" and ItemTrackingCode."SN Warehouse Tracking") or
           (ItemTrackingCode."Lot Specific Tracking" and ItemTrackingCode."Lot Warehouse Tracking")
        then
            exit(true);

        exit(false);
    end;

    procedure LocationIsBinMandatory(LocationCode: Code[20]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);

        Location.Get(LocationCode);
        exit(Location."Bin Mandatory");
    end;

    procedure TransferResEntryToItemJnlLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemJnlLine: Record "Item Journal Line"; Qty: Decimal; Positive: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        // Transfer all Reserve Entry, connected by a PhysInvtOrderLine, to an ItemJnlLine bevor posting the PhysInvtOrderLine

        if Qty = 0 then
            exit;

        ItemJnlLine.TestField("Item No.", PhysInvtOrderLine."Item No.");
        ItemJnlLine.TestField("Variant Code", PhysInvtOrderLine."Variant Code");
        ItemJnlLine.TestField("Location Code", PhysInvtOrderLine."Location Code");
        ItemJnlLine.TestField("Bin Code", PhysInvtOrderLine."Bin Code");

        ReservEntry.Reset();
        ReservEntry.SetCurrentKey(
          "Source Type", "Source Subtype", "Source ID",
          "Source Batch Name", "Source Prod. Order Line",
          "Source Ref. No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Phys. Invt. Order Line");
        ReservEntry.SetRange("Source Subtype", 0);
        ReservEntry.SetRange("Source ID", PhysInvtOrderLine."Document No.");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetRange("Source Ref. No.", PhysInvtOrderLine."Line No.");
        ReservEntry.SetRange(Positive, Positive);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);

                ReservEntry.TestField("Item No.", PhysInvtOrderLine."Item No.");
                ReservEntry.TestField("Variant Code", PhysInvtOrderLine."Variant Code");
                ReservEntry.TestField("Location Code", PhysInvtOrderLine."Location Code");
                ReservEntry."New Serial No." := ReservEntry."Serial No.";
                ReservEntry."New Lot No." := ReservEntry."Lot No.";
                OnTransferResEntryToItemJnlLineOnBeforeTransfer(ReservEntry, PhysInvtOrderLine);

                Qty :=
                  CreateReservEntry.TransferReservEntry(
                    DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type",
                    ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name",
                    0,
                    ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure",
                    ReservEntry,
                    Qty);
            until (ReservEntry.Next = 0) or (Qty = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferResEntryToItemJnlLineOnBeforeTransfer(var ReservationEntry: Record "Reservation Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

