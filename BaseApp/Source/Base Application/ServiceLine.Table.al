table 5902 "Service Line"
{
    Caption = 'Service Line';
    DrillDownPageID = "Service Line List";
    LookupPageID = "Service Line List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo";
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Service Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Item,Resource,Cost,G/L Account';
            OptionMembers = " ",Item,Resource,Cost,"G/L Account";

            trigger OnValidate()
            begin
                CheckIfCanBeModified;

                GetServHeader;
                TestStatusOpen;
                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                if xRec.Type = xRec.Type::Item then
                    WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);

                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick", false);
                end;

                UpdateReservation(FieldNo(Type));

                ServiceLine := Rec;

                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then
                    UpdateServDocRegister(true);
                ClearFields;

                "Currency Code" := ServiceLine."Currency Code";
                Validate("Service Item Line No.", ServiceLine."Service Item Line No.");

                if Type = Type::Item then begin
                    if ServHeader.InventoryPickConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                        DisplayConflictError(ServHeader.InvPickConflictResolutionTxt);
                    if ServHeader.WhseShpmntConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                        DisplayConflictError(ServHeader.WhseShpmtConflictResolutionTxt);
                end;
            end;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item WHERE(Type = FILTER(Inventory | "Non-Inventory"),
                                                                   Blocked = CONST(false))
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST(Cost)) "Service Cost";

            trigger OnValidate()
            begin
                CheckIfCanBeModified;

                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');
                CheckItemAvailable(FieldNo("No."));
                TestStatusOpen;

                ClearFields;

                UpdateReservation(FieldNo("No."));

                if "No." = '' then
                    exit;

                GetServHeader;

                if ServHeader."Document Type" = ServHeader."Document Type"::Quote then begin
                    if ServHeader."Customer No." = '' then
                        Error(
                          Text031,
                          ServHeader.FieldCaption("Customer No."));
                    if ServHeader."Bill-to Customer No." = '' then
                        Error(
                          Text031,
                          ServHeader.FieldCaption("Bill-to Customer No."));
                end else
                    ServHeader.TestField("Customer No.");

                InitHeaderDefaults(ServHeader);

                if "Service Item Line No." <> 0 then begin
                    ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                    Validate("Contract No.", ServItemLine."Contract No.")
                end else
                    Validate("Contract No.", ServHeader."Contract No.");

                case Type of
                    Type::" ":
                        CopyFromStdTxt;
                    Type::"G/L Account":
                        CopyFromGLAccount;
                    Type::Cost:
                        CopyFromCost;
                    Type::Item:
                        begin
                            CopyFromItem;
                            if ServItem.Get("Service Item No.") then
                                CopyFromServItem(ServItem);
                        end;
                    Type::Resource:
                        CopyFromResource;
                end;

                if Type <> Type::" " then begin
                    Validate("VAT Prod. Posting Group");
                    Validate("Unit of Measure Code");
                    if Quantity <> 0 then begin
                        InitOutstanding;
                        if "Document Type" = "Document Type"::"Credit Memo" then
                            InitQtyToInvoice
                        else
                            InitQtyToShip;
                        UpdateWithWarehouseShip;
                    end;
                    UpdateUnitPrice(FieldNo("No."));
                    AdjustMaxLabourUnitPrice("Unit Price");

                    if (Type <> Type::Cost) and
                       not ReplaceServItemAction
                    then
                        Validate(Quantity, xRec.Quantity);
                    UpdateAmounts;
                end;
                UpdateReservation(FieldNo("No."));

                GetDefaultBin;

                if not IsTemporary then
                    CreateDim(
                      DimMgt.TypeToTableID5(Type), "No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Responsibility Center", "Responsibility Center");

                if ServiceLine.Get("Document Type", "Document No.", "Line No.") then
                    Modify;
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                TestStatusOpen;
                UpdateWithWarehouseShip;
                GetServHeader;
                if Type = Type::Item then begin
                    // Location code in allowed only for inventoriable items
                    if "Location Code" <> '' then begin
                        GetItem(Item);
                        Item.TestField(Type, Item.Type::Inventory);
                    end;

                    if Quantity <> 0 then
                        WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);
                    if "Location Code" <> xRec."Location Code" then begin
                        TestField("Reserved Quantity", 0);
                        TestField("Shipment No.", '');
                        TestField("Qty. Shipped Not Invoiced", 0);
                        CheckItemAvailable(FieldNo("Location Code"));
                        UpdateReservation(FieldNo("Location Code"));
                    end;
                    GetUnitCost;
                end;
                GetDefaultBin;
            end;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Inventory Posting Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                Item: Record Item;
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                GetServHeader;
                TestField(Type);
                TestField("No.");
                TestStatusOpen;

                if Quantity < 0 then
                    FieldError(Quantity, Text029);

                case "Spare Part Action" of
                    "Spare Part Action"::Permanent, "Spare Part Action"::"Temporary":
                        if Quantity <> 1 then
                            Error(Text011, ServItem.TableCaption);
                    "Spare Part Action"::"Component Replaced", "Spare Part Action"::"Component Installed":
                        if Quantity <> Round(Quantity, 1) then
                            Error(Text026, FieldCaption(Quantity));
                end;

                "Quantity (Base)" := UOMMgt.CalcBaseQty(Quantity, "Qty. per Unit of Measure");

                if "Document Type" <> "Document Type"::"Credit Memo" then begin
                    if (Quantity * "Quantity Shipped" < 0) or
                       ((Abs(Quantity) < Abs("Quantity Shipped")) and ("Shipment No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text003, FieldCaption("Quantity Shipped")));
                    if ("Quantity (Base)" * "Qty. Shipped (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Qty. Shipped (Base)")) and ("Shipment No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text003, FieldCaption("Qty. Shipped (Base)")));
                end;

                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
                    InitOutstanding;
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        InitQtyToInvoice
                    else
                        InitQtyToShip;
                end;
                CheckItemAvailable(FieldNo(Quantity));

                if (Quantity * xRec.Quantity < 0) or (Quantity = 0) then
                    InitItemAppl(false);

                if Type = Type::Item then begin
                    WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);
                    UpdateUnitPrice(FieldNo(Quantity));
                    UpdateReservation(FieldNo(Quantity));
                    UpdateWithWarehouseShip;
                    if ("Quantity (Base)" * xRec."Quantity (Base)" <= 0) and ("No." <> '') then begin
                        GetItem(Item);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment then
                            GetUnitCost;
                    end;
                    if ("Appl.-from Item Entry" <> 0) and (xRec.Quantity < Quantity) then
                        CheckApplFromItemLedgEntry(ItemLedgEntry);
                end else
                    Validate("Line Discount %");

                if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                   ((Amount <> 0) or
                    ("Amount Including VAT" <> 0) or
                    ("VAT Base Amount" <> 0))
                then begin
                    Amount := 0;
                    "Amount Including VAT" := 0;
                    "VAT Base Amount" := 0;
                end;
                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Invoice" < 0 then
                    FieldError("Qty. to Invoice", Text029);

                if "Qty. to Invoice" > 0 then begin
                    "Qty. to Consume" := 0;
                    "Qty. to Consume (Base)" := 0;
                end;

                if "Qty. to Invoice" = MaxQtyToInvoice then
                    InitQtyToInvoice
                else
                    "Qty. to Invoice (Base)" := UOMMgt.CalcBaseQty("Qty. to Invoice", "Qty. per Unit of Measure");
                if ("Qty. to Invoice" * Quantity < 0) or
                   (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice))
                then
                    Error(
                      Text000,
                      MaxQtyToInvoice);
                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase))
                then
                    Error(
                      Text001,
                      MaxQtyToInvoiceBase);
                "VAT Difference" := 0;

                if (xRec."Qty. to Consume" <> "Qty. to Consume") or
                   (xRec."Qty. to Consume (Base)" <> "Qty. to Consume (Base)")
                then
                    Validate("Line Discount %")
                else begin
                    CalcInvDiscToInvoice;
                    UpdateAmounts
                end;
            end;
        }
        field(18; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Ship" < 0 then
                    FieldError("Qty. to Ship", Text029);

                if (CurrFieldNo <> 0) and
                   (Type = Type::Item) and
                   ("Qty. to Ship" <> 0)
                then
                    CheckWarehouse;

                if "Qty. to Ship" = "Outstanding Quantity" then begin
                    if not LineRequiresShipmentOrReceipt then
                        InitQtyToShip
                    else
                        "Qty. to Ship (Base)" := UOMMgt.CalcBaseQty("Qty. to Ship", "Qty. per Unit of Measure");
                    if "Qty. to Consume" <> 0 then
                        Validate("Qty. to Consume", "Qty. to Ship")
                    else
                        Validate("Qty. to Consume", 0);
                end else begin
                    "Qty. to Ship (Base)" := UOMMgt.CalcBaseQty("Qty. to Ship", "Qty. per Unit of Measure");
                    if "Qty. to Consume" <> 0 then
                        Validate("Qty. to Consume", "Qty. to Ship")
                    else
                        Validate("Qty. to Consume", 0);
                end;
                if ((("Qty. to Ship" < 0) xor (Quantity < 0)) and (Quantity <> 0) and ("Qty. to Ship" <> 0)) or
                   (Abs("Qty. to Ship") > Abs("Outstanding Quantity")) or
                   (((Quantity < 0) xor ("Outstanding Quantity" < 0)) and (Quantity <> 0) and ("Outstanding Quantity" <> 0))
                then
                    Error(
                      Text016,
                      "Outstanding Quantity");
                if ((("Qty. to Ship (Base)" < 0) xor ("Quantity (Base)" < 0)) and ("Qty. to Ship (Base)" <> 0) and ("Quantity (Base)" <> 0)) or
                   (Abs("Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)")) or
                   ((("Quantity (Base)" < 0) xor ("Outstanding Qty. (Base)" < 0)) and ("Quantity (Base)" <> 0) and ("Outstanding Qty. (Base)" <> 0))
                then
                    Error(
                      Text017,
                      "Outstanding Qty. (Base)");
            end;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetServHeader;
                if ("Appl.-to Service Entry" > 0) and (CurrFieldNo <> 0) then
                    Error(Text052, FieldCaption("Unit Price"));
                if ("Unit Price" > ServHeader."Max. Labor Unit Price") and
                   (Type = Type::Resource) and
                   (ServHeader."Max. Labor Unit Price" <> 0)
                then
                    Error(
                      Text022,
                      FieldCaption("Unit Price"), ServHeader.FieldCaption("Max. Labor Unit Price"),
                      ServHeader.TableCaption);

                Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                GetServHeader;
                Currency.Initialize("Currency Code");
                if "Unit Cost (LCY)" <> xRec."Unit Cost (LCY)" then
                    if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                       (Type = Type::Item) and ("No." <> '') and ("Quantity (Base)" <> 0)
                    then begin
                        GetItem(Item);
                        if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment then begin
                            if "Document Type" in ["Document Type"::"Credit Memo"] then
                                Error(
                                  Text037,
                                  FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                                  Item."Costing Method", FieldCaption(Quantity));
                            Error(
                              Text038,
                              FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                              Item."Costing Method", FieldCaption(Quantity));
                        end;
                    end;

                if "Currency Code" <> '' then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    "Unit Cost" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate, "Currency Code", "Unit Cost (LCY)",
                          ServHeader."Currency Factor"), Currency."Unit-Amount Rounding Precision")
                end else
                    "Unit Cost" := "Unit Cost (LCY)";

                UpdateRemainingCostsAndAmounts;
            end;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Line Discount %") then
                    TestStatusOpen;
                GetServHeader;
                if (CurrFieldNo in
                    [FieldNo("Line Discount %"),
                     FieldNo("Line Discount Amount"),
                     FieldNo("Line Amount")]) and
                   ("Document Type" <> "Document Type"::Invoice)
                then
                    CheckLineDiscount("Line Discount %");

                "Line Discount Amount" :=
                  Round(
                    Round(CalcChargeableQty * "Unit Price", Currency."Amount Rounding Precision") *
                    "Line Discount %" / 100, Currency."Amount Rounding Precision");
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;

                UpdateAmounts;
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetServHeader;
                TestField(Quantity);
                if "Line Discount Amount" <> xRec."Line Discount Amount" then
                    UpdateLineDiscPct;
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                Validate("Line Discount %");
            end;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetServHeader;
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - ServHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * "VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text013, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Round(Amount, Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Amount +
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                "VAT Base Amount", "Quantity (Base)", ServHeader."Currency Factor");
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                            "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                        end;
                end;

                InitOutstandingAmount;
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetServHeader;
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - ServHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - ServHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                "Amount Including VAT", "Quantity (Base)", ServHeader."Currency Factor");
                            if Amount <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - Amount) / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end;

                InitOutstandingAmount;
            end;
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Allow Invoice Disc." <> xRec."Allow Invoice Disc.") and
                   not "Allow Invoice Disc."
                then begin
                    "Inv. Discount Amount" := 0;
                    "Inv. Disc. Amount to Invoice" := 0;
                    UpdateAmounts;
                end;
            end;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
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

                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));
                    "Location Code" := ItemLedgEntry."Location Code";
                    if not ItemLedgEntry.Open then
                        Message(Text042, "Appl.-to Item Entry");
                end;
            end;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
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
        field(41; "Shortcut Dimension 2 Code"; Code[20])
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
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            Editable = false;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then
                    UpdateUnitPrice(FieldNo("Customer Price Group"));
            end;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job."No." WHERE("Bill-to Customer No." = FIELD("Bill-to Customer No."));

            trigger OnValidate()
            var
                Job: Record Job;
            begin
                TestField("Quantity Consumed", 0);
                Validate("Job Task No.", '');

                if "Job No." <> '' then begin
                    Job.Get("Job No.");
                    Job.TestBlocked;
                end;

                CreateDim(
                  DATABASE::Job, "Job No.",
                  DimMgt.TypeToTableID5(Type), "No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(46; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            begin
                TestField("Quantity Consumed", 0);
                if "Job Task No." = '' then
                    "Job Line Type" := "Job Line Type"::" ";

                if "Job Task No." <> xRec."Job Task No." then
                    Validate("Job Planning Line No.", 0);
            end;
        }
        field(47; "Job Line Type"; Option)
        {
            Caption = 'Job Line Type';
            OptionCaption = ' ,Budget,Billable,Both Budget and Billable';
            OptionMembers = " ",Budget,Billable,"Both Budget and Billable";

            trigger OnValidate()
            begin
                TestField("Quantity Consumed", 0);
                TestField("Job No.");
                TestField("Job Task No.");
                if "Job Planning Line No." <> 0 then
                    Error(Text048, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                WorkType: Record "Work Type";
            begin
                if Type = Type::Resource then begin
                    TestStatusOpen;
                    if WorkType.Get("Work Type Code") then
                        Validate("Unit of Measure Code", WorkType."Unit of Measure Code");
                    UpdateUnitPrice(FieldNo("Work Type Code"));
                    Validate("Unit Price");
                    FindResUnitCost;
                end;
            end;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetServHeader;
                Currency2.InitRoundingPrecision;
                if ServHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate, "Currency Code",
                          "Outstanding Amount", ServHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Shipped Not Invoiced"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetServHeader;
                Currency2.InitRoundingPrecision;
                if ServHeader."Currency Code" <> '' then
                    "Shipped Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate, "Currency Code",
                          "Shipped Not Invoiced", ServHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Shipped Not Invoiced (LCY)" :=
                      Round("Shipped Not Invoiced", Currency2."Amount Rounding Precision");
            end;
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';

            trigger OnLookup()
            var
                ServShptHeader: Record "Service Shipment Header";
            begin
                GetServHeader;
                if "Document Type" = "Document Type"::"Credit Memo" then begin
                    ServShptHeader.Reset;
                    ServShptHeader.SetCurrentKey("Customer No.", "Posting Date");
                    ServShptHeader.FilterGroup(2);
                    ServShptHeader.SetRange("Customer No.", ServHeader."Customer No.");
                    ServShptHeader.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                    ServShptHeader.SetRange("Bill-to Customer No.", ServHeader."Bill-to Customer No.");
                    ServShptHeader.FilterGroup(0);
                    ServShptHeader."No." := "Shipment No.";
                    if PAGE.RunModal(0, ServShptHeader) = ACTION::LookupOK then
                        Validate("Shipment No.", ServShptHeader."No.");
                end
            end;

            trigger OnValidate()
            var
                ServShptHeader: Record "Service Shipment Header";
                ServDocReg: Record "Service Document Register";
            begin
                if "Shipment No." <> xRec."Shipment No." then begin
                    if "Shipment No." <> '' then begin
                        GetServHeader;
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            ServShptHeader.Reset;
                            ServShptHeader.SetCurrentKey("Customer No.", "Posting Date");
                            ServShptHeader.SetRange("Customer No.", ServHeader."Customer No.");
                            ServShptHeader.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                            ServShptHeader.SetRange("Bill-to Customer No.", ServHeader."Bill-to Customer No.");
                            ServShptHeader.SetRange("No.", "Shipment No.");
                            ServShptHeader.FindFirst;
                        end;
                    end;
                    TestField("Appl.-to Service Entry", 0);
                    ServDocReg.Reset;
                    ServDocReg.SetRange("Destination Document Type", "Document Type");
                    ServDocReg.SetRange("Destination Document No.", "Document No.");
                    ServDocReg.SetRange("Source Document Type", ServDocReg."Source Document Type"::Order);
                    ServDocReg.SetRange("Source Document No.", xRec."Shipment No.");
                    ServDocReg.DeleteAll;
                    Clear(ServDocReg);
                end;
            end;
        }
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestField(Quantity);
                CalcInvDiscToInvoice;
                UpdateAmounts;
            end;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGroup: Record "Gen. Business Posting Group";
            begin
                if "Gen. Bus. Posting Group" <> xRec."Gen. Bus. Posting Group" then
                    if GenBusPostingGroup.ValidateVatBusPostingGroup(GenBusPostingGroup, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGroup."Def. VAT Bus. Posting Group");
            end;
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGroup: Record "Gen. Product Posting Group";
            begin
                TestStatusOpen;
                if "Gen. Prod. Posting Group" <> xRec."Gen. Prod. Posting Group" then
                    if GenProdPostingGroup.ValidateVatProdPostingGroup(GenProdPostingGroup, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
            end;
        }
        field(77; "VAT Calculation Type"; Option)
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Service Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                             "Document No." = FIELD("Document No."));
        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateAmounts;
            end;
        }
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                TestStatusOpen;
                GetServHeader;
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                "VAT Difference" := 0;
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Reverse Charge VAT",
                  "VAT Calculation Type"::"Sales Tax":
                        "VAT %" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        TestField(Type, Type::Cost);
                end;
                GetServHeader;
                if ServHeader."Prices Including VAT" and (Type in [Type::Item, Type::Resource]) then
                    "Unit Price" :=
                      Round(
                        "Unit Price" * (100 + "VAT %") / (100 + xRec."VAT %"),
                        Currency."Unit-Amount Rounding Precision");
                UpdateAmounts;
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            Editable = false;
        }
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(5902),
                                                                   "Source Subtype" = FIELD("Document Type"),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; Reserve; Option)
        {
            Caption = 'Reserve';
            OptionCaption = 'Never,Optional,Always';
            OptionMembers = Never,Optional,Always;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;
                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItem(Item);
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                TestField(Type);
                TestField(Quantity);
                TestField("Unit Price");
                Currency.Initialize("Currency Code");
                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                Validate(
                  "Line Discount Amount",
                  Round(CalcChargeableQty * "Unit Price", Currency."Amount Rounding Precision") - "Line Amount");
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';

            trigger OnValidate()
            begin
                TestField(Quantity);
                UpdateAmounts;
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
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." WHERE("Time Sheet No." = FIELD("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date WHERE("Time Sheet No." = FIELD("Time Sheet No."),
                                                            "Time Sheet Line No." = FIELD("Time Sheet Line No."));
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                case Type of
                    Type::"G/L Account":
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                    Type::Item:
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
                end;
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    case Type of
                        Type::Resource:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Resource);
                        Type::Item:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                        Type::"G/L Account":
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                    end;
                    JobPlanningLine.TestField("No.", "No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine."Line Type" + 1;
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - Quantity);
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text047, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else begin
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                    end;
                end;
                "Job Remaining Qty. (Base)" := UOMMgt.CalcBaseQty("Job Remaining Qty.", "Qty. per Unit of Measure");

                UpdateRemainingCostsAndAmounts;
            end;
        }
        field(1031; "Job Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Job Remaining Qty. (Base)';
        }
        field(1032; "Job Remaining Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Remaining Total Cost';
            Editable = false;
        }
        field(1033; "Job Remaining Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Remaining Total Cost (LCY)';
            Editable = false;
        }
        field(1034; "Job Remaining Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Remaining Line Amount';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then
                    TestField(Type, Type::Item);
                TestStatusOpen;

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                    InitItemAppl(false);
                end;

                CheckItemAvailable(FieldNo("Variant Code"));
                UpdateReservation(FieldNo("Variant Code"));

                if Type = Type::Item then begin
                    GetUnitCost;
                    UpdateUnitPrice(FieldNo("Variant Code"));
                    WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);
                end;

                GetDefaultBin;

                if "Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        GetItem(Item);
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                        OnValidateVariantCodeOnAssignItem(Rec, Item);
                        GetItemTranslation;
                    end;
                    exit;
                end;

                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
                OnValidateVariantCodeOnAssignItemVariant(Rec, ItemVariant);

                GetServHeader;
                if ServHeader."Language Code" <> '' then
                    GetItemTranslation;
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Document Type" = FILTER(Order | Invoice),
                                "Location Code" = FILTER(<> ''),
                                Type = CONST(Item)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Item No." = FIELD("No."),
                                                                                  "Variant Code" = FIELD("Variant Code"))
            ELSE
            IF ("Document Type" = FILTER("Credit Memo"),
                                                                                           "Location Code" = FILTER(<> ''),
                                                                                           Type = CONST(Item)) Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationManagement: Codeunit "Whse. Integration Management";
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                if "Bin Code" <> '' then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
                    else
                        if "Document Type" = "Document Type"::"Credit Memo" then
                            WMSManagement.FindBin("Location Code", "Bin Code", '');

                if xRec."Bin Code" <> "Bin Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                end;

                if "Bin Code" <> '' then
                    WhseIntegrationManagement.CheckBinTypeCode(
                      DATABASE::"Service Line",
                      FieldCaption("Bin Code"),
                      "Location Code",
                      "Bin Code",
                      "Document Type");
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5405; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                UnitOfMeasure: Record "Unit of Measure";
                UnitOfMeasureTranslation: Record "Unit of Measure Translation";
                ResUnitofMeasure: Record "Resource Unit of Measure";
            begin
                TestField("Quantity Shipped", 0);
                TestField("Qty. Shipped (Base)", 0);
                TestStatusOpen;

                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init;
                    "Unit of Measure" := UnitOfMeasure.Description;
                    GetServHeader;
                    if ServHeader."Language Code" <> '' then begin
                        UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                        UnitOfMeasureTranslation.SetRange("Language Code", ServHeader."Language Code");
                        if UnitOfMeasureTranslation.FindFirst then
                            "Unit of Measure" := UnitOfMeasureTranslation.Description;
                    end;
                end;

                case Type of
                    Type::Item:
                        begin
                            if Quantity <> 0 then
                                WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);
                            GetItem(Item);
                            GetUnitCost;
                            UpdateUnitPrice(FieldNo("Unit of Measure Code"));
                            "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                            "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                            "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                            "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                            if "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" then
                                InitItemAppl(false);
                        end;
                    Type::Resource:
                        begin
                            if "Unit of Measure Code" = '' then begin
                                GetResource;
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                                if UnitOfMeasure.Get("Unit of Measure Code") then
                                    "Unit of Measure" := UnitOfMeasure.Description;
                            end;
                            ResUnitofMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                            UpdateUnitPrice(FieldNo("Unit of Measure Code"));
                            FindResUnitCost;
                        end;
                    Type::"G/L Account", Type::" ", Type::Cost:
                        "Qty. per Unit of Measure" := 1;
                end;

                Validate(Quantity);
                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                UpdateReservation(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Quantity (Base)" < 0 then
                    FieldError("Quantity (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
                UpdateUnitPrice(FieldNo("Quantity (Base)"));
            end;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Invoice (Base)" < 0 then
                    FieldError("Qty. to Invoice (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Ship (Base)" < 0 then
                    FieldError("Qty. to Ship (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(5902),
                                                                            "Source Subtype" = FIELD("Document Type"),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure");
                CalcFields("Reserved Quantity");
                Planned := "Reserved Quantity" = "Outstanding Quantity";
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DimMgt.TypeToTableID5(Type), "No.",
                  DATABASE::Job, "Job No.");
            end;
        }
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = Exist ("Item Substitution" WHERE(Type = CONST(Item),
                                                           "No." = FIELD("No."),
                                                           "Substitute Type" = CONST(Item)));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            Editable = false;
        }
        field(5712; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
            ObsoleteTag = '15.0';
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(5902),
                                                                                         "Source Subtype" = FIELD("Document Type"),
                                                                                         "Source No." = FIELD("Document No."),
                                                                                         "Source Line No." = FIELD("Line No.")));
            Caption = 'Whse. Outstanding Qty. (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and
                   ("Promised Delivery Date" <> 0D)
                then
                    Error(
                      Text046,
                      FieldCaption("Requested Delivery Date"),
                      FieldCaption("Promised Delivery Date"));

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Requested Delivery Date")
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                Validate("Needed by Date", "Planned Delivery Date");
            end;
        }
        field(5796; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(5797; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            var
                ShippingAgentServices: Record "Shipping Agent Services";
            begin
                TestStatusOpen;
                if "Shipping Agent Service Code" <> xRec."Shipping Agent Service Code" then
                    Clear("Shipping Time");

                if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
                    "Shipping Time" := ShippingAgentServices."Shipping Time"
                else begin
                    GetServHeader;
                    "Shipping Time" := ServHeader."Shipping Time";
                end;

                if ShippingAgentServices."Shipping Time" <> xRec."Shipping Time" then
                    Validate("Shipping Time", "Shipping Time");
            end;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" <> 0 then begin
                    CheckApplFromItemLedgEntry(ItemLedgEntry);
                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));
                end;
            end;
        }
        field(5902; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item"."No.";

            trigger OnLookup()
            begin
                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                    ServItem.Reset;
                    ServItem.SetCurrentKey("Customer No.");
                    ServItem.FilterGroup(2);
                    ServItem.SetRange("Customer No.", "Customer No.");
                    ServItem.FilterGroup(0);
                    if PAGE.RunModal(0, ServItem) = ACTION::LookupOK then
                        Validate("Service Item No.", ServItem."No.");
                end
                else begin
                    ServItemLine.Reset;
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                    ServItemLine.FilterGroup(2);
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.FilterGroup(0);
                    ServItemLine."Service Item No." := "Service Item No.";
                    if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                        Validate("Service Item Line No.", ServItemLine."Line No.");
                end;

                if "Service Item No." <> xRec."Service Item No." then
                    Validate("No.");
            end;

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');
                if "Service Item No." <> '' then begin
                    if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then
                        exit;
                    ServItemLine.Reset;
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Service Item No.", "Service Item No.");
                    ServItemLine.Find('-');
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;

                if "Service Item No." <> xRec."Service Item No." then begin
                    if "Service Item No." = '' then
                        Validate("Service Item Line No.", 0);
                    Validate("No.");
                end;
            end;
        }
        field(5903; "Appl.-to Service Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Service Entry';
            Editable = false;
        }
        field(5904; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            TableRelation = "Service Item Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                                  "Document No." = FIELD("Document No."));

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
                ErrorIfAlreadySelectedSI("Service Item Line No.");
                if ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then begin
                    "Service Item No." := ServItemLine."Service Item No.";
                    "Service Item Serial No." := ServItemLine."Serial No.";
                    "Fault Area Code" := ServItemLine."Fault Area Code";
                    "Symptom Code" := ServItemLine."Symptom Code";
                    "Fault Code" := ServItemLine."Fault Code";
                    "Resolution Code" := ServItemLine."Resolution Code";
                    "Service Price Group Code" := ServItemLine."Service Price Group Code";
                    "Serv. Price Adjmt. Gr. Code" := ServItemLine."Serv. Price Adjmt. Gr. Code";
                    if "No." <> '' then
                        Validate("Contract No.", ServItemLine."Contract No.");
                end else begin
                    "Service Item No." := '';
                    "Service Item Serial No." := '';
                end;
                CalcFields("Service Item Line Description");
            end;
        }
        field(5905; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';

            trigger OnLookup()
            begin
                ServItemLine.Reset;
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "Document No.");
                ServItemLine."Serial No." := "Service Item Serial No.";
                if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                    Validate("Service Item Line No.", ServItemLine."Line No.");
            end;

            trigger OnValidate()
            begin
                if "Service Item Serial No." <> '' then begin
                    ServItemLine.Reset;
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Serial No.", "Service Item Serial No.");
                    ServItemLine.Find('-');
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;
            end;
        }
        field(5906; "Service Item Line Description"; Text[100])
        {
            CalcFormula = Lookup ("Service Item Line".Description WHERE("Document Type" = FIELD("Document Type"),
                                                                        "Document No." = FIELD("Document No."),
                                                                        "Line No." = FIELD("Service Item Line No.")));
            Caption = 'Service Item Line Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5907; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(5908; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5909; "Order Date"; Date)
        {
            Caption = 'Order Date';
            Editable = false;
        }
        field(5910; "Needed by Date"; Date)
        {
            Caption = 'Needed by Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if CurrFieldNo = FieldNo("Needed by Date") then
                    if xRec."Needed by Date" <> 0D then
                        TestField("Needed by Date");
                if "Needed by Date" <> 0D then
                    CheckItemAvailable(FieldNo("Needed by Date"));
                if CurrFieldNo = FieldNo("Planned Delivery Date") then
                    UpdateReservation(CurrFieldNo)
                else
                    UpdateReservation(FieldNo("Needed by Date"));
                "Planned Delivery Date" := "Needed by Date";
            end;
        }
        field(5916; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(5917; "Qty. to Consume"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Consume';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Qty. to Consume") then
                    CheckWarehouse;

                if "Qty. to Consume" < 0 then
                    FieldError("Qty. to Consume", Text029);

                if "Qty. to Consume" = MaxQtyToConsume then
                    InitQtyToConsume
                else begin
                    "Qty. to Consume (Base)" := UOMMgt.CalcBaseQty("Qty. to Consume", "Qty. per Unit of Measure");
                    InitQtyToInvoice;
                end;

                if "Qty. to Consume" > 0 then begin
                    "Qty. to Ship" := "Qty. to Consume";
                    "Qty. to Ship (Base)" := "Qty. to Consume (Base)";
                    "Qty. to Invoice" := 0;
                    "Qty. to Invoice (Base)" := 0;
                end;

                if ("Qty. to Consume" * Quantity < 0) or
                   (Abs("Qty. to Consume") > Abs(MaxQtyToConsume))
                then
                    Error(
                      Text028,
                      MaxQtyToConsume);
                if ("Qty. to Consume (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Consume (Base)") > Abs(MaxQtyToConsumeBase))
                then
                    Error(
                      Text032,
                      MaxQtyToConsumeBase);

                if (xRec."Qty. to Consume" <> "Qty. to Consume") or
                   (xRec."Qty. to Consume (Base)" <> "Qty. to Consume (Base)")
                then
                    Validate("Line Discount %");
            end;
        }
        field(5918; "Quantity Consumed"; Decimal)
        {
            Caption = 'Quantity Consumed';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5919; "Qty. to Consume (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Consume (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if LineRequiresShipmentOrReceipt then
                    exit;
                if "Qty. to Consume (Base)" < 0 then
                    FieldError("Qty. to Consume (Base)", Text029);

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5920; "Qty. Consumed (Base)"; Decimal)
        {
            Caption = 'Qty. Consumed (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5928; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(5929; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";

            trigger OnValidate()
            begin
                if "Fault Area Code" <> xRec."Fault Area Code" then
                    "Fault Code" := '';
            end;
        }
        field(5930; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";

            trigger OnValidate()
            begin
                if "Symptom Code" <> xRec."Symptom Code" then
                    "Fault Code" := '';
            end;
        }
        field(5931; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code WHERE("Fault Area Code" = FIELD("Fault Area Code"),
                                                     "Symptom Code" = FIELD("Symptom Code"));
        }
        field(5932; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(5933; "Exclude Warranty"; Boolean)
        {
            Caption = 'Exclude Warranty';
            Editable = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not (Type in [Type::Item, Type::Resource]) then
                    if CurrFieldNo = FieldNo("Exclude Warranty") then
                        FieldError(Type)
                    else
                        exit;

                if CurrFieldNo = FieldNo("Exclude Warranty") then begin
                    ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                    ServItemLine.TestField(Warranty, true);
                    if "Exclude Warranty" and (not Warranty) then
                        FieldError(Warranty);
                end;
                if HideWarrantyWarning = false then
                    if "Fault Reason Code" <> '' then begin
                        FaultReasonCode.Get("Fault Reason Code");
                        if FaultReasonCode."Exclude Warranty Discount" and
                           not "Exclude Warranty"
                        then
                            Error(
                              Text008,
                              FieldCaption("Exclude Warranty"),
                              FaultReasonCode.FieldCaption("Exclude Warranty Discount"),
                              "Fault Reason Code",
                              FaultReasonCode.TableCaption);
                    end;
                if HideWarrantyWarning = false then
                    if "Exclude Warranty" <> xRec."Exclude Warranty" then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text009, FieldCaption("Exclude Warranty")), true)
                        then begin
                            "Exclude Warranty" := xRec."Exclude Warranty";
                            exit;
                        end;
                Validate("Contract No.");
                if "Exclude Warranty" then
                    Validate(Warranty, false)
                else
                    Validate(Warranty, true);
            end;
        }
        field(5934; Warranty; Boolean)
        {
            Caption = 'Warranty';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateDiscountsAmounts;
            end;
        }
        field(5936; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract));

            trigger OnLookup()
            var
                ServContractHeader: Record "Service Contract Header";
            begin
                GetServHeader;
                ServContractHeader.FilterGroup(2);
                ServContractHeader.SetRange("Customer No.", ServHeader."Customer No.");
                ServContractHeader.SetRange("Contract Type", ServContractHeader."Contract Type"::Contract);
                ServContractHeader.FilterGroup(0);
                if (PAGE.RunModal(0, ServContractHeader) = ACTION::LookupOK) and
                   ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
                then
                    Validate("Contract No.", ServContractHeader."Contract No.");
            end;

            trigger OnValidate()
            var
                Res: Record Resource;
                ServCost: Record "Service Cost";
                ContractGroup: Record "Contract Group";
                ContractServDisc: Record "Contract/Service Discount";
                ServContractHeader: Record "Service Contract Header";
            begin
                if "Shipment Line No." <> 0 then
                    if "Shipment No." <> '' then
                        FieldError("Contract No.");

                if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                    if "Contract No." <> xRec."Contract No." then begin
                        TestField("Appl.-to Service Entry", 0);
                        UpdateServDocRegister(false);
                    end;
                end else begin
                    ServMgtSetup.Get;
                    if not ServItem.Get("Service Item No.") then
                        Clear(ServItem);
                    if "Contract No." = '' then
                        "Contract Disc. %" := 0
                    else begin
                        GetServHeader;
                        if ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.") then begin
                            if (ServContractHeader."Starting Date" <= WorkDate) and not "Exclude Contract Discount" then begin
                                if not ContractGroup.Get(ServContractHeader."Contract Group Code") then
                                    ContractGroup.Init;
                                if not ContractGroup."Disc. on Contr. Orders Only" or
                                   (ContractGroup."Disc. on Contr. Orders Only" and (ServHeader."Contract No." <> ''))
                                then begin
                                    case Type of
                                        Type::" ":
                                            "Contract Disc. %" := 0;
                                        Type::Item:
                                            begin
                                                ContractServDisc.Init;
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::"Service Item Group";
                                                ContractServDisc."No." := ServItem."Service Item Group Code";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                OnValidateContractNoOnBeforeContractDiscountFind(Rec, ContractServDisc, ServItem);
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                        Type::Resource:
                                            begin
                                                Res.Get("No.");
                                                ContractServDisc.Init;
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::"Resource Group";
                                                ContractServDisc."No." := Res."Resource Group No.";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                        Type::Cost:
                                            begin
                                                ServCost.Get("No.");
                                                ContractServDisc.Init;
                                                ContractServDisc."Contract Type" := ContractServDisc."Contract Type"::Contract;
                                                ContractServDisc."Contract No." := ServContractHeader."Contract No.";
                                                ContractServDisc.Type := ContractServDisc.Type::Cost;
                                                ContractServDisc."No." := "No.";
                                                ContractServDisc."Starting Date" := "Posting Date";
                                                CODEUNIT.Run(CODEUNIT::"ContractDiscount-Find", ContractServDisc);
                                                "Contract Disc. %" := ContractServDisc."Discount %";
                                            end;
                                    end;
                                end else
                                    "Contract Disc. %" := 0;
                            end;
                        end else
                            "Contract Disc. %" := 0;
                    end;

                    if Warranty then
                        case Type of
                            Type::Item:
                                "Warranty Disc. %" := ServItem."Warranty % (Parts)";
                            Type::Resource:
                                "Warranty Disc. %" := ServItem."Warranty % (Labor)";
                            else
                                "Warranty Disc. %" := 0;
                        end;

                    UpdateDiscountsAmounts;
                end;
            end;
        }
        field(5938; "Contract Disc. %"; Decimal)
        {
            Caption = 'Contract Disc. %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(5939; "Warranty Disc. %"; Decimal)
        {
            Caption = 'Warranty Disc. %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateUnitPrice(FieldNo(Warranty));
                UpdateAmounts;
            end;
        }
        field(5965; "Component Line No."; Integer)
        {
            Caption = 'Component Line No.';
        }
        field(5966; "Spare Part Action"; Option)
        {
            Caption = 'Spare Part Action';
            OptionCaption = ' ,Permanent,Temporary,Component Replaced,Component Installed';
            OptionMembers = " ",Permanent,"Temporary","Component Replaced","Component Installed";
        }
        field(5967; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";

            trigger OnValidate()
            var
                NewWarranty: Boolean;
                OldExcludeContractDiscount: Boolean;
            begin
                SetHideWarrantyWarning := true;
                OldExcludeContractDiscount := "Exclude Contract Discount";
                if FaultReasonCode.Get("Fault Reason Code") then begin
                    if FaultReasonCode."Exclude Warranty Discount" and
                       (not (Type in [Type::Item, Type::Resource]))
                    then
                        Error(
                          Text027,
                          FieldCaption("Fault Reason Code"),
                          FaultReasonCode.Code,
                          FaultReasonCode.FieldCaption("Exclude Warranty Discount"));
                    "Exclude Contract Discount" := FaultReasonCode."Exclude Contract Discount";
                    NewWarranty := (not FaultReasonCode."Exclude Warranty Discount") and
                      ("Exclude Warranty" or Warranty);
                    Validate("Exclude Warranty",
                      FaultReasonCode."Exclude Warranty Discount" and
                      ("Exclude Warranty" or Warranty));
                    Validate(Warranty, NewWarranty);
                    if OldExcludeContractDiscount and (not "Exclude Contract Discount") then
                        Validate("Contract No.");
                end else begin
                    "Exclude Contract Discount" := false;
                    if "Exclude Warranty" then begin
                        Validate("Exclude Warranty", false);
                        Validate(Warranty, true);
                    end else
                        if OldExcludeContractDiscount <> "Exclude Contract Discount" then
                            if OldExcludeContractDiscount and (not "Exclude Contract Discount") then
                                Validate("Contract No.")
                            else
                                Validate(Warranty);
                end;
            end;
        }
        field(5968; "Replaced Item No."; Code[20])
        {
            Caption = 'Replaced Item No.';
            TableRelation = IF ("Replaced Item Type" = CONST(Item)) Item
            ELSE
            IF ("Replaced Item Type" = CONST("Service Item")) "Service Item";
        }
        field(5969; "Exclude Contract Discount"; Boolean)
        {
            Caption = 'Exclude Contract Discount';
            Editable = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if Type = Type::"G/L Account" then
                    FieldError(Type);

                if "Fault Reason Code" <> '' then begin
                    FaultReasonCode.Get("Fault Reason Code");
                    if FaultReasonCode."Exclude Contract Discount" and
                       not "Exclude Contract Discount"
                    then
                        Error(
                          Text008,
                          FieldCaption("Exclude Contract Discount"),
                          FaultReasonCode.FieldCaption("Exclude Contract Discount"),
                          "Fault Reason Code",
                          FaultReasonCode.TableCaption);
                end;

                if "Exclude Contract Discount" <> xRec."Exclude Contract Discount" then begin
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text009, FieldCaption("Exclude Contract Discount")), true)
                    then begin
                        "Exclude Contract Discount" := xRec."Exclude Contract Discount";
                        exit;
                    end;
                    Validate("Contract No.");
                    Validate(Warranty);
                end;
            end;
        }
        field(5970; "Replaced Item Type"; Option)
        {
            Caption = 'Replaced Item Type';
            OptionCaption = ' ,Service Item,Item';
            OptionMembers = " ","Service Item",Item;
        }
        field(5994; "Price Adjmt. Status"; Option)
        {
            Caption = 'Price Adjmt. Status';
            Editable = false;
            OptionCaption = ' ,Adjusted,Modified';
            OptionMembers = " ",Adjusted,Modified;
        }
        field(5997; "Line Discount Type"; Option)
        {
            Caption = 'Line Discount Type';
            Editable = false;
            OptionCaption = ' ,Warranty Disc.,Contract Disc.,Line Disc.,Manual';
            OptionMembers = " ","Warranty Disc.","Contract Disc.","Line Disc.",Manual;
        }
        field(5999; "Copy Components From"; Option)
        {
            Caption = 'Copy Components From';
            OptionCaption = 'None,Item BOM,Old Service Item,Old Serv.Item w/o Serial No.';
            OptionMembers = "None","Item BOM","Old Service Item","Old Serv.Item w/o Serial No.";
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";

            trigger OnValidate()
            var
                ReturnReason: Record "Return Reason";
            begin
                if "Return Reason Code" = '' then
                    UpdateUnitPrice(FieldNo("Return Reason Code"));

                if ReturnReason.Get("Return Reason Code") then begin
                    if (ReturnReason."Default Location Code" <> '') and (not IsNonInventoriableItem) then
                        Validate("Location Code", ReturnReason."Default Location Code");
                    if ReturnReason."Inventory Value Zero" then begin
                        Validate("Unit Cost (LCY)", 0);
                        Validate("Unit Price", 0);
                    end else
                        if "Unit Price" = 0 then
                            UpdateUnitPrice(FieldNo("Return Reason Code"));
                end;
            end;
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then
                    UpdateUnitPrice(FieldNo("Customer Disc. Group"));
            end;
        }
        field(7300; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" := UOMMgt.CalcBaseQty("Qty. Picked", "Qty. per Unit of Measure");
                "Completely Picked" := "Qty. Picked" >= 0;
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
            Caption = 'Pick Qty. (Base)';
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
        key(Key2; Type, "No.", "Order Date")
        {
        }
        key(Key3; "Service Item No.", Type, "Posting Date")
        {
        }
        key(Key4; "Document Type", "Bill-to Customer No.", "Currency Code", "Document No.")
        {
            SumIndexFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key5; "Document Type", "Document No.", "Service Item No.")
        {
        }
        key(Key6; "Document Type", "Document No.", "Service Item Line No.", "Serv. Price Adjmt. Gr. Code")
        {
            SumIndexFields = "Line Amount";
        }
        key(Key7; "Document Type", "Document No.", "Service Item Line No.", Type, "No.")
        {
        }
        key(Key8; Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code")
        {
            SumIndexFields = "Quantity (Base)", "Outstanding Qty. (Base)";
        }
        key(Key9; "Appl.-to Service Entry")
        {
        }
        key(Key10; "Document Type", "Document No.", "Service Item Line No.", "Component Line No.")
        {
        }
        key(Key11; "Fault Reason Code")
        {
        }
        key(Key12; "Document Type", "Customer No.", "Shipment No.", "Document No.")
        {
            SumIndexFields = "Outstanding Amount (LCY)";
        }
        key(Key13; "Document Type", "Document No.", "Location Code")
        {
        }
        key(Key14; "Document Type", "Document No.", Type, "No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Type, "No.", Description, Quantity, "Unit of Measure Code", "Line Amount")
        {
        }
    }

    trigger OnDelete()
    var
        Item: Record Item;
        ServiceLine2: Record "Service Line";
    begin
        TestStatusOpen;
        if Type = Type::Item then
            WhseValidateSourceLine.ServiceLineDelete(Rec);
        if Type in [Type::"G/L Account", Type::Cost, Type::Resource] then
            TestField("Qty. Shipped Not Invoiced", 0);

        if ("Document Type" = "Document Type"::Invoice) and ("Appl.-to Service Entry" > 0) then
            Error(Text045);

        if (Quantity <> 0) and ItemExists("No.") then begin
            ReserveServLine.DeleteLine(Rec);
            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
            if "Shipment No." = '' then
                TestField("Qty. Shipped Not Invoiced", 0);
        end;

        ReserveServLine.DeleteLine(Rec);
        if (Type = Type::Item) and Item.Get("No.") then
            CatalogItemMgt.DelNonStockFSM(Rec);

        if (Type <> Type::" ") and
           (("Contract No." <> '') or
            ("Shipment No." <> ''))
        then
            UpdateServDocRegister(true);

        if "Line No." <> 0 then begin
            ServiceLine2.Reset;
            ServiceLine2.SetRange("Document Type", "Document Type");
            ServiceLine2.SetRange("Document No.", "Document No.");
            ServiceLine2.SetRange("Attached to Line No.", "Line No.");
            ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");
            ServiceLine2.DeleteAll(true);
        end;
    end;

    trigger OnInsert()
    begin
        if TempTrackingSpecification.FindFirst then
            InsertItemTracking;

        if Quantity <> 0 then
            ReserveServLine.VerifyQuantity(Rec, xRec);

        if Type = Type::Item then
            if ServHeader.InventoryPickConflict("Document Type", "Document No.", ServHeader."Shipping Advice") then
                DisplayConflictError(ServHeader.InvPickConflictResolutionTxt);

        IsCustCrLimitChecked := false;
    end;

    trigger OnModify()
    begin
        if "Document Type" = ServiceLine."Document Type"::Invoice then
            CheckIfCanBeModified;

        if "Spare Part Action" in
           ["Spare Part Action"::"Component Replaced",
            "Spare Part Action"::"Component Installed",
            "Spare Part Action"::" "]
        then begin
            if (Type <> xRec.Type) or ("No." <> xRec."No.") then
                ReserveServLine.DeleteLine(Rec);
            UpdateReservation(0);
        end;

        UpdateServiceLedgerEntry;
        IsCustCrLimitChecked := false;
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        Text000: Label 'You cannot invoice more than %1 units.';
        Text001: Label 'You cannot invoice more than %1 base units.';
        Text002: Label 'You cannot rename a %1.';
        Text003: Label 'must not be less than %1';
        Text004: Label 'You must confirm %1 %2, because %3 is not equal to %4 in %5 %6.';
        Text005: Label 'The update has been interrupted to respect the warning.';
        Text006: Label 'Replace Component,New Component,Ignore';
        Text007: Label 'You must select a %1.';
        Text008: Label 'You cannot change the value of the %1 field because the %2 field in the Fault Reason Codes window contains a check mark for the %3 %4.';
        Text009: Label 'You have changed the value of the field %1.\Do you want to continue ?';
        Text010: Label '%1 cannot be less than %2.';
        Text011: Label 'When replacing a %1 the quantity must be 1.';
        ManualReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        Text013: Label ' must be 0 when %1 is %2.';
        Text015: Label 'You have already selected %1 %2 for replacement.';
        Text016: Label 'You cannot ship more than %1 units.';
        Text017: Label 'You cannot ship more than %1 base units.';
        Text018: Label '%1 %2 is greater than %3 and was adjusted to %4.';
        CompAlreadyReplacedErr: Label 'The component that you selected has already been replaced in service line %1.', Comment = '%1 = Line No.';
        ServMgtSetup: Record "Service Mgt. Setup";
        ServiceLine: Record "Service Line";
        ServHeader: Record "Service Header";
        ServItem: Record "Service Item";
        ServItemLine: Record "Service Item Line";
        Resource: Record Resource;
        Location: Record Location;
        FaultReasonCode: Record "Fault Reason Code";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SKU: Record "Stockkeeping Unit";
        DimMgt: Codeunit DimensionManagement;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        UOMMgt: Codeunit "Unit of Measure Management";
        CatalogItemMgt: Codeunit "Catalog Item Management";
        ReserveServLine: Codeunit "Service Line-Reserve";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Select: Integer;
        FullAutoReservation: Boolean;
        HideReplacementDialog: Boolean;
        Text022: Label 'The %1 cannot be greater than the %2 set on the %3.';
        Text023: Label 'You must enter a serial number.';
        ReplaceServItemAction: Boolean;
        Text026: Label 'When replacing or creating a service item component you may only enter a whole number into the %1 field.';
        Text027: Label 'The %1 %2 with a check mark in the %3 field cannot be entered if the service line type is other than Item or Resource.';
        Text028: Label 'You cannot consume more than %1 units.';
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
        Text031: Label 'You must specify %1.';
        Text032: Label 'You cannot consume more than %1 base units.';
        Text033: Label 'The line you are trying to change has the adjusted price.\';
        Text034: Label 'Do you want to continue?';
        Text035: Label 'Warehouse';
        Text036: Label 'Inventory';
        Text037: Label 'You cannot change %1 when %2 is %3 and %4 is positive.';
        Text038: Label 'You cannot change %1 when %2 is %3 and %4 is negative.';
        Text039: Label 'You cannot return more than %1 units for %2 %3.';
        Text040: Label 'You must use form %1 to enter %2, if item tracking is used.';
        Text041: Label 'There were no Resource Lines to split.';
        Text042: Label 'When posting the Applied to Ledger Entry %1 will be opened first';
        HideCostWarning: Boolean;
        HideWarrantyWarning: Boolean;
        Text043: Label 'You cannot change the value of the %1 field manually if %2 for this line is %3.';
        Text044: Label 'Do you want to split the resource line and use it to create resource lines\for the other service items with divided amounts?';
        Text045: Label 'You cannot delete this service line because one or more service entries exist for this line.';
        Text046: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text047: Label '%1 can only be set when %2 is set.';
        Text048: Label '%1 cannot be changed when %2 is set.';
        Text049: Label '%1 is required for %2 = %3.', Comment = 'Example: Inventory put-away is required for Line 50000.';
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1=Document';
        StatusCheckSuspended: Boolean;
        Text051: Label 'You cannot add an item line.';
        Text052: Label 'You cannot change the %1 field because one or more service entries exist for this line.';
        Text053: Label 'You cannot modify the service line because one or more service entries exist for this line.';
        IsCustCrLimitChecked: Boolean;
        LocationChangedMsg: Label 'Item %1 with serial number %2 is stored on location %3. The Location Code field on the service line will be updated.', Comment = '%1 = Item No., %2 = Item serial No., %3 = Location code';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        if "Needed by Date" = 0D then begin
            GetServHeader;
            if ServHeader."Order Date" <> 0D then
                Validate("Needed by Date", ServHeader."Order Date")
            else
                Validate("Needed by Date", WorkDate);
        end;

        if CurrFieldNo <> CalledByFieldNo then
            exit;
        if not GuiAllowed then
            exit;
        if Reserve = Reserve::Always then
            exit;
        if (Type <> Type::Item) or ("No." = '') then
            exit;
        if Quantity <= 0 then
            exit;

        IsHandled := false;
        OnCheckItemAvailableOnBeforeCheckNonStock(Rec, CalledByFieldNo, IsHandled);
        if not IsHandled then
            if Nonstock then
                exit;
        if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
            exit;

        if ItemCheckAvail.ServiceInvLineCheck(Rec) then
            ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimensionSetID: Integer;
    begin
        SourceCodeSetup.Get;
        GetServHeader;
        if not ServItemLine.Get(ServHeader."Document Type", ServHeader."No.", "Service Item Line No.") then
            ServItemLine.Init;

        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimensionSetID := ServItemLine."Dimension Set ID";
        if DimensionSetID = 0 then
            DimensionSetID := ServHeader."Dimension Set ID";
        UpdateDimSetupFromDimSetID(TableID, No, DimensionSetID);
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", DimensionSetID, DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
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
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    local procedure ReplaceServItem(): Boolean
    var
        Item: Record Item;
        ServItemReplacement: Page "Service Item Replacement";
        SerialNo: Code[50];
        VariantCode: Code[10];
        LocationCode: Code[10];
    begin
        ErrorIfAlreadySelectedSI("Service Item Line No.");
        Clear(ServItemReplacement);
        ServItemReplacement.SetValues("Service Item No.", "No.", "Variant Code");
        Commit;
        if ServItemReplacement.RunModal = ACTION::OK then begin
            SerialNo := ServItemReplacement.ReturnSerialNo;
            VariantCode := ServItemReplacement.ReturnVariantCode;
            GetItem(Item);
            if SerialNo = '' then
                CheckItemTrackingCode(Item)
            else
                if FindSerialNoStorageLocation(LocationCode, Item."No.", SerialNo, VariantCode) and (LocationCode <> "Location Code") then begin
                    Validate("Location Code", LocationCode);
                    Message(StrSubstNo(LocationChangedMsg, Item."No.", SerialNo, LocationCode));
                end;

            "Variant Code" := VariantCode;
            Validate(Quantity, 1);
            TempTrackingSpecification.DeleteAll;
            TempTrackingSpecification."Serial No." := SerialNo;
            TempTrackingSpecification."Variant Code" := VariantCode;
            TempTrackingSpecification.Insert;
            if "Line No." <> 0 then
                InsertItemTracking;
            case ServItemReplacement.ReturnReplacement of
                0:
                    "Spare Part Action" := "Spare Part Action"::"Temporary";
                1:
                    "Spare Part Action" := "Spare Part Action"::Permanent;
            end;
            "Copy Components From" := ServItemReplacement.ReturnCopyComponentsFrom;
            OnReplaceServItemOnCopyFromReplacementItem(Rec);
            exit(true);
        end;
        ReserveServLine.DeleteLine(Rec);
        ClearFields;
        Validate("No.", '');
        exit(false);
    end;

    local procedure FindSerialNoStorageLocation(var LocationCode: Code[10]; ItemNo: Code[20]; SerialNo: Code[50]; VariantCode: Code[10]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.FindLast then
            exit(false);

        LocationCode := ItemLedgerEntry."Location Code";
        exit(true);
    end;

    local procedure CheckItemTrackingCode(ReplacementItem: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if ReplacementItem."Item Tracking Code" = '' then
            exit;

        ItemTrackingCode.Get(ReplacementItem."Item Tracking Code");
        if ItemTrackingCode."SN Specific Tracking" then
            Error(Text023);
    end;

    local procedure ErrorIfAlreadySelectedSI(ServItemLineNo: Integer)
    var
        Item: Record Item;
    begin
        if "Document Type" <> "Document Type"::Order then
            exit;
        if ServItemLineNo <> 0 then begin
            ServItemLine.Get("Document Type", "Document No.", ServItemLineNo);
            if (ServItemLine."Service Item No." = '') or
               (ServItemLine."Item No." = '') or
               (ServItemLine."Item No." <> "No.")
            then
                exit;
        end;

        ServiceLine.Reset;
        ServiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type, "No.");
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServItemLineNo);
        ServiceLine.SetRange(Type, Type::Item);
        ServiceLine.SetFilter("Line No.", '<>%1', "Line No.");
        ServiceLine.SetRange("No.", "No.");
        if ServiceLine.FindFirst then
            Error(Text015, Item.TableCaption, "No.");
    end;

    local procedure CalculateDiscount()
    var
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
        Discounts: array[4] of Decimal;
        i: Integer;
    begin
        if "Exclude Warranty" or not Warranty then
            Discounts[1] := 0
        else begin
            if ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then
                case Type of
                    Type::Item:
                        "Warranty Disc. %" := ServItemLine."Warranty % (Parts)";
                    Type::Resource:
                        "Warranty Disc. %" := ServItemLine."Warranty % (Labor)";
                end;
            Discounts[1] := "Warranty Disc. %";
        end;

        if "Exclude Contract Discount" then
            if CurrFieldNo = FieldNo("Fault Reason Code") then
                Discounts[2] := "Line Discount %"
            else
                Discounts[2] := 0
        else
            Discounts[2] := "Contract Disc. %";

        ServHeader.Get("Document Type", "Document No.");
        SalesPriceCalcMgt.FindServLineDisc(ServHeader, Rec);
        Discounts[3] := "Line Discount %";
        if Discounts[3] > 100 then
            Discounts[3] := 100;

        "Line Discount Type" := "Line Discount Type"::" ";
        "Line Discount %" := 0;

        if "Line Discount Type" = "Line Discount Type"::Manual then
            Discounts[4] := "Line Discount %"
        else
            Discounts[4] := 0;

        for i := 1 to 4 do
            if Discounts[i] > "Line Discount %" then begin
                "Line Discount Type" := i;
                "Line Discount %" := Discounts[i];
            end;

        OnAfterCalculateDiscount(Rec);
    end;

    procedure UpdateAmounts()
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        if GuiAllowed and (CurrFieldNo <> 0) then
            ConfirmAdjPriceLineChange;

        GetServHeader;

        if "Line Amount" <> xRec."Line Amount" then
            "VAT Difference" := 0;
        if "Line Amount" <>
           Round(
             CalcChargeableQty * "Unit Price",
             Currency."Amount Rounding Precision") - "Line Discount Amount"
        then begin
            "Line Amount" :=
              Round(CalcChargeableQty * "Unit Price",
                Currency."Amount Rounding Precision") - "Line Discount Amount";
            "VAT Difference" := 0;
        end;
        if ServHeader."Tax Area Code" = '' then
            UpdateVATAmounts;

        InitOutstandingAmount;
        if not IsCustCrLimitChecked and (CurrFieldNo <> 0) then begin
            IsCustCrLimitChecked := true;
            CustCheckCrLimit.ServiceLineCheck(Rec);
        end;
        UpdateRemainingCostsAndAmounts;
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        SalesSetup.Get;
        DiscountNotificationMgt.RecallNotification(SalesSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          SalesSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Invoice Discounts");
    end;

    local procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");
    end;

    local procedure GetDate(): Date
    begin
        if ServHeader."Document Type" = ServHeader."Document Type"::Quote then
            exit(WorkDate);

        exit(ServHeader."Posting Date");
    end;

    local procedure GetServHeader()
    begin
        TestField("Document No.");
        if ("Document Type" <> ServHeader."Document Type") or ("Document No." <> ServHeader."No.") then begin
            ServHeader.Get("Document Type", "Document No.");
            if ServHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                ServHeader.TestField("Currency Factor");
                Currency.Get(ServHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
    end;

    local procedure InitHeaderDefaults(ServHeader: Record "Service Header")
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        "Customer No." := ServHeader."Customer No.";
        if "Service Item Line No." <> 0 then begin
            ServItemLine.Get(ServHeader."Document Type", ServHeader."No.", "Service Item Line No.");
            "Ship-to Code" := ServItemLine."Ship-to Code";
        end else
            "Ship-to Code" := ServHeader."Ship-to Code";
        if "Posting Date" = 0D then
            "Posting Date" := ServHeader."Posting Date";
        "Document Type" := ServHeader."Document Type";

        "Order Date" := ServHeader."Order Date";
        "Replaced Item No." := '';
        "Component Line No." := 0;
        "Spare Part Action" := 0;
        "Price Adjmt. Status" := "Price Adjmt. Status"::" ";
        "Exclude Warranty" := false;
        "Exclude Contract Discount" := false;
        "Fault Reason Code" := '';

        "Bill-to Customer No." := ServHeader."Bill-to Customer No.";
        "Customer Price Group" := ServHeader."Customer Price Group";
        "Customer Disc. Group" := ServHeader."Customer Disc. Group";
        "Allow Line Disc." := ServHeader."Allow Line Disc.";
        "Bin Code" := '';
        "Transaction Type" := ServHeader."Transaction Type";
        "Transport Method" := ServHeader."Transport Method";
        "Exit Point" := ServHeader."Exit Point";
        Area := ServHeader.Area;
        "Transaction Specification" := ServHeader."Transaction Specification";

        "Location Code" := '';
        if Type = Type::Resource then
            "Location Code" := ServOrderMgt.FindResLocationCode("No.", ServHeader."Order Date");
        if ("Location Code" = '') and (not IsNonInventoriableItem) then
            "Location Code" := ServHeader."Location Code";

        OnInitHeaderDefaultsOnAfterAssignLocationCode(Rec);

        if Type = Type::Item then begin
            if (xRec."No." <> "No.") and (Quantity <> 0) then
                WhseValidateSourceLine.ServiceLineVerifyChange(Rec, xRec);
            GetLocation("Location Code");
        end;

        "Gen. Bus. Posting Group" := ServHeader."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := ServHeader."VAT Bus. Posting Group";
        "Tax Area Code" := ServHeader."Tax Area Code";
        "Tax Liable" := ServHeader."Tax Liable";
        "Responsibility Center" := ServHeader."Responsibility Center";
        "Posting Date" := ServHeader."Posting Date";
        "Currency Code" := ServHeader."Currency Code";

        "Shipping Agent Code" := ServHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := ServHeader."Shipping Agent Service Code";
        "Shipping Time" := ServHeader."Shipping Time";

        OnAfterAssignHeaderValues(Rec, ServHeader);
    end;

    procedure UpdateUnitPrice(CalledByFieldNo: Integer)
    var
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
    begin
        OnBeforeUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);

        TestField("Qty. per Unit of Measure");
        ServHeader.Get("Document Type", "Document No.");

        CalculateDiscount;
        SalesPriceCalcMgt.FindServLinePrice(ServHeader, Rec, CalledByFieldNo);
        Validate("Unit Price");

        OnAfterUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    procedure ShowDimensions()
    begin
        if ("Contract No." <> '') and ("Appl.-to Service Entry" <> 0) then
            ViewDimensionSetEntries
        else
            "Dimension Set ID" :=
              DimMgt.EditDimensionSet(
                "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
                "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField(Reserve);
        Clear(Reservation);
        Reservation.SetServiceLine(Rec);
        Reservation.RunModal;
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, true);
        ReserveServLine.FilterReservFor(ReservEntry, Rec);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure AutoReserve()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        if Reserve = Reserve::Never then
            FieldError(Reserve);
        ReserveServLine.ReservQuantity(Rec, QtyToReserve, QtyToReserveBase);
        if QtyToReserveBase <> 0 then begin
            ReservMgt.SetServLine(Rec);
            if ReplaceServItemAction then begin
                ReserveServLine.FindReservEntry(Rec, ReservationEntry);
                ReservMgt.SetSerialLotNo(ReservationEntry."Serial No.", ReservationEntry."Lot No.");
            end;
            ReservMgt.AutoReserve(FullAutoReservation, '', "Order Date", QtyToReserve, QtyToReserveBase);
            Find;
            ServiceMgtSetup.Get;
            if (not FullAutoReservation) and (not ServiceMgtSetup."Skip Manual Reservation") then begin
                Commit;
                if ConfirmManagement.GetResponse(ManualReserveQst, true) then begin
                    ShowReservation;
                    Find;
                end;
            end;
        end;
    end;

    local procedure ClearFields()
    var
        TempServLine: Record "Service Line" temporary;
    begin
        TempServLine := Rec;
        Init;

        if CurrFieldNo <> FieldNo(Type) then
            "No." := TempServLine."No.";

        Type := TempServLine.Type;
        if Type <> Type::" " then
            Quantity := TempServLine.Quantity;

        "Line No." := TempServLine."Line No.";
        Validate("Service Item Line No.", TempServLine."Service Item Line No.");
        "Service Item No." := TempServLine."Service Item No.";
        "Service Item Serial No." := TempServLine."Service Item Serial No.";
        "Document Type" := TempServLine."Document Type";
        "Document No." := TempServLine."Document No.";
        "Gen. Bus. Posting Group" := TempServLine."Gen. Bus. Posting Group";
        "Order Date" := TempServLine."Order Date";
        "Customer No." := TempServLine."Customer No.";
        "Ship-to Code" := TempServLine."Ship-to Code";
        "Posting Date" := TempServLine."Posting Date";
        "System-Created Entry" := TempServLine."System-Created Entry";
        "Price Adjmt. Status" := "Price Adjmt. Status"::" ";
        "Time Sheet No." := TempServLine."Time Sheet No.";
        "Time Sheet Line No." := TempServLine."Time Sheet Line No.";
        "Time Sheet Date" := TempServLine."Time Sheet Date";
        if "No." <> xRec."No." then
            Validate("Job Planning Line No.", 0);

        OnAfterClearFields(Rec, xRec, TempServLine, CurrFieldNo);
    end;

    procedure ShowNonstock()
    var
        NonstockItem: Record "Nonstock Item";
        ConfigTemplateHeader: Record "Config. Template Header";
        ItemTemplate: Record "Item Template";
    begin
        TestField(Type, Type::Item);
        TestField("No.", '');
        if PAGE.RunModal(PAGE::"Catalog Item List", NonstockItem) = ACTION::LookupOK then begin
            NonstockItem.TestField("Item Template Code");
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
            ConfigTemplateHeader.SetRange(Code, NonstockItem."Item Template Code");
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplateHeader.FindFirst;

            TestConfigTemplateLineField(NonstockItem."Item Template Code", ItemTemplate.FieldNo("Gen. Prod. Posting Group"));
            TestConfigTemplateLineField(NonstockItem."Item Template Code", ItemTemplate.FieldNo("Inventory Posting Group"));

            "No." := NonstockItem."Entry No.";
            CatalogItemMgt.NonStockFSM(Rec);
            Validate("No.", "No.");
            Validate("Unit Price", NonstockItem."Unit Price");
        end;
    end;

    local procedure TestConfigTemplateLineField(ItemTemplateCode: Code[10]; FieldNo: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ItemTemplateCode);
        ConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateLine.SetRange("Field ID", FieldNo);
        ConfigTemplateLine.FindFirst;
        ConfigTemplateLine.TestField("Default Value");
    end;

    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    local procedure CopyFromCost()
    var
        ServCost: Record "Service Cost";
        GLAcc: Record "G/L Account";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServCost.Get("No.");
        if ServCost."Cost Type" = ServCost."Cost Type"::Travel then
            if ServHeader."Service Zone Code" <> ServCost."Service Zone Code" then
                if not HideCostWarning then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(
                           Text004, ServCost.TableCaption, "No.",
                           ServCost.FieldCaption("Service Zone Code"),
                           ServHeader.FieldCaption("Service Zone Code"),
                           ServHeader.TableCaption, ServHeader."No."), true)
                    then
                        Error(Text005);
        Description := ServCost.Description;
        Validate("Unit Cost (LCY)", ServCost."Default Unit Cost");
        "Unit Price" := ServCost."Default Unit Price";
        "Unit of Measure Code" := ServCost."Unit of Measure Code";
        GLAcc.Get(ServCost."Account No.");
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            GLAcc.TestField("Gen. Prod. Posting Group");
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if "Service Item Line No." <> 0 then
            if FaultReasonCode.Get(ServItemLine."Fault Reason Code") and
               (not FaultReasonCode."Exclude Warranty Discount")
            then
                Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
        Quantity := ServCost."Default Quantity";

        OnAfterAssignServCostValues(Rec, ServCost);
    end;

    local procedure CopyFromStdTxt()
    var
        StandardText: Record "Standard Text";
    begin
        "Tax Area Code" := '';
        "Tax Liable" := false;
        StandardText.Get("No.");
        Description := StandardText.Description;

        OnAfterAssignStdTxtValues(Rec, StandardText);
    end;

    local procedure CopyFromGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc;
        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Allow Invoice Disc." := false;

        OnAfterAssignGLAccountValues(Rec, GLAcc);
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, IsHandled);
        if IsHandled then
            exit;

        GetItem(Item);
        Item.TestField(Blocked, false);
        if Item.IsInventoriableType then
            Item.TestField("Inventory Posting Group");
        Item.TestField("Gen. Prod. Posting Group");
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        GetUnitCost;
        "Allow Invoice Disc." := Item."Allow Invoice Disc.";
        "Units per Parcel" := Item."Units per Parcel";
        CalcFields("Substitution Available");

        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        "Tax Group Code" := Item."Tax Group Code";
        "Posting Group" := Item."Inventory Posting Group";
        "Item Category Code" := Item."Item Category Code";
        "Variant Code" := '';
        Nonstock := Item."Created From Nonstock Item";
        "Unit of Measure Code" := Item."Sales Unit of Measure";

        if ServHeader."Language Code" <> '' then
            GetItemTranslation;

        if Item.Reserve = Item.Reserve::Optional then
            Reserve := ServHeader.Reserve
        else
            Reserve := Item.Reserve;

        if "Service Item Line No." <> 0 then begin
            "Warranty Disc. %" := ServItemLine."Warranty % (Parts)";
            Warranty :=
              ServItemLine.Warranty and
              (ServHeader."Order Date" >= ServItemLine."Warranty Starting Date (Parts)") and
              (ServHeader."Order Date" <= ServItemLine."Warranty Ending Date (Parts)") and
              not "Exclude Warranty";
            Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
        end else begin
            Warranty := false;
            "Warranty Disc. %" := 0;
        end;

        OnAfterAssignItemValues(Rec, Item, xRec, CurrFieldNo, ServHeader);
    end;

    procedure CopyFromServItem(ServItem: Record "Service Item")
    var
        ServItem2: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromServItem(Rec, ServItem, ServItemComponent, IsHandled, HideReplacementDialog);
        if IsHandled then
            exit;

        if ServItem."Item No." = "No." then begin
            ServItemLine.Reset;
            if not HideReplacementDialog then begin
                ReplaceServItemAction := ReplaceServItem;
                if not ReplaceServItemAction then
                    exit;
            end;
        end else begin
            ServItem.CalcFields("Service Item Components");
            if ServItem."Service Item Components" and not HideReplacementDialog then begin
                Select := StrMenu(Text006, 3);
                case Select of
                    1:
                        begin
                            Commit;
                            ServItemComponent.Reset;
                            ServItemComponent.SetRange(Active, true);
                            ServItemComponent.SetRange("Parent Service Item No.", ServItem."No.");
                            if PAGE.RunModal(0, ServItemComponent) = ACTION::LookupOK then begin
                                "Replaced Item Type" := ServItemComponent.Type + 1;
                                "Replaced Item No." := ServItemComponent."No.";
                                "Component Line No." := ServItemComponent."Line No.";
                                CheckIfServItemReplacement("Component Line No.");
                                if ServItemComponent.Type = ServItemComponent.Type::"Service Item" then begin
                                    ServItem2.Get(ServItemComponent."No.");
                                    "Warranty Disc. %" := ServItem2."Warranty % (Parts)";
                                end;
                                "Spare Part Action" := "Spare Part Action"::"Component Replaced";
                            end else
                                Error(Text007, ServItemComponent.TableCaption);
                        end;
                    2:
                        begin
                            "Replaced Item No." := '';
                            "Component Line No." := 0;
                            "Spare Part Action" := "Spare Part Action"::"Component Installed";
                        end;
                end;
            end;
        end;

        OnAfterAssignServItemValues(Rec, ServItem, ServItemComponent, HideReplacementDialog);
    end;

    local procedure CopyFromResource()
    var
        Res: Record Resource;
    begin
        Res.Get("No.");
        Res.CheckResourcePrivacyBlocked(false);
        Res.TestField(Blocked, false);
        Res.TestField("Gen. Prod. Posting Group");
        Description := Res.Name;
        "Description 2" := Res."Name 2";
        if "Service Item Line No." <> 0 then begin
            "Warranty Disc. %" := ServItemLine."Warranty % (Labor)";
            Warranty :=
              ServItemLine.Warranty and
              (ServHeader."Order Date" >= ServItemLine."Warranty Starting Date (Labor)") and
              (ServHeader."Order Date" <= ServItemLine."Warranty Ending Date (Labor)") and
              not "Exclude Warranty";
            Validate("Fault Reason Code", ServItemLine."Fault Reason Code");
        end else begin
            Warranty := false;
            "Warranty Disc. %" := 0;
        end;
        "Unit of Measure Code" := Res."Base Unit of Measure";
        Validate("Unit Cost (LCY)", Res."Unit Cost");
        "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Res."VAT Prod. Posting Group";
        "Tax Group Code" := Res."Tax Group Code";
        FindResUnitCost;

        OnAfterAssignResourceValues(Rec, Res);
    end;

    [Scope('OnPrem')]
    procedure ShowItemSub()
    var
        ItemSubstMgt: Codeunit "Item Subst.";
    begin
        ItemSubstMgt.ItemServiceSubstGet(Rec);
    end;

    procedure SetHideReplacementDialog(NewHideReplacementDialog: Boolean)
    begin
        HideReplacementDialog := NewHideReplacementDialog;
    end;

    procedure CheckIfServItemReplacement(ComponentLineNo: Integer)
    begin
        if "Service Item Line No." <> 0 then begin
            ServiceLine.Reset;
            ServiceLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", "Component Line No.");
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "Document No.");
            ServiceLine.SetRange("Service Item Line No.", "Service Item Line No.");
            ServiceLine.SetFilter("Line No.", '<>%1', "Line No.");
            ServiceLine.SetRange("Component Line No.", ComponentLineNo);
            ServiceLine.SetFilter("Spare Part Action", '<>%1', "Spare Part Action"::" ");
            if ServiceLine.FindFirst then
                Error(CompAlreadyReplacedErr, ServiceLine."Line No.");
        end;
    end;

    procedure IsInbound(): Boolean
    begin
        case "Document Type" of
            "Document Type"::Quote, "Document Type"::Order, ServiceLine."Document Type"::Invoice:
                exit("Quantity (Base)" < 0);
            ServiceLine."Document Type"::"Credit Memo":
                exit("Quantity (Base)" > 0);
        end;

        exit(false);
    end;

    procedure OpenItemTrackingLines()
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        ReserveServLine.CallItemTracking(Rec);
    end;

    local procedure InsertItemTracking()
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ServiceLine := Rec;
        if TempTrackingSpecification.FindFirst then begin
            ReserveServLine.DeleteLine(Rec);
            Clear(CreateReservEntry);
            with ServiceLine do begin
                CreateReservEntry.CreateReservEntryFor(DATABASE::"Service Line", "Document Type", "Document No.",
                  '', 0, "Line No.", "Qty. per Unit of Measure", Quantity, "Quantity (Base)",
                  TempTrackingSpecification."Serial No.", TempTrackingSpecification."Lot No.");
                CreateReservEntry.CreateEntry("No.", "Variant Code", "Location Code", Description,
                  0D, "Posting Date", 0, ReservEntry."Reservation Status"::Surplus);
            end;
            TempTrackingSpecification.DeleteAll;
        end;
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
        Bin: Record Bin;
        BinType: Record "Bin Type";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Type <> Type::Item then
            exit;

        "Bin Code" := '';

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            if not Location."Bin Mandatory" then
                exit;
            if (not Location."Directed Put-away and Pick") or ("Document Type" <> "Document Type"::Order) then begin
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                if ("Document Type" <> "Document Type"::Order) and ("Bin Code" <> '') and Location."Directed Put-away and Pick"
                then begin
                    // Clear the bin code if the bin is not of pick type
                    Bin.Get("Location Code", "Bin Code");
                    BinType.Get(Bin."Bin Type Code");
                    if not BinType.Pick then
                        "Bin Code" := '';
                end;
            end;
        end;
    end;

    local procedure GetItemTranslation()
    var
        ItemTranslation: Record "Item Translation";
    begin
        GetServHeader;
        if ItemTranslation.Get("No.", "Variant Code", ServHeader."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
            OnAfterGetItemTranslation(Rec, ServHeader, ItemTranslation);
        end;
    end;

    local procedure GetSKU(): Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        exit(false);
    end;

    procedure GetUnitCost()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        GetItem(Item);
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        if GetSKU then
            Validate("Unit Cost (LCY)", SKU."Unit Cost" * "Qty. per Unit of Measure")
        else
            Validate("Unit Cost (LCY)", Item."Unit Cost" * "Qty. per Unit of Measure");

        OnAfterGetUnitCost(Rec, Item);
    end;

    procedure FindResUnitCost()
    var
        ResCost: Record "Resource Cost";
    begin
        ResCost.Init;
        ResCost.Code := "No.";
        ResCost."Work Type Code" := "Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        OnAfterResourseFindCost(Rec, ResCost);
        Validate("Unit Cost (LCY)", ResCost."Unit Cost" * "Qty. per Unit of Measure");
    end;

    procedure InitOutstanding()
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            "Outstanding Quantity" := Quantity;
            "Outstanding Qty. (Base)" := "Quantity (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced" - "Quantity Consumed";
            "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)" - "Qty. Consumed (Base)";
        end;
        CalcFields("Reserved Quantity");
        Planned := "Reserved Quantity" = "Outstanding Quantity";
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount;
    end;

    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        if (Quantity = 0) or (CalcChargeableQty = 0) then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Shipped Not Invoiced" := 0;
            "Shipped Not Invoiced (LCY)" := 0;
        end else begin
            GetServHeader;
            AmountInclVAT := CalcLineAmount;
            if not ServHeader."Prices Including VAT" then
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    AmountInclVAT := AmountInclVAT +
                      Round(
                        SalesTaxCalculate.CalculateTax(
                          "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                          CalcLineAmount, "Quantity (Base)", ServHeader."Currency Factor"),
                        Currency."Amount Rounding Precision")
                else
                    AmountInclVAT :=
                      Round(
                        AmountInclVAT *
                        (1 + "VAT %" / 100 * (1 - ServHeader."VAT Base Discount %" / 100)),
                        Currency."Amount Rounding Precision");
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if "Document Type" <> "Document Type"::"Credit Memo" then
                Validate(
                  "Shipped Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Shipped Not Invoiced" / CalcChargeableQty,
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, ServHeader, Currency);
    end;

    procedure InitQtyToShip()
    begin
        if LineRequiresShipmentOrReceipt then begin
            "Qty. to Ship" := 0;
            "Qty. to Ship (Base)" := 0;
        end else begin
            "Qty. to Ship" := "Outstanding Quantity";
            "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end;
        Validate("Qty. to Consume");
        InitQtyToInvoice;

        OnAfterInitQtyToShip(Rec, CurrFieldNo);
    end;

    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;
        CalcInvDiscToInvoice;

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    procedure MaxQtyToInvoice(): Decimal
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then
            exit(Quantity);

        exit("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced" - "Quantity Consumed" - "Qty. to Consume");
    end;

    local procedure MaxQtyToInvoiceBase(): Decimal
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then
            exit("Quantity (Base)");

        exit(
          "Qty. Shipped (Base)" + "Qty. to Ship (Base)" -
          "Qty. Invoiced (Base)" - "Qty. Consumed (Base)" -
          "Qty. to Consume (Base)");
    end;

    local procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetServHeader;
        OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
        if (Quantity = 0) or (CalcChargeableQty = 0) then
            Validate("Inv. Disc. Amount to Invoice", 0)
        else
            Validate(
              "Inv. Disc. Amount to Invoice",
              Round(
                "Inv. Discount Amount" * "Qty. to Invoice" / CalcChargeableQty,
                Currency."Amount Rounding Precision"));

        if OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" then begin
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
            "VAT Difference" := 0;
        end;
        NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    local procedure InitItemAppl(OnlyApplTo: Boolean)
    begin
        "Appl.-to Item Entry" := 0;
        if not OnlyApplTo then
            "Appl.-from Item Entry" := 0;
    end;

    local procedure GetResource()
    begin
        TestField("No.");
        if "No." <> Resource."No." then
            Resource.Get("No.");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        if not ServHeader.Get("Document Type", "Document No.") then begin
            ServHeader."No." := '';
            ServHeader.Init;
        end;
        if ServHeader."Prices Including VAT" then
            exit('2,1,' + GetFieldCaption(FieldNumber));

        exit('2,0,' + GetFieldCaption(FieldNumber));
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Service Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure UpdateVATAmounts()
    var
        ServiceLine2: Record "Service Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalQuantityBase: Decimal;
    begin
        OnBeforeUpdateVATAmounts(Rec);

        GetServHeader;
        ServiceLine2.SetRange("Document Type", "Document Type");
        ServiceLine2.SetRange("Document No.", "Document No.");
        ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");
        if "Line Amount" = 0 then
            if xRec."Line Amount" >= 0 then
                ServiceLine2.SetFilter(Amount, '>%1', 0)
            else
                ServiceLine2.SetFilter(Amount, '<%1', 0)
        else
            if "Line Amount" > 0 then
                ServiceLine2.SetFilter(Amount, '>%1', 0)
            else
                ServiceLine2.SetFilter(Amount, '<%1', 0);
        ServiceLine2.SetRange("VAT Identifier", "VAT Identifier");
        ServiceLine2.SetRange("Tax Group Code", "Tax Group Code");

        if "Line Amount" = "Inv. Discount Amount" then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT"]) and
                ("VAT %" <> 0))
            then
                if not ServiceLine2.IsEmpty then begin
                    ServiceLine2.CalcSums("Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)");
                    TotalLineAmount := ServiceLine2."Line Amount";
                    TotalInvDiscAmount := ServiceLine2."Inv. Discount Amount";
                    TotalAmount := ServiceLine2.Amount;
                    TotalAmountInclVAT := ServiceLine2."Amount Including VAT";
                    TotalQuantityBase := ServiceLine2."Quantity (Base)";
                end;

            if ServHeader."Prices Including VAT" then
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              (TotalLineAmount - TotalInvDiscAmount + CalcLineAmount) / (1 + "VAT %" / 100) -
                              TotalAmount;
                            "VAT Base Amount" :=
                              Round(
                                Amount * (1 - ServHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(TotalAmount + Amount +
                                (TotalAmount + Amount) * (1 - ServHeader."VAT Base Discount %" / 100) * "VAT %" / 100 -
                                TotalAmountInclVAT, Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            ServHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                ServHeader."Currency Factor") -
                              TotalAmount;
                            if Amount <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - Amount) / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end
            else
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        Validate(Amount, Round(CalcLineAmount, Currency."Amount Rounding Precision"));
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := CalcLineAmount;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            Amount := Round(CalcLineAmount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                SalesTaxCalculate.CalculateTax(
                                  "Tax Area Code", "Tax Group Code", "Tax Liable", ServHeader."Posting Date",
                                  TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                  ServHeader."Currency Factor"), Currency."Amount Rounding Precision") -
                              TotalAmountInclVAT;
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                        end;
                end;
        end;

        OnAfterUpdateVATAmounts(Rec);
    end;

    procedure MaxQtyToConsume(): Decimal
    begin
        exit(Quantity - "Quantity Shipped");
    end;

    procedure MaxQtyToConsumeBase(): Decimal
    begin
        exit("Quantity (Base)" - "Qty. Shipped (Base)");
    end;

    procedure InitQtyToConsume()
    begin
        "Qty. to Consume" := MaxQtyToConsume;
        "Qty. to Consume (Base)" := MaxQtyToConsumeBase;
        OnAfterInitQtyToConsume(Rec, CurrFieldNo);

        InitQtyToInvoice;
    end;

    procedure SetServHeader(NewServHeader: Record "Service Header")
    begin
        ServHeader := NewServHeader;

        if ServHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else begin
            ServHeader.TestField("Currency Factor");
            Currency.Get(ServHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping,Consuming; var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; isShip: Boolean)
    var
        Cust: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        QtyFactor: Decimal;
        TotalVATAmount: Decimal;
        RoundingLineInserted: Boolean;
    begin
        Currency.Initialize(ServHeader."Currency Code");

        VATAmountLine.DeleteAll;

        with ServiceLine do begin
            SetRange("Document Type", ServHeader."Document Type");
            SetRange("Document No.", ServHeader."No.");
            SetFilter(Type, '>0');
            SetFilter(Quantity, '<>0');
            SalesSetup.Get;
            if SalesSetup."Invoice Rounding" then begin
                Cust.Get(ServHeader."Bill-to Customer No.");
                CustPostingGroup.Get(Cust."Customer Posting Group");
            end;
            if FindSet then
                repeat
                    if Type = Type::"G/L Account" then
                        RoundingLineInserted := ("No." = CustPostingGroup."Invoice Rounding Account") or RoundingLineInserted;
                    if "VAT Calculation Type" in
                       ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                    then
                        "VAT %" := 0;
                    if not
                       VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0)
                    then
                        VATAmountLine.InsertNewLine(
                          "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "VAT %", "Line Amount" >= 0, false);

                    QtyFactor := 0;
                    case QtyType of
                        QtyType::Invoicing:
                            begin
                                case true of
                                    ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and not isShip:
                                        begin
                                            if CalcChargeableQty <> 0 then
                                                QtyFactor := GetAbsMin("Qty. to Invoice", "Qty. Shipped Not Invoiced") / CalcChargeableQty;
                                            VATAmountLine.Quantity :=
                                              VATAmountLine.Quantity + GetAbsMin("Qty. to Invoice (Base)", "Qty. Shipped Not Invd. (Base)");
                                        end;
                                    "Document Type" in ["Document Type"::"Credit Memo"]:
                                        begin
                                            QtyFactor := GetAbsMin("Qty. to Invoice", Quantity) / Quantity;
                                            VATAmountLine.Quantity += GetAbsMin("Qty. to Invoice (Base)", "Quantity (Base)");
                                        end;
                                    else begin
                                            if CalcChargeableQty <> 0 then
                                                QtyFactor := "Qty. to Invoice" / CalcChargeableQty;
                                            VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                        end;
                                end;
                                VATAmountLine."Line Amount" += Round("Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                                if "Allow Invoice Disc." then
                                    VATAmountLine."Inv. Disc. Base Amount" += Round("Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                                VATAmountLine."Invoice Discount Amount" += "Inv. Disc. Amount to Invoice";
                                VATAmountLine."VAT Difference" += "VAT Difference";
                                VATAmountLine.Modify;
                            end;
                        QtyType::Shipping:
                            begin
                                if "Document Type" in
                                   ["Document Type"::"Credit Memo"]
                                then begin
                                    QtyFactor := 1;
                                    VATAmountLine.Quantity += "Quantity (Base)";
                                end else begin
                                    QtyFactor := "Qty. to Ship" / Quantity;
                                    VATAmountLine.Quantity += "Qty. to Ship (Base)";
                                end;
                                VATAmountLine."Line Amount" += Round("Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                                if "Allow Invoice Disc." then
                                    VATAmountLine."Inv. Disc. Base Amount" += Round("Line Amount" * QtyFactor, Currency."Amount Rounding Precision");
                                VATAmountLine."Invoice Discount Amount" +=
                                  Round("Inv. Discount Amount" * QtyFactor, Currency."Amount Rounding Precision");
                                VATAmountLine."VAT Difference" += "VAT Difference";
                                VATAmountLine.Modify;
                            end;
                        QtyType::Consuming:
                            begin
                                case true of
                                    ("Document Type" = "Document Type"::Order) and not isShip:
                                        begin
                                            QtyFactor := GetAbsMin("Qty. to Consume", "Qty. Shipped Not Invoiced") / Quantity;
                                            VATAmountLine.Quantity += GetAbsMin("Qty. to Consume (Base)", "Qty. Shipped Not Invd. (Base)");
                                        end;
                                    else begin
                                            QtyFactor := "Qty. to Consume" / Quantity;
                                            VATAmountLine.Quantity += "Qty. to Consume (Base)";
                                        end;
                                end;
                            end
                        else begin
                                VATAmountLine.Quantity += "Quantity (Base)";
                                VATAmountLine."Line Amount" += "Line Amount";
                                if "Allow Invoice Disc." then
                                    VATAmountLine."Inv. Disc. Base Amount" += "Line Amount";
                                VATAmountLine."Invoice Discount Amount" += "Inv. Discount Amount";
                                VATAmountLine."VAT Difference" += "VAT Difference";
                                VATAmountLine.Modify;
                            end;
                    end;
                    TotalVATAmount += "Amount Including VAT" - Amount + "VAT Difference";
                until Next = 0;
            SetRange(Type);
            SetRange(Quantity);
        end;

        VATAmountLine.UpdateLines(
          TotalVATAmount, Currency, ServHeader."Currency Factor", ServHeader."Prices Including VAT", ServHeader."VAT Base Discount %",
          ServHeader."Tax Area Code", ServHeader."Tax Liable", ServHeader."Posting Date");

        if RoundingLineInserted and (TotalVATAmount <> 0) then
            if VATAmountLine.Get(ServiceLine."VAT Identifier", ServiceLine."VAT Calculation Type",
                 ServiceLine."Tax Group Code", false, ServiceLine."Line Amount" >= 0)
            then begin
                VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + TotalVATAmount;
                VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + TotalVATAmount;
                VATAmountLine.Modify;
            end;

        OnAfterCalcVATAmountLines(ServHeader, ServiceLine, VATAmountLine, QtyType);
    end;

    local procedure GetAbsMin(QTyToHandle: Decimal; QtyHandled: Decimal): Decimal
    begin
        if QtyHandled = 0 then
            exit(QTyToHandle);
        if Abs(QtyHandled) < Abs(QTyToHandle) then
            exit(QtyHandled);

        exit(QTyToHandle);
    end;

    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
    begin
        if QtyType = QtyType::Shipping then
            exit;

        Currency.Initialize(ServHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll;

        with ServiceLine do begin
            SetRange("Document Type", ServHeader."Document Type");
            SetRange("Document No.", ServHeader."No.");
            SetFilter(Type, '>0');
            SetFilter(Quantity, '<>0');
            case QtyType of
                QtyType::Invoicing:
                    SetFilter("Qty. to Invoice", '<>0');
                QtyType::Shipping:
                    SetFilter("Qty. to Ship", '<>0');
            end;
            LockTable;
            if Find('-') then
                repeat
                    VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0);
                    if VATAmountLine.Modified then begin
                        if not
                           TempVATAmountLineRemainder.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0)
                        then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init;
                            TempVATAmountLineRemainder.Insert;
                        end;

                        if QtyType = QtyType::General then
                            LineAmountToInvoice := "Line Amount"
                        else
                            LineAmountToInvoice :=
                              Round("Line Amount" * "Qty. to Invoice" / CalcChargeableQty, Currency."Amount Rounding Precision");

                        if "Allow Invoice Disc." then begin
                            if VATAmountLine."Inv. Disc. Base Amount" = 0 then
                                InvDiscAmount := 0
                            else begin
                                TempVATAmountLineRemainder."Invoice Discount Amount" +=
                                  VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice / VATAmountLine."Inv. Disc. Base Amount";
                                InvDiscAmount :=
                                  Round(
                                    TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                                TempVATAmountLineRemainder."Invoice Discount Amount" -= InvDiscAmount;
                            end;
                            if QtyType = QtyType::General then begin
                                "Inv. Discount Amount" := InvDiscAmount;
                                CalcInvDiscToInvoice;
                            end else
                                "Inv. Disc. Amount to Invoice" := InvDiscAmount;
                        end else
                            InvDiscAmount := 0;

                        if QtyType = QtyType::General then
                            if ServHeader."Prices Including VAT" then begin
                                if (VATAmountLine.CalcLineAmount = 0) or ("Line Amount" = 0) then begin
                                    VATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * CalcLineAmount / VATAmountLine.CalcLineAmount;
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * CalcLineAmount / VATAmountLine.CalcLineAmount;
                                end;
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                  Round(VATAmount, Currency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - ServHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                            end else begin
                                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                                    VATAmount := CalcLineAmount;
                                    NewAmount := 0;
                                    NewVATBaseAmount := 0;
                                end else begin
                                    NewAmount := CalcLineAmount;
                                    NewVATBaseAmount :=
                                      Round(
                                        NewAmount * (1 - ServHeader."VAT Base Discount %" / 100),
                                        Currency."Amount Rounding Precision");
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmount := 0
                                    else
                                        VATAmount :=
                                          TempVATAmountLineRemainder."VAT Amount" +
                                          VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                end;
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end
                        else begin
                            if VATAmountLine.CalcLineAmount = 0 then
                                VATDifference := 0
                            else
                                VATDifference :=
                                  TempVATAmountLineRemainder."VAT Difference" +
                                  VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) / VATAmountLine.CalcLineAmount;
                            if LineAmountToInvoice = 0 then
                                "VAT Difference" := 0
                            else
                                "VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                        end;

                        if QtyType = QtyType::General then begin
                            Amount := NewAmount;
                            "Amount Including VAT" := Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := NewVATBaseAmount;
                        end;
                        InitOutstanding;
                        Modify;

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - "VAT Difference";
                        TempVATAmountLineRemainder.Modify;
                    end;
                until Next = 0;
            SetRange(Type);
            SetRange(Quantity);
            SetRange("Qty. to Invoice");
            SetRange("Qty. to Ship");
        end;

        OnAfterUpdateVATOnLines(ServHeader, ServiceLine, VATAmountLine, QtyType);
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
            CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
            UnitCost :=
              ("Cost Amount (Expected)" + "Cost Amount (Actual)") / ItemLedgEntry.Quantity;
        end;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ServLine3: Record "Service Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
        end;
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ServLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                ServLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                ServLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := ServLine3;
        end;
    end;

    procedure CalcChargeableQty(): Decimal
    begin
        exit(Quantity - "Quantity Consumed" - "Qty. to Consume");
    end;

    procedure SignedXX(Value: Decimal): Decimal
    begin
        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice:
                exit(-Value);
            "Document Type"::"Credit Memo":
                exit(Value);
        end;
    end;

    procedure IsShipment(): Boolean
    begin
        exit(SignedXX("Quantity (Base)") < 0);
    end;

    local procedure AdjustMaxLabourUnitPrice(ResUnitPrice: Decimal)
    var
        Res: Record Resource;
    begin
        if Type <> Type::Resource then
            exit;
        if (ResUnitPrice > ServHeader."Max. Labor Unit Price") and
           (ServHeader."Max. Labor Unit Price" <> 0)
        then begin
            Res.Get("No.");
            "Unit Price" := ServHeader."Max. Labor Unit Price";
            Message(
              StrSubstNo(
                Text018,
                Res.TableCaption, FieldCaption("Unit Price"),
                ServHeader.FieldCaption("Max. Labor Unit Price"),
                ServHeader."Max. Labor Unit Price"));
        end
    end;

    procedure CheckLineDiscount(LineDisc: Decimal)
    begin
        if ("Line Discount Type" = "Line Discount Type"::"Contract Disc.") and
           ("Contract No." <> '') and not "Exclude Contract Discount" and
           not ("Document Type" = "Document Type"::Invoice)
        then
            Error(Text043, FieldCaption("Line Discount %"), FieldCaption("Line Discount Type"), "Line Discount Type");

        if (LineDisc < "Warranty Disc. %") and
           Warranty and not "Exclude Warranty"
        then
            Error(Text010, FieldCaption("Line Discount %"), FieldCaption("Warranty Disc. %"));

        if "Line Discount %" <> 0 then
            "Line Discount Type" := "Line Discount Type"::Manual
        else
            "Line Discount Type" := "Line Discount Type"::" ";
    end;

    procedure ConfirmAdjPriceLineChange()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Price Adjmt. Status" = "Price Adjmt. Status"::Adjusted then
            if ConfirmManagement.GetResponseOrDefault(Text033 + Text034, true) then
                "Price Adjmt. Status" := "Price Adjmt. Status"::Modified
            else
                Error('');
    end;

    procedure SetHideCostWarning(Value: Boolean)
    begin
        HideCostWarning := Value;
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemTrackingLines: Page "Item Tracking Lines";
        QtyBase: Decimal;
        ShippedQtyNotReturned: Decimal;
    begin
        if "Appl.-from Item Entry" = 0 then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        if "Document Type" in ["Document Type"::"Credit Memo"] then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029);
        end else begin
            if Quantity > 0 then
                FieldError(Quantity, Text030);
        end;

        ItemLedgEntry.Get("Appl.-from Item Entry");
        ItemLedgEntry.TestField(Positive, false);
        ItemLedgEntry.TestField("Item No.", "No.");
        ItemLedgEntry.TestField("Variant Code", "Variant Code");
        if ItemLedgEntry.TrackingExists then
            Error(Text040, ItemTrackingLines.Caption, FieldCaption("Appl.-from Item Entry"));

        if "Document Type" in ["Document Type"::"Credit Memo"] then
            QtyBase := "Quantity (Base)"
        else
            QtyBase := "Qty. to Ship (Base)";

        if Abs(QtyBase) > -ItemLedgEntry."Shipped Qty. Not Returned" then begin
            if "Qty. per Unit of Measure" = 0 then
                ShippedQtyNotReturned := ItemLedgEntry."Shipped Qty. Not Returned"
            else
                ShippedQtyNotReturned :=
                  Round(ItemLedgEntry."Shipped Qty. Not Returned" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            Error(
              Text039,
              -ShippedQtyNotReturned, ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
        end;
    end;

    procedure SetHideWarrantyWarning(Value: Boolean)
    begin
        HideWarrantyWarning := Value;
    end;

    procedure SplitResourceLine()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        SumQty: Decimal;
        Qty: Decimal;
        TempDiscount: Decimal;
        NoOfServItems: Integer;
        NextLine: Integer;
    begin
        TestField(Type, Type::Resource);
        TestField("No.");
        TestField("Service Item Line No.");
        TestField(Quantity);
        TestField("Quantity Shipped", 0);

        ServItemLine.Reset;
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "Document No.");
        NoOfServItems := ServItemLine.Count;
        if NoOfServItems <= 1 then
            Error(Text041);

        if ConfirmManagement.GetResponseOrDefault(Text044, true) then begin
            ServiceLine.Reset;
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "Document No.");
            if ServiceLine.FindLast then
                NextLine := ServiceLine."Line No." + 10000
            else
                NextLine := 10000;

            Qty := Round(Quantity / NoOfServItems, 0.01);
            if ServItemLine.Find('-') then
                repeat
                    if ServItemLine."Line No." <> "Service Item Line No." then begin
                        Clear(ServiceLine);
                        ServiceLine.Init;
                        ServiceLine."Document Type" := "Document Type";
                        ServiceLine."Document No." := "Document No.";
                        ServiceLine."Line No." := NextLine;
                        ServiceLine.Insert(true);
                        ServiceLine.TransferFields(Rec, false);
                        ServiceLine.Validate("Service Item Line No.", ServItemLine."Line No.");
                        ServiceLine.Validate("No.");

                        ServiceLine.Validate(Quantity, Qty);
                        SumQty := SumQty + Qty;
                        if "Qty. to Consume" > 0 then
                            ServiceLine.Validate("Qty. to Consume", Qty);

                        ServiceLine.Validate("Contract No.", ServItemLine."Contract No.");
                        if not ServiceLine."Exclude Warranty" then
                            ServiceLine.Validate(Warranty, ServItemLine.Warranty);

                        TempDiscount := "Line Discount %" - "Contract Disc. %" - "Warranty Disc. %";
                        if TempDiscount > 0 then begin
                            ServiceLine."Line Discount %" := ServiceLine."Line Discount %" + TempDiscount;
                            if ServiceLine."Line Discount %" > 100 then
                                ServiceLine."Line Discount %" := 100;
                            ServiceLine.Validate("Line Discount %");
                        end;

                        ServiceLine.Modify(true);
                        NextLine := NextLine + 10000;
                    end;
                until ServItemLine.Next = 0;

            if ServiceLine.Get("Document Type", "Document No.", "Line No.") then begin
                if "Qty. to Consume" > 0 then
                    ServiceLine.Validate("Qty. to Consume", Quantity - SumQty);
                ServiceLine.Validate(Quantity, Quantity - SumQty);
                ServiceLine.Modify(true);
            end;
        end;
    end;

    local procedure UpdateDiscountsAmounts()
    begin
        if Type <> Type::" " then begin
            TestField("Qty. per Unit of Measure");
            CalculateDiscount;
            Validate("Unit Price");
        end;
    end;

    local procedure UpdateRemainingCostsAndAmounts()
    var
        TotalPrice: Decimal;
        AmountRoundingPrecision: Decimal;
        AmountRoundingPrecisionFCY: Decimal;
    begin
        if "Job Remaining Qty." <> 0 then begin
            Clear(Currency);
            Currency.InitRoundingPrecision;
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            GetServHeader;
            AmountRoundingPrecisionFCY := Currency."Amount Rounding Precision";

            "Job Remaining Total Cost" := Round("Unit Cost" * "Job Remaining Qty.", AmountRoundingPrecisionFCY);
            "Job Remaining Total Cost (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  GetDate, "Currency Code",
                  "Job Remaining Total Cost", ServHeader."Currency Factor"),
                AmountRoundingPrecision);

            TotalPrice := Round("Job Remaining Qty." * "Unit Price", AmountRoundingPrecisionFCY);
            "Job Remaining Line Amount" := TotalPrice - Round(TotalPrice * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
        end else begin
            "Job Remaining Total Cost" := 0;
            "Job Remaining Total Cost (LCY)" := 0;
            "Job Remaining Line Amount" := 0;
        end;
    end;

    local procedure UpdateServDocRegister(DeleteRecord: Boolean)
    var
        ServiceLine2: Record "Service Line";
        ServDocReg: Record "Service Document Register";
    begin
        ServiceLine2.Reset;
        ServiceLine2.SetRange("Document Type", "Document Type");
        ServiceLine2.SetRange("Document No.", "Document No.");
        if DeleteRecord then
            ServiceLine2.SetRange("Contract No.", "Contract No.")
        else
            ServiceLine2.SetRange("Contract No.", xRec."Contract No.");
        ServiceLine2.SetFilter("Line No.", '<>%1', "Line No.");

        if ServiceLine2.IsEmpty then
            if xRec."Contract No." <> '' then begin
                ServDocReg.Reset;
                if "Document Type" = "Document Type"::Invoice then
                    ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::Invoice)
                else
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::"Credit Memo");
                ServDocReg.SetRange("Destination Document No.", "Document No.");
                ServDocReg.SetRange("Source Document Type", ServDocReg."Source Document Type"::Contract);
                ServDocReg.SetRange("Source Document No.", xRec."Contract No.");
                ServDocReg.DeleteAll;
            end;

        if ("Contract No." <> '') and (Type <> Type::" ") and not DeleteRecord then begin
            if "Document Type" = "Document Type"::Invoice then
                ServDocReg.InsertServSalesDocument(
                  ServDocReg."Source Document Type"::Contract, "Contract No.",
                  ServDocReg."Destination Document Type"::Invoice, "Document No.")
            else
                if "Document Type" = "Document Type"::"Credit Memo" then
                    ServDocReg.InsertServSalesDocument(
                      ServDocReg."Source Document Type"::Contract, "Contract No.",
                      ServDocReg."Destination Document Type"::"Credit Memo", "Document No.")
        end;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Service Line", "Document Type",
            "Document No.", '', 0, "Line No."));
    end;

    local procedure UpdateReservation(CalledByFieldNo: Integer)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        if (CurrFieldNo <> CalledByFieldNo) and (CurrFieldNo <> 0) then
            exit;

        case CalledByFieldNo of
            FieldNo("Needed by Date"), FieldNo("Planned Delivery Date"):
                if (xRec."Needed by Date" <> "Needed by Date") and
                   (Quantity <> 0) and
                   (Reserve <> Reserve::Never)
                then
                    ReservationCheckDateConfl.ServiceInvLineCheck(Rec, true);
            FieldNo(Quantity):
                ReserveServLine.VerifyQuantity(Rec, xRec);
        end;
        ReserveServLine.VerifyChange(Rec, xRec);
    end;

    procedure ShowTracking()
    var
        OrderTrackingForm: Page "Order Tracking";
    begin
        OrderTrackingForm.SetServLine(Rec);
        OrderTrackingForm.RunModal;
    end;

    procedure ShowOrderPromisingLine()
    var
        OrderPromisingLine: Record "Order Promising Line";
        OrderPromisingLines: Page "Order Promising Lines";
    begin
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLine.SetRange("Source ID", "Document No.");
        OrderPromisingLine.SetRange("Source Line No.", "Line No.");

        OrderPromisingLines.SetSourceType(OrderPromisingLine."Source Type"::"Service Order");
        OrderPromisingLines.SetTableView(OrderPromisingLine);
        OrderPromisingLines.RunModal;
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset;
        SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type");
        SetRange("Document Type", "Document Type"::Order);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Needed by Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(not IsEmpty);
    end;

    local procedure UpdateServiceLedgerEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LCYRoundingPrecision: Decimal;
        CurrencyFactor: Decimal;
    begin
        if "Appl.-to Service Entry" = 0 then
            exit;
        if not ServiceLedgerEntry.Get("Appl.-to Service Entry") then
            exit;
        if ("Unit Price" = xRec."Unit Price") and ("Unit Cost" = xRec."Unit Cost") and (Amount = xRec.Amount) and
           ("Line Discount Amount" = xRec."Line Discount Amount") and ("Line Discount %" = xRec."Line Discount %")
        then
            exit;

        CurrencyFactor := 1;
        if "Currency Code" <> '' then begin
            CurrencyExchangeRate.SetRange("Currency Code", "Currency Code");
            CurrencyExchangeRate.SetRange("Starting Date", 0D, "Order Date");
            if CurrencyExchangeRate.FindLast then
                CurrencyFactor := CurrencyExchangeRate."Adjustment Exch. Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";
        end;
        GeneralLedgerSetup.Get;
        LCYRoundingPrecision := 0.01;
        if Currency.Get(GeneralLedgerSetup."LCY Code") then
            LCYRoundingPrecision := Currency."Amount Rounding Precision";

        if "Unit Price" <> xRec."Unit Price" then
            ServiceLedgerEntry."Unit Price" := -Round("Unit Price" / CurrencyFactor, LCYRoundingPrecision);
        if "Unit Cost (LCY)" <> xRec."Unit Cost (LCY)" then
            ServiceLedgerEntry."Unit Cost" := "Unit Cost (LCY)";
        if Amount <> xRec.Amount then begin
            ServiceLedgerEntry.Amount := -Amount;
            ServiceLedgerEntry."Amount (LCY)" := -Round(Amount / CurrencyFactor, LCYRoundingPrecision);
        end;
        if "Line Discount Amount" <> xRec."Line Discount Amount" then
            ServiceLedgerEntry."Discount Amount" := Round("Line Discount Amount" / CurrencyFactor, LCYRoundingPrecision);
        if "Line Discount %" <> xRec."Line Discount %" then
            ServiceLedgerEntry."Discount %" := "Line Discount %";
        ServiceLedgerEntry.Modify;
    end;

    local procedure UpdateWithWarehouseShip()
    begin
        if Type <> Type::Item then
            exit;
        if "Document Type" in ["Document Type"::Quote, "Document Type"::Order] then
            if Location.RequireShipment("Location Code") then begin
                Validate("Qty. to Ship", 0);
                Validate("Qty. to Invoice", 0);
            end else
                Validate("Qty. to Ship", "Outstanding Quantity");
    end;

    local procedure CheckWarehouse()
    var
        Location2: Record Location;
        WhseSetup: Record "Warehouse Setup";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[100];
    begin
        GetLocation("Location Code");
        if "Location Code" = '' then begin
            WhseSetup.Get;
            Location2."Require Shipment" := WhseSetup."Require Shipment";
            Location2."Require Pick" := WhseSetup."Require Pick";
            Location2."Require Receive" := WhseSetup."Require Receive";
            Location2."Require Put-away" := WhseSetup."Require Put-away";
        end else
            Location2 := Location;

        DialogText := Text035 + ' ';

        if "Document Type" = "Document Type"::Order then
            if Location2."Directed Put-away and Pick" then begin
                ShowDialog := ShowDialog::Error;
                if Quantity >= 0 then
                    DialogText := DialogText + ' ' + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                else
                    DialogText := DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"));
            end else begin
                if (Quantity >= 0) and (Location2."Require Shipment" or Location2."Require Pick") then begin
                    if WhseValidateSourceLine.WhseLinesExist(DATABASE::"Service Line", "Document Type", "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Shipment" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Shipment" then
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                    else begin
                        DialogText := Text036;
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick"));
                    end;
                end;

                if (Quantity < 0) and (Location2."Require Receive" or Location2."Require Put-away") then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Service Line",
                         "Document Type",
                         "Document No.",
                         "Line No.",
                         0,
                         Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Receive" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Receive" then
                        DialogText := DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
                    else
                        DialogText := Text036 + ' ' + Location2.GetRequirementText(Location2.FieldNo("Require Put-away"));
                end;
            end;

        case ShowDialog of
            ShowDialog::Message:
                Message(WhseRequirementMsg, DialogText);
            ShowDialog::Error:
                Error(Text049, DialogText, FieldCaption("Line No."), "Line No.");
        end;

        HandleDedicatedBin(true);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    local procedure TestStatusOpen()
    var
        ServHeader: Record "Service Header";
    begin
        ServHeader.Get("Document Type", "Document No.");
        OnBeforeTestStatusOpen(Rec, ServHeader);

        if StatusCheckSuspended then
            exit;

        if (Type = Type::Item) or (xRec.Type = Type::Item) then
            ServHeader.TestField("Release Status", ServHeader."Release Status"::Open);

        OnAfterTestStatusOpen(Rec, ServHeader);
    end;

    procedure SuspendStatusCheck(bSuspend: Boolean)
    begin
        StatusCheckSuspended := bSuspend;
    end;

    local procedure LineRequiresShipmentOrReceipt(): Boolean
    var
        Location: Record Location;
    begin
        if ("Document Type" <> "Document Type"::Order) or (Type <> Type::Item) then
            exit(false);
        exit(Location.RequireReceive("Location Code") or Location.RequireShipment("Location Code"));
    end;

    local procedure DisplayConflictError(ErrTxt: Text[500])
    var
        DisplayedError: Text[600];
    begin
        DisplayedError := Text051 + ErrTxt;
        Error(DisplayedError);
    end;

    procedure GetDueDate(): Date
    begin
        exit(EvaluateDaysBack("Shipping Time", "Needed by Date"));
    end;

    procedure GetShipmentDate(): Date
    var
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
    begin
        if Location.Get("Location Code") then
            exit(EvaluateDaysBack(Location."Outbound Whse. Handling Time", GetDueDate));
        InventorySetup.Get;
        exit(EvaluateDaysBack(InventorySetup."Outbound Whse. Handling Time", GetDueDate));
    end;

    procedure OutstandingInvoiceAmountFromShipment(CustomerNo: Code[20]): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetCurrentKey("Document Type", "Customer No.", "Shipment No.");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Customer No.", CustomerNo);
        ServiceLine.SetFilter("Shipment No.", '<>%1', '');
        ServiceLine.CalcSums("Outstanding Amount (LCY)");
        exit(ServiceLine."Outstanding Amount (LCY)");
    end;

    local procedure EvaluateDaysBack(InputFormula: DateFormula; InputDate: Date): Date
    var
        DFCode: Code[10];
        DF: DateFormula;
    begin
        if Format(InputFormula) = '' then
            exit(InputDate);
        DFCode := Format(InputFormula);
        if not (CopyStr(DFCode, 1, 1) in ['+', '-']) then
            DFCode := '+' + DFCode;
        DFCode := ConvertStr(DFCode, '+-', '-+');
        Evaluate(DF, DFCode);
        exit(CalcDate(DF, InputDate));
    end;

    local procedure CheckIfCanBeModified()
    begin
        if ("Appl.-to Service Entry" > 0) and ("Contract No." <> '') then
            Error(Text053);
    end;

    local procedure ViewDimensionSetEntries()
    begin
        DimMgt.ShowDimensionSet(
          "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document No.", "Line No."));
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure TestBinCode()
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Location Code" = '') or (Type <> Type::Item) then
            exit;
        Location.Get("Location Code");
        if not Location."Bin Mandatory" then
            exit;
        if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) or
           not Location."Directed Put-away and Pick"
        then
            TestField("Bin Code");
    end;

    procedure GetNextLineNo(ServiceLineSource: Record "Service Line"; BelowxRec: Boolean): Integer
    var
        ServiceLine: Record "Service Line";
        LowLineNo: Integer;
        HighLineNo: Integer;
        NextLineNo: Integer;
        LineStep: Integer;
    begin
        LowLineNo := 0;
        HighLineNo := 0;
        NextLineNo := 0;
        LineStep := 10000;
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "Document No.");

        if ServiceLine.Find('+') then
            if not ServiceLine.Get(ServiceLineSource."Document Type", ServiceLineSource."Document No.", ServiceLineSource."Line No.") then
                NextLineNo := ServiceLine."Line No." + LineStep
            else
                if BelowxRec then begin
                    ServiceLine.FindLast;
                    NextLineNo := ServiceLine."Line No." + LineStep;
                end else
                    if ServiceLine.Next(-1) = 0 then begin
                        LowLineNo := 0;
                        HighLineNo := ServiceLineSource."Line No.";
                    end else begin
                        ServiceLine := ServiceLineSource;
                        ServiceLine.Next(-1);
                        LowLineNo := ServiceLine."Line No.";
                        HighLineNo := ServiceLineSource."Line No.";
                    end
        else
            NextLineNo := LineStep;

        if NextLineNo = 0 then
            NextLineNo := Round((LowLineNo + HighLineNo) / 2, 1, '<');

        if ServiceLine.Get("Document Type", "Document No.", NextLineNo) then
            exit(0);
        exit(NextLineNo);
    end;

    [Scope('OnPrem')]
    procedure GetLineNo(): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        if "Line No." <> 0 then
            if not ServiceLine.Get("Document Type", "Document No.", "Line No.") then
                exit("Line No.");

        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "Document No.");
        if ServiceLine.FindLast() then
            exit(ServiceLine."Line No." + 10000);
        exit(10000);
    end;

    procedure DeleteWithAttachedLines()
    begin
        SetRange("Document Type", "Document Type");
        SetRange("Document No.", "Document No.");
        SetRange("Attached to Line No.", "Line No.");
        DeleteAll;

        SetRange("Document Type");
        SetRange("Document No.");
        SetRange("Attached to Line No.");
        Delete;
    end;

    procedure IsNonInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem(Item);
        exit(Item.IsNonInventoriableType);
    end;

    local procedure UpdateDimSetupFromDimSetID(var TableID: array[10] of Integer; var No: array[10] of Code[20]; InheritFromDimSetID: Integer)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        LastAddedTableID: Integer;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, InheritFromDimSetID);
        ServHeader.Get("Document Type", "Document No.");
        LastAddedTableID := 3;
        UpdateDimSetupByDefaultDim(
          DATABASE::"Service Order Type", ServHeader."Service Order Type", TempDimSetEntry, TableID, No, LastAddedTableID);
        UpdateDimSetupByDefaultDim(
          DATABASE::Customer, ServHeader."Bill-to Customer No.", TempDimSetEntry, TableID, No, LastAddedTableID);
        UpdateDimSetupByDefaultDim(
          DATABASE::"Salesperson/Purchaser", ServHeader."Salesperson Code", TempDimSetEntry, TableID, No, LastAddedTableID);
        UpdateDimSetupByDefaultDim(
          DATABASE::"Service Contract Header", ServHeader."Contract No.", TempDimSetEntry, TableID, No, LastAddedTableID);
        UpdateDimSetupByDefaultDim(
          DATABASE::"Service Item", ServItemLine."Service Item No.", TempDimSetEntry, TableID, No, LastAddedTableID);
        UpdateDimSetupByDefaultDim(
          DATABASE::"Service Item Group", ServItemLine."Service Item Group Code", TempDimSetEntry, TableID, No, LastAddedTableID);
    end;

    local procedure UpdateDimSetupByDefaultDim(SourceID: Integer; SourceNo: Code[20]; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var LastAddedTableID: Integer)
    var
        DefaultDim: Record "Default Dimension";
        TableAdded: Boolean;
    begin
        if SourceNo = '' then
            exit;

        DefaultDim.SetRange("Table ID", SourceID);
        DefaultDim.SetRange("No.", SourceNo);
        if DefaultDim.FindSet then
            repeat
                TempDimSetEntry.SetRange("Dimension Code", DefaultDim."Dimension Code");
                TempDimSetEntry.SetRange("Dimension Value Code", DefaultDim."Dimension Value Code");
                if TempDimSetEntry.FindFirst then begin
                    UpdateDimSetup(TableID, No, DefaultDim."Table ID", DefaultDim."No.", LastAddedTableID);
                    TableAdded := true;
                end;
            until (DefaultDim.Next = 0) or TableAdded;
    end;

    local procedure UpdateDimSetup(var TableID: array[10] of Integer; var No: array[10] of Code[20]; NewTableID: Integer; NewNo: Code[20]; var LastAddedTableID: Integer)
    var
        TableAlreadyAdded: Boolean;
        i: Integer;
    begin
        for i := 1 to LastAddedTableID do
            if TableID[i] = NewTableID then
                TableAlreadyAdded := true;

        if not TableAlreadyAdded then begin
            LastAddedTableID += 1;
            TableID[LastAddedTableID] := NewTableID;
            No[LastAddedTableID] := NewNo;
        end;
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
    begin
        if Round(CalcChargeableQty * "Unit Price", Currency."Amount Rounding Precision") <> 0 then begin
            LineDiscountPct := Round(
                "Line Discount Amount" / Round(CalcChargeableQty * "Unit Price", Currency."Amount Rounding Precision") * 100,
                0.00001);
            if not (LineDiscountPct in [0 .. 100]) then
                Error(LineDiscountPctErr);
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var ServiceLine: Record "Service Line"; StandardText: Record "Standard Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var ServiceLine: Record "Service Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignServCostValues(var ServiceLine: Record "Service Line"; ServiceCost: Record "Service Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var ServiceLine: Record "Service Line"; Item: Record Item; xServiceLine: Record "Service Line"; CallingFieldNo: Integer; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignServItemValues(var ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item"; ServiceItemComp: Record "Service Item Component"; HideReplacementDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var ServiceLine: Record "Service Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var ServiceLine: Record "Service Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDiscount(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearFields(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; TempServiceLine: Record "Service Line" temporary; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTranslation(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var ServiceLine: Record "Service Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ServiceLine: Record "Service Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResourseFindCost(var ServiceLine: Record "Service Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var ServHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping,Consuming)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToConsume(var ServiceLine: Record "Service Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ServiceLine: Record "Service Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromServItem(var ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item"; ServItemComponent: Record "Service Item Component"; var IsHandled: Boolean; var HideReplacementDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBinCode(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailableOnBeforeCheckNonStock(var ServiceLine: Record "Service Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitHeaderDefaultsOnAfterAssignLocationCode(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplaceServItemOnCopyFromReplacementItem(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeContractDiscountFind(var ServiceLine: Record "Service Line"; var ContractServDisc: Record "Contract/Service Discount"; ServItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAssignItem(var ServiceLine: Record "Service Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAssignItemVariant(var ServiceLine: Record "Service Line"; ItemVariant: Record "Item Variant")
    begin
    end;
}

