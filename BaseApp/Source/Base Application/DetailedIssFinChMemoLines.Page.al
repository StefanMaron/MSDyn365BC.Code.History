page 11788 "Detailed Iss.Fin.Ch.Memo Lines"
{
    Caption = 'Detailed Iss.Fin.Ch.Memo Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Iss.Fin.Ch. Memo Line";

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                ShowCaption = false;
                field("Fin. Charge. Memo Line No."; "Fin. Charge. Memo Line No.")
                {
                    ToolTip = 'Specifies the number line of the finance charge memo.';
                    Visible = false;
                }
                field("Finance Charge Memo No."; "Finance Charge Memo No.")
                {
                    ToolTip = 'Specifies the number of the finance charge memo.';
                    Visible = false;
                }
                field("Detailed Customer Entry No."; "Detailed Customer Entry No.")
                {
                    ToolTip = 'Specifies the number of detailed customer entry.';
                    Visible = false;
                }
                field("Line No."; "Line No.")
                {
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer ledger entry this finance charge memos line is for.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("Base Amount"; "Base Amount")
                {
                    ToolTip = 'Specifies the base amount of the issued finance charge memo.';
                    Visible = false;
                }
                field(Days; Days)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of finance charge memo days.';
                }
                field("Interest Rate"; "Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Amount"; "Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the interest amounts on the finance charge memo lines.';
                }
                field("Interest Base Amount"; "Interest Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interest base amount.';
                }
            }
        }
    }

    actions
    {
    }
}

