codeunit 5346 "CRM Sales Document Posting Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSalesOrderId: Guid;
        CRMDocumentHasBeenPostedMsg: Label '%1 ''%2'' has been posted.', Comment = '%1=Document Type;%2=Document Id';

    [EventSubscriber(ObjectType::Table, 36, 'OnBeforeDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure SetCRMSalesOrderIdOnSalesHeaderDeletion(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if (Rec."Document Type" <> Rec."Document Type"::Order) or
           (Rec.Status = Rec.Status::Open) or
           RunTrigger // RunTrigger is expected to be FALSE on removal of Sales Order Header on posting
        then
            exit;
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        if not CRMIntegrationRecord.FindIDFromRecordID(Rec.RecordId, CRMSalesOrderId) then
            Clear(CRMSalesOrderId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterPostSalesDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure PostCRMSalesDocumentOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        AddPostedSalesDocumentToCRMAccountWall(SalesHeader);

        if not IsNullGuid(CRMSalesOrderId) then // Should be set by SetOrderOnSalesHeaderDeletion
            SetCRMSalesOrderStateAsInvoiced;
    end;

    local procedure AddPostedSalesDocumentToCRMAccountWall(SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        if not CRMSetupDefaults.GetAddPostedSalesDocumentToCRMAccountWallConfig then
            exit;
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice] then begin
            Customer.Get(SalesHeader."Sell-to Customer No.");
            AddPostToCRMEntityWall(
              Customer.RecordId, StrSubstNo(CRMDocumentHasBeenPostedMsg, SalesHeader."Document Type", SalesHeader."No."));
        end;
    end;

    local procedure AddPostToCRMEntityWall(TargetRecordID: RecordID; Message: Text)
    var
        CRMPost: Record "CRM Post";
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        EntityID: Guid;
        EntityTypeName: Text;
    begin
        if not GetCRMEntityIdAndTypeName(TargetRecordID, EntityID, EntityTypeName) then
            exit;

        if not CRMIntegrationManagement.IsWorkingConnection then
            exit;

        CRMIntegrationRecord.FindByRecordID(TargetRecordID);
        if CRMIntegrationRecord."Table ID" = DATABASE::Customer then
            if not CRMAccount.Get(EntityID) then begin
                CRMIntegrationRecord.Skipped := true;
                CRMIntegrationRecord.Modify(true);
                exit;
            end;

        Clear(CRMPost);
        Evaluate(CRMPost.RegardingObjectTypeCode, EntityTypeName);
        CRMPost.RegardingObjectId := EntityID;
        CRMPost.Text := CopyStr(Message, 1, MaxStrLen(CRMPost.Text));
        CRMPost.Source := CRMPost.Source::AutoPost;
        CRMPost.Type := CRMPost.Type::Status;
        CRMPost.Insert();
    end;

    local procedure GetCRMEntityIdAndTypeName(DestinationRecordID: RecordID; var EntityID: Guid; var EntityTypeName: Text): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.FindIDFromRecordID(DestinationRecordID, EntityID) then
            exit(false);

        EntityTypeName := CRMIntegrationManagement.GetCRMEntityTypeName(DestinationRecordID.TableNo);
        exit(true);
    end;

    local procedure SetCRMSalesOrderStateAsInvoiced()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        if CRMSalesorder.Get(CRMSalesOrderId) then begin
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Invoiced;
            CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::Invoiced;
            CRMSalesorder.Modify();
        end;

        Clear(CRMSalesOrderId);
    end;

    procedure CheckShippedOrders(var SalesHeaderOrder: Record "Sales Header")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if SalesHeaderOrder.FindSet then
            repeat
                if IsSalesOrderFullyInvoiced(SalesHeaderOrder) then
                    if CRMIntegrationRecord.FindIDFromRecordID(SalesHeaderOrder.RecordId, CRMSalesOrderId) then
                        SetCRMSalesOrderStateAsInvoiced;
            until SalesHeaderOrder.Next = 0;
    end;

    local procedure IsSalesOrderFullyInvoiced(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Quantity Invoiced", '<>0');
        if SalesLine.FindFirst then begin
            SalesLine.SetRange("Quantity Invoiced");
            SalesLine.SetFilter("Outstanding Quantity", '<>0');
            if SalesLine.IsEmpty then begin
                SalesLine.SetRange("Outstanding Quantity");
                SalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                exit(SalesLine.IsEmpty);
            end;
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateCRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, 414, 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateACRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if PreviewMode then
            exit;

        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterSalesShptHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; SuppressCommit: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesShptHeaderCreated);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesInvHeaderCreated);
    end;

    local procedure CreateCRMPostBufferEntry(RecId: RecordID; ChangeType: Option)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        CRMPostBuffer.ID := CreateGuid;
        CRMPostBuffer."Table ID" := DATABASE::"Sales Header";
        CRMPostBuffer.RecId := RecId;
        CRMPostBuffer.ChangeType := ChangeType;
        CRMPostBuffer.ChangeDateTime := CurrentDateTime;
        CRMPostBuffer.Insert();
    end;
}

