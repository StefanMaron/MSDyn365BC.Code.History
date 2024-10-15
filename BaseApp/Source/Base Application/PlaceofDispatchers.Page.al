page 11000 "Place of Dispatchers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Place of Dispatchers';
    PageType = List;
    SourceTable = "Place of Dispatcher";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a location code for the dispatcher.';
                }
                field(Text; Text)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you must enter a name for the location of the dispatcher.';
                }
            }
        }
    }

    actions
    {
    }
}

