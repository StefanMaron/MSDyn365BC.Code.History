report 5854 "Roll Up Standard Cost"
{
    Caption = 'Roll Up Standard Cost';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Costing Method";

            trigger OnPostDataItem()
            begin
                if not NoMessage then
                    if RolledUp then
                        Message(Text000)
                    else
                        Message(Text001);
            end;

            trigger OnPreDataItem()
            begin
                StdCostWksh.LockTable();
                Clear(CalcStdCost);
                CalcStdCost.SetProperties(CalculationDate, true, false, false, ToStdCostWkshName, true);
                CalcStdCost.CalcItems(Item, TempItem);

                TempItem.SetFilter("Replenishment System", '%1|%2',
                  TempItem."Replenishment System"::"Prod. Order",
                  TempItem."Replenishment System"::Assembly);
                if TempItem.Find('-') then
                    repeat
                        UpdateStdCostWksh();
                        RolledUp := true;
                    until TempItem.Next() = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculationDate; CalculationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date you want the cost shares to be calculated.';

                        trigger OnValidate()
                        begin
                            if CalculationDate = 0D then
                                Error(Text002);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CalculationDate = 0D then
                CalculationDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
    begin
        RolledUp := false;

        if ToStdCostWkshName = '' then
            Error(Text003);
        StdCostWkshName.Get(ToStdCostWkshName);
    end;

    var
        TempItem: Record Item temporary;
        StdCostWksh: Record "Standard Cost Worksheet";
        CalcStdCost: Codeunit "Calculate Standard Cost";
        CalculationDate: Date;
        ToStdCostWkshName: Code[10];
        RolledUp: Boolean;
        Text000: Label 'The standard costs have been rolled up successfully.';
        Text001: Label 'There is nothing to roll up.';
        Text002: Label 'You must enter a calculation date.';
        Text003: Label 'You must specify a worksheet name to roll up to.';
        NoMessage: Boolean;

    local procedure UpdateStdCostWksh()
    var
        Found: Boolean;
    begin
        with StdCostWksh do begin
            Found := Get(ToStdCostWkshName, Type::Item, TempItem."No.");
            Validate("Standard Cost Worksheet Name", ToStdCostWkshName);
            Validate(Type, Type::Item);
            Validate("No.", TempItem."No.");
            "New Standard Cost" := TempItem."Standard Cost";

            "New Single-Lvl Material Cost" := TempItem."Single-Level Material Cost";
            "New Single-Lvl Cap. Cost" := TempItem."Single-Level Capacity Cost";
            "New Single-Lvl Subcontrd Cost" := TempItem."Single-Level Subcontrd. Cost";
            "New Single-Lvl Cap. Ovhd Cost" := TempItem."Single-Level Cap. Ovhd Cost";
            "New Single-Lvl Mfg. Ovhd Cost" := TempItem."Single-Level Mfg. Ovhd Cost";

            "New Rolled-up Material Cost" := TempItem."Rolled-up Material Cost";
            "New Rolled-up Cap. Cost" := TempItem."Rolled-up Capacity Cost";
            "New Rolled-up Subcontrd Cost" := TempItem."Rolled-up Subcontracted Cost";
            "New Rolled-up Cap. Ovhd Cost" := TempItem."Rolled-up Cap. Overhead Cost";
            "New Rolled-up Mfg. Ovhd Cost" := TempItem."Rolled-up Mfg. Ovhd Cost";
            OnUpdateStdCostWkshOnAfterFieldsPopulated(StdCostWksh, TempItem);

            if Found then
                Modify(true)
            else
                Insert(true);
        end;
    end;

    procedure SetStdCostWksh(NewStdCostWkshName: Code[10])
    begin
        ToStdCostWkshName := NewStdCostWkshName;
    end;

    procedure Initialize(StdCostWkshName2: Code[10]; NoMessage2: Boolean)
    begin
        ToStdCostWkshName := StdCostWkshName2;
        NoMessage := NoMessage2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStdCostWkshOnAfterFieldsPopulated(var StdCostWksh: Record "Standard Cost Worksheet"; TempItem: Record Item temporary)
    begin
    end;
}

