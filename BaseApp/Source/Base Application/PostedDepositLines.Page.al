page 10148 "Posted Deposit Lines"
{
    Caption = 'Posted Deposit Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Deposit Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Deposit No."; "Deposit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the deposit document.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type from which the deposit was received.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number from which the deposit was received.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction on the deposit line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the document (usually a check) that was deposited.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document (usually a check) that was deposited.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit line.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit line.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number from the general ledger account entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    RunObject = Page "Posted Deposit List";
                    RunPageLink = "No." = FIELD("Deposit No.");
                    ToolTip = 'View the document that the deposit is related to.';
                }
                action("Account &Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account &Card';
                    Image = Account;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountCard;
                    end;
                }
                action("Account Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Ledger E&ntries';
                    Image = LedgerEntries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View ledger entries that are posted for the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountLedgerEntries;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
            }
        }
    }
}

