table 336 "Tracking Specification"
{
    Caption = 'Tracking Specification';

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
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Quantity (Base)" * "Quantity Handled (Base)" < 0) or
                   (Abs("Quantity (Base)") < Abs("Quantity Handled (Base)"))
                then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Quantity Handled (Base)")));

                "Quantity (Base)" := UOMMgt.RoundAndValidateQty("Quantity (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Quantity (Base)"));

                IsHandled := false;
                OnValidateQuantityBaseOnBeforeCheckItemTrackingChange(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);

                InitQtyToShip();
                CheckSerialNoQty();

                ClearApplyToEntryIfQuantityToInvoiceIsNotSufficient();
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(16; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(17; "Transfer Item Entry No."; Integer)
        {
            Caption = 'Transfer Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(24; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                if "Serial No." <> xRec."Serial No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    TestField("Appl.-from Item Entry", 0);
                    if IsReclass() then
                        "New Serial No." := "Serial No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    CheckSerialNoQty();
                    InitExpirationDate();
                end;
            end;
        }
        field(28; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Positive, true);
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetTrackingFilterFromSpec(Rec);
                ItemLedgEntry.SetRange(Open, true);
                if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
                    Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-to Item Entry" = 0 then
                    exit;

                if not TrackingExists() then
                    TestTrackingFieldsAreBlank();

                ItemLedgEntry.Get("Appl.-to Item Entry");

                TestApplyToItemLedgEntryNo(ItemLedgEntry);

                if Abs("Quantity (Base)" - "Quantity Handled (Base)") > Abs(ItemLedgEntry."Remaining Quantity") then
                    Error(
                      RemainingQtyErr,
                      ItemLedgEntry.FieldCaption("Remaining Quantity"), ItemLedgEntry."Entry No.");
            end;
        }
        field(40; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            var
                ItemTrackingMgt: Codeunit "Item Tracking Management";
                IsHandled: Boolean;
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);

                IsHandled := false;
                OnValidateExpirationDateOnBeforeResetExpirationDate(Rec, xRec, IsHandled);
                If not IsHandled then
                    if "Buffer Status2" = "Buffer Status2"::"ExpDate blocked" then begin
                        "Expiration Date" := xRec."Expiration Date";
                        Message(Text004);
                    end;

                if "Expiration Date" <> xRec."Expiration Date" then
                    ItemTrackingMgt.UpdateExpirationDateForLot(Rec);
            end;
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
            begin
                if ("Qty. to Handle (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Handle (Base)") > Abs("Quantity (Base)")
                    - "Quantity Handled (Base)")
                then
                    Error(Text001, "Quantity (Base)" - "Quantity Handled (Base)");

                OnValidateQtyToHandleOnBeforeInitQtyToInvoice(Rec, xRec, CurrFieldNo);

                "Qty. to Handle (Base)" := UOMMgt.RoundAndValidateQty("Qty. to Handle (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. to Handle (Base)"));

                InitQtyToInvoice();
                "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");
                CheckSerialNoQty();
            end;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs("Qty. to Handle (Base)"
                      + "Quantity Handled (Base)" - "Quantity Invoiced (Base)"))
                then
                    Error(
                      Text000,
                      "Qty. to Handle (Base)" + "Quantity Handled (Base)" - "Quantity Invoiced (Base)");

                "Qty. to Invoice (Base)" := UOMMgt.RoundAndValidateQty("Qty. to Invoice (Base)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. to Invoice (Base)"));

                "Qty. to Invoice" := CalcQty("Qty. to Invoice (Base)");
                CheckSerialNoQty();
            end;
        }
        field(52; "Quantity Handled (Base)"; Decimal)
        {
            Caption = 'Quantity Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
        }
        field(61; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Buffer Status"; Option)
        {
            Caption = 'Buffer Status';
            Editable = false;
            OptionCaption = ' ,MODIFY,INSERT';
            OptionMembers = " ",MODIFY,INSERT;
        }
        field(71; "Buffer Status2"; Option)
        {
            Caption = 'Buffer Status2';
            Editable = false;
            OptionCaption = ',ExpDate blocked';
            OptionMembers = ,"ExpDate blocked";
        }
        field(72; "Buffer Value1"; Decimal)
        {
            Caption = 'Buffer Value1';
            Editable = false;
        }
        field(73; "Buffer Value2"; Decimal)
        {
            Caption = 'Buffer Value2';
            Editable = false;
        }
        field(74; "Buffer Value3"; Decimal)
        {
            Caption = 'Buffer Value3';
            Editable = false;
        }
        field(75; "Buffer Value4"; Decimal)
        {
            Caption = 'Buffer Value4';
            Editable = false;
        }
        field(76; "Buffer Value5"; Decimal)
        {
            Caption = 'Buffer Value5';
            Editable = false;
        }
        field(80; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
                CheckSerialNoQty();
            end;
        }
        field(81; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
            end;
        }
        field(900; "Prohibit Cancellation"; Boolean)
        {
            Caption = 'Prohibit Cancellation';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                if "Lot No." <> xRec."Lot No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    TestField("Appl.-from Item Entry", 0);
                    if IsReclass() then
                        "New Lot No." := "Lot No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    InitExpirationDate();
                end;
            end;
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5402; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                ItemLedgEntry.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Positive, false);
                if "Location Code" <> '' then
                    ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetTrackingFilterFromSpec(Rec);
                ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
                OnAfterLookupApplFromItemEntrySetFilters(ItemLedgEntry, Rec);
                if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
                    Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" = 0 then
                    exit;

                CheckApplyFromItemEntrySourceType();

                if not TrackingExists() then
                    TestTrackingFieldsAreBlank();

                ItemLedgEntry.Get("Appl.-from Item Entry");
                ItemLedgEntry.TestField("Item No.", "Item No.");
                ItemLedgEntry.TestField(Positive, false);
                if ItemLedgEntry."Shipped Qty. Not Returned" + Abs("Qty. to Handle (Base)") > 0 then
                    ItemLedgEntry.FieldError("Shipped Qty. Not Returned");
                ItemLedgEntry.TestField("Variant Code", "Variant Code");
                ItemLedgEntry.TestTrackingEqualToTrackingSpec(Rec);

                OnAfterValidateApplFromItemEntry(Rec, ItemLedgEntry, IsReclass());
            end;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(6505; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';

            trigger OnValidate()
            begin
                WMSManagement.CheckItemTrackingChange(Rec, xRec);
            end;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                if "Package No." <> xRec."Package No." then begin
                    CheckPackageNo("Package No.");
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass() then
                        "New Package No." := "Package No.";
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                    InitExpirationDate();
                end;
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,2';

            trigger OnValidate()
            begin
                if "New Package No." <> xRec."New Package No." then begin
                    CheckPackageNo("New Package No.");
                    TestField("Quantity Handled (Base)", 0);
                    WMSManagement.CheckItemTrackingChange(Rec, xRec);
                end;
            end;
        }
        field(7300; "Quantity actual Handled (Base)"; Decimal)
        {
            Caption = 'Quantity actual Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.")
        {
            IncludedFields = "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)";
        }
#pragma warning disable AS0009
        key(Key3; "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
        }
#pragma warning disable AS0009
        key(Key4; "New Lot No.", "New Serial No.", "New Package No.")
#pragma warning restore AS0009
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        TestField("Quantity Handled (Base)", 0);
        TestField("Quantity Invoiced (Base)", 0);
    end;

    var
        CachedItem: Record Item;
        CachedItemTrackingCode: Record "Item Tracking Code";
        WMSManagement: Codeunit "WMS Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SkipSerialNoQtyValidation: Boolean;

        Text000: Label 'You cannot invoice more than %1 units.';
        Text001: Label 'You cannot handle more than %1 units.';
        Text002: Label 'must not be less than %1';
        Text003: Label '%1 must be -1, 0 or 1 when %2 is stated.';
        Text004: Label 'Expiration date has been established by existing entries and cannot be changed.';
        RemainingQtyErr: Label 'The %1 in item ledger entry %2 is too low to cover quantity available to handle.';
        WrongQtyForItemErr: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6.', Comment = '%1 - Qty. to Handle or Qty. to Invoice, %2 - Item No., %3 - actual value, %4 - expected value, %5 - Serial No., %6 - Lot No.';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, IsHandled);
        if IsHandled then
            exit;

        "Qty. to Handle (Base)" := "Quantity (Base)" - "Quantity Handled (Base)";
        "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");

        InitQtyToInvoice();

        OnAfterInitQtyToShip(Rec);
    end;

    procedure InitQtyToInvoice()
    begin
        OnBeforeInitQtyToInvoice(Rec);

        "Qty. to Invoice (Base)" := "Quantity Handled (Base)" + "Qty. to Handle (Base)" - "Quantity Invoiced (Base)";
        "Qty. to Invoice" := CalcQty("Qty. to Invoice (Base)");

        OnAfterInitQtyToInvoice(Rec);
    end;

    procedure InitFromAsmHeader(var AsmHeader: Record "Assembly Header")
    begin
        Init();
        SetItemData(
          AsmHeader."Item No.", AsmHeader.Description, AsmHeader."Location Code", AsmHeader."Variant Code", AsmHeader."Bin Code",
          AsmHeader."Qty. per Unit of Measure", AsmHeader."Qty. Rounding Precision (Base)");
        SetSource(DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", 0, '', 0);
        SetQuantities(
          AsmHeader."Quantity (Base)", AsmHeader."Quantity to Assemble", AsmHeader."Quantity to Assemble (Base)",
          AsmHeader."Quantity to Assemble", AsmHeader."Quantity to Assemble (Base)",
          AsmHeader."Assembled Quantity (Base)", AsmHeader."Assembled Quantity (Base)");

        OnAfterInitFromAsmHeader(Rec, AsmHeader);
    end;

    procedure InitFromAsmLine(var AsmLine: Record "Assembly Line")
    begin
        Init();
        SetItemData(
          AsmLine."No.", AsmLine.Description, AsmLine."Location Code", AsmLine."Variant Code", AsmLine."Bin Code",
          AsmLine."Qty. per Unit of Measure", AsmLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Assembly Line", AsmLine."Document Type".AsInteger(), AsmLine."Document No.", AsmLine."Line No.", '', 0);
        SetQuantities(
          AsmLine."Quantity (Base)", AsmLine."Quantity to Consume", AsmLine."Quantity to Consume (Base)",
          AsmLine."Quantity to Consume", AsmLine."Quantity to Consume (Base)",
          AsmLine."Consumed Quantity (Base)", AsmLine."Consumed Quantity (Base)");

        OnAfterInitFromAsmLine(Rec, AsmLine);
    end;

    procedure InitFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        Init();
        SetItemData(
          ItemJnlLine."Item No.", ItemJnlLine.Description, ItemJnlLine."Location Code", ItemJnlLine."Variant Code",
          ItemJnlLine."Bin Code", ItemJnlLine."Qty. per Unit of Measure", ItemJnlLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Item Journal Line", ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Line No.",
          ItemJnlLine."Journal Batch Name", 0);
        SetQuantities(
          ItemJnlLine."Quantity (Base)", ItemJnlLine.Quantity, ItemJnlLine."Quantity (Base)", ItemJnlLine.Quantity,
          ItemJnlLine."Quantity (Base)", 0, 0);

        OnAfterInitFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure InitFromInvtDocLine(var InvtDocLine: Record "Invt. Document Line")
    begin
        Init();
        SetItemData(
          InvtDocLine."Item No.", InvtDocLine.Description, InvtDocLine."Location Code", InvtDocLine."Variant Code",
          InvtDocLine."Bin Code", InvtDocLine."Qty. per Unit of Measure", InvtDocLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Invt. Document Line", InvtDocLine."Document Type".AsInteger(), InvtDocLine."Document No.", InvtDocLine."Line No.", '', 0);
        SetQuantities(
          InvtDocLine."Quantity (Base)", InvtDocLine.Quantity, InvtDocLine."Quantity (Base)", InvtDocLine.Quantity,
          InvtDocLine."Quantity (Base)", 0, 0);
    end;

    procedure InitFromJobJnlLine(var JobJnlLine: Record "Job Journal Line")
    begin
        Init();
        SetItemData(
          JobJnlLine."No.", JobJnlLine.Description, JobJnlLine."Location Code", JobJnlLine."Variant Code", JobJnlLine."Bin Code",
          JobJnlLine."Qty. per Unit of Measure", JobJnlLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Job Journal Line", JobJnlLine."Entry Type".AsInteger(), JobJnlLine."Journal Template Name", JobJnlLine."Line No.",
          JobJnlLine."Journal Batch Name", 0);
        SetQuantities(
          JobJnlLine."Quantity (Base)", JobJnlLine.Quantity, JobJnlLine."Quantity (Base)", JobJnlLine.Quantity,
          JobJnlLine."Quantity (Base)", 0, 0);

        OnAfterInitFromJobJnlLine(Rec, JobJnlLine);
    end;

    procedure InitFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        Init();
        SetItemData(
            JobPlanningLine."No.", JobPlanningLine.Description, JobPlanningLine."Location Code", JobPlanningLine."Variant Code",
            JobPlanningLine."Bin Code", JobPlanningLine."Qty. per Unit of Measure", JobPlanningLine."Qty. Rounding Precision (Base)");
        SetSource(
            DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", '', 0);
        SetQuantities(
            JobPlanningLine."Remaining Qty. (Base)", JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
            JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
            JobPlanningLine."Quantity" - JobPlanningLine."Remaining Qty.",
            JobPlanningLine."Quantity (Base)" - JobPlanningLine."Remaining Qty. (Base)");

        OnAfterInitFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    procedure InitFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        Init();
        SetItemData(
          PurchLine."No.", PurchLine.Description, PurchLine."Location Code", PurchLine."Variant Code", PurchLine."Bin Code",
          PurchLine."Qty. per Unit of Measure", PurchLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.", '', 0);
        if PurchLine.IsCreditDocType() then
            SetQuantities(
              PurchLine."Quantity (Base)", PurchLine."Return Qty. to Ship", PurchLine."Return Qty. to Ship (Base)",
              PurchLine."Qty. to Invoice", PurchLine."Qty. to Invoice (Base)", PurchLine."Return Qty. Shipped (Base)",
              PurchLine."Qty. Invoiced (Base)")
        else
            SetQuantities(
              PurchLine."Quantity (Base)", PurchLine."Qty. to Receive", PurchLine."Qty. to Receive (Base)",
              PurchLine."Qty. to Invoice", PurchLine."Qty. to Invoice (Base)", PurchLine."Qty. Received (Base)",
              PurchLine."Qty. Invoiced (Base)");

        OnAfterInitFromPurchLine(Rec, PurchLine);
    end;

    procedure InitFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        Init();
        SetItemData(
            ProdOrderLine."Item No.", ProdOrderLine.Description, ProdOrderLine."Location Code", ProdOrderLine."Variant Code", '',
            ProdOrderLine."Qty. per Unit of Measure", ProdOrderLine."Qty. Rounding Precision (Base)");
        SetSource(
            DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        SetQuantities(
            ProdOrderLine."Quantity (Base)", ProdOrderLine."Remaining Quantity", ProdOrderLine."Remaining Qty. (Base)",
            ProdOrderLine."Remaining Quantity", ProdOrderLine."Remaining Qty. (Base)", ProdOrderLine."Finished Qty. (Base)",
            ProdOrderLine."Finished Qty. (Base)");

        OnAfterInitFromProdOrderLine(Rec, ProdOrderLine);
    end;

    procedure InitFromProdOrderComp(var ProdOrderComp: Record "Prod. Order Component")
    begin
        Init();
        SetItemData(
            ProdOrderComp."Item No.", ProdOrderComp.Description, ProdOrderComp."Location Code", ProdOrderComp."Variant Code",
            ProdOrderComp."Bin Code", ProdOrderComp."Qty. per Unit of Measure", ProdOrderComp."Qty. Rounding Precision (Base)");
        SetSource(
            DATABASE::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.", '',
            ProdOrderComp."Prod. Order Line No.");
        SetQuantities(
            ProdOrderComp."Remaining Qty. (Base)", ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Remaining Qty. (Base)");

        OnAfterInitFromProdOrderComp(Rec, ProdOrderComp);
    end;

    procedure InitFromProdPlanningComp(var PlanningComponent: Record "Planning Component")
    var
        NetQuantity: Decimal;
    begin
        Init();
        SetItemData(
          PlanningComponent."Item No.", PlanningComponent.Description, PlanningComponent."Location Code",
          PlanningComponent."Variant Code", '', PlanningComponent."Qty. per Unit of Measure", PlanningComponent."Qty. Rounding Precision (Base)");
        SetSource(DATABASE::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
          PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
        NetQuantity :=
          Round(PlanningComponent."Net Quantity (Base)" / PlanningComponent."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        SetQuantities(
          PlanningComponent."Net Quantity (Base)", NetQuantity, PlanningComponent."Net Quantity (Base)", NetQuantity,
          PlanningComponent."Net Quantity (Base)", 0, 0);

        OnAfterInitFromProdPlanningComp(Rec, PlanningComponent);
    end;

    procedure InitFromReqLine(ReqLine: Record "Requisition Line")
    begin
        Init();
        SetItemData(
          ReqLine."No.", ReqLine.Description, ReqLine."Location Code", ReqLine."Variant Code", '', ReqLine."Qty. per Unit of Measure", ReqLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Requisition Line", 0, ReqLine."Worksheet Template Name", ReqLine."Line No.", ReqLine."Journal Batch Name", 0);
        SetQuantities(
          ReqLine."Quantity (Base)", ReqLine.Quantity, ReqLine."Quantity (Base)", ReqLine.Quantity, ReqLine."Quantity (Base)", 0, 0);

        OnAfterInitFromReqLine(Rec, ReqLine);
    end;

    procedure InitFromSalesLine(SalesLine: Record "Sales Line")
    begin
        Init();
        SetItemData(
          SalesLine."No.", SalesLine.Description, SalesLine."Location Code", SalesLine."Variant Code", SalesLine."Bin Code",
          SalesLine."Qty. per Unit of Measure", SalesLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", '', 0);
        if SalesLine.IsCreditDocType() then
            SetQuantities(
              SalesLine."Quantity (Base)", SalesLine."Return Qty. to Receive", SalesLine."Return Qty. to Receive (Base)",
              SalesLine."Qty. to Invoice", SalesLine."Qty. to Invoice (Base)", SalesLine."Return Qty. Received (Base)",
              SalesLine."Qty. Invoiced (Base)")
        else
            SetQuantities(
              SalesLine."Quantity (Base)", SalesLine."Qty. to Ship", SalesLine."Qty. to Ship (Base)", SalesLine."Qty. to Invoice",
              SalesLine."Qty. to Invoice (Base)", SalesLine."Qty. Shipped (Base)", SalesLine."Qty. Invoiced (Base)");

        OnAfterInitFromSalesLine(Rec, SalesLine);
    end;

    procedure InitFromServLine(var ServiceLine: Record "Service Line"; Consume: Boolean)
    begin
        Init();
        SetItemData(
          ServiceLine."No.", ServiceLine.Description, ServiceLine."Location Code", ServiceLine."Variant Code", ServiceLine."Bin Code",
          ServiceLine."Qty. per Unit of Measure", ServiceLine."Qty. Rounding Precision (Base)");
        SetSource(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", '', 0);

        "Quantity (Base)" := ServiceLine."Quantity (Base)";
        if Consume then begin
            "Qty. to Invoice (Base)" := ServiceLine."Qty. to Consume (Base)";
            "Qty. to Invoice" := ServiceLine."Qty. to Consume";
            "Quantity Invoiced (Base)" := ServiceLine."Qty. Consumed (Base)";
        end else begin
            "Qty. to Invoice (Base)" := ServiceLine."Qty. to Invoice (Base)";
            "Qty. to Invoice" := ServiceLine."Qty. to Invoice";
            "Quantity Invoiced (Base)" := ServiceLine."Qty. Invoiced (Base)";
        end;

        if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then begin
            "Qty. to Handle" := ServiceLine."Qty. to Invoice";
            "Qty. to Handle (Base)" := ServiceLine."Qty. to Invoice (Base)";
            "Quantity Handled (Base)" := ServiceLine."Qty. Invoiced (Base)";
        end else begin
            "Qty. to Handle" := ServiceLine."Qty. to Ship";
            "Qty. to Handle (Base)" := ServiceLine."Qty. to Ship (Base)";
            "Quantity Handled (Base)" := ServiceLine."Qty. Shipped (Base)";
        end;

        OnAfterInitFromServLine(Rec, ServiceLine);
    end;

    procedure InitFromTransLine(var TransLine: Record "Transfer Line"; var AvalabilityDate: Date; Direction: Enum "Transfer Direction")
    begin
        case Direction of
            Direction::Outbound:
                begin
                    Init();
                    SetItemData(
                      TransLine."Item No.", TransLine.Description, TransLine."Transfer-from Code", TransLine."Variant Code",
                      TransLine."Transfer-from Bin Code", TransLine."Qty. per Unit of Measure", TransLine."Qty. Rounding Precision (Base)");
                    SetSource(
                      DATABASE::"Transfer Line", Direction.AsInteger(), TransLine."Document No.", TransLine."Line No.", '',
                      TransLine."Derived From Line No.");
                    SetQuantities(
                      TransLine."Quantity (Base)", TransLine."Qty. to Ship", TransLine."Qty. to Ship (Base)", TransLine.Quantity,
                      TransLine."Quantity (Base)", TransLine."Qty. Shipped (Base)", 0);
                    AvalabilityDate := TransLine."Shipment Date";
                end;
            Direction::Inbound:
                begin
                    Init();
                    SetItemData(
                      TransLine."Item No.", TransLine.Description, TransLine."Transfer-to Code", TransLine."Variant Code",
                      TransLine."Transfer-To Bin Code", TransLine."Qty. per Unit of Measure", TransLine."Qty. Rounding Precision (Base)");
                    SetSource(
                      DATABASE::"Transfer Line", Direction.AsInteger(), TransLine."Document No.", TransLine."Line No.", '',
                      TransLine."Derived From Line No.");
                    SetQuantities(
                      TransLine."Quantity (Base)", TransLine."Qty. to Receive", TransLine."Qty. to Receive (Base)", TransLine.Quantity,
                      TransLine."Quantity (Base)", TransLine."Qty. Received (Base)", 0);
                    AvalabilityDate := TransLine."Receipt Date";
                end;
        end;

        OnAfterInitFromTransLine(Rec, TransLine, Direction);
    end;

    local procedure CheckApplyFromItemEntrySourceType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplyFromItemEntrySourceType(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Source Type" of
            DATABASE::"Sales Line":
                if (("Source Subtype" in [3, 5]) and ("Quantity (Base)" < 0)) or
                    (("Source Subtype" in [1, 2]) and ("Quantity (Base)" > 0)) // sale
                then
                    FieldError("Quantity (Base)");
            DATABASE::"Item Journal Line":
                if (("Source Subtype" in [0, 2, 6]) and ("Quantity (Base)" < 0)) or
                    (("Source Subtype" in [1, 3, 4, 5]) and ("Quantity (Base)" > 0))
                then
                    FieldError("Quantity (Base)");
            DATABASE::"Service Line":
                if (("Source Subtype" in [3]) and ("Quantity (Base)" < 0)) or
                    (("Source Subtype" in [1, 2]) and ("Quantity (Base)" > 0))
                then
                    FieldError("Quantity (Base)");
            DATABASE::"Invt. Document Line":
                if (("Source Subtype" in [1, 3, 4, 5]) and ("Quantity (Base)" < 0)) or
                    (("Source Subtype" in [0, 2, 6]) and ("Quantity (Base)" > 0))
                then
                    FieldError("Quantity (Base)");
            else begin
                IsHandled := false;
                OnValidateApplFromItemEntryOnSourceTypeCaseElse(Rec, IsHandled);
                if not IsHandled then
                    FieldError("Source Subtype");
            end;
        end;
    end;

    local procedure CheckSerialNoQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNoQty(Rec, IsHandled);
        if IsHandled then
            exit;

        if SkipSerialNoQtyValidation then
            exit;

        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;
        if not ("Quantity (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Quantity (Base)"), FieldCaption("Serial No."));
        if not ("Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Qty. to Handle (Base)"), FieldCaption("Serial No."));
        if not ("Qty. to Invoice (Base)" in [-1, 0, 1]) then
            Error(Text003, FieldCaption("Qty. to Invoice (Base)"), FieldCaption("Serial No."));

        OnAfterCheckSerialNoQty(Rec);
    end;

    procedure CalcQty(BaseQty: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        exit(Round(BaseQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    procedure CopySpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        Reset();
        if TempTrackingSpecification.FindSet() then begin
            repeat
                Rec := TempTrackingSpecification;
                if Insert() then;
            until TempTrackingSpecification.Next() = 0;
            TempTrackingSpecification.DeleteAll();
        end;
    end;

    procedure HasSameTracking(TrackingSpecification: Record "Tracking Specification") IsSameTracking: Boolean;
    begin
        IsSameTracking :=
            ("Serial No." = TrackingSpecification."Serial No.") and
            ("Lot No." = TrackingSpecification."Lot No.");

        OnAfterHasSameTracking(Rec, TrackingSpecification, IsSameTracking);
    end;

    procedure InsertSpecification()
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        Reset();
        if FindSet() then begin
            repeat
                TrackingSpecification := Rec;
                TrackingSpecification."Buffer Status" := 0;
                TrackingSpecification.InitQtyToShip();
                TrackingSpecification.Correction := false;
                TrackingSpecification."Quantity actual Handled (Base)" := 0;
                OnBeforeUpdateTrackingSpecification(Rec, TrackingSpecification);
                if "Buffer Status" = "Buffer Status"::MODIFY then
                    TrackingSpecification.Modify()
                else
                    TrackingSpecification.Insert();
            until Next() = 0;
            DeleteAll();
        end;
    end;

    procedure InitTrackingSpecification(FromType: Integer; FromSubtype: Integer; FromID: Code[20]; FromBatchName: Code[10]; FromProdOrderLine: Integer; FromRefNo: Integer; FromVariantCode: Code[10]; FromLocationCode: Code[10]; FromQtyPerUOM: Decimal)
    begin
        SetSource(FromType, FromSubtype, FromID, FromRefNo, FromBatchName, FromProdOrderLine);
        "Variant Code" := FromVariantCode;
        "Location Code" := FromLocationCode;
        "Qty. per Unit of Measure" := FromQtyPerUOM;
    end;

    procedure InitExpirationDate()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpDate: Date;
        EntriesExist: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitExpirationDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if HasSameTracking(xRec) then
            exit;

        "Expiration Date" := 0D;
        ItemTrackingMgt.CopyExpirationDateForLot(Rec);

        GetItemTrackingCode("Item No.", ItemTrackingCode);
        if not ItemTrackingCode."Use Expiration Dates" then
            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked"
        else begin
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(Rec, false, EntriesExist);
            if EntriesExist then begin
                "Expiration Date" := ExpDate;
                "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
            end else
                "Buffer Status2" := 0;
        end;

        if IsReclass() then begin
            "New Expiration Date" := "Expiration Date";
            ItemTrackingSetup.CopyTrackingFromNewTrackingSpec(Rec);
            "Warranty Date" := ItemTrackingMgt.ExistingWarrantyDate("Item No.", "Variant Code", ItemTrackingSetup, EntriesExist);
        end;

        OnAfterInitExpirationDate(Rec);
    end;

    procedure IsReclass() Reclass: Boolean
    begin
        Reclass := ("Source Type" = DATABASE::"Item Journal Line") and ("Source Subtype" = 4);

        OnAfterIsReclass(Rec, Reclass);
    end;

    local procedure TestApplyToItemLedgEntryNo(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestApplyToItemLedgEntry(Rec, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.TestField("Item No.", "Item No.");
        ItemLedgEntry.TestField(Positive, true);
        ItemLedgEntry.TestField("Variant Code", "Variant Code");
        ItemLedgEntry.TestTrackingEqualToTrackingSpec(Rec);
        if "Source Type" = DATABASE::"Item Journal Line" then begin
            ItemJnlLine.SetRange("Journal Template Name", "Source ID");
            ItemJnlLine.SetRange("Journal Batch Name", "Source Batch Name");
            ItemJnlLine.SetRange("Line No.", "Source Ref. No.");
            ItemJnlLine.SetRange("Entry Type", "Source Subtype");
            if ItemJnlLine.FindFirst() then
                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output then begin
                    ItemLedgEntry.TestField("Order Type", ItemJnlLine."Order Type"::Production);
                    ItemLedgEntry.TestField("Order No.", ItemJnlLine."Order No.");
                    ItemLedgEntry.TestField("Order Line No.", ItemJnlLine."Order Line No.");
                    ItemLedgEntry.TestField("Entry Type", ItemJnlLine."Entry Type");
                end;
        end;
    end;

    procedure TestFieldError(FieldCaptionText: Text[80]; CurrFieldValue: Decimal; CompareValue: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldError(FieldCaptionText, CurrFieldValue, CompareValue, IsHandled);
        if IsHandled then
            exit;

        if CurrFieldValue = CompareValue then
            exit;

        Error(
          WrongQtyForItemErr,
          FieldCaptionText, "Item No.", Abs(CurrFieldValue), Abs(CompareValue), "Serial No.", "Lot No.");
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Bin Code" := BinCode;
        "Qty. per Unit of Measure" := QtyPerUoM;
    end;

    local procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; QtyPerUoM: Decimal; QtyRoundingPrecision: Decimal)
    begin
        SetItemData(ItemNo, ItemDescription, LocationCode, VariantCode, BinCode, QtyPerUoM);
        "Qty. Rounding Precision (Base)" := QtyRoundingPrecision;
    end;

    procedure SetQuantities(QtyBase: Decimal; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal; QtyHandledBase: Decimal; QtyInvoicedBase: Decimal)
    begin
        "Quantity (Base)" := QtyBase;
        "Qty. to Handle" := QtyToHandle;
        "Qty. to Handle (Base)" := QtyToHandleBase;
        "Qty. to Invoice" := QtyToInvoice;
        "Qty. to Invoice (Base)" := QtyToInvoiceBase;
        "Quantity Handled (Base)" := QtyHandledBase;
        "Quantity Invoiced (Base)" := QtyInvoicedBase;
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source ID");
        SetRange("Source Ref. No.");
        SetRange("Source Batch Name");
        SetRange("Source Prod. Order Line");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Source Type" := DATABASE::"Purchase Line";
        "Source Subtype" := PurchLine."Document Type".AsInteger();
        "Source ID" := PurchLine."Document No.";
        "Source Batch Name" := '';
        "Source Prod. Order Line" := 0;
        "Source Ref. No." := PurchLine."Line No.";

        OnAfterSetSourceFromPurchLine(Rec, PurchLine);
    end;

    procedure SetSourceFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Source Type" := DATABASE::"Sales Line";
        "Source Subtype" := SalesLine."Document Type".AsInteger();
        "Source ID" := SalesLine."Document No.";
        "Source Batch Name" := '';
        "Source Prod. Order Line" := 0;
        "Source Ref. No." := SalesLine."Line No.";

        OnAfterSetSourceFromSalesLine(Rec, SalesLine);
    end;

    procedure SetSourceFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Source Type" := ReservEntry."Source Type";
        "Source Subtype" := ReservEntry."Source Subtype";
        "Source ID" := ReservEntry."Source ID";
        "Source Batch Name" := ReservEntry."Source Batch Name";
        "Source Prod. Order Line" := ReservEntry."Source Prod. Order Line";
        "Source Ref. No." := ReservEntry."Source Ref. No.";
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Warranty Date" := 0D;
        "Expiration Date" := 0D;

        OnAfterClearTracking(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure SetTrackingBlank()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Warranty Date" := 0D;
        "Expiration Date" := 0D;

        OnAfterSetTrackingBlank(Rec);
    end;

    procedure CopyTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."Serial No.";
        "New Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyNewTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromNewTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyNewTrackingFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        "Serial No." := EntrySummary."Serial No.";
        "Lot No." := EntrySummary."Lot No.";

        OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterBlank()
    begin
        SetRange("Serial No.", '');
        SetRange("Lot No.", '');

        OnAfterSetTrackingFilterBlank(Rec);
    end;

    procedure SetTrackingFilterFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        SetRange("Serial No.", EntrySummary."Serial No.");
        SetRange("Lot No.", EntrySummary."Lot No.");

        OnAfterSetTrackingFilterFromEntrySummary(Rec, EntrySummary);
    end;

    procedure SetTrackingFilterFromItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        SetRange("Serial No.", ItemJnlLine."Serial No.");
        SetRange("Lot No.", ItemJnlLine."Lot No.");

        OnAfterSetTrackingFilterFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservEntry."Serial No.");
        SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetNewTrackingFilterFromNewReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("New Serial No.", ReservEntry."New Serial No.");
        SetRange("New Lot No.", ReservEntry."New Lot No.");

        OnAfterSetNewTrackingFilterFromNewReservEntry(Rec, ReservEntry);
    end;

    procedure SetNewTrackingFilterFromNewTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("New Serial No.", TrackingSpecification."New Serial No.");
        SetRange("New Lot No.", TrackingSpecification."New Lot No.");

        OnAfterSetNewTrackingFilterFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetNonSerialTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetNonSerialTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WhseActivityLine."Serial No.");
        SetRange("Lot No.", WhseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure SetTrackingKey()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingKey(Rec, IsHandled);
        if not IsHandled then
            SetCurrentKey("Lot No.", "Serial No.", "Package No.");
    end;

    procedure SetSkipSerialNoQtyValidation(NewSkipSerialNoQtyValidation: Boolean)
    begin
        SkipSerialNoQtyValidation := NewSkipSerialNoQtyValidation;
    end;

    procedure CheckItemTrackingQuantity(TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; Handle: Boolean; Invoice: Boolean)
    begin
        CheckItemTrackingQuantity(TableNo, DocumentType, DocumentNo, LineNo, -1, QtyToHandleBase, QtyToInvoiceBase, Handle, Invoice);
    end;

    procedure CheckItemTrackingQuantity(TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; ProdOrderLineNo: Integer; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; Handle: Boolean; Invoice: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingQuantity(
            Rec, TableNo, DocumentType, DocumentNo, LineNo, ProdOrderLineNo,
            QtyToHandleBase, QtyToInvoiceBase, Handle, Invoice, IsHandled);
        if IsHandled then
            exit;

        if QtyToHandleBase = 0 then
            Handle := false;
        if QtyToInvoiceBase = 0 then
            Invoice := false;
        if not (Handle or Invoice) then
            exit;
        ReservationEntry.SetSourceFilter(TableNo, DocumentType, DocumentNo, LineNo, true);
        if ProdOrderLineNo >= 0 then
            ReservationEntry.SetSourceFilter('', ProdOrderLineNo);
        ReservationEntry.SetFilter("Item Tracking", '%1|%2',
          ReservationEntry."Item Tracking"::"Lot and Serial No.",
          ReservationEntry."Item Tracking"::"Serial No.");
        CheckItemTrackingByType(ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, false, Handle, Invoice);
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::"Lot No.");
        CheckItemTrackingByType(ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, true, Handle, Invoice);

        OnAfterCheckItemTrackingQuantity(Rec, ReservationEntry, TableNo, DocumentType, DocumentNo, LineNo);
    end;

    procedure CheckItemTrackingByType(var ReservationEntry: Record "Reservation Entry"; QtyToHandleBase: Decimal; QtyToInvoiceBase: Decimal; OnlyLot: Boolean; Handle: Boolean; Invoice: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        HandleQtyBase: Decimal;
        InvoiceQtyBase: Decimal;
        LotsToHandleUndefined: Boolean;
        LotsToInvoiceUndefined: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingByType(
            ReservationEntry, QtyToHandleBase, QtyToInvoiceBase, OnlyLot, Handle, Invoice, IsHandled);
        if IsHandled then
            exit;

        if OnlyLot then begin
            GetUndefinedLots(ReservationEntry, Handle, Invoice, LotsToHandleUndefined, LotsToInvoiceUndefined);
            if not (LotsToHandleUndefined or LotsToInvoiceUndefined) then
                exit;
        end;

        if Handle then begin
            ReservationEntry.SetFilter("Qty. to Handle (Base)", '<>%1', 0);
            ReservationEntry.CalcSums("Qty. to Handle (Base)");
            HandleQtyBase := ReservationEntry."Qty. to Handle (Base)";

            if Abs(HandleQtyBase) > Abs(QtyToHandleBase) then begin
                ReservationEntry.FindLast();
                TrackingSpecification.TransferFields(ReservationEntry);
                TrackingSpecification.TestFieldError(FieldCaption("Qty. to Handle (Base)"), HandleQtyBase, QtyToHandleBase);
            end;
            ReservationEntry.SetRange("Qty. to Handle (Base)");
        end;

        if Invoice then begin
            ReservationEntry.SetFilter("Qty. to Invoice (Base)", '<>%1', 0);
            if ReservationEntry.FindSet() then
                repeat
                    InvoiceQtyBase += ReservationEntry."Qty. to Invoice (Base)";
                until ReservationEntry.Next() = 0;
            if Abs(InvoiceQtyBase) > Abs(QtyToInvoiceBase) then begin
                ReservationEntry.FindLast();
                TrackingSpecification.TransferFields(ReservationEntry);
                TrackingSpecification.TestFieldError(FieldCaption("Qty. to Invoice (Base)"), InvoiceQtyBase, QtyToInvoiceBase);
            end;
            ReservationEntry.SetRange("Qty. to Invoice (Base)");
        end;
    end;

    local procedure GetUndefinedLots(var ReservationEntry: Record "Reservation Entry"; Handle: Boolean; Invoice: Boolean; var LotsToHandleUndefined: Boolean; var LotsToInvoiceUndefined: Boolean)
    var
        HandleLotNo: Code[50];
        InvoiceLotNo: Code[50];
        StopLoop: Boolean;
    begin
        LotsToHandleUndefined := false;
        LotsToInvoiceUndefined := false;
        if not ReservationEntry.FindSet() then
            exit;
        repeat
            if Handle then begin
                CheckLot(ReservationEntry."Qty. to Handle (Base)", ReservationEntry."Lot No.", HandleLotNo, LotsToHandleUndefined);
                if LotsToHandleUndefined and not Invoice then
                    StopLoop := true;
            end;
            if Invoice then begin
                CheckLot(ReservationEntry."Qty. to Invoice (Base)", ReservationEntry."Lot No.", InvoiceLotNo, LotsToInvoiceUndefined);
                if LotsToInvoiceUndefined and not Handle then
                    StopLoop := true;
            end;
            if LotsToHandleUndefined and LotsToInvoiceUndefined then
                StopLoop := true;
        until StopLoop or (ReservationEntry.Next() = 0);
    end;

    local procedure CheckLot(ReservQty: Decimal; ReservLotNo: Code[50]; var LotNo: Code[50]; var Undefined: Boolean)
    begin
        Undefined := false;
        if ReservQty = 0 then
            exit;
        if LotNo = '' then
            LotNo := ReservLotNo
        else
            if ReservLotNo <> LotNo then
                Undefined := true;
    end;

    local procedure QuantityToInvoiceIsSufficient(): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        case "Source Type" of
            DATABASE::"Sales Line":
                if SalesLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then
                    exit("Quantity (Base)" <= SalesLine."Qty. to Invoice (Base)");
            DATABASE::"Purchase Line":
                if PurchaseLine.Get("Source Subtype", "Source ID", "Source Ref. No.") then
                    exit("Quantity (Base)" <= PurchaseLine."Qty. to Invoice (Base)");
        end;

        exit(false);
    end;

    local procedure ClearApplyToEntryIfQuantityToInvoiceIsNotSufficient()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearApplyToEntryIfQuantityToInvoiceIsNotSufficient(Rec, IsHandled);
        if IsHandled then
            exit;

        if not QuantityToInvoiceIsSufficient() then
            Validate("Appl.-to Item Entry", 0);
    end;

    procedure TestTrackingFieldsAreBlank();
    begin
        TestField("Serial No.");
        TestField("Lot No.");

        OnAfterTestTrackingFieldsAreBlank(Rec);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExist(Rec, IsTrackingExist);
    end;

    procedure NonSerialTrackingExists() IsTrackingExists: Boolean
    begin
        IsTrackingExists := "Lot No." <> '';

        OnAfterNonSerialTrackingExists(Rec, IsTrackingExists);
    end;

    local procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        if CachedItem."No." <> ItemNo then begin
            // searching for a new item, clear the cached item
            Clear(CachedItem);

            // get the item from the database
            if CachedItem.Get(ItemNo) then begin
                if CachedItem."Item Tracking Code" <> CachedItemTrackingCode.Code then
                    Clear(CachedItemTrackingCode); // item tracking code changed, clear the cached tracking code

                if CachedItem."Item Tracking Code" <> '' then
                    // item tracking code changed to something not empty, so get the new item tracking code from the database
                    CachedItemTrackingCode.Get(CachedItem."Item Tracking Code");
            end else
                Clear(CachedItemTrackingCode); // can't find the item, so clear the cached tracking code as well
        end;

        ItemTrackingCode := CachedItemTrackingCode;
    end;

    local procedure CheckPackageNo(PackageNo: Code[50])
    begin
        OnCheckPackageNo(Rec, PackageNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservEntry: Record "Reservation Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromAsmHeader(var TrackingSpecification: Record "Tracking Specification"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromAsmLine(var TrackingSpecification: Record "Tracking Specification"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN20
    [Obsolete('Event is never raised.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobJnlLine(var TrackingSpecification: Record "Tracking Specification"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var TrackingSpecification: Record "Tracking Specification"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderLine(var TrackingSpecification: Record "Tracking Specification"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderComp(var TrackingSpecification: Record "Tracking Specification"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdPlanningComp(var TrackingSpecification: Record "Tracking Specification"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromReqLine(var TrackingSpecification: Record "Tracking Specification"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromServLine(var TrackingSpecification: Record "Tracking Specification"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTransLine(var TrackingSpecification: Record "Tracking Specification"; TransferLine: Record "Transfer Line"; Direction: Enum "Transfer Direction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitExpirationDate(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFilterFromNewReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewTrackingFilterFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNonSerialTrackingFilterFromSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var TrackingSpecification: Record "Tracking Specification"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupApplFromItemEntrySetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestTrackingFieldsAreBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNonSerialTrackingExists(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameTracking(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateApplFromItemEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry"; IsReclassification: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoQty(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearApplyToEntryIfQuantityToInvoiceIsNotSufficient(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestApplyToItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldError(FieldCaptionText: Text[80]; CurrFieldValue: Decimal; CompareValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPackageNo(TrackingSpecification: Record "Tracking Specification"; PackageNo: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; var FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnBeforeInitQtyToInvoice(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplFromItemEntryOnSourceTypeCaseElse(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingQuantity(var TrackingSpecification: Record "Tracking Specification"; TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer; ProdOrderLineNo: Integer; var QtyToHandleBase: Decimal; var QtyToInvoiceBase: Decimal; var Handle: Boolean; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingByType(var ReservationEntry: Record "Reservation Entry"; var QtyToHandleBase: Decimal; var QtyToInvoiceBase: Decimal; var OnlyLot: Boolean; var Handle: Boolean; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFromSalesLine(var TrackingSpecification: Record "Tracking Specification"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitExpirationDate(var TrackingSpecification: Record "Tracking Specification"; xRec: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackingKey(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsReclass(TrackingSpecification: Record "Tracking Specification"; var Reclass: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingQuantity(var TrackingSpecification: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry"; TableNo: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSerialNoQty(var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityBaseOnBeforeCheckItemTrackingChange(var TrackingSpecification: Record "Tracking Specification"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpirationDateOnBeforeResetExpirationDate(var TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplyFromItemEntrySourceType(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;
}

