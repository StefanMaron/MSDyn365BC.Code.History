codeunit 1303 "Correct Posted Sales Invoice"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        UnapplyCostApplication("No.");

        OnBeforeCreateCorrectiveSalesCrMemo(Rec);
        CreateCopyDocument(Rec, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        OnAfterCreateCorrectiveSalesCrMemo(Rec, SalesHeader, CancellingOnly);

        if SalesInvoiceLinesContainJob("No.") then
            CreateAndProcessJobPlanningLines(SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        SetTrackInfoForCancellation(Rec);
        UpdateSalesOrderLinesFromCancelledInvoice("No.");

        Commit();
    end;

    var
        PostedInvoiceIsPaidCorrectErr: Label 'You cannot correct this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        PostedInvoiceIsPaidCCancelErr: Label 'You cannot cancel this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must manually create a sales credit memo.';
        PostedInvoiceIsPaidCancelInInvAppErr: Label 'You cannot cancel this posted sales invoice because it is fully or partially paid.\\To reverse a paid sales invoice, you must delete all existing payments and then proceed to cancellation.';
        AlreadyCorrectedErr: Label 'You cannot correct this posted sales invoice because it has been canceled.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales invoice because it has already been canceled.';
        CorrCorrectiveDocErr: Label 'You cannot correct this posted sales invoice because it represents a correction of a credit memo.';
        CancelCorrectiveDocErr: Label 'You cannot cancel this posted sales invoice because it represents a correction of a credit memo.';
        CustomerIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCorrectErr: Label 'You cannot correct this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales invoice because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreeCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreeCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused credit memo numbers are available. \\You must extend the range of the number series for credit memos.';
        NoFreePostCMSeriesCorrectErr: Label 'You cannot correct this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        NoFreePostCMSeriesCancelErr: Label 'You cannot cancel this posted sales invoice because no unused posted credit memo numbers are available. \\You must extend the range of the number series for posted credit memos.';
        SalesLineFromOrderCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used on a sales order.', Comment = '%1 = Item no. %2 = Item description';
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        UsedInJobCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 is used in a job.', Comment = '%1 = Item no. %2 = Item description.';
        PostingNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because it was posted in a posting period that is closed.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because it was posted in a posting period that is closed.';
        LineTypeNotAllowedCorrectErr: Label 'You cannot correct this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        LineTypeNotAllowedCancelErr: Label 'You cannot cancel this posted sales invoice because the sales invoice line for %1 %2 is of type %3, which is not allowed on a simplified sales invoice.', Comment = '%1 = Item no. %2 = Item description %3 = Item type.';
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CancellingOnly: Boolean;
        InvalidDimCodeCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being canceled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCorrectErr: Label 'You cannot correct this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales invoice because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCorrectErr: Label 'You cannot correct this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales invoice because the combination of dimensions on the invoice is blocked.';
        ExternalDocCorrectErr: Label 'You cannot correct this posted sales invoice because the external document number is required on the invoice.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales invoice because the external document number is required on the invoice.';
        InventoryPostClosedCorrectErr: Label 'You cannot correct this posted sales invoice because the posting inventory period is already closed.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales invoice because the posting inventory period is already closed.';
        FixedAssetNotPossibleToCreateCreditMemoErr: Label 'You cannot cancel this posted sales invoice because it contains lines of type Fixed Asset.\\Use the Cancel Entries function in the FA Ledger Entries window instead.';
        PostingCreditMemoFailedOpenPostedCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted. Do you want to open the posted credit memo?';
        PostingCreditMemoFailedOpenCMQst: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted. Do you want to open the credit memo?';
        CreatingCreditMemoFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.';
        ErrorType: Option IsPaid,CustomerBlocked,ItemBlocked,AccountBlocked,IsCorrected,IsCorrective,SerieNumInv,SerieNumCM,SerieNumPostCM,ItemIsReturned,FromOrder,PostingNotAllowed,LineFromOrder,WrongItemType,LineFromJob,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        WrongDocumentTypeForCopyDocumentErr: Label 'You cannot correct or cancel this type of document.';
        CheckPrepaymentErr: Label 'You cannot correct or cancel a posted sales prepayment invoice.\\Open the related sales order and choose the Post Prepayment Credit Memo.';
        InvoicePartiallyPaidMsg: Label 'Invoice %1 is partially paid or credited. The corrective credit memo may not be fully closed by the invoice.', Comment = '%1 - invoice no.';
        InvoiceClosedMsg: Label 'Invoice %1 is closed. The corrective credit memo will not be applied to the invoice.', Comment = '%1 - invoice no.';
        SkipLbl: Label 'Skip';
        CreateCreditMemoLbl: Label 'Create credit memo anyway';
        ShowEntriesLbl: Label 'Show applied entries';

    procedure CancelPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        CancellingOnly := true;
        exit(CreateCreditMemo(SalesInvoiceHeader));
    end;

    local procedure CreateCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, CancellingOnly);
        if not CODEUNIT.Run(CODEUNIT::"Correct Posted Sales Invoice", SalesInvoiceHeader) then begin
            SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
            if SalesCrMemoHeader.FindFirst then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedCMQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
            end else begin
                SalesHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
                if SalesHeader.FindFirst then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenCMQst, GetLastErrorText)) then begin
                        IsHandled := false;
                        OnCreateCreditMemoOnBeforePageRun(SalesHeader, IsHandled);
                        if not IsHandled then
                            PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
                    end;
                end else
                    Error(CreatingCreditMemoFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; DocumentType: Option; SkipCopyFromDescription: Boolean)
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(SalesHeader);
        SalesHeader."No." := '';
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.SetAllowSelectNoSeries;
        OnBeforeSelesHeaderInsert(SalesHeader, SalesInvoiceHeader, CancellingOnly);
        OnBeforeSalesHeaderInsert(SalesHeader, SalesInvoiceHeader, CancellingOnly);
        SalesHeader.Insert(true);

        case DocumentType of
            SalesHeader."Document Type"::"Credit Memo":
                CopyDocMgt.SetPropertiesForCreditMemoCorrection;
            SalesHeader."Document Type"::Invoice:
                CopyDocMgt.SetPropertiesForInvoiceCorrection(SkipCopyFromDescription);
            else
                Error(WrongDocumentTypeForCopyDocumentErr);
        end;

        CopyDocMgt.CopySalesDocForInvoiceCancelling(SalesInvoiceHeader."No.", SalesHeader);
    end;

    procedure CreateCreditMemoCopyDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        TestNoFixedAssetInSalesInvoice(SalesInvoiceHeader);
        TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader);
        if not SalesInvoiceHeader.IsFullyOpen then begin
            ShowInvoiceAppliedNotification(SalesInvoiceHeader);
            exit(false);
        end;
        CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        exit(true);
    end;

    procedure CreateCorrectiveCreditMemo(var InvoiceNotification: Notification)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNotification.GetData(SalesInvoiceHeader.FieldName("No.")));
        InvoiceNotification.Recall;

        CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);
    end;

    procedure ShowAppliedEntries(var InvoiceNotification: Notification)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNotification.GetData(SalesInvoiceHeader.FieldName("No.")));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        PAGE.RunModal(PAGE::"Applied Customer Entries", CustLedgerEntry);
    end;

    procedure SkipCorrectiveCreditMemo(var InvoiceNotification: Notification)
    begin
        InvoiceNotification.Recall;
    end;

    local procedure CreateAndProcessJobPlanningLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Job Contract Entry No.", '<>0');
        if SalesLine.FindSet then
            repeat
                SalesLine."Job Contract Entry No." := CreateJobPlanningLine(SalesHeader, SalesLine);
                SalesLine.Modify();
            until SalesLine.Next = 0;
    end;

    local procedure CreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"): Integer
    var
        FromJobPlanningLine: Record "Job Planning Line";
        ToJobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        FromJobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        FromJobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        FromJobPlanningLine.FindFirst;

        ToJobPlanningLine.InitFromJobPlanningLine(FromJobPlanningLine, -SalesLine.Quantity);
        JobPlanningLineInvoice.InitFromJobPlanningLine(ToJobPlanningLine);
        JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");
        JobPlanningLineInvoice.Insert();

        ToJobPlanningLine.UpdateQtyToTransfer;
        ToJobPlanningLine.Insert();

        exit(ToJobPlanningLine."Job Contract Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CancelPostedInvoiceStartNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
        CancellingOnly := false;

        if CreateCreditMemo(SalesInvoiceHeader) then begin
            CreateCopyDocument(SalesInvoiceHeader, SalesHeader, SalesHeader."Document Type"::Invoice, true);
            OnAfterCreateCorrSalesInvoice(SalesHeader);
            Commit();
        end;
    end;

    procedure TestCorrectInvoiceIsAllowed(var SalesInvoiceHeader: Record "Sales Invoice Header"; Cancelling: Boolean)
    begin
        CancellingOnly := Cancelling;

        SalesInvoiceHeader.CalcFields(Amount);
        TestIfPostingIsAllowed(SalesInvoiceHeader);
        TestIfInvoiceIsCorrectedOnce(SalesInvoiceHeader);
        TestIfInvoiceIsNotCorrectiveDoc(SalesInvoiceHeader);
        TestIfInvoiceIsPaid(SalesInvoiceHeader);
        TestIfCustomerIsBlocked(SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
        TestIfCustomerIsBlocked(SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.");
        TestIfJobPostingIsAllowed(SalesInvoiceHeader."No.");
        TestCustomerDimension(SalesInvoiceHeader, SalesInvoiceHeader."Bill-to Customer No.");
        TestDimensionOnHeader(SalesInvoiceHeader);
        TestSalesLines(SalesInvoiceHeader);
        TestIfAnyFreeNumberSeries(SalesInvoiceHeader);
        TestExternalDocument(SalesInvoiceHeader);
        TestInventoryPostingClosed(SalesInvoiceHeader);
        TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader);

        OnAfterTestCorrectInvoiceIsAllowed(SalesInvoiceHeader, Cancelling);
    end;

    local procedure ShowInvoiceAppliedNotification(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoiceNotification: Notification;
        NotificationText: Text;
    begin
        InvoiceNotification.Id := CreateGuid;
        InvoiceNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        InvoiceNotification.SetData(SalesInvoiceHeader.FieldName("No."), SalesInvoiceHeader."No.");
        SalesInvoiceHeader.CalcFields(Closed);
        if SalesInvoiceHeader.Closed then
            NotificationText := StrSubstNo(InvoiceClosedMsg, SalesInvoiceHeader."No.")
        else
            NotificationText := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        InvoiceNotification.Message(NotificationText);
        InvoiceNotification.AddAction(ShowEntriesLbl, CODEUNIT::"Correct Posted Sales Invoice", 'ShowAppliedEntries');
        InvoiceNotification.AddAction(SkipLbl, CODEUNIT::"Correct Posted Sales Invoice", 'SkipCorrectiveCreditMemo');
        InvoiceNotification.AddAction(CreateCreditMemoLbl, CODEUNIT::"Correct Posted Sales Invoice", 'CreateCorrectiveCreditMemo');
        NotificationLifecycleMgt.SendNotification(InvoiceNotification, SalesInvoiceHeader.RecordId);
    end;

    local procedure SetTrackInfoForCancellation(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        if SalesCrMemoHeader.FindLast then
            CancelledDocument.InsertSalesInvToCrMemoCancelledDocument(SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");
    end;

    local procedure SalesInvoiceLinesContainJob(InvoiceNo: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.SetFilter("Job No.", '<>%1', '');
        exit(not SalesInvoiceLine.IsEmpty);
    end;

    local procedure TestDimensionOnHeader(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(SalesInvoiceHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, SalesInvoiceHeader);
    end;

    local procedure TestIfCustomerIsBlocked(SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(ErrorType::CustomerBlocked, SalesInvoiceHeader);
    end;

    local procedure TestCustomerDimension(SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Customer.TableCaption, Customer."No.", Customer."No.", Customer.Name);
    end;

    local procedure TestSalesLines(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        ShippedQtyNoReturned: Decimal;
        RevUnitCostLCY: Decimal;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        TestNoFixedAssetInSalesLines(SalesInvoiceLine);
        if SalesInvoiceLine.Find('-') then
            repeat
                if not IsCommentLine(SalesInvoiceLine) then begin
                    TestSalesLineType(SalesInvoiceLine);

                    if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
                        if (SalesInvoiceLine.Quantity > 0) and (SalesInvoiceLine."Job No." = '') and
                           WasNotCancelled(SalesInvoiceHeader."No.")
                        then begin
                            SalesInvoiceLine.CalcShippedSaleNotReturned(ShippedQtyNoReturned, RevUnitCostLCY, false);
                            if SalesInvoiceLine.Quantity <> ShippedQtyNoReturned then
                                ErrorHelperLine(ErrorType::ItemIsReturned, SalesInvoiceLine);
                        end;

                        Item.Get(SalesInvoiceLine."No.");

                        if Item.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, SalesInvoiceLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := SalesInvoiceLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, Item.TableCaption, No[1], Item."No.", Item.Description);

                        if Item.Type = Item.Type::Inventory then
                            TestInventoryPostingSetup(SalesInvoiceLine);
                    end;

                    TestGenPostingSetup(SalesInvoiceLine);
                    TestCustomerPostingGroup(SalesInvoiceLine, SalesInvoiceHeader."Customer Posting Group");
                    TestVATPostingSetup(SalesInvoiceLine);

                    if not DimensionManagement.CheckDimIDComb(SalesInvoiceLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, SalesInvoiceLine);
                end;
            until SalesInvoiceLine.Next = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, GLAccount.TableCaption, AccountNo, '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
            Item.Get(SalesInvoiceLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesInvoiceLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, GLAccount.TableCaption, AccountNo, Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsPaid(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        if SalesInvoiceHeader."Amount Including VAT" <> SalesInvoiceHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsPaid, SalesInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, SalesInvoiceHeader);
    end;

    local procedure TestIfInvoiceIsNotCorrectiveDoc(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindSalesCorrectiveInvoice(SalesInvoiceHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrective, SalesInvoiceHeader);
    end;

    local procedure TestIfPostingIsAllowed(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(SalesInvoiceHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, SalesInvoiceHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate;
        SalesReceivablesSetup.Get();

        if NoSeriesManagement.TryGetNextNo(SalesReceivablesSetup."Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumCM, SalesInvoiceHeader);

        if NoSeriesManagement.TryGetNextNo(SalesReceivablesSetup."Posted Credit Memo Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostCM, SalesInvoiceHeader);

        if (not CancellingOnly) and (NoSeriesManagement.TryGetNextNo(SalesReceivablesSetup."Invoice Nos.", PostingDate) = '') then
            ErrorHelperHeader(ErrorType::SerieNumInv, SalesInvoiceHeader);
    end;

    local procedure TestIfJobPostingIsAllowed(SalesInvoiceNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Job: Record Job;
    begin
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.SetFilter("Job No.", '<>%1', '');
        if SalesInvoiceLine.FindSet then
            repeat
                Job.Get(SalesInvoiceLine."Job No.");
                Job.TestBlocked;
            until SalesInvoiceLine.Next = 0;
    end;

    local procedure TestExternalDocument(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if (SalesInvoiceHeader."External Document No." = '') and SalesReceivablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, SalesInvoiceHeader);
    end;

    local procedure TestInventoryPostingClosed(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        InventoryPeriod: Record "Inventory Period";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentHasLineWithRestrictedType: Boolean;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Quantity, '<>%1', 0);
        SalesInvoiceLine.SetFilter(Type, '%1|%2', SalesInvoiceLine.Type::Item, SalesInvoiceLine.Type::"Charge (Item)");
        DocumentHasLineWithRestrictedType := not SalesInvoiceLine.IsEmpty;

        if DocumentHasLineWithRestrictedType then begin
            InventoryPeriod.SetRange(Closed, true);
            InventoryPeriod.SetFilter("Ending Date", '>=%1', SalesInvoiceHeader."Posting Date");
            if InventoryPeriod.FindFirst then
                ErrorHelperHeader(ErrorType::InventoryPostClosed, SalesInvoiceHeader);
        end;
    end;

    local procedure TestSalesLineType(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        IsHandled: Boolean;
    begin
        if SalesInvoiceLine.IsCancellationSupported then
            exit;

        if (SalesInvoiceLine."Job No." <> '') and (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Resource) then
            exit;

        IsHandled := false;
        OnAfterTestSalesLineType(SalesInvoiceLine, IsHandled);
        if not IsHandled then
            ErrorHelperLine(ErrorType::WrongItemType, SalesInvoiceLine);
    end;

    local procedure TestGenPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        SalesReceivablesSetup.GetRecordOnce;

        with GenPostingSetup do begin
            Get(SalesInvoiceLine."Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group");
            if SalesInvoiceLine.Type <> SalesInvoiceLine.Type::"G/L Account" then begin
                TestField("Sales Account");
                TestGLAccount("Sales Account", SalesInvoiceLine);
                TestField("Sales Credit Memo Account");
                TestGLAccount("Sales Credit Memo Account", SalesInvoiceLine);
            end;
            if SalesReceivablesSetup."Discount Posting" <> SalesReceivablesSetup."Discount Posting"::"No Discounts" then begin
                TestField("Sales Line Disc. Account");
                TestGLAccount("Sales Line Disc. Account", SalesInvoiceLine);
            end;
            if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
                Item.Get(SalesInvoiceLine."No.");
                if Item.IsInventoriableType then
                    TestGLAccount(GetCOGSAccount, SalesInvoiceLine);
            end;
        end;
    end;

    local procedure TestCustomerPostingGroup(SalesInvoiceLine: Record "Sales Invoice Line"; CustomerPostingGr: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        with CustomerPostingGroup do begin
            Get(CustomerPostingGr);
            TestField("Receivables Account");
            TestGLAccount("Receivables Account", SalesInvoiceLine);
        end;
    end;

    local procedure TestVATPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                TestField("Sales VAT Account");
                TestGLAccount("Sales VAT Account", SalesInvoiceLine);
            end;
        end;
    end;

    local procedure TestInventoryPostingSetup(SalesInvoiceLine: Record "Sales Invoice Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        with InventoryPostingSetup do begin
            Get(SalesInvoiceLine."Location Code", SalesInvoiceLine."Posting Group");
            TestField("Inventory Account");
            TestGLAccount("Inventory Account", SalesInvoiceLine);
        end;
    end;

    local procedure TestNoFixedAssetInSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        TestNoFixedAssetInSalesLines(SalesInvoiceLine);
    end;

    local procedure TestNoFixedAssetInSalesLines(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Copy(SalesInvoiceLine);
        SalesInvLine.SetRange(Type, SalesInvLine.Type::"Fixed Asset");
        if not SalesInvLine.IsEmpty then
            Error(FixedAssetNotPossibleToCreateCreditMemoErr);
    end;

    local procedure TestNotSalesPrepaymentlInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if SalesInvoiceHeader."Prepayment Invoice" then
            Error(CheckPrepaymentErr);
    end;

    local procedure IsCommentLine(SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    begin
        exit((SalesInvoiceLine.Type = SalesInvoiceLine.Type::" ") or (SalesInvoiceLine."No." = ''));
    end;

    local procedure WasNotCancelled(InvNo: Code[20]): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", InvNo);
        exit(SalesCrMemoHeader.IsEmpty);
    end;

    local procedure UnapplyCostApplication(InvNo: Code[20])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempItemApplicationEntry: Record "Item Application Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        FindItemLedgEntries(TempItemLedgEntry, InvNo);
        if FindAppliedInbndEntries(TempItemApplicationEntry, TempItemLedgEntry) then begin
            repeat
                ItemJnlPostLine.UnApply(TempItemApplicationEntry);
            until TempItemApplicationEntry.Next = 0;
            ItemJnlPostLine.RedoApplications;
        end;
    end;

    procedure FindItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry"; InvNo: Code[20])
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        with SalesInvLine do begin
            SetRange("Document No.", InvNo);
            SetRange(Type, Type::Item);
            if FindSet then
                repeat
                    GetItemLedgEntries(ItemLedgEntry, false);
                until Next = 0;
        end;
    end;

    local procedure FindAppliedInbndEntries(var TempItemApplicationEntry: Record "Item Application Entry" temporary; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        TempItemApplicationEntry.Reset();
        TempItemApplicationEntry.DeleteAll();
        if ItemLedgEntry.FindSet then
            repeat
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgEntry."Entry No.", true) then
                    repeat
                        TempItemApplicationEntry := ItemApplicationEntry;
                        if not TempItemApplicationEntry.Find then
                            TempItemApplicationEntry.Insert();
                    until ItemApplicationEntry.Next = 0;
            until ItemLedgEntry.Next = 0;
        exit(TempItemApplicationEntry.FindSet);
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::IsPaid:
                    begin
                        if EnvInfoProxy.IsInvoicing then
                            Error(PostedInvoiceIsPaidCancelInInvAppErr);
                        Error(PostedInvoiceIsPaidCCancelErr);
                    end;
                ErrorType::CustomerBlocked:
                    begin
                        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCancelErr, Customer.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCancelledErr);
                ErrorType::IsCorrective:
                    Error(CancelCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCancelErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCancelErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCancelErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCancelErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCancelErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCancelErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCancelErr);
            end
        else
            case ErrorOption of
                ErrorType::IsPaid:
                    Error(PostedInvoiceIsPaidCorrectErr);
                ErrorType::CustomerBlocked:
                    begin
                        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                        Error(CustomerIsBlockedCorrectErr, Customer.Name);
                    end;
                ErrorType::IsCorrected:
                    Error(AlreadyCorrectedErr);
                ErrorType::IsCorrective:
                    Error(CorrCorrectiveDocErr);
                ErrorType::SerieNumInv:
                    Error(NoFreeInvoiceNoSeriesCorrectErr);
                ErrorType::SerieNumPostCM:
                    Error(NoFreePostCMSeriesCorrectErr);
                ErrorType::SerieNumCM:
                    Error(NoFreeCMSeriesCorrectErr);
                ErrorType::PostingNotAllowed:
                    Error(PostingNotAllowedCorrectErr);
                ErrorType::ExtDocErr:
                    Error(ExternalDocCorrectErr);
                ErrorType::InventoryPostClosed:
                    Error(InventoryPostClosedCorrectErr);
                ErrorType::DimCombHeaderErr:
                    Error(InvalidDimCombHeaderCorrectErr);
            end;
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        Item: Record Item;
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ShippedQtyReturnedCancelErr, Item."No.", Item.Description);
                    end;
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description, SalesInvoiceLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCancelErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
            end
        else
            case ErrorOption of
                ErrorType::ItemBlocked:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ItemIsBlockedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::ItemIsReturned:
                    begin
                        Item.Get(SalesInvoiceLine."No.");
                        Error(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description);
                    end;
                ErrorType::LineFromOrder:
                    Error(SalesLineFromOrderCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                ErrorType::WrongItemType:
                    Error(LineTypeNotAllowedCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description, SalesInvoiceLine.Type);
                ErrorType::LineFromJob:
                    Error(UsedInJobCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
                ErrorType::DimCombErr:
                    Error(InvalidDimCombinationCorrectErr, SalesInvoiceLine."No.", SalesInvoiceLine.Description);
            end;
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        if CancellingOnly then
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
            end
        else
            case ErrorOption of
                ErrorType::AccountBlocked:
                    Error(AccountIsBlockedCorrectErr, AccountCaption, AccountNo);
                ErrorType::DimErr:
                    Error(InvalidDimCodeCorrectErr, AccountCaption, AccountNo, No, Name);
            end;
    end;

    local procedure UpdateSalesOrderLinesFromCancelledInvoice(SalesInvoiceHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeaderNo);
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesLine.Get(SalesLine."Document Type"::Order, SalesInvoiceLine."Order No.", SalesInvoiceLine."Order Line No.") then
                    UpdateSalesOrderLineInvoicedQuantity(SalesLine, SalesInvoiceLine.Quantity, SalesInvoiceLine."Quantity (Base)");
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure UpdateSalesOrderLineInvoicedQuantity(var SalesLine: Record "Sales Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesOrderLineInvoicedQuantity(SalesLine, CancelledQuantity, CancelledQtyBase, IsHandled);
        if IsHandled then
            exit;

        SalesLine."Quantity Invoiced" -= CancelledQuantity;
        SalesLine."Qty. Invoiced (Base)" -= CancelledQtyBase;
        SalesLine."Quantity Shipped" -= CancelledQuantity;
        SalesLine."Qty. Shipped (Base)" -= CancelledQtyBase;
        SalesLine.InitOutstanding();
        SalesLine.InitQtyToShip();
        SalesLine.InitQtyToInvoice();
        SalesLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestCorrectInvoiceIsAllowed(var SalesInvoiceHeader: Record "Sales Invoice Header"; Cancelling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSalesLineType(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCorrectiveSalesCrMemo(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; var CancellingOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCorrectiveSalesCrMemo(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; CancellingOnly: Boolean)
    begin
    end;

    [Obsolete('This event has been replaced by OnBeforeSalesHeaderInsert, to fix a typo in the name', '15.1')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelesHeaderInsert(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; CancellingOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesOrderLineInvoicedQuantity(var SalesLine: Record "Sales Line"; CancelledQuantity: Decimal; CancelledQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditMemoOnBeforePageRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

