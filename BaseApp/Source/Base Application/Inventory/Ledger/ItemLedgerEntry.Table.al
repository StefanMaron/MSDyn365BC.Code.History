namespace Microsoft.Inventory.Ledger;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

table 32 "Item Ledger Entry"
{
    Caption = 'Item Ledger Entry';
    DrillDownPageID = "Item Ledger Entries";
    LookupPageID = "Item Ledger Entries";
    Permissions = TableData "Item Ledger Entry" = rimd;
    DataClassification = CustomerContent;

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
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(28; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
        }
        field(29; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(36; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(41; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(47; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
        }
        field(50; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(51; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(52; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
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
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(62; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(63; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(64; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(70; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = const(''),
                                                                           "Source Ref. No." = field("Entry No."),
                                                                           "Source Type" = const(32),
                                                                           "Source Subtype" = const("0"),
                                                                           "Source Batch Name" = const(''),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
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
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(904; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Purchase"; Boolean)
        {
            Caption = 'Project Purchase';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
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
            Caption = 'Item Reference No.';
        }
        field(5800; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(5801; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
        }
        field(5802; "Applied Entry to Adjust"; Boolean)
        {
            Caption = 'Applied Entry to Adjust';
        }
        field(5803; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Expected)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5804; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5805; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Non-Invtbl.)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5806; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Expected) (ACY)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Expected) (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5807; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Actual) (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5808; "Cost Amount (Non-Invtbl.)(ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Non-Invtbl.)(ACY)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Cost Amount (Non-Invtbl.)(ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5813; "Purchase Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Purchase Amount (Expected)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Purchase Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5814; "Purchase Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Purchase Amount (Actual)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Purchase Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5815; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Expected)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Sales Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5816; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry No." = field("Entry No.")));
            Caption = 'Sales Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(5818; "Shipped Qty. Not Returned"; Decimal)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Shipped Qty. Not Returned';
            DecimalPlaces = 0 : 5;
        }
        field(5833; "Prod. Order Comp. Line No."; Integer)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Prod. Order Comp. Line No.';
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(6510; "Item Tracking"; Enum "Item Tracking Entry Type")
        {
            Caption = 'Item Tracking';
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
        field(6602; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(11500; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(11501; "Ship-to Address Code"; Code[10])
        {
            Caption = 'Ship-to Address Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(11502; "Customer Salesperson Code"; Code[20])
        {
            Caption = 'Customer Salesperson Code';
            Editable = false;
            TableRelation = "Salesperson/Purchaser";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.")
        {
            SumIndexFields = "Invoiced Quantity", Quantity;
        }
        key(Key3; "Item No.", "Posting Date")
        {
            IncludedFields = Quantity, "Location Code";
        }
        key(Key4; "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date")
        {
            SumIndexFields = Quantity, "Invoiced Quantity";
        }
        key(Key5; "Source Type", "Source No.", "Item No.", "Variant Code", "Posting Date")
        {
            SumIndexFields = Quantity;
        }
        key(Key6; "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date")
        {
            SumIndexFields = Quantity, "Remaining Quantity";
            IncludedFields = "Job No.", "Job Task No.", "Document Type", "Document No.", "Order Type", "Order No.", "Serial No.", "Lot No.", "Package No.";
        }
        key(Key8; "Country/Region Code", "Entry Type", "Posting Date")
        {
        }
        key(Key9; "Document No.", "Document Type", "Document Line No.")
        {
            IncludedFields = "Entry Type", "Item No.", Correction;
        }
        key(Key12; "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.")
        {
            IncludedFields = Quantity, "Posting Date", Positive, "Applies-to Entry";
        }
        key(Key13; "Item No.", "Applied Entry to Adjust")
        {
        }
        key(Key14; "Item No.", Positive, "Location Code", "Variant Code")
        {
        }
#pragma warning disable AS0009
        key(Key17; "Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
            IncludedFields = "Remaining Quantity";
        }
        key(Key19; "Lot No.")
        {
        }
        key(Key20; "Serial No.", "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date")
        {
        }
        key(Key21; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Item No.", "Posting Date", "Entry Type", "Document No.")
        {
        }
        fieldgroup(Brick; "Item No.", Description, Quantity, "Document No.", "Document Date")
        { }
    }

    var
        GLSetup: Record "General Ledger Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingType: Enum "Item Tracking Type";
        GLSetupRead: Boolean;
        UseItemTrackingLinesPageErr: Label 'You must use form %1 to enter %2, if item tracking is used.', Comment = '%1 - page caption, %2 - field caption';
        IsNotOnInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.';

    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure SetAppliedEntryToAdjust(AppliedEntryToAdjust: Boolean)
    begin
        if "Applied Entry to Adjust" <> AppliedEntryToAdjust then begin
            "Applied Entry to Adjust" := AppliedEntryToAdjust;
            Modify();
        end;
    end;

    procedure SetAvgTransCompletelyInvoiced(): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
        InbndItemLedgEntry: Record "Item Ledger Entry";
        CompletelyInvoiced: Boolean;
    begin
        if "Entry Type" <> "Entry Type"::Transfer then
            exit(false);

        ItemApplnEntry.SetCurrentKey("Item Ledger Entry No.");
        ItemApplnEntry.SetRange("Item Ledger Entry No.", "Entry No.");
        ItemApplnEntry.FindSet();
        if not "Completely Invoiced" then begin
            CompletelyInvoiced := true;
            repeat
                InbndItemLedgEntry.SetLoadFields("Completely Invoiced");
                InbndItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
                if not InbndItemLedgEntry."Completely Invoiced" then
                    CompletelyInvoiced := false;
            until ItemApplnEntry.Next() = 0;

            if CompletelyInvoiced then begin
                SetCompletelyInvoiced();
                exit(true);
            end;
        end;
        exit(false);
    end;

    procedure SetCompletelyInvoiced()
    begin
        if not "Completely Invoiced" then begin
            "Completely Invoiced" := true;
            Modify();
        end;
    end;

#if not CLEAN24
    [Obsolete('Unused', '24.0')]
    procedure AppliedEntryToAdjustExists(ItemNo: Code[20]): Boolean
    begin
        Reset();
        SetCurrentKey("Item No.", "Applied Entry to Adjust");
        SetRange("Item No.", ItemNo);
        SetRange("Applied Entry to Adjust", true);
        exit(Find('-'));
    end;
#endif

    procedure IsOutbndConsump(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::Consumption) and not Positive);
    end;

    procedure IsExactCostReversingPurchase(): Boolean
    begin
        exit(
          ("Applies-to Entry" <> 0) and
          ("Entry Type" = "Entry Type"::Purchase) and
          ("Invoiced Quantity" < 0));
    end;

    procedure IsExactCostReversingOutput(): Boolean
    begin
        exit(
          ("Applies-to Entry" <> 0) and
          ("Entry Type" in ["Entry Type"::Output, "Entry Type"::"Assembly Output"]) and
          ("Invoiced Quantity" < 0));
    end;

    procedure UpdateItemTracking()
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.CopyTrackingFromItemLedgEntry(Rec);
        "Item Tracking" := ReservEntry.GetItemTrackingEntryType();
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure GetUnitCostLCY(): Decimal
    begin
        if Quantity = 0 then
            exit("Cost Amount (Actual)");

        exit(Round("Cost Amount (Actual)" / Quantity, 0.00001));
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; NetChange: Boolean)
    begin
        Reset();
        SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        SetRange("Item No.", Item."No.");
        SetRange(Open, true);
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        if NetChange then
            SetFilter("Posting Date", Item.GetFilter("Date Filter"));
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, NetChange);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; NetChange: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, NetChange);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; NetChange: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, NetChange);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; NewPositive: Boolean)
    var
        IsHandled: Boolean;
    begin
        Reset();
        SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code");
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange(Open, true);
        IsHandled := false;
        OnFilterLinesForReservationOnBeforeSetFilterVariantCode(Rec, ReservationEntry, Positive, IsHandled);
        if not IsHandled then
            SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange(Positive, NewPositive);
        SetRange("Location Code", ReservationEntry."Location Code");
        SetRange("Drop Shipment", false);
        OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewPositive);
    end;

    procedure FilterLinesForTracking(CalcReservEntry: Record "Reservation Entry"; Positive: Boolean)
    var
        FieldFilter: Text;
    begin
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Lot No.") then
            SetFilter("Lot No.", FieldFilter);
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Serial No.") then
            SetFilter("Serial No.", FieldFilter);

        OnAfterFilterLinesForTracking(Rec, CalcReservEntry, Positive);
    end;

    procedure IsOutbndSale(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::Sale) and not Positive);
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure CalculateRemQuantity(ItemLedgEntryNo: Integer; PostingDate: Date) RemQty: Decimal
    var
        ItemApplnEntry: Record "Item Application Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateRemQuantity(Rec, ItemLedgEntryNo, PostingDate, RemQty, IsHandled);
        if IsHandled then
            exit(RemQty);

        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntryNo);
        RemQty := 0;
        if ItemApplnEntry.FindSet() then
            repeat
                if ItemApplnEntry."Posting Date" <= PostingDate then
                    RemQty += ItemApplnEntry.Quantity;
            until ItemApplnEntry.Next() = 0;
        exit(RemQty);
    end;

    procedure VerifyOnInventory()
    begin
        VerifyOnInventory(StrSubstNo(IsNotOnInventoryErr, "Item No."));
    end;

    procedure VerifyOnInventory(ErrorMessageText: Text)
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyOnInventory(Rec, IsHandled, ErrorMessageText);
        if IsHandled then
            exit;

        if not Open then
            exit;
        if Quantity >= 0 then
            exit;
        case "Entry Type" of
            "Entry Type"::Consumption, "Entry Type"::"Assembly Consumption", "Entry Type"::Transfer:
                Error(ErrorMessageText);
            else begin
                Item.Get("Item No.");
                if Item.PreventNegativeInventory() then
                    Error(ErrorMessageText);
            end;
        end;

        OnAfterVerifyOnInventory(Rec, ErrorMessageText);
    end;

    procedure CalculateRemInventoryValue(ItemLedgEntryNo: Integer; ItemLedgEntryQty: Decimal; RemQty: Decimal; IncludeExpectedCost: Boolean; PostingDate: Date): Decimal
    begin
        exit(
          CalculateRemInventoryValue(ItemLedgEntryNo, ItemLedgEntryQty, RemQty, IncludeExpectedCost, 0D, PostingDate));
    end;

    procedure CalculateRemInventoryValue(ItemLedgEntryNo: Integer; ItemLedgEntryQty: Decimal; RemQty: Decimal; IncludeExpectedCost: Boolean; ValuationDate: Date; PostingDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        AdjustedCost: Decimal;
        TotalQty: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ValuationDate <> 0D then
            ValueEntry.SetRange("Valuation Date", 0D, ValuationDate);
        if PostingDate <> 0D then
            ValueEntry.SetRange("Posting Date", 0D, PostingDate);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Rounding);
        if not IncludeExpectedCost then
            ValueEntry.SetRange("Expected Cost", false);
        if ValueEntry.FindSet() then
            repeat
                if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                    TotalQty := ValueEntry."Valued Quantity"
                else
                    TotalQty := ItemLedgEntryQty;
                if IncludeExpectedCost then
                    AdjustedCost += RemQty / TotalQty * (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)")
                else
                    AdjustedCost += RemQty / TotalQty * ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next() = 0;

        exit(AdjustedCost);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure CheckTrackingDoesNotExist(RecId: RecordId; FldCaption: Text)
    var
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTrackingDoesNotExist(RecId, Rec, FldCaption, IsHandled);
        if IsHandled then
            exit;

        if TrackingExists() then
            Error(UseItemTrackingLinesPageErr, ItemTrackingLines.Caption, FldCaption);
    end;

    procedure CopyTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        "Serial No." := ItemJnlLine."Serial No.";
        "Lot No." := ItemJnlLine."Lot No.";

        OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingFromNewItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        "Serial No." := ItemJnlLine."New Serial No.";
        "Lot No." := ItemJnlLine."New Lot No.";

        OnAfterCopyTrackingFromNewItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyToReserve: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReservationQty(Rec, QtyReserved, QtyToReserve, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Quantity");
        QtyReserved := "Reserved Quantity";
        QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
    end;

    internal procedure CalcReservedQuantity()
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        OnBeforeCalcReservedQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." = '' then
            CalcFields("Reserved Quantity")
        else begin
            ReservationEntry.SetCurrentKey("Serial No.", "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
            ReservationEntry.SetRange("Serial No.", "Serial No.");
            ReservationEntry.SetRange("Source ID", '');
            ReservationEntry.SetRange("Source Ref. No.", "Entry No.");
            ReservationEntry.SetRange("Source Type", Database::"Item Ledger Entry");
            ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"0");
            ReservationEntry.SetRange("Source Batch Name", '');
            ReservationEntry.SetRange("Source Prod. Order Line", 0);
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
            ReservationEntry.CalcSums("Quantity (Base)");
            "Reserved Quantity" := ReservationEntry."Quantity (Base)"
        end;
    end;

    procedure SetItemVariantLocationFilters(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; PostingDate: Date)
    begin
        Reset();
        SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        SetRange("Item No.", ItemNo);
        SetRange("Variant Code", VariantCode);
        SetRange("Location Code", LocationCode);
        SetRange("Posting Date", 0D, PostingDate);
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Item Ledger Entry", 0, '', "Entry No.", '', 0);
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        Positive := "Remaining Quantity" <= 0;
        if Positive then begin
            ReservEntry."Expected Receipt Date" := DMY2Date(31, 12, 9999);
            ReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
        end else begin
            ReservEntry."Expected Receipt Date" := 0D;
            ReservEntry."Shipment Date" := 0D;
        end;
        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Item Ledger Entry", 0, '', "Entry No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromItemJournalLine(ItemJournalLine: Record "Item Journal Line")
    begin
        SetRange("Serial No.", ItemJournalLine."Serial No.");
        SetRange("Lot No.", ItemJournalLine."Lot No.");

        OnAfterSetTrackingFilterFromItemJournalLine(Rec, ItemJournalLine);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterBlank()
    begin
        SetRange("Serial No.", '');
        SetRange("Lot No.", '');

        OnAfterSetTrackingFilterBlank(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure TestTrackingEqualToTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        TestField("Serial No.", TrackingSpecification."Serial No.");
        TestField("Lot No.", TrackingSpecification."Lot No.");

        OnAfterTestTrackingEqualToTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CollectItemLedgerEntryTypesUsed(var ItemLedgerEntryTypesUsed: Dictionary of [Enum "Item Ledger Entry Type", Boolean]; ItemNoFilter: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
        i: Integer;
    begin
        Clear(ItemLedgerEntryTypesUsed);

        if ItemNoFilter <> '' then
            ItemLedgerEntry.SetFilter("Item No.", ItemNoFilter);
        foreach i in "Item Ledger Entry Type".Ordinals() do begin
            ItemLedgerEntryType := "Item Ledger Entry Type".FromInteger(i);
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
            ItemLedgerEntryTypesUsed.Add(ItemLedgerEntryType, not ItemLedgerEntry.IsEmpty());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterBlank(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromNewItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item; NetChange: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry: Record "Reservation Entry"; NewPositive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForTracking(var ItemLedgerEntry: Record "Item Ledger Entry"; CalcReservEntry: Record "Reservation Entry"; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; FromItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemJournalLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromSpec(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(ItemLedgerEntry: Record "Item Ledger Entry"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestTrackingEqualToTrackingSpec(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateRemQuantity(ItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgEntryNo: Integer; PostingDate: Date; var RemQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTrackingDoesNotExist(RecId: RecordId; ItemLedgEntry: Record "Item Ledger Entry"; FldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReservationQty(var ItemLedgerEntry: Record "Item Ledger Entry"; var QtyReserved: Decimal; var QtyToReserve: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyOnInventory(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; ErrorMessageText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterLinesForReservationOnBeforeSetFilterVariantCode(var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservationEntry: Record "Reservation Entry"; var Positive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVerifyOnInventory(var ItemLedgerEntry: Record "Item Ledger Entry"; ErrorMessageText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReservedQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

