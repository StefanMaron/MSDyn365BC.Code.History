page 11716 "Payment Order"
{
    Caption = 'Payment Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    RefreshOnActivate = true;
    SourceTable = "Payment Order Header";

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
                    ToolTip = 'Specifies the number of the payment order.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
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
                field("Foreign Payment Order"; "Foreign Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the foreign or domestic payment order.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the date on which you created the document.';
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
                            CurrPage.Update;
                        end;
                    end;
                }
                field("Payment Order Currency Code"; "Payment Order Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order currency code.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Payment Order Currency Code", "Payment Order Currency Factor", "Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Payment Order Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                    end;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of vendor''s document.';
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the payment order.';
                }
                field("Uncertainty Pay.Check DateTime"; "Uncertainty Pay.Check DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the check of uncertainty.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    QuickEntry = false;
                    ToolTip = 'Specifies the status of credit card';
                }
            }
            part(Lines; "Payment Order Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Payment Order No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group("Debet/Credit")
            {
                Caption = 'Debet/Credit';
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for payment order lines. The program calculates this amount from the sum of line amount fields on payment order lines.';
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of, if it is a debit amount.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total credit amount for issued payment order lines. The program calculates this credit amount from the sum of line credit fields on issued payment order lines.';
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
        area(factboxes)
        {
            systempart(Control1220034; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220033; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            part(Control1220037; "Approval FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = CONST(11708),
                              "Document No." = FIELD("No.");
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Payment Order")
            {
                Caption = '&Payment Order';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Payment Order Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected payment order.';
                }
                action("A&pprovals")
                {
                    ApplicationArea = Suite;
                    Caption = 'A&pprovals';
                    Image = Approvals;
                    ToolTip = 'This function opens the approvals entries.';

                    trigger OnAction()
                    var
                        ApprovalEntries: Page "Approval Entries";
                    begin
                        ApprovalEntries.Setfilters(DATABASE::"Payment Order Header", 0, "No.");
                        ApprovalEntries.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Relations to the workflow.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Rejects cash document';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Specifies enu delegate of payment order.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Specifies payment order comments.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Suggest Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Payments';
                    Ellipsis = true;
                    Image = SuggestPayment;
                    ToolTip = 'Opens suggest payments lines page';

                    trigger OnAction()
                    var
                        SuggestPayments: Report "Suggest Payments";
                    begin
                        SuggestPayments.SetPaymentOrder(Rec);
                        SuggestPayments.RunModal;
                    end;
                }
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Allows to import payment order prepared as file without the system.';

                    trigger OnAction()
                    begin
                        ImportPaymentOrder;
                    end;
                }
                action("Uncertainty VAT Payment Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Uncertainty VAT Payment Check';
                    Image = ElectronicPayment;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Checks uncertaintie vat of the vendor';

                    trigger OnAction()
                    var
                        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
                    begin
                        UncPayerMgt.ImportUncPayerStatusForPaymentOrder(Rec);
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
                    ToolTip = 'Specifies test report';

                    trigger OnAction()
                    begin
                        TestPrintPaymentOrder;
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
                    ToolTip = 'Issue the payment order to indicate that it has been printed or exported. Payment order will be moved to issued payment order.';

                    trigger OnAction()
                    begin
                        Issue(CODEUNIT::"Issue Payment Order (Yes/No)");
                    end;
                }
                action(IssueAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue and &Print';
                    Image = ConfirmAndPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Issue and prepare to print the payment order. Payment order will be moved to issued payment order.';

                    trigger OnAction()
                    begin
                        Issue(CODEUNIT::"Issue Payment Order + Print");
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Opens cash document';

                    trigger OnAction()
                    var
                        IssuePaymentOrder: Codeunit "Issue Payment Order";
                    begin
                        IssuePaymentOrder.PerformManualReopen(Rec);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckPaymentOrderApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendPaymentOrderForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelPaymentOrderApprovalRequest(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility;
        FilterGroup := 2;
        if not (GetFilter("Bank Account No.") <> '') then begin
            if "Bank Account No." <> '' then
                SetRange("Bank Account No.", "Bank Account No.");
        end;
        FilterGroup := 0;
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
        ShowWorkflowStatus: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        OpenIssuedPayOrdQst: Label 'The payment order has been issued and moved to the Issued Payment Orders window.\\Do you want to open the issued payment orders?';

    local procedure Issue(IssuingCodeunitID: Integer)
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        SendToIssuing(IssuingCodeunitID);
        CurrPage.Update(false);

        if IssuingCodeunitID <> CODEUNIT::"Issue Payment Order (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.GetOpeningIssuedDocumentNotificationId) then
            ShowIssuedConfirmationMessage("No.");
    end;

    local procedure ShowIssuedConfirmationMessage(PreAssignedNo: Code[20])
    var
        IssuedPaymentOrderHeader: Record "Issued Payment Order Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        IssuedPaymentOrderHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if IssuedPaymentOrderHeader.FindFirst then
            if InstructionMgt.ShowConfirm(OpenIssuedPayOrdQst, InstructionMgt.ShowIssuedConfirmationMessageCode) then
                PAGE.Run(PAGE::"Issued Payment Order", IssuedPaymentOrderHeader);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option "Bank Statement","Payment Order";
    begin
        DocNoVisible := DocumentNoVisibility.BankDocumentNoIsVisible("Bank Account No.", DocType::"Payment Order", "No.");
    end;

    local procedure TestPrintPaymentOrder()
    var
        PmtOrdHdr: Record "Payment Order Header";
    begin
        CurrPage.SetSelectionFilter(PmtOrdHdr);
        PmtOrdHdr.TestPrintRecords(true);
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}

