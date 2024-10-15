table 7302 "Bin Content"
{
    Caption = 'Bin Content';
    DrillDownPageID = "Bin Contents List";
    LookupPageID = "Bin Contents List";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Location Code" <> xRec."Location Code") then begin
                    CheckManualChange(FieldCaption("Location Code"));
                    "Bin Code" := '';
                end;
            end;
        }
        field(2; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Zone Code" <> xRec."Zone Code") then
                    CheckManualChange(FieldCaption("Zone Code"));
            end;
        }
        field(3; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            NotBlank = true;
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Bin Code" <> xRec."Bin Code") then begin
                    CheckManualChange(FieldCaption("Bin Code"));
                    GetBin("Location Code", "Bin Code");
                    Dedicated := Bin.Dedicated;
                    "Bin Type Code" := Bin."Bin Type Code";
                    "Warehouse Class Code" := Bin."Warehouse Class Code";
                    "Bin Ranking" := Bin."Bin Ranking";
                    "Block Movement" := Bin."Block Movement";
                    "Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item WHERE(Type = CONST(Inventory));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Item No." <> xRec."Item No.") then begin
                    CheckManualChange(FieldCaption("Item No."));
                    "Variant Code" := '';
                end;

                if ("Item No." <> xRec."Item No.") and ("Item No." <> '') then begin
                    GetItem("Item No.");
                    Validate("Unit of Measure Code", Item."Base Unit of Measure");
                end;
            end;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            Editable = false;
            TableRelation = "Bin Type";
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            Editable = false;
            TableRelation = "Warehouse Class";
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(15; "Min. Qty."; Decimal)
        {
            Caption = 'Min. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Max. Qty."; Decimal)
        {
            Caption = 'Max. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Max. Qty." <> xRec."Max. Qty." then
                    CheckBinMaxCubageAndWeight;
            end;
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
            Editable = false;
        }
        field(26; Quantity; Decimal)
        {
            CalcFormula = Sum ("Warehouse Entry".Quantity WHERE("Location Code" = FIELD("Location Code"),
                                                                "Bin Code" = FIELD("Bin Code"),
                                                                "Item No." = FIELD("Item No."),
                                                                "Variant Code" = FIELD("Variant Code"),
                                                                "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                "Lot No." = FIELD("Lot No. Filter"),
                                                                "Serial No." = FIELD("Serial No. Filter"),
                                                                "CD No." = FIELD("CD No. Filter")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Pick Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Bin Code" = FIELD("Bin Code"),
                                                                                  "Item No." = FIELD("Item No."),
                                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = CONST(Take),
                                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                                  "Serial No." = FIELD("Serial No. Filter"),
                                                                                  "Assemble to Order" = CONST(false)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Neg. Adjmt. Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Journal Line"."Qty. (Absolute)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                "From Bin Code" = FIELD("Bin Code"),
                                                                                "Item No." = FIELD("Item No."),
                                                                                "Variant Code" = FIELD("Variant Code"),
                                                                                "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                "Lot No." = FIELD("Lot No. Filter"),
                                                                                "Serial No." = FIELD("Serial No. Filter"),
                                                                                "CD No." = FIELD("CD No. Filter")));
            Caption = 'Neg. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Put-away Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Bin Code" = FIELD("Bin Code"),
                                                                                  "Item No." = FIELD("Item No."),
                                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = CONST(Place),
                                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                                  "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Put-away Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Pos. Adjmt. Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Journal Line"."Qty. (Absolute)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                "To Bin Code" = FIELD("Bin Code"),
                                                                                "Item No." = FIELD("Item No."),
                                                                                "Variant Code" = FIELD("Variant Code"),
                                                                                "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                "Lot No." = FIELD("Lot No. Filter"),
                                                                                "Serial No." = FIELD("Serial No. Filter"),
                                                                                "CD No." = FIELD("CD No. Filter")));
            Caption = 'Pos. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
        }
        field(40; "Cross-Dock Bin"; Boolean)
        {
            Caption = 'Cross-Dock Bin';
        }
        field(41; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            begin
                if (xRec.Default <> Default) and Default then
                    if WMSManagement.CheckDefaultBin(
                         "Item No.", "Variant Code", "Location Code", "Bin Code")
                    then
                        Error(Text010, "Location Code", "Item No.", "Variant Code");
            end;
        }
        field(50; "Quantity (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Entry"."Qty. (Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                     "Bin Code" = FIELD("Bin Code"),
                                                                     "Item No." = FIELD("Item No."),
                                                                     "Variant Code" = FIELD("Variant Code"),
                                                                     "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                     "Lot No." = FIELD("Lot No. Filter"),
                                                                     "Serial No." = FIELD("Serial No. Filter"),
                                                                     "CD No." = FIELD("CD No. Filter")));
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Pick Quantity (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                         "Bin Code" = FIELD("Bin Code"),
                                                                                         "Item No." = FIELD("Item No."),
                                                                                         "Variant Code" = FIELD("Variant Code"),
                                                                                         "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                                         "Action Type" = CONST(Take),
                                                                                         "Lot No." = FIELD("Lot No. Filter"),
                                                                                         "Serial No." = FIELD("Serial No. Filter"),
                                                                                         "Assemble to Order" = CONST(false)));
            Caption = 'Pick Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Negative Adjmt. Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Journal Line"."Qty. (Absolute, Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                      "From Bin Code" = FIELD("Bin Code"),
                                                                                      "Item No." = FIELD("Item No."),
                                                                                      "Variant Code" = FIELD("Variant Code"),
                                                                                      "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                      "Lot No." = FIELD("Lot No. Filter"),
                                                                                      "Serial No." = FIELD("Serial No. Filter"),
                                                                                      "CD No." = FIELD("CD No. Filter")));
            Caption = 'Negative Adjmt. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Put-away Quantity (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                         "Bin Code" = FIELD("Bin Code"),
                                                                                         "Item No." = FIELD("Item No."),
                                                                                         "Variant Code" = FIELD("Variant Code"),
                                                                                         "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                         "Action Type" = CONST(Place),
                                                                                         "Lot No." = FIELD("Lot No. Filter"),
                                                                                         "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Put-away Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Positive Adjmt. Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Journal Line"."Qty. (Absolute, Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                      "To Bin Code" = FIELD("Bin Code"),
                                                                                      "Item No." = FIELD("Item No."),
                                                                                      "Variant Code" = FIELD("Variant Code"),
                                                                                      "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                      "Lot No." = FIELD("Lot No. Filter"),
                                                                                      "Serial No." = FIELD("Serial No. Filter"),
                                                                                      "CD No." = FIELD("CD No. Filter")));
            Caption = 'Positive Adjmt. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "ATO Components Pick Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Bin Code" = FIELD("Bin Code"),
                                                                                  "Item No." = FIELD("Item No."),
                                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = CONST(Take),
                                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                                  "Serial No." = FIELD("Serial No. Filter"),
                                                                                  "Assemble to Order" = CONST(true),
                                                                                  "ATO Component" = CONST(true)));
            Caption = 'ATO Components Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "ATO Components Pick Qty (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Location Code" = FIELD("Location Code"),
                                                                                         "Bin Code" = FIELD("Bin Code"),
                                                                                         "Item No." = FIELD("Item No."),
                                                                                         "Variant Code" = FIELD("Variant Code"),
                                                                                         "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                         "Action Type" = CONST(Take),
                                                                                         "Lot No." = FIELD("Lot No. Filter"),
                                                                                         "Serial No." = FIELD("Serial No. Filter"),
                                                                                         "Assemble to Order" = CONST(true),
                                                                                         "ATO Component" = CONST(true)));
            Caption = 'ATO Components Pick Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Variant Code" <> xRec."Variant Code") then
                    CheckManualChange(FieldCaption("Variant Code"));
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
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Unit of Measure Code" <> xRec."Unit of Measure Code") then
                    CheckManualChange(FieldCaption("Unit of Measure Code"));

                GetItem("Item No.");
                "Qty. per Unit of Measure" :=
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            end;
        }
        field(6500; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(6501; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(6502; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
        field(6503; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(14900; "CD No. Filter"; Code[30])
        {
            Caption = 'CD No. Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        {
            Clustered = true;
        }
        key(Key2; "Bin Type Code")
        {
        }
        key(Key3; "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking")
        {
        }
        key(Key4; "Location Code", "Warehouse Class Code", "Fixed", "Bin Ranking")
        {
        }
        key(Key5; "Location Code", "Item No.", "Variant Code", "Warehouse Class Code", "Fixed", "Bin Ranking")
        {
        }
        key(Key6; "Item No.")
        {
        }
        key(Key7; Default, "Location Code", "Item No.", "Variant Code", "Bin Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent := Rec;
        BinContent.CalcFields(
          "Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)",
          "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
        if BinContent."Quantity (Base)" <> 0 then
            Error(Text000, TableCaption);

        if (BinContent."Pick Quantity (Base)" <> 0) or (BinContent."Negative Adjmt. Qty. (Base)" <> 0) or
           (BinContent."Put-away Quantity (Base)" <> 0) or (BinContent."Positive Adjmt. Qty. (Base)" <> 0)
        then
            Error(Text001, TableCaption);
    end;

    trigger OnInsert()
    begin
        if Default then
            if WMSManagement.CheckDefaultBin(
                 "Item No.", "Variant Code", "Location Code", "Bin Code")
            then
                Error(Text010, "Location Code", "Item No.", "Variant Code");

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code")
        else
            TestField("Zone Code", '');

        if "Min. Qty." > "Max. Qty." then
            Error(
              Text005,
              FieldCaption("Max. Qty."), "Max. Qty.",
              FieldCaption("Min. Qty."), "Min. Qty.");
    end;

    trigger OnModify()
    begin
        if Default then
            if WMSManagement.CheckDefaultBin(
                 "Item No.", "Variant Code", "Location Code", "Bin Code")
            then
                Error(Text010, "Location Code", "Item No.", "Variant Code");

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code")
        else
            TestField("Zone Code", '');

        if "Min. Qty." > "Max. Qty." then
            Error(
              Text005,
              FieldCaption("Max. Qty."), "Max. Qty.",
              FieldCaption("Min. Qty."), "Min. Qty.");
    end;

    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Text000: Label 'You cannot delete this %1, because the %1 contains items.';
        Text001: Label 'You cannot delete this %1, because warehouse document lines have items allocated to this %1.';
        Text002: Label 'The total cubage %1 of the %2 for the %5 exceeds the %3 %4 of the %5.\Do you still want enter this %2?';
        Text003: Label 'The total weight %1 of the %2 for the %5 exceeds the %3 %4 of the %5.\Do you still want enter this %2?';
        Text004: Label 'Cancelled.';
        Text005: Label 'The %1 %2 must not be less than the %3 %4.';
        Text006: Label 'available must not be less than %1';
        UOMMgt: Codeunit "Unit of Measure Management";
        Text007: Label 'You cannot modify the %1, because the %2 contains items.';
        Text008: Label 'You cannot modify the %1, because warehouse document lines have items allocated to this %2.';
        Text009: Label 'You must first set up user %1 as a warehouse employee.';
        Text010: Label 'There is already a default bin content for location code %1, item no. %2 and variant code %3.';
        WMSManagement: Codeunit "WMS Management";
        StockProposal: Boolean;

    procedure SetUpNewLine()
    begin
        GetBin("Location Code", "Bin Code");
        Dedicated := Bin.Dedicated;
        "Bin Type Code" := Bin."Bin Type Code";
        "Warehouse Class Code" := Bin."Warehouse Class Code";
        "Bin Ranking" := Bin."Bin Ranking";
        "Block Movement" := Bin."Block Movement";
        "Zone Code" := Bin."Zone Code";
        "Cross-Dock Bin" := Bin."Cross-Dock Bin";
    end;

    local procedure CheckManualChange(CaptionField: Text[80])
    begin
        xRec.CalcFields(
          "Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)",
          "Negative Adjmt. Qty. (Base)", "Pick Quantity (Base)");
        if xRec."Quantity (Base)" <> 0 then
            Error(Text007, CaptionField, TableCaption);
        if (xRec."Positive Adjmt. Qty. (Base)" <> 0) or (xRec."Put-away Quantity (Base)" <> 0) or
           (xRec."Negative Adjmt. Qty. (Base)" <> 0) or (xRec."Pick Quantity (Base)" <> 0)
        then
            Error(Text008, CaptionField, TableCaption);
    end;

    procedure CalcQtyAvailToTake(ExcludeQtyBase: Decimal): Decimal
    begin
        SetFilterOnUnitOfMeasure;
        CalcFields("Quantity (Base)", "Negative Adjmt. Qty. (Base)", "Pick Quantity (Base)", "ATO Components Pick Qty (Base)");
        exit(
          "Quantity (Base)" -
          (("Pick Quantity (Base)" + "ATO Components Pick Qty (Base)") - ExcludeQtyBase + "Negative Adjmt. Qty. (Base)"));
    end;

    procedure CalcQtyAvailToTakeUOM(): Decimal
    begin
        GetItem("Item No.");
        if Item."No." <> '' then
            exit(
              Round(CalcQtyAvailToTake(0) / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision));
    end;

    local procedure CalcTotalQtyAvailToTake(ExcludeQtyBase: Decimal): Decimal
    var
        TotalQtyBase: Decimal;
        TotalNegativeAdjmtQtyBase: Decimal;
        TotalATOComponentsPickQtyBase: Decimal;
    begin
        TotalQtyBase := CalcTotalQtyBase;
        TotalNegativeAdjmtQtyBase := CalcTotalNegativeAdjmtQtyBase;
        TotalATOComponentsPickQtyBase := CalcTotalATOComponentsPickQtyBase;
        SetFilterOnUnitOfMeasure;
        CalcFields("Pick Quantity (Base)");
        exit(
          TotalQtyBase -
          ("Pick Quantity (Base)" + TotalATOComponentsPickQtyBase - ExcludeQtyBase + TotalNegativeAdjmtQtyBase));
    end;

    procedure CalcQtyAvailToPick(ExcludeQtyBase: Decimal): Decimal
    begin
        if (not Dedicated) and (not ("Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All])) then
            exit(CalcQtyAvailToTake(ExcludeQtyBase) - CalcQtyWithBlockedItemTracking);
    end;

    procedure CalcQtyAvailToPickIncludingDedicated(ExcludeQtyBase: Decimal): Decimal
    begin
        if not ("Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All]) then
            exit(CalcQtyAvailToTake(ExcludeQtyBase) - CalcQtyWithBlockedItemTracking);
    end;

    procedure CalcQtyWithBlockedItemTracking(): Decimal
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        XBinContent: Record "Bin Content";
        CDNoInfo: Record "CD No. Information";
        QtySNBlocked: Decimal;
        QtyLNBlocked: Decimal;
        QtyCDBlocked: Decimal;
        QtySNAndLNBlocked: Decimal;
        QtySNAndCDBlocked: Decimal;
        QtyLNAndCDBlocked: Decimal;
        QtySNAndLNAndCDBlocked: Decimal;
        SNGiven: Boolean;
        LNGiven: Boolean;
        NoITGiven: Boolean;
        CDGiven: Boolean;
    begin
        SerialNoInfo.SetRange("Item No.", "Item No.");
        SerialNoInfo.SetRange("Variant Code", "Variant Code");
        CopyFilter("Serial No. Filter", SerialNoInfo."Serial No.");
        SerialNoInfo.SetRange(Blocked, true);

        LotNoInfo.SetRange("Item No.", "Item No.");
        LotNoInfo.SetRange("Variant Code", "Variant Code");
        CopyFilter("Lot No. Filter", LotNoInfo."Lot No.");
        LotNoInfo.SetRange(Blocked, true);

        CDNoInfo.SetRange(Type, CDNoInfo.Type::Item);
        CDNoInfo.SetRange("No.", "Item No.");
        CDNoInfo.SetRange("Variant Code", "Variant Code");
        CopyFilter("CD No. Filter", CDNoInfo."CD No.");
        CDNoInfo.SetRange(Blocked, true);

        if SerialNoInfo.IsEmpty and LotNoInfo.IsEmpty and CDNoInfo.IsEmpty then
            exit;

        SNGiven := not (GetFilter("Serial No. Filter") = '');
        LNGiven := not (GetFilter("Lot No. Filter") = '');
        CDGiven := not (GetFilter("CD No. Filter") = '');

        XBinContent.Copy(Rec);
        SetRange("Serial No. Filter");
        SetRange("Lot No. Filter");
        SetRange("CD No. Filter");

        NoITGiven := not SNGiven and not LNGiven and not CDGiven;
        if SNGiven or NoITGiven then
            if SerialNoInfo.FindSet then
                repeat
                    SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                    CalcFields("Quantity (Base)");
                    QtySNBlocked += "Quantity (Base)";
                    SetRange("Serial No. Filter");
                until SerialNoInfo.Next = 0;

        if LNGiven or NoITGiven then
            if LotNoInfo.FindSet then
                repeat
                    SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                    CalcFields("Quantity (Base)");
                    QtyLNBlocked += "Quantity (Base)";
                    SetRange("Lot No. Filter");
                until LotNoInfo.Next = 0;

        if CDGiven or NoITGiven then
            if CDNoInfo.FindSet then
                repeat
                    SetRange("CD No. Filter", CDNoInfo."CD No.");
                    CalcFields("Quantity (Base)");
                    QtyCDBlocked += "Quantity (Base)";
                    SetRange("CD No. Filter");
                until CDNoInfo.Next = 0;

        if (SNGiven and LNGiven) or NoITGiven then
            if SerialNoInfo.FindSet then
                repeat
                    if LotNoInfo.FindSet then
                        repeat
                            SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                            SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                            CalcFields("Quantity (Base)");
                            QtySNAndLNBlocked += "Quantity (Base)";
                        until LotNoInfo.Next = 0;
                until SerialNoInfo.Next = 0;

        if (SNGiven and CDGiven) or NoITGiven then
            if SerialNoInfo.FindSet then
                repeat
                    if CDNoInfo.FindSet then
                        repeat
                            SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                            SetRange("CD No. Filter", CDNoInfo."CD No.");
                            CalcFields("Quantity (Base)");
                            QtySNAndCDBlocked += "Quantity (Base)";
                        until CDNoInfo.Next = 0;
                until SerialNoInfo.Next = 0;

        if (LNGiven and CDGiven) or NoITGiven then
            if LotNoInfo.FindSet then
                repeat
                    if CDNoInfo.FindSet then
                        repeat
                            SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                            SetRange("CD No. Filter", CDNoInfo."CD No.");
                            CalcFields("Quantity (Base)");
                            QtyLNAndCDBlocked += "Quantity (Base)";
                        until CDNoInfo.Next = 0;
                until LotNoInfo.Next = 0;

        if SNGiven and LNGiven and CDGiven then
            if SerialNoInfo.FindSet then
                repeat
                    if LotNoInfo.FindSet then
                        repeat
                            if CDNoInfo.FindSet then
                                repeat
                                    SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                                    SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                                    SetRange("CD No. Filter", CDNoInfo."CD No.");
                                    CalcFields("Quantity (Base)");
                                    QtySNAndLNAndCDBlocked += "Quantity (Base)";
                                until CDNoInfo.Next = 0;
                        until LotNoInfo.Next = 0;
                until SerialNoInfo.Next = 0;

        Copy(XBinContent);
        exit(QtySNBlocked + QtyLNBlocked + QtyCDBlocked - QtySNAndLNBlocked - QtySNAndCDBlocked - QtyLNAndCDBlocked - QtySNAndLNAndCDBlocked);
    end;

    procedure CalcQtyAvailToPutAway(ExcludeQtyBase: Decimal): Decimal
    begin
        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Max. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision) -
          ("Quantity (Base)" + "Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)"));
    end;

    procedure NeedToReplenish(ExcludeQtyBase: Decimal): Boolean
    begin
        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Min. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision) >
          "Quantity (Base)" +
          Abs("Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)"));
    end;

    procedure CalcQtyToReplenish(ExcludeQtyBase: Decimal): Decimal
    begin
        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Max. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision) -
          ("Quantity (Base)" + "Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)"));
    end;

    local procedure CheckBinMaxCubageAndWeight()
    var
        BinContent: Record "Bin Content";
        WMSMgt: Codeunit "WMS Management";
        TotalCubage: Decimal;
        TotalWeight: Decimal;
        Cubage: Decimal;
        Weight: Decimal;
    begin
        GetBin("Location Code", "Bin Code");
        if (Bin."Maximum Cubage" <> 0) or (Bin."Maximum Weight" <> 0) then begin
            BinContent.SetRange("Location Code", "Location Code");
            BinContent.SetRange("Bin Code", "Bin Code");
            if BinContent.Find('-') then
                repeat
                    if (BinContent."Location Code" = "Location Code") and
                       (BinContent."Bin Code" = "Bin Code") and
                       (BinContent."Item No." = "Item No.") and
                       (BinContent."Variant Code" = "Variant Code") and
                       (BinContent."Unit of Measure Code" = "Unit of Measure Code")
                    then
                        WMSMgt.CalcCubageAndWeight(
                          "Item No.", "Unit of Measure Code", "Max. Qty.", Cubage, Weight)
                    else
                        WMSMgt.CalcCubageAndWeight(
                          BinContent."Item No.", BinContent."Unit of Measure Code",
                          BinContent."Max. Qty.", Cubage, Weight);
                    TotalCubage := TotalCubage + Cubage;
                    TotalWeight := TotalWeight + Weight;
                until BinContent.Next = 0;

            if (Bin."Maximum Cubage" > 0) and (Bin."Maximum Cubage" - TotalCubage < 0) then
                if not Confirm(
                     Text002,
                     false, TotalCubage, FieldCaption("Max. Qty."),
                     Bin.FieldCaption("Maximum Cubage"), Bin."Maximum Cubage", Bin.TableCaption)
                then
                    Error(Text004);
            if (Bin."Maximum Weight" > 0) and (Bin."Maximum Weight" - TotalWeight < 0) then
                if not Confirm(
                     Text003,
                     false, TotalWeight, FieldCaption("Max. Qty."),
                     Bin.FieldCaption("Maximum Weight"), Bin."Maximum Weight", Bin.TableCaption)
                then
                    Error(Text004);
        end;
    end;

    procedure CheckDecreaseBinContent(Qty: Decimal; var QtyBase: Decimal; DecreaseQtyBase: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
        QtyAvailToPickBase: Decimal;
        QtyAvailToPick: Decimal;
    begin
        if "Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All] then
            FieldError("Block Movement");

        GetLocation("Location Code");
        if "Bin Code" = Location."Adjustment Bin Code" then
            exit;

        WhseActivLine.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Action Type",
          "Variant Code", "Unit of Measure Code", "Breakbulk No.",
          "Activity Type", "Lot No.", "Serial No.", "Original Breakbulk");
        WhseActivLine.SetRange("Item No.", "Item No.");
        WhseActivLine.SetRange("Bin Code", "Bin Code");
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseActivLine.SetRange("Variant Code", "Variant Code");

        if Location."Allow Breakbulk" then begin
            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
            WhseActivLine.SetRange("Original Breakbulk", true);
            WhseActivLine.SetRange("Breakbulk No.", 0);
            WhseActivLine.CalcSums("Qty. (Base)");
            DecreaseQtyBase := DecreaseQtyBase + WhseActivLine."Qty. (Base)";
        end;

        QtyAvailToPickBase := CalcTotalQtyAvailToTake(DecreaseQtyBase);
        if QtyAvailToPickBase < QtyBase then begin
            GetItem("Item No.");
            QtyAvailToPick :=
              Round(QtyAvailToPickBase / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision);
            if QtyAvailToPick = Qty then
                QtyBase := QtyAvailToPickBase // rounding issue- qty is same, but not qty (base)
            else
                FieldError("Quantity (Base)", StrSubstNo(Text006, Abs(QtyBase)));
        end;
    end;

    procedure CheckIncreaseBinContent(QtyBase: Decimal; DeductQtyBase: Decimal; DeductCubage: Decimal; DeductWeight: Decimal; PutawayCubage: Decimal; PutawayWeight: Decimal; CalledbyPosting: Boolean; IgnoreError: Boolean): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WMSMgt: Codeunit "WMS Management";
        QtyAvailToPutAwayBase: Decimal;
        AvailableWeight: Decimal;
        AvailableCubage: Decimal;
    begin
        if "Block Movement" in ["Block Movement"::Inbound, "Block Movement"::All] then
            if not StockProposal then
                FieldError("Block Movement");

        GetLocation("Location Code");
        if "Bin Code" = Location."Adjustment Bin Code" then
            exit;

        if not CheckWhseClass(IgnoreError) then
            exit(false);

        if QtyBase <> 0 then
            if Location."Bin Capacity Policy" in
               [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]
            then
                if "Max. Qty." <> 0 then begin
                    QtyAvailToPutAwayBase := CalcQtyAvailToPutAway(DeductQtyBase);
                    WMSMgt.CheckPutAwayAvailability(
                      "Bin Code", WhseActivLine.FieldCaption("Qty. (Base)"), TableCaption, QtyBase, QtyAvailToPutAwayBase,
                      (Location."Bin Capacity Policy" =
                       Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);
                end else begin
                    GetBin("Location Code", "Bin Code");
                    if (Bin."Maximum Cubage" <> 0) or (Bin."Maximum Weight" <> 0) then begin
                        Bin.CalcCubageAndWeight(AvailableCubage, AvailableWeight, CalledbyPosting);
                        if not CalledbyPosting then begin
                            AvailableCubage := AvailableCubage + DeductCubage;
                            AvailableWeight := AvailableWeight + DeductWeight;
                        end;

                        if (Bin."Maximum Cubage" <> 0) and (PutawayCubage > AvailableCubage) then
                            WMSMgt.CheckPutAwayAvailability(
                              "Bin Code", WhseActivLine.FieldCaption(Cubage), Bin.TableCaption, PutawayCubage, AvailableCubage,
                              (Location."Bin Capacity Policy" =
                               Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);

                        if (Bin."Maximum Weight" <> 0) and (PutawayWeight > AvailableWeight) then
                            WMSMgt.CheckPutAwayAvailability(
                              "Bin Code", WhseActivLine.FieldCaption(Weight), Bin.TableCaption, PutawayWeight, AvailableWeight,
                              (Location."Bin Capacity Policy" =
                               Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);
                    end;
                end;
        exit(true);
    end;

    procedure CheckWhseClass(IgnoreError: Boolean): Boolean
    begin
        GetItem("Item No.");
        if IgnoreError then
            exit("Warehouse Class Code" = Item."Warehouse Class Code");
        TestField("Warehouse Class Code", Item."Warehouse Class Code");
        exit(true);
    end;

    procedure ShowBinContents(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        BinContentLookup: Page "Bin Contents List";
    begin
        if BinCode <> '' then
            BinContent.SetRange("Bin Code", BinCode)
        else
            BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContentLookup.SetTableView(BinContent);
        BinContentLookup.Initialize(LocationCode);
        BinContentLookup.RunModal;
        Clear(BinContentLookup);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (LocationCode = '') or (BinCode = '') then
            Bin.Init
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." = ItemNo then
            exit;

        if ItemNo = '' then
            Item.Init
        else
            Item.Get(ItemNo);
    end;

    procedure GetItemDescr(ItemNo: Code[20]; VariantCode: Code[10]; var ItemDescription: Text[100])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        OldItemNo: Code[20];
    begin
        ItemDescription := '';
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then begin
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
                if VariantCode <> '' then
                    if ItemVariant.Get(ItemNo, VariantCode) then
                        ItemDescription := ItemVariant.Description;
            end;
            OldItemNo := ItemNo;
        end;
    end;

    procedure GetWhseLocation(var CurrentLocationCode: Code[10]; var CurrentZoneCode: Code[10])
    var
        Location: Record Location;
        WhseEmployee: Record "Warehouse Employee";
        WMSMgt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        if UserId <> '' then begin
            IsHandled := false;
            OnBeforeGetWhseLocation(CurrentLocationCode, CurrentZoneCode, IsHandled);
            if not IsHandled then begin
                WhseEmployee.SetRange("User ID", UserId);
                if WhseEmployee.IsEmpty then
                    Error(Text009, UserId);
            end;
            if CurrentLocationCode <> '' then begin
                if not Location.Get(CurrentLocationCode) then begin
                    CurrentLocationCode := '';
                    CurrentZoneCode := '';
                end else
                    if not Location."Bin Mandatory" then begin
                        CurrentLocationCode := '';
                        CurrentZoneCode := '';
                    end else begin
                        WhseEmployee.SetRange("Location Code", CurrentLocationCode);
                        if WhseEmployee.IsEmpty then begin
                            CurrentLocationCode := '';
                            CurrentZoneCode := '';
                        end;
                    end
                    ;
                if CurrentLocationCode = '' then begin
                    CurrentLocationCode := WMSMgt.GetDefaultLocation;
                    if CurrentLocationCode <> '' then begin
                        Location.Get(CurrentLocationCode);
                        if not Location."Bin Mandatory" then
                            CurrentLocationCode := '';
                    end;
                end;
            end;
        end;
        FilterGroup := 2;
        if CurrentLocationCode <> '' then
            SetRange("Location Code", CurrentLocationCode)
        else
            SetRange("Location Code");
        if CurrentZoneCode <> '' then
            SetRange("Zone Code", CurrentZoneCode)
        else
            SetRange("Zone Code");
        FilterGroup := 0;
    end;

    procedure CalcQtyonAdjmtBin(): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        GetLocation("Location Code");
        WhseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", "Location Code");
        WhseEntry.SetRange("Variant Code", "Variant Code");
        WhseEntry.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcQtyBase(): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseActivLine.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code",
          "Action Type", "Variant Code", "Unit of Measure Code",
          "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.", "CD No.");
        WhseActivLine.SetRange("Item No.", "Item No.");
        WhseActivLine.SetRange("Bin Code", "Bin Code");
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Variant Code", "Variant Code");
        WhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        CopyFilter("Lot No. Filter", WhseActivLine."Lot No.");
        CopyFilter("Serial No. Filter", WhseActivLine."Serial No.");
        CopyFilter("CD No. Filter", WhseActivLine."CD No.");
        OnCalcQtyBaseOnAfterSetFiltersForWhseActivLine(WhseActivLine, Rec);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");

        WhseJnlLine.SetCurrentKey(
          "Item No.", "From Bin Code", "Location Code", "Entry Type", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseJnlLine.SetRange("Item No.", "Item No.");
        WhseJnlLine.SetRange("From Bin Code", "Bin Code");
        WhseJnlLine.SetRange("Location Code", "Location Code");
        WhseJnlLine.SetRange("Variant Code", "Variant Code");
        WhseJnlLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        CopyFilter("Lot No. Filter", WhseJnlLine."Lot No.");
        CopyFilter("Serial No. Filter", WhseJnlLine."Serial No.");
        CopyFilter("CD No. Filter", WhseJnlLine."CD No.");
        OnCalcQtyBaseOnAfterSetFiltersForWhseJnlLine(WhseJnlLine, Rec);
        WhseJnlLine.CalcSums("Qty. (Absolute, Base)");

        CalcFields("Quantity (Base)");
        exit(
          "Quantity (Base)" +
          WhseActivLine."Qty. Outstanding (Base)" +
          WhseJnlLine."Qty. (Absolute, Base)");
    end;

    procedure CalcQtyUOM(): Decimal
    begin
        GetItem("Item No.");
        CalcFields("Quantity (Base)");
        if Item."No." <> '' then
            exit(
              Round("Quantity (Base)" / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision));
    end;

    procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        ReservEntry: Record "Reservation Entry";
        FormCaption: Text[250];
        "Filter": Text;
    begin
        FormCaption :=
          StrSubstNo(
            '%1 %2',
            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DATABASE::Location),
            "Location Code");

        case true of
            GetFieldFilter(GetFilter("Serial No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("Serial No. Filter"), Filter, -1, ReservEntry.FieldCaption("Serial No."));
            GetFieldFilter(GetFilter("Lot No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("Lot No. Filter"), Filter, -1, ReservEntry.FieldCaption("Lot No."));
            GetFieldFilter(GetFilter("CD No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("CD No. Filter"), Filter, -1, ReservEntry.FieldCaption("CD No."));
            GetFieldFilter(GetFilter("Bin Code"), Filter):
                GetPageCaption(FormCaption, FieldNo("Bin Code"), Filter, DATABASE::"Registered Invt. Movement Line", '');
            GetFieldFilter(GetFilter("Variant Code"), Filter):
                GetPageCaption(FormCaption, FieldNo("Variant Code"), Filter, DATABASE::"Item Variant", '');
            GetFieldFilter(GetFilter("Item No."), Filter):
                GetPageCaption(FormCaption, FieldNo("Item No."), Filter, DATABASE::Item, '');
        end;

        exit(FormCaption);
    end;

    procedure SetProposalMode(NewValue: Boolean)
    begin
        StockProposal := NewValue;
    end;

    local procedure GetFieldFilter(FieldFilter: Text; var "Filter": Text): Boolean
    begin
        Filter := FieldFilter;
        exit(StrLen(Filter) > 0);
    end;

    local procedure GetPageCaption(var PageCaption: Text; FieldNo: Integer; "Filter": Text; TableId: Integer; CustomDetails: Text)
    var
        ObjectTranslation: Record "Object Translation";
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetFilter(Filter);

        if RecRef.FindFirst then begin
            if TableId > 0 then
                CustomDetails := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, TableId);

            PageCaption := StrSubstNo('%1 %2 %3', PageCaption, CustomDetails, FieldRef.Value);
        end;
    end;

    procedure SetFilterOnUnitOfMeasure()
    begin
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            SetRange("Unit of Measure Filter", "Unit of Measure Code")
        else
            SetRange("Unit of Measure Filter");
    end;

    local procedure CalcTotalQtyBase(): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Location Code", "Location Code");
        WarehouseEntry.SetRange("Bin Code", "Bin Code");
        WarehouseEntry.SetRange("Item No.", "Item No.");
        WarehouseEntry.SetRange("Variant Code", "Variant Code");
        WarehouseEntry.SetFilter("Lot No.", GetFilter("Lot No. Filter"));
        WarehouseEntry.SetFilter("Serial No.", GetFilter("Serial No. Filter"));
        OnCalcTotalQtyBaseOnAfterSetFilters(WarehouseEntry, Rec);
        WarehouseEntry.CalcSums("Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)");
    end;

    local procedure CalcTotalNegativeAdjmtQtyBase() TotalNegativeAdjmtQtyBase: Decimal
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WarehouseJournalLine.SetRange("Location Code", "Location Code");
        WarehouseJournalLine.SetRange("From Bin Code", "Bin Code");
        WarehouseJournalLine.SetRange("Item No.", "Item No.");
        WarehouseJournalLine.SetRange("Variant Code", "Variant Code");
        OnCalcTotalNegativeAdjmtQtyBaseOnAfterSetFilters(WarehouseJournalLine, Rec);
        if (GetFilter("Lot No. Filter") = '') and
           (GetFilter("Serial No. Filter") = '') and
           (GetFilter("CD No. Filter") = '')
        then begin
            WarehouseJournalLine.CalcSums("Qty. (Absolute, Base)");
            TotalNegativeAdjmtQtyBase := WarehouseJournalLine."Qty. (Absolute, Base)";
        end else begin
            WhseItemTrackingLine.SetRange("Location Code", "Location Code");
            WhseItemTrackingLine.SetRange("Item No.", "Item No.");
            WhseItemTrackingLine.SetRange("Variant Code", "Variant Code");
            WhseItemTrackingLine.SetFilter("Lot No.", GetFilter("Lot No. Filter"));
            WhseItemTrackingLine.SetFilter("Serial No.", GetFilter("Serial No. Filter"));
            WhseItemTrackingLine.SetFilter("CD No.", GetFilter("CD No. Filter"));
            WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
            if WarehouseJournalLine.FindSet then
                repeat
                    WhseItemTrackingLine.SetRange("Source ID", WarehouseJournalLine."Journal Batch Name");
                    WhseItemTrackingLine.SetRange("Source Batch Name", WarehouseJournalLine."Journal Template Name");
                    WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseJournalLine."Line No.");
                    WhseItemTrackingLine.CalcSums("Quantity (Base)");
                    TotalNegativeAdjmtQtyBase += WhseItemTrackingLine."Quantity (Base)";
                until WarehouseJournalLine.Next = 0;
        end;
    end;

    local procedure CalcTotalATOComponentsPickQtyBase(): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        GetLocation("Location Code");
        WarehouseActivityLine.SetRange("Location Code", "Location Code");
        WarehouseActivityLine.SetRange("Bin Code", "Bin Code");
        WarehouseActivityLine.SetRange("Item No.", "Item No.");
        WarehouseActivityLine.SetRange("Variant Code", "Variant Code");
        if Location."Allow Breakbulk" then
            WarehouseActivityLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Assemble to Order", true);
        WarehouseActivityLine.SetRange("ATO Component", true);
        WarehouseActivityLine.SetFilter("Lot No.", GetFilter("Lot No. Filter"));
        WarehouseActivityLine.SetFilter("Serial No.", GetFilter("Serial No. Filter"));
        OnCalcTotalATOComponentsPickQtyBaseOnAfterSetFilters(WarehouseActivityLine, Rec);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseLocation(LocationCode: Code[10]; ZoneCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyBaseOnAfterSetFiltersForWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyBaseOnAfterSetFiltersForWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalATOComponentsPickQtyBaseOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalNegativeAdjmtQtyBaseOnAfterSetFilters(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalQtyBaseOnAfterSetFilters(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
    end;
}

