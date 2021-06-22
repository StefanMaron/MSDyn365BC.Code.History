page 1535 "Dynamic Request Page Entities"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Dynamic Request Page Entities';
    PageType = List;
    SourceTable = "Dynamic Request Page Entity";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the workflow event condition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the workflow event condition.';
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that the workflow event condition applies to.';
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the table that the workflow event condition applies to.';
                }
                field("Related Table ID"; "Related Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that the workflow event condition applies to.';
                }
                field("Related Table Name"; "Related Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related table that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Related Table Caption"; "Related Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the related table that the workflow event condition applies to.';
                }
                field("Sequence No."; "Sequence No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
            }
        }
    }

    actions
    {
    }
}

