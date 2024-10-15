codeunit 31276 "Compensation Approv. Mgt. CZC"
{
    var
        ApprovalAmount: Decimal;
        ApprovalAmountLCY: Decimal;
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';

    procedure CalcCompensationAmount(CompensationHeaderCZC: Record "Compensation Header CZC"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    begin
        CompensationHeaderCZC.CalcFields("Compensation Value (LCY)");
        ApprovalAmount := 0;
        ApprovalAmountLCY := CompensationHeaderCZC."Compensation Value (LCY)";
    end;

    procedure PrePostApprovalCheckCompensation(var CompensationHeaderCZC: Record "Compensation Header CZC"): Boolean
    var
        PrePostCheckCompensationErr: Label 'Compensation %1 must be approved and released before you can perform this action.', Comment = '%1 = Document No.';
    begin
        if (CompensationHeaderCZC.Status = CompensationHeaderCZC.Status::Open) and IsCompensationApprovalsWorkflowEnabled(CompensationHeaderCZC) then
            Error(PrePostCheckCompensationErr, CompensationHeaderCZC."No.");

        exit(true);
    end;

    procedure IsCompensationApprovalsWorkflowEnabled(var CompensationHeaderCZC: Record "Compensation Header CZC"): Boolean
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowHandlerCZC: Codeunit "Workflow Handler CZC";
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(CompensationHeaderCZC,
          WorkflowHandlerCZC.RunWorkflowOnSendCompensationForApprovalCode()));
    end;

    local procedure IsSufficientCompensationApprover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Compens. Appr. CZC" or
           ((ApprovalAmountLCY <= UserSetup."Compens. Amt. Appr. Limit CZC") and (UserSetup."Compens. Amt. Appr. Limit CZC" <> 0))
        then
            exit(true);

        exit(false);
    end;

    procedure CheckCompensationApprovalsWorkflowEnabled(var CompensationHeaderCZC: Record "Compensation Header CZC"): Boolean
    begin
        if not IsCompensationApprovalsWorkflowEnabled(CompensationHeaderCZC) then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Management CZL", 'OnSetStatusToApproved', '', false, false)]
    local procedure SetCompensationDocumentStatusToApproved(InputRecordRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
    begin
        if IsHandled then
            exit;

        if InputRecordRef.Number = Database::"Compensation Header CZC" then begin
            InputRecordRef.SetTable(CompensationHeaderCZC);
            CompensationHeaderCZC.Validate(Status, CompensationHeaderCZC.Status::Approved);
            CompensationHeaderCZC.Modify();
            Variant := CompensationHeaderCZC;
            IsHandled := true;
        end;
    end;

#if not CLEAN19
    [Obsolete('The function is replaced by the SetCompensationDocumentStatusToApproved subscriber.', '19.0')]
    procedure SetStatusToApproved(var Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovedCompensationHeaderCZC: Record "Compensation Header CZC";
        TargetRecordRef: RecordRef;
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.GetTable(Variant);

        case SourceRecordRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    TargetRecordRef.Get(ApprovalEntry."Record ID to Approve");
                    Variant := TargetRecordRef;
#pragma warning disable AL0432
                    SetStatusToApproved(Variant);
#pragma warning restore AL0432
                end;
            Database::"Compensation Header CZC":
                begin
                    SourceRecordRef.SetTable(ApprovedCompensationHeaderCZC);
                    ApprovedCompensationHeaderCZC.Validate(Status, ApprovedCompensationHeaderCZC.Status::Approved);
                    ApprovedCompensationHeaderCZC.Modify();
                    Variant := ApprovedCompensationHeaderCZC;
                end;
        end;
    end;

    [Obsolete('The function is discontinued, use the DeleteApprovalEntries function from "Approvals Mgmt." instead.', '19.0')]
    procedure DeleteApprovalEntryForRecord(Variant: Variant)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Variant);
        ApprovalsMgmt.DeleteApprovalEntries(RecordRef.RecordId);
        ApprovalsMgmt.DeleteApprovalCommentLines(RecordRef.RecordId);
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure ApprovalsMgmtOnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry")
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
    begin
        if RecRef.Number = Database::"Compensation Header CZC" then begin
            RecRef.SetTable(CompensationHeaderCZC);
            CalcCompensationAmount(CompensationHeaderCZC, ApprovalAmount, ApprovalAmountLCY);
            ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" ";
            ApprovalEntryArgument."Document No." := CompensationHeaderCZC."No.";
            ApprovalEntryArgument."Salespers./Purch. Code" := CompensationHeaderCZC."Salesperson/Purchaser Code";
            ApprovalEntryArgument.Amount := 0;
            ApprovalEntryArgument."Amount (LCY)" := ApprovalAmountLCY;
            ApprovalEntryArgument."Currency Code" := '';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterIsSufficientApprover', '', false, false)]
    local procedure ApprovalsMgmtOnAfterIsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    begin
        if ApprovalEntryArgument."Table ID" = Database::"Compensation Header CZC" then
            IsSufficient := IsSufficientCompensationApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure ApprovalsMgmtOnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
    begin
        if IsHandled then
            exit;

        if RecRef.Number = Database::"Compensation Header CZC" then begin
            RecRef.SetTable(CompensationHeaderCZC);
            CompensationHeaderCZC.Validate(Status, CompensationHeaderCZC.Status::"Pending Approval");
            CompensationHeaderCZC.Modify(true);
            Variant := CompensationHeaderCZC;
            IsHandled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendCompensationForApprovalCZC(var CompensationHeaderCZC: Record "Compensation Header CZC")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelCompensationApprovalRequestCZC(var CompensationHeaderCZC: Record "Compensation Header CZC")
    begin
    end;
}
