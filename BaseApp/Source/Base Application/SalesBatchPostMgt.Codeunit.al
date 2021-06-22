codeunit 1371 "Sales Batch Post Mgt."
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
    begin
        SalesHeader.Copy(Rec);

        BindSubscription(SalesBatchPostMgt);
        SalesBatchPostMgt.SetPostingCodeunitId(PostingCodeunitId);
        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        SalesBatchPostMgt.Code(SalesHeader);

        Rec := SalesHeader;
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        PostingDateIsNotSetErr: Label 'Enter the posting date.';
        BatchPostingMsg: Label 'Bacth posting of sales documents.';

    procedure RunBatch(var SalesHeader: Record "Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Ship: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Invoice, Invoice);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::Ship, Ship);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.SetParameter("Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);
        OnRunBatchOnAfterAddParameters(BatchProcessingMgt);

        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if SalesBatchPostMgt.Run(SalesHeader) then;
        BatchProcessingMgt.ResetBatchID;
        if GuiAllowed then begin
            BatchProcessingMgt.GetErrorMessages(TempErrorMessage);

            if TempErrorMessage.FindFirst then begin
                ErrorMessages.SetRecords(TempErrorMessage);
                ErrorMessages.Run;
            end;
        end;
    end;

    procedure RunWithUI(var SalesHeader: Record "Sales Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
    begin
        if not Confirm(StrSubstNo(Question, SalesHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, DATABASE::"Sales Header", 0, BatchPostingMsg);
        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if SalesBatchPostMgt.Run(SalesHeader) then;
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

    procedure "Code"(var SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := CODEUNIT::"Sales-Post";

        RecRef.GetTable(SalesHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(SalesHeader);
    end;

    local procedure PrepareSalesHeader(var SalesHeader: Record "Sales Header"; var BatchConfirm: Option)
    var
        CalcInvoiceDiscont: Boolean;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
    begin
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscont);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.GetDateParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if CalcInvoiceDiscont then
            CalculateInvoiceDiscount(SalesHeader);

        SalesHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate);

        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::Ship, SalesHeader.Ship);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::Invoice, SalesHeader.Invoice);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::Receive, SalesHeader.Receive);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, "Batch Posting Parameter Type"::Print, SalesHeader."Print Posted Documents");

        OnAfterPrepareSalesHeader(SalesHeader);
    end;

    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    local procedure CalculateInvoiceDiscount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindFirst then begin
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            Commit();
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    local procedure CanPostDocument(var SalesHeader: Record "Sales Header"): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsSalesApprovalsWorkflowEnabled(SalesHeader) then
            exit(false);

        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then
            exit(false);

        if not SalesHeader.IsApprovedForPostingBatch then
            exit(false);

        exit(true);
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
    local procedure PrepareSalesHeaderOnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        PrepareSalesHeader(SalesHeader, BatchConfirm);
        RecRef.GetTable(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnVerifyRecord', '', false, false)]
    local procedure CheckSalesHeaderOnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        Result := CanPostDocument(SalesHeader);
        RecRef.GetTable(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, 1380, 'OnCustomProcessing', '', false, false)]
    local procedure HandleOnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        RecRef.SetTable(SalesHeader);

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Post with Job Queue" then begin
            SalesHeader."Print Posted Documents" :=
              SalesHeader."Print Posted Documents" and SalesReceivablesSetup."Post & Print with Job Queue";
            SalesPostViaJobQueue.EnqueueSalesDocWithUI(SalesHeader, false);
            if not IsNullGuid(SalesHeader."Job Queue Entry ID") then begin
                Commit();
                KeepParameters := true;
            end;
            SalesHeader."Print Posted Documents" := false;
            RecRef.GetTable(SalesHeader);
            Handled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunBatchOnAfterAddParameters(var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;
}

