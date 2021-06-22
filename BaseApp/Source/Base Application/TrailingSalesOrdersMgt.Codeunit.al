codeunit 760 "Trailing Sales Orders Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TrailingSalesOrdersSetup: Record "Trailing Sales Orders Setup";
        SalesHeader: Record "Sales Header";

    procedure OnOpenPage(var TrailingSalesOrdersSetup: Record "Trailing Sales Orders Setup")
    begin
        with TrailingSalesOrdersSetup do
            if not Get(UserId) then begin
                LockTable();
                "User ID" := UserId;
                "Use Work Date as Base" := true;
                "Period Length" := "Period Length"::Month;
                "Value to Calculate" := "Value to Calculate"::"No. of Orders";
                "Chart Type" := "Chart Type"::"Stacked Column";
                Insert;
            end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        SalesHeader: Record "Sales Header";
        ToDate: Date;
        Measure: Integer;
    begin
        Measure := BusChartBuf."Drill-Down Measure Index";
        if (Measure < 0) or (Measure > 3) then
            exit;
        TrailingSalesOrdersSetup.Get(UserId);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            SalesHeader.SetFilter("Shipment Date", '<%1', TrailingSalesOrdersSetup.GetStartDate);
        if Evaluate(SalesHeader.Status, BusChartBuf.GetMeasureValueString(Measure), 9) then
            SalesHeader.SetRange(Status, SalesHeader.Status);

        ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
        SalesHeader.SetRange("Document Date", 0D, ToDate);
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;

    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer")
    var
        ChartToStatusMap: array[4] of Integer;
        ToDate: array[5] of Date;
        FromDate: array[5] of Date;
        Value: Decimal;
        TotalValue: Decimal;
        ColumnNo: Integer;
        SalesHeaderStatus: Integer;
    begin
        TrailingSalesOrdersSetup.Get(UserId);
        with BusChartBuf do begin
            Initialize;
            "Period Length" := TrailingSalesOrdersSetup."Period Length";
            SetPeriodXAxis;

            CreateMap(ChartToStatusMap);
            for SalesHeaderStatus := 1 to ArrayLen(ChartToStatusMap) do begin
                SalesHeader.Status := ChartToStatusMap[SalesHeaderStatus];
                AddMeasure(Format(SalesHeader.Status), SalesHeader.Status, "Data Type"::Decimal, TrailingSalesOrdersSetup.GetChartType);
            end;

            if CalcPeriods(FromDate, ToDate, BusChartBuf) then begin
                AddPeriods(ToDate[1], ToDate[ArrayLen(ToDate)]);

                for SalesHeaderStatus := 1 to ArrayLen(ChartToStatusMap) do begin
                    TotalValue := 0;
                    for ColumnNo := 1 to ArrayLen(ToDate) do begin
                        Value := GetSalesOrderValue(ChartToStatusMap[SalesHeaderStatus], FromDate[ColumnNo], ToDate[ColumnNo]);
                        if ColumnNo = 1 then
                            TotalValue := Value
                        else
                            TotalValue += Value;
                        SetValueByIndex(SalesHeaderStatus - 1, ColumnNo - 1, TotalValue);
                    end;
                end;
            end;
        end;
    end;

    local procedure CalcPeriods(var FromDate: array[5] of Date; var ToDate: array[5] of Date; var BusChartBuf: Record "Business Chart Buffer"): Boolean
    var
        MaxPeriodNo: Integer;
        i: Integer;
    begin
        MaxPeriodNo := ArrayLen(ToDate);
        ToDate[MaxPeriodNo] := TrailingSalesOrdersSetup.GetStartDate;
        if ToDate[MaxPeriodNo] = 0D then
            exit(false);
        for i := MaxPeriodNo downto 1 do begin
            if i > 1 then begin
                FromDate[i] := BusChartBuf.CalcFromDate(ToDate[i]);
                ToDate[i - 1] := FromDate[i] - 1;
            end else
                FromDate[i] := 0D
        end;
        exit(true);
    end;

    local procedure GetSalesOrderValue(Status: Option; FromDate: Date; ToDate: Date): Decimal
    begin
        if TrailingSalesOrdersSetup."Value to Calculate" = TrailingSalesOrdersSetup."Value to Calculate"::"No. of Orders" then
            exit(GetSalesOrderCount(Status, FromDate, ToDate));
        exit(GetSalesOrderAmount(Status, FromDate, ToDate));
    end;

    local procedure GetSalesOrderAmount(Status: Option; FromDate: Date; ToDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        TrailingSalesOrderQry: Query "Trailing Sales Order Qry";
        Amount: Decimal;
        TotalAmount: Decimal;
    begin
        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            TrailingSalesOrderQry.SetFilter(ShipmentDate, '<%1', TrailingSalesOrdersSetup.GetStartDate);

        TrailingSalesOrderQry.SetRange(Status, Status);
        TrailingSalesOrderQry.SetRange(DocumentDate, FromDate, ToDate);
        TrailingSalesOrderQry.Open;
        while TrailingSalesOrderQry.Read do begin
            if TrailingSalesOrderQry.CurrencyCode = '' then
                Amount := TrailingSalesOrderQry.Amount
            else
                Amount := Round(TrailingSalesOrderQry.Amount / CurrExchRate.ExchangeRate(Today, TrailingSalesOrderQry.CurrencyCode));
            TotalAmount := TotalAmount + Amount;
        end;
        exit(TotalAmount);
    end;

    local procedure GetSalesOrderCount(Status: Option; FromDate: Date; ToDate: Date): Decimal
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            SalesHeader.SetFilter("Shipment Date", '<%1', TrailingSalesOrdersSetup.GetStartDate)
        else
            SalesHeader.SetRange("Shipment Date");
        SalesHeader.SetRange(Status, Status);
        SalesHeader.SetRange("Document Date", FromDate, ToDate);
        exit(SalesHeader.Count);
    end;

    procedure CreateMap(var Map: array[4] of Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        Map[1] := SalesHeader.Status::Released;
        Map[2] := SalesHeader.Status::"Pending Prepayment";
        Map[3] := SalesHeader.Status::"Pending Approval";
        Map[4] := SalesHeader.Status::Open;
    end;
}

