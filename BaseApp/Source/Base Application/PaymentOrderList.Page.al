page 12424 "Payment Order List"
{
    Caption = 'Payment Order List';
    DataCaptionFields = "Journal Batch Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the related payment is a prepayment.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';

                    trigger OnValidate()
                    begin
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';

                    trigger OnValidate()
                    begin
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Business Unit Code"; "Business Unit Code")
                {
                    ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                    Visible = false;
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the code for the salesperson or purchaser who is linked to the sale or purchase on the journal line.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeCurrencyFactor.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeCurrencyFactor.RunModal = ACTION::OK then
                            Validate("Currency Factor", ChangeCurrencyFactor.GetParameter);
                        Clear(ChangeCurrencyFactor);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ToolTip = 'Specifies the type of transaction.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ToolTip = 'Specifies the amount.';
                    Visible = false;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expenses';
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Income';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ToolTip = 'Specifies the payment amount.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnValidate()
                    begin
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
                    end;
                }
                field("Bal. Gen. Posting Type"; "Bal. Gen. Posting Type")
                {
                    ToolTip = 'Specifies the general posting type associated with the balancing account that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bal. Gen. Bus. Posting Group"; "Bal. Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the general business posting group code associated with the balancing account that will be used when you post the entry.';
                    Visible = false;
                }
                field("Bal. Gen. Prod. Posting Group"; "Bal. Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the general product posting group code associated with the balancing account that will be used when you post the entry.';
                    Visible = false;
                }
                field("Bal. VAT Bus. Posting Group"; "Bal. VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT business posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bal. VAT Prod. Posting Group"; "Bal. VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT product posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("On Hold"; "On Hold")
                {
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                    Visible = false;
                }
                field("Bank Payment Type"; "Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Export Status"; "Export Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of a bank payment order. This value is set automatically.';
                }
            }
            group(Control30)
            {
                ShowCaption = false;
                field(AccountName; AccountName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                }
                field(BalAccountName; BalAccountName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bal. Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Document")
            {
                Caption = '&Document';
                Image = Document;
                Visible = false;
                action(List)
                {
                    Caption = 'List';
                    Image = OpportunitiesList;
                    RunObject = Page "Ingoing Cash Order";
                    RunPageLink = "Document No." = FIELD("Document No."),
                                  "Journal Template Name" = FIELD("Journal Template Name"),
                                  "Journal Batch Name" = FIELD("Journal Batch Name");
                    ToolTip = 'Open the list of ongoing cash orders.';
                }
                action("Payment Order")
                {
                    Caption = 'Payment Order';
                    Image = "Order";
                    RunObject = Page "Bank Payment Order";
                    RunPageLink = "Document No." = FIELD("Document No."),
                                  "Journal Template Name" = FIELD("Journal Template Name"),
                                  "Journal Batch Name" = FIELD("Journal Batch Name");
                }
                action(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Printing)
            {
                Caption = 'Printing';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';
                Visible = false;

                trigger OnAction()
                begin
                    TestField("Bal. Account No.");

                    BankAccount.Reset();
                    BankAccount.SetRange("No.", "Bal. Account No.");
                    if BankAccount.FindFirst then begin
                        if BankAccount."Account Type" <> BankAccount."Account Type"::"Bank Account" then begin
                            GenJnlLine.Reset();
                            GenJnlLine.Copy(Rec);
                            GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                            GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                            GenJnlLine.SetRange("Line No.", "Line No.");
                            DocumentPrint.PrintCashOrder(GenJnlLine);
                        end else
                            DocumentPrint.PrintCheck(Rec);
                    end;
                end;
            }
            group(Posting)
            {
                Caption = 'Posting';
                Image = Post;
                Visible = false;
                action(Reconcile)
                {
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts.';

                    trigger OnAction()
                    begin
                        Reconciliation.SetGenJnlLine(Rec);
                        Reconciliation.Run;
                    end;
                }
                action("Test Report")
                {
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        TestPrint.PrintGenJnlLine(Rec);
                    end;
                }
                action(Action38)
                {
                    Caption = 'Posting';
                    Image = Post;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        GenJnlPost: Codeunit "Gen. Jnl.-Post";
                    begin
                        GenJnlPost.Preview(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
    end;

    trigger OnOpenPage()
    begin
        ExportStatusFilter := "Export Status";
        SetExportStatusFilter;

        FilterGroup(4);
        if (GetFilter("Journal Template Name") = '') or (GetFilter("Journal Batch Name") = '') then
            Error('');
        FilterGroup(0);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GenJnlMgt: Codeunit GenJnlManagement;
        TestPrint: Codeunit "Test Report-Print";
        DocumentPrint: Codeunit "Document-Print";
        ChangeCurrencyFactor: Page "Change Exchange Rate";
        Reconciliation: Page Reconciliation;
        AccountName: Text[50];
        BalAccountName: Text[50];
        ExportStatusFilter: Option " ",New,Exported,"Bank Statement Found";
        Text14701: Label 'There is nothing to export. Only bank payment orders with %1 = New can be exported.';

    local procedure SetExportStatusFilter()
    begin
        FilterGroup(2);
        if ExportStatusFilter = ExportStatusFilter::" " then
            SetRange("Export Status")
        else
            SetRange("Export Status", ExportStatusFilter);
        FilterGroup(0);
    end;
}

