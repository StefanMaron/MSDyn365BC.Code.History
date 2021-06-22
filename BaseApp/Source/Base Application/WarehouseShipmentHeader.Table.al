table 7320 "Warehouse Shipment Header"
{
    Caption = 'Warehouse Shipment Header';
    DataCaptionFields = "No.";
    LookupPageID = "Warehouse Shipment List";

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
                    NoSeriesMgt.TestManual(WhseSetup."Whse. Ship Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

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
                    if not WhseShptLine.IsEmpty then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
                end;

                GetLocation("Location Code");
                Location.TestField("Require Shipment");
                if Location."Directed Put-away and Pick" or Location."Bin Mandatory" then
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
            TableRelation = "Warehouse Employee" WHERE("Location Code" = FIELD("Location Code"));

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
                    SortWhseDoc;
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist ("Warehouse Comment Line" WHERE("Table Name" = CONST("Whse. Shipment"),
                                                                Type = CONST(" "),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
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
                if (xRec."Bin Code" <> "Bin Code") or ("Zone Code" = '') then begin
                    TestField(Status, Status::Open);
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Warehouse Shipment Header",
                          FieldCaption("Bin Code"),
                          "Location Code",
                          "Bin Code", 0);
                        if Location."Directed Put-away and Pick" then begin
                            Bin.Get("Location Code", "Bin Code");
                            "Zone Code" := Bin."Zone Code";
                        end;
                    end;
                    MessageIfShptLinesExist(FieldCaption("Bin Code"));
                end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if "Zone Code" <> xRec."Zone Code" then begin
                    TestField(Status, Status::Open);
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                    MessageIfShptLinesExist(FieldCaption("Zone Code"));
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
                    if not WhsePickRqst.IsEmpty then
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
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));
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
            begin
                if "Shipment Date" <> xRec."Shipment Date" then begin
                    WhseShptLine.SetRange("No.", "No.");
                    if not WhseShptLine.IsEmpty then
                        if Confirm(
                             StrSubstNo(Text008, FieldCaption("Shipment Date")), false)
                        then
                            WhseShptLine.ModifyAll("Shipment Date", "Shipment Date");
                end;
            end;
        }
        field(46; "Completely Picked"; Boolean)
        {
            CalcFormula = Min ("Warehouse Shipment Line"."Completely Picked" WHERE("No." = FIELD("No.")));
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
                with WhseShptHeader do begin
                    WhseShptHeader := Rec;
                    WhseSetup.Get();
                    WhseSetup.TestField("Posted Whse. Shipment Nos.");
                    if NoSeriesMgt.LookupSeries(WhseSetup."Posted Whse. Shipment Nos.", "Shipping No. Series") then
                        Validate("Shipping No. Series");
                    Rec := WhseShptHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Shipping No. Series" <> '' then begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Posted Whse. Shipment Nos.");
                    NoSeriesMgt.TestSeries(WhseSetup."Posted Whse. Shipment Nos.", "Shipping No. Series");
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
        DeleteWarehouseShipmentLines;
        DeleteRelatedLines;
    end;

    trigger OnInsert()
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            WhseSetup.TestField("Whse. Ship Nos.");
            NoSeriesMgt.InitSeries(WhseSetup."Whse. Ship Nos.", xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;

        NoSeriesMgt.SetDefaultSeries("Shipping No. Series", WhseSetup."Posted Whse. Shipment Nos.");

        GetLocation("Location Code");
        Validate("Bin Code", Location."Shipment Bin Code");
        "Posting Date" := WorkDate;
        "Shipment Date" := WorkDate;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseSetup: Record "Warehouse Setup";
        WhseShptHeader: Record "Warehouse Shipment Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        Text002: Label 'You must first set up user %1 as a warehouse employee.';
        WmsManagement: Codeunit "WMS Management";
        Text003: Label 'You are not allowed to use location code %1.';
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        HideValidationDialog: Boolean;
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Shipment Lines.\';
        Text007: Label 'You must update the existing Warehouse Shipment Lines manually.';
        Text008: Label 'You have modified the %1.\\Do you want to update the lines?';
        Text009: Label 'The items have been picked. If you delete the warehouse shipment, then the items will remain in the shipping area until you put them away.\Related item tracking information that is defined during the pick will be deleted.\Are you sure that you want to delete the warehouse shipment?';

    procedure AssistEdit(OldWhseShptHeader: Record "Warehouse Shipment Header"): Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        WhseSetup.Get();
        with WhseShptHeader do begin
            WhseShptHeader := Rec;
            WhseSetup.TestField("Whse. Ship Nos.");
            if NoSeriesMgt.SelectSeries(
                 WhseSetup."Whse. Ship Nos.", OldWhseShptHeader."No. Series", "No. Series")
            then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := WhseShptHeader;
                exit(true);
            end;
        end;

        OnAfterAssistEdit(OldWhseShptHeader);
    end;

    procedure SortWhseDoc()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SequenceNo: Integer;
    begin
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
        end;

        if WhseShptLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseShptLine."Sorting Sequence No." := SequenceNo;
                WhseShptLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseShptLine.Next = 0;
        end;
    end;

    procedure GetDocumentStatus(LineNo: Integer): Integer
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetRange("No.", "No.");
        if LineNo <> 0 then
            WhseShptLine.SetFilter("Line No.", '<>%1', LineNo);
        if not WhseShptLine.FindFirst then
            exit(WhseShptLine.Status::" ");

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Partially Shipped");
        if WhseShptLine.FindFirst then
            exit(WhseShptLine.Status);

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Partially Picked");
        if WhseShptLine.FindFirst then
            exit(WhseShptLine.Status);

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Completely Picked");
        if WhseShptLine.FindFirst then begin
            WhseShptLine.SetFilter(Status, '<%1', WhseShptLine.Status::"Completely Picked");
            if WhseShptLine.FindFirst then
                exit(WhseShptLine.Status::"Partially Picked");

            exit(WhseShptLine.Status);
        end;

        WhseShptLine.SetRange(Status, WhseShptLine.Status::"Completely Shipped");
        if WhseShptLine.FindFirst then begin
            WhseShptLine.SetFilter(Status, '<%1', WhseShptLine.Status::"Completely Shipped");
            if WhseShptLine.FindFirst then
                exit(WhseShptLine.Status::"Partially Shipped");

            exit(WhseShptLine.Status);
        end;

        exit(WhseShptLine.Status);
    end;

    local procedure MessageIfShptLinesExist(ChangedFieldName: Text[80])
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetRange("No.", "No.");
        if not WhseShptLine.IsEmpty then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure LookupWhseShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
        Commit();
        if UserId <> '' then begin
            WhseShptHeader.FilterGroup := 2;
            WhseShptHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, WhseShptHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            WhseShptHeader.FilterGroup := 2;
            WhseShptHeader.SetRange("Location Code", WhseShptHeader."Location Code");
            WhseShptHeader.FilterGroup := 0;
        end;
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
        if not WhsePickRqst.IsEmpty then
            WhsePickRqst.DeleteAll();

        WhseComment.SetRange("Table Name", WhseComment."Table Name"::"Whse. Shipment");
        WhseComment.SetRange(Type, WhseComment.Type::" ");
        WhseComment.SetRange("No.", "No.");
        WhseComment.DeleteAll();
    end;

    local procedure DeleteWarehouseShipmentLines()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        Confirmed: Boolean;
    begin
        WhseShptLine.SetRange("No.", "No.");
        if WhseShptLine.Find('-') then
            repeat
                if WhseShptLine."Qty. Shipped" < WhseShptLine."Qty. Picked" then begin
                    if not Confirm(Text009) then
                        Error('');
                    Confirmed := true;
                end;
            until (WhseShptLine.Next = 0) or Confirmed;

        ItemTrackingMgt.SetDeleteReservationEntries(Confirmed);

        if WhseShptLine.Find('-') then
            repeat
                if WhseShptLine."Assemble to Order" then
                    WhseShptLine.Validate("Qty. to Ship", 0);
                ItemTrackingMgt.DeleteWhseItemTrkgLines(DATABASE::"Warehouse Shipment Line", 0, WhseShptLine."No.",
                  '', 0, WhseShptLine."Line No.", WhseShptLine."Location Code", true);

                OnBeforeWhseShptLineDelete(WhseShptLine);
                WhseShptLine.Delete();
            until WhseShptLine.Next = 0;
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
            if not Find then;
        end;
        exit(RealSteps);
    end;

    procedure ErrorIfUserIsNotWhseEmployee()
    var
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfUserIsNotWhseEmployee("Location Code", IsHandled);
        if IsHandled then
            exit;

        if UserId <> '' then begin
            WhseEmployee.SetRange("User ID", UserId);
            if WhseEmployee.IsEmpty then
                Error(Text002, UserId);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEdit(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
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
}

