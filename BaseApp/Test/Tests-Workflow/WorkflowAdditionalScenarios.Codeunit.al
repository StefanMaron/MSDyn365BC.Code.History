codeunit 134317 "Workflow Additional Scenarios"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        PurchHeaderTypeCondnTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Doc. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Document Type=FILTER(%1))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        SalesHeaderTypeCondnTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Sales Doc. Event Conditions" id="1504"><DataItems><DataItem name="Sales Header">SORTING(Document Type,No.) WHERE(Document Type=FILTER(%1))</DataItem><DataItem name="Sales Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        SameEventConditionsErr: Label 'One or more entry-point steps exist that use the same event on table %1. You must specify unique event conditions on entry-point steps that use the same table.', Comment = '%1=Table Caption';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterInvoiceIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 1] The user can change the salesperson for a Sales Invoice after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Sales Invoice.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::Invoice);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterQuoteIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 2] The user can change the salesperson for a Sales Quote after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Sales Quote.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::Quote);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterOrderIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 3] The user can change the salesperson for a Sales Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Sales Order.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::Order);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterCreditMemoIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 4] The user can change the salesperson for a Sales Credit Memo after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Sales Credit Memo.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterReturnOrderIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 5] The user can change the salesperson for a Sales Return Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Sales Return Order.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::"Return Order");
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeSalespersonCodeAfterBlanketOrderIsApprovedAndReopened()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 6] The user can change the salesperson for a Blanket Sales Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Blanket Sales Order.
        // [WHEN] The user changes the salesperson code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Blanket Order", 1000);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        ChangeSalespersonForSalesDoc(SalesHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterInvoiceIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 7] The user can change the purchaser for a Purchase Invoice after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Purchase Invoice.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterQuoteIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 8] The user can change the purchaser for a Purchase Quote after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Purchase Quote.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::Quote);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Quote, 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterOrderIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 9] The user can change the purchaser for a Purchase Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Purchase Order.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::Order);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterCreditMemoIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 10] The user can change the purchaser for a Purchase Credit Memo after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Purchase Credit Memo.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterReturnOrderIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 11] The user can change the purchaser for a Purchase Return Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Purchase Return Order.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangePurcahserCodeAfterBlanketOrderIsApprovedAndReopened()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 12] The user can change the purchaser for a Blanket Purchase Order after the doc was approved and reopened.
        // [GIVEN] There is an approved and reopened Blanket Purchase Order.
        // [WHEN] The user changes the purchaser code.
        // [THEN] There is no error and the change is done.

        // Setup
        Initialize;
        CreateApprovalWorkflowForPurchaseDocument(PurchaseHeader."Document Type"::"Blanket Order");
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", 1000);
        WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);

        // Execute
        ChangePurchaserForPurchaseDoc(PurchaseHeader);

        // Verify
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestApproveSalesDocWhileCustomerIsAlsoAwaitingApproval()
    var
        CustomerWorkflow: Record Workflow;
        SalesDocWorkflow: Record Workflow;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesDocApprovalEntry: Record "Approval Entry";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowSetup: Codeunit "Workflow Setup";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        // [SCENARIO] When a customer approval and sales doc approval are active in the same time, the workflow engine executes the correct event from the correct instance.
        // [GIVEN] A customer approval workflow instance and a sales order approval workflow instance.
        // [WHEN] The users decides to approve the sales order approval request.
        // [THEN] The event to approve a record is executed from the sales order approval workflow, and not from the customer approval workflow.

        // Setup
        Initialize;
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        LibraryWorkflow.CreateEnabledWorkflow(CustomerWorkflow, WorkflowSetup.CustomerWorkflowCode);
        LibraryWorkflow.CopyWorkflowTemplate(SalesDocWorkflow, WorkflowSetup.SalesOrderApprovalWorkflowCode);
        LibraryWorkflow.SetWorkflowDirectApprover(SalesDocWorkflow.Code);
        LibraryWorkflow.EnableWorkflow(SalesDocWorkflow);

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, 100);
        LibrarySales.CreateCustomer(Customer);

        WorkflowEventHandling.RunWorkflowOnSendCustomerForApproval(Customer);
        WorkflowEventHandling.RunWorkflowOnSendSalesDocForApproval(SalesHeader);

        // Execute
        SalesDocApprovalEntry.SetRange("Record ID to Approve", SalesHeader.RecordId);
        SalesDocApprovalEntry.FindFirst;

        SalesDocApprovalEntry."Approver ID" := UserId;
        SalesDocApprovalEntry.Modify();

        RequeststoApprove.OpenView;
        RequeststoApprove.GotoRecord(SalesDocApprovalEntry);
        RequeststoApprove.Approve.Invoke;

        // Verify
        WorkflowStepInstance.SetRange("Workflow Code", SalesDocWorkflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, 'Wrong workflow step was executed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableSameNoRules()
    var
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowSetup: Codeunit "Workflow Setup";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Try to enable multiple identical workflows that have same conditions and no rules.
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Same event conditions specified on Workflow Events
        // [GIVEN] One instance of the workflow is enabled.
        // [WHEN] User marks the Enabled checkbox on the second instance of the same workflow
        // [THEN] The second workflow cannot be enabled.

        // Setup
        LibraryWorkflow.CopyWorkflowTemplate(Workflow1, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode);
        LibraryWorkflow.CopyWorkflowTemplate(Workflow2, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode);
        Workflow1.Validate(Enabled, true);
        Workflow1.Modify();

        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetRange("Workflow Code", Workflow1.Code);
        WorkflowStep.FindFirst;
        WorkflowEvent.SetRange("Function Name", WorkflowStep."Function Name");
        WorkflowEvent.FindFirst;
        RecRef.Open(WorkflowEvent."Table ID");

        // Exercise
        asserterror Workflow2.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(StrSubstNo(SameEventConditionsErr, RecRef.Caption));
    end;

    [Test]
    [HandlerFunctions('ExpectedMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOnceStartedWorkflowCanContinueEvenIfWorkflowIsDisabled()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 201613] Started but disabled workflow must be finished
        Initialize;

        // [GIVEN] Two users with the second one as the Direct Approver for the first one.
        // [GIVEN] Sales Document Approval Workflow "WF" with 3 events and responses, where every response matches the following event.
        // [GIVEN] "WF" has Approver as Approver Type and Direct Approver as Approver Limit Type.
        LibraryDocumentApprovals.SetupUsersForApprovals(UserSetup);
        CreateWorkflowTableRelationsFromApprovalEntryToSalesHeader;
        CreateApprovalWorkflowForSalesDocWithThreeLinkedEventsAndResponses(LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Invoice "SI" created by initial user and send to approval
        LibrarySales.CreateSalesInvoice(SalesHeader);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] All workflows including "WF" are disabled.
        LibraryWorkflow.DisableAllWorkflows;

        // [WHEN] "SI" is approved.
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);

        // [THEN] "SI" status changed according to the second Workflow response.
        // [THEN] A message invoked from the third response is verifyed with ExpectedMessageHandler.
        SalesHeader.Find;
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Additional Scenarios");
        LibraryVariableStorage.Clear;
        Workflow.SetRange(Template, false);
        Workflow.ModifyAll(Enabled, false, true);
        LibraryERMCountryData.CreateVATData;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Additional Scenarios");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Additional Scenarios");
    end;

    local procedure CreateApprovalWorkflowForSalesDocument(DocType: Enum "Sales Document Type")
    var
        Workflow: Record Workflow;
        EntryPoint: Integer;
        FirstResponse: Integer;
        SecondResponse: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPoint := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode);
        LibraryWorkflow.InsertEventArgument(EntryPoint, StrSubstNo(SalesHeaderTypeCondnTxt, DocType));

        FirstResponse := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.SetStatusToPendingApprovalCode, EntryPoint);

        SecondResponse := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreateAndApproveApprovalRequestAutomaticallyCode, FirstResponse);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode, SecondResponse);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateApprovalWorkflowForSalesDocWithThreeLinkedEventsAndResponses(Message: Text[10])
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        EntryPointStepID: Integer;
        FirstResponse: Integer;
        SecondResponse: Integer;
        SecondStepID: Integer;
        ThirdResponse: Integer;
        ThirdStepID: Integer;
        FourthResponse: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointStepID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode);

        FirstResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode, EntryPointStepID);

        WorkflowStep.SetRange(ID, FirstResponse);
        WorkflowStep.FindFirst;
        LibraryWorkflow.UpdateWorkflowStepArgumentApproverLimitType(
          WorkflowStep.Argument, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", '', '');

        SecondResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode, FirstResponse);

        SecondStepID :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode, SecondResponse);
        ThirdResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode, SecondStepID);

        ThirdStepID :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleaseSalesDocCode, ThirdResponse);
        FourthResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode, ThirdStepID);

        WorkflowStep.SetRange(ID, FourthResponse);
        WorkflowStep.FindFirst;
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.Message := Message;
        WorkflowStepArgument.Modify(true);

        LibraryWorkflow.EnableWorkflow(Workflow);

        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure CreateApprovalWorkflowForPurchaseDocument(DocType: Enum "Purchase Document Type")
    var
        Workflow: Record Workflow;
        EntryPoint: Integer;
        FirstResponse: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPoint :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode);
        LibraryWorkflow.InsertEventArgument(EntryPoint, StrSubstNo(PurchHeaderTypeCondnTxt, DocType));

        FirstResponse := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreateAndApproveApprovalRequestAutomaticallyCode, EntryPoint);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode, FirstResponse);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure ChangeSalespersonForSalesDoc(SalesHeader: Record "Sales Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.FindFirst;

        SalesHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SalesHeader.Modify(true);
    end;

    local procedure ChangePurchaserForPurchaseDoc(PurchaseHeader: Record "Purchase Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.FindFirst;

        PurchaseHeader.Validate("Purchaser Code", SalespersonPurchaser.Code);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateWorkflowTableRelationsFromApprovalEntryToSalesHeader()
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
    begin
        LibraryWorkflow.CreateWorkflowTableRelation(
          WorkflowTableRelation, DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Document No."),
          DATABASE::"Sales Header", SalesHeader.FieldNo("No."));
        LibraryWorkflow.CreateWorkflowTableRelation(
          WorkflowTableRelation, DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Document Type"),
          DATABASE::"Sales Header", SalesHeader.FieldNo("Document Type"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExpectedMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure DisableTaskOnBeforeJobQueueScheduleTask(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true
    end;
}

