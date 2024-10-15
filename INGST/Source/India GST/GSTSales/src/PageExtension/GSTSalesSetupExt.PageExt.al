pageextension 18156 "GST Sales Setup Ext" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast("general")
        {
            field("GST Dependency Type"; "GST Dependency Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST calculation dependency mentioned in sales and receivable setup.';
            }
        }
        addafter("Number Series")
        {
            group(GST)
            {
                field("Posted Inv. Nos. (Exempt)"; "Posted Inv. Nos. (Exempt)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted invoices where invoice type is exempt.';
                    Visible = false;
                }
                field("Posted Cr. Memo Nos. (Exempt)"; "Posted Cr. Memo Nos. (Exempt)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted credit memos where invoice type is exempt.';
                    Visible = false;
                }
                field("Posted Inv. No. (Export)"; "Posted Inv. No. (Export)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted invoices where invoice type is export.';
                    Visible = false;
                }
                field("Posted Cr. Memo No. (Export)"; "Posted Cr. Memo No. (Export)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted credit memos where invoice type is export.';
                    Visible = false;
                }
                field("Posted Inv. No. (Supp)"; "Posted Inv. No. (Supp)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted invoices where invoice type is supplementary.';
                    Visible = false;
                }
                field("Posted Cr. Memo No. (Supp)"; "Posted Cr. Memo No. (Supp)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted credit memos where invoice type is supplementary.';
                    Visible = false;
                }
                field("Posted Inv. No. (Debit Note)"; "Posted Inv. No. (Debit Note)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted invoices where invoice type is debit note.';
                    Visible = false;
                }
                field("Posted Inv. No. (Non-GST)"; "Posted Inv. No. (Non-GST)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted invoices where invoice type is Non-GST.';
                    Visible = false;
                }
                field("Posted Cr. Memo No. (Non-GST)"; "Posted Cr. Memo No. (Non-GST)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for posted credit memos where invoice type is Non-GST.';
                    Visible = false;
                }
            }
        }
    }
}