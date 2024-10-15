namespace Microsoft.Finance.Consolidation;

table 141 "Bus. Unit Consolidation Data"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Consolidation Process Id"; Integer)
        {
        }
        field(2; "Business Unit Code"; Code[20])
        {
        }
    }

    var
        Consolidate: Codeunit Consolidate;

    procedure GetConsolidate(var ConsolidateToGet: Codeunit Consolidate)
    begin
        ConsolidateToGet := Consolidate;
    end;

    procedure SetConsolidate(var ConsolidateToSet: Codeunit Consolidate)
    begin
        Consolidate := ConsolidateToSet;
    end;


}