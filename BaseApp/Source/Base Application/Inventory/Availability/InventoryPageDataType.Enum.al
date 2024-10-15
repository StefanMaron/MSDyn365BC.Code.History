﻿namespace Microsoft.Inventory.Availability;

enum 5531 "Inventory Page Data Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Purchase)
    {
        Caption = 'Purchase';
    }
    value(2; Sale)
    {
        Caption = 'Sale';
    }
    value(3; "Purch. Return")
    {
        Caption = 'Purch. Return';
    }
    value(4; "Sales Return")
    {
        Caption = 'Sales Return';
    }
    value(5; Transfer)
    {
        Caption = 'Transfer';
    }
    value(6; Component)
    {
        Caption = 'Component';
    }
    value(7; Production)
    {
        Caption = 'Production';
    }
    value(8; Service)
    {
        Caption = 'Service';
    }
    value(9; Job)
    {
        Caption = 'Job';
    }
    value(10; Forecast)
    {
        Caption = 'Forecast';
    }
    value(11; "Blanket Sales Order")
    {
        Caption = 'Blanket Sales Order';
    }
    value(12; Plan)
    {
        Caption = 'Plan';
    }
    value(13; "Plan Revert")
    {
        Caption = 'Plan Revert';
    }
    value(14; "Assembly Order")
    {
        Caption = 'Assembly Order';
    }
    value(15; "Assembly Component")
    {
        Caption = 'Assembly Component';
    }
}
