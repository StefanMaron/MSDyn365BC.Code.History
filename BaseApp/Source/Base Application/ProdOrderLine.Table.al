table 5406 "Prod. Order Line"
{
    Caption = 'Prod. Order Line';
    DataCaptionFields = "Prod. Order No.";
    DrillDownPageID = "Prod. Order Line List";
    LookupPageID = "Prod. Order Line List";
    Permissions = TableData "Prod. Order Line" = rimd;

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
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item WHERE(Type = CONST(Inventory));

            trigger OnValidate()
            begin
                ReserveProdOrderLine.VerifyChange(Rec, xRec);
                TestField("Finished Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                WhseValidateSourceLine.ProdOrderLineVerifyChange(Rec, xRec);
                if ("Item No." <> xRec."Item No.") and ("Line No." <> 0) then begin
                    DeleteRelations;
                    "Variant Code" := '';
                end;
                if "Item No." = '' then
                    Init
                else begin
                    ProdOrder.Get(Status, "Prod. Order No.");
                    "Starting Date" := ProdOrder."Starting Date";
                    "Starting Time" := ProdOrder."Starting Time";
                    "Ending Date" := ProdOrder."Ending Date";
                    "Ending Time" := ProdOrder."Ending Time";
                    "Due Date" := ProdOrder."Due Date";
                    "Location Code" := ProdOrder."Location Code";
                    "Bin Code" := ProdOrder."Bin Code";
                    if "Bin Code" = '' then
                        GetDefaultBin;

                    GetItem;
                    Item.TestField("Inventory Posting Group");
                    "Inventory Posting Group" := Item."Inventory Posting Group";

                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                    "Production BOM No." := Item."Production BOM No.";
                    "Routing No." := Item."Routing No.";

                    "Scrap %" := Item."Scrap %";
                    "Unit Cost" := Item."Unit Cost";
                    "Indirect Cost %" := Item."Indirect Cost %";
                    "Overhead Rate" := Item."Overhead Rate";
                    if "Item No." <> xRec."Item No." then begin
                        Validate("Production BOM No.", Item."Production BOM No.");
                        Validate("Routing No.", Item."Routing No.");
                        Validate("Unit of Measure Code", Item."Base Unit of Measure");
                    end;
                    OnAfterCopyFromItem(Rec, Item, xRec);
                    if ProdOrder."Source Type" = ProdOrder."Source Type"::Family then
                        "Routing Reference No." := 0
                    else
                        if "Line No." = 0 then
                            "Routing Reference No." := -10000
                        else
                            "Routing Reference No." := "Line No.";
                end;
                if "Item No." <> xRec."Item No." then
                    Validate(Quantity);
                GetUpdateFromSKU;

                CreateDim(DATABASE::Item, "Item No.");
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."),
                                                       Code = FIELD("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                ReserveProdOrderLine.VerifyChange(Rec, xRec);
                TestField("Finished Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                WhseValidateSourceLine.ProdOrderLineVerifyChange(Rec, xRec);

                if "Variant Code" = '' then begin
                    Validate("Item No.");
                    exit;
                end;

                ItemVariant.Get("Item No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
                GetUpdateFromSKU;
                GetDefaultBin;
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                ReserveProdOrderLine.VerifyChange(Rec, xRec);
                WhseValidateSourceLine.ProdOrderLineVerifyChange(Rec, xRec);
                GetUpdateFromSKU;
                GetDefaultBin;
            end;
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(22; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF (Quantity = FILTER(< 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                     "Item No." = FIELD("Item No."),
                                                                                     "Variant Code" = FIELD("Variant Code"))
            ELSE
            Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                if Quantity < 0 then
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
                    if Quantity < 0 then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "Item No.", "Variant Code", '')
                    else
                        WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Prod. Order Line",
                      FieldCaption("Bin Code"),
                      "Location Code",
                      "Bin Code", 0);
                    CheckBin;
                end;
            end;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                "Remaining Quantity" := Quantity - "Finished Quantity";
                if "Remaining Quantity" < 0 then
                    "Remaining Quantity" := 0;
                "Remaining Qty. (Base)" := "Remaining Quantity" * "Qty. per Unit of Measure";
                ReserveProdOrderLine.VerifyQuantity(Rec, xRec);
                WhseValidateSourceLine.ProdOrderLineVerifyChange(Rec, xRec);

                UpdateProdOrderComp(xRec."Qty. per Unit of Measure");

                if CurrFieldNo <> 0 then
                    Validate("Ending Time");
                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(41; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(42; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(45; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(47; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;

            trigger OnValidate()
            begin
                CheckEndingDate(CurrFieldNo <> 0);
            end;
        }
        field(48; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if "Ending Date" < "Starting Date" then
                    "Ending Date" := "Starting Date";

                Validate("Starting Time");
            end;
        }
        field(49; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Line No.") then begin
                    Modify;

                    CalcProdOrder.Recalculate(Rec, 0, true);

                    OnAfterRecalculate(Rec, 0, CurrFieldNo);

                    Get(Status, "Prod. Order No.", "Line No.");
                end;
                if CurrFieldNo <> 0 then
                    Validate("Due Date");

                UpdateDatetime;
            end;
        }
        field(50; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Ending Time");
            end;
        }
        field(51; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Line No.") then begin
                    Modify;

                    CalcProdOrder.Recalculate(Rec, 1, true);

                    OnAfterRecalculate(Rec, 1, CurrFieldNo);

                    Get(Status, "Prod. Order No.", "Line No.");
                end;
                if CurrFieldNo <> 0 then
                    Validate("Due Date");

                UpdateDatetime;
            end;
        }
        field(52; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(53; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(60; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            TableRelation = "Production BOM Header"."No.";

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
            begin
                "Production BOM Version Code" := '';
                if "Production BOM No." = '' then
                    exit;

                Validate("Production BOM Version Code", VersionMgt.GetBOMVersion("Production BOM No.", "Due Date", true));
                if "Production BOM Version Code" = '' then begin
                    ProdBOMHeader.Get("Production BOM No.");
                    ProdBOMHeader.TestField(Status, ProdBOMHeader.Status::Certified);
                    Validate("Unit of Measure Code", ProdBOMHeader."Unit of Measure Code");
                end;
            end;
        }
        field(61; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header"."No.";

            trigger OnValidate()
            var
                RoutingHeader: Record "Routing Header";
                ProdOrderRoutingLine: Record "Prod. Order Routing Line";
                CapLedgEntry: Record "Capacity Ledger Entry";
                PurchLine: Record "Purchase Line";
                ModifyRecord: Boolean;
            begin
                "Routing Version Code" := '';

                if "Routing No." <> xRec."Routing No." then begin
                    if Status = Status::Released then begin
                        if CheckCapLedgEntry then
                            Error(
                              Text99000004Err,
                              FieldCaption("Routing No."), xRec."Routing No.", CapLedgEntry.TableCaption);

                        if CheckSubcontractPurchOrder then
                            Error(
                              Text99000004Err,
                              FieldCaption("Routing No."), xRec."Routing No.", PurchLine.TableCaption);
                    end;

                    ModifyRecord := false;
                    OnBeforeDeleteProdOrderRtngLines(Rec, ModifyRecord);
                    if ModifyRecord then
                        Modify;

                    ProdOrderRoutingLine.SetRange(Status, Status);
                    ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderRoutingLine.SetRange("Routing No.", xRec."Routing No.");
                    ProdOrderRoutingLine.SetRange("Routing Reference No.", "Line No.");
                    ProdOrderRoutingLine.DeleteAll(true);

                    OnAfterDeleteProdOrderRtngLines(Rec);
                end;
                if "Routing No." = '' then
                    exit;

                Validate("Routing Version Code", VersionMgt.GetRtngVersion("Routing No.", "Due Date", true));
                if "Routing Version Code" = '' then begin
                    RoutingHeader.Get("Routing No.");
                    RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
                    "Routing Type" := RoutingHeader.Type;
                end;
            end;
        }
        field(62; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(63; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            Editable = false;
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                TestField("Item No.");
                GetItem;
                Item.TestField("Inventory Value Zero", false);
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text99000002,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                    if GetSKU then
                        "Unit Cost" := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        "Unit Cost" := Item."Unit Cost" * "Qty. per Unit of Measure";
                end;

                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Prod. Order No."),
                                                                  "Source Ref. No." = CONST(0),
                                                                  "Source Type" = CONST(5406),
                                                                  "Source Subtype" = FIELD(Status),
                                                                  "Source Batch Name" = CONST(''),
                                                                  "Source Prod. Order Line" = FIELD("Line No."),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Capacity Type Filter"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type Filter';
            FieldClass = FlowFilter;
        }
        field(71; "Capacity No. Filter"; Code[20])
        {
            Caption = 'Capacity No. Filter';
            FieldClass = FlowFilter;
            TableRelation = IF ("Capacity Type Filter" = CONST("Work Center")) "Work Center"
            ELSE
            IF ("Capacity Type Filter" = CONST("Machine Center")) "Machine Center";
        }
        field(72; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                GetItem;
                GetGLSetup;
                WhseValidateSourceLine.ProdOrderLineVerifyChange(Rec, xRec);
                "Unit Cost" := Item."Unit Cost";

                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");

                "Unit Cost" :=
                  Round(Item."Unit Cost" * "Qty. per Unit of Measure",
                    GLSetup."Unit-Amount Rounding Precision");

                Validate(Quantity);
            end;
        }
        field(81; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
                "Remaining Quantity" := Quantity - "Finished Quantity";

                Validate("Ending Time");

                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(82; "Finished Qty. (Base)"; Decimal)
        {
            Caption = 'Finished Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(83; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(84; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Prod. Order No."),
                                                                           "Source Ref. No." = CONST(0),
                                                                           "Source Type" = CONST(5406),
                                                                           "Source Subtype" = FIELD(Status),
                                                                           "Source Batch Name" = CONST(''),
                                                                           "Source Prod. Order Line" = FIELD("Line No."),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(90; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Prod. Order Routing Line"."Expected Operation Cost Amt." WHERE(Status = FIELD(Status),
                                                                                               "Prod. Order No." = FIELD("Prod. Order No."),
                                                                                               "Routing No." = FIELD("Routing No."),
                                                                                               "Routing Reference No." = FIELD("Routing Reference No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Total Exp. Oper. Output (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line".Quantity WHERE(Status = FIELD(Status),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."),
                                                                 "Routing No." = FIELD("Routing No."),
                                                                 "Routing Reference No." = FIELD("Routing Reference No."),
                                                                 "Ending Date" = FIELD("Date Filter")));
            Caption = 'Total Exp. Oper. Output (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Prod. Order Component"."Cost Amount" WHERE(Status = FIELD(Status),
                                                                           "Prod. Order No." = FIELD("Prod. Order No."),
                                                                           "Prod. Order Line No." = FIELD("Line No."),
                                                                           "Due Date" = FIELD("Date Filter")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(198; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(199; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");
                Validate("Ending Time");
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
        field(5831; "Cost Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Cost Amount (ACY)';
            Editable = false;
        }
        field(5832; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Unit Cost (ACY)';
            Editable = false;
        }
        field(99000750; "Production BOM Version Code"; Code[20])
        {
            Caption = 'Production BOM Version Code';
            TableRelation = "Production BOM Version"."Version Code" WHERE("Production BOM No." = FIELD("Production BOM No."));

            trigger OnValidate()
            var
                ProdBOMVersion: Record "Production BOM Version";
            begin
                if "Production BOM Version Code" = '' then
                    exit;

                ProdBOMVersion.Get("Production BOM No.", "Production BOM Version Code");
                ProdBOMVersion.TestField(Status, ProdBOMVersion.Status::Certified);
                Validate("Unit of Measure Code", ProdBOMVersion."Unit of Measure Code");
            end;
        }
        field(99000751; "Routing Version Code"; Code[20])
        {
            Caption = 'Routing Version Code';
            TableRelation = "Routing Version"."Version Code" WHERE("Routing No." = FIELD("Routing No."));

            trigger OnValidate()
            var
                RoutingVersion: Record "Routing Version";
            begin
                if "Routing Version Code" = '' then
                    exit;

                RoutingVersion.Get("Routing No.", "Routing Version Code");
                RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
                "Routing Type" := RoutingVersion.Type;
            end;
        }
        field(99000752; "Routing Type"; Option)
        {
            Caption = 'Routing Type';
            OptionCaption = 'Serial,Parallel';
            OptionMembers = Serial,Parallel;
        }
        field(99000753; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000754; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000755; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ReserveProdOrderLine.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000764; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(99000765; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Line No.", Status)
        {
        }
        key(Key3; Status, "Item No.", "Variant Code", "Location Code", "Ending Date")
        {
            SumIndexFields = "Remaining Qty. (Base)", "Cost Amount";
        }
        key(Key4; Status, "Item No.", "Variant Code", "Location Code", "Starting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key5; Status, "Item No.", "Variant Code", "Location Code", "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key6; Status, "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Due Date")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key7; Status, "Prod. Order No.", "Item No.")
        {
        }
        key(Key8; Status, "Prod. Order No.", "Routing No.", "Routing Reference No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Quantity, "Finished Quantity";
        }
        key(Key9; Status, "Prod. Order No.", "Planning Level Code")
        {
        }
        key(Key10; "Planning Level Code", Priority)
        {
            Enabled = false;
        }
        key(Key11; "Item No.", "Variant Code", "Location Code", Status, "Ending Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key12; "Item No.", "Variant Code", "Location Code", Status, "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        PurchLine: Record "Purchase Line";
        RefreshRecord: Boolean;
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        if Status = Status::Released then begin
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Line No.");
            if not ItemLedgEntry.IsEmpty then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", ItemLedgEntry.TableCaption);

            if CheckCapLedgEntry then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", CapLedgEntry.TableCaption);

            if CheckSubcontractPurchOrder then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", PurchLine.TableCaption);
        end;

        ReserveProdOrderLine.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        WhseValidateSourceLine.ProdOrderLineDelete(Rec);

        DeleteRelations;

        RefreshRecord := false;
        OnAfterOnDelete(Rec, RefreshRecord);
        if RefreshRecord then
            Get(Status, "Prod. Order No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        ReserveProdOrderLine.VerifyQuantity(Rec, xRec);
        if "Routing Reference No." < 0 then
            "Routing Reference No." := "Line No.";
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        ReserveProdOrderLine.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text99000001, TableCaption);
    end;

    var
        Text000: Label 'A %1 %2 cannot be inserted, modified, or deleted.';
        Text99000000: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Table Caption; %2 = Field Value; %3 = Table Caption';
        Text99000001: Label 'You cannot rename a %1.';
        Text99000002: Label 'You cannot change %1 when %2 is %3.';
        Text99000004Err: Label 'You cannot modify %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Field Caption; %2 = Field Value; %3 = Table Caption';
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProdOrder: Record "Production Order";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        DimMgt: Codeunit DimensionManagement;
        Blocked: Boolean;
        GLSetupRead: Boolean;
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;
        CalledFromComponent: Boolean;

    procedure DeleteRelations()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        ProdOrderLine.SetFilter("Line No.", '<>%1', "Line No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        if not ProdOrderLine.FindFirst then begin
            ProdOrderRoutingLine.SetRange(Status, Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
            if ProdOrderRoutingLine.FindSet(true) then
                repeat
                    ProdOrderRoutingLine.SetSkipUpdateOfCompBinCodes(true);
                    ProdOrderRoutingLine.Delete(true);
                until ProdOrderRoutingLine.Next = 0;
        end;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        ProdOrderComp.DeleteAll(true);

        if not CalledFromComponent then begin
            ProdOrderComp.SetRange("Prod. Order Line No.");
            ProdOrderComp.SetRange("Supplied-by Line No.", "Line No.");
            OnDeleteRelationsNotCalledFromComponentFilter(Rec, ProdOrderComp);
            if ProdOrderComp.Find('-') then
                repeat
                    ProdOrderComp."Supplied-by Line No." := 0;
                    ProdOrderComp."Planning Level Code" -= 1;
                    OnDeleteRelationsNotCalledFromComponentInitFields(ProdOrderComp);
                    ProdOrderComp.Modify();
                until ProdOrderComp.Next = 0;
        end;

        WhseOutputProdRelease.DeleteLine(Rec);
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        TestField("Item No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField("Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure CheckEndingDate(ShowWarning: Boolean)
    var
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
    begin
        if not Blocked then begin
            CheckDateConflict.ProdOrderLineCheck(Rec, ShowWarning);
            ReserveProdOrderLine.AssignForPlanning(Rec);
        end;

        OnAfterCheckEndingDate(Rec);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
        ReserveProdOrderLine.Block(Blocked);
        CalcProdOrder.BlockDynamicTracking(Blocked);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, '',
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ProdOrder."Dimension Set ID", DATABASE::Item);
    end;

    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" > 0);
    end;

    procedure OpenItemTrackingLines()
    begin
        ReserveProdOrderLine.CallItemTracking(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if ProdOrderCompExist then
                UpdateProdOrderCompDim("Dimension Set ID", OldDimSetID);
        end;

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

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    local procedure GetSKU(): Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "Item No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        exit(SKU.Get("Location Code", "Item No.", "Variant Code"));
    end;

    local procedure GetUpdateFromSKU()
    begin
        GetItem;
        if GetSKU then
            "Unit Cost" := SKU."Unit Cost"
        else
            "Unit Cost" := Item."Unit Cost";
    end;

    procedure UpdateDatetime()
    begin
        if ("Starting Date" <> 0D) and ("Starting Time" <> 0T) then
            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time")
        else
            "Starting Date-Time" := 0DT;

        if ("Ending Date" <> 0D) and ("Ending Time" <> 0T) then
            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time")
        else
            "Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

    procedure ShowDimensions()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', Status, "Prod. Order No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if ProdOrderCompExist then
                UpdateProdOrderCompDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Prod. Order Line", Status,
            "Prod. Order No.", '', "Line No.", 0));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then begin
            "Bin Code" := WMSManagement.GetLastOperationFromBinCode("Routing No.", "Routing Version Code", "Location Code", false, 0);
            GetLocation("Location Code");
            if "Bin Code" = '' then
                "Bin Code" := Location."From-Production Bin Code";
            if ("Bin Code" = '') and Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
        end;
        Validate("Bin Code");
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
    begin
        exit(StrSubstNo('%1 %2 %3 %4', Status, TableCaption, "Prod. Order No.", "Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Prod. Order Line", Status, "Prod. Order No.", 0, '', "Line No.");
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Prod. Order Line", Status, "Prod. Order No.", 0, false);
        ReservEntry.SetSourceFilter('', "Line No.");

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
            SetFilter("Remaining Qty. (Base)", '>0')
        else
            SetFilter("Remaining Qty. (Base)", '<0');
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure SetCalledFromComponent(NewCalledFromComponent: Boolean)
    begin
        CalledFromComponent := NewCalledFromComponent;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure UpdateProdOrderComp(QtyPerUnitOfMeasure: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ModifyRecord: Boolean;
    begin
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        if ProdOrderComp.FindSet then begin
            ModifyRecord := false;
            OnUpdateProdOrderCompOnAfterFind(Rec, ModifyRecord);
            if ModifyRecord then
                Modify;
            repeat
                if QtyPerUnitOfMeasure <> 0 then
                    ProdOrderComp.Validate(
                      "Quantity per",
                      ProdOrderComp."Quantity per" * "Qty. per Unit of Measure" /
                      QtyPerUnitOfMeasure)
                else
                    ProdOrderComp.Validate("Quantity per", "Qty. per Unit of Measure");
                OnUpdateProdOrderCompOnBeforeModify(Rec, ProdOrderComp);
                ProdOrderComp.Modify();
            until ProdOrderComp.Next = 0;
        end;
    end;

    local procedure CheckCapLedgEntry(): Boolean
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
        CapLedgEntry.SetRange("Order Line No.", "Line No.");

        exit(not CapLedgEntry.IsEmpty);
    end;

    local procedure CheckSubcontractPurchOrder(): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetCurrentKey(
          "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", "Line No.");

        exit(not PurchLine.IsEmpty);
    end;

    local procedure ProdOrderCompExist(): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        exit(not ProdOrderComp.IsEmpty);
    end;

    procedure UpdateProdOrderCompDim(NewDimSetID: Integer; OldDimSetID: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        NewCompDimSetID: Integer;
    begin
        if NewDimSetID = OldDimSetID then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        ProdOrderComp.LockTable();
        if ProdOrderComp.FindSet then
            repeat
                NewCompDimSetID := DimMgt.GetDeltaDimSetID(ProdOrderComp."Dimension Set ID", NewDimSetID, OldDimSetID);
                if ProdOrderComp."Dimension Set ID" <> NewCompDimSetID then begin
                    ProdOrderComp."Dimension Set ID" := NewCompDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ProdOrderComp."Dimension Set ID", ProdOrderComp."Shortcut Dimension 1 Code", ProdOrderComp."Shortcut Dimension 2 Code");
                    ProdOrderComp.Modify();
                end;
            until ProdOrderComp.Next = 0;
    end;

    procedure ShowRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");

        PAGE.RunModal(PAGE::"Prod. Order Routing", ProdOrderRoutingLine);
        CalcProdOrder.FindAndSetProdOrderLineBinCodeFromProdRtngLines(Status, "Prod. Order No.", "Line No.");
    end;

    procedure SetFilterByReleasedOrderNo(OrderNo: Code[20])
    begin
        Reset;
        SetCurrentKey(Status, "Prod. Order No.", "Line No.", "Item No.");
        SetRange(Status, Status::Released);
        SetRange("Prod. Order No.", OrderNo);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    [Scope('OnPrem')]
    procedure GetStartingEndingDateAndTime(var StartingTime: Time; var StartingDate: Date; var EndingTime: Time; var EndingDate: Date)
    begin
        StartingTime := DT2Time("Starting Date-Time");
        StartingDate := DT2Date("Starting Date-Time");
        EndingTime := DT2Time("Ending Date-Time");
        EndingDate := DT2Date("Ending Date-Time");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEndingDate(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; var xProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteProdOrderRtngLines(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(var ProdOrderLine: Record "Prod. Order Line"; var RefreshRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculate(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option; var CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderRtngLines(var ProdOrderLine: Record "Prod. Order Line"; var ModifyRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsNotCalledFromComponentFilter(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsNotCalledFromComponentInitFields(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateProdOrderCompOnAfterFind(var ProdOrderLine: Record "Prod. Order Line"; var ModifyRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateProdOrderCompOnBeforeModify(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;
}

