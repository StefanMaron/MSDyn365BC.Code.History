table 7311 "Warehouse Journal Line"
{
    Caption = 'Warehouse Journal Line';
    DrillDownPageID = "Warehouse Journal Lines";
    LookupPageID = "Warehouse Journal Lines";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Warehouse Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Warehouse Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(6; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "From Zone Code" <> xRec."From Zone Code" then begin
                    "From Bin Code" := '';
                    "From Bin Type Code" := '';
                end;
            end;
        }
        field(7; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';
            TableRelation = IF ("Phys. Inventory" = CONST(false),
                                "Item No." = FILTER(''),
                                "From Zone Code" = FILTER('')) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Phys. Inventory" = CONST(false),
                                         "Item No." = FILTER(<> ''),
                                         "From Zone Code" = FILTER('')) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                      "Item No." = FIELD("Item No."))
            ELSE
            IF ("Phys. Inventory" = CONST(false),
                                                                                                               "Item No." = FILTER(''),
                                                                                                               "From Zone Code" = FILTER(<> '')) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                              "Zone Code" = FIELD("From Zone Code"))
            ELSE
            IF ("Phys. Inventory" = CONST(false),
                                                                                                                                                                                       "Item No." = FILTER(<> ''),
                                                                                                                                                                                       "From Zone Code" = FILTER(<> '')) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                                                      "Item No." = FIELD("Item No."),
                                                                                                                                                                                                                                                      "Zone Code" = FIELD("From Zone Code"))
            ELSE
            IF ("Phys. Inventory" = CONST(true),
                                                                                                                                                                                                                                                               "From Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Phys. Inventory" = CONST(true),
                                                                                                                                                                                                                                                                        "From Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                                                                                                                       "Zone Code" = FIELD("From Zone Code"));

            trigger OnLookup()
            begin
                LookupFromBinCode;
            end;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo = FieldNo("From Bin Code") then
                    if "From Bin Code" <> xRec."From Bin Code" then
                        CheckBin("Location Code", "From Bin Code", false);

                "From Bin Type Code" :=
                  GetBinType("Location Code", "From Bin Code");

                Bin.CalcFields("Adjustment Bin");
                if Bin."Adjustment Bin" and ("Entry Type" <> "Entry Type"::"Positive Adjmt.") then
                    Bin.FieldError("Adjustment Bin");

                if "From Bin Code" <> '' then
                    "From Zone Code" := Bin."Zone Code";

                if "Entry Type" = "Entry Type"::"Negative Adjmt." then
                    SetUpAdjustmentBin;
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item WHERE(Type = CONST(Inventory));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Item No." <> '' then begin
                    if "Item No." <> xRec."Item No." then
                        "Variant Code" := '';
                    GetItemUnitOfMeasure;
                    Description := Item.Description;
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                end else begin
                    Description := '';
                    "Variant Code" := '';
                    Validate("Unit of Measure Code", '');
                end;
            end;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                WhseItemTrackingSetup: Record "Item Tracking Setup";
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                WhseJnlTemplate.Get("Journal Template Name");
                if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then begin
                    if Quantity < 0 then
                        FieldError(Quantity, Text000);
                end else begin
                    GetLocation("Location Code");
                    Location.TestField("Adjustment Bin Code");
                end;

                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                "Qty. (Absolute)" := Abs(Quantity);
                "Qty. (Absolute, Base)" := Abs("Qty. (Base)");
                if (xRec.Quantity < 0) and (Quantity >= 0) or
                   (xRec.Quantity >= 0) and (Quantity < 0)
                then
                    ExchangeFromToBin;

                if Quantity > 0 then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight)
                else begin
                    Cubage := 0;
                    Weight := 0;
                end;

                if Quantity <> xRec.Quantity then begin
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end;

                ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
                if WhseItemTrackingSetup."Serial No. Required" and not "Phys. Inventory" and
                   ("Serial No." <> '') and ((Quantity < 0) or (Quantity > 1))
                then
                    Error(Text006, FieldCaption(Quantity));
            end;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Qty. (Base)");
            end;
        }
        field(12; "Qty. (Absolute)"; Decimal)
        {
            Caption = 'Qty. (Absolute)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                "Qty. (Absolute, Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. (Absolute)", "Qty. per Unit of Measure");

                if Quantity > 0 then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight)
                else begin
                    Cubage := 0;
                    Weight := 0;
                end;
            end;
        }
        field(13; "Qty. (Absolute, Base)"; Decimal)
        {
            Caption = 'Qty. (Absolute, Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                NewValue: Decimal;
            begin
                NewValue := Round("Qty. (Absolute, Base)", UOMMgt.QtyRndPrecision);
                Validate(Quantity, CalcQty("Qty. (Absolute, Base)") * Quantity / Abs(Quantity));
                // Take care of rounding issues
                "Qty. (Absolute, Base)" := NewValue;
                "Qty. (Base)" := NewValue * "Qty. (Base)" / Abs("Qty. (Base)");
            end;
        }
        field(14; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Zone Code" <> xRec."Zone Code" then
                    "Bin Code" := '';

                if Quantity < 0 then
                    Validate("From Zone Code", "Zone Code")
                else
                    Validate("To Zone Code", "Zone Code");
            end;
        }
        field(15; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));

            trigger OnLookup()
            begin
                LookupBinCode;
            end;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if Quantity < 0 then begin
                    Validate("From Bin Code", "Bin Code");
                    if "Bin Code" <> xRec."Bin Code" then
                        CheckBin("Location Code", "Bin Code", false);
                end else begin
                    Validate("To Bin Code", "Bin Code");
                    if "Bin Code" <> xRec."Bin Code" then
                        CheckBin("Location Code", "Bin Code", true);
                end;

                if "Bin Code" <> '' then begin
                    GetBin("Location Code", "Bin Code");
                    "Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(20; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(21; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(23; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(24; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(25; "Source Document"; Enum "Warehouse Journal Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            Editable = false;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(27; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "To Zone Code" <> xRec."To Zone Code" then
                    "To Bin Code" := '';
            end;
        }
        field(28; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = IF ("To Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("To Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Zone Code" = FIELD("To Zone Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo = FieldNo("To Bin Code") then
                    if "To Bin Code" <> xRec."To Bin Code" then
                        CheckBin("Location Code", "To Bin Code", true);

                GetBin("Location Code", "To Bin Code");

                Bin.CalcFields("Adjustment Bin");
                if Bin."Adjustment Bin" and ("Entry Type" <> "Entry Type"::"Negative Adjmt.") then
                    Bin.FieldError("Adjustment Bin");

                if "To Bin Code" <> '' then
                    "To Zone Code" := Bin."Zone Code";

                if "Entry Type" = "Entry Type"::"Positive Adjmt." then
                    SetUpAdjustmentBin;
            end;
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(33; "Registering No. Series"; Code[20])
        {
            Caption = 'Registering No. Series';
            TableRelation = "No. Series";
        }
        field(35; "From Bin Type Code"; Code[10])
        {
            Caption = 'From Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(41; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(50; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
        }
        field(51; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            OptionCaption = 'Whse. Journal,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Whse. Phys. Inventory, ,Assembly';
            OptionMembers = "Whse. Journal",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Whse. Phys. Inventory"," ",Assembly;
        }
        field(52; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
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

                if "Serial No." <> '' then
                    if ("Qty. (Phys. Inventory)" < 0) or ("Qty. (Phys. Inventory)" > 1) then
                        Error(Text006, FieldCaption("Qty. (Phys. Inventory)"));

                PhysInvtEntered := true;
                Quantity := 0;
                Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                if "Qty. (Phys. Inventory)" = "Qty. (Calculated)" then
                    Validate("Qty. (Phys. Inventory) (Base)", "Qty. (Calculated) (Base)")
                else
                    Validate("Qty. (Phys. Inventory) (Base)", Round("Qty. (Phys. Inventory)" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
                PhysInvtEntered := false;
            end;
        }
        field(55; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Negative Adjmt.,Positive Adjmt.,Movement';
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
        }
        field(60; "Reference Document"; Option)
        {
            Caption = 'Reference Document';
            OptionCaption = ' ,Posted Rcpt.,Posted P. Inv.,Posted Rtrn. Rcpt.,Posted P. Cr. Memo,Posted Shipment,Posted S. Inv.,Posted Rtrn. Shipment,Posted S. Cr. Memo,Posted T. Receipt,Posted T. Shipment,Item Journal,Prod.,Put-away,Pick,Movement,BOM Journal,Job Journal,Assembly';
            OptionMembers = " ","Posted Rcpt.","Posted P. Inv.","Posted Rtrn. Rcpt.","Posted P. Cr. Memo","Posted Shipment","Posted S. Inv.","Posted Rtrn. Shipment","Posted S. Cr. Memo","Posted T. Receipt","Posted T. Shipment","Item Journal","Prod.","Put-away",Pick,Movement,"BOM Journal","Job Journal",Assembly;
        }
        field(61; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
        }
        field(67; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(68; "Qty. (Calculated) (Base)"; Decimal)
        {
            Caption = 'Qty. (Calculated) (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(69; "Qty. (Phys. Inventory) (Base)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory) (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. (Base)" := "Qty. (Phys. Inventory) (Base)" - "Qty. (Calculated) (Base)";
                "Qty. (Absolute, Base)" := Abs("Qty. (Base)");
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Variant Code" <> '' then begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end else
                    GetItem("Item No.", Description);

                if "Variant Code" <> xRec."Variant Code" then begin
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end;
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
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Item No." <> '' then begin
                    TestField("Unit of Measure Code");
                    GetItemUnitOfMeasure;
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end else
                    "Qty. per Unit of Measure" := 1;
                Validate(Quantity);
            end;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupLotSerialNoInfo("Item No.", "Variant Code", 0, "Serial No.");
            end;

            trigger OnValidate()
            begin
                if "Serial No." <> '' then
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");

                if (Quantity < 0) or (Quantity > 1) then
                    Error(Text006, FieldCaption(Quantity));
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupLotSerialNoInfo("Item No.", "Variant Code", 1, "Lot No.");
            end;

            trigger OnValidate()
            begin
                if "Lot No." <> '' then
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            Editable = false;
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(6504; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            Editable = false;
        }
        field(6505; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            Editable = false;
        }
        field(6506; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
            Editable = false;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Location Code", "Entry Type", "From Bin Type Code", "Variant Code", "Unit of Measure Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Absolute, Base)";
        }
        key(Key3; "Item No.", "From Bin Code", "Location Code", "Entry Type", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Absolute, Base)", "Qty. (Absolute)", Cubage, Weight;
        }
        key(Key4; "Item No.", "To Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Absolute, Base)", "Qty. (Absolute)";
        }
        key(Key5; "To Bin Code", "Location Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Cubage, Weight, "Qty. (Absolute)";
        }
        key(Key6; "Location Code", "Item No.", "Variant Code")
        {
        }
        key(Key7; "Location Code", "Bin Code", "Item No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Warehouse Journal Line", 0, "Journal Batch Name",
          "Journal Template Name", 0, "Line No.", "Location Code", true);
    end;

    trigger OnInsert()
    begin
        "User ID" := UserId;
    end;

    trigger OnModify()
    begin
        if "User ID" = '' then
            "User ID" := UserId;
    end;

    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        WMSMgt: Codeunit "WMS Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        OldItemNo: Code[20];
        PhysInvtEntered: Boolean;
        Text000: Label 'must not be negative';
        Text001: Label '%1 Journal';
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Journal';
        Text005: Label 'The location %1 of warehouse journal batch %2 is not enabled for user %3.';
        Text006: Label '%1 must be 0 or 1 for an Item tracked by Serial Number.';
        OpenFromBatch: Boolean;
        StockProposal: Boolean;

    procedure GetItem(ItemNo: Code[20]; var ItemDescription: Text[100])
    begin
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
            OldItemNo := ItemNo;
        end else
            ItemDescription := Item.Description;
    end;

    procedure SetUpNewLine(LastWhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlTemplate.Get("Journal Template Name");
        WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        WhseJnlLine.SetRange("Location Code", "Location Code");
        if WhseJnlLine.FindFirst then begin
            WhseJnlBatch.Get(
              "Journal Template Name", "Journal Batch Name", LastWhseJnlLine."Location Code");
            "Registering Date" := LastWhseJnlLine."Registering Date";
            "Whse. Document No." := LastWhseJnlLine."Whse. Document No.";
            "Entry Type" := LastWhseJnlLine."Entry Type";
            "Location Code" := LastWhseJnlLine."Location Code";
        end else begin
            "Registering Date" := WorkDate;
            WhseJnlBatch.Get("Journal Template Name", "Journal Batch Name", "Location Code");
            if WhseJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Whse. Document No." :=
                  NoSeriesMgt.TryGetNextNo(WhseJnlBatch."No. Series", "Registering Date");
            end;
        end;
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::"Physical Inventory" then begin
            "Source Document" := "Source Document"::"Phys. Invt. Jnl.";
            "Whse. Document Type" := "Whse. Document Type"::"Whse. Phys. Inventory";
        end;
        "Source Code" := WhseJnlTemplate."Source Code";
        "Reason Code" := WhseJnlBatch."Reason Code";
        "Registering No. Series" := WhseJnlBatch."Registering No. Series";
        if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::Reclassification then begin
            if Quantity >= 0 then
                "Entry Type" := "Entry Type"::"Positive Adjmt."
            else
                "Entry Type" := "Entry Type"::"Negative Adjmt.";
            SetUpAdjustmentBin;
        end else
            "Entry Type" := "Entry Type"::Movement;

        OnAfterSetupNewLine(Rec, LastWhseJnlLine, WhseJnlTemplate);
    end;

    procedure SetUpAdjustmentBin()
    var
        Location: Record Location;
    begin
        WhseJnlTemplate.Get("Journal Template Name");
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then
            exit;

        Location.Get("Location Code");
        GetBin(Location.Code, Location."Adjustment Bin Code");
        case "Entry Type" of
            "Entry Type"::"Positive Adjmt.":
                begin
                    "From Zone Code" := Bin."Zone Code";
                    "From Bin Code" := Bin.Code;
                    "From Bin Type Code" := Bin."Bin Type Code";
                end;
            "Entry Type"::"Negative Adjmt.":
                begin
                    "To Zone Code" := Bin."Zone Code";
                    "To Bin Code" := Bin.Code;
                end;
        end;
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem("Item No.", Description);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and (Quantity = 0));
    end;

    local procedure ExchangeFromToBin()
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        GetLocation("Location Code");
        WhseJnlLine := Rec;
        "From Zone Code" := WhseJnlLine."To Zone Code";
        "From Bin Code" := WhseJnlLine."To Bin Code";
        "From Bin Type Code" :=
          GetBinType("Location Code", "From Bin Code");
        if ("Location Code" = Location.Code) and
           ("From Bin Code" = Location."Adjustment Bin Code")
        then
            WMSMgt.CheckAdjmtBin(Location, "Qty. (Absolute)", Quantity > 0);

        "To Zone Code" := WhseJnlLine."From Zone Code";
        "To Bin Code" := WhseJnlLine."From Bin Code";
        if ("Location Code" = Location.Code) and
           ("To Bin Code" = Location."Adjustment Bin Code")
        then
            WMSMgt.CheckAdjmtBin(Location, "Qty. (Absolute)", Quantity > 0);

        if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::Reclassification then begin
            if Quantity >= 0 then
                "Entry Type" := "Entry Type"::"Positive Adjmt."
            else
                "Entry Type" := "Entry Type"::"Negative Adjmt.";
            SetUpAdjustmentBin;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(Location, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
        Location.TestField("Directed Put-away and Pick");
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (LocationCode = '') or (BinCode = '') then
            Clear(Bin)
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure CheckBin(LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean)
    var
        BinContent: Record "Bin Content";
        WhseJnlLine: Record "Warehouse Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, LocationCode, BinCode, Inbound, IsHandled);
        if IsHandled then
            exit;

        if (BinCode <> '') and ("Item No." <> '') then begin
            GetLocation(LocationCode);
            if BinCode = Location."Adjustment Bin Code" then
                exit;
            BinContent.SetProposalMode(StockProposal);
            if Inbound then begin
                GetBinType(LocationCode, BinCode);
                if Location."Bin Capacity Policy" in
                   [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                    Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]
                then begin
                    WhseJnlLine.SetCurrentKey("To Bin Code", "Location Code");
                    WhseJnlLine.SetRange("To Bin Code", BinCode);
                    WhseJnlLine.SetRange("Location Code", LocationCode);
                    WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    WhseJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    WhseJnlLine.SetRange("Line No.", "Line No.");
                    WhseJnlLine.CalcSums("Qty. (Absolute)", Cubage, Weight);
                end;
                if BinContent.Get(
                     "Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code")
                then
                    BinContent.CheckIncreaseBinContent(
                      "Qty. (Absolute, Base)", WhseJnlLine."Qty. (Absolute, Base)",
                      WhseJnlLine.Cubage, WhseJnlLine.Weight, Cubage, Weight, false, false)
                else begin
                    GetBin(LocationCode, BinCode);
                    Bin.CheckIncreaseBin(
                      BinCode, "Item No.", "Qty. (Absolute)",
                      WhseJnlLine.Cubage, WhseJnlLine.Weight, Cubage, Weight, false, false);
                end;
            end else begin
                IsHandled := false;
                OnCheckBinOnBeforeCheckOutboundBin(Rec, IsHandled);
                if not IsHandled then begin
                    BinContent.Get("Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code");
                    if BinContent."Block Movement" in [
                                                    BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]
                    then
                        if not StockProposal then
                            BinContent.FieldError("Block Movement");
                end;
            end;
            BinContent.SetProposalMode(false);
        end;
    end;

    procedure GetBinType(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        BinType: Record "Bin Type";
    begin
        GetBin(LocationCode, BinCode);
        WhseJnlTemplate.Get("Journal Template Name");
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then
            if Bin."Bin Type Code" <> '' then
                if BinType.Get(Bin."Bin Type Code") then
                    BinType.TestField(Receive, false);

        exit(Bin."Bin Type Code");
    end;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Option Adjustment,"Phys. Inventory",Reclassification; var WhseJnlLine: Record "Warehouse Journal Line"; var JnlSelected: Boolean)
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        JnlSelected := true;

        WhseJnlTemplate.Reset();
        if not OpenFromBatch then
            WhseJnlTemplate.SetRange("Page ID", PageID);
        WhseJnlTemplate.SetRange(Type, PageTemplate);

        case WhseJnlTemplate.Count of
            0:
                begin
                    WhseJnlTemplate.Init();
                    WhseJnlTemplate.Validate(Type, PageTemplate);
                    WhseJnlTemplate.Validate("Page ID");
                    WhseJnlTemplate.Name := Format(WhseJnlTemplate.Type, MaxStrLen(WhseJnlTemplate.Name));
                    WhseJnlTemplate.Description := StrSubstNo(Text001, WhseJnlTemplate.Type);
                    WhseJnlTemplate.Insert();
                    Commit();
                end;
            1:
                WhseJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, WhseJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            WhseJnlLine.FilterGroup := 2;
            WhseJnlLine.SetRange("Journal Template Name", WhseJnlTemplate.Name);
            WhseJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                WhseJnlLine."Journal Template Name" := '';
                PAGE.Run(WhseJnlTemplate."Page ID", WhseJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var WhseJnlBatch: Record "Warehouse Journal Batch")
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := true;
        WhseJnlBatch.CalcFields("Template Type");
        WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
        WhseJnlLine."Location Code" := WhseJnlBatch."Location Code";
        TemplateSelection(0, WhseJnlBatch."Template Type", WhseJnlLine, JnlSelected);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        WMSMgt.CheckUserIsWhseEmployee;
        CheckTemplateName(
          WhseJnlLine.GetRangeMax("Journal Template Name"), CurrentLocationCode, CurrentJnlBatchName);
        WhseJnlLine.FilterGroup := 2;
        WhseJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        if CurrentLocationCode <> '' then
            WhseJnlLine.SetRange("Location Code", CurrentLocationCode);
        WhseJnlLine.FilterGroup := 0;
    end;

    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentLocationCode: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTemplateName(CurrentJnlTemplateName, CurrentJnlBatchName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        if FindExistingBatch(CurrentJnlTemplateName, CurrentLocationCode, CurrentJnlBatchName) then
            exit;

        WhseJnlBatch.Init();
        WhseJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
        WhseJnlBatch.SetupNewBatch;
        WhseJnlBatch."Location Code" := CurrentLocationCode;
        WhseJnlBatch.Name := Text002;
        WhseJnlBatch.Description := Text003;
        WhseJnlBatch.Insert(true);
        Commit();
        CurrentJnlBatchName := WhseJnlBatch.Name;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckName(CurrentJnlBatchName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        WhseJnlBatch.Get(
          WhseJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName, CurrentLocationCode);
        if (UserId <> '') and not WhseEmployee.Get(UserId, CurrentLocationCode) then
            Error(Text005, CurrentLocationCode, CurrentJnlBatchName, UserId);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.FilterGroup := 2;
        WhseJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        WhseJnlLine.SetRange("Location Code", CurrentLocationCode);
        WhseJnlLine.FilterGroup := 0;
        if WhseJnlLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        Commit();
        WhseJnlBatch."Journal Template Name" := WhseJnlLine.GetRangeMax("Journal Template Name");
        WhseJnlBatch.Name := WhseJnlLine.GetRangeMax("Journal Batch Name");
        WhseJnlBatch.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
        if PAGE.RunModal(PAGE::"Whse. Journal Batches List", WhseJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := WhseJnlBatch.Name;
            CurrentLocationCode := WhseJnlBatch."Location Code";
            SetName(CurrentJnlBatchName, CurrentLocationCode, WhseJnlLine);
        end;
    end;

    procedure OpenItemTrackingLines()
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        OnBeforeOpenItemTrackingLines(Rec);

        TestField("Item No.");
        TestField("Qty. (Base)");
        WhseWkshLine.Init();
        WhseWkshLine."Worksheet Template Name" := "Journal Template Name";
        WhseWkshLine.Name := "Journal Batch Name";
        WhseWkshLine."Location Code" := "Location Code";
        WhseWkshLine."Line No." := "Line No.";
        WhseWkshLine."Item No." := "Item No.";
        WhseWkshLine."Variant Code" := "Variant Code";
        WhseWkshLine."Qty. (Base)" := "Qty. (Base)";
        WhseWkshLine."Qty. to Handle (Base)" := "Qty. (Base)";
        OnOpenItemTrackingLinesOnBeforeSetSource(WhseWkshLine, Rec);

        WhseItemTrackingLines.SetSource(WhseWkshLine, DATABASE::"Warehouse Journal Line");
        WhseItemTrackingLines.RunModal;
        Clear(WhseItemTrackingLines);
    end;

    procedure ItemTrackingReclass(TemplateName: Code[10]; BatchName: Code[10]; LocationCode: Code[10]; LineNo: Integer): Boolean
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        if not IsReclass(TemplateName) then
            exit(false);

        with WhseItemTrkgLine do begin
            if ItemTrackingMgt.WhseItemTrackingLineExists(TemplateName, BatchName, LocationCode, LineNo, WhseItemTrkgLine) then begin
                FindSet();
                repeat
                    if not HasSameNewTracking() or ("Expiration Date" <> "New Expiration Date") then
                        exit(true);
                until Next = 0;
            end;
        end;

        exit(false);
    end;

    local procedure LookupFromBinCode()
    var
        LotNo: Code[50];
        SerialNo: Code[50];
        BinCode: Code[20];
    begin
        if ("Line No." <> 0) and IsReclass("Journal Template Name") then begin
            LotNo := '';
            SerialNo := '';
            RetrieveItemTracking(LotNo, SerialNo);
            BinCode := WMSMgt.BinContentLookUp("Location Code", "Item No.", "Variant Code", "Zone Code", LotNo, SerialNo, "Bin Code");
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
        if BinCode <> '' then
            Validate("From Bin Code", BinCode);
    end;

    local procedure LookupBinCode()
    var
        LotNo: Code[50];
        SerialNo: Code[50];
        BinCode: Code[20];
    begin
        if ("Line No." <> 0) and (Quantity < 0) then begin
            LotNo := '';
            SerialNo := '';
            RetrieveItemTracking(LotNo, SerialNo);
            BinCode := WMSMgt.BinContentLookUp("Location Code", "Item No.", "Variant Code", "Zone Code", LotNo, SerialNo, "Bin Code");
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
        if BinCode <> '' then
            Validate("Bin Code", BinCode);
    end;

    procedure RetrieveItemTracking(var LotNo: Code[50]; var SerialNo: Code[50])
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        if ItemTrackingMgt.WhseItemTrackingLineExists(
             "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.", WhseItemTrkgLine)
        then
            // Don't step in if more than one Tracking Definition exists
            if WhseItemTrkgLine.Count = 1 then begin
                WhseItemTrkgLine.FindFirst;
                if WhseItemTrkgLine."Quantity (Base)" = "Qty. (Absolute, Base)" then begin
                    LotNo := WhseItemTrkgLine."Lot No.";
                    SerialNo := WhseItemTrkgLine."Serial No.";
                end;
            end;
    end;

    procedure IsReclass(CurrentJnlTemplateName: Code[10]): Boolean
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        if WhseJnlTemplate.Get(CurrentJnlTemplateName) then
            exit(WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification);

        exit(false);
    end;

    procedure SetProposal(NewValue: Boolean)
    begin
        StockProposal := NewValue;
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                WarehouseJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            WarehouseJournalBatch.SetFilter(Name, BatchFilter);
            WarehouseJournalBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    local procedure FindExistingBatch(CurrentJnlTemplateName: Code[10]; var CurrentLocationCode: Code[10]; var CurrentJnlBatchName: Code[10]): Boolean
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        WhseJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        WhseJnlBatch.SetRange(Name, CurrentJnlBatchName);

        if IsWarehouseEmployeeLocationDirectPutAwayAndPick(CurrentLocationCode) then begin
            WhseJnlBatch.SetRange("Location Code", CurrentLocationCode);
            if not WhseJnlBatch.IsEmpty then
                exit(true);
        end;

        WhseJnlBatch.SetRange(Name);
        CurrentLocationCode := WMSMgt.GetDefaultDirectedPutawayAndPickLocation;
        WhseJnlBatch.SetRange("Location Code", CurrentLocationCode);

        if WhseJnlBatch.FindFirst then begin
            CurrentJnlBatchName := WhseJnlBatch.Name;
            exit(true);
        end;

        WhseJnlBatch.SetRange("Location Code");

        if WhseJnlBatch.FindSet then begin
            repeat
                if IsWarehouseEmployeeLocationDirectPutAwayAndPick(WhseJnlBatch."Location Code") then begin
                    CurrentLocationCode := WhseJnlBatch."Location Code";
                    CurrentJnlBatchName := WhseJnlBatch.Name;
                    exit(true);
                end;
            until WhseJnlBatch.Next = 0;
        end;

        exit(false);
    end;

    local procedure IsWarehouseEmployeeLocationDirectPutAwayAndPick(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if Location.Get(LocationCode) and Location."Directed Put-away and Pick" then
            exit(WarehouseEmployee.Get(UserId, Location.Code));

        exit(false);
    end;

    procedure CheckTrackingIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            TestField("Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterCheckTrackingIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
        "Source Type" := SourceType;
        if SourceSubtype >= 0 then
            "Source Subtype" := SourceSubtype;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        if SourceSublineNo >= 0 then
            "Source Subline No." := SourceSublineNo;
    end;

    procedure SetTracking(SerialNo: Code[50]; LotNo: Code[50]; WarrantyDate: Date; ExpirationDate: Date)
    begin
        "Serial No." := SerialNo;
        "Lot No." := LotNo;
        "Warranty Date" := WarrantyDate;
        "Expiration Date" := ExpirationDate;
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetWhseDoc(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    begin
        "Whse. Document Type" := DocType;
        "Whse. Document No." := DocNo;
        "Whse. Document Line No." := DocLineNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var WhseJnlLine: Record "Warehouse Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var LastWhseJnlLine: Record "Warehouse Journal Line"; WarehouseJournalTemplate: Record "Warehouse Journal Template");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckName(var JnlBatchName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(var JnlTemplateName: Code[10]; var JnlBatchName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var Location: Record Location; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinOnBeforeCheckOutboundBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLinesOnBeforeSetSource(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

