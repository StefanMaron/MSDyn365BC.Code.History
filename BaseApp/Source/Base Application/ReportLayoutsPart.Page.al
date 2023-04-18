page 9653 "Report Layouts Part"
{
    Caption = 'Report Layouts Part';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Custom Report Layout";
    SourceTableView = SORTING("Report ID", "Company Name", Type);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the report layout.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file type of the report layout. The following table includes the types that are available:';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Central company that the report layout applies to. You to create report layouts that can only be used on reports when they are run for a specific to a company. If the field is blank, then the layout will be available for use in all companies.';
                    Width = 10;
                }
            }
        }
    }

    actions
    {
    }
}

