page 16 "Chart of Accounts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Chart of Accounts';
    CardPageID = "G/L Account Card";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Periodic Activities,Account,Balance';
    QueryCategory = 'Chart of Accounts';
    RefreshOnActivate = true;
    SourceTable = "G/L Account";
    UsageCategory = Lists;

    AboutTitle = 'About the chart of accounts';
    AboutText = 'The chart of accounts is the core of the financials used to group income and expenses in the income statement and balance sheet. Define indentation levels for a structured overview of your financials. The chart of accounts should reflect how the business is organized.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NoEmphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the general ledger account.';
                    Width = 60;
                }
                field("Net Change"; "Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                    AboutTitle = 'What is behind the numbers';
                    AboutText = 'Tap or click on amounts to drill down and see the underlying entries to learn what is behind the numbers for insight and troubleshooting.';
                    Visible = AmountVisible;
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account.';
                }
                field("Income/Balance"; "Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Category"; "Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';
                    Visible = false;
                }
                field("Account Subcategory Descript."; "Account Subcategory Descript.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Subcategory';
                    DrillDown = false;
                    ToolTip = 'Specifies the subcategory of the account category of the G/L account.';
                    AboutTitle = 'Structure the chart of accounts';
                    AboutText = 'Group your accounts into categories and subcategories to provide structure to the financial overview.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field("Direct Posting"; "Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account.';
                    Visible = false;
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLaccList: Page "G/L Account List";
                    begin
                        GLaccList.LookupMode(true);
                        if not (GLaccList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := GLaccList.GetSelectionFilter;
                        exit(true);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Balance at Date"; "Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Additional-Currency Net Change"; "Additional-Currency Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance.';
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; "Add.-Currency Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance, in the additional reporting currency, on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Additional-Currency Balance"; "Additional-Currency Balance")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account, in the additional reporting currency.';
                    Visible = false;
                }
                field("Consol. Debit Acc."; "Consol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number in a consolidated company to transfer credit balances.';
                    Visible = false;
                }
                field("Consol. Credit Acc."; "Consol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts without any payment tolerance amount from the customer and vendor ledger entries are used.';
                    Visible = false;
                }
                field("Cost Type No."; "Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a cost type number to establish which cost type a general ledger account belongs to.';
                }
                field("Consol. Translation Method"; "Consol. Translation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the consolidation translation method that will be used for the account.';
                    Visible = false;
                }
                field("Default IC Partner G/L Acc. No"; "Default IC Partner G/L Acc. No")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies accounts that you often enter in the Bal. Account No. field on intercompany journal or document lines.';
                    Visible = false;
                }
                field("Default Deferral Template Code"; "Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default deferral template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
                field("No. 2"; "No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternative account number which can be used internally in the company.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Table ID" = CONST(15),
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = FIELD("No.");
                    RunPageView = SORTING("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("G/L Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
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
                        PromotedOnly = true;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(15),
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
                        PromotedOnly = true;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            GLAcc: Record "G/L Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(GLAcc);
                            DefaultDimMultiple.SetMultiRecord(GLAcc, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                    action(SetDimensionFilter)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Set Dimension Filter';
                        Ellipsis = true;
                        Image = "Filter";
                        Promoted = true;
                        PromotedCategory = Category5;
                        PromotedOnly = true;
                        ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                        trigger OnAction()
                        begin
                            SetFilter("Dimension Set ID Filter", DimensionSetIDFilter.LookupFilter);
                        end;
                    }
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = CONST("G/L Account"),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View additional information that has been added to the description for the current account.';
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    Image = ReceivablesPayables;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    RunObject = Page "Receivables-Payables";
                    ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
                }
                action("Where-Used List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Where-Used List';
                    Image = Track;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Show setup tables where the current account is used.';

                    trigger OnAction()
                    var
                        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
                    begin
                        CalcGLAccWhereUsed.CheckGLAcc("No.");
                    end;
                }
            }
            group("&Balance")
            {
                Caption = '&Balance';
                Image = Balance;
                action("G/L &Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'G/L &Account Balance';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = FIELD("Business Unit Filter");
                    ToolTip = 'View a summary of the debit and credit balances for different time periods, for the account that you select in the chart of accounts.';
                }
                action("G/L &Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'G/L &Balance';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance";
                    RunPageLink = "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = FIELD("Business Unit Filter");
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the debit and credit balances for all the accounts in the chart of accounts, for the time period that you select.';
                }
                action("G/L Balance by &Dimension")
                {
                    ApplicationArea = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'G/L Balance by &Dimension';
                    Image = GLBalanceDimension;
                    RunObject = Page "G/L Balance by Dimension";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
                action("G/L Account Balance/Bud&get")
                {
                    ApplicationArea = Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'G/L Account Balance/Bud&get';
                    Image = Period;
                    RunObject = Page "G/L Account Balance/Budget";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = FIELD("Business Unit Filter"),
                                  "Budget Filter" = FIELD("Budget Filter");
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("G/L Balance/B&udget")
                {
                    ApplicationArea = Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'G/L Balance/B&udget';
                    Image = ChartOfAccounts;
                    RunObject = Page "G/L Balance/Budget";
                    RunPageLink = "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = FIELD("Business Unit Filter"),
                                  "Budget Filter" = FIELD("Budget Filter");
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("Chart of Accounts &Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedOnly = true;
                    Caption = 'Chart of Accounts &Overview';
                    Image = Accounts;
                    RunObject = Page "Chart of Accounts Overview";
                    ToolTip = 'View the chart of accounts with different levels of detail where you can expand or collapse a section of the chart of accounts.';
                }
            }
            action("G/L Register")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Register';
                Image = GLRegisters;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = Page "G/L Registers";
                ToolTip = 'View posted G/L entries.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(IndentChartOfAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Indent Chart of Accounts';
                    Image = IndentChartOfAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Codeunit "G/L Account-Indent";
                    ToolTip = 'Indent accounts between a Begin-Total and the matching End-Total one level to make the chart of accounts easier to read.';
                }
            }
            group("Periodic Activities")
            {
                Caption = 'Periodic Activities';
                action("General Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = Journal;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "General Journal";
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';
                }
                action("Close Income Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close Income Statement';
                    Image = CloseYear;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Report "Close Income Statement";
                    ToolTip = 'Start the transfer of the year''s result to an account in the balance sheet and close the income statement accounts.';
                }
                action(DocsWithoutIC)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Documents without Incoming Document';
                    Image = Documents;
                    ToolTip = 'Show a list of posted purchase and sales documents under the G/L account that do not have related incoming document records.';

                    trigger OnAction()
                    var
                        PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf.";
                    begin
                        if "Account Type" = "Account Type"::Posting then
                            PostedDocsWithNoIncBuf.SetRange("G/L Account No. Filter", "No.")
                        else
                            if Totaling <> '' then
                                PostedDocsWithNoIncBuf.SetFilter("G/L Account No. Filter", Totaling)
                            else
                                exit;
                        PAGE.Run(PAGE::"Posted Docs. With No Inc. Doc.", PostedDocsWithNoIncBuf);
                    end;
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
                RunObject = Report "Detail Trial Balance";
                ToolTip = 'View a detail trial balance for the general ledger accounts that you specify.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "Trial Balance";
                ToolTip = 'View the chart of accounts that have balances and net changes.';
                AboutTitle = 'Get the financial overview';
                AboutText = 'With the Trial Balance reports you get the balance sheet, income statement, or the full trial balance.';
            }
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
            }
            action(Action1900210206)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Register';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "G/L Register";
                ToolTip = 'View posted G/L entries.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NoEmphasize := "Account Type" <> "Account Type"::Posting;
        NameIndent := Indentation;
        NameEmphasize := "Account Type" <> "Account Type"::Posting;
    end;

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewGLAcc(xRec, BelowxRec);
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility;
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        [InDataSet]
        NoEmphasize: Boolean;
        [InDataSet]
        NameEmphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;
}

