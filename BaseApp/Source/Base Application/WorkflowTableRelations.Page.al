page 1509 "Workflow - Table Relations"
{
    ApplicationArea = Suite;
    Caption = 'Workflow - Table Relations';
    PageType = List;
    SourceTable = "Workflow - Table Relation";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the table that is used in the workflow.';
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the caption of the table that is used in the workflow.';
                }
                field("Field ID"; "Field ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the field that is used in the workflow.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the caption of the field that is used in the workflow.';
                }
                field("Related Table ID"; "Related Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the related table that is used in the workflow.';
                }
                field("Related Table Caption"; "Related Table Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the caption of the related field that is used in the workflow.';
                }
                field("Related Field ID"; "Related Field ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the related field that is used in the workflow.';
                }
                field("Related Field Caption"; "Related Field Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the caption of the related table that is used in the workflow.';
                }
            }
        }
    }

    actions
    {
    }
}

