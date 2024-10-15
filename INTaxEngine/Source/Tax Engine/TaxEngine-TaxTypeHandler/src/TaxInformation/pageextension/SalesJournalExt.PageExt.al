pageextension 20257 "Sales Journal Ext" extends "Sales Journal"
{
    layout
    {
        addbefore(IncomingDocAttachFactBox)
        {
            part(TaxInformation; "Tax Information Factbox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Table ID Filter" = const(81), "Template Name Filter" = field("Journal Template Name"), "Batch Name Filter" = field("Journal Batch Name"), "Line No. Filter" = field("Line No.");
            }
        }
    }
}