page 522 "View Applied Entries"
{
    Caption = 'View Applied Entries';
    DataCaptionExpression = CaptionExpr;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Worksheet;
    Permissions = TableData "Item Application Entry" = rimd;
    SaveValues = true;
    SourceTable = "Item Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Document Line No."; "Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line on the posted document that corresponds to the item ledger entry.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item in the entry.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                    Visible = false;
                }
                field(ApplQty; ApplQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry linked to an inventory decrease, or increase, as appropriate.';
                }
                field(Qty; Qty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry.';
                }
                field("Cost Amount (Actual)"; "Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjusted cost, in LCY, of the quantity posting.';
                }
                field(GetUnitCostLCY; GetUnitCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Cost(LCY)';
                    ToolTip = 'Specifies the unit cost of the item in the item ledger entry.';
                    Visible = false;
                }
                field("Invoiced Quantity"; "Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been invoiced.';
                    Visible = true;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                    Visible = true;
                }
                field("CostAvailable(Rec)"; CostAvailable(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity Available for Cost Applications';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry that can be cost applied.';
                }
                field("QuantityAvailable(Rec)"; QuantityAvailable(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available for Quantity Application';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item ledger entry that can be applied.';
                }
                field("Shipped Qty. Not Returned"; "Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity per item unit of measure.';
                    Visible = false;
                }
                field("Drop Shipment"; "Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field("Applies-to Entry"; "Applies-to Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the quantity on the journal line must be applied to an already-posted entry. In that case, enter the entry number that the quantity will be applied to.';
                    Visible = false;
                }
                field("Applied Entry to Adjust"; "Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there is one or more applied entries, which need to be adjusted.';
                    Visible = false;
                }
                field("Order Type"; "Order Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of order that the entry was created in.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        ShowReservationEntries(true);
                    end;
                }
            }
        }
        area(processing)
        {
            action(RemoveAppButton)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Re&move Application';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Remove item applications.';
                Visible = RemoveAppButtonVisible;

                trigger OnAction()
                begin
                    UnapplyRec;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetApplQty;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Find(Which));
    end;

    trigger OnInit()
    begin
        RemoveAppButtonVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode := not ShowApplied;
        RemoveAppButtonVisible := ShowApplied;
        Show;
    end;

    var
        RecordToShow: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Apply: Codeunit "Item Jnl.-Post Line";
        ShowApplied: Boolean;
        ShowQuantity: Boolean;
        MaxToApply: Decimal;
        ApplQty: Decimal;
        Qty: Decimal;
        TotalApplied: Decimal;
        Text001: Label 'Applied Entries';
        Text002: Label 'Unapplied Entries';
        [InDataSet]
        RemoveAppButtonVisible: Boolean;

    procedure SetRecordToShow(var RecordToSet: Record "Item Ledger Entry"; var ApplyCodeunit: Codeunit "Item Jnl.-Post Line"; newShowApplied: Boolean)
    begin
        RecordToShow.Copy(RecordToSet);
        Apply := ApplyCodeunit;
        ShowApplied := newShowApplied;
    end;

    local procedure Show()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Apprec: Record "Item Application Entry";
    begin
        with ItemLedgEntry do begin
            Get(RecordToShow."Entry No.");
            ShowQuantity := not (("Entry Type" in ["Entry Type"::Sale, "Entry Type"::Consumption, "Entry Type"::Output]) and Positive);

            MaxToApply := 0;
            if not ShowQuantity then
                MaxToApply := Quantity + Apprec.Returned("Entry No.");
        end;
        SetMyView(RecordToShow, ShowApplied, ShowQuantity, MaxToApply);
    end;

    local procedure SetMyView(ItemLedgEntry: Record "Item Ledger Entry"; ShowApplied: Boolean; ShowQuantity: Boolean; MaxToApply: Decimal)
    begin
        InitView;
        case ShowQuantity of
            true:
                case ShowApplied of
                    true:
                        ShowQuantityApplied(ItemLedgEntry);
                    false:
                        begin
                            ShowQuantityOpen(ItemLedgEntry);
                            ShowCostOpen(ItemLedgEntry, MaxToApply);
                        end;
                end;
            false:
                case ShowApplied of
                    true:
                        ShowCostApplied(ItemLedgEntry);
                    false:
                        ShowCostOpen(ItemLedgEntry, MaxToApply);
                end;
        end;

        if TempItemLedgEntry.FindSet then
            repeat
                Rec := TempItemLedgEntry;
                Insert;
            until TempItemLedgEntry.Next = 0;
    end;

    local procedure InitView()
    begin
        DeleteAll();
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
    end;

    local procedure ShowQuantityApplied(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        InitApplied;
        with ItemLedgEntry do
            if Positive then begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Inbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1&<>%2', "Entry No.", 0);
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Outbound Item Entry No.", ItemApplnEntry.Quantity, true);
                    until ItemApplnEntry.Next = 0;
            end else begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Outbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Inbound Item Entry No.", -ItemApplnEntry.Quantity, true);
                    until ItemApplnEntry.Next = 0;
            end;
    end;

    local procedure ShowQuantityOpen(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do
            if "Remaining Quantity" <> 0 then begin
                ItemLedgEntry2.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
                ItemLedgEntry2.SetRange("Item No.", "Item No.");
                ItemLedgEntry2.SetRange("Location Code", "Location Code");
                ItemLedgEntry2.SetRange(Positive, not Positive);
                ItemLedgEntry2.SetRange(Open, true);
                if ItemLedgEntry2.Find('-') then
                    repeat
                        if (QuantityAvailable(ItemLedgEntry2) <> 0) and
                           not ItemApplnEntry.ExistsBetween("Entry No.", ItemLedgEntry2."Entry No.")
                        then
                            InsertTempEntry(ItemLedgEntry2."Entry No.", 0, true);
                    until ItemLedgEntry2.Next = 0;
            end;
    end;

    local procedure ShowCostApplied(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        InitApplied;
        with ItemLedgEntry do
            if Positive then begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Inbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', "Entry No.");
                ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
                ItemApplnEntry.SetRange("Cost Application", true); // we want to show even average cost application
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Outbound Item Entry No.", ItemApplnEntry.Quantity, false);
                    until ItemApplnEntry.Next = 0;
            end else begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Outbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', "Entry No.");
                ItemApplnEntry.SetRange("Cost Application", true); // we want to show even average cost application
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Inbound Item Entry No.", -ItemApplnEntry.Quantity, false);
                    until ItemApplnEntry.Next = 0;
            end;
    end;

    local procedure ShowCostOpen(ItemLedgEntry: Record "Item Ledger Entry"; MaxToApply: Decimal)
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            ItemLedgEntry2.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
            ItemLedgEntry2.SetRange("Item No.", "Item No.");
            ItemLedgEntry2.SetRange("Location Code", "Location Code");
            ItemLedgEntry2.SetRange(Positive, not Positive);
            ItemLedgEntry2.SetFilter("Shipped Qty. Not Returned", '<%1&>=%2', 0, -MaxToApply);
            if (MaxToApply <> 0) and Positive then
                ItemLedgEntry2.SetFilter("Shipped Qty. Not Returned", '<=%1', -MaxToApply);
            if ItemLedgEntry2.Find('-') then
                repeat
                    if (CostAvailable(ItemLedgEntry2) <> 0) and
                       not ItemApplnEntry.ExistsBetween("Entry No.", ItemLedgEntry2."Entry No.")
                    then
                        InsertTempEntry(ItemLedgEntry2."Entry No.", 0, true);
                until ItemLedgEntry2.Next = 0;
        end;
    end;

    local procedure InsertTempEntry(EntryNo: Integer; AppliedQty: Decimal; ShowQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(EntryNo);

        if ShowQuantity then
            if AppliedQty * ItemLedgEntry.Quantity < 0 then
                exit;

        if not TempItemLedgEntry.Get(EntryNo) then begin
            TempItemLedgEntry.Reset();
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.CalcFields("Reserved Quantity");
            TempItemLedgEntry.Quantity := AppliedQty;
            TempItemLedgEntry.Insert();
        end else begin
            TempItemLedgEntry.Quantity := TempItemLedgEntry.Quantity + AppliedQty;
            TempItemLedgEntry.Modify();
        end;

        TotalApplied := TotalApplied + AppliedQty;
    end;

    local procedure InitApplied()
    begin
        Clear(TotalApplied);
    end;

    local procedure RemoveApplications(Inbound: Integer; OutBound: Integer)
    var
        Application: Record "Item Application Entry";
    begin
        Application.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        Application.SetRange("Inbound Item Entry No.", Inbound);
        Application.SetRange("Outbound Item Entry No.", OutBound);
        if Application.FindSet then
            repeat
                Apply.UnApply(Application);
                Apply.LogUnapply(Application);
            until Application.Next = 0;
    end;

    local procedure UnapplyRec()
    var
        Applyrec: Record "Item Ledger Entry";
        AppliedItemLedgEntry: Record "Item Ledger Entry";
    begin
        Applyrec.Get(RecordToShow."Entry No.");
        CurrPage.SetSelectionFilter(TempItemLedgEntry);
        if TempItemLedgEntry.FindSet then begin
            repeat
                AppliedItemLedgEntry.Get(TempItemLedgEntry."Entry No.");
                if AppliedItemLedgEntry."Entry No." <> 0 then begin
                    if Applyrec.Positive then
                        RemoveApplications(Applyrec."Entry No.", AppliedItemLedgEntry."Entry No.")
                    else
                        RemoveApplications(AppliedItemLedgEntry."Entry No.", Applyrec."Entry No.");
                end;
            until TempItemLedgEntry.Next = 0;

            BlockItem(Applyrec."Item No.");
        end;
        Show;
    end;

    procedure ApplyRec()
    var
        Applyrec: Record "Item Ledger Entry";
        AppliedItemLedgEntry: Record "Item Ledger Entry";
    begin
        Applyrec.Get(RecordToShow."Entry No.");
        CurrPage.SetSelectionFilter(TempItemLedgEntry);
        if TempItemLedgEntry.FindSet then
            repeat
                AppliedItemLedgEntry.Get(TempItemLedgEntry."Entry No.");
                if AppliedItemLedgEntry."Entry No." <> 0 then begin
                    Apply.ReApply(Applyrec, AppliedItemLedgEntry."Entry No.");
                    Apply.LogApply(Applyrec, AppliedItemLedgEntry);
                end;
            until TempItemLedgEntry.Next = 0;

        if Applyrec.Positive then
            RemoveDuplicateApplication(Applyrec."Entry No.");

        Show;
    end;

    local procedure RemoveDuplicateApplication(ItemLedgerEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        with ItemApplicationEntry do begin
            SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
            SetRange("Inbound Item Entry No.", ItemLedgerEntryNo);
            SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
            SetFilter("Outbound Item Entry No.", '<>0');
            if not IsEmpty then begin
                SetRange("Outbound Item Entry No.", 0);
                DeleteAll();
            end
        end;
    end;

    local procedure BlockItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if Item."Application Wksh. User ID" <> UpperCase(UserId) then
            Item.CheckBlockedByApplWorksheet;

        Item."Application Wksh. User ID" := UserId;
        Item.Modify(true);
    end;

    local procedure GetApplQty()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get("Entry No.");
        ApplQty := Quantity;
        Qty := ItemLedgEntry.Quantity;
    end;

    local procedure QuantityAvailable(ILE: Record "Item Ledger Entry"): Decimal
    begin
        with ILE do begin
            CalcFields("Reserved Quantity");
            exit("Remaining Quantity" - "Reserved Quantity");
        end;
    end;

    local procedure CostAvailable(ILE: Record "Item Ledger Entry"): Decimal
    var
        Apprec: Record "Item Application Entry";
    begin
        with ILE do begin
            if "Shipped Qty. Not Returned" <> 0 then
                exit(-"Shipped Qty. Not Returned");

            exit("Remaining Quantity" + Apprec.Returned("Entry No."));
        end;
    end;

    procedure CaptionExpr(): Text
    begin
        if ShowApplied then
            exit(Text001);

        exit(Text002);
    end;
}

