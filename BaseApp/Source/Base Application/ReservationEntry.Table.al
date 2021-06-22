table 337 "Reservation Entry"
{
    Caption = 'Reservation Entry';
    DrillDownPageID = "Reservation Entries";
    LookupPageID = "Reservation Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Quantity := CalcReservationQuantity;
                "Qty. to Handle (Base)" := "Quantity (Base)";
                "Qty. to Invoice (Base)" := "Quantity (Base)";
            end;
        }
        field(5; "Reservation Status"; Enum "Reservation Status")
        {
            Caption = 'Reservation Status';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(9; "Transferred from Entry No."; Integer)
        {
            Caption = 'Transferred from Entry No.';
            TableRelation = "Reservation Entry";
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(16; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(22; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(23; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(24; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(25; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(27; "Changed By"; Code[50])
        {
            Caption = 'Changed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(28; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;

            trigger OnValidate()
            begin
                Quantity := Round("Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            end;
        }
        field(30; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(31; "Action Message Adjustment"; Decimal)
        {
            CalcFormula = Sum ("Action Message Entry".Quantity WHERE("Reservation Entry" = FIELD("Entry No."),
                                                                     Calculation = CONST(Sum)));
            Caption = 'Action Message Adjustment';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; Binding; Enum "Reservation Binding")
        {
            Caption = 'Binding';
            Editable = false;
        }
        field(33; "Suppressed Action Msg."; Boolean)
        {
            Caption = 'Suppressed Action Msg.';
        }
        field(34; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            Caption = 'Appl.-to Item Entry';
        }
        field(40; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            Editable = false;
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(80; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            Editable = false;
        }
        field(81; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            Editable = false;
        }
        field(900; "Disallow Cancellation"; Boolean)
        {
            Caption = 'Disallow Cancellation';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(6505; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
            Editable = false;
        }
        field(6510; "Item Tracking"; Enum "Item Tracking Entry Type")
        {
            Caption = 'Item Tracking';
            Editable = false;
        }
        field(6511; "Untracked Surplus"; Boolean)
        {
            Caption = 'Untracked Surplus';
        }
    }

    keys
    {
        key(Key1; "Entry No.", Positive)
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)", Quantity, "Qty. to Handle (Base)", "Qty. to Invoice (Base)";
        }
        key(Key3; "Item No.", "Variant Code", "Location Code")
        {
            MaintainSIFTIndex = false;
        }
        key(Key4; "Item No.", "Variant Code", "Location Code", "Reservation Status", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key5; "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Quantity (Base)", Quantity;
        }
        key(Key6; "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key7; "Lot No.")
        {
            Enabled = false;
        }
        key(Key8; "Serial No.")
        {
            Enabled = false;
        }
        key(Key9; "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.")
        {
        }
        key(Key10; "Reservation Status", "Item No.", "Variant Code", "Location Code", "Expected Receipt Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Positive, "Item No.", Description, Quantity)
        {
        }
    }

    trigger OnDelete()
    var
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", "Entry No.");
        ActionMessageEntry.DeleteAll();
    end;

    var
        Text001: Label 'Line';
        Text004: Label 'Codeunit 99000845: Illegal FieldFilter parameter';
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InitSortingAndFilters(SetFilters: Boolean)
    begin
        Reset;
        SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");
        if SetFilters then
            SetRange("Reservation Status", "Reservation Status"::Reservation);
    end;

    procedure TextCaption(): Text[255]
    var
        RecRef: RecordRef;
        ExtensionTextCaption: Text[255];
    begin
        if "Source Type" > 0 then begin
            RecRef.Open("Source Type");
            ExtensionTextCaption := RecRef.Caption;
        end;

        OnAfterTextCaption("Source Type", ExtensionTextCaption);
        if ExtensionTextCaption <> '' then
            exit(ExtensionTextCaption);
        exit(Text001);
    end;

    procedure SummEntryNo(): Integer
    var
        ReturnValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummEntryNo(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        case "Source Type" of
            DATABASE::"Item Ledger Entry":
                exit(1);
            DATABASE::"Purchase Line":
                exit(11 + "Source Subtype");
            DATABASE::"Requisition Line":
                exit(21);
            DATABASE::"Sales Line":
                exit(31 + "Source Subtype");
            DATABASE::"Item Journal Line":
                exit(41 + "Source Subtype");
            DATABASE::"Job Journal Line":
                exit(51 + "Source Subtype");
            DATABASE::"Prod. Order Line":
                exit(61 + "Source Subtype");
            DATABASE::"Prod. Order Component":
                exit(71 + "Source Subtype");
            DATABASE::"Transfer Line":
                exit(101 + "Source Subtype");
            DATABASE::"Service Line":
                exit(110);
            DATABASE::"Assembly Header":
                exit(141 + "Source Subtype");
            DATABASE::"Assembly Line":
                exit(151 + "Source Subtype");
            else
                exit(0);
        end;
    end;

    procedure HasSamePointer(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit(
          ("Source Type" = ReservEntry."Source Type") and
          ("Source Subtype" = ReservEntry."Source Subtype") and
          ("Source ID" = ReservEntry."Source ID") and
          ("Source Batch Name" = ReservEntry."Source Batch Name") and
          ("Source Prod. Order Line" = ReservEntry."Source Prod. Order Line") and
          ("Source Ref. No." = ReservEntry."Source Ref. No."));
    end;

    procedure HasSamePointerWithSpec(TrackingSpecification: Record "Tracking Specification"): Boolean
    begin
        exit(
          ("Source Type" = TrackingSpecification."Source Type") and
          ("Source Subtype" = TrackingSpecification."Source Subtype") and
          ("Source ID" = TrackingSpecification."Source ID") and
          ("Source Batch Name" = TrackingSpecification."Source Batch Name") and
          ("Source Prod. Order Line" = TrackingSpecification."Source Prod. Order Line") and
          ("Source Ref. No." = TrackingSpecification."Source Ref. No."));
    end;

    procedure HasSameTracking(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit(
          ("Serial No." = ReservEntry."Serial No.") and
          ("Lot No." = ReservEntry."Lot No."));
    end;

    procedure HasSameTrackingWithSpec(TrackingSpecification: Record "Tracking Specification"): Boolean
    begin
        exit(
          ("Serial No." = TrackingSpecification."Serial No.") and
          ("Lot No." = TrackingSpecification."Lot No."));
    end;

    procedure HasSameNewTracking(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit(
          ("New Serial No." = ReservEntry."New Serial No.") and
          ("New Lot No." = ReservEntry."New Lot No."));
    end;

    procedure SetPointer(RowID: Text[250])
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        StrArray: array[6] of Text[100];
    begin
        ItemTrackingMgt.DecomposeRowID(RowID, StrArray);
        Evaluate("Source Type", StrArray[1]);
        Evaluate("Source Subtype", StrArray[2]);
        "Source ID" := StrArray[3];
        "Source Batch Name" := StrArray[4];
        Evaluate("Source Prod. Order Line", StrArray[5]);
        Evaluate("Source Ref. No.", StrArray[6]);
    end;

    procedure SetPointerFilter()
    begin
        SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");
        SetRange("Source ID", "Source ID");
        SetRange("Source Ref. No.", "Source Ref. No.");
        SetRange("Source Type", "Source Type");
        SetRange("Source Subtype", "Source Subtype");
        SetRange("Source Batch Name", "Source Batch Name");
        SetRange("Source Prod. Order Line", "Source Prod. Order Line");
    end;

    procedure SetSourceFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Source ID", ReservEntry."Source ID");
        SetRange("Source Ref. No.", ReservEntry."Source Ref. No.");
        SetRange("Source Type", ReservEntry."Source Type");
        SetRange("Source Subtype", ReservEntry."Source Subtype");
        SetRange("Source Batch Name", ReservEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ReservEntry."Source Prod. Order Line");
    end;

    procedure Lock()
    var
        Rec2: Record "Reservation Entry";
    begin
        Rec2.SetCurrentKey("Item No.");
        if "Item No." <> '' then
            Rec2.SetRange("Item No.", "Item No.");
        Rec2.LockTable();
        if Rec2.FindLast then;
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; LocationCode: Code[10]; VariantCode: Code[10]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Qty. per Unit of Measure" := QtyPerUoM;
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Warranty Date" := 0D;
        "Expiration Date" := 0D;

        OnAfterClearTracking(Rec);
    end;

    procedure ClearNewTracking()
    begin
        "New Serial No." := '';
        "New Lot No." := '';

        OnAfterClearNewTracking(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingFromInvtProfile(InvtProfile: Record "Inventory Profile")
    begin
        "Serial No." := InvtProfile."Serial No.";
        "Lot No." := InvtProfile."Lot No.";

        OnAfterCopyTrackingFromInvtProfile(Rec, InvtProfile);
    end;

    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
    end;

    procedure CopyTrackingFromReservEntryNewTracking(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."New Serial No.";
        "Lot No." := ReservationEntry."New Lot No.";

        OnAfterCopyTrackingFromReservEntryNewTracking(Rec, ReservationEntry);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";
        "Warranty Date" := TrackingSpecification."Warranty Date";
        "Expiration Date" := TrackingSpecification."Expiration Date";

        OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromWhseActivLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WarehouseActivityLine."Serial No.";
        "Lot No." := WarehouseActivityLine."Lot No.";
        "Expiration Date" := WarehouseActivityLine."Expiration Date";

        OnAfterCopyTrackingFromWhseActivLine(Rec, WarehouseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure CopyNewTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        "New Serial No." := ItemJnlLine."New Serial No.";
        "New Lot No." := ItemJnlLine."New Lot No.";

        OnAfterSetNewTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyNewTrackingFromTrackingSpec(TrackingSpeficification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpeficification."New Serial No.";
        "New Lot No." := TrackingSpeficification."New Lot No.";

        OnAfterSetNewTrackingFromTrackingSpecification(Rec, TrackingSpeficification);
    end;

    procedure CopyNewTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "New Serial No." := WhseItemTrackingLine."New Serial No.";
        "New Lot No." := WhseItemTrackingLine."New Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilter(SerialNo: Code[50]; LotNo: Code[50])
    begin
        SetRange("Serial No.", SerialNo);
        SetRange("Lot No.", LotNo);
    end;

    procedure SetTrackingFilterBlank()
    begin
        SetRange("Serial No.", '');
        SetRange("Lot No.", '');

        OnAfterSetTrackingFilterBlank(Rec);
    end;

    procedure SetTrackingFilterFromItemJnlLine(ItemJournalLine: Record "Item Journal Line")
    begin
        SetRange("Serial No.", ItemJournalLine."Serial No.");
        SetRange("Lot No.", ItemJournalLine."Lot No.");

        OnAfterSetTrackingFilterFromItemJnlLine(Rec, ItemJournalLine);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservEntry."Serial No.");
        SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromSpecIfNotBlank(TrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecification."Serial No." <> '' then
            SetRange("Serial No.", TrackingSpecification."Serial No.");
        if TrackingSpecification."Lot No." <> '' then
            SetRange("Lot No.", TrackingSpecification."Lot No.");
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WhseActivityLine."Serial No.");
        SetRange("Lot No.", WhseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseJnlLine(WhseJournalLine: Record "Warehouse Journal Line")
    begin
        SetRange("Serial No.", WhseJournalLine."Serial No.");
        SetRange("Lot No.", WhseJournalLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseJnlLine(Rec, WhseJournalLine);
    end;

    procedure SetTrackingFilterFromWhseSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseSpec(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromWhseActivityLineIfRequired(WhseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", WhseActivityLine."Serial No.")
        else
            SetFilter("Serial No.", '%1|%2', WhseActivityLine."Serial No.", '');

        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", WhseActivityLine."Lot No.")
        else
            SetFilter("Lot No.", '%1|%2', WhseActivityLine."Lot No.", '');
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
            else
                SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
            else
                SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');
    end;

    procedure SetTrackingFilterToItemIfRequired(var Item: Record Item)
    begin
        if "Lot No." <> '' then
            Item.SetRange("Lot No. Filter", "Lot No.");
        if "Serial No." <> '' then
            Item.SetRange("Serial No. Filter", "Serial No.");
    end;

    procedure GetItemTrackingEntryType() TrackingEntryType: Enum "Item Tracking Entry Type"
    begin
        if "Lot No." <> '' then
            TrackingEntryType := TrackingEntryType::"Lot No.";

        if "Serial No." <> '' then
            if "Lot No." <> '' then
                TrackingEntryType := TrackingEntryType::"Lot and Serial No."
            else
                TrackingEntryType := TrackingEntryType::"Serial No.";
    end;

    procedure UpdateItemTracking()
    begin
        "Item Tracking" := GetItemTrackingEntryType();
    end;

    procedure UpdateActionMessageEntries(OldReservEntry: Record "Reservation Entry")
    var
        ActionMessageEntry: Record "Action Message Entry";
        ActionMessageEntry2: Record "Action Message Entry";
        OldReservEntry2: Record "Reservation Entry";
    begin
        if OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Surplus then begin
            ActionMessageEntry.FilterFromReservEntry(OldReservEntry);
            if ActionMessageEntry.FindSet then
                repeat
                    ActionMessageEntry2 := ActionMessageEntry;
                    ActionMessageEntry2.TransferFromReservEntry(Rec);
                    ActionMessageEntry2.Modify();
                until ActionMessageEntry.Next = 0;
            Modify;
        end else
            if OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then begin
                if HasSamePointer(OldReservEntry2) then begin
                    OldReservEntry2.Delete();
                    Delete;
                end else
                    Modify;
            end else
                Modify;
    end;

    procedure ClearItemTrackingFields()
    begin
        OnBeforeClearItemTrackingFields(Rec);

        "Lot No." := '';
        "Serial No." := '';
        UpdateItemTracking;

        OnAfterClearItemTrackingFields(Rec);
    end;

    local procedure CalcReservationQuantity(): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if "Qty. per Unit of Measure" = 1 then
            exit("Quantity (Base)");

        ReservEntry.SetFilter("Entry No.", '<>%1', "Entry No.");
        ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", false);
        ReservEntry.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
        ReservEntry.SetRange("Reservation Status", "Reservation Status"::Reservation);
        ReservEntry.CalcSums("Quantity (Base)", Quantity);
        exit(
          Round((ReservEntry."Quantity (Base)" + "Quantity (Base)") / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision) -
          ReservEntry.Quantity);
    end;

    procedure ClearApplFromToItemEntry()
    begin
        if Positive then
            "Appl.-to Item Entry" := 0
        else
            "Appl.-from Item Entry" := 0;
    end;

    [Scope('OnPrem')]
    procedure IsResidualSurplus(): Boolean
    begin
        exit(
          ("Item Tracking" = "Item Tracking"::None) and
          ("Reservation Status" = "Reservation Status"::Surplus) and not Positive and
          ("Source Type" = DATABASE::"Sales Line") and ("Source Subtype" = 1));
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestItemFields(Rec, ItemNo, VariantCode, LocationCode, IsHandled);
        if not IsHandled then begin
            TestField("Item No.", ItemNo);
            TestField("Variant Code", VariantCode);
            TestField("Location Code", LocationCode);
        end;
    end;

    procedure TrackingExists(): Boolean
    begin
        exit(("Serial No." <> '') or ("Lot No." <> ''));
    end;

    procedure GetTrackingText(): Text;
    begin
        exit(StrSubstNo('%1 %2', "Serial No.", "Lot No."));
    end;

    procedure NewTrackingExists(): Boolean
    begin
        exit(("New Serial No." <> '') or ("New Lot No." <> ''));
    end;

    procedure TransferReservations(var OldReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; TransferAll: Boolean; TransferQty: Decimal; QtyPerUOM: Decimal; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        NewReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if TransferAll then begin
            OldReservEntry.FindSet;
            OldReservEntry.TestField("Qty. per Unit of Measure", QtyPerUOM);
            repeat
                OldReservEntry.TestItemFields(ItemNo, VariantCode, LocationCode);

                NewReservEntry := OldReservEntry;
                NewReservEntry.SetSource(SourceType, SourceSubtype, SourceID, SourceRefNo, SourceBatchName, SourceProdOrderLine);

                NewReservEntry.UpdateActionMessageEntries(OldReservEntry);
            until OldReservEntry.Next = 0;
        end else
            for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
                if TransferQty = 0 then
                    exit;
                OldReservEntry.SetRange("Reservation Status", ReservStatus);
                if OldReservEntry.FindSet then
                    repeat
                        OldReservEntry.TestItemFields(ItemNo, VariantCode, LocationCode);

                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo,
                            QtyPerUOM, OldReservEntry, TransferQty);
                    until (OldReservEntry.Next = 0) or (TransferQty = 0);
            end;
    end;

    procedure FieldFilterNeeded(var FieldFilter: Text; SearchForSupply: Boolean; ItemTrackingType: Enum "Item Tracking Type"): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        FieldValue: Code[50];
    begin
        FieldFilter := '';

        FieldValue := '';
        if "Item No." <> Item."No." then begin
            Item.Get("Item No.");
            if Item."Item Tracking Code" <> '' then
                ItemTrackingCode.Get(Item."Item Tracking Code")
            else
                ItemTrackingCode.Init();
        end;
        case ItemTrackingType of
            ItemTrackingType::"Lot No.":
                begin
                    if not ItemTrackingCode."Lot Specific Tracking" then
                        exit(false);
                    FieldValue := "Lot No.";
                end;
            ItemTrackingType::"Serial No.":
                begin
                    if not ItemTrackingCode."SN Specific Tracking" then
                        exit(false);
                    FieldValue := "Serial No.";
                end;
            else
                Error(Text004);
        end;

        // The field "Lot No." is used a foundation for building up the filter:

        if FieldValue <> '' then begin
            if SearchForSupply then // Demand
                ItemTrackingSetup.SetRange("Lot No.", FieldValue)
            else // Supply
                ItemTrackingSetup.SetFilter("Lot No.", '%1|%2', FieldValue, '');
            FieldFilter := ItemTrackingSetup.GetFilter("Lot No.");
        end else // FieldValue = ''
            if SearchForSupply then // Demand
                exit(false)
            else
                FieldFilter := StrSubstNo('''%1''', '');

        exit(true);
    end;

    procedure GetAvailabilityFilter(AvailabilityDate: Date; Positive: Boolean): Text
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if Positive then
            ReservEntry.SetFilter("Expected Receipt Date", '..%1', AvailabilityDate)
        else
            ReservEntry.SetFilter("Expected Receipt Date", '>=%1', AvailabilityDate);

        exit(ReservEntry.GetFilter("Expected Receipt Date"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromInvtProfile(var ReservationEntry: Record "Reservation Entry"; InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntryNewTracking(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivLine(var ReservationEntry: Record "Reservation Entry"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var ReservationEntry: Record "Reservation Entry"; WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearItemTrackingFields(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearNewTracking(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFromTrackingSpecification(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterBlank(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var ReservationEntry: Record "Reservation Entry"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseJnlLine(var ReservationEntry: Record "Reservation Entry"; WhseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseSpec(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTextCaption(SourceType: Integer; var NewTextCaption: Text[255])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearItemTrackingFields(ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemFields(ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

