table 246 "Requisition Line"
{
    Caption = 'Requisition Line';
    DataCaptionFields = "Journal Batch Name", "Line No.";
    DrillDownPageID = "Requisition Lines";
    LookupPageID = "Requisition Lines";
    Permissions = TableData "Prod. Order Capacity Need" = rimd,
                  TableData "Routing Header" = r,
                  TableData "Production BOM Header" = r;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Requisition Wksh. Name".Name WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item';
            OptionMembers = " ","G/L Account",Item;

            trigger OnValidate()
            var
                NewType: Option;
            begin
                if Type <> xRec.Type then begin
                    NewType := Type;

                    DeleteRelations;
                    "Dimension Set ID" := 0;
                    "No." := '';
                    "Variant Code" := '';
                    "Location Code" := '';
                    "Prod. Order No." := '';
                    ReserveReqLine.VerifyChange(Rec, xRec);
                    AddOnIntegrMgt.ResetReqLineFields(Rec);
                    Init;
                    Type := NewType;
                end;
            end;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item),
                                     "Worksheet Template Name" = FILTER(<> ''),
                                     "Journal Batch Name" = FILTER(<> '')) Item WHERE(Type = CONST(Inventory))
            ELSE
            IF (Type = CONST(Item),
                                              "Worksheet Template Name" = CONST(''),
                                              "Journal Batch Name" = CONST('')) Item;

            trigger OnValidate()
            begin
                CheckActionMessageNew;
                ReserveReqLine.VerifyChange(Rec, xRec);
                DeleteRelations;

                if "No." = '' then begin
                    CreateDim(
                      DimMgt.TypeToTableID3(Type),
                      "No.", DATABASE::Vendor, "Vendor No.");
                    Init;
                    Type := xRec.Type;
                    exit;
                end;

                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    "Prod. Order No." := '';
                    AddOnIntegrMgt.ResetReqLineFields(Rec);
                end;

                TestField(Type);
                case Type of
                    Type::"G/L Account":
                        CopyFromGLAcc();
                    Type::Item:
                        CopyFromItem();
                end;

                if "Planning Line Origin" <> "Planning Line Origin"::"Order Planning" then
                    if ("Replenishment System" = "Replenishment System"::Purchase) and
                       (Item."Purch. Unit of Measure" <> '')
                    then
                        Validate("Unit of Measure Code", Item."Purch. Unit of Measure")
                    else
                        Validate("Unit of Measure Code", Item."Base Unit of Measure");

                CreateDim(
                  DimMgt.TypeToTableID3(Type),
                  "No.", DATABASE::Vendor, "Vendor No.");
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Quantity (Base)" := CalcBaseQty(Quantity);
                if Type = Type::Item then begin
                    GetDirectCost(FieldNo(Quantity));
                    "Remaining Quantity" := Quantity - "Finished Quantity";
                    "Remaining Qty. (Base)" := "Remaining Quantity" * "Qty. per Unit of Measure";

                    if (CurrFieldNo = FieldNo(Quantity)) or (CurrentFieldNo = FieldNo(Quantity)) then
                        SetActionMessage;

                    "Net Quantity (Base)" := (Quantity - "Original Quantity") * "Qty. per Unit of Measure";

                    OnValidateQuantityOnBeforeUnitCost(Rec, CurrFieldNo);
                    Validate("Unit Cost");
                    if ValidateFields then
                        if "Ending Date" <> 0D then
                            Validate("Ending Time")
                        else begin
                            if "Starting Date" = 0D then
                                "Starting Date" := WorkDate;
                            Validate("Starting Time");
                        end;
                    ReserveReqLine.VerifyQuantity(Rec, xRec);
                end;
            end;
        }
        field(9; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Vend: Record Vendor;
            begin
                if LookupVendor(Vend, true) then
                    Validate("Vendor No.", Vend."No.");
            end;

            trigger OnValidate()
            var
                Vend: Record Vendor;
                ItemVend: Record "Item Vendor";
                TempSKU: Record "Stockkeeping Unit" temporary;
            begin
                CheckActionMessageNew;
                "Order Address Code" := '';
                if "Vendor No." <> '' then
                    if Vend.Get("Vendor No.") then begin
                        if Vend."Privacy Blocked" then begin
                            if PlanningResiliency then
                                TempPlanningErrorLog.SetError(
                                  StrSubstNo(Text031, Vend.TableCaption, Vend."No."),
                                  DATABASE::Vendor, Vend.GetPosition);
                            Vend.VendPrivacyBlockedErrorMessage(Vend, false);
                        end;
                        if Vend.Blocked = Vend.Blocked::All then begin
                            if PlanningResiliency then
                                TempPlanningErrorLog.SetError(
                                  StrSubstNo(Text031, Vend.TableCaption, Vend."No."),
                                  DATABASE::Vendor, Vend.GetPosition);
                            Vend.VendBlockedErrorMessage(Vend, false);
                        end;
                        if "Order Date" = 0D then
                            Validate("Order Date", WorkDate);

                        Validate("Currency Code", Vend."Currency Code");
                        "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                        if Type = Type::Item then
                            UpdateDescription;
                        Validate(Quantity);
                    end else begin
                        if ValidateFields then
                            Error(Text005, FieldCaption("Vendor No."), "Vendor No.");
                        "Vendor No." := '';
                        "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                    end
                else begin
                    UpdateDescription;
                    "Price Calculation Method" := Vend.GetPriceCalculationMethod();
                end;
                UpdateDescription;

                GetLocationCode;

                if (Type = Type::Item) and ("No." <> '') and ("Prod. Order No." = '') then begin
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then begin
                        "Vendor Item No." := ItemVend."Vendor Item No.";
                        UpdateOrderReceiptDate(ItemVend."Lead Time Calculation");
                    end else begin
                        GetPlanningParameters.AtSKU(TempSKU, "No.", "Variant Code", "Location Code");
                        if "Vendor No." = TempSKU."Vendor No." then
                            "Vendor Item No." := TempSKU."Vendor Item No."
                        else
                            "Vendor Item No." := '';
                    end;
                    GetDirectCost(FieldNo("Vendor No."))
                end;
                "Supply From" := "Vendor No.";

                CreateDim(
                  DATABASE::Vendor, "Vendor No.",
                  DimMgt.TypeToTableID3(Type), "No.");
            end;
        }
        field(10; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
        }
        field(12; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                if (CurrFieldNo = FieldNo("Due Date")) or (CurrentFieldNo = FieldNo("Due Date")) then
                    SetActionMessage;

                if "Due Date" = 0D then
                    exit;

                if (CurrFieldNo = FieldNo("Due Date")) or (CurrentFieldNo = FieldNo("Due Date")) then
                    if (Type = Type::Item) and
                       ("Planning Level" = 0)
                    then
                        Validate(
                          "Ending Date",
                          LeadTimeMgt.PlannedEndingDate("No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type"))
                    else
                        Validate("Ending Date", "Due Date");

                CheckDueDateToDemandDate;
            end;
        }
        field(13; "Requester ID"; Code[50])
        {
            Caption = 'Requester ID';
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Requester ID");
            end;
        }
        field(14; Confirmed; Boolean)
        {
            Caption = 'Confirmed';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(17; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                ItemVend: Record "Item Vendor";
                ShouldGetDefaultBin: Boolean;
            begin
                ValidateLocationChange;
                CheckActionMessageNew;
                "Bin Code" := '';
                ReserveReqLine.VerifyChange(Rec, xRec);

                if Type = Type::Item then begin
                    UpdateReplenishmentSystem;
                    if "Location Code" <> xRec."Location Code" then
                        if ("Location Code" <> '') and ("No." <> '') and not IsDropShipment then begin
                            GetLocation("Location Code");
                            ShouldGetDefaultBin := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
                            OnValidateLocationCodeOnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin);
                            if ShouldGetDefaultBin then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                        end;
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then
                        "Vendor Item No." := ItemVend."Vendor Item No.";
                end;
                GetDirectCost(FieldNo("Location Code"));
            end;
        }
        field(18; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(19; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(20; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(21; "Order Date"; Date)
        {
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                "Starting Date" := "Order Date";

                GetDirectCost(FieldNo("Order Date"));

                if CurrFieldNo = FieldNo("Order Date") then
                    Validate("Starting Date");
            end;
        }
        field(22; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(23; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            TableRelation = "Sales Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            begin
                ReserveReqLine.VerifyChange(Rec, xRec);
            end;
        }
        field(24; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            Editable = false;

            trigger OnValidate()
            begin
                ReserveReqLine.VerifyChange(Rec, xRec);
            end;
        }
        field(25; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if "Sell-to Customer No." = '' then
                    "Ship-to Code" := ''
                else
                    Validate("Ship-to Code", '');

                ReserveReqLine.VerifyChange(Rec, xRec);
            end;
        }
        field(26; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Sell-to Customer No."));

            trigger OnValidate()
            var
                Cust: Record Customer;
                ShipToAddr: Record "Ship-to Address";
            begin
                if "Ship-to Code" <> '' then begin
                    ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                    "Location Code" := ShipToAddr."Location Code";
                end else begin
                    Cust.Get("Sell-to Customer No.");
                    "Location Code" := Cust."Location Code";
                end;
            end;
        }
        field(28; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            TableRelation = "Order Address".Code WHERE("Vendor No." = FIELD("Vendor No."));
        }
        field(29; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                Currency: Record Currency;
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                Currency.Initialize("Currency Code");
                if "Currency Code" <> '' then begin
                    TestField("Order Date");
                    if PlanningResiliency then
                        CheckExchRate(Currency);
                    Validate(
                      "Currency Factor", CurrExchRate.ExchangeRate("Order Date", "Currency Code"));
                end else
                    Validate("Currency Factor", 0);

                GetDirectCost(FieldNo("Currency Code"));
            end;
        }
        field(30; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;

            trigger OnValidate()
            var
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                if "Currency Code" <> '' then
                    TestField("Currency Factor");
                if "Currency Factor" <> xRec."Currency Factor" then begin
                    if xRec."Currency Factor" <> 0 then
                        "Direct Unit Cost" :=
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            "Order Date", xRec."Currency Code", "Direct Unit Cost", xRec."Currency Factor");
                    if "Currency Factor" <> 0 then
                        "Direct Unit Cost" :=
                          CurrExchRate.ExchangeAmtLCYToFCY(
                            "Order Date", "Currency Code", "Direct Unit Cost", "Currency Factor");
                end;
            end;
        }
        field(31; "Reserved Quantity"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Worksheet Template Name"),
                                                                  "Source Ref. No." = FIELD("Line No."),
                                                                  "Source Type" = CONST(246),
                                                                  "Source Subtype" = CONST("0"),
                                                                  "Source Batch Name" = FIELD("Journal Batch Name"),
                                                                  "Source Prod. Order Line" = CONST(0),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
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
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
            TableRelation = "Production Order"."No." WHERE(Status = CONST(Released));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                AddOnIntegrMgt.ValidateProdOrderOnReqLine(Rec);
                Validate("Unit of Measure Code");
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            var
                ItemVend: Record "Item Vendor";
                ShouldGetDefaultBin: Boolean;
            begin
                if "Variant Code" <> '' then
                    TestField(Type, Type::Item);
                CheckActionMessageNew;
                ReserveReqLine.VerifyChange(Rec, xRec);

                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);

                GetDirectCost(FieldNo("Variant Code"));
                if "Variant Code" <> '' then begin
                    UpdateDescription;
                    UpdateReplenishmentSystem;
                    if "Variant Code" <> xRec."Variant Code" then begin
                        "Bin Code" := '';
                        if ("Location Code" <> '') and ("No." <> '') then begin
                            GetLocation("Location Code");
                            ShouldGetDefaultBin := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
                            OnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin);
                            if ShouldGetDefaultBin then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                        end;
                    end;
                    if ItemVend.Get("Vendor No.", "No.", "Variant Code") then
                        "Vendor Item No." := ItemVend."Vendor Item No.";
                end else
                    Validate("No.");
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                            "Item Filter" = FIELD("No."),
                                            "Variant Filter" = FIELD("Variant Code"));

            trigger OnValidate()
            begin
                CheckActionMessageNew;
                if (CurrFieldNo = FieldNo("Bin Code")) and
                   ("Action Message" <> "Action Message"::" ")
                then
                    TestField("Action Message", "Action Message"::New);
                TestField(Type, Type::Item);
                TestField("Location Code");
                if ("Bin Code" <> xRec."Bin Code") and ("Bin Code" <> '') then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    Location.TestField("Directed Put-away and Pick", false);
                    GetBin("Location Code", "Bin Code");
                    TestField("Location Code", Bin."Location Code");
                end;
                ReserveReqLine.VerifyChange(Rec, xRec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";

            trigger OnValidate()
            begin
                CheckActionMessageNew;
                if (Type = Type::Item) and
                   ("No." <> '') and
                   ("Prod. Order No." = '')
                then begin
                    GetItem;
                    "Unit Cost" := Item."Unit Cost";
                    "Overhead Rate" := Item."Overhead Rate";
                    "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                    if "Unit of Measure Code" <> '' then begin
                        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                        "Unit Cost" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    end else
                        "Qty. per Unit of Measure" := 1;
                end else
                    if "Prod. Order No." = '' then
                        "Qty. per Unit of Measure" := 1
                    else
                        "Qty. per Unit of Measure" := 0;
                GetDirectCost(FieldNo("Unit of Measure Code"));

                if "Planning Line Origin" = "Planning Line Origin"::"Order Planning" then
                    SetSupplyQty("Demand Quantity (Base)", "Needed Quantity (Base)")
                else
                    Validate(Quantity);
            end;
        }
        field(5408; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Prod. Order No.", '');
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5431; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Worksheet Template Name"),
                                                                           "Source Ref. No." = FIELD("Line No."),
                                                                           "Source Type" = CONST(246),
                                                                           "Source Subtype" = CONST("0"),
                                                                           "Source Batch Name" = FIELD("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = CONST(0),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5520; "Demand Type"; Integer)
        {
            Caption = 'Demand Type';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(5521; "Demand Subtype"; Option)
        {
            Caption = 'Demand Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9";
        }
        field(5522; "Demand Order No."; Code[20])
        {
            Caption = 'Demand Order No.';
            Editable = false;
        }
        field(5525; "Demand Line No."; Integer)
        {
            Caption = 'Demand Line No.';
            Editable = false;
        }
        field(5526; "Demand Ref. No."; Integer)
        {
            Caption = 'Demand Ref. No.';
            Editable = false;
        }
        field(5527; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(5530; "Demand Date"; Date)
        {
            Caption = 'Demand Date';
            Editable = false;
        }
        field(5532; "Demand Quantity"; Decimal)
        {
            Caption = 'Demand Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5533; "Demand Quantity (Base)"; Decimal)
        {
            Caption = 'Demand Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5538; "Needed Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Needed Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5539; "Needed Quantity (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Needed Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5540; Reserve; Boolean)
        {
            Caption = 'Reserve';

            trigger OnValidate()
            var
                ProdOrderCapNeed: Record "Prod. Order Capacity Need";
            begin
                GetItem;
                if Item.Reserve <> Item.Reserve::Optional then
                    TestField(Reserve, Item.Reserve = Item.Reserve::Always);
                if Reserve and
                   ("Demand Type" = DATABASE::"Prod. Order Component") and
                   ("Demand Subtype" = ProdOrderCapNeed.Status::Planned)
                then
                    Error(Text030);
                TestField("Planning Level", 0);
                TestField("Planning Line Origin", "Planning Line Origin"::"Order Planning");
            end;
        }
        field(5541; "Qty. per UOM (Demand)"; Decimal)
        {
            Caption = 'Qty. per UOM (Demand)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5542; "Unit Of Measure Code (Demand)"; Code[10])
        {
            Caption = 'Unit Of Measure Code (Demand)';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."));
        }
        field(5552; "Supply From"; Code[20])
        {
            Caption = 'Supply From';
            TableRelation = IF ("Replenishment System" = CONST(Purchase)) Vendor
            ELSE
            IF ("Replenishment System" = CONST(Transfer)) Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnLookup()
            var
                Vend: Record Vendor;
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        if LookupVendor(Vend, true) then
                            Validate("Supply From", Vend."No.");
                    "Replenishment System"::Transfer:
                        if LookupFromLocation(Location) then
                            Validate("Supply From", Location.Code);
                    else
                        OnLookupSupplyFromOnCaseReplenishmentSystemElse(Rec);
                end;
            end;

            trigger OnValidate()
            begin
                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        Validate("Vendor No.", "Supply From");
                    "Replenishment System"::Transfer:
                        Validate("Transfer-from Code", "Supply From");
                    else
                        OnValidateSupplyFromOnCaseReplenishmentSystemElse(Rec);
                end;
            end;
        }
        field(5553; "Original Item No."; Code[20])
        {
            Caption = 'Original Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(5554; "Original Variant Code"; Code[10])
        {
            Caption = 'Original Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Original Item No."));
        }
        field(5560; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(5563; "Demand Qty. Available"; Decimal)
        {
            Caption = 'Demand Qty. Available';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5590; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5701; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = IF (Type = CONST(Item)) "Item Category";
        }
        field(5702; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5703; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5705; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
            ObsoleteTag = '15.0';
        }
        field(5706; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                CheckActionMessageNew;
                "Supply From" := "Transfer-from Code";
            end;
        }
        field(5707; "Transfer Shipment Date"; Date)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Transfer Shipment Date';
            Editable = false;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7002; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(7100; "Blanket Purch. Order Exists"; Boolean)
        {
            CalcFormula = Exist ("Purchase Line" WHERE("Document Type" = CONST("Blanket Order"),
                                                       Type = CONST(Item),
                                                       "No." = FIELD("No."),
                                                       "Outstanding Quantity" = FILTER(<> 0)));
            Caption = 'Blanket Purch. Order Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7110; "Custom Sorting Order"; Code[50])
        {
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";

            trigger OnValidate()
            var
                RoutingHeader: Record "Routing Header";
                RoutingDate: Date;
            begin
                CheckActionMessageNew;
                "Routing Version Code" := '';

                if "Routing No." = '' then
                    exit;

                if CurrFieldNo = FieldNo("Starting Date") then
                    RoutingDate := "Starting Date"
                else
                    RoutingDate := "Ending Date";
                if RoutingDate = 0D then
                    RoutingDate := "Order Date";

                Validate("Routing Version Code", VersionMgt.GetRtngVersion("Routing No.", RoutingDate, true));
                if "Routing Version Code" = '' then begin
                    RoutingHeader.Get("Routing No.");
                    if PlanningResiliency and (RoutingHeader.Status <> RoutingHeader.Status::Certified) then
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(Text033, RoutingHeader.TableCaption, RoutingHeader.FieldCaption("No."), RoutingHeader."No."),
                          DATABASE::"Routing Header", RoutingHeader.GetPosition);
                    RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
                    "Routing Type" := RoutingHeader.Type;
                end;
            end;
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            TableRelation = "Prod. Order Routing Line"."Operation No." WHERE(Status = CONST(Released),
                                                                              "Prod. Order No." = FIELD("Prod. Order No."),
                                                                              "Routing No." = FIELD("Routing No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if "Operation No." = '' then
                    exit;

                TestField(Type, Type::Item);
                TestField("Prod. Order No.");
                TestField("Routing No.");

                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.", "Operation No.");

                ProdOrderRtngLine.TestField(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Due Date" := ProdOrderRtngLine."Ending Date";
                CheckDueDateToDemandDate;

                Validate("Work Center No.", ProdOrderRtngLine."No.");

                Validate("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                GetWorkCenter;
                Validate("Vendor No.", WorkCenter."Subcontractor No.");
            end;
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." WHERE(Status = CONST(Finished),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."));
        }
        field(99000755; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000756; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ReserveReqLine.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000757; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(99000882; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(99000883; "Gen. Business Posting Group"; Code[20])
        {
            Caption = 'Gen. Business Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(99000884; "Low-Level Code"; Integer)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(99000885; "Production BOM Version Code"; Code[20])
        {
            Caption = 'Production BOM Version Code';
            TableRelation = "Production BOM Version"."Version Code" WHERE("Production BOM No." = FIELD("Production BOM No."));

            trigger OnValidate()
            var
                ProdBOMVersion: Record "Production BOM Version";
            begin
                CheckActionMessageNew;
                if "Production BOM Version Code" = '' then
                    exit;

                ProdBOMVersion.Get("Production BOM No.", "Production BOM Version Code");
                if PlanningResiliency and (ProdBOMVersion.Status <> ProdBOMVersion.Status::Certified) then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(
                        Text034, ProdBOMVersion.TableCaption,
                        ProdBOMVersion.FieldCaption("Production BOM No."), ProdBOMVersion."Production BOM No.",
                        ProdBOMVersion.FieldCaption("Version Code"), ProdBOMVersion."Version Code"),
                      DATABASE::"Production BOM Version", ProdBOMVersion.GetPosition);
                ProdBOMVersion.TestField(Status, ProdBOMVersion.Status::Certified);
            end;
        }
        field(99000886; "Routing Version Code"; Code[20])
        {
            Caption = 'Routing Version Code';
            TableRelation = "Routing Version"."Version Code" WHERE("Routing No." = FIELD("Routing No."));

            trigger OnValidate()
            var
                RoutingVersion: Record "Routing Version";
            begin
                CheckActionMessageNew;
                if "Routing Version Code" = '' then
                    exit;

                RoutingVersion.Get("Routing No.", "Routing Version Code");
                if PlanningResiliency and (RoutingVersion.Status <> RoutingVersion.Status::Certified) then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(
                        Text034, RoutingVersion.TableCaption,
                        RoutingVersion.FieldCaption("Routing No."), RoutingVersion."Routing No.",
                        RoutingVersion.FieldCaption("Version Code"), RoutingVersion."Version Code"),
                      DATABASE::"Routing Version", RoutingVersion.GetPosition);
                RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
                "Routing Type" := RoutingVersion.Type;
            end;
        }
        field(99000887; "Routing Type"; Option)
        {
            Caption = 'Routing Type';
            OptionCaption = 'Serial,Parallel';
            OptionMembers = Serial,Parallel;
        }
        field(99000888; "Original Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000889; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(99000890; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(99000891; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
            Editable = false;
        }
        field(99000892; "Scrap %"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
        }
        field(99000894; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    GetWorkCenter;
                    if not Subcontracting then begin
                        Validate("Production BOM No.");
                        Validate("Routing No.");
                    end;
                    Validate("Starting Time");
                end;
            end;
        }
        field(99000895; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            var
                ShouldSetDueDate: Boolean;
            begin
                TestField(Type, Type::Item);
                if ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                    PlanningLineMgt.Recalculate(Rec, 0)
                else
                    CalcEndingDate('');

                CheckEndingDate(ValidateFields);

                ShouldSetDueDate := true;
                OnValidateStartingTimeOnBeforeSetDueDate(Rec, ShouldSetDueDate);
                if ShouldSetDueDate then
                    SetDueDate;

                SetActionMessage;
                UpdateDatetime;
            end;
        }
        field(99000896; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckEndingDate(ValidateFields);

                if Type = Type::Item then begin
                    Validate("Ending Time");
                    GetWorkCenter;
                    if not Subcontracting then begin
                        Validate("Production BOM No.");
                        Validate("Routing No.");
                    end;
                end;
            end;
        }
        field(99000897; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            var
                ShouldSetDueDate: Boolean;
            begin
                TestField(Type, Type::Item);
                if ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                    PlanningLineMgt.RecalculateWithOptionalModify(Rec, 1, false)
                else
                    CalcStartingDate('');

                ShouldSetDueDate := (CurrFieldNo in [FieldNo("Ending Date"), FieldNo("Ending Date-Time")]) and (CurrentFieldNo <> FieldNo("Due Date"));
                OnValidateEndingTimeOnBeforeSetDueDate(Rec, ShouldSetDueDate);
                if ShouldSetDueDate then
                    SetDueDate;

                SetActionMessage;
                if "Ending Time" = 0T then begin
                    MfgSetup.Get();
                    "Ending Time" := MfgSetup."Normal Ending Time";
                end;
                UpdateDatetime;
            end;
        }
        field(99000898; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            TableRelation = "Production BOM Header"."No.";

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
                BOMDate: Date;
            begin
                TestField(Type, Type::Item);
                CheckActionMessageNew;
                "Production BOM Version Code" := '';
                if "Production BOM No." = '' then
                    exit;

                if CurrFieldNo = FieldNo("Starting Date") then
                    BOMDate := "Starting Date"
                else begin
                    BOMDate := "Ending Date";
                    if BOMDate = 0D then
                        BOMDate := "Order Date";
                end;

                Validate("Production BOM Version Code", VersionMgt.GetBOMVersion("Production BOM No.", BOMDate, true));
                if "Production BOM Version Code" = '' then begin
                    ProdBOMHeader.Get("Production BOM No.");
                    if PlanningResiliency and (ProdBOMHeader.Status <> ProdBOMHeader.Status::Certified) then
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(
                            Text033,
                            ProdBOMHeader.TableCaption,
                            ProdBOMHeader.FieldCaption("No."), ProdBOMHeader."No."),
                          DATABASE::"Production BOM Header", ProdBOMHeader.GetPosition);

                    ProdBOMHeader.TestField(Status, ProdBOMHeader.Status::Certified);
                end;
            end;
        }
        field(99000899; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(99000900; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
        }
        field(99000901; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);
                TestField("No.");

                Item.Get("No.");
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text006,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    "Unit Cost" := Item."Unit Cost" * "Qty. per Unit of Measure";
                end;
                "Cost Amount" := Round("Unit Cost" * Quantity);
            end;
        }
        field(99000902; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
            MinValue = 0;
        }
        field(99000903; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';

            trigger OnValidate()
            var
                StockkeepingUnit: Record "Stockkeeping Unit";
            begin
                TestField(Type, Type::Item);
                CheckActionMessageNew;
                if ValidateFields and
                   ("Replenishment System" = xRec."Replenishment System") and
                   ("No." = xRec."No.") and
                   ("Location Code" = xRec."Location Code") and
                   ("Variant Code" = xRec."Variant Code")
                then
                    exit;

                TestField(Type, Type::Item);
                TestField("No.");
                GetItem;
                GetPlanningParameters.AtSKU(StockkeepingUnit, "No.", "Variant Code", "Location Code");
                if Subcontracting then
                    StockkeepingUnit."Replenishment System" := StockkeepingUnit."Replenishment System"::"Prod. Order";

                "Supply From" := '';

                case "Replenishment System" of
                    "Replenishment System"::Purchase:
                        SetReplenishmentSystemFromPurchase(StockkeepingUnit);
                    "Replenishment System"::"Prod. Order":
                        SetReplenishmentSystemFromProdOrder;
                    "Replenishment System"::Assembly:
                        SetReplenishmentSystemFromAssembly;
                    "Replenishment System"::Transfer:
                        SetReplenishmentSystemFromTransfer(StockkeepingUnit);
                    else
                        OnValidateReplenishmentSystemCaseElse(Rec);
                end;
            end;
        }
        field(99000904; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            Editable = false;
            TableRelation = IF ("Ref. Order Type" = CONST("Prod. Order")) "Production Order"."No." WHERE(Status = FIELD("Ref. Order Status"))
            ELSE
            IF ("Ref. Order Type" = CONST(Purchase)) "Purchase Header"."No." WHERE("Document Type" = CONST(Order))
            ELSE
            IF ("Ref. Order Type" = CONST(Transfer)) "Transfer Header"."No." WHERE("No." = FIELD("Ref. Order No."))
            ELSE
            IF ("Ref. Order Type" = CONST(Assembly)) "Assembly Header"."No." WHERE("Document Type" = CONST(Order));
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                PurchHeader: Record "Purchase Header";
                ProdOrder: Record "Production Order";
                TransHeader: Record "Transfer Header";
                AsmHeader: Record "Assembly Header";
            begin
                case "Ref. Order Type" of
                    "Ref. Order Type"::Purchase:
                        if PurchHeader.Get(PurchHeader."Document Type"::Order, "Ref. Order No.") then
                            PAGE.Run(PAGE::"Purchase Order", PurchHeader)
                        else
                            Message(Text007, PurchHeader.TableCaption);
                    "Ref. Order Type"::"Prod. Order":
                        if ProdOrder.Get("Ref. Order Status", "Ref. Order No.") then
                            case ProdOrder.Status of
                                ProdOrder.Status::Planned:
                                    PAGE.Run(PAGE::"Planned Production Order", ProdOrder);
                                ProdOrder.Status::"Firm Planned":
                                    PAGE.Run(PAGE::"Firm Planned Prod. Order", ProdOrder);
                                ProdOrder.Status::Released:
                                    PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                            end
                        else
                            Message(Text007, ProdOrder.TableCaption);
                    "Ref. Order Type"::Transfer:
                        if TransHeader.Get("Ref. Order No.") then
                            PAGE.Run(PAGE::"Transfer Order", TransHeader)
                        else
                            Message(Text007, TransHeader.TableCaption);
                    "Ref. Order Type"::Assembly:
                        if AsmHeader.Get("Ref. Order Status", "Ref. Order No.") then
                            PAGE.Run(PAGE::"Assembly Order", AsmHeader)
                        else
                            Message(Text007, AsmHeader.TableCaption);
                    else
                        Message(Text008);
                end;
            end;
        }
        field(99000905; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Transfer,Assembly';
            OptionMembers = " ",Purchase,"Prod. Order",Transfer,Assembly;
        }
        field(99000906; "Ref. Order Status"; Option)
        {
            BlankZero = true;
            Caption = 'Ref. Order Status';
            Editable = false;
            OptionCaption = ',Planned,Firm Planned,Released';
            OptionMembers = ,Planned,"Firm Planned",Released;
        }
        field(99000907; "Ref. Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ref. Line No.';
            Editable = false;
        }
        field(99000908; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(99000909; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Planning Routing Line"."Expected Operation Cost Amt." WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                                                                            "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                                                                            "Worksheet Line No." = FIELD("Line No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000910; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Planning Component"."Cost Amount" WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                                                        "Worksheet Batch Name" = FIELD("Journal Batch Name"),
                                                                        "Worksheet Line No." = FIELD("Line No.")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000911; "Finished Qty. (Base)"; Decimal)
        {
            Caption = 'Finished Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000912; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000913; "Related to Planning Line"; Integer)
        {
            Caption = 'Related to Planning Line';
            Editable = false;
        }
        field(99000914; "Planning Level"; Integer)
        {
            Caption = 'Planning Level';
            Editable = false;
        }
        field(99000915; "Planning Line Origin"; Option)
        {
            Caption = 'Planning Line Origin';
            Editable = false;
            OptionCaption = ' ,Action Message,Planning,Order Planning';
            OptionMembers = " ","Action Message",Planning,"Order Planning";
        }
        field(99000916; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';

            trigger OnValidate()
            begin
                if ("Action Message" = xRec."Action Message") or
                   (("Action Message" in ["Action Message"::" ", "Action Message"::New]) and
                    (xRec."Action Message" in ["Action Message"::" ", "Action Message"::New]))
                then
                    exit;
                TestField("Action Message", xRec."Action Message");
            end;
        }
        field(99000917; "Accept Action Message"; Boolean)
        {
            Caption = 'Accept Action Message';

            trigger OnValidate()
            begin
                if "Action Message" = "Action Message"::" " then
                    Validate("Action Message", "Action Message"::New);
            end;
        }
        field(99000918; "Net Quantity (Base)"; Decimal)
        {
            Caption = 'Net Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000919; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");

                Validate("Starting Date");
            end;
        }
        field(99000920; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");

                Validate("Ending Date");
            end;
        }
        field(99000921; "Order Promising ID"; Code[20])
        {
            Caption = 'Order Promising ID';
        }
        field(99000922; "Order Promising Line No."; Integer)
        {
            Caption = 'Order Promising Line No.';
        }
        field(99000923; "Order Promising Line ID"; Integer)
        {
            Caption = 'Order Promising Line ID';
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Worksheet Template Name", "Journal Batch Name", "Vendor No.", "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code", "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Location Code", "Transfer-from Code", "Purchasing Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key4; Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Order Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key5; Type, "No.", "Variant Code", "Location Code", "Starting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key6; "Worksheet Template Name", "Journal Batch Name", Type, "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.")
        {
        }
        key(Key8; "Replenishment System", Type, "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date")
        {
            MaintainSQLIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key9; "Order Promising ID", "Order Promising Line ID", "Order Promising Line No.")
        {
        }
        key(Key10; "User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
        }
        key(Key11; "User ID", "Demand Type", "Demand Subtype", "Demand Order No.", "Demand Line No.", "Demand Ref. No.")
        {
        }
        key(Key12; "User ID", "Worksheet Template Name", "Journal Batch Name", "Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key13; "Worksheet Template Name", "Journal Batch Name", "Custom Sorting Order")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ReqLine.Reset();
        ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.");
        while (ReqLine.Next <> 0) and (ReqLine.Level > Level) do
            ReqLine.Delete(true);

        ReserveReqLine.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);

        DeleteRelations;
    end;

    trigger OnInsert()
    var
        Rec2: Record "Requisition Line";
    begin
        if CurrentKey <> Rec2.CurrentKey then begin
            Rec2 := Rec;
            Rec2.SetRecFilter;
            Rec2.SetRange("Line No.");
            if Rec2.FindLast then
                "Line No." := Rec2."Line No." + 10000;
        end;

        ReserveReqLine.VerifyQuantity(Rec, xRec);

        ReqWkshTmpl.Get("Worksheet Template Name");
        ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        ReserveReqLine.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text004, TableCaption);
    end;

    var
        Text004: Label 'You cannot rename a %1.';
        Text005: Label '%1 %2 does not exist.';
        Text006: Label 'You cannot change %1 when %2 is %3.';
        Text007: Label 'There is no %1 for this line.';
        Text008: Label 'There is no replenishment order for this line.';
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        MfgSetup: Record "Manufacturing Setup";
        Location: Record Location;
        Bin: Record Bin;
        TempPlanningErrorLog: Record "Planning Error Log" temporary;
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        DimMgt: Codeunit DimensionManagement;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        VersionMgt: Codeunit VersionManagement;
        PlanningLineMgt: Codeunit "Planning Line Management";
        WMSManagement: Codeunit "WMS Management";
        CurrentFieldNo: Integer;
        BlockReservation: Boolean;
        Text028: Label 'The %1 on this %2 must match the %1 on the sales order line it is associated with.';
        Subcontracting: Boolean;
        Text029: Label 'Line %1 has a %2 that exceeds the %3.';
        Text030: Label 'You cannot reserve components with status Planned.';
        PlanningResiliency: Boolean;
        Text031: Label '%1 %2 is blocked.';
        Text032: Label '%1 %2 has no %3 defined.';
        Text033: Label '%1 %2 %3 is not certified.';
        Text034: Label '%1 %2 %3 %4 %5 is not certified.';
        Text035: Label '%1 %2 %3 specified on %4 %5 does not exist.';
        Text036: Label '%1 %2 %3 does not allow default numbering.';
        Text037: Label 'The currency exchange rate for the %1 %2 that vendor %3 uses on the order date %4, does not have an %5 specified.';
        Text038: Label 'The currency exchange rate for the %1 %2 that vendor %3 uses on the order date %4, does not exist.';
        Text039: Label 'You cannot assign new numbers from the number series %1 on %2.';
        Text040: Label 'You cannot assign new numbers from the number series %1.';
        Text041: Label 'You cannot assign new numbers from the number series %1 on a date before %2.';
        Text042: Label 'You cannot assign new numbers from the number series %1 line %2 because the %3 is not defined.';
        Text043: Label 'The number %1 on number series %2 cannot be extended to more than 20 characters.';
        Text044: Label 'You cannot assign numbers greater than %1 from the number series %2.';
        ReplenishmentErr: Label 'Requisition Worksheet cannot be used to create Prod. Order replenishment.';
        SourceDropShipment: Boolean;

    local procedure CalcBaseQty(Qty: Decimal): Decimal
    begin
        if "Prod. Order No." = '' then
            TestField("Qty. per Unit of Measure");
        exit(Round(Qty * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    local procedure CopyFromGLAcc()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc;
        GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
    end;

    local procedure CopyFromItem()
    begin
        GetItem;
        OnBeforeCopyFromItem(Rec, Item, xRec, CurrFieldNo, TempPlanningErrorLog, PlanningResiliency);

        if PlanningResiliency and Item.Blocked then
            TempPlanningErrorLog.SetError(
              StrSubstNo(Text031, Item.TableCaption, Item."No."),
              DATABASE::Item, Item.GetPosition);
        Item.TestField(Blocked, false);
        "Low-Level Code" := Item."Low-Level Code";
        "Scrap %" := Item."Scrap %";
        "Item Category Code" := Item."Item Category Code";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := '';
        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(Text032, Item.TableCaption, Item."No.",
                Item.FieldCaption("Base Unit of Measure")),
              DATABASE::Item, Item.GetPosition);
        Item.TestField("Base Unit of Measure");
        "Indirect Cost %" := Item."Indirect Cost %";
        UpdateReplenishmentSystem();
        "Accept Action Message" := true;
        GetDirectCost(FieldNo("No."));
        SetFromBinCode;

        OnAfterCopyFromItem(Rec, Item);
    end;

    local procedure GetItem()
    begin
        TestField("No.");
        if "No." <> Item."No." then
            Item.Get("No.");
    end;

    procedure ShowReservation()
    var
        ReservationPage: Page Reservation;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        Clear(ReservationPage);
        ReservationPage.SetReservSource(Rec);
        ReservationPage.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    local procedure UpdateOrderReceiptDate(LeadTimeCalc: DateFormula)
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateOrderReceiptDate(Rec, LeadTimeCalc, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        if "Reserved Qty. (Base)" = 0 then begin
            if "Order Date" <> 0D then
                "Starting Date" := "Order Date"
            else begin
                "Starting Date" := WorkDate;
                "Order Date" := "Starting Date";
            end;
            CalcEndingDate(Format(LeadTimeCalc));
            CheckEndingDate(ValidateFields);
            SetDueDate;
        end else
            if (Format(LeadTimeCalc) = '') or ("Due Date" = 0D) then
                "Order Date" := 0D
            else
                if "Due Date" <> 0D then begin
                    "Ending Date" :=
                      LeadTimeMgt.PlannedEndingDate(
                        "No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type");
                    CalcStartingDate(Format(LeadTimeCalc));
                end;

        SetActionMessage;
        UpdateDatetime;
    end;

    procedure LookupVendor(var Vend: Record Vendor; PreferItemVendorCatalog: Boolean): Boolean
    var
        ItemVend: Record "Item Vendor";
        LookupThroughItemVendorCatalog: Boolean;
        IsHandled: Boolean;
        IsVendorSelected: Boolean;
    begin
        IsHandled := false;
        IsVendorSelected := false;
        OnBeforeLookupVendor(Rec, Vend, PreferItemVendorCatalog, IsHandled, IsVendorSelected);
        if IsHandled then
            exit(IsVendorSelected);

        if (Type = Type::Item) and ItemVend.ReadPermission then begin
            ItemVend.Init();
            ItemVend.SetRange("Item No.", "No.");
            ItemVend.SetRange("Vendor No.", "Vendor No.");
            if "Variant Code" <> '' then
                ItemVend.SetRange("Variant Code", "Variant Code");
            if not ItemVend.FindLast then begin
                ItemVend."Item No." := "No.";
                ItemVend."Variant Code" := "Variant Code";
                ItemVend."Vendor No." := "Vendor No.";
            end;
            ItemVend.SetRange("Vendor No.");
            LookupThroughItemVendorCatalog := not ItemVend.IsEmpty or PreferItemVendorCatalog;
        end;

        if LookupThroughItemVendorCatalog then begin
            if PAGE.RunModal(0, ItemVend) = ACTION::LookupOK then
                exit(Vend.Get(ItemVend."Vendor No."));
        end else begin
            Vend."No." := "Vendor No.";
            exit(PAGE.RunModal(0, Vend) = ACTION::LookupOK);
        end;
    end;

    local procedure LookupFromLocation(var Location: Record Location): Boolean
    begin
        Location.Code := "Transfer-from Code";
        Location.SetRange("Use As In-Transit", false);
        exit(PAGE.RunModal(0, Location) = ACTION::LookupOK);
    end;

    procedure UpdateDescription()
    var
        Vend: Record Vendor;
        ItemCrossRef: Record "Item Cross Reference";
        ItemTranslation: Record "Item Translation";
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        OnBeforeUpdateDescription(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;
        if (Type <> Type::Item) or ("No." = '') then
            exit;
        if "Variant Code" = '' then begin
            GetItem;
            Description := Item.Description;
            "Description 2" := Item."Description 2";
            OnUpdateDescriptionFromItem(Rec, Item);
        end else begin
            ItemVariant.Get("No.", "Variant Code");
            Description := ItemVariant.Description;
            "Description 2" := ItemVariant."Description 2";
            OnUpdateDescriptionFromItemVariant(Rec, ItemVariant);
        end;

        if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then begin
            Description := SalesLine.Description;
            "Description 2" := SalesLine."Description 2";
            OnUpdateDescriptionFromSalesLine(Rec, SalesLine);
        end;

        if "Vendor No." <> '' then
            if not ItemCrossRef.GetItemDescription(
                 Description, "Description 2", "No.", "Variant Code", "Unit of Measure Code",
                 ItemCrossRef."Cross-Reference Type"::Vendor, "Vendor No.")
            then begin
                Vend.Get("Vendor No.");
                if Vend."Language Code" <> '' then
                    if ItemTranslation.Get("No.", "Variant Code", Vend."Language Code") then begin
                        Description := ItemTranslation.Description;
                        "Description 2" := ItemTranslation."Description 2";
                        OnUpdateDescriptionFromItemTranslation(Rec, ItemTranslation);
                    end;
            end;
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        ReserveReqLine.Block(SetBlock);
    end;

    procedure BlockDynamicTrackingOnComp(SetBlock: Boolean)
    begin
        BlockReservation := SetBlock;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Purchases, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if "Ref. Order No." <> '' then
            GetDimFromRefOrderLine(true);

        OnAfterCreateDim(Rec, xRec);
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

    procedure OpenItemTrackingLines()
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        ReserveReqLine.CallItemTracking(Rec);
    end;

    procedure DeleteRelations()
    var
        PlanningComponent: Record "Planning Component";
        PlanningRtngLine: Record "Planning Routing Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        if Type <> Type::Item then
            exit;

        PlanningComponent.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", "Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", "Line No.");
        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent.BlockDynamicTracking(BlockReservation);
                PlanningComponent.Delete(true);
            until PlanningComponent.Next = 0;

        PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", "Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", "Line No.");
        if not PlanningRtngLine.IsEmpty then
            PlanningRtngLine.DeleteAll();

        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", "Journal Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", "Line No.");
        if not ProdOrderCapNeed.IsEmpty then
            ProdOrderCapNeed.DeleteAll();

        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetCurrentKey(Status, "Prod. Order No.", Active);
        ProdOrderCapNeed.SetRange(Status, "Ref. Order Status");
        ProdOrderCapNeed.SetRange("Prod. Order No.", "Ref. Order No.");
        ProdOrderCapNeed.SetRange(Active, false);
        if not ProdOrderCapNeed.IsEmpty then
            ProdOrderCapNeed.ModifyAll(Active, true);

        UntrackedPlanningElement.SetRange("Worksheet Template Name", "Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", "Journal Batch Name");
        UntrackedPlanningElement.SetRange("Worksheet Line No.", "Line No.");
        if not UntrackedPlanningElement.IsEmpty then
            UntrackedPlanningElement.DeleteAll();

        OnAfterDeleteRelations(Rec);
    end;

    procedure DeleteMultiLevel()
    var
        ReqLine2: Record "Requisition Line";
    begin
        ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        ReqLine2.SetRange("Ref. Order Type", "Ref. Order Type");
        ReqLine2.SetRange("Ref. Order Status", "Ref. Order Status");
        ReqLine2.SetRange("Ref. Order No.", "Ref. Order No.");
        ReqLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ReqLine2.SetRange("Journal Batch Name", "Journal Batch Name");
        ReqLine2.SetFilter("Line No.", '<>%1', "Line No.");
        ReqLine2.SetFilter("Planning Level", '>0');
        if ReqLine2.Find('-') then
            repeat
                ReserveReqLine.DeleteLine(ReqLine2);
                ReqLine2.CalcFields("Reserved Qty. (Base)");
                ReqLine2.TestField("Reserved Qty. (Base)", 0);
                ReqLine2.DeleteRelations;
                ReqLine2.Delete();
            until ReqLine2.Next = 0;
    end;

    procedure SetUpNewLine(LastReqLine: Record "Requisition Line")
    var
        Vendor: Record Vendor;
    begin
        ReqWkshTmpl.Get("Worksheet Template Name");
        ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ReqLine.Find('-') then begin
            "Order Date" := LastReqLine."Order Date";
        end else
            "Order Date" := WorkDate;

        "Recurring Method" := LastReqLine."Recurring Method";
        "Price Calculation Method" := Vendor.GetPriceCalculationMethod();
    end;

    local procedure CheckEndingDate(ShowWarning: Boolean)
    var
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEndingDate(Rec, ShowWarning, IsHandled);
        if IsHandled then
            exit;

        CheckDateConflict.ReqLineCheck(Rec, ShowWarning);
        ReserveReqLine.VerifyChange(Rec, xRec);
    end;

    procedure SetDueDate()
    begin
        if "Ending Date" = 0D then
            exit;
        if (Type = Type::Item) and
           ("Planning Level" = 0)
        then
            "Due Date" :=
              LeadTimeMgt.PlannedDueDate("No.", "Location Code", "Variant Code", "Ending Date", '', "Ref. Order Type")
        else
            "Due Date" := "Ending Date";

        CheckDueDateToDemandDate;
    end;

    procedure SetCurrFieldNo(NewCurrFieldNo: Integer)
    begin
        CurrentFieldNo := NewCurrFieldNo;
    end;

    local procedure CheckDueDateToDemandDate()
    begin
        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and
           ("Due Date" > "Demand Date") and
           ("Demand Date" <> 0D) and
           ValidateFields
        then
            Message(Text029, "Line No.", FieldCaption("Due Date"), FieldCaption("Demand Date"));
    end;

    local procedure CheckActionMessageNew()
    begin
        if "Action Message" <> "Action Message"::" " then
            if CurrFieldNo in [FieldNo(Type),
                               FieldNo("No."),
                               FieldNo("Variant Code"),
                               FieldNo("Location Code"),
                               FieldNo("Bin Code"),
                               FieldNo("Production BOM Version Code"),
                               FieldNo("Routing Version Code"),
                               FieldNo("Production BOM No."),
                               FieldNo("Routing No."),
                               FieldNo("Replenishment System"),
                               FieldNo("Unit of Measure Code"),
                               FieldNo("Vendor No."),
                               FieldNo("Transfer-from Code")]
            then
                TestField("Action Message", "Action Message"::New);
    end;

    procedure SetActionMessage()
    begin
        if ValidateFields and
           ("Action Message" <> "Action Message"::" ") and
           ("Action Message" <> "Action Message"::New)
        then begin
            if (Quantity <> xRec.Quantity) and ("Original Quantity" = 0) then
                "Original Quantity" := xRec.Quantity;
            if ("Due Date" <> xRec."Due Date") and ("Original Due Date" = 0D) then
                "Original Due Date" := xRec."Due Date";
            if Quantity = 0 then
                "Action Message" := "Action Message"::Cancel
            else
                if "Original Quantity" <> 0 then
                    if "Original Due Date" <> 0D then
                        "Action Message" := "Action Message"::"Resched. & Chg. Qty."
                    else
                        "Action Message" := "Action Message"::"Change Qty."
                else
                    if "Original Due Date" <> 0D then
                        "Action Message" := "Action Message"::Reschedule;

            if "Action Message" <> xRec."Action Message" then
                Clear("Planning Line Origin");
        end;
    end;

    local procedure ValidateFields(): Boolean
    begin
        exit((CurrFieldNo <> 0) or (CurrentFieldNo <> 0));
    end;

    procedure GetProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        Item.Get(ProdOrderLine."Item No.");

        TransferFromProdOrderLine(ProdOrderLine);
    end;

    procedure GetPurchOrderLine(PurchOrderLine: Record "Purchase Line")
    var
        PurchHeader2: Record "Purchase Header";
    begin
        if PurchOrderLine.Type <> PurchOrderLine.Type::Item then
            exit;
        PurchOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        PurchHeader2.Get(PurchOrderLine."Document Type", PurchOrderLine."Document No.");
        Item.Get(PurchOrderLine."No.");

        TransferFromPurchaseLine(PurchOrderLine);
    end;

    procedure GetTransLine(TransLine: Record "Transfer Line")
    var
        TransHeader: Record "Transfer Header";
    begin
        TransLine.CalcFields(
          "Reserved Quantity Inbnd.",
          "Reserved Quantity Outbnd.",
          "Reserved Qty. Inbnd. (Base)",
          "Reserved Qty. Outbnd. (Base)");
        TransHeader.Get(TransLine."Document No.");
        Item.Get(TransLine."Item No.");

        TransferFromTransLine(TransLine);
    end;

    procedure GetAsmHeader(AsmHeader: Record "Assembly Header")
    var
        AsmHeader2: Record "Assembly Header";
    begin
        AsmHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        AsmHeader2.Get(AsmHeader."Document Type", AsmHeader."No.");
        Item.Get(AsmHeader."Item No.");

        TransferFromAsmHeader(AsmHeader);
    end;

    procedure GetActionMessages()
    var
        GetActionMsgReport: Report "Get Action Messages";
    begin
        GetActionMsgReport.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name");
        GetActionMsgReport.RunModal;
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := 0;
        RemainingQtyBase := "Net Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := Quantity;
        QtyToReserveBase := "Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Worksheet Template Name", "Journal Batch Name", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Requisition Line", 0, "Worksheet Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Requisition Line", 0, "Worksheet Template Name", "Line No.", false);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);

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

    procedure SetRefFilter(RefOrderType: Option; RefOrderStatus: Option; RefOrderNo: Code[20]; RefLineNo: Integer)
    begin
        SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        SetRange("Ref. Order Type", RefOrderType);
        SetRange("Ref. Order Status", RefOrderStatus);
        SetRange("Ref. Order No.", RefOrderNo);
        SetRange("Ref. Line No.", RefLineNo);
    end;

    procedure TransferFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");

        Type := Type::Item;
        "No." := ProdOrderLine."Item No.";
        "Variant Code" := ProdOrderLine."Variant Code";
        Description := ProdOrderLine.Description;
        "Description 2" := ProdOrderLine."Description 2";
        "Location Code" := ProdOrderLine."Location Code";
        "Dimension Set ID" := ProdOrderLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := ProdOrderLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ProdOrderLine."Shortcut Dimension 2 Code";
        "Bin Code" := ProdOrderLine."Bin Code";
        "Gen. Prod. Posting Group" := ProdOrder."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        "Scrap %" := ProdOrderLine."Scrap %";
        "Order Date" := ProdOrder."Creation Date";
        "Starting Time" := ProdOrderLine."Starting Time";
        "Starting Date" := ProdOrderLine."Starting Date";
        "Ending Time" := ProdOrderLine."Ending Time";
        "Ending Date" := ProdOrderLine."Ending Date";
        "Due Date" := ProdOrderLine."Due Date";
        "Production BOM No." := ProdOrderLine."Production BOM No.";
        "Routing No." := ProdOrderLine."Routing No.";
        "Production BOM Version Code" := ProdOrderLine."Production BOM Version Code";
        "Routing Version Code" := ProdOrderLine."Routing Version Code";
        "Routing Type" := ProdOrderLine."Routing Type";
        "Replenishment System" := "Replenishment System"::"Prod. Order";
        Quantity := ProdOrderLine.Quantity;
        "Finished Quantity" := ProdOrderLine."Finished Quantity";
        "Remaining Quantity" := ProdOrderLine."Remaining Quantity";
        "Unit Cost" := ProdOrderLine."Unit Cost";
        "Cost Amount" := ProdOrderLine."Cost Amount";
        "Low-Level Code" := ProdOrder."Low-Level Code";
        "Planning Level" := ProdOrderLine."Planning Level Code";
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        "Quantity (Base)" := ProdOrderLine."Quantity (Base)";
        "Finished Qty. (Base)" := ProdOrderLine."Finished Qty. (Base)";
        "Remaining Qty. (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        "Indirect Cost %" := ProdOrderLine."Indirect Cost %";
        "Overhead Rate" := ProdOrderLine."Overhead Rate";
        "Expected Operation Cost Amt." := ProdOrderLine."Expected Operation Cost Amt.";
        "Expected Component Cost Amt." := ProdOrderLine."Expected Component Cost Amt.";
        "MPS Order" := ProdOrderLine."MPS Order";
        "Planning Flexibility" := ProdOrderLine."Planning Flexibility";
        "Ref. Order No." := ProdOrderLine."Prod. Order No.";
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order Status" := ProdOrderLine.Status;
        "Ref. Line No." := ProdOrderLine."Line No.";

        OnAfterTransferFromProdOrderLine(Rec, ProdOrderLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure TransferFromPurchaseLine(var PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        Item.Get(PurchLine."No.");

        Type := Type::Item;
        "No." := PurchLine."No.";
        "Variant Code" := PurchLine."Variant Code";
        Description := PurchLine.Description;
        "Description 2" := PurchLine."Description 2";
        "Location Code" := PurchLine."Location Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Bin Code" := PurchLine."Bin Code";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Order Date" := PurchHeader."Order Date";
        "Starting Date" := "Order Date";
        "Ending Date" := PurchLine."Planned Receipt Date";
        "Due Date" := PurchLine."Expected Receipt Date";
        Quantity := PurchLine.Quantity;
        "Finished Quantity" := PurchLine."Quantity Received";
        "Remaining Quantity" := PurchLine."Outstanding Quantity";
        BlockDynamicTracking(true);
        Validate("Unit Cost", PurchLine."Unit Cost (LCY)");
        BlockDynamicTracking(false);
        "Indirect Cost %" := PurchLine."Indirect Cost %";
        "Overhead Rate" := PurchLine."Overhead Rate";
        "Unit of Measure Code" := PurchLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
        "Quantity (Base)" := PurchLine."Quantity (Base)";
        "Finished Qty. (Base)" := PurchLine."Qty. Received (Base)";
        "Remaining Qty. (Base)" := PurchLine."Outstanding Qty. (Base)";
        "Routing No." := PurchLine."Routing No.";
        "Replenishment System" := "Replenishment System"::Purchase;
        "MPS Order" := PurchLine."MPS Order";
        "Planning Flexibility" := PurchLine."Planning Flexibility";
        "Ref. Order No." := PurchLine."Document No.";
        "Ref. Order Type" := "Ref. Order Type"::Purchase;
        "Ref. Line No." := PurchLine."Line No.";
        "Vendor No." := PurchLine."Buy-from Vendor No.";

        OnAfterTransferFromPurchaseLine(Rec, PurchLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure TransferFromAsmHeader(var AsmHeader: Record "Assembly Header")
    begin
        Item.Get(AsmHeader."Item No.");

        Type := Type::Item;
        "No." := AsmHeader."Item No.";
        "Variant Code" := AsmHeader."Variant Code";
        Description := AsmHeader.Description;
        "Description 2" := AsmHeader."Description 2";
        "Location Code" := AsmHeader."Location Code";
        "Dimension Set ID" := AsmHeader."Dimension Set ID";
        "Shortcut Dimension 1 Code" := AsmHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := AsmHeader."Shortcut Dimension 2 Code";
        "Bin Code" := AsmHeader."Bin Code";
        "Gen. Prod. Posting Group" := AsmHeader."Gen. Prod. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Order Date" := AsmHeader."Due Date";
        "Starting Date" := "Order Date";
        "Ending Date" := AsmHeader."Due Date";
        "Due Date" := AsmHeader."Due Date";
        Quantity := AsmHeader.Quantity;
        "Finished Quantity" := AsmHeader."Assembled Quantity";
        "Remaining Quantity" := AsmHeader."Remaining Quantity";
        BlockDynamicTracking(true);
        Validate("Unit Cost", AsmHeader."Unit Cost");
        BlockDynamicTracking(false);
        "Indirect Cost %" := AsmHeader."Indirect Cost %";
        "Overhead Rate" := AsmHeader."Overhead Rate";
        "Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        "Qty. per Unit of Measure" := AsmHeader."Qty. per Unit of Measure";
        "Quantity (Base)" := AsmHeader."Quantity (Base)";
        "Finished Qty. (Base)" := AsmHeader."Assembled Quantity (Base)";
        "Remaining Qty. (Base)" := AsmHeader."Remaining Quantity (Base)";
        "Replenishment System" := "Replenishment System"::Assembly;
        "MPS Order" := AsmHeader."MPS Order";
        "Planning Flexibility" := AsmHeader."Planning Flexibility";
        "Ref. Order Type" := "Ref. Order Type"::Assembly;
        "Ref. Order Status" := AsmHeader."Document Type";
        "Ref. Order No." := AsmHeader."No.";
        "Ref. Line No." := 0;

        OnAfterTransferFromAsmHeader(Rec, AsmHeader);

        GetDimFromRefOrderLine(false);
    end;

    procedure TransferFromTransLine(var TransLine: Record "Transfer Line")
    var
        TransHeader: Record "Transfer Header";
    begin
        TransHeader.Get(TransLine."Document No.");
        Item.Get(TransLine."Item No.");
        Type := Type::Item;
        "No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        Description := TransLine.Description;
        "Description 2" := TransLine."Description 2";
        "Location Code" := TransLine."Transfer-to Code";
        "Dimension Set ID" := TransLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        "Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        "Low-Level Code" := Item."Low-Level Code";
        "Starting Date" := CalcDate(TransLine."Outbound Whse. Handling Time", TransLine."Shipment Date");
        "Ending Date" := CalcDate(TransLine."Shipping Time", "Starting Date");
        "Due Date" := TransLine."Receipt Date";
        Quantity := TransLine.Quantity;
        "Finished Quantity" := TransLine."Quantity Received";
        "Remaining Quantity" := TransLine."Outstanding Quantity";
        BlockDynamicTracking(false);
        "Unit of Measure Code" := TransLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        "Quantity (Base)" := TransLine."Quantity (Base)";
        "Finished Qty. (Base)" := TransLine."Qty. Received (Base)";
        "Remaining Qty. (Base)" := TransLine."Outstanding Qty. (Base)";
        "Replenishment System" := "Replenishment System"::Transfer;
        "Ref. Order No." := TransLine."Document No.";
        "Ref. Order Type" := "Ref. Order Type"::Transfer;
        "Ref. Line No." := TransLine."Line No.";
        "Transfer-from Code" := TransLine."Transfer-from Code";
        "Transfer Shipment Date" := TransLine."Shipment Date";

        OnAfterTransferFromTransLine(Rec, TransLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure GetDimFromRefOrderLine(AddToExisting: Boolean)
    var
        PurchLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
        TransferLine: Record "Transfer Line";
        AsmHeader: Record "Assembly Header";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
    begin
        if AddToExisting then begin
            i := 1;
            DimSetIDArr[i] := "Dimension Set ID";
        end;
        i := i + 1;

        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                begin
                    if PurchLine.Get(PurchLine."Document Type"::Order, "Ref. Order No.", "Ref. Line No.") then
                        DimSetIDArr[i] := PurchLine."Dimension Set ID"
                end;
            "Ref. Order Type"::"Prod. Order":
                begin
                    if ProdOrderLine.Get("Ref. Order Status", "Ref. Order No.", "Ref. Line No.") then
                        DimSetIDArr[i] := ProdOrderLine."Dimension Set ID"
                end;
            "Ref. Order Type"::Transfer:
                begin
                    if TransferLine.Get("Ref. Order No.", "Ref. Line No.") then
                        DimSetIDArr[i] := TransferLine."Dimension Set ID"
                end;
            "Ref. Order Type"::Assembly:
                begin
                    if AsmHeader.Get(AsmHeader."Document Type"::Order, "Ref. Order No.") then
                        DimSetIDArr[i] := AsmHeader."Dimension Set ID"
                end;
        end;
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure TransferFromActionMessage(var ActionMessageEntry: Record "Action Message Entry")
    var
        ReservEntry: Record "Reservation Entry";
        EndDate: Date;
    begin
        if not ReservEntry.Get(ActionMessageEntry."Reservation Entry", true) then
            ReservEntry.Get(ActionMessageEntry."Reservation Entry", false);
        BlockDynamicTracking(true);
        Type := Type::Item;
        Validate("No.", ReservEntry."Item No.");
        BlockDynamicTracking(false);
        Validate("Variant Code", ReservEntry."Variant Code");
        Validate("Location Code", ReservEntry."Location Code");
        Description := ReservEntry.Description;

        if ReservEntry.Positive then
            EndDate := ReservEntry."Expected Receipt Date"
        else
            EndDate := ReservEntry."Shipment Date";

        if EndDate <> 0D then
            "Due Date" := EndDate
        else
            "Due Date" := WorkDate;

        case ReservEntry."Source Type" of
            DATABASE::"Transfer Line",
          DATABASE::"Prod. Order Line",
          DATABASE::"Purchase Line",
          DATABASE::"Requisition Line",
          DATABASE::"Assembly Header":
                "Ending Date" :=
                  LeadTimeMgt.PlannedEndingDate(
                    ReservEntry."Item No.", ReservEntry."Location Code", ReservEntry."Variant Code",
                    "Due Date", "Vendor No.", "Ref. Order Type");
        end;
    end;

    procedure TransferToTrackingEntry(var TrkgReservEntry: Record "Reservation Entry"; PointerOnly: Boolean)
    begin
        TrkgReservEntry.SetSource(
          DATABASE::"Requisition Line", 0, "Worksheet Template Name", "Line No.", "Journal Batch Name", 0);
        if PointerOnly then
            exit;

        TrkgReservEntry."Item No." := "No.";
        TrkgReservEntry."Location Code" := "Location Code";
        TrkgReservEntry.Description := '';
        TrkgReservEntry."Creation Date" := Today;
        TrkgReservEntry."Created By" := UserId;
        TrkgReservEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        TrkgReservEntry."Variant Code" := "Variant Code";
        CalcFields("Reserved Quantity");
        TrkgReservEntry.Quantity := "Remaining Quantity" - "Reserved Quantity";
        TrkgReservEntry."Quantity (Base)" := TrkgReservEntry.Quantity * TrkgReservEntry."Qty. per Unit of Measure";
        TrkgReservEntry.Positive := TrkgReservEntry."Quantity (Base)" > 0;
        if "Planning Level" > 0 then
            TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Reservation
        else
            TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Tracking;
        if TrkgReservEntry.Positive then
            TrkgReservEntry."Expected Receipt Date" := "Due Date"
        else
            TrkgReservEntry."Shipment Date" := "Due Date";

        OnAfterTransferToTrackingEntry(TrkgReservEntry, Rec);
    end;

    procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
    end;

    procedure GetDirectCost(CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculation: Interface "Price Calculation";
        PriceType: enum "Price Type";
        Line: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDirectCost(Rec, xRec, CalledByFieldNo, CurrFieldNo, Subcontracting, IsHandled);
        if IsHandled then
            exit;

        GetWorkCenter;
        if ("Replenishment System" = "Replenishment System"::Purchase) and not Subcontracting then begin
            RequisitionLinePrice.SetLine(PriceType::Purchase, Rec);
            PriceCalculationMgt.GetHandler(RequisitionLinePrice, PriceCalculation);
            PriceCalculation.ApplyDiscount();
            PriceCalculation.ApplyPrice(CalledByFieldNo);
            PriceCalculation.GetLine(Line);
            Rec := Line;
        end;

        OnAfterGetDirectCost(Rec, CalledByFieldNo);
    end;

    local procedure ValidateLocationChange()
    var
        Purchasing: Record Purchasing;
        SalesOrderLine: Record "Sales Line";
    begin
        case true of
            "Location Code" = xRec."Location Code":
                exit;
            "Purchasing Code" = '':
                exit;
            not Purchasing.Get("Purchasing Code"):
                exit;
            not Purchasing."Special Order":
                exit;
            not SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No."):
                exit;
            "Location Code" = SalesOrderLine."Location Code":
                exit;
        end;

        Error(Text028, FieldCaption("Location Code"), TableCaption);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(
            DATABASE::"Requisition Line", 0, "Worksheet Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    procedure CalcEndingDate(LeadTime: Code[20])
    begin
        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if LeadTime = '' then
                    LeadTime := LeadTimeMgt.PurchaseLeadTime("No.", "Location Code", "Variant Code", "Vendor No.");
            "Ref. Order Type"::"Prod. Order",
            "Ref. Order Type"::Assembly:
                begin
                    if RoutingLineExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::Transfer:
                CalcTransferShipmentDate;
            else
                exit;
        end;

        "Ending Date" :=
          LeadTimeMgt.PlannedEndingDate(
            "No.", "Location Code", "Variant Code", "Vendor No.", LeadTime, "Ref. Order Type", "Starting Date");
    end;

    procedure CalcStartingDate(LeadTime: Code[20])
    begin
        case "Ref. Order Type" of
            "Ref. Order Type"::Purchase:
                if LeadTime = '' then
                    LeadTime :=
                      LeadTimeMgt.PurchaseLeadTime(
                        "No.", "Location Code", "Variant Code", "Vendor No.");
            "Ref. Order Type"::"Prod. Order",
            "Ref. Order Type"::Assembly:
                begin
                    if RoutingLineExists then
                        exit;

                    if LeadTime = '' then
                        LeadTime := LeadTimeMgt.ManufacturingLeadTime("No.", "Location Code", "Variant Code");
                end;
            "Ref. Order Type"::" ":
                exit;
        end;

        "Starting Date" :=
          LeadTimeMgt.PlannedStartingDate(
            "No.", "Location Code", "Variant Code", "Vendor No.", LeadTime, "Ref. Order Type", "Ending Date");

        Validate("Order Date", "Starting Date");

        if "Ref. Order Type" = "Ref. Order Type"::Transfer then
            CalcTransferShipmentDate;
    end;

    local procedure CalcTransferShipmentDate()
    var
        TransferRoute: Record "Transfer Route";
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, LeadTimeMgt.WhseOutBoundHandlingTime("Transfer-from Code"));
        TransferRoute.CalcShipmentDateBackward("Transfer Shipment Date", "Starting Date", DateFormula, "Transfer-from Code");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if Bin.Code <> BinCode then
                Bin.Get(LocationCode, BinCode);
    end;

    procedure SetSubcontracting(IsSubcontracting: Boolean)
    begin
        Subcontracting := IsSubcontracting;
    end;

    procedure TransferFromUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
        Init;
        "Line No." := "Line No." + 10000;
        "Planning Line Origin" := "Planning Line Origin"::"Order Planning";

        Type := Type::Item;
        "No." := UnplannedDemand."Item No.";
        "Location Code" := UnplannedDemand."Location Code";
        "Bin Code" := UnplannedDemand."Bin Code";
        Validate("No.");
        Validate("Variant Code", UnplannedDemand."Variant Code");
        UpdateDescription;
        "Unit Of Measure Code (Demand)" := UnplannedDemand."Unit of Measure Code";
        "Qty. per UOM (Demand)" := UnplannedDemand."Qty. per Unit of Measure";
        Reserve := UnplannedDemand.Reserve;

        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Sales:
                "Demand Type" := DATABASE::"Sales Line";
            UnplannedDemand."Demand Type"::Production:
                "Demand Type" := DATABASE::"Prod. Order Component";
            UnplannedDemand."Demand Type"::Service:
                "Demand Type" := DATABASE::"Service Line";
            UnplannedDemand."Demand Type"::Job:
                "Demand Type" := DATABASE::"Job Planning Line";
            UnplannedDemand."Demand Type"::Assembly:
                "Demand Type" := DATABASE::"Assembly Line";
        end;
        "Demand Subtype" := UnplannedDemand."Demand SubType";
        "Demand Order No." := UnplannedDemand."Demand Order No.";
        "Demand Line No." := UnplannedDemand."Demand Line No.";
        "Demand Ref. No." := UnplannedDemand."Demand Ref. No.";

        Status := UnplannedDemand.Status;

        Level := 1;
        "Action Message" := ReqLine."Action Message"::New;
        "User ID" := UserId;

        OnAfterTransferFromUnplannedDemand(Rec, UnplannedDemand);
    end;

    procedure SetSupplyDates(DemandDate: Date)
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        "Demand Date" := DemandDate;
        "Starting Date" := "Demand Date";
        "Order Date" := "Demand Date";
        Validate("Due Date", "Demand Date");

        if "Planning Level" = 0 then begin
            Validate(
              "Ending Date",
              LeadTimeMgt.PlannedEndingDate(
                "No.", "Location Code", "Variant Code", "Due Date", '', "Ref. Order Type"));
            if ("Replenishment System" = "Replenishment System"::"Prod. Order") and ("Starting Time" = 0T) then begin
                MfgSetup.Get();
                "Starting Time" := MfgSetup."Normal Starting Time";
            end;
        end else begin
            Validate("Ending Date", "Due Date");
            Validate("Ending Time", 0T);
        end;
    end;

    procedure SetSupplyQty(DemandQtyBase: Decimal; NeededQtyBase: Decimal)
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;

        "Demand Quantity" := Round(DemandQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        "Demand Quantity (Base)" := DemandQtyBase;
        "Needed Quantity" := Round(NeededQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        if "Needed Quantity" < NeededQtyBase / "Qty. per Unit of Measure" then
            "Needed Quantity" := Round(NeededQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision, '>');
        "Needed Quantity (Base)" := NeededQtyBase;
        "Demand Qty. Available" :=
          Round((DemandQtyBase - NeededQtyBase) / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        Validate(Quantity, "Needed Quantity");
    end;

    procedure SetResiliencyOn(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        PlanningResiliency := true;
        TempPlanningErrorLog.SetJnlBatch(WkshTemplName, JnlBatchName, ItemNo);
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        exit(TempPlanningErrorLog.GetError(PlanningErrorLog));
    end;

    procedure SetResiliencyError(TheError: Text[250]; TheTableID: Integer; TheTablePosition: Text[250])
    begin
        TempPlanningErrorLog.SetError(TheError, TheTableID, TheTablePosition);
    end;

    local procedure CheckExchRate(Currency: Record Currency)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Order Date");
        case true of
            not CurrExchRate.FindLast:
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text038,
                    Currency.TableCaption, Currency.Code, "Vendor No.", "Order Date"),
                  DATABASE::Currency, Currency.GetPosition);
            CurrExchRate."Exchange Rate Amount" = 0:
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text037,
                    Currency.TableCaption, Currency.Code, "Vendor No.",
                    "Order Date", CurrExchRate.FieldCaption("Exchange Rate Amount")),
                  DATABASE::Currency, Currency.GetPosition);
            CurrExchRate."Relational Exch. Rate Amount" = 0:
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text037,
                    Currency.TableCaption, Currency.Code, "Vendor No.",
                    "Order Date", CurrExchRate.FieldCaption("Relational Exch. Rate Amount")),
                  DATABASE::Currency, Currency.GetPosition);
        end;
    end;

    local procedure CheckNoSeries(NoSeriesCode: Code[20]; SeriesDate: Date)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        case true of
            not NoSeries.Get(NoSeriesCode):
                TempPlanningErrorLog.SetError(
                  StrSubstNo(
                    Text035,
                    NoSeries.TableCaption, NoSeries.FieldCaption(Code), NoSeriesCode,
                    MfgSetup.TableCaption, MfgSetup.FieldCaption("Planned Order Nos.")),
                  DATABASE::"No. Series", NoSeries.GetPosition);
            not NoSeries."Default Nos.":
                TempPlanningErrorLog.SetError(
                  StrSubstNo(Text036, NoSeries.TableCaption, NoSeries.FieldCaption(Code), NoSeries.Code),
                  DATABASE::"No. Series", NoSeries.GetPosition);
            else
                if SeriesDate = 0D then
                    SeriesDate := WorkDate;

                NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, NoSeriesCode, SeriesDate);
                if not NoSeriesLine.FindFirst then begin
                    NoSeriesLine.SetRange("Starting Date");
                    if NoSeriesLine.FindFirst then begin
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(Text039, NoSeriesCode, SeriesDate), DATABASE::"No. Series", NoSeries.GetPosition);
                        exit;
                    end;
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text040, NoSeriesCode), DATABASE::"No. Series", NoSeries.GetPosition);
                    exit;
                end;

                if NoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then begin
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text041, NoSeries.Code, NoSeriesLine."Last Date Used"),
                      DATABASE::"No. Series", NoSeries.GetPosition);
                    exit;
                end;
                NoSeriesLine."Last Date Used" := SeriesDate;
                if NoSeriesLine."Last No. Used" = '' then begin
                    if NoSeriesLine."Starting No." = '' then begin
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(
                            Text042,
                            NoSeries.Code, NoSeriesLine."Line No.", NoSeriesLine.FieldCaption("Starting No.")),
                          DATABASE::"No. Series", NoSeries.GetPosition);
                        exit;
                    end;
                    NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
                end else
                    if NoSeriesLine."Increment-by No." <= 1 then begin
                        if StrLen(IncStr(NoSeriesLine."Last No. Used")) > 20 then begin
                            TempPlanningErrorLog.SetError(
                              StrSubstNo(
                                Text043, NoSeriesLine."Last No. Used", NoSeriesCode),
                              DATABASE::"No. Series", NoSeries.GetPosition);
                            exit;
                        end;
                        NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
                    end else
                        if not IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.") then begin
                            TempPlanningErrorLog.SetError(
                              StrSubstNo(
                                Text043, NoSeriesLine."Last No. Used", NoSeriesCode),
                              DATABASE::"No. Series", NoSeries.GetPosition);
                            exit;
                        end;
                if (NoSeriesLine."Ending No." <> '') and
                   (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
                then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text044, NoSeriesLine."Ending No.", NoSeriesCode),
                      DATABASE::"No. Series", NoSeries.GetPosition);
        end;
    end;

    local procedure IncrementNoText(var No: Code[20]; IncrementByNo: Decimal): Boolean
    var
        DecimalNo: Decimal;
        StartPos: Integer;
        EndPos: Integer;
        NewNo: Text[30];
    begin
        GetIntegerPos(No, StartPos, EndPos);
        Evaluate(DecimalNo, CopyStr(No, StartPos, EndPos - StartPos + 1));
        NewNo := Format(DecimalNo + IncrementByNo, 0, 1);
        if not ReplaceNoText(No, NewNo, 0, StartPos, EndPos) then
            exit(false);
        exit(true);
    end;

    local procedure ReplaceNoText(var No: Code[20]; NewNo: Code[20]; FixedLength: Integer; StartPos: Integer; EndPos: Integer): Boolean
    var
        StartNo: Code[20];
        EndNo: Code[20];
        ZeroNo: Code[20];
        NewLength: Integer;
        OldLength: Integer;
    begin
        if StartPos > 1 then
            StartNo := CopyStr(No, 1, StartPos - 1);
        if EndPos < StrLen(No) then
            EndNo := CopyStr(No, EndPos + 1);
        NewLength := StrLen(NewNo);
        OldLength := EndPos - StartPos + 1;
        if FixedLength > OldLength then
            OldLength := FixedLength;
        if OldLength > NewLength then
            ZeroNo := PadStr('', OldLength - NewLength, '0');
        if StrLen(StartNo) + StrLen(ZeroNo) + StrLen(NewNo) + StrLen(EndNo) > 20 then
            exit(false);
        No := StartNo + ZeroNo + NewNo + EndNo;
        exit(true);
    end;

    local procedure GetIntegerPos(No: Code[20]; var StartPos: Integer; var EndPos: Integer)
    var
        IsDigit: Boolean;
        i: Integer;
    begin
        StartPos := 0;
        EndPos := 0;
        if No <> '' then begin
            i := StrLen(No);
            repeat
                IsDigit := No[i] in ['0' .. '9'];
                if IsDigit then begin
                    if EndPos = 0 then
                        EndPos := i;
                    StartPos := i;
                end;
                i := i - 1;
            until (i = 0) or (StartPos <> 0) and not IsDigit;
        end;
    end;

    local procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset;
        SetCurrentKey(Type, "No.");
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetRange("Sales Order No.", '');
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        Item.CopyFilter("Global Dimension 1 Filter", "Shortcut Dimension 1 Code");
        Item.CopyFilter("Global Dimension 2 Filter", "Shortcut Dimension 2 Code");
        SetRange("Planning Line Origin", "Planning Line Origin"::" ");
        SetFilter("Quantity (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey(
          Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetRange("Sales Order No.", '');
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Quantity (Base)", '>0')
        else
            SetFilter("Quantity (Base)", '<0');
    end;

    procedure FindCurrForecastName(var ForecastName: Code[10]): Boolean
    var
        UntrackedPlngElement: Record "Untracked Planning Element";
    begin
        if (Type <> Type::Item) or
           ("Planning Line Origin" <> "Planning Line Origin"::Planning)
        then
            exit(false);
        UntrackedPlngElement.SetRange("Worksheet Template Name", "Worksheet Template Name");
        UntrackedPlngElement.SetRange("Worksheet Batch Name", "Journal Batch Name");
        UntrackedPlngElement.SetRange("Item No.", "No.");
        UntrackedPlngElement.SetRange("Source Type", DATABASE::"Production Forecast Entry");
        if UntrackedPlngElement.FindFirst then begin
            ForecastName := CopyStr(UntrackedPlngElement."Source ID", 1, 10);
            exit(true);
        end;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Worksheet Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ShowTimeline(ReqLine: Record "Requisition Line")
    var
        ItemAvailByTimeline: Page "Item Availability by Timeline";
    begin
        ReqLine.TestField(Type, Type::Item);
        ReqLine.TestField("No.");

        Item.Get("No.");
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Variant Filter", ReqLine."Variant Code");
        Item.SetRange("Location Filter", ReqLine."Location Code");

        ItemAvailByTimeline.SetItem(Item);
        ItemAvailByTimeline.SetWorksheet(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
        ItemAvailByTimeline.Run;
    end;

    procedure GetOriginalQtyBase(): Decimal
    begin
        exit(CalcBaseQty("Original Quantity"));
    end;

    local procedure SetFromBinCode()
    var
        IsHandled: Boolean;
        ShouldGetDefaultBin: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFromBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            case "Ref. Order Type" of
                "Ref. Order Type"::"Prod. Order":
                    begin
                        if "Bin Code" = '' then
                            "Bin Code" := WMSManagement.GetLastOperationFromBinCode("Routing No.", "Routing Version Code", "Location Code", false, 0);
                        if "Bin Code" = '' then
                            "Bin Code" := Location."From-Production Bin Code";
                    end;
                "Ref. Order Type"::Assembly:
                    if "Bin Code" = '' then
                        "Bin Code" := Location."From-Assembly Bin Code";
            end;
            ShouldGetDefaultBin := ("Bin Code" = '') and Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
            OnBeforeGetDefaultBin(Rec, ShouldGetDefaultBin);
            if ShouldGetDefaultBin then
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
        end;
    end;

    procedure SetDropShipment(NewDropShipment: Boolean)
    begin
        SourceDropShipment := NewDropShipment;
    end;

    procedure IsDropShipment(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if SourceDropShipment then
            exit(true);

        if "Replenishment System" = "Replenishment System"::Purchase then
            if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then
                exit(SalesLine."Drop Shipment");
        exit(false);
    end;

    local procedure GetLocationCode()
    var
        Vend: Record Vendor;
        IsHandled: Boolean;
    begin
        if not IsLocationCodeAlterable or IsDropShipmentOrSpecialOrder then
            exit;

        IsHandled := false;
        OnGetLocationCodeOnBeforeUpdate(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Vendor No." <> '' then begin
            Vend.Get("Vendor No.");
            if Vend."Location Code" <> '' then
                "Location Code" := Vend."Location Code";
        end else
            "Location Code" := '';
    end;

    local procedure IsDropShipmentOrSpecialOrder(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if "Replenishment System" = "Replenishment System"::Purchase then
            if SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.") then
                exit(SalesLine."Drop Shipment" or SalesLine."Special Order");
    end;

    local procedure IsLocationCodeAlterable(): Boolean
    begin
        if (CurrFieldNo = 0) and (CurrentFieldNo = 0) then
            exit(false);

        if (CurrFieldNo = FieldNo("Location Code")) or (CurrentFieldNo = FieldNo("Location Code")) then
            exit(false);

        if (CurrFieldNo = FieldNo("Replenishment System")) or (CurrentFieldNo = FieldNo("Replenishment System")) then
            exit(false);

        if "Planning Line Origin" <> "Planning Line Origin"::" " then
            exit(false);

        exit(true);
    end;

    local procedure GetWorkCenter()
    begin
        if WorkCenter."No." = "Work Center No." then
            exit;

        Clear(WorkCenter);
        if WorkCenter.Get("Work Center No.") then
            SetSubcontracting(WorkCenter."Subcontractor No." <> '')
        else
            SetSubcontracting(false);
    end;

    local procedure RoutingLineExists(): Boolean
    var
        RoutingLine: Record "Routing Line";
    begin
        if "Routing No." <> '' then begin
            RoutingLine.SetRange("Routing No.", "Routing No.");
            exit(not RoutingLine.IsEmpty);
        end;

        exit(false);
    end;

    local procedure SetReplenishmentSystemFromPurchase(StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        "Ref. Order Type" := "Ref. Order Type"::Purchase;
        Clear("Ref. Order Status");
        "Ref. Order No." := '';
        DeleteRelations;
        Validate("Production BOM No.", '');
        Validate("Routing No.", '');
        if Item."Purch. Unit of Measure" <> '' then
            Validate("Unit of Measure Code", Item."Purch. Unit of Measure");
        Validate("Transfer-from Code", '');
        if StockkeepingUnit."Vendor No." = '' then
            Validate("Vendor No.")
        else
            Validate("Vendor No.", StockkeepingUnit."Vendor No.");

        OnAfterSetReplenishmentSystemFromPurchase(Rec, Item, StockkeepingUnit);
    end;

    local procedure SetReplenishmentSystemFromProdOrder()
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if ReqWkshTmpl.Get("Worksheet Template Name") and
           (ReqWkshTmpl.Type = ReqWkshTmpl.Type::"Req.") and (ReqWkshTmpl.Name <> '') and not SourceDropShipment
        then
            Error(ReplenishmentErr);

        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(Text032, Item.TableCaption, Item."No.", Item.FieldCaption("Base Unit of Measure")),
              DATABASE::Item, Item.GetPosition);

        Item.TestField("Base Unit of Measure");
        if "Ref. Order No." = '' then begin
            "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
            "Ref. Order Status" := "Ref. Order Status"::Planned;
            MfgSetup.Get();
            if PlanningResiliency and (MfgSetup."Planned Order Nos." = '') then
                TempPlanningErrorLog.SetError(
                  StrSubstNo(Text032, MfgSetup.TableCaption, '',
                    MfgSetup.FieldCaption("Planned Order Nos.")),
                  DATABASE::"Manufacturing Setup", MfgSetup.GetPosition);
            MfgSetup.TestField("Planned Order Nos.");
            if PlanningResiliency then
                CheckNoSeries(MfgSetup."Planned Order Nos.", "Due Date");
            if not Subcontracting then
                NoSeriesMgt.InitSeries(
                  MfgSetup."Planned Order Nos.", xRec."No. Series", "Due Date", "Ref. Order No.", "No. Series");
        end;
        Validate("Vendor No.", '');

        if not Subcontracting then begin
            Validate("Production BOM No.", Item."Production BOM No.");
            Validate("Routing No.", Item."Routing No.");
        end else begin
            "Production BOM No." := Item."Production BOM No.";
            "Routing No." := Item."Routing No.";
        end;

        OnSetReplenishmentSystemFromProdOrderOnAfterSetProdFields(Rec, Item, Subcontracting);

        Validate("Transfer-from Code", '');
        Validate("Unit of Measure Code", Item."Base Unit of Measure");

        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and ValidateFields then
            PlanningLineMgt.Calculate(Rec, 1, true, true, 0);

        OnAfterSetReplenishmentSystemFromProdOrder(Rec, Item);
    end;

    local procedure SetReplenishmentSystemFromAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                Text032, Item.TableCaption, Item."No.",
                Item.FieldCaption("Base Unit of Measure")),
              DATABASE::Item, Item.GetPosition);
        Item.TestField("Base Unit of Measure");
        if "Ref. Order No." = '' then begin
            "Ref. Order Type" := "Ref. Order Type"::Assembly;
            "Ref. Order Status" := AssemblyHeader."Document Type"::Order;
        end;
        Validate("Vendor No.", '');
        Validate("Production BOM No.", '');
        Validate("Routing No.", '');
        Validate("Transfer-from Code", '');
        Validate("Unit of Measure Code", Item."Base Unit of Measure");

        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and ValidateFields then
            PlanningLineMgt.Calculate(Rec, 1, true, true, 0);

        OnAfterSetReplenishmentSystemFromAssembly(Rec, Item);
    end;

    local procedure SetReplenishmentSystemFromTransfer(StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        "Ref. Order Type" := "Ref. Order Type"::Transfer;
        Clear("Ref. Order Status");
        "Ref. Order No." := '';
        DeleteRelations;
        Validate("Vendor No.", '');
        Validate("Production BOM No.", '');
        Validate("Routing No.", '');
        Validate("Transfer-from Code", StockkeepingUnit."Transfer-from Code");
        Validate("Unit of Measure Code", Item."Base Unit of Measure");

        OnAfterSetReplenishmentSystemFromTransfer(Rec, Item, StockkeepingUnit);
    end;

    local procedure UpdateReplenishmentSystem()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        GetPlanningParameters.AtSKU(StockkeepingUnit, "No.", "Variant Code", "Location Code");
        if Subcontracting then
            StockkeepingUnit."Replenishment System" := StockkeepingUnit."Replenishment System"::"Prod. Order";
        Validate("Replenishment System", StockkeepingUnit."Replenishment System");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ReqLine: Record "Requisition Line"; xReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var RequisitionLine: Record "Requisition Line"; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var RequisitionLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDirectCost(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromPurchase(var RequisitionLine: Record "Requisition Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromProdOrder(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplenishmentSystemFromProdOrderOnAfterSetProdFields(var RequisitionLine: Record "Requisition Line"; Item: Record Item; Subcontracting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromAssembly(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromTransfer(var RequisitionLine: Record "Requisition Line"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrderLine(var ReqLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchaseLine(var ReqLine: Record "Requisition Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmHeader(var ReqLine: Record "Requisition Line"; AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromTransLine(var ReqLine: Record "Requisition Line"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToTrackingEntry(var ReservationEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item; xRequisitionLine: Record "Requisition Line"; FieldNo: Integer; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEndingDate(var RequisitionLine: Record "Requisition Line"; var ShowWarning: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var RequisitionLine: Record "Requisition Line"; var ShouldGetDefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectCost(var ReqLine: Record "Requisition Line"; xReqLine: Record "Requisition Line"; CalledByFieldNo: Integer; FieldNo: Integer; Subcontracting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupVendor(var RequisitionLine: Record "Requisition Line"; var Vendor: Record Vendor; var PreferItemVendorCatalog: Boolean; var IsHandled: Boolean; var IsVendorSelected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFromBinCode(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDescription(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderReceiptDate(var RequisitionLine: Record "Requisition Line"; LeadTimeCalc: DateFormula; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLocationCodeOnBeforeUpdate(var RequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSupplyFromOnCaseReplenishmentSystemElse(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSupplyFromOnCaseReplenishmentSystemElse(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItemVariant(var RequisitionLine: Record "Requisition Line"; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromItemTranslation(var RequisitionLine: Record "Requisition Line"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionFromSalesLine(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEndingTimeOnBeforeSetDueDate(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingTimeOnBeforeSetDueDate(var RequisitionLine: Record "Requisition Line"; var ShouldSetDueDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeGetDefaultBin(RequisitionLine: Record "Requisition Line"; var ShouldGetDefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeUnitCost(var RequisitionLine: Record "Requisition Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var RequisitionLine: Record "Requisition Line");
    begin
    end;
}

