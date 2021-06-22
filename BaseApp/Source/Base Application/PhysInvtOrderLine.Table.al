table 5876 "Phys. Invt. Order Line"
{
    Caption = 'Phys. Invt. Order Line';
    DrillDownPageID = "Physical Inventory Order Lines";
    LookupPageID = "Physical Inventory Order Lines";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(12; "On Recording Lines"; Boolean)
        {
            Caption = 'On Recording Lines';
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                TempPhysInvtOrderLine: Record "Phys. Invt. Order Line" temporary;
            begin
                TestStatusOpen;
                TestField("On Recording Lines", false);

                TempPhysInvtOrderLine := Rec;
                Init;
                "Item No." := TempPhysInvtOrderLine."Item No.";
                "Variant Code" := '';
                ResetQtyExpected;

                if "Item No." = '' then
                    exit;

                GetPhysInvtOrderHeader;
                GetItem;
                Item.TestField(Blocked, false);

                Validate(Description, Item.Description);
                Validate("Description 2", Item."Description 2");

                Validate("Base Unit of Measure Code", Item."Base Unit of Measure");
                if "Base Unit of Measure Code" <> '' then begin
                    UnitOfMeasure.Get("Base Unit of Measure Code");
                    "Unit of Measure" := UnitOfMeasure.Description;
                end else
                    "Unit of Measure" := '';

                "Item Category Code" := Item."Item Category Code";

                Validate("Gen. Bus. Posting Group", PhysInvtOrderHeader."Gen. Bus. Posting Group");
                Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
                Validate("Inventory Posting Group", Item."Inventory Posting Group");

                CreateDim(DATABASE::Item, "Item No.");

                "Location Code" := PhysInvtOrderHeader."Location Code";
                "Bin Code" := PhysInvtOrderHeader."Bin Code";

                "Use Item Tracking" := PhysInvtTrackingMgt.SuggestUseTrackingLines(Item);

                GetShelfNo();
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                TestStatusOpen;
                TestField("On Recording Lines", false);

                if "Variant Code" <> xRec."Variant Code" then begin
                    ResetQtyExpected;
                    GetShelfNo();
                end;

                if "Variant Code" = '' then
                    exit;

                TestField("Item No.");

                ItemVariant.Get("Item No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
            end;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestStatusOpen;
                TestField("On Recording Lines", false);

                if "Location Code" <> xRec."Location Code" then
                    ResetQtyExpected;

                GetShelfNo();
            end;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            var
                Location: Record Location;
            begin
                TestStatusOpen;
                TestField("On Recording Lines", false);

                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;

                if "Bin Code" <> xRec."Bin Code" then
                    ResetQtyExpected;
            end;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(32; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(40; "Base Unit of Measure Code"; Code[10])
        {
            Caption = 'Base Unit of Measure Code';
            Editable = false;
            TableRelation = "Unit of Measure";
        }
        field(50; "Qty. Expected (Base)"; Decimal)
        {
            Caption = 'Qty. Expected (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(51; "Qty. Exp. Calculated"; Boolean)
        {
            Caption = 'Qty. Exp. Calculated';
            Editable = false;
        }
        field(52; "Qty. Exp. Item Tracking (Base)"; Decimal)
        {
            CalcFormula = Sum ("Exp. Phys. Invt. Tracking"."Quantity (Base)" WHERE("Order No" = FIELD("Document No."),
                                                                                   "Order Line No." = FIELD("Line No.")));
            Caption = 'Qty. Exp. Item Tracking (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Use Item Tracking"; Boolean)
        {
            Caption = 'Use Item Tracking';

            trigger OnValidate()
            begin
                TestStatusOpen;

                if "Use Item Tracking" <> xRec."Use Item Tracking" then
                    ResetQtyExpected;
            end;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(60; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';
        }
        field(62; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(70; "No. Finished Rec.-Lines"; Integer)
        {
            Caption = 'No. Finished Rec.-Lines';
            Editable = false;
        }
        field(71; "Qty. Recorded (Base)"; Decimal)
        {
            Caption = 'Qty. Recorded (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(72; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(73; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = ' ,Positive Adjmt.,Negative Adjmt.';
            OptionMembers = " ","Positive Adjmt.","Negative Adjmt.";
        }
        field(74; "Pos. Qty. (Base)"; Decimal)
        {
            Caption = 'Pos. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(75; "Neg. Qty. (Base)"; Decimal)
        {
            Caption = 'Neg. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(76; "Without Difference"; Boolean)
        {
            Caption = 'Without Difference';
            Editable = false;
        }
        field(80; "Recorded Without Order"; Boolean)
        {
            Caption = 'Recorded Without Order';
            Editable = false;
        }
        field(90; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify;
            end;
        }
        field(91; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify;
            end;
        }
        field(100; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(110; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(111; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(112; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
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
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
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
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
        }
        key(Key3; "Document No.", "Entry Type", "Without Difference")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
        TestField("On Recording Lines", false);

        ExpPhysInvtTracking.DeleteLine("Document No.", "Line No.", true);

        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(DATABASE::"Phys. Invt. Order Line", 0, "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        CannotSetErr: Label 'You cannot use item tracking because there is a difference between the values of the fields Qty. Expected (Base) = %1 and Qty. Exp. Item Tracking (Base) = %2.\%3', Comment = '%1 and %2 - Decimal, %3 = Text';
        IndenitiedValuesMsg: Label 'Identified values on the line:  %1 %2 %3 %4.', Comment = '%1,%2,%3,%4 - field captions';
        DifferentSumErr: Label 'The value of the Qty. Recorded (Base) field is different from the sum of all Quantity (Base) fields on related physical inventory recordings.%1', Comment = '%1 = text';
        MustSpecifyErr: Label 'You must specify a serial number or lot number on physical inventory recording line %1 when the Use Item Tracking check box is selected.%2', Comment = '%1 = Recording No., %2 = Text';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        UnitOfMeasure: Record "Unit of Measure";
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
        ReservEntry: Record "Reservation Entry";
        SKU: Record "Stockkeeping Unit";
        BinContent: Record "Bin Content";
        DimManagement: Codeunit DimensionManagement;
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = table caption';
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        UnknownEntryTypeErr: Label 'Unknown Entry Type.';

    local procedure GetPhysInvtOrderHeader()
    begin
        TestField("Document No.");
        if "Document No." <> PhysInvtOrderHeader."No." then
            PhysInvtOrderHeader.Get("Document No.");
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    procedure TestStatusOpen()
    begin
        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
    end;

    procedure CalcQtyAndTrackLinesExpected()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
    begin
        if EmptyLine then
            exit;

        GetItem;

        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField("Posting Date");

        TestStatusOpen;

        CalcQtyAndLastItemLedgExpected(
          "Qty. Expected (Base)",
          "Last Item Ledger Entry No.");

        // Create Expected Phys. Invt. Tracking Lines:
        if "Use Item Tracking" then begin
            ExpPhysInvtTracking.Reset();
            ExpPhysInvtTracking.SetRange("Order No", "Document No.");
            ExpPhysInvtTracking.SetRange("Order Line No.", "Line No.");
            ExpPhysInvtTracking.DeleteAll();

            if not PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") then begin
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey(
                  "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
                OnCalcQtyAndTrackLinesExpectedSetItemLedgEntryFilters(ItemLedgEntry, Rec);
                if ItemLedgEntry.FindSet then
                    repeat
                        if not
                           ExpPhysInvtTracking.Get(
                             "Document No.", "Line No.", ItemLedgEntry."Serial No.", ItemLedgEntry."Lot No.")
                        then begin
                            ExpPhysInvtTracking.InsertLine(
                              "Document No.", "Line No.", ItemLedgEntry."Serial No.", ItemLedgEntry."Lot No.", ItemLedgEntry.Quantity);
                            OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLine(ExpPhysInvtTracking, ItemLedgEntry);
                        end else begin
                            ExpPhysInvtTracking."Quantity (Base)" += ItemLedgEntry.Quantity;
                            OnCalcQtyAndTrackLinesExpectedOnBeforeModifyFromItemLedgEntry(ExpPhysInvtTracking, ItemLedgEntry);
                            ExpPhysInvtTracking.Modify();
                        end;
                    until ItemLedgEntry.Next = 0;
                ExpPhysInvtTracking.DeleteLine("Document No.", "Line No.", false);
                TestQtyExpected;
            end else begin
                if PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item) then begin
                    WhseEntry.Reset();
                    WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
                    WhseEntry.SetRange("Location Code", "Location Code");
                    WhseEntry.SetRange("Bin Code", "Bin Code");
                    WhseEntry.SetRange("Item No.", "Item No.");
                    WhseEntry.SetRange("Variant Code", "Variant Code");
                    WhseEntry.SetRange("Registering Date", 0D, PhysInvtOrderHeader."Posting Date");
                    OnCalcQtyAndTrackLinesExpectedOnAfterSetWhseEntryFilters(WhseEntry, Rec);
                    if WhseEntry.FindSet then
                        repeat
                            if not
                               ExpPhysInvtTracking.Get(
                                 "Document No.", "Line No.", WhseEntry."Serial No.", WhseEntry."Lot No.")
                            then begin
                                ExpPhysInvtTracking.InsertLine(
                                  "Document No.", "Line No.", WhseEntry."Serial No.", WhseEntry."Lot No.", WhseEntry."Qty. (Base)");
                                OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLineFromWhseEntry(ExpPhysInvtTracking, WhseEntry);
                            end else begin
                                ExpPhysInvtTracking."Quantity (Base)" += WhseEntry."Qty. (Base)";
                                OnCalcQtyAndTrackLinesExpectedOnBeforeInsertFromWhseEntry(ExpPhysInvtTracking, WhseEntry);
                                ExpPhysInvtTracking.Modify();
                            end;
                        until WhseEntry.Next = 0;
                    ExpPhysInvtTracking.DeleteLine("Document No.", "Line No.", false);
                    TestQtyExpected;
                end else
                    // In the case of
                    // ItemTrkgMgtPhysInvtLine.LocationIsBinMandatory("Location Code") = Yes and
                    // ItemTrkgMgtPhysInvtLine.GetTrackingNosFromWhse(Item) = No
                    // Navision cannot create the records of table ExpPhysInvtTracking
                    // In this case Navision must create the Reservation Entries by
                    // analyzing the ItemLedgerEntries and WhseEntries during the function to Finish the Order.
                    ;
            end;
        end;

        "Qty. Exp. Calculated" := true;
    end;

    procedure CalcQtyAndLastItemLedgExpected(var QtyExpected: Decimal; var LastItemLedgEntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
    begin
        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField("Posting Date");

        TestStatusOpen;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        if ItemLedgEntry.FindLast then
            LastItemLedgEntryNo := ItemLedgEntry."Entry No."
        else
            LastItemLedgEntryNo := 0;

        if PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") then begin
            TestField("Bin Code");
            WhseEntry.Reset();
            WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
            WhseEntry.SetRange("Location Code", "Location Code");
            WhseEntry.SetRange("Bin Code", "Bin Code");
            WhseEntry.SetRange("Item No.", "Item No.");
            WhseEntry.SetRange("Variant Code", "Variant Code");
            WhseEntry.SetRange("Registering Date", 0D, PhysInvtOrderHeader."Posting Date");
            OnCalcQtyAndLastItemLedgExpectedSetWhseEntryFilters(WhseEntry, Rec);
            WhseEntry.CalcSums("Qty. (Base)");
            QtyExpected := WhseEntry."Qty. (Base)";
        end else begin
            TestField("Bin Code", '');
            ItemLedgEntry.Reset();

            ItemLedgEntry.SetCurrentKey(
              "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
            ItemLedgEntry.SetRange("Item No.", "Item No.");
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
            ItemLedgEntry.SetRange("Location Code", "Location Code");
            ItemLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
            OnCalcQtyAndLastItemLedgExpectedSetItemLedgEntryFilters(ItemLedgEntry, Rec);
            ItemLedgEntry.CalcSums(Quantity);
            QtyExpected := ItemLedgEntry.Quantity;
        end;
    end;

    procedure ResetQtyExpected()
    begin
        "Qty. Expected (Base)" := 0;

        ExpPhysInvtTracking.DeleteLine("Document No.", "Line No.", true);
        CalcFields("Qty. Exp. Item Tracking (Base)");

        "Qty. Exp. Calculated" := false;

        OnAfterResetQtyExpected(Rec);
    end;

    procedure TestQtyExpected()
    begin
        if "Use Item Tracking" then begin
            if PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") and
               not PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item)
            then
                exit;

            CalcFields("Qty. Exp. Item Tracking (Base)");
            if "Qty. Expected (Base)" <> "Qty. Exp. Item Tracking (Base)" then
                Error(
                  StrSubstNo(
                    CannotSetErr,
                    "Qty. Expected (Base)", "Qty. Exp. Item Tracking (Base)",
                    StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code")));
        end;
    end;

    procedure TestQtyRecorded()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        "Sum": Decimal;
    begin
        Sum := 0;

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", "Document No.");
        PhysInvtRecordLine.SetRange("Order Line No.", "Line No.");
        if PhysInvtRecordLine.Find('-') then
            repeat
                PhysInvtRecordLine.TestField("Item No.", "Item No.");
                PhysInvtRecordLine.TestField("Variant Code", "Variant Code");
                PhysInvtRecordLine.TestField("Location Code", "Location Code");
                PhysInvtRecordLine.TestField("Bin Code", "Bin Code");
                if "Use Item Tracking" then
                    if (PhysInvtRecordLine."Quantity (Base)" <> 0) and
                       (PhysInvtRecordLine."Serial No." = '') and
                       (PhysInvtRecordLine."Lot No." = '')
                    then
                        Error(
                          StrSubstNo(
                            MustSpecifyErr, PhysInvtRecordLine."Recording No.",
                            StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code")));
                Sum := Sum + PhysInvtRecordLine."Quantity (Base)";
            until PhysInvtRecordLine.Next = 0;

        if "Qty. Recorded (Base)" <> Sum then
            Error(
              StrSubstNo(
                DifferentSumErr,
                StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code")));
    end;

    procedure CalcCosts()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if EmptyLine then
            exit;
        TestField("Item No.");

        TestStatusOpen;
        TestField("Qty. Exp. Calculated", true);
        TestField("On Recording Lines", true);

        GetPhysInvtOrderHeader;

        ItemJnlLine.Init();
        OnCalcCostsOnAfterInitItemJnlLine(Rec, ItemJnlLine);

        ItemJnlLine."Posting Date" := PhysInvtOrderHeader."Posting Date";
        case "Entry Type" of
            "Entry Type"::"Positive Adjmt.":
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
            "Entry Type"::"Negative Adjmt.":
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            else
                Error(UnknownEntryTypeErr);
        end;

        ItemJnlLine.Validate("Item No.", "Item No.");
        ItemJnlLine.Validate("Variant Code", "Variant Code");
        ItemJnlLine.Validate("Location Code", "Location Code");

        Validate("Unit Amount", ItemJnlLine."Unit Amount");
        Validate("Unit Cost", ItemJnlLine."Unit Cost");
    end;

    procedure CheckLine()
    begin
        TestField("Item No.");
        TestField("Qty. Exp. Calculated", true);
        TestQtyExpected;
        TestField("On Recording Lines", true);
        TestQtyRecorded;
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and
          ("Variant Code" = '') and
          ("Location Code" = '') and
          ("Bin Code" = ''));
    end;

    procedure PrepareLine(DocNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; PeriodCode: Code[10]; PeriodType: Option)
    begin
        Init;
        "Document No." := DocNo;
        "Line No." := LineNo;
        Validate("Item No.", ItemNo);
        Validate("Variant Code", VariantCode);
        Validate("Location Code", LocationCode);
        Validate("Bin Code", BinCode);
        "Phys Invt Counting Period Code" := PeriodCode;
        "Phys Invt Counting Period Type" := PeriodType;
        "Recorded Without Order" := false;
    end;

    procedure ShowDimensions()
    begin
        if EmptyLine then
            exit;
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
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
        GetPhysInvtOrderHeader;
        "Dimension Set ID" :=
          DimManagement.GetDefaultDimID(TableID, No, SourceCodeSetup."Phys. Invt. Orders", "Shortcut Dimension 1 Code",
            "Shortcut Dimension 2 Code", PhysInvtOrderHeader."Dimension Set ID", 0);
        DimManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimManagement.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowPhysInvtRecordingLines()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        if EmptyLine then
            exit;

        TestField("Item No.");
        TestField("On Recording Lines", true);

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", "Document No.");
        PhysInvtRecordLine.SetRange("Order Line No.", "Line No.");
        PAGE.RunModal(0, PhysInvtRecordLine);
    end;

    procedure ShowExpectPhysInvtTrackLines()
    begin
        if EmptyLine then
            exit;

        TestField("Item No.");
        TestField("Qty. Exp. Calculated", true);

        ExpPhysInvtTracking.Reset();
        ExpPhysInvtTracking.SetRange("Order No", "Document No.");
        ExpPhysInvtTracking.SetRange("Order Line No.", "Line No.");
        PAGE.RunModal(0, ExpPhysInvtTracking);
    end;

    procedure ShowItemTrackingLines(Which: Option All,Positive,Negative)
    begin
        if EmptyLine then
            exit;
        TestField("Item No.");

        PhysInvtOrderHeader.Get("Document No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Finished);

        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(DATABASE::"Phys. Invt. Order Line", 0, "Document No.", "Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        case Which of
            Which::All:
                ReservEntry.SetRange(Positive);
            Which::Positive:
                ReservEntry.SetRange(Positive, true);
            Which::Negative:
                ReservEntry.SetRange(Positive, false);
        end;

        PAGE.RunModal(PAGE::"Phys. Invt. Item Track. List", ReservEntry);
    end;

    procedure ShowItemLedgerEntries()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if EmptyLine then
            exit;

        TestField("Item No.");
        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField("Posting Date");

        ItemLedgEntry.SetItemVariantLocationFilters(
          "Item No.", "Variant Code", "Location Code", PhysInvtOrderHeader."Posting Date");
        OnBeforeShowItemLedgerEntries(ItemLedgEntry, Rec);
        PAGE.RunModal(0, ItemLedgEntry);
    end;

    procedure ShowPhysInvtLedgerEntries()
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
    begin
        if EmptyLine then
            exit;

        TestField("Item No.");
        GetPhysInvtOrderHeader;
        PhysInvtOrderHeader.TestField("Posting Date");

        PhysInvtLedgEntry.Reset();
        PhysInvtLedgEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");
        PhysInvtLedgEntry.SetRange("Item No.", "Item No.");
        PhysInvtLedgEntry.SetRange("Variant Code", "Variant Code");
        PhysInvtLedgEntry.SetRange("Location Code", "Location Code");
        PhysInvtLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
        OnBeforeShowPhysInvtLedgerEntries(PhysInvtLedgEntry, Rec);
        PAGE.RunModal(0, PhysInvtLedgEntry);
    end;

    local procedure GetShelfNo()
    begin
        GetItem();
        "Shelf No." := Item."Shelf No.";
        GetFieldsFromSKU();
    end;

    procedure GetFieldsFromSKU()
    begin
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            Validate("Shelf No.", SKU."Shelf No.");
    end;

    procedure ShowBinContentItem()
    begin
        BinContent.Reset();
        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "Item No.");

        PAGE.RunModal(0, BinContent);
    end;

    procedure ShowBinContentBin()
    begin
        BinContent.Reset();
        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", "Location Code");
        BinContent.SetRange("Bin Code", "Bin Code");

        PAGE.RunModal(0, BinContent);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; CurrentFieldID: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQtyExpected(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var xPhysInvtOrderLine: Record "Phys. Invt. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var xPhysInvtOrderLine: Record "Phys. Invt. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemLedgerEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPhysInvtLedgerEntries(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCostsOnAfterInitItemJnlLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedSetWhseEntryFilters(var WarehouseEntry: Record "Warehouse Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLine(var ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLineFromWhseEntry(var ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterSetWhseEntryFilters(var WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnBeforeModifyFromItemLedgEntry(var ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnBeforeInsertFromWhseEntry(var ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking"; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;
}

