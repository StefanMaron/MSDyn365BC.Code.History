#if CLEAN17
enum 1370 "Batch Posting Parameter Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Invoice") { Caption = 'Invoice'; }
    value(1; "Ship") { Caption = 'Ship'; }
    value(2; "Receive") { Caption = 'Receive'; }
    value(3; "Posting Date") { Caption = 'Posting Date'; }
    value(4; "Replace Posting Date") { Caption = 'Replace Posting Date'; }
    value(5; "Replace Document Date") { Caption = 'Replace Document Date'; }
    value(6; "Calculate Invoice Discount") { Caption = 'Calculate Invoice Discount'; }
    value(7; "Print") { Caption = 'Print'; }
}
#endif