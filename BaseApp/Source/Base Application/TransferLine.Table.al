table 5741 "Transfer Line"
{
    Caption = 'Transfer Line';
    DrillDownPageID = "Transfer Lines";
    LookupPageID = "Transfer Lines";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item WHERE(Type = CONST(Inventory),
                                        Blocked = CONST(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempTransferLine: Record "Transfer Line" temporary;
                ReturnValue: Text[50];
            begin
                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                Item.TryGetItemNo(ReturnValue, "Item No.", true);
                "Item No." := CopyStr(ReturnValue, 1, MaxStrLen("Item No."));
                ReserveTransferLine.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. Inbnd. (Base)");
                TestField("Reserved Qty. Inbnd. (Base)", 0);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);

                TempTransferLine := Rec;
                Init;
                "Item No." := TempTransferLine."Item No.";
                OnValidateItemNoOnCopyFromTempTransLine(Rec, TempTransferLine);
                if "Item No." = '' then
                    exit;

                OnValidateItemNoOnAfterInitLine(Rec, TempTransferLine);

                GetTransHeader;
                GetItem;
                GetDefaultBin("Transfer-from Code", "Transfer-to Code");

                Item.TestField(Blocked, false);
                Item.TestField(Type, Item.Type::Inventory);

                Description := Item.Description;
                "Description 2" := Item."Description 2";
                Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
                Validate("Inventory Posting Group", Item."Inventory Posting Group");
                Validate(Quantity, xRec.Quantity);
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
                Validate("Gross Weight", Item."Gross Weight");
                Validate("Net Weight", Item."Net Weight");
                Validate("Unit Volume", Item."Unit Volume");
                Validate("Units per Parcel", Item."Units per Parcel");
                "Item Category Code" := Item."Item Category Code";

                OnAfterAssignItemValues(Rec, Item);

                CreateDim(DATABASE::Item, "Item No.");
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                if Quantity <> 0 then
                    TestField("Item No.");
                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                if ((Quantity * "Quantity Shipped") < 0) or
                   (Abs(Quantity) < Abs("Quantity Shipped"))
                then
                    FieldError(Quantity, StrSubstNo(Text002, FieldCaption("Quantity Shipped")));
                if (("Quantity (Base)" * "Qty. Shipped (Base)") < 0) or
                   (Abs("Quantity (Base)") < Abs("Qty. Received (Base)"))
                then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Qty. Shipped (Base)")));
                InitQtyInTransit;
                InitOutstandingQty;
                InitQtyToShip;
                InitQtyToReceive;
                CheckItemAvailable(FieldNo(Quantity));

                ReserveTransferLine.VerifyQuantity(Rec, xRec);

                UpdateWithWarehouseShipReceive;

                IsHandled := false;
                OnValidateQuantityOnBeforeTransLineVerifyChange(Rec, xRec, IsHandled);
                if not IsHandled then
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(5; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
            end;
        }
        field(6; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetLocation("Transfer-from Code");
                if CurrFieldNo <> 0 then begin
                    if Location."Require Shipment" and
                       ("Qty. to Ship" <> 0)
                    then
                        CheckWarehouse(Location, false);
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                end;

                if "Qty. to Ship" > "Outstanding Quantity" then
                    if "Outstanding Quantity" > 0 then
                        Error(
                          Text005,
                          "Outstanding Quantity")
                    else
                        Error(Text006);
                "Qty. to Ship (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");

                if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then
                    Validate("Qty. to Receive", "Qty. to Ship");
            end;
        }
        field(7; "Qty. to Receive"; Decimal)
        {
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetLocation("Transfer-to Code");
                if CurrFieldNo <> 0 then begin
                    if Location."Require Receive" and
                       ("Qty. to Receive" <> 0)
                    then
                        CheckWarehouse(Location, true);
                    WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                end;

                GetTransferHeaderNoVerification;

                if not TransHeader."Direct Transfer" and ("Direct Transfer" = xRec."Direct Transfer") then
                    if "Qty. to Receive" > "Qty. in Transit" then
                        if "Qty. in Transit" > 0 then
                            Error(
                              Text008,
                              "Qty. in Transit")
                        else
                            Error(Text009);
                "Qty. to Receive (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. to Receive", "Qty. per Unit of Measure");
            end;
        }
        field(8; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Shipped (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Quantity Shipped", "Qty. per Unit of Measure");
                InitQtyInTransit;
                InitOutstandingQty;
                InitQtyToShip;
                InitQtyToReceive;
            end;
        }
        field(9; "Quantity Received"; Decimal)
        {
            Caption = 'Quantity Received';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Received (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Quantity Received", "Qty. per Unit of Measure");
                InitQtyInTransit;
                InitOutstandingQty;
                InitQtyToReceive;
            end;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(11; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(12; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            TableRelation = Item WHERE(Type = CONST(Inventory),
                                        Blocked = CONST(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Item: Record Item;
                ReturnValue: Text[50];
                ItemDescriptionIsNo: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if (StrLen(Description) <= MaxStrLen(Item."No.")) and ("Item No." <> '') then
                    ItemDescriptionIsNo := Item.Get(Description);

                if ("Item No." <> '') and (not ItemDescriptionIsNo) and (Description <> '') then begin
                    Item.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
                    if not Item.FindFirst then
                        exit;
                    if Item."No." = "Item No." then
                        exit;
                    if ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(AnotherItemWithSameDescrQst, Item."No.", Item.Description), true)
                    then
                        Validate("Item No.", Item."No.");
                    exit;
                end;

                if Item.TryGetItemNoOpenCard(ReturnValue, Description, false, true, true) then
                    case ReturnValue of
                        '':
                            Description := xRec.Description;
                        "Item No.":
                            Description := xRec.Description;
                        else begin
                                CurrFieldNo := FieldNo("Item No.");
                                Validate("Item No.", CopyStr(ReturnValue, 1, MaxStrLen(Item."No.")));
                            end;
                    end;

                if "Item No." <> '' then
                    GetItem;
            end;
        }
        field(14; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
            end;
        }
        field(15; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
            end;
        }
        field(16; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(17; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(18; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(19; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(21; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(22; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(23; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                UnitOfMeasure: Record "Unit of Measure";
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TestField("Quantity Shipped", 0);
                TestField("Qty. Shipped (Base)", 0);
                TestField("Quantity Received", 0);
                TestField("Qty. Received (Base)", 0);
                ReserveTransferLine.VerifyChange(Rec, xRec);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init();
                    "Unit of Measure" := UnitOfMeasure.Description;
                end;
                GetItem;
                Validate("Qty. per Unit of Measure", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"));
                "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                Validate(Quantity);
            end;
        }
        field(24; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(26; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(27; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(30; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                ReserveTransferLine.VerifyChange(Rec, xRec);
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);

                if "Variant Code" = '' then
                    exit;

                GetDefaultBin("Transfer-from Code", "Transfer-to Code");
                ItemVariant.Get("Item No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";

                CheckItemAvailable(FieldNo("Variant Code"));
            end;
        }
        field(31; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(33; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            Editable = false;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(true));

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
            end;
        }
        field(34; "Qty. in Transit"; Decimal)
        {
            Caption = 'Qty. in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(35; "Qty. in Transit (Base)"; Decimal)
        {
            Caption = 'Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(36; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                if "Transfer-from Code" <> xRec."Transfer-from Code" then begin
                    "Transfer-from Bin Code" := '';
                    GetDefaultBin("Transfer-from Code", '');
                end;

                CheckItemAvailable(FieldNo("Transfer-from Code"));
                ReserveTransferLine.VerifyChange(Rec, xRec);
                UpdateWithWarehouseShipReceive;
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(37; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            Editable = false;
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Quantity Shipped", 0);
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                if "Transfer-to Code" <> xRec."Transfer-to Code" then begin
                    "Transfer-To Bin Code" := '';
                    GetDefaultBin('', "Transfer-to Code");
                end;

                ReserveTransferLine.VerifyChange(Rec, xRec);
                UpdateWithWarehouseShipReceive;
                WhseValidateSourceLine.TransLineVerifyChange(Rec, xRec);
            end;
        }
        field(38; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                CheckItemAvailable(FieldNo("Shipment Date"));
                DateConflictCheck;
            end;
        }
        field(39; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.CalcShipmentDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                CheckItemAvailable(FieldNo("Shipment Date"));
                DateConflictCheck;
            end;
        }
        field(40; "Derived From Line No."; Integer)
        {
            Caption = 'Derived From Line No.';
            TableRelation = "Transfer Line"."Line No." WHERE("Document No." = FIELD("Document No."));
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.GetShippingTime(
                  "Transfer-from Code", "Transfer-to Code",
                  "Shipping Agent Code", "Shipping Agent Service Code",
                  "Shipping Time");
                TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                CheckItemAvailable(FieldNo("Shipping Agent Service Code"));
                DateConflictCheck;
            end;
        }
        field(43; "Appl.-to Item Entry"; Integer)
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
                ItemTrackingLines: Page "Item Tracking Lines";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Quantity);
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    if (ItemLedgEntry."Lot No." <> '') or (ItemLedgEntry."Serial No." <> '') then
                        Error(MustUseTrackingErr, ItemTrackingLines.Caption, FieldCaption("Appl.-to Item Entry"));
                    if Abs("Qty. to Ship (Base)") > ItemLedgEntry.Quantity then
                        Error(ShippingMoreUnitsThanReceivedErr, ItemLedgEntry.Quantity, ItemLedgEntry."Document No.");

                    ItemLedgEntry.TestField("Location Code", "Transfer-from Code");
                    if not ItemLedgEntry.Open then
                        Message(LedgEntryWillBeOpenedMsg, "Appl.-to Item Entry");
                end;
            end;
        }
        field(50; "Reserved Quantity Inbnd."; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                  "Source Ref. No." = FIELD("Line No."),
                                                                  "Source Type" = CONST(5741),
                                                                  "Source Subtype" = CONST("1"),
                                                                  "Source Prod. Order Line" = FIELD("Derived From Line No."),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity Inbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Reserved Quantity Outbnd."; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(5741),
                                                                   "Source Subtype" = CONST("0"),
                                                                   "Source Prod. Order Line" = FIELD("Derived From Line No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity Outbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Reserved Qty. Inbnd. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                           "Source Ref. No." = FIELD("Line No."),
                                                                           "Source Type" = CONST(5741),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Source Prod. Order Line" = FIELD("Derived From Line No."),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. Inbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Reserved Qty. Outbnd. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(5741),
                                                                            "Source Subtype" = CONST("0"),
                                                                            "Source Prod. Order Line" = FIELD("Derived From Line No."),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. Outbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                DateConflictCheck;
            end;
        }
        field(55; "Reserved Quantity Shipped"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                  "Source Ref. No." = FILTER(<> 0),
                                                                  "Source Type" = CONST(5741),
                                                                  "Source Subtype" = CONST("1"),
                                                                  "Source Prod. Order Line" = FIELD("Line No."),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Reserved Qty. Shipped (Base)"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                           "Source Ref. No." = FILTER(<> 0),
                                                                           "Source Type" = CONST(5741),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Source Prod. Order Line" = FIELD("Line No."),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
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
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5707; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
            ObsoleteTag = '15.0';
        }
        field(5750; "Whse. Inbnd. Otsdg. Qty (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Warehouse Receipt Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(5741),
                                                                                        "Source Subtype" = CONST("1"),
                                                                                        "Source No." = FIELD("Document No."),
                                                                                        "Source Line No." = FIELD("Line No.")));
            Caption = 'Whse. Inbnd. Otsdg. Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5751; "Whse Outbnd. Otsdg. Qty (Base)"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(5741),
                                                                                         "Source Subtype" = CONST("0"),
                                                                                         "Source No." = FIELD("Document No."),
                                                                                         "Source Line No." = FIELD("Line No.")));
            Caption = 'Whse Outbnd. Otsdg. Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5753; "Completely Received"; Boolean)
        {
            Caption = 'Completely Received';
            Editable = false;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                DateConflictCheck;
            end;
        }
        field(5794; "Inbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen;
                TransferRoute.CalcReceiptDate("Shipment Date", "Receipt Date",
                  "Shipping Time", "Outbound Whse. Handling Time", "Inbound Whse. Handling Time",
                  "Transfer-from Code", "Transfer-to Code", "Shipping Agent Code", "Shipping Agent Service Code");
                DateConflictCheck;
            end;
        }
        field(7300; "Transfer-from Bin Code"; Code[20])
        {
            Caption = 'Transfer-from Bin Code';
            TableRelation = "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Transfer-from Code"),
                                                            "Item No." = FIELD("Item No."),
                                                            "Variant Code" = FIELD("Variant Code"));

            trigger OnValidate()
            begin
                if "Transfer-from Bin Code" <> xRec."Transfer-from Bin Code" then begin
                    TestField("Transfer-from Code");
                    if "Transfer-from Bin Code" <> '' then begin
                        GetLocation("Transfer-from Code");
                        Location.TestField("Bin Mandatory");
                        Location.TestField("Directed Put-away and Pick", false);
                        GetBin("Transfer-from Code", "Transfer-from Bin Code");
                        TestField("Transfer-from Code", Bin."Location Code");
                        HandleDedicatedBin(true);
                    end;
                end;
            end;
        }
        field(7301; "Transfer-To Bin Code"; Code[20])
        {
            Caption = 'Transfer-To Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Transfer-to Code"));

            trigger OnValidate()
            begin
                if "Transfer-To Bin Code" <> xRec."Transfer-To Bin Code" then begin
                    TestField("Transfer-to Code");
                    if "Transfer-To Bin Code" <> '' then begin
                        GetLocation("Transfer-to Code");
                        Location.TestField("Bin Mandatory");
                        Location.TestField("Directed Put-away and Pick", false);
                        GetBin("Transfer-to Code", "Transfer-To Bin Code");
                        TestField("Transfer-to Code", Bin."Location Code");
                    end;
                end;
            end;
        }
        field(99000755; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ReserveTransferLine.UpdatePlanningFlexibility(Rec);
            end;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Transfer-to Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Receipt Date", "In-Transit Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. in Transit (Base)", "Outstanding Qty. (Base)";
        }
        key(Key3; "Transfer-from Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Shipment Date", "In-Transit Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Item No.", "Variant Code")
        {
        }
        key(Key5; "Transfer-to Code", "Receipt Date", "Item No.", "Variant Code")
        {
        }
        key(Key6; "Transfer-from Code", "Shipment Date", "Item No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", Description, Quantity, "Unit of Measure", "Transfer-from Code", "Transfer-to Code")
        {
        }
    }

    trigger OnDelete()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        TestStatusOpen;

        TestField("Quantity Shipped", "Quantity Received");
        TestField("Qty. Shipped (Base)", "Qty. Received (Base)");
        CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Outbnd. (Base)");
        TestField("Reserved Qty. Inbnd. (Base)", 0);
        TestField("Reserved Qty. Outbnd. (Base)", 0);

        ReserveTransferLine.DeleteLine(Rec);
        WhseValidateSourceLine.TransLineDelete(Rec);

        ItemChargeAssgntPurch.SetCurrentKey(
          "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", "Line No.");
        ItemChargeAssgntPurch.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        TransLine2: Record "Transfer Line";
    begin
        TestStatusOpen;
        TransLine2.Reset();
        TransLine2.SetFilter("Document No.", TransHeader."No.");
        if TransLine2.FindLast then
            "Line No." := TransLine2."Line No." + 10000;
        ReserveTransferLine.VerifyQuantity(Rec, xRec);
    end;

    trigger OnModify()
    begin
        if ItemExists(xRec."Item No.") then
            ReserveTransferLine.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'must not be less than %1';
        Text003: Label 'Warehouse %1 is required for %2 = %3.';
        Text004: Label '\The entered information may be disregarded by warehouse operations.';
        Text005: Label 'You cannot ship more than %1 units.';
        Text006: Label 'All items have been shipped.';
        Text008: Label 'You cannot receive more than %1 units.';
        Text009: Label 'No items are currently in transit.';
        Text011: Label 'Outbound,Inbound';
        Text012: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
        Text013: Label 'Cancelled.';
        TransferRoute: Record "Transfer Route";
        Item: Record Item;
        TransHeader: Record "Transfer Header";
        Location: Record Location;
        Bin: Record Bin;
        DimMgt: Codeunit DimensionManagement;
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ReserveTransferLine: Codeunit "Transfer Line-Reserve";
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        WMSManagement: Codeunit "WMS Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ConfirmManagement: Codeunit "Confirm Management";
        Reservation: Page Reservation;
        TrackingBlocked: Boolean;
        MustUseTrackingErr: Label 'You must use the %1 page to specify the %2, if you use item tracking.', Comment = '%1 = Form Name, %2 = Value to Enter';
        LedgEntryWillBeOpenedMsg: Label 'When posting the Applied to Ledger Entry %1 will be opened first.', Comment = '%1 = Entry No.';
        ShippingMoreUnitsThanReceivedErr: Label 'You cannot ship more than the %1 units that you have received for document no. %2.', Comment = '%1 = Quantity Value, %2 = Document No.';
        AnotherItemWithSameDescrQst: Label 'We found an item with the description "%2" (No. %1).\Did you mean to change the current item to %1?', Comment = '%1=Item no., %2=item description';
        StatusCheckSuspended: Boolean;

    procedure InitOutstandingQty()
    begin
        "Outstanding Quantity" := Quantity - "Quantity Shipped";
        "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);

        OnAfterInitOutstandingQty(Rec, CurrFieldNo);
    end;

    procedure InitQtyToShip()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToShip(Rec, CurrFieldNo);
    end;

    procedure InitQtyToReceive()
    begin
        if "In-Transit Code" <> '' then begin
            "Qty. to Receive" := "Qty. in Transit";
            "Qty. to Receive (Base)" := "Qty. in Transit (Base)";
        end;
        if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then begin
            "Qty. to Receive" := "Qty. to Ship";
            "Qty. to Receive (Base)" := "Qty. to Ship (Base)";
        end;

        OnAfterInitQtyToReceive(Rec, CurrFieldNo);
    end;

    procedure InitQtyInTransit()
    begin
        if "In-Transit Code" <> '' then begin
            "Qty. in Transit" := "Quantity Shipped" - "Quantity Received";
            "Qty. in Transit (Base)" := "Qty. Shipped (Base)" - "Qty. Received (Base)";
        end else begin
            "Qty. in Transit" := 0;
            "Qty. in Transit (Base)" := 0;
        end;
        "Completely Received" := (Quantity <> 0) and (Quantity = "Quantity Received");

        OnAfterInitQtyInTransit(Rec, CurrFieldNo);
    end;

    procedure ResetPostedQty()
    begin
        "Quantity Shipped" := 0;
        "Qty. Shipped (Base)" := 0;
        "Quantity Received" := 0;
        "Qty. Received (Base)" := 0;
        "Qty. in Transit" := 0;
        "Qty. in Transit (Base)" := 0;

        OnAfterResetPostedQty(Rec);
    end;

    local procedure GetTransHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTransHeader(Rec, TransHeader, IsHandled);
        if IsHandled then
            exit;

        GetTransferHeaderNoVerification;

        CheckTransferHeader(TransHeader);

        "In-Transit Code" := TransHeader."In-Transit Code";
        "Transfer-from Code" := TransHeader."Transfer-from Code";
        "Transfer-to Code" := TransHeader."Transfer-to Code";
        "Shipment Date" := TransHeader."Shipment Date";
        "Receipt Date" := TransHeader."Receipt Date";
        "Shipping Agent Code" := TransHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := TransHeader."Shipping Agent Service Code";
        "Shipping Time" := TransHeader."Shipping Time";
        "Outbound Whse. Handling Time" := TransHeader."Outbound Whse. Handling Time";
        "Inbound Whse. Handling Time" := TransHeader."Inbound Whse. Handling Time";
        Status := TransHeader.Status;
        "Direct Transfer" := TransHeader."Direct Transfer";

        OnAfterGetTransHeader(Rec, TransHeader);
    end;

    local procedure CheckTransferHeader(TransferHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferHeader(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        TransHeader.TestField("Shipment Date");
        TransHeader.TestField("Receipt Date");
        TransHeader.TestField("Transfer-from Code");
        TransHeader.TestField("Transfer-to Code");
        if not TransHeader."Direct Transfer" and ("Direct Transfer" = xRec."Direct Transfer") then
            TransHeader.TestField("In-Transit Code");
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        ReserveTransferLine.Block(SetBlock);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document No.", "Line No."));
        VerifyItemLineDim;
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Transfer,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", TransHeader."Dimension Set ID", DATABASE::Item);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        VerifyItemLineDim;

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

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and
           (CurrFieldNo = CalledByFieldNo) and
           ("Item No." <> '') and
           ("Outstanding Quantity" > 0)
        then
            if ItemCheckAvail.TransferLineCheck(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    procedure OpenItemTrackingLines(Direction: Enum "Transfer Direction")
    begin
        TestField("Item No.");
        TestField("Quantity (Base)");

        ReserveTransferLine.CallItemTracking(Rec, Direction);
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        TestField("Document No.");
        if TransHeader."No." <> "Document No." then
            TransHeader.Get("Document No.");

        OnBeforeTestStatusOpen(Rec, TransHeader);

        TransHeader.TestField(Status, TransHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, TransHeader);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure ShowReservation()
    var
        OptionNumber: Integer;
    begin
        TestField("Item No.");
        Clear(Reservation);
        OptionNumber := StrMenu(Text011);
        if OptionNumber > 0 then begin
            Reservation.SetReservSource(Rec, OptionNumber - 1);
            Reservation.RunModal();
        end;
    end;

    procedure UpdateWithWarehouseShipReceive()
    begin
        if Location.RequireShipment("Transfer-from Code") then
            Validate("Qty. to Ship", 0)
        else
            Validate("Qty. to Ship", "Outstanding Quantity");

        if Location.RequireReceive("Transfer-to Code") then
            Validate("Qty. to Receive", 0)
        else begin
            if "In-Transit Code" <> '' then
                Validate("Qty. to Receive", "Qty. in Transit");
            if ("In-Transit Code" = '') and ("Quantity Shipped" = "Quantity Received") then
                Validate("Qty. to Receive", "Qty. to Ship");
        end;

        OnAfterUpdateWithWarehouseShipReceive(Rec, CurrFieldNo);
    end;

    procedure RenameNo(OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset;
        SetRange("Item No.", OldNo);
        ModifyAll("Item No.", NewNo, true);
    end;

    procedure CheckWarehouse(Location: Record Location; Receive: Boolean)
    var
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, Location, Receive, IsHandled);
        if IsHandled then
            exit;

        if Location."Directed Put-away and Pick" then begin
            ShowDialog := ShowDialog::Error;
            if Receive then
                DialogText := Location.GetRequirementText(Location.FieldNo("Require Receive"))
            else
                DialogText := Location.GetRequirementText(Location.FieldNo("Require Shipment"));
        end else begin
            if Receive and (Location."Require Receive" or Location."Require Put-away") then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location."Require Receive" then
                        ShowDialog := ShowDialog::Message;
                if Location."Require Receive" then
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Receive"))
                else
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Put-away"));
            end;

            if not Receive and (Location."Require Shipment" or Location."Require Pick") then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location."Require Shipment" then
                        ShowDialog := ShowDialog::Message;
                if Location."Require Shipment" then
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Shipment"))
                else
                    DialogText := Location.GetRequirementText(Location.FieldNo("Require Pick"));
            end;
        end;

        case ShowDialog of
            ShowDialog::Message:
                Message(Text003 + Text004, DialogText, FieldCaption("Line No."), "Line No.");
            ShowDialog::Error:
                Error(Text003, DialogText, FieldCaption("Line No."), "Line No.");
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
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

    local procedure GetDefaultBin(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        if (FromLocationCode <> '') and ("Item No." <> '') then begin
            GetLocation(FromLocationCode);
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then begin
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", FromLocationCode, "Transfer-from Bin Code");
                HandleDedicatedBin(false);
            end;
        end;

        if (ToLocationCode <> '') and ("Item No." <> '') then begin
            GetLocation(ToLocationCode);
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", ToLocationCode, "Transfer-To Bin Code");
        end;
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal; Direction: Integer)
    begin
        case Direction of
            0: // Outbound
                begin
                    CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
                    RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity Outbnd.");
                    RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. Outbnd. (Base)");
                end;
            1: // Inbound
                begin
                    CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
                    RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity Inbnd.");
                    RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. Inbnd. (Base)");
                end;
        end;
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; Direction: Integer): Decimal
    begin
        if Direction = 0 then begin // Outbound
            CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
            QtyReserved := "Reserved Quantity Outbnd.";
            QtyReservedBase := "Reserved Qty. Outbnd. (Base)";
            QtyToReserve := "Outstanding Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)";
        end else begin // Inbound
            CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
            QtyReserved := "Reserved Quantity Inbnd.";
            QtyReservedBase := "Reserved Qty. Inbnd. (Base)";
            QtyToReserve := "Outstanding Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)";
        end;
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document No.", "Line No.", "Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        ReservEntry.SetSource(
            DATABASE::"Transfer Line", Direction, "Document No.", "Line No.", '', "Derived From Line No.");
        case Direction of
            0: // Outbound
                begin
                    ReservEntry.SetItemData(
                        "Item No.", Description, "Transfer-from Code", "Variant Code", "Qty. per Unit of Measure");
                    ReservEntry."Shipment Date" := "Shipment Date";
                    ReservEntry."Expected Receipt Date" := "Shipment Date";
                end;
            1: // Inbound:
                begin
                    ReservEntry.SetItemData(
                        "Item No.", Description, "Transfer-to Code", "Variant Code", "Qty. per Unit of Measure");
                    ReservEntry."Shipment Date" := "Receipt Date";
                    ReservEntry."Expected Receipt Date" := "Receipt Date";
                end;
        end;
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction, "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', "Derived From Line No.");

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry, 0);
        ReservEntry.SetRange("Source Subtype"); // Ignore direction
        exit(not ReservEntry.IsEmpty);
    end;

    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" < 0);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if not IsInbound and ("Quantity (Base)" <> 0) then
            WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Transfer-from Code", "Transfer-from Bin Code", IssueWarning);
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean)
    begin
        Reset;
        SetCurrentKey("Item No.");
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        if not IsSupplyForPlanning then
            SetRange("Derived From Line No.", 0);
        if IsReceipt then begin
            SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
            SetFilter("Receipt Date", Item.GetFilter("Date Filter"))
        end else begin
            SetFilter("Transfer-from Code", Item.GetFilter("Location Filter"));
            SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            SetFilter("Outstanding Qty. (Base)", '<>0');
        end;
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IsReceipt, IsSupplyForPlanning);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; IsReceipt: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IsReceipt, false);
        exit(not IsEmpty);
    end;

    procedure FilterInboundLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey("Transfer-to Code", "Receipt Date", "Item No.", "Variant Code");
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Transfer-to Code", ReservationEntry."Location Code");
        SetFilter("Receipt Date", AvailabilityFilter);
        if Positive then
            SetFilter("Outstanding Qty. (Base)", '>0')
        else
            SetFilter("Outstanding Qty. (Base)", '<0');
    end;

    procedure FilterOutboundLinesForReservation(ReservationEntry: Record "Reservation Entry"; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey("Transfer-from Code", "Shipment Date", "Item No.", "Variant Code");
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Transfer-from Code", ReservationEntry."Location Code");
        SetFilter("Shipment Date", AvailabilityFilter);
        if Positive then
            SetFilter("Outstanding Qty. (Base)", '<0')
        else
            SetFilter("Outstanding Qty. (Base)", '>0');
    end;

    local procedure VerifyItemLineDim()
    begin
        if IsShippedDimChanged then
            ConfirmShippedDimChange;
    end;

    procedure IsShippedDimChanged(): Boolean
    begin
        exit(("Dimension Set ID" <> xRec."Dimension Set ID") and
          (("Quantity Shipped" <> 0) or ("Qty. Shipped (Base)" <> 0)));
    end;

    procedure ConfirmShippedDimChange(): Boolean
    begin
        if not Confirm(Text012, false, TableCaption) then
            Error(Text013);

        exit(true);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TransferLine2: Record "Transfer Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        if "Transfer-from Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Transfer-from Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        ItemLedgEntry.SetRange(Positive, true);
        ItemLedgEntry.SetRange(Open, true);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            TransferLine2 := Rec;
            TransferLine2.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := TransferLine2;
        end;
    end;

    local procedure GetTransferHeaderNoVerification()
    begin
        TestField("Document No.");
        if "Document No." <> TransHeader."No." then
            TransHeader.Get("Document No.");
    end;

    procedure DateConflictCheck()
    begin
        if not TrackingBlocked then
            CheckDateConflict.TransferLineCheck(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var TransferLine: Record "Transfer Line"; FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    local procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        IEItem: Record Item;
    begin
        exit(IEItem.Get(ItemNo));
    end;

    procedure RowID1(Direction: Enum "Transfer Direction"): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Transfer Line", Direction, "Document No.", '', "Derived From Line No.", "Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var TransferLine: Record "Transfer Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTransHeader(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyInTransit(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetPostedQty(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseShipReceive(var TransferLine: Record "Transfer Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var TransferLine: Record "Transfer Line"; CalledByFieldNo: Integer; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferHeader(TransferHeader: Record "Transfer Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(TransferLine: Record "Transfer Line"; Location: Record Location; Receive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTransHeader(var TransferLine: Record "Transfer Line"; var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TransferLine: Record "Transfer Line"; var xTransferLine: Record "Transfer Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterInitLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnCopyFromTempTransLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeTransLineVerifyChange(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;
}

