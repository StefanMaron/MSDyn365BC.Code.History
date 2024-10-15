page 12190 "Vendor Bill List Sent Card"
{
    Caption = 'Vendor Bill List Sent Card';
    PageType = Card;
    SourceTable = "Vendor Bill Header";
    SourceTableView = WHERE("List Status" = CONST(Sent));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        AssistEdit(xRec);
                    end;
                }
                field("Vendor Bill List No."; "Vendor Bill List No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor bill list identification number.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you want the bill header to be posted.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created .';
                }
                field("Beneficiary Value Date"; "Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
                }
            }
            part(VendBillLinesSent; "Subform Sent Vendor Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Vendor Bill List No." = FIELD("No.");
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
                    Editable = false;
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
                }
            }
        }
        area(factboxes)
        {
            part("Payment Journal Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = VendBillLinesSent;
                SubPageLink = "Journal Template Name" = CONST(''),
                              "Journal Batch Name" = CONST(''),
                              "Document No." = FIELD("Vendor Bill List No."),
                              "Journal Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Vend. Bill")
            {
                Caption = '&Vend. Bill';
                Image = VendorBill;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    RunObject = Page "List of Sent Vendor Bills";
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View the list of all documents.';
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = FIELD("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ExportBillListToFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Bill List to File';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'View the releated export bill list to file.';

                    trigger OnAction()
                    begin
                        ExportToFile;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Vendor Bill List - Post";
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the document.';
                }
            }
            action(CancelList)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Cancel List';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Cancel the changes to the list of sent vendor bills.';

                trigger OnAction()
                begin
                    VendBillListChangeStatus.FromSentToOpen(Rec);
                    CurrPage.Update();
                end;
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the list of vendor bills.';

                trigger OnAction()
                begin
                    SetRecFilter;
                    REPORT.RunModal(REPORT::"Vendor Bill Report", true, false, Rec);
                    SetRange("No.");
                end;
            }
        }
        area(reporting)
        {
            action("Vendor Bills List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Bills List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor Bill Report";
                ToolTip = 'View the list of vendor bills.';
            }
        }
    }

    var
        VendBillListChangeStatus: Codeunit "Vend. Bill List-Change Status";
}

