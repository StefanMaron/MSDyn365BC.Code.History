page 17500 "Person Excluded Days"
{
    Caption = 'Person Excluded Days';
    PageType = List;
    SourceTable = "Person Excluded Days";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Absence Starting Date"; "Absence Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the absence period.';
                }
                field("Absence Ending Date"; "Absence Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the absence period.';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
            }
        }
    }

    actions
    {
    }
}

