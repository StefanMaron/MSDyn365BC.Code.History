page 9654 "Built-in Report Layouts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Built-in Report Layouts';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Layout';
    SourceTable = "Report Layout List";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the report.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report layout.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the report layout.';
                }
                field(Format; "Layout Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the report layout.';
                }
            }
        }
    }
}

