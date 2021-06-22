page 9200 "Time Zones"
{
    Caption = 'Time Zones';
    PageType = List;
    SourceTable = "Time Zone";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the time zone.';
                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full name of the time zone.';
                }
            }
        }
    }

    actions
    {
    }
}

