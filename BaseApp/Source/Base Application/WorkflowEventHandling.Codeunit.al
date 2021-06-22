codeunit 1520 "Workflow Event Handling"
{

    trigger OnRun()
    begin
    end;

    var
        IncDocReleasedEventDescTxt: Label 'An incoming document is released.';
        CreateDocFromIncDocSuccessfulEventDescTxt: Label 'Creating a document from an incoming document is successful.';
        CreateDocFromIncDocFailsEventDescTxt: Label 'Creating a document from an incoming document fails.';
        IncDocCreatedEventDescTxt: Label 'An incoming document is created.';
        IncDocIsReadyForOCREventDescTxt: Label 'An incoming document is ready for OCR.';
        IncDocIsSentForOCREventDescTxt: Label 'An incoming document is sent for OCR.';
        IncDocIsReceivedFromOCREventDescTxt: Label 'An incoming document is received from OCR.';
        IncDocIsReceivedFromDocExchEventDescTxt: Label 'An incoming document is received from document exchange.';
        IncDocSendForApprovalEventDescTxt: Label 'Approval of a incoming document is requested.';
        IncDocApprReqCancelledEventDescTxt: Label 'An approval request for an incoming document is canceled.';
        PurchDocSendForApprovalEventDescTxt: Label 'Approval of a purchase document is requested.';
        PurchDocApprReqCancelledEventDescTxt: Label 'An approval request for a purchase document is canceled.';
        PurchInvPostEventDescTxt: Label 'A purchase invoice is posted.';
        PurchDocReleasedEventDescTxt: Label 'A purchase document is released.';
        PurchInvPmtCreatedEventDescTxt: Label 'A general journal line is created.';
        ApprReqApprovedEventDescTxt: Label 'An approval request is approved.';
        ApprReqRejectedEventDescTxt: Label 'An approval request is rejected.';
        ApprReqDelegatedEventDescTxt: Label 'An approval request is delegated.';
        SalesDocSendForApprovalEventDescTxt: Label 'Approval of a sales document is requested.';
        SalesDocApprReqCancelledEventDescTxt: Label 'An approval request for a sales document is canceled.';
        SalesDocReleasedEventDescTxt: Label 'A sales document is released.';
        EventAlreadyExistErr: Label 'An event with description %1 already exists.';
        SendOverdueNotifTxt: Label 'The overdue approval notifications batch job will be run.';
        CustomerCreditLimitExceededTxt: Label 'A customer credit limit is exceeded.';
        CustomerCreditLimitNotExceededTxt: Label 'A customer credit limit is not exceeded.';
        CustomerSendForApprovalEventDescTxt: Label 'Approval of a customer is requested.';
        VendorSendForApprovalEventDescTxt: Label 'Approval of a vendor is requested.';
        ItemSendForApprovalEventDescTxt: Label 'Approval of an item is requested.';
        CustomerApprovalRequestCancelEventDescTxt: Label 'An approval request for a customer is canceled.';
        VendorApprovalRequestCancelEventDescTxt: Label 'An approval request for a vendor is canceled.';
        ItemApprovalRequestCancelEventDescTxt: Label 'An approval request for an item is canceled.';
        WorkflowManagement: Codeunit "Workflow Management";
        GeneralJournalBatchSendForApprovalEventDescTxt: Label 'Approval of a general journal batch is requested.';
        GeneralJournalBatchApprovalRequestCancelEventDescTxt: Label 'An approval request for a general journal batch is canceled.';
        GeneralJournalLineSendForApprovalEventDescTxt: Label 'Approval of a general journal line is requested.';
        GeneralJournalLineApprovalRequestCancelEventDescTxt: Label 'An approval request for a general journal line is canceled.';
        GeneralJournalBatchBalancedEventDescTxt: Label 'A general journal batch is balanced.';
        GeneralJournalBatchNotBalancedEventDescTxt: Label 'A general journal batch is not balanced.';
        ImageOrPDFIsAttachedToAnIncomingDocEventDescTxt: Label 'An image or pdf is attached to a new incoming document for OCR.';
        CustChangedTxt: Label 'A customer record is changed.';
        VendChangedTxt: Label 'A vendor record is changed.';
        ItemChangedTxt: Label 'An item record is changed.';
        CreateGenJnlLineFromIncDocSuccessfulEventDescTxt: Label 'The creation of a general journal line from the incoming document was successful.';
        CreateGenJnlLineFromIncDocFailsEventDescTxt: Label 'The creation of a general journal line from the incoming document failed.';

    procedure CreateEventsLibrary()
    begin
        AddEventToLibrary(
          RunWorkflowOnAfterInsertIncomingDocumentCode, DATABASE::"Incoming Document", IncDocCreatedEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReleaseIncomingDocCode, DATABASE::"Incoming Document", IncDocReleasedEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode,
          DATABASE::"Incoming Document", CreateDocFromIncDocSuccessfulEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateDocFromIncomingDocFailCode, DATABASE::"Incoming Document", CreateDocFromIncDocFailsEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReadyForOCRIncomingDocCode, DATABASE::"Incoming Document", IncDocIsReadyForOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterSendToOCRIncomingDocCode, DATABASE::"Incoming Document", IncDocIsSentForOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReceiveFromOCRIncomingDocCode, DATABASE::"Incoming Document", IncDocIsReceivedFromOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode,
          DATABASE::"Incoming Document", IncDocIsReceivedFromDocExchEventDescTxt, 0, false);

        AddEventToLibrary(
          RunWorkflowOnSendPurchaseDocForApprovalCode, DATABASE::"Purchase Header", PurchDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnSendIncomingDocForApprovalCode, DATABASE::"Incoming Document", IncDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnCancelIncomingDocApprovalRequestCode, DATABASE::"Incoming Document", IncDocApprReqCancelledEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCancelPurchaseApprovalRequestCode, DATABASE::"Purchase Header",
          PurchDocApprReqCancelledEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnAfterReleasePurchaseDocCode, DATABASE::"Purchase Header",
          PurchDocReleasedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnAfterPostPurchaseDocCode, DATABASE::"Purch. Inv. Header",
          PurchInvPostEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendSalesDocForApprovalCode, DATABASE::"Sales Header",
          SalesDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelSalesApprovalRequestCode, DATABASE::"Sales Header",
          SalesDocApprReqCancelledEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnAfterReleaseSalesDocCode, DATABASE::"Sales Header",
          SalesDocReleasedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnAfterInsertGeneralJournalLineCode, DATABASE::"Gen. Journal Line",
          PurchInvPmtCreatedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnApproveApprovalRequestCode, DATABASE::"Approval Entry", ApprReqApprovedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnRejectApprovalRequestCode, DATABASE::"Approval Entry", ApprReqRejectedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnDelegateApprovalRequestCode, DATABASE::"Approval Entry", ApprReqDelegatedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendOverdueNotificationsCode, DATABASE::"Approval Entry", SendOverdueNotifTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCustomerCreditLimitExceededCode, DATABASE::"Sales Header",
          CustomerCreditLimitExceededTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCustomerCreditLimitNotExceededCode, DATABASE::"Sales Header",
          CustomerCreditLimitNotExceededTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendCustomerForApprovalCode, DATABASE::Customer,
          CustomerSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelCustomerApprovalRequestCode, DATABASE::Customer,
          CustomerApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendVendorForApprovalCode, DATABASE::Vendor,
          VendorSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelVendorApprovalRequestCode, DATABASE::Vendor,
          VendorApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendItemForApprovalCode, DATABASE::Item,
          ItemSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelItemApprovalRequestCode, DATABASE::Item,
          ItemApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendGeneralJournalBatchForApprovalCode, DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode, DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendGeneralJournalLineForApprovalCode, DATABASE::"Gen. Journal Line",
          GeneralJournalLineSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode, DATABASE::"Gen. Journal Line",
          GeneralJournalLineApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnGeneralJournalBatchBalancedCode, DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchBalancedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnGeneralJournalBatchNotBalancedCode, DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchNotBalancedEventDescTxt, 0, false);

        AddEventToLibrary(
          RunWorkflowOnBinaryFileAttachedCode,
          DATABASE::"Incoming Document Attachment", ImageOrPDFIsAttachedToAnIncomingDocEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCustomerChangedCode, DATABASE::Customer, CustChangedTxt, 0, true);
        AddEventToLibrary(RunWorkflowOnVendorChangedCode, DATABASE::Vendor, VendChangedTxt, 0, true);
        AddEventToLibrary(RunWorkflowOnItemChangedCode, DATABASE::Item, ItemChangedTxt, 0, true);

        AddEventToLibrary(
          RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode, DATABASE::"Incoming Document",
          CreateGenJnlLineFromIncDocSuccessfulEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode, DATABASE::"Incoming Document",
          CreateGenJnlLineFromIncDocFailsEventDescTxt, 0, false);

        OnAddWorkflowEventsToLibrary;
        OnAddWorkflowTableRelationsToLibrary;
    end;

    local procedure AddEventPredecessors(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            RunWorkflowOnAfterPostPurchaseDocCode:
                AddEventPredecessor(RunWorkflowOnAfterPostPurchaseDocCode, RunWorkflowOnAfterReleasePurchaseDocCode);
            RunWorkflowOnCancelIncomingDocApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelIncomingDocApprovalRequestCode, RunWorkflowOnSendIncomingDocForApprovalCode);
            RunWorkflowOnCancelPurchaseApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelPurchaseApprovalRequestCode, RunWorkflowOnSendPurchaseDocForApprovalCode);
            RunWorkflowOnCancelSalesApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelSalesApprovalRequestCode, RunWorkflowOnSendSalesDocForApprovalCode);
            RunWorkflowOnCancelCustomerApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelCustomerApprovalRequestCode, RunWorkflowOnSendCustomerForApprovalCode);
            RunWorkflowOnCancelVendorApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelVendorApprovalRequestCode, RunWorkflowOnSendVendorForApprovalCode);
            RunWorkflowOnCancelItemApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelItemApprovalRequestCode, RunWorkflowOnSendItemForApprovalCode);
            RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode,
                  RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
            RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode:
                AddEventPredecessor(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode,
                  RunWorkflowOnSendGeneralJournalLineForApprovalCode);
            RunWorkflowOnCustomerCreditLimitExceededCode:
                AddEventPredecessor(RunWorkflowOnCustomerCreditLimitExceededCode, RunWorkflowOnSendSalesDocForApprovalCode);
            RunWorkflowOnCustomerCreditLimitNotExceededCode:
                AddEventPredecessor(RunWorkflowOnCustomerCreditLimitNotExceededCode, RunWorkflowOnSendSalesDocForApprovalCode);
            RunWorkflowOnApproveApprovalRequestCode:
                begin
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendIncomingDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendPurchaseDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendSalesDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendCustomerForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendVendorForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendItemForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnGeneralJournalBatchBalancedCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendGeneralJournalLineForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnCustomerChangedCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnVendorChangedCode);
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnItemChangedCode);
                end;
            RunWorkflowOnRejectApprovalRequestCode:
                begin
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendIncomingDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendPurchaseDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendSalesDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendCustomerForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendVendorForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendItemForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnGeneralJournalBatchBalancedCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendGeneralJournalLineForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnCustomerChangedCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnVendorChangedCode);
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnItemChangedCode);
                end;
            RunWorkflowOnDelegateApprovalRequestCode:
                begin
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendIncomingDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendPurchaseDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendSalesDocForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendCustomerForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendVendorForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendItemForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnGeneralJournalBatchBalancedCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendGeneralJournalLineForApprovalCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnCustomerChangedCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnVendorChangedCode);
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnItemChangedCode);
                end;
            RunWorkflowOnGeneralJournalBatchBalancedCode:
                AddEventPredecessor(RunWorkflowOnGeneralJournalBatchBalancedCode, RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
            RunWorkflowOnGeneralJournalBatchNotBalancedCode:
                AddEventPredecessor(RunWorkflowOnGeneralJournalBatchNotBalancedCode, RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
        end;

        OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName);
    end;

    procedure AddEventToLibrary(FunctionName: Code[128]; TableID: Integer; Description: Text[250]; RequestPageID: Integer; UsedForRecordChange: Boolean)
    var
        WorkflowEvent: Record "Workflow Event";
        SystemInitialization: Codeunit "System Initialization";
    begin
        if WorkflowEvent.Get(FunctionName) then
            exit;

        WorkflowEvent.SetRange(Description, Description);
        if not WorkflowEvent.IsEmpty then begin
            if SystemInitialization.IsInProgress or (GetExecutionContext() <> ExecutionContext::Normal) then
                exit;
            Error(EventAlreadyExistErr, Description);
        end;

        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := FunctionName;
        WorkflowEvent."Table ID" := TableID;
        WorkflowEvent.Description := Description;
        WorkflowEvent."Request Page ID" := RequestPageID;
        WorkflowEvent."Used for Record Change" := UsedForRecordChange;
        WorkflowEvent.Insert();

        AddEventPredecessors(WorkflowEvent."Function Name");
    end;

    procedure AddEventPredecessor(FunctionName: Code[128]; PredecessorFunctionName: Code[128])
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.Init();
        WFEventResponseCombination.Type := WFEventResponseCombination.Type::"Event";
        WFEventResponseCombination."Function Name" := FunctionName;
        WFEventResponseCombination."Predecessor Type" := WFEventResponseCombination."Predecessor Type"::"Event";
        WFEventResponseCombination."Predecessor Function Name" := PredecessorFunctionName;
        if WFEventResponseCombination.Insert() then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowTableRelationsToLibrary()
    begin
    end;

    procedure RunWorkflowOnAfterInsertIncomingDocumentCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterInsertIncomingDocument'));
    end;

    procedure RunWorkflowOnAfterReleaseIncomingDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseIncomingDoc'));
    end;

    procedure RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterCreateDocFromIncomingDocSuccess'));
    end;

    procedure RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterCreateDocFromIncomingDocFail'));
    end;

    procedure RunWorkflowOnAfterReadyForOCRIncomingDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterreadyforOCRIncomingDoc'));
    end;

    procedure RunWorkflowOnAfterSendToOCRIncomingDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterSendToOCRIncomingDoc'));
    end;

    procedure RunWorkflowOnAfterReceiveFromOCRIncomingDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReceiveFromOCRIncomingDoc'));
    end;

    procedure RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReceiveFromDocExchIncomingDoc'));
    end;

    procedure RunWorkflowOnSendPurchaseDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendPurchaseDocForApproval'));
    end;

    procedure RunWorkflowOnSendIncomingDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendIncomingDocForApproval'));
    end;

    procedure RunWorkflowOnCancelIncomingDocApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelIncomingDocApprovalRequest'));
    end;

    procedure RunWorkflowOnCancelPurchaseApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelPurchaseApprovalRequest'));
    end;

    procedure RunWorkflowOnAfterReleasePurchaseDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleasePurchaseDoc'));
    end;

    procedure RunWorkflowOnSendSalesDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendSalesDocForApproval'));
    end;

    procedure RunWorkflowOnCancelSalesApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelSalesApprovalRequest'));
    end;

    procedure RunWorkflowOnAfterReleaseSalesDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseSalesDoc'));
    end;

    procedure RunWorkflowOnAfterPostPurchaseDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterPostPurchaseDoc'));
    end;

    procedure RunWorkflowOnAfterInsertGeneralJournalLineCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterInsertGeneralJournalLine'));
    end;

    procedure RunWorkflowOnApproveApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnApproveApprovalRequest'));
    end;

    procedure RunWorkflowOnDelegateApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnDelegateApprovalRequest'));
    end;

    procedure RunWorkflowOnRejectApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnRejectApprovalRequest'));
    end;

    procedure RunWorkflowOnSendOverdueNotificationsCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendOverdueNotifications'));
    end;

    procedure RunWorkflowOnCustomerCreditLimitExceededCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCustomerCreditLimitExceeded'));
    end;

    procedure RunWorkflowOnCustomerCreditLimitNotExceededCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCustomerCreditLimitNotExceeded'));
    end;

    procedure RunWorkflowOnSendCustomerForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendCustomerForApproval'));
    end;

    procedure RunWorkflowOnSendVendorForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendVendorForApproval'));
    end;

    procedure RunWorkflowOnSendItemForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendItemForApproval'));
    end;

    procedure RunWorkflowOnCancelCustomerApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelCustomerApprovalRequest'));
    end;

    procedure RunWorkflowOnCancelVendorApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelVendorApprovalRequest'));
    end;

    procedure RunWorkflowOnCancelItemApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelItemApprovalRequest'));
    end;

    procedure RunWorkflowOnSendGeneralJournalBatchForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendGeneralJournalBatchForApproval'));
    end;

    procedure RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelGeneralJournalBatchApprovalRequest'));
    end;

    procedure RunWorkflowOnSendGeneralJournalLineForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendGeneralJournalLineForApproval'));
    end;

    procedure RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelGeneralJournalLineApprovalRequest'));
    end;

    procedure RunWorkflowOnGeneralJournalBatchBalancedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnGeneralJournalBatchBalanced'));
    end;

    procedure RunWorkflowOnGeneralJournalBatchNotBalancedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnGeneralJournalBatchNotBalanced'));
    end;

    procedure RunWorkflowOnBinaryFileAttachedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnBinaryFileAttached'));
    end;

    procedure RunWorkflowOnCustomerChangedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCustomerChangedCode'));
    end;

    procedure RunWorkflowOnVendorChangedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnVendorChangedCode'));
    end;

    procedure RunWorkflowOnItemChangedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnItemChangedCode'));
    end;

    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode'));
    end;

    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterCreateGenJnlLineFromIncomingDoFailCode'));
    end;

    [EventSubscriber(ObjectType::Table, 130, 'OnAfterInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterInsertIncomingDocument(var Rec: Record "Incoming Document"; RunTrigger: Boolean)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterInsertIncomingDocumentCode, Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendPurchaseDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendPurchaseDocForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPurchaseDocForApprovalCode, PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelPurchaseApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelPurchaseApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPurchaseApprovalRequestCode, PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendIncomingDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendIncomingDocForApproval(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendIncomingDocForApprovalCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelIncomingDocApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelIncomingDocApprovalRequest(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelIncomingDocApprovalRequestCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 415, 'OnAfterReleasePurchaseDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
        if not PreviewMode then
            WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleasePurchaseDocCode, PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendSalesDocForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendSalesDocForApproval(var SalesHeader: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendSalesDocForApprovalCode, SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelSalesApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelSalesApprovalRequest(var SalesHeader: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelSalesApprovalRequestCode, SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 414, 'OnAfterReleaseSalesDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
        if not PreviewMode then
            WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseSalesDocCode, SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 132, 'OnAfterReleaseIncomingDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterReleaseIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseIncomingDocCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 132, 'OnAfterCreateDocFromIncomingDocSuccess', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateDocFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 132, 'OnAfterCreateDocFromIncomingDocFail', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateDocFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateDocFromIncomingDocFailCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 133, 'OnAfterIncomingDocReadyForOCR', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIncomingDocReadyForOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReadyForOCRIncomingDocCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 133, 'OnAfterIncomingDocSentToOCR', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIncomingDocSentToOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterSendToOCRIncomingDocCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 133, 'OnAfterIncomingDocReceivedFromOCR', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIncomingDocReceivedFromOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReceiveFromOCRIncomingDocCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1410, 'OnAfterIncomingDocReceivedFromDocExch', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIncomingDocReceivedFromDocExch(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnAfterPostPurchaseDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice:
                begin
                    if PurchInvHeader.Get(PurchInvHdrNo) then
                        WorkflowManagement.HandleEvent(RunWorkflowOnAfterPostPurchaseDocCode, PurchInvHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnAfterInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterInsertGeneralJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterInsertGeneralJournalLineCode, Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnApproveApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnApproveApprovalRequestCode,
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnDelegateApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnDelegateApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnDelegateApprovalRequestCode,
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnRejectApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnRejectApprovalRequestCode,
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Report, 1509, 'OnSendOverdueNotifications', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendOverdueNotifications()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        WorkflowManagement.HandleEvent(RunWorkflowOnSendOverdueNotificationsCode, ApprovalEntry);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnCustomerCreditLimitExceeded', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCustomerCreditLimitExceeded(var Sender: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCustomerCreditLimitExceededCode, Sender);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnCustomerCreditLimitNotExceeded', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCustomerCreditLimitNotExceeded(var Sender: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCustomerCreditLimitNotExceededCode, Sender);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendCustomerForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendCustomerForApproval(Customer: Record Customer)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCustomerForApprovalCode, Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendVendorForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendVendorForApproval(Vendor: Record Vendor)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendVendorForApprovalCode, Vendor);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendItemForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendItemForApproval(Item: Record Item)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendItemForApprovalCode, Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelCustomerApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelCustomerApprovalRequest(Customer: Record Customer)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCustomerApprovalRequestCode, Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelVendorApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelVendorApprovalRequest(Vendor: Record Vendor)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelVendorApprovalRequestCode, Vendor);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelItemApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelItemApprovalRequest(Item: Record Item)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelItemApprovalRequestCode, Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendGeneralJournalBatchForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendGeneralJournalBatchForApproval(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendGeneralJournalBatchForApprovalCode, GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelGeneralJournalBatchApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode, GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnSendGeneralJournalLineForApproval', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnSendGeneralJournalLineForApproval(var GenJournalLine: Record "Gen. Journal Line")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendGeneralJournalLineForApprovalCode, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelGeneralJournalLineApprovalRequest', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, 232, 'OnGeneralJournalBatchBalanced', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnGeneralJournalBatchBalanced(var Sender: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnGeneralJournalBatchBalancedCode, Sender);
    end;

    [EventSubscriber(ObjectType::Table, 232, 'OnGeneralJournalBatchNotBalanced', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnGeneralJournalBatchNotBalanced(var Sender: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnGeneralJournalBatchNotBalancedCode, Sender);
    end;

    [EventSubscriber(ObjectType::Table, 133, 'OnAttachBinaryFile', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnBinaryFileAttached(var Sender: Record "Incoming Document Attachment")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnBinaryFileAttachedCode, Sender);
    end;

    [EventSubscriber(ObjectType::Table, 18, 'OnAfterModifyEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCustomerChanged(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    begin
        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnCustomerChangedCode, Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterModifyEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnVendorChanged(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnVendorChangedCode, Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, 27, 'OnAfterModifyEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnItemChanged(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if GenJnlPostPreview.IsActive then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnItemChangedCode, Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, 130, 'OnAfterCreateGenJnlLineFromIncomingDocSuccess', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode, IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Table, 130, 'OnAfterCreateGenJnlLineFromIncomingDocFail', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode, IncomingDocument);
    end;
}

