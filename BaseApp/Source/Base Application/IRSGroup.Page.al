page 10901 "IRS Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Group';
    PageType = List;
    SourceTable = "IRS Groups";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number for this group of Internal Revenue Service (IRS) tax numbers.';
                }
                field(Class; Class)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Class';
                    ToolTip = 'Specifies a class of Internal Revenue Service (IRS) tax numbers.';
                }
            }
        }
    }

    actions
    {
    }
}

