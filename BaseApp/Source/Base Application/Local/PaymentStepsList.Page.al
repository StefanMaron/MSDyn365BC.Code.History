page 10873 "Payment Steps List"
{
    Caption = 'Payment Steps List';
    PageType = List;
    SourceTable = "Payment Step";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment Class"; Rec."Payment Class")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment class.';
                }
                field(Line; Line)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the step line''s entry number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies text to describe the payment step.';
                }
                field("Previous Status"; Rec."Previous Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status from which this step should start executing.';
                }
                field("Next Status"; Rec."Next Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status on which this step should end.';
                }
                field("Action Type"; Rec."Action Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of action to be performed by this step.';
                }
            }
        }
    }

    actions
    {
    }
}

