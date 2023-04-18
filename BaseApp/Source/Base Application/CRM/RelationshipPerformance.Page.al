page 783 "Relationship Performance"
{
    Caption = 'Top 5 Opportunities';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Status Text';
                Enabled = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the status of the chart.';
                Visible = false;
            }
            usercontrol(BusinessChart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = RelationshipMgmt;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(point);
                    RlshpPerformanceMgt.DrillDown(BusinessChartBuffer, TempOpportunity);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    UpdateChart();
                end;

                trigger Refresh()
                begin
                    if IsChartAddInReady then
                        UpdateChart();
                end;
            }
        }
    }

    actions
    {
    }

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempOpportunity: Record Opportunity temporary;
        StatusText: Text;
        IsChartAddInReady: Boolean;

    protected var
        RlshpPerformanceMgt: Codeunit "Relationship Performance Mgt.";

    protected procedure UpdateChart()
    begin
        if not IsChartAddInReady then
            exit;

        RlshpPerformanceMgt.UpdateData(BusinessChartBuffer, TempOpportunity);
        BusinessChartBuffer.Update(CurrPage.BusinessChart);
    end;
}

