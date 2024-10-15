pageextension 18088 "GST Purchases Setup Ext" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast("Number Series")
        {
            field("Posted Purch. Inv.(Unreg)"; "Posted Purch. Inv.(Unreg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase invoices for unregistered vendor.';
                Visible = false;
            }
            field("Posted Purch Cr. Memo(Unreg)"; "Posted Purch Cr. Memo(Unreg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase credit memo for unregistered vendor.';
                Visible = false;
            }
            field("Posted Purch Inv.(Unreg Supp)"; "Posted Purch Inv.(Unreg Supp)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase supplementary for unregistered vendor.';
                Visible = false;
            }
            field("Pst. Pur. Inv(Unreg. Deb.Note)"; "Pst. Pur. Inv(Unreg. Deb.Note)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase debit note for unregistered vendor.';
                Visible = false;
            }
            field("GST Liability Adj. Jnl Nos."; "GST Liability Adj. Jnl Nos.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to GST liability journal.';
            }
            field("Purch. Inv. Nos. (Reg)"; "Purch. Inv. Nos. (Reg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase invoices for registered vendors.';
                Visible = false;
            }
            field("Purch. Inv. Nos. (Reg Supp)"; "Purch. Inv. Nos. (Reg Supp)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase Supplementary for registered vendors.';
                Visible = false;
            }
            field("Pur. Inv. Nos.(Reg Deb.Note)"; "Pur. Inv. Nos.(Reg Deb.Note)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase debit note for registered vendors.';
                Visible = false;
            }
            field("Purch. Cr. Memo Nos. (Reg)"; "Purch. Cr. Memo Nos. (Reg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase credit memo for registered vendors.';
                Visible = false;
            }
            field("RCM Exempt start Date (Unreg)"; "RCM Exempt start Date (Unreg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the RCM Exepmt Start Date.';
            }
            field("RCM Exempt End Date (Unreg)"; "RCM Exempt End Date (Unreg)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the RCM Exepmt End Date.';
            }

        }
    }
}