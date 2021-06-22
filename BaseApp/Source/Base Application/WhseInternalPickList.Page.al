page 7359 "Whse. Internal Pick List"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Internal Picks';
    CardPageID = "Whse. Internal Pick";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Internal Pick Header";
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
                    ToolTip = 'Specifies the code of the location where the internal pick is being performed.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the warehouse internal pick lines are sorted.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether the internal pick is open or released.';
                }
                field("To Zone Code"; "To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone in which you want the items to be placed when they are picked.';
                    Visible = false;
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin in which you want the items to be placed when they are picked.';
                    Visible = false;
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the document status of the internal pick.';
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
            group("&Pick")
            {
                Caption = '&Pick';
                Image = CreateInventoryPickup;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Internal Pick"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = CONST("Internal Pick"),
                                  "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  WHERE("Activity Type" = CONST(Pick));
                    ToolTip = 'View the related picks.';
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
                        PAGE.Run(PAGE::"Whse. Internal Pick", Rec);
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
                        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
                    begin
                        CurrPage.Update(true);
                        if Status = Status::Open then
                            ReleaseWhseInternalPick.Release(Rec);
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
                        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
                    begin
                        ReleaseWhseInternalPick.Reopen(Rec);
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then begin
            WhseInternalPickHeader := Rec;
            while true do begin
                if WMSMgt.LocationIsAllowed("Location Code") then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := WhseInternalPickHeader;
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
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        WhseInternalPickHeader := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            if WMSMgt.LocationIsAllowed("Location Code") then begin
                RealSteps := RealSteps + NextSteps;
                WhseInternalPickHeader := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := WhseInternalPickHeader;
        Find;
        exit(RealSteps);
    end;

    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WMSMgt: Codeunit "WMS Management";
}

