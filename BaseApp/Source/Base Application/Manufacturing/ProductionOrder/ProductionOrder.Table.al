table 5405 "Production Order"
{
    Caption = 'Production Order';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Production Order List";
    LookupPageID = "Production Order List";
    Permissions = TableData "Prod. Order Capacity Need" = r;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Production Order"."No." WHERE(Status = FIELD(Status));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    MfgSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Description" := Description;
            end;
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(9; "Source Type"; Enum "Prod. Order Source Type")
        {
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if "Source Type" <> xRec."Source Type" then
                    CheckProdOrderStatus(FieldCaption("Source Type"));
            end;
        }
        field(10; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Item)) Item WHERE(Type = CONST(Inventory))
            ELSE
            IF ("Source Type" = CONST(Family)) Family
            ELSE
            IF (Status = CONST(Simulated),
                                     "Source Type" = CONST("Sales Header")) "Sales Header"."No." WHERE("Document Type" = CONST(Quote))
            ELSE
            IF (Status = FILTER(Planned ..),
                                              "Source Type" = CONST("Sales Header")) "Sales Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            var
                Item: Record Item;
                Family: Record Family;
                SalesHeader: Record "Sales Header";
            begin
                if "Source No." <> xRec."Source No." then
                    CheckProdOrderStatus(FieldCaption("Source No."));

                if "Source No." = '' then
                    exit;

                case "Source Type" of
                    "Source Type"::Item:
                        begin
                            Item.Get("Source No.");
                            Item.TestField(Blocked, false);
                            InitFromSourceNo(
                              Item.Description, Item."Description 2", Item."Routing No.",
                              Item."Inventory Posting Group", Item."Gen. Prod. Posting Group", '', Item."Unit Cost");
                            CreateDimFromDefaultDim();
                            OnBeforeAssignItemNo(Rec, xRec, Item, CurrFieldNo);
                        end;
                    "Source Type"::Family:
                        begin
                            Family.Get("Source No.");
                            InitFromSourceNo(Family.Description, Family."Description 2", Family."Routing No.", '', '', '', 0);
                            OnBeforeAssignFamily(Rec, xRec, Family, CurrFieldNo);
                        end;
                    "Source Type"::"Sales Header":
                        begin
                            if Status = Status::Simulated then
                                SalesHeader.Get(SalesHeader."Document Type"::Quote, "Source No.")
                            else
                                SalesHeader.Get(SalesHeader."Document Type"::Order, "Source No.");
                            InitFromSourceNo(SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", '', '', '', '', 0);
                            "Location Code" := SalesHeader."Location Code";
                            "Due Date" := SalesHeader."Shipment Date";
                            "Ending Date" := SalesHeader."Shipment Date";
                            "Dimension Set ID" := SalesHeader."Dimension Set ID";
                            "Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            "Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            OnBeforeAssignSalesHeader(Rec, xRec, SalesHeader, CurrFieldNo);
                        end;
                    else
                        OnValidateSourceNoOnSourceTypeEnumExtension(Rec);
                end;
                Validate(Description);
                InitRecord();
                UpdateDatetime();
            end;
        }
        field(11; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF ("Source Type" = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("Source No."),
                                                                                        Code = FIELD("Variant Code"));

            trigger OnValidate()
            var
                Item: Record Item;
                StockkeepingUnit: Record "Stockkeeping Unit";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVariantCode(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Rec."Variant Code" = xRec."Variant Code" then
                    exit;

                TestField("Source Type", "Source Type"::Item);
                TestField("Source No.");

                if StockkeepingUnit.Get("Location Code", "Source No.", "Variant Code") and
                   (StockkeepingUnit."Routing No." <> '')
                then
                    "Routing No." := StockkeepingUnit."Routing No.";

                if ("Routing No." = '') and ("Variant Code" = '') then begin
                    Item.Get("Source No.");
                    "Routing No." := Item."Routing No.";
                end;

                InitRecord();
                UpdateDatetime();
            end;
        }
        field(15; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(16; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(17; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(19; Comment; Boolean)
        {
            CalcFormula = Exist("Prod. Order Comment Line" WHERE(Status = FIELD(Status),
                                                                  "Prod. Order No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                UpdateStartingEndingTime(0);
            end;
        }
        field(21; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                Validate("Starting Time");
            end;
        }
        field(22; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                UpdateStartingEndingTime(1);
            end;
        }
        field(23; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Ending Time");
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                if "Due Date" = 0D then
                    exit;
                if (CurrFieldNo = FieldNo("Due Date")) or
                   (CurrFieldNo = FieldNo("Location Code")) or
                   UpdateEndDate
                then begin
                    ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Planning Level Code");
                    ProdOrderLine.Ascending(true);
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "No.");
                    ProdOrderLine.SetFilter("Item No.", '<>%1', '');
                    ProdOrderLine.SetFilter("Planning Level Code", '>%1', 0);
                    if not ProdOrderLine.IsEmpty() then begin
                        ProdOrderLine.SetRange("Planning Level Code", 0);
                        if "Source Type" = "Source Type"::Family then
                            UpdateEndingDate(ProdOrderLine)
                        else begin
                            if ProdOrderLine.Find('-') then
                                "Ending Date" :=
                                    LeadTimeMgt.PlannedEndingDate(ProdOrderLine."Item No.", "Location Code", '', "Due Date", '', 2)
                            else
                                "Ending Date" := "Due Date";
                            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                            MultiLevelMessage();
                            exit;
                        end;
                    end else begin
                        ProdOrderLine.SetRange("Planning Level Code");
                        if not ProdOrderLine.IsEmpty() then
                            UpdateEndingDate(ProdOrderLine)
                        else begin
                            if "Source Type" = "Source Type"::Item then
                                "Ending Date" :=
                                    LeadTimeMgt.PlannedEndingDate("Source No.", "Location Code", '', "Due Date", '', 2)
                            else
                                "Ending Date" := "Due Date";
                            "Starting Date" := "Ending Date";
                            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                        end;
                        AdjustStartEndingDate();
                        Modify(true);
                    end;
                    OnValidateDueDateOnAfterModify(Rec);
                end;
            end;
        }
        field(25; "Finished Date"; Date)
        {
            Caption = 'Finished Date';
            Editable = false;
        }
        field(28; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(30; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(31; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(32; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                GetDefaultBin();

                Validate("Due Date"); // Scheduling consider Calendar assigned to Location
                CreateDimFromDefaultDim();
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Source Type" = CONST(Item)) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                           "Item Filter" = FIELD("Source No."))
            ELSE
            IF ("Source Type" = FILTER(<> Item)) Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if "Bin Code" <> '' then
                    WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Production Order",
                      FieldCaption("Bin Code"),
                      "Location Code",
                      "Bin Code", 0);
            end;
        }
        field(34; "Replan Ref. No."; Code[20])
        {
            Caption = 'Replan Ref. No.';
            Editable = false;
        }
        field(35; "Replan Ref. Status"; Enum "Production Order Status")
        {
            Caption = 'Replan Ref. Status';
            Editable = false;
        }
        field(38; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Source Type" = "Source Type"::Item then
                    "Cost Amount" := Round(Quantity * "Unit Cost")
                else
                    "Cost Amount" := 0;
            end;
        }
        field(41; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(42; "Cost Amount"; Decimal)
        {
            Caption = 'Cost Amount';
            DecimalPlaces = 2 : 2;
        }
        field(47; "Work Center Filter"; Code[20])
        {
            Caption = 'Work Center Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Center";
        }
        field(48; "Capacity Type Filter"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type Filter';
            FieldClass = FlowFilter;
        }
        field(49; "Capacity No. Filter"; Code[20])
        {
            Caption = 'Capacity No. Filter';
            FieldClass = FlowFilter;
            TableRelation = IF ("Capacity Type Filter" = CONST("Machine Center")) "Machine Center"
            ELSE
            IF ("Capacity Type Filter" = CONST("Work Center")) "Work Center";
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Prod. Order Routing Line"."Expected Operation Cost Amt." WHERE(Status = FIELD(Status),
                                                                                               "Prod. Order No." = FIELD("No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Prod. Order Component"."Cost Amount" WHERE(Status = FIELD(Status),
                                                                           "Prod. Order No." = FIELD("No."),
                                                                           "Due Date" = FIELD("Date Filter")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Actual Time Used"; Decimal)
        {
            CalcFormula = Sum("Capacity Ledger Entry".Quantity WHERE("Order Type" = CONST(Production),
                                                                      "Order No." = FIELD("No."),
                                                                      Type = FIELD("Capacity Type Filter"),
                                                                      "No." = FIELD("Capacity No. Filter"),
                                                                      "Posting Date" = FIELD("Date Filter")));
            Caption = 'Actual Time Used';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Allocated Capacity Need"; Decimal)
        {
            CalcFormula = Sum("Prod. Order Capacity Need"."Needed Time" WHERE(Status = FIELD(Status),
                                                                               "Prod. Order No." = FIELD("No."),
                                                                               Type = FIELD("Capacity Type Filter"),
                                                                               "No." = FIELD("Capacity No. Filter"),
                                                                               "Work Center No." = FIELD("Work Center Filter"),
                                                                               Date = FIELD("Date Filter"),
                                                                               "Requested Only" = CONST(false)));
            Caption = 'Allocated Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Expected Capacity Need"; Decimal)
        {
            CalcFormula = Sum("Prod. Order Capacity Need"."Needed Time" WHERE(Status = FIELD(Status),
                                                                               "Prod. Order No." = FIELD("No."),
                                                                               Type = FIELD("Capacity Type Filter"),
                                                                               "No." = FIELD("Capacity No. Filter"),
                                                                               "Work Center No." = FIELD("Work Center Filter"),
                                                                               Date = FIELD("Date Filter"),
                                                                               "Requested Only" = CONST(false)));
            Caption = 'Expected Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(82; "Planned Order No."; Code[20])
        {
            Caption = 'Planned Order No.';
        }
        field(83; "Firm Planned Order No."; Code[20])
        {
            Caption = 'Firm Planned Order No.';
        }
        field(85; "Simulated Order No."; Code[20])
        {
            Caption = 'Simulated Order No.';
        }
        field(92; "Expected Material Ovhd. Cost"; Decimal)
        {
            CalcFormula = Sum("Prod. Order Component"."Overhead Amount" WHERE(Status = FIELD(Status),
                                                                               "Prod. Order No." = FIELD("No.")));
            Caption = 'Expected Material Ovhd. Cost';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Expected Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Prod. Order Routing Line"."Expected Capacity Ovhd. Cost" WHERE(Status = FIELD(Status),
                                                                                               "Prod. Order No." = FIELD("No.")));
            Caption = 'Expected Capacity Ovhd. Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(99; "Ending Date-Time"; DateTime)
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
                ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(7300; "Completely Picked"; Boolean)
        {
            CalcFormula = Min("Prod. Order Component"."Completely Picked" WHERE(Status = FIELD(Status),
                                                                                 "Prod. Order No." = FIELD("No."),
                                                                                 "Supplied-by Line No." = FILTER(0)));
            Caption = 'Completely Picked';
            FieldClass = FlowField;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; Status, "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", Status)
        {
        }
        key(Key3; "Search Description")
        {
        }
        key(Key4; "Low-Level Code", "Replan Ref. No.", "Replan Ref. Status")
        {
        }
        key(Key5; "Source Type", "Source No.")
        {
            Enabled = false;
        }
        key(Key6; Description)
        {
        }
        key(Key7; "Source No.")
        {
        }
        key(Key8; "Starting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Source No.", "Source Type")
        {
        }
    }

    trigger OnDelete()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        PurchLine: Record "Purchase Line";
        RefreshRecord: Boolean;
    begin
        if Status = Status::Released then begin
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "No.");
            if not ItemLedgEntry.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", ItemLedgEntry.TableCaption());

            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
            CapLedgEntry.SetRange("Order No.", "No.");
            if not CapLedgEntry.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", CapLedgEntry.TableCaption());
        end;

        if Status in [Status::Released, Status::Finished] then begin
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange(Type, PurchLine.Type::Item);
            PurchLine.SetRange("Prod. Order No.", "No.");
            if not PurchLine.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "No.", PurchLine.TableCaption());
        end;

        if Status = Status::Finished then
            DeleteFinishedProdOrderRelations()
        else
            DeleteProdOrderRelations();

        RefreshRecord := false;
        OnAfterOnDelete(Rec, RefreshRecord);
        if RefreshRecord then
            Get(Status, "No.");
    end;

    trigger OnInsert()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, xRec, InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        MfgSetup.Get();
        if "No." = '' then begin
            TestNoSeries();
            NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Due Date", "No.", "No. Series");
        end;

        IsHandled := false;
        OnInsertOnBeforeStatusCheck(Rec, IsHandled);
        if not IsHandled then
            if Status = Status::Released then begin
                if ProdOrder.Get(Status::Finished, "No.") then
                    Error(Text007, Status, TableCaption(), ProdOrder."No.", ProdOrder.Status);
                InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
                InvtAdjmtEntryOrder.SetRange("Order No.", "No.");
                if not InvtAdjmtEntryOrder.IsEmpty() then
                    Error(Text007, Status, TableCaption(), ProdOrder."No.", InvtAdjmtEntryOrder.TableCaption());
            end;

        InitRecord();

        if MfgSetup."Normal Starting Time" <> 0T then
            Rec."Starting Time" := MfgSetup."Normal Starting Time";
        if MfgSetup."Normal Ending Time" <> 0T then
            Rec."Ending Time" := MfgSetup."Normal Ending Time";
        "Creation Date" := Today;
        UpdateDatetime();
        if MfgSetup."Normal Starting Time" = 0T then
            Rec."Starting Time" := DT2Time("Starting Date-Time");
        if MfgSetup."Normal Ending Time" = 0T then
            Rec."Ending Time" := DT2Time("Ending Date-Time");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        CheckStatusNotFinished();
    end;

    trigger OnRename()
    begin
        ShowErrorOnRename();
    end;

    var
        Text000: Label 'You cannot delete %1 %2 %3 because there is at least one %4 associated with it.', Comment = '%1 = Document status; %2 = Table caption; %3 = Field value; %4 = Table Caption';
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot change %1 on %2 %3 %4 because there is at least one %5 associated with it.', Comment = '%1 = Field caption; %2 = Document status; %3 = Table caption; %4 = Field value; %5 = Table Caption';
        MultiLevelMsg: Label 'The production order contains lines connected in a multi-level structure and the production order lines have not been automatically rescheduled.\Use Refresh if you want to reschedule the lines.';
        MfgSetup: Record "Manufacturing Setup";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Location: Record Location;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        DimMgt: Codeunit DimensionManagement;
        Text006: Label 'A Finished Production Order cannot be modified.';
        Text007: Label '%1 %2 %3 cannot be created, because a %4 %2 %3 already exists.';
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Text008: Label 'Nothing to handle.';
        UpdateEndDate: Boolean;
        Text010: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        Text011: Label 'You cannot change Finished Production Order dimensions.';

    protected var
        HideValidationDialog: Boolean;

    procedure InitRecord()
    begin
        OnBeforeInitRecord(Rec);

        if "Due Date" = 0D then
            Validate("Due Date", WorkDate());
        if ("Source Type" = "Source Type"::Item) and ("Source No." <> '') then
            "Ending Date" :=
              LeadTimeMgt.PlannedEndingDate(
                "Source No.", "Location Code", "Variant Code", "Due Date", '', 2)
        else
            "Ending Date" := "Due Date";
        "Starting Date" := "Ending Date";
        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");

        OnAfterInitRecord(Rec);
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        MfgSetup.Get();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, MfgSetup, IsHandled);
        if IsHandled then
            exit;

        case Status of
            Status::Simulated:
                MfgSetup.TestField("Simulated Order Nos.");
            Status::Planned:
                MfgSetup.TestField("Planned Order Nos.");
            Status::"Firm Planned":
                MfgSetup.TestField("Firm Planned Order Nos.");
            Status::Released:
                MfgSetup.TestField("Released Order Nos.");
        end;
    end;

    procedure AssistEdit(OldProdOrder: Record "Production Order"): Boolean
    begin
        with ProdOrder do begin
            ProdOrder := Rec;
            MfgSetup.Get();
            TestNoSeries();
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode(), OldProdOrder."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := ProdOrder;
                exit(true);
            end;
        end;
    end;

    procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        MfgSetup.Get();
        OnBeforeGetNoSeriesCode(Rec, MfgSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case Status of
            Status::Simulated:
                exit(MfgSetup."Simulated Order Nos.");
            Status::Planned:
                exit(MfgSetup."Planned Order Nos.");
            Status::"Firm Planned":
                exit(MfgSetup."Firm Planned Order Nos.");
            Status::Released:
                exit(MfgSetup."Released Order Nos.");
        end;
    end;

    procedure CheckProdOrderStatus(Name: Text[80])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if Status <> Status::Released then
            exit;

        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", "No.");
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text002,
              Name, Status, TableCaption(), "No.", ItemLedgEntry.TableCaption());

        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", "No.");
        if not CapLedgEntry.IsEmpty() then
            Error(
              Text002,
              Name, Status, TableCaption(), "No.", CapLedgEntry.TableCaption());
    end;

    local procedure CheckStatusNotFinished()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatusNotFinished(Rec, IsHandled);
        if IsHandled then
            exit;

        if Status = Status::Finished then
            Error(Text006);
    end;

    procedure DeleteProdOrderRelations()
    var
        ProdOrderComment: Record "Prod. Order Comment Line";
        WhseRequest: Record "Whse. Pick Request";
        ReservMgt: Codeunit "Reservation Management";
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderComment.SetRange(Status, Status);
        ProdOrderComment.SetRange("Prod. Order No.", "No.");
        ProdOrderComment.DeleteAll();

        ReservMgt.DeleteDocumentReservation(DATABASE::"Prod. Order Line", Status.AsInteger(), "No.", HideValidationDialog);

        DeleteProdOrderLines();

        WhseRequest.SetRange("Document Type", WhseRequest."Document Type"::Production);
        WhseRequest.SetRange("Document Subtype", Status);
        WhseRequest.SetRange("Document No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Prod. Order Component", Status.AsInteger(), "No.", '', 0, 0, '', false);
    end;

    local procedure DeleteProdOrderLines()
    begin
        OnBeforeDeleteProdOrderLines(Rec, ProdOrderLine);

        ProdOrderLine.LockTable();
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.DeleteAll(true);
    end;

    procedure DeleteFinishedProdOrderRelations()
    var
        FnshdProdOrderRtngLine: Record "Prod. Order Routing Line";
        FnshdProdOrderLine: Record "Prod. Order Line";
        FnshdProdOrderComp: Record "Prod. Order Component";
        FnshdProdOrderRtngTool: Record "Prod. Order Routing Tool";
        FnshdProdOrderRtngPers: Record "Prod. Order Routing Personnel";
        FnshdProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        FnshdProdOrderComment: Record "Prod. Order Comment Line";
        FnshdProdOrderRtngCmt: Record "Prod. Order Rtng Comment Line";
        FnshdProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
    begin
        OnBeforeDeleteFnshdProdOrderRelations(Rec);

        FnshdProdOrderRtngLine.SetRange(Status, Status);
        FnshdProdOrderRtngLine.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngLine.DeleteAll();

        FnshdProdOrderLine.SetRange(Status, Status);
        FnshdProdOrderLine.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderLine.DeleteAll();

        FnshdProdOrderComp.SetRange(Status, Status);
        FnshdProdOrderComp.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderComp.DeleteAll();

        FnshdProdOrderRtngTool.SetRange(Status, Status);
        FnshdProdOrderRtngTool.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngTool.DeleteAll();

        FnshdProdOrderRtngPers.SetRange(Status, Status);
        FnshdProdOrderRtngPers.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngPers.DeleteAll();

        FnshdProdOrderRtngQltyMeas.SetRange(Status, Status);
        FnshdProdOrderRtngQltyMeas.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngQltyMeas.DeleteAll();

        FnshdProdOrderComment.SetRange(Status, Status);
        FnshdProdOrderComment.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderComment.DeleteAll();

        FnshdProdOrderRtngCmt.SetRange(Status, Status);
        FnshdProdOrderRtngCmt.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderRtngCmt.DeleteAll();

        FnshdProdOrderBOMComment.SetRange(Status, Status);
        FnshdProdOrderBOMComment.SetRange("Prod. Order No.", "No.");
        FnshdProdOrderBOMComment.DeleteAll();
    end;

    procedure AdjustStartEndingDate()
    var
        EarliestLatestProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        EarliestLatestProdOrderLine.SetRange(Status, Status);
        EarliestLatestProdOrderLine.SetRange("Prod. Order No.", "No.");
        if EarliestLatestProdOrderLine.IsEmpty() then
            exit;

        EarliestLatestProdOrderLine.SetCurrentKey("Starting Date-Time");
        EarliestLatestProdOrderLine.FindFirst();
        "Starting Date" := EarliestLatestProdOrderLine."Starting Date";
        "Starting Time" := EarliestLatestProdOrderLine."Starting Time";

        EarliestLatestProdOrderLine.SetCurrentKey("Ending Date-Time");
        EarliestLatestProdOrderLine.FindLast();
        "Ending Date" := EarliestLatestProdOrderLine."Ending Date";
        "Ending Time" := EarliestLatestProdOrderLine."Ending Time";

        EarliestLatestProdOrderLine.SetCurrentKey("Due Date");
        EarliestLatestProdOrderLine.FindLast();

        IsHandled := false;
        OnAdjustStartEndingDateOnBeforeSetDueDate(Rec, EarliestLatestProdOrderLine, IsHandled);
        if not IsHandled then
            "Due Date" := EarliestLatestProdOrderLine."Due Date";

        UpdateDatetime();
    end;

    local procedure MultiLevelMessage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMultiLevelMessage(IsHandled, Rec, xRec, CurrFieldNo);
        if IsHandled then
            exit;

        Message(MultiLevelMsg);
    end;

    procedure UpdateDatetime()
    begin
        if (Rec."Starting Date" <> 0D) and (Rec."Starting Time" <> 0T) then
            Rec."Starting Date-Time" := CreateDateTime(Rec."Starting Date", Rec."Starting Time")
        else
            if Rec."Starting Date" = 0D then
                Rec."Starting Date-Time" := 0DT;

        if (Rec."Ending Date" <> 0D) and (Rec."Ending Time" <> 0T) then
            Rec."Ending Date-Time" := CreateDateTime(Rec."Ending Date", Rec."Ending Time")
        else
            if Rec."Ending Date" = 0D then
                Rec."Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

#if not CLEAN20
    [Obsolete('Replaced by CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])', '20.0')]
    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);
        CreateDefaultDimSourcesFromDimArray(DefaultDimSource, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled);
        if not IsHandled then begin
#if not CLEAN20
            RunEventOnAfterCreateDimTableIDs(DefaultDimSource);
#endif
            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            if Status = Status::Finished then
                Error(Text011);
            Modify();
            if ProdOrderLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Due Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure CreatePick(AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        ProdOrderCompLine: Record "Prod. Order Component";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ProdOrderCompLine.Reset();
        ProdOrderCompLine.SetRange(Status, Status);
        ProdOrderCompLine.SetRange("Prod. Order No.", "No.");
        if ProdOrderCompLine.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type"::Production, ProdOrderCompLine."Prod. Order No.",
                  ProdOrderCompLine."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderCompLine.Status.AsInteger(), ProdOrderCompLine."Prod. Order No.",
                  ProdOrderCompLine."Prod. Order Line No.", ProdOrderCompLine."Line No.");
            until ProdOrderCompLine.Next() = 0;
        Commit();

        TestField(Status, Status::Released);
        CalcFields("Completely Picked");
        if "Completely Picked" then
            Error(Text008);

        ProdOrderCompLine.Reset();
        ProdOrderCompLine.SetRange(Status, Status);
        ProdOrderCompLine.SetRange("Prod. Order No.", "No.");
        ProdOrderCompLine.SetFilter(
          "Flushing Method", '%1|%2|%3',
          ProdOrderCompLine."Flushing Method"::Manual,
          ProdOrderCompLine."Flushing Method"::"Pick + Forward",
          ProdOrderCompLine."Flushing Method"::"Pick + Backward");
        ProdOrderCompLine.SetRange("Planning Level Code", 0);
        ProdOrderCompLine.SetFilter("Expected Quantity", '>0');
        if ProdOrderCompLine.Find('-') then
            RunCreatePickFromWhseSource(AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument)
        else
            if not HideValidationDialog then
                Message(Text008);
    end;

    local procedure RunCreatePickFromWhseSource(AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreatePickFromWhseSource(Rec, AssignedUserID, SortingMethod, PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        CreatePickFromWhseSource.SetProdOrder(Rec);
        CreatePickFromWhseSource.SetHideValidationDialog(HideValidationDialog);
        if HideValidationDialog then
            CreatePickFromWhseSource.Initialize(
                AssignedUserID, "Whse. Activity Sorting Method".FromInteger(SortingMethod), PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter);
        CreatePickFromWhseSource.UseRequestPage(not HideValidationDialog);
        CreatePickFromWhseSource.RunModal();
        CreatePickFromWhseSource.GetResultMessage(2);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetFilter(
          "Source Document", '%1|%2',
          WhseRequest."Source Document"::"Prod. Consumption",
          WhseRequest."Source Document"::"Prod. Output");
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    local procedure GetDefaultBin()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        WMSManagement: Codeunit "WMS Management";
        VersionManagement: Codeunit VersionManagement;
        RoutingNo: Code[20];
        IsHandled: Boolean;
    begin
        "Bin Code" := '';

        if "Source Type" <> "Source Type"::Item then
            exit;

        if "Location Code" = '' then
            exit;

        GetLocation("Location Code");
        if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
            exit;

        if StockkeepingUnit.Get("Location Code", "Source No.", "Variant Code") then
            RoutingNo := StockkeepingUnit."Routing No.";
        if (RoutingNo = '') and Item.Get("Source No.") then
            RoutingNo := Item."Routing No.";

        // 1st priority - output bin from work/machine center
        if RoutingNo <> '' then
            "Bin Code" :=
              WMSManagement.GetLastOperationFromBinCode(
                RoutingNo, VersionManagement.GetRtngVersion(RoutingNo, "Due Date", true), "Location Code", false, 0);

        // 2nd priority - default output bin at location
        if "Bin Code" = '' then
            "Bin Code" := Location."From-Production Bin Code";

        // 3rd priority - default bin at location
        IsHandled := false;
        OnGetDefaultBinOnBeforeThirdPrioritySetBinCode(Rec, xRec, IsHandled);
        if not IsHandled then
            if ("Bin Code" = '') and ("Source No." <> '') then
                WMSManagement.GetDefaultBin("Source No.", '', "Location Code", "Bin Code");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    procedure SetUpdateEndDate()
    begin
        UpdateEndDate := true;
    end;

    local procedure UpdateStartingEndingTime(Direction: Option Forward,Backward)
    var
        IsHandled: Boolean;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Planning Level Code");
        ProdOrderLine.Ascending(Direction = Direction::Backward);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');
        ProdOrderLine.SetFilter("Planning Level Code", '>%1', 0);
        if ProdOrderLine.Find('-') then begin
            case Direction of
                Direction::Forward:
                    "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                Direction::Backward:
                    "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
            end;
            Modify();
            MultiLevelMessage();
            exit;
        end;
        "Due Date" := 0D;
        ProdOrderLine.SetRange("Planning Level Code");
        if ProdOrderLine.Find('-') then
            repeat
                case Direction of
                    Direction::Forward:
                        begin
                            ProdOrderLine."Starting Time" := "Starting Time";
                            ProdOrderLine."Starting Date" := "Starting Date";
                        end;
                    Direction::Backward:
                        begin
                            ProdOrderLine."Ending Time" := "Ending Time";
                            ProdOrderLine."Ending Date" := "Ending Date";
                        end;
                end;
                ProdOrderLine.Modify();
                CalcProdOrder.SetParameter(true);
                case Direction of
                    Direction::Forward:
                        CalcProdOrder.Recalculate(ProdOrderLine, 0, true);
                    Direction::Backward:
                        CalcProdOrder.Recalculate(ProdOrderLine, 1, true);
                end;
                IsHandled := false;
                OnBeforeUpdateProdOrderLineDueDate(ProdOrderLine, IsHandled);
                if not IsHandled then
                    if ProdOrderLine."Planning Level Code" > 0 then
                        ProdOrderLine."Due Date" := ProdOrderLine."Ending Date"
                    else
                        ProdOrderLine."Due Date" :=
                          LeadTimeMgt.PlannedDueDate(
                            ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                            ProdOrderLine."Ending Date", '', 2);
                if "Due Date" = 0D then
                    "Due Date" := ProdOrderLine."Due Date";
                case Direction of
                    Direction::Forward:
                        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                    Direction::Backward:
                        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                end;
                OnUpdateStartingEndingTimeOnBeforeProdOrderLineModify(ProdOrderLine, Rec);
                ProdOrderLine.Modify(true);
                ProdOrderLine.CheckEndingDate(CurrFieldNo <> 0);
            until ProdOrderLine.Next() = 0
        else
            case Direction of
                Direction::Forward:
                    begin
                        "Ending Date" := "Starting Date";
                        "Ending Time" := "Starting Time";
                    end;
                Direction::Backward:
                    begin
                        "Starting Date" := "Ending Date";
                        "Starting Time" := "Ending Time";
                    end;
            end;

        AdjustStartEndingDate();
        Modify();
    end;

    local procedure UpdateEndingDate(var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateEndingDate(ProdOrderLine, Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if ProdOrderLine.FindSet(true) then
            repeat
                ProdOrderLine."Due Date" := "Due Date";
                ProdOrderLine.Modify();
                CalcProdOrder.SetParameter(true);
                ProdOrderLine."Ending Date" :=
                  LeadTimeMgt.PlannedEndingDate(
                    ProdOrderLine."Item No.",
                    ProdOrderLine."Location Code",
                    ProdOrderLine."Variant Code",
                    ProdOrderLine."Due Date",
                    '',
                    2);
                OnUpdateEndingDateOnBeforeCalcProdOrderRecalculate(ProdOrderLine);
                CalcProdOrder.Recalculate(ProdOrderLine, 1, true);
                "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
                "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
                OnUpdateEndingDateOnBeforeProdOrderLineModify(ProdOrderLine, Rec);
                ProdOrderLine.Modify(true);
                ProdOrderLine.CheckEndingDate(CurrFieldNo <> 0);
            until ProdOrderLine.Next() = 0
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        TestField("No.");
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            if Status = Status::Finished then
                Error(Text011);
            Modify();
            if ProdOrderLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ProdOrderLineExist(): Boolean
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetRange(Status, Status);
        exit(not ProdOrderLine.IsEmpty());
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
        OldDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text010) then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", "No.");
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.LockTable();
        if ProdOrderLine.Find('-') then
            repeat
                OldDimSetID := ProdOrderLine."Dimension Set ID";
                NewDimSetID := DimMgt.GetDeltaDimSetID(ProdOrderLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ProdOrderLine."Dimension Set ID" <> NewDimSetID then begin
                    ProdOrderLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ProdOrderLine."Dimension Set ID", ProdOrderLine."Shortcut Dimension 1 Code", ProdOrderLine."Shortcut Dimension 2 Code");
                    ProdOrderLine.Modify();
                    ProdOrderLine.UpdateProdOrderCompDim(NewDimSetID, OldDimSetID);
                end;
            until ProdOrderLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    [Obsolete('Starting and Ending Date-Time field should be used instead.', '17.0')]
    procedure GetStartingEndingDateAndTime(var StartingTime: Time; var StartingDate: Date; var EndingTime: Time; var EndingDate: Date)
    begin
        StartingTime := DT2Time("Starting Date-Time");
        StartingDate := DT2Date("Starting Date-Time");
        EndingTime := DT2Time("Ending Date-Time");
        EndingDate := DT2Date("Ending Date-Time");
    end;

    procedure IsStatusLessThanReleased(): Boolean
    begin
        exit((Status = Status::Simulated) or (Status = Status::Planned) or (Status = Status::"Firm Planned"));
    end;

    local procedure InitFromSourceNo(SourceDescription: Text[100]; SourceDescription2: Text[50]; RoutingNo: Code[20]; InventoryPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; UnitCost: Decimal)
    begin
        Description := SourceDescription;
        "Description 2" := SourceDescription2;
        "Routing No." := RoutingNo;
        "Inventory Posting Group" := InventoryPostingGroup;
        "Gen. Prod. Posting Group" := GenProdPostingGroup;
        "Gen. Bus. Posting Group" := GenBusPostingGroup;
        "Unit Cost" := UnitCost;
    end;

    local procedure ShowErrorOnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowErrorOnRename(IsHandled, Rec);
        if IsHandled then
            exit;

        Error(Text001, TableCaption);
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Source No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

#if not CLEAN20
    local procedure CreateDefaultDimSourcesFromDimArray(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; TableID: array[10] of Integer; No: array[10] of Code[20])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
    begin
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Production Order", DefaultDimSource, TableID, No);
    end;

    local procedure CreateDimTableIDs(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
    begin
        DimArrayConversionHelper.CreateDimTableIDs(Database::"Production Order", DefaultDimSource, TableID, No);
    end;

    local procedure RunEventOnAfterCreateDimTableIDs(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunEventOnAfterCreateDimTableIDs(Rec, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        if not DimArrayConversionHelper.IsSubscriberExist(Database::"Production Order") then
            exit;

        CreateDimTableIDs(DefaultDimSource, TableID, No);
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);
        CreateDefaultDimSourcesFromDimArray(DefaultDimSource, TableID, No);
    end;

    [Obsolete('Temporary event for compatibility', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunEventOnAfterCreateDimTableIDs(var ProductionOrder: Record "Production Order"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ProductionOrder: Record "Production Order"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustStartEndingDateOnBeforeSetDueDate(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN20
    [Obsolete('Temporary event for compatibility.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ProductionOrder: Record "Production Order"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(var ProductionOrder: Record "Production Order"; var RefreshOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ProductionOrder: Record "Production Order"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemNo(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var Item: Record Item; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignFamily(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var Family: Record Family; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignSalesHeader(var ProdOrder: Record "Production Order"; xProdOrder: Record "Production Order"; var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var ProductionOrder: Record "Production Order"; MfgSetup: Record "Manufacturing Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteFnshdProdOrderRelations(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderLines(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMultiLevelMessage(var IsHandled: Boolean; var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEndingDate(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLineDueDate(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVariantCode(var ProductionOrder: Record "Production Order"; xProductionOrder: Record "Production Order"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDueDateOnAfterModify(ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSourceNoOnSourceTypeEnumExtension(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEndingDateOnBeforeCalcProdOrderRecalculate(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStartingEndingTimeOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEndingDateOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var ProductionOrder: Record "Production Order"; var xProductionOrder: Record "Production Order"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowErrorOnRename(var IsHandled: Boolean; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePickFromWhseSource(var ProductionOrder: Record "Production Order"; AssignedUserID: Code[50]; SortingMethod: Option; PrintDocument: Boolean; DoNotFillQtyToHandle: Boolean; SetBreakBulkFilter: Boolean; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(ProductionOrder: Record "Production Order"; MfgSetup: Record "Manufacturing Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatusNotFinished(ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultBinOnBeforeThirdPrioritySetBinCode(var ProductionOrder: Record "Production Order"; xProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeStatusCheck(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;
}

