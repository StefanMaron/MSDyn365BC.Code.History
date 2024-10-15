page 11208 "Automatic Acc. List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Automatic Account Groups';
    CardPageID = "Automatic Acc. Groups";
    Editable = false;
    PageType = List;
    SourceTable = "Automatic Acc. Header";
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies the automatic account group number in this field.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an appropriate description of the automatic account group in this field.';
                }
            }
        }
    }

    actions
    {
    }
}

