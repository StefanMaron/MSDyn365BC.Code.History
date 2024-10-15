page 370 "Bank Account Card"
{
    Caption = 'Bank Account Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Bank Statement Service,Bank Account,Navigate';
    SourceTable = "Bank Account";

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
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the bank account''s current balance in LCY.';
                }
                field("Min. Balance"; "Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a minimum balance for the bank account.';
                    Visible = false;
                }
                field("Our Contact Code"; "Our Contact Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code to specify the employee who is responsible for this bank account.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("SEPA Direct Debit Exp. Format"; "SEPA Direct Debit Exp. Format")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the SEPA format of the bank file that will be exported when you choose the Create Direct Debit File button in the Direct Debit Collect. Entries window.';
                }
                field("Credit Transfer Msg. Nos."; "Credit Transfer Msg. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number series for bank instruction messages that are created with the export file that you create from the Direct Debit Collect. Entries window.';
                }
                field("Direct Debit Msg. Nos."; "Direct Debit Msg. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number series that will be used on the direct debit file that you export for a direct-debit collection entry in the Direct Debit Collect. Entries window.';
                }
                field("Creditor No."; "Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies your company as the creditor in connection with payment collection from customers using SEPA Direct Debit.';
                }
                field("Bank Clearing Standard"; "Bank Clearing Standard")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
                }
                field("Bank Clearing Code"; "Bank Clearing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
                }
                field("Use as Default for Currency"; "Use as Default for Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether this is the default company account for payments in sales and service documents in the currency specified for this account. Each currency can have only one default bank account.';
                }
                group(Control45)
                {
                    ShowCaption = false;
                    Visible = ShowBankLinkingActions;
                    field(OnlineFeedStatementStatus; OnlineFeedStatementStatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Linking Status';
                        Editable = false;
                        ToolTip = 'Specifies if the bank account is linked to an online bank account through the bank statement service.';

                        trigger OnValidate()
                        begin
                            if not Linked then
                                UnlinkStatementProvider
                            else
                                Error(OnlineBankAccountLinkingErr);
                        end;
                    }
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the Bank Account card was last modified.';
                }
                group("Payment Matching")
                {
                    Caption = 'Payment Matching';
                    field("Disable Automatic Pmt Matching"; "Disable Automatic Pmt Matching")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Disable Automatic Payment Matching';
                        Importance = Additional;
                        ToolTip = 'Specifies whether to disable automatic payment matching after importing bank transactions for this bank account.';
                    }
                }
                group("Payment Match Tolerance")
                {
                    Caption = 'Payment Match Tolerance';
                    field("Match Tolerance Type"; "Match Tolerance Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies by which tolerance the automatic payment application function will apply the Amount Incl. Tolerance Matched rule for this bank account.';
                    }
                    field("Match Tolerance Value"; "Match Tolerance Value")
                    {
                        ApplicationArea = Basic, Suite;
                        DecimalPlaces = 0 : 2;
                        Importance = Additional;
                        ToolTip = 'Specifies if the automatic payment application function will apply the Amount Incl. Tolerance Matched rule by Percentage or Amount.';
                    }
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the bank where you have the bank account.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the bank where you have the bank account.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county of the address.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field(MobilePhoneNo; "Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the bank where you have the bank account.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                    Visible = false;
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where you have the bank account.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank''s VAT registration number.';
                }
                field("Last Check No."; "Last Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check number of the last check issued from the bank account.';
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field("Last Statement No."; "Last Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the last bank account statement that was reconciled with this bank account.';
                }
                field("Last Payment Statement No."; "Last Payment Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last bank statement that was imported.';
                }
                field("Balance Last Statement"; "Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the balance amount of the last statement reconciliation on the bank account.';

                    trigger OnValidate()
                    begin
                        if "Balance Last Statement" <> xRec."Balance Last Statement" then
                            if not Confirm(Text001, false, "No.") then
                                Error(Text002);
                    end;
                }
                field("Last Remittance Advice No."; "Last Remittance Advice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the Remittance Advice is printed on blank paper in a format that is easy to mail to the vendor.';
                }
                field("Las E-Pay File Creation No."; "Las E-Pay File Creation No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the Last E-Pay File Creation No. is used to keep track of the electronic payment files created.';
                }
                field("Bank Acc. Posting Group"; "Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Cartera)
            {
                Caption = 'Cartera';
                field("Delay for Notices"; "Delay for Notices")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies, if applicable, the delay for notice defined for this bank.';
                }
                field("Credit Limit for Discount"; "Credit Limit for Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the credit limit for the discount of bills available at this particular bank.';
                }
                field("Operation Fees Code"; "Operation Fees Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the operations fee code related to this particular bank.';
                }
                field("Customer Ratings Code"; "Customer Ratings Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for insolvency risk percentages that the bank assigns to its customers.';
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field("CCC Bank No."; "CCC Bank No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the four-digit bank account code.';
                }
                field("CCC Bank Branch No."; "CCC Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the four-digit office code.';
                }
                field("CCC Control Digits"; "CCC Control Digits")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the two-digit account control code.';
                }
                field("CCC Bank Account No."; "CCC Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 10-digit account code.';
                }
                field("CCC No."; "CCC No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the complete 20-digit customer account code.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("E-Pay Export File Path"; "E-Pay Export File Path")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full path of the electronic payment file, starting with the drive letter and with a back slash (\) at the end.';
                }
                field("Last E-Pay Export File Name"; "Last E-Pay Export File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the file with the extension .txt without the path. This file name should have digits in it.';
                }
                field("Bank Branch No.2"; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Branch No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies a number of the bank branch.';
                    Visible = false;
                }
                field("Bank Account No.2"; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                }
                field("Transit No.2"; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transit No.';
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field("Bank Statement Import Format"; "Bank Statement Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the bank statement file that can be imported into this bank account.';
                }
                field("Payment Export Format"; "Payment Export Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the bank file that will be exported when you choose the Export Payments to File button in the Payment Journal window.';
                }
                field("Positive Pay Export Code"; "Positive Pay Export Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Bank Export/Import Setup";
                    ToolTip = 'Specifies a code for the data exchange definition that manages the export of positive-pay files.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
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
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(270),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'View a summary of the bank account balance in different periods.';
                }
                action(Statements)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.")
                                  ORDER(Descending);
                    ToolTip = 'View check ledger entries that result from posting transactions in a payment journal for the relevant bank account.';
                }
                action("C&ontact")
                {
                    ApplicationArea = All;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'View or edit detailed information about the contact person at the bank.';
                    Visible = ContactActionVisible;

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
                separator(Action81)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
                separator(Action1100030)
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
                separator(Action1100034)
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
                separator(Action1100038)
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
                separator(Action1100041)
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
                action(PagePositivePayEntries)
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
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to the contact person for this bank account.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::"Bank Account", Rec.SystemId);
                    end;
                }
            }
            action(BankAccountReconciliations)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Reconciliation Journals';
                Image = BankAccountRec;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageLink = "Bank Account No." = FIELD("No.");
                RunPageView = SORTING("Bank Account No.");
                ToolTip = 'Reconcile your bank account by importing transactions and applying them, automatically or manually, to open customer ledger entries, open vendor ledger entries, or open bank account ledger entries.';
            }
            action("Receivables-Payables")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = ReceivablesPayables;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "Receivables-Payables Lines";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
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
                    RefreshStatementProvider(Rec);
                end;
            }
            action(EditOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Online Bank Account Information';
                Enabled = Linked;
                Image = EditCustomer;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Edit the information about the online bank account linked to the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    EditAccountStatementProvider(Rec);
                end;
            }
            action(RenewAccessConsentOnlineBankAccount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Renew Access Consent for Online Bank Account';
                Enabled = Linked;
                Image = Approve;
                Promoted = false;
                ToolTip = 'Renew access consent for the online bank account linked to the selected bank account.';
                Visible = ShowBankLinkingActions;

                trigger OnAction()
                begin
                    RenewAccessConsentStatementProvider(Rec);
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
        }
        area(processing)
        {
            action("Cash Receipt Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Receipt Journals';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Create a cash receipt journal line for the bank account, for example, to post a payment receipt.';
            }
            action("Payment Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journals';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "Payment Journal";
                ToolTip = 'Open the list of payment journals where you can register payments to vendors.';
            }
            action(PagePosPayExport)
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
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to the contact person for this bank account.';

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::"Bank Account", Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(reporting)
        {
            action(List)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List';
                Image = "Report";
                ToolTip = 'View a list of general information about bank accounts, such as posting group, currency code, minimum balance, and balance.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Account - List", "No.");
                end;
            }
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                ToolTip = 'View a detailed trial balance for selected checks.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Acc. - Detail Trial Bal.", "No.");
                end;
            }
            action(Action1906306806)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables-Payables';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Receivables-Payables";
                ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
            }
            action("Check Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Details';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                ToolTip = 'View a detailed trial balance for selected checks.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Bank Account - Check Details", "No.");
                end;
            }
            action("Bank - Summ. Bill Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Summ. Bill Group';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Bank - Summ. Bill Group";
                ToolTip = 'View a detailed summary for existing bill groups.';
            }
            action("Bank - Risk")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank - Risk';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Bank - Risk";
                ToolTip = 'View the risk status for discounting bills with the selected bank.';
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
        GetOnlineFeedStatementStatus(OnlineFeedStatementStatus, Linked);
        CalcFields("Check Report Name");
    end;

    trigger OnOpenPage()
    var
        Contact: Record Contact;
    begin
        OnBeforeOnOpenPage();
        ContactActionVisible := Contact.ReadPermission;
        SetNoFieldVisible;
    end;

    var
        Text001: Label 'There may be a statement using the %1.\\Do you want to change Balance Last Statement?';
        Text002: Label 'Canceled.';
        [InDataSet]
        ContactActionVisible: Boolean;
        Linked: Boolean;
        OnlineBankAccountLinkingErr: Label 'You must link the bank account to an online bank account.\\Choose the Link to Online Bank Account action.';
        ShowBankLinkingActions: Boolean;
        NoFieldVisible: Boolean;
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.BankAccountNoIsVisible;
    end;

    local procedure RunReport(ReportNumber: Integer; BankActNumber: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange("No.", BankActNumber);
        REPORT.RunModal(ReportNumber, true, true, BankAccount);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage()
    begin
    end;
}

