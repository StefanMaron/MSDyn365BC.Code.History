codeunit 5923 "Service-Quote to Order"
{
    Permissions = TableData "Loaner Entry" = m,
                  TableData "Service Order Allocation" = rimd;
    TableNo = "Service Header";

    trigger OnRun()
    var
        ServQuoteLine: Record "Service Line";
        Customer: Record Customer;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        SkipDelete: Boolean;
    begin
        OnBeforeRun(Rec);

        ServOrderHeader := Rec;

        ServMgtSetup.Get();

        ServOrderHeader."Document Type" := "Document Type"::Order;
        Customer.Get("Customer No.");
        Customer.CheckBlockedCustOnDocs(Customer, DocType::Quote, false, false);
        if "Customer No." <> "Bill-to Customer No." then begin
            Customer.Get("Bill-to Customer No.");
            Customer.CheckBlockedCustOnDocs(Customer, DocType::Quote, false, false);
        end;

        ValidateSalesPersonOnServiceHeader(Rec, true, false);

        CustCheckCreditLimit.ServiceHeaderCheck(ServOrderHeader);

        TransferQuoteToOrderLines(ServQuoteLine, Rec, ServOrderLine, ServOrderHeader);

        MakeOrder(Rec);

        SkipDelete := false;
        OnBeforeServHeaderDelete(Rec, SkipDelete);
        if not SkipDelete then
            Delete(true);
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        RepairStatus: Record "Repair Status";
        ServItemLine: Record "Service Item Line";
        ServItemLine2: Record "Service Item Line";
        ServOrderLine: Record "Service Line";
        ServOrderLine2: Record "Service Line";
        ServOrderAlloc: Record "Service Order Allocation";
        ServOrderHeader: Record "Service Header";
        LoanerEntry: Record "Loaner Entry";
        ServCommentLine: Record "Service Comment Line";
        ServCommentLine2: Record "Service Comment Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ServLogMgt: Codeunit ServLogManagement;
        ReserveServiceLine: Codeunit "Service Line-Reserve";

    local procedure TestNoSeries()
    begin
        ServMgtSetup.TestField("Service Order Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        exit(ServMgtSetup."Service Order Nos.");
    end;

    procedure ReturnOrderNo(): Code[20]
    begin
        exit(ServOrderHeader."No.");
    end;

    local procedure InsertServHeader(var ServiceHeaderOrder: Record "Service Header"; ServiceHeaderQuote: Record "Service Header")
    begin
        ServiceHeaderOrder.Insert(true);
        ServiceHeaderOrder."Document Date" := ServiceHeaderQuote."Document Date";
        ServiceHeaderOrder."Location Code" := ServiceHeaderQuote."Location Code";
        OnBeforeServiceHeaderOrderModify(ServiceHeaderOrder, ServiceHeaderQuote);
        ServiceHeaderOrder.Modify();

        OnAfterInsertServHeader(ServiceHeaderOrder, ServiceHeaderQuote);
    end;

    local procedure MakeOrder(ServiceHeader: Record "Service Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecordLinkManagement: Codeunit "Record Link Management";
        SkipDelete: Boolean;
    begin
        with ServOrderHeader do begin
            "No." := '';
            "No. Printed" := 0;
            Validate(Status, Status::Pending);
            "Order Date" := WorkDate;
            "Order Time" := Time;
            "Actual Response Time (Hours)" := 0;
            "Service Time (Hours)" := 0;
            "Starting Date" := 0D;
            "Starting Time" := 0T;
            "Finishing Date" := 0D;
            "Finishing Time" := 0T;

            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, '', 0D, "No.", "No. Series");

            "Quote No." := ServiceHeader."No.";
            RecordLinkManagement.CopyLinks(ServiceHeader, ServOrderHeader);
            InsertServHeader(ServOrderHeader, ServiceHeader);

            ServCommentLine.Reset();
            ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
            ServCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
            ServCommentLine.SetRange("No.", ServiceHeader."No.");
            ServCommentLine.SetRange("Table Line No.", 0);
            if ServCommentLine.Find('-') then
                repeat
                    ServCommentLine2 := ServCommentLine;
                    ServCommentLine2."Table Subtype" := "Document Type";
                    ServCommentLine2."No." := "No.";
                    OnBeforeServCommentLineInsert(ServCommentLine2, ServiceHeader, ServOrderHeader);
                    ServCommentLine2.Insert();
                until ServCommentLine.Next = 0;

            ServOrderAlloc.Reset();
            ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", Status);
            ServOrderAlloc.SetRange("Document Type", ServiceHeader."Document Type");
            ServOrderAlloc.SetRange("Document No.", ServiceHeader."No.");
            ServOrderAlloc.SetRange(Status, ServOrderAlloc.Status::Active);
            while ServOrderAlloc.FindFirst do begin
                ServOrderAlloc."Document Type" := "Document Type";
                ServOrderAlloc."Document No." := "No.";
                ServOrderAlloc."Service Started" := true;
                ServOrderAlloc.Status := ServOrderAlloc.Status::"Reallocation Needed";
                ServOrderAlloc.Modify();
            end;

            ServItemLine.Reset();
            ServItemLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServItemLine.SetRange("Document No.", ServiceHeader."No.");
            if ServItemLine.Find('-') then
                repeat
                    ServItemLine2 := ServItemLine;
                    ServItemLine2."Document Type" := "Document Type";
                    ServItemLine2."Document No." := "No.";
                    ServItemLine2."Starting Date" := 0D;
                    ServItemLine2."Starting Time" := 0T;
                    ServItemLine2."Actual Response Time (Hours)" := 0;
                    ServItemLine2."Finishing Date" := 0D;
                    ServItemLine2."Finishing Time" := 0T;
                    RepairStatus.Reset();
                    RepairStatus.SetRange(Initial, true);
                    if RepairStatus.FindFirst then
                        ServItemLine2."Repair Status Code" := RepairStatus.Code;
                    OnBeforeServiceItemLineInsert(ServItemLine2, ServItemLine);
                    ServItemLine2.Insert(true);
                    OnAfterInsertServiceLine(ServItemLine2, ServItemLine);
                until ServItemLine.Next = 0;

            UpdateResponseDateTime;

            LoanerEntry.Reset();
            LoanerEntry.SetCurrentKey("Document Type", "Document No.");
            LoanerEntry.SetRange("Document Type", ServiceHeader."Document Type" + 1);
            LoanerEntry.SetRange("Document No.", ServiceHeader."No.");
            while LoanerEntry.FindFirst do begin
                LoanerEntry."Document Type" := "Document Type" + 1;
                LoanerEntry."Document No." := "No.";
                LoanerEntry.Modify();
            end;

            ServCommentLine.Reset();
            ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
            ServCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
            ServCommentLine.SetRange("No.", ServiceHeader."No.");
            ServCommentLine.SetFilter("Table Line No.", '>%1', 0);
            if ServCommentLine.Find('-') then
                repeat
                    ServCommentLine2 := ServCommentLine;
                    ServCommentLine2."Table Subtype" := "Document Type";
                    ServCommentLine2."No." := "No.";
                    ServCommentLine2.Insert();
                until ServCommentLine.Next = 0;

            ServOrderLine.Reset();
            ServOrderLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServOrderLine.SetRange("Document No.", ServiceHeader."No.");
            if ServOrderLine.Find('-') then
                repeat
                    ServOrderLine2 := ServOrderLine;
                    ServOrderLine2."Document Type" := "Document Type";
                    ServOrderLine2."Document No." := "No.";
                    ServOrderLine2."Posting Date" := "Posting Date";
                    OnBeforeServOrderLineInsert(ServOrderLine2, ServOrderLine);
                    ServOrderLine2.Insert();
                    ReserveServiceLine.TransServLineToServLine(ServOrderLine, ServOrderLine2, ServOrderLine.Quantity);
                until ServOrderLine.Next = 0;

            ServLogMgt.ServOrderQuoteChanged(ServOrderHeader, ServiceHeader);
            ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(ServiceHeader.RecordId, "No.", RecordId);

            SkipDelete := false;
            OnBeforeServLineDeleteAll(ServiceHeader, ServOrderHeader, SkipDelete);
            if not SkipDelete then begin
                ApprovalsMgmt.DeleteApprovalEntries(ServiceHeader.RecordId);
                ServOrderLine.DeleteAll(true);
            end;
        end;
    end;

    local procedure TransferQuoteToOrderLines(var ServiceQuoteLine: Record "Service Line"; var ServiceQuoteHeader: Record "Service Header"; var ServiceOrderLine: Record "Service Line"; var ServiceOrderHeader: Record "Service Header")
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        ServiceQuoteLine.Reset();
        ServiceQuoteLine.SetRange("Document Type", ServiceQuoteHeader."Document Type");
        ServiceQuoteLine.SetRange("Document No.", ServiceQuoteHeader."No.");
        ServiceQuoteLine.SetRange(Type, ServiceQuoteLine.Type::Item);
        ServiceQuoteLine.SetFilter("No.", '<>%1', '');
        if ServiceQuoteLine.FindSet then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(ServiceQuoteLine, ServiceQuoteHeader, ServiceOrderHeader, IsHandled);
                if not IsHandled then begin
                    ServiceOrderLine := ServiceQuoteLine;
                    ServiceOrderLine.Validate("Reserved Qty. (Base)", 0);
                    ServiceOrderLine."Line No." := 0;
                    if GuiAllowed then
                        if ItemCheckAvail.ServiceInvLineCheck(ServiceOrderLine) then
                            ItemCheckAvail.RaiseUpdateInterruptedError;
                end;
            until ServiceQuoteLine.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServHeader(var ServiceHeaderOrder: Record "Service Header"; ServiceHeaderQuote: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServiceLine(var ServiceItemLine2: Record "Service Item Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCommentLineInsert(var ServiceCommentLine: Record "Service Comment Line"; ServiceQuoteHeader: Record "Service Header"; ServiceOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServHeaderDelete(var ServiceHeader: Record "Service Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLineDeleteAll(var ServiceHeader: Record "Service Header"; var NewServiceHeader: Record "Service Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServOrderLineInsert(var ServiceOrderLine2: Record "Service Line"; ServiceOrderLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderOrderModify(var ServiceOrderHeader: Record "Service Header"; ServiceQuoteHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceItemLineInsert(var ServiceItemLine2: Record "Service Item Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var ServiceQuoteLine: Record "Service Line"; var ServiceQuoteHeader: Record "Service Header"; var ServiceOrderHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

