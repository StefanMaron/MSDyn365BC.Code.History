table 6550 "Whse. Item Tracking Line"
{
    Caption = 'Whse. Item Tracking Line';

    fields
    {
        field(1; "Entry No."; Integer)
        {
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
                if "Quantity (Base)" < 0 then
                    FieldError("Quantity (Base)", Text004);

                if "Quantity (Base)" < "Quantity Handled (Base)" then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Quantity Handled (Base)")));

                CheckSerialNoQty;

                InitQtyToHandle;
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
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
        field(24; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                if "Serial No." <> xRec."Serial No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass("Source Type", "Source Batch Name") then
                        "New Serial No." := "Serial No.";
                    CheckSerialNoQty;
                    InitExpirationDate;
                end;
            end;
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(40; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                "New Expiration Date" := "Expiration Date";
            end;
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Handle (Base)" < 0 then
                    FieldError("Qty. to Handle (Base)", Text004);

                if "Qty. to Handle (Base)" > ("Quantity (Base)" - "Quantity Handled (Base)")
                then
                    Error(
                      Text001,
                      "Quantity (Base)" - "Quantity Handled (Base)");

                "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");
            end;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(52; "Quantity Handled (Base)"; Decimal)
        {
            Caption = 'Quantity Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Buffer Status"; Option)
        {
            Caption = 'Buffer Status';
            Editable = false;
            OptionCaption = ' ,MODIFY';
            OptionMembers = " ",MODIFY;
        }
        field(71; "Buffer Status2"; Option)
        {
            Caption = 'Buffer Status2';
            Editable = false;
            OptionCaption = ',ExpDate blocked';
            OptionMembers = ,"ExpDate blocked";
        }
        field(80; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
        }
        field(81; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
        }
        field(90; "Source Type Filter"; Option)
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Movement Worksheet,Assembly';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet",Assembly;
        }
        field(91; "Qty. Registered (Base)"; Decimal)
        {
            Caption = 'Qty. Registered (Base)';
        }
        field(92; "Put-away Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = FILTER("Put-away"),
                                                                                         "Whse. Document Type" = FIELD("Source Type Filter"),
                                                                                         "Whse. Document No." = FIELD("Source ID"),
                                                                                         "Whse. Document Line No." = FIELD("Source Ref. No."),
                                                                                         "Serial No." = FIELD("Serial No."),
                                                                                         "Lot No." = FIELD("Lot No."),
                                                                                         "Action Type" = FILTER(" " | Take)));
            Caption = 'Put-away Qty. (Base)';
            FieldClass = FlowField;
        }
        field(93; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = FILTER(Pick | Movement),
                                                                                         "Whse. Document Type" = FIELD("Source Type Filter"),
                                                                                         "Whse. Document No." = FIELD("Source ID"),
                                                                                         "Whse. Document Line No." = FIELD("Source Ref. No."),
                                                                                         "Serial No." = FIELD("Serial No."),
                                                                                         "Lot No." = FIELD("Lot No."),
                                                                                         "Action Type" = FILTER(" " | Place)));
            Caption = 'Pick Qty. (Base)';
            FieldClass = FlowField;
        }
        field(94; "Created by Whse. Activity Line"; Boolean)
        {
            Caption = 'Created by Whse. Activity Line';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                if "Lot No." <> xRec."Lot No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass("Source Type", "Source Batch Name") then
                        "New Lot No." := "Lot No.";
                    InitExpirationDate;
                end;
            end;
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(6505; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.", "Location Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)";
        }
        key(Key3; "Serial No.", "Lot No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Quantity Handled (Base)", 0);
    end;

    var
        Text001: Label 'You cannot handle more than %1 units.';
        Text002: Label 'must not be less than %1';
        Text003: Label '%1 must be 0 or 1 when %2 is stated.';
        Text004: Label 'must not be negative';
        UOMMgt: Codeunit "Unit of Measure Management";

    local procedure CheckSerialNoQty()
    begin
        if "Serial No." <> '' then
            if not ("Quantity (Base)" in [0, 1]) then
                Error(Text003, FieldCaption("Quantity (Base)"), FieldCaption("Serial No."));
    end;

    local procedure CalcQty(BaseQty: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        exit(Round(BaseQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    procedure InitQtyToHandle()
    begin
        "Qty. to Handle (Base)" := "Quantity (Base)" - "Quantity Handled (Base)";
        "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");

        OnAfterInitQtyToHandle(Rec, xRec, CurrFieldNo);
    end;

    procedure InitExpirationDate()
    var
        Location: Record Location;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        WarDate: Date;
    begin
        if ("Serial No." = xRec."Serial No.") and ("Lot No." = xRec."Lot No.") then
            exit;

        "Expiration Date" := 0D;
        "Buffer Status2" := 0;

        Location.Init;
        if "Location Code" <> '' then
            Location.Get("Location Code");

        if ItemTrackingMgt.GetWhseExpirationDate("Item No.", "Variant Code", Location, "Lot No.", "Serial No.", ExpDate) then begin
            "Expiration Date" := ExpDate;
            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
        end;

        if IsReclass("Source Type", "Source Batch Name") then begin
            "New Expiration Date" := "Expiration Date";
            if ItemTrackingMgt.GetWhseWarrantyDate("Item No.", "Variant Code", Location, "Lot No.", "Serial No.", WarDate) then
                "Warranty Date" := WarDate;
        end;
    end;

    procedure IsReclass(SourceType: Integer; SourceBatchName: Code[10]): Boolean
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        if SourceType = DATABASE::"Warehouse Journal Line" then
            exit(WhseJnlLine.IsReclass(SourceBatchName));

        exit(false);
    end;

    procedure LookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Option SerialNo,LotNo; MaxQuantity: Decimal; SignFactor: Integer; SearchForSupply: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
        InternalMovementLine: Record "Internal Movement Line";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpTrackingSummary(WhseItemTrackingLine, TrackingType, MaxQuantity, SignFactor, true, IsHandled);
        if IsHandled then
            exit;

        with WhseItemTrackingLine do begin
            case "Source Type" of
                DATABASE::"Warehouse Journal Line":
                    begin
                        WhseJnlLine.Get("Source Batch Name", "Source ID", "Location Code", "Source Ref. No.");
                        BinCode := WhseJnlLine."Bin Code";
                    end;
                DATABASE::"Whse. Worksheet Line":
                    begin
                        WhseWorksheetLine.Get("Source Batch Name", "Source ID", "Location Code", "Source Ref. No.");
                        BinCode := WhseWorksheetLine."From Bin Code";
                    end;
                DATABASE::"Whse. Internal Put-away Line":
                    begin
                        WhseInternalPutawayLine.Get("Source ID", "Source Ref. No.");
                        BinCode := WhseInternalPutawayLine."From Bin Code";
                    end;
                DATABASE::"Internal Movement Line":
                    begin
                        InternalMovementLine.Get("Source ID", "Source Ref. No.");
                        BinCode := InternalMovementLine."From Bin Code";
                    end;
                else
                    exit;
            end;

            TempTrackingSpecification.Init;
            TempTrackingSpecification.SetItemData(
              "Item No.", Description, "Location Code", "Variant Code", BinCode, "Qty. per Unit of Measure");
            TempTrackingSpecification.SetSource(
              "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Batch Name", "Source Prod. Order Line");
            TempTrackingSpecification."Quantity (Base)" := "Quantity (Base)";
            TempTrackingSpecification."Qty. to Handle" := "Qty. to Handle";
            TempTrackingSpecification."Qty. to Handle (Base)" := "Qty. to Handle (Base)";
            Clear(ItemTrackingDataCollection);
            ItemTrackingDataCollection.AssistEditTrackingNo(
              TempTrackingSpecification, SearchForSupply, SignFactor, TrackingType, MaxQuantity);
            Validate("Quantity (Base)", TempTrackingSpecification."Quantity (Base)");
            case TrackingType of
                TrackingType::SerialNo:
                    if TempTrackingSpecification."Serial No." <> '' then
                        Validate("Serial No.", TempTrackingSpecification."Serial No.");
                TrackingType::LotNo:
                    if TempTrackingSpecification."Lot No." <> '' then
                        Validate("Lot No.", TempTrackingSpecification."Lot No.");
            end;
        end;

        OnAfterLookUpTrackingSummary(WhseItemTrackingLine, TrackingType, TempTrackingSpecification);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";
        "Warranty Date" := ItemLedgerEntry."Warranty Date";
        "Expiration Date" := ItemLedgerEntry."Expiration Date";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";
        "Warranty Date" := ReservEntry."Warranty Date";
        "Expiration Date" := ReservEntry."Expiration Date";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
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
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
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
        if SourceProdOrderLine >= 0 then
            SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetTracking(SerialNo: Code[50]; LotNo: Code[50]; WarrantyDate: Date; ExpirationDate: Date)
    begin
        "Serial No." := SerialNo;
        "Lot No." := LotNo;
        "Warranty Date" := WarrantyDate;
        "Expiration Date" := ExpirationDate;
    end;

    procedure SetTrackingFilter(SerialNo: Code[50]; LotNo: Code[50])
    begin
        SetRange("Serial No.", SerialNo);
        SetRange("Lot No.", LotNo);
    end;

    procedure SetTrackingFilterFromRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        SetRange("Serial No.", WhseItemEntryRelation."Serial No.");
        SetRange("Lot No.", WhseItemEntryRelation."Lot No.");
    end;

    procedure SetTrackingFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservEntry."Serial No.");
        SetRange("Lot No.", ReservEntry."Lot No.");
    end;

    procedure SetTrackingFilterFromSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No.", WhseItemTrackingLine."Lot No.");
    end;

    procedure TrackingExists(): Boolean
    begin
        exit(("Lot No." <> '') or ("Serial No." <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToHandle(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; xWhseItemTrackingLine: Record "Whse. Item Tracking Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Option SerialNo,LotNo; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Option SerialNo,LotNo; MaxQuantity: Decimal; SignFactor: Integer; SearchForSupply: Boolean; var IsHandled: Boolean)
    begin
    end;
}

