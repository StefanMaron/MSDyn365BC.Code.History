page 7116 "Analysis Report Names"
{
    Caption = 'Analysis Report Names';
    PageType = List;
    SourceTable = "Analysis Report Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the column template name for this analysis report.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

