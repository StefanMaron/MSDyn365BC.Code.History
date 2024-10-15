table 7316 "Warehouse Receipt Header"
{
    Caption = 'Warehouse Receipt Header';
    LookupPageID = "Warehouse Receipts";
    Permissions = TableData "Warehouse Receipt Line" = rd;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                WhseSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(WhseSetup."Whse. Receipt Nos.");
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
                WhseRcptLine: Record "Warehouse Receipt Line";
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, "Location Code");

                if "Location Code" <> xRec."Location Code" then begin
                    "Zone Code" := '';
                    "Bin Code" := '';
                    "Cross-Dock Zone Code" := '';
                    "Cross-Dock Bin Code" := '';
                    WhseRcptLine.SetRange("No.", "No.");
                    if not WhseRcptLine.IsEmpty then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
                end;

                GetLocation("Location Code");
                Location.TestField("Require Receive");
                if Location."Directed Put-away and Pick" or Location."Bin Mandatory" then begin
                    Validate("Bin Code", Location."Receipt Bin Code");
                    Validate("Cross-Dock Bin Code", Location."Cross-Dock Bin Code");
                end;

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
        field(6; "Sorting Method"; Enum "Warehouse Receipt Sorting Method")
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
        field(8; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if "Zone Code" <> xRec."Zone Code" then begin
                    if "Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Bin Code" := '';
                    MessageIfRcptLinesExist(FieldCaption("Zone Code"));
                end;
            end;
        }
        field(9; "Bin Code"; Code[20])
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
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Warehouse Receipt Header",
                          FieldCaption("Bin Code"),
                          "Location Code",
                          "Bin Code", 0);
                        if Location."Directed Put-away and Pick" then begin
                            Bin.Get("Location Code", "Bin Code");
                            "Zone Code" := Bin."Zone Code";
                        end;
                    end;
                    MessageIfRcptLinesExist(FieldCaption("Bin Code"));
                end;
            end;
        }
        field(10; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Received,Completely Received';
            OptionMembers = " ","Partially Received","Completely Received";
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist("Warehouse Comment Line" WHERE("Table Name" = CONST("Whse. Receipt"),
                                                                Type = CONST(" "),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(13; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';
        }
        field(16; "Cross-Dock Zone Code"; Code[10])
        {
            Caption = 'Cross-Dock Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"),
                                             "Cross-Dock Bin Zone" = CONST(true));

            trigger OnValidate()
            begin
                if "Cross-Dock Zone Code" <> xRec."Cross-Dock Zone Code" then begin
                    if "Cross-Dock Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "Cross-Dock Bin Code" := '';
                    MessageIfRcptLinesExist(FieldCaption("Cross-Dock Zone Code"));
                end;
            end;
        }
        field(17; "Cross-Dock Bin Code"; Code[20])
        {
            Caption = 'Cross-Dock Bin Code';
            TableRelation = IF ("Cross-Dock Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                   "Cross-Dock Bin" = CONST(true))
            ELSE
            IF ("Cross-Dock Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                 "Zone Code" = FIELD("Cross-Dock Zone Code"),
                                                                                                                                                 "Cross-Dock Bin" = CONST(true));

            trigger OnValidate()
            var
                Bin: Record Bin;
            begin
                if (xRec."Cross-Dock Bin Code" <> "Cross-Dock Bin Code") or ("Cross-Dock Zone Code" = '') then begin
                    if "Cross-Dock Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "Cross-Dock Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "Cross-Dock Bin Code",
                              StrSubstNo(
                                Text005,
                                Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption));

                        Bin.Get("Location Code", "Cross-Dock Bin Code");
                        Bin.TestField("Cross-Dock Bin", true);
                        "Cross-Dock Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfRcptLinesExist(FieldCaption("Cross-Dock Bin Code"));
                end;
            end;
        }
        field(50; "Create Posted Header"; Boolean)
        {
            Caption = 'Create Posted Header';
        }
        field(51; "Receiving No."; Code[20])
        {
            Caption = 'Receiving No.';
        }
        field(62; "Last Receiving No."; Code[20])
        {
            Caption = 'Last Receiving No.';
            TableRelation = "Posted Whse. Receipt Header";
        }
        field(63; "Receiving No. Series"; Code[20])
        {
            Caption = 'Receiving No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with WhseRcptHeader do begin
                    WhseRcptHeader := Rec;
                    WhseSetup.Get();
                    WhseSetup.TestField("Posted Whse. Receipt Nos.");
                    if NoSeriesMgt.LookupSeries(WhseSetup."Posted Whse. Receipt Nos.", "Receiving No. Series") then
                        Validate("Receiving No. Series");
                    Rec := WhseRcptHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Receiving No. Series" <> '' then begin
                    WhseSetup.Get();
                    WhseSetup.TestField("Posted Whse. Receipt Nos.");
                    NoSeriesMgt.TestSeries(WhseSetup."Posted Whse. Receipt Nos.", "Receiving No. Series");
                end;
                TestField("Receiving No.", '');
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
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteRelatedLines(true);
    end;

    trigger OnInsert()
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            WhseSetup.TestField("Whse. Receipt Nos.");
            NoSeriesMgt.InitSeries(WhseSetup."Whse. Receipt Nos.", xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;

        NoSeriesMgt.SetDefaultSeries("Receiving No. Series", WhseSetup."Posted Whse. Receipt Nos.");

        GetLocation("Location Code");
        Validate("Bin Code", Location."Receipt Bin Code");
        Validate("Cross-Dock Bin Code", Location."Cross-Dock Bin Code");
        "Posting Date" := WorkDate;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseSetup: Record "Warehouse Setup";
        WhseCommentLine: Record "Warehouse Comment Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        WmsManagement: Codeunit "WMS Management";
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        Text002: Label 'You must first set up user %1 as a warehouse employee.';
        Text003: Label 'You are not allowed to use location code %1.';
        Text005: Label 'must not be the %1 of the %2';
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Receipt Lines.\';
        Text007: Label 'You must update the existing Warehouse Receipt Lines manually.';
        Text008: Label 'The Whse. Receipt is not completely received.\Do you really want to delete the Whse. Receipt?';
        Text009: Label 'Cancelled.';

    protected var
        HideValidationDialog: Boolean;

    procedure AssistEdit(OldWhseRcptHeader: Record "Warehouse Receipt Header"): Boolean
    begin
        WhseSetup.Get();
        with WhseRcptHeader do begin
            WhseRcptHeader := Rec;
            WhseSetup.TestField("Whse. Receipt Nos.");
            if NoSeriesMgt.SelectSeries(
                 WhseSetup."Whse. Receipt Nos.", OldWhseRcptHeader."No. Series", "No. Series")
            then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := WhseRcptHeader;
                exit(true);
            end;
        end;

        OnAfterAssistEdit(OldWhseRcptHeader);
    end;

    procedure SortWhseDoc()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        SequenceNo: Integer;
    begin
        WhseRcptLine.SetRange("No.", "No.");
        GetLocation("Location Code");
        case "Sorting Method" of
            "Sorting Method"::Item:
                WhseRcptLine.SetCurrentKey("No.", "Item No.");
            "Sorting Method"::Document:
                WhseRcptLine.SetCurrentKey("No.", "Source Document", "Source No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    if Location."Bin Mandatory" then
                        WhseRcptLine.SetCurrentKey("No.", "Bin Code")
                    else
                        WhseRcptLine.SetCurrentKey("No.", "Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                WhseRcptLine.SetCurrentKey("No.", "Due Date");
            else
                OnSortWhseDocOnCaseSortingMethodElse(Rec, WhseRcptLine);
        end;

        if WhseRcptLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseRcptLine."Sorting Sequence No." := SequenceNo;
                WhseRcptLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseRcptLine.Next = 0;
        end;
    end;

    local procedure MessageIfRcptLinesExist(ChangedFieldName: Text[80])
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.SetRange("No.", "No.");
        if not WhseRcptLine.IsEmpty then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    procedure DeleteRelatedLines(UseTableTrigger: Boolean)
    var
        CrossDockOpp: Record "Whse. Cross-Dock Opportunity";
        WhseRcptLine: Record "Warehouse Receipt Line";
        Confirmed: Boolean;
        SkipConfirm: Boolean;
    begin
        WhseRcptLine.SetRange("No.", "No.");
        if UseTableTrigger then begin
            if WhseRcptLine.Find('-') then begin
                repeat
                    OnBeforeDeleteWhseRcptRelatedLines(WhseRcptLine, SkipConfirm);
                    if (WhseRcptLine.Quantity <> WhseRcptLine."Qty. Outstanding") and
                       (WhseRcptLine."Qty. Outstanding" <> 0) and not SkipConfirm
                    then
                        if not Confirm(Text008, false) then
                            Error(Text009)
                        else
                            Confirmed := true;
                until (WhseRcptLine.Next = 0) or Confirmed;
                WhseRcptLine.DeleteAll();
            end;
        end else
            WhseRcptLine.DeleteAll(UseTableTrigger);

        CrossDockOpp.SetRange("Source Template Name", '');
        CrossDockOpp.SetRange("Source Name/No.", "No.");
        CrossDockOpp.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Whse. Receipt");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();
    end;

    procedure GetHeaderStatus(LineNo: Integer): Integer
    var
        WhseReceiptLine2: Record "Warehouse Receipt Line";
        OrderStatus: Option " ","Partially Received","Completely Received";
    begin
        WhseReceiptLine2.SetRange("No.", "No.");
        with WhseReceiptLine2 do begin
            if LineNo <> 0 then
                SetFilter("Line No.", '<>%1', LineNo);
            if Find('-') then
                repeat
                    case OrderStatus of
                        OrderStatus::" ":
                            OrderStatus := Status;
                        OrderStatus::"Completely Received":
                            if Status = Status::"Partially Received" then
                                OrderStatus := OrderStatus::"Partially Received";
                    end;
                until Next = 0;
        end;
        exit(OrderStatus);
    end;

    procedure LookupWhseRcptHeader(var WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
        Commit();
        if UserId <> '' then begin
            WhseRcptHeader.FilterGroup := 2;
            WhseRcptHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, WhseRcptHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            WhseRcptHeader.FilterGroup := 2;
            WhseRcptHeader.SetRange("Location Code", WhseRcptHeader."Location Code");
            WhseRcptHeader.FilterGroup := 0;
        end;
    end;

    procedure LookupLocation(var WhseRcptHeader: Record "Warehouse Receipt Header")
    var
        Location: Record Location;
    begin
        Commit();
        Location.FilterGroup := 2;
        Location.SetRange(Code);
        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then
            WhseRcptHeader.Validate("Location Code", Location.Code);
        Location.FilterGroup := 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            WhseRcptHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := WhseRcptHeader;
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
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            WhseRcptHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    WhseRcptHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := WhseRcptHeader;
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
    local procedure OnAfterAssistEdit(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteWhseRcptRelatedLines(var WhseRcptLine: Record "Warehouse Receipt Line"; var SkipConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocOnCaseSortingMethodElse(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;
}

