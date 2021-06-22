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

    procedure RunBatch(var PurchaseHeader: Record "Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Receive: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.Invoice, Invoice);
        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.Receive, Receive);
        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.CalcInvoiceDiscount, CalcInvoiceDiscount);
        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.PostingDate, PostingDate);
        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate);
        BatchProcessingMgt.AddParameter(BatchPostParameterTypes.ReplaceDocumentDate, ReplaceDocumentDate);

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
        BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
        CalcInvoiceDiscont: Boolean;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
    begin
        BatchProcessingMgt.GetParameterBoolean(PurchaseHeader.RecordId, BatchPostParameterTypes.CalcInvoiceDiscount, CalcInvoiceDiscont);
        BatchProcessingMgt.GetParameterBoolean(PurchaseHeader.RecordId, BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate);
        BatchProcessingMgt.GetParameterDate(PurchaseHeader.RecordId, BatchPostParameterTypes.PostingDate, PostingDate);

        if CalcInvoiceDiscont then
            CalculateInvoiceDiscount(PurchaseHeader);

        PurchaseHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate);

        BatchProcessingMgt.GetParameterBoolean(PurchaseHeader.RecordId, BatchPostParameterTypes.Receive, PurchaseHeader.Receive);
        BatchProcessingMgt.GetParameterBoolean(PurchaseHeader.RecordId, BatchPostParameterTypes.Invoice, PurchaseHeader.Invoice);
        BatchProcessingMgt.GetParameterBoolean(PurchaseHeader.RecordId, BatchPostParameterTypes.Ship, PurchaseHeader.Ship);
        BatchProcessingMgt.GetParameterBoolean(
          PurchaseHeader.RecordId, BatchPostParameterTypes.Print, PurchaseHeader."Print Posted Documents");

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
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader) then
            exit(false);

        if PurchaseHeader.Status = PurchaseHeader.Status::"Pending Approval" then
            exit(false);

        if not PurchaseHeader.IsApprovedForPostingBatch then
            exit(false);

        exit(true);
    end;

    procedure AddParameter(ParameterId: Integer; ParameterValue: Variant)
    var
        ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        GetBatchProcessor(ResultBatchProcessingMgt);
        ResultBatchProcessingMgt.AddParameter(ParameterId, ParameterValue);
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
}

