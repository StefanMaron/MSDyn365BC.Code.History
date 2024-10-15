page 10869 "Payment Slip Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Payment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the payment line will be posted to.';

                    trigger OnValidate()
                    begin
                        BankInfoEditable := IsBankInfoEditable;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = AccountNoEmphasize;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the payment line.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Drawee Reference"; "Drawee Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file reference which will be used in the electronic payment (ETEBAC) file.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting group associated with the account.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date on the entry.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount (including VAT) of the payment line, if it is a debit amount.';
                    Visible = DebitAmountVisible;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount (including VAT) of the payment line, if it is a credit amount.';
                    Visible = CreditAmountVisible;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount (including VAT) of the payment line.';
                    Visible = AmountVisible;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the international bank account number (IBAN) for the payment slip.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the international bank identification code for the payment slip.';
                }
                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the customer or vendor bank account that you want to perform the payment to, or collection from.';
                    Visible = BankAccountCodeVisible;
                }
                field("Acceptation Code"; "Acceptation Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an acceptation code for the payment line.';
                    Visible = AcceptationCodeVisible;
                }
                field("Payment Address Code"; "Payment Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the payment address of the customer or vendor.';
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = All;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the branch number of the bank account.';
                    Visible = RIBVisible;
                }
                field("Agency Code"; "Agency Code")
                {
                    ApplicationArea = All;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the agency code of the bank account.';
                    Visible = RIBVisible;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = All;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the number of the customer or vendor bank account that you want to perform the payment to, or collection from.';
                    Visible = RIBVisible;
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = All;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the name of the bank account as entered in the Bank Account Code field.';
                    Visible = RIBVisible;
                }
                field("Bank City"; "Bank City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the city of the bank account.';
                    Visible = false;
                }
                field("RIB Key"; "RIB Key")
                {
                    ApplicationArea = All;
                    Editable = BankInfoEditable;
                    ToolTip = 'Specifies the two-digit RIB key associated with the Bank Account No. RIB key value in range from 01 to 09 is represented in the single-digit form, without leading zero digit.';
                    Visible = RIBVisible;
                }
                field("RIB Checked"; "RIB Checked")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the key entered in the RIB Key field is correct.';
                    Visible = RIBVisible;
                }
                field("Has Payment Export Error"; "Has Payment Export Error")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an error occurred when you used the Export Payments to File function in the Payment Slip window.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct debit mandate of the customer who made this payment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Set Document ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Document ID';
                    ToolTip = 'Fill in the document number of the entry in the payment slip.';

                    trigger OnAction()
                    begin
                        SetDocumentID;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Application)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Application';
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Apply the customer or vendor payment on the selected payment slip line.';

                    trigger OnAction()
                    begin
                        ApplyPayment();
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or change the dimension settings for this payment slip. If you change the dimension, you can update all lines on the payment slip.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action(Modify)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Modify';
                    Image = EditFilter;
                    ToolTip = 'View and edit information in the document associated with the line on the payment slip.';

                    trigger OnAction()
                    begin
                        OnModify;
                    end;
                }
                action(Insert)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert';

                    trigger OnAction()
                    begin
                        OnInsert;
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove';
                    Image = Cancel;
                    ToolTip = 'Remove the payment line.';

                    trigger OnAction()
                    begin
                        OnDelete;
                    end;
                }
                group("A&ccount")
                {
                    Caption = 'A&ccount';
                    Image = ChartOfAccounts;
                    action(Card)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Card';
                        Image = EditLines;
                        ShortCutKey = 'Shift+F7';
                        ToolTip = 'Open the card for the entity on the selected line to view more details.';

                        trigger OnAction()
                        begin
                            ShowAccount;
                        end;
                    }
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View details about ledger entries for the vendor account.';

                        trigger OnAction()
                        begin
                            ShowEntries;
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActivateControls;
        BankInfoEditable := IsBankInfoEditable;
        AccountNoEmphasize := "Copied To No." <> '';
    end;

    trigger OnInit()
    begin
        BankAccountCodeVisible := true;
        CreditAmountVisible := true;
        DebitAmountVisible := true;
        AmountVisible := true;
        AcceptationCodeVisible := true;
        RIBVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec, BelowxRec);
    end;

    var
        Text000: Label 'Assign No. ?';
        Header: Record "Payment Header";
        Status: Record "Payment Status";
        Text001: Label 'There is no line to modify.';
        Text002: Label 'A posted line cannot be modified.';
        Text003: Label 'You cannot assign numbers to a posted header.';
        Navigate: Page Navigate;
        [InDataSet]
        AccountNoEmphasize: Boolean;
        [InDataSet]
        AcceptationCodeVisible: Boolean;
        [InDataSet]
        AmountVisible: Boolean;
        [InDataSet]
        BankAccountCodeVisible: Boolean;
        [InDataSet]
        BankInfoEditable: Boolean;
        [InDataSet]
        CreditAmountVisible: Boolean;
        [InDataSet]
        DebitAmountVisible: Boolean;
        [InDataSet]
        RIBVisible: Boolean;

    local procedure ApplyPayment()
    begin
        CODEUNIT.Run(CODEUNIT::"Payment-Apply", Rec);
    end;

    local procedure DisableFields()
    begin
        if Header.Get("No.") then
            CurrPage.Editable((Header."Status No." = 0) and ("Copied To No." = ''));
    end;

    local procedure OnModify()
    var
        PaymentLine: Record "Payment Line";
        PaymentModification: Page "Payment Line Modification";
    begin
        if "Line No." = 0 then
            Message(Text001)
        else
            if not Posted then begin
                PaymentLine.Copy(Rec);
                PaymentLine.SetRange("No.", "No.");
                PaymentLine.SetRange("Line No.", "Line No.");
                PaymentModification.SetTableView(PaymentLine);
                PaymentModification.RunModal;
            end else
                Message(Text002);
    end;

    local procedure OnInsert()
    var
        PaymentManagement: Codeunit "Payment Management";
    begin
        PaymentManagement.LinesInsert("No.");
    end;

    local procedure OnDelete()
    var
        StatementLine: Record "Payment Line";
        PostingStatement: Codeunit "Payment Management";
    begin
        StatementLine.Copy(Rec);
        CurrPage.SetSelectionFilter(StatementLine);
        PostingStatement.DeleteLigBorCopy(StatementLine);
    end;

    local procedure SetDocumentID()
    var
        StatementLine: Record "Payment Line";
        PostingStatement: Codeunit "Payment Management";
        No: Code[20];
    begin
        if "Status No." <> 0 then begin
            Message(Text003);
            exit;
        end;
        if Confirm(Text000) then begin
            CurrPage.SetSelectionFilter(StatementLine);
            StatementLine.MarkedOnly(true);
            if not StatementLine.Find('-') then
                StatementLine.MarkedOnly(false);
            if StatementLine.Find('-') then begin
                No := StatementLine."Document No.";
                while StatementLine.Next <> 0 do begin
                    PostingStatement.IncrementNoText(No, 1);
                    StatementLine."Document No." := No;
                    StatementLine.Modify();
                end;
            end;
        end;
    end;

    local procedure ShowAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Account Type" := "Account Type";
        GenJnlLine."Account No." := "Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Card", GenJnlLine);
    end;

    local procedure ShowEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Account Type" := "Account Type";
        GenJnlLine."Account No." := "Account No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show Entries", GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure MarkLines(ToMark: Boolean)
    var
        LineCopy: Record "Payment Line";
        NumLines: Integer;
    begin
        if ToMark then begin
            CurrPage.SetSelectionFilter(LineCopy);
            NumLines := LineCopy.Count();
            if NumLines > 0 then begin
                LineCopy.Find('-');
                repeat
                    LineCopy.Marked := true;
                    LineCopy.Modify();
                until LineCopy.Next() = 0;
            end else
                LineCopy.Reset();
            LineCopy.SetRange("No.", "No.");
            LineCopy.ModifyAll(Marked, true);
        end else begin
            LineCopy.SetRange("No.", "No.");
            LineCopy.ModifyAll(Marked, false);
        end;
        Commit();
    end;

    local procedure ActivateControls()
    begin
        if Header.Get("No.") then begin
            Status.Get(Header."Payment Class", Header."Status No.");
            RIBVisible := Status.RIB;
            AcceptationCodeVisible := Status."Acceptation Code";
            AmountVisible := Status.Amount;
            DebitAmountVisible := Status.Debit;
            CreditAmountVisible := Status.Credit;
            BankAccountCodeVisible := Status."Bank Account";
            DisableFields;
        end;
    end;

    [Scope('OnPrem')]
    procedure NavigateLine(PostingDate: Date)
    begin
        Navigate.SetDoc(PostingDate, "Document No.");
        Navigate.Run;
    end;

    local procedure IsBankInfoEditable(): Boolean
    begin
        exit(not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]));
    end;
}

