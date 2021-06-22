table 5407 "Prod. Order Component"
{
    Caption = 'Prod. Order Component';
    DataCaptionFields = Status, "Prod. Order No.";
    DrillDownPageID = "Prod. Order Comp. Line List";
    LookupPageID = "Prod. Order Comp. Line List";
    Permissions = TableData "Prod. Order Component" = rimd;

    fields
    {
        field(1; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Simulated,Planned,Firm Planned,Released,Finished';
            OptionMembers = Simulated,Planned,"Firm Planned",Released,Finished;
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." WHERE(Status = FIELD(Status));
        }
        field(3; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            TableRelation = "Prod. Order Line"."Line No." WHERE(Status = FIELD(Status),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item WHERE(Type = FILTER(Inventory | "Non-Inventory"));

            trigger OnValidate()
            begin
                if xRec.Find then begin
                    CalcFields("Act. Consumption (Qty)");
                    TestField("Act. Consumption (Qty)", 0);
                end;
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
                ReserveProdOrderComp.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                TestField("Remaining Qty. (Base)", "Expected Qty. (Base)");
                if "Item No." = '' then begin
                    CreateDim(DATABASE::Item, "Item No.");
                    exit;
                end;

                Item.Get("Item No.");
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    OnValidateItemNoOnBeforeGetDefaultBin(Rec, Item);
                    GetDefaultBin;
                    ClearCalcFormula;
                    if "Quantity per" <> 0 then
                        Validate("Quantity per");
                end;
                Description := Item.Description;
                Item.TestField("Base Unit of Measure");
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
                GetUpdateFromSKU;
                CreateDim(DATABASE::Item, "Item No.");
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);

                Item.Get("Item No.");
                GetGLSetup;

                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                UpdateUnitCost;

                Validate("Expected Quantity", Quantity * ProdOrderNeeds);
            end;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(16; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(17; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
        }
        field(19; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                Validate("Expected Quantity", Quantity * ProdOrderNeeds);

                ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

                "Due Date" := ProdOrderLine."Starting Date";
                "Due Time" := ProdOrderLine."Starting Time";
                if "Routing Link Code" <> '' then begin
                    ProdOrderRtngLine.SetRange(Status, Status);
                    ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                    ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                    ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
                    if ProdOrderRtngLine.FindFirst then begin
                        "Due Date" := ProdOrderRtngLine."Starting Date";
                        "Due Time" := ProdOrderRtngLine."Starting Time";
                    end;
                end;
                if Format("Lead-Time Offset") <> '' then begin
                    "Due Date" :=
                      "Due Date" -
                      (CalcDate("Lead-Time Offset", WorkDate) - WorkDate);
                    "Due Time" := 0T;
                end;

                OnValidateRoutingLinkCodeBeforeValidateDueDate(Rec, ProdOrderLine);
                Validate("Due Date");

                if "Routing Link Code" <> xRec."Routing Link Code" then
                    UpdateBin(Rec, FieldNo("Routing Link Code"), FieldCaption("Routing Link Code"));
            end;
        }
        field(20; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if Item."No." <> "Item No." then
                    Item.Get("Item No.");
                if "Variant Code" = '' then
                    Description := Item.Description
                else begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end;
                GetDefaultBin;
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
                ReserveProdOrderComp.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                TestField("Remaining Qty. (Base)", "Expected Qty. (Base)");
                UpdateUnitCost;
                Validate("Expected Quantity");
                GetUpdateFromSKU;
            end;
        }
        field(25; "Expected Quantity"; Decimal)
        {
            Caption = 'Expected Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                if Item.Get("Item No.") then
                    if Item."Rounding Precision" > 0 then begin
                        "Expected Quantity" := UOMMgt.RoundToItemRndPrecision("Expected Quantity", Item."Rounding Precision");
                        OnAfterRoundExpectedQuantity(Rec);
                    end;

                "Expected Qty. (Base)" := Round("Expected Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                if (Status in [Status::Released, Status::Finished]) and
                   (xRec."Item No." <> '') and
                   ("Line No." <> 0)
                then
                    CalcFields("Act. Consumption (Qty)");

                OnValidateExpectedQuantityOnAfterCalcActConsumptionQty(Rec, xRec);
                "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)" / "Qty. per Unit of Measure";
                if ("Remaining Quantity" * "Expected Quantity") <= 0 then
                    "Remaining Quantity" := 0;
                "Remaining Qty. (Base)" := Round("Remaining Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                "Completely Picked" := "Qty. Picked" >= "Expected Quantity";

                ReserveProdOrderComp.VerifyQuantity(Rec, xRec);

                "Cost Amount" := Round("Expected Quantity" * "Unit Cost");
                "Overhead Amount" :=
                  Round(
                    "Expected Quantity" *
                    (("Direct Unit Cost" * "Indirect Cost %" / 100) + "Overhead Rate"));
                "Direct Cost Amount" := Round("Expected Quantity" * "Direct Unit Cost");
            end;
        }
        field(26; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Act. Consumption (Qty)"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            CalcFormula = - Sum ("Item Ledger Entry".Quantity WHERE("Entry Type" = CONST(Consumption),
                                                                   "Order Type" = CONST(Production),
                                                                   "Order No." = FIELD("Prod. Order No."),
                                                                   "Order Line No." = FIELD("Prod. Order Line No."),
                                                                   "Prod. Order Comp. Line No." = FIELD("Line No.")));
            Caption = 'Act. Consumption (Qty)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Flushing Method"; Option)
        {
            Caption = 'Flushing Method';
            OptionCaption = 'Manual,Forward,Backward,Pick + Forward,Pick + Backward';
            OptionMembers = Manual,Forward,Backward,"Pick + Forward","Pick + Backward";

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                PickWhseWorksheetLine: Record "Whse. Worksheet Line";
            begin
                if ("Flushing Method" = "Flushing Method"::Backward) and (Status = Status::Released) then begin
                    ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
                    ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
                    ItemLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", "Line No.");
                    if "Line No." = 0 then
                        ItemLedgEntry.SetRange("Item No.", "Item No.");
                    if not ItemLedgEntry.IsEmpty then
                        Error(Text99000002, "Flushing Method", ItemLedgEntry.TableCaption);
                end;

                if ("Flushing Method" <> xRec."Flushing Method") and
                   (xRec."Flushing Method" in
                    [xRec."Flushing Method"::Manual,
                     xRec."Flushing Method"::"Pick + Forward",
                     xRec."Flushing Method"::"Pick + Backward"])
                then begin
                    CalcFields("Pick Qty.");
                    if "Pick Qty." <> 0 then
                        Error(Text99000007, "Flushing Method", "Item No.");

                    if "Qty. Picked" <> 0 then
                        Error(Text99000008, "Flushing Method", "Item No.");

                    if (xRec."Flushing Method" in
                        [xRec."Flushing Method"::Manual,
                         xRec."Flushing Method"::"Pick + Forward",
                         xRec."Flushing Method"::"Pick + Backward"]) and
                       ("Flushing Method" in ["Flushing Method"::Forward, "Flushing Method"::Backward])
                    then begin
                        PickWhseWorksheetLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
                        PickWhseWorksheetLine.SetRange("Source No.", "Prod. Order No.");
                        PickWhseWorksheetLine.SetRange("Source Line No.", "Prod. Order Line No.");
                        PickWhseWorksheetLine.SetRange("Source Subline No.", "Line No.");
                        if not PickWhseWorksheetLine.IsEmpty then
                            Error(Text99000002, "Flushing Method", PickWhseWorksheetLine.TableCaption);
                    end;
                end;

                if "Flushing Method" <> xRec."Flushing Method" then
                    UpdateBin(Rec, FieldNo("Flushing Method"), FieldCaption("Flushing Method"));
            end;
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                if Item."No." <> "Item No." then
                    Item.Get("Item No.");

                // Location code in allowed only for inventoriable items
                if "Location Code" <> '' then
                    Item.TestField(Type, Item.Type::Inventory);

                UpdateUnitCost;
                Validate("Expected Quantity");

                GetDefaultBin;
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
                ReserveProdOrderComp.VerifyChange(Rec, xRec);
                GetUpdateFromSKU;
            end;
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeBinCodeOnLookup(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "Item No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "Item No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Prod. Order Component",
                      FieldCaption("Bin Code"),
                      "Location Code",
                      "Bin Code", 0);
                    CheckBin;
                end;
            end;
        }
        field(35; "Supplied-by Line No."; Integer)
        {
            Caption = 'Supplied-by Line No.';
            TableRelation = "Prod. Order Line"."Line No." WHERE(Status = FIELD(Status),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."),
                                                                 "Line No." = FIELD("Supplied-by Line No."));
        }
        field(36; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(37; "Item Low-Level Code"; Integer)
        {
            Caption = 'Item Low-Level Code';
        }
        field(40; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(41; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(43; Depth; Decimal)
        {
            Caption = 'Depth';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(44; "Calculation Formula"; Enum "Quantity Calculation Formula")
        {
            Caption = 'Calculation Formula';

            trigger OnValidate()
            begin
                case "Calculation Formula" of
                    "Calculation Formula"::" ":
                        Quantity := "Quantity per";
                    "Calculation Formula"::Length:
                        Quantity := Round(Length * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width":
                        Quantity := Round(Length * Width * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width * Depth":
                        Quantity := Round(Length * Width * Depth * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::Weight:
                        Quantity := Round(Weight * "Quantity per", UOMMgt.QtyRndPrecision);
                    else
                        OnValidateCalculationFormulaEnumExtension(Rec);
                end;
                OnValidateCalculationFormulaOnAfterSetQuantity(Rec);
                "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                Validate("Expected Quantity", Quantity * ProdOrderNeeds);
            end;
        }
        field(45; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
                TestField("Item No.");
                Validate("Calculation Formula");
            end;
        }
        field(50; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                TestField("Item No.");

                Item.Get("Item No.");
                GetGLSetup;
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text99000003,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    UpdateUnitCost;
                end;
                Validate("Calculation Formula");
            end;
        }
        field(51; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
            begin
                WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
                if not Blocked then begin
                    if CurrFieldNo <> 0 then
                        CheckDateConflict.ProdOrderComponentCheck(Rec, true, true)
                    else
                        if CheckDateConflict.ProdOrderComponentCheck(Rec, not WarningRaised, false) then
                            WarningRaised := true;
                end;
                UpdateDatetime;
            end;
        }
        field(53; "Due Time"; Time)
        {
            Caption = 'Due Time';

            trigger OnValidate()
            begin
                UpdateDatetime;
            end;
        }
        field(60; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(62; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(63; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Prod. Order No."),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(5407),
                                                                            "Source Subtype" = FIELD(Status),
                                                                            "Source Batch Name" = CONST(''),
                                                                            "Source Prod. Order Line" = FIELD("Prod. Order Line No."),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            FieldClass = FlowField;
        }
        field(71; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Prod. Order No."),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(5407),
                                                                   "Source Subtype" = FIELD(Status),
                                                                   "Source Batch Name" = CONST(''),
                                                                   "Source Prod. Order Line" = FIELD("Prod. Order Line No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Expected Qty. (Base)"; Decimal)
        {
            Caption = 'Expected Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                if Status <> Status::Simulated then begin
                    if Status in [Status::Released, Status::Finished] then
                        CalcFields("Act. Consumption (Qty)");
                    OnValidateExpectedQtyBaseOnAfterCalcActConsumptionQty(Rec, xRec);
                    "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)";
                    "Remaining Qty. (Base)" := Round("Remaining Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                end;
                "Cost Amount" := Round("Expected Quantity" * "Unit Cost");
                "Overhead Amount" :=
                  Round(
                    "Expected Quantity" *
                    (("Direct Unit Cost" * "Indirect Cost %" / 100) + "Overhead Rate"));
                "Direct Cost Amount" := Round("Expected Quantity" * "Direct Unit Cost");
            end;
        }
        field(76; "Due Date-Time"; DateTime)
        {
            Caption = 'Due Date-Time';

            trigger OnValidate()
            begin
                "Due Date" := DT2Date("Due Date-Time");
                "Due Time" := DT2Time("Due Date-Time");
                Validate("Due Date");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = Exist ("Item Substitution" WHERE(Type = CONST(Item),
                                                           "Substitute Type" = CONST(Item),
                                                           "No." = FIELD("Item No."),
                                                           "Variant Code" = FIELD("Variant Code")));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5703; "Original Item No."; Code[20])
        {
            Caption = 'Original Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(5704; "Original Variant Code"; Code[10])
        {
            Caption = 'Original Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Original Item No."));
        }
        field(5750; "Pick Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                  "Source Type" = CONST(5407),
                                                                                  "Source Subtype" = FIELD(Status),
                                                                                  "Source No." = FIELD("Prod. Order No."),
                                                                                  "Source Line No." = FIELD("Prod. Order Line No."),
                                                                                  "Source Subline No." = FIELD("Line No."),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = FILTER(" " | Place),
                                                                                  "Original Breakbulk" = CONST(false),
                                                                                  "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7300; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");

                "Completely Picked" := "Qty. Picked" >= "Expected Quantity";
            end;
        }
        field(7301; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7302; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7303; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                         "Source Type" = CONST(5407),
                                                                                         "Source Subtype" = FIELD(Status),
                                                                                         "Source No." = FIELD("Prod. Order No."),
                                                                                         "Source Line No." = FIELD("Prod. Order Line No."),
                                                                                         "Source Subline No." = FIELD("Line No."),
                                                                                         "Action Type" = FILTER(" " | Place),
                                                                                         "Original Breakbulk" = CONST(false),
                                                                                         "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000754; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(99000755; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Direct Unit Cost" :=
                  Round(("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100));

                Validate("Unit Cost");
            end;
        }
        field(99000756; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(99000757; "Direct Cost Amount"; Decimal)
        {
            Caption = 'Direct Cost Amount';
            DecimalPlaces = 2 : 2;
        }
        field(99000758; "Overhead Amount"; Decimal)
        {
            Caption = 'Overhead Amount';
            DecimalPlaces = 2 : 2;
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Prod. Order Line No.", "Line No.", Status)
        {
        }
        key(Key3; Status, "Prod. Order No.", "Prod. Order Line No.", "Due Date")
        {
            SumIndexFields = "Expected Quantity", "Cost Amount";
        }
        key(Key4; Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; Status, "Item No.", "Variant Code", "Location Code", "Due Date")
        {
            SumIndexFields = "Expected Quantity", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount";
        }
        key(Key6; "Item No.", "Variant Code", "Location Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Due Date")
        {
            Enabled = false;
            SumIndexFields = "Expected Quantity", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount";
        }
        key(Key7; Status, "Prod. Order No.", "Routing Link Code", "Flushing Method")
        {
        }
        key(Key8; Status, "Prod. Order No.", "Location Code")
        {
        }
        key(Key9; "Item No.", "Variant Code", "Location Code", Status, "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Qty. (Base)", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount", "Qty. Picked (Base)";
        }
        key(Key10; Status, "Prod. Order No.", "Prod. Order Line No.", "Item Low-Level Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Supplied-by Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NewQuantity: Decimal;
        IsHandled: Boolean;
    begin
        if Status = Status::Finished then
            Error(Text000);
        if Status = Status::Released then begin
            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
            ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", "Line No.");
            if ItemLedgEntry.FindFirst then
                Error(Text99000000, ItemLedgEntry."Item No.", "Line No.");
        end;

        WhseValidateSourceLine.ProdComponentDelete(Rec);
        ReserveProdOrderComp.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);

        if "Supplied-by Line No." > 0 then begin
            IsHandled := false;
            OnDeleteOnBeforeGetProdOrderLine(Rec, IsHandled);
            if not IsHandled then
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Supplied-by Line No.") then begin
                    NewQuantity := ProdOrderLine.Quantity - "Expected Quantity";
                    if (NewQuantity = 0) or IsLineRequiredForSingleDemand(ProdOrderLine, "Prod. Order Line No.") then begin
                        ProdOrderLine.SetCalledFromComponent(true);
                        ProdOrderLine.Delete(true);
                    end else begin
                        ProdOrderLine.Validate(Quantity, NewQuantity);
                        ProdOrderLine.Modify();
                        ProdOrderLine.UpdateProdOrderComp(ProdOrderLine."Qty. per Unit of Measure");
                    end;
                end;
        end;

        ProdOrderBOMComment.SetRange(Status, Status);
        ProdOrderBOMComment.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderBOMComment.SetRange("Prod. Order Line No.", "Prod. Order Line No.");
        ProdOrderBOMComment.SetRange("Prod. Order BOM Line No.", "Line No.");
        ProdOrderBOMComment.DeleteAll();

        WhseProdRelease.DeleteLine(Rec);

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Prod. Order Component", Status, "Prod. Order No.", '',
          "Prod. Order Line No.", "Line No.", "Location Code", true);
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000);

        ReserveProdOrderComp.VerifyQuantity(Rec, xRec);

        if Status = Status::Released then
            WhseProdRelease.ReleaseLine(Rec, xRec);
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000);

        WhseValidateSourceLine.ProdComponentVerifyChange(Rec, xRec);
        ReserveProdOrderComp.VerifyChange(Rec, xRec);
        if Status = Status::Released then
            WhseProdRelease.ReleaseLine(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text99000001, TableCaption);
    end;

    var
        Text000: Label 'A finished production order component cannot be inserted, modified, or deleted.';
        Text001: Label 'The changed %1 now points to bin %2. Do you want to update the bin on this line?';
        Text99000000: Label 'You cannot delete item %1 in line %2 because at least one item ledger entry is associated with it.';
        Text99000001: Label 'You cannot rename a %1.';
        Text99000002: Label 'You cannot change flushing method to %1 when there is at least one record in table %2 associated with it.';
        Text99000003: Label 'You cannot change %1 when %2 is %3.';
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        ReservMgt: Codeunit "Reservation Management";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ItemSubstitutionMgt: Codeunit "Item Subst.";
        Reservation: Page Reservation;
        Blocked: Boolean;
        GLSetupRead: Boolean;
        Text99000007: Label 'You cannot change flushing method to %1 because a pick has already been created for production order component %2.';
        Text99000008: Label 'You cannot change flushing method to %1 because production order component %2 has already been picked.';
        Text99000009: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;
        WarningRaised: Boolean;

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        if not ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.") then
            Clear(ProdOrderLine);

        exit(
          StrSubstNo('%1 %2 %3',
            "Prod. Order No.", ProdOrder.Description, ProdOrderLine."Item No."));
    end;

    procedure ProdOrderNeeds(): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        NeededQty: Decimal;
    begin
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

        if "Due Date" = 0D then begin
            "Due Date" := ProdOrderLine."Starting Date";
            "Due Time" := ProdOrderLine."Starting Time";
            UpdateDatetime;
        end;

        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange(Status, Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        if "Routing Link Code" <> '' then
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
        if ProdOrderRtngLine.FindFirst then
            NeededQty :=
              ProdOrderLine.Quantity * (1 + ProdOrderLine."Scrap %" / 100) *
              (1 + ProdOrderRtngLine."Scrap Factor % (Accumulated)") * (1 + "Scrap %" / 100) +
              ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)"
        else
            NeededQty :=
              ProdOrderLine.Quantity * (1 + ProdOrderLine."Scrap %" / 100) * (1 + "Scrap %" / 100);

        OnAfterProdOrderNeeds(Rec, ProdOrderLine, ProdOrderRtngLine, NeededQty);

        exit(NeededQty);
    end;

    procedure GetNeededQty(CalcBasedOn: Option "Actual Output","Expected Output"; IncludePreviousPosting: Boolean): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        CapLedgEntry: Record "Capacity Ledger Entry";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        OutputQtyBase: Decimal;
        CompQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        Item.Get("Item No.");
        if Item."Rounding Precision" = 0 then
            Item."Rounding Precision" := UOMMgt.QtyRndPrecision;

        OnGetNeededQtyOnBeforeCalcBasedOn(Rec);
        if CalcBasedOn = CalcBasedOn::"Actual Output" then begin
            ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
            if not ProdOrderRtngLine.FindFirst or ("Routing Link Code" = '') then begin
                ProdOrderRtngLine.SetRange("Routing Link Code");
                ProdOrderRtngLine.SetFilter("Next Operation No.", '%1', '');
                if not ProdOrderRtngLine.FindFirst then
                    ProdOrderRtngLine."Operation No." := '';
                OnGetNeededQtyOnAfterLastOperationFound(Rec, ProdOrderRtngLine);
            end;
            if Status in [Status::Released, Status::Finished] then begin
                CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
                CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
                CapLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
                CapLedgEntry.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
                if CapLedgEntry.Find('-') then
                    repeat
                        IsHandled := false;
                        OnGetNeededQtyOnBeforeAddOutputQtyBase(CapLedgEntry, OutputQtyBase, IsHandled);
                        if not IsHandled then
                            OutputQtyBase := OutputQtyBase + CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity";
                    until CapLedgEntry.Next = 0;
            end;

            CompQtyBase := CostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, Rec, OutputQtyBase);
            OnGetNeededQtyAfterCalcCompQtyBase(Rec, CompQtyBase);

            if IncludePreviousPosting then begin
                if Status in [Status::Released, Status::Finished] then
                    CalcFields("Act. Consumption (Qty)");
                OnGetNeededQtyAfterCalcActConsumptionQty(Rec);
                exit(
                  UOMMgt.RoundToItemRndPrecision(
                    (CompQtyBase - "Act. Consumption (Qty)") / "Qty. per Unit of Measure",
                    Item."Rounding Precision"));
            end;
            exit(UOMMgt.RoundToItemRndPrecision(CompQtyBase / "Qty. per Unit of Measure", Item."Rounding Precision"));
        end;
        OnGetNeededQtyOnAfterCalcBasedOn(Rec);
        exit(Round("Remaining Quantity", Item."Rounding Precision"));
    end;

    procedure ShowReservation()
    begin
        TestField("Item No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    begin
        TestField("Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure CopyFromPlanningComp(PlanningComponent: Record "Planning Component")
    begin
        "Line No." := PlanningComponent."Line No.";
        "Item No." := PlanningComponent."Item No.";
        Description := PlanningComponent.Description;
        "Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
        "Quantity per" := PlanningComponent."Quantity per";
        Quantity := PlanningComponent.Quantity;
        Position := PlanningComponent.Position;
        "Position 2" := PlanningComponent."Position 2";
        "Position 3" := PlanningComponent."Position 3";
        "Lead-Time Offset" := PlanningComponent."Lead-Time Offset";
        "Routing Link Code" := PlanningComponent."Routing Link Code";
        "Scrap %" := PlanningComponent."Scrap %";
        "Variant Code" := PlanningComponent."Variant Code";
        "Flushing Method" := PlanningComponent."Flushing Method";
        "Location Code" := PlanningComponent."Location Code";
        if PlanningComponent."Bin Code" <> '' then
            "Bin Code" := PlanningComponent."Bin Code"
        else
            GetDefaultBin;
        Length := PlanningComponent.Length;
        Width := PlanningComponent.Width;
        Weight := PlanningComponent.Weight;
        Depth := PlanningComponent.Depth;
        "Calculation Formula" := PlanningComponent."Calculation Formula";
        "Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
        "Quantity (Base)" := PlanningComponent."Quantity (Base)";
        "Due Date" := PlanningComponent."Due Date";
        "Due Time" := PlanningComponent."Due Time";
        "Unit Cost" := PlanningComponent."Unit Cost";
        "Direct Unit Cost" := PlanningComponent."Direct Unit Cost";
        "Indirect Cost %" := PlanningComponent."Indirect Cost %";
        "Variant Code" := PlanningComponent."Variant Code";
        "Overhead Rate" := PlanningComponent."Overhead Rate";
        "Expected Quantity" := PlanningComponent."Expected Quantity";
        "Expected Qty. (Base)" := PlanningComponent."Expected Quantity (Base)";
        "Cost Amount" := PlanningComponent."Cost Amount";
        "Overhead Amount" := PlanningComponent."Overhead Amount";
        "Direct Cost Amount" := PlanningComponent."Direct Cost Amount";
        "Planning Level Code" := PlanningComponent."Planning Level Code";
        if Status in [Status::Released, Status::Finished] then
            CalcFields("Act. Consumption (Qty)");
        "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)";
        "Remaining Qty. (Base)" := Round("Remaining Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        "Shortcut Dimension 1 Code" := PlanningComponent."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PlanningComponent."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PlanningComponent."Dimension Set ID";

        OnAfterCopyFromPlanningComp(Rec, PlanningComponent);
    end;

    procedure AdjustQtyToQtyPicked(var QtyToPost: Decimal)
    var
        AdjustedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustQtyToQtyPicked(Rec, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        AdjustedQty :=
          "Qty. Picked" + WhseValidateSourceLine.CalcNextLevelProdOutput(Rec) -
          ("Expected Quantity" - "Remaining Quantity");

        if QtyToPost > AdjustedQty then
            QtyToPost := AdjustedQty;
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
        ReserveProdOrderComp.Block(Blocked);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, '',
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ProdOrderLine."Dimension Set ID", DATABASE::Item);
    end;

    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" < 0);
    end;

    procedure OpenItemTrackingLines()
    begin
        ReserveProdOrderComp.CallItemTracking(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    local procedure GetUpdateFromSKU()
    var
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
    begin
        GetPlanningParameters.AtSKU(SKU, "Item No.", "Variant Code", "Location Code");
        Validate("Flushing Method", SKU."Flushing Method");
    end;

    procedure UpdateDatetime()
    begin
        if ("Due Date" <> 0D) and ("Due Time" <> 0T) then
            "Due Date-Time" := CreateDateTime("Due Date", "Due Time")
        else
            "Due Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Prod. Order Component", Status,
            "Prod. Order No.", '', "Prod. Order Line No.", "Line No."));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetDefaultBin()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code") and
           ("Routing Link Code" = xRec."Routing Link Code")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then
            Validate("Bin Code", GetDefaultConsumptionBin(ProdOrderRtngLine));
    end;

    procedure GetDefaultConsumptionBin(var ProdOrderRtngLine: Record "Prod. Order Routing Line") BinCode: Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        OnBeforeGetDefaultConsumptionBin(Rec, ProdOrderRtngLine, BinCode);

        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        if "Location Code" = ProdOrderLine."Location Code" then
            if FindFirstRtngLine(ProdOrderRtngLine, ProdOrderLine) then
                BinCode := GetBinCodeFromRtngLine(ProdOrderRtngLine);

        OnGetDefaultConsumptionBinOnAfterGetBinCodeFromRtngLine(Rec, ProdOrderRtngLine, BinCode);
        if BinCode <> '' then
            exit;

        BinCode := GetBinCodeFromLocation("Location Code");

        if BinCode <> '' then
            exit;

        GetLocation("Location Code");
        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", BinCode);
    end;

    local procedure FindFirstRtngLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetFilter("No.", '<>%1', ''); // empty No. implies blank bin codes - ignore these
        ProdOrderRtngLine.SetRange("Previous Operation No.", ''); // first operation
        if "Routing Link Code" <> '' then begin
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
            ProdOrderRtngLine.SetRange("Previous Operation No.");
            if ProdOrderRtngLine.Count = 0 then begin // no routing line with Routing Link Code found- use 1st op
                ProdOrderRtngLine.SetRange("Routing Link Code");
                ProdOrderRtngLine.SetRange("Previous Operation No.", '');
            end;
        end;

        exit(ProdOrderRtngLine.FindFirst);
    end;

    local procedure GetBinCodeFromRtngLine(ProdOrderRtngLine: Record "Prod. Order Routing Line") BinCode: Code[20]
    begin
        case "Flushing Method" of
            "Flushing Method"::Manual,
          "Flushing Method"::"Pick + Forward",
          "Flushing Method"::"Pick + Backward":
                BinCode := ProdOrderRtngLine."To-Production Bin Code";
            "Flushing Method"::Forward,
          "Flushing Method"::Backward:
                BinCode := ProdOrderRtngLine."Open Shop Floor Bin Code";
        end;
    end;

    local procedure GetBinCodeFromLocation(LocationCode: Code[10]) BinCode: Code[20]
    begin
        GetLocation(LocationCode);
        case "Flushing Method" of
            "Flushing Method"::Manual,
          "Flushing Method"::"Pick + Forward",
          "Flushing Method"::"Pick + Backward":
                BinCode := Location."To-Production Bin Code";
            "Flushing Method"::Forward,
          "Flushing Method"::Backward:
                BinCode := Location."Open Shop Floor Bin Code";
        end;
        OnAfterGetBinCodeFromLocation(Rec, Location, BinCode);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        exit(StrSubstNo('%1 %2 %3 %4 %5', Status, TableCaption, "Prod. Order No.", "Item No.", ProdOrderLine."Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Line No.", '', "Prod. Order Line No.");
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Prod. Order Component", Status, "Prod. Order No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', "Prod. Order Line No.");

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure UpdateBin(var ProdOrderComp: Record "Prod. Order Component"; FieldNo: Integer; FieldCaption: Text[30])
    var
        ProdOrderComp2: Record "Prod. Order Component";
        OverwriteBinCode: Boolean;
    begin
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2.GetDefaultBin;
        if ProdOrderComp."Bin Code" <> ProdOrderComp2."Bin Code" then
            if CurrFieldNo = FieldNo then begin
                if Confirm(Text001, false, FieldCaption, ProdOrderComp2."Bin Code") then
                    OverwriteBinCode := true;
            end else
                OverwriteBinCode := true;
        if OverwriteBinCode then
            ProdOrderComp."Bin Code" := ProdOrderComp2."Bin Code";
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if not Location."Directed Put-away and Pick" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "Item No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckWhseClass(IgnoreErrors) then
                    ErrorOccured := true;
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckWhseClass("Item No.", IgnoreErrors) then
                    ErrorOccured := true;
            end;
        end;
        if ErrorOccured then
            "Bin Code" := '';
    end;

    procedure AutoReserve()
    var
        Item: Record Item;
        FullAutoReservation: Boolean;
    begin
        if Status in [Status::Simulated, Status::Finished] then
            exit;

        TestField("Item No.");
        Item.Get("Item No.");
        OnBeforeAutoReserve(Item, Rec);
        if Item.Reserve <> Item.Reserve::Always then
            exit;

        if "Remaining Qty. (Base)" <> 0 then begin
            TestField("Due Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Due Date", "Remaining Quantity", "Remaining Qty. (Base)");
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            Find;
            if not FullAutoReservation and
               (CurrFieldNo <> 0)
            then
                if Confirm(Text99000009, true) then begin
                    Commit();
                    ShowReservation;
                    Find;
                end;
        end;

        OnAfterAutoReserve(Item, Rec);
    end;

    procedure ShowItemSub()
    begin
        ItemSubstitutionMgt.GetCompSubst(Rec);
    end;

    local procedure GetSKU(): Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "Item No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            exit(true);

        exit(false);
    end;

    local procedure ClearCalcFormula()
    begin
        "Calculation Formula" := "Calculation Formula"::" ";
        Length := 0;
        Width := 0;
        Weight := 0;
        Depth := 0;
    end;

    local procedure UpdateUnitCost()
    begin
        if GetSKU then
            "Unit Cost" := SKU."Unit Cost"
        else
            "Unit Cost" := Item."Unit Cost";

        "Unit Cost" :=
          Round("Unit Cost" * "Qty. per Unit of Measure",
            GLSetup."Unit-Amount Rounding Precision");

        "Indirect Cost %" := Round(Item."Indirect Cost %", UOMMgt.QtyRndPrecision);

        "Overhead Rate" :=
          Round(Item."Overhead Rate" * "Qty. per Unit of Measure",
            GLSetup."Unit-Amount Rounding Precision");

        "Direct Unit Cost" :=
          Round(
            ("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100),
            GLSetup."Unit-Amount Rounding Precision");

        OnAfterUpdateUnitCost(Rec, GLSetup);
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; IncludeFirmPlanned: Boolean)
    begin
        Reset;
        SetCurrentKey("Item No.", "Variant Code", "Location Code", Status, "Due Date");
        if IncludeFirmPlanned then
            SetRange(Status, Status::Planned, Status::Released)
        else
            SetFilter(Status, '%1|%2', Status::Planned, Status::Released);
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Remaining Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; IncludeFirmPlanned: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IncludeFirmPlanned);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; IncludeFirmPlanned: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IncludeFirmPlanned);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code", "Due Date");
        SetRange(Status, NewStatus);
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Qty. (Base)", '<0')
        else
            SetFilter("Remaining Qty. (Base)", '>0');
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', Status, "Prod. Order No.", "Prod. Order Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure SetFilterByReleasedOrderNo(OrderNo: Code[20])
    begin
        Reset;
        SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.");
        SetRange(Status, Status::Released);
        SetRange("Prod. Order No.", OrderNo);
    end;

    [Scope('OnPrem')]
    procedure SetFilterFromProdBOMLine(ProdBOMLine: Record "Production BOM Line")
    begin
        SetRange("Item No.", ProdBOMLine."No.");
        SetRange("Variant Code", ProdBOMLine."Variant Code");
        SetRange("Routing Link Code", ProdBOMLine."Routing Link Code");
        SetRange(Position, ProdBOMLine.Position);
        SetRange("Position 2", ProdBOMLine."Position 2");
        SetRange("Position 3", ProdBOMLine."Position 3");
        SetRange(Length, ProdBOMLine.Length);
        SetRange(Width, ProdBOMLine.Width);
        SetRange(Weight, ProdBOMLine.Weight);
        SetRange(Depth, ProdBOMLine.Depth);
        SetRange("Unit of Measure Code", ProdBOMLine."Unit of Measure Code");
    end;

    local procedure IsLineRequiredForSingleDemand(ProdOrderLine: Record "Prod. Order Line"; DemandLineNo: Integer): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetFilter("Prod. Order Line No.", '<>%1', DemandLineNo);
        ProdOrderComponent.SetRange("Supplied-by Line No.", ProdOrderLine."Line No.");
        exit(ProdOrderComponent.IsEmpty);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPlanningComp(var ProdOrderComponent: Record "Prod. Order Component"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ProdOrderComponent: Record "Prod. Order Component"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBinCodeFromLocation(var ProdOrderComponent: Record "Prod. Order Component"; Location: Record Location; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var ProdOrderComp: Record "Prod. Order Component"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderNeeds(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var NeededQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundExpectedQuantity(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ProdOrderComponent: Record "Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQtyToQtyPicked(var ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinCodeOnLookup(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultConsumptionBin(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeGetProdOrderLine(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultConsumptionBinOnAfterGetBinCodeFromRtngLine(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyAfterCalcCompQtyBase(var ProdOrderComp: Record "Prod. Order Component"; var CompQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnAfterCalcBasedOn(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnAfterLastOperationFound(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnBeforeAddOutputQtyBase(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var OutputQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnBeforeCalcBasedOn(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaEnumExtension(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaOnAfterSetQuantity(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedQuantityOnAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedQtyBaseOnAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeGetDefaultBin(var ProdOrderComponent: Record "Prod. Order Component"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingLinkCodeBeforeValidateDueDate(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
}

