pageextension 20255 "Sales Credit Memo Extension" extends "Sales Credit Memo"
{
    layout
    {
        addbefore(Control1900383207)
        {
            part("Tax Information"; "Tax Information Factbox")
            {
                ApplicationArea = Basic, Suite;
                Provider = SalesLines;
                SubPageLink = "Table ID Filter" = const(37), "Document Type Filter" = field("Document Type"), "Document No. Filter" = field("Document No."), "Line No. Filter" = field("Line No.");
            }
        }
    }
}