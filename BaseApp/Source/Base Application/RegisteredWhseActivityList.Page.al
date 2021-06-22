page 5797 "Registered Whse. Activity List"
{
    Caption = 'Registered Whse. Activity List';
    Editable = false;
    PageType = List;
    SourceTable = "Registered Whse. Activity Hdr.";

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
                    ApplicationArea = Location;
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
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        case Type of
                            Type::"Put-away":
                                PAGE.Run(PAGE::"Registered Put-away", Rec);
                            Type::Pick:
                                PAGE.Run(PAGE::"Registered Pick", Rec);
                            Type::Movement:
                                PAGE.Run(PAGE::"Registered Movement", Rec);
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := FormCaption;
    end;

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
        Text000: Label 'Registered Whse. Put-away List';
        Text001: Label 'Registered Whse. Pick List';
        Text002: Label 'Registered Whse. Movement List';
        Text003: Label 'Registered Whse. Activity List';

    local procedure FormCaption(): Text[250]
    begin
        case Type of
            Type::"Put-away":
                exit(Text000);
            Type::Pick:
                exit(Text001);
            Type::Movement:
                exit(Text002);
            else
                exit(Text003);
        end;
    end;
}

