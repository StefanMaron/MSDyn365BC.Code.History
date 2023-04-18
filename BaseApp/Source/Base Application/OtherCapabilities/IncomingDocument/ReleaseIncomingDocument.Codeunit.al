codeunit 132 "Release Incoming Document"
{
    TableNo = "Incoming Document";
    Permissions = TableData "Incoming Document" = rm;

    trigger OnRun()
    begin
        if Status = Status::Released then
            exit;
        if Status in [Status::Created, Status::Posted] then
            Error(CanReleasedIfStatusErr, Status::"Pending Approval", Status::New, Status::Failed);

        OnCheckIncomingDocReleaseRestrictions();

        TestField(Posted, false);

        if not IsADocumentAttached() then
            Error(NothingToReleaseErr, "Entry No.");

        Status := Status::Released;
        Released := true;
        "Released Date-Time" := CurrentDateTime;
        "Released By User ID" := UserSecurityId();

        Modify(true);

        OnAfterReleaseIncomingDoc(Rec);
    end;

    var
        NothingToReleaseErr: Label 'There is nothing to release for the incoming document number %1.', Comment = '%1 = Incoming Document Entry No';
        DocReleasedWhenApprovedErr: Label 'This document can only be released when the approval process is complete.';
        CancelOrCompleteToReopenDocErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        CanReleasedIfStatusErr: Label 'It is only possible to release the document when the status is %1, %2 or %3.', Comment = '%1 = status released, %2 = status pending approval';

    procedure Reopen(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            if Status = Status::New then
                exit;
            ClearReleaseFields(IncomingDocument);
            Status := Status::New;

            Modify(true);
        end;
    end;

    procedure Reject(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            TestField(Posted, false);

            ClearReleaseFields(IncomingDocument);
            Status := Status::Rejected;

            Modify(true);
        end;
    end;

    procedure Fail(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            if Status = Status::Failed then
                exit;

            Status := Status::Failed;

            Modify(true);
            Commit();

            OnAfterCreateDocFromIncomingDocFail(IncomingDocument);
        end;
    end;

    procedure Create(var IncomingDocument: Record "Incoming Document")
    begin
        with IncomingDocument do begin
            if Status = Status::Created then
                exit;

            Status := Status::Created;

            Modify(true);
            Commit();
            OnAfterCreateDocFromIncomingDocSuccess(IncomingDocument);
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformManualRelease(var IncomingDocument: Record "Incoming Document")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) and
           (IncomingDocument.Status = IncomingDocument.Status::New)
        then
            Error(DocReleasedWhenApprovedErr);

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
    end;

    procedure PerformManualReopen(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::"Pending Approval" then
            Error(CancelOrCompleteToReopenDocErr);

        Reopen(IncomingDocument);
    end;

    procedure PerformManualReject(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::"Pending Approval" then
            Error(CancelOrCompleteToReopenDocErr);

        Reject(IncomingDocument);
    end;

    local procedure ClearReleaseFields(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Released := false;
        IncomingDocument."Released Date-Time" := 0DT;
        Clear(IncomingDocument."Released By User ID");
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReleaseIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateDocFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateDocFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
    end;
}

