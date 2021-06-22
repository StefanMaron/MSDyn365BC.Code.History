page 731 "Job Act to Bud Price Chart"
{
    Caption = 'Job Act to Bud Price Chart';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            usercontrol(Chart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Jobs;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    BusChartBuf.SetDrillDownIndexes(point);
                    JobChartMgt.DataPointClicked(BusChartBuf, TempJob);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    ChartIsReady := true;
                    UpdateChart(DefaultChartType);
                end;

                trigger Refresh()
                begin
                    if ChartIsReady then
                        UpdateChart(CurrentChartType);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Options)
            {
                Caption = 'Options';
                group("Chart Type")
                {
                    Caption = 'Chart Type';
                    action(Default)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Default';
                        ToolTip = 'Select the default graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(DefaultChartType);
                        end;
                    }
                    action(Column)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Column';
                        ToolTip = 'Select the column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(ChartType::Column);
                        end;
                    }
                    action(Line)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Line';
                        ToolTip = 'Select the line graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(ChartType::Line);
                        end;
                    }
                    action("Stacked Column")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Column';
                        ToolTip = 'Select the stacked column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(ChartType::StackedColumn);
                        end;
                    }
                    action("Stacked Area")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Area';
                        ToolTip = 'Select the stacked area graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(ChartType::StackedArea);
                        end;
                    }
                }
            }
        }
    }

    var
        BusChartBuf: Record "Business Chart Buffer";
        TempJob: Record Job temporary;
        JobChartMgt: Codeunit "Job Chart Mgt";
        ChartIsReady: Boolean;
        ChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel;
        JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price";
        CurrentChartType: Option;

    local procedure UpdateChart(NewChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel)
    begin
        if not ChartIsReady then
            exit;

        JobChartMgt.CreateJobChart(BusChartBuf, TempJob, NewChartType, JobChartType::"Actual to Budget Price");
        BusChartBuf.Update(CurrPage.Chart);
        CurrentChartType := NewChartType;
    end;

    local procedure DefaultChartType(): Integer
    begin
        exit(ChartType::Column);
    end;
}

