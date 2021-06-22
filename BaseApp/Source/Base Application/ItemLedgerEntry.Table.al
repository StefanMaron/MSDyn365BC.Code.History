table 32 "Item Ledger Entry"
{
    Caption = 'Item Ledger Entry';
    DrillDownPageID = "Item Ledger Entries";
    LookupPageID = "Item Ledger Entries";
    Permissions = TableData "Item Ledger Entry" = rimd;

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
        field(4; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Purchase,Sale,Positive Adjmt.,Negative Adjmt.,Transfer,Consumption,Output, ,Assembly Consumption,Assembly Output';
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output";
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
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
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
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
        field(41; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
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
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = CONST(''),
                                                                           "Source Ref. No." = FIELD("Entry No."),
                                                                           "Source Type" = CONST(32),
                                                                           "Source Subtype" = CONST("0"),
                                                                           "Source Batch Name" = CONST(''),
                                                                           "Source Prod. Order Line" = CONST(0),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Sales Shipment,Sales Invoice,Sales Return Receipt,Sales Credit Memo,Purchase Receipt,Purchase Invoice,Purchase Return Shipment,Purchase Credit Memo,Transfer Shipment,Transfer Receipt,Service Shipment,Service Invoice,Service Credit Memo,Posted Assembly';
            OptionMembers = " ","Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo","Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo","Transfer Shipment","Transfer Receipt","Service Shipment","Service Invoice","Service Credit Memo","Posted Assembly";
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(90; "Order Type"; Option)
        {
            Caption = 'Order Type';
            Editable = false;
            OptionCaption = ' ,Production,Transfer,Service,Assembly';
            OptionMembers = " ",Production,Transfer,Service,Assembly;
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
                ShowDimensions;
            end;
        }
        field(904; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job."No.";
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(1002; "Job Purchase"; Boolean)
        {
            Caption = 'Job Purchase';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
        }
        field(5700; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
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
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Originally Ordered No."));
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
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
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
            CalcFormula = Sum ("Value Entry"."Cost Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5804; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5805; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Non-Invtbl.)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5806; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Expected) (ACY)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Expected) (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5807; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Actual) (ACY)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Actual) (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5808; "Cost Amount (Non-Invtbl.)(ACY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Cost Amount (Non-Invtbl.)(ACY)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Cost Amount (Non-Invtbl.)(ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5813; "Purchase Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Purchase Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Purchase Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5814; "Purchase Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Purchase Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Purchase Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5815; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Sales Amount (Expected)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
            Caption = 'Sales Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5816; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry No." = FIELD("Entry No.")));
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
                ItemTrackingMgt.LookupLotSerialNoInfo("Item No.", "Variant Code", 0, "Serial No.");
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupLotSerialNoInfo("Item No.", "Variant Code", 1, "Lot No.");
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
        field(6510; "Item Tracking"; Option)
        {
            Caption = 'Item Tracking';
            Editable = false;
            OptionCaption = 'None,Lot No.,Lot and Serial No.,Serial No.';
            OptionMembers = "None","Lot No.","Lot and Serial No.","Serial No.";
        }
        field(6602; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
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
        }
        key(Key7; "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.")
        {
            Enabled = false;
            SumIndexFields = Quantity, "Remaining Quantity";
        }
        key(Key8; "Country/Region Code", "Entry Type", "Posting Date")
        {
        }
        key(Key9; "Document No.", "Document Type", "Document Line No.")
        {
        }
        key(Key10; "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Global Dimension 1 Code", "Global Dimension 2 Code", "Location Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Quantity, "Invoiced Quantity";
        }
        key(Key11; "Source Type", "Source No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Item No.", "Variant Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Quantity;
        }
        key(Key12; "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Quantity;
        }
        key(Key13; "Item No.", "Applied Entry to Adjust")
        {
        }
        key(Key14; "Item No.", Positive, "Location Code", "Variant Code")
        {
        }
        key(Key15; "Entry Type", Nonstock, "Item No.", "Posting Date")
        {
            Enabled = false;
        }
        key(Key16; "Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.")
        {
            Enabled = false;
            SumIndexFields = "Remaining Quantity";
        }
        key(Key17; "Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.")
        {
        }
        key(Key18; "Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Remaining Quantity";
        }
        key(Key19; "Lot No.")
        {
        }
        key(Key20; "Serial No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Item No.", "Posting Date", "Entry Type", "Document No.")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveItemLedgEntry: Codeunit "Item Ledger Entry-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        GLSetupRead: Boolean;
        IsNotOnInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.';

    local procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get;
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, true);
        ReserveItemLedgEntry.FilterReservFor(ReservEntry, Rec);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure SetAppliedEntryToAdjust(AppliedEntryToAdjust: Boolean)
    begin
        if "Applied Entry to Adjust" <> AppliedEntryToAdjust then begin
            "Applied Entry to Adjust" := AppliedEntryToAdjust;
            Modify;
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
        ItemApplnEntry.Find('-');
        if not "Completely Invoiced" then begin
            CompletelyInvoiced := true;
            repeat
                InbndItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
                if not InbndItemLedgEntry."Completely Invoiced" then
                    CompletelyInvoiced := false;
            until ItemApplnEntry.Next = 0;

            if CompletelyInvoiced then begin
                SetCompletelyInvoiced;
                exit(true);
            end;
        end;
        exit(false);
    end;

    procedure SetCompletelyInvoiced()
    begin
        if not "Completely Invoiced" then begin
            "Completely Invoiced" := true;
            Modify;
        end;
    end;

    procedure AppliedEntryToAdjustExists(ItemNo: Code[20]): Boolean
    begin
        Reset;
        SetCurrentKey("Item No.", "Applied Entry to Adjust");
        SetRange("Item No.", ItemNo);
        SetRange("Applied Entry to Adjust", true);
        exit(Find('-'));
    end;

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
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        "Item Tracking" := ItemTrackingMgt.ItemTrackingOption("Lot No.", "Serial No.");
    end;

    procedure GetUnitCostLCY(): Decimal
    begin
        if Quantity = 0 then
            exit("Cost Amount (Actual)");

        exit(Round("Cost Amount (Actual)" / Quantity, 0.00001));
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; NetChange: Boolean)
    begin
        Reset;
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

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
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

    procedure IsOutbndSale(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::Sale) and not Positive);
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;

    procedure CalculateRemQuantity(ItemLedgEntryNo: Integer; PostingDate: Date): Decimal
    var
        ItemApplnEntry: Record "Item Application Entry";
        RemQty: Decimal;
    begin
        ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.");
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntryNo);
        RemQty := 0;
        if ItemApplnEntry.FindSet then
            repeat
                if ItemApplnEntry."Posting Date" <= PostingDate then
                    RemQty += ItemApplnEntry.Quantity;
            until ItemApplnEntry.Next = 0;
        exit(RemQty);
    end;

    procedure VerifyOnInventory()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyOnInventory(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Open then
            exit;
        if Quantity >= 0 then
            exit;
        case "Entry Type" of
            "Entry Type"::Consumption, "Entry Type"::"Assembly Consumption", "Entry Type"::Transfer:
                Error(IsNotOnInventoryErr, "Item No.");
            else begin
                    Item.Get("Item No.");
                    if Item.PreventNegativeInventory then
                        Error(IsNotOnInventoryErr, "Item No.");
                end;
        end;
    end;

    procedure CalculateRemInventoryValue(ItemLedgEntryNo: Integer; ItemLedgEntryQty: Decimal; RemQty: Decimal; IncludeExpectedCost: Boolean; PostingDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        AdjustedCost: Decimal;
        TotalQty: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.SetFilter("Valuation Date", '<=%1', PostingDate);
        if not IncludeExpectedCost then
            ValueEntry.SetRange("Expected Cost", false);
        if ValueEntry.FindSet then
            repeat
                if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                    TotalQty := ValueEntry."Valued Quantity"
                else
                    TotalQty := ItemLedgEntryQty;
                if ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Rounding then
                    if IncludeExpectedCost then
                        AdjustedCost += RemQty / TotalQty * (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)")
                    else
                        AdjustedCost += RemQty / TotalQty * ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next = 0;
        exit(AdjustedCost);
    end;

    procedure TrackingExists(): Boolean
    begin
        exit(("Serial No." <> '') or ("Lot No." <> ''));
    end;

    procedure SetItemVariantLocationFilters(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; PostingDate: Date)
    begin
        Reset;
        SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        SetRange("Item No.", ItemNo);
        SetRange("Variant Code", VariantCode);
        SetRange("Location Code", LocationCode);
        SetRange("Posting Date", 0D, PostingDate);
    end;

    procedure SetTrackingFilter(SerialNo: Code[50]; LotNo: Code[50])
    begin
        SetRange("Serial No.", SerialNo);
        SetRange("Lot No.", LotNo);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");
    end;

    [Scope('OnPrem')]
    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyOnInventory(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

