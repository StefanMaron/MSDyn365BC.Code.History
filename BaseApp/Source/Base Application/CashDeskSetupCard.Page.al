page 11751 "Cash Desk Setup Card"
{
    Caption = 'Cash Desk Setup Card';
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
                    ToolTip = 'Specifies the No. of the cash desk you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the cash desk.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional name of the cash desk.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the place where the cash desk is located.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the place where the cash desk is located.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the cash desk employee regularly contacted in connection with this cash desk.';
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
                    ToolTip = 'Specifies the date when the Cash Desk Card was last modified.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the telephone number of the place where the cash desk is located.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number of the place where the cash desk is located.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the email address associated with the cash desk.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the home page address associated with the cash desk.';
                }
            }
            group(Responsibility)
            {
                Caption = 'Responsibility';
                field("Cashier No."; "Cashier No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee responsible for cash desk.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the responsibility center that will administer this cash desk by default.';
                }
                field("Payed To/By Checking"; "Payed To/By Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level of checking payed to or payed by fields from cash document.';
                }
                field("Responsibility ID (Release)"; "Responsibility ID (Release)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the user responsible for releasing the documents.';

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
                    ToolTip = 'Specifies the user responsible for posting the documents.';

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
                    ToolTip = 'Specifies the relevant currency code for the cash desk.';
                }
                field("Confirm Inserting of Document"; "Confirm Inserting of Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that confirmation is required if you are creating a cash document.';
                }
                field("Amounts Including VAT"; "Amounts Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether amounts are including VAT.';
                }
                field("Bank Acc. Posting Group"; "Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Desk Posting Group';
                    ToolTip = 'Specifies a code for the cash desk posting group for the cash desk.';
                }
                field("Debit Rounding Account"; "Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post rounding differences from remaining amount.';
                }
                field("Credit Rounding Account"; "Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post rounding differences from remaining amount.';
                }
                field("Rounding Method Code"; "Rounding Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of rounding method.';
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
                    ToolTip = 'Specifies the dimension value code for the global dimension 1 you have assigned to the cash desk.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code for the global dimension 2 you have assigned to the cash desk.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code linked to the cash desk.';
                }
            }
            group(Limits)
            {
                Caption = 'Limits';
                field("Cash Receipt Limit"; "Cash Receipt Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the limit of cash document receipt.';
                }
                field("Max. Balance Checking"; "Max. Balance Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level of checking maximal balance of cash document.';
                }
                field("Max. Balance"; "Max. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the maximal balance of cash document.';
                }
                field("Cash Withdrawal Limit"; "Cash Withdrawal Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the limit of cash document withdrawal.';
                }
                field("Min. Balance Checking"; "Min. Balance Checking")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level of checking minimal balance from cash document.';
                }
                field("Min. Balance"; "Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the minimal balance of cash document.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Cash Document Receipt Nos."; "Cash Document Receipt Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to cash document receipt.';
                }
                field("Cash Document Withdrawal Nos."; "Cash Document Withdrawal Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to cash document withdrawal.';
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
                    ToolTip = 'View the statistics on the selected cash desk.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments.';
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
                        ToolTip = 'View or edit the dimensions single sets that are set up for the current dimensions.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit the dimensions multiple sets that are set up for the current dimensions.';

                        trigger OnAction()
                        var
                            BankAcc: Record "Bank Account";
                            DefaultDimensionsMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(BankAcc);
                            DefaultDimensionsMultiple.SetMultiRecord(BankAcc, FieldNo("No."));
                            DefaultDimensionsMultiple.RunModal;
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
                    ToolTip = 'View a summary of the cash desk balance at different periods.';
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
                    ToolTip = 'View the bank account ledger entries for the current cash desk.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'View or edit detailed information about the contact person at the cash desk.';

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
                    ToolTip = 'View an opened cash document of the current cash desk.';
                }
                action("Released Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Released Cash Documents';
                    Image = Confirm;
                    RunObject = Page "Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    RunPageView = WHERE(Status = CONST(Released));
                    ToolTip = 'View an released cash document of the current cash desk.';
                }
                action("Posted Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Cash Documents';
                    Image = PostDocument;
                    RunObject = Page "Posted Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    ToolTip = 'View an posted cash document of the current cash desk.';
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
                ToolTip = 'Create a cash document for the cash desk.';
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
                ToolTip = 'View, print, or save the cash book of the current cash desk.';

                trigger OnAction()
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
                ToolTip = 'View, print, or save the cash inventory of the current cash desk.';

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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Insert(true);

        if GetFilterNo <> '' then
            SetFilterNo(StrSubstNo('%1|%2', GetFilterNo, "No."))
        else
            SetFilterNo("No.");

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "No." := '';
        "Account Type" := "Account Type"::"Cash Desk";
    end;

    trigger OnOpenPage()
    begin
        CashDeskMgt.CheckCashDesk("No.");
        SetFilterNo(CashDeskMgt.GetCashDesksFilter);
    end;

    var
        BankAccount: Record "Bank Account";
        CashDeskMgt: Codeunit CashDeskManagement;

    local procedure GetFilterNo(): Text[1024]
    var
        "Filter": Text;
    begin
        FilterGroup(2);
        Filter := GetFilter("No.");
        FilterGroup(0);
        exit(Filter);
    end;

    local procedure SetFilterNo(FilterNo: Text)
    begin
        FilterGroup(2);
        if FilterNo <> '' then
            SetFilter("No.", FilterNo);
        FilterGroup(0);
        CurrPage.Update(false);
    end;
}

