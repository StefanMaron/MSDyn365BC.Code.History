page 10902 "IRS Type"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Type';
    PageType = List;
    SourceTable = "IRS Types";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number for this type of Internal Revenue Service (IRS) tax numbers.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a type of Internal Revenue Service (IRS) tax numbers.';
                }
            }
        }
    }

    actions
    {
    }
}

