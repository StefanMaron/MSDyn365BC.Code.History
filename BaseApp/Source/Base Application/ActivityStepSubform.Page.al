page 5102 "Activity Step Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Activity Step";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the step. There are three options:';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the step.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the step.';
                }
                field("Date Formula"; "Date Formula")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date formula that determines how to calculate when the step should be completed.';
                }
            }
        }
    }

    actions
    {
    }
}

