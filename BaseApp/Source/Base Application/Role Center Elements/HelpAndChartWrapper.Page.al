page 1392 "Help And Chart Wrapper"
{
    Caption = 'Business Assistance';
    DeleteAllowed = false;
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field("Status Text"; StatusText)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Status Text';
                Editable = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the status of the resource, such as Completed.';
            }
            usercontrol(BusinessChart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Basic, Suite, Invoicing;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(point);
                    ChartManagement.DataPointClicked(BusinessChartBuffer, SelectedChartDefinition);
                end;

                trigger DataPointDoubleClicked(point: DotNet BusinessChartDataPoint)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    ChartManagement.AddinReady(SelectedChartDefinition, BusinessChartBuffer);
                    InitializeSelectedChart;
                end;

                trigger Refresh()
                begin
                    UpdateChart
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Select Chart';
                Image = SelectChart;
                ToolTip = 'Change the chart that is displayed. You can choose from several charts that show data for different performance indicators.';

                trigger OnAction()
                begin
                    ChartManagement.SelectChart(BusinessChartBuffer, SelectedChartDefinition);
                    InitializeSelectedChart;
                end;
            }
            action("Previous Chart")
            {
                ApplicationArea = Basic, Suite, Invoicing;
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
                ApplicationArea = Basic, Suite, Invoicing;
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
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Day';
                    Image = DueDate;
                    ToolTip = 'Each stack covers one day.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Day);
                    end;
                }
                action(Week)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Week';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one week. The last stack contains data from the start of the week until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Week);
                    end;
                }
                action(Month)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Month';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one month. The last stack contains data from the start of the month until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Month);
                    end;
                }
                action(Quarter)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Quarter';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one quarter. The last stack contains data from the start of the quarter until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Quarter);
                    end;
                }
                action(Year)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Year';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one year. The last stack contains data from the start of the year until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Year);
                    end;
                }
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Previous Period';
                Enabled = PreviousNextActionEnabled;
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::Previous);
                    BusinessChartBuffer.Update(CurrPage.BusinessChart);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Next Period';
                Enabled = PreviousNextActionEnabled;
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::Next);
                    BusinessChartBuffer.Update(CurrPage.BusinessChart);
                end;
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite, Invoicing;
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
            action("Show Assisted Setup")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Show Assisted Setup';
                Tooltip = 'Get assistance with set-up.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the Product Video Topics page to play videos that show how to complete setups that are frequently used.';
                ObsoleteTag = '16.0';

                trigger OnAction()
                begin
                    Message(ShowAssistedSetupObsoletedMsg);
                end;
            }
        }
    }

    var
        ShowAssistedSetupObsoletedMsg: Label 'Use the Product Video Topics page to view the most common videos to setup Business Central.';

    trigger OnOpenPage()
    var
        LastUsedChart: Record "Last Used Chart";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsSaaS := EnvironmentInfo.IsSaaS;
        if LastUsedChart.Get(UserId) then
            if SelectedChartDefinition.Get(LastUsedChart."Code Unit ID", LastUsedChart."Chart Name") then;

        InitializeSelectedChart;
    end;

    var
        SelectedChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartManagement: Codeunit "Chart Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        StatusText: Text;
        Period: Option " ",Next,Previous;
        [InDataSet]
        PreviousNextActionEnabled: Boolean;
        NoDescriptionMsg: Label 'A description was not specified for this chart.';
        IsChartAddInReady: Boolean;
        RefreshPageMsg: Label 'Refresh the page for the change to take effect.';
        IsSaaS: Boolean;
        SignInAgainMsg: Label 'Sign out and sign in for the change to take effect.';

    local procedure InitializeSelectedChart()
    begin
        OnBeforeInitializeSelectedChart(SelectedChartDefinition);
        ChartManagement.SetDefaultPeriodLength(SelectedChartDefinition, BusinessChartBuffer);
        ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::" ");
        PreviousNextActionEnabled := ChartManagement.UpdateNextPrevious(SelectedChartDefinition);
        ChartManagement.UpdateStatusText(SelectedChartDefinition, BusinessChartBuffer, StatusText);
        UpdateChart;
    end;

    local procedure SetPeriodAndUpdateChart(PeriodLength: Option)
    begin
        ChartManagement.SetPeriodLength(SelectedChartDefinition, BusinessChartBuffer, PeriodLength, false);
        ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::" ");
        ChartManagement.UpdateStatusText(SelectedChartDefinition, BusinessChartBuffer, StatusText);
        UpdateChart;
    end;

    local procedure UpdateChart()
    begin
        if not IsChartAddInReady then
            exit;
        BusinessChartBuffer.Update(CurrPage.BusinessChart);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeSelectedChart(var ChartDefinition: Record "Chart Definition")
    begin
    end;
}

