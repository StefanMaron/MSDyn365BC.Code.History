#if not CLEAN19
page 11706 "Bank Statement"
{
    Caption = 'Bank Statement (Obsolete)';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Bank Statement Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

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
                    ToolTip = 'Specifies the number of the bank statement.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the date on which you created the document.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Bank Statement Currency Code"; "Bank Statement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank statement currency code in the bank statement.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Bank Statement Currency Code", "Bank Statement Currency Factor", "Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Bank Statement Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the external document number received from bank.';
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the bank statement.';
                }
            }
            part(Lines; "Bank Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Bank Statement No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group("Debit/Credit")
            {
                Caption = 'Debit/Credit';
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of.';
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a credit amount.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("Debit (LCY)"; "Debit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount. The amount is in the local currency.';
                }
                field("Credit (LCY)"; "Credit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a credit amount. The amount is in the local currency.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank statement")
            {
                Caption = '&Bank statement';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Bank Statement Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected bank statement.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Bank Statement Import")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Statement Import';
                    Ellipsis = true;
                    Image = ImportChartOfAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Allows import bank statement in the system.';

                    trigger OnAction()
                    begin
                        ImportBankStatement;
                    end;
                }
                action("Copy Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Payment Order';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Allows copy payment order in the bank statement.';

                    trigger OnAction()
                    begin
                        CopyPaymentOrder;
                    end;
                }
            }
            group("&Release")
            {
                Caption = '&Release';
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Report Specifies how the bank statement entries will be applied.';

                    trigger OnAction()
                    begin
                        TestPrintBankStatement;
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Issue the bank statement to indicate that it has been printed or exported. Bank statement will be moved to issued bank statemet.';

                    trigger OnAction()
                    begin
                        IssueBankStatement(CODEUNIT::"Issue Bank Statement (Yes/No)");
                    end;
                }
                action(IssueAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue and &Print';
                    Image = ConfirmAndPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Issue and print the bank statement. Bank statement will be moved to issued bank statemet.';

                    trigger OnAction()
                    begin
                        IssueBankStatement(CODEUNIT::"Issue Bank Statement + Print");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FilterGroup(2);
        if not (GetFilter("Bank Account No.") <> '') then begin
            if "Bank Account No." <> '' then
                SetRange("Bank Account No.", "Bank Account No.");
        end;
        FilterGroup(0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        BankAccount: Record "Bank Account";
    begin
        FilterGroup := 2;
        "Document Date" := WorkDate;
        "Bank Account No." := CopyStr(GetFilter("Bank Account No."), 1, MaxStrLen("Bank Account No."));
        FilterGroup := 0;
        CurrPage.Lines.PAGE.SetParameters("Bank Account No.");

        if BankAccount.Get("Bank Account No.") then
            BankAccount.CheckCurrExchRateExist("Document Date");

        Validate("Bank Account No.");
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible;
    end;

    var
        DocNoVisible: Boolean;
        OpenIssuedBankStmtQst: Label 'The bank statement has been issued and moved to the Issued Bank Statements window.\\Do you want to open the issued bank statements?';

    local procedure IssueBankStatement(IssuingCodeunitId: Integer)
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        CODEUNIT.Run(IssuingCodeunitId, Rec);
        CurrPage.Update(false);

        if IssuingCodeunitId <> CODEUNIT::"Issue Bank Statement (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.GetOpeningIssuedDocumentNotificationId) then
            ShowIssuedConfirmationMessage("No.");
    end;

    local procedure ShowIssuedConfirmationMessage(PreAssignedNo: Code[20])
    var
        IssuedBankStatementHeader: Record "Issued Bank Statement Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        IssuedBankStatementHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if IssuedBankStatementHeader.FindFirst then
            if InstructionMgt.ShowConfirm(OpenIssuedBankStmtQst, InstructionMgt.ShowIssuedConfirmationMessageCode) then
                PAGE.Run(PAGE::"Issued Bank Statement", IssuedBankStatementHeader);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option "Bank Statement","Payment Order";
    begin
        DocNoVisible := DocumentNoVisibility.BankDocumentNoIsVisible("Bank Account No.", DocType::"Bank Statement", "No.");
    end;

    local procedure CopyPaymentOrder()
    var
        BankStmtHdr: Record "Bank Statement Header";
        CopyPaymentOrder: Report "Copy Payment Order";
    begin
        BankStmtHdr.Get("No.");
        BankStmtHdr.SetRecFilter;
        CopyPaymentOrder.SetBankStmtHdr(BankStmtHdr);
        CopyPaymentOrder.RunModal;
        CurrPage.Update(false);
    end;

    local procedure TestPrintBankStatement()
    var
        BankStmtHdr: Record "Bank Statement Header";
    begin
        CurrPage.SetSelectionFilter(BankStmtHdr);
        BankStmtHdr.TestPrintRecords(true);
    end;
}
#endif
