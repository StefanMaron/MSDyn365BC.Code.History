table 27 Item
{
    Caption = 'Item';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Item List";
    LookupPageID = "Item Lookup";
    Permissions = TableData "Service Item" = rm,
                  TableData "Service Item Component" = rm;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetInvtSetup;
                    NoSeriesMgt.TestManual(InvtSetup."Item Nos.");
                    "No. Series" := '';
                    if xRec."No." = '' then
                        "Costing Method" := InvtSetup."Default Costing Method";
                end;
            end;
        }
        field(2; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := CopyStr(Description, 1, MaxStrLen("Search Description"));

                if "Created From Nonstock Item" then begin
                    NonstockItem.SetCurrentKey("Item No.");
                    NonstockItem.SetRange("Item No.", "No.");
                    if NonstockItem.FindFirst then
                        if NonstockItem.Description = '' then begin
                            NonstockItem.Description := Description;
                            NonstockItem.Modify;
                        end;
                end;
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
        field(6; "Assembly BOM"; Boolean)
        {
            CalcFormula = Exist ("BOM Component" WHERE("Parent Item No." = FIELD("No.")));
            Caption = 'Assembly BOM';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UnitOfMeasure: Record "Unit of Measure";
            begin
                UpdateUnitOfMeasureId;

                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then begin
                    TestNoOpenEntriesExist(FieldCaption("Base Unit of Measure"));

                    "Sales Unit of Measure" := "Base Unit of Measure";
                    "Purch. Unit of Measure" := "Base Unit of Measure";
                    if "Base Unit of Measure" <> '' then begin
                        // If we can't find a Unit of Measure with a GET,
                        // then try with International Standard Code, as some times it's used as Code
                        if not UnitOfMeasure.Get("Base Unit of Measure") then begin
                            UnitOfMeasure.SetRange("International Standard Code", "Base Unit of Measure");
                            if not UnitOfMeasure.FindFirst then
                                Error(UnitOfMeasureNotExistErr, "Base Unit of Measure");
                            "Base Unit of Measure" := UnitOfMeasure.Code;
                        end;

                        if not ItemUnitOfMeasure.Get("No.", "Base Unit of Measure") then begin
                            ItemUnitOfMeasure.Init;
                            if IsTemporary then
                                ItemUnitOfMeasure."Item No." := "No."
                            else
                                ItemUnitOfMeasure.Validate("Item No.", "No.");
                            ItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
                            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                            ItemUnitOfMeasure.Insert;
                        end else begin
                            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                        end;
                    end;
                end;
            end;
        }
        field(9; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Inventory,Service,Non-Inventory';
            OptionMembers = Inventory,Service,"Non-Inventory";

            trigger OnValidate()
            begin
                if ExistsItemLedgerEntry then
                    Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ItemLedgEntryTableCaptionTxt);
                CheckJournalsAndWorksheets(FieldNo(Type));
                CheckDocuments(FieldNo(Type));
                if IsNonInventoriableType then begin
                    CalcFields("Assembly BOM");
                    TestField("Assembly BOM", false);

                    CalcFields("Stockkeeping Unit Exists");
                    TestField("Stockkeeping Unit Exists", false);

                    Validate("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
                    Validate("Replenishment System", "Replenishment System"::Purchase);
                    Validate(Reserve, Reserve::Never);
                    Validate("Inventory Posting Group", '');
                    Validate("Item Tracking Code", '');
                    Validate("Costing Method", "Costing Method"::FIFO);
                    Validate("Production BOM No.", '');
                    Validate("Routing No.", '');
                    Validate("Reordering Policy", "Reordering Policy"::" ");
                    Validate("Order Tracking Policy", "Order Tracking Policy"::None);
                    Validate("Overhead Rate", 0);
                    Validate("Indirect Cost %", 0);
                end;
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
                if "Inventory Posting Group" <> '' then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
            TableRelation = "Item Discount Group";
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(16; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
        }
        field(17; "Commission Group"; Integer)
        {
            Caption = 'Commission Group';
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(19; "Price/Profit Calculation"; Option)
        {
            Caption = 'Price/Profit Calculation';
            OptionCaption = 'Profit=Price-Cost,Price=Cost+Profit,No Relationship';
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";

            trigger OnValidate()
            begin
                case "Price/Profit Calculation" of
                    "Price/Profit Calculation"::"Profit=Price-Cost":
                        if "Unit Price" <> 0 then
                            if "Unit Cost" = 0 then
                                "Profit %" := 0
                            else
                                "Profit %" :=
                                  Round(
                                    100 * (1 - "Unit Cost" /
                                           ("Unit Price" / (1 + CalcVAT))), 0.00001)
                        else
                            "Profit %" := 0;
                    "Price/Profit Calculation"::"Price=Cost+Profit":
                        if "Profit %" < 100 then begin
                            GetGLSetup;
                            "Unit Price" :=
                              Round(
                                ("Unit Cost" / (1 - "Profit %" / 100)) *
                                (1 + CalcVAT),
                                GLSetup."Unit-Amount Rounding Precision");
                        end;
                end;
            end;
        }
        field(20; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(21; "Costing Method"; Option)
        {
            Caption = 'Costing Method';
            OptionCaption = 'FIFO,LIFO,Specific,Average,Standard';
            OptionMembers = FIFO,LIFO,Specific,"Average",Standard;

            trigger OnValidate()
            begin
                if "Costing Method" = xRec."Costing Method" then
                    exit;

                if "Costing Method" <> "Costing Method"::FIFO then
                    TestField(Type, Type::Inventory);

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption, ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoEntriesExist(FieldCaption("Costing Method"));

                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Costing Method"));
            end;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Costing Method" = "Costing Method"::Standard then
                    Validate("Standard Cost", "Unit Cost")
                else
                    TestNoEntriesExist(FieldCaption("Unit Cost"));
                Validate("Price/Profit Calculation");
            end;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Standard Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStandardCost(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if ("Costing Method" = "Costing Method"::Standard) and (CurrFieldNo <> 0) then
                    if not GuiAllowed then begin
                        "Standard Cost" := xRec."Standard Cost";
                        exit;
                    end else
                        if not
                           Confirm(
                             Text020 +
                             Text021 +
                             Text022, false,
                             FieldCaption("Standard Cost"))
                        then begin
                            "Standard Cost" := xRec."Standard Cost";
                            exit;
                        end;

                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Standard Cost"));
            end;
        }
        field(25; "Last Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Last Direct Cost';
            MinValue = 0;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Indirect Cost %" > 0 then
                    TestField(Type, Type::Inventory);
                ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Indirect Cost %"));
            end;
        }
        field(29; "Cost is Adjusted"; Boolean)
        {
            Caption = 'Cost is Adjusted';
            Editable = false;
            InitValue = true;
        }
        field(30; "Allow Online Adjustment"; Boolean)
        {
            Caption = 'Allow Online Adjustment';
            Editable = false;
            InitValue = true;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                if (xRec."Vendor No." <> "Vendor No.") and
                   ("Vendor No." <> '')
                then
                    if Vend.Get("Vendor No.") then
                        "Lead Time Calculation" := Vend."Lead Time Calculation";
            end;
        }
        field(32; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(34; "Reorder Point"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Point';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Inventory';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
            TableRelation = Item;
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit List Price';
            MinValue = 0;
        }
        field(39; "Duty Due %"; Decimal)
        {
            Caption = 'Duty Due %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(40; "Duty Code"; Code[10])
        {
            Caption = 'Duty Code';
        }
        field(41; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(42; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(43; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(44; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(45; Durability; Code[10])
        {
            Caption = 'Durability';
        }
        field(46; "Freight Type"; Code[10])
        {
            Caption = 'Freight Type';
        }
        field(47; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            TableRelation = "Tariff Number";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TariffNumber: Record "Tariff Number";
            begin
                if "Tariff No." = '' then
                    exit;

                if (not TariffNumber.WritePermission) or
                   (not TariffNumber.ReadPermission)
                then
                    exit;

                if TariffNumber.Get("Tariff No.") then
                    exit;

                TariffNumber.Init;
                TariffNumber."No." := "Tariff No.";
                TariffNumber.Insert;
            end;
        }
        field(48; "Duty Unit Conversion"; Decimal)
        {
            Caption = 'Duty Unit Conversion';
            DecimalPlaces = 0 : 5;
        }
        field(49; "Country/Region Purchased Code"; Code[10])
        {
            Caption = 'Country/Region Purchased Code';
            TableRelation = "Country/Region";
        }
        field(50; "Budget Quantity"; Decimal)
        {
            Caption = 'Budget Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(51; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';
        }
        field(52; "Budget Profit"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budget Profit';
        }
        field(53; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST(Item),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked then
                    "Block Reason" := '';
            end;
        }
        field(55; "Cost is Posted to G/L"; Boolean)
        {
            CalcFormula = - Exist ("Post Value Entry to G/L" WHERE("Item No." = FIELD("No.")));
            Caption = 'Cost is Posted to G/L';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';

            trigger OnValidate()
            begin
                TestField(Blocked, true);
            end;
        }
        field(61; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            Editable = false;
        }
        field(62; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(63; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
            Editable = false;
        }
        field(64; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(65; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(67; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(68; Inventory; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                  "Variant Code" = FIELD("Variant Filter"),
                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                  "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Net Invoiced Qty."; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry"."Invoiced Quantity" WHERE("Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Variant Code" = FIELD("Variant Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Net Invoiced Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Net Change"; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                  "Posting Date" = FIELD("Date Filter"),
                                                                  "Variant Code" = FIELD("Variant Filter"),
                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                  "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Net Change';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Purchases (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Purchase),
                                                                             "Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Variant Code" = FIELD("Variant Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Purchases (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - Sum ("Value Entry"."Invoiced Quantity" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                        "Item No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Location Code" = FIELD("Location Filter"),
                                                                        "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                        "Variant Code" = FIELD("Variant Filter"),
                                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Positive Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST("Positive Adjmt."),
                                                                             "Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Variant Code" = FIELD("Variant Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Positive Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(74; "Negative Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = - Sum ("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST("Negative Adjmt."),
                                                                              "Item No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                              "Variant Code" = FIELD("Variant Filter"),
                                                                              "Posting Date" = FIELD("Date Filter"),
                                                                              "Lot No." = FIELD("Lot No. Filter"),
                                                                              "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Negative Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Purchases (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Purchase Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Purchase),
                                                                              "Item No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                              "Variant Code" = FIELD("Variant Filter"),
                                                                              "Posting Date" = FIELD("Date Filter")));
            Caption = 'Purchases (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                           "Item No." = FIELD("No."),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Posting Date" = FIELD("Date Filter")));
            Caption = 'Sales (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Positive Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST("Positive Adjmt."),
                                                                          "Item No." = FIELD("No."),
                                                                          "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Posting Date" = FIELD("Date Filter")));
            Caption = 'Positive Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Negative Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST("Negative Adjmt."),
                                                                          "Item No." = FIELD("No."),
                                                                          "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Posting Date" = FIELD("Date Filter")));
            Caption = 'Negative Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "COGS (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum ("Value Entry"."Cost Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                           "Item No." = FIELD("No."),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Posting Date" = FIELD("Date Filter")));
            Caption = 'COGS (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Qty. on Purch. Order"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum ("Purchase Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST(Order),
                                                                               Type = CONST(Item),
                                                                               "No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Location Code" = FIELD("Location Filter"),
                                                                               "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                               "Variant Code" = FIELD("Variant Filter"),
                                                                               "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Purch. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Qty. on Sales Order"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Sum ("Sales Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST(Order),
                                                                            Type = CONST(Item),
                                                                            "No." = FIELD("No."),
                                                                            "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Sales Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(87; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if "Price Includes VAT" then begin
                    SalesSetup.Get;
                    if SalesSetup."VAT Bus. Posting Gr. (Price)" <> '' then
                        "VAT Bus. Posting Gr. (Price)" := SalesSetup."VAT Bus. Posting Gr. (Price)";
                    VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
                end;
                Validate("Price/Profit Calculation");
            end;
        }
        field(89; "Drop Shipment Filter"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment Filter';
            FieldClass = FlowFilter;
        }
        field(90; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then begin
                    if CurrFieldNo <> 0 then
                        if ProdOrderExist then
                            if not Confirm(
                                 Text024 +
                                 Text022, false,
                                 FieldCaption("Gen. Prod. Posting Group"))
                            then begin
                                "Gen. Prod. Posting Group" := xRec."Gen. Prod. Posting Group";
                                exit;
                            end;

                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;

                Validate("Price/Profit Calculation");
            end;
        }
        field(92; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        field(93; "Transferred (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Transfer),
                                                                             "Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Variant Code" = FIELD("Variant Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Transferred (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Transferred (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Transfer),
                                                                           "Item No." = FIELD("No."),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Posting Date" = FIELD("Date Filter")));
            Caption = 'Transferred (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(95; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(98; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                UpdateTaxGroupId;
            end;
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(100; Reserve; Option)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            InitValue = Optional;
            OptionCaption = 'Never,Optional,Always';
            OptionMembers = Never,Optional,Always;

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(101; "Reserved Qty. on Inventory"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(32),
                                                                           "Source Subtype" = CONST("0"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Serial No." = FIELD("Serial No. Filter"),
                                                                           "Lot No." = FIELD("Lot No. Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter")));
            Caption = 'Reserved Qty. on Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "Reserved Qty. on Purch. Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(39),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Reserved Qty. on Purch. Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(103; "Reserved Qty. on Sales Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(37),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Reserved Qty. on Sales Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(107; "Res. Qty. on Outbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(5741),
                                                                            "Source Subtype" = CONST("0"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Outbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(108; "Res. Qty. on Inbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(5741),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Inbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(109; "Res. Qty. on Sales Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(37),
                                                                           "Source Subtype" = CONST("5"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Sales Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Res. Qty. on Purch. Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(39),
                                                                            "Source Subtype" = CONST("5"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Purch. Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(120; "Stockout Warning"; Option)
        {
            Caption = 'Stockout Warning';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(121; "Prevent Negative Inventory"; Option)
        {
            Caption = 'Prevent Negative Inventory';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(200; "Cost of Open Production Orders"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Cost Amount" WHERE(Status = FILTER(Planned | "Firm Planned" | Released),
                                                                      "Item No." = FIELD("No.")));
            Caption = 'Cost of Open Production Orders';
            FieldClass = FlowField;
        }
        field(521; "Application Wksh. User ID"; Code[128])
        {
            Caption = 'Application Wksh. User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(910; "Assembly Policy"; Option)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';
            OptionCaption = 'Assemble-to-Stock,Assemble-to-Order';
            OptionMembers = "Assemble-to-Stock","Assemble-to-Order";

            trigger OnValidate()
            begin
                if "Assembly Policy" = "Assembly Policy"::"Assemble-to-Order" then
                    TestField("Replenishment System", "Replenishment System"::Assembly);
                if IsNonInventoriableType then
                    TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
            end;
        }
        field(929; "Res. Qty. on Assembly Order"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(900),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(930; "Res. Qty. on  Asm. Comp."; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(901),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on  Asm. Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(977; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = Sum ("Assembly Header"."Remaining Quantity (Base)" WHERE("Document Type" = CONST(Order),
                                                                                   "Item No." = FIELD("No."),
                                                                                   "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Location Code" = FIELD("Location Filter"),
                                                                                   "Variant Code" = FIELD("Variant Filter"),
                                                                                   "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(978; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = Sum ("Assembly Line"."Remaining Quantity (Base)" WHERE("Document Type" = CONST(Order),
                                                                                 Type = CONST(Item),
                                                                                 "No." = FIELD("No."),
                                                                                 "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                 "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                 "Location Code" = FIELD("Location Filter"),
                                                                                 "Variant Code" = FIELD("Variant Filter"),
                                                                                 "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Asm. Component';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1001; "Qty. on Job Order"; Decimal)
        {
            CalcFormula = Sum ("Job Planning Line"."Remaining Qty. (Base)" WHERE(Status = CONST(Order),
                                                                                 Type = CONST(Item),
                                                                                 "No." = FIELD("No."),
                                                                                 "Location Code" = FIELD("Location Filter"),
                                                                                 "Variant Code" = FIELD("Variant Filter"),
                                                                                 "Planning Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Job Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1002; "Res. Qty. on Job Order"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(1003),
                                                                            "Source Subtype" = CONST("2"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Job Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1217; GTIN; Code[14])
        {
            Caption = 'GTIN';
            Numeric = true;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(5400; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(5401; "Lot Size"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Serial Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(5403; "Last Unit Cost Calc. Date"; Date)
        {
            Caption = 'Last Unit Cost Calc. Date';
            Editable = false;
        }
        field(5404; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Material Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5405; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Capacity Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5407; "Scrap %"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5409; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';

            trigger OnValidate()
            begin
                CheckForProductionOutput("No.");
            end;
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            Caption = 'Discrete Order Quantity';
            MinValue = 0;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Minimum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5413; "Safety Stock Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Order Multiple';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Lead Time';
        }
        field(5417; "Flushing Method"; Option)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Flushing Method';
            OptionCaption = 'Manual,Forward,Backward,Pick + Forward,Pick + Backward';
            OptionMembers = Manual,Forward,Backward,"Pick + Forward","Pick + Backward";
        }
        field(5419; "Replenishment System"; Option)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Replenishment System';
            OptionCaption = 'Purchase,Prod. Order,,Assembly';
            OptionMembers = Purchase,"Prod. Order",,Assembly;

            trigger OnValidate()
            begin
                if "Replenishment System" <> "Replenishment System"::Assembly then
                    TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
                if "Replenishment System" <> "Replenishment System"::Purchase then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(5420; "Scheduled Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = FILTER("Firm Planned" | Released),
                                                                                "Item No." = FIELD("No."),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Due Date" = FIELD("Date Filter")));
            Caption = 'Scheduled Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5421; "Scheduled Need (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Component"."Remaining Qty. (Base)" WHERE(Status = FILTER(Planned .. Released),
                                                                                     "Item No." = FIELD("No."),
                                                                                     "Variant Code" = FIELD("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                     "Location Code" = FIELD("Location Filter"),
                                                                                     "Due Date" = FIELD("Date Filter")));
            Caption = 'Scheduled Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                if "Rounding Precision" <= 0 then
                    FieldError("Rounding Precision", Text027);
            end;
        }
        field(5423; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Filter"));
        }
        field(5424; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(5425; "Sales Unit of Measure"; Code[10])
        {
            Caption = 'Sales Unit of Measure';
            TableRelation = IF ("No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(5426; "Purch. Unit of Measure"; Code[10])
        {
            Caption = 'Purch. Unit of Measure';
            TableRelation = IF ("No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(5428; "Time Bucket"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Time Bucket';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Time Bucket");
            end;
        }
        field(5429; "Reserved Qty. on Prod. Order"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(5406),
                                                                           "Source Subtype" = FILTER("1" .. "3"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Reserved Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5430; "Res. Qty. on Prod. Order Comp."; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(5407),
                                                                            "Source Subtype" = FILTER("1" .. "3"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Prod. Order Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5431; "Res. Qty. on Req. Line"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(246),
                                                                           "Source Subtype" = FILTER("0"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Req. Line';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5440; "Reordering Policy"; Option)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reordering Policy';
            OptionCaption = ' ,Fixed Reorder Qty.,Maximum Qty.,Order,Lot-for-Lot';
            OptionMembers = " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot";

            trigger OnValidate()
            begin
                "Include Inventory" :=
                  "Reordering Policy" in ["Reordering Policy"::"Lot-for-Lot",
                                          "Reordering Policy"::"Maximum Qty.",
                                          "Reordering Policy"::"Fixed Reorder Qty."];

                if "Reordering Policy" <> "Reordering Policy"::" " then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(5441; "Include Inventory"; Boolean)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Include Inventory';
        }
        field(5442; "Manufacturing Policy"; Option)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Manufacturing Policy';
            OptionCaption = 'Make-to-Stock,Make-to-Order';
            OptionMembers = "Make-to-Stock","Make-to-Order";
        }
        field(5443; "Rescheduling Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Rescheduling Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Rescheduling Period");
            end;
        }
        field(5444; "Lot Accumulation Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Lot Accumulation Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Lot Accumulation Period");
            end;
        }
        field(5445; "Dampener Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Period';

            trigger OnValidate()
            begin
                CalendarMgt.CheckDateFormulaPositive("Dampener Period");
            end;
        }
        field(5446; "Dampener Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5447; "Overflow Level"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Overflow Level';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5449; "Planning Transfer Ship. (Qty)."; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE("Worksheet Template Name" = FILTER(<> ''),
                                                                          "Journal Batch Name" = FILTER(<> ''),
                                                                          "Replenishment System" = CONST(Transfer),
                                                                          Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Transfer-from Code" = FIELD("Location Filter"),
                                                                          "Transfer Shipment Date" = FIELD("Date Filter")));
            Caption = 'Planning Transfer Ship. (Qty).';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5450; "Planning Worksheet (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE("Planning Line Origin" = CONST(Planning),
                                                                          Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Due Date" = FIELD("Date Filter"),
                                                                          "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Planning Worksheet (Qty.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5700; "Stockkeeping Unit Exists"; Boolean)
        {
            CalcFormula = Exist ("Stockkeeping Unit" WHERE("Item No." = FIELD("No.")));
            Caption = 'Stockkeeping Unit Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5701; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer;
        }
        field(5702; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";

            trigger OnValidate()
            var
                ItemAttributeManagement: Codeunit "Item Attribute Management";
            begin
                if not IsTemporary then
                    ItemAttributeManagement.InheritAttributesFromItemCategory(Rec, "Item Category Code", xRec."Item Category Code");
                UpdateItemCategoryId;
            end;
        }
        field(5703; "Created From Nonstock Item"; Boolean)
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Created From Catalog Item';
            Editable = false;
        }
        field(5704; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
        }
        field(5706; "Substitutes Exist"; Boolean)
        {
            CalcFormula = Exist ("Item Substitution" WHERE(Type = CONST(Item),
                                                           "No." = FIELD("No.")));
            Caption = 'Substitutes Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5707; "Qty. in Transit"; Decimal)
        {
            CalcFormula = Sum ("Transfer Line"."Qty. in Transit (Base)" WHERE("Derived From Line No." = CONST(0),
                                                                              "Item No." = FIELD("No."),
                                                                              "Transfer-to Code" = FIELD("Location Filter"),
                                                                              "Variant Code" = FIELD("Variant Filter"),
                                                                              "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Receipt Date" = FIELD("Date Filter")));
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5708; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Transfer Line"."Outstanding Qty. (Base)" WHERE("Derived From Line No." = CONST(0),
                                                                               "Item No." = FIELD("No."),
                                                                               "Transfer-to Code" = FIELD("Location Filter"),
                                                                               "Variant Code" = FIELD("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Receipt Date" = FIELD("Date Filter")));
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5709; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Transfer Line"."Outstanding Qty. (Base)" WHERE("Derived From Line No." = CONST(0),
                                                                               "Item No." = FIELD("No."),
                                                                               "Transfer-from Code" = FIELD("Location Filter"),
                                                                               "Variant Code" = FIELD("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Trans. Ord. Shipment (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5776; "Qty. Assigned to ship"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE("Item No." = FIELD("No."),
                                                                                         "Location Code" = FIELD("Location Filter"),
                                                                                         "Variant Code" = FIELD("Variant Filter"),
                                                                                         "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. Assigned to ship';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5777; "Qty. Picked"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Shipment Line"."Qty. Picked (Base)" WHERE("Item No." = FIELD("No."),
                                                                                    "Location Code" = FIELD("Location Filter"),
                                                                                    "Variant Code" = FIELD("Variant Filter"),
                                                                                    "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5900; "Service Item Group"; Code[10])
        {
            Caption = 'Service Item Group';
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            var
                ResSkill: Record "Resource Skill";
            begin
                if xRec."Service Item Group" <> "Service Item Group" then begin
                    if not ResSkillMgt.ChangeRelationWithGroup(
                         ResSkill.Type::Item,
                         "No.",
                         ResSkill.Type::"Service Item Group",
                         "Service Item Group",
                         xRec."Service Item Group")
                    then
                        "Service Item Group" := xRec."Service Item Group";
                end else
                    ResSkillMgt.RevalidateRelation(
                      ResSkill.Type::Item,
                      "No.",
                      ResSkill.Type::"Service Item Group",
                      "Service Item Group")
            end;
        }
        field(5901; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = Sum ("Service Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST(Order),
                                                                              Type = CONST(Item),
                                                                              "No." = FIELD("No."),
                                                                              "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Variant Code" = FIELD("Variant Filter"),
                                                                              "Needed by Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5902; "Res. Qty. on Service Orders"; Decimal)
        {
            AccessByPermission = TableData "Service Header" = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(5902),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Service Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            TableRelation = "Item Tracking Code";

            trigger OnValidate()
            var
                EmptyDateFormula: DateFormula;
            begin
                if "Item Tracking Code" <> '' then
                    TestField(Type, Type::Inventory);
                if "Item Tracking Code" = xRec."Item Tracking Code" then
                    exit;

                if not ItemTrackingCode.Get("Item Tracking Code") then
                    Clear(ItemTrackingCode);

                if not ItemTrackingCode2.Get(xRec."Item Tracking Code") then
                    Clear(ItemTrackingCode2);

                if (ItemTrackingCode."SN Specific Tracking" <> ItemTrackingCode2."SN Specific Tracking") or
                   (ItemTrackingCode."Lot Specific Tracking" <> ItemTrackingCode2."Lot Specific Tracking")
                then
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption, ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoOpenDocumentsWithTrackingExist;

                if "Expiration Calculation" <> EmptyDateFormula then
                    if not ItemTrackingCodeUsesExpirationDate then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6501; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Lot Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
            Caption = 'Expiration Calculation';

            trigger OnValidate()
            begin
                if Format("Expiration Calculation") <> '' then
                    if not ItemTrackingCodeUsesExpirationDate then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6503; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(6504; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(6650; "Qty. on Purch. Return"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Sum ("Purchase Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST("Return Order"),
                                                                               Type = CONST(Item),
                                                                               "No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Location Code" = FIELD("Location Filter"),
                                                                               "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                               "Variant Code" = FIELD("Variant Filter"),
                                                                               "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Purch. Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6660; "Qty. on Sales Return"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = Sum ("Sales Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST("Return Order"),
                                                                            Type = CONST(Item),
                                                                            "No." = FIELD("No."),
                                                                            "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Sales Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7171; "No. of Substitutes"; Integer)
        {
            CalcFormula = Count ("Item Substitution" WHERE(Type = CONST(Item),
                                                           "No." = FIELD("No.")));
            Caption = 'No. of Substitutes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7300; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";
        }
        field(7301; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(7302; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            TableRelation = "Put-away Template Header";
        }
        field(7307; "Put-away Unit of Measure Code"; Code[10])
        {
            AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
            Caption = 'Put-away Unit of Measure Code';
            TableRelation = IF ("No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            TableRelation = "Phys. Invt. Counting Period";

            trigger OnValidate()
            var
                PhysInvtCountPeriod: Record "Phys. Invt. Counting Period";
                PhysInvtCountPeriodMgt: Codeunit "Phys. Invt. Count.-Management";
            begin
                if ("Phys Invt Counting Period Code" <> '') and
                   ("Phys Invt Counting Period Code" <> xRec."Phys Invt Counting Period Code")
                then begin
                    PhysInvtCountPeriod.Get("Phys Invt Counting Period Code");
                    PhysInvtCountPeriod.TestField("Count Frequency per Year");
                    if xRec."Phys Invt Counting Period Code" <> '' then
                        if CurrFieldNo <> 0 then
                            if not Confirm(
                                 Text7380,
                                 false,
                                 FieldCaption("Phys Invt Counting Period Code"),
                                 FieldCaption("Next Counting Start Date"),
                                 FieldCaption("Next Counting End Date"))
                            then
                                Error(Text7381);

                    if "Last Counting Period Update" = 0D then
                        PhysInvtCountPeriodMgt.CalcPeriod(
                          "Last Counting Period Update", "Next Counting Start Date", "Next Counting End Date",
                          PhysInvtCountPeriod."Count Frequency per Year");
                end else begin
                    if CurrFieldNo <> 0 then
                        if not Confirm(Text003, false, FieldCaption("Phys Invt Counting Period Code")) then
                            Error(Text7381);
                    "Next Counting Start Date" := 0D;
                    "Next Counting End Date" := 0D;
                    "Last Counting Period Update" := 0D;
                end;
            end;
        }
        field(7381; "Last Counting Period Update"; Date)
        {
            AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
            Caption = 'Last Counting Period Update';
            Editable = false;
        }
        field(7383; "Last Phys. Invt. Date"; Date)
        {
            CalcFormula = Max ("Phys. Inventory Ledger Entry"."Posting Date" WHERE("Item No." = FIELD("No."),
                                                                                   "Phys Invt Counting Period Type" = FILTER(" " | Item)));
            Caption = 'Last Phys. Invt. Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7384; "Use Cross-Docking"; Boolean)
        {
            AccessByPermission = TableData "Bin Content" = R;
            Caption = 'Use Cross-Docking';
            InitValue = true;
        }
        field(7385; "Next Counting Start Date"; Date)
        {
            Caption = 'Next Counting Start Date';
            Editable = false;
        }
        field(7386; "Next Counting End Date"; Date)
        {
            Caption = 'Next Counting End Date';
            Editable = false;
        }
        field(7700; "Identifier Code"; Code[20])
        {
            CalcFormula = Lookup ("Item Identifier".Code WHERE("Item No." = FIELD("No.")));
            Caption = 'Identifier Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
        }
        field(8001; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".Id;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode;
            end;
        }
        field(8002; "Tax Group Id"; Guid)
        {
            Caption = 'Tax Group Id';
            TableRelation = "Tax Group".Id;

            trigger OnValidate()
            begin
                UpdateTaxGroupCode;
            end;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            DataClassification = CustomerContent;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            DataClassification = CustomerContent;
        }
        field(8005; "Item Category Id"; Guid)
        {
            Caption = 'Item Category Id';
            DataClassification = SystemMetadata;
            TableRelation = "Item Category".Id;

            trigger OnValidate()
            begin
                UpdateItemCategoryCode;
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";

            trigger OnValidate()
            begin
                if "Routing No." <> '' then
                    TestField(Type, Type::Inventory);

                PlanningAssignment.RoutingReplace(Rec, xRec."Routing No.");

                if "Routing No." <> xRec."Routing No." then
                    ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Routing No."));
            end;
        }
        field(99000751; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            TableRelation = "Production BOM Header";

            trigger OnValidate()
            var
                MfgSetup: Record "Manufacturing Setup";
                ProdBOMHeader: Record "Production BOM Header";
                ItemUnitOfMeasure: Record "Item Unit of Measure";
            begin
                if "Production BOM No." <> '' then
                    TestField(Type, Type::Inventory);

                PlanningAssignment.BomReplace(Rec, xRec."Production BOM No.");

                if "Production BOM No." <> xRec."Production BOM No." then
                    ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Production BOM No."));

                if ("Production BOM No." <> '') and ("Production BOM No." <> xRec."Production BOM No.") then begin
                    ProdBOMHeader.Get("Production BOM No.");
                    ItemUnitOfMeasure.Get("No.", ProdBOMHeader."Unit of Measure Code");
                    if ProdBOMHeader.Status = ProdBOMHeader.Status::Certified then begin
                        MfgSetup.Get;
                        if MfgSetup."Dynamic Low-Level Code" then
                            CODEUNIT.Run(CODEUNIT::"Calculate Low-Level Code", Rec);
                    end;
                end;
            end;
        }
        field(99000752; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Cost';
            Editable = false;
        }
        field(99000753; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Capacity Cost';
            Editable = false;
        }
        field(99000754; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Subcontrd. Cost';
            Editable = false;
        }
        field(99000755; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Cap. Ovhd Cost';
            Editable = false;
        }
        field(99000756; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000757; "Overhead Rate"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            AutoFormatType = 2;
            Caption = 'Overhead Rate';

            trigger OnValidate()
            begin
                if "Overhead Rate" <> 0 then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(99000758; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            AutoFormatType = 2;
            Caption = 'Rolled-up Subcontracted Cost';
            Editable = false;
        }
        field(99000759; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            Editable = false;
        }
        field(99000760; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Cap. Overhead Cost';
            Editable = false;
        }
        field(99000761; "Planning Issues (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Planning Component"."Expected Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                                     "Due Date" = FIELD("Date Filter"),
                                                                                     "Location Code" = FIELD("Location Filter"),
                                                                                     "Variant Code" = FIELD("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                     "Planning Line Origin" = CONST(" ")));
            Caption = 'Planning Issues (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000762; "Planning Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE(Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Due Date" = FIELD("Date Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Planning Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000765; "Planned Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = CONST(Planned),
                                                                                "Item No." = FIELD("No."),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Due Date" = FIELD("Date Filter")));
            Caption = 'Planned Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000766; "FP Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = CONST("Firm Planned"),
                                                                                "Item No." = FIELD("No."),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Due Date" = FIELD("Date Filter")));
            Caption = 'FP Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000767; "Rel. Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = CONST(Released),
                                                                                "Item No." = FIELD("No."),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Due Date" = FIELD("Date Filter")));
            Caption = 'Rel. Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000768; "Planning Release (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE(Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Starting Date" = FIELD("Date Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Planning Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000769; "Planned Order Release (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = CONST(Planned),
                                                                                "Item No." = FIELD("No."),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Starting Date" = FIELD("Date Filter")));
            Caption = 'Planned Order Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000770; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE(Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                          "Due Date" = FIELD("Date Filter"),
                                                                          "Planning Line Origin" = CONST(" ")));
            Caption = 'Purch. Req. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000771; "Purch. Req. Release (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Requisition Line"."Quantity (Base)" WHERE(Type = CONST(Item),
                                                                          "No." = FIELD("No."),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                          "Order Date" = FIELD("Date Filter")));
            Caption = 'Purch. Req. Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000773; "Order Tracking Policy"; Option)
        {
            Caption = 'Order Tracking Policy';
            OptionCaption = 'None,Tracking Only,Tracking & Action Msg.';
            OptionMembers = "None","Tracking Only","Tracking & Action Msg.";

            trigger OnValidate()
            var
                ReservEntry: Record "Reservation Entry";
                ActionMessageEntry: Record "Action Message Entry";
                TempReservationEntry: Record "Reservation Entry" temporary;
            begin
                if "Order Tracking Policy" <> "Order Tracking Policy"::None then
                    TestField(Type, Type::Inventory);
                if xRec."Order Tracking Policy" = "Order Tracking Policy" then
                    exit;
                if "Order Tracking Policy" > xRec."Order Tracking Policy" then begin
                    Message(Text99000000 +
                      Text99000001,
                      SelectStr("Order Tracking Policy", Text99000002));
                end else begin
                    ActionMessageEntry.SetCurrentKey("Reservation Entry");
                    ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
                    ReservEntry.SetRange("Item No.", "No.");
                    ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Tracking, ReservEntry."Reservation Status"::Surplus);
                    if ReservEntry.Find('-') then
                        repeat
                            ActionMessageEntry.SetRange("Reservation Entry", ReservEntry."Entry No.");
                            ActionMessageEntry.DeleteAll;
                            if "Order Tracking Policy" = "Order Tracking Policy"::None then
                                if ReservEntry.TrackingExists then begin
                                    TempReservationEntry := ReservEntry;
                                    TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Surplus;
                                    TempReservationEntry.Insert;
                                end else
                                    ReservEntry.Delete;
                        until ReservEntry.Next = 0;

                    if TempReservationEntry.Find('-') then
                        repeat
                            ReservEntry := TempReservationEntry;
                            ReservEntry.Modify;
                        until TempReservationEntry.Next = 0;
                end;
            end;
        }
        field(99000774; "Prod. Forecast Quantity (Base)"; Decimal)
        {
            CalcFormula = Sum ("Production Forecast Entry"."Forecast Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                                            "Production Forecast Name" = FIELD("Production Forecast Name"),
                                                                                            "Forecast Date" = FIELD("Date Filter"),
                                                                                            "Location Code" = FIELD("Location Filter"),
                                                                                            "Component Forecast" = FIELD("Component Forecast")));
            Caption = 'Prod. Forecast Quantity (Base)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(99000775; "Production Forecast Name"; Code[10])
        {
            Caption = 'Production Forecast Name';
            FieldClass = FlowFilter;
            TableRelation = "Production Forecast Name";
        }
        field(99000776; "Component Forecast"; Boolean)
        {
            Caption = 'Component Forecast';
            FieldClass = FlowFilter;
        }
        field(99000777; "Qty. on Prod. Order"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Line"."Remaining Qty. (Base)" WHERE(Status = FILTER(Planned .. Released),
                                                                                "Item No." = FIELD("No."),
                                                                                "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Location Code" = FIELD("Location Filter"),
                                                                                "Variant Code" = FIELD("Variant Filter"),
                                                                                "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000778; "Qty. on Component Lines"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Component"."Remaining Qty. (Base)" WHERE(Status = FILTER(Planned .. Released),
                                                                                     "Item No." = FIELD("No."),
                                                                                     "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                     "Location Code" = FIELD("Location Filter"),
                                                                                     "Variant Code" = FIELD("Variant Filter"),
                                                                                     "Due Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Component Lines';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
        }
        field(99008500; "Common Item No."; Code[20])
        {
            Caption = 'Common Item No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Inventory Posting Group")
        {
        }
        key(Key4; "Shelf No.")
        {
        }
        key(Key5; "Vendor No.")
        {
        }
        key(Key6; "Gen. Prod. Posting Group")
        {
        }
        key(Key7; "Low-Level Code")
        {
        }
        key(Key8; "Production BOM No.")
        {
        }
        key(Key9; "Routing No.")
        {
        }
        key(Key10; "Vendor Item No.", "Vendor No.")
        {
        }
        key(Key11; "Common Item No.")
        {
        }
        key(Key12; "Service Item Group")
        {
        }
        key(Key13; "Cost is Adjusted", "Allow Online Adjustment")
        {
        }
        key(Key14; Description)
        {
        }
        key(Key15; "Base Unit of Measure")
        {
        }
        key(Key16; Type)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Base Unit of Measure", "Unit Price")
        {
        }
        fieldgroup(Brick; "No.", Description, Inventory, "Unit Price", "Base Unit of Measure", "Description 2", Picture)
        {
        }
    }

    trigger OnDelete()
    begin
        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);

        CheckJournalsAndWorksheets(0);
        CheckDocuments(0);

        MoveEntries.MoveItemEntries(Rec);

        ServiceItem.Reset;
        ServiceItem.SetRange("Item No.", "No.");
        if ServiceItem.Find('-') then
            repeat
                ServiceItem.Validate("Item No.", '');
                ServiceItem.Modify(true);
            until ServiceItem.Next = 0;

        DeleteRelatedData;
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            GetInvtSetup;
            InvtSetup.TestField("Item Nos.");
            NoSeriesMgt.InitSeries(InvtSetup."Item Nos.", xRec."No. Series", 0D, "No.", "No. Series");
            "Costing Method" := InvtSetup."Default Costing Method";
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Item, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        UpdateReferencedIds;
        SetLastDateTimeModified;
    end;

    trigger OnModify()
    begin
        UpdateReferencedIds;
        SetLastDateTimeModified;
        PlanningAssignment.ItemChange(Rec, xRec);
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        SalesLine.RenameNo(SalesLine.Type::Item, xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::Item, xRec."No.", "No.");
        TransferLine.RenameNo(xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::Item, xRec."No.", "No.");

        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        ItemAttributeValueMapping.RenameItemAttributeValueMapping(xRec."No.", "No.");
        SetLastDateTimeModified;
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 that includes this item.';
        CannotDeleteItemIfSalesDocExistErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Sales %3 that includes this item.', Comment = '1: Type, 2 Item No. and 3 : Type of document Order,Invoice';
        CannotDeleteItemIfSalesDocExistInvoicingErr: Label 'You cannot delete %1 %2 because at least one sales document (%3 %4) includes the item.', Comment = '1: Type, 2: Item No., 3: Description of document, 4: Document number';
        Text002: Label 'You cannot delete %1 %2 because there are one or more outstanding production orders that include this item.';
        Text003: Label 'Do you want to change %1?';
        Text004: Label 'You cannot delete %1 %2 because there are one or more certified Production BOM that include this item.';
        CannotDeleteItemIfProdBOMVersionExistsErr: Label 'You cannot delete %1 %2 because there are one or more certified production BOM version that include this item.', Comment = '%1 - Tablecaption, %2 - No.';
        Text006: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text007: Label 'You cannot change %1 because there are one or more ledger entries for this item.';
        Text008: Label 'You cannot change %1 because there is at least one outstanding Purchase %2 that include this item.';
        Text014: Label 'You cannot delete %1 %2 because there are one or more production order component lines that include this item with a remaining quantity that is not 0.';
        Text016: Label 'You cannot delete %1 %2 because there are one or more outstanding transfer orders that include this item.';
        Text017: Label 'You cannot delete %1 %2 because there is at least one outstanding Service %3 that includes this item.';
        Text018: Label '%1 must be %2 in %3 %4 when %5 is %6.';
        Text019: Label 'You cannot change %1 because there are one or more open ledger entries for this item.';
        Text020: Label 'There may be orders and open ledger entries for the item. ';
        Text021: Label 'If you change %1 it may affect new orders and entries.\\';
        Text022: Label 'Do you want to change %1?';
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        Text023: Label 'You cannot delete %1 %2 because there is at least one %3 that includes this item.';
        Text024: Label 'If you change %1 it may affect existing production orders.\';
        Text025: Label '%1 must be an integer because %2 %3 is set up to use %4.';
        Text026: Label '%1 cannot be changed because the %2 has work in process (WIP). Changing the value may offset the WIP account.';
        Text7380: Label 'If you change the %1, the %2 and %3 are calculated.\Do you still want to change the %1?', Comment = 'If you change the Phys Invt Counting Period Code, the Next Counting Start Date and Next Counting End Date are calculated.\Do you still want to change the Phys Invt Counting Period Code?';
        Text7381: Label 'Cancelled.';
        Text99000000: Label 'The change will not affect existing entries.\';
        CommentLine: Record "Comment Line";
        Text99000001: Label 'If you want to generate %1 for existing entries, you must run a regenerative planning.';
        ItemVend: Record "Item Vendor";
        Text99000002: Label 'tracking,tracking and action messages';
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrepmtPct: Record "Sales Prepayment %";
        PurchPrice: Record "Purchase Price";
        PurchLineDisc: Record "Purchase Line Discount";
        PurchPrepmtPct: Record "Purchase Prepayment %";
        ItemTranslation: Record "Item Translation";
        BOMComp: Record "BOM Component";
        VATPostingSetup: Record "VAT Posting Setup";
        ExtTextHeader: Record "Extended Text Header";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningAssignment: Record "Planning Assignment";
        SKU: Record "Stockkeeping Unit";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";
        ServInvLine: Record "Service Line";
        ItemSub: Record "Item Substitution";
        TransLine: Record "Transfer Line";
        Vend: Record Vendor;
        NonstockItem: Record "Nonstock Item";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ItemIdent: Record "Item Identifier";
        RequisitionLine: Record "Requisition Line";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisBudgViewEntry: Record "Item Analysis View Budg. Entry";
        TroubleshSetup: Record "Troubleshooting Setup";
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItemComponent: Record "Service Item Component";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        MoveEntries: Codeunit MoveEntries;
        DimMgt: Codeunit DimensionManagement;
        CatalogItemMgt: Codeunit "Catalog Item Management";
        ItemCostMgt: Codeunit ItemCostManagement;
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        CalendarMgt: Codeunit "Calendar Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        HasInvtSetup: Boolean;
        GLSetupRead: Boolean;
        Text027: Label 'must be greater than 0.', Comment = 'starts with "Rounding Precision"';
        Text028: Label 'You cannot perform this action because entries for item %1 are unapplied in %2 by user %3.';
        CannotChangeFieldErr: Label 'You cannot change the %1 field on %2 %3 because at least one %4 exists for this item.', Comment = '%1 = Field Caption, %2 = Item Table Name, %3 = Item No., %4 = Table Name';
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.\\You can change this setup in the Item Units of Measure window.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
        OpenDocumentTrackingErr: Label 'You cannot change "Item Tracking Code" because there is at least one open document that includes this item with specified tracking: Source Type = %1, Document No. = %2.';
        SelectItemErr: Label 'You must select an existing item.';
        CreateNewItemTxt: Label 'Create a new item card for %1.', Comment = '%1 is the name to be used to create the customer. ';
        ItemNotRegisteredTxt: Label 'This item is not registered. To continue, choose one of the following options:';
        SelectItemTxt: Label 'Select an existing item.';
        UnitOfMeasureNotExistErr: Label 'The Unit of Measure with Code %1 does not exist.', Comment = '%1 = Code of Unit of measure';
        ItemLedgEntryTableCaptionTxt: Label 'Item Ledger Entry';
        ItemTrackingCodeIgnoresExpirationDateErr: Label 'The settings for expiration dates do not match on the item tracking code and the item. Both must either use, or not use, expiration dates.', Comment = '%1 is the Item number';

    local procedure DeleteRelatedData()
    var
        BinContent: Record "Bin Content";
        ItemCrossReference: Record "Item Cross Reference";
        SocialListeningSearchTopic: Record "Social Listening Search Topic";
        MyItem: Record "My Item";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        ItemBudgetEntry.SetRange("Item No.", "No.");
        ItemBudgetEntry.DeleteAll(true);

        ItemSub.Reset;
        ItemSub.SetRange(Type, ItemSub.Type::Item);
        ItemSub.SetRange("No.", "No.");
        ItemSub.DeleteAll;

        ItemSub.Reset;
        ItemSub.SetRange("Substitute Type", ItemSub."Substitute Type"::Item);
        ItemSub.SetRange("Substitute No.", "No.");
        ItemSub.DeleteAll;

        SKU.Reset;
        SKU.SetCurrentKey("Item No.");
        SKU.SetRange("Item No.", "No.");
        SKU.DeleteAll;

        CatalogItemMgt.NonstockItemDel(Rec);
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll;

        ItemVend.SetCurrentKey("Item No.");
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.DeleteAll;

        SalesPrice.SetRange("Item No.", "No.");
        SalesPrice.DeleteAll;

        SalesLineDisc.SetRange(Type, SalesLineDisc.Type::Item);
        SalesLineDisc.SetRange(Code, "No.");
        SalesLineDisc.DeleteAll;

        SalesPrepmtPct.SetRange("Item No.", "No.");
        SalesPrepmtPct.DeleteAll;

        PurchPrice.SetRange("Item No.", "No.");
        PurchPrice.DeleteAll;

        PurchLineDisc.SetRange("Item No.", "No.");
        PurchLineDisc.DeleteAll;

        PurchPrepmtPct.SetRange("Item No.", "No.");
        PurchPrepmtPct.DeleteAll;

        ItemTranslation.SetRange("Item No.", "No.");
        ItemTranslation.DeleteAll;

        ItemUnitOfMeasure.SetRange("Item No.", "No.");
        ItemUnitOfMeasure.DeleteAll;

        ItemVariant.SetRange("Item No.", "No.");
        ItemVariant.DeleteAll;

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        ItemAnalysisViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisViewEntry.DeleteAll;

        ItemAnalysisBudgViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisBudgViewEntry.DeleteAll;

        PlanningAssignment.SetRange("Item No.", "No.");
        PlanningAssignment.DeleteAll;

        BOMComp.Reset;
        BOMComp.SetRange("Parent Item No.", "No.");
        BOMComp.DeleteAll;

        TroubleshSetup.Reset;
        TroubleshSetup.SetRange(Type, TroubleshSetup.Type::Item);
        TroubleshSetup.SetRange("No.", "No.");
        TroubleshSetup.DeleteAll;

        ResSkillMgt.DeleteItemResSkills("No.");
        DimMgt.DeleteDefaultDim(DATABASE::Item, "No.");

        ItemIdent.Reset;
        ItemIdent.SetCurrentKey("Item No.");
        ItemIdent.SetRange("Item No.", "No.");
        ItemIdent.DeleteAll;

        ServiceItemComponent.Reset;
        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.SetRange("No.", "No.");
        ServiceItemComponent.ModifyAll("No.", '');

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "No.");
        BinContent.DeleteAll;

        ItemCrossReference.SetRange("Item No.", "No.");
        ItemCrossReference.DeleteAll;

        MyItem.SetRange("Item No.", "No.");
        MyItem.DeleteAll;

        if not SocialListeningSearchTopic.IsEmpty then begin
            SocialListeningSearchTopic.FindSearchTopic(SocialListeningSearchTopic."Source Type"::Item, "No.");
            SocialListeningSearchTopic.DeleteAll;
        end;

        ItemAttributeValueMapping.Reset;
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", "No.");
        ItemAttributeValueMapping.DeleteAll;

        OnAfterDeleteRelatedData(Rec);
    end;

    procedure AssistEdit(): Boolean
    begin
        GetInvtSetup;
        InvtSetup.TestField("Item Nos.");
        if NoSeriesMgt.SelectSeries(InvtSetup."Item Nos.", xRec."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    procedure FindItemVend(var ItemVend: Record "Item Vendor"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
    begin
        TestField("No.");
        ItemVend.Reset;
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.SetRange("Vendor No.", ItemVend."Vendor No.");
        ItemVend.SetRange("Variant Code", ItemVend."Variant Code");

        if not ItemVend.Find('+') then begin
            ItemVend."Item No." := "No.";
            ItemVend."Vendor Item No." := '';
            GetPlanningParameters.AtSKU(SKU, "No.", ItemVend."Variant Code", LocationCode);
            if ItemVend."Vendor No." = '' then
                ItemVend."Vendor No." := SKU."Vendor No.";
            if ItemVend."Vendor Item No." = '' then
                ItemVend."Vendor Item No." := SKU."Vendor Item No.";
            ItemVend."Lead Time Calculation" := SKU."Lead Time Calculation";
        end;
        if Format(ItemVend."Lead Time Calculation") = '' then begin
            GetPlanningParameters.AtSKU(SKU, "No.", ItemVend."Variant Code", LocationCode);
            ItemVend."Lead Time Calculation" := SKU."Lead Time Calculation";
            if Format(ItemVend."Lead Time Calculation") = '' then
                if Vend.Get(ItemVend."Vendor No.") then
                    ItemVend."Lead Time Calculation" := Vend."Lead Time Calculation";
        end;
        ItemVend.Reset;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::Item, "No.", FieldNumber, ShortcutDimCode);
        Modify;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure TestNoEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeTestNoItemLedgEntiesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            ItemLedgEntry.SetCurrentKey("Item No.");
            ItemLedgEntry.SetRange("Item No.", "No.");
            if not ItemLedgEntry.IsEmpty then
                Error(Text007, CurrentFieldName);
        end;

        IsHandled := false;
        OnBeforeTestNoPurchLinesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
            PurchaseLine.SetFilter(
              "Document Type", '%1|%2',
              PurchaseLine."Document Type"::Order,
              PurchaseLine."Document Type"::"Return Order");
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", "No.");
            if PurchaseLine.FindFirst then
                Error(Text008, CurrentFieldName, PurchaseLine."Document Type");
        end;
    end;

    procedure TestNoOpenEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty then
            Error(
              Text019,
              CurrentFieldName);
    end;

    local procedure TestNoOpenDocumentsWithTrackingExist()
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        SourceType: Integer;
        SourceID: Code[20];
    begin
        if ItemTrackingCode2.Code = '' then
            exit;

        TrackingSpecification.SetRange("Item No.", "No.");
        if TrackingSpecification.FindFirst then begin
            SourceType := TrackingSpecification."Source Type";
            SourceID := TrackingSpecification."Source ID";
        end else begin
            ReservationEntry.SetRange("Item No.", "No.");
            ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
            if ReservationEntry.FindFirst then begin
                SourceType := ReservationEntry."Source Type";
                SourceID := ReservationEntry."Source ID";
            end;
        end;

        if SourceType = 0 then
            exit;

        RecRef.Open(SourceType);
        Error(OpenDocumentTrackingErr, RecRef.Caption, SourceID);
    end;

    procedure ItemSKUGet(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if Item.Get("No.") then begin
            if SKU.Get(LocationCode, Item."No.", VariantCode) then
                Item."Shelf No." := SKU."Shelf No.";
        end;
    end;

    local procedure GetInvtSetup()
    begin
        if not HasInvtSetup then begin
            InvtSetup.Get;
            HasInvtSetup := true;
        end;
    end;

    procedure IsMfgItem(): Boolean
    begin
        exit("Replenishment System" = "Replenishment System"::"Prod. Order");
    end;

    procedure IsAssemblyItem(): Boolean
    begin
        exit("Replenishment System" = "Replenishment System"::Assembly);
    end;

    procedure HasBOM(): Boolean
    begin
        CalcFields("Assembly BOM");
        exit("Assembly BOM" or ("Production BOM No." <> ''));
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    local procedure ProdOrderExist(): Boolean
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", "No.");
        if not ProdOrderLine.IsEmpty then
            exit(true);

        exit(false);
    end;

    procedure CheckSerialNoQty(ItemNo: Code[20]; FieldName: Text[30]; Quantity: Decimal)
    var
        ItemRec: Record Item;
        ItemTrackingCode3: Record "Item Tracking Code";
    begin
        if Quantity = Round(Quantity, 1) then
            exit;
        if not ItemRec.Get(ItemNo) then
            exit;
        if ItemRec."Item Tracking Code" = '' then
            exit;
        if not ItemTrackingCode3.Get(ItemRec."Item Tracking Code") then
            exit;
        if ItemTrackingCode3."SN Specific Tracking" then
            Error(Text025,
              FieldName,
              TableCaption,
              ItemNo,
              ItemTrackingCode3.FieldCaption("SN Specific Tracking"));
    end;

    local procedure CheckForProductionOutput(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Clear(ItemLedgEntry);
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        if not ItemLedgEntry.IsEmpty then
            Error(Text026, FieldCaption("Inventory Value Zero"), TableCaption);
    end;

    procedure CheckBlockedByApplWorksheet()
    var
        ApplicationWorksheet: Page "Application Worksheet";
    begin
        if "Application Wksh. User ID" <> '' then
            Error(Text028, "No.", ApplicationWorksheet.Caption, "Application Wksh. User ID");
    end;

    procedure ShowTimelineFromItem(var Item: Record Item)
    var
        ItemAvailByTimeline: Page "Item Availability by Timeline";
    begin
        ItemAvailByTimeline.SetItem(Item);
        ItemAvailByTimeline.Run;
    end;

    procedure ShowTimelineFromSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);
        ShowTimelineFromItem(Item);
    end;

    procedure CheckJournalsAndWorksheets(CurrFieldNo: Integer)
    begin
        CheckItemJnlLine(CurrFieldNo);
        CheckStdCostWksh(CurrFieldNo);
        CheckReqLine(CurrFieldNo);
    end;

    local procedure CheckItemJnlLine(CurrFieldNo: Integer)
    begin
        ItemJnlLine.SetRange("Item No.", "No.");
        if not ItemJnlLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", ItemJnlLine.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ItemJnlLine.TableCaption);
        end;
    end;

    local procedure CheckStdCostWksh(CurrFieldNo: Integer)
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        StdCostWksh.Reset;
        StdCostWksh.SetRange(Type, StdCostWksh.Type::Item);
        StdCostWksh.SetRange("No.", "No.");
        if not StdCostWksh.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", StdCostWksh.TableCaption);
    end;

    local procedure CheckReqLine(CurrFieldNo: Integer)
    begin
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "No.");
        if not RequisitionLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", RequisitionLine.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", RequisitionLine.TableCaption);
        end;
    end;

    procedure CheckDocuments(CurrFieldNo: Integer)
    begin
        if "No." = '' then
            exit;

        CheckBOM(CurrFieldNo);
        CheckPurchLine(CurrFieldNo);
        CheckSalesLine(CurrFieldNo);
        CheckProdOrderLine(CurrFieldNo);
        CheckProdOrderCompLine(CurrFieldNo);
        CheckPlanningCompLine(CurrFieldNo);
        CheckTransLine(CurrFieldNo);
        CheckServLine(CurrFieldNo);
        CheckProdBOMLine(CurrFieldNo);
        CheckServContractLine(CurrFieldNo);
        CheckAsmHeader(CurrFieldNo);
        CheckAsmLine(CurrFieldNo);
        CheckJobPlanningLine(CurrFieldNo);

        OnAfterCheckDocuments(Rec, xRec, CurrFieldNo);
    end;

    local procedure CheckBOM(CurrFieldNo: Integer)
    begin
        BOMComp.Reset;
        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", "No.");
        if not BOMComp.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", BOMComp.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", BOMComp.TableCaption);
        end;
    end;

    local procedure CheckPurchLine(CurrFieldNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey(Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", "No.");
        if PurchaseLine.FindFirst then begin
            if CurrFieldNo = 0 then
                Error(Text000, TableCaption, "No.", PurchaseLine."Document Type");
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", PurchaseLine.TableCaption);
        end;
    end;

    local procedure CheckSalesLine(CurrFieldNo: Integer)
    var
        SalesLine: Record "Sales Line";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", "No.");
        if SalesLine.FindFirst then begin
            if CurrFieldNo = 0 then begin
                if EnvInfoProxy.IsInvoicing then
                    Error(CannotDeleteItemIfSalesDocExistInvoicingErr, TableCaption, Description,
                      SalesLine.GetDocumentTypeDescription, SalesLine."Document No.");
                Error(CannotDeleteItemIfSalesDocExistErr, TableCaption, "No.", SalesLine."Document Type");
            end;
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", SalesLine.TableCaption);
        end;
    end;

    local procedure CheckProdOrderLine(CurrFieldNo: Integer)
    begin
        if ProdOrderExist then begin
            if CurrFieldNo = 0 then
                Error(Text002, TableCaption, "No.");
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ProdOrderLine.TableCaption);
        end;
    end;

    local procedure CheckProdOrderCompLine(CurrFieldNo: Integer)
    begin
        ProdOrderComp.SetCurrentKey(Status, "Item No.");
        ProdOrderComp.SetFilter(Status, '..%1', ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Item No.", "No.");
        if not ProdOrderComp.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text014, TableCaption, "No.");
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ProdOrderComp.TableCaption);
        end;
    end;

    local procedure CheckPlanningCompLine(CurrFieldNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Planning Line Origin");
        PlanningComponent.SetRange("Item No.", "No.");
        if not PlanningComponent.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", PlanningComponent.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", PlanningComponent.TableCaption);
        end;
    end;

    local procedure CheckTransLine(CurrFieldNo: Integer)
    begin
        TransLine.SetCurrentKey("Item No.");
        TransLine.SetRange("Item No.", "No.");
        if not TransLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text016, TableCaption, "No.");
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", TransLine.TableCaption);
        end;
    end;

    local procedure CheckServLine(CurrFieldNo: Integer)
    begin
        ServInvLine.Reset;
        ServInvLine.SetCurrentKey(Type, "No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::Item);
        ServInvLine.SetRange("No.", "No.");
        if not ServInvLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text017, TableCaption, "No.", ServInvLine."Document Type");
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ServInvLine.TableCaption);
        end;
    end;

    local procedure CheckProdBOMLine(CurrFieldNo: Integer)
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProdBOMLine.Reset;
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", "No.");
        if ProdBOMLine.Find('-') then begin
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ProdBOMLine.TableCaption);
            if CurrFieldNo = 0 then
                repeat
                    if ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") and
                       (ProdBOMHeader.Status = ProdBOMHeader.Status::Certified)
                    then
                        Error(Text004, TableCaption, "No.");
                    if ProductionBOMVersion.Get(ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code") and
                       (ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified)
                    then
                        Error(CannotDeleteItemIfProdBOMVersionExistsErr, TableCaption, "No.");
                until ProdBOMLine.Next = 0;
        end;
    end;

    local procedure CheckServContractLine(CurrFieldNo: Integer)
    begin
        ServiceContractLine.Reset;
        ServiceContractLine.SetRange("Item No.", "No.");
        if not ServiceContractLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", ServiceContractLine.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", ServiceContractLine.TableCaption);
        end;
    end;

    local procedure CheckAsmHeader(CurrFieldNo: Integer)
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader.SetCurrentKey("Document Type", "Item No.");
        AsmHeader.SetRange("Item No.", "No.");
        if not AsmHeader.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", AsmHeader.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", AsmHeader.TableCaption);
        end;
    end;

    local procedure CheckAsmLine(CurrFieldNo: Integer)
    var
        AsmLine: Record "Assembly Line";
    begin
        AsmLine.SetCurrentKey(Type, "No.");
        AsmLine.SetRange(Type, AsmLine.Type::Item);
        AsmLine.SetRange("No.", "No.");
        if not AsmLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", AsmLine.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", AsmLine.TableCaption);
        end;
    end;

    procedure PreventNegativeInventory(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        case "Prevent Negative Inventory" of
            "Prevent Negative Inventory"::Yes:
                exit(true);
            "Prevent Negative Inventory"::No:
                exit(false);
            "Prevent Negative Inventory"::Default:
                begin
                    InventorySetup.Get;
                    exit(InventorySetup."Prevent Negative Inventory");
                end;
        end;
    end;

    local procedure CheckJobPlanningLine(CurrFieldNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetRange("No.", "No.");
        if not JobPlanningLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023, TableCaption, "No.", JobPlanningLine.TableCaption);
            if CurrFieldNo = FieldNo(Type) then
                Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption, "No.", JobPlanningLine.TableCaption);
        end;
    end;

    local procedure CalcVAT(): Decimal
    begin
        if "Price Includes VAT" then begin
            VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text006,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
        end else
            Clear(VATPostingSetup);

        exit(VATPostingSetup."VAT %" / 100);
    end;

    procedure CalcUnitPriceExclVAT(): Decimal
    begin
        GetGLSetup;
        if 1 + CalcVAT = 0 then
            exit(0);
        exit(Round("Unit Price" / (1 + CalcVAT), GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure GetItemNo(ItemText: Text): Code[20]
    var
        ItemNo: Text[50];
    begin
        TryGetItemNo(ItemNo, ItemText, true);
        exit(CopyStr(ItemNo, 1, MaxStrLen("No.")));
    end;

    procedure TryGetItemNo(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean): Boolean
    begin
        InvtSetup.Get;
        exit(TryGetItemNoOpenCard(ReturnValue, ItemText, DefaultCreate, true, not InvtSetup."Skip Prompt to Create Item"));
    end;

    procedure TryGetItemNoOpenCard(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean): Boolean
    var
        Item: Record Item;
        ItemView: Record Item;
        SalesLine: Record "Sales Line";
        FindRecordMgt: Codeunit "Find Record Management";
        ItemNo: Code[20];
        ItemWithoutQuote: Text;
        ItemFilterContains: Text;
        FoundRecordCount: Integer;
    begin
        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if ItemText = '' then
            exit(DefaultCreate);

        ItemView.SetRange(Blocked, false);

        FoundRecordCount := FindRecordMgt.FindRecordByDescriptionAndView(ReturnValue, SalesLine.Type::Item, ItemText, ItemView.GetView);

        if FoundRecordCount = 1 then
            exit(true);

        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if FoundRecordCount = 0 then begin
            if not DefaultCreate then
                exit(false);

            if not GuiAllowed then
                Error(SelectItemErr);

            if Item.WritePermission then
                if ShowCreateItemOption then
                    case StrMenu(
                           StrSubstNo('%1,%2', StrSubstNo(CreateNewItemTxt, ConvertStr(ItemText, ',', '.')), SelectItemTxt), 1, ItemNotRegisteredTxt)
                    of
                        0:
                            Error('');
                        1:
                            begin
                                ReturnValue := CreateNewItem(CopyStr(ItemText, 1, MaxStrLen(Item.Description)), ShowItemCard);
                                exit(true);
                            end;
                    end
                else
                    exit(false);
        end;

        if not GuiAllowed then
            Error(SelectItemErr);

        if FoundRecordCount > 0 then begin
            ItemWithoutQuote := ConvertStr(ItemText, '''', '?');
            ItemFilterContains := '''@*' + ItemWithoutQuote + '*''';
            Item.FilterGroup(-1);
            Item.SetFilter("No.", ItemFilterContains);
            Item.SetFilter(Description, ItemFilterContains);
            Item.SetFilter("Base Unit of Measure", ItemFilterContains);
        end;

        if ShowItemCard then
            ItemNo := PickItem(Item)
        else begin
            ReturnValue := '';
            exit(true);
        end;

        if ItemNo <> '' then begin
            ReturnValue := ItemNo;
            exit(true);
        end;

        if not DefaultCreate then
            exit(false);
        Error('');
    end;

    local procedure CreateNewItem(ItemName: Text[100]; ShowItemCard: Boolean): Code[20]
    var
        Item: Record Item;
        ItemTemplate: Record "Item Template";
        ItemCard: Page "Item Card";
    begin
        OnBeforeCreateNewItem(Item, ItemName);
        if not ItemTemplate.NewItemFromTemplate(Item) then
            Error(SelectItemErr);

        Item.Description := ItemName;
        Item.Modify(true);
        Commit;
        if not ShowItemCard then
            exit(Item."No.");
        Item.SetRange("No.", Item."No.");
        ItemCard.SetTableView(Item);
        if not (ItemCard.RunModal = ACTION::OK) then
            Error(SelectItemErr);

        exit(Item."No.");
    end;

    procedure PickItem(var Item: Record Item): Code[20]
    var
        ItemList: Page "Item List";
    begin
        if Item.FilterGroup = -1 then
            ItemList.SetTempFilteredItemRec(Item);

        if Item.FindFirst then;
        ItemList.SetTableView(Item);
        ItemList.SetRecord(Item);
        ItemList.LookupMode := true;
        if ItemList.RunModal = ACTION::LookupOK then
            ItemList.GetRecord(Item)
        else
            Clear(Item);

        exit(Item."No.");
    end;

    local procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
    end;

    procedure SetLastDateTimeFilter(DateFilter: DateTime)
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        SyncDateTimeUtc: DateTime;
        CurrentFilterGroup: Integer;
    begin
        SyncDateTimeUtc := DotNet_DateTimeOffset.ConvertToUtcDateTime(DateFilter);
        CurrentFilterGroup := FilterGroup;
        SetFilter("Last Date Modified", '>=%1', DT2Date(SyncDateTimeUtc));
        FilterGroup(-1);
        SetFilter("Last Date Modified", '>%1', DT2Date(SyncDateTimeUtc));
        SetFilter("Last Time Modified", '>%1', DT2Time(SyncDateTimeUtc));
        FilterGroup(CurrentFilterGroup);
    end;

    procedure UpdateReplenishmentSystem(): Boolean
    begin
        CalcFields("Assembly BOM");

        if "Assembly BOM" then begin
            if not ("Replenishment System" in ["Replenishment System"::Assembly, "Replenishment System"::"Prod. Order"])
            then begin
                Validate("Replenishment System", "Replenishment System"::Assembly);
                exit(true);
            end
        end else
            if "Replenishment System" = "Replenishment System"::Assembly then begin
                if "Assembly Policy" <> "Assembly Policy"::"Assemble-to-Order" then begin
                    Validate("Replenishment System", "Replenishment System"::Purchase);
                    exit(true);
                end
            end
    end;

    procedure UpdateUnitOfMeasureId()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if "Base Unit of Measure" = '' then begin
            Clear("Unit of Measure Id");
            exit;
        end;

        if not UnitOfMeasure.Get("Base Unit of Measure") then
            exit;

        "Unit of Measure Id" := UnitOfMeasure.Id;
    end;

    procedure UpdateItemCategoryId()
    var
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        if "Item Category Code" = '' then begin
            Clear("Item Category Id");
            exit;
        end;

        if not ItemCategory.Get("Item Category Code") then
            exit;

        "Item Category Id" := ItemCategory.Id;
    end;

    procedure UpdateTaxGroupId()
    var
        TaxGroup: Record "Tax Group";
    begin
        if "Tax Group Code" = '' then begin
            Clear("Tax Group Id");
            exit;
        end;

        if not TaxGroup.Get("Tax Group Code") then
            exit;

        "Tax Group Id" := TaxGroup.Id;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not IsNullGuid("Unit of Measure Id") then begin
            UnitOfMeasure.SetRange(Id, "Unit of Measure Id");
            UnitOfMeasure.FindFirst;
        end;

        "Base Unit of Measure" := UnitOfMeasure.Code;
    end;

    local procedure UpdateTaxGroupCode()
    var
        TaxGroup: Record "Tax Group";
    begin
        if not IsNullGuid("Tax Group Id") then begin
            TaxGroup.SetRange(Id, "Tax Group Id");
            TaxGroup.FindFirst;
        end;

        Validate("Tax Group Code", TaxGroup.Code);
    end;

    local procedure UpdateItemCategoryCode()
    var
        ItemCategory: Record "Item Category";
    begin
        if IsNullGuid("Item Category Id") then begin
            ItemCategory.SetRange(Id, "Item Category Id");
            ItemCategory.FindFirst;
        end;

        "Item Category Code" := ItemCategory.Code;
    end;

    procedure UpdateReferencedIds()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        UpdateUnitOfMeasureId;
        UpdateTaxGroupId;
        UpdateItemCategoryId;
    end;

    procedure GetReferencedIds(var TempField: Record "Field" temporary)
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Unit of Measure Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Tax Group Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Item Category Id"));
    end;

    procedure IsServiceType(): Boolean
    begin
        exit(Type = Type::Service);
    end;

    procedure IsNonInventoriableType(): Boolean
    begin
        exit(Type in [Type::"Non-Inventory", Type::Service]);
    end;

    procedure IsInventoriableType(): Boolean
    begin
        exit(not IsNonInventoriableType);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDocuments(var Item: Record Item; var xItem: Record Item; var CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedData(Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Item: Record Item; xItem: Record Item; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewItem(var Item: Record Item; var ItemName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoItemLedgEntiesExist(Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoPurchLinesExist(Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Item: Record Item; xItem: Record Item; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStandardCost(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure ExistsItemLedgerEntry(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset;
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", "No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure ItemTrackingCodeUsesExpirationDate(): Boolean
    begin
        if "Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get("Item Tracking Code");
        exit(ItemTrackingCode."Use Expiration Dates");
    end;
}

