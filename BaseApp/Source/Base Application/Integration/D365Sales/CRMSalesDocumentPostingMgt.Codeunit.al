codeunit 5346 "CRM Sales Document Posting Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSalesOrderId: Guid;
        DeletedCoupledOrderNo: Code[20];
        DeletedCoupledOrderYourReference: Text[35];
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CRMOrderHasBeenPostedMsg: Label '%1 ''%2'' has been posted in %3.', Comment = '%1=Document Type;%2=Document Id;%3=The name of our product';
        CRMInvoiceHasBeenPostedMsg: Label 'Invoice ''%1'' for order ''%2'' has been posted in %3.', Comment = '%1=Invoice number;%2=Order number;%3=The name of our product';
        FailedToCreatePostErr: Label 'Failed to create a post on the entity wall of %1 with id %2.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeDeleteAfterPosting', '', false, false)]
    local procedure SetSalesOrderIdsOnSalesHeaderDeletion(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SkipDelete: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        DeletedCoupledOrderNo := '';
        DeletedCoupledOrderYourReference := '';
        Clear(CRMSalesOrderId);

        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesOrderId) then begin
            DeletedCoupledOrderNo := SalesHeader."No.";
            DeletedCoupledOrderYourReference := SalesHeader."Your Reference";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PostCRMSalesDocumentOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostCRMSalesDocumentOnAfterPostSalesDoc(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");

        AddPostedSalesDocumentToCRMAccountWall(SalesHeader, SalesInvHdrNo);

        if not IsNullGuid(CRMSalesOrderId) then // Should be set by SetOrderOnSalesHeaderDeletion
            SetCRMSalesOrderStateAsInvoiced();
    end;

    local procedure AddPostedSalesDocumentToCRMAccountWall(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrderHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;

        if not CRMSetupDefaults.GetAddPostedSalesDocumentToCRMAccountWallConfig() then
            exit;

        Customer.Get(SalesHeader."Sell-to Customer No.");

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                if (SalesHeader."No." = DeletedCoupledOrderNo) then
                    AddPostToCRMEntityWall(Customer.RecordId, StrSubstNo(CRMOrderHasBeenPostedMsg, SalesHeader."Document Type", DeletedCoupledOrderYourReference, ProductName.Short()))
                else
                    if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, SalesHeader."No.") then
                        if CRMIntegrationRecord.FindByRecordID(SalesOrderHeader.RecordId) then
                            AddPostToCRMEntityWall(Customer.RecordId, StrSubstNo(CRMOrderHasBeenPostedMsg, SalesHeader."Document Type", SalesOrderHeader."Your Reference", ProductName.Short()));
            SalesHeader."Document Type"::Invoice:
                if SalesInvoiceHeader.Get(SalesInvHdrNo) then
                    if (SalesInvoiceHeader."Your Reference" <> '') and (SalesInvoiceHeader."Your Reference" = DeletedCoupledOrderYourReference) then
                        AddPostToCRMEntityWall(Customer.RecordId, StrSubstNo(CRMInvoiceHasBeenPostedMsg, SalesInvoiceHeader."No.", SalesInvoiceHeader."Your Reference", ProductName.Short()))
                    else
                        if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, SalesInvoiceHeader."Order No.") then
                            if CRMIntegrationRecord.FindByRecordID(SalesOrderHeader.RecordId) then
                                AddPostToCRMEntityWall(Customer.RecordId, StrSubstNo(CRMInvoiceHasBeenPostedMsg, SalesInvoiceHeader."No.", SalesOrderHeader."Your Reference", ProductName.Short()));
        end;
    end;

    local procedure AddPostToCRMEntityWall(TargetRecordID: RecordID; Message: Text)
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        EntityID: Guid;
        EntityTypeName: Text;
    begin
        if not GetCRMEntityIdAndTypeName(TargetRecordID, EntityID, EntityTypeName) then
            exit;

        if not CRMIntegrationManagement.IsWorkingConnection() then
            exit;

        CRMIntegrationRecord.FindByRecordID(TargetRecordID);
        if CRMIntegrationRecord."Table ID" = DATABASE::Customer then
            if not CRMAccount.Get(EntityID) then begin
                CRMIntegrationRecord.Skipped := true;
                CRMIntegrationRecord.Modify(true);
                exit;
            end;

        if not TryCreatePost(EntityTypeName, EntityID, Message) then
            Session.LogMessage('0000KOV', StrSubstNo(FailedToCreatePostErr, EntityTypeName, EntityID), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    [TryFunction]
    local procedure TryCreatePost(EntityTypeName: Text; EntityID: Guid; Message: Text)
    var
        CRMPost: Record "CRM Post";
    begin
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
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");

        if SalesHeaderOrder.FindSet() then
            repeat
                if IsSalesOrderFullyInvoiced(SalesHeaderOrder) then
                    if CRMIntegrationRecord.FindIDFromRecordID(SalesHeaderOrder.RecordId, CRMSalesOrderId) then
                        SetCRMSalesOrderStateAsInvoiced();
            until SalesHeaderOrder.Next() = 0;
    end;

    local procedure IsSalesOrderFullyInvoiced(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Quantity Invoiced", '<>0');
        if SalesLine.FindFirst() then begin
            SalesLine.SetRange("Quantity Invoiced");
            SalesLine.SetFilter("Outstanding Quantity", '<>0');
            if SalesLine.IsEmpty() then begin
                SalesLine.SetRange("Outstanding Quantity");
                SalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                exit(SalesLine.IsEmpty);
            end;
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateCRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateACRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if PreviewMode then
            exit;

        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; SuppressCommit: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesShptHeaderCreated);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesInvHeaderCreated);
    end;

    local procedure CreateCRMPostBufferEntry(RecId: RecordID; ChangeType: Option)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if not CRMPostBuffer.WritePermission() then
            exit;

        CRMPostBuffer.ID := CreateGuid();
        CRMPostBuffer."Table ID" := DATABASE::"Sales Header";
        CRMPostBuffer.RecId := RecId;
        CRMPostBuffer.ChangeType := ChangeType;
        CRMPostBuffer.ChangeDateTime := CurrentDateTime;
        CRMPostBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCRMSalesDocumentOnAfterPostSalesDoc(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

