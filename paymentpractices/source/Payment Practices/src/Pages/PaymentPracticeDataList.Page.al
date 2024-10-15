page 686 "Payment Practice Data List"
{
    PageType = List;
    SourceTable = "Payment Practice Data";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Caption = 'Lines';
                Editable = false;

                field("Invoice Entry No."; Rec."Invoice Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the invoice entry number that is the source for this entry.';
                }
                field("Payment Entry No."; Rec."Pmt. Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the closing payment entry number that is associated with the source invoicy entry, if any was applied.';
                }
                field("Invoice Posting Date"; Rec."Invoice Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the invoice entry that is the source for this entry.';
                }
                field("Invoice Received Date"; Rec."Invoice Received Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the invoice was received that is the source for this buffer entry. If empty, the posting date is used.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the due date of the invoice entry that is the source for this entry.';
                }
                field("Pmt. Posting Date"; Rec."Pmt. Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the payment entry that is associated with the source invoicy entry, if any was applied.';
                }
                field("Invoice Is Open"; Rec."Invoice Is Open")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the invoice entry that is the source for this entry is open.';
                }
                field("Invoice Amount"; Rec."Invoice Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the invoice entry that is the source for this entry.';
                }
                field("Company Size Code"; Rec."Company Size Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company size code of the vendor that is the source for this entry.';
                }
                field("Agreed Payment Days"; Rec."Agreed Payment Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of days that was the agreed period for payment for the invoice.';
                }
                field("Actual Payment Days"; Rec."Actual Payment Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of days that was the actual period for payment for the invoice.';
                    Style = Unfavorable;
                    StyleExpr = Rec."Actual Payment Days" > Rec."Agreed Payment Days";
                }
            }
        }
    }
}