table 7318 "Posted Whse. Receipt Header"
{
    Caption = 'Posted Whse. Receipt Header';
    LookupPageID = "Posted Whse. Receipt List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(3; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Warehouse Employee" WHERE("Location Code" = FIELD("Location Code"));
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
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(8; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(9; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist ("Warehouse Comment Line" WHERE("Table Name" = CONST("Posted Whse. Receipt"),
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
        field(14; "Whse. Receipt No."; Code[20])
        {
            Caption = 'Whse. Receipt No.';
        }
        field(15; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
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
        key(Key3; "Whse. Receipt No.")
        {
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Location Code", "Posting Date", "Document Status")
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteRelatedLines;
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        WhseSetup.Get();
        if "No." = '' then begin
            IsHandled := false;
            OnInsertOnBeforeTestWhseReceiptNos(WhseSetup, IsHandled);
            if not IsHandled then
                WhseSetup.TestField("Whse. Receipt Nos.");
            NoSeriesMgt.InitSeries(
              WhseSetup."Posted Whse. Receipt Nos.", xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
    end;

    var
        WhseSetup: Record "Warehouse Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'You must first set up user %1 as a warehouse employee.';

    procedure GetHeaderStatus(LineNo: Integer): Integer
    var
        PostedWhseRcptLine2: Record "Posted Whse. Receipt Line";
        OrderStatus: Option " ","Partially Put Away","Completely Put Away";
        First: Boolean;
    begin
        First := true;
        PostedWhseRcptLine2.SetRange("No.", "No.");
        with PostedWhseRcptLine2 do begin
            if LineNo <> 0 then
                SetFilter("Line No.", '<>%1', LineNo);
            if Find('-') then
                repeat
                    case OrderStatus of
                        OrderStatus::" ":
                            if (Status = Status::"Completely Put Away") and
                               (not First)
                            then
                                OrderStatus := OrderStatus::"Partially Put Away"
                            else
                                OrderStatus := Status;
                        OrderStatus::"Completely Put Away":
                            if Status <> Status::"Completely Put Away" then
                                OrderStatus := OrderStatus::"Partially Put Away";
                    end;
                    First := false;
                until Next = 0;
        end;
        exit(OrderStatus);
    end;

    local procedure DeleteRelatedLines()
    var
        Location: Record Location;
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        if Location.RequirePutaway("Location Code") then
            TestField("Document Status", "Document Status"::"Completely Put Away");

        WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::Receipt);
        WhsePutAwayRequest.SetRange("Document No.", "No.");
        WhsePutAwayRequest.DeleteAll();

        PostedWhseRcptLine.SetRange("No.", "No.");
        PostedWhseRcptLine.DeleteAll();

        WhseCommentLine.SetRange("Table Name", WhseCommentLine."Table Name"::"Posted Whse. Receipt");
        WhseCommentLine.SetRange(Type, WhseCommentLine.Type::" ");
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.DeleteAll();
    end;

    procedure LookupPostedWhseRcptHeader(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header")
    begin
        Commit();
        if UserId <> '' then begin
            PostedWhseRcptHeader.FilterGroup := 2;
            PostedWhseRcptHeader.SetRange("Location Code");
        end;
        if PAGE.RunModal(0, PostedWhseRcptHeader) = ACTION::LookupOK then;
        if UserId <> '' then begin
            PostedWhseRcptHeader.FilterGroup := 2;
            PostedWhseRcptHeader.SetRange("Location Code", PostedWhseRcptHeader."Location Code");
            PostedWhseRcptHeader.FilterGroup := 0;
        end;
    end;

    procedure FindFirstAllowedRec(Which: Text[1024]): Boolean
    var
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WMSManagement: Codeunit "WMS Management";
    begin
        if Find(Which) then begin
            PostedWhseRcptHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowedToView("Location Code") then
                    exit(true);

                if Next(1) = 0 then begin
                    Rec := PostedWhseRcptHeader;
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
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WMSManagement: Codeunit "WMS Management";
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        RealSteps := 0;
        if Steps <> 0 then begin
            PostedWhseRcptHeader := Rec;
            repeat
                NextSteps := Next(Steps / Abs(Steps));
                if WMSManagement.LocationIsAllowedToView("Location Code") then begin
                    RealSteps := RealSteps + NextSteps;
                    PostedWhseRcptHeader := Rec;
                end;
            until (NextSteps = 0) or (RealSteps = Steps);
            Rec := PostedWhseRcptHeader;
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
                Error(Text000, UserId);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfUserIsNotWhseEmployee(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeTestWhseReceiptNos(WarehouseSetup: Record "Warehouse Setup"; var IsHandled: Boolean)
    begin
    end;
}

