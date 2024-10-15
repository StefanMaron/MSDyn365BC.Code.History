namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Setup;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Graph;
using Microsoft.Inventory;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Text;
using System.Reflection;
using System.Utilities;
using System.DateTime;

table 27 Item
{
    Caption = 'Item';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Item List";
    LookupPageID = "Item Lookup";
    Permissions = TableData "Service Item" = rm,
                  TableData "Service Item Component" = rm,
                  TableData "Bin Content" = d,
                  TableData "Planning Assignment" = d;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
#if not CLEAN24
                NoSeriesMgt: Codeunit NoSeriesManagement;
#endif
                IsHandled: Boolean;
            begin
                IsHandled := false;
#if not CLEAN24
                OnBeforeValidateNo(IsHandled, Rec, xRec, InventorySetup, NoSeriesMgt);
#else
                OnBeforeValidateNo(IsHandled, Rec, xRec, InventorySetup);
#endif
                if IsHandled then
                    exit;
                if "No." <> xRec."No." then begin
                    GetInvtSetup();
                    NoSeries.TestManual(InventorySetup."Item Nos.");
                    "No. Series" := '';
                    if xRec."No." = '' then
                        "Costing Method" := InventorySetup."Default Costing Method";
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
                    if NonstockItem.FindFirst() then
                        if NonstockItem.Description = '' then begin
                            NonstockItem.Description := Description;
                            NonstockItem.Modify();
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
            CalcFormula = exist("BOM Component" where("Parent Item No." = field("No.")));
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
                TempItem: Record Item temporary;
                UnitOfMeasure: Record "Unit of Measure";
                IsHandled: Boolean;
                ValidateBaseUnitOfMeasure: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBaseUnitOfMeasure(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if CurrentClientType() in [ClientType::ODataV4, ClientType::API] then
                    if not TempItem.Get(Rec."No.") and IsNullGuid(Rec.SystemId) then
                        Rec.Insert(true);

                UpdateUnitOfMeasureId();

                OnValidateBaseUnitOfMeasure(ValidateBaseUnitOfMeasure);

                if not ValidateBaseUnitOfMeasure then
                    ValidateBaseUnitOfMeasure := "Base Unit of Measure" <> xRec."Base Unit of Measure";

                if ValidateBaseUnitOfMeasure then begin
                    TestNoOpenEntriesExist(FieldCaption("Base Unit of Measure"));

                    if "Base Unit of Measure" <> '' then begin
                        // If we can't find a Unit of Measure with a GET,
                        // then try with International Standard Code, as some times it's used as Code
                        if not UnitOfMeasure.Get("Base Unit of Measure") then begin
                            UnitOfMeasure.SetRange("International Standard Code", "Base Unit of Measure");
                            if not UnitOfMeasure.FindFirst() then
                                Error(UnitOfMeasureNotExistErr, "Base Unit of Measure");
                            "Base Unit of Measure" := UnitOfMeasure.Code;
                        end;

                        if not ItemUnitOfMeasure.Get("No.", "Base Unit of Measure") then
                            CreateItemUnitOfMeasure()
                        else
                            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                        UpdateQtyRoundingPrecisionForBaseUoM();
                    end;
                    "Sales Unit of Measure" := "Base Unit of Measure";
                    "Purch. Unit of Measure" := "Base Unit of Measure";
                end;

                if CurrFieldNo <> 0 then
                    if CurrFieldNo <> FieldNo("Base Unit of Measure") then
                        Modify(true);
            end;
        }
        field(9; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';
        }
        field(10; Type; Enum "Item Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateTypeOnBeforeCheckExistsItemLedgerEntry(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if ExistsItemLedgerEntry() then
                        Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption(), "No.", ItemLedgEntryTableCaptionTxt);
                TestNoWhseEntriesExist(FieldCaption(Type));
                CheckJournalsAndWorksheets(FieldNo(Type));
                CheckDocuments(FieldNo(Type));
                if IsNonInventoriableType() then
                    CheckUpdateFieldsForNonInventoriableItem();
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            var
                InventoryPostGroupExists: Boolean;
            begin
                InventoryPostGroupExists := false;
                if "Inventory Posting Group" <> '' then begin
                    TestField(Type, Type::Inventory);
                    InventoryPostGroupExists := InventoryPostingGroup.Get("Inventory Posting Group");
                end;
                if InventoryPostGroupExists then
                    "Inventory Posting Group Id" := InventoryPostingGroup.SystemId
                else
                    Clear("Inventory Posting Group Id");
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
        field(19; "Price/Profit Calculation"; Enum "Item Price Profit Calculation")
        {
            Caption = 'Price/Profit Calculation';

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
                                           ("Unit Price" / (1 + CalcVAT()))), 0.00001)
                        else
                            "Profit %" := 0;
                    "Price/Profit Calculation"::"Price=Cost+Profit":
                        if "Profit %" < 100 then begin
                            GetGLSetup();
                            "Unit Price" :=
                              Round(
                                ("Unit Cost" / (1 - "Profit %" / 100)) *
                                (1 + CalcVAT()),
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
        field(21; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';

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
                          Format(true), ItemTrackingCode.TableCaption(), ItemTrackingCode.Code,
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitCost(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if IsNonInventoriableType() then
                    exit;

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
                    // Show confirmation dialog only for standard web client.
                    if GuiAllowed() then
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

                TariffNumber.Init();
                TariffNumber."No." := "Tariff No.";
                TariffNumber.Insert();
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
            CalcFormula = exist("Comment Line" where("Table Name" = const(Item),
                                                      "No." = field("No.")));
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
            CalcFormula = - exist("Post Value Entry to G/L" where("Item No." = field("No.")));
            Caption = 'Cost is Posted to G/L';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';

            trigger OnValidate()
            begin
                if ("Block Reason" <> '') and ("Block Reason" <> xRec."Block Reason") then
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
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(67; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(68; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Drop Shipment" = field("Drop Shipment Filter"),
                                                                  "Variant Code" = field("Variant Filter"),
                                                                  "Lot No." = field("Lot No. Filter"),
                                                                  "Serial No." = field("Serial No. Filter"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                  "Package No." = field("Package No. Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Net Invoiced Qty."; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Net Invoiced Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Net Change"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Drop Shipment" = field("Drop Shipment Filter"),
                                                                  "Posting Date" = field("Date Filter"),
                                                                  "Variant Code" = field("Variant Filter"),
                                                                  "Lot No." = field("Lot No. Filter"),
                                                                  "Serial No." = field("Serial No. Filter"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                  "Package No." = field("Package No. Filter")));
            Caption = 'Net Change';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Purchases (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const(Purchase),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Purchases (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Value Entry"."Invoiced Quantity" where("Item Ledger Entry Type" = const(Sale),
                                                                        "Item No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Location Code" = field("Location Filter"),
                                                                        "Drop Shipment" = field("Drop Shipment Filter"),
                                                                        "Variant Code" = field("Variant Filter"),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Positive Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const("Positive Adjmt."),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Positive Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(74; "Negative Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const("Negative Adjmt."),
                                                                              "Item No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Drop Shipment" = field("Drop Shipment Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Posting Date" = field("Date Filter"),
                                                                              "Lot No." = field("Lot No. Filter"),
                                                                              "Serial No." = field("Serial No. Filter"),
                                                                              "Package No." = field("Package No. Filter")));
            Caption = 'Negative Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Purchases (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Purchase Amount (Actual)" where("Item Ledger Entry Type" = const(Purchase),
                                                                              "Item No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Drop Shipment" = field("Drop Shipment Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Posting Date" = field("Date Filter")));
            Caption = 'Purchases (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry Type" = const(Sale),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Sales (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Positive Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const("Positive Adjmt."),
                                                                          "Item No." = field("No."),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Positive Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Negative Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const("Negative Adjmt."),
                                                                          "Item No." = field("No."),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Negative Adjmt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "COGS (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry Type" = const(Sale),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'COGS (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Qty. on Purch. Order"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                               Type = const(Item),
                                                                               "No." = field("No."),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Drop Shipment" = field("Drop Shipment Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Expected Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Purch. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Qty. on Sales Order"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                            Type = const(Item),
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
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
                    SalesSetup.Get();
                    SalesSetup.TestField("VAT Bus. Posting Gr. (Price)");
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
            var
                ConfirmMgt: Codeunit "Confirm Management";
                Question: Text;
                GenProdPostGroupExists: Boolean;
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then begin
                    if CurrFieldNo <> 0 then
                        if ProdOrderExist() then begin
                            Question := StrSubstNo(Text024 + Text022, FieldCaption("Gen. Prod. Posting Group"));
                            if not ConfirmMgt.GetResponseOrDefault(Question, true)
                            then begin
                                "Gen. Prod. Posting Group" := xRec."Gen. Prod. Posting Group";
                                exit;
                            end;
                        end;

                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;

                GenProdPostGroupExists := false;
                if "Gen. Prod. Posting Group" <> '' then
                    GenProdPostGroupExists := GenProdPostingGrp.Get("Gen. Prod. Posting Group");
                if GenProdPostGroupExists then
                    "Gen. Prod. Posting Group Id" := GenProdPostingGrp.SystemId
                else
                    Clear("Gen. Prod. Posting Group Id");

                Validate("Price/Profit Calculation");
            end;
        }
        field(92; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        field(93; "Transferred (Qty.)"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Invoiced Quantity" where("Entry Type" = const(Transfer),
                                                                             "Item No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Drop Shipment" = field("Drop Shipment Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Serial No." = field("Serial No. Filter"),
                                                                             "Package No." = field("Package No. Filter")));
            Caption = 'Transferred (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Transferred (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry Type" = const(Transfer),
                                                                           "Item No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Drop Shipment" = field("Drop Shipment Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Posting Date" = field("Date Filter")));
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
                UpdateTaxGroupId();
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
        field(100; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            InitValue = Optional;

            trigger OnValidate()
            begin
                if Reserve in [Reserve::Optional, Reserve::Always] then
                    TestField(Type, Type::Inventory);
            end;
        }
        field(101; "Reserved Qty. on Inventory"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(32),
                                                                           "Source Subtype" = const("0"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Serial No." = field("Serial No. Filter"),
                                                                           "Lot No." = field("Lot No. Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Package No." = field("Package No. Filter")));
            Caption = 'Reserved Qty. on Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "Reserved Qty. on Purch. Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(39),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Reserved Qty. on Purch. Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(103; "Reserved Qty. on Sales Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(37),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Reserved Qty. on Sales Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(107; "Res. Qty. on Outbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(5741),
                                                                            "Source Subtype" = const("0"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Outbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(108; "Res. Qty. on Inbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(5741),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Inbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(109; "Res. Qty. on Sales Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(37),
                                                                           "Source Subtype" = const("5"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Sales Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Res. Qty. on Purch. Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(39),
                                                                            "Source Subtype" = const("5"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Expected Receipt Date" = field("Date Filter")));
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
        field(122; "Variant Mandatory if Exists"; Option)
        {
            Caption = 'Variant Mandatory if Exists';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(200; "Cost of Open Production Orders"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Cost Amount" where(Status = filter(Planned | "Firm Planned" | Released),
                                                                      "Item No." = field("No.")));
            Caption = 'Cost of Open Production Orders';
            FieldClass = FlowField;
        }
        field(521; "Application Wksh. User ID"; Code[128])
        {
            Caption = 'Application Wksh. User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Item)));
        }
        field(910; "Assembly Policy"; Enum "Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';

            trigger OnValidate()
            begin
                if "Assembly Policy" = "Assembly Policy"::"Assemble-to-Order" then
                    TestField("Replenishment System", "Replenishment System"::Assembly);
                if IsNonInventoriableType() then
                    TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
            end;
        }
        field(929; "Res. Qty. on Assembly Order"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(900),
                                                                           "Source Subtype" = const("1"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(930; "Res. Qty. on  Asm. Comp."; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(901),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on  Asm. Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(977; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = sum("Assembly Header"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                   "Item No." = field("No."),
                                                                                   "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Location Code" = field("Location Filter"),
                                                                                   "Variant Code" = field("Variant Filter"),
                                                                                   "Due Date" = field("Date Filter"),
                                                                                   "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(978; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = sum("Assembly Line"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                 Type = const(Item),
                                                                                 "No." = field("No."),
                                                                                 "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                 "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                 "Location Code" = field("Location Filter"),
                                                                                 "Variant Code" = field("Variant Filter"),
                                                                                 "Due Date" = field("Date Filter"),
                                                                                 "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Asm. Component';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1001; "Qty. on Job Order"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Remaining Qty. (Base)" where(Status = const(Order),
                                                                                 Type = const(Item),
                                                                                 "No." = field("No."),
                                                                                 "Location Code" = field("Location Filter"),
                                                                                 "Variant Code" = field("Variant Filter"),
                                                                                 "Planning Date" = field("Date Filter"),
                                                                                 "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1002; "Res. Qty. on Job Order"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(1003),
                                                                            "Source Subtype" = const("2"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1217; GTIN; Code[14])
        {
            Caption = 'GTIN';
            Numeric = true;
            ExtendedDatatype = Barcode;
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
        field(5417; "Flushing Method"; Enum "Flushing Method")
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Flushing Method';
        }
        field(5419; "Replenishment System"; Enum "Replenishment System")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Replenishment System';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
                    "Replenishment System"::"Prod. Order":
                        begin
                            TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
                            TestField(Type, Type::Inventory);
                        end;
                    "Replenishment System"::Transfer:
                        begin
                            IsHandled := false;
                            OnValidateReplenishmentSystemCaseTransfer(Rec, IsHandled);
                            if not IsHandled then
                                error(ReplenishmentSystemTransferErr);
                        end;
                    "Replenishment System"::Assembly:
                        begin
                            IsHandled := false;
                            OnValidateReplenishmentSystemCaseAssemblyr(Rec, IsHandled);
                            if not IsHandled then
                                TestField(Type, Type::Inventory);
                        end;
                    else
                        OnValidateReplenishmentSystemCaseElse(Rec);
                end;
            end;
        }
        field(5420; "Scheduled Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = filter("Firm Planned" | Released),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Due Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Scheduled Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5421; "Scheduled Need (Qty.)"; Decimal)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Use the field ''Qty. on Component Lines'' instead';
            ObsoleteTag = '18.0';
            CalcFormula = sum("Prod. Order Component"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                     "Item No." = field("No."),
                                                                                     "Variant Code" = field("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Due Date" = field("Date Filter"),
                                                                                     "Unit of Measure Code" = field("Unit of Measure Filter")));
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
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(5424; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code where("Item No." = field("No."));
        }
        field(5425; "Sales Unit of Measure"; Code[10])
        {
            Caption = 'Sales Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5426; "Purch. Unit of Measure"; Code[10])
        {
            Caption = 'Purch. Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5427; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
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
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(5406),
                                                                           "Source Subtype" = filter("1" .. "3"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Reserved Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5430; "Res. Qty. on Prod. Order Comp."; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(5407),
                                                                            "Source Subtype" = filter("1" .. "3"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Prod. Order Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5431; "Res. Qty. on Req. Line"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(246),
                                                                           "Source Subtype" = filter("0"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Req. Line';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5440; "Reordering Policy"; Enum "Reordering Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reordering Policy';

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
        field(5442; "Manufacturing Policy"; Enum "Manufacturing Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Manufacturing Policy';
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
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where("Worksheet Template Name" = filter(<> ''),
                                                                          "Journal Batch Name" = filter(<> ''),
                                                                          "Replenishment System" = const(Transfer),
                                                                          Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Transfer-from Code" = field("Location Filter"),
                                                                          "Transfer Shipment Date" = field("Date Filter")));
            Caption = 'Planning Transfer Ship. (Qty).';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5450; "Planning Worksheet (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where("Planning Line Origin" = const(Planning),
                                                                          Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Planning Worksheet (Qty.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5700; "Stockkeeping Unit Exists"; Boolean)
        {
            CalcFormula = exist("Stockkeeping Unit" where("Item No." = field("No.")));
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
                UpdateItemCategoryId();

                OnAfterValidateItemCategoryCode(Rec, xRec);
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
            ObsoleteTag = '15.0';
        }
        field(5706; "Substitutes Exist"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No.")));
            Caption = 'Substitutes Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5707; "Qty. in Transit"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Derived From Line No." = const(0),
                                                                              "Item No." = field("No."),
                                                                              "Transfer-to Code" = field("Location Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Receipt Date" = field("Date Filter"),
                                                                              "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5708; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("No."),
                                                                               "Transfer-to Code" = field("Location Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5709; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Derived From Line No." = const(0),
                                                                               "Item No." = field("No."),
                                                                               "Transfer-from Code" = field("Location Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Shipment Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
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
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Item No." = field("No."),
                                                                                         "Location Code" = field("Location Filter"),
                                                                                         "Variant Code" = field("Variant Filter"),
                                                                                         "Due Date" = field("Date Filter")));
            Caption = 'Qty. Assigned to ship';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5777; "Qty. Picked"; Decimal)
        {
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Picked (Base)" where("Item No." = field("No."),
                                                                                    "Location Code" = field("Location Filter"),
                                                                                    "Variant Code" = field("Variant Filter"),
                                                                                    "Due Date" = field("Date Filter")));
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5801; "Excluded from Cost Adjustment"; Boolean)
        {
            Caption = 'Excluded from Cost Adjustment';
            DataClassification = CustomerContent;
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
                    if not ResSkillMgt.ChangeResSkillRelationWithGroup(
                         ResSkill.Type::Item,
                         "No.",
                         ResSkill.Type::"Service Item Group",
                         "Service Item Group",
                         xRec."Service Item Group")
                    then
                        "Service Item Group" := xRec."Service Item Group";
                end else
                    ResSkillMgt.RevalidateResSkillRelation(
                      ResSkill.Type::Item,
                      "No.",
                      ResSkill.Type::"Service Item Group",
                      "Service Item Group")
            end;
        }
        field(5901; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = sum("Service Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                              Type = const(Item),
                                                                              "No." = field("No."),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Variant Code" = field("Variant Filter"),
                                                                              "Needed by Date" = field("Date Filter"),
                                                                              "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5902; "Res. Qty. on Service Orders"; Decimal)
        {
            AccessByPermission = TableData "Service Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                            "Source Type" = const(5902),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = const(Reservation),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
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
                IsHandled: Boolean;
            begin
                if "Item Tracking Code" <> '' then
                    TestField(Type, Type::Inventory);
                if "Item Tracking Code" = xRec."Item Tracking Code" then
                    exit;

                if not ItemTrackingCode.Get("Item Tracking Code") then
                    Clear(ItemTrackingCode);

                if not ItemTrackingCode2.Get(xRec."Item Tracking Code") then
                    Clear(ItemTrackingCode2);

                IsHandled := false;
                OnValidateItemTrackingCodeOnBeforeTestNoEntriesExist(Rec, xRec, CurrFieldNo, IsHandled);
                if ItemTrackingCode.IsSpecificTrackingChanged(ItemTrackingCode2) then
                    if not IsHandled then
                        TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                if ItemTrackingCode.IsWarehouseTrackingChanged(ItemTrackingCode2) then
                    TestNoWhseEntriesExist(FieldCaption("Item Tracking Code"));

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption(), ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoOpenDocumentsWithTrackingExist();

                if "Expiration Calculation" <> EmptyDateFormula then
                    if not ItemTrackingCodeUseExpirationDates() then
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
                    if not ItemTrackingCodeUseExpirationDates() then
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
        field(6515; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            CaptionClass = '6,3';
            FieldClass = FlowFilter;
        }
        field(6650; "Qty. on Purch. Return"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Qty. (Base)" where("Document Type" = const("Return Order"),
                                                                               Type = const(Item),
                                                                               "No." = field("No."),
                                                                               "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Drop Shipment" = field("Drop Shipment Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Expected Receipt Date" = field("Date Filter"),
                                                                               "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Purch. Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6660; "Qty. on Sales Return"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = sum("Sales Line"."Outstanding Qty. (Base)" where("Document Type" = const("Return Order"),
                                                                            Type = const(Item),
                                                                            "No." = field("No."),
                                                                            "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Drop Shipment" = field("Drop Shipment Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Shipment Date" = field("Date Filter"),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Sales Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7171; "No. of Substitutes"; Integer)
        {
            CalcFormula = count("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No.")));
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
            TableRelation = if ("No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
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
                IsHandled: Boolean;
            begin
                if ("Phys Invt Counting Period Code" <> '') and
                   (("Phys Invt Counting Period Code" <> xRec."Phys Invt Counting Period Code") or
                   (xRec."Phys Invt Counting Period Code" <> ''))
                then begin
                    PhysInvtCountPeriod.Get("Phys Invt Counting Period Code");
                    PhysInvtCountPeriod.TestField("Count Frequency per Year");
                    IsHandled := false;
                    OnValidatePhysInvtCountingPeriodCodeOnBeforeConfirmUpdate(Rec, xRec, PhysInvtCountPeriod, IsHandled);
                    if not IsHandled then
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

                    if "Last Counting Period Update" <> 0D then
                        "Last Counting Period Update" := WorkDate();
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
            CalcFormula = max("Phys. Inventory Ledger Entry"."Posting Date" where("Item No." = field("No."),
                                                                                   "Phys Invt Counting Period Type" = filter(" " | Item)));
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
        field(7387; "Unit Group Exists"; Boolean)
        {
            CalcFormula = exist("Unit Group" where("Source Id" = field(SystemId),
                                                "Source Type" = const(Item)));
            Caption = 'Unit Group Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7700; "Identifier Code"; Code[20])
        {
            CalcFormula = lookup("Item Identifier".Code where("Item No." = field("No.")));
            Caption = 'Identifier Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(8001; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".SystemId;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode();
            end;
        }
        field(8002; "Tax Group Id"; Guid)
        {
            Caption = 'Tax Group Id';
            TableRelation = "Tax Group".SystemId;

            trigger OnValidate()
            begin
                UpdateTaxGroupCode();
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
            TableRelation = "Item Category".SystemId;

            trigger OnValidate()
            begin
                UpdateItemCategoryCode();
            end;
        }
        field(8006; "Inventory Posting Group Id"; Guid)
        {
            Caption = 'Inventory Posting Group Id';
            TableRelation = "Inventory Posting Group".SystemId;

            trigger OnValidate()
            var
                InventoryPostGroupExists: Boolean;
            begin
                InventoryPostGroupExists := false;
                if not IsNullGuid("Inventory Posting Group Id") then
                    InventoryPostGroupExists := InventoryPostingGroup.GetBySystemId("Inventory Posting Group Id");
                if InventoryPostGroupExists then
                    Validate("Inventory Posting Group", InventoryPostingGroup."Code")
                else
                    Validate("Inventory Posting Group", '')
            end;
        }
        field(8007; "Gen. Prod. Posting Group Id"; Guid)
        {
            Caption = 'Gen. Prod. Posting Group Id';
            TableRelation = "Gen. Product Posting Group".SystemId;
            trigger OnValidate()
            var
                GenProdPostGroup: Record "Gen. Product Posting Group";
                GenProdPostGroupExists: Boolean;
            begin
                GenProdPostGroupExists := false;
                if not IsNullGuid("Gen. Prod. Posting Group Id") then
                    GenProdPostGroupExists := GenProdPostGroup.GetBySystemId("Gen. Prod. Posting Group Id");

                if GenProdPostGroupExists then
                    Validate("Gen. Prod. Posting Group", GenProdPostGroup."Code")
                else
                    Validate("Gen. Prod. Posting Group", '')
            end;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
        field(11500; "No Stockkeeping"; Boolean)
        {
            Caption = 'No Stockkeeping';
            ObsoleteReason = 'Removing local functionality and adding Non-Inventory Item Type';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(11501; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(11503; "Sale blocked"; Boolean)
        {
            Caption = 'Sale blocked';
            ObsoleteReason = 'The field has been reproduced in W1 and will now have a new ID and be called Blocked for sale.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(11504; "Purchase blocked"; Boolean)
        {
            Caption = 'Purchase blocked';
            ObsoleteReason = 'The field has been reproduced in W1 and will now have a new ID and be called Blocked for purchase.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(11505; "Inventory Price"; Decimal)
        {
            Caption = 'Inventory Price';
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
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateProductionBOMNo(Rec, xRec, IsHandled);
                if not IsHandled then begin
                    if "Production BOM No." <> '' then
                        TestField(Type, Type::Inventory);

                    PlanningAssignment.BomReplace(Rec, xRec."Production BOM No.");

                    if "Production BOM No." <> xRec."Production BOM No." then
                        ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Production BOM No."));

                    if ("Production BOM No." <> '') and ("Production BOM No." <> xRec."Production BOM No.") then begin
                        ProdBOMHeader.Get("Production BOM No.");
                        ItemUnitOfMeasure.Get("No.", ProdBOMHeader."Unit of Measure Code");
                        if ProdBOMHeader.Status = ProdBOMHeader.Status::Certified then begin
                            MfgSetup.Get();
                            if MfgSetup."Dynamic Low-Level Code" then begin
                                CODEUNIT.Run(CODEUNIT::"Calculate Low-Level Code", Rec);
                                OnValidateProductionBOMNoOnAfterCodeunitRun(ProdBOMHeader, Rec);
                            end;
                            OnValidateProductionBOMNoOnAfterProcessStatusCertified(ProdBOMHeader, Rec);
                        end;
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
            CalcFormula = sum("Planning Component"."Expected Quantity (Base)" where("Item No." = field("No."),
                                                                                     "Due Date" = field("Date Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Variant Code" = field("Variant Filter"),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Planning Line Origin" = const(" "),
                                                                                     "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Issues (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000762; "Planning Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000765; "Planned Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Planned),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Due Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planned Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000766; "FP Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const("Firm Planned"),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Due Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'FP Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000767; "Rel. Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Released),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Due Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Rel. Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000768; "Planning Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Starting Date" = field("Date Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planning Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000769; "Planned Order Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Planned),
                                                                                "Item No." = field("No."),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Starting Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Planned Order Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000770; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Due Date" = field("Date Filter"),
                                                                          "Planning Line Origin" = const(" "),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Purch. Req. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000771; "Purch. Req. Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Requisition Line"."Quantity (Base)" where(Type = const(Item),
                                                                          "No." = field("No."),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Drop Shipment" = field("Drop Shipment Filter"),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Order Date" = field("Date Filter"),
                                                                          "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Purch. Req. Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000773; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';

            trigger OnValidate()
            var
                ReservEntry: Record "Reservation Entry";
                ActionMessageEntry: Record "Action Message Entry";
                TempReservationEntry: Record "Reservation Entry" temporary;
                ShouldRaiseRegenerativePlanningMessage: Boolean;
            begin
                if "Order Tracking Policy" <> "Order Tracking Policy"::None then
                    TestField(Type, Type::Inventory);
                if xRec."Order Tracking Policy" = "Order Tracking Policy" then
                    exit;

                ShouldRaiseRegenerativePlanningMessage := "Order Tracking Policy".AsInteger() > xRec."Order Tracking Policy".AsInteger();
                OnValidateOrderTrackingPolicyOnBeforeUpdateReservation(Rec, ShouldRaiseRegenerativePlanningMessage);
                if ShouldRaiseRegenerativePlanningMessage then
                    Message(Text99000000 + Text99000001, "Order Tracking Policy")
                else begin
                    ActionMessageEntry.SetCurrentKey("Reservation Entry");
                    ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
                    ReservEntry.SetRange("Item No.", "No.");
                    ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Tracking, ReservEntry."Reservation Status"::Surplus);
                    if ReservEntry.Find('-') then
                        repeat
                            ActionMessageEntry.SetRange("Reservation Entry", ReservEntry."Entry No.");
                            ActionMessageEntry.DeleteAll();
                            if "Order Tracking Policy" = "Order Tracking Policy"::None then
                                if ReservEntry.TrackingExists() then begin
                                    TempReservationEntry := ReservEntry;
                                    TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Surplus;
                                    TempReservationEntry.Insert();
                                end else
                                    ReservEntry.Delete();
                        until ReservEntry.Next() = 0;

                    if TempReservationEntry.Find('-') then
                        repeat
                            ReservEntry := TempReservationEntry;
                            ReservEntry.Modify();
                        until TempReservationEntry.Next() = 0;
                end;
            end;
        }
        field(99000774; "Prod. Forecast Quantity (Base)"; Decimal)
        {
            CalcFormula = sum("Production Forecast Entry"."Forecast Quantity (Base)" where("Item No." = field("No."),
                                                                                            "Production Forecast Name" = field("Production Forecast Name"),
                                                                                            "Forecast Date" = field("Date Filter"),
                                                                                            "Location Code" = field("Location Filter"),
                                                                                            "Component Forecast" = field("Component Forecast"),
                                                                                            "Variant Code" = field("Variant Filter")));
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
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                "Item No." = field("No."),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Filter"),
                                                                                "Variant Code" = field("Variant Filter"),
                                                                                "Due Date" = field("Date Filter"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000778; "Qty. on Component Lines"; Decimal)
        {
            CalcFormula = sum("Prod. Order Component"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                     "Item No." = field("No."),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Variant Code" = field("Variant Filter"),
                                                                                     "Due Date" = field("Date Filter"),
                                                                                     "Unit of Measure Code" = field("Unit of Measure Filter")));
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
            IncludedFields = "Excluded from Cost Adjustment";
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
        key(Key17; SystemModifiedAt)
        {
        }
        key(Key18; GTIN)
        {
        }
#if not CLEAN23
        key(Key19; "Coupled to CRM")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteTag = '23.0';
        }
#endif
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
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);

        CheckJournalsAndWorksheets(0);
        CheckDocuments(0);

        MoveEntries.MoveItemEntries(Rec);

        DeleteRelatedData();

        DeleteItemUnitGroup();
    end;

    trigger OnInsert()
    var
        Item: Record Item;
#if not CLEAN24
        NoSeriesManagement: Codeunit NoSeriesManagement;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled, xRec);
        if not IsHandled then begin
            if "No." = '' then begin
                GetInvtSetup();
                InventorySetup.TestField("Item Nos.");
#if not CLEAN24
                NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(InventorySetup."Item Nos.", xRec."No. Series", 0D, "No.", "No. Series", IsHandled);
                if not IsHandled then begin
                    if NoSeries.AreRelated(InventorySetup."Item Nos.", xRec."No. Series") then
                        "No. Series" := xRec."No. Series"
                    else
                        "No. Series" := InventorySetup."Item Nos.";
                    "No." := NoSeries.GetNextNo("No. Series");
                    Item.ReadIsolation(IsolationLevel::ReadUncommitted);
                    Item.SetLoadFields("No.");
                    while Item.Get("No.") do
                        "No." := NoSeries.GetNextNo("No. Series");
                    NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", InventorySetup."Item Nos.", 0D, "No.");
                end;
#else
			if NoSeries.AreRelated(InventorySetup."Item Nos.", xRec."No. Series") then
				"No. Series" := xRec."No. Series"
			else
				"No. Series" := InventorySetup."Item Nos.";
                "No." := NoSeries.GetNextNo("No. Series");
                Item.ReadIsolation(IsolationLevel::ReadUncommitted);
                Item.SetLoadFields("No.");
                while Item.Get("No.") do
                   "No." := NoSeries.GetNextNo("No. Series");
#endif
                "Costing Method" := InventorySetup."Default Costing Method";
            end;

            DimMgt.UpdateDefaultDim(
              DATABASE::Item, "No.",
              "Global Dimension 1 Code", "Global Dimension 2 Code");

            UpdateReferencedIds();
            SetLastDateTimeModified();

            UpdateItemUnitGroup();
        end;

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        UpdateReferencedIds();
        SetLastDateTimeModified();

        IsHandled := false;
        OnModifyOnBeforePlanningAssignmentItemChange(Rec, xRec, PlanningAssignment, IsHandled);
        if not IsHandled then
            PlanningAssignment.ItemChange(Rec, xRec);

        UpdateItemUnitGroup();
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
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Item, xRec."No.", "No.");

        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        ItemAttributeValueMapping.RenameItemAttributeValueMapping(xRec."No.", "No.");
        SetLastDateTimeModified();

        UpdateItemUnitGroup();
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 that includes this item.';
        CannotDeleteItemIfSalesDocExistErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Sales %3 that includes this item.', Comment = '1: Type, 2 Item No. and 3 : Type of document Order,Invoice';
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
        InventorySetup: Record "Inventory Setup";
        Text023: Label 'You cannot delete %1 %2 because there is at least one %3 that includes this item.';
        Text024: Label 'If you change %1 it may affect existing production orders.\';
        Text025: Label '%1 must be an integer because %2 %3 is set up to use %4.';
        Text026: Label '%1 cannot be changed because the %2 has work in process (WIP). Changing the value may offset the WIP account.';
        Text7380: Label 'If you change the %1, the %2 and %3 are calculated.\Do you still want to change the %1?', Comment = 'If you change the Phys Invt Counting Period Code, the Next Counting Start Date and Next Counting End Date are calculated.\Do you still want to change the Phys Invt Counting Period Code?';
        Text7381: Label 'Cancelled.';
        Text99000000: Label 'The change will not affect existing entries.\';
        CommentLine: Record "Comment Line";
        Text99000001: Label 'If you want to generate %1 for existing entries, you must run a regenerative planning.';
        ItemVendor: Record "Item Vendor";
        ItemReference: Record "Item Reference";
        SalesPrepmtPct: Record "Sales Prepayment %";
        PurchPrepmtPct: Record "Purchase Prepayment %";
        ItemTranslation: Record "Item Translation";
        BOMComp: Record "BOM Component";
        VATPostingSetup: Record "VAT Posting Setup";
        ExtTextHeader: Record "Extended Text Header";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningAssignment: Record "Planning Assignment";
        StockkeepingUnit: Record "Stockkeeping Unit";
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
        ServiceContractLine: Record "Service Contract Line";
        InventoryPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
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
        ReplenishmentSystemTransferErr: Label 'The Replenishment System Transfer cannot be used for item.';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';

    protected var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";

    local procedure DeleteRelatedData()
    var
        BinContent: Record "Bin Content";
        MyItem: Record "My Item";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariant: Record "Item Variant";
        EntityText: Record "Entity Text";
    begin
        ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        ItemBudgetEntry.SetRange("Item No.", "No.");
        ItemBudgetEntry.DeleteAll(true);

        ItemSub.Reset();
        ItemSub.SetRange(Type, ItemSub.Type::Item);
        ItemSub.SetRange("No.", "No.");
        ItemSub.DeleteAll();

        ItemSub.Reset();
        ItemSub.SetRange("Substitute Type", ItemSub."Substitute Type"::Item);
        ItemSub.SetRange("Substitute No.", "No.");
        ItemSub.DeleteAll();

        StockkeepingUnit.Reset();
        StockkeepingUnit.SetCurrentKey("Item No.");
        StockkeepingUnit.SetRange("Item No.", "No.");
        StockkeepingUnit.DeleteAll();

        CatalogItemMgt.NonstockItemDel(Rec);
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        ItemVendor.SetCurrentKey("Item No.");
        ItemVendor.SetRange("Item No.", "No.");
        ItemVendor.DeleteAll();

        ItemReference.SetRange("Item No.", "No.");
        ItemReference.DeleteAll();

        SalesPrepmtPct.SetRange("Item No.", "No.");
        SalesPrepmtPct.DeleteAll();

        PurchPrepmtPct.SetRange("Item No.", "No.");
        PurchPrepmtPct.DeleteAll();

        ItemTranslation.SetRange("Item No.", "No.");
        ItemTranslation.DeleteAll();

        ItemUnitOfMeasure.SetRange("Item No.", "No.");
        ItemUnitOfMeasure.DeleteAll();

        ItemVariant.SetRange("Item No.", "No.");
        ItemVariant.DeleteAll();

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        ItemAnalysisViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisViewEntry.DeleteAll();

        ItemAnalysisBudgViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisBudgViewEntry.DeleteAll();

        PlanningAssignment.SetRange("Item No.", "No.");
        PlanningAssignment.DeleteAll();

        BOMComp.Reset();
        BOMComp.SetRange("Parent Item No.", "No.");
        BOMComp.DeleteAll();

        TroubleshSetup.Reset();
        TroubleshSetup.SetRange(Type, TroubleshSetup.Type::Item);
        TroubleshSetup.SetRange("No.", "No.");
        TroubleshSetup.DeleteAll();

        ResSkillMgt.DeleteItemResSkills("No.");
        DimMgt.DeleteDefaultDim(DATABASE::Item, "No.");

        ItemIdent.Reset();
        ItemIdent.SetCurrentKey("Item No.");
        ItemIdent.SetRange("Item No.", "No.");
        ItemIdent.DeleteAll();

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "No.");
        BinContent.DeleteAll();

        MyItem.SetRange("Item No.", "No.");
        MyItem.DeleteAll();

        ItemAttributeValueMapping.Reset();
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", "No.");
        ItemAttributeValueMapping.DeleteAll();

        EntityText.SetRange(Company, CompanyName());
        EntityText.SetRange("Source Table Id", Database::Item);
        EntityText.SetRange("Source System Id", Rec.SystemId);
        EntityText.DeleteAll();

        OnAfterDeleteRelatedData(Rec);
    end;

    procedure AssistEdit() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetInvtSetup();
        InventorySetup.TestField("Item Nos.");
        if NoSeries.LookupRelatedNoSeries(InventorySetup."Item Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            if xRec."No." = '' then
                "Costing Method" := InventorySetup."Default Costing Method";
            exit(true);
        end;
    end;

    procedure FindItemVend(var ItemVend: Record "Item Vendor"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemVend(Rec, ItemVend, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        ItemVend.Reset();
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.SetRange("Vendor No.", ItemVend."Vendor No.");
        ItemVend.SetRange("Variant Code", ItemVend."Variant Code");
        OnFindItemVendOnAfterSetFilters(ItemVend, Rec);

        if not ItemVend.Find('+') then begin
            ItemVend."Item No." := "No.";
            ItemVend."Vendor Item No." := '';
            GetPlanningParameters.AtSKU(StockkeepingUnit, "No.", ItemVend."Variant Code", LocationCode);
            if ItemVend."Vendor No." = '' then
                ItemVend."Vendor No." := StockkeepingUnit."Vendor No.";
            if ItemVend."Vendor Item No." = '' then
                ItemVend."Vendor Item No." := StockkeepingUnit."Vendor Item No.";
            ItemVend."Lead Time Calculation" := StockkeepingUnit."Lead Time Calculation";
        end;
        ItemVend.FindLeadTimeCalculation(Rec, StockkeepingUnit, LocationCode);
        ItemVend.Reset();

        OnAfterFindItemVend(ItemVend, Rec, StockkeepingUnit, LocationCode);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Item, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

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
            if not ItemLedgEntry.IsEmpty() then
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
            if PurchaseLine.FindFirst() then
                Error(Text008, CurrentFieldName, PurchaseLine."Document Type");
        end;
    end;

    procedure TestNoWhseEntriesExist(CurrentFieldName: Text)
    var
        WarehouseEntry: Record "Warehouse Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoWhseEntriesExist(Rec, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        WarehouseEntry.SetRange("Item No.", "No.");
        if not WarehouseEntry.IsEmpty() then
            Error(WhseEntriesExistErr, CurrentFieldName);
    end;

    procedure TestNoOpenEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoOpenEntriesExist(Rec, ItemLedgEntry, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty() then
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoOpenDocumentsWithTrackingExist(Rec, ItemTrackingCode2, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode2.Code = '' then
            exit;

        TrackingSpecification.SetRange("Item No.", "No.");
        if TrackingSpecification.FindFirst() then begin
            SourceType := TrackingSpecification."Source Type";
            SourceID := TrackingSpecification."Source ID";
        end else begin
            ReservationEntry.SetRange("Item No.", "No.");
            ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
            if ReservationEntry.FindFirst() then begin
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
        if Item.Get("No.") then
            if SKU.Get(LocationCode, Item."No.", VariantCode) then
                Item."Shelf No." := SKU."Shelf No.";
    end;

    procedure GetSKU(LocationCode: Code[10]; VariantCode: Code[10]) SKU: Record "Stockkeeping Unit" temporary
    var
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningGetParameters.AtSKU(SKU, "No.", VariantCode, LocationCode);
    end;

    local procedure GetInvtSetup()
    begin
        if not HasInvtSetup then begin
            InventorySetup.Get();
            HasInvtSetup := true;
        end;
    end;

    procedure IsMfgItem() Result: Boolean
    begin
        Result := "Replenishment System" = "Replenishment System"::"Prod. Order";
        OnAfterIsMfgItem(Rec, Result);
    end;

    procedure IsAssemblyItem() Result: Boolean
    begin
        Result := Rec."Replenishment System" = Rec."Replenishment System"::Assembly;
        OnAfterIsAssemblyItem(Rec, Result);
    end;

    procedure HasBOM(): Boolean
    begin
        CalcFields("Assembly BOM");
        exit("Assembly BOM" or ("Production BOM No." <> ''));
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure ProdOrderExist(): Boolean
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", "No.");
        if not ProdOrderLine.IsEmpty() then
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
        ItemRec.SetLoadFields("No.", "Item Tracking Code");
        if not ItemRec.Get(ItemNo) then
            exit;
        if ItemRec."Item Tracking Code" = '' then
            exit;
        ItemTrackingCode3.SetLoadFields("SN Specific Tracking");
        if not ItemTrackingCode3.Get(ItemRec."Item Tracking Code") then
            exit;
        CheckSNSpecificTrackingInteger(ItemTrackingCode3, ItemRec, FieldName);
    end;

    local procedure CheckSNSpecificTrackingInteger(var ItemTrackingCode3: Record "Item Tracking Code"; var ItemRec: Record Item; FieldName: Text[30])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSNSpecificTrackingInteger(ItemRec, IsHandled);
        if IsHandled then
            exit;

        if ItemTrackingCode3."SN Specific Tracking" then
            Error(Text025,
              FieldName,
              TableCaption,
              ItemRec."No.",
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
        if not ItemLedgEntry.IsEmpty() then
            Error(Text026, FieldCaption("Inventory Value Zero"), TableCaption);
    end;

    procedure CheckBlockedByApplWorksheet()
    var
        ApplicationWorksheet: Page "Application Worksheet";
    begin
        if "Application Wksh. User ID" <> '' then
            Error(Text028, "No.", ApplicationWorksheet.Caption, "Application Wksh. User ID");
    end;

    procedure CheckJournalsAndWorksheets(CurrFieldNo: Integer)
    begin
        CheckItemJnlLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckStdCostWksh(CurrFieldNo);
        CheckReqLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
    end;

    local procedure CheckItemJnlLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckItemJnlLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.SetRange("Item No.", "No.");
        if not ItemJnlLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", ItemJnlLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ItemJnlLine.TableCaption());
        end;
    end;

    local procedure CheckStdCostWksh(CurrentFieldNo: Integer)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckStdCostWksh(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        StandardCostWorksheet.Reset();
        StandardCostWorksheet.SetRange(Type, StandardCostWorksheet.Type::Item);
        StandardCostWorksheet.SetRange("No.", "No.");
        if not StandardCostWorksheet.IsEmpty() then
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", StandardCostWorksheet.TableCaption());
    end;

    local procedure CheckReqLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeCheckReqLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "No.");
        if not RequisitionLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", RequisitionLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", RequisitionLine.TableCaption());
        end;
    end;

    procedure CheckDocuments(CurrentFieldNo: Integer)
    begin
        if "No." = '' then
            exit;

        CheckBOM(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckPurchLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckSalesLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckProdOrderLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckProdOrderCompLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckPlanningCompLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckTransLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckServLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckProdBOMLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckServContractLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckAsmHeader(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckAsmLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckJobPlanningLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));

        OnAfterCheckDocuments(Rec, xRec, CurrentFieldNo);
    end;

    procedure CheckBOM(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBOM(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        BOMComp.Reset();
        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", "No.");
        if not BOMComp.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", BOMComp.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", BOMComp.TableCaption());
        end;
    end;

    procedure CheckPurchLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SetCurrentKey(Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", "No.");
        OnCheckPurchLineOnAfterPurchLineSetFilters(Rec, PurchaseLine, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
        PurchaseLine.SetLoadFields("Document Type");
        if PurchaseLine.FindFirst() then begin
            if CurrentFieldNo = 0 then
                Error(Text000, TableCaption(), "No.", PurchaseLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", PurchaseLine.TableCaption());
        end;
    end;

    procedure CheckSalesLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", "No.");
        SalesLine.SetLoadFields("Document Type");
        if SalesLine.FindFirst() then begin
            if CurrentFieldNo = 0 then
                Error(CannotDeleteItemIfSalesDocExistErr, TableCaption(), "No.", SalesLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", SalesLine.TableCaption());
        end;
    end;

    procedure CheckProdOrderLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderExist() then begin
            if CurrentFieldNo = 0 then
                Error(Text002, TableCaption(), "No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ProdOrderLine.TableCaption());
        end;
    end;

    procedure CheckProdOrderCompLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderCompLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComp.SetCurrentKey(Status, "Item No.");
        ProdOrderComp.SetFilter(Status, '..%1', ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Item No.", "No.");
        if not ProdOrderComp.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text014, TableCaption(), "No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ProdOrderComp.TableCaption());
        end;
    end;

    procedure CheckPlanningCompLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        PlanningComponent: Record "Planning Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPlanningCompLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        PlanningComponent.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Planning Line Origin");
        PlanningComponent.SetRange("Item No.", "No.");
        if not PlanningComponent.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", PlanningComponent.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", PlanningComponent.TableCaption());
        end;
    end;

    procedure CheckTransLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        TransLine.SetCurrentKey("Item No.");
        TransLine.SetRange("Item No.", "No.");
        if not TransLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text016, TableCaption(), "No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", TransLine.TableCaption());
        end;
    end;

    procedure CheckServLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ServInvLine.Reset();
        ServInvLine.SetCurrentKey(Type, "No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::Item);
        ServInvLine.SetRange("No.", "No.");
        if not ServInvLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text017, TableCaption(), "No.", ServInvLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ServInvLine.TableCaption());
        end;
    end;

    procedure CheckProdBOMLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdBOMLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ProdBOMLine.Reset();
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", "No.");
        if ProdBOMLine.Find('-') then begin
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ProdBOMLine.TableCaption());
            if CurrentFieldNo = 0 then
                repeat
                    if ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") and
                       (ProdBOMHeader.Status = ProdBOMHeader.Status::Certified)
                    then
                        Error(Text004, TableCaption(), "No.");
                    if ProductionBOMVersion.Get(ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code") and
                       (ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified)
                    then
                        Error(CannotDeleteItemIfProdBOMVersionExistsErr, TableCaption(), "No.");
                until ProdBOMLine.Next() = 0;
        end;
    end;

    procedure CheckServContractLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        ServiceContractLine.Reset();
        ServiceContractLine.SetRange("Item No.", "No.");
        if not ServiceContractLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", ServiceContractLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ServiceContractLine.TableCaption());
        end;
    end;

    procedure CheckAsmHeader(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        AssemblyHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAsmHeader(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        AssemblyHeader.SetCurrentKey("Document Type", "Item No.");
        AssemblyHeader.SetRange("Item No.", "No.");
        if not AssemblyHeader.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", AssemblyHeader.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", AssemblyHeader.TableCaption());
        end;
    end;

    procedure CheckAsmLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        AssemblyLine: Record "Assembly Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAsmLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;


        AssemblyLine.SetCurrentKey(Type, "No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", "No.");
        if not AssemblyLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", AssemblyLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", AssemblyLine.TableCaption());
        end;
    end;

    procedure CheckUpdateFieldsForNonInventoriableItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateFieldsForNonInventoriableItem(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

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
                    InventorySetup.Get();
                    exit(InventorySetup."Prevent Negative Inventory");
                end;
        end;
    end;

    procedure CheckJobPlanningLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;

    begin
        IsHandled := false;
        OnBeforeCheckJobPlanningLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetRange("No.", "No.");
        if not JobPlanningLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", JobPlanningLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", JobPlanningLine.TableCaption());
        end;
    end;

    local procedure CalcVAT(): Decimal
    begin
        if "Price Includes VAT" then begin
            VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
            OnCalcVATOnAfterVATPostingSetupGet(VATPostingSetup);
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
        GetGLSetup();
        if 1 + CalcVAT() = 0 then
            exit(0);
        exit(Round("Unit Price" / (1 + CalcVAT()), GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure GetItemNo(ItemText: Text): Code[20]
    var
        ItemNo: Text[50];
    begin
        TryGetItemNo(ItemNo, ItemText, true);
        exit(CopyStr(ItemNo, 1, MaxStrLen("No.")));
    end;

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure TryGetItemNo(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean): Boolean
    begin
        InventorySetup.Get();
        exit(TryGetItemNoOpenCard(ReturnValue, ItemText, DefaultCreate, true, not InventorySetup."Skip Prompt to Create Item"));
    end;

    procedure TryGetItemNoOpenCard(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean): Boolean
    var
        ItemView: Record Item;
    begin
        ItemView.SetRange(Blocked, false);
        exit(TryGetItemNoOpenCardWithView(ReturnValue, ItemText, DefaultCreate, ShowItemCard, ShowCreateItemOption, ItemView.GetView()));
    end;

    internal procedure TryGetItemNoOpenCardWithView(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean; View: Text): Boolean
    var
        Item: Record Item;
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

        FoundRecordCount :=
            FindRecordMgt.FindRecordByDescriptionAndView(ReturnValue, SalesLine.Type::Item.AsInteger(), ItemText, View);

        if FoundRecordCount = 1 then
            exit(true);

        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if FoundRecordCount = 0 then begin
            if not DefaultCreate then
                exit(false);

            if not GuiAllowed then
                Error(SelectItemErr);

            OnTryGetItemNoOpenCardWithViewOnBeforeShowCreateItemOption(Rec);
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
            OnTryGetItemNoOpenCardOnAfterSetItemFilters(Item, ItemFilterContains);
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
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        ItemCard: Page "Item Card";
    begin
        OnBeforeCreateNewItem(Item, ItemName);
        if not ItemTemplMgt.InsertItemFromTemplate(Item) then
            Error(SelectItemErr);

        Item.Description := ItemName;
        Item.Modify(true);
        Commit();
        if not ShowItemCard then
            exit(Item."No.");
        Item.SetRange("No.", Item."No.");
        ItemCard.SetTableView(Item);
        if not (ItemCard.RunModal() = ACTION::OK) then
            Error(SelectItemErr);

        exit(Item."No.");
    end;

    local procedure CreateItemUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateItemUnitOfMeasure(Rec, ItemUnitOfMeasure, IsHandled);
        if IsHandled then
            exit;

        ItemUnitOfMeasure.Init();
        if IsTemporary then
            ItemUnitOfMeasure."Item No." := "No."
        else
            ItemUnitOfMeasure.Validate("Item No.", "No.");
        ItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();
    end;

    procedure PickItem(var Item: Record Item): Code[20]
    var
        ItemList: Page "Item List";
    begin
        if Item.FilterGroup = -1 then
            ItemList.SetTempFilteredItemRec(Item);

        if Item.FindFirst() then;
        ItemList.SetTableView(Item);
        ItemList.SetRecord(Item);
        ItemList.LookupMode := true;
        if ItemList.RunModal() = ACTION::LookupOK then
            ItemList.GetRecord(Item)
        else
            Clear(Item);

        exit(Item."No.");
    end;

    procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
        OnAfterSetLastDateTimeModified(Rec);
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

    procedure UpdateReplenishmentSystem() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReplenishmentSystem(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

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

        "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    local procedure UpdateQtyRoundingPrecisionForBaseUoM()
    var
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyRoundingPrecisionForBaseUoM(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        // Reset Rounding Precision in old Base UOM
        if BaseItemUnitOfMeasure.Get("No.", xRec."Base Unit of Measure") then begin
            BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 0);
            BaseItemUnitOfMeasure.Modify(true);
        end;
    end;

    procedure UpdateItemCategoryId()
    var
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        if "Item Category Code" = '' then begin
            Clear("Item Category Id");
            exit;
        end;

        if not ItemCategory.Get("Item Category Code") then
            exit;

        "Item Category Id" := ItemCategory.SystemId;
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

        "Tax Group Id" := TaxGroup.SystemId;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not IsNullGuid("Unit of Measure Id") then
            UnitOfMeasure.GetBySystemId("Unit of Measure Id");

        "Base Unit of Measure" := UnitOfMeasure.Code;
    end;

    local procedure UpdateTaxGroupCode()
    var
        TaxGroup: Record "Tax Group";
    begin
        if not IsNullGuid("Tax Group Id") then
            TaxGroup.GetBySystemId("Tax Group Id");

        Validate("Tax Group Code", TaxGroup.Code);
    end;

    local procedure UpdateItemCategoryCode()
    var
        ItemCategory: Record "Item Category";
    begin
        if not IsNullGuid("Item Category Id") then
            ItemCategory.GetBySystemId("Item Category Id");

        "Item Category Code" := ItemCategory.Code;
    end;

    procedure UpdateReferencedIds()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        UpdateUnitOfMeasureId();
        UpdateTaxGroupId();
        UpdateItemCategoryId();
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
        exit(not IsNonInventoriableType());
    end;

    procedure IsVariantMandatory(IsTypeItem: Boolean; ItemNo: Code[20]): Boolean
    begin
        if IsTypeItem and (ItemNo <> '') then
            exit(IsVariantMandatory(ItemNo));
        exit(false)
    end;

    procedure IsVariantMandatory(): Boolean
    begin
        exit(IsVariantMandatory(Rec."No."));
    end;

    local procedure IsVariantMandatory(ItemNo: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsVariantMandatory(ItemNo, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ItemNo <> Rec."No." then begin
            Rec.SetLoadFields("No.", "Variant Mandatory if Exists");
            if Rec.Get(ItemNo) then;
            Rec.SetLoadFields();
        end;
        if ItemNo <> Rec."No." then
            exit(false);
        if VariantMandatoryIfAvailable(false, false) then
            exit(VariantsAvailable(ItemNo))
        else
            exit(false);
    end;

    internal procedure IsVariantMandatory(InvtSetupDefaultSetting: boolean): Boolean
    begin
        if VariantMandatoryIfAvailable(true, InvtSetupDefaultSetting) then
            exit(VariantsAvailable())
        else
            exit(false);
    end;

    local procedure VariantMandatoryIfAvailable(InvtSetupDefaultIsKnown: boolean; InvtSetupDefaultSetting: boolean): Boolean
    begin
        case "Variant Mandatory if Exists" of
            "Variant Mandatory if Exists"::Default:
                begin
                    if InvtSetupDefaultIsKnown then
                        exit(InvtSetupDefaultSetting);
                    GetInvtSetup();
                    exit(InventorySetup."Variant Mandatory if Exists");
                end;
            "Variant Mandatory if Exists"::No:
                exit(false);
            "Variant Mandatory if Exists"::Yes:
                exit(true);
        end;
    end;

    local procedure VariantsAvailable(): Boolean
    begin
        exit(VariantsAvailable(Rec."No."));
    end;

    local procedure VariantsAvailable(ItemNo: Code[20]): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetLoadFields("Item No.");
        ItemVariant.SetRange("Item No.", ItemNo);
        exit(not ItemVariant.IsEmpty());
    end;

    local procedure UpdateItemUnitGroup()
    var
        UnitGroup: Record "Unit Group";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if CRMIntegrationManagement.IsIntegrationEnabled() then begin
            UnitGroup.SetRange("Source Id", Rec.SystemId);
            UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Item);
            if UnitGroup.IsEmpty() then begin
                UnitGroup.Init();
                UnitGroup."Source Id" := Rec.SystemId;
                UnitGroup."Source No." := Rec."No.";
                UnitGroup."Source Type" := UnitGroup."Source Type"::Item;
                UnitGroup.Insert();
            end;
        end
    end;

    local procedure DeleteItemUnitGroup()
    var
        UnitGroup: Record "Unit Group";
    begin
        if UnitGroup.Get(UnitGroup."Source Type"::Item, Rec.SystemId) then
            UnitGroup.Delete();
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
    local procedure OnAfterIsMfgItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAssemblyItem(Item: Record Item; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Item: Record Item; xItem: Record Item; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var Item: Record Item; var xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLastDateTimeModified(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Item: Record Item; var xItem: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSNSpecificTrackingInteger(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateFieldsForNonInventoriableItem(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewItem(var Item: Record Item; var ItemName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Item: Record Item; var IsHandled: Boolean; xRecItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoItemLedgEntiesExist(var Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoOpenDocumentsWithTrackingExist(Item: Record Item; ItemTrackingCode2: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoOpenEntriesExist(Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoPurchLinesExist(Item: Record Item; CurrentFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoWhseEntriesExist(Item: Record Item; CurrentFieldName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyRoundingPrecisionForBaseUoM(var Item: Record Item; xItem: Record Item; var IsHandled: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBaseUnitOfMeasure(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseTransfer(var Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemVendOnAfterSetFilters(var ItemVend: Record "Item Vendor"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetItemNoOpenCardOnAfterSetItemFilters(var Item: Record Item; var ItemFilterContains: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBaseUnitOfMeasure(var ValidateBaseUnitOfMeasure: Boolean)
    begin
    end;

    procedure ExistsItemLedgerEntry(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if "No." = '' then
            exit;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetLoadFields("Item No.");
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", "No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    procedure ItemTrackingCodeUseExpirationDates(): Boolean
    begin
        if "Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.SetLoadFields("Use Expiration Dates");
        ItemTrackingCode.Get("Item Tracking Code");
        ItemTrackingCode.SetLoadFields();
        exit(ItemTrackingCode."Use Expiration Dates");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePhysInvtCountingPeriodCodeOnBeforeConfirmUpdate(var Item: Record Item; xItem: Record Item; PhysInvtCountPeriod: Record "Phys. Invt. Counting Period"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReplenishmentSystem(var Item: Record Item; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseAssemblyr(var Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetItemNoOpenCardWithViewOnBeforeShowCreateItemOption(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateProductionBOMNo(var Item: Record Item; xItem: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemCategoryCode(var Item: Record Item; xItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderTrackingPolicyOnBeforeUpdateReservation(var Item: Record Item; var ShouldRaiseRegenerativePlanningMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateProductionBOMNoOnAfterCodeunitRun(ProductionBOMHeader: Record "Production BOM Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchLine(Item: Record Item; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBOM(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdBOMLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPlanningCompLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobPlanningLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmHeader(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReqLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemJnlLine(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchLineOnAfterPurchLineSetFilters(Item: Record Item; var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVariantMandatory(ItemNo: Code[20]; var IsHandled: Boolean; var Result: Boolean);
    begin
    end;

#if not CLEAN24
    [Obsolete('Parameter NoSeriesMgt is obsolete and will be removed, update your subscriber accordingly.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var IsHandled: Boolean; var Item: Record Item; xItem: Record Item; InventorySetup: Record "Inventory Setup"; var NoSeriesMgt: Codeunit NoSeriesManagement)
    begin
    end;
#else
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var IsHandled: Boolean; var Item: Record Item; xItem: Record Item; InventorySetup: Record "Inventory Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnValidateProductionBOMNoOnAfterProcessStatusCertified(ProductionBOMHeader: Record "Production BOM Header"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemVend(var Item: Record Item; var ItemVendor: Record "Item Vendor"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforePlanningAssignmentItemChange(var Item: Record Item; xItem: Record Item; PlanningAssignment: Record "Planning Assignment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindItemVend(var ItemVendor: Record "Item Vendor"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnBeforeCheckExistsItemLedgerEntry(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStdCostWksh(var Item: Record Item; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemTrackingCodeOnBeforeTestNoEntriesExist(var Item: Record Item; xItem: Record Item; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}
