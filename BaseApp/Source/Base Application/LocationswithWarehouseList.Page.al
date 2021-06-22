page 7347 "Locations with Warehouse List"
{
    Caption = 'Locations with Warehouse List';
    CardPageID = "Location Card";
    Editable = false;
    PageType = List;
    SourceTable = Location;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name or address of the location.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Zones")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Zones';
                    Image = Zones;
                    RunObject = Page Zones;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to structure your bins under zones.';
                }
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to hold items.';
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then begin
            Location := Rec;
            while true do begin
                if WMSMgt.LocationIsAllowed(Code) then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := Location;
                    if Find(Which) then
                        while true do begin
                            if WMSMgt.LocationIsAllowed(Code) then
                                exit(true);
                            if Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        Location := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            if WMSMgt.LocationIsAllowed(Code) then begin
                RealSteps := RealSteps + NextSteps;
                Location := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := Location;
        Find;
        exit(RealSteps);
    end;

    var
        Location: Record Location;
        WMSMgt: Codeunit "WMS Management";
}

