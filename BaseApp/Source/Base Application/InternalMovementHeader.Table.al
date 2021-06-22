table 7346 "Internal Movement Header"
{
    Caption = 'Internal Movement Header';
    LookupPageID = "Internal Movement List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                InvtSetup.Get();
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(InvtSetup."Internal Movement Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                if not WmsManagement.LocationIsAllowed("Location Code") then
                    Error(Text003, "Location Code");

                CheckLocationSettings("Location Code");
                if "Location Code" <> xRec."Location Code" then begin
                    if LineExist then
                        Error(LinesExistErr, FieldCaption("Location Code"));
                    "To Bin Code" := '';
                end;

                FilterGroup := 2;
                SetRange("Location Code", "Location Code");
                FilterGroup := 0;
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
        field(6; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(7; Comment; Boolean)
        {
            CalcFormula = Exist ("Warehouse Comment Line" WHERE("Table Name" = CONST("Internal Movement"),
                                                                Type = CONST(" "),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            var
                BinType: Record "Bin Type";
                InternalMovementLine: Record "Internal Movement Line";
            begin
                if xRec."To Bin Code" <> "To Bin Code" then begin
                    if "To Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "To Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "To Bin Code",
                              StrSubstNo(
                                Text001, Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption));

                        Bin.Get("Location Code", "To Bin Code");
                        if Bin."Bin Type Code" <> '' then
                            if BinType.Get(Bin."Bin Type Code") then
                                BinType.TestField(Receive, false);
                    end;
                    InternalMovementLine.SetRange("No.", "No.");
                    if not InternalMovementLine.IsEmpty then
                        Message(Text004, FieldCaption("To Bin Code"), TableCaption);
                end;
            end;
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(12; "Sorting Method"; Enum "Warehouse Internal Sorting Method")
        {
            Caption = 'Sorting Method';

            trigger OnValidate()
            begin
                if "Sorting Method" <> xRec."Sorting Method" then
                    SortWhseDoc;
            end;
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
        DeleteRelatedLines;
    end;

    trigger OnInsert()
    begin
        InvtSetup.Get();
        if "No." = '' then begin
            InvtSetup.TestField("Internal Movement Nos.");
            NoSeriesMgt.InitSeries(
              InvtSetup."Internal Movement Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        Location: Record Location;
        Bin: Record Bin;
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        WmsManagement: Codeunit "WMS Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Text001: Label 'must not be the %1 of the %2';
        Text002: Label 'You cannot rename a %1.';
        Text003: Label 'You cannot use Location Code %1.';
        Text004: Label 'You have changed the %1 on the %2, but it has not been changed on the existing internal movement lines.\You must update the existing internal movement lines manually.';
        NoAllowedLocationsErr: Label 'Internal movement is not possible at any locations where you are a warehouse employee.';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1=Location Code';

    local procedure SortWhseDoc()
    var
        InternalMovementLine: Record "Internal Movement Line";
        SequenceNo: Integer;
    begin
        InternalMovementLine.Reset();
        InternalMovementLine.SetRange("No.", "No.");
        case "Sorting Method" of
            "Sorting Method"::Item:
                InternalMovementLine.SetCurrentKey("No.", "Item No.");
            "Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        InternalMovementLine.SetCurrentKey("No.", "From Bin Code")
                    else
                        InternalMovementLine.SetCurrentKey("No.", "Shelf No.");
                end;
            "Sorting Method"::"Due Date":
                InternalMovementLine.SetCurrentKey("No.", "Due Date");
            else
                OnSortWhseDocOnCaseSortingMethodElse(Rec);
        end;

        if InternalMovementLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                InternalMovementLine."Sorting Sequence No." := SequenceNo;
                InternalMovementLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until InternalMovementLine.Next = 0;
        end;
    end;

    procedure AssistEdit(): Boolean
    begin
        InvtSetup.Get();
        InvtSetup.TestField("Internal Movement Nos.");
        if NoSeriesMgt.SelectSeries(InvtSetup."Internal Movement Nos.", xRec."No. Series", "No. Series")
        then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure LineExist(): Boolean
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        InternalMovementLine.SetRange("No.", "No.");
        exit(not InternalMovementLine.IsEmpty);
    end;

    procedure OpenInternalMovementHeader(var InternalMovementHeader: Record "Internal Movement Header")
    var
        WhseEmployee: Record "Warehouse Employee";
        CurrentLocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenInternalMovementHeader(InternalMovementHeader, IsHandled);
        if IsHandled then
            exit;

        WhseEmployee.SetRange("Location Code", InternalMovementHeader."Location Code");
        if not WhseEmployee.IsEmpty then
            CurrentLocationCode := InternalMovementHeader."Location Code"
        else
            CurrentLocationCode := GetDefaultOrFirstAllowedLocation;

        InternalMovementHeader.FilterGroup := 2;
        InternalMovementHeader.SetRange("Location Code", CurrentLocationCode);
        InternalMovementHeader.FilterGroup := 0;
    end;

    procedure LookupInternalMovementHeader(var InternalMovementHeader: Record "Internal Movement Header")
    begin
        Commit();
        InternalMovementHeader.FilterGroup := 2;
        InternalMovementHeader.SetRange("Location Code");
        if PAGE.RunModal(0, InternalMovementHeader) = ACTION::LookupOK then;
        InternalMovementHeader.SetRange("Location Code", InternalMovementHeader."Location Code");
        InternalMovementHeader.FilterGroup := 0;
    end;

    local procedure DeleteRelatedLines()
    var
        InternalMovementLine: Record "Internal Movement Line";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        InternalMovementLine.SetRange("No.", "No.");
        InternalMovementLine.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Internal Movement");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"Internal Movement Line", 0, "No.", '', 0, 0, '', false);
    end;

    procedure CheckLocationSettings(LocationCode: Code[10])
    begin
        GetLocation(LocationCode);
        Location.TestField("Directed Put-away and Pick", false);
        Location.TestField("Bin Mandatory", true);
    end;

    local procedure GetDefaultOrFirstAllowedLocation() LocationCode: Code[10]
    var
        WhseEmployeesatLocations: Query "Whse. Employees at Locations";
    begin
        WhseEmployeesatLocations.SetRange(User_ID, UserId);
        WhseEmployeesatLocations.SetRange(Bin_Mandatory, true);
        WhseEmployeesatLocations.SetRange(Directed_Put_away_and_Pick, false);

        WhseEmployeesatLocations.SetRange(Default, true);
        if GetFirstLocationCodeFromLocationsofWhseEmployee(LocationCode, WhseEmployeesatLocations) then
            exit(LocationCode);

        WhseEmployeesatLocations.SetRange(Default);
        if GetFirstLocationCodeFromLocationsofWhseEmployee(LocationCode, WhseEmployeesatLocations) then
            exit(LocationCode);

        Error(NoAllowedLocationsErr);
    end;

    local procedure GetFirstLocationCodeFromLocationsofWhseEmployee(var LocationCode: Code[10]; var WhseEmployeesatLocations: Query "Whse. Employees at Locations"): Boolean
    begin
        WhseEmployeesatLocations.TopNumberOfRows(1);
        if WhseEmployeesatLocations.Open then
            if WhseEmployeesatLocations.Read then begin
                LocationCode := WhseEmployeesatLocations.Code;
                WhseEmployeesatLocations.Close;
                exit(true);
            end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenInternalMovementHeader(var InternalMovementHeader: Record "Internal Movement Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseDocOnCaseSortingMethodElse(var InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;
}

