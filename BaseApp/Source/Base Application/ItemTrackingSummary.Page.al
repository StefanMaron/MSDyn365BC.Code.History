page 6500 "Item Tracking Summary"
{
    Caption = 'Item Tracking Summary';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Entry Summary";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the lot number for which availability is presented in the Item Tracking Summary window.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the serial number for which availability is presented in the Item Tracking Summary window.';
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the warranty expiration date, if any, of the item carrying the item tracking number.';
                    Visible = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the expiration date, if any, of the item carrying the item tracking number.';
                    Visible = false;
                }
                field("Total Quantity"; "Total Quantity")
                {
                    ApplicationArea = ItemTracking;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntries(FieldNo("Total Quantity"));
                    end;
                }
                field("Total Requested Quantity"; "Total Requested Quantity")
                {
                    ApplicationArea = ItemTracking;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the lot or serial number that is requested in all documents.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntries(FieldNo("Total Requested Quantity"));
                    end;
                }
                field("Current Pending Quantity"; "Current Pending Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the quantity from the item tracking line that is selected on the document but not yet committed to the database.';
                }
                field("Total Available Quantity"; "Total Available Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the quantity available for the user to request, in entries of the type on the line.';
                }
                field("Current Reserved Quantity"; "Current Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items in the entry that are reserved for the line that the Reservation window is opened from.';
                    Visible = false;
                }
                field("Total Reserved Quantity"; "Total Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the relevant item that is reserved on documents or entries of the type on the line.';
                    Visible = false;
                }
                field("Bin Content"; "Bin Content")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item in the bin specified in the document line.';
                    Visible = BinContentVisible;

                    trigger OnDrillDown()
                    begin
                        DrillDownBinContent(FieldNo("Bin Content"));
                    end;
                }
                field("Selected Quantity"; "Selected Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = SelectedQuantityEditable;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the quantity of each lot or serial number that you want to use to fulfill the demand for the transaction.';
                    Visible = SelectedQuantityVisible;

                    trigger OnValidate()
                    begin
                        SelectedQuantityOnAfterValidat;
                    end;
                }
            }
            group(Control50)
            {
                ShowCaption = false;
                fixed(Control1901775901)
                {
                    ShowCaption = false;
                    group(Selectable)
                    {
                        Caption = 'Selectable';
                        Visible = MaxQuantity1Visible;
                        field(MaxQuantity1; MaxQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Selectable';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the value from the Undefined field on the Item Tracking Lines window. This value indicates how much can be selected.';
                        }
                    }
                    group(Selected)
                    {
                        Caption = 'Selected';
                        Visible = Selected1Visible;
                        field(Selected1; SelectedQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Selected';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the sum of the quantity that you have selected. It Specifies a total of the quantities in the Selected Quantity fields.';
                        }
                    }
                    group(Undefined)
                    {
                        Caption = 'Undefined';
                        Visible = Undefined1Visible;
                        field(Undefined1; MaxQuantity - SelectedQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'Undefined';
                            DecimalPlaces = 2 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the difference between the quantity that can be selected for the document line, and the quantity selected in this window.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateIfFiltersHaveChanged;
    end;

    trigger OnInit()
    begin
        Undefined1Visible := true;
        Selected1Visible := true;
        MaxQuantity1Visible := true;
        BinContentVisible := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateSelectedQuantity;

        BinContentVisible := CurrBinCode <> '';
    end;

    var
        CurrItemTrackingCode: Record "Item Tracking Code";
        TempReservEntry: Record "Reservation Entry" temporary;
        xFilterRec: Record "Entry Summary";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        MaxQuantity: Decimal;
        SelectedQuantity: Decimal;
        CurrBinCode: Code[20];
        [InDataSet]
        SelectedQuantityVisible: Boolean;
        [InDataSet]
        BinContentVisible: Boolean;
        [InDataSet]
        MaxQuantity1Visible: Boolean;
        [InDataSet]
        Selected1Visible: Boolean;
        [InDataSet]
        Undefined1Visible: Boolean;
        [InDataSet]
        SelectedQuantityEditable: Boolean;

    procedure SetSources(var ReservEntry: Record "Reservation Entry"; var EntrySummary: Record "Entry Summary")
    var
        xEntrySummary: Record "Entry Summary";
    begin
        TempReservEntry.Reset();
        TempReservEntry.DeleteAll();
        if ReservEntry.Find('-') then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next = 0;

        xEntrySummary.SetView(GetView);
        Reset;
        DeleteAll();
        if EntrySummary.FindSet then
            repeat
                if EntrySummary.HasQuantity then begin
                    Rec := EntrySummary;
                    Insert;
                end;
            until EntrySummary.Next = 0;
        SetView(xEntrySummary.GetView);
        UpdateSelectedQuantity;
    end;

    procedure SetSelectionMode(SelectionMode: Boolean)
    begin
        SelectedQuantityVisible := SelectionMode;
        SelectedQuantityEditable := SelectionMode;
        MaxQuantity1Visible := SelectionMode;
        Selected1Visible := SelectionMode;
        Undefined1Visible := SelectionMode;
    end;

    procedure SetMaxQuantity(MaxQty: Decimal)
    begin
        MaxQuantity := MaxQty;
    end;

    procedure SetCurrentBinAndItemTrkgCode(BinCode: Code[20]; ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(BinCode, ItemTrackingCode);
        BinContentVisible := BinCode <> '';
        CurrBinCode := BinCode;
        CurrItemTrackingCode := ItemTrackingCode;
        OnAfterSetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode, BinContentVisible, Rec, TempReservEntry);
    end;

    procedure AutoSelectTrackingNo()
    var
        AvailableQty: Decimal;
        SelectedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoSelectTrackingNo(Rec, MaxQuantity, IsHandled);
        if IsHandled then
            exit;

        if MaxQuantity = 0 then
            exit;

        SelectedQty := MaxQuantity;
        if FindSet then
            repeat
                AvailableQty := "Total Available Quantity";
                if "Bin Active" then
                    AvailableQty := MinValueAbs(QtyAvailableToSelectFromBin, "Total Available Quantity");

                if AvailableQty > 0 then begin
                    "Selected Quantity" := MinValueAbs(AvailableQty, SelectedQty);
                    SelectedQty -= "Selected Quantity";
                    Modify;
                end;
            until (Next = 0) or (SelectedQty <= 0);
    end;

    local procedure MinValueAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Abs(Value1) < Abs(Value2) then
            exit(Value1);

        exit(Value2);
    end;

    local procedure UpdateSelectedQuantity()
    var
        xEntrySummary: Record "Entry Summary";
    begin
        if not SelectedQuantityVisible then
            exit;
        if Modify then; // Ensure that changes to current rec are included in CALCSUMS
        xEntrySummary := Rec;
        CalcSums("Selected Quantity");
        SelectedQuantity := "Selected Quantity";
        Rec := xEntrySummary;
    end;

    procedure GetSelected(var EntrySummary: Record "Entry Summary")
    begin
        EntrySummary.Reset();
        EntrySummary.DeleteAll();
        SetFilter("Selected Quantity", '<>%1', 0);
        if FindSet then
            repeat
                EntrySummary := Rec;
                EntrySummary.Insert();
            until Next = 0;
    end;

    local procedure DrillDownEntries(FieldNumber: Integer)
    var
        TempReservEntry2: Record "Reservation Entry" temporary;
    begin
        TempReservEntry.Reset();
        TempReservEntry.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status",
          "Location Code", "Variant Code", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        TempReservEntry.SetRange("Lot No.", "Lot No.");
        if "Serial No." <> '' then
            TempReservEntry.SetRange("Serial No.", "Serial No.");

        case FieldNumber of
            FieldNo("Total Quantity"):
                begin
                    // An Item Ledger Entry will in itself be represented with a surplus TempReservEntry. Order tracking
                    // and reservations against Item Ledger Entries are therefore kept out, as these quantities would
                    // otherwise be represented twice in the drill down.

                    TempReservEntry.SetRange(Positive, true);
                    TempReservEntry2.Copy(TempReservEntry);  // Copy key
                    if TempReservEntry.FindSet then
                        repeat
                            TempReservEntry2 := TempReservEntry;
                            if TempReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then begin
                                if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Surplus then
                                    TempReservEntry2.Insert();
                            end else
                                TempReservEntry2.Insert();
                        until TempReservEntry.Next = 0;
                    TempReservEntry2.Ascending(false);
                    PAGE.RunModal(PAGE::"Avail. - Item Tracking Lines", TempReservEntry2);
                end;
            FieldNo("Total Requested Quantity"):
                begin
                    TempReservEntry.SetRange(Positive, false);
                    TempReservEntry.Ascending(false);
                    PAGE.RunModal(PAGE::"Avail. - Item Tracking Lines", TempReservEntry);
                end;
        end;
    end;

    local procedure DrillDownBinContent(FieldNumber: Integer)
    var
        BinContent: Record "Bin Content";
    begin
        if CurrBinCode = '' then
            exit;
        TempReservEntry.Reset();
        if not TempReservEntry.FindFirst then
            exit;

        CurrItemTrackingCode.TestField(Code);

        BinContent.SetRange("Location Code", TempReservEntry."Location Code");
        BinContent.SetRange("Item No.", TempReservEntry."Item No.");
        BinContent.SetRange("Variant Code", TempReservEntry."Variant Code");
        if CurrItemTrackingCode."Lot Warehouse Tracking" then
            if "Lot No." <> '' then
                BinContent.SetRange("Lot No. Filter", "Lot No.");
        if CurrItemTrackingCode."SN Warehouse Tracking" then
            if "Serial No." <> '' then
                BinContent.SetRange("Serial No. Filter", "Serial No.");

        if FieldNumber = FieldNo("Bin Content") then
            BinContent.SetRange("Bin Code", CurrBinCode);

        PAGE.RunModal(PAGE::"Bin Content", BinContent);
    end;

    local procedure UpdateIfFiltersHaveChanged()
    begin
        // In order to update Selected Quantity when filters have been changed on the form.
        if GetFilters = xFilterRec.GetFilters then
            exit;

        UpdateSelectedQuantity;
        xFilterRec.Copy(Rec);
    end;

    local procedure SelectedQuantityOnAfterValidat()
    begin
        UpdateSelectedQuantity;
        CurrPage.Update;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentBinAndItemTrkgCode(var CurrBinCode: Code[20]; var CurrItemTrackingCode: Record "Item Tracking Code"; var BinContentVisible: Boolean; var EntrySummary: Record "Entry Summary"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoSelectTrackingNo(var EntrySummary: Record "Entry Summary"; var MaxQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;
}

