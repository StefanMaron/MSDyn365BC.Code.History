codeunit 1316 "Top Ten Customers Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CustomerXCaptionTxt: Label 'Customer Name';
        SalesLCYYCaptionTxt: Label 'Sales (LCY)';

    [Scope('OnPrem')]
    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        ColumnIndex: Integer;
        CustomerName: array[11] of Text[100];
        SalesLCY: array[11] of Decimal;
    begin
        with BusChartBuf do begin
            Initialize;
            AddMeasure(SalesLCYYCaptionTxt, 1, "Data Type"::Decimal, "Chart Type"::StackedColumn);
            SetXAxis(CustomerXCaptionTxt, "Data Type"::String);
            CalcTopTenSalesCustomers(CustomerName, SalesLCY);
            for ColumnIndex := 1 to 11 do begin
                if SalesLCY[ColumnIndex] = 0 then
                    exit;
                AddColumn(CustomerName[ColumnIndex]);
                SetValueByIndex(0, ColumnIndex - 1, SalesLCY[ColumnIndex]);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        CustomerName: Variant;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", CustomerName);
        // drill down only for top 10 customers
        // for the 11th column "all other customers", it drills down to customer list of all other customers
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" < 10) then
            DrillDownCust(Format(CustomerName));
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" = 10) then
            DrillDownOtherCustList;
    end;

    local procedure CalcTopTenSalesCustomers(var CustomerName: array[11] of Text[100]; var SalesLCY: array[11] of Decimal)
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TopCustomersBySalesJob: Codeunit "Top Customers By Sales Job";
        ChartManagement: Codeunit "Chart Management";
    begin
        if TopCustomersBySalesBuffer.IsEmpty then
            TopCustomersBySalesJob.UpdateCustomerTopList;

        if TopCustomersBySalesBuffer.FindSet then begin
            repeat
                CustomerName[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.CustomerName;
                SalesLCY[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.SalesLCY;
            until TopCustomersBySalesBuffer.Next = 0;
            ChartManagement.ScheduleTopCustomerListRefreshTask
        end;
    end;

    local procedure DrillDownCust(DrillDownName: Text[50])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange(Name, DrillDownName);
        Customer.FindFirst;
        PAGE.Run(PAGE::"Customer Card", Customer);
    end;

    local procedure DrillDownOtherCustList()
    var
        Customer: Record Customer;
    begin
        Customer.SetFilter("No.", GetFilterToExcludeTopTenCustomers);
        Customer.SetCurrentKey(Name);
        Customer.Ascending(true);
        PAGE.Run(PAGE::"Customer List", Customer);
    end;

    local procedure GetFilterToExcludeTopTenCustomers(): Text
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        CustomerCounter: Integer;
        FilterToExcludeTopTenCustomers: Text;
    begin
        CustomerCounter := 1;
        if TopCustomersBySalesBuffer.FindSet then
            repeat
                if CustomerCounter = 1 then
                    FilterToExcludeTopTenCustomers := StrSubstNo('<>%1', TopCustomersBySalesBuffer.CustomerNo)
                else
                    FilterToExcludeTopTenCustomers += StrSubstNo('&<>%1', TopCustomersBySalesBuffer.CustomerNo);
                CustomerCounter += 1;
            until (TopCustomersBySalesBuffer.Next = 0) or (CustomerCounter = 11);
        exit(FilterToExcludeTopTenCustomers);
    end;
}

