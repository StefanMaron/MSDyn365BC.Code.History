codeunit 6310 "PBI Top Opportunities Calc."
{

    trigger OnRun()
    begin
    end;

    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        CalcTopFiveOpportunities(TempOpportunity);
        TempOpportunity.SetAutoCalcFields("Estimated Value (LCY)");
        if TempOpportunity.FindSet then
            repeat
                InsertToBuffer(TempPowerBIChartBuffer, TempOpportunity);
            until TempOpportunity.Next = 0;
    end;

    local procedure CalcTopFiveOpportunities(var TempOpportunity: Record Opportunity temporary)
    var
        Opportunity: Record Opportunity;
    begin
        TempOpportunity.DeleteAll();
        Opportunity.SetAutoCalcFields("Estimated Value (LCY)");
        Opportunity.SetRange(Closed, false);
        Opportunity.SetCurrentKey("Estimated Value (LCY)");
        Opportunity.Ascending(false);
        if Opportunity.FindSet then
            repeat
                TempOpportunity := Opportunity;
                TempOpportunity.Insert();
            until Opportunity.Next = 0;
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; TempOpportunity: Record Opportunity temporary)
    begin
        with TempPowerBIChartBuffer do begin
            if FindLast then
                ID += 1
            else
                ID := 1;
            Value := TempOpportunity."Estimated Value (LCY)";
            "Measure Name" := TempOpportunity.Description;
            "Measure No." := TempOpportunity."No.";
            Insert;
        end;
    end;
}

