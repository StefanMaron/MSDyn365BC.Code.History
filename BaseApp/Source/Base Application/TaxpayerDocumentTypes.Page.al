page 12494 "Taxpayer Document Types"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Taxpayer Document Types';
    PageType = List;
    SourceTable = "Taxpayer Document Type";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the taxpayer document types that have been set up.';
                }
                field("Document Name"; "Document Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document name associated with the taxpayer document types that have been set up.';
                }
                field(Note; Note)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the note associated with the taxpayer document types that have been set up.';
                }
            }
        }
    }

    actions
    {
    }
}

