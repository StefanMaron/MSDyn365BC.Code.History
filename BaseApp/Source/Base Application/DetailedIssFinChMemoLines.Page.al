#if not CLEAN20
page 11788 "Detailed Iss.Fin.Ch.Memo Lines"
{
    Caption = 'Detailed Iss.Fin.Ch.Memo Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Iss.Fin.Ch. Memo Line";
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                ShowCaption = false;
                field("Fin. Charge. Memo Line No."; Rec."Fin. Charge. Memo Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number line of the finance charge memo.';
                    Visible = false;
                }
                field("Finance Charge Memo No."; Rec."Finance Charge Memo No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the finance charge memo.';
                    Visible = false;
                }
                field("Detailed Customer Entry No."; Rec."Detailed Customer Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of detailed customer entry.';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer ledger entry this finance charge memos line is for.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("Base Amount"; Rec."Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount of the issued finance charge memo.';
                    Visible = false;
                }
                field(Days; Days)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of finance charge memo days.';
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Amount"; Rec."Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the interest amounts on the finance charge memo lines.';
                }
                field("Interest Base Amount"; Rec."Interest Base Amount")
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

#endif