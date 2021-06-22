table 99000851 "Production Forecast Name"
{
    Caption = 'Demand Forecast Name';
    DrillDownPageID = "Demand Forecast Names";
    LookupPageID = "Demand Forecast Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdForecastEntry: Record "Production Forecast Entry";
    begin
        ProdForecastEntry.SetRange("Production Forecast Name", Name);
        if not ProdForecastEntry.IsEmpty then begin
            if GuiAllowed then
                if not Confirm(Confirm001Qst, true, Name) then
                    Error('');
            ProdForecastEntry.DeleteAll();
        end;
    end;

    var
        Confirm001Qst: Label 'Demand forecast %1 has entries. Do you want to delete it anyway?', Comment = '%1 = forecast name';
}

