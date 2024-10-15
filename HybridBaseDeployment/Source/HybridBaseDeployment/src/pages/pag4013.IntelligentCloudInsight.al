page 4013 "Intelligent Cloud Insights"
{
    PageType = Card;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = Tasks;
    ApplicationArea = Basic, Suite;
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2009758 ';
    layout
    {
        area(Content)
        {
            group(KPIs)
            {
                Caption = 'KPIs';
                part(IntelligentEdgeKPIS; "Intelligent Edge KPIs")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KPIs';
                    ToolTip = 'Intelligent Edge KPIs';
                }
                part(IntelligentEdgeInsights; "Intelligent Edge Insights")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insights';
                    ToolTip = 'Intelligent Edge Insights';
                }

            }
            group(Insight)
            {
                Caption = 'Power BI';
                part(PowerBIReportSpinnerPart; "Power BI Report Spinner Part")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Power BI Report';
                    UpdatePropagation = Both;
                    AccessByPermission = tabledata 6304 = I;
                    ToolTip = 'Power BI Report';
                }
                part(PowerBIReportSpinnerPart2; "Power BI Report Spinner Part")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Power BI Report';
                    UpdatePropagation = Both;
                    AccessByPermission = tabledata 6304 = I;
                    ToolTip = 'Power BI Report';
                }
            }
            group(MachineLearning)
            {
                Caption = 'Azure ML';
                part(CashFlowForecastChart; "Cash Flow Forecast Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Forecast';
                    UpdatePropagation = Both;
                    AccessByPermission = TableData 110 = R;
                    ToolTip = 'Cash Flow Forecast';
                }
            }
        }
    }

    var

    trigger OnOpenPage()
    var

    begin
        CurrPage.PowerBIReportSpinnerPart.Page.SetContext('4009PowerBIPartOne');
        CurrPage.PowerBIReportSpinnerPart2.Page.SetContext('4009PowerBIPartTwo');
    end;
}