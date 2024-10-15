page 11719 "Payment Order List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Orders';
    CardPageID = "Payment Order";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    SourceTable = "Payment Order Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220010)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the payment order.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for payment order lines. The program calculates this amount from the sum of line amount fields on payment order lines.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the payment order.';
                }
                field("File Name"; "File Name")
                {
                    ToolTip = 'Specifies the name and address of the payment order file created in the system.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220024; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220023; Notes)
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
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Issue Payment Order (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Release the payment order to indicate that it has been printed or exported. The status then changes to Released.';
                }
                action("Release and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release and &Print';
                    Image = ConfirmAndPrint;
                    RunObject = Codeunit "Issue Payment Order + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Release and prepare to print the payment order.';
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
        SetControlAppearance;
    end;

    trigger OnOpenPage()
    var
        PaymentOrderMgt: Codeunit "Payment Order Management";
        StatSelected: Boolean;
    begin
        PaymentOrderMgt.PaymentOrderSelection(Rec, StatSelected);
        if not StatSelected then
            Error('');
    end;

    var
        OpenApprovalEntriesExist: Boolean;

    local procedure TestPrintPaymentOrder()
    var
        PmtOrdHdr: Record "Payment Order Header";
    begin
        CurrPage.SetSelectionFilter(PmtOrdHdr);
        PmtOrdHdr.TestPrintRecords(true);
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}

