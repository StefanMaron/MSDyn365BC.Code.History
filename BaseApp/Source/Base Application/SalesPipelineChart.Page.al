page 781 "Sales Pipeline Chart"
{
    Caption = 'Sales Pipeline';
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
            }
            usercontrol(BusinessChart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = RelationshipMgmt;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(point);
                    SalesPipelineChartMgt.DrillDown(BusinessChartBuffer, TempSalesCycleStage);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    if not IsChartDataReady then
                        exit;

                    IsChartAddInReady := true;
                    UpdateChart(SalesCycle);
                end;

                trigger Refresh()
                begin
                    if IsChartAddInReady and IsChartDataReady then
                        UpdateChart(SalesCycle);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PrevSalesCycle)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Previous Sales Cycle';
                Enabled = PrevSalesCycleAvailable;
                Image = PreviousRecord;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    SalesPipelineChartMgt.SetPrevNextSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable, -1);
                    UpdateChart(SalesCycle);
                end;
            }
            action(NextSalesCycle)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next Sales Cycle';
                Enabled = NextSalesCycleAvailable;
                Image = NextRecord;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    SalesPipelineChartMgt.SetPrevNextSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable, 1);
                    UpdateChart(SalesCycle);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsChartDataReady :=
          SalesPipelineChartMgt.SetDefaultSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable);
    end;

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        SalesCycle: Record "Sales Cycle";
        TempSalesCycleStage: Record "Sales Cycle Stage" temporary;
        SalesPipelineChartMgt: Codeunit "Sales Pipeline Chart Mgt.";
        StatusText: Text;
        IsChartAddInReady: Boolean;
        IsChartDataReady: Boolean;
        NextSalesCycleAvailable: Boolean;
        PrevSalesCycleAvailable: Boolean;

    local procedure UpdateChart(SalesCycle: Record "Sales Cycle")
    begin
        if not IsChartAddInReady then
            exit;

        SalesPipelineChartMgt.UpdateData(BusinessChartBuffer, TempSalesCycleStage, SalesCycle);
        BusinessChartBuffer.Update(CurrPage.BusinessChart);
        UpdateStatusText(SalesCycle);
    end;

    local procedure UpdateStatusText(SalesCycle: Record "Sales Cycle")
    begin
        StatusText := SalesCycle.TableCaption + ': ' + SalesCycle.Code;
    end;
}

