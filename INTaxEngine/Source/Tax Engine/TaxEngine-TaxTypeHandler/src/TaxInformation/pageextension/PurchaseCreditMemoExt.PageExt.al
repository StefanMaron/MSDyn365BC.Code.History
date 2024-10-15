pageextension 20249 "Purchase Credit Memo Ext" extends "Purchase Credit Memo"
{
    layout
    {
        addbefore(Control1900383207)
        {
            part("Tax Information"; "Tax Information Factbox")
            {
                ApplicationArea = Basic, Suite;
                Provider = PurchLines;
                SubPageLink = "Table ID Filter" = const(39), "Document Type Filter" = field("Document Type"), "Document No. Filter" = field("Document No."), "Line No. Filter" = field("Line No.");
            }
        }
    }
}