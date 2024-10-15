page 17404 "Payroll Calc Group Lines"
{
    Caption = 'Payroll Calc Group Line';
    DataCaptionFields = "Payroll Calc Group";
    PageType = List;
    SourceTable = "Payroll Calc Group Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; "Line No.")
                {
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field("Payroll Calc Type"; "Payroll Calc Type")
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

