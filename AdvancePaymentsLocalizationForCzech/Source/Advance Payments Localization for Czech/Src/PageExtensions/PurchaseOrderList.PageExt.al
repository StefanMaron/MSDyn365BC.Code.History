pageextension 31061 "Purchase Order List CZZ" extends "Purchase Order List"
{
    layout
    {
        addlast(Control1)
        {
            field("Unpaid Advance Letter CZZ"; Rec."Unpaid Advance Letter CZZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if unpaid advance letter exists for this order.';
                Visible = false;
            }
        }
    }

    actions
    {
        modify(PostedPurchasePrepmtInvoices)
        {
            Visible = false;
        }
        modify("Prepayment Credi&t Memos")
        {
            Visible = false;
        }
    }
}
