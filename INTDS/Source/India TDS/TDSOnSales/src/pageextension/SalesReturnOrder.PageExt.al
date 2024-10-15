pageextension 18669 "Sales Return Order TDS" extends "Sales Return Order"
{
    layout
    {
        addlast("Tax Info")
        {
            field("TDS Certificate Receivable"; "TDS Certificate Receivable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Selected to allow calculating TDS for the customer.';
            }
        }
    }
}