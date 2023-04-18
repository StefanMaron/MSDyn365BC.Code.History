codeunit 6306 "PBI Aged Acc. Calc"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        AgedAccPayable: Codeunit "Aged Acc. Payable";
        NoOfPeriods: Integer;
        FormatedPeriod: Text[30];

    [Scope('OnPrem')]
    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; ChartCodeunitID: Integer; ChartName: Text)
    begin
        SetPeriodAndUpdateChart(TempPowerBIChartBuffer, ChartCodeunitID, ChartName);
    end;

    local procedure SetPeriodAndUpdateChart(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; ChartCodeunitID: Integer; ChartName: Text)
    var
        SelectedChartDefinition: Record "Chart Definition";
        LogInManagement: Codeunit LogInManagement;
        ChartManagement: Codeunit "Chart Management";
        i: Integer;
    begin
        if SelectedChartDefinition.Get(ChartCodeunitID, ChartName) then
            for i := 0 to 4 do begin
                BusinessChartBuffer.Reset();
                BusinessChartBuffer.DeleteAll();
                TempEntryNoAmountBuffer.Reset();
                TempEntryNoAmountBuffer.DeleteAll();

                BusinessChartBuffer."Period Length" := i;
                ChartManagement.SetPeriodLength(SelectedChartDefinition, BusinessChartBuffer, BusinessChartBuffer."Period Length", false);
                BusinessChartBuffer."Period Filter Start Date" := LogInManagement.GetDefaultWorkDate();

                case SelectedChartDefinition."Code Unit ID" of
                    CODEUNIT::"Aged Acc. Payable":
                        AgedAccPayable.UpdateData(BusinessChartBuffer, TempEntryNoAmountBuffer);
                    CODEUNIT::"Aged Acc. Receivable":
                        AgedAccReceivable.UpdateDataPerGroup(BusinessChartBuffer, TempEntryNoAmountBuffer);
                end;

                TempEntryNoAmountBuffer.Reset();
                if TempEntryNoAmountBuffer.FindSet() then
                    repeat
                        FormatPeriod();
                        InsertToBuffer(TempPowerBIChartBuffer);
                    until TempEntryNoAmountBuffer.Next() = 0;
            end
    end;

    local procedure FormatPeriod()
    var
        TempEntryNoAmountBuffer2: Record "Entry No. Amount Buffer" temporary;
        PeriodLength: Text[1];
        PeriodOption: Option " ",Next,Previous;
        PeriodIndex: Integer;
    begin
        AgedAccReceivable.InitParameters(BusinessChartBuffer, PeriodLength, NoOfPeriods, TempEntryNoAmountBuffer2);

        with BusinessChartBuffer do begin
            PeriodIndex := TempEntryNoAmountBuffer."Entry No.";
            FormatedPeriod := CopyStr(AgedAccReceivable.FormatColumnName(PeriodIndex, PeriodLength, NoOfPeriods, PeriodOption), 1, 30);
        end;
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    begin
        with TempPowerBIChartBuffer do begin
            if FindLast() then
                ID += 1
            else
                ID := 1;
            Value := TempEntryNoAmountBuffer.Amount;
            "Measure Name" := TempEntryNoAmountBuffer."Business Unit Code";
            Date := FormatedPeriod;
            "Period Type" := BusinessChartBuffer."Period Length";
            "Period Type Sorting" := BusinessChartBuffer."Period Length";
            case "Period Type" of
                BusinessChartBuffer."Period Length"::Day:
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No.";
                BusinessChartBuffer."Period Length"::Week:
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No." * 10;
                BusinessChartBuffer."Period Length"::Month:
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No." * 100;
                BusinessChartBuffer."Period Length"::Quarter:
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No." * 1000;
                BusinessChartBuffer."Period Length"::Year:
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No." * 10000;
                BusinessChartBuffer."Period Length"::"Accounting Period":
                    "Date Sorting" := TempEntryNoAmountBuffer."Entry No." * 100000;
            end;
            if TempEntryNoAmountBuffer."Entry No." = 0 then
                "Date Sorting" := 0;
            if TempEntryNoAmountBuffer."Entry No." = (NoOfPeriods - 1) then
                "Date Sorting" := 1000000;
            Insert();
        end;
    end;
}

