page 9377 "Analysis Report Inventory"
{
    ApplicationArea = InventoryAnalysis;
    Caption = 'Inventory Analysis Reports';
    PageType = List;
    SourceTable = "Analysis Report Name";
    SourceTableView = WHERE("Analysis Area" = CONST(Inventory));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = InventoryAnalysis;
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
        area(processing)
        {
            action(EditAnalysisReport)
            {
                ApplicationArea = InventoryAnalysis;
                Caption = 'Edit Analysis Report';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the settings for the analysis report such as the name or period.';

                trigger OnAction()
                var
                    InventoryAnalysisReport: Page "Inventory Analysis Report";
                begin
                    InventoryAnalysisReport.SetReportName(Name);
                    InventoryAnalysisReport.Run;
                end;
            }
        }
    }
}

