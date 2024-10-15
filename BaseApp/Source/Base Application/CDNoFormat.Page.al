page 14917 "CD No. Format"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'CD No. Format';
    PageType = List;
    SourceTable = "CD No. Format";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Format; Format)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

