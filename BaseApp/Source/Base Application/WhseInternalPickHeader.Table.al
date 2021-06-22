table 7333 "Whse. Internal Pick Header"
{
    Caption = 'Whse. Internal Pick Header';
    DataCaptionFields = "No.";
    LookupPageID = "Whse. Internal Pick List";

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
                    NoSeriesMgt.TestManual(WhseSetup."Whse. Internal Pick Nos.");
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
                WhseInternalPickLine: Record "Whse. Internal Pick Line";
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, FieldCaption("Location Code"), "Location Code");

                CheckPickRequired("Location Code");
                if "Location Code" <> '' then begin
                    Location.Get("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                end;
                if "Location Code" <> xRec."Location Code" then begin
                    "To Zone Code" := '';
                    "To Bin Code" := '';
                    WhseInternalPickLine.SetRange("No.", "No.");
                    if not WhseInternalPickLine.IsEmpty then
                        Error(
                          Text001,
                          FieldCaption("Location Code"));
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
        field(6; "Sorting Method"; Enum "Warehouse Internal Sorting Method")
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
            CalcFormula = Exist ("Warehouse Comment Line" WHERE("Table Name" = CONST("Internal Pick"),
                                                                Type = CONST(" "),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = IF ("To Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("To Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                  "Zone Code" = FIELD("To Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
            begin
                if xRec."To Bin Code" <> "To Bin Code" then begin
                    TestField(Status, Status::Open);
                    if "To Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "To Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "To Bin Code",
                              StrSubstNo(
                                Text005, Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption));
                        Bin.Get("Location Code", "To Bin Code");
                        "To Zone Code" := Bin."Zone Code";
                    end;
                    MessageIfIntPickLinesExist(FieldCaption("To Bin Code"));
                end;
            end;
        }
        field(13; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                if "To Zone Code" <> xRec."To Zone Code" then begin
                    TestField(Status, Status::Open);
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                    "To Bin Code" := '';
                    MessageIfIntPickLinesExist(FieldCaption("To Zone Code"));
                end;
            end;
        }
        field(34; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Picked,Completely Picked';
            OptionMembers = " ","Partially Picked","Completely Picked";

            trigger OnValidate()
            var
                WhsePickRqst: Record "Whse. Pick Request";
            begin
                if "Document Status" <> xRec."Document Status" then begin
                    WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
                    WhsePickRqst.SetRange("Document No.", "No.");
                    if not WhsePickRqst.IsEmpty then
                        WhsePickRqst.ModifyAll(
                          "Completely Picked", "Document Status" = "Document Status"::"Completely Picked");
                end;
            end;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                MessageIfIntPickLinesExist(FieldCaption("Due Date"));
            end;
        }
        field(47; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);
        DeleteRelatedLines;
    end;

    trigger OnInsert()
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            WhseSetup.TestField("Whse. Internal Pick Nos.");
            NoSeriesMgt.InitSeries(
              WhseSetup."Whse. Internal Pick Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        WhseSetup: Record "Warehouse Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change the %1, because the document has one or more lines.';
        WmsManagement: Codeunit "WMS Management";
        Text003: Label 'You are not allowed to use %1 %2.';
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        HideValidationDialog: Boolean;
        Text005: Label 'must not be the %1 of the %2';
        Text006: Label 'You have changed %1 on the %2, but it has not been changed on the existing Warehouse Internal Pick Lines.\';
        Text007: Label 'You must update the existing Warehouse Internal Pick Lines manually.';

    procedure AssistEdit(OldWhseInternalPickHeader: Record "Whse. Internal Pick Header"): Boolean
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        WhseSetup.Get();
        with WhseInternalPickHeader do begin
            WhseInternalPickHeader := Rec;
            WhseSetup.TestField("Whse. Internal Pick Nos.");
            if NoSeriesMgt.SelectSeries(
                 WhseSetup."Whse. Internal Pick Nos.", OldWhseInternalPickHeader."No. Series", "No. Series")
            then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := WhseInternalPickHeader;
                exit(true);
            end;
        end;
    end;

    local procedure SortWhseDoc()
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        SequenceNo: Integer;
    begin
        with WhseInternalPickLine do begin
            SetRange("No.", Rec."No.");
            case "Sorting Method" of
                "Sorting Method"::Item:
                    SetCurrentKey("No.", "Item No.");
                "Sorting Method"::"Shelf or Bin":
                    begin
                        GetLocation(Rec."Location Code");
                        if Location."Bin Mandatory" then
                            SetCurrentKey("No.", "To Bin Code")
                        else
                            SetCurrentKey("No.", "Shelf No.");
                    end;
                "Sorting Method"::"Due Date":
                    SetCurrentKey("No.", "Due Date");
                else
                    OnSortWhseDocOnCaseSortingMethodElse(Rec);
            end;

            if Find('-') then begin
                SequenceNo := 10000;
                repeat
                    "Sorting Sequence No." := SequenceNo;
                    Modify;
                    SequenceNo := SequenceNo + 10000;
                until Next = 0;
            end;
        end;
    end;

    procedure GetDocumentStatus(LineNo: Integer): Integer
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        with WhseInternalPickLine do begin
            if LineNo <> 0 then
                SetFilter("Line No.", '<>%1', LineNo);
            if not FindFirst then
                exit(Status::" ");

            SetRange(Status, Status::"Partially Picked");
            if FindFirst then
                exit(Status);

            SetRange(Status, Status::"Completely Picked");
            if FindFirst then begin
                SetFilter(Status, '<%1', Status::"Completely Picked");
                if FindFirst then
                    exit(Status::"Partially Picked");

                exit(Status);
            end;

            exit(Status);
        end;
    end;

    local procedure MessageIfIntPickLinesExist(ChangedFieldName: Text[80])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        if not WhseInternalPickLine.IsEmpty then
            if not HideValidationDialog then
                Message(
                  StrSubstNo(
                    Text006, ChangedFieldName, TableCaption) + Text007);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure LookupWhseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
        Commit();
        if UserId <> '' then begin
            WhseInternalPickHeader.FilterGroup := 2;
            WhseInternalPickHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, WhseInternalPickHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            WhseInternalPickHeader.FilterGroup := 2;
            WhseInternalPickHeader.SetRange("Location Code", WhseInternalPickHeader."Location Code");
            WhseInternalPickHeader.FilterGroup := 0;
        end;
    end;

    procedure SetWhseLocationFilter()
    var
        WmsManagement: Codeunit "WMS Management";
    begin
        if UserId <> '' then begin
            FilterGroup := 2;
            SetRange("Location Code", WmsManagement.GetAllowedLocation("Location Code"));
            FilterGroup := 0;
        end;
    end;

    procedure LookupLocation(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    var
        Location: Record Location;
    begin
        Commit();
        Location.FilterGroup := 2;
        Location.SetRange(Code);
        if PAGE.RunModal(PAGE::"Locations with Warehouse List", Location) = ACTION::LookupOK then
            WhseInternalPickHeader.Validate("Location Code", Location.Code);
        Location.FilterGroup := 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteRelatedLines()
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhsePickRqst: Record "Whse. Pick Request";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        WhseInternalPickLine.SetRange("No.", "No.");
        WhseInternalPickLine.DeleteAll();

        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
        WhsePickRqst.SetRange("Document No.", "No.");
        if not WhsePickRqst.IsEmpty then
            WhsePickRqst.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Internal Pick");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Whse. Internal Pick Line", 0, "No.", '', 0, 0, '', false);
    end;

    procedure CheckPickRequired(LocationCode: Code[10])
    begin
        if LocationCode = '' then begin
            WhseSetup.Get();
            WhseSetup.TestField("Require Pick");
        end else begin
            GetLocation(LocationCode);
            Location.TestField("Require Pick");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocOnCaseSortingMethodElse(WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;
}

