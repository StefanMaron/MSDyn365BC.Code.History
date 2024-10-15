codeunit 31110 "Workflow Event Handling CZ"
{

    trigger OnRun()
    begin
    end;

    var
        PmtOrderSendForApprovalEventDescTxt: Label 'Approval of a payment order is requested.';
        PmtOrderApprReqCancelledEventDescTxt: Label 'An approval request for a payment order is canceled.';
        PmtOrderIssuedEventDescTxt: Label 'A payment order is issued.';
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowSetup: Codeunit "Workflow Setup";
        CashDocSendForApprovalEventDescTxt: Label 'Approval of a cash document is requested.';
        CashDocApprReqCancelledEventDescTxt: Label 'An approval request for a cash document is canceled.';
        CashDocReleasedEventDescTxt: Label 'A cash document is released.';
        CreditDocSendForApprovalEventDescTxt: Label 'Approval of a credit is requested.';
        CreditDocApprReqCancelledEventDescTxt: Label 'An approval request for a credit is canceled.';
        CreditDocReleasedEventDescTxt: Label 'A credit is released.';
        SalesAdvanceLetterSendForApprovalEventDescTxt: Label 'Approval of a sales advance letter is requested.';
        SalesAdvanceLetterApprReqCancelledEventDescTxt: Label 'An approval request for a sales advance letter is canceled.';
        SalesAdvanceLetterReleasedEventDescTxt: Label 'A sales advance letter is released.';
        PurchAdvanceLetterSendForApprovalEventDescTxt: Label 'Approval of a purchase advance letter is requested.';
        PurchAdvanceLetterApprReqCancelledEventDescTxt: Label 'An approval request for a purchase advance letter is canceled.';
        PurchAdvanceLetterReleasedEventDescTxt: Label 'A purchase advance letter is released.';

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowEventsToLibrary', '', false, false)]
    [Scope('OnPrem')]
    procedure AddWorkflowEventsToLibrary()
    begin
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

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    [Scope('OnPrem')]
    procedure AddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            RunWorkflowOnCancelPaymentOrderApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelPaymentOrderApprovalRequestCode,
                  RunWorkflowOnSendPaymentOrderForApprovalCode);
            RunWorkflowOnCancelCashDocApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelCashDocApprovalRequestCode,
                  RunWorkflowOnSendCashDocForApprovalCode);
            RunWorkflowOnCancelCreditApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(
                  RunWorkflowOnCancelCreditApprovalRequestCode,
                  RunWorkflowOnSendCreditDocForApprovalCode);
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
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode:
                begin
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode:
                begin
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendPaymentOrderForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendCashDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendCreditDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendSalesAdvanceLetterForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(
                      WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode,
                      RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    [Scope('OnPrem')]
    procedure AddWorkflowTableRelationsToLibrary()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        WorkflowSetup.InsertTableRelation(DATABASE::"Payment Order Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Cash Document Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Credit Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Sales Advance Letter Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Purch. Advance Letter Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPaymentOrderForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendPaymentOrderForApproval'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelPaymentOrderApprovalRequest'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIssuePaymentOrderCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterIssuePaymentOrder'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCashDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendCashDocForApproval'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCashDocApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelCashDocApprovalRequest'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCashDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseCashDoc'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCreditDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendCreditDocForApproval'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCreditApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelCreditApprovalRequest'));
    end;

    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCreditDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseCreditDoc'));
    end;

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

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendPaymentOrderForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPaymentOrderForApproval(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPaymentOrderForApprovalCode, PaymentOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelPaymentOrderApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPaymentOrderApprovalRequest(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPaymentOrderApprovalRequestCode, PaymentOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 11706, 'OnAfterIssuePaymentOrder', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIssuePaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterIssuePaymentOrderCode, PaymentOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendCashDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCashDocForApproval(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCashDocForApprovalCode, CashDocHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelCashDocApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCashDocApprovalRequest(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCashDocApprovalRequestCode, CashDocHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 11731, 'OnAfterReleaseCashDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseCashDocCode, CashDocHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendCreditDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCreditDocForApproval(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCreditDocForApprovalCode, CreditHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelCreditApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCreditApprovalRequest(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCreditApprovalRequestCode, CreditHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 31053, 'OnAfterReleaseCreditDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseCreditDoc(var CreditHdr: Record "Credit Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseCreditDocCode, CreditHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendSalesAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesAdvanceLetterForApproval(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendSalesAdvanceLetterForApprovalCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelSalesAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesAdvanceLetterApprovalRequest(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelSalesAdvanceLetterApprovalRequestCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, 31000, 'OnAfterReleaseSalesAdvanceLetter', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseSalesAdvanceLetterCode, SalesAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendPurchaseAdvanceLetterForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseAdvanceLetterForApproval(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPurchaseAdvanceLetterForApprovalCode, PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelPurchaseAdvanceLetterApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequest(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPurchaseAdvanceLetterApprovalRequestCode, PurchAdvanceLetterHeader);
    end;

    [EventSubscriber(ObjectType::Table, 31020, 'OnAfterReleasePurchaseAdvanceLetter', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleasePurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleasePurchaseAdvanceLetterCode, PurchAdvanceLetterHeader);
    end;
}

