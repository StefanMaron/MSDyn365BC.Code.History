page 12192 "Posted Vendor Bill Card"
{
    Caption = 'Posted Vendor Bill Card';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Vendor Bill Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted bill number.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the vendor bill was posted.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the vendor bill was created.';
                }
                field("Beneficiary Value Date"; "Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Bank Expense"; "Bank Expense")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any expenses or fees that are charged by the bank for the bank transfer.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the sum of the amounts in the Amount to Pay fields on the related posted vendor bill lines.';
                }
            }
            part(SubformPostedVendBillLines; "Subform Posted Vend Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Vendor Bill No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for the vendor bill.';
                }
                field("Report Header"; "Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code used to calculate the amounts on the bill.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the vendor bill.';

                trigger OnAction()
                begin
                    SetRecFilter;
                    REPORT.RunModal(REPORT::"Issued Vendor Bill List", true, false, Rec);
                    SetRange("No.");
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
        area(reporting)
        {
            action("Issued Vendor Bill List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Vendor Bill List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Issued Vendor Bill List";
                ToolTip = 'View the releated issued vendor bill list.';
            }
        }
    }
}

