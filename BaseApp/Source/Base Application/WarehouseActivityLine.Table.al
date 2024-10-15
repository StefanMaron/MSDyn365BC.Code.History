﻿table 5767 "Warehouse Activity Line"
{
    Caption = 'Warehouse Activity Line';
    DrillDownPageID = "Warehouse Activity Lines";
    LookupPageID = "Warehouse Activity Lines";
    Permissions = TableData "Whse. Item Tracking Line" = rmd;

    fields
    {
        field(1; "Activity Type"; Enum "Warehouse Activity Type")
        {
            Caption = 'Activity Type';
            Editable = false;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(5; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            Editable = false;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure;
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                    OnValidateItemNoOnAfterValidateUoMCode(Rec, Item, CurrFieldNo);
                end else begin
                    Description := '';
                    "Description 2" := '';
                    "Variant Code" := '';
                    Validate("Unit of Measure Code", '');
                end;
            end;
        }
        field(15; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVariantCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Variant Code" = '' then
                    Validate("Item No.")
                else begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    IsHandled := false;
                    OnValidateVariantCodeOnAfterGetItemVariant(Rec, ItemVariant, IsHandled);
                    if not IsHandled then begin
                        Description := ItemVariant.Description;
                        "Description 2" := ItemVariant."Description 2";
                    end;
                end;
            end;
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure;
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                    "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                end else
                    "Qty. per Unit of Measure" := 1;

                Validate(Quantity);
                Validate("Qty. Outstanding");
                Validate("Qty. to Handle");
            end;
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Qty. (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
                Validate("Qty. Outstanding", (Quantity - "Qty. Handled"));
            end;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Qty. (Base)");
            end;
        }
        field(24; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyOutstanding(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;
                "Qty. Outstanding" := UOMMgt.RoundAndValidateQty("Qty. Outstanding", "Qty. Rounding Precision", FieldCaption("Qty. Outstanding"));
                "Qty. Outstanding (Base)" :=
                    CalcBaseQty("Qty. Outstanding", FieldCaption("Qty. Outstanding"), FieldCaption("Qty. Outstanding (Base)"));
                Validate("Qty. to Handle", "Qty. Outstanding");
            end;
        }
        field(25; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. Outstanding", "Qty. Outstanding (Base)");
            end;
        }
        field(26; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                QtyToHandleBase: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToHandle(Rec, IsHandled);
                if not IsHandled then
                    if "Qty. to Handle" > "Qty. Outstanding" then
                        Error(Text002, "Qty. Outstanding");

                GetLocation("Location Code");
                if Location."Directed Put-away and Pick" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Handle", Cubage, Weight);

                if (CurrFieldNo <> 0) and
                   ("Action Type" = "Action Type"::Place) and
                   ("Breakbulk No." = 0) and
                   ("Qty. to Handle" > 0) and
                   Location."Directed Put-away and Pick"
                then
                    if GetBin("Location Code", "Bin Code") then
                        CheckIncreaseCapacity(true);

                OnValidateQtyToHandleOnBeforeCalcQtyToHandleBase(Rec, xRec, Location, CurrFieldNo);

                if not UseBaseQty then begin
                    "Qty. to Handle" :=
                        UOMMgt.RoundAndValidateQty("Qty. to Handle", "Qty. Rounding Precision", FieldCaption("Qty. to Handle"));
                    "Qty. to Handle (Base)" :=
                        CalcBaseQty("Qty. to Handle", FieldCaption("Qty. to Handle"), FieldCaption("Qty. to Handle (Base)"));

                    if (("Qty. to Handle" = "Qty. Outstanding") and ("Qty. to Handle (Base)" < "Qty. Outstanding (Base)")) then // Rounding fix (Round Down)- Qty same, not Base Qty
                        "Qty. to Handle (Base)" := "Qty. Outstanding (Base)";

                    if "Qty. to Handle (Base)" > "Qty. Outstanding (Base)" then begin // Rounding fix (Round Up)- Qty same, not Base Qty
                        QtyToHandleBase := "Qty. Outstanding (Base)";
                        OnValidateQtyToHandleOnAfterCalcQtyToHandleBase(Rec, "Qty. To Handle (Base)", QtyToHandleBase);
                        "Qty. to Handle (Base)" := QtyToHandleBase;
                    end;
                    ValidateQuantityIsBalanced();
                end;

                if ("Activity Type" = "Activity Type"::"Put-away") and
                   ("Action Type" = "Action Type"::Take) and
                   (CurrFieldNo <> 0)
                then
                    if ("Breakbulk No." <> 0) or "Original Breakbulk" then
                        UpdateBreakbulkQtytoHandle;

                if ("Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"]) and
                   ("Action Type" <> "Action Type"::Place) and ("Lot No." <> '') and (CurrFieldNo <> 0)
                then
                    CheckReservedItemTrkg(ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(27; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                UseBaseQty := true;
                Validate("Qty. to Handle", CalcQty("Qty. to Handle (Base)"));
            end;
        }
        field(28; "Qty. Handled"; Decimal)
        {
            Caption = 'Qty. Handled';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Handled" := UOMMgt.RoundAndValidateQty("Qty. Handled", "Qty. Rounding Precision", FieldCaption("Qty. Handled"));
                "Qty. Handled (Base)" :=
                    CalcBaseQty("Qty. Handled", FieldCaption("Qty. Handled"), FieldCaption("Qty. Handled (Base)"));
            end;
        }
        field(29; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(31; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
            FieldClass = Normal;
        }
        field(34; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            Editable = false;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = IF ("Destination Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Destination Type" = CONST(Customer)) Customer
            ELSE
            IF ("Destination Type" = CONST(Location)) Location
            ELSE
            IF ("Destination Type" = CONST(Item)) Item
            ELSE
            IF ("Destination Type" = CONST(Family)) Family
            ELSE
            IF ("Destination Type" = CONST("Sales Order")) "Sales Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(50; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(51; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(900; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
        }
        field(901; "ATO Component"; Boolean)
        {
            Caption = 'ATO Component';
            Editable = false;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent, -1, ItemTrackingType::"Serial No.");
            end;

            trigger OnValidate()
            var
                WhseItemTrackingSetup: Record "Item Tracking Setup";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSerialNo(Rec, IsHandled);
                if IsHandled then
                    exit;
                if "Serial No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
                    TestField("Qty. (Base)", 1);

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg(ItemTrackingType::"Serial No.", "Serial No.");

                    CheckSNSpecificationExists;

                    ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
                    if WhseItemTrackingSetup."Serial No. Required" and WhseItemTrackingSetup."Lot No. Required" then
                        FindLotNoBySerialNo;
                end;

                if "Serial No." <> xRec."Serial No." then
                    "Expiration Date" := 0D;
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent(), -1, ItemTrackingType::"Lot No.");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateLotNo(Rec);
                if "Lot No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg(ItemTrackingType::"Lot No.", "Lot No.");
                end;

                if "Lot No." <> xRec."Lot No." then
                    "Expiration Date" := 0D;
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            var
                WhseActivLine: Record "Warehouse Activity Line";
            begin
                if "Lot No." <> '' then
                    with WhseActivLine do begin
                        Reset;
                        SetCurrentKey("No.", "Line No.", "Activity Type");
                        SetRange("No.", Rec."No.");
                        SetRange("Item No.", Rec."Item No.");
                        SetRange("Lot No.", Rec."Lot No.");

                        if FindSet() then
                            repeat
                                if ("Line No." <> Rec."Line No.") and ("Expiration Date" <> Rec."Expiration Date") and
                                   (Rec."Expiration Date" <> 0D) and ("Expiration Date" <> 0D)
                                then
                                    Rec.FieldError("Expiration Date");
                            until Next() = 0;
                    end;
            end;
        }
        field(6504; "Serial No. Blocked"; Boolean)
        {
            CalcFormula = Lookup("Serial No. Information".Blocked WHERE("Item No." = FIELD("Item No."),
                                                                         "Variant Code" = FIELD("Variant Code"),
                                                                         "Serial No." = FIELD("Serial No.")));
            Caption = 'Serial No. Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6505; "Lot No. Blocked"; Boolean)
        {
            CalcFormula = Lookup("Lot No. Information".Blocked WHERE("Item No." = FIELD("Item No."),
                                                                      "Variant Code" = FIELD("Variant Code"),
                                                                      "Lot No." = FIELD("Lot No.")));
            Caption = 'Lot No. Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent(), -1, "Item Tracking Type"::"Package No.");
            end;

            trigger OnValidate()
            begin
                if "Package No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg("Item Tracking Type"::"Package No.", "Package No.");
                end;
            end;
        }
        field(7300; "Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));

            trigger OnLookup()
            var
                BinCode: Code[20];
            begin
                BinCode := FindBinCode();

                if BinCode <> '' then begin
                    Validate("Bin Code", BinCode);
                    Modify;
                end;
            end;

            trigger OnValidate()
            var
                BinContent: Record "Bin Content";
                BinType: Record "Bin Type";
                WhseItemTrackingLine: Record "Whse. Item Tracking Line";
                QtyAvailBase: Decimal;
                AvailableQtyBase: Decimal;
                UOMCode: Code[10];
                NewBinCode: Code[20];
                IsHandled: Boolean;
            begin
                CheckBinInSourceDoc;

                if "Bin Code" <> '' then
                    FindBinContent();

                if "Bin Code" <> xRec."Bin Code" then begin
                    CheckInvalidBinCode;
                    IsHandled := false;
                    OnValidateBinCodeOnAfterCheckInvalidBinCode(Rec, xRec, CurrFieldNo, IsHandled);
                    if IsHandled then
                        exit;
                    if GetBin("Location Code", "Bin Code") then begin
                        if CurrFieldNo <> 0 then begin
                            if ("Activity Type" = "Activity Type"::"Put-away") and
                               ("Breakbulk No." <> 0)
                            then
                                Error(Text005, FieldCaption("Bin Code"));
                            CheckWhseDocLine;
                            if "Action Type" = "Action Type"::Take then begin
                                if (("Whse. Document Type" <> "Whse. Document Type"::Receipt) and
                                    (Bin."Bin Type Code" <> ''))
                                then
                                    if BinType.Get(Bin."Bin Type Code") then
                                        BinType.TestField(Receive, false);
                                GetLocation("Location Code");
                                UOMCode := GetUOMCode();
                                NewBinCode := "Bin Code";
                                if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", UOMCode) then begin
                                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Movement"] then
                                        QtyAvailBase := BinContent.CalcQtyAvailToPick(0)
                                    else
                                        QtyAvailBase := BinContent.CalcQtyAvailToTake(0);
                                    if Location."Directed Put-away and Pick" then begin
                                        CreatePick.SetCrossDock(Bin."Cross-Dock Bin");
                                        WhseItemTrackingLine.CopyTrackingFromWhseActivityLine(Rec);
                                        AvailableQtyBase :=
                                          CreatePick.CalcTotalAvailQtyToPick(
                                            "Location Code", "Item No.", "Variant Code", WhseItemTrackingLine,
                                            "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", 0, false);
                                        AvailableQtyBase += "Qty. Outstanding (Base)";
                                        if AvailableQtyBase < 0 then
                                            AvailableQtyBase := 0;

                                        if AvailableQtyBase = 0 then
                                            Error(Text015);
                                    end else
                                        AvailableQtyBase := QtyAvailBase;

                                    if AvailableQtyBase < QtyAvailBase then
                                        QtyAvailBase := AvailableQtyBase;

                                    OnValidateBinCodeOnAfterCalcQtyAvailBase(Rec, QtyAvailBase, NewBinCode);
                                end;

                                CheckExceedQtyAvailBase(BinContent, QtyAvailBase, NewBinCode);
                            end else begin
                                if "Qty. to Handle" > 0 then
                                    CheckIncreaseCapacity(false);
                                xRec.DeleteBinContent("Warehouse Action Type"::Place.AsInteger());
                            end;
                        end;
                        Dedicated := Bin.Dedicated;
                        if Location."Directed Put-away and Pick" then begin
                            "Bin Ranking" := Bin."Bin Ranking";
                            "Bin Type Code" := Bin."Bin Type Code";
                            "Zone Code" := Bin."Zone Code";
                        end;
                        OnValidateBinCodeOnAfterGetBin(Rec, Bin);
                    end else begin
                        xRec.DeleteBinContent(xRec."Action Type"::Place.AsInteger());
                        Dedicated := false;
                        "Bin Ranking" := 0;
                        "Bin Type Code" := '';
                    end;
                end;
            end;
        }
        field(7301; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if xRec."Zone Code" <> "Zone Code" then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                    xRec.DeleteBinContent(xRec."Action Type"::Place.AsInteger());
                    "Bin Code" := '';
                    "Bin Ranking" := 0;
                    "Bin Type Code" := '';
                end;
            end;
        }
        field(7305; "Action Type"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type';
            Editable = false;
        }
        field(7306; "Whse. Document Type"; Enum "Warehouse Activity Document Type")
        {
            Caption = 'Whse. Document Type';
            Editable = false;
        }
        field(7307; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            Editable = false;
            TableRelation = IF ("Whse. Document Type" = CONST(Receipt)) "Posted Whse. Receipt Header"."No." WHERE("No." = FIELD("Whse. Document No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Shipment)) "Warehouse Shipment Header"."No." WHERE("No." = FIELD("Whse. Document No."))
            ELSE
            IF ("Whse. Document Type" = CONST("Internal Put-away")) "Whse. Internal Put-away Header"."No." WHERE("No." = FIELD("Whse. Document No."))
            ELSE
            IF ("Whse. Document Type" = CONST("Internal Pick")) "Whse. Internal Pick Header"."No." WHERE("No." = FIELD("Whse. Document No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Production)) "Production Order"."No." WHERE("No." = FIELD("Whse. Document No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Assembly)) "Assembly Header"."No." WHERE("Document Type" = CONST(Order),
                                                                                                           "No." = FIELD("Whse. Document No."));
        }
        field(7308; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
            Editable = false;
            TableRelation = IF ("Whse. Document Type" = CONST(Receipt)) "Posted Whse. Receipt Line"."Line No." WHERE("No." = FIELD("Whse. Document No."),
                                                                                                                    "Line No." = FIELD("Whse. Document Line No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Shipment)) "Warehouse Shipment Line"."Line No." WHERE("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                "Line No." = FIELD("Whse. Document Line No."))
            ELSE
            IF ("Whse. Document Type" = CONST("Internal Put-away")) "Whse. Internal Put-away Line"."Line No." WHERE("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                            "Line No." = FIELD("Whse. Document Line No."))
            ELSE
            IF ("Whse. Document Type" = CONST("Internal Pick")) "Whse. Internal Pick Line"."Line No." WHERE("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                "Line No." = FIELD("Whse. Document Line No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Production)) "Prod. Order Line"."Line No." WHERE("Prod. Order No." = FIELD("No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       "Line No." = FIELD("Line No."))
            ELSE
            IF ("Whse. Document Type" = CONST(Assembly)) "Assembly Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         "Document No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         "Line No." = FIELD("Whse. Document Line No."));
        }
        field(7309; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
            Editable = false;
        }
        field(7310; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(7311; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(7313; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(7314; "Breakbulk No."; Integer)
        {
            BlankZero = true;
            Caption = 'Breakbulk No.';
        }
        field(7315; "Original Breakbulk"; Boolean)
        {
            Caption = 'Original Breakbulk';
        }
        field(7316; Breakbulk; Boolean)
        {
            Caption = 'Breakbulk';
        }
        field(7317; "Cross-Dock Information"; Option)
        {
            Caption = 'Cross-Dock Information';
            OptionCaption = ' ,Cross-Dock Items,Some Items Cross-Docked';
            OptionMembers = " ","Cross-Dock Items","Some Items Cross-Docked";
        }
        field(7318; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Activity Type", "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Line No.", "Activity Type")
        {
        }
        key(Key3; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk", "Activity Type", "Assemble to Order")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding", "Qty. Outstanding (Base)";
        }
        key(Key4; "Activity Type", "No.", "Sorting Sequence No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Activity Type", "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Activity Type", "No.", "Location Code", "Source Document", "Source No.", "Action Type", "Zone Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "Activity Type", "No.", "Due Date", "Action Type", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key8; "Activity Type", "No.", "Bin Code", "Breakbulk No.", "Action Type")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Activity Type", "No.", "Bin Ranking", "Breakbulk No.", "Action Type")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Activity Type", "No.", "Destination Type", "Destination No.", "Action Type", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key12; "Activity Type", "No.", "Action Type", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key13; "Activity Type", "No.", "Item No.", "Variant Code", "Action Type", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
#pragma warning disable AS0009
        key(Key14; "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type", "Unit of Measure Code", "Original Breakbulk", "Breakbulk No.", "Lot No.", "Serial No.", "Assemble to Order", "Package No.")
#pragma warning restore AS0009
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)", "Qty. Outstanding";
        }
        key(Key15; "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.", "Original Breakbulk", "Assemble to Order", "ATO Component")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Quantity, "Qty. (Base)", "Qty. Outstanding", "Qty. Outstanding (Base)", Cubage, Weight;
        }
#pragma warning disable AS0009
        key(Key16; "Item No.", "Location Code", "Activity Type", "Bin Type Code", "Unit of Measure Code", "Variant Code", "Breakbulk No.", "Action Type", "Lot No.", "Serial No.", "Assemble to Order", "Package No.")
#pragma warning restore AS0009
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)";
        }
        key(Key17; "Bin Code", "Location Code", "Action Type", "Breakbulk No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = Cubage, Weight;
        }
        key(Key18; "Location Code", "Activity Type")
        {
        }
#pragma warning disable AS0009
        key(Key19; "Source No.", "Source Line No.", "Source Subline No.", "Serial No.", "Lot No.", "Package No.")
#pragma warning restore AS0009
        {
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteRelatedWhseActivLines(Rec, false);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot handle more than the outstanding %1 units.';
        Text003: Label 'must not be %1';
        Text004: Label 'If you delete %1 %2, %3 %4, %5 %6\the quantity to %7 will be imbalanced.\Do you still want to delete the %8?';
        Text005: Label 'You must not change the %1 in breakbulk lines.';
        Text006: Label 'The update was interrupted to respect the warning.';
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        WMSMgt: Codeunit "WMS Management";
        CreatePick: Codeunit "Create Pick";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingType: Enum "Item Tracking Type";
        Text007: Label 'You must not split breakbulk lines.';
        Text008: Label 'Quantity available to pick is not enough to fill in all the lines.';
        Text009: Label 'If you delete the %1\you must recreate related Warehouse Worksheet Lines manually.\\Do you want to delete the %1?';
        Text011: Label 'You cannot enter the %1 of the %2 as %3.';
        Text012: Label 'The %1 %2 exceeds the quantity available to pick %3 of the %4.\Do you still want to enter this %5?';
        Text013: Label 'All related Warehouse Activity Lines are deleted.';
        Text014: Label '%1 %2 has already been reserved for another document.';
        Text015: Label 'The total available quantity has already been applied.';
        InventoryNotAvailableErr: Label '%1 %2 is not available in inventory, it has already been reserved for another document, or the quantity available is lower than the quantity to handle specified on the line.', Comment = '%1 = CD No. Caption; %2 = CD No. Value';
        UseBaseQty: Boolean;
        Text018: Label '%1 already exists with %2 %3.', Comment = 'Warehouse Activity Line already exists with Serial No. XXX';
        Text019: Label 'The %1 bin code must be different from the %2 bin code on location %3.';
        Text020: Label 'The %1 bin code must not be the Receipt Bin Code or the Shipment Bin Code that are set up on location %2.';
        ValidValuesIfSNDefinedErr: Label 'Field %1 can only have values -1, 0 or 1 when serial no. is defined. Current value is %2.', Comment = '%1 = field name, %2 = field value';

    procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        OnBeforeCalcQty(Rec, QtyBase);
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    procedure AutofillQtyToHandle(var WhseActivLine: Record "Warehouse Activity Line")
    var
        NotEnough: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutofillQtyToHandle(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        with WhseActivLine do begin
            NotEnough := false;
            if Find('-') then
                repeat
                    Validate("Qty. to Handle", "Qty. Outstanding");
                    if "Qty. to Handle (Base)" <> "Qty. Outstanding (Base)" then
                        Validate("Qty. to Handle (Base)", "Qty. Outstanding (Base)");
                    Modify;
                    OnAfterAutofillQtyToHandleLine(WhseActivLine);

                    if not NotEnough then
                        if "Qty. to Handle" < "Qty. Outstanding" then
                            NotEnough := true;
                until Next() = 0;

            if NotEnough then
                Message(Text008);
        end;

        OnAfterAutofillQtyToHandle(WhseActivLine);
    end;

    procedure DeleteQtyToHandle(var WhseActivLine: Record "Warehouse Activity Line")
    begin
        OnBeforeDeleteQtyToHandle(WhseActivLine);
        with WhseActivLine do begin
            if Find('-') then
                repeat
                    Validate("Qty. to Handle", 0);
                    Modify;
                    OnAfterUpdateQtyToHandleWhseActivLine(WhseActivLine);
                until Next() = 0;
        end;
        OnAfterDeleteQtyToHandle(WhseActivLine);
    end;

    local procedure GetItem()
    begin
        if Item."No." = "Item No." then
            exit;

        Item.Get("Item No.");
        if Item."Item Tracking Code" <> '' then
            ItemTrackingCode.Get(Item."Item Tracking Code")
        else
            Clear(ItemTrackingCode);
    end;

    procedure DeleteRelatedWhseActivLines(WhseActivLine: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        Confirmed: Boolean;
        DeleteLineConfirmed: Boolean;
    begin
        OnBeforeDeleteRelatedWhseActivLines(WhseActivLine, CalledFromHeader);

        with WhseActivLine do begin
            if ("Activity Type" in ["Activity Type"::"Invt. Put-away", "Activity Type"::"Invt. Pick"]) and
               (not CalledFromHeader)
            then
                exit;

            WhseActivLine2.SetCurrentKey(
              "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            WhseActivLine2.SetRange("Activity Type", "Activity Type");
            WhseActivLine2.SetRange("No.", "No.");
            WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            if WhseActivLine2.Find('-') then
                repeat
                    Confirmed := ConfirmWhseActivLinesDeletionRecreate(WhseActivLine2, WhseWkshLine);
                until (WhseActivLine2.Next() = 0) or Confirmed;

            OnDeleteRelatedWhseActivLinesOnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine, CalledFromHeader, DeleteLineConfirmed);
            if DeleteLineConfirmed then
                exit;

            if (not CalledFromHeader) and ("Action Type" <> "Action Type"::" ") then begin
                ConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine, WhseActivLine2, DeleteLineConfirmed);
                if DeleteLineConfirmed then
                    exit;
            end;

            if not CalledFromHeader then
                if "Action Type" <> "Action Type"::" " then
                    WhseActivLine2.SetFilter("Line No.", '<>%1', "Line No.")
                else
                    WhseActivLine2.SetRange("Line No.", "Line No.");
            OnDeleteRelatedWhseActivLinesOnBeforeWhseActivLine2Find(WhseActivLine, WhseActivLine2);
            if WhseActivLine2.Find('-') then
                repeat
                    OnDeleteRelatedWhseActivLinesOnBeforeDeleteWhseActivLine2(WhseActivLine, WhseActivLine2, CalledFromHeader);
                    DeleteWhseActivLine2(WhseActivLine2, CalledFromHeader);
                    WhseActivLine2.DeleteBinContent("Warehouse Action Type"::Place.AsInteger());
                    UpdateRelatedItemTrkg(WhseActivLine2);
                until WhseActivLine2.Next() = 0;

            if (not CalledFromHeader) and ("Action Type" <> "Action Type"::" ") then
                ShowDeletedMessage(WhseActivLine);
        end;
    end;

    local procedure DeleteWhseActivLine2(var WhseActivLine2: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteWhseActivLine2(WhseActivLine2, CalledFromHeader, IsHandled);
        if IsHandled then
            exit;

        WhseActivLine2.Delete(); // to ensure correct item tracking update
    end;

    procedure CheckWhseDocLine()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ProdOrderCompLine: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        WhseDocType2: Enum "Warehouse Activity Document Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocLine(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Bin Code" <> '' then begin
            if "Breakbulk No." <> 0 then
                exit;
            if ("Activity Type" = "Activity Type"::Pick) and
               ("Action Type" = "Action Type"::Place)
            then begin
                if ("Whse. Document Type" = "Whse. Document Type"::Shipment) and "Assemble to Order" then
                    WhseDocType2 := "Whse. Document Type"::Assembly
                else
                    WhseDocType2 := "Whse. Document Type";
                case WhseDocType2 of
                    "Whse. Document Type"::Shipment:
                        begin
                            WhseShptLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            CheckBinCodeFromWhseShptLine(WhseShptLine);
                        end;
                    "Whse. Document Type"::"Internal Pick":
                        begin
                            WhseInternalPickLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", WhseInternalPickLine."To Bin Code");
                        end;
                    "Whse. Document Type"::Production:
                        begin
                            GetLocation("Location Code");
                            if Location."Directed Put-away and Pick" then begin
                                ProdOrderCompLine.Get("Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                                CheckBinCodeFromProdOrderCompLine(ProdOrderCompLine);
                            end;
                        end;
                    "Whse. Document Type"::Assembly:
                        begin
                            GetLocation("Location Code");
                            if Location."Directed Put-away and Pick" then begin
                                AssemblyLine.Get("Source Subtype", "Source No.", "Source Line No.");
                                TestField("Bin Code", AssemblyLine."Bin Code");
                            end;
                        end;
                end;
            end;
            if ("Activity Type" = "Activity Type"::"Put-away") and
               ("Action Type" = "Action Type"::Take)
            then
                case "Whse. Document Type" of
                    "Whse. Document Type"::Receipt:
                        begin
                            PostedWhseRcptLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", PostedWhseRcptLine."Bin Code");
                        end;
                    "Whse. Document Type"::"Internal Put-away":
                        begin
                            WhseInternalPutAwayLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", WhseInternalPutAwayLine."From Bin Code");
                        end;
                end;
        end;
    end;

    procedure CheckBinInSourceDoc()
    var
        ProdOrderComponentLine: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        if not (("Activity Type" = "Activity Type"::"Invt. Movement") and
                ("Action Type" = "Action Type"::Place) and
                ("Source Type" <> 0))
        then
            exit;

        IsHandled := false;
        OnBeforeCheckBinInSourceDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Source Type" of
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComponentLine.Get(
                      "Source Subtype", "Source No.",
                      "Source Line No.", "Source Subline No.");
                    TestField("Bin Code", ProdOrderComponentLine."Bin Code");
                end;
            DATABASE::"Assembly Line":
                begin
                    AssemblyLine.Get(
                      "Source Subtype", "Source No.",
                      "Source Line No.");
                    TestField("Bin Code", AssemblyLine."Bin Code");
                end;
            DATABASE::Job:
                begin
                    JobPlanningLine.SetRange("Job Contract Entry No.", "Source Line No.");
                    JobPlanningLine.SetLoadFields("Bin Code");
                    if JobPlanningLine.FindFirst() then
                        TestField("Bin Code", JobPlanningLine."Bin Code");
                end;
        end;
    end;

    procedure GetBin(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then begin
            GetLocation(LocationCode);
            if not Location."Directed Put-away and Pick" then
                exit(true);
            if Bin.Get(LocationCode, BinCode) then begin
                CheckBin;
                exit(true);
            end;
            exit(false);
        end;

        CheckBin;
        exit(true);
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem;
        Item.TestField("No.");
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetUOMCode() UOMCode: Code[10];
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUOMCode(Rec, UOMCode, IsHandled, Location);
        if IsHandled then
            exit(UOMCode);

        if Location."Directed Put-away and Pick" then
            UOMCode := "Unit of Measure Code"
        else
            UOMCode := WMSMgt.GetBaseUOM("Item No.");
    end;

    local procedure CheckBin()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Bin, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        Location.TestField("Directed Put-away and Pick");
        if Location."Adjustment Bin Code" <> '' then
            if "Bin Code" = Location."Adjustment Bin Code" then
                Error(
                  Text011,
                  Location.FieldCaption("Adjustment Bin Code"), Location.TableCaption,
                  FieldCaption("Bin Code"));
    end;

    procedure CheckIncreaseCapacity(DeductLineCapacity: Boolean)
    var
        BinContent: Record "Bin Content";
        DeductCubage: Decimal;
        DeductWeight: Decimal;
        IsHandled: Boolean;
    begin
        if DeductLineCapacity then begin
            DeductCubage := xRec.Cubage;
            DeductWeight := xRec.Weight;
        end;

        IsHandled := false;
        OnCheckIncreaseCapacityOnBeforeCheckIncreaseBinContent(Rec, Bin, DeductCubage, DeductWeight, IsHandled);
        if IsHandled then
            exit;

        if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
            BinContent.CheckIncreaseBinContent(
              "Qty. to Handle (Base)", "Qty. Outstanding (Base)",
              DeductCubage, DeductWeight, Cubage, Weight, false, false)
        else
            Bin.CheckIncreaseBin(
              "Bin Code", "Item No.", "Qty. to Handle",
              DeductCubage, DeductWeight, Cubage, Weight, false, false);
    end;

    local procedure CheckExceedQtyAvailBase(BinContent: Record "Bin Content"; QtyAvailBase: Decimal; NewBinCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExceedQtyAvailBase(Rec, QtyAvailBase, NewBinCode, IsHandled);
        if IsHandled then
            exit;

        if (QtyAvailBase < "Qty. Outstanding (Base)") and not "Assemble to Order" then begin
            if not
               Confirm(
                 StrSubstNo(
                   Text012,
                   FieldCaption("Qty. Outstanding (Base)"), "Qty. Outstanding (Base)",
                   QtyAvailBase, BinContent.TableCaption, FieldCaption("Bin Code")),
                 false)
            then
                Error(Text006);

            "Bin Code" := NewBinCode;
            Modify();
        end;
    end;

    local procedure CheckBinCodeFromWhseShptLine(WhseShptLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeFromWhseShptLine(Rec, WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        TestField("Bin Code", WhseShptLine."Bin Code");
    end;

    local procedure CheckBinCodeFromProdOrderCompLine(ProdOrderCompLine: Record "Prod. Order Component")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeFromProdOrderCompLine(Rec, ProdOrderCompLine, IsHandled);
        if IsHandled then
            exit;

        TestField("Bin Code", ProdOrderCompLine."Bin Code");
    end;

    procedure SplitLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        NewWhseActivLine: Record "Warehouse Activity Line";
        LineSpacing: Integer;
        NewLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitLines(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        CheckSplitLine(WhseActivLine);

        NewWhseActivLine := WhseActivLine;
        NewWhseActivLine.SetRange("No.", WhseActivLine."No.");
        if NewWhseActivLine.Find('>') then
            LineSpacing :=
              (NewWhseActivLine."Line No." - WhseActivLine."Line No.") div 2
        else
            LineSpacing := 10000;

        OnSplitLineOnBeforeRenumberAllLines(WhseActivLine, LineSpacing);
        if LineSpacing = 0 then
            ReNumberWhseActivityLines(NewWhseActivLine, WhseActivLine, NewLineNo, LineSpacing);

        NewWhseActivLine.Reset();
        NewWhseActivLine.Init();
        NewWhseActivLine := WhseActivLine;
        NewWhseActivLine."Line No." := NewWhseActivLine."Line No." + LineSpacing;
        NewWhseActivLine.Quantity :=
          WhseActivLine."Qty. Outstanding" - WhseActivLine."Qty. to Handle";
        NewWhseActivLine."Qty. (Base)" :=
          WhseActivLine."Qty. Outstanding (Base)" - WhseActivLine."Qty. to Handle (Base)";
        NewWhseActivLine."Qty. Outstanding" := NewWhseActivLine.Quantity;
        NewWhseActivLine."Qty. Outstanding (Base)" := NewWhseActivLine."Qty. (Base)";
        NewWhseActivLine."Qty. to Handle" := NewWhseActivLine.Quantity;
        NewWhseActivLine."Qty. to Handle (Base)" := NewWhseActivLine."Qty. (Base)";
        NewWhseActivLine."Qty. Handled" := 0;
        NewWhseActivLine."Qty. Handled (Base)" := 0;
        OnSplitLineOnAfterInitNewWhseActivLine(NewWhseActivLine);
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then begin
            WMSMgt.CalcCubageAndWeight(
              NewWhseActivLine."Item No.", NewWhseActivLine."Unit of Measure Code",
              NewWhseActivLine."Qty. to Handle", NewWhseActivLine.Cubage, NewWhseActivLine.Weight);
            if not
               (((NewWhseActivLine."Activity Type" = NewWhseActivLine."Activity Type"::"Put-away") and
                 (NewWhseActivLine."Action Type" = NewWhseActivLine."Action Type"::Take)) or
                ((NewWhseActivLine."Activity Type" = NewWhseActivLine."Activity Type"::Pick) and
                 (NewWhseActivLine."Action Type" = NewWhseActivLine."Action Type"::Place)) or
                ("Breakbulk No." <> 0))
            then begin
                NewWhseActivLine."Zone Code" := '';
                NewWhseActivLine."Bin Code" := '';
            end;
        end;
        OnBeforeInsertNewWhseActivLine(NewWhseActivLine, WhseActivLine);
        NewWhseActivLine.Insert();

        WhseActivLine.Quantity := WhseActivLine."Qty. to Handle" + WhseActivLine."Qty. Handled";
        WhseActivLine."Qty. (Base)" :=
          WhseActivLine."Qty. to Handle (Base)" + WhseActivLine."Qty. Handled (Base)";
        WhseActivLine."Qty. Outstanding" := WhseActivLine."Qty. to Handle";
        WhseActivLine."Qty. Outstanding (Base)" := WhseActivLine."Qty. to Handle (Base)";
        if Location."Directed Put-away and Pick" then
            WMSMgt.CalcCubageAndWeight(
              WhseActivLine."Item No.", WhseActivLine."Unit of Measure Code",
              WhseActivLine."Qty. to Handle", WhseActivLine.Cubage, WhseActivLine.Weight);
        OnBeforeModifyOldWhseActivLine(WhseActivLine);
        WhseActivLine.Modify();

        OnAfterSplitLines(WhseActivLine, NewWhseActivLine);
    end;

    local procedure CheckSplitLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLine(WhseActivLine, IsHandled);
        if not IsHandled then begin
            WhseActivLine.TestField("Qty. to Handle");
            if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Put-away" then begin
                if WhseActivLine."Breakbulk No." <> 0 then
                    Error(Text007);
                WhseActivLine.TestField("Action Type", WhseActivLine."Action Type"::Place);
            end;
            if WhseActivLine."Qty. to Handle" = WhseActivLine."Qty. Outstanding" then
                WhseActivLine.FieldError(
                "Qty. to Handle", StrSubstNo(Text003, WhseActivLine.FieldCaption("Qty. Outstanding")));
        end;
    end;

    procedure FindBinCode() BinCode: Code[20]
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinCode(Rec, Item, BinCode, IsHandled);
        if IsHandled then
            exit(BinCode);

        if "Action Type" = "Action Type"::Take then begin
            WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(Rec);
            BinCode :=
                WMSMgt.BinContentLookUp(
                    "Location Code", "Item No.", "Variant Code", "Zone Code", WhseItemTrackingSetup, "Bin Code")
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
    end;

    procedure FindBinContent()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinContent(Rec, IsHandled);
        if IsHandled then
            exit;

        if not "Assemble to Order" and ("Action Type" = "Action Type"::Take) then
            WMSMgt.FindBinContent("Location Code", "Bin Code", "Item No.", "Variant Code", "Zone Code")
        else
            WMSMgt.FindBin("Location Code", "Bin Code", "Zone Code");
    end;

    procedure UpdateBreakbulkQtytoHandle()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetCurrentKey(
          "Activity Type", "No.", "Whse. Document Type",
          "Whse. Document No.", "Whse. Document Line No.");
        WhseActivLine.SetRange("Activity Type", "Activity Type");
        WhseActivLine.SetRange("No.", "No.");
        WhseActivLine.SetRange("Whse. Document Type", "Whse. Document Type");
        WhseActivLine.SetRange("Whse. Document No.", "Whse. Document No.");
        WhseActivLine.SetRange("Whse. Document Line No.", "Whse. Document Line No.");
        WhseActivLine.SetTrackingFilterFromWhseActivityLine(Rec);
        if "Original Breakbulk" then
            WhseActivLine.SetRange("Original Breakbulk", true)
        else
            WhseActivLine.SetRange("Breakbulk No.", "Breakbulk No.");
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        if WhseActivLine.FindFirst() then begin
            UpdateQtyToHandle(WhseActivLine);

            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
            if "Original Breakbulk" then begin
                WhseActivLine.SetRange("Original Breakbulk");
                WhseActivLine.SetRange("Breakbulk No.", WhseActivLine."Breakbulk No.")
            end else begin
                WhseActivLine.SetRange("Breakbulk No.");
                WhseActivLine.SetRange("Original Breakbulk", true);
            end;
            if WhseActivLine.FindFirst() then
                UpdateQtyToHandle(WhseActivLine);
        end;
    end;

    local procedure UpdateQtyToHandle(var WhseActivLine: Record "Warehouse Activity Line")
    begin
        WhseActivLine."Qty. to Handle (Base)" := "Qty. to Handle (Base)";
        WhseActivLine."Qty. to Handle" := WhseActivLine.CalcQty("Qty. to Handle (Base)");
        WMSMgt.CalcCubageAndWeight(
            WhseActivLine."Item No.", WhseActivLine."Unit of Measure Code",
            WhseActivLine."Qty. to Handle", WhseActivLine.Cubage, WhseActivLine.Weight);
        OnUpdateQtyToHandleOnBeforeWhseActivLineModify(WhseActivLine);
        WhseActivLine.Modify();
    end;

    procedure ShowWhseDoc()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseIntPickHeader: Record "Whse. Internal Pick Header";
        WhseIntPutawayHeader: Record "Whse. Internal Put-away Header";
        RelProdOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        WhseShptCard: Page "Warehouse Shipment";
        PostedWhseRcptCard: Page "Posted Whse. Receipt";
        WhseIntPickCard: Page "Whse. Internal Pick";
        WhseIntPutawayCard: Page "Whse. Internal Put-away";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowWhseDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Whse. Document Type" of
            "Whse. Document Type"::Shipment:
                begin
                    WhseShptHeader.SetRange("No.", "Whse. Document No.");
                    WhseShptCard.SetTableView(WhseShptHeader);
                    WhseShptCard.RunModal();
                end;
            "Whse. Document Type"::Receipt:
                begin
                    PostedWhseRcptHeader.SetRange("No.", "Whse. Document No.");
                    PostedWhseRcptCard.SetTableView(PostedWhseRcptHeader);
                    PostedWhseRcptCard.RunModal();
                end;
            "Whse. Document Type"::"Internal Pick":
                begin
                    WhseIntPickHeader.SetRange("No.", "Whse. Document No.");
                    WhseIntPickHeader.FindFirst();
                    WhseIntPickCard.SetRecord(WhseIntPickHeader);
                    WhseIntPickCard.SetTableView(WhseIntPickHeader);
                    WhseIntPickCard.RunModal();
                end;
            "Whse. Document Type"::"Internal Put-away":
                begin
                    WhseIntPutawayHeader.SetRange("No.", "Whse. Document No.");
                    WhseIntPutawayHeader.FindFirst();
                    WhseIntPutawayCard.SetRecord(WhseIntPutawayHeader);
                    WhseIntPutawayCard.SetTableView(WhseIntPutawayHeader);
                    WhseIntPutawayCard.RunModal();
                end;
            "Whse. Document Type"::Production:
                begin
                    RelProdOrder.SetRange(Status, "Source Subtype");
                    RelProdOrder.SetRange("No.", "Source No.");
                    PAGE.RunModal(PAGE::"Released Production Order", RelProdOrder);
                end;
            "Whse. Document Type"::Assembly:
                begin
                    AssemblyHeader.SetRange("Document Type", "Source Subtype");
                    AssemblyHeader.SetRange("No.", "Source No.");
                    PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                end;
        end;
    end;

    procedure ShowActivityDoc()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhsePutawayCard: Page "Warehouse Put-away";
        WhseMovCard: Page "Warehouse Movement";
        InvtPickCard: Page "Inventory Pick";
        InvtPutAwayCard: Page "Inventory Put-away";
    begin
        WhseActivHeader.SetRange(Type, "Activity Type");
        WhseActivHeader.SetRange("No.", "No.");
        case "Activity Type" of
            "Activity Type"::Pick:
                RunWhsePickCard(WhseActivHeader);
            "Activity Type"::"Put-away":
                begin
                    WhsePutawayCard.SetTableView(WhseActivHeader);
                    WhsePutawayCard.RunModal();
                end;
            "Activity Type"::Movement:
                begin
                    WhseMovCard.SetTableView(WhseActivHeader);
                    WhseMovCard.RunModal();
                end;
            "Activity Type"::"Invt. Pick":
                begin
                    InvtPickCard.SetTableView(WhseActivHeader);
                    InvtPickCard.RunModal();
                end;
            "Activity Type"::"Invt. Put-away":
                begin
                    InvtPutAwayCard.SetTableView(WhseActivHeader);
                    InvtPutAwayCard.RunModal();
                end;
            "Activity Type"::"Invt. Movement":
                PAGE.RunModal(PAGE::"Inventory Movement", WhseActivHeader);
        end;
    end;

    procedure ChangeUOMCode(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeUOMCode(WhseActivLine, WhseActivLine2, IsHandled);
        if IsHandled then
            exit;

        if "Breakbulk No." = 0 then
            if (Quantity <> "Qty. to Handle") or ("Qty. Handled" <> 0) then
                CreateNewUOMLine("Action Type", WhseActivLine, WhseActivLine2)
            else begin
                Rec := WhseActivLine2;
                GetLocation("Location Code");
                if Location."Directed Put-away and Pick" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Handle", Cubage, Weight);
                OnChangeUOMCodeOnBeforeRecModify(Rec, Location);
                Modify;
            end;
    end;

    local procedure CreateNewUOMLine(ActType: Enum "Warehouse Action Type"; WhseActivLine: Record "Warehouse Activity Line"; WhseActivLine2: Record "Warehouse Activity Line")
    var
        NewWhseActivLine: Record "Warehouse Activity Line";
        LineSpacing: Integer;
    begin
        NewWhseActivLine := WhseActivLine;
        if NewWhseActivLine.Find('>') then
            LineSpacing :=
              (NewWhseActivLine."Line No." - WhseActivLine."Line No.") div 2
        else
            LineSpacing := 10000;

        NewWhseActivLine.Reset();
        NewWhseActivLine.Init();
        NewWhseActivLine := WhseActivLine2;
        NewWhseActivLine."Line No." := NewWhseActivLine."Line No." + LineSpacing;
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            WMSMgt.CalcCubageAndWeight(
              NewWhseActivLine."Item No.", NewWhseActivLine."Unit of Measure Code",
              NewWhseActivLine."Qty. to Handle", NewWhseActivLine.Cubage, NewWhseActivLine.Weight);
        NewWhseActivLine."Action Type" := ActType;
        NewWhseActivLine.Validate("Qty. Handled", 0);
        OnCreateNewUOMLineOnBeforeNewWhseActivLineInsert(NewWhseActivLine, WhseActivLine);
        NewWhseActivLine.Insert();

        WhseActivLine."Qty. Outstanding" :=
          WhseActivLine."Qty. Outstanding" - WhseActivLine."Qty. to Handle";
        WhseActivLine."Qty. Outstanding (Base)" :=
          WhseActivLine."Qty. Outstanding (Base)" - WhseActivLine."Qty. to Handle (Base)";
        WhseActivLine.Quantity :=
          WhseActivLine.Quantity - WhseActivLine."Qty. to Handle";
        WhseActivLine."Qty. (Base)" :=
          WhseActivLine."Qty. (Base)" - WhseActivLine."Qty. to Handle (Base)";
        WhseActivLine.Validate("Qty. to Handle", WhseActivLine."Qty. Outstanding");
        if Location."Directed Put-away and Pick" then
            WMSMgt.CalcCubageAndWeight(
              WhseActivLine."Item No.", WhseActivLine."Unit of Measure Code",
              WhseActivLine."Qty. to Handle", WhseActivLine.Cubage, WhseActivLine.Weight);
        OnCreateNewUOMLineOnBeforeNewWhseActivLineModify(NewWhseActivLine, WhseActivLine);
        WhseActivLine.Modify();
    end;

    procedure UpdateRelatedItemTrkg(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseDocType2: Enum "Warehouse Activity Document Type";
    begin
        if WhseActivLine.TrackingExists() then begin
            WhseItemTrkgLine.SetTrackingKey();
            WhseItemTrkgLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
            if (WhseActivLine."Whse. Document Type" = WhseActivLine."Whse. Document Type"::Shipment) and
               WhseActivLine."Assemble to Order"
            then
                WhseDocType2 := WhseActivLine."Whse. Document Type"::Assembly
            else
                WhseDocType2 := WhseActivLine."Whse. Document Type";
            case WhseDocType2 of
                WhseActivLine."Whse. Document Type"::Shipment:
                    SetWhseItemTrkgLineFiltersWhseShipment(WhseItemTrkgLine, WhseActivLine);
                WhseActivLine."Whse. Document Type"::"Internal Pick":
                    begin
                        WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Whse. Internal Pick Line");
                        WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Whse. Document No.");
                        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Whse. Document Line No.");
                    end;
                WhseActivLine."Whse. Document Type"::"Internal Put-away":
                    begin
                        WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Whse. Internal Put-away Line");
                        WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Whse. Document No.");
                        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Whse. Document Line No.");
                    end;
                WhseActivLine."Whse. Document Type"::Production:
                    begin
                        WhseItemTrkgLine.SetRange("Source Type", WhseActivLine."Source Type");
                        WhseItemTrkgLine.SetRange("Source Subtype", WhseActivLine."Source Subtype");
                        WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Source No.");
                        WhseItemTrkgLine.SetRange("Source Prod. Order Line", WhseActivLine."Source Line No.");
                        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Source Subline No.");
                    end;
                WhseActivLine."Whse. Document Type"::Assembly,
                WhseActivLine."Whse. Document Type"::Job:
                    begin
                        WhseItemTrkgLine.SetRange("Source Type", WhseActivLine."Source Type");
                        WhseItemTrkgLine.SetRange("Source Subtype", WhseActivLine."Source Subtype");
                        WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Source No.");
                        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Source Line No.");
                    end;
            end;
            if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then
                case WhseActivLine."Source Type" of
                    DATABASE::"Prod. Order Component":
                        begin
                            WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
                            WhseItemTrkgLine.SetRange("Source Subtype", WhseActivLine."Source Subtype");
                            WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Source No.");
                            WhseItemTrkgLine.SetRange("Source Prod. Order Line", WhseActivLine."Source Line No.");
                            WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Source Subline No.");
                        end;
                    DATABASE::"Assembly Line":
                        begin
                            WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Assembly Line");
                            WhseItemTrkgLine.SetRange("Source Subtype", WhseActivLine."Source Subtype");
                            WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Source No.");
                            WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Source Line No.");
                        end;
                end;
            if WhseItemTrkgLine.Find('-') then
                repeat
                    ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrkgLine);
                    UpdateReservation(WhseActivLine, true);
                    if (WhseActivLine."Whse. Document Type" in
                        [WhseActivLine."Whse. Document Type"::Production, WhseActivLine."Whse. Document Type"::Assembly, WhseActivLine."Whse. Document Type"::Job]) and
                       not WhseActivLine."Assemble to Order"
                    then
                        if WhseItemTrkgLine."Quantity Handled (Base)" = 0 then
                            WhseItemTrkgLine.Delete
                        else begin
                            WhseItemTrkgLine.Validate("Quantity (Base)", WhseItemTrkgLine."Quantity Handled (Base)");
                            WhseItemTrkgLine.Modify();
                        end
                    else
                        if (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement") and
                           (WhseItemTrkgLine."Quantity Handled (Base)" = 0)
                        then
                            WhseItemTrkgLine.Delete
                        else
                            WhseItemTrkgLine.Modify();
                until WhseItemTrkgLine.Next() = 0;
        end;
    end;

    local procedure SetWhseItemTrkgLineFiltersWhseShipment(var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetWhseItemTrkgLineFiltersWhseShipment(Rec, WhseItemTrkgLine, WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        WhseItemTrkgLine.SetRange("Source Type", DATABASE::"Warehouse Shipment Line");
        WhseItemTrkgLine.SetRange("Source ID", WhseActivLine."Whse. Document No.");
        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseActivLine."Whse. Document Line No.");
    end;

    procedure LookUpTrackingSummary(var WhseActivLine: Record "Warehouse Activity Line"; SearchForSupply: Boolean; SignFactor: Integer; TrackingType: Enum "Item Tracking Type")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpTrackingSummary(WhseActivLine, TrackingType, IsHandled);
        if IsHandled then
            exit;

        InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, WhseActivLine);
        TempTrackingSpecification."Quantity (Base)" := WhseActivLine."Qty. Outstanding (Base)";
        TempTrackingSpecification."Qty. to Handle" := WhseActivLine."Qty. Outstanding";
        TempTrackingSpecification."Qty. to Handle (Base)" := WhseActivLine."Qty. Outstanding (Base)";
        TempTrackingSpecification."Qty. to Invoice" := 0;
        TempTrackingSpecification."Qty. to Invoice (Base)" := 0;
        TempTrackingSpecification."Quantity Handled (Base)" := 0;
        TempTrackingSpecification."Quantity Invoiced (Base)" := 0;

        GetItem();
        if not ItemTrackingDataCollection.CurrentDataSetMatches(
            WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseActivLine."Location Code")
        then
            Clear(ItemTrackingDataCollection);
        OnLookUpTrackingSummaryOnAfterCheckDataSet(WhseActivLine, Item, TempTrackingSpecification);
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(WhseActivLine."Bin Code", ItemTrackingCode);
        ItemTrackingDataCollection.AssistEditTrackingNo(
            TempTrackingSpecification, SearchForSupply, SignFactor, TrackingType, WhseActivLine."Qty. Outstanding");

        OnLookUpTrackingSummaryOnAfterAssistEditTrackingNo(WhseActivLine, TempTrackingSpecification, TrackingType);

        case TrackingType of
            TrackingType::"Serial No.":
                if TempTrackingSpecification."Serial No." <> '' then begin
                    WhseActivLine.Validate("Serial No.", TempTrackingSpecification."Serial No.");
                    WhseActivLine.Validate("Lot No.", TempTrackingSpecification."Lot No.");
                    OnLookUpTrackingSummaryOnAfterAssignSerialNoTracking(WhseActivLine, TempTrackingSpecification);
                    WhseActivLine.Validate("Expiration Date", TempTrackingSpecification."Expiration Date");
                    WhseActivLine.Modify();
                end;
            TrackingType::"Lot No.":
                if TempTrackingSpecification."Lot No." <> '' then begin
                    WhseActivLine.Validate("Lot No.", TempTrackingSpecification."Lot No.");
                    OnLookUpTrackingSummaryOnAfterAssignLotNoTracking(WhseActivLine, TempTrackingSpecification);
                    WhseActivLine.Validate("Expiration Date", TempTrackingSpecification."Expiration Date");
                    WhseActivLine.Modify();
                end;
        end;

        OnAfterLookupTrackingSummary(WhseActivLine, TempTrackingSpecification, TrackingType);
    end;

    procedure CheckReservedItemTrkg(CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := ("Activity Type" = "Activity Type"::"Invt. Pick") and "Assemble to Order";
        OnBeforeCheckReservedItemTrkg(Rec, CheckType, ItemTrkgCode, IsHandled);
        if IsHandled then
            exit;

        case CheckType of
            CheckType::"Serial No.":
                CheckReservedItemTrkgForSerialNo(ItemTrkgCode);
            CheckType::"Lot No.":
                CheckReservedItemTrkgForLotNo(ItemTrkgCode);
            else
                OnCheckReservedItemTrkgOnCheckTypeElseCase(Rec, CheckType, ItemTrkgCode);
        end;
    end;

    local procedure CheckReservedItemTrkgForSerialNo(ItemTrkgCode: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Serial No. Required" then
            exit;

        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", "Item No.");
        ReservEntry.SetRange("Variant Code", "Variant Code");
        ReservEntry.SetRange("Location Code", "Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Serial No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, false);
        if ReservEntry.FindFirst() and
            ((ReservEntry."Source Type" <> "Source Type") or
            (ReservEntry."Source Subtype" <> "Source Subtype") or
            (ReservEntry."Source ID" <> "Source No.") or
            (((ReservEntry."Source Ref. No." <> "Source Line No.") and
                (ReservEntry."Source Type" <> DATABASE::"Prod. Order Component")) or
                (((ReservEntry."Source Prod. Order Line" <> "Source Line No.") or
                (ReservEntry."Source Ref. No." <> "Source Subline No.")) and
                (ReservEntry."Source Type" = DATABASE::"Prod. Order Component"))))
        then
            Error(Text014, FieldCaption("Serial No."), ItemTrkgCode);
    end;

    local procedure CheckReservedItemTrkgForLotNo(ItemTrkgCode: Code[50])
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
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Lot No. Required" then
            exit;

        Item.Get("Item No.");
        Item.SetRange("Location Filter", "Location Code");
        Item.SetRange("Variant Filter", "Variant Code");
        Item.SetRange("Lot No. Filter", ItemTrkgCode);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        WhseItemTrackingSetup."Lot No." := ItemTrkgCode;
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", "Item No.");
        ReservEntry.SetRange("Variant Code", "Variant Code");
        ReservEntry.SetRange("Location Code", "Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Lot No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, true);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", false);
                if ((ReservEntry2."Source Type" <> "Source Type") or
                    (ReservEntry2."Source Subtype" <> "Source Subtype") or
                    (ReservEntry2."Source ID" <> "Source No.") or
                    (((ReservEntry2."Source Ref. No." <> "Source Line No.") and
                        (ReservEntry2."Source Type" <> DATABASE::"Prod. Order Component")) or
                        (((ReservEntry2."Source Prod. Order Line" <> "Source Line No.") or
                        (ReservEntry2."Source Ref. No." <> "Source Subline No.")) and
                        (ReservEntry2."Source Type" = DATABASE::"Prod. Order Component")))) and
                    (ReservEntry2."Lot No." = '')
                then
                    AvailQtyFromOtherResvLines := AvailQtyFromOtherResvLines + Abs(ReservEntry2."Quantity (Base)");
            until ReservEntry.Next() = 0;

        TempWhseActivLine := Rec;
        TempWhseActivLine."Qty. Outstanding (Base)" *= -1;
        TempWhseActivLine.Insert();

        LineReservedQty :=
            WhseAvailMgt.CalcLineReservedQtyOnInvt(
            "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true, WhseItemTrackingSetup, TempWhseActivLine);

        if (Item.Inventory - Abs(Item."Reserved Qty. on Inventory") +
            LineReservedQty + AvailQtyFromOtherResvLines +
            WhseAvailMgt.CalcReservQtyOnPicksShips("Location Code", "Item No.", "Variant Code", TempWhseActivLine)) <
            "Qty. to Handle (Base)"
        then
            Error(InventoryNotAvailableErr, FieldCaption("Lot No."), ItemTrkgCode);

        OnAfterCheckReservedItemTrkg(Rec, xRec, CurrFieldNo, 0, LineReservedQty);
    end;

    procedure DeleteBinContent(ActionType: Option)
    var
        BinContent: Record "Bin Content";
    begin
        if "Action Type".AsInteger() <> ActionType then
            exit;

        if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
            if not BinContent.Fixed and
               (BinContent."Min. Qty." = 0) and (BinContent."Max. Qty." = 0)
            then begin
                BinContent.CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
                if (BinContent."Quantity (Base)" = 0) and
                   (BinContent."Positive Adjmt. Qty. (Base)" = 0) and
                   (BinContent."Put-away Quantity (Base)" - "Qty. Outstanding (Base)" <= 0)
                then
                    BinContent.Delete();
            end;
    end;

    local procedure UpdateReservation(TempWhseActivLine2: Record "Warehouse Activity Line" temporary; Deletion: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        with TempWhseActivLine2 do begin
            if ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0) and
               ("Whse. Document Type" = "Whse. Document Type"::Shipment)
            then begin
                InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, TempWhseActivLine2);
                TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                TempTrackingSpecification."Entry No." := TempTrackingSpecification."Entry No." + 1;
                TempTrackingSpecification."Creation Date" := Today;
                TempTrackingSpecification."Warranty Date" := "Warranty Date";
                TempTrackingSpecification."Expiration Date" := "Expiration Date";
                TempTrackingSpecification.Correction := true;
                OnUpdateReservationOnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, TempWhseActivLine2);
                TempTrackingSpecification.Insert();
            end;
            ItemTrackingMgt.SetPick("Activity Type" = "Activity Type"::Pick);
            ItemTrackingMgt.SynchronizeWhseItemTracking(TempTrackingSpecification, '', Deletion);
        end;
    end;

    procedure TransferFromPickWkshLine(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := WhseWkshLine."Source Type";
        "Source Subtype" := WhseWkshLine."Source Subtype";
        "Source No." := WhseWkshLine."Source No.";
        "Source Line No." := WhseWkshLine."Source Line No.";
        "Source Subline No." := WhseWkshLine."Source Subline No.";
        "Shelf No." := WhseWkshLine."Shelf No.";
        "Item No." := WhseWkshLine."Item No.";
        "Variant Code" := WhseWkshLine."Variant Code";
        Description := WhseWkshLine.Description;
        "Description 2" := WhseWkshLine."Description 2";
        "Due Date" := WhseWkshLine."Due Date";
        "Starting Date" := WorkDate;
        "Destination Type" := WhseWkshLine."Destination Type";
        "Destination No." := WhseWkshLine."Destination No.";
        "Shipping Agent Code" := WhseWkshLine."Shipping Agent Code";
        "Shipping Agent Service Code" := WhseWkshLine."Shipping Agent Service Code";
        "Shipment Method Code" := WhseWkshLine."Shipment Method Code";
        "Shipping Advice" := WhseWkshLine."Shipping Advice";
        "Whse. Document Type" := WhseWkshLine."Whse. Document Type";
        "Whse. Document No." := WhseWkshLine."Whse. Document No.";
        "Whse. Document Line No." := WhseWkshLine."Whse. Document Line No.";

        case "Whse. Document Type" of
            "Whse. Document Type"::Shipment:
                begin
                    WhseShptLine.Get("Whse. Document No.", "Whse. Document Line No.");
                    "Assemble to Order" := WhseShptLine."Assemble to Order";
                    "ATO Component" := WhseShptLine."Assemble to Order";
                end;
            "Whse. Document Type"::Assembly:
                begin
                    "Assemble to Order" := AssembleToOrderLink.Get("Source Subtype", "Source No.");
                    "ATO Component" := true;
                end;
        end;

        OnAfterTransferFromPickWkshLine(Rec, WhseWkshLine);
    end;

    procedure TransferFromShptLine(WhseShptLine: Record "Warehouse Shipment Line")
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := WhseShptLine."Source Type";
        "Source Subtype" := WhseShptLine."Source Subtype";
        "Source No." := WhseShptLine."Source No.";
        "Source Line No." := WhseShptLine."Source Line No.";
        "Shelf No." := WhseShptLine."Shelf No.";
        "Item No." := WhseShptLine."Item No.";
        "Variant Code" := WhseShptLine."Variant Code";
        Description := WhseShptLine.Description;
        "Description 2" := WhseShptLine."Description 2";
        "Due Date" := WhseShptLine."Due Date";
        "Starting Date" := WhseShptLine."Shipment Date";
        "Destination Type" := WhseShptLine."Destination Type";
        "Destination No." := WhseShptLine."Destination No.";
        "Shipping Advice" := WhseShptLine."Shipping Advice";
        "Whse. Document Type" := "Whse. Document Type"::Shipment;
        "Whse. Document No." := WhseShptLine."No.";
        "Whse. Document Line No." := WhseShptLine."Line No.";

        OnAfterTransferFromShptLine(Rec, WhseShptLine);
    end;

    procedure TransferFromATOShptLine(WhseShptLine: Record "Warehouse Shipment Line"; AssemblyLine: Record "Assembly Line")
    begin
        WhseShptLine.TestField("Assemble to Order", true);
        TransferFromShptLine(WhseShptLine);
        TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine);
    end;

    procedure TransferFromIntPickLine(WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Shelf No." := WhseInternalPickLine."Shelf No.";
        "Item No." := WhseInternalPickLine."Item No.";
        "Variant Code" := WhseInternalPickLine."Variant Code";
        Description := WhseInternalPickLine.Description;
        "Description 2" := WhseInternalPickLine."Description 2";
        "Due Date" := WhseInternalPickLine."Due Date";
        "Starting Date" := WorkDate;
        "Source Type" := DATABASE::"Whse. Internal Pick Line";
        "Source No." := WhseInternalPickLine."No.";
        "Source Line No." := WhseInternalPickLine."Line No.";
        "Whse. Document Type" := "Whse. Document Type"::"Internal Pick";
        "Whse. Document No." := WhseInternalPickLine."No.";
        "Whse. Document Line No." := WhseInternalPickLine."Line No.";

        OnAfterTransferFromIntPickLine(Rec, WhseInternalPickLine);
    end;

    procedure TransferFromCompLine(ProdOrderCompLine: Record "Prod. Order Component")
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := DATABASE::"Prod. Order Component";
        "Source Subtype" := ProdOrderCompLine.Status.AsInteger();
        "Source No." := ProdOrderCompLine."Prod. Order No.";
        "Source Line No." := ProdOrderCompLine."Prod. Order Line No.";
        "Source Subline No." := ProdOrderCompLine."Line No.";
        "Item No." := ProdOrderCompLine."Item No.";
        "Variant Code" := ProdOrderCompLine."Variant Code";
        Description := ProdOrderCompLine.Description;
        "Due Date" := ProdOrderCompLine."Due Date";
        "Whse. Document Type" := "Whse. Document Type"::Production;
        "Whse. Document No." := ProdOrderCompLine."Prod. Order No.";
        "Whse. Document Line No." := ProdOrderCompLine."Prod. Order Line No.";

        OnAfterTransferFromCompLine(Rec, ProdOrderCompLine);
    end;

    procedure TransferFromAssemblyLine(AssemblyLine: Record "Assembly Line")
    begin
        TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine);
        "Whse. Document Type" := "Whse. Document Type"::Assembly;
        "Whse. Document No." := AssemblyLine."Document No.";
        "Whse. Document Line No." := AssemblyLine."Line No.";

        OnAfterTransferFromAssemblyLine(Rec, AssemblyLine);
    end;

    procedure TransferFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := DATABASE::Job;
        "Source Subtype" := 0;
        "Source No." := JobPlanningLine."Job No.";
        "Source Line No." := JobPlanningLine."Job Contract Entry No.";
        "Source Subline No." := JobPlanningLine."Line No.";
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        Description := JobPlanningLine.Description;
        "Due Date" := JobPlanningLine."Planning Due Date";
        "Whse. Document Type" := "Whse. Document Type"::Job;
        "Whse. Document No." := JobPlanningLine."Job No.";
        "Whse. Document Line No." := JobPlanningLine."Job Contract Entry No.";
        "Destination Type" := "Destination Type"::Customer;

        Job.SetLoadFields("Sell-to Customer No.");
        Job.Get(JobPlanningLine."Job No.");
        "Destination No." := Job."Sell-to Customer No.";
    end;

    procedure TransferFromMovWkshLine(WhseWkshLine: Record "Whse. Worksheet Line")
    begin
        "Activity Type" := "Activity Type"::Movement;
        "Item No." := WhseWkshLine."Item No.";
        "Variant Code" := WhseWkshLine."Variant Code";
        "Starting Date" := WorkDate;
        Description := WhseWkshLine.Description;
        "Description 2" := WhseWkshLine."Description 2";
        "Due Date" := WhseWkshLine."Due Date";
        Dedicated := Bin.Dedicated;
        "Zone Code" := Bin."Zone Code";
        "Bin Ranking" := Bin."Bin Ranking";
        "Bin Type Code" := Bin."Bin Type Code";
        "Whse. Document Type" := "Whse. Document Type"::"Movement Worksheet";
        "Whse. Document No." := WhseWkshLine.Name;
        "Whse. Document Line No." := WhseWkshLine."Line No.";

        OnAfterTransferFromMovWkshLine(Rec, WhseWkshLine);
    end;

    local procedure TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine: Record "Assembly Line")
    var
        AsmHeader: Record "Assembly Header";
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := DATABASE::"Assembly Line";
        "Source Subtype" := AssemblyLine."Document Type".AsInteger();
        "Source No." := AssemblyLine."Document No.";
        "Source Line No." := AssemblyLine."Line No.";
        "Source Subline No." := 0;
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        "Item No." := AssemblyLine."No.";
        "Variant Code" := AssemblyLine."Variant Code";
        Description := AssemblyLine.Description;
        "Description 2" := AssemblyLine."Description 2";
        "Due Date" := AssemblyLine."Due Date";
        AsmHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        AsmHeader.CalcFields("Assemble to Order");
        "Assemble to Order" := AsmHeader."Assemble to Order";
        "ATO Component" := true;

        OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(Rec, AssemblyLine);
    end;

    local procedure CheckSNSpecificationExists()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSNSpecificationExists(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." <> '' then begin
            WarehouseActivityLine.SetCurrentKey("Item No.");
            WarehouseActivityLine.SetRange("Activity Type", "Activity Type");
            WarehouseActivityLine.SetRange("Action Type", "Action Type");
            WarehouseActivityLine.SetRange("No.", "No.");
            WarehouseActivityLine.SetRange("Item No.", "Item No.");
            WarehouseActivityLine.SetRange("Variant Code", "Variant Code");
            WarehouseActivityLine.SetFilter("Line No.", '<>%1', "Line No.");
            WarehouseActivityLine.SetRange("Serial No.", "Serial No.");
            if not WarehouseActivityLine.IsEmpty() then
                Error(Text018, TableCaption, FieldCaption("Serial No."), "Serial No.");
        end;
    end;

    local procedure InitTrackingSpecFromWhseActivLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            TrackingSpecification.Init();
            if "Source Type" = DATABASE::"Prod. Order Component" then
                TrackingSpecification.SetSource(
                  "Source Type", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.")
            else
                TrackingSpecification.SetSource(
                  "Source Type", "Source Subtype", "Source No.", "Source Line No.", '', 0);

            TrackingSpecification."Item No." := "Item No.";
            TrackingSpecification."Location Code" := "Location Code";
            TrackingSpecification.Description := Description;
            TrackingSpecification."Variant Code" := "Variant Code";
            TrackingSpecification."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            TrackingSpecification.CopyTrackingFromWhseActivityLine(WhseActivityLine);
            TrackingSpecification."Expiration Date" := "Expiration Date";
            TrackingSpecification."Bin Code" := "Bin Code";
            TrackingSpecification."Qty. to Handle (Base)" := "Qty. to Handle (Base)";
        end;

        OnAfterInitTrackingSpecFromWhseActivLine(TrackingSpecification, WhseActivityLine);
    end;

    local procedure FindLotNoBySerialNo()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CheckGlobalEntrySummary: Boolean;
        LotNo: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLotNoBySerialNo(Rec, IsHandled);
        if IsHandled then
            exit;

        InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, Rec);
        CheckGlobalEntrySummary :=
          ("Activity Type" <> "Activity Type"::"Put-away") and
          (not ("Source Document" in
                ["Source Document"::"Purchase Order", "Source Document"::"Prod. Output", "Source Document"::"Assembly Order", "Source Document"::"Job Usage"]));
        if CheckGlobalEntrySummary then
            Validate("Lot No.", ItemTrackingDataCollection.FindLotNoBySN(TempTrackingSpecification))
        else begin
            if not ItemTrackingDataCollection.FindLotNoBySNSilent(LotNo, TempTrackingSpecification) then
                LotNo := TempTrackingSpecification."Lot No.";
            Validate("Lot No.", LotNo);
        end;
    end;

    local procedure CheckInvalidBinCode()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Direction: Text[1];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvalidBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Location.Get("Location Code");
        if ("Action Type" = "Action Type"::" ") or (not Location."Bin Mandatory") then
            exit;
        WhseActivLine := Rec;
        WhseActivLine.SetRange("Activity Type", "Activity Type");
        WhseActivLine.SetRange("No.", "No.");
        WhseActivLine.SetRange("Whse. Document Line No.", "Whse. Document Line No.");
        WhseActivLine.SetFilter("Action Type", '<>%1', "Action Type");
        if "Action Type" = "Action Type"::Take then
            Direction := '>'
        else
            Direction := '<';
        if WhseActivLine.Find(Direction) then begin
            if ("Location Code" = WhseActivLine."Location Code") and
               ("Bin Code" = WhseActivLine."Bin Code") and
               ("Unit of Measure Code" = WhseActivLine."Unit of Measure Code")
            then
                Error(Text019, Format("Action Type"), Format(WhseActivLine."Action Type"), Location.Code);

            if (("Activity Type" = "Activity Type"::"Put-away") and ("Action Type" = "Action Type"::Place) and
                Location.IsBWReceive or ("Activity Type" = "Activity Type"::Pick) and
                ("Action Type" = "Action Type"::Take) and Location.IsBWShip) and Location.IsBinBWReceiveOrShip("Bin Code")
            then
                Error(Text020, Format("Action Type"), Location.Code);
        end;
    end;

    local procedure RegisteredWhseActLineIsEmpty(): Boolean
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", "Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Source No.", "Source No.");
        RegisteredWhseActivityLine.SetRange("Source Line No.", "Source Line No.");
        RegisteredWhseActivityLine.SetRange("Source Type", "Source Type");
        RegisteredWhseActivityLine.SetRange("Source Subtype", "Source Subtype");
        RegisteredWhseActivityLine.SetTrackingFilterFromWhseActivityLine(Rec);
        exit(RegisteredWhseActivityLine.IsEmpty);
    end;

    procedure ShowItemAvailabilityByPeriod()
    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseActivLine(Rec, ItemAvailFormsMgt.ByPeriod);
    end;

    procedure ShowItemAvailabilityByVariant()
    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseActivLine(Rec, ItemAvailFormsMgt.ByVariant);
    end;

    procedure ShowItemAvailabilityByLocation()
    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseActivLine(Rec, ItemAvailFormsMgt.ByLocation);
    end;

    procedure ShowItemAvailabilityByEvent()
    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        ItemAvailFormsMgt.ShowItemAvailFromWhseActivLine(Rec, ItemAvailFormsMgt.ByEvent);
    end;

    local procedure ShowDeletedMessage(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        with WhseActivLine2 do begin
            Reset;
            SetRange("Activity Type", WhseActivLine."Activity Type");
            SetRange("No.", WhseActivLine."No.");
            if not IsEmpty() then begin
                IsHandled := false;
                OnBeforeShowDeletedMessage(WhseActivLine2, IsHandled);
                if not IsHandled then
                    Message(Text013);
            end;
        end;

        OnAfterShowDeletedMessage(WhseActivLine2);
    end;

    local procedure ConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type");
        WhseWorksheetLine.SetRange("Whse. Document No.", WarehouseActivityLine."Whse. Document No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", WarehouseActivityLine."Whse. Document Line No.");
        if not WhseWorksheetLine.IsEmpty() then begin
            IsHandled := false;
            OnBeforeConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine, IsHandled);
            if not IsHandled then
                if not Confirm(Text009, false, WarehouseActivityLine.TableCaption) then
                    Error(Text006);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line"; var DeleteLineConfirmed: Boolean)
    var
        WhseActivLine3: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        with WhseActivLine2 do begin
            SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type");
            SetRange("Whse. Document No.", WhseActivLine."Whse. Document No.");
            SetRange("Whse. Document Line No.", WhseActivLine."Whse. Document Line No.");
            SetRange("Breakbulk No.", WhseActivLine."Breakbulk No.");
            SetRange("Source No.", WhseActivLine."Source No.");
            SetRange("Source Line No.", WhseActivLine."Source Line No.");
            SetRange("Source Subline No.", WhseActivLine."Source Subline No.");
            SetTrackingFilterFromWhseActivityLine(WhseActivLine);
            if Find('-') then begin
                WhseActivLine3.Copy(WhseActivLine2);
                WhseActivLine3.SetRange("Action Type", WhseActivLine."Action Type");
                WhseActivLine3.SetFilter("Line No.", '<>%1', WhseActivLine."Line No.");
                OnConfirmWhseActivLinesDeletionOutOfBalanceOnAfterWhseActivLine3SetFilters(WhseActivLine, WhseActivLine2, WhseActivLine3);
                if not WhseActivLine3.IsEmpty() then begin
                    IsHandled := false;
                    OnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine2, IsHandled);
                    if not IsHandled then
                        if not DeleteLineConfirmed then
                            if not Confirm(
                                 StrSubstNo(
                                   Text004,
                                   WhseActivLine.FieldCaption("Activity Type"), WhseActivLine."Activity Type", FieldCaption("No."), "No.",
                                   WhseActivLine.FieldCaption("Line No."), WhseActivLine."Line No.", WhseActivLine."Action Type",
                                   WhseActivLine.TableCaption),
                                 false)
                            then
                                Error(Text006);

                    DeleteLineConfirmed := true;
                end;
            end;
        end;
    end;

    procedure ActivityExists(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; ActivityType: Option): Boolean
    begin
        if ActivityType <> 0 then
            SetRange("Activity Type", ActivityType);
        SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo, false);
        exit(not IsEmpty);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Lot No." <> '') or ("Serial No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        "Source Subline No." := SourceSublineNo;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        SetRange("Source Line No.", SourceLineNo);
        if SourceSubLineNo >= 0 then
            SetRange("Source Subline No.", SourceSubLineNo);
    end;

    procedure SetSumLinesFilters(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        SetCurrentKey("Activity Type", "No.", "Bin Code", "Breakbulk No.", "Action Type");
        SetRange("Activity Type", WhseActivityLine."Activity Type");
        SetRange("No.", WhseActivityLine."No.");
        SetRange("Bin Code", WhseActivityLine."Bin Code");
        SetRange("Item No.", WhseActivityLine."Item No.");
        SetRange("Action Type", WhseActivityLine."Action Type");
        SetRange("Variant Code", WhseActivityLine."Variant Code");
        SetRange("Unit of Measure Code", WhseActivityLine."Unit of Measure Code");
        SetRange("Due Date", WhseActivityLine."Due Date");
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source No.");
        SetRange("Source Line No.");
        SetRange("Source Subline No.");
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";
        "Expiration Date" := TrackingSpecification."Expiration Date";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := WhseItemTrackingSetup."Serial No.";
        "Lot No." := WhseItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingFromPostedWhseRcptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        "Serial No." := PostedWhseRcptLine."Serial No.";
        "Lot No." := PostedWhseRcptLine."Lot No.";

        OnAfterCopyTrackingFromPostedWhseRcptLine(Rec, PostedWhseRcptLine);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterIfNotEmpty()
    begin
        if "Serial No." <> '' then
            SetRange("Serial No.", "Serial No.");
        if "Lot No." <> '' then
            SetRange("Lot No.", "Lot No.");

        OnAfterSetTrackingFilterIfNotEmpty(Rec);
    end;

#if not CLEAN20
    [Obsolete('Replaced by SetTrackingFilterFrom procedures.', '17.0')]
    procedure SetTrackingFilter(SerialNo: Code[50]; LotNo: Code[50])
    begin
        SetRange("Serial No.", SerialNo);
        SetRange("Lot No.", LotNo);

        OnAfterSetTrackingFilter(Rec);
    end;
#endif

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetTrackingFilterFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer")
    begin
        SetRange("Serial No.", BinContentBuffer."Serial No.");
        SetRange("Lot No.", BinContentBuffer."Lot No.");

        OnAfterSetTrackingFilterFromBinContentBuffer(Rec, BinContentBuffer);
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

    procedure SetTrackingFilterFromReservEntryIfRequired(ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Serial No." <> '' then
            SetRange("Serial No.", ReservEntry."Serial No.");
        if ReservEntry."Lot No." <> '' then
            SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntryIfRequired(Rec, ReservEntry);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        if WhseItemTrackingLine."Serial No." <> '' then
            SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        if WhseItemTrackingLine."Lot No." <> '' then
            SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WhseActivityLine."Serial No.");
        SetRange("Lot No.", WhseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
        else
            SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
        else
            SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetupifNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
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

        OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToItemIfRequired(var Item: Record Item; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Lot No." <> '' then begin
            if WhseItemTrackingSetup."Lot No. Required" then
                Item.SetRange("Lot No. Filter", "Lot No.")
            else
                Item.SetFilter("Lot No. Filter", '%1|%2', "Lot No.", '')
        end else
            Item.SetRange("Lot No. Filter");
        if "Serial No." <> '' then begin
            if WhseItemTrackingSetup."Serial No. Required" then
                Item.SetRange("Serial No. Filter", "Serial No.")
            else
                Item.SetFilter("Serial No. Filter", '%1|%2', "Serial No.", '');
        end else
            Item.SetRange("Serial No. Filter");

        OnAfterSetTrackingFilterToItemIfRequired(Rec, Item, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToItemLedgEntryIfRequired(var ItemLedgEntry: Record "Item Ledger Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                ItemLedgEntry.SetRange("Serial No.", "Serial No.")
            else
                ItemLedgEntry.SetFilter("Serial No.", '%1|%2', "Serial No.", '');
        if "Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                ItemLedgEntry.SetRange("Lot No.", "Lot No.")
            else
                ItemLedgEntry.SetFilter("Lot No.", '%1|%2', "Lot No.", '');

        OnAfterSetTrackingFilterToItemLedgEntryIfRequired(Rec, ItemLedgEntry, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToWhseEntryIfRequired(var WhseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                WhseEntry.SetRange("Serial No.", "Serial No.")
            else
                WhseEntry.SetFilter("Serial No.", '%1|%2', "Serial No.", '');
        if "Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                WhseEntry.SetRange("Lot No.", "Lot No.")
            else
                WhseEntry.SetFilter("Lot No.", '%1|%2', "Lot No.", '');

        OnAfterSetTrackingFilterToWhseEntryIfRequired(Rec, WhseEntry, WhseItemTrackingSetup);
    end;

    procedure TestTrackingIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then begin
            TestField("Serial No.");
            TestField("Qty. (Base)", 1);
        end;
        if WhseItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterTestTrackingIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure HasRequiredTracking(WhseItemTrackingSetup: Record "Item Tracking Setup") Result: Boolean
    begin
        Result := true;

        if WhseItemTrackingSetup."Serial No. Required" <> ("Serial No." <> '') then
            Result := false;
        if WhseItemTrackingSetup."Lot No. Required" <> ("Lot No." <> '') then
            Result := false;

        OnAfterHasRequiredTracking(Rec, WhseItemTrackingSetup, Result);
    end;

    local procedure ReNumberWhseActivityLines(var NewWhseActivityLine: Record "Warehouse Activity Line"; var WhseActivLine: Record "Warehouse Activity Line"; var NewLineNo: Integer; var LineSpacing: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReNumberWhseActivityLines(NewWhseActivityLine, WhseActivLine, NewLineNo, LineSpacing, IsHandled);
        if IsHandled then
            exit;

        ReNumberAllLines(NewWhseActivityLine, WhseActivLine."Line No.", NewLineNo);
        WhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", NewLineNo);
        LineSpacing := 5000;
    end;

    local procedure ReNumberAllLines(var NewWhseActivityLine: Record "Warehouse Activity Line"; OldLineNo: Integer; var NewLineNo: Integer)
    var
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        LineNo: Integer;
    begin
        NewWhseActivityLine.FindSet();
        repeat
            LineNo += 10000;
            TempWarehouseActivityLine := NewWhseActivityLine;
            TempWarehouseActivityLine."Line No." := LineNo;
            TempWarehouseActivityLine.Insert();
            if NewWhseActivityLine."Line No." = OldLineNo then
                NewLineNo := LineNo;
        until NewWhseActivityLine.Next() = 0;
        NewWhseActivityLine.DeleteAll();

        TempWarehouseActivityLine.FindSet();
        repeat
            NewWhseActivityLine := TempWarehouseActivityLine;
            NewWhseActivityLine.Insert();
        until TempWarehouseActivityLine.Next() = 0;
    end;

    procedure TrackingFilterExists() IsTrackingFilterExist: Boolean
    begin
        IsTrackingFilterExist := (GetFilter("Serial No.") <> '') or (GetFilter("Lot No.") <> '');
        OnAfterTrackingFilterExists(Rec, IsTrackingFilterExist);
    end;

    procedure ValidateQtyWhenSNDefined()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyWhenSNDefined(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Serial No." = '' then
            exit;

        if not (Rec."Qty. (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, Rec.FieldCaption("Qty. (Base)"), Rec."Qty. (Base)");

        if not (Rec."Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, Rec.FieldCaption("Qty. to Handle (Base)"), Rec."Qty. to Handle (Base)");
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Qty. (Base)", "Qty. to Handle", "Qty. to Handle (Base)", "Qty. Handled", "Qty. Handled (Base)");
    end;

    local procedure RunWhsePickCard(var WhseActivHeader: Record "Warehouse Activity Header")
    var
        WhsePickCard: Page "Warehouse Pick";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWhsePickCard(WhseActivHeader, IsHandled);
        if IsHandled then
            exit;

        WhsePickCard.SetTableView(WhseActivHeader);
        WhsePickCard.RunModal();
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure ShouldLookupBinContent(): Boolean
    begin
        exit(
            ("Activity Type".AsInteger() <= "Activity Type"::Movement.AsInteger()) or
            ("Action Type" <> "Action Type"::Place));
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;

    procedure ResetQtyToHandleOnReservation()
    begin
        if ("Qty. to Handle" = 0) and TrackingExists() and RegisteredWhseActLineIsEmpty() then
            if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then
                UpdateReservation(Rec, false);
    end;

    procedure TestNonSpecificItemTracking()
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingSetup: Record "Item Tracking Setup";
        NonWhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
    begin
        case "Source Document" of
            "Source Document"::"Sales Order":
                ItemLedgerEntryType := ItemLedgerEntryType::Sale;
            "Source Document"::"Purchase Return Order":
                ItemLedgerEntryType := ItemLedgerEntryType::Purchase;
            "Source Document"::"Outbound Transfer":
                ItemLedgerEntryType := ItemLedgerEntryType::Transfer;
            "Source Document"::"Prod. Consumption":
                ItemLedgerEntryType := ItemLedgerEntryType::Consumption;
            "Source Document"::"Assembly Consumption":
                ItemLedgerEntryType := ItemLedgerEntryType::"Assembly Consumption";
            else
                exit;
        end;

        GetItem();
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        ItemTrackingMgt.GetItemTrackingSetup(ItemTrackingCode, ItemLedgerEntryType, false, ItemTrackingSetup);

        NonWhseItemTrackingSetup.Code := ItemTrackingCode.Code;
        NonWhseItemTrackingSetup.GetNonWarehouseTrackingRequirements(WhseItemTrackingSetup, ItemTrackingSetup);

        TestTrackingIfRequired(NonWhseItemTrackingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandleLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedWhseRcptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTrackingSpecFromWhseActivLine(var TrackingSpecification: Record "Tracking Specification"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupTrackingSummary(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by events OnAfterSetTrackingFilterFrom', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilter(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterIfNotEmpty(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContentBuffer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToItemIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Item: Record Item; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToItemLedgEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToWhseEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDeletedMessage(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; NewWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingFilterExists(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingFilterExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromShptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromIntPickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAssemblyLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromMovWkshLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPickWkshLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestTrackingIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasRequiredTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQtyToHandleWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinInSourceDoc(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedItemTrkg(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExceedQtyAvailBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyAvailBase: Decimal; NewBinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeFromProdOrderCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderCompLine: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeFromWhseShptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvalidBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLine(WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSNSpecificationExists(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedWhseActivLines(var WhseActivLine: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteWhseActivLine2(var WarehouseActivityLine2: Record "Warehouse Activity Line"; CalledFromHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Item: Record Item; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLotNoBySerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUOMCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var UOMCode: Code[10]; var IsHandled: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewWhseActivLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpTrackingSummary(WhseActivLine: Record "Warehouse Activity Line"; TrackingType: Enum "Item Tracking Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyOldWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetWhseItemTrkgLineFiltersWhseShipment(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeletedMessage(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWhseDoc(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyOutstanding(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVariantCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeUOMCodeOnBeforeRecModify(var WarehouseActivityLine: Record "Warehouse Activity Line"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewUOMLineOnBeforeNewWhseActivLineInsert(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewUOMLineOnBeforeNewWhseActivLineModify(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssistEditTrackingNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterCheckDataSet(WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssignSerialNoTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssignLotNoTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterGetBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterCalcQtyAvailBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyAvailBase: Decimal; NewBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateUoMCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnAfterCalcQtyToHandleBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandleBase: Decimal; var NewQtyToHandleBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnBeforeCalcQtyToHandleBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var xWarehouseActivityLine: Record "Warehouse Activity Line"; Location: Record Location; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterGetItemVariant(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemVariant: Record "Item Variant"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBin(var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeUOMCode(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeReNumberWhseActivityLines(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var NewLineNo: Integer; var LineSpacing: Integer; var sHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityIsBalanced(var WhseActivLine: Record "Warehouse Activity Line"; xWhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyWhenSNDefined(WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservedItemTrkgOnCheckTypeElseCase(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    begin
    end;

    [Obsolete('Replaced by OnCheckReservedItemTrkgOnCheckTypeElseCase().', '18.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckReservedItemTrkgOnCkeckTypeElseCase(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeWhseActivLine2Find(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine: record "Warehouse Activity Line"; CalledFromHeader: Boolean; var DeleteLineConfirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeDeleteWhseActivLine2(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine2: Record "Warehouse Activity Line"; var CalledFromHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIncreaseCapacityOnBeforeCheckIncreaseBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Bin: Record Bin; DeductCubage: Decimal; DeductWeight: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterCheckInvalidBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWhsePickCard(var WhseActivHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmWhseActivLinesDeletionOutOfBalanceOnAfterWhseActivLine3SetFilters(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line"; var WhseActivLine3: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReservedItemTrkg(var WarehouseActivityLine: Record "Warehouse Activity Line"; xRec: Record "Warehouse Activity Line"; CurrFieldNo: Integer; LineReservedQty: Integer; ReservedQty: Decimal)
    begin
        // use ReservedQty parameter instead of LineReservedQty for the same purpose
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitLineOnBeforeRenumberAllLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitLineOnAfterInitNewWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateReservationOnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateQtyToHandleOnBeforeWhseActivLineModify(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

