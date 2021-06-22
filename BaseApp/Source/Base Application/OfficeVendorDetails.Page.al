page 1621 "Office Vendor Details"
{
    Caption = 'Office Vendor Details';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("Balance (LCY)"; "Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';
            }
            field("Balance Due (LCY)"; "Balance Due (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your unpaid purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all open purchase invoices and credit memos.';
            }
        }
    }

    actions
    {
    }
}

