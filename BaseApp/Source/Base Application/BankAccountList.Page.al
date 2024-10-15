page 371 "Bank Account List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Accounts';
    CardPageID = "Bank Account Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Bank Statement Service,Bank Account,Navigate';
    SourceTable = "Bank Account";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field(OnlineFeedStatementStatus; OnlineFeedStatementStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Linking Status';
                    Editable = false;
                    ToolTip = 'Specifies if the bank account is linked to an online bank account through the bank statement service.';
                    Visible = ShowBankLinkingActions;
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number associated with the address.';
                    Visible = false;
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    Visible = false;
                }
                field("Our Contact Code"; "Our Contact Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to specify the employee who is responsible for this bank account.';
                    Visible = false;
                }
                field("Bank Acc. Posting Group"; "Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Table ID" = CONST(270),
                              "No." = FIELD("No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(PositivePayExport)
                {
                    ApplicationArea = Suite;
                    Caption = 'Positive Pay Export';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Positive Pay Export";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'Export a Positive Pay file with relevant payment information that you then send to the bank for reference when you process payments to make sure that your bank only clears validated checks and amounts.';
                    Visible = false;
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Category5;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(270),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Category5;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

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
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'View a summary of the bank account balance in different periods.';
                }
                action(Statements)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    Image = List;
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    ToolTip = 'View posted bank statements and reconciliations.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = BankAccountLedger;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Chec&k Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.")
                                  ORDER(Descending);
                    ToolTip = 'View check ledger entries that result from posting transactions in a payment journal for the relevant bank account.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'View or edit detailed information about the contact person at the bank.';

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
                separator(Action1100000)
                {
                }
                action("&Operation Fees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Operation Fees';
                    Image = Costs;
                    RunObject = Page "Operation Fees";
                    RunPageLink = Code = FIELD("Operation Fees Code"),
                                  "Currency Code" = FIELD("Currency Code");
                    ToolTip = 'View the various operation fees that banks charge to process the documents that are remitted to them. These operations include collections, discounts, discount interest, rejections, payment orders, unrisked factoring, and risked factoring.';
                }
                action("Customer Ratings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Ratings';
                    Image = CustomerRating;
                    RunObject = Page "Customer Ratings";
                    RunPageLink = Code = FIELD("Customer Ratings Code"),
                                  "Currency Code" = FIELD("Currency Code");
                    ToolTip = 'View or edit the risk percentages that are assigned to customers according to their insolvency risk.';
                }
                action("Sufi&xes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sufi&xes';
                    Image = NumberSetup;
                    RunObject = Page Suffixes;
                    RunPageLink = "Bank Acc. Code" = FIELD("No.");
                    ToolTip = 'View the bank suffixes that area assigned to manage bill groups. Typically, banks assign the company a different suffix for managing bill groups, depending if they are receivable or discount management type operations.';
                }
                separator(Action1100004)
                {
                }
                action("Bill &Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill &Groups';
                    Image = VoucherGroup;
                    RunObject = Page "Bill Groups List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ToolTip = 'View the related bill groups.';
                }
                action("&Posted Bill Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Posted Bill Groups';
                    Image = PostedVoucherGroup;
                    RunObject = Page "Posted Bill Groups List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
                }
                separator(Action1100007)
                {
                }
                action("Payment O&rders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment O&rders';
                    Image = Payment;
                    RunObject = Page "Payment Orders List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ToolTip = 'View or edit related payment orders.';
                }
                action("Posted P&ayment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted P&ayment Orders';
                    Image = PostedPayment;
                    RunObject = Page "Posted Payment Orders List";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
                }
                separator(Action1100010)
                {
                }
                action("Posted Recei&vable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Recei&vable Bills';
                    Image = PostedReceivableVoucher;
                    RunObject = Page "Bank Cat. Posted Receiv. Bills";
                    ToolTip = 'View the list of posted bill groups pertaining to receivables.';
                }
                action("Posted Pa&yable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Pa&yable Bills';
                    Image = PostedPayableVoucher;
                    RunObject = Page "Bank Cat. Posted Payable Bills";
                    ToolTip = 'View the list of posted bill groups pertaining to payables.';
                }
                action(CreateNewLinkedBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create New Linked Bank Account';
                    Image = NewBank;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Create a new online bank account to link to the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    var
                        BankAccount: Record "Bank Account";
                    begin
                        BankAccount.Init();
                        BankAccount.LinkStatementProvider(BankAccount);
                    end;
                }
                action(LinkToOnlineBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link to Online Bank Account';
                    Enabled = NOT Linked;
                    Image = LinkAccount;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Create a link to an online bank account from the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        VerifySingleSelection;
                        LinkStatementProvider(Rec);
                    end;
                }
                action(UnlinkOnlineBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unlink Online Bank Account';
                    Enabled = Linked;
                    Image = UnLinkAccount;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Remove a link to an online bank account from the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        VerifySingleSelection;
                        UnlinkStatementProvider;
                        CurrPage.Update(true);
                    end;
                }
                action(RefreshOnlineBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Refresh Online Bank Account';
                    Enabled = Linked;
                    Image = RefreshRegister;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Refresh the online bank account for the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        VerifySingleSelection;
                        RefreshStatementProvider(Rec);
                    end;
                }
                action(RenewAccessConsentOnlineBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Renew Access Consent for Online Bank Account';
                    Enabled = Linked;
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Renew access consent for the online bank account linked to the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        RenewAccessConsentStatementProvider(Rec);
                    end;
                }
                action(UpdateBankAccountLinking)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Bank Account Linking';
                    Image = MapAccounts;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Link any non-linked bank accounts to their related bank accounts.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        UpdateBankAccountLinking;
                    end;
                }
                action(AutomaticBankStatementImportSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Automatic Bank Statement Import Setup';
                    Enabled = Linked;
                    Image = ElectronicBanking;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Auto. Bank Stmt. Import Setup";
                    RunPageOnRec = true;
                    ToolTip = 'Set up the information for importing bank statement files.';
                    Visible = ShowBankLinkingActions;
                }
                action(PagePosPayEntries)
                {
                    ApplicationArea = Suite;
                    Caption = 'Positive Pay Entries';
                    Image = CheckLedger;
                    RunObject = Page "Positive Pay Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.", "Upload Date-Time")
                                  ORDER(Descending);
                    ToolTip = 'View the bank ledger entries that are related to Positive Pay transactions.';
                    Visible = false;
                }
            }
        }
        area(reporting)
        {
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "Bank Acc. - Detail Trial Bal.";
                ToolTip = 'View a detailed trial balance for selected checks.';
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account - Check Details";
                ToolTip = 'View a detailed trial balance for selected checks.';
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View a detailed trial balance for selected checks within a selected period.';
            }
            action(List)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "Bank Account - List";
                ToolTip = 'View a list of general information about bank accounts, such as posting group, currency code, minimum balance, and balance.';
            }
            action("Receivables-Payables")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Receivables-Payables";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View a detailed trial balance for the selected bank account.';
            }
            action("Bank - Summ. Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Summ. Bill Group';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank - Summ. Bill Group";
                ToolTip = 'View a detailed summary for existing bill groups.';
            }
            action("Bank - Risk")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Risk';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank - Risk";
                ToolTip = 'View the risk status for discounting bills with the selected bank.';
            }
            action("Bank Account Statements")
            {
                ApplicationArea = Suite;
                Caption = 'Bank Account Statements';
                Image = "Report";
                RunObject = Report "Bank Account Statement";
                ToolTip = 'View statements for selected bank accounts. For each bank transaction, the report shows a description, an applied amount, a statement amount, and other information.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetOnlineFeedStatementStatus(OnlineFeedStatementStatus, Linked);
        ShowBankLinkingActions := StatementProvidersExist;
    end;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Check Report Name");
        GetOnlineFeedStatementStatus(OnlineFeedStatementStatus, Linked);
    end;

    trigger OnOpenPage()
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        ShowBankLinkingActions := StatementProvidersExist;
        MonitorSensitiveField.ShowPromoteMonitorSensitiveFieldNotification();
    end;

    var
        MultiselectNotSupportedErr: Label 'You can only link to one online bank account at a time.';
        Linked: Boolean;
        ShowBankLinkingActions: Boolean;
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";

    local procedure VerifySingleSelection()
    var
        BankAccount: Record "Bank Account";
    begin
        CurrPage.SetSelectionFilter(BankAccount);

        if BankAccount.Count > 1 then
            Error(MultiselectNotSupportedErr);
    end;
}

