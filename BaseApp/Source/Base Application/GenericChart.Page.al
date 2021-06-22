page 1390 "Generic Chart"
{
    Caption = 'Key Performance Indicators';
    PageType = CardPart;
    SourceTable = "Business Chart Buffer";

    layout
    {
        area(content)
        {
            field("Status Text"; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status Text';
                Editable = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    SetDrillDownIndexes(point);
                    ChartManagement.DataPointClicked(Rec, SelectedChartDefinition);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    ChartManagement.AddinReady(SelectedChartDefinition, Rec);
                    InitializeSelectedChart;
                end;

                trigger Refresh()
                begin
                    InitializeSelectedChart;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Select Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Chart';
                Image = SelectChart;
                ToolTip = 'Change the chart that is displayed. You can choose from several charts that show data for different performance indicators.';

                trigger OnAction()
                begin
                    ChartManagement.SelectChart(Rec, SelectedChartDefinition);
                    InitializeSelectedChart;
                end;
            }
            action("Previous Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Chart';
                Image = PreviousSet;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    SelectedChartDefinition.SetRange(Enabled, true);
                    if SelectedChartDefinition.Next(-1) = 0 then
                        if not SelectedChartDefinition.FindLast then
                            exit;
                    InitializeSelectedChart;
                end;
            }
            action("Next Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Chart';
                Image = NextSet;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    SelectedChartDefinition.SetRange(Enabled, true);
                    if SelectedChartDefinition.Next = 0 then
                        if not SelectedChartDefinition.FindFirst then
                            exit;
                    InitializeSelectedChart;
                end;
            }
            group(PeriodLength)
            {
                Caption = 'Period Length';
                Image = Period;
                action(Day)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Day';
                    Image = DueDate;
                    ToolTip = 'Each stack covers one day.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart("Period Length"::Day);
                    end;
                }
                action(Week)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Week';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one week. The last stack contains data from the start of the week until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart("Period Length"::Week);
                    end;
                }
                action(Month)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one month. The last stack contains data from the start of the month until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart("Period Length"::Month);
                    end;
                }
                action(Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quarter';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one quarter. The last stack contains data from the start of the quarter until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart("Period Length"::Quarter);
                    end;
                }
                action(Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one year. The last stack contains data from the start of the year until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart("Period Length"::Year);
                    end;
                }
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Enabled = PreviousNextActionEnabled;
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, Rec, Period::Previous);
                    Update(CurrPage.BusinessChart);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Enabled = PreviousNextActionEnabled;
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, Rec, Period::Next);
                    Update(CurrPage.BusinessChart);
                end;
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                var
                    Description: Text;
                begin
                    if StatusText = '' then
                        exit;
                    Description := ChartManagement.ChartDescription(SelectedChartDefinition);
                    if Description = '' then
                        Message(NoDescriptionMsg)
                    else
                        Message(Description);
                end;
            }
        }
    }

    var
        SelectedChartDefinition: Record "Chart Definition";
        ChartManagement: Codeunit "Chart Management";
        StatusText: Text;
        Period: Option " ",Next,Previous;
        [InDataSet]
        PreviousNextActionEnabled: Boolean;
        NoDescriptionMsg: Label 'A description was not specified for this chart.';
        IsChartAddInReady: Boolean;

    local procedure InitializeSelectedChart()
    begin
        ChartManagement.SetDefaultPeriodLength(SelectedChartDefinition, Rec);
        ChartManagement.UpdateChart(SelectedChartDefinition, Rec, Period::" ");
        PreviousNextActionEnabled := ChartManagement.UpdateNextPrevious(SelectedChartDefinition);
        ChartManagement.UpdateStatusText(SelectedChartDefinition, Rec, StatusText);
        UpdateChart;
    end;

    local procedure SetPeriodAndUpdateChart(PeriodLength: Option)
    begin
        ChartManagement.SetPeriodLength(SelectedChartDefinition, Rec, PeriodLength, false);
        ChartManagement.UpdateChart(SelectedChartDefinition, Rec, Period::" ");
        ChartManagement.UpdateStatusText(SelectedChartDefinition, Rec, StatusText);
        UpdateChart;
    end;

    local procedure UpdateChart()
    begin
        if not IsChartAddInReady then
            exit;
        Update(CurrPage.BusinessChart);
    end;
}

