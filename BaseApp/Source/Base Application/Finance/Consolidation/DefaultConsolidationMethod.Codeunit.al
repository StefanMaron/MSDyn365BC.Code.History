namespace Microsoft.Finance.Consolidation;

codeunit 434 "Default Consolidation Method" implements "Consolidation Method"
{
    procedure Consolidate(ConsolidationProcess: Record "Consolidation Process"; BusinessUnit: Record "Business Unit"; var BusUnitConsolidationData: Record "Bus. Unit Consolidation Data");
    var
        ConsolidateData: Codeunit Consolidate;
    begin
        BusUnitConsolidationData.GetConsolidate(ConsolidateData);
        ConsolidateData.Run(BusinessUnit);
    end;
}