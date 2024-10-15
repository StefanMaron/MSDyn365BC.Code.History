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
          RunWorkflowOnSendPaymentOrderForApprovalCode(), DATABASE::"Payment Order Header",
          PmtOrderSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelPaymentOrderApprovalRequestCode(), DATABASE::"Payment Order Header",
          PmtOrderApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterIssuePaymentOrderCode(), DATABASE::"Payment Order Header",
          PmtOrderIssuedEventDescTxt, 0, false);
#endif

        // Sales Advance Letter
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendSalesAdvanceLetterForApprovalCode(), DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode(), DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleaseSalesAdvanceLetterCode(), DATABASE::"Sales Advance Letter Header",
          SalesAdvanceLetterReleasedEventDescTxt, 0, false);

        // Purchase Advance Letter
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode(), DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode(), DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
          RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode(), DATABASE::"Purch. Advance Letter Header",
          PurchAdvanceLetterReleasedEventDescTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
#if not CLEAN19
            RunWorkflowOnCancelPaymentOrderApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelPaymentOrderApprovalRequestCode(),
                  RunWorkflowOnSendPaymentOrderForApprovalCode());
#endif
            RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode(),
                  RunWorkflowOnSendSalesAdvanceLetterForApprovalCode());
            RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode(),
                  RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode());
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode():
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                      RunWorkflowOnSendPaymentOrderForApprovalCode());
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode());
                end;
            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode():
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                      RunWorkflowOnSendPaymentOrderForApprovalCode());
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode());
                end;
            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode():
                begin
#if not CLEAN19
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                      RunWorkflowOnSendPaymentOrderForApprovalCode());
#endif
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode());
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
        exit('RUNWORKFLOWONSENDPAYMENTORDERFORAPPROVAL');
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELPAYMENTORDERAPPROVALREQUEST');
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIssuePaymentOrderCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERISSUEPAYMENTORDER');
    end;

#endif
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesAdvanceLetterForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDSALESADVANCELETTERFORAPPROVAL');
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELSALESADVANCELETTERAPPROVALREQUEST');
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseSalesAdvanceLetterCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRELEASESALESADVANCELETTER');
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDPURCHASEADVANCELETTERFORAPPROVAL');
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELPURCHASEADVANCELETTERAPPROVALREQUEST');
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRELEASEPURCHASEADVANCELETTER');
    end;

#if not CLEAN19
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPaymentOrderForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPaymentOrderForApproval(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPaymentOrderForApprovalCode(), PaymentOrderHeader);
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelPaymentOrderApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequest(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPaymentOrderApprovalRequestCode(), PaymentOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Issue Payment Order", 'OnAfterIssuePaymentOrder', '', false, false)]
    local procedure RunWorkflowOnAfterIssuePaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterIssuePaymentOrderCode(), PaymentOrderHeader);
    end;

#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendSalesAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesAdvanceLetterForApproval(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendSalesAdvanceLetterForApprovalCode(), SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelSalesAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesAdvanceLetterApprovalRequest(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode(), SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Advance Letter Header", 'OnAfterReleaseSalesAdvanceLetter', '', false, false)]
    local procedure RunWorkflowOnAfterReleaseSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseSalesAdvanceLetterCode(), SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPurchaseAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseAdvanceLetterForApproval(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode(), PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelPurchaseAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequest(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode(), PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Advance Letter Header", 'OnAfterReleasePurchaseAdvanceLetter', '', false, false)]
    local procedure RunWorkflowOnAfterReleasePurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode(), PurchAdvanceLetterHeader);
    end;
}
#endif