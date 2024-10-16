namespace Microsoft.Warehouse.Document;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7320 "Warehouse Shipment Header"
{
    Caption = 'Warehouse Shipment Header';
    DataCaptionFields = "No.";
    LookupPageID = "Warehouse Shipment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                WhseSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(WhseSetup."Whse. Ship Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                WhseShptLine: Record "Warehouse Shipment Line";
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, "Location Code");

                if "Location Code" <> xRec."Location Code" then begin
                    "Zone Code" := '';
                    "Bin Code" := '';
                    WhseShptLine.SetRange("No.", "No.");
                    if not WhseShptLine.IsEmpty() then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
                end;

                GetLocation("Location Code");
                Location.TestField("Require Shipment");
                if Location."Bin Mandatory" then
                    Validate("Bin Code", Location."Shipment Bin Code");

                if UserId <> '' then begin
                    FilterGroup := 2;
                    SetRange("Location Code", "Location Code");
                    FilterGroup := 0;
                end;
            end;
        }
        field(3; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Assigned User ID" <> '' then begin
                    "Assignment Date" := Today;
                    "Assignment Time" := Time;
                end else begin
                    "Assignment Date" := 0D;
                    "Assignment Time" := 0T;
                end;
            end;
        }
        field(4; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            Editable = false;
        }
        field(5; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
            Editable = false;
        }
        field(6; "Sorting Method"; Enum "Warehouse Shipment Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc();
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Whse. Shipment"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if (xRec."Bin Code" <> "Bin Code") or ("Zone Code" = '') then begin
                    TestField(Status, Status::Open);
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Warehouse Shipment Header", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                        Bin.Get("Location Code", "Bin Code");
                        "Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfShipmentLinesExist(FieldCaption("Bin Code"));
                end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Zone Code" <> xRec."Zone Code" then begin
                    TestField(Status, Status::Open);
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                    MessageIfShipmentLinesExist(FieldCaption("Zone Code"));
                end;
            end;
        }
        field(34; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Picked,Partially Shipped,Completely Picked,Completely Shipped';
            OptionMembers = " ","Partially Picked","Partially Shipped","Completely Picked","Completely Shipped";

            trigger OnValidate()
            var
                WhsePickRqst: Record "Whse. Pick Request";
            begin
                CalcFields("Completely Picked");
                if "Completely Picked" <> xRec."Completely Picked" then begin
                    WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Shipment);
                    WhsePickRqst.SetRange("Document No.", "No.");
                    if not WhsePickRqst.IsEmpty() then
                        WhsePickRqst.ModifyAll("Completely Picked", "Completely Picked");
                end;
            end;
        }
        field(39; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
            end;
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(43; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                WhseShptLine: Record "Warehouse Shipment Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Shipment Date" <> xRec."Shipment Date" then begin
                    WhseShptLine.SetRange("No.", "No.");
                    if not WhseShptLine.IsEmpty() then
                        if ConfirmModification() then
                            WhseShptLine.ModifyAll("Shipment Date", "Shipment Date");
                end;
            end;
        }
        field(46; "Completely Picked"; Boolean)
        {
            CalcFormula = min("Warehouse Shipment Line"."Completely Picked" where("No." = field("No.")));
            Caption = 'Completely Picked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(48; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(50; "Create Posted Header"; Boolean)
        {
            Caption = 'Create Posted Header';
        }
        field(61; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(62; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Posted Whse. Shipment Header";
        }
        field(63; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                WhseShptHeader := Rec;
                WhseSetup.Get();
                WhseSetup.TestField("Posted Whse. Shipment Nos.");
                if NoSeries.LookupRelatedNoSeries(WhseSetup."Posted Whse. Shipment Nos.", WhseShptHeader."Shipping No. Series") then
                    WhseShptHeader.Validate(WhseShptHeader."Shipping No. Series");
                Rec := WhseShptHeader;
            end;

            trigger OnValidate()
            begin
                if "Shipping No. Series" <> '' then begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Posted Whse. Shipment Nos.");
                    NoSeries.TestAreRelated(WhseSetup."Posted Whse. Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Location Code")
        {
        }
        key(Key3; "Shipment Date", "Document Status")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);
        OnDeleteOnBeforeDeleteWarehouseShipmentLines(Rec, HideValidationDialog);
        DeleteWarehouseShipmentLines();
        DeleteRelatedLines();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN24
        OnBeforeOnInsert(Rec, xRec, WhseSetup, NoSeriesMgt, Location, IsHandled);
#else
        OnBeforeOnInsert(Rec, xRec, WhseSetup, Location, IsHandled);
#endif
        if IsHandled then
            exit;

        WhseSetup.Get();
        if "No." = '' then begin
            WhseSetup.TestField("Whse. Ship Nos.");
#if not CLEAN24
            NoSeriesMgt.RaiseObsoleteOnBeforeInitSeries(WhseSetup."Whse. Ship Nos.", xRec."No. Series", "Posting Date", "No.", "No. Series", IsHandled);
            if not IsHandled then begin
#endif
                "No. Series" := WhseSetup."Whse. Ship Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
#if not CLEAN24
                NoSeriesMgt.RaiseObsoleteOnAfterInitSeries("No. Series", WhseSetup."Whse. Ship Nos.", "Posting Date", "No.");
            end;
#endif
        end;

#if CLEAN24
        if NoSeries.IsAutomatic(WhseSetup."Posted Whse. Shipment Nos.") then
            "Shipping No. Series" := WhseSetup."Posted Whse. Shipment Nos.";
#else
#pragma warning disable AL0432
        NoSeriesMgt.SetDefaultSeries("Shipping No. Series", WhseSetup."Posted Whse. Shipment Nos.");
#pragma warning restore AL0432
#endif

        GetLocation("Location Code");
        Validate("Bin Code", Location."Shipment Bin Code");
        "Posting Date" := WorkDate();
        "Shipment Date" := WorkDate();

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseSetup: Record "Warehouse Setup";
        WhseShptHeader: Record "Warehouse Shipment Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
#if not CLEAN24
        NoSeriesMgt: Codeunit NoSeriesManagement;
#endif
        NoSeries: Codeunit "No. Series";
        WmsManagement: Codeunit "WMS Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        Text003: Label 'You are not allowed to use location code %1.';
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Shipment Lines.\';
#pragma warning restore AA0470
        Text007: Label 'You must update the existing Warehouse Shipment Lines manually.';
#pragma warning disable AA0470
        Text008: Label 'You have modified the %1.\\Do you want to update the lines?';
#pragma warning restore AA0470
        Text009: Label 'The items have been picked. If you delete the warehouse shipment, then the items will remain in the shipping area until you put them away.\Related item tracking information that is defined during the pick will be deleted.\Are you sure that you want to delete the warehouse shipment?';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure AssistEdit(OldWhseShptHeader: Record "Warehouse Shipment Header"): Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        WhseSetup.Get();
        WhseShptHeader := Rec;
        WhseSetup.TestField("Whse. Ship Nos.");
        if NoSeries.LookupRelatedNoSeries(WhseSetup."Whse. Ship Nos.", OldWhseShptHeader."No. Series", WhseShptHeader."No. Series") then begin
            WhseShptHeader."No." := NoSeries.GetNextNo(WhseShptHeader."No. Series");
            Rec := WhseShptHeader;
            exit(true);
        end;

        OnAfterAssistEdit(OldWhseShptHeader);
    end;

    local procedure ConfirmModification() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmModification(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := Confirm(StrSubstNo(Text008, Rec.FieldCaption("Shipment Date")), false);
    end;

    procedure SortWhseDoc()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSortWhseDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine.SetRange("No.", "No.");
        case "Sorting Method" of
            "Sorting Method"::Item:
                WhseShptLine.SetCurrentKey("No.", "Item No.");
            "Sorting Method"::Document:
                WhseShptLine.SetCurrentKey("No.", "Source Document", "Source No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WhseShptLine.SetCurrentKey("No.", "Bin Code")
                    else
                        WhseShptLine.SetCurrentKey("No.", "Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                WhseShptLine.SetCurrentKey("No.", "Due Date");
            "Sorting Method"::Destination:
                WhseShptLine.SetCurrentKey("No.", "Destination Type", "Destination No.");
            else
                OnSortWhseDocCaseElse(Rec, WhseShptLine);
        end;

        if WhseShptLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseShptLine."Sorting Sequence No." := SequenceNo;
                WhseShptLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseShptLine.Next() = 0;
        end;
    end;

    procedure GetDocumentStatus(LineNo: Integer): Integer
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetRange("No.", "No.");
        if LineNo <> 0 then
            WhseShptLine.SetFilter("Line No.", '<>%1', LineNo);
        if not WhseShptLine.FindFirst() then
            exit(WhseShptLine.Status::" ");

        OnGetDocumentStatusOnBeforeCheckPartllyShipped(Rec, WhseShptLine);
        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Partially Shipped");
        if WhseShptLine.FindFirst() then
            exit(WhseShptLine.Status);

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Partially Picked");
        if WhseShptLine.FindFirst() then
            exit(WhseShptLine.Status);

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Completely Picked");
        if WhseShptLine.FindFirst() then begin
            WhseShptLine.SetFilter(Status, '<%1', WhseShptLine.Status::"Completely Picked");
            if WhseShptLine.FindFirst() then
                exit(WhseShptLine.Status::"Partially Picked");

            exit(WhseShptLine.Status);
        end;

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Completely Shipped");
        if WhseShptLine.FindFirst() then begin
            WhseShptLine.SetFilter(Status, '<%1', WhseShptLine.Status::"Completely Shipped");
            if WhseShptLine.FindFirst() then
                exit(WhseShptLine.Status::"Partially Shipped");

            exit(WhseShptLine.Status);
        end;

        exit(WhseShptLine.Status);
    end;

    procedure MessageIfShipmentLinesExist(ChangedFieldName: Text[80])
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetRange("No.", "No.");
        if not WhseShptLine.IsEmpty() then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    procedure GetLocation(LocationCode: Code[10]): Record Location
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(LocationCode, Rec, Location, IsHandled);
        if IsHandled then
            exit(Location);

        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
        exit(Location);
    end;

    procedure LookupLocation(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        Location: Record Location;
    begin
        Commit();
        Location.FilterGroup := 2;
        Location.SetRange(Code);
        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then
            WhseShptHeader.Validate("Location Code", Location.Code);
        Location.FilterGroup := 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteRelatedLines()
    var
        WhsePickRqst: Record "Whse. Pick Request";
        WhseComment: Record "Warehouse Comment Line";
    begin
        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Shipment);
        WhsePickRqst.SetRange("Document No.", "No.");
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.DeleteAll();

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Shipment");
        WhseComment.SetRange(Type, WhseComment.Type::" ");
        WhseComment.SetRange("No.", "No.");
        WhseComment.DeleteAll();
    end;

    procedure DeleteWarehouseShipmentLines()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        Confirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteWarehouseShipmentLines(Rec, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine.SetRange("No.", "No.");
        if WhseShptLine.Find('-') then
            repeat
                if WhseShptLine."Qty. Shipped" < WhseShptLine."Qty. Picked" then begin
                    IsHandled := false;
                    OnDeleteWarehouseShipmentLinesOnBeforeConfirm(WhseShptLine, Confirmed, IsHandled);
                    if not IsHandled then begin
                        if not Confirm(Text009) then
                            Error('');
                        Confirmed := true;
                    end;
                end;
            until (WhseShptLine.Next() = 0) or Confirmed;

        ItemTrackingMgt.SetDeleteReservationEntries(Confirmed);

        if WhseShptLine.Find('-') then
            repeat
                if WhseShptLine."Assemble to Order" then
                    WhseShptLine.Validate("Qty. to Ship", 0);
                ItemTrackingMgt.DeleteWhseItemTrkgLines(
                    Database::"Warehouse Shipment Line", 0, WhseShptLine."No.",
                    '', 0, WhseShptLine."Line No.", WhseShptLine."Location Code", true);

                OnBeforeWhseShptLineDelete(WhseShptLine);
                WhseShptLine.Delete();
            until WhseShptLine.Next() = 0;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            WhseShptHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := WhseShptHeader;
                    if Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowedToView("Location Code") then
                                exit(true);

                            if Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    procedure FindNextAllowedRec(Steps: Integer): Integer
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            WhseShptHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    WhseShptHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := WhseShptHeader;
            if not Find() then;
        end;
        exit(RealSteps);
    end;

    procedure ErrorIfUserIsNotWhseEmployee()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfUserIsNotWhseEmployee("Location Code", IsHandled);
        if IsHandled then
            exit;

        WMSManagement.CheckUserIsWhseEmployee();
    end;

    procedure ApplyCustomSortingToWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        TempFirstPriorityWhseShptLine: Record "Warehouse Shipment Line" temporary;
        TempSecondPriorityWhseShptLine: Record "Warehouse Shipment Line" temporary;
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyCustomSortingToWhseShptLines(WarehouseShipmentLine, IsHandled);
        if IsHandled then
            exit;

        if not WarehouseShipmentLine.FindSet() then
            exit;

        repeat
            if MeetsCriteria(WarehouseShipmentLine) then begin
                TempFirstPriorityWhseShptLine := WarehouseShipmentLine;
                TempFirstPriorityWhseShptLine.Insert();
            end else begin
                TempSecondPriorityWhseShptLine := WarehouseShipmentLine;
                TempSecondPriorityWhseShptLine.Insert();
            end;
        until WarehouseShipmentLine.Next() = 0;

        SequenceNo := 10000;
        if TempFirstPriorityWhseShptLine.FindSet() then
            repeat
                WarehouseShipmentLine := TempFirstPriorityWhseShptLine;
                WarehouseShipmentLine.Find();
                WarehouseShipmentLine."Sorting Sequence No." := SequenceNo;
                WarehouseShipmentLine.Modify();
                SequenceNo += 10000;
            until TempFirstPriorityWhseShptLine.Next() = 0;

        if TempSecondPriorityWhseShptLine.FindSet() then
            repeat
                WarehouseShipmentLine := TempSecondPriorityWhseShptLine;
                WarehouseShipmentLine.Find();
                WarehouseShipmentLine."Sorting Sequence No." := SequenceNo;
                WarehouseShipmentLine.Modify();
                SequenceNo += 10000;
            until TempSecondPriorityWhseShptLine.Next() = 0;
    end;

    local procedure MeetsCriteria(WarehouseShipmentLine: Record "Warehouse Shipment Line") Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMeetsCriteria(WarehouseShipmentLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetSourceFilter(
          WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.",
          WarehouseShipmentLine."Source Line No.", true);
        ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
        Result := not ReservationEntry.IsEmpty();

        exit(Result);
    end;

    procedure ShipmentLinesEditable() IsEditable: Boolean;
    begin
        IsEditable := true;

        OnAfterShipmentLinesEditable(Rec, IsEditable);
    end;

    procedure BinCodeMandatory(): Boolean;
    begin
        exit(GetLocation("Location Code")."Bin Mandatory");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEdit(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var xWarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipmentLinesEditable(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsEditable: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmModification(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineDelete(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(LocationCode: Code[10]; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteWarehouseShipmentLinesOnBeforeConfirm(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Confirmed: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteWarehouseShipmentLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentDate(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; xWarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocCaseElse(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteWarehouseShipmentLines(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCustomSortingToWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMeetsCriteria(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN24
    [IntegrationEvent(false, false)]
    [Obsolete('Parameter NoSeriesMgt is obsolete and will be removed, update your subscriber accordingly.', '24.0')]
    local procedure OnBeforeOnInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var xWarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseSetup: Record "Warehouse Setup"; var NoSeriesMgt: Codeunit NoSeriesManagement; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;
#else
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var xWarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseSetup: Record "Warehouse Setup"; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentStatusOnBeforeCheckPartllyShipped(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;
}

