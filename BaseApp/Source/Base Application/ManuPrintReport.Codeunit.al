codeunit 99000817 "Manu. Print Report"
{

    trigger OnRun()
    begin
    end;

    var
        ReportSelection: Record "Report Selections";
        ProductionOrder: Record "Production Order";

    procedure PrintProductionOrder(NewProductionOrder: Record "Production Order"; Usage: Option)
    begin
        ProductionOrder := NewProductionOrder;
        ProductionOrder.SetRecFilter;

        ReportSelection.PrintWithCheck(ConvertUsage(Usage), ProductionOrder, 0);
    end;

    local procedure ConvertUsage(Usage: Option M1,M2,M3,M4): Integer
    begin
        case Usage of
            Usage::M1:
                exit(ReportSelection.Usage::M1);
            Usage::M2:
                exit(ReportSelection.Usage::M2);
            Usage::M3:
                exit(ReportSelection.Usage::M3);
            Usage::M4:
                exit(ReportSelection.Usage::M4);
        end;
    end;
}

