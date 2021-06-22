table 901 "Assembly Line"
{
    Caption = 'Assembly Line';
    DrillDownPageID = "Assembly Lines";
    LookupPageID = "Assembly Lines";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,,,Blanket Order';
            OptionMembers = Quote,"Order",,,"Blanket Order";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Assembly Header"."No." WHERE("Document Type" = FIELD("Document Type"));

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Item,Resource';
            OptionMembers = " ",Item,Resource;

            trigger OnValidate()
            begin
                TestField("Consumed Quantity", 0);
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen;

                "No." := '';
                "Variant Code" := '';
                "Location Code" := '';
                "Bin Code" := '';
                InitResourceUsageType;
                "Inventory Posting Group" := '';
                "Gen. Prod. Posting Group" := '';
                Clear("Lead-Time Offset");
            end;
        }
        field(11; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Item)) Item WHERE(Type = FILTER(Inventory | "Non-Inventory"))
            ELSE
            IF (Type = CONST(Resource)) Resource;

            trigger OnValidate()
            begin
                "Location Code" := '';
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                if "No." <> '' then
                    CheckItemAvailable(FieldNo("No."));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen;

                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    InitResourceUsageType;
                end;

                if "No." = '' then
                    Init
                else begin
                    GetHeader;
                    "Due Date" := AssemblyHeader."Starting Date";
                    case Type of
                        Type::Item:
                            CopyFromItem;
                        Type::Resource:
                            CopyFromResource;
                    end
                end;
            end;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."),
                                                                             Code = FIELD("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                TestField(Type, Type::Item);
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Variant Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen;

                if "Variant Code" = '' then begin
                    GetItemResource;
                    Description := Item.Description;
                    "Description 2" := Item."Description 2"
                end else begin
                    ItemVariant.Get("No.", "Variant Code");
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;

                GetDefaultBin;
                "Unit Cost" := GetUnitCost;
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
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
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';

            trigger OnValidate()
            begin
                GetHeader;
                ValidateLeadTimeOffset(AssemblyHeader, "Lead-Time Offset", true);
            end;
        }
        field(19; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            OptionCaption = ' ,Direct,Fixed';
            OptionMembers = " ",Direct,"Fixed";

            trigger OnValidate()
            begin
                if "Resource Usage Type" = xRec."Resource Usage Type" then
                    exit;

                if Type = Type::Resource then
                    TestField("Resource Usage Type")
                else
                    TestField("Resource Usage Type", "Resource Usage Type"::" ");

                GetHeader;
                Validate(Quantity, CalcQuantity("Quantity per", AssemblyHeader.Quantity));
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);

                Item.Get("No.");
                // Location code in allowed only for inventoriable items
                if "Location Code" <> '' then
                    Item.TestField(Type, Item.Type::Inventory);

                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Location Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen;

                GetDefaultBin;

                "Unit Cost" := GetUnitCost;
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
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
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField(Type, Type::Item);
                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestStatusOpen;
                TestField(Type, Type::Item);
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Assembly Line",
                      FieldCaption("Bin Code"),
                      "Location Code",
                      "Bin Code", 0);
                    CheckBin;
                end;
            end;
        }
        field(25; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(26; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(27; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Type, Type::Item);
                    TestField(Quantity);
                    if Quantity < 0 then
                        FieldError(Quantity, Text029);
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    "Location Code" := ItemLedgEntry."Location Code";
                    if not ItemLedgEntry.Open then
                        Message(Text042, "Appl.-to Item Entry");
                end;
            end;
        }
        field(39; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);

                RoundQty(Quantity);
                "Quantity (Base)" := CalcBaseQty(Quantity);
                InitRemainingQty;
                InitQtyToConsume;

                CheckItemAvailable(FieldNo(Quantity));
                VerifyReservationQuantity(Rec, xRec);

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(41; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(42; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(43; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(44; "Consumed Quantity"; Decimal)
        {
            Caption = 'Consumed Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(45; "Consumed Quantity (Base)"; Decimal)
        {
            Caption = 'Consumed Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(46; "Quantity to Consume"; Decimal)
        {
            Caption = 'Quantity to Consume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                RoundQty("Quantity to Consume");
                RoundQty("Remaining Quantity");
                if "Quantity to Consume" > "Remaining Quantity" then
                    Error(Text003,
                      FieldCaption("Quantity to Consume"), FieldCaption("Remaining Quantity"), "Remaining Quantity");

                Validate("Quantity to Consume (Base)", CalcBaseQty("Quantity to Consume"));
            end;
        }
        field(47; "Quantity to Consume (Base)"; Decimal)
        {
            Caption = 'Quantity to Consume (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(48; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(901),
                                                                   "Source Subtype" = FIELD("Document Type"),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(901),
                                                                            "Source Subtype" = FIELD("Document Type"),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Avail. Warning"; Boolean)
        {
            Caption = 'Avail. Warning';
            Editable = false;
        }
        field(51; "Substitution Available"; Boolean)
        {
            CalcFormula = Exist ("Item Substitution" WHERE(Type = CONST(Item),
                                                           "Substitute Type" = CONST(Item),
                                                           "No." = FIELD("No."),
                                                           "Variant Code" = FIELD("Variant Code")));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                GetHeader;
                ValidateDueDate(AssemblyHeader, "Due Date", true);
            end;
        }
        field(53; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;

                CalcFields("Reserved Qty. (Base)");
                if Reserve = Reserve::Never then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItemResource;
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(60; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                if Type = Type::" " then
                    Error(Text99000002, FieldCaption("Quantity per"), FieldCaption(Type), Type::" ");
                RoundQty("Quantity per");

                GetHeader;
                Validate(Quantity, CalcQuantity("Quantity per", AssemblyHeader.Quantity));
                Validate(
                  "Quantity to Consume",
                  MinValue(MaxQtyToConsume, CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));
            end;
        }
        field(61; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(62; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(63; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                SkuItemUnitCost: Decimal;
            begin
                TestField("No.");
                GetItemResource;
                if Type = Type::Item then begin
                    SkuItemUnitCost := GetUnitCost;
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        if "Unit Cost" <> SkuItemUnitCost then
                            Error(
                              Text99000002,
                              FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(72; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."));

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
                TestStatusOpen;

                GetItemResource;
                case Type of
                    Type::Item:
                        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                    Type::Resource:
                        "Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, "Unit of Measure Code");
                    else
                        "Qty. per Unit of Measure" := 1;
                end;

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                "Unit Cost" := GetUnitCost;
                Validate(Quantity);
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
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(7301; "Pick Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                  "Source Type" = CONST(901),
                                                                                  "Source Subtype" = FIELD("Document Type"),
                                                                                  "Source No." = FIELD("Document No."),
                                                                                  "Source Line No." = FIELD("Line No."),
                                                                                  "Source Subline No." = CONST(0),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = FILTER(" " | Place),
                                                                                  "Original Breakbulk" = CONST(false),
                                                                                  "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7302; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                         "Source Type" = CONST(901),
                                                                                         "Source Subtype" = FIELD("Document Type"),
                                                                                         "Source No." = FIELD("Document No."),
                                                                                         "Source Line No." = FIELD("Line No."),
                                                                                         "Source Subline No." = CONST(0),
                                                                                         "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                         "Action Type" = FILTER(" " | Place),
                                                                                         "Original Breakbulk" = CONST(false),
                                                                                         "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7303; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" := CalcBaseQty("Qty. Picked");
            end;
        }
        field(7304; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", Type, "Location Code")
        {
            SumIndexFields = "Cost Amount", Quantity;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Location Code", "Due Date")
        {
            SumIndexFields = "Remaining Quantity (Base)", "Qty. Picked (Base)", "Consumed Quantity (Base)";
        }
        key(Key4; Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        TestStatusOpen;
        WhseValidateSourceLine.AssemblyLineDelete(Rec);
        WhseAssemblyRelease.DeleteLine(Rec);
        AssemblyLineReserve.DeleteLine(Rec);
        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
        VerifyReservationQuantity(Rec, xRec);
    end;

    trigger OnModify()
    begin
        WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);
        VerifyReservationChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        Item: Record Item;
        Resource: Record Resource;
        Text001: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        Text002: Label 'You cannot rename an %1.';
        Text003: Label '%1 cannot be higher than the %2, which is %3.';
        Text029: Label 'must be positive', Comment = 'starts with "Quantity"';
        Text042: Label 'When posting the Applied to Ledger Entry, %1 will be opened first.';
        Text99000002: Label 'You cannot change %1 when %2 is ''%3''.';
        AssemblyHeader: Record "Assembly Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        GLSetup: Record "General Ledger Setup";
        ItemSubstMgt: Codeunit "Item Subst.";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        GLSetupRead: Boolean;
        StatusCheckSuspended: Boolean;
        TestReservationDateConflict: Boolean;
        SkipVerificationsThatChangeDatabase: Boolean;
        Text049: Label '%1 cannot be later than %2 because the %3 is set to %4.';
        Text050: Label 'Due Date %1 is before work date %2.';

    procedure InitRemainingQty()
    begin
        "Remaining Quantity" := MaxValue(Quantity - "Consumed Quantity", 0);
        "Remaining Quantity (Base)" := MaxValue("Quantity (Base)" - "Consumed Quantity (Base)", 0);

        OnAfterInitRemainingQty(Rec, xRec, CurrFieldNo);
    end;

    procedure InitQtyToConsume()
    begin
        OnBeforeInitQtyToConsume(Rec, xRec, CurrFieldNo);

        GetHeader;
        "Quantity to Consume" :=
          MinValue(MaxQtyToConsume, CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble"));
        "Quantity to Consume (Base)" :=
          MinValue(
            MaxQtyToConsumeBase,
            CalcBaseQty(CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble (Base)")));

        OnAfterInitQtyToConsume(Rec, xRec, CurrFieldNo);
    end;

    procedure MaxQtyToConsume(): Decimal
    begin
        exit("Remaining Quantity");
    end;

    local procedure MaxQtyToConsumeBase(): Decimal
    begin
        exit("Remaining Quantity (Base)");
    end;

    local procedure GetSKU(): Boolean
    begin
        if Type = Type::Item then
            if (StockkeepingUnit."Location Code" = "Location Code") and
               (StockkeepingUnit."Item No." = "No.") and
               (StockkeepingUnit."Variant Code" = "Variant Code")
            then
                exit(true);
        if StockkeepingUnit.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        exit(false);
    end;

    procedure GetUnitCost(): Decimal
    var
        UnitCost: Decimal;
    begin
        GetItemResource;

        case Type of
            Type::Item:
                if GetSKU then
                    UnitCost := StockkeepingUnit."Unit Cost" * "Qty. per Unit of Measure"
                else
                    UnitCost := Item."Unit Cost" * "Qty. per Unit of Measure";
            Type::Resource:
                UnitCost := Resource."Unit Cost" * "Qty. per Unit of Measure";
        end;

        OnAfterGetUnitCost(Rec, UnitCost);

        exit(RoundUnitAmount(UnitCost));
    end;

    procedure CalcCostAmount(Qty: Decimal; UnitCost: Decimal): Decimal
    begin
        exit(Round(Qty * UnitCost));
    end;

    local procedure RoundUnitAmount(UnitAmount: Decimal): Decimal
    begin
        GetGLSetup;

        exit(Round(UnitAmount, GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        if Type = Type::Item then begin
            TestField("No.");
            TestField(Reserve);
            Clear(Reservation);
            Reservation.SetReservSource(Rec);
            Reservation.RunModal();
        end;
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if Type = Type::Item then begin
            TestField("No.");
            ReservEntry.InitSortingAndFilters(true);
            SetReservationFilters(ReservEntry);
            if Modal then
                PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
            else
                PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
        end;
    end;

    procedure UpdateAvailWarning(): Boolean
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        "Avail. Warning" := false;
        if Type = Type::Item then
            "Avail. Warning" := ItemCheckAvail.AsmOrderLineShowWarning(Rec);
        exit("Avail. Warning");
    end;

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        AssemblySetup: Record "Assembly Setup";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if not UpdateAvailWarning then
            exit;

        if "Document Type" <> "Document Type"::Order then
            exit;

        AssemblySetup.Get();
        if not AssemblySetup."Stockout Warning" then
            exit;

        if Reserve = Reserve::Always then
            exit;

        if (CalledByFieldNo = CurrFieldNo) or
           ((CalledByFieldNo = FieldNo("No.")) and (CurrFieldNo <> 0)) or
           ((CalledByFieldNo = FieldNo(Quantity)) and (CurrFieldNo = FieldNo("Quantity per")))
        then
            if ItemCheckAvail.AssemblyLineCheck(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    [Scope('OnPrem')]
    procedure ShowAvailabilityWarning()
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        TestField(Type, Type::Item);

        if "Due Date" = 0D then begin
            GetHeader;
            if AssemblyHeader."Due Date" <> 0D then
                Validate("Due Date", AssemblyHeader."Due Date")
            else
                Validate("Due Date", WorkDate);
        end;

        ItemCheckAvail.AssemblyLineCheck(Rec);
    end;

    local procedure CalcBaseQty(Qty: Decimal): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(
          UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure"));
    end;

    local procedure CalcQtyFromBase(QtyBase: Decimal): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(
          UOMMgt.CalcQtyFromBase(
            "No.", "Variant Code", "Unit of Measure Code", QtyBase, "Qty. per Unit of Measure"));
    end;

    procedure IsInbound(): Boolean
    begin
        if "Document Type" in ["Document Type"::Order, "Document Type"::Quote, "Document Type"::"Blanket Order"] then
            exit("Quantity (Base)" < 0);

        exit(false);
    end;

    procedure OpenItemTrackingLines()
    var
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        AssemblyLineReserve.CallItemTracking(Rec);
    end;

    local procedure GetItemResource()
    begin
        if Type = Type::Item then
            if Item."No." <> "No." then
                Item.Get("No.");
        if Type = Type::Resource then
            if Resource."No." <> "No." then
                Resource.Get("No.");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true
        end
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure AutoReserve()
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(Rec, IsHandled);
        if Ishandled then
            exit;

        if Type <> Type::Item then
            exit;

        TestField("No.");
        if Reserve <> Reserve::Always then
            exit;

        if "Remaining Quantity (Base)" <> 0 then begin
            TestField("Due Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Due Date", "Remaining Quantity", "Remaining Quantity (Base)");
            Find;
            if not FullAutoReservation and (CurrFieldNo <> 0) then
                if Confirm(Text001, true) then begin
                    Commit();
                    ShowReservation;
                    Find;
                end;
        end;
    end;

    procedure ReservationStatus(): Integer
    var
        Status: Option " ",Partial,Complete;
    begin
        if (Reserve = Reserve::Never) or ("Remaining Quantity" = 0) then
            exit(Status::" ");

        CalcFields("Reserved Quantity");
        if "Reserved Quantity" = 0 then begin
            if Reserve = Reserve::Always then
                exit(Status::Partial);
            exit(Status::" ");
        end;

        if "Reserved Quantity" < "Remaining Quantity" then
            exit(Status::Partial);

        exit(Status::Complete);
    end;

    procedure SetTestReservationDateConflict(NewTestReservationDateConflict: Boolean)
    begin
        TestReservationDateConflict := NewTestReservationDateConflict;
    end;

    local procedure GetHeader()
    begin
        if (AssemblyHeader."No." <> "Document No.") and ("Document No." <> '') then
            AssemblyHeader.Get("Document Type", "Document No.");
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Assembly Line", "Document Type", "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Assembly Line", "Document Type", "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

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

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; HeaderDimensionSetID: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        AssemblySetup: Record "Assembly Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimensionSetIDArr: array[10] of Integer;
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;

        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        AssemblySetup.Get();
        case AssemblySetup."Copy Component Dimensions from" of
            AssemblySetup."Copy Component Dimensions from"::"Order Header":
                begin
                    DimensionSetIDArr[1] :=
                      DimMgt.GetRecDefaultDimID(
                        Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Assembly,
                        "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
                        0, 0);
                    DimensionSetIDArr[2] := HeaderDimensionSetID;
                end;
            AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card":
                begin
                    DimensionSetIDArr[2] :=
                      DimMgt.GetRecDefaultDimID(
                        Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Assembly,
                        "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
                        0, 0);
                    DimensionSetIDArr[1] := HeaderDimensionSetID;
                end;
        end;

        "Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure UpdateDim(NewHeaderSetID: Integer; OldHeaderSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" := DimMgt.GetDeltaDimSetID("Dimension Set ID", NewHeaderSetID, OldHeaderSetID);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowItemSub()
    begin
        ItemSubstMgt.ItemAssemblySubstGet(Rec);
    end;

    procedure ShowAssemblyList()
    var
        BomComponent: Record "BOM Component";
    begin
        TestField(Type, Type::Item);
        BomComponent.SetRange("Parent Item No.", "No.");
        PAGE.Run(PAGE::"Assembly BOM", BomComponent);
    end;

    procedure ExplodeAssemblyList()
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        AssemblyLineManagement.ExplodeAsmList(Rec);
    end;

    procedure CalcQuantityPer(Qty: Decimal): Decimal
    begin
        GetHeader;
        AssemblyHeader.TestField(Quantity);

        if FixedUsage then
            exit(Qty);

        exit(Qty / AssemblyHeader.Quantity);
    end;

    procedure CalcQuantityFromBOM(LineType: Option; QtyPer: Decimal; HeaderQty: Decimal; HeaderQtyPerUOM: Decimal; LineResourceUsageType: Option): Decimal
    begin
        if FixedUsage(LineType, LineResourceUsageType) then
            exit(QtyPer);

        exit(QtyPer * HeaderQty * HeaderQtyPerUOM);
    end;

    local procedure CalcQuantity(LineQtyPer: Decimal; HeaderQty: Decimal): Decimal
    begin
        exit(CalcQuantityFromBOM(Type, LineQtyPer, HeaderQty, 1, "Resource Usage Type"));
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; DocumentType: Option)
    begin
        Reset;
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Location Code");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Remaining Quantity (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, DocumentType);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; DocumentType: Option): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; DocumentType: Option): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code", "Location Code", "Due Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Quantity (Base)", '<0')
        else
            SetFilter("Remaining Quantity (Base)", '>0');
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        AsmLine3: Record "Assembly Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
            ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        end;
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            AsmLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                AsmLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                AsmLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            Rec := AsmLine3;
        end;
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        if Type = Type::Item then begin
            Item.Get("No.");
            if "Due Date" = 0D then
                "Due Date" := WorkDate;
            Item.SetRange("Date Filter", 0D, "Due Date");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Variant Filter", "Variant Code");
        end;
    end;

    local procedure CalcAvailQuantities(var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal; var EarliestDate: Date)
    var
        OldAssemblyLine: Record "Assembly Line";
        CompanyInfo: Record "Company Information";
        AvailableToPromise: Codeunit "Available to Promise";
        AvailabilityDate: Date;
        ReservedReceipt: Decimal;
        ReservedRequirement: Decimal;
        QtyAvailable: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        LookaheadDateFormula: DateFormula;
    begin
        SetItemFilter(Item);
        AvailableInventory := AvailableToPromise.CalcAvailableInventory(Item);
        ScheduledReceipt := AvailableToPromise.CalcScheduledReceipt(Item);
        ReservedReceipt := AvailableToPromise.CalcReservedReceipt(Item);
        ReservedRequirement := AvailableToPromise.CalcReservedRequirement(Item);
        GrossRequirement := AvailableToPromise.CalcGrossRequirement(Item);

        if OrderLineExists(OldAssemblyLine) then
            if OldAssemblyLine."Due Date" > "Due Date" then
                AvailableToPromise.SetChangedAsmLine(OldAssemblyLine)
            else
                GrossRequirement -= OldAssemblyLine."Remaining Quantity";

        CompanyInfo.Get();
        LookaheadDateFormula := CompanyInfo."Check-Avail. Period Calc.";
        if Format(LookaheadDateFormula) <> '' then begin
            AvailabilityDate := Item.GetRangeMax("Date Filter");
            PeriodType := CompanyInfo."Check-Avail. Time Bucket";

            GrossRequirement :=
              GrossRequirement +
              AvailableToPromise.CalculateLookahead(
                Item, PeriodType,
                AvailabilityDate + 1,
                AvailableToPromise.AdjustedEndingDate(CalcDate(LookaheadDateFormula, AvailabilityDate), PeriodType));
        end;

        EarliestDate :=
          AvailableToPromise.EarliestAvailabilityDate(
            Item, "Remaining Quantity (Base)", "Due Date",
            OldAssemblyLine."Remaining Quantity (Base)", OldAssemblyLine."Due Date",
            QtyAvailable,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc.");

        ExpectedInventory :=
          CalcExpectedInventory(AvailableInventory, ScheduledReceipt - ReservedReceipt, GrossRequirement - ReservedRequirement);

        OnAfterCalcExpectedInventory(Rec, Item, ExpectedInventory);

        AvailableInventory := CalcQtyFromBase(AvailableInventory);
        GrossRequirement := CalcQtyFromBase(GrossRequirement);
        ScheduledReceipt := CalcQtyFromBase(ScheduledReceipt);
        ExpectedInventory := CalcQtyFromBase(ExpectedInventory);
    end;

    local procedure CalcExpectedInventory(Inventory: Decimal; ScheduledReceipt: Decimal; GrossRequirement: Decimal): Decimal
    begin
        exit(Inventory + ScheduledReceipt - GrossRequirement);
    end;

    procedure CalcAvailToAssemble(AssemblyHeader: Record "Assembly Header"; var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal; var EarliestDate: Date; var AbleToAssemble: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        TestField("Quantity per");

        CalcAvailQuantities(
          Item,
          GrossRequirement,
          ScheduledReceipt,
          ExpectedInventory,
          AvailableInventory,
          EarliestDate);

        if ExpectedInventory < "Remaining Quantity (Base)" then begin
            if ExpectedInventory < 0 then
                AbleToAssemble := 0
            else
                AbleToAssemble := Round(ExpectedInventory / "Quantity per", UOMMgt.QtyRndPrecision, '<')
        end else begin
            AbleToAssemble := AssemblyHeader."Remaining Quantity";
            EarliestDate := 0D;
        end;
    end;

    local procedure MaxValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value2);

        exit(Value);
    end;

    local procedure MinValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value);

        exit(Value2);
    end;

    local procedure RoundQty(var Qty: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Qty := UOMMgt.RoundQty(Qty);
    end;

    procedure FixedUsage(): Boolean
    begin
        exit(FixedUsage(Type, "Resource Usage Type"));
    end;

    local procedure FixedUsage(LineType: Option; LineResourceUsageType: Option): Boolean
    begin
        if (LineType = Type::Resource) and (LineResourceUsageType = "Resource Usage Type"::Fixed) then
            exit(true);

        exit(false);
    end;

    local procedure InitResourceUsageType()
    begin
        case Type of
            Type::" ", Type::Item:
                "Resource Usage Type" := "Resource Usage Type"::" ";
            Type::Resource:
                "Resource Usage Type" := "Resource Usage Type"::Direct;
        end;
    end;

    procedure SignedXX(Value: Decimal): Decimal
    begin
        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::"Blanket Order":
                exit(-Value);
        end;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Assembly Line", "Document Type", "Document No.", '', 0, "Line No."));
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Location: Record Location;
    begin
        if "Bin Code" <> '' then begin
            GetLocation(Location, "Location Code");
            if not Location."Directed Put-away and Pick" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "No.", "Variant Code", "Unit of Measure Code")
            then
                BinContent.CheckWhseClass(false)
            else begin
                Bin.Get("Location Code", "Bin Code");
                Bin.CheckWhseClass("No.", false);
            end;
        end;
    end;

    procedure GetDefaultBin()
    begin
        TestField(Type, Type::Item);
        if (Quantity * xRec.Quantity > 0) and
           ("No." = xRec."No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;

        Validate("Bin Code", FindBin);
    end;

    procedure FindBin() NewBinCode: Code[20]
    var
        Location: Record Location;
        WMSManagement: Codeunit "WMS Management";
    begin
        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation(Location, "Location Code");
            NewBinCode := Location."To-Assembly Bin Code";
            if NewBinCode <> '' then
                exit;

            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", NewBinCode);
        end;
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        GetHeader;
        if Type in [Type::Item, Type::Resource] then
            AssemblyHeader.TestField(Status, AssemblyHeader.Status::Open);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure CompletelyPicked(): Boolean
    var
        Location: Record Location;
    begin
        TestField(Type, Type::Item);
        GetLocation(Location, "Location Code");
        if Location."Require Shipment" then
            exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Remaining Quantity (Base)");
        exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Quantity to Consume (Base)");
    end;

    procedure CalcQtyToPick(): Decimal
    var
        QtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToPick(Rec, QtyToPick, IsHandled);
        if IsHandled then
            exit(QtyToPick);

        CalcFields("Pick Qty.");
        exit("Remaining Quantity" - (CalcQtyPickedNotConsumed + "Pick Qty."));
    end;

    procedure CalcQtyToPickBase(): Decimal
    var
        QtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToPickBase(Rec, QtyToPickBase, IsHandled);
        if IsHandled then
            exit(QtyToPickBase);

        CalcFields("Pick Qty. (Base)");
        exit("Remaining Quantity (Base)" - (CalcQtyPickedNotConsumedBase + "Pick Qty. (Base)"));
    end;

    procedure CalcQtyPickedNotConsumed(): Decimal
    begin
        exit("Qty. Picked" - "Consumed Quantity");
    end;

    procedure CalcQtyPickedNotConsumedBase(): Decimal
    begin
        exit("Qty. Picked (Base)" - "Consumed Quantity (Base)");
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);

        if not Item2.Get(ItemNo) then
            exit(false);
        exit(true);
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetAsmLine(Rec);
        OrderTracking.RunModal;
    end;

    local procedure OrderLineExists(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(
          ("Document Type" = "Document Type"::Order) and
          AssemblyLine.Get("Document Type", "Document No.", "Line No.") and
          (AssemblyLine.Type = Type) and
          (AssemblyLine."No." = "No.") and
          (AssemblyLine."Location Code" = "Location Code") and
          (AssemblyLine."Variant Code" = "Variant Code") and
          (AssemblyLine."Bin Code" = "Bin Code"));
    end;

    procedure VerifyReservationQuantity(var NewAsmLine: Record "Assembly Line"; var OldAsmLine: Record "Assembly Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        AssemblyLineReserve.VerifyQuantity(NewAsmLine, OldAsmLine);
    end;

    procedure VerifyReservationChange(var NewAsmLine: Record "Assembly Line"; var OldAsmLine: Record "Assembly Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        AssemblyLineReserve.VerifyChange(NewAsmLine, OldAsmLine);
    end;

    procedure VerifyReservationDateConflict(NewAsmLine: Record "Assembly Line")
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        ReservationCheckDateConfl.AssemblyLineCheck(NewAsmLine, (CurrFieldNo <> 0) or TestReservationDateConflict);
    end;

    procedure SetSkipVerificationsThatChangeDatabase(State: Boolean)
    begin
        SkipVerificationsThatChangeDatabase := State;
    end;

    procedure GetSkipVerificationsThatChangeDatabase(): Boolean
    begin
        exit(SkipVerificationsThatChangeDatabase);
    end;

    procedure ValidateDueDate(AsmHeader: Record "Assembly Header"; NewDueDate: Date; ShowDueDateBeforeWorkDateMsg: Boolean)
    var
        MaxDate: Date;
    begin
        "Due Date" := NewDueDate;
        TestStatusOpen;

        MaxDate := LatestPossibleDueDate(AsmHeader."Starting Date");
        if "Due Date" > MaxDate then
            Error(Text049, FieldCaption("Due Date"), MaxDate, AsmHeader.FieldCaption("Starting Date"), AsmHeader."Starting Date");

        if (xRec."Due Date" <> "Due Date") and (Quantity <> 0) then
            VerifyReservationDateConflict(Rec);

        CheckItemAvailable(FieldNo("Due Date"));
        WhseValidateSourceLine.AssemblyLineVerifyChange(Rec, xRec);

        if ("Due Date" < WorkDate) and ShowDueDateBeforeWorkDateMsg then
            Message(Text050, "Due Date", WorkDate);
    end;

    procedure ValidateLeadTimeOffset(AsmHeader: Record "Assembly Header"; NewLeadTimeOffset: DateFormula; ShowDueDateBeforeWorkDateMsg: Boolean)
    var
        ZeroDF: DateFormula;
    begin
        "Lead-Time Offset" := NewLeadTimeOffset;
        TestStatusOpen;

        if Type <> Type::Item then
            TestField("Lead-Time Offset", ZeroDF);
        ValidateDueDate(AsmHeader, LatestPossibleDueDate(AsmHeader."Starting Date"), ShowDueDateBeforeWorkDateMsg);
    end;

    local procedure LatestPossibleDueDate(HeaderStartingDate: Date): Date
    begin
        exit(HeaderStartingDate - (CalcDate("Lead-Time Offset", WorkDate) - WorkDate));
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    local procedure CopyFromItem()
    begin
        GetItemResource;
        if IsInventoriableItem then begin
            "Location Code" := AssemblyHeader."Location Code";
            Item.TestField("Inventory Posting Group");
        end;

        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "Inventory Posting Group" := Item."Inventory Posting Group";
        GetDefaultBin;
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        "Unit Cost" := GetUnitCost;
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
        CreateDim(DATABASE::Item, "No.", AssemblyHeader."Dimension Set ID");
        Reserve := Item.Reserve;
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume, CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));

        OnAfterCopyFromItem(Rec, Item, AssemblyHeader);
    end;

    local procedure CopyFromResource()
    begin
        GetItemResource;
        Resource.TestField("Gen. Prod. Posting Group");
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        "Inventory Posting Group" := '';
        Description := Resource.Name;
        "Description 2" := Resource."Name 2";
        "Unit Cost" := GetUnitCost;
        Validate("Unit of Measure Code", Resource."Base Unit of Measure");
        CreateDim(DATABASE::Resource, "No.", AssemblyHeader."Dimension Set ID");
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume, CalcQuantity("Quantity per", AssemblyHeader."Quantity to Assemble")));

        OnAfterCopyFromResource(Rec, Resource, AssemblyHeader);
    end;

    procedure IsInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItemResource;
        exit(Item.IsInventoriableType);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedInventory(var AssemblyLine: Record "Assembly Line"; var Item: Record Item; var ExpectedInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var AssemblyLine: Record "Assembly Line"; Item: Record Item; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromResource(var AssemblyLine: Record "Assembly Line"; Resource: Record Resource; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var AssemblyLine: Record "Assembly Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var AssemblyLine: Record "Assembly Line"; Item: Record Item; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var AssemblyLine: Record "Assembly Line"; var UnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRemainingQty(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToConsume(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var AssemblyLine: Record "Assembly Line"; var xAssemblyLine: Record "Assembly Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToPick(var AssemblyLine: Record "Assembly Line"; var QtyToPick: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToPickBase(var AssemblyLine: Record "Assembly Line"; var QtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToConsume(var AssemblyLine: Record "Assembly Line"; xAssemblyLine: Record "Assembly Line"; CurrentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var AssemblyLine: Record "Assembly Line"; var xAssemblyLine: Record "Assembly Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

