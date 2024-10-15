pageextension 18006 "GST Inventory Setup Ext" extends "Inventory Setup"
{
    layout
    {
        addlast(Numbering)
        {
            field("Service Transfer Order Nos."; "Service Transfer Order Nos.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number series that will be used to assign numbers to service transfer orders.';
            }
            field("Posted Serv. Trans. Rcpt. Nos."; "Posted Serv. Trans. Rcpt. Nos.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number series that will be used to assign numbers to posted service transfer receipts.';
            }
            field("Posted Serv. Trans. Shpt. Nos."; "Posted Serv. Trans. Shpt. Nos.")
            {
                ApplicationArea = Basic, Suite;	
				ToolTip = 'Specifies the number series that will be used to assign numbers to posted service transfer shipments.';
            }
        }
    }
}