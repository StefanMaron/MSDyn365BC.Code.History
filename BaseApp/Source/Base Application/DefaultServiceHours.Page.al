page 5957 "Default Service Hours"
{
    ApplicationArea = Service;
    Caption = 'Default Service Hours';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Service Hour";
    SourceTableView = WHERE("Service Contract No." = CONST(''));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Contract No."; "Service Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract to which the service hours apply.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service hours become valid.';
                }
                field(Day; Day)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the day when the service hours are valid.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting time of the service hours.';
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending time of the service hours.';
                }
                field("Valid on Holidays"; "Valid on Holidays")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that service hours are valid on holidays.';
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
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Clear(ServHour);
        ServHour.SetRange("Service Contract No.", '');
        ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::" ");
        Clear(Weekdays);
        EntryMissing := false;
        if ServHour.Find('-') then begin
            repeat
                Weekdays[ServHour.Day + 1] := true;
            until ServHour.Next = 0;
            for i := 1 to 5 do begin
                if not Weekdays[i] then
                    EntryMissing := true;
            end;
            if EntryMissing then
                if not Confirm(Text000)
                then
                    exit(false);
        end;
    end;

    var
        Text000: Label 'You have not specified service hours for all working days.\Do you want to close the window?', Comment = 'You have not specified service hours for all working days.\Do you want to close the window?';
        ServHour: Record "Service Hour";
        Weekdays: array[7] of Boolean;
        EntryMissing: Boolean;
        i: Integer;
}

