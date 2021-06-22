page 9375 "Analysis Report Purchase"
{
    ApplicationArea = PurchaseAnalysis;
    Caption = 'Purchase Analysis Reports';
    PageType = List;
    SourceTable = "Analysis Report Name";
    SourceTableView = WHERE("Analysis Area" = CONST(Purchase));
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
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis report name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis report description.';
                }
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis line template name for this analysis report.';
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = PurchaseAnalysis;
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
                ApplicationArea = PurchaseAnalysis;
                Caption = 'Edit Analysis Report';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the settings for the analysis report such as the name or period.';

                trigger OnAction()
                var
                    PurchaseAnalysisReport: Page "Purchase Analysis Report";
                begin
                    PurchaseAnalysisReport.SetReportName(Name);
                    PurchaseAnalysisReport.Run;
                end;
            }
        }
    }
}

