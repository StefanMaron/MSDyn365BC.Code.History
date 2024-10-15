page 11745 "Cash Desk Card"
{
    Caption = 'Cash Desk Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Bank Account";
    SourceTableView = WHERE("Account Type" = CONST("Cash Desk"));

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the cash document.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of cash desk.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the another line for name if name is longer.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of cash desk.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the another line for address if address is longer.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of cash desk.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee contacted with cash desk.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the cash desk.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to block the cash desk by placing a check mark in the check box.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the cash desk card was last modified.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the phone number associated with the cash desk card.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number associated with the cash desk card.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the e-mail address associated with the cash desk card.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s home page address.';
                }
            }
            group(Responsibility)
            {
                Caption = 'Responsibility';
                field("Cashier No."; "Cashier No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the cashier number from employee list.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the responsibility center which works with this cash desk.';
                }
                field("Payed To/By Checking"; "Payed To/By Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to check for filling payed to/by checking in the cash desk document.';
                }
                field("Responsibility ID (Release)"; "Responsibility ID (Release)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the responsibility ID for release from employee list.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Responsibility ID (Post)"; "Responsibility ID (Post)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the responsibility ID for posting from employee list.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Confirm Inserting of Document"; "Confirm Inserting of Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies confirming inserting of document automaticaly or with message.';
                }
                field("Amounts Including VAT"; "Amounts Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Bank Acc. Posting Group"; "Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Desk Posting Group';
                    ToolTip = 'Specifies the posting group for cash desk.';
                }
                field("Debit Rounding Account"; "Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for debit rounding.';
                }
                field("Credit Rounding Account"; "Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for credit rounding.';
                }
                field("Rounding Method Code"; "Rounding Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of rounding method in the cash desk document.';
                }
                field("Allow VAT Difference"; "Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in cash documents.';
                }
                field("Exclude from Exch. Rate Adj."; "Exclude from Exch. Rate Adj.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether entries will be excluded from exchange rates adjustment.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code associated with the cash desk.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code associated with the cash desk.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code on the entry.';
                }
            }
            group(Limits)
            {
                Caption = 'Limits';
                field("Cash Receipt Limit"; "Cash Receipt Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum limit for cash receipt.';
                }
                field("Max. Balance Checking"; "Max. Balance Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup possibility to maximum balance check.';
                }
                field("Max. Balance"; "Max. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the value of maximum balance.';
                }
                field("Cash Withdrawal Limit"; "Cash Withdrawal Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum limit for cash withdrawal.';
                }
                field("Min. Balance Checking"; "Min. Balance Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup possibility to minimum balance check.';
                }
                field("Min. Balance"; "Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the value of minimun balance.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Cash Document Receipt Nos."; "Cash Document Receipt Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the receipt number series in cash document.';
                }
                field("Cash Document Withdrawal Nos."; "Cash Document Withdrawal Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the withdrawal number series in cash document.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cash Desk")
            {
                Caption = '&Cash Desk';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Cash Desk Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'Show the total receipts and withdrawals in cash desk.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'Specifies cash desk comments.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(270),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Shift+Ctrl+D';
                        ToolTip = 'Allows to setup dimensions.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'Allows to setup multiple dimensions.';

                        trigger OnAction()
                        var
                            BankAcc: Record "Bank Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(BankAcc);
                            DefaultDimMultiple.SetMultiRecord(BankAcc, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'Show the cash desk balance during the period.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Show the cash desk ledger entries.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'The function creates contact card or Specifies created contact card for cash desk.';

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Opened Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Opened Cash Documents';
                    Image = Document;
                    RunObject = Page "Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    RunPageView = WHERE(Status = CONST(Open));
                    ToolTip = 'Show the overview of opened cash documents.';
                }
                action("Released Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Released Cash Documents';
                    Image = Confirm;
                    RunObject = Page "Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    RunPageView = WHERE(Status = CONST(Released));
                    ToolTip = 'Show the overview of released cash documents.';
                }
                action("Posted Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Cash Documents';
                    Image = PostDocument;
                    RunObject = Page "Posted Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    ToolTip = 'Show the overview of posted cash documents.';
                }
            }
        }
        area(creation)
        {
            action("Cash &Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash &Document';
                Image = Document;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Cash Document";
                RunPageLink = "Cash Desk No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new cash document.';
            }
        }
        area(reporting)
        {
            action(Cashbook)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cashbook';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Open the report for cash desk entries during the period.';

                trigger OnAction()
                var
                    BankAccount: Record "Bank Account";
                begin
                    BankAccount := Rec;
                    BankAccount.SetRecFilter;
                    REPORT.RunModal(REPORT::"Cash Desk Book", true, false, BankAccount);
                end;
            }
            action("Cash Inventory")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Inventory';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Open the report for cash inventory.';

                trigger OnAction()
                var
                    CashInventory: Report "Cash Inventory";
                begin
                    CashInventory.SetParameters("No.");
                    CashInventory.RunModal;
                end;
            }
        }
    }
}

