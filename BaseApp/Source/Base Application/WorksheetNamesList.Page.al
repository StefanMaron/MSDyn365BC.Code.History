page 7346 "Worksheet Names List"
{
    Caption = 'Worksheet Names List';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Worksheet Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name you enter for the worksheet.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code of the warehouse the worksheet should be used for.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description for the worksheet.';
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
        area(processing)
        {
            action("Edit Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Worksheet';
                Image = OpenWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open the related worksheet.';

                trigger OnAction()
                begin
                    WhseWkshLine.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then begin
            PickWkshName := Rec;
            while true do begin
                if WMSMgt.LocationIsAllowed("Location Code") then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := PickWkshName;
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

    trigger OnInit()
    begin
        SetRange("Worksheet Template Name");
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        PickWkshName := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            if WMSMgt.LocationIsAllowed("Location Code") then begin
                RealSteps := RealSteps + NextSteps;
                PickWkshName := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := PickWkshName;
        Find;
        exit(RealSteps);
    end;

    trigger OnOpenPage()
    begin
        WhseWkshLine.OpenWhseWkshBatch(Rec);
    end;

    var
        PickWkshName: Record "Whse. Worksheet Name";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WMSMgt: Codeunit "WMS Management";
}

