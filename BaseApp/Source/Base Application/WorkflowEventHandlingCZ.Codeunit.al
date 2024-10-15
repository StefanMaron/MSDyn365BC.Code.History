#if not CLEAN19
codeunit 31110 "Workflow Event Handling CZ"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The codeunit is replaced by codeunits in CZ applications.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        PmtOrderSendForApprovalEventDescTxt: Label 'Approval of a payment order is requested. (Obsolete)';
        PmtOrderApprReqCancelledEventDescTxt: Label 'An approval request for a payment order is canceled. (Obsolete)';
        PmtOrderIssuedEventDescTxt: Label 'A payment order is issued. (Obsolete)';
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowSetup: Codeunit "Workflow Setup";
#if not CLEAN17
        CashDocSendForApprovalEventDescTxt: Label 'Approval of a cash document is requested. (Obsolete)';
        CashDocApprReqCancelledEventDescTxt: Label 'An approval request for a cash document is canceled. (Obsolete)';
        CashDocReleasedEventDescTxt: Label 'A cash document is released. (Obsolete)';
#endif
#if not CLEAN18
        CreditDocSendForApprovalEventDescTxt: Label 'Approval of a credit is requested. (Obsolete)';
        CreditDocApprReqCancelledEventDescTxt: Label 'An approval request for a credit is canceled. (Obsolete)';
        CreditDocReleasedEventDescTxt: Label 'A credit is released. (Obsolete)';
#endif
        SalesAdvanceLetterSendForApprovalEventDescTxt: Label 'Approval of a sales advance letter is requested. (Obsolete)';
        SalesAdvanceLetterApprReqCancelledEventDescTxt: Label 'An approval request for a sales advance letter is canceled. (Obsolete)';
        SalesAdvanceLetterReleasedEventDescTxt: Label 'A sales advance letter is released. (Obsolete)';
        PurchAdvanceLetterSendForApprovalEventDescTxt: Label 'Approval of a purchase advance letter is requested. (Obsolete)';
        PurchAdvanceLetterApprReqCancelledEventDescTxt: Label 'An approval request for a purchase advance letter is canceled. (Obsolete)';
        PurchAdvanceLetterReleasedEventDescTxt: Label 'A purchase advance letter is released. (Obsolete)';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure AddWorkflowEventsToLibrary()
    begin
#if not CLEAN19
        // Payment Order
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendPaymentOrderForApprovalCode, DATABASE::"Payment Order Header",
          PmtOrderSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelPaymentOrderApprovalRequestCode, DATABASE::"Payment Order Header",
          PmtOrderApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterIssuePaymentOrderCode, DATABASE::"Payment Order Header",
          PmtOrderIssuedEventDescTxt, 0, false);
#endif
#if not CLEAN17
        // Cash Document
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendCashDocForApprovalCode, DATABASE::"Cash Document Header",
          CashDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelCashDocApprovalRequestCode, DATABASE::"Cash Document Header",
          CashDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleaseCashDocCode, DATABASE::"Cash Document Header",
          CashDocReleasedEventDescTxt, 0, false);
#endif
#if not CLEAN18
        // Credit
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendCreditDocForApprovalCode, DATABASE::"Credit Header",
          CreditDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelCreditApprovalRequestCode, DATABASE::"Credit Header",
          CreditDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleaseCreditDocCode, DATABASE::"Credit Header",
          CreditDocReleasedEventDescTxt, 0, false);
#endif

        // Sales Advance Letter
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendSalesAdvanceLetterForApprovalCode, DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode, DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleaseSalesAdvanceLetterCode, DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterReleasedEventDescTxt, 0, false);

        // Purchase Advance Letter
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode, DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode, DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode, DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterReleasedEventDescTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
#if not CLEAN19
            RunWorkflowOnCancelPaymentOrderApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelPaymentOrderApprovalRequestCode,
                  RunWorkflowOnSendPaymentOrderForApprovalCode);
#endif
#if not CLEAN17
            RunWorkflowOnCancelCashDocApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelCashDocApprovalRequestCode,
                  RunWorkflowOnSendCashDocForApprovalCode);
#endif
#if not CLEAN18
            RunWorkflowOnCancelCreditApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelCreditApprovalRequestCode,
                  RunWorkflowOnSendCreditDocForApprovalCode);
#endif
            RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode,
                  RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
            RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode,
                  RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode:
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
#endif
#if not CLEAN17
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
#endif
#if not CLEAN18
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode:
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
#endif
#if not CLEAN17
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
#endif
#if not CLEAN18
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode:
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
#endif
#if not CLEAN17
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
#endif
#if not CLEAN18
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddWorkflowTableRelationsToLibrary()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
#if not CLEAN19
        WorkflowSetup.InsertTableRelation(DATABASE::"Payment Order Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
#endif
#if not CLEAN17
        WorkflowSetup.InsertTableRelation(DATABASE::"Cash Document Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
#endif
#if not CLEAN18
        WorkflowSetup.InsertTableRelation(DATABASE::"Credit Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
#endif
        WorkflowSetup.InsertTableRelation(DATABASE::"Sales Advance Letter Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Purch. Advance Letter Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
    end;

#if not CLEAN19
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPaymentOrderForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendPaymentOrderForApproval'));
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelPaymentOrderApprovalRequest'));
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIssuePaymentOrderCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterIssuePaymentOrder'));
    end;

#endif
#if not CLEAN17
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCashDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendCashDocForApproval'));
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCashDocApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelCashDocApprovalRequest'));
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCashDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseCashDoc'));
    end;

#endif
#if not CLEAN18
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCreditDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendCreditDocForApproval'));
    end;

    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCreditApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelCreditApprovalRequest'));
    end;

    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCreditDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseCreditDoc'));
    end;

#endif
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesAdvanceLetterForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendSalesAdvanceLetterForApproval'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelSalesAdvanceLetterApprovalRequest'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseSalesAdvanceLetterCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseSalesAdvanceLetter'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendPurchaseAdvanceLetterForApproval'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequest'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleasePurchaseAdvanceLetter'));
    end;

#if not CLEAN19
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPaymentOrderForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPaymentOrderForApproval(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPaymentOrderForApprovalCode, PaymentOrderHeader);
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelPaymentOrderApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequest(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPaymentOrderApprovalRequestCode, PaymentOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Issue Payment Order", 'OnAfterIssuePaymentOrder', '', false, false)]
    local procedure RunWorkflowOnAfterIssuePaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterIssuePaymentOrderCode, PaymentOrderHeader);
    end;

#endif
#if not CLEAN17
    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendCashDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCashDocForApproval(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCashDocForApprovalCode, CashDocHdr);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelCashDocApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCashDocApprovalRequest(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCashDocApprovalRequestCode, CashDocHdr);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Document-Release", 'OnAfterReleaseCashDoc', '', false, false)]
    local procedure RunWorkflowOnAfterReleaseCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseCashDocCode, CashDocHdr);
    end;

#endif
#if not CLEAN18
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendCreditDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCreditDocForApproval(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCreditDocForApprovalCode, CreditHdr);
    end;

    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelCreditApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCreditApprovalRequest(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCreditApprovalRequestCode, CreditHdr);
    end;

    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.1')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Credit Document", 'OnAfterReleaseCreditDoc', '', false, false)]
    local procedure RunWorkflowOnAfterReleaseCreditDoc(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseCreditDocCode, CreditHdr);
    end;

#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendSalesAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesAdvanceLetterForApproval(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendSalesAdvanceLetterForApprovalCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelSalesAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesAdvanceLetterApprovalRequest(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Advance Letter Header", 'OnAfterReleaseSalesAdvanceLetter', '', false, false)]
    local procedure RunWorkflowOnAfterReleaseSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseSalesAdvanceLetterCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPurchaseAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseAdvanceLetterForApproval(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode, PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelPurchaseAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequest(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode, PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Advance Letter Header", 'OnAfterReleasePurchaseAdvanceLetter', '', false, false)]
    local procedure RunWorkflowOnAfterReleasePurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode, PurchAdvanceLetterHeader);
    end;
}
#endif
