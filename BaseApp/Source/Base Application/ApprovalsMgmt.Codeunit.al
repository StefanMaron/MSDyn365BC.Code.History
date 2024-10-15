codeunit 1535 "Approvals Mgmt."
{
    Permissions = TableData "Approval Entry" = imd,
                  TableData "Approval Comment Line" = imd,
                  TableData "Posted Approval Entry" = imd,
                  TableData "Posted Approval Comment Line" = imd,
                  TableData "Overdue Approval Entry" = imd,
                  TableData "Notification Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        UserIdNotInSetupErr: Label 'User ID %1 does not exist in the Approval User Setup window.', Comment = 'User ID NAVUser does not exist in the Approval User Setup window.';
        ApproverUserIdNotInSetupErr: Label 'You must set up an approver for user ID %1 in the Approval User Setup window.', Comment = 'You must set up an approver for user ID NAVUser in the Approval User Setup window.';
        WFUserGroupNotInSetupErr: Label 'The workflow user group member with user ID %1 does not exist in the Approval User Setup window.', Comment = 'The workflow user group member with user ID NAVUser does not exist in the Approval User Setup window.';
        SubstituteNotFoundErr: Label 'There is no substitute, direct approver, or approval administrator for user ID %1 in the Approval User Setup window.', Comment = 'There is no substitute for user ID NAVUser in the Approval User Setup window.';
        NoSuitableApproverFoundErr: Label 'No qualified approver was found.';
        DelegateOnlyOpenRequestsErr: Label 'You can only delegate open approval requests.';
        ApproveOnlyOpenRequestsErr: Label 'You can only approve open approval requests.';
        RejectOnlyOpenRequestsErr: Label 'You can only reject open approval entries.';
        ApprovalsDelegatedMsg: Label 'The selected approval requests have been delegated.';
        NoReqToApproveErr: Label 'There is no approval request to approve.';
        NoReqToRejectErr: Label 'There is no approval request to reject.';
        NoReqToDelegateErr: Label 'There is no approval request to delegate.';
        PendingApprovalMsg: Label 'An approval request has been sent.';
        NoApprovalsSentMsg: Label 'No approval requests have been sent, either because they are already sent or because related workflows do not support the journal line.';
        PendingApprovalForSelectedLinesMsg: Label 'Approval requests have been sent.';
        PendingApprovalForSomeSelectedLinesMsg: Label 'Approval requests have been sent.\\Requests for some journal lines were not sent, either because they are already sent or because related workflows do not support the journal line.';
        PurchaserUserNotFoundErr: Label 'The salesperson/purchaser user ID %1 does not exist in the Approval User Setup window for %2 %3.', Comment = 'Example: The salesperson/purchaser user ID NAVUser does not exist in the Approval User Setup window for Salesperson/Purchaser code AB.';
        NoApprovalRequestsFoundErr: Label 'No approval requests exist.';
        NoWFUserGroupMembersErr: Label 'A workflow user group with at least one member must be set up.';
        DocStatusChangedMsg: Label '%1 %2 has been automatically approved. The status has been changed to %3.', Comment = 'Order 1001 has been automatically approved. The status has been changed to Released.';
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = 'Record type Customer is not supported by this workflow response.';
        SalesPrePostCheckErr: Label 'Sales %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Sales Order 321 must be approved...';
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
        PurchPrePostCheckErr: Label 'Purchase %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Purchase Order 321 must be approved...';
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalReqCanceledForSelectedLinesMsg: Label 'The approval request for the selected record has been canceled.';
        PendingJournalBatchApprovalExistsErr: Label 'An approval request already exists.', Comment = '%1 is the Document No. of the journal line';
        ApporvalChainIsUnsupportedMsg: Label 'Only Direct Approver is supported as Approver Limit Type option for %1. The approval request will be approved automatically.', Comment = 'Only Direct Approver is supported as Approver Limit Type option for Gen. Journal Batch DEFAULT, CASH. The approval request will be approved automatically.';
        RecHasBeenApprovedMsg: Label '%1 has been approved.', Comment = '%1 = Record Id';
        NoPermissionToDelegateErr: Label 'You do not have permission to delegate one or more of the selected approval requests.';
        NothingToApproveErr: Label 'There is nothing to approve.';
        ApproverChainErr: Label 'No sufficient approver was found in the approver chain.';

    [IntegrationEvent(false, false)]
    procedure OnSendPurchaseDocForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendSalesDocForApproval(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendIncomingDocForApproval(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelPurchaseApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelSalesApprovalRequest(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelIncomingDocApprovalRequest(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendCustomerForApproval(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendVendorForApproval(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendItemForApproval(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelCustomerApprovalRequest(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelVendorApprovalRequest(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelItemApprovalRequest(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendGeneralJournalBatchForApproval(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendGeneralJournalLineForApproval(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelegateApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRenameRecordInApprovalRequest(OldRecordId: RecordID; NewRecordId: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDeleteRecordInApprovalRequest(RecordIDToApprove: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
    end;

    procedure ApproveRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToApproveErr);

        ApprovalEntry.SetRecFilter;
        ApproveApprovalRequests(ApprovalEntry);
    end;

    procedure ApproveGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            ApproveRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            ApproveRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure RejectRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToRejectErr);

        ApprovalEntry.SetRecFilter;
        RejectApprovalRequests(ApprovalEntry);
    end;

    procedure RejectGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            RejectRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            RejectRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure DelegateRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToDelegateErr);

        ApprovalEntry.SetRecFilter;
        DelegateApprovalRequests(ApprovalEntry);
    end;

    procedure DelegateGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            DelegateRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            DelegateRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure ApproveApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
    begin
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                ApproveSelectedApprovalRequest(ApprovalEntryToUpdate);
            until ApprovalEntry.Next = 0;
    end;

    procedure RejectApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
    begin
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                RejectSelectedApprovalRequest(ApprovalEntryToUpdate);
            until ApprovalEntry.Next = 0;
    end;

    procedure DelegateApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
    begin
        if ApprovalEntry.FindSet() then begin
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                DelegateSelectedApprovalRequest(ApprovalEntryToUpdate, true);
            until ApprovalEntry.Next = 0;
            Message(ApprovalsDelegatedMsg);
        end;
    end;

    local procedure ApproveSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        if ApprovalEntry.Status <> ApprovalEntry.Status::Open then
            Error(ApproveOnlyOpenRequestsErr);

        if ApprovalEntry."Approver ID" <> UserId then
            CheckUserAsApprovalAdministrator;

        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Approved);
        ApprovalEntry.Modify(true);
        OnApproveApprovalRequest(ApprovalEntry);
    end;

    local procedure RejectSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        if ApprovalEntry.Status <> ApprovalEntry.Status::Open then
            Error(RejectOnlyOpenRequestsErr);

        if ApprovalEntry."Approver ID" <> UserId then
            CheckUserAsApprovalAdministrator;

        OnRejectApprovalRequest(ApprovalEntry);
        ApprovalEntry.Get(ApprovalEntry."Entry No.");
        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Rejected);
        ApprovalEntry.Modify(true);
    end;

    procedure DelegateSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry"; CheckCurrentUser: Boolean)
    begin
        if ApprovalEntry.Status <> ApprovalEntry.Status::Open then
            Error(DelegateOnlyOpenRequestsErr);

        if CheckCurrentUser and (not ApprovalEntry.CanCurrentUserEdit) then
            Error(NoPermissionToDelegateErr);

        SubstituteUserIdForApprovalEntry(ApprovalEntry)
    end;

    local procedure SubstituteUserIdForApprovalEntry(ApprovalEntry: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        ApprovalAdminUserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(ApprovalEntry."Approver ID") then
            Error(ApproverUserIdNotInSetupErr, ApprovalEntry."Sender ID");

        if UserSetup.Substitute = '' then
            if UserSetup."Approver ID" = '' then begin
                ApprovalAdminUserSetup.SetRange("Approval Administrator", true);
                if ApprovalAdminUserSetup.FindFirst then
                    UserSetup.Get(ApprovalAdminUserSetup."User ID")
                else
                    Error(SubstituteNotFoundErr, UserSetup."User ID");
            end else
                UserSetup.Get(UserSetup."Approver ID")
        else
            UserSetup.Get(UserSetup.Substitute);

        ApprovalEntry."Approver ID" := UserSetup."User ID";
        ApprovalEntry.Modify(true);
        OnDelegateApprovalRequest(ApprovalEntry);
    end;

    procedure FindOpenApprovalEntryForCurrUser(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Approver ID", UserId);
        ApprovalEntry.SetRange("Related to Change", false);

        exit(ApprovalEntry.FindFirst);
    end;

    procedure FindApprovalEntryForCurrUser(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange("Approver ID", UserId);

        exit(ApprovalEntry.FindFirst);
    end;

    local procedure ShowPurchApprovalStatus(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find;

        case PurchaseHeader.Status of
            PurchaseHeader.Status::Released:
                Message(DocStatusChangedMsg, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader.Status);
            PurchaseHeader.Status::"Pending Approval":
                if HasOpenOrPendingApprovalEntries(PurchaseHeader.RecordId) then
                    Message(PendingApprovalMsg);
            PurchaseHeader.Status::"Pending Prepayment":
                Message(DocStatusChangedMsg, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader.Status);
        end;
    end;

    local procedure ShowSalesApprovalStatus(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Find;

        case SalesHeader.Status of
            SalesHeader.Status::Released:
                Message(DocStatusChangedMsg, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.Status);
            SalesHeader.Status::"Pending Approval":
                if HasOpenOrPendingApprovalEntries(SalesHeader.RecordId) then
                    Message(PendingApprovalMsg);
            SalesHeader.Status::"Pending Prepayment":
                Message(DocStatusChangedMsg, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.Status);
        end;
    end;

    local procedure ShowApprovalStatus(RecId: RecordID; WorkflowInstanceId: Guid)
    begin
        if HasPendingApprovalEntriesForWorkflow(RecId, WorkflowInstanceId) then
            Message(PendingApprovalMsg)
        else
            Message(RecHasBeenApprovedMsg, Format(RecId, 0, 1));
    end;

    procedure ApproveApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntry.Status::Approved);
                ApprovalEntryToUpdate.Modify(true);
                CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
            until ApprovalEntry.Next = 0;
    end;

    procedure CancelApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        OldStatus: Option;
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        if ApprovalEntry.FindSet() then
            repeat
                OldStatus := ApprovalEntry.Status;
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntryToUpdate.Status::Canceled);
                ApprovalEntryToUpdate.Modify(true);
                if OldStatus in [ApprovalEntry.Status::Open, ApprovalEntry.Status::Approved] then
                    CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
            until ApprovalEntry.Next = 0;
    end;

    procedure RejectApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        OldStatus: Option;
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        if ApprovalEntry.FindSet() then begin
            repeat
                OldStatus := ApprovalEntry.Status;
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntry.Status::Rejected);
                ApprovalEntryToUpdate.Modify(true);
                if (OldStatus in [ApprovalEntry.Status::Open, ApprovalEntry.Status::Approved]) and
                   (ApprovalEntryToUpdate."Approver ID" <> UserId)
                then
                    CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
            until ApprovalEntry.Next = 0;
            if ApprovalEntry."Approver ID" <> ApprovalEntry."Sender ID" then begin
                ApprovalEntry."Approver ID" := ApprovalEntry."Sender ID";
                CreateApprovalEntryNotification(ApprovalEntry, WorkflowStepInstance);
            end;
        end;
    end;

    procedure SendApprovalRequestFromRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Record ID to Approve", Status, "Workflow Step Instance ID", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Created);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);

        if ApprovalEntry.FindFirst then begin
            ApprovalEntry2.CopyFilters(ApprovalEntry);
            ApprovalEntry2.SetRange("Sequence No.", ApprovalEntry."Sequence No.");
            if ApprovalEntry2.FindSet(true) then
                repeat
                    ApprovalEntry2.Validate(Status, ApprovalEntry2.Status::Open);
                    ApprovalEntry2.Modify(true);
                    CreateApprovalEntryNotification(ApprovalEntry2, WorkflowStepInstance);
                until ApprovalEntry2.Next = 0;
            if FindApprovedApprovalEntryForWorkflowUserGroup(ApprovalEntry, WorkflowStepInstance) then
                OnApproveApprovalRequest(ApprovalEntry);
            exit;
        end;

        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        if ApprovalEntry.FindLast then
            OnApproveApprovalRequest(ApprovalEntry)
        else
            Error(NoApprovalRequestsFoundErr);
    end;

    procedure SendApprovalRequestFromApprovalEntry(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry2: Record "Approval Entry";
        ApprovalEntry3: Record "Approval Entry";
    begin
        if ApprovalEntry.Status = ApprovalEntry.Status::Open then begin
            CreateApprovalEntryNotification(ApprovalEntry, WorkflowStepInstance);
            exit;
        end;

        if FindOpenApprovalEntriesForWorkflowStepInstance(ApprovalEntry, WorkflowStepInstance."Record ID") then
            exit;

        ApprovalEntry2.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry2.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalEntry2.SetRange(Status, ApprovalEntry2.Status::Created);

        if ApprovalEntry2.FindFirst then begin
            ApprovalEntry3.CopyFilters(ApprovalEntry2);
            ApprovalEntry3.SetRange("Sequence No.", ApprovalEntry2."Sequence No.");
            if ApprovalEntry3.FindSet then
                repeat
                    ApprovalEntry3.Validate(Status, ApprovalEntry3.Status::Open);
                    ApprovalEntry3.Modify(true);
                    CreateApprovalEntryNotification(ApprovalEntry3, WorkflowStepInstance);
                until ApprovalEntry3.Next = 0;
        end;
    end;

    procedure CreateApprovalRequests(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        ApprovalEntryArgument: Record "Approval Entry";
    begin
        PopulateApprovalEntryArgument(RecRef, WorkflowStepInstance, ApprovalEntryArgument);

        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            case WorkflowStepArgument."Approver Type" of
                WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser":
                    CreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                WorkflowStepArgument."Approver Type"::Approver:
                    CreateApprReqForApprTypeApprover(WorkflowStepArgument, ApprovalEntryArgument);
                WorkflowStepArgument."Approver Type"::"Workflow User Group":
                    CreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument, ApprovalEntryArgument);
            end;

        if WorkflowStepArgument."Show Confirmation Message" then
            InformUserOnStatusChange(RecRef, WorkflowStepInstance.ID);
    end;

    procedure CreateAndAutomaticallyApproveRequest(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntryArgument: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        PopulateApprovalEntryArgument(RecRef, WorkflowStepInstance, ApprovalEntryArgument);
        if not WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            WorkflowStepArgument.Init;

        CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);

        InformUserOnStatusChange(RecRef, WorkflowStepInstance.ID);
    end;

    local procedure CreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        ApprovalEntryArgument.TestField("Salespers./Purch. Code");

        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
            WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForSpecificUser(WorkflowStepArgument, ApprovalEntryArgument);
                end;
        end;

        OnAfterCreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    local procedure CreateApprReqForApprTypeApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain":
                begin
                    CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                CreateApprovalRequestForApprover(WorkflowStepArgument, ApprovalEntryArgument);
            WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                begin
                    CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                CreateApprovalRequestForSpecificUser(WorkflowStepArgument, ApprovalEntryArgument);
        end;

        OnAfterCreateApprReqForApprTypeApprover(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    local procedure CreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        WorkflowUserGroupMember: Record "Workflow User Group Member";
        ApproverId: Code[50];
        SequenceNo: Integer;
    begin
        if not UserSetup.Get(UserId) then
            Error(UserIdNotInSetupErr, UserId);
        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        with WorkflowUserGroupMember do begin
            SetCurrentKey("Workflow User Group Code", "Sequence No.");
            SetRange("Workflow User Group Code", WorkflowStepArgument."Workflow User Group Code");

            if not FindSet then
                Error(NoWFUserGroupMembersErr);

            repeat
                ApproverId := "User Name";
                if not UserSetup.Get(ApproverId) then
                    Error(WFUserGroupNotInSetupErr, ApproverId);
                MakeApprovalEntry(ApprovalEntryArgument, SequenceNo + "Sequence No.", ApproverId, WorkflowStepArgument);
            until Next = 0;
        end;

        OnAfterCreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    local procedure CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        CreateApprovalRequestForApproverChain(WorkflowStepArgument, ApprovalEntryArgument, false);
    end;

    local procedure CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        CreateApprovalRequestForApproverChain(WorkflowStepArgument, ApprovalEntryArgument, true);
    end;

    local procedure CreateApprovalRequestForApproverChain(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; SufficientApproverOnly: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        ApproverId: Code[50];
        SequenceNo: Integer;
        MaxCount: Integer;
        i: Integer;
    begin
        ApproverId := UserId;

        with ApprovalEntry do begin
            SetCurrentKey("Record ID to Approve", "Workflow Step Instance ID", "Sequence No.");
            SetRange("Table ID", ApprovalEntryArgument."Table ID");
            SetRange("Record ID to Approve", ApprovalEntryArgument."Record ID to Approve");
            SetRange("Workflow Step Instance ID", ApprovalEntryArgument."Workflow Step Instance ID");
            SetRange(Status, Status::Created);
            if FindLast then
                ApproverId := "Approver ID"
            else
                if (WorkflowStepArgument."Approver Type" = WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser") and
                   (WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver")
                then begin
                    FindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument);
                    ApproverId := UserSetup."User ID";
                end;
        end;

        UserSetup.Reset;
        MaxCount := UserSetup.Count;

        if not UserSetup.Get(ApproverId) then
            Error(ApproverUserIdNotInSetupErr, ApprovalEntry."Sender ID");

        if not IsSufficientApprover(UserSetup, ApprovalEntryArgument) then
            repeat
                i += 1;
                if i > MaxCount then
                    Error(ApproverChainErr);
                ApproverId := UserSetup."Approver ID";

                if ApproverId = '' then
                    Error(NoSuitableApproverFoundErr);

                if not UserSetup.Get(ApproverId) then
                    Error(ApproverUserIdNotInSetupErr, UserSetup."User ID");

                // Approval Entry should not be created only when IsSufficientApprover is false and SufficientApproverOnly is true
                if IsSufficientApprover(UserSetup, ApprovalEntryArgument) or (not SufficientApproverOnly) then begin
                    SequenceNo := GetLastSequenceNo(ApprovalEntryArgument) + 1;
                    MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, ApproverId, WorkflowStepArgument);
                end;

            until IsSufficientApprover(UserSetup, ApprovalEntryArgument);
    end;

    local procedure CreateApprovalRequestForApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        UsrId: Code[50];
        SequenceNo: Integer;
    begin
        UsrId := UserId;

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        if not UserSetup.Get(UserId) then
            Error(UserIdNotInSetupErr, UsrId);

        UsrId := UserSetup."Approver ID";
        if not UserSetup.Get(UsrId) then begin
            if not UserSetup."Approval Administrator" then
                Error(ApproverUserIdNotInSetupErr, UserSetup."User ID");
            UsrId := UserId;
        end;

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UsrId, WorkflowStepArgument);
    end;

    local procedure CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        SequenceNo: Integer;
    begin
        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        FindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument);

        SequenceNo += 1;

        if WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver" then begin
            if IsSufficientApprover(UserSetup, ApprovalEntryArgument) then
                MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserSetup."User ID", WorkflowStepArgument);
        end else
            MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserSetup."User ID", WorkflowStepArgument);
    end;

    procedure CreateApprovalRequestForUser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        SequenceNo: Integer;
    begin
        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserId, WorkflowStepArgument);
    end;

    local procedure CreateApprovalRequestForSpecificUser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        UsrId: Code[50];
        SequenceNo: Integer;
    begin
        UsrId := WorkflowStepArgument."Approver User ID";

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        if not UserSetup.Get(UsrId) then
            Error(UserIdNotInSetupErr, UsrId);

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UsrId, WorkflowStepArgument);
    end;

    procedure MakeApprovalEntry(ApprovalEntryArgument: Record "Approval Entry"; SequenceNo: Integer; ApproverId: Code[50]; WorkflowStepArgument: Record "Workflow Step Argument")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        with ApprovalEntry do begin
            "Table ID" := ApprovalEntryArgument."Table ID";
            "Document Type" := ApprovalEntryArgument."Document Type";
            "Document No." := ApprovalEntryArgument."Document No.";
            "Salespers./Purch. Code" := ApprovalEntryArgument."Salespers./Purch. Code";
            "Sequence No." := SequenceNo;
            "Sender ID" := UserId;
            Amount := ApprovalEntryArgument.Amount;
            "Amount (LCY)" := ApprovalEntryArgument."Amount (LCY)";
            "Currency Code" := ApprovalEntryArgument."Currency Code";
            "Approver ID" := ApproverId;
            "Workflow Step Instance ID" := ApprovalEntryArgument."Workflow Step Instance ID";
            if ApproverId = UserId then
                Status := Status::Approved
            else
                Status := Status::Created;
            "Date-Time Sent for Approval" := CreateDateTime(Today, Time);
            "Last Date-Time Modified" := CreateDateTime(Today, Time);
            "Last Modified By User ID" := UserId;
            "Due Date" := CalcDate(WorkflowStepArgument."Due Date Formula", Today);

            case WorkflowStepArgument."Delegate After" of
                WorkflowStepArgument."Delegate After"::Never:
                    Evaluate("Delegation Date Formula", '');
                WorkflowStepArgument."Delegate After"::"1 day":
                    Evaluate("Delegation Date Formula", '<1D>');
                WorkflowStepArgument."Delegate After"::"2 days":
                    Evaluate("Delegation Date Formula", '<2D>');
                WorkflowStepArgument."Delegate After"::"5 days":
                    Evaluate("Delegation Date Formula", '<5D>');
                else
                    Evaluate("Delegation Date Formula", '');
            end;
            "Available Credit Limit (LCY)" := ApprovalEntryArgument."Available Credit Limit (LCY)";
            SetApproverType(WorkflowStepArgument, ApprovalEntry);
            SetLimitType(WorkflowStepArgument, ApprovalEntry);
            "Record ID to Approve" := ApprovalEntryArgument."Record ID to Approve";
            "Approval Code" := ApprovalEntryArgument."Approval Code";
            OnBeforeApprovalEntryInsert(ApprovalEntry, ApprovalEntryArgument);
            Insert(true);
        end;
    end;

    procedure CalcPurchaseDocAmount(PurchaseHeader: Record "Purchase Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TotalPurchaseLine: Record "Purchase Line";
        TotalPurchaseLineLCY: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        TempAmount: Decimal;
        VAtText: Text[30];
    begin
        PurchaseHeader.CalcInvDiscForHeader;
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(
          PurchaseHeader, TempPurchaseLine, 0, TotalPurchaseLine, TotalPurchaseLineLCY,
          TempAmount, VAtText);
        ApprovalAmount := TotalPurchaseLine.Amount;
        ApprovalAmountLCY := TotalPurchaseLineLCY.Amount;
    end;

    procedure CalcSalesDocAmount(SalesHeader: Record "Sales Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        TempSalesLine: Record "Sales Line" temporary;
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        TempAmount: array[5] of Decimal;
        VAtText: Text[30];
    begin
        SalesHeader.CalcInvDiscForHeader;
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0);
        Clear(SalesPost);
        SalesPost.SumSalesLinesTemp(
          SalesHeader, TempSalesLine, 0, TotalSalesLine, TotalSalesLineLCY,
          TempAmount[1], VAtText, TempAmount[2], TempAmount[3], TempAmount[4]);
        ApprovalAmount := TotalSalesLine.Amount;
        ApprovalAmountLCY := TotalSalesLineLCY.Amount;
    end;

    local procedure PopulateApprovalEntryArgument(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; var ApprovalEntryArgument: Record "Approval Entry")
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        IncomingDocument: Record "Incoming Document";
        ApprovalAmount: Decimal;
        ApprovalAmountLCY: Decimal;
    begin
        ApprovalEntryArgument.Init;
        ApprovalEntryArgument."Table ID" := RecRef.Number;
        ApprovalEntryArgument."Record ID to Approve" := RecRef.RecordId;
        ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" ";
        ApprovalEntryArgument."Approval Code" := WorkflowStepInstance."Workflow Code";
        ApprovalEntryArgument."Workflow Step Instance ID" := WorkflowStepInstance.ID;

        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    CalcPurchaseDocAmount(PurchaseHeader, ApprovalAmount, ApprovalAmountLCY);
                    ApprovalEntryArgument."Document Type" := PurchaseHeader."Document Type";
                    ApprovalEntryArgument."Document No." := PurchaseHeader."No.";
                    ApprovalEntryArgument."Salespers./Purch. Code" := PurchaseHeader."Purchaser Code";
                    ApprovalEntryArgument.Amount := ApprovalAmount;
                    ApprovalEntryArgument."Amount (LCY)" := ApprovalAmountLCY;
                    ApprovalEntryArgument."Currency Code" := PurchaseHeader."Currency Code";
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    CalcSalesDocAmount(SalesHeader, ApprovalAmount, ApprovalAmountLCY);
                    ApprovalEntryArgument."Document Type" := SalesHeader."Document Type";
                    ApprovalEntryArgument."Document No." := SalesHeader."No.";
                    ApprovalEntryArgument."Salespers./Purch. Code" := SalesHeader."Salesperson Code";
                    ApprovalEntryArgument.Amount := ApprovalAmount;
                    ApprovalEntryArgument."Amount (LCY)" := ApprovalAmountLCY;
                    ApprovalEntryArgument."Currency Code" := SalesHeader."Currency Code";
                    ApprovalEntryArgument."Available Credit Limit (LCY)" := GetAvailableCreditLimit(SalesHeader);
                end;
            DATABASE::Customer:
                begin
                    RecRef.SetTable(Customer);
                    ApprovalEntryArgument."Salespers./Purch. Code" := Customer."Salesperson Code";
                    ApprovalEntryArgument."Currency Code" := Customer."Currency Code";
                    ApprovalEntryArgument."Available Credit Limit (LCY)" := Customer.CalcAvailableCredit;
                end;
            DATABASE::"Gen. Journal Batch":
                RecRef.SetTable(GenJournalBatch);
            DATABASE::"Gen. Journal Line":
                begin
                    RecRef.SetTable(GenJournalLine);
                    ApprovalEntryArgument."Document Type" := GenJournalLine."Document Type";
                    ApprovalEntryArgument."Document No." := GenJournalLine."Document No.";
                    ApprovalEntryArgument."Salespers./Purch. Code" := GenJournalLine."Salespers./Purch. Code";
                    ApprovalEntryArgument.Amount := GenJournalLine.Amount;
                    ApprovalEntryArgument."Amount (LCY)" := GenJournalLine."Amount (LCY)";
                    ApprovalEntryArgument."Currency Code" := GenJournalLine."Currency Code";
                end;
            DATABASE::"Incoming Document":
                begin
                    RecRef.SetTable(IncomingDocument);
                    ApprovalEntryArgument."Document No." := Format(IncomingDocument."Entry No.");
                end;
            else
                OnPopulateApprovalEntryArgument(RecRef, ApprovalEntryArgument, WorkflowStepInstance);
        end;
    end;

    procedure CreateApprovalEntryNotification(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationEntry: Record "Notification Entry";
        UserSetup: Record "User Setup";
    begin
        if not WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            exit;

        if WorkflowStepArgument."Notification User ID" = '' then begin
            if not UserSetup.Get(ApprovalEntry."Approver ID") then
                exit;
            WorkflowStepArgument.Validate("Notification User ID", ApprovalEntry."Approver ID");
        end;

        ApprovalEntry.Reset;
        NotificationEntry.CreateNewEntry(
          NotificationEntry.Type::Approval, WorkflowStepArgument."Notification User ID",
          ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link", ApprovalEntry."Sender ID");
    end;

    local procedure SetApproverType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    begin
        case WorkflowStepArgument."Approver Type" of
            WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser":
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::"Sales Pers./Purchaser";
            WorkflowStepArgument."Approver Type"::Approver:
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::Approver;
            WorkflowStepArgument."Approver Type"::"Workflow User Group":
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::"Workflow User Group";
        end;
    end;

    local procedure SetLimitType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    begin
        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"Approval Limits";
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";
        end;

        if ApprovalEntry."Approval Type" = ApprovalEntry."Approval Type"::"Workflow User Group" then
            ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";
    end;

    local procedure IsSufficientPurchApprover(UserSetup: Record "User Setup"; DocumentType: Option; ApprovalAmountLCY: Decimal): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        case DocumentType of
            PurchaseHeader."Document Type"::Quote:
                if UserSetup."Unlimited Request Approval" or
                   ((ApprovalAmountLCY <= UserSetup."Request Amount Approval Limit") and (UserSetup."Request Amount Approval Limit" <> 0))
                then
                    exit(true);
            else
                if UserSetup."Unlimited Purchase Approval" or
                   ((ApprovalAmountLCY <= UserSetup."Purchase Amount Approval Limit") and (UserSetup."Purchase Amount Approval Limit" <> 0))
                then
                    exit(true);
        end;

        exit(false);
    end;

    local procedure IsSufficientSalesApprover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Sales Approval" or
           ((ApprovalAmountLCY <= UserSetup."Sales Amount Approval Limit") and (UserSetup."Sales Amount Approval Limit" <> 0))
        then
            exit(true);

        exit(false);
    end;

    local procedure IsSufficientGenJournalLineApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
    begin
        RecRef.Get(ApprovalEntryArgument."Record ID to Approve");
        RecRef.SetTable(GenJournalLine);

        if GenJournalLine.IsForPurchase then
            exit(IsSufficientPurchApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)"));

        if GenJournalLine.IsForSales then
            exit(IsSufficientSalesApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)"));

        exit(true);
    end;

    procedure IsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"): Boolean
    var
        IsSufficient: Boolean;
    begin
        case ApprovalEntryArgument."Table ID" of
            DATABASE::"Purchase Header":
                exit(IsSufficientPurchApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)"));
            DATABASE::"Sales Header":
                exit(IsSufficientSalesApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)"));
            DATABASE::"Gen. Journal Batch":
                Message(ApporvalChainIsUnsupportedMsg, Format(ApprovalEntryArgument."Record ID to Approve"));
            DATABASE::"Gen. Journal Line":
                exit(IsSufficientGenJournalLineApprover(UserSetup, ApprovalEntryArgument));
        end;

        IsSufficient := true;
        OnAfterIsSufficientApprover(UserSetup, ApprovalEntryArgument, IsSufficient);
        exit(IsSufficient);
    end;

    local procedure GetAvailableCreditLimit(SalesHeader: Record "Sales Header"): Decimal
    begin
        exit(SalesHeader.CheckAvailableCreditLimit);
    end;

    procedure PrePostApprovalCheckSales(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if IsSalesHeaderPendingApproval(SalesHeader) then
            Error(SalesPrePostCheckErr, SalesHeader."Document Type", SalesHeader."No.");

        exit(true);
    end;

    procedure PrePostApprovalCheckPurch(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if IsPurchaseHeaderPendingApproval(PurchaseHeader) then
            Error(PurchPrePostCheckErr, PurchaseHeader."Document Type", PurchaseHeader."No.");

        exit(true);
    end;

    procedure IsIncomingDocApprovalsWorkflowEnabled(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(IncomingDocument, WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode));
    end;

    procedure IsPurchaseApprovalsWorkflowEnabled(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(PurchaseHeader, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode));
    end;

    procedure IsPurchaseHeaderPendingApproval(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            exit(false);

        exit(IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader));
    end;

    procedure IsSalesApprovalsWorkflowEnabled(var SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(SalesHeader, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode));
    end;

    procedure IsSalesHeaderPendingApproval(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            exit(false);

        exit(IsSalesApprovalsWorkflowEnabled(SalesHeader));
    end;

    procedure IsOverdueNotificationsWorkflowEnabled(): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init;
        exit(WorkflowManagement.WorkflowExists(ApprovalEntry, ApprovalEntry,
            WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode));
    end;

    procedure IsGeneralJournalBatchApprovalsWorkflowEnabled(var GenJournalBatch: Record "Gen. Journal Batch"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(GenJournalBatch,
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode));
    end;

    procedure IsGeneralJournalLineApprovalsWorkflowEnabled(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode));
    end;

    procedure CheckPurchaseApprovalPossible(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if not IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader) then
            Error(NoWorkflowEnabledErr);

        if not PurchaseHeader.PurchLinesExist then
            Error(NothingToApproveErr);

        OnAfterCheckPurchaseApprovalPossible(PurchaseHeader);

        exit(true);
    end;

    procedure CheckIncomingDocApprovalsWorkflowEnabled(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        if not IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckSalesApprovalPossible(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if not IsSalesApprovalsWorkflowEnabled(SalesHeader) then
            Error(NoWorkflowEnabledErr);

        if not SalesHeader.SalesLinesExist then
            Error(NothingToApproveErr);

        OnAfterCheckSalesApprovalPossible(SalesHeader);

        exit(true);
    end;

    procedure CheckCustomerApprovalsWorkflowEnabled(var Customer: Record Customer): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Customer, WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Customer, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    procedure CheckVendorApprovalsWorkflowEnabled(var Vendor: Record Vendor): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Vendor, WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Vendor, WorkflowEventHandling.RunWorkflowOnVendorChangedCode) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    procedure CheckItemApprovalsWorkflowEnabled(var Item: Record Item): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Item, WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, WorkflowEventHandling.RunWorkflowOnItemChangedCode) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    procedure CheckGeneralJournalBatchApprovalsWorkflowEnabled(var GenJournalBatch: Record "Gen. Journal Batch"): Boolean
    begin
        if not
           WorkflowManagement.CanExecuteWorkflow(GenJournalBatch,
             WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode)
        then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckGeneralJournalLineApprovalsWorkflowEnabled(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if not
           WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
             WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode)
        then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure DeleteApprovalEntry(Variant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        DeleteApprovalEntries(RecRef.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 12, 'OnMoveGenJournalLine', '', false, false)]
    procedure PostApprovalEntriesMoveGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ToRecordID: RecordID)
    begin
        PostApprovalEntries(GenJournalLine.RecordId, ToRecordID, GenJournalLine."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteGenJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 232, 'OnMoveGenJournalBatch', '', false, false)]
    procedure PostApprovalEntriesMoveGenJournalBatch(var Sender: Record "Gen. Journal Batch"; ToRecordID: RecordID)
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        if PostApprovalEntries(Sender.RecordId, ToRecordID, '') then begin
            RecordRestrictionMgt.AllowRecordUsage(Sender);
            DeleteApprovalEntries(Sender.RecordId);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 232, 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteGenJournalBatch(var Rec: Record "Gen. Journal Batch"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 18, 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 27, 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    procedure PostApprovalEntries(ApprovedRecordID: RecordID; PostedRecordID: RecordID; PostedDocNo: Code[20]): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        ApprovalEntry.SetAutoCalcFields("Pending Approvals", "Number of Approved Requests", "Number of Rejected Requests");
        ApprovalEntry.SetRange("Table ID", ApprovedRecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", ApprovedRecordID);
        if not ApprovalEntry.FindSet then
            exit(false);

        repeat
            PostedApprovalEntry.Init;
            PostedApprovalEntry.TransferFields(ApprovalEntry);
            PostedApprovalEntry."Number of Approved Requests" := ApprovalEntry."Number of Approved Requests";
            PostedApprovalEntry."Number of Rejected Requests" := ApprovalEntry."Number of Rejected Requests";
            PostedApprovalEntry."Table ID" := PostedRecordID.TableNo;
            PostedApprovalEntry."Document No." := PostedDocNo;
            PostedApprovalEntry."Posted Record ID" := PostedRecordID;
            PostedApprovalEntry."Entry No." := 0;
            PostedApprovalEntry.Insert(true);
        until ApprovalEntry.Next = 0;

        PostApprovalCommentLines(ApprovedRecordID, PostedRecordID, PostedDocNo);
        exit(true);
    end;

    local procedure PostApprovalCommentLines(ApprovedRecordID: RecordID; PostedRecordID: RecordID; PostedDocNo: Code[20])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovedRecordID.TableNo);
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovedRecordID);
        if ApprovalCommentLine.FindSet then
            repeat
                PostedApprovalCommentLine.Init;
                PostedApprovalCommentLine.TransferFields(ApprovalCommentLine);
                PostedApprovalCommentLine."Entry No." := 0;
                PostedApprovalCommentLine."Table ID" := PostedRecordID.TableNo;
                PostedApprovalCommentLine."Document No." := PostedDocNo;
                PostedApprovalCommentLine."Posted Record ID" := PostedRecordID;
                PostedApprovalCommentLine.Insert(true);
            until ApprovalCommentLine.Next = 0;
    end;

    procedure ShowPostedApprovalEntries(PostedRecordID: RecordID)
    var
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        PostedApprovalEntry.FilterGroup(2);
        PostedApprovalEntry.SetRange("Posted Record ID", PostedRecordID);
        PostedApprovalEntry.FilterGroup(0);
        PAGE.Run(PAGE::"Posted Approval Entries", PostedApprovalEntry);
    end;

    procedure DeletePostedApprovalEntries(PostedRecordID: RecordID)
    var
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        PostedApprovalEntry.SetRange("Table ID", PostedRecordID.TableNo);
        PostedApprovalEntry.SetRange("Posted Record ID", PostedRecordID);
        if not PostedApprovalEntry.IsEmpty then
            PostedApprovalEntry.DeleteAll;
        DeletePostedApprovalCommentLines(PostedRecordID);
    end;

    local procedure DeletePostedApprovalCommentLines(PostedRecordID: RecordID)
    var
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        PostedApprovalCommentLine.SetRange("Table ID", PostedRecordID.TableNo);
        PostedApprovalCommentLine.SetRange("Posted Record ID", PostedRecordID);
        if not PostedApprovalCommentLine.IsEmpty then
            PostedApprovalCommentLine.DeleteAll;
    end;

    procedure SetStatusToPendingApproval(var Variant: Variant)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        IncomingDocument: Record "Incoming Document";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    PurchaseHeader.Validate(Status, PurchaseHeader.Status::"Pending Approval");
                    PurchaseHeader.Modify(true);
                    Variant := PurchaseHeader;
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SalesHeader.Validate(Status, SalesHeader.Status::"Pending Approval");
                    SalesHeader.Modify(true);
                    Variant := SalesHeader;
                end;
            DATABASE::"Incoming Document":
                begin
                    RecRef.SetTable(IncomingDocument);
                    IncomingDocument.Validate(Status, IncomingDocument.Status::"Pending Approval");
                    IncomingDocument.Modify(true);
                    Variant := IncomingDocument;
                end;
            else begin
                    IsHandled := false;
                    OnSetStatusToPendingApproval(RecRef, Variant, IsHandled);
                    if not IsHandled then
                        Error(UnsupportedRecordTypeErr, RecRef.Caption);
                end;
        end;
    end;

    procedure InformUserOnStatusChange(Variant: Variant; WorkflowInstanceId: Guid)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Purchase Header":
                ShowPurchApprovalStatus(Variant);
            DATABASE::"Sales Header":
                ShowSalesApprovalStatus(Variant);
            else
                ShowApprovalStatus(RecRef.RecordId, WorkflowInstanceId);
        end;
    end;

    procedure GetApprovalComment(Variant: Variant)
    var
        BlankGUID: Guid;
    begin
        ShowApprovalComments(Variant, BlankGUID);
    end;

    procedure GetApprovalCommentForWorkflowStepInstanceID(Variant: Variant; WorkflowStepInstanceID: Guid)
    begin
        ShowApprovalComments(Variant, WorkflowStepInstanceID);
    end;

    local procedure ShowApprovalComments(Variant: Variant; WorkflowStepInstanceID: Guid)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        ApprovalComments: Page "Approval Comments";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
                end;
            DATABASE::"Purchase Header":
                begin
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
                    FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
                end;
            DATABASE::"Sales Header":
                begin
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
                    FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
                end;
            else begin
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
                    FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
                end;
        end;

        if IsNullGuid(WorkflowStepInstanceID) and (not IsNullGuid(ApprovalEntry."Workflow Step Instance ID")) then
            WorkflowStepInstanceID := ApprovalEntry."Workflow Step Instance ID";

        ApprovalComments.SetTableView(ApprovalCommentLine);
        ApprovalComments.SetWorkflowStepInstanceID(WorkflowStepInstanceID);
        ApprovalComments.Run;
    end;

    procedure HasOpenApprovalEntriesForCurrentUser(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        exit(FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID));
    end;

    procedure HasOpenApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasOpenOrPendingApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    local procedure HasPendingApprovalEntriesForWorkflow(RecId: RecordID; WorkflowInstanceId: Guid): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecId);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        ApprovalEntry.SetFilter("Workflow Step Instance ID", WorkflowInstanceId);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasAnyOpenJournalLineApprovalEntries(JournalTemplateName: Code[20]; JournalBatchName: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalEntry: Record "Approval Entry";
        GenJournalLineRecRef: RecordRef;
        GenJournalLineRecordID: RecordID;
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::"Gen. Journal Line");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Related to Change", false);
        if ApprovalEntry.IsEmpty then
            exit(false);

        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        if GenJournalLine.IsEmpty then
            exit(false);

        if GenJournalLine.Count < ApprovalEntry.Count then begin
            GenJournalLine.FindSet;
            repeat
                if HasOpenApprovalEntries(GenJournalLine.RecordId) then
                    exit(true);
            until GenJournalLine.Next = 0;
        end else begin
            ApprovalEntry.FindSet;
            repeat
                GenJournalLineRecordID := ApprovalEntry."Record ID to Approve";
                GenJournalLineRecRef := GenJournalLineRecordID.GetRecord;
                GenJournalLineRecRef.SetTable(GenJournalLine);
                if (GenJournalLine."Journal Template Name" = JournalTemplateName) and
                   (GenJournalLine."Journal Batch Name" = JournalBatchName)
                then
                    exit(true);
            until ApprovalEntry.Next = 0;
        end;

        exit(false)
    end;

    procedure TrySendJournalBatchApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);
        CheckGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch);
        if HasOpenApprovalEntries(GenJournalBatch.RecordId) or
           HasAnyOpenJournalLineApprovalEntries(GenJournalBatch."Journal Template Name", GenJournalBatch.Name)
        then
            Error(PendingJournalBatchApprovalExistsErr);
        OnSendGeneralJournalBatchForApproval(GenJournalBatch);
    end;

    procedure TrySendJournalLineApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    var
        LinesSent: Integer;
    begin
        if GenJournalLine.Count = 1 then
            CheckGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine);

        repeat
            if WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
                 WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode) and
               not HasOpenApprovalEntries(GenJournalLine.RecordId)
            then begin
                OnSendGeneralJournalLineForApproval(GenJournalLine);
                LinesSent += 1;
            end;
        until GenJournalLine.Next = 0;

        case LinesSent of
            0:
                Message(NoApprovalsSentMsg);
            GenJournalLine.Count:
                Message(PendingApprovalForSelectedLinesMsg);
            else
                Message(PendingApprovalForSomeSelectedLinesMsg);
        end;
    end;

    procedure TryCancelJournalBatchApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);
        OnCancelGeneralJournalBatchApprovalRequest(GenJournalBatch);
        WorkflowWebhookManagement.FindAndCancel(GenJournalBatch.RecordId);
    end;

    procedure TryCancelJournalLineApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        repeat
            if HasOpenApprovalEntries(GenJournalLine.RecordId) then
                OnCancelGeneralJournalLineApprovalRequest(GenJournalLine);
            WorkflowWebhookManagement.FindAndCancel(GenJournalLine.RecordId);
        until GenJournalLine.Next = 0;
        Message(ApprovalReqCanceledForSelectedLinesMsg);
    end;

    procedure ShowJournalApprovalEntries(var GenJournalLine: Record "Gen. Journal Line")
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);

        ApprovalEntry.SetFilter("Table ID", '%1|%2', DATABASE::"Gen. Journal Batch", DATABASE::"Gen. Journal Line");
        ApprovalEntry.SetFilter("Record ID to Approve", '%1|%2', GenJournalBatch.RecordId, GenJournalLine.RecordId);
        ApprovalEntry.SetRange("Related to Change", false);
        PAGE.Run(PAGE::"Approval Entries", ApprovalEntry);
    end;

    local procedure GetGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if not GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            GenJournalBatch.Get(GenJournalLine.GetFilter("Journal Template Name"), GenJournalLine.GetFilter("Journal Batch Name"));
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnRenameRecordInApprovalRequest', '', false, false)]
    procedure RenameApprovalEntries(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Record ID to Approve", OldRecordId);
        if not ApprovalEntry.IsEmpty then
            ApprovalEntry.ModifyAll("Record ID to Approve", NewRecordId, true);
        ChangeApprovalComments(OldRecordId, NewRecordId);
    end;

    local procedure ChangeApprovalComments(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Record ID to Approve", OldRecordId);
        if not ApprovalCommentLine.IsEmpty then
            ApprovalCommentLine.ModifyAll("Record ID to Approve", NewRecordId, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1535, 'OnDeleteRecordInApprovalRequest', '', false, false)]
    procedure DeleteApprovalEntries(RecordIDToApprove: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordIDToApprove.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordIDToApprove);
        if not ApprovalEntry.IsEmpty then
            ApprovalEntry.DeleteAll(true);
        DeleteApprovalCommentLines(RecordIDToApprove);
    end;

    procedure DeleteApprovalCommentLines(RecordIDToApprove: RecordID)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", RecordIDToApprove.TableNo);
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        if not ApprovalCommentLine.IsEmpty then
            ApprovalCommentLine.DeleteAll(true);
    end;

    procedure CopyApprovalEntryQuoteToOrder(FromRecID: RecordID; ToDocNo: Code[20]; ToRecID: RecordID)
    var
        FromApprovalEntry: Record "Approval Entry";
        ToApprovalEntry: Record "Approval Entry";
        FromApprovalCommentLine: Record "Approval Comment Line";
        ToApprovalCommentLine: Record "Approval Comment Line";
        LastEntryNo: Integer;
    begin
        FromApprovalEntry.SetRange("Table ID", FromRecID.TableNo);
        FromApprovalEntry.SetRange("Record ID to Approve", FromRecID);
        if FromApprovalEntry.FindSet then begin
            ToApprovalEntry.FindLast;
            LastEntryNo := ToApprovalEntry."Entry No.";
            repeat
                ToApprovalEntry := FromApprovalEntry;
                ToApprovalEntry."Entry No." := LastEntryNo + 1;
                ToApprovalEntry."Document Type" := ToApprovalEntry."Document Type"::Order;
                ToApprovalEntry."Document No." := ToDocNo;
                ToApprovalEntry."Record ID to Approve" := ToRecID;
                LastEntryNo += 1;
                ToApprovalEntry.Insert;
            until FromApprovalEntry.Next = 0;

            FromApprovalCommentLine.SetRange("Table ID", FromRecID.TableNo);
            FromApprovalCommentLine.SetRange("Record ID to Approve", FromRecID);
            if FromApprovalCommentLine.FindSet then begin
                ToApprovalCommentLine.FindLast;
                LastEntryNo := ToApprovalCommentLine."Entry No.";
                repeat
                    ToApprovalCommentLine := FromApprovalCommentLine;
                    ToApprovalCommentLine."Entry No." := LastEntryNo + 1;
                    ToApprovalCommentLine."Document Type" := ToApprovalCommentLine."Document Type"::Order;
                    ToApprovalCommentLine."Document No." := ToDocNo;
                    ToApprovalCommentLine."Record ID to Approve" := ToRecID;
                    ToApprovalCommentLine.Insert;
                    LastEntryNo += 1;
                until FromApprovalCommentLine.Next = 0;
            end;
        end;
    end;

    procedure GetLastSequenceNo(ApprovalEntryArgument: Record "Approval Entry"): Integer
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        with ApprovalEntry do begin
            SetCurrentKey("Record ID to Approve", "Workflow Step Instance ID", "Sequence No.");
            SetRange("Table ID", ApprovalEntryArgument."Table ID");
            SetRange("Record ID to Approve", ApprovalEntryArgument."Record ID to Approve");
            SetRange("Workflow Step Instance ID", ApprovalEntryArgument."Workflow Step Instance ID");
            if FindLast then
                exit("Sequence No.");
        end;
        exit(0);
    end;

    procedure OpenApprovalEntriesPage(RecId: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecId.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecId);
        ApprovalEntry.SetRange("Related to Change", false);
        PAGE.RunModal(PAGE::"Approval Entries", ApprovalEntry);
    end;

    procedure CanCancelApprovalForRecord(RecID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit(false);

        ApprovalEntry.SetRange("Table ID", RecID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecID);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Related to Change", false);

        if not UserSetup."Approval Administrator" then
            ApprovalEntry.SetRange("Sender ID", UserId);
        exit(ApprovalEntry.FindFirst);
    end;

    local procedure FindUserSetupBySalesPurchCode(var UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        if ApprovalEntryArgument."Salespers./Purch. Code" <> '' then begin
            UserSetup.SetCurrentKey("Salespers./Purch. Code");
            UserSetup.SetRange("Salespers./Purch. Code", ApprovalEntryArgument."Salespers./Purch. Code");
            if not UserSetup.FindFirst then
                Error(
                  PurchaserUserNotFoundErr, UserSetup."User ID", UserSetup.FieldCaption("Salespers./Purch. Code"),
                  UserSetup."Salespers./Purch. Code");
            exit;
        end;
    end;

    local procedure CheckUserAsApprovalAdministrator()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId);
        UserSetup.TestField("Approval Administrator");
    end;

    local procedure FindApprovedApprovalEntryForWorkflowUserGroup(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowInstance: Query "Workflow Instance";
    begin
        WorkflowStepInstance.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode);
        WorkflowStepInstance.SetRange("Record ID", WorkflowStepInstance."Record ID");
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        WorkflowStepInstance.SetRange(Type, WorkflowInstance.Type::Response);
        WorkflowStepInstance.SetRange(Status, WorkflowInstance.Status::Completed);
        if WorkflowStepInstance.FindSet then
            repeat
                if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
                    if WorkflowStepArgument."Approver Type" = WorkflowStepArgument."Approver Type"::"Workflow User Group" then begin
                        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
                        exit(ApprovalEntry.FindLast);
                    end;
            until WorkflowStepInstance.Next = 0;
        exit(false);
    end;

    local procedure FindOpenApprovalEntriesForWorkflowStepInstance(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstanceRecID: RecordID): Boolean
    var
        ApprovalEntry2: Record "Approval Entry";
    begin
        if ApprovalEntry."Approval Type" = ApprovalEntry."Approval Type"::"Workflow User Group" then
            ApprovalEntry2.SetFilter("Sequence No.", '>%1', ApprovalEntry."Sequence No.");
        ApprovalEntry2.SetFilter("Record ID to Approve", '%1|%2', WorkflowStepInstanceRecID, ApprovalEntry."Record ID to Approve");
        ApprovalEntry2.SetRange(Status, ApprovalEntry2.Status::Open);
        ApprovalEntry2.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        exit(not ApprovalEntry2.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesApprovalPossible(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchaseApprovalPossible(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApprovalEntryInsert(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    begin
    end;
}

