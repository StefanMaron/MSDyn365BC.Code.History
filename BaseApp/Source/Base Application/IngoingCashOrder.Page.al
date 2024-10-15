page 12423 "Ingoing Cash Order"
{
    Caption = 'Ingoing Cash Order';
    DataCaptionFields = "Document No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group("Cash Order")
            {
                Caption = 'Cash Order';
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DocumentTypeEditable;
                    ToolTip = 'Specifies the type of the related document.';

                    trigger OnValidate()
                    begin
                        if not ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund]) then
                            error(DocumentTypeErr);

                        DocumentTypeOnAfterValidate;
                    end;
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
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';

                    trigger OnValidate()
                    begin
                        CalcPayment;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Code';

                    trigger OnValidate()
                    begin
                        AccountNoOnAfterValidate;
                    end;
                }
                field("Agreement No."; "Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the general journal line.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount.';

                    trigger OnValidate()
                    begin
                        CreditAmountOnAfterValidate;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From to';
                    ToolTip = 'Specifies fields that are filled in automatically and show the starting and ending dates of the chosen period.';
                }
                field("Payment Purpose"; "Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reason';
                    ToolTip = 'Specifies the payment purpose associated with the general journal line.';
                }
                field("Cash Order Supplement"; "Cash Order Supplement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Supplement';
                    ToolTip = 'Specifies the cash order supplement associated with the general journal line.';
                }
                field("Text 2"; "Cash Order Including")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Including';
                    ToolTip = 'Specifies the cash order including a standard text code, such as travel expenses, associated with the general journal line.';
                }
                field("Check Printed"; "Check Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a check has been printed for the amount on the document or journal line.';
                }
                field(BankAccNo; BankAccNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Account';
                }
                field(CorrAccNo; CorrAccNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Account';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        PostingGroupOnAfterValidate;
                    end;
                }
                field("Bank Payment Type"; "Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        if "Line No." = 0 then
                            FieldError("Line No.");
                        GenJnlLine.Reset();
                        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", "Line No.");
                        if GenJnlLine.FindFirst then
                            REPORT.RunModal(REPORT::"Copy Payment Document", true, true, GenJnlLine);
                    end;
                }
                action("Void check print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void check print';
                    Image = VoidCheck;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Change the status of the ingoing cash order from Check Printed to No. If there is a corresponding record in a check ledger entries table, the value in the Entry Status field in that record will be changed from Printed to Voided.';

                    trigger OnAction()
                    begin
                        GenJnlLine := Rec;
                        Clear(CheckManagment);
                        CheckManagment.VoidCheck(GenJnlLine);
                        CurrPage.Update(false);
                        "Bank Payment Type" := "Bank Payment Type"::"Manual Check";
                        Modify;
                        Commit();
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    if (BankAccNo <> '') and (CorrAccNo <> '') then begin
                        GenJnlLine.Reset();
                        GenJnlLine.Copy(Rec);
                        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", "Line No.");
                        DocumentPrint.PrintCashOrder(GenJnlLine);
                    end;
                end;
            }
            group(Posting)
            {
                Caption = 'Posting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the cash receipt in your books.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(GenJnlLine);
                        GenJnlLine.FindFirst;
                        if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        GenJnlPost: Codeunit "Gen. Jnl.-Post";
                    begin
                        CurrPage.SetSelectionFilter(GenJnlLine);
                        GenJnlLine.FindFirst;
                        if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                            GenJnlPost.Preview(GenJnlLine);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcPayment;
    end;

    trigger OnInit()
    begin
        DocumentTypeEditable := true;
    end;

    var
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        Vend: Record Vendor;
        VendPostGroup: Record "Vendor Posting Group";
        BankAccPostingGr: Record "Bank Account Posting Group";
        CashAcc: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        DocumentPrint: Codeunit "Document-Print";
        CheckManagment: Codeunit CheckManagement;
        CorrAccNo: Code[20];
        BankAccNo: Code[20];
        [InDataSet]
        DocumentTypeEditable: Boolean;
        DocumentTypeErr: Label 'Document Type should be Payment or Refund.';

    [Scope('OnPrem')]
    procedure CalcPayment()
    begin
        CashAcc.Init();
        BankAccNo := '';

        CashAcc.Get("Bal. Account No.");
        BankAccPostingGr.Get(CashAcc."Bank Acc. Posting Group");
        BankAccNo := BankAccPostingGr."G/L Account No.";

        if "Debit Amount" <> 0 then
            Validate("Credit Amount", -"Debit Amount");

        CorrAccNo := '';
        if "Account No." <> '' then
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Cust.Get("Account No.");
                        CustPostGroup.Get("Posting Group");
                        if Prepayment then begin
                            CustPostGroup.TestField("Prepayment Account");
                            CorrAccNo := CustPostGroup."Prepayment Account";
                        end else begin
                            CustPostGroup.TestField("Receivables Account");
                            CorrAccNo := CustPostGroup."Receivables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                "Account Type"::Vendor:
                    begin
                        Vend.Get("Account No.");
                        VendPostGroup.Get("Posting Group");
                        if Prepayment then begin
                            VendPostGroup.TestField("Prepayment Account");
                            CorrAccNo := VendPostGroup."Prepayment Account";
                        end else begin
                            VendPostGroup.TestField("Payables Account");
                            CorrAccNo := VendPostGroup."Payables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                "Account Type"::"G/L Account":
                    CorrAccNo := "Account No.";
                "Account Type"::"Bank Account":
                    begin
                        CashAcc.Get("Account No.");
                        BankAccPostingGr.Get(CashAcc."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("G/L Account No.");
                        CorrAccNo := BankAccPostingGr."G/L Account No.";
                        DocumentTypeEditable := false;
                    end;
            end;
    end;

    local procedure CreditAmountOnAfterValidate()
    begin
        CalcPayment;
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        CalcPayment;
    end;

    local procedure DocumentTypeOnAfterValidate()
    begin
        CalcPayment;
    end;

    local procedure PostingGroupOnAfterValidate()
    begin
        CalcPayment;
    end;
}

