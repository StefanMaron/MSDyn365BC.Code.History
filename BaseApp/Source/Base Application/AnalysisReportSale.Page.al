page 9376 "Analysis Report Sale"
{
    ApplicationArea = SalesAnalysis;
    Caption = 'Sales Analysis Reports';
    PageType = List;
    SourceTable = "Analysis Report Name";
    SourceTableView = WHERE("Analysis Area" = CONST(Sales));
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
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = SalesAnalysis;
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
                ApplicationArea = SalesAnalysis;
                Caption = 'Edit Analysis Report';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the settings for the analysis report such as the name or period.';

                trigger OnAction()
                var
                    SalesAnalysisReport: Page "Sales Analysis Report";
                begin
                    SalesAnalysisReport.SetReportName(Name);
                    SalesAnalysisReport.Run;
                end;
            }
        }
    }
}

