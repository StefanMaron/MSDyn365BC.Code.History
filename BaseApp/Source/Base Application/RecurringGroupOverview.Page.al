page 15000301 "Recurring Group Overview"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Recurring Groups';
    CardPageID = "Recurring Groups Card";
    Editable = false;
    PageType = List;
    SourceTable = "Recurring Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code to identify the recurring group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description to identify the recurring group.';
                }
                field("Date formula"; "Date formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the time interval between orders.';
                }
                field("Starting date"; "Starting date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date of the recurring group.';
                }
                field("Closing date"; "Closing date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date of the recurring group.';
                }
            }
        }
    }

    actions
    {
    }
}

