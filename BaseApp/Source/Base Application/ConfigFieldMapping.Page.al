page 8636 "Config. Field Mapping"
{
    Caption = 'Config. Field Mapping';
    PageType = List;
    SourceTable = "Config. Field Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Old Value"; "Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the old value in the data that you want to map to new value. Usually, the value is one that is based on an option list.';
                }
                field("New Value"; "New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value in the data in Business Central to which you want to map the old value. Usually, the value is one that is in an existing option list.';
                }
            }
        }
    }

    actions
    {
    }
}

