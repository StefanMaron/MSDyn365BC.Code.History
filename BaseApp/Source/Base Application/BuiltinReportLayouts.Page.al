namespace System.Reflection;

page 9654 "Built-in Report Layouts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Built-in Report Layouts';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Report Layout List";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the report.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report layout.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the report layout.';
                }
                field(Format; Rec."Layout Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the report layout.';
                }
            }
        }
    }
    actions
    {
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Layout', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }
}

