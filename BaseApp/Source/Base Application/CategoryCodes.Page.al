page 7000023 "Category Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Category Codes';
    PageType = List;
    SourceTable = "Category Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify how you are sorting the documents.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a text description of the document sorting.';
                }
            }
        }
    }

    actions
    {
    }
}

