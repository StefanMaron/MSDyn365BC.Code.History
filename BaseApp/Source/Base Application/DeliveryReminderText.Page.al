page 5005283 "Delivery Reminder Text"
{
    AutoSplitKey = true;
    Caption = 'Delivery Reminder Text';
    DataCaptionFields = "Reminder Level", Position;
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Delivery Reminder Text";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder terms code this text applies to.';
                    Visible = false;
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder level this text applies to.';
                    Visible = false;
                }
                field(Position; Position)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will appear at the beginning or the end of the delivery reminder.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text for this line of the reminder.';
                }
            }
        }
    }

    actions
    {
    }
}

