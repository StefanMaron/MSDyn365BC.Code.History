namespace Microsoft.Inventory.Location;

using Microsoft.Service.Contract;

tableextension 6455 "Serv. Responsibility Center" extends "Responsibility Center"
{
    fields
    {
        field(5901; "Contract Gain/Loss Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Contract Gain/Loss Entry".Amount where("Responsibility Center" = field(Code),
                                                                       "Change Date" = field("Date Filter")));
            Caption = 'Contract Gain/Loss Amount';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}