codeunit 759 "Job Chart Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        XAxisStringTxt: Label 'Job';
        Job: Record Job;
        TotalRevenueTxt: Label 'Total Revenue';
        TotalCostTxt: Label 'Total Cost';
        ProfitMarginTxt: Label 'Profit Margin';
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        CL: array[16] of Decimal;
        PL: array[16] of Decimal;
        ActualTotalCostTxt: Label 'Actual Total Cost';
        BudgetTotalCostTxt: Label 'Budget Total Cost';
        CostVarianceTxt: Label 'Cost Variance';
        ActualTotalPriceTxt: Label 'Actual Total Price';
        BudgetTotalPriceTxt: Label 'Budget Total Price';
        PriceVarianceTxt: Label 'Price Variance';

    [Scope('OnPrem')]
    procedure CreateJobChart(var BusChartBuf: Record "Business Chart Buffer"; var TempJob: Record Job temporary; ChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel; JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price")
    begin
        InitializeBusinessChart(BusChartBuf);
        SetJobRangeByMyJob(TempJob);
        if NothingToShow(TempJob) then
            exit;

        AddMeasures(BusChartBuf, ChartType, JobChartType);
        SetXAxis(BusChartBuf);
        SetJobChartValues(BusChartBuf, TempJob, JobChartType);
    end;

    procedure SetJobRangeByMyJob(var TempRangeJob: Record Job temporary)
    var
        MyJob: Record "My Job";
    begin
        TempRangeJob.DeleteAll();

        with MyJob do begin
            SetRange("User ID", UserId);
            SetRange("Exclude from Business Chart", false);
            if FindSet then
                repeat
                    if Job.Get("Job No.") then begin
                        TempRangeJob := Job;
                        TempRangeJob.Insert();
                    end;
                until Next = 0;
        end;
    end;

    procedure DataPointClicked(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job)
    begin
        with BusChartBuf do begin
            FindCurrentJob(BusChartBuf, RangeJob);
            DrillDownJobValue(RangeJob);
        end;
    end;

    local procedure FindCurrentJob(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job)
    begin
        with RangeJob do begin
            FindSet;
            Next(BusChartBuf."Drill-Down X Index");
        end;
    end;

    local procedure DrillDownJobValue(var RangeJob: Record Job)
    begin
        PAGE.Run(PAGE::"Job Card", RangeJob);
    end;

    local procedure NothingToShow(var RangeJob: Record Job): Boolean
    begin
        with RangeJob do
            exit(IsEmpty);
    end;

    local procedure InitializeBusinessChart(var BusChartBuf: Record "Business Chart Buffer")
    begin
        with BusChartBuf do
            Initialize;
    end;

    local procedure AddMeasures(var BusChartBuf: Record "Business Chart Buffer"; ChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel; JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price")
    begin
        with BusChartBuf do
            case JobChartType of
                JobChartType::Profitability:
                    begin
                        AddMeasure(TotalRevenueTxt, 1, "Data Type"::Decimal, ChartType);
                        AddMeasure(TotalCostTxt, 2, "Data Type"::Decimal, ChartType);
                        AddMeasure(ProfitMarginTxt, 3, "Data Type"::Decimal, ChartType);
                    end;
                JobChartType::"Actual to Budget Cost":
                    begin
                        AddMeasure(ActualTotalCostTxt, 1, "Data Type"::Decimal, ChartType);
                        AddMeasure(BudgetTotalCostTxt, 2, "Data Type"::Decimal, ChartType);
                        AddMeasure(CostVarianceTxt, 3, "Data Type"::Decimal, ChartType);
                    end;
                JobChartType::"Actual to Budget Price":
                    begin
                        AddMeasure(ActualTotalPriceTxt, 1, "Data Type"::Decimal, ChartType);
                        AddMeasure(BudgetTotalPriceTxt, 2, "Data Type"::Decimal, ChartType);
                        AddMeasure(PriceVarianceTxt, 3, "Data Type"::Decimal, ChartType);
                    end;
            end;
    end;

    local procedure SetXAxis(var BusChartBuf: Record "Business Chart Buffer")
    begin
        with BusChartBuf do
            SetXAxis(XAxisStringTxt, "Data Type"::String);
    end;

    local procedure SetJobChartValues(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job; JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price")
    var
        Index: Integer;
        JobRevenue: Decimal;
        JobCost: Decimal;
        ActualCost: Decimal;
        BudgetCost: Decimal;
        ActualPrice: Decimal;
        BudgetPrice: Decimal;
    begin
        with RangeJob do
            if FindSet then
                repeat
                    case JobChartType of
                        JobChartType::Profitability:
                            begin
                                CalculateJobRevenueAndCost(RangeJob, JobRevenue, JobCost);
                                SetJobChartValue(BusChartBuf, RangeJob, Index, JobRevenue, JobCost, JobChartType);
                            end;
                        JobChartType::"Actual to Budget Cost":
                            begin
                                CalculateJobCosts(RangeJob, ActualCost, BudgetCost);
                                SetJobChartValue(BusChartBuf, RangeJob, Index, ActualCost, BudgetCost, JobChartType);
                            end;
                        JobChartType::"Actual to Budget Price":
                            begin
                                CalculateJobPrices(RangeJob, ActualPrice, BudgetPrice);
                                SetJobChartValue(BusChartBuf, RangeJob, Index, ActualPrice, BudgetPrice, JobChartType);
                            end;
                    end;
                until Next = 0;
    end;

    local procedure SetJobChartValue(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job; var Index: Integer; Value1: Decimal; Value2: Decimal; JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price")
    begin
        with BusChartBuf do begin
            AddColumn(RangeJob."No.");
            SetValueByIndex(0, Index, Value1);
            SetValueByIndex(1, Index, Value2);
            if JobChartType = JobChartType::Profitability then
                SetValueByIndex(2, Index, (Value1 - Value2));
            if (JobChartType = JobChartType::"Actual to Budget Cost") or (JobChartType = JobChartType::"Actual to Budget Price") then
                SetValueByIndex(2, Index, (Value2 - Value1));
            Index += 1;
        end;
    end;

    procedure CalculateJobRevenueAndCost(var RangeJob: Record Job; var JobRevenue: Decimal; var JobCost: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts;
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        JobRevenue := PL[16];
        JobCost := CL[8];
    end;

    procedure CalculateJobCosts(var RangeJob: Record Job; var ActualCost: Decimal; var BudgetCost: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts;
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        ActualCost := CL[8];
        BudgetCost := CL[4];
    end;

    procedure CalculateJobPrices(var RangeJob: Record Job; var ActualPrice: Decimal; var BudgetPrice: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts;
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        ActualPrice := PL[16];
        BudgetPrice := PL[4];
    end;
}

