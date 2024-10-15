namespace Microsoft.Inventory.Journal;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Security.User;
using System.Utilities;

table 83 "Item Journal Line"
{
    Caption = 'Item Journal Line';
    DrillDownPageID = "Item Journal Lines";
    LookupPageID = "Item Journal Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderComp: Record "Prod. Order Component";
                PriceType: Enum "Price Type";
                ShouldCopyFromSingleProdOrderLine: Boolean;
                ShouldThrowRevaluationError: Boolean;
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Bin Code" := '';
                    if CurrFieldNo <> 0 then begin
                        GetItem();
                        if Item.IsInventoriableType() then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Item No."));
                    end;
                    if ("Location Code" <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    SetNewBinCodeForSameLocationTransfer();
                end;

                if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then begin
                    if "Item No." <> '' then
                        GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if "Item No." = '' then begin
                    CreateDimFromDefaultDim(Rec.FieldNo("Item No."));
                    OnValidateItemNoOnAfterCreateDimInitial(Rec);
                    exit;
                end;

                GetItem();
                OnValidateItemNoOnAfterGetItem(Rec, Item);
                DisplayErrorIfItemIsBlocked(Item);
                ValidateTypeWithItemNo();

                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    Item.TestField("Inventory Value Zero", false);
                OnValidateItemNoOnBeforeSetDescription(Rec, Item);
                Description := Item.Description;
                "Inventory Posting Group" := Item."Inventory Posting Group";
                "Item Category Code" := Item."Item Category Code";

                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    if "Item No." <> xRec."Item No." then begin
                        TestField("Partial Revaluation", false);
                        RetrieveCosts();
                        "Indirect Cost %" := 0;
                        "Overhead Rate" := 0;
                        "Inventory Value Per" := "Inventory Value Per"::" ";
                        Validate("Applies-to Entry", 0);
                        "Partial Revaluation" := false;
                    end;
                end else begin
                    OnValidateItemNoOnBeforeAssignIndirectCostPct(Rec, Item);
                    "Indirect Cost %" := Item."Indirect Cost %";
                    "Overhead Rate" := Item."Overhead Rate";
                    if not "Phys. Inventory" or (Item."Costing Method" = Item."Costing Method"::Standard) then begin
                        RetrieveCosts();
                        "Unit Cost" := UnitCost;
                    end else
                        UnitCost := "Unit Cost";
                end;
                OnValidateItemNoOnAfterCalcUnitCost(Rec, Item);

                if ("Item No." <> xRec."Item No.") and
                   ((("Entry Type" = "Entry Type"::Output) and (WorkCenter."No." = '') and (MachineCenter."No." = '')) or
                   ("Entry Type" <> "Entry Type"::Output)) or
                   ("Value Entry Type" = "Value Entry Type"::Revaluation)
                then
                    "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";

                case "Entry Type" of
                    "Entry Type"::Purchase,
                    "Entry Type"::Output,
                    "Entry Type"::"Assembly Output":
                        ApplyPrice(PriceType::Purchase, FieldNo("Item No."));
                    "Entry Type"::"Positive Adjmt.",
                    "Entry Type"::"Negative Adjmt.",
                    "Entry Type"::Consumption,
                    "Entry Type"::"Assembly Consumption":
                        "Unit Amount" := UnitCost;
                    "Entry Type"::Sale:
                        ApplyPrice(PriceType::Sale, FieldNo("Item No."));
                    "Entry Type"::Transfer:
                        begin
                            "Unit Amount" := 0;
                            "Unit Cost" := 0;
                            Amount := 0;
                        end;
                end;
                OnValidateItemNoOnAfterCalcUnitAmount(Rec, WorkCenter, MachineCenter);

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        "Unit of Measure Code" := Item."Purch. Unit of Measure";
                    "Entry Type"::Sale:
                        "Unit of Measure Code" := Item."Sales Unit of Measure";
                    "Entry Type"::Output:
                        begin
                            Item.TestField("Inventory Value Zero", false);
                            ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                            ProdOrderLine.SetRange("Item No.", "Item No.");
                            OnValidateItemNoOnAfterSetProdOrderLineItemNoFilter(Rec, xRec, ProdOrderLine);
                            if ProdOrderLine.FindFirst() then begin
                                "Routing No." := ProdOrderLine."Routing No.";
                                "Source Type" := "Source Type"::Item;
                                "Source No." := ProdOrderLine."Item No.";
                            end else begin
                                ShouldThrowRevaluationError := ("Value Entry Type" <> "Value Entry Type"::Revaluation) and (CurrFieldNo <> 0);
                                OnValidateItemNoOnAfterCalcShouldThrowRevaluationError(Rec, ShouldThrowRevaluationError);
                                if ShouldThrowRevaluationError then
                                    Error(Text031, "Item No.", "Order No.");
                            end;

                            ShouldCopyFromSingleProdOrderLine := ProdOrderLine.Count = 1;
                            OnValidateItemNoOnAfterCalcShouldCopyFromSingleProdOrderLine(Rec, xRec, ProdOrderLine, ShouldCopyFromSingleProdOrderLine);
                            if ShouldCopyFromSingleProdOrderLine then
                                CopyFromProdOrderLine(ProdOrderLine)
                            else
                                if "Order Line No." <> 0 then begin
                                    ProdOrderLine.SetRange("Line No.", "Order Line No.");
                                    if ProdOrderLine.FindFirst() then
                                        CopyFromProdOrderLine(ProdOrderLine)
                                    else
                                        "Unit of Measure Code" := Item."Base Unit of Measure";
                                end else
                                    "Unit of Measure Code" := Item."Base Unit of Measure";
                        end;
                    "Entry Type"::Consumption:
                        if FindProdOrderComponent(ProdOrderComp) then
                            CopyFromProdOrderComp(ProdOrderComp)
                        else begin
                            "Unit of Measure Code" := Item."Base Unit of Measure";
                            Validate("Prod. Order Comp. Line No.", 0);
                            OnValidateItemNoOnAfterValidateProdOrderCompLineNo(Rec, ProdOrderLine);
                        end;
                end;

                if "Unit of Measure Code" = '' then
                    "Unit of Measure Code" := Item."Base Unit of Measure";

                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    "Unit of Measure Code" := Item."Base Unit of Measure";
                OnValidateItemNoOnBeforeValidateUnitOfMeasureCode(Rec, Item, CurrFieldNo, xRec);
                Validate("Unit of Measure Code");
                if "Variant Code" <> '' then
                    Validate("Variant Code");

                OnAfterOnValidateItemNoAssignByEntryType(Rec, Item);

                CheckItemAvailable(FieldNo("Item No."));

                if ((not ("Order Type" in ["Order Type"::Production, "Order Type"::Assembly])) or ("Order No." = '')) and not "Phys. Inventory" then
                    CreateDimFromDefaultDim(Rec.FieldNo("Item No."));

                OnBeforeVerifyReservedQty(Rec, xRec, FieldNo("Item No."));
                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
            begin
                TestField("Posting Date");
                Validate("Document Date", "Posting Date");
                CheckDateConflict.ItemJnlLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';

            trigger OnValidate()
            begin
                if not ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Entry Type"));
                end;

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        if UserMgt.GetRespCenter(1, '') <> '' then
                            "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
                    "Entry Type"::Sale:
                        begin
                            if UserMgt.GetRespCenter(0, '') <> '' then
                                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
                            CheckItemAvailable(FieldNo("Entry Type"));
                        end;
                    "Entry Type"::Consumption, "Entry Type"::Output:
                        Validate("Order Type", "Order Type"::Production);
                    "Entry Type"::"Assembly Consumption", "Entry Type"::"Assembly Output":
                        Validate("Order Type", "Order Type"::Assembly);
                end;

                if xRec."Location Code" = '' then
                    if Location.Get("Location Code") then
                        if Location."Directed Put-away and Pick" then
                            "Location Code" := '';

                if "Item No." <> '' then
                    Validate("Location Code");

                Validate("Item No.");
                if "Entry Type" <> "Entry Type"::Transfer then begin
                    "New Location Code" := '';
                    "New Bin Code" := '';
                end;

                if "Entry Type" <> "Entry Type"::Output then
                    Type := Type::" ";

                SetDefaultPriceCalculationMethod();

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLocationCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger() then
                    TestField("Item No.");

                ValidateItemDirectCostUnitAmount();

                if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if "Location Code" <> xRec."Location Code" then begin
                    "Bin Code" := '';
                    if CurrFieldNo <> 0 then begin
                        GetItem();
                        if Item.IsInventoriableType() then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Location Code"));
                    end;
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        GetItem();
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
                    end;
                    if "Entry Type" = "Entry Type"::Transfer then begin
                        "New Location Code" := "Location Code";
                        "New Bin Code" := "Bin Code";
                    end;
                end;

                Validate("Unit of Measure Code");

                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(11; "Source Posting Group"; Code[20])
        {
            Caption = 'Source Posting Group';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Source Type" = const(Item)) "Inventory Posting Group";
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                CallWhseCheck: Boolean;
            begin
                if ("Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger()) and (Quantity <> 0) then
                    TestField("Item No.");

                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                CallWhseCheck :=
                  ("Entry Type" = "Entry Type"::"Assembly Consumption") or
                  ("Entry Type" = "Entry Type"::Consumption) or
                  ("Entry Type" = "Entry Type"::Output) and
                  LastOutputOperation(Rec);
                if CallWhseCheck then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption(Quantity));
                end;

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                if ("Entry Type" = "Entry Type"::Output) and
                   ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then
                    "Invoiced Quantity" := 0
                else
                    "Invoiced Quantity" := Quantity;
                "Invoiced Qty. (Base)" := CalcBaseQty("Invoiced Quantity", FieldCaption("Invoiced Quantity"), FieldCaption("Invoiced Qty. (Base)"));

                CheckSerialNoQty();

                OnValidateQuantityOnBeforeGetUnitAmount(Rec, xRec, CurrFieldNo);

                GetUnitAmount(FieldNo(Quantity));
                UpdateAmount();

                CheckItemAvailable(FieldNo(Quantity));

                if "Entry Type" = "Entry Type"::Transfer then begin
                    "Qty. (Calculated)" := 0;
                    "Qty. (Phys. Inventory)" := 0;
                    "Last Item Ledger Entry No." := 0;
                end;

                CheckReservedQtyBase();

                if Item."Item Tracking Code" <> '' then
                    ItemJnlLineReserve.VerifyQuantity(Rec, xRec);
            end;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';

            trigger OnValidate()
            begin
                UpdateAmount();
                if "Item No." <> '' then
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then
                        "Unit Cost" := "Unit Amount"
                    else
                        case "Entry Type" of
                            "Entry Type"::Purchase,
                            "Entry Type"::"Positive Adjmt.",
                            "Entry Type"::"Assembly Output":
                                begin
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then begin
                                        GetItem();
                                        if (CurrFieldNo = FieldNo("Unit Amount")) and
                                           (Item."Costing Method" = Item."Costing Method"::Standard)
                                        then
                                            Error(
                                              Text002,
                                              FieldCaption("Unit Amount"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                    end;

                                    ReadGLSetup();
                                    if "Entry Type" = "Entry Type"::Purchase then
                                        "Unit Cost" := "Unit Amount";
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then
                                        "Unit Cost" :=
                                          Round(
                                            "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                                          "Overhead Rate" * "Qty. per Unit of Measure";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                            "Entry Type"::"Negative Adjmt.",
                            "Entry Type"::Consumption,
                            "Entry Type"::"Assembly Consumption":
                                begin
                                    GetItem();
                                    if (CurrFieldNo = FieldNo("Unit Amount")) and
                                       (Item."Costing Method" = Item."Costing Method"::Standard)
                                    then
                                        Error(
                                          Text002,
                                          FieldCaption("Unit Amount"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                    "Unit Cost" := "Unit Amount";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                        end;
            end;
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                TestField("Item No.");
                RetrieveCosts();
                if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::Consumption] then
                    if Item."Costing Method" = Item."Costing Method"::Standard then begin
                        if CurrFieldNo = FieldNo("Unit Cost") then
                            Error(
                              Text002,
                              FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                        "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                    end;

                if ("Item Charge No." = '') and
                   ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   (CurrFieldNo = FieldNo("Unit Cost"))
                then begin
                    case "Entry Type" of
                        "Entry Type"::Purchase:
                            "Unit Amount" := "Unit Cost";
                        "Entry Type"::"Positive Adjmt.",
                        "Entry Type"::"Assembly Output":
                            begin
                                ReadGLSetup();
                                "Unit Amount" :=
                                  Round(
                                    ("Unit Cost" - "Overhead Rate" * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                                    GLSetup."Unit-Amount Rounding Precision")
                            end;
                        "Entry Type"::"Negative Adjmt.",
                        "Entry Type"::Consumption,
                        "Entry Type"::"Assembly Consumption":
                            begin
                                if Item."Costing Method" = Item."Costing Method"::Standard then
                                    Error(
                                      Text002,
                                      FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                                "Unit Amount" := "Unit Cost";
                            end;
                    end;
                    UpdateAmount();
                end;
            end;
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAmount(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Quantity);
                "Unit Amount" := Amount / Quantity;
                Validate("Unit Amount");
                ReadGLSetup();
                "Unit Amount" := Round("Unit Amount", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(22; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            Editable = false;
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
                    CreateDimFromDefaultDim(rec.FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(29; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-to Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                ShowTrackingExistsError: Boolean;
                IsHandled: Boolean;
                ShouldCheckItemLedgEntryFieldsForOutput: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToEntry(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to Entry" <> 0 then begin
                    ItemLedgEntry.Get("Applies-to Entry");

                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        if "Inventory Value Per" <> "Inventory Value Per"::" " then
                            Error(Text006, FieldCaption("Applies-to Entry"));

                        if "Inventory Value Per" = "Inventory Value Per"::" " then
                            if not RevaluationPerEntryAllowed("Item No.") then
                                Error(RevaluationPerEntryNotAllowedErr);

                        InitRevalJnlLine(ItemLedgEntry);
                        ItemLedgEntry.TestField(Positive, true);
                    end else begin
                        TestField(Quantity);
                        if Signed(Quantity) * ItemLedgEntry.Quantity > 0 then begin
                            if Quantity > 0 then
                                FieldError(Quantity, Text030);
                            if Quantity < 0 then
                                FieldError(Quantity, Text029);
                        end;
                        ShowTrackingExistsError := ItemLedgEntry.TrackingExists();
                        OnValidateAppliesToEntryOnAferCalcShowTrackingExistsError(Rec, xRec, ShowTrackingExistsError);
                        if ShowTrackingExistsError then
                            Error(Text033, FieldCaption("Applies-to Entry"), ItemTrackingLines.Caption);

                        if not ItemLedgEntry.Open then
                            Message(Text032, "Applies-to Entry");

                        ShouldCheckItemLedgEntryFieldsForOutput := "Entry Type" = "Entry Type"::Output;
                        OnValidateAppliestoEntryOnAfterCalcShouldCheckItemLedgEntryFieldsForOutput(Rec, ItemLedgEntry, ShouldCheckItemLedgEntryFieldsForOutput);
                        if ShouldCheckItemLedgEntryFieldsForOutput then begin
                            ItemLedgEntry.TestField("Order Type", "Order Type"::Production);
                            ItemLedgEntry.TestField("Order No.", "Order No.");
                            ItemLedgEntry.TestField("Order Line No.", "Order Line No.");
                            ItemLedgEntry.TestField("Entry Type", "Entry Type");
                        end;
                    end;

                    "Location Code" := ItemLedgEntry."Location Code";
                    "Variant Code" := ItemLedgEntry."Variant Code";
                end else
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        Validate("Unit Amount", 0);
                        Validate(Quantity, 0);
                        "Inventory Value (Calculated)" := 0;
                        "Inventory Value (Revalued)" := 0;
                        "Location Code" := '';
                        "Variant Code" := '';
                        "Bin Code" := '';
                    end;
            end;
        }
        field(32; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            Editable = false;
        }
        field(34; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(35; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(37; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Item No.");
                TestField("Value Entry Type", "Value Entry Type"::"Direct Cost");
                TestField("Item Charge No.", '');
                if "Entry Type" in ["Entry Type"::Sale, "Entry Type"::"Negative Adjmt."] then
                    Error(
                      Text002,
                      FieldCaption("Indirect Cost %"), FieldCaption("Entry Type"), "Entry Type");

                GetItem();
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    Error(
                      Text002,
                      FieldCaption("Indirect Cost %"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                if "Entry Type" <> "Entry Type"::Purchase then
                    "Unit Cost" :=
                      Round(
                        "Unit Amount" * (1 + "Indirect Cost %" / 100) +
                        "Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(39; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(41; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(43; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(44; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Expiration Date"));
            end;
        }
        field(45; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(46; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(50; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Location Code" <> xRec."New Location Code" then begin
                    "New Bin Code" := '';
                    if ("New Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("New Location Code");
                        GetItem();
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "New Location Code", "New Bin Code")
                    end;
                end;

                CreateNewDimFromDefaultDim(Rec.FieldNo("New Location Code"));

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(51; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,' + Text007;
            Caption = 'New Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
            end;
        }
        field(52; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,' + Text007;
            Caption = 'New Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");
            end;
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Qty. (Phys. Inventory)");
            end;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Phys. Inventory", true);

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Qty. (Phys. Inventory)"));
                end;

                "Qty. (Phys. Inventory)" := UOMMgt.RoundAndValidateQty("Qty. (Phys. Inventory)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. (Phys. Inventory)"));

                PhysInvtEntered := true;
                Quantity := 0;
                if "Qty. (Phys. Inventory)" >= "Qty. (Calculated)" then begin
                    Validate("Entry Type", "Entry Type"::"Positive Adjmt.");
                    Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                end else begin
                    Validate("Entry Type", "Entry Type"::"Negative Adjmt.");
                    Validate(Quantity, "Qty. (Calculated)" - "Qty. (Phys. Inventory)");
                end;
                PhysInvtEntered := false;
            end;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(62; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Journal Template Name"),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(83),
#pragma warning disable AL0603
                                                                  "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                  "Source Batch Name" = field("Journal Batch Name"),
                                                                  "Source Prod. Order Line" = const(0),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost (ACY)';
            Editable = false;
        }
        field(73; "Source Currency Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(86; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;

            trigger OnValidate()
            begin
                if "Order Type" = xRec."Order Type" then
                    exit;
                Validate("Order No.", '');
                "Order Line No." := 0;
            end;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = if ("Order Type" = const(Production)) "Production Order"."No." where(Status = const(Released));

            trigger OnValidate()
            var
                AssemblyHeader: Record "Assembly Header";
                ProdOrder: Record "Production Order";
                ProdOrderLine: Record "Prod. Order Line";
            begin
                case "Order Type" of
                    "Order Type"::Production,
                    "Order Type"::Assembly:
                        begin
                            if "Order No." = '' then begin
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                                exit;
                            end;

                            case "Order Type" of
                                "Order Type"::Production:
                                    begin
                                        GetMfgSetup();
                                        if MfgSetup."Doc. No. Is Prod. Order No." then
                                            "Document No." := "Order No.";
                                        ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
                                        ProdOrder.TestField(Blocked, false);
                                        Description := ProdOrder.Description;
                                        OnValidateOrderNoOrderTypeProduction(Rec, ProdOrder);
                                    end;
                                "Order Type"::Assembly:
                                    begin
                                        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
                                        Description := AssemblyHeader.Description;
                                        OnValidateOrderNoOnAfterProcessOrderTypeAssembly(Rec, ProdOrder, AssemblyHeader);
                                    end;
                            end;

                            "Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
                            case true of
                                "Entry Type" = "Entry Type"::Output:
                                    begin
                                        "Inventory Posting Group" := ProdOrder."Inventory Posting Group";
                                        "Gen. Prod. Posting Group" := ProdOrder."Gen. Prod. Posting Group";
                                    end;
                                "Entry Type" = "Entry Type"::"Assembly Output":
                                    begin
                                        "Inventory Posting Group" := AssemblyHeader."Inventory Posting Group";
                                        "Gen. Prod. Posting Group" := AssemblyHeader."Gen. Prod. Posting Group";
                                    end;
                                "Entry Type" = "Entry Type"::Consumption:
                                    begin
                                        ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                                        if ProdOrderLine.Count = 1 then begin
                                            ProdOrderLine.FindFirst();
                                            Validate("Order Line No.", ProdOrderLine."Line No.");
                                        end;
                                    end;
                            end;

                            if ("Order No." <> xRec."Order No.") or ("Order Type" <> xRec."Order Type") then
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                        end;
                    "Order Type"::Transfer, "Order Type"::Service, "Order Type"::" ":
                        Error(Text002, FieldCaption("Order No."), FieldCaption("Order Type"), "Order Type");
                    else
                        OnValidateOrderNoOnCaseOrderTypeElse(Rec);
                end;
            end;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                                                     "Prod. Order No." = field("Order No."));

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                TestField("Order No.");
                case "Order Type" of
                    "Order Type"::Production,
                    "Order Type"::Assembly:
                        begin
                            if "Order Type" = "Order Type"::Production then begin
                                ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                                ProdOrderLine.SetRange("Line No.", "Order Line No.");
                                OnValidateOrderLineNoOnAfterProdOrderLineSetFilters(Rec, ProdOrderLine);
                                if ProdOrderLine.FindFirst() then begin
                                    "Source Type" := "Source Type"::Item;
                                    "Source No." := ProdOrderLine."Item No.";
                                    "Order Line No." := ProdOrderLine."Line No.";
                                    "Routing No." := ProdOrderLine."Routing No.";
                                    "Routing Reference No." := ProdOrderLine."Routing Reference No.";
                                    if "Entry Type" = "Entry Type"::Output then begin
                                        "Location Code" := ProdOrderLine."Location Code";
                                        "Bin Code" := ProdOrderLine."Bin Code";
                                    end;
                                    OnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(Rec, ProdOrderLine);
                                end;
                            end;

                            if "Order Line No." <> xRec."Order Line No." then
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                        end;
                    else
                        OnValidateOrderLineNoOnCaseOrderTypeElse(Rec);
                end;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(481; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(904; "Assemble to Order"; Boolean)
        {
            Caption = 'Assemble to Order';
            Editable = false;
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Project No.';
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
        }
        field(1002; "Job Purchase"; Boolean)
        {
            Caption = 'Project Purchase';
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem();
                GetItemVariant();
                DisplayErrorIfItemVariantIsBlocked(ItemVariant);

                if ("Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output]) and Item.IsInventoriableType() then
                    WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);

                if "Variant Code" <> xRec."Variant Code" then begin
                    if "Entry Type" <> "Entry Type"::Output then
                        "Bin Code" := '';
                    if (CurrFieldNo <> 0) and Item.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Variant Code"));
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    SetNewBinCodeForSameLocationTransfer();
                end;
                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '')
                then begin
                    GetUnitAmount(FieldNo("Variant Code"));
                    "Unit Cost" := UnitCost;
                    Validate("Unit Amount");
                    Validate("Unit of Measure Code");
                    ItemJnlLineReserve.VerifyChange(Rec, xRec);
                end;

                if "Variant Code" <> '' then
                    Description := ItemVariant.Description
                else
                    Description := Item.Description;
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Entry Type" = filter(Purchase | "Positive Adjmt." | Output),
                                Quantity = filter(>= 0)) Bin.Code where("Location Code" = field("Location Code"),
                                                                      "Item Filter" = field("Item No."),
                                                                      "Variant Filter" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Purchase | "Positive Adjmt." | Output),
                                                                               Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                    "Item No." = field("Item No."),
                                                                                                                                    "Variant Code" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                             Quantity = filter(> 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                                                  "Item No." = field("Item No."),
                                                                                                                                                                                                  "Variant Code" = field("Variant Code"))
            else
            if ("Entry Type" = filter(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                                                                                           Quantity = filter(<= 0)) Bin.Code where("Location Code" = field("Location Code"),
                                                                                                                                                                                                                                                 "Item Filter" = field("Item No."),
                                                                                                                                                                                                                                                 "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                IsHandled: Boolean;
            begin
                if "Bin Code" <> xRec."Bin Code" then begin
                    TestField("Location Code");
                    if "Bin Code" <> '' then begin
                        GetItem();
                        Item.TestField(Type, Item.Type::Inventory);
                        GetBin("Location Code", "Bin Code");
                        GetLocation("Location Code");
                        IsHandled := false;
                        OnBinCodeOnBeforeTestBinMandatory(Rec, IsHandled);
                        if not IsHandled then
                            Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Bin Code"));
                        TestField("Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Item Journal Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", "Entry Type".AsInteger());
                    end;
                    SetNewBinCodeForSameLocationTransfer();

                    IsHandled := false;
                    OnBinCodeOnCheckProdOrderCompBinCodeCheckNeeded(Rec, IsHandled);
                    if not IsHandled then
                        if ("Entry Type" = "Entry Type"::Consumption) and
                        ("Bin Code" <> '') and ("Prod. Order Comp. Line No." <> 0)
                        then begin
                            TestField("Order Type", "Order Type"::Production);
                            TestField("Order No.");
                            CheckProdOrderCompBinCode();
                        end;
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5406; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("New Location Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Bin Code" <> xRec."New Bin Code" then begin
                    TestField("New Location Code");
                    if "New Bin Code" <> '' then begin
                        GetItem();
                        Item.TestField(Type, Item.Type::Inventory);
                        GetBin("New Location Code", "New Bin Code");
                        GetLocation("New Location Code");
                        Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("New Bin Code"));
                        TestField("New Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Item Journal Line", FieldCaption("New Bin Code"), "New Location Code", "New Bin Code", "Entry Type".AsInteger());
                    end;
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateUnitOfMeasureCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetItem();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                OnValidateUnitOfMeasureCodeOnBeforeWhseValidateSourceLine(Rec, xRec);
                if ("Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output]) and Item.IsInventoriableType() then
                    WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);

                if (CurrFieldNo <> 0) and Item.IsInventoriableType() then
                    WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Unit of Measure Code"));

                GetUnitAmount(FieldNo("Unit of Measure Code"));
                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    TestField("Qty. per Unit of Measure", 1);

                ReadGLSetup();
                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(Rec, UnitCost, IsHandled);
                if not IsHandled then
                    "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");

                if "Entry Type" = "Entry Type"::Consumption then begin
                    "Indirect Cost %" := Round(Item."Indirect Cost %" * "Qty. per Unit of Measure", 1);
                    "Overhead Rate" :=
                      Round(Item."Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                    "Unit Amount" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                end;

                if "No." <> '' then
                    Validate("Cap. Unit of Measure Code");

                Validate("Unit Amount");

                if "Entry Type" = "Entry Type"::Output then begin
                    Validate("Output Quantity");
                    Validate("Scrap Quantity");
                end else
                    Validate(Quantity);

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            Editable = false;
        }
        field(5410; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5411; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5415; "Invoiced Qty. (Base)"; Decimal)
        {
            Caption = 'Invoiced Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Journal Template Name"),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(83),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                           "Source Batch Name" = field("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5560; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5561; "Flushing Method"; Enum "Flushing Method")
        {
            Caption = 'Flushing Method';
            Editable = false;
        }
        field(5562; "Changed by User"; Boolean)
        {
            Caption = 'Changed by User';
            Editable = false;
        }
        field(5700; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
            ObsoleteReason = 'Cross-Reference replaced by Item Reference feature.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered No.';
            TableRelation = Item;
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered Var. Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Originally Ordered No."));
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5707; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                ItemReferenceManagement.ItemJournalReferenceNoLookup(Rec);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                ItemReferenceManagement.ValidateItemJournalReferenceNo(Rec, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5791; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
        }
        field(5793; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(5800; "Value Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Value Entry Type';
        }
        field(5801; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            TableRelation = "Item Charge";
        }
        field(5802; "Inventory Value (Calculated)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Calculated)';
            Editable = false;

            trigger OnValidate()
            begin
                ReadGLSetup();
                "Unit Cost (Calculated)" :=
                  Round("Inventory Value (Calculated)" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(5803; "Inventory Value (Revalued)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Revalued)';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                Validate(Amount, "Inventory Value (Revalued)" - "Inventory Value (Calculated)");
                ReadGLSetup();
                if ("Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)") or
                   ("Inventory Value (Revalued)" <> xRec."Inventory Value (Revalued)")
                then begin
                    if CurrFieldNo <> FieldNo("Unit Cost (Revalued)") then
                        "Unit Cost (Revalued)" :=
                          Round("Inventory Value (Revalued)" / Quantity, GLSetup."Unit-Amount Rounding Precision");

                    if CurrFieldNo <> 0 then
                        ClearSingleAndRolledUpCosts();
                end
            end;
        }
        field(5804; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
        }
        field(5805; "Inventory Value Per"; Option)
        {
            Caption = 'Inventory Value Per';
            Editable = false;
            OptionCaption = ' ,Item,Location,Variant,Location and Variant';
            OptionMembers = " ",Item,Location,Variant,"Location and Variant";
        }
        field(5806; "Partial Revaluation"; Boolean)
        {
            Caption = 'Partial Revaluation';
            Editable = false;
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                IsHandled: Boolean;
            begin
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Signed(Quantity) < 0 then begin
                        if Quantity > 0 then
                            FieldError(Quantity, Text030);
                        if Quantity < 0 then
                            FieldError(Quantity, Text029);
                    end;
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);

                    OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(Rec, ItemLedgEntry, IsHandled);
                    if not IsHandled then
                        if ItemLedgEntry.TrackingExists() then
                            Error(Text033, FieldCaption("Applies-from Entry"), ItemTrackingLines.Caption);
                    "Unit Cost" := CalcUnitCost(ItemLedgEntry);
                end;
            end;
        }
        field(5808; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(5809; "Unit Cost (Calculated)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Calculated)';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
            end;
        }
        field(5810; "Unit Cost (Revalued)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Revalued)';
            MinValue = 0;

            trigger OnValidate()
            begin
                ReadGLSetup();
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                if "Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)" then
                    Validate(
                      "Inventory Value (Revalued)",
                      Round(
                        "Unit Cost (Revalued)" * Quantity, GLSetup."Amount Rounding Precision"));
            end;
        }
        field(5811; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            Editable = false;
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
            Caption = 'Update Standard Cost';

            trigger OnValidate()
            begin
                TestField("Inventory Value Per");
                GetItem();
                Item.TestField("Costing Method", Item."Costing Method"::Standard);
            end;
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(5818; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
        }
        field(5819; "Applies-to Value Entry"; Integer)
        {
            Caption = 'Applies-to Value Entry';
        }
        field(5820; "Invoice-to Source No."; Code[20])
        {
            Caption = 'Invoice-to Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor;
        }
        field(5830; Type; Enum "Capacity Type Journal")
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type = Type::Resource then
                    TestField("Entry Type", "Entry Type"::"Assembly Output")
                else
                    TestField("Entry Type", "Entry Type"::Output);
                Validate("No.", '');
            end;
        }
        field(5831; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center"
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if Type = Type::Resource then
                    TestField("Entry Type", "Entry Type"::"Assembly Output")
                else
                    TestField("Entry Type", "Entry Type"::Output);
                if "No." = '' then begin
                    "Work Center No." := '';
                    "Work Center Group Code" := '';
                    Validate("Item No.");
                    if Type in [Type::"Work Center", Type::"Machine Center"] then
                        CreateDimWithProdOrderLine()
                    else
                        CreateDimFromDefaultDim(Rec.FieldNo("Work Center No."));
                    exit;
                end;

                case Type of
                    Type::"Work Center":
                        begin
                            WorkCenter.Get("No.");
                            WorkCenter.TestField(Blocked, false);
                            CopyFromWorkCenter(WorkCenter);
                        end;
                    Type::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField(Blocked, false);
                            WorkCenter.Get(MachineCenter."Work Center No.");
                            WorkCenter.TestField(Blocked, false);
                            CopyFromMachineCenter(MachineCenter);
                        end;
                    Type::Resource:
                        begin
                            Resource.Get("No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;

                if Type in [Type::"Work Center", Type::"Machine Center"] then begin
                    "Work Center No." := WorkCenter."No.";
                    "Work Center Group Code" := WorkCenter."Work Center Group Code";
                    ErrorIfSubcontractingWorkCenterUsed();
                    Validate("Cap. Unit of Measure Code", WorkCenter."Unit of Measure Code");
                end;

                if "Work Center No." <> '' then
                    CreateDimWithProdOrderLine();
            end;
        }
        field(5838; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                                                                  "Prod. Order No." = field("Order No."),
                                                                                                                  "Routing No." = field("Routing No."),
                                                                                                                  "Routing Reference No." = field("Routing Reference No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Operation No." = '' then
                    exit;

                TestField("Order Type", "Order Type"::Production);
                TestField("Order No.");
                TestField("Item No.");

                CheckConfirmOutputOnFinishedOperation();
                GetProdOrderRoutingLine(ProdOrderRtngLine);

                case ProdOrderRtngLine.Type of
                    ProdOrderRtngLine.Type::"Work Center":
                        Type := Type::"Work Center";
                    ProdOrderRtngLine.Type::"Machine Center":
                        Type := Type::"Machine Center";
                end;
                Validate("No.", ProdOrderRtngLine."No.");
                Description := ProdOrderRtngLine.Description;
            end;
        }
        field(5839; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                ErrorIfSubcontractingWorkCenterUsed();
            end;
        }
        field(5841; "Setup Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Setup Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Setup Time"), "Line No.");
                "Setup Time (Base)" := CalcBaseTime("Setup Time");
            end;
        }
        field(5842; "Run Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Run Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Run Time"), "Line No.");

                "Run Time (Base)" := CalcBaseTime("Run Time");
            end;
        }
        field(5843; "Stop Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Stop Time';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Stop Time (Base)" := CalcBaseTime("Stop Time");
            end;
        }
        field(5846; "Output Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Output Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if SubcontractingWorkCenterUsed() and ("Output Quantity" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Output Quantity"), "Line No.");

                CheckConfirmOutputOnFinishedOperation();

                if LastOutputOperation(Rec) then begin
                    GetItem();
                    if Item.IsInventoriableType() then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                end;

                "Output Quantity (Base)" := CalcBaseQty("Output Quantity", FieldCaption("Output Quantity"), FieldCaption("Output Quantity (Base)"));

                Validate(Quantity, "Output Quantity");
                ValidateQuantityIsBalanced();
            end;
        }
        field(5847; "Scrap Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Scrap Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Output);
                "Scrap Quantity (Base)" := CalcBaseQty("Scrap Quantity", FieldCaption("Scrap Quantity"), FieldCaption("Scrap Quantity (Base)"));
            end;
        }
        field(5849; "Concurrent Capacity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Concurrent Capacity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                TotalTime: Integer;
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Concurrent Capacity" = 0 then
                    exit;

                TestField("Starting Time");
                TestField("Ending Time");
                TotalTime := CalendarMgt.CalcTimeDelta("Ending Time", "Starting Time");
                OnvalidateConcurrentCapacityOnAfterCalcTotalTime(Rec, TotalTime, xRec);
                if "Ending Time" < "Starting Time" then
                    TotalTime := TotalTime + 86400000;
                TestField("Work Center No.");
                WorkCenter.Get("Work Center No.");
                Validate("Setup Time", 0);
                Validate(
                  "Run Time",
                  Round(
                    TotalTime / CalendarMgt.TimeFactor("Cap. Unit of Measure Code") *
                    "Concurrent Capacity", WorkCenter."Calendar Rounding Precision"));
            end;
        }
        field(5851; "Setup Time (Base)"; Decimal)
        {
            Caption = 'Setup Time (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Setup Time", "Setup Time (Base)");
            end;
        }
        field(5852; "Run Time (Base)"; Decimal)
        {
            Caption = 'Run Time (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Run Time", "Run Time (Base)");
            end;
        }
        field(5853; "Stop Time (Base)"; Decimal)
        {
            Caption = 'Stop Time (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Stop Time", "Stop Time (Base)");
            end;
        }
        field(5856; "Output Quantity (Base)"; Decimal)
        {
            Caption = 'Output Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateOutputQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Output Quantity", "Output Quantity (Base)");
            end;
        }
        field(5857; "Scrap Quantity (Base)"; Decimal)
        {
            Caption = 'Scrap Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateScrapQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Scrap Quantity", "Scrap Quantity (Base)");
            end;
        }
        field(5858; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
            TableRelation = if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Capacity Unit of Measure";

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
                IsHandled: Boolean;
            begin
                if Type <> Type::Resource then begin
                    "Qty. per Cap. Unit of Measure" :=
                      Round(
                        CalendarMgt.QtyperTimeUnitofMeasure(
                          "Work Center No.", "Cap. Unit of Measure Code"),
                        UOMMgt.QtyRndPrecision());

                    Validate("Setup Time");
                    Validate("Run Time");
                    Validate("Stop Time");
                end;

                if "Order No." <> '' then
                    case "Order Type" of
                        "Order Type"::Production:
                            begin
                                GetProdOrderRoutingLine(ProdOrderRtngLine);
                                "Unit Cost" := ProdOrderRtngLine."Unit Cost per";
                                OnValidateCapUnitofMeasureCodeOnBeforeRoutingCostPerUnit(Rec, ProdOrderRtngLine, IsHandled);
                                if not IsHandled then
                                    CostCalcMgt.CalcRoutingCostPerUnit(
                                      Type, "No.", "Unit Amount", "Indirect Cost %", "Overhead Rate", "Unit Cost", "Unit Cost Calculation");
                            end;
                        "Order Type"::Assembly:
                            CostCalcMgt.ResourceCostPerUnit("No.", "Unit Amount", "Indirect Cost %", "Overhead Rate", "Unit Cost");
                        else
                            OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(Rec);
                    end;

                ReadGLSetup();
                "Unit Cost" :=
                  Round("Unit Cost" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                "Unit Amount" :=
                  Round("Unit Amount" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                Validate("Unit Amount");
            end;
        }
        field(5859; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Cap. Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(5873; "Starting Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    "Ending Time" := "Starting Time";

                Validate("Concurrent Capacity");
            end;
        }
        field(5874; "Ending Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                Validate("Concurrent Capacity");
            end;
        }
        field(5882; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(5883; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(5884; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                                                          "Prod. Order No." = field("Order No."),
                                                                                                          "Prod. Order Line No." = field("Order Line No."));

            trigger OnValidate()
            var
                ProdOrderComponent: Record "Prod. Order Component";
            begin
                if "Prod. Order Comp. Line No." <> xRec."Prod. Order Comp. Line No." then begin
                    if ("Order Type" = "Order Type"::Production) and ("Prod. Order Comp. Line No." <> 0) then begin
                        ProdOrderComponent.Get(
                          ProdOrderComponent.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
                        if "Item No." <> ProdOrderComponent."Item No." then
                            Validate("Item No.", ProdOrderComponent."Item No.");
                    end;

                    CreateProdDim();
                end;
            end;
        }
        field(5885; Finished; Boolean)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Finished';
        }
        field(5887; "Unit Cost Calculation"; Enum "Unit Cost Calculation Type")
        {
            Caption = 'Unit Cost Calculation';
        }
        field(5888; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
        }
        field(5895; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
            TableRelation = Stop;
        }
        field(5896; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            TableRelation = Scrap;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateScrapCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if not (Type in [Type::"Work Center", Type::"Machine Center"]) then
                    Error(ScrapCodeTypeErr);
            end;
        }
        field(5898; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(5899; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            TableRelation = "Work Shift";
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Serial No."));
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Lot No."));
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Warranty Date"));
            end;
        }
        field(6503; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            Editable = false;
        }
        field(6504; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            Editable = false;
        }
        field(6505; "New Item Expiration Date"; Date)
        {
            Caption = 'New Item Expiration Date';
        }
        field(6506; "Item Expiration Date"; Date)
        {
            Caption = 'Item Expiration Date';
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Package No."));
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
        field(6600; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7315; "Warehouse Adjustment"; Boolean)
        {
            Caption = 'Warehouse Adjustment';
        }
        field(7316; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
            DataClassification = SystemMetadata;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    "Overhead Rate" := 0;
                    Validate("Indirect Cost %", 0);
                end else
                    Validate("Indirect Cost %");
            end;
        }
        field(99000756; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Material Cost';
        }
        field(99000757; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Capacity Cost';
        }
        field(99000758; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Subcontrd. Cost';
        }
        field(99000759; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Cap. Ovhd Cost';
        }
        field(99000760; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Mfg. Ovhd Cost';
        }
        field(99000761; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Material Cost';
        }
        field(99000762; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Capacity Cost';
        }
        field(99000763; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Subcontracted Cost';
        }
        field(99000764; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
        }
        field(99000765; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Cap. Overhead Cost';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry Type", "Item No.", "Variant Code", "Location Code", "Bin Code", "Posting Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key3; "Entry Type", "Item No.", "Variant Code", "New Location Code", "New Bin Code", "Posting Date")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key4; "Item No.", "Posting Date")
        {
        }
        key(Key5; "Journal Template Name", "Journal Batch Name", "Item No.", "Location Code", "Variant Code")
        {
        }
        key(Key6; "Journal Template Name", "Journal Batch Name", "Document No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Item No.", Description, Quantity, "Document No.", "Document Date")
        { }
    }

    trigger OnDelete()
    begin
        ItemJnlLineReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        LockTable();
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
        ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
        ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");

        CheckPlanningAssignment();
    end;

    trigger OnModify()
    begin
        OnBeforeVerifyReservedQty(Rec, xRec, 0);
        ItemJnlLineReserve.VerifyChange(Rec, xRec);
        CheckPlanningAssignment();
    end;

    trigger OnRename()
    begin
        ItemJnlLineReserve.RenameLine(Rec, xRec);
    end;

    var
        Text001: Label '%1 must be reduced.';
        Text002: Label 'You cannot change %1 when %2 is %3.';
        Text006: Label 'You must not enter %1 in a revaluation sum line.';
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        GLSetup: Record "General Ledger Setup";
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        Location: Record Location;
        Bin: Record Bin;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        UserMgt: Codeunit "User Setup Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        WMSManagement: Codeunit "WMS Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ItemReferenceManagement: Codeunit "Item Reference Management";
        GLSetupRead: Boolean;
        MfgSetupRead: Boolean;
        Text007: Label 'New ';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        Text021: Label 'The entered bin code %1 is different from the bin code %2 in production order component %3.\\Are you sure that you want to post the consumption from bin code %1?';
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
        Text031: Label 'You can not insert item number %1 because it is not produced on released production order %2.';
        Text032: Label 'When posting, the entry %1 will be opened first.';
        Text033: Label 'If the item carries serial or lot numbers, then you must use the %1 field in the %2 window.';
        RevaluationPerEntryNotAllowedErr: Label 'This item has already been revalued with the Calculate Inventory Value function, so you cannot use the Applies-to Entry field as that may change the valuation.';
        SubcontractedErr: Label '%1 must be zero in line number %2 because it is linked to the subcontracted work center.', Comment = '%1 - Field Caption, %2 - Line No.';
        FinishedOutputQst: Label 'The operation has been finished. Do you want to post output for the finished operation?';
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        SalesBlockedErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        PurchasingBlockedErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ServiceSalesBlockedErr: Label 'You cannot sell %1 %2 via service because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ItemVariantPrimaryKeyLbl: Label '%1, %2', Comment = '%1 - Item No., %2 - Variant Code', Locked = true;
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        RenumberDocNoQst: Label 'If you have many documents it can take time to sort them, and %1 might perform slowly during the process. In those cases we suggest that you sort them during non-working hours. Do you want to continue?', Comment = '%1= Business Central';
        ScrapCodeTypeErr: Label 'When using Scrap Code, Type must be Work Center or Machine Center.';
        IncorrectQtyForSNErr: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        ItemTrackingExistsErr: Label 'You cannot change %1 because item tracking already exists for this journal line.', Comment = '%1 - Serial or Lot No.';

    protected var
        ItemJnlLine: Record "Item Journal Line";
        PhysInvtEntered: Boolean;
        UnitCost: Decimal;

    procedure EmptyLine(): Boolean
    begin
        exit(
          (Quantity = 0) and
          ((TimeIsEmpty() and ("Item No." = '')) or
           ("Value Entry Type" = "Value Entry Type"::Revaluation)));
    end;

    procedure IsValueEntryForDeletedItem(): Boolean
    begin
        exit(
          (("Entry Type" = "Entry Type"::Output) or ("Value Entry Type" = "Value Entry Type"::Rounding)) and
          ("Item No." = '') and ("Item Charge No." = '') and ("Invoiced Qty. (Base)" <> 0));
    end;

    internal procedure CalcReservedQuantity()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if IsSourceSales() then begin
            SetReservEntrySourceFilters(ReservationEntry, false);
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
            ReservationEntry.CalcSums("Quantity (Base)");
            "Reserved Qty. (Base)" := ReservationEntry."Quantity (Base)"
        end else
            CalcFields("Reserved Qty. (Base)");
    end;

    local procedure CalcBaseTime(Qty: Decimal): Decimal
    begin
        if "Run Time" <> 0 then
            TestField("Qty. per Cap. Unit of Measure");
        exit(Round(Qty * "Qty. per Cap. Unit of Measure", UOMMgt.TimeRndPrecision()));
    end;

    procedure UpdateAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        Amount := Round(Quantity * "Unit Amount");

        OnAfterUpdateAmount(Rec);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJnlLine2: Record "Item Journal Line";
        PositiveFilterValue: Boolean;
    begin
        OnBeforeSelectItemEntry(Rec, xRec, CurrentFieldNo);

        if ("Entry Type" = "Entry Type"::Output) and
           ("Value Entry Type" <> "Value Entry Type"::Revaluation) and
           (CurrentFieldNo = FieldNo("Applies-to Entry"))
        then begin
            ItemLedgEntry.SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgEntry.SetRange("Order Type", "Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Order Line No.");
            ItemLedgEntry.SetRange("Entry Type", "Entry Type");
            ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange("Item No.", "Item No.");
        end;

        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            if Quantity <> 0 then begin
                PositiveFilterValue := (Signed(Quantity) < 0) or ("Value Entry Type" = "Value Entry Type"::Revaluation);
                ItemLedgEntry.SetRange(Positive, PositiveFilterValue);
            end;

            if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open);
                ItemLedgEntry.SetRange(Open, true);
            end;
        end else
            ItemLedgEntry.SetRange(Positive, false);

        OnSelectItemEntryOnBeforeOpenPage(ItemLedgEntry, Rec, CurrentFieldNo);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ItemJnlLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                ItemJnlLine2.Validate("Applies-to Entry", ItemLedgEntry."Entry No.")
            else
                ItemJnlLine2.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := ItemJnlLine2;
        end;

        OnAfterSelectItemEntry(Rec);
    end;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo = 0) or (CurrFieldNo <> CalledByFieldNo) then // Prevent two checks on quantity
            exit;

        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and ("Item No." <> '') and (Quantity <> 0) and
           ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')
        then
            if ItemCheckAvail.ItemJnlCheckLine(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckProdOrderCompBinCode()
    var
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderCompBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComp.Get(ProdOrderComp.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
        if (ProdOrderComp."Bin Code" <> '') and (ProdOrderComp."Bin Code" <> "Bin Code") then
            if not Confirm(
                 Text021,
                 false,
                 "Bin Code",
                 ProdOrderComp."Bin Code",
                 "Order No.")
            then
                Error(UpdateInterruptedErr);
    end;

    local procedure CheckReservedQtyBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        if Abs("Quantity (Base)") < Abs("Reserved Qty. (Base)") then
            Error(Text001, FieldCaption("Reserved Qty. (Base)"));
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");

        OnAfterGetItemChange(Item, Rec);
    end;

    local procedure GetItemVariant()
    begin
        if Rec."Variant Code" = '' then begin
            Clear(ItemVariant);
            exit;
        end;

        if (ItemVariant."Item No." <> Rec."Item No.") or (ItemVariant.Code <> Rec."Variant Code") then
            ItemVariant.Get(Rec."Item No.", Rec."Variant Code");

        OnAfterGetItemVariantChange(ItemVariant, Rec);
    end;

    procedure SetUpNewLine(LastItemJnlLine: Record "Item Journal Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        MfgSetup.Get();
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ItemJnlLine.FindFirst() then begin
            OnSetUpNewLineOnAfterFindItemJnlLine(Rec, ItemJnlLine, LastItemJnlLine);
            "Posting Date" := LastItemJnlLine."Posting Date";
            "Document Date" := LastItemJnlLine."Posting Date";
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output])
            then begin
                if not MfgSetup."Doc. No. Is Prod. Order No." then
                    "Document No." := LastItemJnlLine."Document No."
            end else
                "Document No." := LastItemJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if ItemJnlBatch."No. Series" <> '' then
                "Document No." := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output]) and
               not MfgSetup."Doc. No. Is Prod. Order No."
            then
                if ItemJnlBatch."No. Series" <> '' then
                    "Document No." := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
        end;
        "Recurring Method" := LastItemJnlLine."Recurring Method";
        "Entry Type" := LastItemJnlLine."Entry Type";
        "Source Code" := ItemJnlTemplate."Source Code";
        "Reason Code" := ItemJnlBatch."Reason Code";
        "Posting No. Series" := ItemJnlBatch."Posting No. Series";
        if ItemJnlTemplate.Type = ItemJnlTemplate.Type::Revaluation then begin
            "Value Entry Type" := "Value Entry Type"::Revaluation;
            "Entry Type" := "Entry Type"::"Positive Adjmt.";
        end;

        OnSetUpNewLineOnBeforeSetDefaultPriceCalculationMethod(Rec, ItemJnlBatch, DimMgt);
        SetDefaultPriceCalculationMethod();

        case "Entry Type" of
            "Entry Type"::Purchase:
                "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
            "Entry Type"::Sale:
                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
            "Entry Type"::Output:
                Clear(DimMgt);
        end;

        if Location.Get("Location Code") then
            if Location."Directed Put-away and Pick" then
                "Location Code" := '';

        OnAfterSetupNewLine(Rec, LastItemJnlLine, ItemJnlTemplate, ItemJnlBatch);
    end;

    local procedure SetDefaultPriceCalculationMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Entry Type" of
            "Entry Type"::Purchase,
            "Entry Type"::Output,
            "Entry Type"::"Assembly Output":
                begin
                    PurchasesPayablesSetup.Get();
                    "Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method";
                end;
            "Entry Type"::Sale:
                begin
                    SalesReceivablesSetup.Get();
                    "Price Calculation Method" := SalesReceivablesSetup."Price Calculation Method";
                end;
            else
                "Price Calculation Method" := "Price Calculation Method"::" ";
        end;
    end;

    procedure SetDocNos(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20];
                                     ExtDocNo: Text[35];
                                     PostingNos: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Posting No. Series" := PostingNos;
    end;

    local procedure SetNewBinCodeForSameLocationTransfer()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNewBinCodeForSameLocationTransfer(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
            "New Bin Code" := "Bin Code";
    end;

    procedure GetUnitAmount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        UnitCostValue: Decimal;
        IsHandled: Boolean;
    begin
        RetrieveCosts();
        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        OnBeforeGetUnitAmount(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        UnitCostValue := UnitCost;
        if (CalledByFieldNo = FieldNo(Quantity)) and
           (Item."No." <> '') and (Item."Costing Method" <> Item."Costing Method"::Standard)
        then
            UnitCostValue := "Unit Cost" / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");

        case "Entry Type" of
            "Entry Type"::Purchase:
                ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            "Entry Type"::Sale:
                ApplyPrice(PriceType::Sale, CalledByFieldNo);
            "Entry Type"::"Positive Adjmt.":
                "Unit Amount" :=
                  Round(
                    ((UnitCostValue - "Overhead Rate") * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Negative Adjmt.":
                "Unit Amount" := UnitCostValue * "Qty. per Unit of Measure";
            "Entry Type"::Transfer:
                "Unit Amount" := 0;
        end;

        OnAfterGetUnitAmount(Rec, UnitCost);
    end;

    procedure ApplyPrice(PriceType: Enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
    begin
        LineWithPrice := ItemJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    procedure Signed(Value: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSigned(Rec, Value, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case "Entry Type" of
            "Entry Type"::Purchase,
          "Entry Type"::"Positive Adjmt.",
          "Entry Type"::Output,
          "Entry Type"::"Assembly Output":
                Result := Value;
            "Entry Type"::Sale,
          "Entry Type"::"Negative Adjmt.",
          "Entry Type"::Consumption,
          "Entry Type"::Transfer,
          "Entry Type"::"Assembly Consumption":
                Result := -Value;
        end;
        OnAfterSigned(Rec, Value, Result);
    end;

    procedure IsInbound(): Boolean
    begin
        exit((Signed(Quantity) > 0) or (Signed("Invoiced Quantity") > 0));
    end;

    procedure OpenItemTrackingLines(IsReclass: Boolean)
    begin
        ItemJnlLineReserve.CallItemTracking(Rec, IsReclass);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        CreateDim(DefaultDimSource, 0, 0);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        SourceCode: Code[10];
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo, DefaultDimSource, InheritFromDimSetID, InheritFromTableNo);
        if IsHandled then
            exit;

        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCode,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", InheritFromDimSetID, InheritFromTableNo);
        OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource, InheritFromDimSetID, InheritFromTableNo);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if "Entry Type" = "Entry Type"::Transfer then begin
            "New Dimension Set ID" := "Dimension Set ID";
            "New Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            "New Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
        end;
    end;

    procedure CopyDim(DimesionSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDim(Rec, DimesionSetID, IsHandled);
        if IsHandled then
            exit;

        ReadGLSetup();
        "Dimension Set ID" := DimesionSetID;
        DimSetEntry.SetRange("Dimension Set ID", DimesionSetID);
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 1 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 1 Code" := '';
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 2 Code" := '';
    end;

    procedure CreateProdDim()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateProdDim(Rec, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
            exit;
        ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
        i := 1;
        DimSetIDArr[i] := ProdOrder."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.");
            DimSetIDArr[i] := ProdOrderLine."Dimension Set ID";
        end;

        IsHandled := false;
        OnCreateProdDimOnBeforeCreateDimSetIDArr(Rec, DimSetIDArr, IsHandled);
        if not IsHandled then
            if "Prod. Order Comp. Line No." <> 0 then begin
                i := i + 1;
                ProdOrderComp.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
                DimSetIDArr[i] := ProdOrderComp."Dimension Set ID";
            end;

        OnCreateProdDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure CreateAssemblyDim()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Assembly) or ("Order No." = '') then
            exit;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
        i := 1;
        DimSetIDArr[i] := AssemblyHeader."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            AssemblyLine.Get(AssemblyLine."Document Type"::Order, "Order No.", "Order Line No.");
            DimSetIDArr[i] := AssemblyLine."Dimension Set ID";
        end;

        OnCreateAssemblyDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateAssemblyDim(Rec, AssemblyHeader);
    end;

    local procedure CreateDimWithProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        InheritFromDimSetID: Integer;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if "Order Type" = "Order Type"::Production then
            if ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.") then
                InheritFromDimSetID := ProdOrderLine."Dimension Set ID";

        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", Rec."Work Center No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code");
        OnCreateDimWithProdOrderLineOnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, Rec.FieldNo("No."));
        CreateDim(DefaultDimSource, InheritFromDimSetID, Database::Item);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure ValidateItemDirectCostUnitAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemDirectCostUnitAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
           ("Item Charge No." = '') and
           ("No." = '')
        then begin
            GetUnitAmount(FieldNo("Location Code"));
            "Unit Cost" := UnitCost;
            Validate("Unit Amount");
            CheckItemAvailable(FieldNo("Location Code"));
        end;
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Output Quantity", "Output Quantity (Base)", 0, 0);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ValidateNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    procedure LookupNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, NewShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    procedure ShowNewShortcutDimCode(var NewShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("New Dimension Set ID", NewShortcutDimCode);
    end;

    local procedure InitRevalJnlLine(ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        CostAmtActual: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRevalJnlLine(Rec, ItemLedgEntry2, IsHandled);
        if IsHandled then
            exit;

        if "Value Entry Type" <> "Value Entry Type"::Revaluation then
            exit;

        ItemLedgEntry2.TestField("Item No.", "Item No.");
        ItemLedgEntry2.TestField("Completely Invoiced", true);
        ItemLedgEntry2.TestField(Positive, true);
        ItemApplnEntry.CheckAppliedFromEntryToAdjust(ItemLedgEntry2."Entry No.");

        Validate("Entry Type", ItemLedgEntry2."Entry Type");
        "Posting Date" := ItemLedgEntry2."Posting Date";
        Validate("Unit Amount", 0);
        Validate(Quantity, ItemLedgEntry2."Invoiced Quantity");

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Rounding);
        ValueEntry.Find('-');
        repeat
            if not (ValueEntry."Expected Cost" or ValueEntry."Partial Revaluation") then
                CostAmtActual := CostAmtActual + ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;

        Validate("Inventory Value (Calculated)", CostAmtActual);
        Validate("Inventory Value (Revalued)", CostAmtActual);

        "Location Code" := ItemLedgEntry2."Location Code";
        "Variant Code" := ItemLedgEntry2."Variant Code";
        "Applies-to Entry" := ItemLedgEntry2."Entry No.";
        CopyDim(ItemLedgEntry2."Dimension Set ID");

        OnAfterInitRevalJnlLine(Rec, ItemLedgEntry2);
    end;

    procedure CopyDocumentFields(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Posting Date" := SalesHeader."Posting Date";
        "Document Date" := SalesHeader."Document Date";
        "VAT Reporting Date" := SalesHeader."VAT Reporting Date";
        "Order Date" := SalesHeader."Order Date";
        "Source Posting Group" := SalesHeader."Customer Posting Group";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "Reason Code" := SalesHeader."Reason Code";
        "Source Currency Code" := SalesHeader."Currency Code";
        "Shpt. Method Code" := SalesHeader."Shipment Method Code";
        "Price Calculation Method" := SalesHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromSalesHeader(Rec, SalesHeader);
    end;

    procedure CopyFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Item No." := SalesLine."No.";
        Description := SalesLine.Description;
        "Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Location Code" := SalesLine."Location Code";
        "Bin Code" := SalesLine."Bin Code";
        "Variant Code" := SalesLine."Variant Code";
        "Inventory Posting Group" := SalesLine."Posting Group";
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "Transaction Type" := SalesLine."Transaction Type";
        "Transport Method" := SalesLine."Transport Method";
        "Entry/Exit Point" := SalesLine."Exit Point";
        Area := SalesLine.Area;
        "Transaction Specification" := SalesLine."Transaction Specification";
        "Drop Shipment" := SalesLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Sale;
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := SalesLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := SalesLine."Qty. Rounding Precision (Base)";
        "Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        "Item Reference No." := SalesLine."Item Reference No.";
        "Originally Ordered No." := SalesLine."Originally Ordered No.";
        "Originally Ordered Var. Code" := SalesLine."Originally Ordered Var. Code";
        "Out-of-Stock Substitution" := SalesLine."Out-of-Stock Substitution";
        "Item Category Code" := SalesLine."Item Category Code";
        Nonstock := SalesLine.Nonstock;
        "Purchasing Code" := SalesLine."Purchasing Code";
        "Return Reason Code" := SalesLine."Return Reason Code";
        "Planned Delivery Date" := SalesLine."Planned Delivery Date";
        "Document Line No." := SalesLine."Line No.";
        "Unit Cost" := SalesLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := SalesLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesLine."Sell-to Customer No.";
        "Price Calculation Method" := SalesLine."Price Calculation Method";
        "Invoice-to Source No." := SalesLine."Bill-to Customer No.";

        OnAfterCopyItemJnlLineFromSalesLine(Rec, SalesLine);
    end;

    procedure CopyFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        "Posting Date" := PurchHeader."Posting Date";
        "Document Date" := PurchHeader."Document Date";
        "VAT Reporting Date" := PurchHeader."VAT Reporting Date";
        "Source Posting Group" := PurchHeader."Vendor Posting Group";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "Country/Region Code" := PurchHeader."Buy-from Country/Region Code";
        "Reason Code" := PurchHeader."Reason Code";
        "Source Currency Code" := PurchHeader."Currency Code";
        "Shpt. Method Code" := PurchHeader."Shipment Method Code";
        "Price Calculation Method" := PurchHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromPurchHeader(Rec, PurchHeader);
    end;

    procedure CopyFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Item No." := PurchLine."No.";
        Description := PurchLine.Description;
        "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Location Code" := PurchLine."Location Code";
        "Bin Code" := PurchLine."Bin Code";
        "Variant Code" := PurchLine."Variant Code";
        "Item Category Code" := PurchLine."Item Category Code";
        "Inventory Posting Group" := PurchLine."Posting Group";
        "Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "Job No." := PurchLine."Job No.";
        "Job Task No." := PurchLine."Job Task No.";
        if "Job No." <> '' then
            "Job Purchase" := true;
        "Applies-to Entry" := PurchLine."Appl.-to Item Entry";
        "Transaction Type" := PurchLine."Transaction Type";
        "Transport Method" := PurchLine."Transport Method";
        "Entry/Exit Point" := PurchLine."Entry Point";
        Area := PurchLine.Area;
        "Transaction Specification" := PurchLine."Transaction Specification";
        "Drop Shipment" := PurchLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Purchase;
        if PurchLine."Prod. Order No." <> '' then begin
            "Order Type" := "Order Type"::Production;
            "Order No." := PurchLine."Prod. Order No.";
            "Order Line No." := PurchLine."Prod. Order Line No.";
        end;
        "Unit of Measure Code" := PurchLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := PurchLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := PurchLine."Qty. Rounding Precision (Base)";
        "Item Reference No." := PurchLine."Item Reference No.";
        "Document Line No." := PurchLine."Line No.";
        "Unit Cost" := PurchLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := PurchLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchLine."Buy-from Vendor No.";
        "Price Calculation Method" := PurchLine."Price Calculation Method";
        "Invoice-to Source No." := PurchLine."Pay-to Vendor No.";
        "Purchasing Code" := PurchLine."Purchasing Code";
        "Indirect Cost %" := PurchLine."Indirect Cost %";
        "Overhead Rate" := PurchLine."Overhead Rate";
        "Return Reason Code" := PurchLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromPurchLine(Rec, PurchLine);
    end;

    procedure CopyFromServHeader(ServiceHeader: Record "Service Header")
    begin
        "Document Date" := ServiceHeader."Document Date";
        "Order Date" := ServiceHeader."Order Date";
        "Source Posting Group" := ServiceHeader."Customer Posting Group";
        "Salespers./Purch. Code" := ServiceHeader."Salesperson Code";
        "Reason Code" := ServiceHeader."Reason Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := ServiceHeader."Customer No.";
        "Shpt. Method Code" := ServiceHeader."Shipment Method Code";
        "Price Calculation Method" := ServiceHeader."Price Calculation Method";

        if ServiceHeader.IsCreditDocType() then
            "Country/Region Code" := ServiceHeader."Country/Region Code"
        else
            if ServiceHeader."Ship-to Country/Region Code" <> '' then
                "Country/Region Code" := ServiceHeader."Ship-to Country/Region Code"
            else
                "Country/Region Code" := ServiceHeader."Country/Region Code";

        OnAfterCopyItemJnlLineFromServHeader(Rec, ServiceHeader);
    end;

    procedure CopyFromServLine(ServiceLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemJnlLineFromServLine(Rec, ServiceLine, IsHandled);
        if not IsHandled then begin
            "Item No." := ServiceLine."No.";
            "Posting Date" := ServiceLine."Posting Date";
            Description := ServiceLine.Description;
            "Shortcut Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServiceLine."Dimension Set ID";
            "Location Code" := ServiceLine."Location Code";
            "Bin Code" := ServiceLine."Bin Code";
            "Variant Code" := ServiceLine."Variant Code";
            "Inventory Posting Group" := ServiceLine."Posting Group";
            "Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
            "Applies-to Entry" := ServiceLine."Appl.-to Item Entry";
            "Transaction Type" := ServiceLine."Transaction Type";
            "Transport Method" := ServiceLine."Transport Method";
            "Entry/Exit Point" := ServiceLine."Exit Point";
            Area := ServiceLine.Area;
            "Transaction Specification" := ServiceLine."Transaction Specification";
            "Entry Type" := "Entry Type"::Sale;
            "Unit of Measure Code" := ServiceLine."Unit of Measure Code";
            "Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
            "Qty. Rounding Precision" := ServiceLine."Qty. Rounding Precision";
            "Qty. Rounding Precision (Base)" := ServiceLine."Qty. Rounding Precision (Base)";
            "Derived from Blanket Order" := false;
            "Item Category Code" := ServiceLine."Item Category Code";
            Nonstock := ServiceLine.Nonstock;
            "Return Reason Code" := ServiceLine."Return Reason Code";
            "Order Type" := "Order Type"::Service;
            "Order No." := ServiceLine."Document No.";
            "Order Line No." := ServiceLine."Line No.";
            "Job No." := ServiceLine."Job No.";
            "Job Task No." := ServiceLine."Job Task No.";
            "Price Calculation Method" := ServiceLine."Price Calculation Method";
            "Invoice-to Source No." := ServiceLine."Bill-to Customer No.";
        end;
        OnAfterCopyItemJnlLineFromServLine(Rec, ServiceLine);
    end;

    procedure CopyFromServShptHeader(ServShptHeader: Record "Service Shipment Header")
    begin
        "Document Date" := ServShptHeader."Document Date";
        "Order Date" := ServShptHeader."Order Date";
        "Country/Region Code" := ServShptHeader."VAT Country/Region Code";
        "Source Posting Group" := ServShptHeader."Customer Posting Group";
        "Salespers./Purch. Code" := ServShptHeader."Salesperson Code";
        "Reason Code" := ServShptHeader."Reason Code";

        OnAfterCopyItemJnlLineFromServShptHeader(Rec, ServShptHeader);
    end;

    procedure CopyFromServShptLine(ServShptLine: Record "Service Shipment Line")
    begin
        "Item No." := ServShptLine."No.";
        Description := ServShptLine.Description;
        "Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        "Inventory Posting Group" := ServShptLine."Posting Group";
        "Location Code" := ServShptLine."Location Code";
        "Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Variant Code" := ServShptLine."Variant Code";
        "Bin Code" := ServShptLine."Bin Code";
        "Shortcut Dimension 1 Code" := ServShptLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServShptLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServShptLine."Dimension Set ID";
        "Entry/Exit Point" := ServShptLine."Exit Point";
        "Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";
        "Transaction Type" := ServShptLine."Transaction Type";
        "Transport Method" := ServShptLine."Transport Method";
        Area := ServShptLine.Area;
        "Transaction Specification" := ServShptLine."Transaction Specification";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Item Category Code" := ServShptLine."Item Category Code";
        Nonstock := ServShptLine.Nonstock;
        "Return Reason Code" := ServShptLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromServShptLine(Rec, ServShptLine);
    end;

    procedure CopyFromServShptLineUndo(ServShptLine: Record "Service Shipment Line")
    begin
        "Item No." := ServShptLine."No.";
        "Posting Date" := ServShptLine."Posting Date";
        "Order Date" := ServShptLine."Order Date";
        "Inventory Posting Group" := ServShptLine."Posting Group";
        "Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        "Location Code" := ServShptLine."Location Code";
        "Variant Code" := ServShptLine."Variant Code";
        "Bin Code" := ServShptLine."Bin Code";
        "Entry/Exit Point" := ServShptLine."Exit Point";
        "Shortcut Dimension 1 Code" := ServShptLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServShptLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServShptLine."Dimension Set ID";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Item No." := ServShptLine."No.";
        Description := ServShptLine.Description;
        "Location Code" := ServShptLine."Location Code";
        "Variant Code" := ServShptLine."Variant Code";
        "Transaction Type" := ServShptLine."Transaction Type";
        "Transport Method" := ServShptLine."Transport Method";
        Area := ServShptLine.Area;
        "Transaction Specification" := ServShptLine."Transaction Specification";
        "Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Derived from Blanket Order" := false;
        "Item Category Code" := ServShptLine."Item Category Code";
        Nonstock := ServShptLine.Nonstock;
        "Return Reason Code" := ServShptLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromServShptLineUndo(Rec, ServShptLine);
    end;

    procedure CopyFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Line No." := JobJnlLine."Line No.";
        "Item No." := JobJnlLine."No.";
        "Posting Date" := JobJnlLine."Posting Date";
        "Document Date" := JobJnlLine."Document Date";
        "Document No." := JobJnlLine."Document No.";
        "External Document No." := JobJnlLine."External Document No.";
        Description := JobJnlLine.Description;
        "Location Code" := JobJnlLine."Location Code";
        "Applies-to Entry" := JobJnlLine."Applies-to Entry";
        "Applies-from Entry" := JobJnlLine."Applies-from Entry";
        "Shortcut Dimension 1 Code" := JobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := JobJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := JobJnlLine."Dimension Set ID";
        "Country/Region Code" := JobJnlLine."Country/Region Code";
        "Entry Type" := "Entry Type"::"Negative Adjmt.";
        "Source Code" := JobJnlLine."Source Code";
        "Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        "Posting No. Series" := JobJnlLine."Posting No. Series";
        "Variant Code" := JobJnlLine."Variant Code";
        "Bin Code" := JobJnlLine."Bin Code";
        "Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        "Reason Code" := JobJnlLine."Reason Code";
        "Transaction Type" := JobJnlLine."Transaction Type";
        "Transport Method" := JobJnlLine."Transport Method";
        "Entry/Exit Point" := JobJnlLine."Entry/Exit Point";
        Area := JobJnlLine.Area;
        "Transaction Specification" := JobJnlLine."Transaction Specification";
        "Invoiced Quantity" := JobJnlLine.Quantity;
        "Invoiced Qty. (Base)" := JobJnlLine."Quantity (Base)";
        "Source Currency Code" := JobJnlLine."Source Currency Code";
        Quantity := JobJnlLine.Quantity;
        "Quantity (Base)" := JobJnlLine."Quantity (Base)";
        "Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := JobJnlLine."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := JobJnlLine."Qty. Rounding Precision (Base)";
        "Unit Cost" := JobJnlLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := JobJnlLine."Unit Cost";
        Amount := JobJnlLine."Total Cost (LCY)";
        "Amount (ACY)" := JobJnlLine."Total Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Job No." := JobJnlLine."Job No.";
        "Job Task No." := JobJnlLine."Job Task No.";
        "Shpt. Method Code" := JobJnlLine."Shpt. Method Code";

        OnAfterCopyItemJnlLineFromJobJnlLine(Rec, JobJnlLine);
    end;

    local procedure CopyFromProdOrderComp(ProdOrderComp: Record "Prod. Order Component")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromProdOrderComp(Rec, ProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        Validate("Order Line No.", ProdOrderComp."Prod. Order Line No.");
        Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Location Code" := ProdOrderComp."Location Code";
        Validate("Variant Code", ProdOrderComp."Variant Code");
        Validate("Bin Code", ProdOrderComp."Bin Code");

        OnAfterCopyFromProdOrderComp(Rec, ProdOrderComp);
    end;

    local procedure CopyFromProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
        Validate("Order Line No.", ProdOrderLine."Line No.");
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Location Code" := ProdOrderLine."Location Code";
        Validate("Variant Code", ProdOrderLine."Variant Code");
        Validate("Bin Code", ProdOrderLine."Bin Code");

        OnAfterCopyFromProdOrderLine(Rec, ProdOrderLine);
    end;

    local procedure CopyFromWorkCenter(WorkCenter: Record "Work Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromWorkCenter(Rec, WorkCenter, IsHandled);
        if IsHandled then
            exit;

        "Work Center No." := WorkCenter."No.";
        Description := WorkCenter.Name;
        "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";

        OnAfterCopyFromWorkCenter(Rec, WorkCenter);
    end;

    local procedure CopyFromMachineCenter(MachineCenter: Record "Machine Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromMachineCenter(Rec, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        "Work Center No." := MachineCenter."Work Center No.";
        Description := MachineCenter.Name;
        "Gen. Prod. Posting Group" := MachineCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := "Unit Cost Calculation"::Time;

        OnAfterCopyFromMachineCenter(Rec, MachineCenter);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;

        OnAfterReadGLSetup(GLSetup);
    end;

    protected procedure RetrieveCosts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCosts(Rec, UnitCost, IsHandled);
        if IsHandled then
            exit;

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        ReadGLSetup();
        GetItem();

        UnitCost := FindUnitCost();

        OnRetrieveCostsOnAfterSetUnitCost(Rec, UnitCost, Item);

        if "Entry Type" = "Entry Type"::Transfer then
            UnitCost := 0
        else
            if Item."Costing Method" <> Item."Costing Method"::Standard then
                UnitCost := Round(UnitCost, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure FindUnitCost() UnitCost: Decimal
    var
        SKU: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindUnitCost(Rec, UnitCost, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        if InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::Item then
            UnitCost := Item."Unit Cost"
        else
            if SKU.Get("Location Code", "Item No.", "Variant Code") then
                UnitCost := SKU."Unit Cost"
            else
                UnitCost := Item."Unit Cost";
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
        UnitCost :=
          (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;
        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure ClearSingleAndRolledUpCosts()
    begin
        "Single-Level Material Cost" := "Unit Cost (Revalued)";
        "Single-Level Capacity Cost" := 0;
        "Single-Level Subcontrd. Cost" := 0;
        "Single-Level Cap. Ovhd Cost" := 0;
        "Single-Level Mfg. Ovhd Cost" := 0;
        "Rolled-up Material Cost" := "Unit Cost (Revalued)";
        "Rolled-up Capacity Cost" := 0;
        "Rolled-up Subcontracted Cost" := 0;
        "Rolled-up Mfg. Ovhd Cost" := 0;
        "Rolled-up Cap. Overhead Cost" := 0;
    end;

    local procedure GetMfgSetup()
    begin
        if not MfgSetupRead then
            MfgSetup.Get();
        MfgSetupRead := true;
    end;

    local procedure GetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Order Type", "Order Type"::Production);
        TestField("Order No.");
        TestField("Operation No.");

        ProdOrderRoutingLine.Get(
            ProdOrderRoutingLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
    end;

    procedure OnlyStopTime(): Boolean
    begin
        exit(("Setup Time" = 0) and ("Run Time" = 0) and ("Stop Time" <> 0));
    end;

    procedure OutputValuePosting(): Boolean
    begin
        exit(TimeIsEmpty() and ("Invoiced Quantity" <> 0) and not Subcontracting);
    end;

    procedure TimeIsEmpty(): Boolean
    begin
        exit(("Setup Time" = 0) and ("Run Time" = 0) and ("Stop Time" = 0));
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::"Item Journal Line", "Entry Type".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if (Bin.Code <> BinCode) or (Bin."Location Code" <> LocationCode) then
                Bin.Get(LocationCode, BinCode);
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Posting Date";
        ReservEntry."Shipment Date" := "Posting Date";

        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        SetReservEntrySourceFilters(ReservEntry, false);
        ReservEntry.SetTrackingFilterFromItemJnlLine(Rec);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    internal procedure SetReservEntrySourceFilters(var ReservEntry: Record "Reservation Entry"; SourceKey: Boolean)
    begin
        if IsSourceSales() then
            ReservEntry.SetSourceFilter(Database::"Item Journal Line", "Entry Type".AsInteger(), "Document No.", "Document Line No.", SourceKey)
        else
            ReservEntry.SetSourceFilter(Database::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", SourceKey);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);
    end;

    internal procedure IsSourceSales(): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if ("Entry Type" = Rec."Entry Type"::"Sale") then begin
            SourceCodeSetup.SetLoadFields(Sales);
            SourceCodeSetup.Get();
            exit("Source Code" = SourceCodeSetup.Sales);
        end;
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        ReservEntry.ClearTrackingFilter();
        exit(not ReservEntry.IsEmpty);
    end;

    procedure ItemPosting(): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NextOperationNoIsEmpty: Boolean;
        IsHandled: Boolean;
    begin
        if ("Entry Type" = "Entry Type"::Output) and ("Output Quantity" <> 0) and ("Operation No." <> '') then begin
            GetProdOrderRoutingLine(ProdOrderRoutingLine);
            IsHandled := false;
            OnAfterItemPosting(ProdOrderRoutingLine, NextOperationNoIsEmpty, IsHandled);
            if IsHandled then
                exit(NextOperationNoIsEmpty);
            exit(ProdOrderRoutingLine."Next Operation No." = '');
        end;

        exit(true);
    end;

    local procedure CheckPlanningAssignment()
    begin
        if ("Quantity (Base)" <> 0) and ("Item No." <> '') and ("Posting Date" <> 0D) and
           ("Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::"Positive Adjmt.", "Entry Type"::Transfer])
        then begin
            if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                exit;

            ItemJnlLineReserve.AssignForPlanning(Rec);
        end;
    end;

    procedure LastOutputOperation(ItemJnlLine: Record "Item Journal Line") Result: Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Operation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLastOutputOperation(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemJnlLine."Operation No." <> '' then begin
            IsHandled := false;
            OnLastOutputOperationOnBeforeTestRoutingNo(ItemJnlLine, IsHandled);
            if not IsHandled then
                ItemJnlLine.TestField("Routing No.");
            if not ProdOrderRtngLine.Get(
                 ProdOrderRtngLine.Status::Released, ItemJnlLine."Order No.",
                 ItemJnlLine."Routing Reference No.", ItemJnlLine."Routing No.", ItemJnlLine."Operation No.")
            then
                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Finished, ItemJnlLine."Order No.",
                  ItemJnlLine."Routing Reference No.", ItemJnlLine."Routing No.", ItemJnlLine."Operation No.");
            if ItemJnlLine.Finished then
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
            else
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
            Operation := not ItemJnlPostLine.NextOperationExist(ProdOrderRtngLine);
        end else
            Operation := true;
        exit(Operation);
    end;

    procedure LookupItemNo()
    var
        ItemList: Page "Item List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupItemNo(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Entry Type" of
            "Entry Type"::Consumption:
                LookupProdOrderComp();
            "Entry Type"::Output:
                LookupProdOrderLine();
            else begin
                ItemList.LookupMode := true;
                if "Item No." <> '' then
                    if Item.Get("Item No.") then
                        ItemList.SetRecord(Item);
                if ItemList.RunModal() = ACTION::LookupOK then begin
                    ItemList.GetRecord(Item);
                    Validate("Item No.", Item."No.");
                end;
            end;
        end;
    end;

    local procedure LookupProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLineList: Page "Prod. Order Line List";
    begin
        ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := "Order No.";
        ProdOrderLine."Line No." := "Order Line No.";
        ProdOrderLine."Item No." := "Item No.";
        ProdOrderLine."Variant Code" := "Variant Code";

        ProdOrderLineList.LookupMode(true);
        ProdOrderLineList.SetTableView(ProdOrderLine);
        ProdOrderLineList.SetRecord(ProdOrderLine);

        if ProdOrderLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderLineList.GetRecord(ProdOrderLine);
            Validate("Item No.", ProdOrderLine."Item No.");
            if ProdOrderLine."Variant Code" <> '' then
                Validate("Variant Code", ProdOrderLine."Variant Code");
            if "Order Line No." <> ProdOrderLine."Line No." then
                Validate("Order Line No.", ProdOrderLine."Line No.");
        end;
    end;

    local procedure LookupProdOrderComp()
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderCompLineList: Page "Prod. Order Comp. Line List";
        IsHandled: Boolean;
    begin
        ProdOrderComp.SetFilterByReleasedOrderNo("Order No.");
        if "Order Line No." <> 0 then
            ProdOrderComp.SetRange("Prod. Order Line No.", "Order Line No.");
        ProdOrderComp.Status := ProdOrderComp.Status::Released;
        ProdOrderComp."Prod. Order No." := "Order No.";
        ProdOrderComp."Prod. Order Line No." := "Order Line No.";
        ProdOrderComp."Line No." := "Prod. Order Comp. Line No.";
        ProdOrderComp."Item No." := "Item No.";

        ProdOrderCompLineList.LookupMode(true);
        ProdOrderCompLineList.SetTableView(ProdOrderComp);
        ProdOrderCompLineList.SetRecord(ProdOrderComp);

        IsHandled := false;
        OnLookupProdOrderCompBeforeRunModal(ProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderCompLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderCompLineList.GetRecord(ProdOrderComp);
            if "Prod. Order Comp. Line No." <> ProdOrderComp."Line No." then begin
                Validate("Item No.", ProdOrderComp."Item No.");
                Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            end;
        end;
    end;

    procedure RecalculateUnitAmount()
    var
        ItemJnlLine1: Record "Item Journal Line";
        PriceType: Enum "Price Type";
    begin
        GetItem();

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then begin
            "Indirect Cost %" := 0;
            "Overhead Rate" := 0;
        end else begin
            "Indirect Cost %" := Item."Indirect Cost %";
            "Overhead Rate" := Item."Overhead Rate";
        end;

        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        OnRecalculateUnitAmountOnAfterCalcQtyPerUnitOfMeasure(Rec, xRec);
        GetUnitAmount(FieldNo("Unit of Measure Code"));

        ReadGLSetup();

        UpdateAmount();

        case "Entry Type" of
            "Entry Type"::Purchase:
                begin
                    ItemJnlLine1.Copy(Rec);
                    ItemJnlLine1.ApplyPrice(PriceType::Purchase, FieldNo("Unit of Measure Code"));
                    "Unit Cost" := Round(ItemJnlLine1."Unit Amount" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                end;
            "Entry Type"::Sale:
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Positive Adjmt.":
                "Unit Cost" :=
                  Round(
                    "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                  "Overhead Rate" * "Qty. per Unit of Measure";
            "Entry Type"::"Negative Adjmt.":
                if not "Phys. Inventory" then
                    "Unit Cost" := UnitCost * "Qty. per Unit of Measure";
        end;

        if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt."] then begin
            if Item."Costing Method" = Item."Costing Method"::Standard then
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        end;

        OnAfterRecalculateUnitAmount(Rec, xRec, CurrFieldNo);
    end;

    procedure IsReclass(ItemJnlLine: Record "Item Journal Line"): Boolean
    begin
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
           ((ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Transfer) or (ItemJnlLine."Order No." = ''))
        then
            exit(true);
        exit(false);
    end;

    procedure CheckWhse(LocationCode: Code[20]; var QtyToPost: Decimal)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);

        if "Entry Type" = "Entry Type"::Output then begin
            if Location."Prod. Output Whse. Handling" = Enum::"Prod. Output Whse. Handling"::"Inventory Put-away" then
                QtyToPost := 0;
        end else
            if Location."Require Put-away" and
               (not Location."Directed Put-away and Pick") and
               (not Location."Require Receive")
            then
                QtyToPost := 0;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure ShowReclasDimensions()
    begin
        DimMgt.EditReclasDimensionSet(
          "Dimension Set ID", "New Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
          "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        ItemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            ItemJournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    procedure PostingItemJnlFromProduction(Print: Boolean)
    var
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
    begin
        if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then
            ProductionOrder.Get(ProductionOrder.Status::Released, "Order No.");

        IsHandled := false;
        OnBeforePostingItemJnlFromProduction(Rec, Print, IsHandled);
        if IsHandled then
            exit;

        if Print then
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post+Print", Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", Rec);
    end;

    internal procedure PreviewPostItemJnlFromProduction()
    var
        ProductionOrder: Record "Production Order";
        ItemJnlPost: Codeunit "Item Jnl.-Post";
    begin
        if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then
            ProductionOrder.Get(ProductionOrder.Status::Released, "Order No.");

        ItemJnlPost.Preview(Rec);
    end;

    procedure IsAssemblyResourceConsumpLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::Resource));
    end;

    procedure IsAssemblyOutputLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::" "));
    end;

    procedure IsATOCorrection(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        if not Correction then
            exit(false);
        if "Entry Type" <> "Entry Type"::Sale then
            exit(false);
        if not ItemLedgEntry.Get("Applies-to Entry") then
            exit(false);
        if ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Sale then
            exit(false);
        PostedATOLink.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        PostedATOLink.SetRange("Document Type", PostedATOLink."Document Type"::"Sales Shipment");
        PostedATOLink.SetRange("Document No.", ItemLedgEntry."Document No.");
        PostedATOLink.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
        exit(not PostedATOLink.IsEmpty);
    end;

    local procedure RevaluationPerEntryAllowed(ItemNo: Code[20]) Result: Boolean
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevaluationPerEntryAllowed(Rec, ItemNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetItem();
        if Item."Costing Method" <> Item."Costing Method"::Average then
            exit(true);

        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Partial Revaluation", true);
        exit(ValueEntry.IsEmpty);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
    end;

    procedure ClearDates()
    begin
        "Expiration Date" := 0D;
        "Warranty Date" := 0D;
    end;

    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromNewSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyNewTrackingFromNewSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromOldItemLedgerEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "New Serial No." := ItemLedgEntry."Serial No.";
        "New Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyNewTrackingFromOldItemLedgerEntry(Rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromItemLedgerEntry(ItemledgerEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgerEntry."Serial No.");
        SetRange("Lot No.", ItemLedgerEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure HasSameTracking(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(
          (Rec."Serial No." = ItemJournalLine."Serial No.") and
          (Rec."Lot No." = ItemJournalLine."Lot No.") and
          (Rec."Package No." = ItemJournalLine."Package No."));
    end;

    procedure HasSameNewTracking() IsSameTracking: Boolean
    begin
        IsSameTracking := ("Serial No." = "New Serial No.") and ("Lot No." = "New Lot No.");

        OnAfterHasSameNewTracking(Rec, IsSameTracking);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestItemFields(Rec, ItemNo, VariantCode, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure DisplayErrorIfItemIsBlocked(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisplayErrorIfItemIsBlocked(Item, Rec, IsHandled);
        if IsHandled then
            exit;

        if Item.Blocked then
            Error(BlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption(Blocked));

        if "Item Charge No." <> '' then
            exit;

        case "Entry Type" of
            "Entry Type"::Purchase:
                if Item."Purchasing Blocked" and
                   not ("Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Credit Memo"])
                   and ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then
                    Error(PurchasingBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked"));
            "Entry Type"::Sale:
                case "Order Type" of
                    "Order Type"::Service:
                        if Item."Service Blocked" and
                           not ("Document Type" in ["Document Type"::"Service Credit Memo"])
                        then
                            Error(ServiceSalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Service Blocked"));
                    else
                        if Item."Sales Blocked" and
                           not ("Document Type" in ["Document Type"::"Sales Return Receipt", "Document Type"::"Sales Credit Memo"])
                        then
                            Error(SalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked"));
                end;
        end;

        OnAfterDisplayErrorIfItemIsBlocked(Item, Rec);
    end;

    procedure DisplayErrorIfItemVariantIsBlocked(ItemVariant: Record "Item Variant")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisplayErrorIfItemVariantIsBlocked(ItemVariant, Rec, IsHandled);
        if IsHandled then
            exit;

        if ItemVariant.Blocked then
            Error(BlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption(Blocked));

        case Rec."Entry Type" of
            Rec."Entry Type"::Purchase:
                if ItemVariant."Purchasing Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Purchase Return Shipment", Rec."Document Type"::"Purchase Credit Memo"]) then
                    Error(PurchasingBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked"));
            "Entry Type"::Sale:
                case "Order Type" of
                    "Order Type"::Service:
                        if ItemVariant."Service Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Service Credit Memo"]) then
                            Error(ServiceSalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Service Blocked"));
                    else
                        if ItemVariant."Sales Blocked" and not (Rec."Document Type" in [Rec."Document Type"::"Sales Return Receipt", Rec."Document Type"::"Sales Credit Memo"]) then
                            Error(SalesBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked"));
                end;
        end;

        OnAfterDisplayErrorIfItemVariantIsBlocked(ItemVariant, Rec);
    end;

    procedure IsPurchaseReturn(): Boolean
    begin
        exit(
          ("Document Type" in ["Document Type"::"Purchase Credit Memo",
                               "Document Type"::"Purchase Return Shipment",
                               "Document Type"::"Purchase Invoice",
                               "Document Type"::"Purchase Receipt"]) and
          (Quantity < 0));
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                ItemJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            ItemJournalBatch.SetFilter(Name, BatchFilter);
            ItemJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure SubcontractingWorkCenterUsed() Result: Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if Type = Type::"Work Center" then
            if WorkCenter.Get("Work Center No.") then
                Result := WorkCenter."Subcontractor No." <> '';
        OnAfterSubcontractingWorkCenterUsed(Rec, WorkCenter, Result);
    end;

    local procedure ErrorIfSubcontractingWorkCenterUsed()
    begin
        if not SubcontractingWorkCenterUsed() then
            exit;
        if "Setup Time" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Setup Time"), "Line No."), true));
        if "Run Time" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Run Time"), "Line No."), true));
        if "Output Quantity" <> 0 then
            Error(ErrorInfo.Create(StrSubstNo(SubcontractedErr, FieldCaption("Output Quantity"), "Line No."), true));
    end;

    procedure CheckItemJournalLineRestriction()
    begin
        OnCheckItemJournalLinePostRestrictions();
    end;

    procedure CheckTrackingIsEmpty()
    begin
        TestField("Serial No.", '');
        TestField("Lot No.", '');

        OnAfterCheckTrackingisEmpty(Rec);
    end;

    procedure CheckNewTrackingIsEmpty()
    begin
        TestField("New Serial No.", '');
        TestField("New Lot No.", '');

        OnAfterCheckNewTrackingisEmpty(Rec);
    end;

    procedure CheckTrackingEqualItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TestField("Lot No.", ItemLedgerEntry."Lot No.");
        TestField("Serial No.", ItemLedgerEntry."Serial No.");

        OnAfterCheckTrackingEqualItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CheckTrackingEqualTrackingSpecification(TrackingSpecification: Record "Tracking Specification")
    begin
        TestField("Lot No.", TrackingSpecification."Lot No.");
        TestField("Serial No.", TrackingSpecification."Serial No.");

        OnAfterCheckTrackingEqualTrackingSpecification(Rec, TrackingSpecification);
    end;

    procedure CheckTrackingIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            TestField("Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterCheckTrackingIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure CheckNewTrackingIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            TestField("New Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            TestField("New Lot No.");

        OnAfterCheckNewTrackingIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure CheckTrackingIfRequiredNotBlank(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" and ("Serial No." = '') then
            Error(SerialNoRequiredErr, "Item No.");
        if ItemTrackingSetup."Lot No. Required" and ("Lot No." = '') then
            Error(LotNoRequiredErr, "Item No.");

        OnAfterCheckTrackingIfRequiredNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure ValidateTypeWithItemNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateTypeWithItemNo(Rec, Item, IsHandled);
        if IsHandled then
            exit;
        // Validate the item type when defining a relation with another table

        // Service is not a valid item type
        // i.e items of type service cannot be in a relation with another table
        if Item.IsServiceType() then
            Item.TestField(Type, Item.Type::Inventory);

        // Non-inventoriable item types are valid only for the following entry types
        if Item.IsNonInventoriableType() and
           not ("Entry Type" in ["Entry Type"::Consumption, "Entry Type"::"Assembly Consumption"])
        then
            Item.TestField(Type, Item.Type::Inventory);
    end;

    procedure IsNotInternalWhseMovement(): Boolean
    begin
        exit(
          not (("Entry Type" = "Entry Type"::Transfer) and
               ("Location Code" = "New Location Code") and
               ("Dimension Set ID" = "New Dimension Set ID") and
               ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
               not Adjustment));
    end;

    procedure PrintInventoryMovement()
    begin
        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
        Rec.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        Report.RunModal(Report::"Inventory Movement", true, true, Rec);
    end;

    local procedure IsDefaultBin() Result: Boolean
    begin
        Result := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";

        OnAfterIsDefaultBin(Location, Result);
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    begin
        Result := UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName);
        OnAfterCalcBaseQty(Rec, xRec, FromFieldName, Result);
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        IsHandled: Boolean;
        RecordCount: Integer;
    begin
        ProdOrderComponent.SetFilterByReleasedOrderNo("Order No.");
        if "Order Line No." <> 0 then
            ProdOrderComponent.SetRange("Prod. Order Line No.", "Order Line No.");
        ProdOrderComponent.SetRange("Line No.", "Prod. Order Comp. Line No.");
        IsHandled := false;
        OnValidateItemNoOnAfterProdOrderCompSetFilters(Rec, ProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetRange("Item No.", "Item No.");
        RecordCount := ProdOrderComponent.Count();
        if RecordCount > 1 then
            exit(false)
        else
            if RecordCount = 1 then
                exit(ProdOrderComponent.FindFirst());

        ProdOrderComponent.SetRange("Line No.");
        if ProdOrderComponent.Count() = 1 then
            exit(ProdOrderComponent.FindFirst());

        exit(false);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure CreateNewDimFromDefaultDim(FieldNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        SourceCode: Code[10];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);

        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "New Shortcut Dimension 1 Code" := '';
        "New Shortcut Dimension 2 Code" := '';
        "New Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCode,
            "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code", 0, 0);
        DimMgt.UpdateGlobalDimFromDimSetID("New Dimension Set ID", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("Item No."):
                TableValuePair.Add(Database::Item, Rec."Item No.");
            FieldNo = Rec.FieldNo("Salespers./Purch. Code"):
                TableValuePair.Add(Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code");
            FieldNo = Rec.FieldNo("Work Center No."):
                TableValuePair.Add(Database::"Work Center", Rec."Work Center No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
            FieldNo = Rec.FieldNo("New Location Code"):
                TableValuePair.Add(Database::Location, Rec."New Location Code");
        end;

        OnAfterInitTableValuePair(Rec, TableValuePair, FieldNo);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.", FieldNo = Rec.FieldNo("Item No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", Rec."Work Center No.", FieldNo = Rec.FieldNo("Work Center No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."New Location Code", FieldNo = Rec.FieldNo("New Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure RenumberDocumentNo()
    var
        ItemJnlLine2: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if SkipRenumberDocumentNo() then
            exit;

        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if ItemJnlBatch."No. Series" = '' then
            exit;
        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        FirstDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := GetTempRenumberDocumentNo();
        // step1 - renumber to non-existing document number
        DocNo := FirstTempDocNo;
        ItemJnlLine2 := Rec;
        ItemJnlLine2.Reset();
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);
        LastTempDocNo := DocNo;

        // step2 - renumber to real document number (within Filter)
        DocNo := FirstDocNo;
        ItemJnlLine2.CopyFilters(Rec);
        ItemJnlLine2 := Rec;
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);

        // step3 - renumber to real document number (outside filter)
        DocNo := IncStr(DocNo);
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Document No.", FirstTempDocNo, LastTempDocNo);
        RenumberDocNoOnLines(DocNo, ItemJnlLine2);

        if Get("Journal Template Name", "Journal Batch Name", "Line No.") then;
    end;

    local procedure GetTempRenumberDocumentNo(): Code[20]
    begin
        exit('RENUMBERED-000000001');
    end;

    local procedure SkipRenumberDocumentNo() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRenumberDocumentNo(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GuiAllowed() and not DIALOG.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true));
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line")
    var
        LastItemJnlLine: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        PrevDocNo: Code[20];
        FirstDocNo: Code[20];
        TempFirstDocNo: Code[20];
        First: Boolean;
        IsHandled: Boolean;
        PrevPostingDate: Date;
    begin
        IsHandled := false;
        OnBeforeRenumberDocNoOnLines(DocNo, ItemJnlLine2, IsHandled);
        if IsHandled then
            exit;

        FirstDocNo := DocNo;
        ItemJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.");
        ItemJnlLine2.SetRange("Journal Template Name", ItemJnlLine2."Journal Template Name");
        ItemJnlLine2.SetRange("Journal Batch Name", ItemJnlLine2."Journal Batch Name");
        LastItemJnlLine.Init();
        First := true;
        if ItemJnlLine2.FindSet() then
            repeat
                if ((FirstDocNo <> GetTempRenumberDocumentNo()) and (ItemJnlLine2.GetFilter("Document No.") = '')) then begin
                    Commit();
                    ItemJnlBatch.Get(ItemJnlLine2."Journal Template Name", ItemJnlLine2."Journal Batch Name");
                    TempFirstDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", ItemJnlLine2."Posting Date");
                    if (FirstDocNo <> TempFirstDocNo) and (FirstDocNo <> IncStr(TempFirstDocNo)) then begin
                        DocNo := TempFirstDocNo;
                        FirstDocNo := DocNo;
                        First := true;
                    end;
                end;
                if ItemJnlLine2."Document No." = FirstDocNo then
                    exit;
                if not First and
                    ((ItemJnlLine2."Posting Date" <> PrevPostingDate) or
                    (ItemJnlLine2."Document No." = '')) and
                    not LastItemJnlLine.EmptyLine()
                then
                    DocNo := IncStr(DocNo);
                PrevDocNo := ItemJnlLine2."Document No.";
                PrevPostingDate := ItemJnlLine2."Posting Date";
                ItemJnlLine3.Get(ItemJnlLine2."Journal Template Name", ItemJnlLine2."Journal Batch Name", ItemJnlLine2."Line No.");
                ItemJnlLine3."Document No." := DocNo;
                ItemJnlLine3.Modify();
                First := false;
                LastItemJnlLine := ItemJnlLine2;
            until ItemJnlLine2.Next() = 0;

        OnAfterRenumberDocNoOnLines(DocNo, ItemJnlLine2);
    end;

    internal procedure CreateItemTrackingLines(UpdateTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Copy(Rec);
        ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);
        if UpdateTracking then
            UpdateItemTracking(ItemJournalLine);
    end;

    internal procedure UpdateItemTracking(var ItemJournalLine: Record "Item Journal Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SingleItemTrackingExists: Boolean;
    begin
        ItemJournalLine.Find();
        TempItemJournalLine := ItemJournalLine;

        if ItemJournalLine.GetItemTracking(TempTrackingSpecification) then
            if TempTrackingSpecification.Count() = 1 then begin
                SingleItemTrackingExists := true;
                ItemJournalLine.CopyTrackingFromSpec(TempTrackingSpecification);
                ItemJournalLine."Expiration Date" := TempTrackingSpecification."Expiration Date";
                ItemJournalLine."Warranty Date" := TempTrackingSpecification."Warranty Date";
            end;

        if not SingleItemTrackingExists then begin
            ItemJournalLine.ClearTracking();
            ItemJournalLine.ClearDates();
        end;

        if not ItemJournalLine.HasSameTracking(TempItemJournalLine) then
            ItemJournalLine.Modify();
    end;

    local procedure IsItemTrackingEnabledInBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if ItemJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(ItemJournalBatch."Item Tracking on Lines");

        exit(false);
    end;

    local procedure CheckItemTracking(CalledByFieldNo: Integer)
    var
        FieldCap: Text;
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemTracking(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsItemTrackingEnabledInBatch() then begin
            ClearTracking();
            ClearDates();
            exit;
        end;

        case CalledByFieldNo of
            FieldNo("Serial No."):
                begin
                    CheckSerialNoQty();
                    if "Serial No." <> '' then
                        if HasItemTracking() then
                            FieldCap := FieldCaption("Serial No.");
                end;
            FieldNo("Lot No."):
                if "Lot No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Lot No.");
            FieldNo("Package No."):
                if "Package No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Package No.");
            FieldNo("Warranty Date"):
                if "Warranty Date" <> 0D then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Warranty Date");
            FieldNo("Expiration Date"):
                if "Expiration Date" <> 0D then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Expiration Date");
        end;

        if FieldCap <> '' then
            Error(ItemTrackingExistsErr, FieldCap);
    end;

    local procedure HasItemTracking(): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(not ReservationEntry.IsEmpty());
    end;

    internal procedure GetItemTracking(var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(ItemTrackingManagement.SumUpItemTracking(ReservationEntry, TempTrackingSpecification, false, true));
    end;

    procedure LookUpTrackingSummary(TrackingType: Enum "Item Tracking Type")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        Math: Codeunit "Math";
    begin
        TempTrackingSpecification.InitFromItemJnlLine(Rec);
        GetItem();
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode('', ItemTrackingCode);
        ItemTrackingDataCollection.AssistEditTrackingNo(
            TempTrackingSpecification, not IsInbound(), Math.Sign(Signed(Quantity)),
            TrackingType, Quantity);

        case TrackingType of
            TrackingType::"Serial No.":
                if TempTrackingSpecification."Serial No." <> '' then begin
                    "Serial No." := TempTrackingSpecification."Serial No.";
                    "Lot No." := TempTrackingSpecification."Lot No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            TrackingType::"Lot No.":
                if TempTrackingSpecification."Lot No." <> '' then begin
                    "Lot No." := TempTrackingSpecification."Lot No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            TrackingType::"Package No.":
                if TempTrackingSpecification."Package No." <> '' then begin
                    "Package No." := TempTrackingSpecification."Package No.";
                    "Expiration Date" := TempTrackingSpecification."Expiration Date";
                end;
            else
                OnLookUpTrackingSummaryOnCaseOrderTypeElse(Rec, TempTrackingSpecification, TrackingType);
        end;

        OnAfterLookUpTrackingSummary(Rec, TempTrackingSpecification, TrackingType);
    end;

    local procedure CheckSerialNoQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNoQty(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;
        if not ("Quantity (Base)" in [-1, 0, 1]) then
            Error(IncorrectQtyForSNErr);
    end;

    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        CalculationDate := Rec."Posting Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ItemJournalLine: Record "Item Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimWithProdOrderLineOnAfterInitDefaultDimensionSources(var ItemJournalLine: Record "Item Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var ItemJournalLine: Record "Item Journal Line"; var LastItemJournalLine: Record "Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSigned(ItemJournalLine: Record "Item Journal Line"; Value: Decimal; Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubcontractingWorkCenterUsed(ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record "Work Center"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQty(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FromFieldName: Text; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingisEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewTrackingisEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualItemLedgEntry(ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualTrackingSpecification(ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesHeader(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesLine(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchHeader(var ItemJnlLine: Record "Item Journal Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchLine(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServHeader(var ItemJnlLine: Record "Item Journal Line"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServLine(var ItemJnlLine: Record "Item Journal Line"; ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptHeader(var ItemJnlLine: Record "Item Journal Line"; ServShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLine(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLineUndo(var ItemJnlLine: Record "Item Journal Line"; ServShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromJobJnlLine(var ItemJournalLine: Record "Item Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ItemJournalLine: Record "Item Journal Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromNewSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromOldItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromWorkCenter(var ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMachineCenter(var ItemJournalLine: Record "Item Journal Line"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateAssemblyDim(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayErrorIfItemIsBlocked(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayErrorIfItemVariantIsBlocked(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemChange(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemVariantChange(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; UnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameNewTracking(ItemJournalLine: Record "Item Journal Line"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemPosting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var NextOperationNoIsEmpty: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnValidateItemNoAssignByEntryType(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateUnitAmount(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(var ItemJournalLine: Record "Item Journal Line"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmount(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderCompBinCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmOutputOnFinishedOperation(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromMachineCenter(var ItemJournalLine: Record "Item Journal Line"; var MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromWorkCenter(var ItemJournalLine: Record "Item Journal Line"; var WorkCenter: Record "Work Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisplayErrorIfItemIsBlocked(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisplayErrorIfItemVariantIsBlocked(var ItemVariant: Record "Item Variant"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLastOutputOperation(ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItemNo(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostingItemJnlFromProduction(var ItemJournalLine: Record "Item Journal Line"; Print: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCosts(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevaluationPerEntryAllowed(ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectItemEntry(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNewBinCodeForSameLocationTransfer(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemDirectCostUnitAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityIsBalanced(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitOfMeasureCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateScrapQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateOutputQuantityBase(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer)
    begin
    end;

    local procedure CheckConfirmOutputOnFinishedOperation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if ("Entry Type" <> "Entry Type"::Output) or ("Output Quantity" = 0) then
            exit;

        if not ProdOrderRtngLine.Get(
             ProdOrderRtngLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.")
        then
            exit;

        if ProdOrderRtngLine."Routing Status" <> ProdOrderRtngLine."Routing Status"::Finished then
            exit;

        ConfirmOutputOnFinishedOperation();
    end;

    local procedure ConfirmOutputOnFinishedOperation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmOutputOnFinishedOperation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Confirm(FinishedOutputQst) then
            Error(UpdateInterruptedErr);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckItemJournalLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAssemblyDimOnAfterCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdDimOnAfterCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLastOutputOperationOnBeforeTestRoutingNo(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnAfterFindItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var FirstItemJournalLine: Record "Item Journal Line"; var LastItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnBeforeOpenPage(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnvalidateConcurrentCapacityOnAfterCalcTotalTime(var ItemJournalLine: Record "Item Journal Line"; var TotalTime: Integer; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitofMeasureCodeOnBeforeRoutingCostPerUnit(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterGetItem(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliestoEntryOnAfterCalcShouldCheckItemLedgEntryFieldsForOutput(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ShouldCheckItemLedgEntryFieldsForOutput: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcShouldThrowRevaluationError(var ItemJournalLine: Record "Item Journal Line"; var ShouldThrowRevaluationError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOrderTypeProduction(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnAfterProcessOrderTypeAssembly(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderLineNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderLineNoOnAfterProdOrderLineSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitAmount(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesToEntryOnAferCalcShowTrackingExistsError(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ShowTrackingExistsError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemFields(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeWhseValidateSourceLine(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmount(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateScrapCode(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveCostsOnAfterSetUnitCost(var ItemJournalLine: Record "Item Journal Line"; var UnitCost: Decimal; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeValidateUnitOfmeasureCode(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item; CurrFieldNo: Integer; xItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterSetProdOrderLineItemNoFilter(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcShouldCopyFromSingleProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var ShouldCopyFromSingleProdOrderLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeSetDescription(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcUnitCost(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCalcUnitAmount(var ItemJournalLine: Record "Item Journal Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterCreateDimInitial(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterProdOrderCompSetFilters(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDim(var ItemJournalLine: Record "Item Journal Line"; DimenionSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateProdDim(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationCode(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDefaultBin(Location: Record Location; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfrequiredNotBlank(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRevalJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateUnitAmountOnAfterCalcQtyPerUnitOfMeasure(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupProdOrderCompBeforeRunModal(var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdDimOnBeforeCreateDimSetIDArr(var ItemJournalLine: Record "Item Journal Line"; var DimSetIDArr: array[10] of Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinCodeOnCheckProdOrderCompBinCodeCheckNeeded(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeAssignIndirectCostPct(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetDefaultPriceCalculationMethod(var ItemJournalLine: Record "Item Journal Line"; ItemJnlBatch: Record "Item Journal Batch"; var DimMgt: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateProdOrderCompLineNo(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSkipRenumberDocumentNo(ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberDocNoOnLines(var DocNo: Code[20]; var ItemJnlLine2: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinCodeOnBeforeTestBinMandatory(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemJnlLineFromServLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectItemEntry(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRevalJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry2: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpTrackingSummary(var ItemJournalLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var ItemJournalLine: Record "Item Journal Line"; var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSigned(ItemJournalLine: Record "Item Journal Line"; var Value: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTypeWithItemNo(var ItemJournalLine: Record "Item Journal Line"; Item: Record "Item"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(var ItemJournalLine: Record "Item Journal Line"; xItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoQty(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
}
