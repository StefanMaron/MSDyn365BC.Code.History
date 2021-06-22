page 981 "Payment Registration"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Register Customer Payments';
    DataCaptionExpression = BalAccCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Posting,Navigate,Search,Setup,Line';
    SourceTable = "Payment Registration Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer or vendor that the payment relates to.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        Customer.Get("Source No.");
                        PAGE.Run(PAGE::"Customer Card", Customer);
                    end;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the payment relates to.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Navigate;
                    end;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the payment relates to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the invoice transaction that the payment relates to.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = DueDateStyle;
                    ToolTip = 'Specifies the payment due date on the related document.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the amount that remains to be paid on the document.';
                }
                field("Payment Made"; "Payment Made")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you have received or made payment for the document.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions;
                    end;
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DueDateStyle;
                    ToolTip = 'Specifies the date when the payment was made.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions;
                    end;
                }
                field("Amount Received"; "Amount Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is paid in the bank account.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions;
                    end;
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SetUserInteractions
                    end;
                }
                field("Rem. Amt. after Discount"; "Rem. Amt. after Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rem Amount Incl. Discount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount after the payment discount is deducted.';
                    Visible = false;
                }
                field(ExternalDocumentNo; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
            }
            grid("Bal. Account Details")
            {
                Caption = 'Bal. Account Details';
                field(PostedBalance; PostedBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Balance';
                    Editable = false;
                    ToolTip = 'Specifies the balance of payments posted to the balancing account that is being used in the Payment Registration window.';
                }
                field(UnpostedBalance; UnpostedBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unposted Balance';
                    Editable = false;
                    ToolTip = 'Specifies the amount that exists on unposted journal lines with the same balancing account as the one used in the Payment Registration window.';
                }
                field(TotalBalance; TotalBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Balance';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the sum of posted amounts and unposted journal line amounts for the balancing account that is being used on the Payment Registration page. The value in this field is the sum of values in the Posted Balance and the Unposted Balance fields.';
                }
            }
            group(Control27)
            {
                ShowCaption = false;
                fixed(Control26)
                {
                    ShowCaption = false;
                    group(Control24)
                    {
                        ShowCaption = false;
                        field(Warning; Warning)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = TRUE;
                            ToolTip = 'Specifies a warning about the payment, such as past due date.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Related Information")
            {
                Caption = 'Related Information';
                Image = Navigate;
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Navigate';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category8;
                    Scope = Repeater;
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                    trigger OnAction()
                    begin
                        Navigate;
                    end;
                }
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = ViewDetails;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'View additional information about the document on the selected line and link to the related customer card.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Payment Registration Details", Rec);
                    end;
                }
            }
            group(Search)
            {
                Caption = 'Search';
                action(SearchCustomer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Search Customers';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "Customer List";
                    ToolTip = 'Open the list of customers, for example, to check for missing payments from a specific customer.';
                }
                action(SearchDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Search Documents';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "Document Search";
                    ToolTip = 'Find documents that are not fully invoiced, for example, to post an invoice so that the received payment can be processed.';
                }
            }
        }
        area(processing)
        {
            group(Post)
            {
                Caption = 'Post';
                Image = Post;
                action(PostPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Payments';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post payment of amounts on the lines where the Payment Made check box is selected.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.ConfirmPost(Rec);
                    end;
                }
                action(PostAsLump)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post as Lump Payment';
                    Image = PostBatch;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Post payment as a lump sum of amounts on lines where the Payment Made check box is selected.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.ConfirmPostLumpPayment(Rec);
                    end;
                }
                action(PreviewPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting Payments';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal. When you perform the actual posting, you may be asked how to post payment tolerance entries. The posting preview assumes the default option: that each payment tolerance is posted as one entry.';

                    trigger OnAction()
                    var
                        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
                    begin
                        PaymentRegistrationMgt.Preview(Rec, false);
                    end;
                }
                action(PreviewLump)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting Payments as Lump';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal as a lump sum of amounts. When you perform the actual posting, you may be asked how to post payment tolerance entries. The posting preview assumes the default option: that each payment tolerance is posted as one entry.';

                    trigger OnAction()
                    var
                        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
                    begin
                        PaymentRegistrationMgt.Preview(Rec, true);
                    end;
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action(OpenGenJnl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = GLRegisters;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.OpenGenJnl
                    end;
                }
                action(FinanceChargeMemo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memo';
                    Image = FinChargeMemo;
                    Promoted = true;
                    PromotedCategory = New;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = FIELD("Source No.");
                    RunPageMode = Create;
                    Scope = Repeater;
                    ToolTip = 'Create a finance charge memo for the customer on the selected line, for example, to issue a finance charge for late payment.';
                }
            }
            group(Action36)
            {
                Caption = 'Setup';
                Image = Setup;
                action(Setup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup';
                    Image = Setup;
                    ToolTip = 'Adjust how payments are posted and which balancing account to use.';

                    trigger OnAction()
                    begin
                        if PAGE.RunModal(PAGE::"Payment Registration Setup") = ACTION::LookupOK then
                            FormatPageCaption
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetUserInteractions;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Reload;
        PaymentRegistrationMgt.CalculateBalance(PostedBalance, UnpostedBalance);
        TotalBalance := PostedBalance + UnpostedBalance;
        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        PaymentRegistrationMgt.RunSetup;
        FormatPageCaption;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(PaymentRegistrationMgt.ConfirmClose(Rec));
    end;

    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        BalAccCaption: Text;
        PmtDiscStyle: Text;
        DueDateStyle: Text;
        Warning: Text;
        PostedBalance: Decimal;
        UnpostedBalance: Decimal;
        TotalBalance: Decimal;

    local procedure FormatPageCaption()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        BalAccCaption := Format(PaymentRegistrationSetup."Bal. Account Type") + ' - ' + PaymentRegistrationSetup."Bal. Account No.";
    end;

    local procedure SetUserInteractions()
    begin
        PmtDiscStyle := GetPmtDiscStyle;
        DueDateStyle := GetDueDateStyle;
        Warning := GetWarning;
    end;
}

