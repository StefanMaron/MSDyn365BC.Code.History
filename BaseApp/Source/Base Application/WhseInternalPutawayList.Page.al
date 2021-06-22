page 7356 "Whse. Internal Put-away List"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Internal Put-aways';
    CardPageID = "Whse. Internal Put-away";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Internal Put-away Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the internal put-away is being performed.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the warehouse internal put-always are sorted.';
                }
                field("From Zone Code"; "From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone from which the items to be put away should be taken.';
                    Visible = false;
                }
                field("From Bin Code"; "From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin from which the items to be put away should be taken.';
                    Visible = false;
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the internal put-away.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the internal put-away.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                    Visible = false;
                }
                field("Assignment Date"; "Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Put-away")
            {
                Caption = '&Put-away';
                Image = CreatePutAway;
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        LookupInternalPutAwayHeader(Rec);
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Internal Put-away"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Put-away Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Lines';
                    Image = PutawayLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = CONST("Internal Put-away"),
                                  "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  WHERE("Activity Type" = CONST("Put-away"));
                    ToolTip = ' View the related put-aways.';
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Whse. Internal Put-away", Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. When a document is released, it will be included in all availability calculations from the expected receipt date of the items. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
                    begin
                        if Status = Status::Open then
                            ReleaseWhseInternalPutAway.Release(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseInternalPutaway: Codeunit "Whse. Int. Put-away Release";
                    begin
                        ReleaseWhseInternalPutaway.Reopen(Rec);
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then begin
            WhseInternalPutawayHeader := Rec;
            while true do begin
                if WMSMgt.LocationIsAllowed("Location Code") then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := WhseInternalPutawayHeader;
                    if Find(Which) then
                        while true do begin
                            if WMSMgt.LocationIsAllowed("Location Code") then
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
        Nextsteps: Integer;
        Realsteps: Integer;
    begin
        if Steps = 0 then
            exit;

        WhseInternalPutawayHeader := Rec;
        repeat
            Nextsteps := Next(Steps / Abs(Steps));
            if WMSMgt.LocationIsAllowed("Location Code") then begin
                Realsteps := Realsteps + Nextsteps;
                WhseInternalPutawayHeader := Rec;
            end;
        until (Nextsteps = 0) or (Realsteps = Steps);
        Rec := WhseInternalPutawayHeader;
        Find;
        exit(Realsteps);
    end;

    var
        WhseInternalPutawayHeader: Record "Whse. Internal Put-away Header";
        WMSMgt: Codeunit "WMS Management";
}

