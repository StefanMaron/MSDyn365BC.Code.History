page 759 "Job Profitability Chart"
{
    Caption = 'Job Profitability Chart';
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
                    UpdateChart(DefaultChartType());
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
                            UpdateChart(DefaultChartType());
                        end;
                    }
                    action(Column)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Column';
                        ToolTip = 'Select the column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart("Business Chart Type"::Column);
                        end;
                    }
                    action(Line)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Line';
                        ToolTip = 'Select the line graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart("Business Chart Type"::Line);
                        end;
                    }
                    action("Stacked Column")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Column';
                        ToolTip = 'Select the stacked column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart("Business Chart Type"::StackedColumn);
                        end;
                    }
                    action("Stacked Area")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Area';
                        ToolTip = 'Select the stacked area graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart("Business Chart Type"::StackedArea);
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
        CurrentChartType: Enum "Business Chart Type";

    local procedure UpdateChart(NewChartType: Enum "Business Chart Type")
    begin
        if not ChartIsReady then
            exit;

        JobChartMgt.CreateChart(BusChartBuf, TempJob, NewChartType, "Job Chart Type"::Profitability);
        BusChartBuf.Update(CurrPage.Chart);
        CurrentChartType := NewChartType;
    end;

    local procedure DefaultChartType(): Enum "Business Chart Type"
    begin
        exit("Business Chart Type"::Column);
    end;
}

