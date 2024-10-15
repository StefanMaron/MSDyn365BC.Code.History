page 10866 "Payment Steps"
{
    AutoSplitKey = true;
    Caption = 'Payment Step';
    CardPageID = "Payment Step Card";
    DataCaptionFields = "Payment Class";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Step";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies text to describe the payment step.';
                }
            }
        }
    }

    actions
    {
    }
}

