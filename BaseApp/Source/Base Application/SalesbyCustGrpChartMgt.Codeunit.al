codeunit 1319 "Sales by Cust. Grp. Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        SalesByCustGrpChartSetup: Record "Sales by Cust. Grp.Chart Setup";
        TotalSalesLCYTxt: Label 'Total Sales (LCY)';

    procedure OnInitPage()
    begin
        GetChartSetupForCurrentUser;
    end;

    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        NoOfPeriods: Integer;
    begin
        GetChartSetupForCurrentUser;

        with BusChartBuf do begin
            Initialize;
            "Period Length" := SalesByCustGrpChartSetup."Period Length";
            "Period Filter Start Date" := SalesByCustGrpChartSetup."Start Date";
            "Period Filter End Date" := 0D;

            NoOfPeriods := 5;
            CalcCustSales(BusChartBuf, NoOfPeriods);
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        Cust: Record Customer;
        ToDate: Date;
        FromDate: Date;
        MeasureValueString: Text;
    begin
        GetChartSetupForCurrentUser;

        with BusChartBuf do begin
            "Period Length" := SalesByCustGrpChartSetup."Period Length";
            ToDate := GetXValueAsDate("Drill-Down X Index");
            FromDate := CalcFromDate(ToDate);
            MeasureValueString := GetMeasureValueString("Drill-Down Measure Index");
        end;

        if MeasureValueString <> '' then
            Cust.SetRange("Customer Posting Group", MeasureValueString);
        Cust.SetRange("Date Filter", FromDate, ToDate);
        PAGE.Run(PAGE::"Customer List", Cust);
    end;

    local procedure CalcCustSales(var BusChartBuf: Record "Business Chart Buffer"; NoOfPeriods: Decimal)
    var
        Cust: Record Customer;
        PreviousCust: Record Customer;
        TotalSalesValue: array[100] of Decimal;
        SalesValue: array[100] of Decimal;
    begin
        BusChartBuf.SetPeriodXAxis;

        AddSalesMeasure(BusChartBuf, TotalSalesLCYTxt, '', BusChartBuf."Chart Type"::Line);

        Cust.SetCurrentKey("Customer Posting Group");
        if Cust.IsEmpty then begin
            BusChartBuf.SetXAxis('Empty', BusChartBuf."Data Type"::String);
            exit;
        end;

        Cust.FindSet;
        repeat
            if not (PreviousCust."Customer Posting Group" in ['', Cust."Customer Posting Group"]) then begin
                AddSalesMeasure(
                  BusChartBuf,
                  PreviousCust."Customer Posting Group",
                  PreviousCust."Customer Posting Group",
                  BusChartBuf."Chart Type"::Column);
                AddSalesValues(BusChartBuf, PreviousCust."Customer Posting Group", SalesValue, NoOfPeriods);
            end;

            AddCustSales(BusChartBuf, Cust, SalesValue, TotalSalesValue, NoOfPeriods);

            PreviousCust := Cust;
        until Cust.Next = 0;

        AddSalesMeasure(
          BusChartBuf,
          PreviousCust."Customer Posting Group",
          PreviousCust."Customer Posting Group",
          BusChartBuf."Chart Type"::Column);
        AddSalesValues(BusChartBuf, PreviousCust."Customer Posting Group", SalesValue, NoOfPeriods);

        AddSalesValues(BusChartBuf, TotalSalesLCYTxt, TotalSalesValue, NoOfPeriods);
    end;

    local procedure AddCustSales(var BusChartBuf: Record "Business Chart Buffer"; Cust: Record Customer; var SalesValues: array[100] of Decimal; var TotalSalesValues: array[100] of Decimal; NoOfPeriods: Integer)
    var
        FromDate: Date;
        ToDate: Date;
        PeriodNo: Integer;
    begin
        FromDate := BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date");
        for PeriodNo := 1 to NoOfPeriods do begin
            ToDate := BusChartBuf.CalcToDate(FromDate);

            Cust.SetRange("Date Filter", FromDate, ToDate);
            Cust.CalcFields("Sales (LCY)");
            SalesValues[PeriodNo] += Cust."Sales (LCY)";
            TotalSalesValues[PeriodNo] += Cust."Sales (LCY)";

            FromDate := CalcDate('<1D>', ToDate);
        end;

        if BusChartBuf."Period Filter End Date" = 0D then begin
            BusChartBuf."Period Filter End Date" := ToDate;
            BusChartBuf.AddPeriods(BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date"), ToDate);
        end;
    end;

    local procedure AddSalesMeasure(var BusChartBuf: Record "Business Chart Buffer"; Measure: Text; MeasureValue: Text; ChartType: Integer)
    begin
        BusChartBuf.AddMeasure(Measure, MeasureValue, BusChartBuf."Data Type"::Decimal, ChartType);
    end;

    local procedure AddSalesValues(var BusChartBuf: Record "Business Chart Buffer"; Measure: Text; var SalesValues: array[100] of Decimal; NoOfPeriods: Integer)
    var
        PeriodNo: Integer;
    begin
        for PeriodNo := 1 to NoOfPeriods do begin
            BusChartBuf.SetValue(Measure, PeriodNo - 1, SalesValues[PeriodNo]);
            SalesValues[PeriodNo] := 0;
        end;
    end;

    local procedure GetChartSetupForCurrentUser()
    begin
        with SalesByCustGrpChartSetup do
            if not Get(UserId) then begin
                "User ID" := UserId;
                "Start Date" := WorkDate;
                "Period Length" := "Period Length"::Week;
                Insert;
            end;
    end;

    procedure TotalSalesLCY(): Text
    begin
        exit(TotalSalesLCYTxt);
    end;
}

