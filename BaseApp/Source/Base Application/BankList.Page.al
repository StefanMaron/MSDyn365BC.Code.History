#if not CLEAN19
page 11727 "Bank List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Banks';
    CardPageID = "Bank Account Card";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";
    ObsoleteState = Pending;
    ObsoleteReason = 'Discontinued, use standard page Bank Account List instead.';
    ObsoleteTag = '19.0';


    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220021)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field(Linked; Linked)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked';
                    Editable = false;
                    ToolTip = 'Specifies if the bank account is linked to an online bank account through the bank statement service.';
                    Visible = ShowBankLinkingActions;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field("Fax No."; Rec."Fax No.")
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
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                }
                field("SWIFT Code"; Rec."SWIFT Code")
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
                field("Our Contact Code"; Rec."Our Contact Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to specify the employee who is responsible for this bank account.';
                    Visible = false;
                }
                field("Bank Acc. Posting Group"; Rec."Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that determines the language associated with this bank account.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the bank account.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1220002; "Dimensions FactBox")
            {
                ApplicationArea = Dimensions;
                SubPageLink = "Table ID" = CONST(270),
                              "No." = FIELD("No.");
                Visible = false;
            }
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected bank account.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'Create a comment attached to the selected bank account.';
                }
                action(PositivePayExport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Positive Pay Export';
                    Image = Export;
                    RunObject = Page "Positive Pay Export";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'Export a positive pay file.';
                    Visible = false;
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
                        ToolTip = 'Show how the current account uses dimensions and dimension values.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'Show how a group of accounts use dimensions and dimension values.';

                        trigger OnAction()
                        var
                            BankAcc: Record "Bank Account";
                            DefaultDimensionsMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(BankAcc);
                            DefaultDimensionsMultiple.SetMultiRecord(BankAcc, FieldNo("No."));
                            DefaultDimensionsMultiple.RunModal();
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
                    ToolTip = 'View a summary of the bank account balance at different periods.';
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
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
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
                    ToolTip = 'View or edit detailed information about the contact person at the customer.';

                    trigger OnAction()
                    begin
                        ShowContact();
                    end;
                }
                action(CreateNewLinkedBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create New Linked Bank Account';
                    Image = NewBank;
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
                    ToolTip = 'Create a link to an online bank account from the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        VerifySingleSelection();
                        LinkStatementProvider(Rec);
                    end;
                }
                action(UnlinkOnlineBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unlink Online Bank Account';
                    Enabled = Linked;
                    Image = UnLinkAccount;
                    ToolTip = 'Remove a link to an online bank account from the selected bank account.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        VerifySingleSelection();
                        UnlinkStatementProvider();
                        CurrPage.Update(true);
                    end;
                }
                action(UpdateBankAccountLinking)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Bank Account Linking';
                    Image = MapAccounts;
                    ToolTip = 'Update the online bank account links.';
                    Visible = ShowBankLinkingActions;

                    trigger OnAction()
                    begin
                        UpdateBankAccountLinking();
                    end;
                }
                action(AutomaticBankStatementImportSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Automatic Bank Statement Import Setup';
                    Enabled = Linked;
                    Image = ElectronicBanking;
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
                    ToolTip = 'View a positive pay entries.';
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
                RunObject = Report "Bank Acc. - Detail Trial Bal.";
                ToolTip = 'View, print, or save a detailed trial balance for selected checks.';
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account - Check Details";
                ToolTip = 'View, print, or save a detailed trial balance for selected checks.';
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View, print, or save a detailed trial balance for selected checks within a selected period.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View, print, or save a detailed trial balance for selected checks.';
            }
            action("Bank Account Statements")
            {
                ApplicationArea = Suite;
                Caption = 'Bank Account Statements';
                Image = "Report";
                RunObject = Report "Bank Account Statement";
                ToolTip = 'View, print, or save statements for selected bank accounts. For each bank transaction, the report Specifies a description, an applied amount, a statement amount, and other information.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(PositivePayExport_Promoted; PositivePayExport)
                {
                }
                actionref(Balance_Promoted; Balance)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
                actionref("Trial Balance by Period_Promoted"; "Trial Balance by Period")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Bank Statement Service', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(CreateNewLinkedBankAccount_Promoted; CreateNewLinkedBankAccount)
                {
                }
                actionref(LinkToOnlineBankAccount_Promoted; LinkToOnlineBankAccount)
                {
                }
                actionref(UnlinkOnlineBankAccount_Promoted; UnlinkOnlineBankAccount)
                {
                }
                actionref(UpdateBankAccountLinking_Promoted; UpdateBankAccountLinking)
                {
                }
                actionref(AutomaticBankStatementImportSetup_Promoted; AutomaticBankStatementImportSetup)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Linked := IsLinkedToBankStatementServiceProvider();
        ShowBankLinkingActions := StatementProvidersExist();
    end;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Check Report Name");
        Linked := IsLinkedToBankStatementServiceProvider();
    end;

    trigger OnOpenPage()
    begin
        ShowBankLinkingActions := StatementProvidersExist();
    end;

    var
        Linked: Boolean;
        ShowBankLinkingActions: Boolean;
        MultiselectNotSupportedErr: Label 'You can only link to one online bank account at a time.';

    local procedure VerifySingleSelection()
    var
        BankAccount: Record "Bank Account";
    begin
        CurrPage.SetSelectionFilter(BankAccount);

        if BankAccount.Count > 1 then
            Error(MultiselectNotSupportedErr);
    end;
}

#endif