codeunit 1372 "Purchase Batch Post Mgt."
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
    begin
        PurchaseHeader.Copy(Rec);

        BindSubscription(PurchaseBatchPostMgt);
        PurchaseBatchPostMgt.SetPostingCodeunitId(PostingCodeunitId);
        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        PurchaseBatchPostMgt.Code(PurchaseHeader);

        Rec := PurchaseHeader;
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        PostingDateIsNotSetErr: Label 'Enter the posting date.';
        BatchPostingMsg: Label 'Bacth posting of purchase documents.';
        ApprovalPendingErr: Label 'Cannot post purchase document no. %1 of type %2 because it is pending approval.', Comment = '%1 = Document No.; %2 = Document Type';
        ApprovalWorkflowErr: Label 'Cannot post purchase document no. %1 of type %2 due to the approval workflow.', Comment = '%1 = Document No.; %2 = Document Type';

    procedure RunBatch(var PurchaseHeader: Record "Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Receive: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Invoice, Invoice);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Receive, Receive);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);
        OnRunBatchOnAfterAddParameters(BatchProcessingMgt);

        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if PurchaseBatchPostMgt.Run(PurchaseHeader) then;
        BatchProcessingMgt.ResetBatchID;
        if GuiAllowed then begin
            BatchProcessingMgt.GetErrorMessages(TempErrorMessage);

            if TempErrorMessage.FindFirst then begin
                ErrorMessages.SetRecords(TempErrorMessage);
                ErrorMessages.Run;
            end;
        end;

        OnAfterRunBatch(PurchaseHeader, TempErrorMessage);
    end;

    procedure RunWithUI(var PurchaseHeader: Record "Purchase Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
    begin
        if not Confirm(StrSubstNo(Question, PurchaseHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, DATABASE::"Purchase Header", 0, BatchPostingMsg);
        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if PurchaseBatchPostMgt.Run(PurchaseHeader) then;
        BatchProcessingMgt.ResetBatchID;

        if ErrorMessageMgt.GetLastErrorID > 0 then
            ErrorMessageHandler.ShowErrors;
    end;

    procedure GetBatchProcessor(var ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        ResultBatchProcessingMgt := BatchProcessingMgt;
    end;

    procedure SetBatchProcessor(NewBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        BatchProcessingMgt := NewBatchProcessingMgt;
    end;

    procedure "Code"(var PurchaseHeader: Record "Purchase Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := CODEUNIT::"Purch.-Post";

        RecRef.GetTable(PurchaseHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(PurchaseHeader);
    end;

    local procedure PreparePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var BatchConfirm: Option)
    var
        CalcInvoiceDiscont: Boolean;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
    begin
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscont);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.GetDateParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if CalcInvoiceDiscont then
            CalculateInvoiceDiscount(PurchaseHeader);

        PurchaseHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate);

        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::Receive, PurchaseHeader.Receive);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::Invoice, PurchaseHeader.Invoice);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::Ship, PurchaseHeader.Ship);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, "Batch Posting Parameter Type"::Print, PurchaseHeader."Print Posted Documents");

        OnAfterPreparePurchaseHeader(PurchaseHeader);
    end;

    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    local procedure CalculateInvoiceDiscount(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst then begin
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
            Commit();
            PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        end;
    end;

    local procedure CanPostDocument(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if not CheckApprovalWorkflow(PurchaseHeader) then
            exit(false);

        if not PurchaseHeader.IsApprovedForPostingBatch then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckApprovalWorkflow(var PurchaseHeader: Record "Purchase Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader) then
            Error(ApprovalWorkflowErr, PurchaseHeader."No.", PurchaseHeader."Document Type");

        if PurchaseHeader.Status = PurchaseHeader.Status::"Pending Approval" then
            Error(ApprovalPendingErr, PurchaseHeader."No.", PurchaseHeader."Document Type");
    end;

    [Obsolete('Replaced by SetParameter().', '17.0')]
    procedure AddParameter(ParameterId: Integer; ParameterValue: Variant)
    begin
        SetParameter("Batch Posting Parameter Type".FromInteger(ParameterId), ParameterValue);
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant)
    var
        ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        GetBatchProcessor(ResultBatchProcessingMgt);
        ResultBatchProcessingMgt.SetParameter(ParameterId, ParameterValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnBeforeBatchProcessing', '', false, false)]
    local procedure PreparePurchaseHeaderOnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        PreparePurchaseHeader(PurchaseHeader, BatchConfirm);
        RecRef.GetTable(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnVerifyRecord', '', false, false)]
    local procedure CheckPurchaseHeaderOnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        Result := CanPostDocument(PurchaseHeader);
        RecRef.GetTable(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnCustomProcessing', '', false, false)]
    local procedure HandleOnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        RecRef.SetTable(PurchaseHeader);

        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Post with Job Queue" then begin
            PurchaseHeader."Print Posted Documents" :=
                PurchaseHeader."Print Posted Documents" and PurchasesPayablesSetup."Post & Print with Job Queue";
            PurchasePostViaJobQueue.EnqueuePurchDocWithUI(PurchaseHeader, false);
            if not IsNullGuid(PurchaseHeader."Job Queue Entry ID") then begin
                Commit();
                KeepParameters := true;
            end;
            PurchaseHeader."Print Posted Documents" := false;
            RecRef.GetTable(PurchaseHeader);
            Handled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunBatch(var PurchaseHeader: Record "Purchase Header"; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunBatchOnAfterAddParameters(var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;
}

