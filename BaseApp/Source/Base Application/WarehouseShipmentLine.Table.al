table 7321 "Warehouse Shipment Line"
{
    Caption = 'Warehouse Shipment Line';
    DrillDownPageID = "Whse. Shipment Lines";
    LookupPageID = "Whse. Shipment Lines";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(9; "Source Document"; Option)
        {
            Caption = 'Source Document';
            Editable = false;
            OptionCaption = ',Sales Order,,,Sales Return Order,Purchase Order,,,Purchase Return Order,,Outbound Transfer,,,,,,,,Service Order';
            OptionMembers = ,"Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order",,"Outbound Transfer",,,,,,,,"Service Order";
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestReleased;
                if xRec."Bin Code" <> "Bin Code" then
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Warehouse Shipment Line",
                          FieldCaption("Bin Code"),
                          "Location Code",
                          "Bin Code", 0);
                        if Location."Directed Put-away and Pick" then begin
                            Bin.Get("Location Code", "Bin Code");
                            "Zone Code" := Bin."Zone Code";
                            CheckBin(0, 0);
                        end;
                    end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                TestReleased;
                if xRec."Zone Code" <> "Zone Code" then begin
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                end;
            end;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
                OrderStatus: Integer;
                IsHandled: Boolean;
            begin
                if Quantity <= 0 then
                    FieldError(Quantity, Text003);
                TestReleased;
                CheckSourceDocLineQty;

                if Quantity < "Qty. Picked" then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Picked"));
                if Quantity < "Qty. Shipped" then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Shipped"));

                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                InitOutstandingQtys;
                "Completely Picked" := (Quantity = "Qty. Picked") or ("Qty. (Base)" = "Qty. Picked (Base)");

                GetLocation("Location Code");
                if Location."Directed Put-away and Pick" then
                    CheckBin(xRec.Cubage, xRec.Weight);

                IsHandled := false;
                OnValidateQuantityStatusUpdate(Rec, xRec, IsHandled);
                if not IsHandled then begin
                    Status := CalcStatusShptLine;
                    if (Status <> xRec.Status) and (not IsTemporary) then begin
                        GetWhseShptHeader("No.");
                        OrderStatus := WhseShptHeader.GetDocumentStatus(0);
                        if OrderStatus <> WhseShptHeader."Document Status" then begin
                            WhseShptHeader.Validate("Document Status", OrderStatus);
                            WhseShptHeader.Modify();
                        end;
                    end;
                end;
            end;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(19; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                WMSMgt: Codeunit "WMS Management";
            begin
                GetLocation("Location Code");
                "Qty. Outstanding (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", "Qty. per Unit of Measure");
                if Location."Require Pick" then begin
                    if "Assemble to Order" then
                        Validate("Qty. to Ship", 0)
                    else
                        Validate("Qty. to Ship", "Qty. Picked" - (Quantity - "Qty. Outstanding"));
                end else
                    Validate("Qty. to Ship", "Qty. Outstanding");

                if Location."Directed Put-away and Pick" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. Outstanding", Cubage, Weight);
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                ATOLink: Record "Assemble-to-Order Link";
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                GetLocation("Location Code");

                IsHandled := false;
                OnBeforeCompareShipAndPickQty(Rec, IsHandled);
                if not IsHandled then
                    if ("Qty. to Ship" > "Qty. Picked" - "Qty. Shipped") and Location."Require Pick" and not "Assemble to Order" then
                        FieldError("Qty. to Ship", StrSubstNo(Text002, "Qty. Picked" - "Qty. Shipped"));

                IsHandled := false;
                OnBeforeCompareQtyToShipAndOutstandingQty(Rec, IsHandled);
                if not IsHandled then
                    if "Qty. to Ship" > "Qty. Outstanding" then
                        Error(Text000, "Qty. Outstanding");

                Confirmed := true;
                if (CurrFieldNo = FieldNo("Qty. to Ship")) and
                   ("Shipping Advice" = "Shipping Advice"::Complete) and
                   ("Qty. to Ship" <> "Qty. Outstanding") and
                   ("Qty. to Ship" > 0)
                then
                    Confirmed :=
                      Confirm(
                        Text009 +
                        Text010,
                        false,
                        FieldCaption("Shipping Advice"),
                        "Shipping Advice",
                        FieldCaption("Qty. to Ship"),
                        "Qty. Outstanding");

                if not Confirmed then
                    Error('');

                if CurrFieldNo <> FieldNo("Qty. to Ship (Base)") then
                    "Qty. to Ship (Base)" :=
                        UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");

                if "Assemble to Order" then
                    ATOLink.UpdateQtyToAsmFromWhseShptLine(Rec);
            end;
        }
        field(22; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Qty. to Ship", CalcQty("Qty. to Ship (Base)"));
            end;
        }
        field(23; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");
            end;
        }
        field(24; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Qty. Shipped"; Decimal)
        {
            Caption = 'Qty. Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Shipped (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Shipped", "Qty. per Unit of Measure");
            end;
        }
        field(26; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Pick Qty."; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding" WHERE("Activity Type" = CONST(Pick),
                                                                                  "Whse. Document Type" = CONST(Shipment),
                                                                                  "Whse. Document No." = FIELD("No."),
                                                                                  "Whse. Document Line No." = FIELD("Line No."),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = FILTER(" " | Place),
                                                                                  "Original Breakbulk" = CONST(false),
                                                                                  "Breakbulk No." = CONST(0),
                                                                                  "Assemble to Order" = CONST(false)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = CONST(Pick),
                                                                                         "Whse. Document Type" = CONST(Shipment),
                                                                                         "Whse. Document No." = FIELD("No."),
                                                                                         "Whse. Document Line No." = FIELD("Line No."),
                                                                                         "Action Type" = FILTER(" " | Place),
                                                                                         "Original Breakbulk" = CONST(false),
                                                                                         "Breakbulk No." = CONST(0),
                                                                                         "Assemble to Order" = CONST(false)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(34; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Picked,Partially Shipped,Completely Picked,Completely Shipped';
            OptionMembers = " ","Partially Picked","Partially Shipped","Completely Picked","Completely Shipped";
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Destination Type"; Option)
        {
            Caption = 'Destination Type';
            Editable = false;
            OptionCaption = ' ,Customer,Vendor,Location';
            OptionMembers = " ",Customer,Vendor,Location;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = IF ("Destination Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Destination Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("Destination Type" = CONST(Location)) Location.Code;
        }
        field(41; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(44; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(46; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(48; "Not upd. by Src. Doc. Post."; Boolean)
        {
            Caption = 'Not upd. by Src. Doc. Post.';
            Editable = false;
        }
        field(49; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
            Editable = false;
        }
        field(900; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Sorting Sequence No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "No.", "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "No.", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key8; "No.", "Destination Type", "Destination No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Assemble to Order")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding", "Qty. Outstanding (Base)";
        }
        key(Key10; "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Item No.", "Location Code", "Variant Code", "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)", "Qty. Picked (Base)", "Qty. Shipped (Base)";
        }
        key(Key12; "Bin Code", "Location Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Cubage, Weight;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OrderStatus: Option;
    begin
        TestReleased;

        if "Assemble to Order" then
            Validate("Qty. to Ship", 0);

        if "Qty. Shipped" < "Qty. Picked" then
            if not Confirm(
                 StrSubstNo(
                   Text007,
                   FieldCaption("Qty. Picked"), "Qty. Picked", FieldCaption("Qty. Shipped"),
                   "Qty. Shipped", TableCaption), false)
            then
                Error('');

        ItemTrackingMgt.SetDeleteReservationEntries(true);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Warehouse Shipment Line", 0, "No.", '', 0, "Line No.", "Location Code", true);

        OrderStatus :=
          WhseShptHeader.GetDocumentStatus("Line No.");
        if OrderStatus <> WhseShptHeader."Document Status" then begin
            WhseShptHeader.Validate("Document Status", OrderStatus);
            WhseShptHeader.Modify();
        end;
    end;

    trigger OnRename()
    begin
        Error(Text008, TableCaption);
    end;

    var
        Text000: Label 'You cannot handle more than the outstanding %1 units.';
        Location: Record Location;
        Item: Record Item;
        WhseShptHeader: Record "Warehouse Shipment Header";
        UOMMgt: Codeunit "Unit of Measure Management";
        Text001: Label 'must not be less than %1 units';
        Text002: Label 'must not be greater than %1 units';
        Text003: Label 'must be greater than zero';
        Text005: Label 'The picked quantity is not enough to ship all lines.';
        HideValidationDialog: Boolean;
        Text007: Label '%1 = %2 is greater than %3 = %4. If you delete the %5, the items will remain in the shipping area until you put them away.\Related Item Tracking information defined during pick will be deleted.\Do you still want to delete the %5?', Comment = 'Qty. Picked = 2 is greater than Qty. Shipped = 0. If you delete the Warehouse Shipment Line, the items will remain in the shipping area until you put them away.\Related Item Tracking information defined during pick will be deleted.\Do you still want to delete the Warehouse Shipment Line?';
        Text008: Label 'You cannot rename a %1.';
        Text009: Label '%1 is set to %2. %3 should be %4.\\';
        Text010: Label 'Accept the entered value?';
        Text011: Label 'Nothing to handle.';
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;
        StatusCheckSuspended: Boolean;

    procedure InitNewLine(DocNo: Code[20])
    begin
        Reset;
        "No." := DocNo;
        SetRange("No.", "No.");
        LockTable();
        if FindLast then;

        Init;
        SetIgnoreErrors;
        "Line No." := "Line No." + 10000;
    end;

    procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure TestReleased()
    begin
        TestField("No.");
        GetWhseShptHeader("No.");
        OnBeforeTestReleased(WhseShptHeader);
        if not StatusCheckSuspended then
            WhseShptHeader.TestField(Status, WhseShptHeader.Status::Open);
    end;

    procedure CheckBin(DeductCubage: Decimal; DeductWeight: Decimal)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if not Location."Directed Put-away and Pick" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "Item No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckIncreaseBinContent(
                     "Qty. Outstanding", "Qty. Outstanding",
                     DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
                then
                    ErrorOccured := true;
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckIncreaseBin(
                     "Bin Code", "Item No.", "Qty. Outstanding",
                     DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
                then
                    ErrorOccured := true;
            end;
        end;
        if ErrorOccured then
            "Bin Code" := '';
    end;

    procedure CheckSourceDocLineQty()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        WhseQtyOutstandingBase: Decimal;
        QtyOutstandingBase: Decimal;
        QuantityBase: Decimal;
    begin
        if "Qty. (Base)" = 0 then
            QuantityBase :=
                UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure")
        else
            QuantityBase := "Qty. (Base)";

        WhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", true);
        WhseShptLine.CalcSums("Qty. Outstanding (Base)");
        if WhseShptLine.Find('-') then
            repeat
                if (WhseShptLine."No." <> "No.") or
                   (WhseShptLine."Line No." <> "Line No.")
                then
                    WhseQtyOutstandingBase := WhseQtyOutstandingBase + WhseShptLine."Qty. Outstanding (Base)";
            until WhseShptLine.Next = 0;

        case "Source Type" of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    if Abs(SalesLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(SalesLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(SalesLine."Outstanding Qty. (Base)");
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    if Abs(PurchaseLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(Abs(PurchaseLine."Outstanding Qty. (Base)") - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(PurchaseLine."Outstanding Qty. (Base)");
                end;
            DATABASE::"Transfer Line":
                begin
                    TransferLine.Get("Source No.", "Source Line No.");
                    if TransferLine."Outstanding Qty. (Base)" < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(TransferLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := TransferLine."Outstanding Qty. (Base)";
                end;
            DATABASE::"Service Line":
                begin
                    ServiceLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    if Abs(ServiceLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(ServiceLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(ServiceLine."Outstanding Qty. (Base)");
                end;
            else
                OnCheckSourceDocLineQtyOnCaseSourceType(Rec, WhseQtyOutstandingBase, QtyOutstandingBase);
        end;
        if QuantityBase > QtyOutstandingBase then
            FieldError(Quantity, StrSubstNo(Text002, FieldCaption("Qty. Outstanding")));
    end;

    procedure CalcStatusShptLine(): Integer
    var
        NewStatus: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStatusShptLine(Rec, NewStatus, IsHandled);
        if IsHandled then
            exit(NewStatus);

        if (Quantity = "Qty. Shipped") or ("Qty. (Base)" = "Qty. Shipped (Base)") then
            exit(Status::"Completely Shipped");
        if "Qty. Shipped" > 0 then
            exit(Status::"Partially Shipped");
        if (Quantity = "Qty. Picked") or ("Qty. (Base)" = "Qty. Picked (Base)") then
            exit(Status::"Completely Picked");
        if "Qty. Picked" > 0 then
            exit(Status::"Partially Picked");
        exit(Status::" ");
    end;

    procedure AutofillQtyToHandle(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        NotEnough: Boolean;
    begin
        with WhseShptLine do begin
            NotEnough := false;
            SetHideValidationDialog(true);
            if Find('-') then
                repeat
                    GetLocation("Location Code");
                    if Location."Require Pick" then
                        Validate("Qty. to Ship (Base)", "Qty. Picked (Base)" - "Qty. Shipped (Base)")
                    else
                        Validate("Qty. to Ship (Base)", "Qty. Outstanding (Base)");
                    OnAutoFillQtyToHandleOnBeforeModify(WhseShptLine);
                    Modify;
                    if not NotEnough then
                        if ("Qty. to Ship (Base)" < "Qty. Outstanding (Base)") and
                           ("Shipping Advice" = "Shipping Advice"::Complete)
                        then
                            NotEnough := true;
                until Next = 0;
            SetHideValidationDialog(false);
            if NotEnough then
                Message(Text005);
        end;
    end;

    procedure DeleteQtyToHandle(var WhseShptLine: Record "Warehouse Shipment Line")
    begin
        with WhseShptLine do begin
            if Find('-') then
                repeat
                    Validate("Qty. to Ship", 0);
                    Modify;
                until Next = 0;
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetWhseShptHeader(WhseShptNo: Code[20])
    begin
        if WhseShptHeader."No." <> WhseShptNo then
            WhseShptHeader.Get(WhseShptNo);

        OnAfterGetWhseShptHeader(Rec, WhseShptHeader, WhseShptNo);
    end;

    procedure CreatePickDoc(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader2.TestField(Status, WhseShptHeader.Status::Released);
        WhseShptLine.SetFilter(Quantity, '>0');
        WhseShptLine.SetRange("Completely Picked", false);
        if WhseShptLine.Find('-') then
            CreatePickDocFromWhseShpt(WhseShptLine, WhseShptHeader2, HideValidationDialog)
        else
            if not HideValidationDialog then
                Message(Text011);
    end;

    local procedure CreatePickDocFromWhseShpt(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean)
    var
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePickDoc(WhseShptLine, WhseShptHeader, HideValidationDialog, IsHandled);
        if not IsHandled then begin
            WhseShipmentCreatePick.SetWhseShipmentLine(WhseShptLine, WhseShptHeader);
            WhseShipmentCreatePick.SetHideValidationDialog(HideValidationDialog);
            WhseShipmentCreatePick.UseRequestPage(not HideValidationDialog);
            WhseShipmentCreatePick.RunModal;
            WhseShipmentCreatePick.GetResultMessage;
            Clear(WhseShipmentCreatePick);
        end;
        OnAfterCreatePickDoc(WhseShptHeader);
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    procedure OpenItemTrackingLines()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        TransferLine: Record "Transfer Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveTransferLine: Codeunit "Transfer Line-Reserve";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        SecondSourceQtyArray: array[3] of Decimal;
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        TestField("Qty. (Base)");

        GetItem;
        Item.TestField("Item Tracking Code");

        SecondSourceQtyArray[1] := DATABASE::"Warehouse Shipment Line";
        SecondSourceQtyArray[2] := "Qty. to Ship (Base)";
        SecondSourceQtyArray[3] := 0;

        case "Source Type" of
            DATABASE::"Sales Line":
                begin
                    if SalesLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                        ReserveSalesLine.CallItemTrackingSecondSource(SalesLine, SecondSourceQtyArray, "Assemble to Order");
                end;
            DATABASE::"Service Line":
                begin
                    if ServiceLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                        ServiceLineReserve.CallItemTracking(ServiceLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    if PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                        ReservePurchLine.CallItemTracking(PurchaseLine, SecondSourceQtyArray);
                end;
            DATABASE::"Transfer Line":
                begin
                    Direction := Direction::Outbound;
                    if TransferLine.Get("Source No.", "Source Line No.") then
                        ReserveTransferLine.CallItemTracking(TransferLine, Direction, SecondSourceQtyArray);
                end
        end;
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure GetATOAndNonATOLines(var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        WhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", false);

        NonATOWhseShptLine.Copy(WhseShptLine);
        NonATOWhseShptLine.SetRange("Assemble to Order", false);
        NonATOLineFound := NonATOWhseShptLine.FindFirst;

        ATOWhseShptLine.Copy(WhseShptLine);
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOLineFound := ATOWhseShptLine.FindFirst;
    end;

    procedure FullATOPosted(): Boolean
    var
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
    begin
        if "Source Document" <> "Source Document"::"Sales Order" then
            exit(true);
        SalesLine.SetRange("Document Type", "Source Subtype");
        SalesLine.SetRange("Document No.", "Source No.");
        SalesLine.SetRange("Line No.", "Source Line No.");
        if not SalesLine.FindFirst then
            exit(true);
        if SalesLine."Qty. Shipped (Base)" >= SalesLine."Qty. to Asm. to Order (Base)" then
            exit(true);
        ATOWhseShptLine.SetRange("No.", "No.");
        ATOWhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", false);
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOWhseShptLine.CalcSums("Qty. to Ship (Base)");
        exit((SalesLine."Qty. Shipped (Base)" + ATOWhseShptLine."Qty. to Ship (Base)") >= SalesLine."Qty. to Asm. to Order (Base)");
    end;

    procedure InitOutstandingQtys()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingQtys(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Qty. Outstanding", Quantity - "Qty. Shipped");
        "Qty. Outstanding (Base)" := "Qty. (Base)" - "Qty. Shipped (Base)";
    end;

    procedure GetWhseShptLine(ShipmentNo: Code[20]; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer): Boolean
    begin
        SetRange("No.", ShipmentNo);
        SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, false);
        if FindFirst then
            exit(true);
    end;

    procedure CreateWhseItemTrackingLines()
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        AsmLineMgt: Codeunit "Assembly Line Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        if "Assemble to Order" then begin
            TestField("Source Type", DATABASE::"Sales Line");
            ATOSalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
            ATOSalesLine.AsmToOrderExists(AsmHeader);
            AsmLineMgt.CreateWhseItemTrkgForAsmLines(AsmHeader);
        end else begin
            if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then
                ItemTrackingMgt.InitItemTrkgForTempWkshLine(
                  WhseWkshLine."Whse. Document Type"::Shipment, "No.",
                  "Line No.", "Source Type",
                  "Source Subtype", "Source No.",
                  "Source Line No.", 0);
        end;
    end;

    procedure DeleteWhseItemTrackingLines()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ItemTrackingMgt.DeleteWhseItemTrkgLinesWithRunDeleteTrigger(
          DATABASE::"Warehouse Shipment Line", 0, "No.", '', 0, "Line No.", "Location Code", true, true);
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; ItemDescription2: Text[50]; LocationCode: Code[10]; VariantCode: Code[10]; UoMCode: Code[10]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Description 2" := ItemDescription2;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Unit of Measure Code" := UoMCode;
        "Qty. per Unit of Measure" := QtyPerUoM;
    end;

    procedure SetSource(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WhseMgt: Codeunit "Whse. Management";
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubType;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        "Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            SetRange("Source Line No.", SourceLineNo);
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source No.");
        SetRange("Source Line No.");
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseShptHeader(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseShptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoFillQtyToHandleOnBeforeModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStatusShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var NewStatus: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickDoc(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompareQtyToShipAndOutstandingQty(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompareShipAndPickQty(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingQtys(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestReleased(var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocLineQtyOnCaseSourceType(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WhseQtyOutstandingBase: Decimal; QtyOutstandingBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityStatusUpdate(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; xWarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}

