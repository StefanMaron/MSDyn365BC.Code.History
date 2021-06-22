codeunit 1541 "Workflow Webhook Events"
{

    trigger OnRun()
    begin
    end;

    var
        WorkflowWebhookResponseReceivedEventTxt: Label 'A response is received from a subscribed webhook.';

    procedure WorkflowWebhookResponseReceivedEventCode(): Code[128]
    begin
        exit(UpperCase('WorkflowWebhookResponseReceivedEvent'));
    end;

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookEventHierarchiesToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            WorkflowWebhookResponseReceivedEventCode:
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode,
                      WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(WorkflowWebhookResponseReceivedEventCode, DATABASE::"Workflow Webhook Entry",
          WorkflowWebhookResponseReceivedEventTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1520, 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookTableRelationsToLibrary()
    var
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        DummyGenJournalBatch: Record "Gen. Journal Batch";
        DummyGenJournalLine: Record "Gen. Journal Line";
        DummyPurchaseHeader: Record "Purchase Header";
        DummySalesHeader: Record "Sales Header";
        DummyVendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(DATABASE::Customer, DummyCustomer.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Gen. Journal Batch", DummyGenJournalBatch.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Gen. Journal Line", DummyGenJournalLine.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::Item, DummyItem.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Sales Header", DummySalesHeader.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::Vendor, DummyVendor.FieldNo(Id),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [EventSubscriber(ObjectType::Codeunit, 1543, 'OnCancelWorkflow', '', false, false)]
    local procedure HandleOnCancelWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode, WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1543, 'OnContinueWorkflow', '', false, false)]
    local procedure HandleOnContinueWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode, WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1543, 'OnRejectWorkflow', '', false, false)]
    local procedure HandleOnRejectWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode, WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelCustomerApprovalRequest', '', false, false)]
    local procedure HandleOnCancelCustomerApprovalRequest(var Customer: Record Customer)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a Customer is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Customer.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelItemApprovalRequest', '', false, false)]
    local procedure HandleOnCancelItemApprovalRequest(var Item: Record Item)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when an Item is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Item.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelGeneralJournalBatchApprovalRequest', '', false, false)]
    local procedure HandleOnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a General Journal Batch is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(GenJournalBatch.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelGeneralJournalLineApprovalRequest', '', false, false)]
    local procedure HandleOnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a General Journal Line is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(GenJournalLine.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnCancelVendorApprovalRequest', '', false, false)]
    local procedure HandleOnCancelVendorApprovalRequest(var Vendor: Record Vendor)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a Vendor is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Vendor.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnDeleteRecordInApprovalRequest', '', false, false)]
    local procedure HandleOnDeleteRecordInApprovalRequest(RecordIDToApprove: RecordID)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.DeleteWorkflowWebhookEntries(RecordIDToApprove);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnRenameRecordInApprovalRequest', '', false, false)]
    local procedure HandleOnRenameRecordInApprovalRequest(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.RenameRecord(OldRecordId, NewRecordId);
    end;
}

