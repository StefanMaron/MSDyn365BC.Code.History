codeunit 1326 "Top Five Customers Chart Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CustomerXCaptionTxt: Label 'Customer Name';
        SalesLCYYCaptionTxt: Label 'Sales (LCY)';
        AllOtherCustomersTxt: Label 'All Other Customers';
        SalesAmountCaptionTxt: Label 'Amount Excl. VAT (%1)', Comment = '%1=Currency Symbol (e.g. $)';

    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        GLSetup: Record "General Ledger Setup";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ColumnIndex: Integer;
        CustomerName: array[11] of Text[100];
        SalesLCY: array[11] of Decimal;
    begin
        with BusChartBuf do begin
            Initialize;
            if GLSetup.Get then;
            if EnvInfoProxy.IsInvoicing then
                AddMeasure(StrSubstNo(SalesAmountCaptionTxt, GLSetup.GetCurrencySymbol), 1, "Data Type"::Decimal, "Chart Type"::Doughnut)
            else
                AddMeasure(SalesLCYYCaptionTxt, 1, "Data Type"::Decimal, "Chart Type"::Doughnut);
            SetXAxis(CustomerXCaptionTxt, "Data Type"::String);
            CalcTopSalesCustomers(CustomerName, SalesLCY);
            for ColumnIndex := 1 to 6 do begin
                if SalesLCY[ColumnIndex] = 0 then
                    exit;
                AddColumn(CustomerName[ColumnIndex]);
                SetValueByIndex(0, ColumnIndex - 1, SalesLCY[ColumnIndex]);
            end;
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        CustomerName: Variant;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", CustomerName);
        // drill down only for top 5 customers
        // for the 6th column "all other customers", it drills down to customer list of all other customers
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" < 5) then
            DrillDownCust(Format(CustomerName));
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" = 5) then
            DrillDownOtherCustList;
    end;

    local procedure CalcTopSalesCustomers(var CustomerName: array[6] of Text[100]; var SalesLCY: array[6] of Decimal)
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TopCustomersBySalesJob: Codeunit "Top Customers By Sales Job";
        ChartManagement: Codeunit "Chart Management";
        ColumnIndex: Integer;
        OtherCustomersSalesLCY: Decimal;
    begin
        if TopCustomersBySalesBuffer.IsEmpty then
            TopCustomersBySalesJob.UpdateCustomerTopList;

        if TopCustomersBySalesBuffer.FindSet then begin
            repeat
                ColumnIndex += 1;
                if ColumnIndex <= 5 then begin
                    CustomerName[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.CustomerName;
                    SalesLCY[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.SalesLCY
                end else
                    OtherCustomersSalesLCY += TopCustomersBySalesBuffer.SalesLCY;
            until TopCustomersBySalesBuffer.Next = 0;

            if OtherCustomersSalesLCY <> 0 then begin
                CustomerName[6] := AllOtherCustomersTxt;
                SalesLCY[6] := OtherCustomersSalesLCY
            end;

            ChartManagement.ScheduleTopCustomerListRefreshTask
        end;
    end;

    local procedure DrillDownCust(DrillDownName: Text[100])
    var
        Customer: Record Customer;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        Customer.SetRange(Name, DrillDownName);
        Customer.FindFirst;
        if EnvInfoProxy.IsInvoicing then
            PAGE.Run(PAGE::"BC O365 Sales Customer Card", Customer)
        else
            PAGE.Run(PAGE::"Customer Card", Customer);
    end;

    local procedure DrillDownOtherCustList()
    var
        Customer: Record Customer;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        Customer.SetFilter("No.", GetFilterToExcludeTopFiveCustomers);
        Customer.SetCurrentKey(Name);
        Customer.Ascending(true);
        if EnvInfoProxy.IsInvoicing then
            PAGE.Run(PAGE::"BC O365 Customer List", Customer)
        else
            PAGE.Run(PAGE::"Customer List", Customer);
    end;

    local procedure GetFilterToExcludeTopFiveCustomers(): Text
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        CustomerCounter: Integer;
        FilterToExcludeTopFiveCustomers: Text;
    begin
        CustomerCounter := 1;
        if TopCustomersBySalesBuffer.FindSet then
            repeat
                if CustomerCounter = 1 then
                    FilterToExcludeTopFiveCustomers := StrSubstNo('<>%1', TopCustomersBySalesBuffer.CustomerNo)
                else
                    FilterToExcludeTopFiveCustomers += StrSubstNo('&<>%1', TopCustomersBySalesBuffer.CustomerNo);
                CustomerCounter += 1;
            until (TopCustomersBySalesBuffer.Next = 0) or (CustomerCounter = 6);
        exit(FilterToExcludeTopFiveCustomers);
    end;
}

