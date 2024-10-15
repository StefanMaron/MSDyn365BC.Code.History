namespace Microsoft.Warehouse.Journal;

#pragma warning disable AL0659
enum 7311 "Warehouse Journal Source Document"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "") { Caption = ''; }
    value(1; "S. Order") { Caption = 'S. Order'; }
    value(2; "S. Invoice") { Caption = 'S. Invoice'; }
    value(3; "S. Credit Memo") { Caption = 'S. Credit Memo'; }
    value(4; "S. Return Order") { Caption = 'S. Return Order'; }
    value(5; "P. Order") { Caption = 'P. Order'; }
    value(6; "P. Invoice") { Caption = 'P. Invoice'; }
    value(7; "P. Credit Memo") { Caption = 'P. Credit Memo'; }
    value(8; "P. Return Order") { Caption = 'P. Return Order'; }
    value(9; "Inb. Transfer") { Caption = 'Inb. Transfer'; }
    value(10; "Outb. Transfer") { Caption = 'Outb. Transfer'; }
    value(11; "Prod. Consumption") { Caption = 'Prod. Consumption'; }
    value(12; "Item Jnl.") { Caption = 'Item Jnl.'; }
    value(13; "Phys. Invt. Jnl.") { Caption = 'Phys. Invt. Jnl.'; }
    value(14; "Reclass. Jnl.") { Caption = 'Reclass. Jnl.'; }
    value(15; "Consumption Jnl.") { Caption = 'Consumption Jnl.'; }
    value(16; "Output Jnl.") { Caption = 'Output Jnl.'; }
    value(17; "BOM Jnl.") { Caption = 'BOM Jnl.'; }
    value(18; "Serv. Order") { Caption = 'Serv. Order'; }
    value(19; "Job Jnl.") { Caption = 'Project Jnl.'; }
    value(20; "Assembly Consumption") { Caption = 'Assembly Consumption'; }
    value(21; "Assembly Order") { Caption = 'Assembly Order'; }
    value(22; "Job Usage") { Caption = 'Project Usage'; }
}