page 9344 "Registered Whse. Picks"
{
    ApplicationArea = Warehouse;
    Caption = 'Registered Warehouse Pick List';
    CardPageID = "Registered Pick";
    Editable = false;
    PageType = List;
    SourceTable = "Registered Whse. Activity Hdr.";
    SourceTableView = WHERE(Type = CONST(Pick));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of activity that the warehouse performed on the lines attached to the header, such as put-away, pick or movement.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Whse. Activity No."; "Whse. Activity No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse activity number from which the activity was registered.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location in which the registered warehouse activity occurred.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines were sorted on the warehouse header, such as by item, or bin code.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
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
            group("P&ick")
            {
                Caption = 'P&ick';
                Image = CreateInventoryPickup;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Rgstrd. Whse. Activity Header"),
                                  Type = FIELD(Type),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action("Delete Registered Movements")
            {
                ApplicationArea = All;
                Caption = 'Delete Registered Picks';
                Image = Delete;
                ToolTip = 'Delete registered warehouse picks.';

                trigger OnAction()
                var
                    DeleteRegisteredWhseDocs: Report "Delete Registered Whse. Docs.";
                    XmlParameters: Text;
                begin
                    XmlParameters := DeleteRegisteredWhseDocs.RunRequestPage(ReportParametersTxt);
                    if XmlParameters <> '' then
                        REPORT.Execute(REPORT::"Delete Registered Whse. Docs.", XmlParameters);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then begin
            RegisteredWhseActivHeader := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowed("Location Code") then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := RegisteredWhseActivHeader;
                    if Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowed("Location Code") then
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

        RegisteredWhseActivHeader := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            if WMSManagement.LocationIsAllowed("Location Code") then begin
                RealSteps := RealSteps + NextSteps;
                RegisteredWhseActivHeader := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := RegisteredWhseActivHeader;
        Find;
        exit(RealSteps);
    end;

    var
        RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr.";
        WMSManagement: Codeunit "WMS Management";
        ReportParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Delete Registered Whse. Docs." id="5755"><DataItems><DataItem name="Registered Whse. Activity Hdr.">VERSION(1) SORTING(Field1,Field2) WHERE(Field1=1(2))</DataItem></DataItems></ReportParameters>', Locked = true;
}

