table 7312 "Warehouse Entry"
{
    Caption = 'Warehouse Entry';
    DrillDownPageID = "Warehouse Entries";
    LookupPageID = "Warehouse Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            BlankZero = true;
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
        field(6; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(7; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(20; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(21; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(23; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
        }
        field(24; "Source Subline No."; Integer)
        {
            Caption = 'Source Subline No.';
        }
        field(25; "Source Document"; Enum "Warehouse Journal Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(33; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(35; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(41; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(45; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
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
        field(55; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Negative Adjmt.,Positive Adjmt.,Movement';
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
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
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
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
        field(7382; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Reference No.", "Registering Date")
        {
        }
        key(Key3; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Source Document", "Bin Code")
        {
        }
        key(Key4; "Serial No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
            Enabled = false;
            SumIndexFields = "Qty. (Base)";
        }
        key(Key5; "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated)
        {
            SumIndexFields = "Qty. (Base)", Cubage, Weight, Quantity;
        }
        key(Key6; "Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code", "Lot No.", "Serial No.", Dedicated)
        {
            SumIndexFields = "Qty. (Base)", Cubage, Weight;
        }
        key(Key7; "Bin Code", "Location Code", "Item No.")
        {
            SumIndexFields = Cubage, Weight, "Qty. (Base)";
        }
        key(Key8; "Location Code", "Item No.", "Variant Code", "Zone Code", "Bin Code", "Lot No.")
        {
            SumIndexFields = "Qty. (Base)";
        }
        key(Key9; "Location Code")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Qty. (Base)";
        }
        key(Key10; "Lot No.")
        {
            Enabled = false;
        }
        key(Key11; "Serial No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Registering Date", "Entry No.", "Location Code", "Item No.")
        {
        }
    }

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromWhseJnlLine(WhseJnlLine: Record "Warehouse Journal Line")
    begin
        "Serial No." := WhseJnlLine."Serial No.";
        "Lot No." := WhseJnlLine."Lot No.";

        OnAfterCopyTrackingFromWhseJnlLine(Rec, WhseJnlLine);
    end;

    procedure SetCalculationFilters(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean)
    begin
        SetRange("Item No.", ItemNo);
        SetRange("Location Code", LocationCode);
        SetRange("Variant Code", VariantCode);
        SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
        if ExcludeDedicatedBinContent then
            SetRange(Dedicated, false);
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
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

    procedure SetTrackingFilterIfNotBlank()
    begin
        if "Lot No." <> '' then
            SetRange("Lot No.", "Lot No.");
        if "Serial No." <> '' then
            SetRange("Serial No.", "Serial No.");

        OnAfterSetTrackingFilterIfNotBlank(Rec);
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetTrackingFilterFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer")
    begin
        SetRange("Serial No.", BinContentBuffer."Serial No.");
        SetRange("Lot No.", BinContentBuffer."Lot No.");

        OnAfterSetTrackingFilterFromBinContentBuffer(Rec, BinContentBuffer);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
            else
                SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
            else
                SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromWhseEntry(FromWhseEntry: Record "Warehouse Entry")
    begin
        SetRange("Serial No.", FromWhseEntry."Serial No.");
        SetRange("Lot No.", FromWhseEntry."Lot No.");

        OnAfterSetTrackingFilterFromWhseEntry(Rec, FromWhseEntry);
    end;

    procedure SetTrackingFilterFromReservEntryIfNotBlank(ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Serial No." <> '' then
            SetRange("Serial No.", ReservEntry."Serial No.");
        if ReservEntry."Lot No." <> '' then
            SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntryIfNotBlank(Rec, ReservEntry);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure TrackingExists(): Boolean
    var
        IsTrackingExists: Boolean;
    begin
        IsTrackingExists := ("Lot No." <> '') or ("Serial No." <> '');
        OnAfterTrackingExists(Rec, IsTrackingExists);
        exit(IsTrackingExists);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; FromWarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContentBuffer(var WarehouseEntry: Record "Warehouse Entry"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntryIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseEntry(var WhseEntry: Record "Warehouse Entry"; FromWhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterIfNotBlank(var WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(WhseEntry: Record "Warehouse Entry"; var IsTrackingExists: Boolean);
    begin
    end;
}

