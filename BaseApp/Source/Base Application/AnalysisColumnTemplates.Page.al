page 7113 "Analysis Column Templates"
{
    Caption = 'Analysis Column Templates';
    DataCaptionFields = "Analysis Area";
    PageType = List;
    SourceTable = "Analysis Column Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the name of the analysis column template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis column template.';
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
            action(Columns)
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Columns';
                Image = Column;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Species the columns on which the analysis view shows data.';

                trigger OnAction()
                var
                    AnalysisLine: Record "Analysis Line";
                    AnalysisReportMgt: Codeunit "Analysis Report Management";
                begin
                    AnalysisLine.FilterGroup := 2;
                    AnalysisLine.SetRange("Analysis Area", GetRangeMax("Analysis Area"));
                    AnalysisLine.FilterGroup := 0;
                    AnalysisReportMgt.OpenAnalysisColumnsForm(AnalysisLine, Name);
                end;
            }
        }
    }
}

