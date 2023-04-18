codeunit 6309 "PBI Sales Pipeline Chart Calc."
{

    trigger OnRun()
    begin
    end;

    var
        SalesPipelineChartMgt: Codeunit "Sales Pipeline Chart Mgt.";

    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    var
        TempSalesCycleStage: Record "Sales Cycle Stage" temporary;
        SalesCycle: Record "Sales Cycle";
    begin
        if SalesCycle.FindSet() then
            repeat
                SalesPipelineChartMgt.InsertTempSalesCycleStage(TempSalesCycleStage, SalesCycle);
                if TempSalesCycleStage.FindSet() then
                    repeat
                        InsertToBuffer(TempPowerBIChartBuffer, TempSalesCycleStage);
                    until TempSalesCycleStage.Next() = 0;
            until SalesCycle.Next() = 0;
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; TempSalesCycleStage: Record "Sales Cycle Stage" temporary)
    begin
        with TempPowerBIChartBuffer do begin
            if FindLast() then
                ID += 1
            else
                ID := 1;
            "Row No." := Format(TempSalesCycleStage.Stage);
            Value := SalesPipelineChartMgt.GetOppEntryCount(TempSalesCycleStage."Sales Cycle Code", TempSalesCycleStage.Stage);
            "Measure Name" := TempSalesCycleStage.Description;
            "Measure No." := TempSalesCycleStage."Sales Cycle Code";
            Insert();
        end;
    end;
}

