page 8635 "Config. Related Tables FactBox"
{
    Caption = 'Related Tables';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Config. Related Table";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("In Worksheet"; "In Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the related table for the configuration table is included in the configuration worksheet.';
                }
                field("Relation Table ID"; "Relation Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the relation table for which related table information is provided.';
                }
                field("Relation Table Name"; "Relation Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the relation table for which related table information is provided.';
                }
                field("Related Fields"; "Related Fields")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    DrillDownPageID = "Config. Related Fields";
                    ToolTip = 'Specifies the number of related fields in the relation table that are associated with the configuration table.';
                }
            }
        }
    }

    actions
    {
    }
}

