﻿namespace Microsoft.Inventory.Availability;

enum 99000880 "Order Promising Line Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Sales)
    {
        Caption = 'Sales';
    }
    value(2; "Requisition Line")
    {
        Caption = 'Requisition Line';
    }
    value(3; Purchase)
    {
        Caption = 'Purchase';
    }
    value(4; "Item Journal")
    {
        Caption = 'Item Journal';
    }
    value(5; "BOM Journal")
    {
        Caption = 'BOM Journal';
    }
    value(6; "Item Ledger Entry")
    {
        Caption = 'Item Ledger Entry';
    }
    value(7; "Prod. Order Line")
    {
        Caption = 'Prod. Order Line';
    }
    value(8; "Prod. Order Component")
    {
        Caption = 'Prod. Order Component';
    }
    value(9; "Planning Line")
    {
        Caption = 'Planning Line';
    }
    value(10; "Planning Component")
    {
        Caption = 'Planning Component';
    }
    value(11; Transfer)
    {
        Caption = 'Transfer';
    }
    value(12; "Service Order")
    {
        Caption = 'Service Order';
    }
    value(13; Job)
    {
        Caption = 'Job';
    }
}
