page 978 "Time Sheet Setup Resources"
{
    PageType = ListPart;
    SourceTable = Resource;
    Caption = 'Resources';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Use Time Sheet"; "Use Time Sheet")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a resource uses time sheets to record the time they use on tasks.';
                }
                field("Time Sheet Owner User ID"; "Time Sheet Owner User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the owner of the time sheet.';
                }
                field("Time Sheet Approver User ID"; "Time Sheet Approver User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the approver of the time sheet.';
                }
            }

        }
    }
}